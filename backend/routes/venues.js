const express = require('express');
const router = express.Router();
const {
    getVenues, createVenue, deleteVenue
} = require('../controllers/venues');
const {
    protect, authorize
} = require('../middleware/auth');

router.route('/')
    .get(getVenues)
    .post(protect, authorize('venue_owner', 'admin'), createVenue);

router.route('/:id')
    .delete(protect, authorize('venue_owner', 'admin'), deleteVenue);

module.exports = router;