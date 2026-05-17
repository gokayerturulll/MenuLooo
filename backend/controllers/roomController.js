const pool = require('../config/db');
const crypto = require('crypto');

// ─── Oda Başına Restoran Destesi Cache ────────────────────────────────────────
// room_id → restaurant_id[] (sunucu yeniden başlayana kadar kalıcı)
// Odadaki tüm kullanıcılara TAM OLARAK AYNI restoranları göstermek için kullanılır.
const roomDecks = new Map();

// server.js'den oda boşalınca ya da deste bitince çağrılır.
exports.clearRoomDeck = (roomId) => roomDecks.delete(roomId);

// server.js'deki deck_exhausted kontrolü için mevcut desteyi döner.
exports.getRoomDeck = (roomId) => roomDecks.get(roomId) ?? [];

// [KRİTİK-1] start_voting handler'ı tarafından deste kurulunca çağrılır.
// roomDecks Map yalnızca bu modülde yaşadığından server.js doğrudan erişemez.
exports.setRoomDeck = (roomId, ids) => roomDecks.set(roomId, ids);

// Socket join_room handler'ından çağrılır — DB'de üyelik doğrulaması yapar.
exports.verifyRoomMember = async (roomId, userId) => {
    const { rowCount } = await pool.query(
        'SELECT 1 FROM room_member WHERE room_id = $1 AND user_id = $2',
        [roomId, userId]
    );
    return rowCount > 0;
};

// 6-karakterli büyük harf alfanümerik PIN (2^24 = ~16M kombinasyon)
function generatePin() {
    return crypto.randomBytes(3).toString('hex').toUpperCase();
}

// Çakışma ihtimaline karşı benzersiz PIN dönen yardımcı
async function uniquePin(retries = 5) {
    for (let i = 0; i < retries; i++) {
        const pin = generatePin();
        const { rowCount } = await pool.query(
            'SELECT 1 FROM friend_room WHERE qr_code = $1',
            [pin]
        );
        if (rowCount === 0) return pin;
    }
    throw new Error('Benzersiz PIN üretilemedi. Lütfen tekrar deneyin.');
}

// POST /api/rooms/create
exports.createRoom = async (req, res) => {
    try {
        // budget / max_distance_km kaldırıldı — kategoriler lobide socket üzerinden alınıyor
        const { name, categories } = req.body;
        const host_id = req.user.user_id;

        const MAX_CAT    = 20;
        const MAX_CAT_LEN = 50;
        const sanitizedCategories = Array.isArray(categories)
            ? categories
                  .filter(c => typeof c === 'string' && c.length > 0 && c.length <= MAX_CAT_LEN)
                  .slice(0, MAX_CAT)
            : [];

        if (!name || typeof name !== 'string' || name.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Oda adı zorunludur.' });
        }

        const pin = await uniquePin();

        const { rows } = await pool.query(
            `INSERT INTO friend_room (creator_id, qr_code, name, categories, status)
             VALUES ($1, $2, $3, $4, 'active')
             RETURNING room_id, qr_code, creator_id, name, categories, status, created_at`,
            [host_id, pin, name.trim(), sanitizedCategories]
        );

        const room = rows[0];

        // Kurucu otomatik olarak odanın ilk üyesi
        await pool.query(
            `INSERT INTO room_member (room_id, user_id)
             VALUES ($1, $2)
             ON CONFLICT (room_id, user_id) DO NOTHING`,
            [room.room_id, host_id]
        );

        return res.status(201).json({
            success: true,
            message: 'Oda başarıyla oluşturuldu.',
            data: {
                room_id:    room.room_id,
                pin_code:   room.qr_code,
                host_id:    room.creator_id,
                name:       room.name,
                categories: room.categories,
                status:     room.status,
                created_at: room.created_at,
            },
        });
    } catch (error) {
        console.error('[createRoom]', error.message);
        res.status(500).json({ success: false, message: 'Oda oluşturulurken sunucu hatası oluştu.' });
    }
};

