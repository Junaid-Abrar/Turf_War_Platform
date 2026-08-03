const express = require('express');
const router = express.Router();
const { getAnalytics } = require('../controllers/analytics');
const { protect, authorize } = require('../middleware/auth');

router.get('/', protect, authorize('venue_owner', 'admin'), getAnalytics);

module.exports = router;
