// routes/menubotRoutes.js
// MenuBot Soru-Cevap endpoint'i.
//
//   POST /api/menubot/ask    body: { restaurantId, message }
//
// Şu an public — istersen authMiddleware eklenebilir.

const express = require('express');
const router = express.Router();
const menubotController = require('../controllers/menubotController');

router.post('/ask', menubotController.ask);

module.exports = router;
