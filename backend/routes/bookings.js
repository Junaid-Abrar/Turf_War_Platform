const express = require('express');
const router = express.Router();
const { createBooking, getMyBookings, getVenueBookings } = require('../controllers/bookings');
const { protect } = require('../middleware/auth');

router.post('/', protect, createBooking);
router.get('/my', protect, getMyBookings);
router.get('/venue/:venueId', getVenueBookings);

module.exports = router;
