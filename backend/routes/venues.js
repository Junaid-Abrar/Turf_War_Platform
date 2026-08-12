const express = require('express');
const router = express.Router();
const {
    getVenues, getVenue, getMyVenues, createVenue, updateVenue, deleteVenue, searchVenues
} = require('../controllers/venues');
const {
    protect, authorize
} = require('../middleware/auth');

// Include other resource routers
const reviewRouter = require('./reviews');

// Re-route into other resource routers
router.use('/:venueId/reviews', reviewRouter);

router.route('/')
    .get(getVenues)
    .post(protect, authorize('venue_owner', 'admin'), createVenue);

router.get('/search', searchVenues);
router.get('/mine', protect, authorize('venue_owner', 'admin'), getMyVenues);

router.route('/:id')
    .get(getVenue)
    .put(protect, authorize('venue_owner', 'admin'), updateVenue)
    .delete(protect, authorize('venue_owner', 'admin'), deleteVenue);

module.exports = router;