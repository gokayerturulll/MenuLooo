// src/routes/restaurant.routes.js
const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');
const { authMiddleware, businessOnly } = require('../middleware/auth.middleware');

// GET /api/restaurants?lat=41.0&lng=28.9&radius=5&search=burger
// Konum bazlı restoran arama (GPS koordinatları ile)
router.get('/', async (req, res) => {
  try {
    const { lat, lng, radius = 5, search, cuisine } = req.query;

    let sql = `
      SELECT r.id, r.name, r.description, r.cuisine_type, r.address,
             r.latitude, r.longitude, r.cover_image_url,
             r.average_rating, r.total_reviews, r.opens_at, r.closes_at
      FROM restaurants r
      WHERE r.is_active = TRUE
    `;
    const params = [];

    // Konum filtresi (Haversine formülü — iki koordinat arasındaki mesafeyi km cinsinden hesaplar)
    if (lat && lng) {
      params.push(parseFloat(lat), parseFloat(lng), parseFloat(radius));
      sql += `
        AND (
          6371 * acos(
            cos(radians($${params.length - 2})) * cos(radians(r.latitude)) *
            cos(radians(r.longitude) - radians($${params.length - 1})) +
            sin(radians($${params.length - 2})) * sin(radians(r.latitude))
          )
        ) < $${params.length}
      `;
    }

    // Full-text arama
    if (search) {
      params.push(search);
      sql += ` AND r.name ILIKE $${params.length} || '%' OR r.cuisine_type ILIKE $${params.length} || '%'`;
    }

    if (cuisine) {
      params.push(cuisine);
      sql += ` AND r.cuisine_type = $${params.length}`;
    }

    sql += ' ORDER BY r.average_rating DESC LIMIT 50';

    const result = await query(sql, params);
    res.json({ restaurants: result.rows, count: result.rowCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Restoran listesi alınamadı.' });
  }
});

// GET /api/restaurants/:id
router.get('/:id', async (req, res) => {
  try {
    const result = await query(
      `SELECT r.*, u.name as owner_name
       FROM restaurants r
       JOIN users u ON u.id = r.owner_id
       WHERE r.id = $1`,
      [req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Restoran bulunamadı.' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Restoran bilgisi alınamadı.' });
  }
});

// POST /api/restaurants (sadece işletme hesapları)
router.post('/', authMiddleware, businessOnly, async (req, res) => {
  try {
    const { v4: uuidv4 } = require('uuid');
    const { name, description, cuisine_type, address, city, latitude, longitude, phone } = req.body;

    const result = await query(
      `INSERT INTO restaurants (id, owner_id, name, description, cuisine_type, address, city, latitude, longitude, phone)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING *`,
      [uuidv4(), req.user.id, name, description, cuisine_type, address, city, latitude, longitude, phone]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Restoran oluşturulamadı.' });
  }
});

module.exports = router;
