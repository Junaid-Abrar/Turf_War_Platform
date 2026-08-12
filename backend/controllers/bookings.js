const Booking = require('../models/Booking');
const Venue = require('../models/Venue');
const User = require('../models/User'); // Import User
const { sendNotification } = require('../config/firebase'); // Import Notification utility

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
exports.createBooking = async (req, res) => {
  try {
    const { venueId, date, startTime, endTime } = req.body;

    // 1. Check if venue exists
    const venue = await Venue.findById(venueId).populate('owner');
    if (!venue) {
      return res.status(404).json({ success: false, error: 'Venue not found' });
    }

    // 2. Prevent owner from booking their own venue
    if (venue.owner._id.toString() === req.user.id) {
      return res.status(400).json({ success: false, error: 'You cannot book your own venue' });
    }

    // 3. Compute price server-side — never trust a client-supplied price
    const hours = durationHours(startTime, endTime);
    if (!hours || hours <= 0) {
      return res.status(400).json({ success: false, error: 'Invalid time range' });
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
      return res.status(400).json({ success: false, error: 'Slot already booked' });
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
    // Notify User
    User.findById(req.user.id).then(user => {
      if (user && user.fcmToken) {
        sendNotification(
          user.fcmToken,
          'Booking Confirmed!',
          `You have successfully booked ${venue.name} for ${date} at ${startTime}.`
        );
      }
    });

    // Notify Venue Owner
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

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @desc    Get logged in user's bookings
// @route   GET /api/bookings/my
// @access  Private
exports.getMyBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ user: req.user.id })
      .populate('venue', 'name location images') // Join with Venue data
      .sort({ date: -1 });

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @desc    Get bookings for venues owned by the logged-in user
// @route   GET /api/bookings/owner
// @access  Private (Owner/Admin)
exports.getOwnerBookings = async (req, res) => {
  try {
    // 1. Find venues owned by this user
    const venues = await Venue.find({ owner: req.user.id });
    
    if (!venues.length) {
      return res.status(200).json({ success: true, count: 0, data: [] });
    }

    const venueIds = venues.map(v => v._id);

    // 2. Find bookings for these venues
    const bookings = await Booking.find({ venue: { $in: venueIds } })
      .populate('user', 'name email')
      .populate('venue', 'name')
      .sort({ date: -1, startTime: -1 });

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @desc    Cancel a booking (by the user who made it)
// @route   PATCH /api/bookings/:id/cancel
// @access  Private
exports.cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id);

    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    if (booking.user.toString() !== req.user.id) {
      return res.status(403).json({ success: false, error: 'Not authorized to cancel this booking' });
    }

    if (booking.status === 'cancelled') {
      return res.status(400).json({ success: false, error: 'Booking is already cancelled' });
    }

    booking.status = 'cancelled';
    await booking.save();

    res.status(200).json({ success: true, data: booking });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @desc    Confirm or reject a pending booking (by the venue owner)
// @route   PATCH /api/bookings/:id/status
// @access  Private (venue owner or admin)
exports.updateBookingStatus = async (req, res) => {
  try {
    const { status } = req.body;
    if (!['confirmed', 'cancelled'].includes(status)) {
      return res.status(400).json({ success: false, error: "Status must be 'confirmed' or 'cancelled'" });
    }

    const booking = await Booking.findById(req.params.id).populate('venue');
    if (!booking) {
      return res.status(404).json({ success: false, error: 'Booking not found' });
    }

    const isOwner = booking.venue.owner.toString() === req.user.id;
    if (!isOwner && req.user.role !== 'admin') {
      return res.status(403).json({ success: false, error: 'Not authorized to update this booking' });
    }

    booking.status = status;
    await booking.save();

    res.status(200).json({ success: true, data: booking });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};

// @route   GET /api/bookings/venue/:venueId
// @access  Public
exports.getVenueBookings = async (req, res) => {
  try {
    const bookings = await Booking.find({ 
      venue: req.params.venueId,
      status: 'confirmed'
    }).select('date startTime endTime'); // Only return time data, not user info

    res.status(200).json({
      success: true,
      count: bookings.length,
      data: bookings
    });
  } catch (err) {
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};