// GET /api/rooms/:roomId/restaurants
// Odadaki kullanıcılara oylanacak gerçek restoran havuzunu döner (maks 10, rastgele sıra).
exports.getRoomRestaurants = async (req, res) => {
    try {
        const roomId = parseInt(req.params.roomId, 10);
        if (Number.isNaN(roomId)) {
            return res.status(400).json({ success: false, message: 'Geçersiz oda kimliği.' });
        }

        // Kullanıcının odanın üyesi olduğunu doğrula
        const memberCheck = await pool.query(
            'SELECT 1 FROM room_member WHERE room_id = $1 AND user_id = $2',
            [roomId, req.user.user_id]
        );
        if (memberCheck.rowCount === 0) {
            return res.status(403).json({ success: false, message: 'Bu odanın üyesi değilsiniz.' });
        }

        // Odanın var olduğunu doğrula
        const roomResult = await pool.query(
            'SELECT room_id FROM friend_room WHERE room_id = $1',
            [roomId]
        );
        if (roomResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Oda bulunamadı.' });
        }

        // Cache HIT: bu oda için daha önce oluşturulmuş deste varsa aynen dön.
        // Böylece odaya geç kalan kullanıcılar da aynı restoranları görür.
        if (roomDecks.has(roomId)) {
            const cachedIds = roomDecks.get(roomId);
            const { rows } = await pool.query(
                `SELECT
                    restaurant_id,
                    owner_id,
                    business_name,
                    address,
                    cuisine_type,
                    categories,
                    phone,
                    website,
                    ST_Y(location_point::geometry) AS latitude,
                    ST_X(location_point::geometry) AS longitude
                 FROM restaurant
                 WHERE restaurant_id = ANY($1::int[])`,
                [cachedIds]
            );
            return res.status(200).json({ success: true, data: rows });
        }

        // Cache MISS: ilk istek — rastgele 10 restoran seç ve ID'lerini cache'le.
        const { rows } = await pool.query(
            `SELECT
                restaurant_id,
                owner_id,
                business_name,
                address,
                cuisine_type,
                categories,
                phone,
                website,
                ST_Y(location_point::geometry) AS latitude,
                ST_X(location_point::geometry) AS longitude
             FROM restaurant
             TABLESAMPLE BERNOULLI(30)
             LIMIT 10`
        );
        roomDecks.set(roomId, rows.map(r => r.restaurant_id));

        return res.status(200).json({ success: true, data: rows });
    } catch (error) {
        console.error('[getRoomRestaurants]', error.message);
        res.status(500).json({ success: false, message: 'Restoran listesi alınamadı.' });
    }
};

// POST /api/rooms/join
exports.joinRoom = async (req, res) => {
    try {
        const { qr_code, individual_preferences } = req.body;
        const user_id = req.user.user_id;

        if (!qr_code) {
            return res.status(400).json({ success: false, message: 'qr_code bilgisi zorunludur.' });
        }

        // budget / max_distance_km SELECT'ten kaldırıldı
        const roomResult = await pool.query(
            `SELECT room_id, name, categories, status, creator_id
             FROM friend_room WHERE qr_code = $1`,
            [qr_code]
        );
        if (roomResult.rows.length === 0) {
            return res.status(404).json({ success: false, message: 'Geçersiz QR kod, oda bulunamadı.' });
        }

        const room = roomResult.rows[0];

        if (room.status !== 'active') {
            return res.status(409).json({ success: false, message: 'Bu oda artık aktif değil.' });
        }

        const prefsStr = typeof individual_preferences === 'object'
            ? JSON.stringify(individual_preferences)
            : individual_preferences;

        await pool.query(
            `INSERT INTO room_member (room_id, user_id, individual_preferences)
             VALUES ($1, $2, $3)
             ON CONFLICT (room_id, user_id) DO NOTHING`,
            [room.room_id, user_id, prefsStr]
        );

        // Oda kurucusunu bilgilendir (yeni üye katıldı) — fire and forget
        if (room.creator_id !== user_id) {
            const { sendPushToUser, generateRoomDeepLink } = require('./notificationController');
            sendPushToUser(room.creator_id, {
                title: 'Birisi Odana Katıldı!',
                body:  `Oda #${qr_code} için yeni bir katılımcı bekleniyor.`,
                deepLink: generateRoomDeepLink(qr_code),
                extra: { action: 'member_joined', room_code: qr_code },
            }).catch(() => {});
        }

        return res.status(201).json({
            success: true,
            message: 'Odaya başarıyla katıldınız.',
            data: {
                room_id:    room.room_id,
                pin_code:   qr_code,
                host_id:    room.creator_id,
                name:       room.name,
                categories: room.categories,
                status:     room.status,
                created_at: null,
            },
        });
    } catch (error) {
        console.error('[joinRoom]', error.message);
        res.status(500).json({ success: false, message: 'Odaya katılırken sunucu hatası oluştu.' });
    }
};

// ─── Kategori Bazlı Restoran Getirme (server.js'deki start_voting için) ───────
// categories: string[] — boşsa tüm havuzdan rastgele 10 restoran döner.
const RESTAURANT_SELECT = `
    SELECT restaurant_id, owner_id, business_name, address, cuisine_type, categories,
           phone, website,
           ST_Y(location_point::geometry) AS latitude,
           ST_X(location_point::geometry) AS longitude
    FROM restaurant`;

exports.fetchRestaurantsByCategories = async (categories) => {
    if (!categories || categories.length === 0) {
        const { rows } = await pool.query(`${RESTAURANT_SELECT} TABLESAMPLE BERNOULLI(30) LIMIT 10`);
        return rows;
    }

    // categories && $1::text[] — seçilen kategorilerden en az biri eşleşsin
    // Not: WHERE filtresi TABLESAMPLE'dan sonra uygulanır; küçük popülasyonda
    // örneklem yetersiz kalırsa boş dönebilir → aşağıdaki fallback devreye girer.
    const { rows } = await pool.query(
        `${RESTAURANT_SELECT} TABLESAMPLE BERNOULLI(30) WHERE categories && $1::text[] LIMIT 10`,
        [categories]
    );

    // Hiçbir kategori eşleşmezse tüm havuzdan rastgele dön
    if (rows.length === 0) {
        const fallback = await pool.query(`${RESTAURANT_SELECT} TABLESAMPLE BERNOULLI(30) LIMIT 10`);
        return fallback.rows;
    }
    return rows;
};
