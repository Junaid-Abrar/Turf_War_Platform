const Venue = require('../models/Venue');
const cloudinary = require('cloudinary').v2;
const asyncHandler = require('../middleware/asyncHandler');
const ErrorResponse = require('../utils/ErrorResponse');
const { paginate } = require('../utils/paginate');
const { venueScopeFilter } = require('../utils/scopeVenues');

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

// @desc    Get all venues (paginated)
// @route   GET /api/venues
// @access  Public
exports.getVenues = asyncHandler(async (req, res) => {
  const { data, page, limit, total, totalPages } = await paginate(Venue, {}, req.query, {
    defaultSort: '-createdAt'
  });

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

// @desc    Get a single venue
// @route   GET /api/venues/:id
// @access  Public
exports.getVenue = asyncHandler(async (req, res, next) => {
  const venue = await Venue.findById(req.params.id);

  if (!venue) {
    return next(new ErrorResponse('Venue not found', 404));
  }

  res.status(200).json({ success: true, data: venue });
});

// @desc    Update a venue
// @route   PUT /api/venues/:id
// @access  Private (owner or admin)
exports.updateVenue = asyncHandler(async (req, res, next) => {
  let venue = await Venue.findById(req.params.id);

  if (!venue) {
    return next(new ErrorResponse('Venue not found', 404));
  }

  if (venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to update this venue', 403));
  }

  // Only allow updating these fields — owner and images/amenities are managed separately
  const allowedFields = ['name', 'description', 'location', 'pricePerHour', 'amenities'];
  const updates = {};
  for (const field of allowedFields) {
    if (req.body[field] !== undefined) {
      updates[field] = req.body[field];
    }
  }

  venue = await Venue.findByIdAndUpdate(req.params.id, updates, {
    new: true,
    runValidators: true
  });

  res.status(200).json({ success: true, data: venue });
});

// @desc    Get venues — all venues for admin, own venues for owner
// @route   GET /api/venues/mine
// @access  Private (venue_owner, admin)
exports.getMyVenues = asyncHandler(async (req, res) => {
  const venues = await Venue.find(venueScopeFilter(req.user)).populate('owner', 'name email');

  res.status(200).json({
    success: true,
    count: venues.length,
    data: venues
  });
});

// @desc    Create a venue
// @route   POST /api/venues
// @access  Private (venue_owner, admin)
exports.createVenue = asyncHandler(async (req, res) => {
  req.body.owner = req.user.id;

  // --- Image Upload Logic ---
  let imageUrls = [];

  if (req.files && req.files.photo) {
    const file = req.files.photo; // 'photo' is the key we'll use in Postman/Flutter

    const result = await cloudinary.uploader.upload(file.tempFilePath, {
      folder: 'turf-war-venues'
    });

    imageUrls.push(result.secure_url);
  }

  if (req.body.images) {
    if (Array.isArray(req.body.images)) {
      imageUrls = [...imageUrls, ...req.body.images];
    } else {
      imageUrls.push(req.body.images);
    }
  }

  req.body.images = imageUrls;

  // --- Amenities Parsing ---
  // Mobile sends amenities as a JSON string; web sends as an array
  if (req.body.amenities) {
    if (typeof req.body.amenities === 'string') {
      try {
        req.body.amenities = JSON.parse(req.body.amenities);
      } catch (_e) {
        req.body.amenities = [req.body.amenities];
      }
    }
  } else {
    req.body.amenities = [];
  }

  const venue = await Venue.create(req.body);

  res.status(201).json({
    success: true,
    data: venue
  });
});

// @desc    Delete a venue
// @route   DELETE /api/venues/:id
// @access  Private (owner or admin)
exports.deleteVenue = asyncHandler(async (req, res, next) => {
  const venue = await Venue.findById(req.params.id);

  if (!venue) {
    return next(new ErrorResponse('Venue not found', 404));
  }

  if (venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
    return next(new ErrorResponse('Not authorized to delete this venue', 403));
  }

  await venue.deleteOne();

  res.status(200).json({ success: true, data: {} });
});

// @desc    Search venues with filters
// @route   GET /api/venues/search
// @access  Public
exports.searchVenues = asyncHandler(async (req, res) => {
  const { query, minPrice, maxPrice, amenities } = req.query;

  let dbQuery = {};

  // 1. Text Search (Name or Location)
  if (query) {
    dbQuery.$or = [
      { name: { $regex: query, $options: 'i' } },
      { location: { $regex: query, $options: 'i' } }
    ];
  }

  // 2. Price Range
  if (minPrice || maxPrice) {
    dbQuery.pricePerHour = {};
    if (minPrice) dbQuery.pricePerHour.$gte = Number(minPrice);
    if (maxPrice) dbQuery.pricePerHour.$lte = Number(maxPrice);
  }

  // 3. Amenities Filter
  if (amenities) {
    // Expecting amenities as comma-separated string: "Wifi,Parking"
    const amenitiesList = amenities.split(',').map((a) => a.trim());
    dbQuery.amenities = { $all: amenitiesList };
  }

  const { data, page, limit, total, totalPages } = await paginate(Venue, dbQuery, req.query, {
    defaultSort: '-createdAt'
  });

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
