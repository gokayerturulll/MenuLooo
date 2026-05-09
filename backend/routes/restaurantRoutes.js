const express = require('express');
const router = express.Router();
const restaurantController = require('../controllers/restaurantController');
const menuController = require('../controllers/menuController');
const reviewController = require('../controllers/reviewController');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

// MARK: - Public — müşteri tarafı
router.get('/', restaurantController.getAllRestaurants);
router.get('/:id/menu', restaurantController.getRestaurantMenu);
router.get('/:id/reviews', reviewController.getRestaurantReviews);

// Restoran detay (MyBusinessView load — public okuma)
router.get('/:rid', restaurantController.getRestaurantById);

// MARK: - Auth-only — yorum gönderme (giriş yapmış her kullanıcı)
router.post('/:id/reviews',
    authMiddleware, reviewController.addReview);

// MARK: - Owner-only — işletme paneli (Bearer token + owner role)
router.put('/:rid',
    authMiddleware, ownerOnly, restaurantController.updateRestaurant);

router.get('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.getOwnerMenuItems);

router.post('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.createMenuItem);

module.exports = router;
