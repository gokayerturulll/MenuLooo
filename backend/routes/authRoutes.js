const express = require('express');
const rateLimit = require('express-rate-limit');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');
const { deleteAccount, forgotPassword, resetPassword, changePassword, getUserStats } = require('../controllers/authController');
const reviewController = require('../controllers/reviewController');

// Brute-force koruması — sadece hassas public auth endpoint'lerinde.
// Development modunda devre dışıdır (yerel test sırasında engele takılmamak için).
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    standardHeaders: true,
    legacyHeaders: false,
    skip: () => process.env.NODE_ENV !== 'production',
    message: { success: false, message: 'Çok fazla istek gönderildi. Lütfen 15 dakika sonra tekrar deneyin.' },
});

router.post('/register',        authLimiter, authController.register);
router.post('/login',           authLimiter, authController.login);

// Şifre kurtarma (public)
router.post('/forgot-password', authLimiter, forgotPassword);
router.post('/reset-password',  authLimiter, resetPassword);

// Authenticated kullanıcı işlemleri
router.get('/me/stats',        authMiddleware, getUserStats);
router.get('/me/reviews',      authMiddleware, reviewController.getUserReviews);
router.put('/change-password', authMiddleware, changePassword);
router.delete('/me',           authMiddleware, deleteAccount);

module.exports = router;
