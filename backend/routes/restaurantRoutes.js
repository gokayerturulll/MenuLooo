const express = require('express');
const multer  = require('multer');
const router  = express.Router();
const restaurantController = require('../controllers/restaurantController');
const menuController = require('../controllers/menuController');
const reviewController = require('../controllers/reviewController');
const { authMiddleware, ownerOnly } = require('../middleware/auth');

const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 },
});

// MARK: - Public — müşteri tarafı
router.get('/', restaurantController.getAllRestaurants);
router.get('/:id/menu', restaurantController.getRestaurantMenu);
router.get('/:id/reviews', reviewController.getRestaurantReviews);
router.get('/:id/stats', restaurantController.getRestaurantStats);

// Restoran detay (MyBusinessView load — public okuma)
router.get('/:rid', restaurantController.getRestaurantById);

// MARK: - Auth-only — yorum gönderme (giriş yapmış her kullanıcı)
router.post('/:id/reviews',
    authMiddleware, reviewController.addReview);

// İşletme sahibinin müşteri yorumuna yanıtı
router.post('/:id/reviews/:reviewId/reply',
    authMiddleware, ownerOnly, reviewController.addReply);

// MARK: - Owner-only — işletme paneli (Bearer token + owner role)
router.put('/:rid',
    authMiddleware, ownerOnly, restaurantController.updateRestaurant);

router.get('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.getOwnerMenuItems);

router.post('/:rid/menu/items',
    authMiddleware, ownerOnly, menuController.createMenuItem);

// Restoran profil görseli yükleme
router.post('/:id/images',
    authMiddleware, ownerOnly, upload.single('image'), restaurantController.uploadRestaurantImage);

module.exports = router;
