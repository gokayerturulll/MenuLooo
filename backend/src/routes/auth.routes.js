// src/routes/auth.routes.js
const express = require('express');
const router = express.Router();
const { body } = require('express-validator');
const authController = require('../controllers/auth.controller');
const { validateRequest } = require('../utils/validate');

// POST /api/auth/register
router.post('/register',
  [
    body('name').trim().notEmpty().withMessage('Ad gerekli.'),
    body('email').isEmail().normalizeEmail().withMessage('Geçerli e-posta girin.'),
    body('password').isLength({ min: 6 }).withMessage('Şifre en az 6 karakter olmalı.'),
    body('user_type').optional().isIn(['customer', 'business']),
    validateRequest
  ],
  authController.register
);

// POST /api/auth/login
router.post('/login',
  [
    body('email').isEmail().normalizeEmail(),
    body('password').notEmpty(),
    validateRequest
  ],
  authController.login
);

// POST /api/auth/refresh
router.post('/refresh', authController.refresh);

// POST /api/auth/logout
router.post('/logout', authController.logout);

module.exports = router;
