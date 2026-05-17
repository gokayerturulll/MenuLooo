const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authMiddleware } = require('../middleware/auth');
const { deleteAccount, forgotPassword, resetPassword, changePassword, getUserStats } = require('../controllers/authController');

router.post('/register', authController.register);
router.post('/login', authController.login);

// Şifre kurtarma (public)
router.post('/forgot-password', forgotPassword);
router.post('/reset-password',  resetPassword);

// Authenticated kullanıcı işlemleri
router.get('/me/stats',        authMiddleware, getUserStats);
router.put('/change-password', authMiddleware, changePassword);
router.delete('/me',           authMiddleware, deleteAccount);

module.exports = router;
