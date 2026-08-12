const express = require('express');
const router = express.Router();
const {
  getVenues, getVenue, getMyVenues, createVenue, updateVenue, deleteVenue, searchVenues
} = require('../controllers/venues');
const { protect, authorize } = require('../middleware/auth');
const { createVenueRules, updateVenueRules, checkValidation } = require('../middleware/validators');

// Include other resource routers
const reviewRouter = require('./reviews');

// Re-route into other resource routers
router.use('/:venueId/reviews', reviewRouter);

/**
 * @openapi
 * /venues:
 *   get:
 *     tags: [Venues]
 *     summary: List venues (paginated)
 *     parameters:
 *       - in: query
 *         name: page
 *         schema: { type: integer, default: 1 }
 *       - in: query
 *         name: limit
 *         schema: { type: integer, default: 20 }
 *       - in: query
 *         name: sort
 *         schema: { type: string, example: -createdAt }
 *     responses:
 *       200: { description: Paginated list of venues }
 *   post:
 *     tags: [Venues]
 *     summary: Create a venue (owner/admin only)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       201: { description: Venue created }
 */
router.route('/')
  .get(getVenues)
  .post(protect, authorize('venue_owner', 'admin'), createVenueRules, checkValidation, createVenue);

/**
 * @openapi
 * /venues/search:
 *   get:
 *     tags: [Venues]
 *     summary: Search venues by name/location, price range, and amenities
 *     parameters:
 *       - in: query
 *         name: query
 *         schema: { type: string }
 *       - in: query
 *         name: minPrice
 *         schema: { type: number }
 *       - in: query
 *         name: maxPrice
 *         schema: { type: number }
 *       - in: query
 *         name: amenities
 *         schema: { type: string, example: "Wifi,Parking" }
 *     responses:
 *       200: { description: Paginated list of matching venues }
 */
router.get('/search', searchVenues);

/**
 * @openapi
 * /venues/mine:
 *   get:
 *     tags: [Venues]
 *     summary: List venues owned by the logged-in user
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: List of owned venues }
 */
router.get('/mine', protect, authorize('venue_owner', 'admin'), getMyVenues);

/**
 * @openapi
 * /venues/{id}:
 *   get:
 *     tags: [Venues]
 *     summary: Get a single venue
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Venue detail }
 *       404: { description: Not found }
 *   put:
 *     tags: [Venues]
 *     summary: Update a venue (owner/admin only)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Venue updated }
 *       403: { description: Not authorized }
 *   delete:
 *     tags: [Venues]
 *     summary: Delete a venue (owner/admin only)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Venue deleted }
 */
router.route('/:id')
  .get(getVenue)
  .put(protect, authorize('venue_owner', 'admin'), updateVenueRules, checkValidation, updateVenue)
  .delete(protect, authorize('venue_owner', 'admin'), deleteVenue);

module.exports = router;
