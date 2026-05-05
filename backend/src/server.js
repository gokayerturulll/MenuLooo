// src/server.js
// MenuLo Backend — Ana sunucu dosyası

require('dotenv').config();
const express = require('express');
const http = require('http');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const { Server } = require('socket.io');
const rateLimit = require('express-rate-limit');

const { pool } = require('../config/database');
const authRoutes = require('./routes/auth.routes');
const restaurantRoutes = require('./routes/restaurant.routes');
const menuRoutes = require('./routes/menu.routes');
const roomRoutes = require('./routes/room.routes');
const menubotRoutes = require('./routes/menubot.routes');
const reviewRoutes = require('./routes/review.routes');
const { setupSocketHandlers } = require('./services/socket.service');

const app = express();
const httpServer = http.createServer(app);

// ── Socket.io ──────────────────────────────────────
const io = new Server(httpServer, {
  cors: { origin: process.env.SOCKET_CORS_ORIGIN || '*', methods: ['GET', 'POST'] }
});
setupSocketHandlers(io);

// ── Middleware ─────────────────────────────────────
app.use(helmet());       // Güvenlik başlıkları
app.use(cors());         // iOS'tan gelen cross-origin isteklere izin ver
app.use(morgan('dev'));  // İstek logları
app.use(express.json()); // JSON body parser

// Rate limiting — aynı IP'den aşırı istek gelirse engelle
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use('/api/', limiter);

// ── Sağlık Kontrolü ────────────────────────────────
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'ok',
      database: 'PostgreSQL bağlantısı aktif',
      timestamp: new Date().toISOString()
    });
  } catch (err) {
    res.status(500).json({ status: 'error', database: err.message });
  }
});

// ── API Rotaları ────────────────────────────────────
app.use('/api/auth',        authRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/menu',        menuRoutes);
app.use('/api/rooms',       roomRoutes);
app.use('/api/menubot',     menubotRoutes);
app.use('/api/reviews',     reviewRoutes);

// ── 404 Handler ─────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Bu endpoint mevcut değil.' });
});

// ── Global Hata Handler ─────────────────────────────
app.use((err, req, res, next) => {
  console.error('❌ Sunucu hatası:', err.stack);
  res.status(500).json({ error: 'Sunucu hatası oluştu.' });
});

// ── Sunucuyu Başlat ─────────────────────────────────
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
  console.log(`🚀 MenuLo Backend http://localhost:${PORT} adresinde çalışıyor`);
  console.log(`📡 Socket.io aktif`);
  console.log(`🌍 Ortam: ${process.env.NODE_ENV}`);
});

module.exports = { app, io };
