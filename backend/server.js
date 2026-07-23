const http    = require('http');
const path    = require('path');
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const jwt     = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
require('dotenv').config();

const authRoutes         = require('./routes/authRoutes');
const restaurantRoutes   = require('./routes/restaurantRoutes');
const menuRoutes         = require('./routes/menuRoutes');
const menubotRoutes      = require('./routes/menubotRoutes');
const greenMenuRoutes    = require('./routes/greenMenuRoutes');
const roomRoutes         = require('./routes/roomRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const usersRoutes        = require('./routes/usersRoutes');
const analyticsRoutes    = require('./routes/analyticsRoutes');
const { clearRoomDeck, getRoomDeck, setRoomDeck, verifyRoomMember, fetchRestaurantsByCategories } = require('./controllers/roomController');

const app        = express();
const httpServer = http.createServer(app);

// ─── CORS origin listesi (hem Express hem Socket.io paylaşır) ─────────────────
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map(o => o.trim())
    .filter(Boolean);

const originAllowed = ALLOWED_ORIGINS.length > 0
    ? (origin, cb) => {
          if (!origin || ALLOWED_ORIGINS.includes(origin)) return cb(null, true);
          cb(new Error(`CORS: ${origin} izin listesinde değil.`));
      }
    : false;

// [KRİTİK-2] Production'da ALLOWED_ORIGINS boşsa wildcard CORS yerine başlatmayı engelle
if (process.env.NODE_ENV === 'production' && ALLOWED_ORIGINS.length === 0) {
    console.error('[FATAL] Production ortamında ALLOWED_ORIGINS tanımlanmamış. Güvenlik riski nedeniyle sunucu başlatılmıyor.');
    process.exit(1);
}

// Reverse-proxy / tünel arkasında gerçek istemci IP'sini almak için:
//   - production: 1 hop (ELB / Heroku / Nginx)
//   - dev/staging: loopback (ngrok agent localhost'tan istek atar; rate-limit
//     uyarısını da susturur — X-Forwarded-For yalnızca 127.0.0.1 için trust edilir)
app.set('trust proxy', process.env.NODE_ENV === 'production' ? 1 : 'loopback');

// ─── Güvenlik başlıkları ───────────────────────────────────────────────────────
app.use(helmet());

// ─── CORS (REST) ──────────────────────────────────────────────────────────────
app.use(cors({
    origin: originAllowed,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));

// ─── Body parser — 50 KB limit ────────────────────────────────────────────────
app.use(express.json({ limit: '50kb' }));

// ─── Static dosya servisi — menü öğesi fotoğrafları ──────────────────────────
// PLACEHOLDER: production'da CDN/S3 önerilir; bu route geliştirme/test içindir.
app.use('/uploads', express.static(path.join(__dirname, 'uploads'), {
    maxAge: '7d',
    setHeaders: (res) => res.set('Cache-Control', 'public, max-age=604800'),
}));

// ─── Rate Limiters ────────────────────────────────────────────────────────────
// authLimiter, authRoutes.js içinde sadece login/register/şifre kurtarma
// endpoint'lerine uygulanır. /api/auth/me/* gibi authenticated user-info
// endpoint'leri muaftır (Profil açılışlarında kotayı tüketmesin diye).
const menubotLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Çok fazla MenuBot isteği. Lütfen biraz bekleyin.' },
});

// ─── Health check (Docker HEALTHCHECK bunu kullanır) ──────────────────────────
app.get('/health', (req, res) => res.status(200).json({ status: 'ok' }));

// ─── REST Rotalar ─────────────────────────────────────────────────────────────
app.use('/api/auth',                          authRoutes);
app.use('/api/restaurants',                   restaurantRoutes);
app.use('/api/menu',                          menuRoutes);
app.use('/api/menubot',       menubotLimiter, menubotRoutes);
app.use('/api/green-menu',                    greenMenuRoutes);
app.use('/api/rooms',                         roomRoutes);
app.use('/api/notifications',                 notificationRoutes);
app.use('/api/users',                         usersRoutes);
app.use('/api/analytics',                     analyticsRoutes);

// ─── 404 ──────────────────────────────────────────────────────────────────────
app.use((req, res) => {
    res.status(404).json({ success: false, message: 'Endpoint bulunamadı.' });
});

