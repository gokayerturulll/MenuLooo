const http    = require('http');
const express = require('express');
const cors    = require('cors');
const helmet  = require('helmet');
const jwt     = require('jsonwebtoken');
const rateLimit = require('express-rate-limit');
const { Server } = require('socket.io');
require('dotenv').config();

const authRoutes       = require('./routes/authRoutes');
const restaurantRoutes = require('./routes/restaurantRoutes');
const menuRoutes       = require('./routes/menuRoutes');
const menubotRoutes    = require('./routes/menubotRoutes');
const greenMenuRoutes  = require('./routes/greenMenuRoutes');
const roomRoutes       = require('./routes/roomRoutes');

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

// ─── Rate Limiters ────────────────────────────────────────────────────────────
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Çok fazla istek gönderildi. Lütfen 15 dakika sonra tekrar deneyin.' },
});

const menubotLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    message: { success: false, message: 'Çok fazla MenuBot isteği. Lütfen biraz bekleyin.' },
});

// ─── REST Rotalar ─────────────────────────────────────────────────────────────
app.use('/api/auth',        authLimiter,    authRoutes);
app.use('/api/restaurants',                 restaurantRoutes);
app.use('/api/menu',                        menuRoutes);
app.use('/api/menubot',     menubotLimiter, menubotRoutes);
app.use('/api/green-menu',                  greenMenuRoutes);
app.use('/api/rooms',                       roomRoutes);

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

// ─── Socket.io ────────────────────────────────────────────────────────────────
const io = new Server(httpServer, {
    cors: {
        origin: ALLOWED_ORIGINS.length > 0 ? ALLOWED_ORIGINS : '*',
        methods: ['GET', 'POST'],
    },
    // iOS istemcisi uzun polling ile başlar, sonra WebSocket'e upgrade eder
    transports: ['polling', 'websocket'],
});

// JWT doğrulama middleware — her soket bağlantısında çalışır
io.use((socket, next) => {
    // iOS client token'ı query param veya auth nesnesinden gönderebilir
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

io.on('connection', (socket) => {
    const userId = socket.user?.user_id;
    console.log(`[Socket] Bağlandı: ${socket.id} (user_id: ${userId})`);

    // Kullanıcı bir odaya katılmak istediğinde bu event gelir (REST create/join'in ardından)
    socket.on('join_room', ({ room_id }) => {
        if (!room_id) return;
        const channel = `room_${room_id}`;
        socket.join(channel);

        // Odadaki diğer üyelere yeni katılım bildirimi gönder
        socket.to(channel).emit('member_joined', {
            user_id:   userId,
            socket_id: socket.id,
        });
        console.log(`[Socket] user_id=${userId} → ${channel}`);
    });

    // Kullanıcı odadan ayrılmak istediğinde (uygulama arka plana geçerse de tetiklenir)
    socket.on('leave_room', ({ room_id }) => {
        if (!room_id) return;
        const channel = `room_${room_id}`;
        socket.leave(channel);

        socket.to(channel).emit('member_left', { user_id: userId });
        console.log(`[Socket] user_id=${userId} ← ${channel}`);
    });

    // Bağlantı koptuğunda tüm odalara bildirim gider (Socket.io otomatik room'lardan çıkarır)
    socket.on('disconnect', (reason) => {
        console.log(`[Socket] Ayrıldı: ${socket.id} (${reason})`);
    });
});

// ─── Sunucu Başlatma ─────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
