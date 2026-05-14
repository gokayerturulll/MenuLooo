// routes/menubotRoutes.js
//
//   POST /api/menubot/ask    body: { restaurantId?, message }
//
// authMiddleware zorunlu — kimliksiz kullanıcıların Gemini/Groq API kotasını
// tüketmesini engeller. server.js'deki menubotLimiter da ek koruma sağlar.

const express = require('express');
const router = express.Router();
const menubotController = require('../controllers/menubotController');
const { authMiddleware } = require('../middleware/auth');

router.post('/ask', authMiddleware, menubotController.ask);

module.exports = router;
