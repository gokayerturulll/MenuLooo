// src/routes/room.routes.js
// Karar Odaları API'si — arkadaş gruplarıyla ortak restoran seçimi
const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');
const { authMiddleware } = require('../middleware/auth.middleware');
const { v4: uuidv4 } = require('uuid');

/** Rastgele 6 haneli oda kodu üret (ABC123 gibi) */
const generateRoomCode = () => {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
};

// POST /api/rooms — Yeni oda oluştur
router.post('/', authMiddleware, async (req, res) => {
  try {
    const { name, budget_min, budget_max, location_lat, location_lng, radius_km, dietary_filters } = req.body;
    const roomCode = generateRoomCode();

    const result = await query(
      `INSERT INTO rooms (id, host_id, room_code, name, budget_min, budget_max,
                          location_lat, location_lng, radius_km, dietary_filters)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10) RETURNING *`,
      [uuidv4(), req.user.id, roomCode, name, budget_min, budget_max,
       location_lat, location_lng, radius_km || 5, dietary_filters || []]
    );

    const room = result.rows[0];
    // Odayı oluşturan kişiyi üye olarak ekle
    await query(
      'INSERT INTO room_members (room_id, user_id, nickname) VALUES ($1, $2, $3)',
      [room.id, req.user.id, req.user.name]
    );

    res.status(201).json(room);
  } catch (err) {
    res.status(500).json({ error: 'Oda oluşturulamadı.' });
  }
});

// POST /api/rooms/join — Oda kodunu girerek katıl
router.post('/join', authMiddleware, async (req, res) => {
  try {
    const { room_code, nickname } = req.body;

    const roomResult = await query(
      `SELECT * FROM rooms WHERE room_code = $1 AND status != 'closed' AND expires_at > NOW()`,
      [room_code.toUpperCase()]
    );
    if (roomResult.rows.length === 0) {
      return res.status(404).json({ error: 'Oda bulunamadı veya süresi doldu.' });
    }

    const room = roomResult.rows[0];
    await query(
      `INSERT INTO room_members (room_id, user_id, nickname) VALUES ($1,$2,$3)
       ON CONFLICT (room_id, user_id) DO NOTHING`,
      [room.id, req.user.id, nickname || req.user.name]
    );

    res.json({ room, message: 'Odaya katıldınız.' });
  } catch (err) {
    res.status(500).json({ error: 'Odaya katılınamadı.' });
  }
});

// GET /api/rooms/:id — Oda detayı + üyeler + oylar
router.get('/:id', authMiddleware, async (req, res) => {
  try {
    const room = await query('SELECT * FROM rooms WHERE id = $1', [req.params.id]);
    if (room.rows.length === 0) return res.status(404).json({ error: 'Oda bulunamadı.' });

    const members = await query(
      `SELECT rm.nickname, u.id, u.name
       FROM room_members rm
       LEFT JOIN users u ON u.id = rm.user_id
       WHERE rm.room_id = $1`,
      [req.params.id]
    );

    res.json({ ...room.rows[0], members: members.rows });
  } catch (err) {
    res.status(500).json({ error: 'Oda bilgisi alınamadı.' });
  }
});

// POST /api/rooms/:id/vote — Restoran oyu ver
router.post('/:id/vote', authMiddleware, async (req, res) => {
  try {
    const { restaurant_id, score } = req.body;
    await query(
      `INSERT INTO room_votes (room_id, user_id, restaurant_id, score)
       VALUES ($1,$2,$3,$4)
       ON CONFLICT (room_id, user_id, restaurant_id) DO UPDATE SET score = EXCLUDED.score`,
      [req.params.id, req.user.id, restaurant_id, score]
    );
    res.json({ message: 'Oy kaydedildi.' });
  } catch (err) {
    res.status(500).json({ error: 'Oy verilemedi.' });
  }
});

module.exports = router;
