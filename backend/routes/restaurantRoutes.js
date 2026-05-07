const express = require('express');
const router = express.Router();
const restaurantController = require('../controllers/restaurantController');
const menuController = require('../controllers/menuController');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

// Public — müşteri tarafı
router.get('/', restaurantController.getAllRestaurants);
router.get('/:id/menu', restaurantController.getRestaurantMenu);

// İşletme paneli (MenuManagerView) — Bearer token + owner role zorunlu
router.get('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.getOwnerMenuItems);

router.post('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.createMenuItem);

module.exports = router;
