// routes/usersRoutes.js
//   GET /api/users/me  — mevcut kullanıcı profili
//   PUT /api/users/me  — username / phone_number güncelleme

const express = require('express');
const router  = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { getMe, updateMe } = require('../controllers/userController');

router.get('/me', authMiddleware, getMe);
router.put('/me', authMiddleware, updateMe);

module.exports = router;
