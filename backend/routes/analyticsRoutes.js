// routes/analyticsRoutes.js
//   GET /api/analytics/searches — en çok aranan MenuBot sorgularını döner

const express = require('express');
const router  = express.Router();
const { authMiddleware } = require('../middleware/auth');
const { getTopSearches } = require('../controllers/analyticsController');

router.get('/searches', authMiddleware, getTopSearches);

module.exports = router;
