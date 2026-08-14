const Venue = require('../models/Venue');
const Booking = require('../models/Booking');
const asyncHandler = require('../middleware/asyncHandler');

const EMPTY_ANALYTICS = {
  totalRevenue: 0,
  totalBookings: 0,
  bookingsPerVenue: [],
  recentBookings: [],
  revenueOverTime: []
};

// @desc    Get analytics — platform-wide for admin, own venues for owner
// @route   GET /api/analytics
// @access  Private (Owner/Admin)
exports.getAnalytics = asyncHandler(async (req, res) => {
  const isAdmin = req.user.role === 'admin';
  let venueMatchStage = [];

  if (!isAdmin) {
    const venues = await Venue.find({ owner: req.user.id }).select('_id');
    const venueIds = venues.map((v) => v._id);

    if (venueIds.length === 0) {
      return res.status(200).json({ success: true, data: EMPTY_ANALYTICS });
    }

    venueMatchStage = [{ $match: { venue: { $in: venueIds } } }];
  }

  const [summary] = await Booking.aggregate([
    ...venueMatchStage,
    {
      $facet: {
        totals: [
          {
            $group: {
              _id: null,
              totalBookings: { $sum: 1 },
              totalRevenue: {
                $sum: { $cond: [{ $eq: ['$status', 'confirmed'] }, '$price', 0] }
              }
            }
          }
        ],
        bookingsPerVenue: [
          { $group: { _id: '$venue', value: { $sum: 1 } } },
          {
            $lookup: {
              from: 'venues',
              localField: '_id',
              foreignField: '_id',
              as: 'venue'
            }
          },
          { $unwind: '$venue' },
          { $project: { _id: 0, name: '$venue.name', value: 1 } },
          { $sort: { value: -1 } }
        ],
        recentBookings: [
          { $sort: { createdAt: -1 } },
          { $limit: 5 },
          {
            $lookup: {
              from: 'venues',
              localField: 'venue',
              foreignField: '_id',
              as: 'venue'
            }
          },
          {
            $lookup: {
              from: 'users',
              localField: 'user',
              foreignField: '_id',
              as: 'user'
            }
          },
          { $unwind: '$venue' },
          { $unwind: '$user' },
          {
            $project: {
              date: 1,
              startTime: 1,
              endTime: 1,
              price: 1,
              status: 1,
              createdAt: 1,
              'venue._id': 1,
              'venue.name': 1,
              'user._id': 1,
              'user.name': 1
            }
          }
        ],
        // Revenue for confirmed bookings, grouped by day, over the last 30 days
        revenueOverTime: [
          {
            $match: {
              status: 'confirmed',
              createdAt: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
            }
          },
          {
            $group: {
              _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } },
              revenue: { $sum: '$price' },
              bookings: { $sum: 1 }
            }
          },
          { $sort: { _id: 1 } },
          { $project: { _id: 0, date: '$_id', revenue: 1, bookings: 1 } }
        ]
      }
    }
  ]);

  const totals = summary.totals[0] || { totalBookings: 0, totalRevenue: 0 };

  res.status(200).json({
    success: true,
    data: {
      totalRevenue: totals.totalRevenue,
      totalBookings: totals.totalBookings,
      bookingsPerVenue: summary.bookingsPerVenue,
      recentBookings: summary.recentBookings,
      revenueOverTime: summary.revenueOverTime
    }
  });
});
