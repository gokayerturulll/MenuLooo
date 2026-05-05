// src/routes/menu.routes.js
const express = require('express');
const router = express.Router();
const { query } = require('../../config/database');
const { authMiddleware, businessOnly } = require('../middleware/auth.middleware');
const { v4: uuidv4 } = require('uuid');

// GET /api/menu/:restaurantId — Restoran menüsünü kategorileriyle getir
router.get('/:restaurantId', async (req, res) => {
  try {
    // Kategorileri getir
    const categories = await query(
      `SELECT id, name, description, display_order
       FROM menu_categories
       WHERE restaurant_id = $1 AND is_active = TRUE
       ORDER BY display_order`,
      [req.params.restaurantId]
    );

    // Her kategori için ürünleri getir
    const items = await query(
      `SELECT id, category_id, name, description, price, image_url,
              is_available, is_vegetarian, is_vegan, is_gluten_free,
              calories, allergens, tags, is_green_menu, green_price, green_expires_at
       FROM menu_items
       WHERE restaurant_id = $1
         AND is_available = TRUE
         AND (is_green_menu = FALSE OR green_expires_at > NOW())
       ORDER BY category_id, name`,
      [req.params.restaurantId]
    );

    // Kategorilere göre grupla
    const grouped = categories.rows.map(cat => ({
      ...cat,
      items: items.rows.filter(item => item.category_id === cat.id)
    }));

    res.json({ categories: grouped });
  } catch (err) {
    res.status(500).json({ error: 'Menü alınamadı.' });
  }
});

// GET /api/menu/search?q=cheeseburger — Full-text menü araması
router.get('/search/items', async (req, res) => {
  try {
    const { q, restaurant_id, vegetarian, vegan, gluten_free, min_price, max_price } = req.query;

    let sql = `
      SELECT mi.*, r.name as restaurant_name, r.address as restaurant_address
      FROM menu_items mi
      JOIN restaurants r ON r.id = mi.restaurant_id
      WHERE mi.is_available = TRUE
        AND r.is_active = TRUE
    `;
    const params = [];

    if (q) {
      params.push(q);
      // PostgreSQL full-text search + ILIKE fallback
      sql += ` AND (mi.search_vector @@ plainto_tsquery('simple', $${params.length})
               OR mi.name ILIKE '%' || $${params.length} || '%')`;
    }

    if (restaurant_id) { params.push(restaurant_id); sql += ` AND mi.restaurant_id = $${params.length}`; }
    if (vegetarian === 'true') sql += ` AND mi.is_vegetarian = TRUE`;
    if (vegan === 'true') sql += ` AND mi.is_vegan = TRUE`;
    if (gluten_free === 'true') sql += ` AND mi.is_gluten_free = TRUE`;
    if (min_price) { params.push(parseFloat(min_price)); sql += ` AND mi.price >= $${params.length}`; }
    if (max_price) { params.push(parseFloat(max_price)); sql += ` AND mi.price <= $${params.length}`; }

    sql += ' ORDER BY mi.name LIMIT 100';

    const result = await query(sql, params);
    res.json({ items: result.rows, count: result.rowCount });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Arama yapılamadı.' });
  }
});

// POST /api/menu/:restaurantId/items — Yeni menü ürünü ekle
router.post('/:restaurantId/items', authMiddleware, businessOnly, async (req, res) => {
  try {
    const { name, description, price, category_id, is_vegetarian, is_vegan, is_gluten_free, calories, allergens, tags } = req.body;

    const result = await query(
      `INSERT INTO menu_items
         (id, restaurant_id, category_id, name, description, price,
          is_vegetarian, is_vegan, is_gluten_free, calories, allergens, tags)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
       RETURNING *`,
      [uuidv4(), req.params.restaurantId, category_id, name, description, price,
       is_vegetarian || false, is_vegan || false, is_gluten_free || false,
       calories, allergens || [], tags || []]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Menü ürünü eklenemedi.' });
  }
});

// PATCH /api/menu/items/:id/green — Green Menu aktifleştir
router.patch('/items/:id/green', authMiddleware, businessOnly, async (req, res) => {
  try {
    const { green_price, expires_in_minutes } = req.body;
    const result = await query(
      `UPDATE menu_items
       SET is_green_menu = TRUE,
           green_price = $1,
           green_expires_at = NOW() + ($2 || ' minutes')::INTERVAL
       WHERE id = $3 RETURNING *`,
      [green_price, expires_in_minutes || 120, req.params.id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Ürün bulunamadı.' });
    res.json(result.rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Green Menu güncellenemedi.' });
  }
});

module.exports = router;
