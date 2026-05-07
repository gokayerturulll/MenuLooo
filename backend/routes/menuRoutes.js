// routes/menuRoutes.js
// Tek bir menü öğesi üzerinde update / delete işlemleri.
// /api/menu/items/:itemId path'i altında, Bearer token + owner zorunlu.

const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

router.put('/items/:itemId',
    authMiddleware, ownerOnly, menuController.updateMenuItem);

router.delete('/items/:itemId',
    authMiddleware, ownerOnly, menuController.deleteMenuItem);

module.exports = router;