// ─── Global hata yakalayıcı ───────────────────────────────────────────────────
// eslint-disable-next-line no-unused-vars
app.use((err, req, res, next) => {
    console.error('[Unhandled Error]', err.message || err);
    res.status(500).json({ success: false, message: 'Beklenmeyen bir sunucu hatası oluştu.' });
});

// ─── Bellek içi geçici depolar (üretimde Redis kullanılmalı) ──────────────────
// { [room_id]: { [restaurant_id]: { approved: [userId], rejected: [userId] } } }
const roomVotes = {};
// { [room_id]: Set<restaurant_id_string> } — match_found olan restoranları takip eder
const roomMatchedIds = {};
// { [socket_id]: room_id } — disconnect'te hangi odadan ayrıldığını bilmek için
const socketRoomMap = {};
// { [room_id]: NodeJS.Timeout } — boşalan odalar için 5 dk'lık TTL zamanlayıcıları
const roomEmptyTimers = {};
// [YÜKSEK-2] Multi-socket race condition koruması — fetchSockets() yerine local Set
// { room_id: Set<user_id> }
const roomActiveUsers = new Map();
const ROOM_TTL_MS       = 5  * 60 * 1000;
const HOST_CACHE_TTL_MS = 10 * 60 * 1000; // [ORTA-1] roomHosts cache yenileme eşiği
const MAX_CATEGORIES    = 20;             // [YÜKSEK-1] submit_categories maks. dizi uzunluğu
const MAX_CATEGORY_LEN  = 50;            // [YÜKSEK-1] tek kategori maks. karakter sayısı
// { [room_id]: { [user_id]: string[] } } — lobideki üyelerin kategori tercihleri
const roomMemberPrefs = {};
// [ORTA-1] { [room_id]: { creatorId: number, cachedAt: number } } — TTL ile yenilenen host cache
const roomHosts = {};

// ─── Socket.io ────────────────────────────────────────────────────────────────
const io = new Server(httpServer, {
    cors: {
        origin: ALLOWED_ORIGINS,
        methods: ['GET', 'POST'],
    },
    // iOS istemcisi uzun polling ile başlar, sonra WebSocket'e upgrade eder
    transports: ['polling', 'websocket'],
});

// ─── JWT_SECRET güç kontrolü ────────────────────────────────────────────────
const jwtSecret = process.env.JWT_SECRET || '';
if (jwtSecret.length < 32) {
    console.error('[FATAL] JWT_SECRET en az 32 karakter olmalıdır. Sunucu başlatılmıyor.');
    process.exit(1);
}

// JWT doğrulama middleware — her soket bağlantısında çalışır
io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.query?.token;

    if (!token) {
        return next(new Error('Socket: Kimlik doğrulama token\'ı eksik.'));
    }

    const secret = process.env.JWT_SECRET;
    if (!secret) {
        console.error('[FATAL] JWT_SECRET eksik.');
        return next(new Error('Sunucu yapılandırma hatası.'));
    }

    try {
        socket.user = jwt.verify(token, secret);
        next();
    } catch {
        next(new Error('Socket: Geçersiz veya süresi dolmuş token.'));
    }
});

// ─── Helper: Deste Tükenme Kontrolü ──────────────────────────────────────────
// Odadaki tüm üyeler destede bulunan her restoran için oy verdiyse ve
// hiçbiri eşleşme sağlayamamışsa deck_exhausted event'i emit eder.
function checkDeckExhausted(roomId, channel) {
    const deck = getRoomDeck(roomId);
    if (deck.length === 0) return; // Deste kurulmadıysa ya da temizlendiyse kontrol yapma

    const roomMembers = io.sockets.adapter.rooms.get(channel);
    const memberCount = roomMembers ? roomMembers.size : 0;
    if (memberCount === 0) return;

    const votes   = roomVotes[roomId]   || {};
    const matched = roomMatchedIds[roomId] || new Set();

    const allDone = deck.every(restaurantId => {
        const rid = String(restaurantId);
        if (matched.has(rid)) return true; // Eşleşme bulunmuş, geç

        const entry = votes[rid];
        if (!entry) return false; // Henüz hiç oy yok
        return (entry.approved.length + entry.rejected.length) >= memberCount;
    });

    if (allDone) {
        // Tüm state'i sıfırla — frontend yeni deste için fetchRoomRestaurants() çağıracak
        delete roomVotes[roomId];
        delete roomMatchedIds[roomId];
        clearRoomDeck(roomId);
        io.to(channel).emit('deck_exhausted');
        console.log(`[Socket] deck_exhausted: room=${roomId}`);
    }
}

