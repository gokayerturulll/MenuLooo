const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Route İçe Aktarımları
const authRoutes = require('./routes/authRoutes');
const restaurantRoutes = require('./routes/restaurantRoutes');
const menuRoutes = require('./routes/menuRoutes');
const greenMenuRoutes = require('./routes/greenMenuRoutes');
const roomRoutes = require('./routes/roomRoutes');

// Express uygulamasını başlat
const app = express();

// Middleware'ler
app.use(cors());
app.use(express.json());

// Rotaları Bağla
app.use('/api/auth', authRoutes);
app.use('/api/restaurants', restaurantRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/green-menu', greenMenuRoutes);
app.use('/api/rooms', roomRoutes);

// Sunucuyu Başlat
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
});
