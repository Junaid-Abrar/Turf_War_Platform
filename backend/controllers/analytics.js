const Booking = require('../models/Booking');
const Venue = require('../models/Venue');

// @desc    Get analytics for owner
// @route   GET /api/analytics
// @access  Private (Owner/Admin)
exports.getAnalytics = async (req, res) => {
  try {
    // 1. Find venues owned by this user
    const venues = await Venue.find({ owner: req.user.id });
    const venueIds = venues.map(v => v._id);

    if (venueIds.length === 0) {
      return res.status(200).json({
        success: true,
        data: {
          totalRevenue: 0,
          totalBookings: 0,
          bookingsPerVenue: [],
          recentBookings: []
        }
      });
    }

    // 2. Get all bookings for these venues
    const bookings = await Booking.find({ venue: { $in: venueIds } })
      .populate('venue', 'name')
      .populate('user', 'name');

    // 3. Calculate Metrics
    const totalBookings = bookings.length;
    
    const totalRevenue = bookings.reduce((acc, curr) => {
      // Only count revenue for confirmed bookings
      return (curr.status === 'confirmed') ? acc + curr.price : acc;
    }, 0);

    // 4. Bookings per Venue
    const bookingsPerVenueMap = {};
    bookings.forEach(b => {
      const vName = b.venue.name;
      if (!bookingsPerVenueMap[vName]) bookingsPerVenueMap[vName] = 0;
      bookingsPerVenueMap[vName]++;
    });

    const bookingsPerVenue = Object.keys(bookingsPerVenueMap).map(key => ({
      name: key,
      value: bookingsPerVenueMap[key]
    }));

    // 5. Recent Bookings (Last 5)
    const recentBookings = bookings
      .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
      .slice(0, 5);

    res.status(200).json({
      success: true,
      data: {
        totalRevenue,
        totalBookings,
        bookingsPerVenue,
        recentBookings
      }
    });

  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, error: 'Server Error' });
  }
};
