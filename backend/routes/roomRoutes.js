const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const { authMiddleware } = require('../middleware/auth');

router.post('/create',                  authMiddleware, roomController.createRoom);
router.post('/join',                    authMiddleware, roomController.joinRoom);
router.get('/:roomId/restaurants',      authMiddleware, roomController.getRoomRestaurants);

module.exports = router;