// ─── Helper: Üye Ayrılması Sonrası Oy Eşiği Yeniden Kontrolü ─────────────────
// Bir üye düştüğünde yeni memberCount ile mevcut oylar tekrar değerlendirilir.
// Onay eşiği dolmuşsa match_found; deste tükenmiş durumdaysa deck_exhausted emit eder.
function recheckVotesAfterMemberChange(roomId, channel) {
    const roomMembers = io.sockets.adapter.rooms.get(channel);
    const memberCount = roomMembers ? roomMembers.size : 0;
    if (memberCount === 0) return;

    const votes = roomVotes[roomId];
    if (!votes) {
        // Oy yoksa sadece deste kontrolü gerekiyor (nadir durum)
        checkDeckExhausted(roomId, channel);
        return;
    }

    const matched = roomMatchedIds[roomId] || new Set();

    for (const [restaurantId, entry] of Object.entries(votes)) {
        if (matched.has(restaurantId)) continue;

        if (entry.approved.length >= memberCount) {
            io.to(channel).emit('match_found', { restaurant_id: restaurantId });
            matched.add(restaurantId);
            roomMatchedIds[roomId] = matched;
            delete votes[restaurantId];
            console.log(`[Socket] match_found (üye düşmesi): room=${roomId} restaurant=${restaurantId}`);
            return; // Tek seferde bir eşleşme yeterli
        }
    }

    // Yeni eşleşme yoksa deste tükenmiş mi diye kontrol et
    checkDeckExhausted(roomId, channel);
}

// ─── Helper: Oda Boşaldığında Tüm State'i Temizle ────────────────────────────
function clearRoomState(roomId) {
    delete roomVotes[roomId];
    delete roomMatchedIds[roomId];
    delete roomMemberPrefs[roomId];
    delete roomHosts[roomId];
    clearRoomDeck(roomId);
    roomActiveUsers.delete(roomId);
    delete roomEmptyTimers[roomId]; // Timer zaten tetiklendiyse referansı temizle
}

// 5 dk TTL başlat — kimse dönmezse state silinir.
function scheduleRoomCleanup(roomId) {
    if (roomEmptyTimers[roomId]) clearTimeout(roomEmptyTimers[roomId]);
    roomEmptyTimers[roomId] = setTimeout(() => {
        clearRoomState(roomId);
        console.log(`[Socket] TTL doldu, state temizlendi: room=${roomId}`);
    }, ROOM_TTL_MS);
}

// Biri geri döndüğünde bekleyen TTL'yi iptal et.
function cancelRoomCleanup(roomId) {
    if (roomEmptyTimers[roomId]) {
        clearTimeout(roomEmptyTimers[roomId]);
        delete roomEmptyTimers[roomId];
    }
}

// Kopan kullanıcının oylarını tüm entry'lerden sil (zombie oy temizliği).
function removeUserVotes(roomId, userId) {
    const votes = roomVotes[roomId];
    if (!votes) return;
    for (const entry of Object.values(votes)) {
        const ai = entry.approved.indexOf(userId);
        if (ai !== -1) entry.approved.splice(ai, 1);
        const ri = entry.rejected.indexOf(userId);
        if (ri !== -1) entry.rejected.splice(ri, 1);
    }
}

