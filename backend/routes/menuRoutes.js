// routes/menuRoutes.js
// Tek bir menü öğesi üzerinde update / delete / photo işlemleri.
// /api/menu/items/:itemId path'i altında, Bearer token + owner zorunlu.

const express = require('express');
const router = express.Router();
const multer = require('multer');
const menuController = require('../controllers/menuController');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

// Multer — bellek storage (controller dosyaya yazar).
// 5 MB hard limit; controller'da MIME tipi de tekrar kontrol edilir.
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
});

router.put('/items/:itemId',
    authMiddleware, ownerOnly, menuController.updateMenuItem);

router.delete('/items/:itemId',
    authMiddleware, ownerOnly, menuController.deleteMenuItem);

router.post('/items/:itemId/photo',
    authMiddleware, ownerOnly, upload.single('photo'), menuController.uploadMenuItemPhoto);

module.exports = router;
