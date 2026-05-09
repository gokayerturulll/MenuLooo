const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const { authMiddleware } = require('../middleware/auth');

router.post('/join', authMiddleware, roomController.joinRoom);

module.exports = router;