io.on('connection', (socket) => {
    const userId = socket.user?.user_id;
    console.log(`[Socket] Bağlandı: ${socket.id} (user_id: ${userId})`);

    // Kullanıcı bir odaya katılmak istediğinde bu event gelir (REST create/join'in ardından)
    socket.on('join_room', async ({ room_id }) => {
        if (!room_id) return;

        // DB üyelik doğrulaması — token sahibi bu odanın gerçek üyesi mi?
        try {
            const isMember = await verifyRoomMember(room_id, userId);
            if (!isMember) {
                socket.emit('join_room_rejected', { room_id, reason: 'Bu odanın üyesi değilsiniz.' });
                console.warn(`[Socket] Yetkisiz join_room: user_id=${userId} room=${room_id}`);
                return;
            }
        } catch (err) {
            console.error('[Socket] join_room DB hatası:', err.message);
            socket.emit('join_room_rejected', { room_id, reason: 'Üyelik doğrulanamadı.' });
            return;
        }

        // Oda boşalmıştı ama biri geri döndü — TTL sayacını iptal et
        cancelRoomCleanup(room_id);

        // [ORTA-1] Oda kurucusunu ilk join'da cache'le ({ creatorId, cachedAt } formatında)
        if (!roomHosts[room_id]) {
            try {
                const pool = require('./config/db');
                const { rows } = await pool.query(
                    'SELECT creator_id FROM friend_room WHERE room_id = $1', [room_id]
                );
                if (rows.length > 0) {
                    roomHosts[room_id] = { creatorId: rows[0].creator_id, cachedAt: Date.now() };
                }
            } catch (err) {
                console.error('[Socket] roomHosts cache hatası:', err.message);
            }
        }

        const channel = `room_${room_id}`;

        // [YÜKSEK-2] Atomic multi-socket koruması — local Map ile race-free kontrol
        if (!roomActiveUsers.has(room_id)) roomActiveUsers.set(room_id, new Set());
        if (roomActiveUsers.get(room_id).has(userId)) {
            socket.emit('join_room_rejected', { room_id, reason: 'Zaten başka bir cihazdan bu odaya bağlısınız.' });
            console.warn(`[Socket] Çoklu socket reddi: user_id=${userId} room=${room_id}`);
            return;
        }
        roomActiveUsers.get(room_id).add(userId);

        socket.join(channel);
        socketRoomMap[socket.id] = room_id;

        socket.to(channel).emit('member_joined', { user_id: userId, socket_id: socket.id });

        // Katılan kullanıcıya anlık oda durumunu gönder (reconnect sync)
        const roomMembers = io.sockets.adapter.rooms.get(channel);

        // Katılan kullanıcının daha önce oy verdiği restoran ID'lerini hesapla
        const myVotedIds = Object.entries(roomVotes[room_id] ?? {})
            .filter(([, entry]) =>
                entry.approved.includes(userId) || entry.rejected.includes(userId)
            )
            .map(([rid]) => rid);

        socket.emit('sync_room_state', {
            votes:                  roomVotes[room_id]         ?? {},
            matched_restaurant_ids: roomMatchedIds[room_id] ? [...roomMatchedIds[room_id]] : [],
            member_count:           roomMembers ? roomMembers.size : 1,
            my_voted_ids:           myVotedIds,
        });

        console.log(`[Socket] user_id=${userId} → ${channel}`);
    });

    // Kullanıcı odadan ayrılmak istediğinde (uygulama arka plana geçerse de tetiklenir)
    socket.on('leave_room', ({ room_id }) => {
        if (!room_id) return;
        const channel = `room_${room_id}`;
        socket.leave(channel);
        delete socketRoomMap[socket.id];
        roomActiveUsers.get(room_id)?.delete(userId);

        socket.to(channel).emit('member_left', { user_id: userId });

        // Kullanıcının zombie oylarını sil, ardından eşiği yeniden hesapla
        removeUserVotes(room_id, userId);

        const remaining = io.sockets.adapter.rooms.get(channel);
        if (!remaining || remaining.size === 0) {
            scheduleRoomCleanup(room_id); // Anında silme yok — 5 dk TTL başlat
        } else {
            recheckVotesAfterMemberChange(room_id, channel);
        }

        console.log(`[Socket] user_id=${userId} ← ${channel}`);
    });

    // Kullanıcı lobideyken kendi kategori tercihlerini bildirir
    socket.on('submit_categories', ({ room_id, categories }) => {
        if (socketRoomMap[socket.id] !== room_id) return;
        if (!Array.isArray(categories)) return;

        // [YÜKSEK-1] Uzunluk ve tip kontrolü; limit aşan eleman/dizi budanır
        const sanitized = categories
            .filter(c => typeof c === 'string' && c.length > 0 && c.length <= MAX_CATEGORY_LEN)
            .slice(0, MAX_CATEGORIES);

        if (!roomMemberPrefs[room_id]) roomMemberPrefs[room_id] = {};
        roomMemberPrefs[room_id][userId] = sanitized;

        // Diğer üyelere hangi kullanıcının ne seçtiğini bildir (opsiyonel UI güncelleme)
        socket.to(`room_${room_id}`).emit('categories_updated', { user_id: userId, categories: sanitized });
        console.log(`[Socket] submit_categories: user=${userId} room=${room_id} categories=${sanitized}`);
    });

    // Oda kurucusu oylamayı başlatır — tüm üyelerin kategorilerini toplar, DB'den restoran çeker
    socket.on('start_voting', async ({ room_id }, ack) => {
        const reply = (success, error) => {
            if (typeof ack === 'function') ack({ success, ...(error ? { error } : {}) });
        };

        if (!room_id) return reply(false, 'Eksik parametreler.');

        // Yetki kontrolü: sadece odadaki kullanıcılar event gönderebilir
        if (socketRoomMap[socket.id] !== room_id) {
            return reply(false, 'Bu odada değilsiniz.');
        }

        const channel = `room_${room_id}`;

        // [ORTA-1] Host cache'i kontrol et; TTL dolmuşsa DB'den yenile
        let hostEntry = roomHosts[room_id];
        if (!hostEntry || Date.now() - hostEntry.cachedAt > HOST_CACHE_TTL_MS) {
            try {
                const pool = require('./config/db');
                const { rows } = await pool.query(
                    'SELECT creator_id FROM friend_room WHERE room_id = $1', [room_id]
                );
                if (rows.length > 0) {
                    hostEntry = { creatorId: rows[0].creator_id, cachedAt: Date.now() };
                    roomHosts[room_id] = hostEntry;
                }
            } catch (err) {
                console.error('[Socket] roomHosts yenileme hatası:', err.message);
                return reply(false, 'Yetki doğrulaması yapılamadı.');
            }
        }

        // Host kontrolü: sadece oda kurucusu start_voting yapabilir
        if (!hostEntry || hostEntry.creatorId !== userId) {
            console.warn(`[Socket] Yetkisiz start_voting: user=${userId} room=${room_id}`);
            return reply(false, 'Sadece oda kurucusu oylamayı başlatabilir.');
        }

        try {
            // Odadaki tüm üyelerin kategorilerini birleştir (tekrarları kaldır)
            const prefs = roomMemberPrefs[room_id] ?? {};
            const allCategories = [...new Set(Object.values(prefs).flat())];
            console.log(`[Socket] start_voting: room=${room_id} categories=${allCategories}`);

            // Kategorilere uygun restoranları DB'den çek
            const restaurants = await fetchRestaurantsByCategories(allCategories);

            // Deste boşsa cache'e yazmadan hata dön (DB tamamen boşsa olası kenar durum)
            if (restaurants.length === 0) {
                return reply(false, 'Seçilen kategorilerde restoran bulunamadı.');
            }

            // [KRİTİK-1] roomDecks Map yalnızca roomController scope'unda; setRoomDeck ile yazılır
            setRoomDeck(room_id, restaurants.map(r => r.restaurant_id));

            reply(true);
            // Tüm odaya restoran listesiyle birlikte voting_started gönder
            io.to(channel).emit('voting_started', { restaurants });
            console.log(`[Socket] voting_started: room=${room_id} count=${restaurants.length}`);
        } catch (err) {
            console.error('[Socket] start_voting hatası:', err.message);
            reply(false, 'Oylama başlatılamadı. Lütfen tekrar deneyin.');
        }
    });

    // Oy gönderme: bir kullanıcı restoran için onay/red oyunu iletir
    socket.on('submit_vote', ({ room_id, restaurant_id, is_approved }, ack) => {
        const reply = (success, error) => {
            if (typeof ack === 'function') ack({ success, ...(error ? { error } : {}) });
        };

        if (!room_id || !restaurant_id || is_approved === undefined) {
            return reply(false, 'Eksik parametreler.');
        }

        // Yetkilendirme Kontrolü: Sadece odaya 'join_room' ile başarıyla katılanlar oy verebilir.
        if (socketRoomMap[socket.id] !== room_id) {
            console.warn(`[Socket] Yetkisiz oy girişimi: user_id=${userId} room=${room_id}`);
            return reply(false, 'Bu odada oy kullanma yetkiniz yok.');
        }

        // DoS koruması: restaurant_id bu odanın geçerli destesinde bulunmalı
        const deck = getRoomDeck(room_id);
        if (deck.length === 0 || !deck.map(String).includes(String(restaurant_id))) {
            console.warn(`[Socket] Geçersiz restaurant_id: ${restaurant_id} room=${room_id}`);
            return reply(false, 'Geçersiz restoran kimliği veya deste hazır değil.');
        }

        const channel = `room_${room_id}`;
        if (!roomVotes[room_id]) roomVotes[room_id] = {};
        if (!roomVotes[room_id][restaurant_id]) {
            roomVotes[room_id][restaurant_id] = { approved: [], rejected: [] };
        }

        const entry = roomVotes[room_id][restaurant_id];

        if (entry.approved.includes(userId) || entry.rejected.includes(userId)) {
            return reply(false, 'Bu restoran için zaten oy kullandınız.');
        }

        if (is_approved) {
            entry.approved.push(userId);
        } else {
            entry.rejected.push(userId);
        }

        // Oy kaydedildi — iOS'a acknowledge gönder (UI kilidi ancak bundan sonra açılır)
        reply(true);

        io.to(channel).emit('vote_update', {
            restaurant_id,
            approved_by: entry.approved,
            rejected_by: entry.rejected,
        });

        const roomMembers = io.sockets.adapter.rooms.get(channel);
        const memberCount = roomMembers ? roomMembers.size : 1;

        if (entry.approved.length >= memberCount) {
            io.to(channel).emit('match_found', { restaurant_id });
            if (!roomMatchedIds[room_id]) roomMatchedIds[room_id] = new Set();
            roomMatchedIds[room_id].add(restaurant_id);
            delete roomVotes[room_id][restaurant_id];
            console.log(`[Socket] match_found: room=${room_id} restaurant=${restaurant_id}`);
        } else {
            checkDeckExhausted(room_id, channel);
        }
    });

    // Beklenmedik kopuş — Socket.io zaten tüm room'lardan çıkarır
    socket.on('disconnect', (reason) => {
        const room_id = socketRoomMap[socket.id];
        delete socketRoomMap[socket.id];
        if (room_id) roomActiveUsers.get(room_id)?.delete(userId);

        if (room_id) {
            const channel   = `room_${room_id}`;

            // Zombie oyları temizle
            removeUserVotes(room_id, userId);

            const remaining = io.sockets.adapter.rooms.get(channel);
            if (!remaining || remaining.size === 0) {
                scheduleRoomCleanup(room_id); // 5 dk TTL — kullanıcı geri dönebilir
            } else {
                io.to(channel).emit('member_left', { user_id: userId });
                recheckVotesAfterMemberChange(room_id, channel);
            }
        }

        console.log(`[Socket] Ayrıldı: ${socket.id} (${reason})`);
    });
});

// ─── Global hata yakalayıcılar ───────────────────────────────────────────────
process.on('unhandledRejection', (reason, promise) => {
    console.error('[unhandledRejection]', reason);
    // Prod'da burada Sentry/Datadog'a log atılabilir
});

process.on('uncaughtException', (err) => {
    console.error('[uncaughtException]', err);
    httpServer.close(() => process.exit(1));
});

// ─── Graceful shutdown (docker compose stop/down → SIGTERM) ──────────────────
function gracefulShutdown(signal) {
    console.log(`\n${signal} alındı, sunucu düzgünce kapatılıyor...`);
    httpServer.close(async () => {
        console.log('HTTP sunucu kapandı, devam eden istek kalmadı.');
        try {
            const pool = require('./config/db');
            await pool.end();
            console.log('PostgreSQL bağlantı havuzu kapandı.');
        } catch (err) {
            console.error('Kapatma sırasında hata:', err.message);
        }
        process.exit(0);
    });
    // 10 sn içinde temiz kapanma olmazsa zorla çık (asılı kalan bağlantı vs.)
    setTimeout(() => process.exit(1), 10_000).unref();
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

// ─── Sunucu Başlatma ─────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
