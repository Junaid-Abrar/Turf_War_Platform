const express = require('express');
const router = express.Router();
const { getAnalytics } = require('../controllers/analytics');
const { protect, authorize } = require('../middleware/auth');

/**
 * @openapi
 * /analytics:
 *   get:
 *     tags: [Analytics]
 *     summary: Revenue and booking analytics for the logged-in owner's venues
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Aggregated analytics, including a 30-day revenue-over-time series }
 */
router.get('/', protect, authorize('venue_owner', 'admin'), getAnalytics);

module.exports = router;
