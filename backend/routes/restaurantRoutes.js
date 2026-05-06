const express = require('express');
const router = express.Router();
const restaurantController = require('../controllers/restaurantController');

router.get('/', restaurantController.getAllRestaurants);
router.get('/:id/menu', restaurantController.getRestaurantMenu);

module.exports = router;
