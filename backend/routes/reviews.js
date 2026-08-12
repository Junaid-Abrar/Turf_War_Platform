const express = require('express');
const router = express.Router({ mergeParams: true }); // Enable access to params from parent router
const { getReviews, addReview } = require('../controllers/reviews');
const { protect } = require('../middleware/auth');
const { addReviewRules, checkValidation } = require('../middleware/validators');

/**
 * @openapi
 * /venues/{venueId}/reviews:
 *   get:
 *     tags: [Reviews]
 *     summary: List reviews for a venue
 *     parameters:
 *       - in: path
 *         name: venueId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: List of reviews }
 *   post:
 *     tags: [Reviews]
 *     summary: Add a review for a venue
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: venueId
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [rating, comment]
 *             properties:
 *               rating: { type: integer, minimum: 1, maximum: 5 }
 *               comment: { type: string }
 *     responses:
 *       201: { description: Review created }
 *       400: { description: Already reviewed or owner reviewing own venue }
 */
router.route('/')
  .get(getReviews)
  .post(protect, addReviewRules, checkValidation, addReview);

module.exports = router;
