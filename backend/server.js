const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Route İçe Aktarımları
const authRoutes = require('./routes/authRoutes');
const restaurantRoutes = require('./routes/restaurantRoutes');
const menuRoutes = require('./routes/menuRoutes');
const menubotRoutes = require('./routes/menubotRoutes');
const greenMenuRoutes = require('./routes/greenMenuRoutes');
const roomRoutes = require('./routes/roomRoutes');

// Express uygulamasını başlat
const app = express();

// Middleware'ler
const ALLOWED_ORIGINS = (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map(o => o.trim())
    .filter(Boolean);

app.use(cors({
    origin: ALLOWED_ORIGINS.length > 0
        ? (origin, cb) => {
            // ngrok / mobil istemciler origin göndermeyebilir
            if (!origin || ALLOWED_ORIGINS.includes(origin)) return cb(null, true);
            cb(new Error(`CORS: ${origin} izin listesinde değil.`));
          }
        : false,
    methods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
}));
app.use(express.json());

// Rotaları Bağla
app.use('/api/auth', authRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/menubot', menubotRoutes);
app.use('/api/green-menu', greenMenuRoutes);
app.use('/api/rooms', roomRoutes);

// Sunucuyu Başlat
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
