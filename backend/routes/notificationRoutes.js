const express = require('express');
const router  = express.Router();
const { registerToken } = require('../controllers/notificationController');
const { authMiddleware } = require('../middleware/auth');

// POST /api/notifications/register — cihaz token'ını kaydet
router.post('/register', authMiddleware, registerToken);

module.exports = router;
