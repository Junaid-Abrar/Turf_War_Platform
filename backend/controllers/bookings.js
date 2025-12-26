const Booking = require('../models/Booking');
const Venue = require('../models/Venue');
const User = require('../models/User'); // Import User
const { sendNotification } = require('../config/firebase'); // Import Notification utility

// @desc    Create a booking
// @route   POST /api/bookings
// @access  Private
exports.createBooking = async (req, res) => {
  try {
    const { venueId, date, startTime, endTime, price } = req.body;

    // 1. Check if venue exists
    const venue = await Venue.findById(venueId).populate('owner');
    if (!venue) {
      return res.status(404).json({ success: false, error: 'Venue not found' });
    }

    // 2. Check for conflicts (Is slot already taken?)
    const existingBooking = await Booking.findOne({
      venue: venueId,
      date: date,
      startTime: startTime,
      status: 'confirmed'
    });

    if (existingBooking) {
      return res.status(400).json({ success: false, error: 'Slot already booked' });
    }

    // 3. Create Booking
    const booking = await Booking.create({
      user: req.user.id,
      venue: venueId,
      date,
      startTime,
      endTime,
      price
    });

    // 4. Send Notifications (Don't wait for them to finish)
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
