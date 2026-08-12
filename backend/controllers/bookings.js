const Booking = require('../models/Booking');
const Venue = require('../models/Venue');
const User = require('../models/User'); // Import User
const { sendNotification } = require('../config/firebase'); // Import Notification utility
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/ErrorResponse');
const { paginate } = require('../utils/paginate');

// Computes duration in hours from 'HH:MM' strings, e.g. '18:00' -> '19:30' = 1.5
function durationHours(startTime, endTime) {
  const [startH, startM] = startTime.split(':').map(Number);
  const [endH, endM] = endTime.split(':').map(Number);
  const minutes = (endH * 60 + endM) - (startH * 60 + startM);
  return minutes / 60;
}

// @desc    Create a booking
// @route   POST /api/bookings
// @access  Private
exports.createBooking = asyncHandler(async (req, res, next) => {
  const { venueId, date, startTime, endTime } = req.body;

  // 1. Check if venue exists
  const venue = await Venue.findById(venueId).populate('owner');
  if (!venue) {
    return next(new ErrorResponse('Venue not found', 404));
  }

  // 2. Prevent owner from booking their own venue
  if (venue.owner._id.toString() === req.user.id) {
    return next(new ErrorResponse('You cannot book your own venue', 400));
  }

  // 3. Compute price server-side — never trust a client-supplied price
  const hours = durationHours(startTime, endTime);
  if (!hours || hours <= 0) {
    return next(new ErrorResponse('Invalid time range', 400));
  }
  const price = Math.round(venue.pricePerHour * hours * 100) / 100;

  // 4. Check for conflicts (Is slot already taken? Block both confirmed AND pending)
  const existingBooking = await Booking.findOne({
    venue: venueId,
    date: date,
    startTime: startTime,
    status: { $in: ['confirmed', 'pending'] }
  });

  if (existingBooking) {
    return next(new ErrorResponse('Slot already booked', 400));
  }

  // 5. Create Booking
  const booking = await Booking.create({
    user: req.user.id,
    venue: venueId,
    date,
    startTime,
    endTime,
    price
  });

  // 6. Send Notifications (Don't wait for them to finish)
  User.findById(req.user.id).then((user) => {
    if (user && user.fcmToken) {
      sendNotification(
        user.fcmToken,
        'Booking Confirmed!',
        `You have successfully booked ${venue.name} for ${date} at ${startTime}.`
      );
    }
  });

  if (venue.owner && venue.owner.fcmToken) {
    sendNotification(
      venue.owner.fcmToken,
      'New Booking Received',
      `${req.user.name || 'A customer'} has booked ${venue.name} for ${date} at ${startTime}.`
    );
  }

  res.status(201).json({
    success: true,
    data: booking
  });
});

// @desc    Get logged in user's bookings
// @route   GET /api/bookings/my
// @access  Private
exports.getMyBookings = asyncHandler(async (req, res) => {
  const { data, page, limit, total, totalPages } = await paginate(
    Booking,
    { user: req.user.id },
    req.query,
    { defaultSort: '-date', populate: { path: 'venue', select: 'name location images' } }
  );

  res.status(200).json({
    success: true,
    count: data.length,
    page,
    limit,
    total,
    totalPages,
    data
  });
});

// @desc    Get bookings for venues owned by the logged-in user
// @route   GET /api/bookings/owner
// @access  Private (Owner/Admin)
exports.getOwnerBookings = asyncHandler(async (req, res) => {
  // 1. Find venues owned by this user
  const venues = await Venue.find({ owner: req.user.id });

  if (!venues.length) {
    return res.status(200).json({
      success: true, count: 0, page: 1, limit: 0, total: 0, totalPages: 1, data: []
    });
  }

  const venueIds = venues.map((v) => v._id);

  // 2. Find bookings for these venues
  const { data, page, limit, total, totalPages } = await paginate(
    Booking,
    { venue: { $in: venueIds } },
    req.query,
    {
      defaultSort: '-date -startTime',
      populate: [{ path: 'user', select: 'name email' }, { path: 'venue', select: 'name' }]
    }
  );

  res.status(200).json({
    success: true,
    count: data.length,
    page,
    limit,
    total,
    totalPages,
    data
  });
});

// @desc    Cancel a booking (by the user who made it)
// @route   PATCH /api/bookings/:id/cancel
// @access  Private
exports.cancelBooking = asyncHandler(async (req, res, next) => {
  const booking = await Booking.findById(req.params.id);

  if (!booking) {
    return next(new ErrorResponse('Booking not found', 404));
  }

  if (booking.user.toString() !== req.user.id) {
    return next(new ErrorResponse('Not authorized to cancel this booking', 403));
  }

  if (booking.status === 'cancelled') {
    return next(new ErrorResponse('Booking is already cancelled', 400));
  }

  booking.status = 'cancelled';
  await booking.save();

  res.status(200).json({ success: true, data: booking });
});

// @desc    Confirm or reject a pending booking (by the venue owner)
// @route   PATCH /api/bookings/:id/status
// @access  Private (venue owner or admin)
exports.updateBookingStatus = asyncHandler(async (req, res, next) => {
  const { status } = req.body;
  if (!['confirmed', 'cancelled'].includes(status)) {
    return next(new ErrorResponse("Status must be 'confirmed' or 'cancelled'", 400));
  }

  const booking = await Booking.findById(req.params.id).populate('venue');
  if (!booking) {
    return next(new ErrorResponse('Booking not found', 404));
  }

  const isOwner = booking.venue.owner.toString() === req.user.id;
  if (!isOwner && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this booking', 403));
  }

  booking.status = status;
  await booking.save();

  res.status(200).json({ success: true, data: booking });
});

// @route   GET /api/bookings/venue/:venueId
// @access  Public
exports.getVenueBookings = asyncHandler(async (req, res) => {
  const bookings = await Booking.find({
    venue: req.params.venueId,
    status: 'confirmed'
  }).select('date startTime endTime'); // Only return time data, not user info

  res.status(200).json({
    success: true,
    count: bookings.length,
    data: bookings
  });
});
