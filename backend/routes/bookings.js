const express = require('express');
const router = express.Router();
const {
  createBooking, getMyBookings, getVenueBookings, getOwnerBookings,
  cancelBooking, updateBookingStatus
} = require('../controllers/bookings');
const { protect } = require('../middleware/auth');

router.post('/', protect, createBooking);
router.get('/my', protect, getMyBookings);
router.get('/owner', protect, getOwnerBookings);
router.get('/venue/:venueId', getVenueBookings);
router.patch('/:id/cancel', protect, cancelBooking);
router.patch('/:id/status', protect, updateBookingStatus);

module.exports = router;
