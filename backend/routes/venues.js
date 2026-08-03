const express = require('express');
const router = express.Router();
const {
    getVenues, createVenue, deleteVenue, searchVenues
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

router.route('/:id')
    .delete(protect, authorize('venue_owner', 'admin'), deleteVenue);

module.exports = router;