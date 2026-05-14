const pool = require('../config/db');
const crypto = require('crypto');

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
        const { name, categories, budget, max_distance_km } = req.body;
        const host_id = req.user.user_id;

        if (!name || typeof name !== 'string' || name.trim().length === 0) {
            return res.status(400).json({ success: false, message: 'Oda adı zorunludur.' });
        }
        if (!Array.isArray(categories) || categories.length === 0) {
            return res.status(400).json({ success: false, message: 'En az bir kategori seçilmelidir.' });
        }

        const pin = await uniquePin();

        const { rows } = await pool.query(
            `INSERT INTO friend_room
                (creator_id, qr_code, name, categories, budget, max_distance_km, status)
             VALUES ($1, $2, $3, $4, $5, $6, 'active')
             RETURNING room_id, qr_code, creator_id, name, categories,
                       budget, max_distance_km, status, created_at`,
            [
                host_id,
                pin,
                name.trim(),
                categories,
                budget   ?? 100,
                max_distance_km ?? 3.0,
            ]
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
                room_id:         room.room_id,
                pin_code:        room.qr_code,
                host_id:         room.creator_id,
                name:            room.name,
                categories:      room.categories,
                budget:          room.budget,
                max_distance_km: room.max_distance_km,
                status:          room.status,
                created_at:      room.created_at,
            },
        });
    } catch (error) {
        console.error('[createRoom]', error.message);
        res.status(500).json({ success: false, message: 'Oda oluşturulurken sunucu hatası oluştu.' });
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

        const roomResult = await pool.query(
            `SELECT room_id, name, categories, budget, max_distance_km, status, creator_id
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

        return res.status(201).json({
            success: true,
            message: 'Odaya başarıyla katıldınız.',
            data: {
                room_id:         room.room_id,
                pin_code:        qr_code,
                host_id:         room.creator_id,
                name:            room.name,
                categories:      room.categories,
                budget:          room.budget,
                max_distance_km: room.max_distance_km,
                status:          room.status,
                created_at:      null,
            },
        });
    } catch (error) {
        console.error('[joinRoom]', error.message);
        res.status(500).json({ success: false, message: 'Odaya katılırken sunucu hatası oluştu.' });
    }
};
