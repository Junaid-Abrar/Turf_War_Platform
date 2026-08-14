const express = require('express');
const router = express.Router();
const {
  createBooking, getMyBookings, getVenueBookings, getOwnerBookings,
  cancelBooking, updateBookingStatus
} = require('../controllers/bookings');
const { protect, authorize } = require('../middleware/auth');
const {
  createBookingRules, updateBookingStatusRules, checkValidation
} = require('../middleware/validators');

/**
 * @openapi
 * /bookings:
 *   post:
 *     tags: [Bookings]
 *     summary: Create a booking (price is always computed server-side)
 *     security: [{ bearerAuth: [] }]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [venueId, date, startTime, endTime]
 *             properties:
 *               venueId: { type: string }
 *               date: { type: string, example: "2026-08-20" }
 *               startTime: { type: string, example: "18:00" }
 *               endTime: { type: string, example: "19:00" }
 *     responses:
 *       201: { description: Booking created }
 *       400: { description: Invalid time range or slot already booked }
 */
router.post('/', protect, createBookingRules, checkValidation, createBooking);

/**
 * @openapi
 * /bookings/my:
 *   get:
 *     tags: [Bookings]
 *     summary: List the logged-in user's bookings (paginated)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Paginated list of bookings }
 */
router.get('/my', protect, getMyBookings);

/**
 * @openapi
 * /bookings/owner:
 *   get:
 *     tags: [Bookings]
 *     summary: List bookings across venues owned by the logged-in user (paginated)
 *     security: [{ bearerAuth: [] }]
 *     responses:
 *       200: { description: Paginated list of bookings }
 */
router.get('/owner', protect, authorize('venue_owner', 'admin'), getOwnerBookings);

/**
 * @openapi
 * /bookings/venue/{venueId}:
 *   get:
 *     tags: [Bookings]
 *     summary: Get confirmed booking slots for a venue (public, no user data)
 *     parameters:
 *       - in: path
 *         name: venueId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: List of booked slots }
 */
router.get('/venue/:venueId', getVenueBookings);

/**
 * @openapi
 * /bookings/{id}/cancel:
 *   patch:
 *     tags: [Bookings]
 *     summary: Cancel a booking (by the user who made it)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200: { description: Booking cancelled }
 *       403: { description: Not authorized }
 */
router.patch('/:id/cancel', protect, cancelBooking);

/**
 * @openapi
 * /bookings/{id}/status:
 *   patch:
 *     tags: [Bookings]
 *     summary: Confirm or reject a pending booking (venue owner or admin)
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema: { type: string }
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [status]
 *             properties:
 *               status: { type: string, enum: [confirmed, cancelled] }
 *     responses:
 *       200: { description: Booking status updated }
 *       403: { description: Not authorized }
 */
router.patch(
  '/:id/status',
  protect,
  authorize('venue_owner', 'admin'),
  updateBookingStatusRules,
  checkValidation,
  updateBookingStatus
);

module.exports = router;
