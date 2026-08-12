const Venue = require('../models/Venue');
const cloudinary = require('cloudinary').v2;

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET
});

exports.getVenues = async (req, res) => {
    try {
        const venues = await Venue.find();

        res.status(200).json({
            success: true,
            count: venues.length,
            data: venues
        });
    } catch(err) {
        res.status(500).json({
            success: false,  
            error: 'Server Error'
        });
    }
};

// @desc    Get a single venue
// @route   GET /api/venues/:id
// @access  Public
exports.getVenue = async (req, res) => {
    try {
        const venue = await Venue.findById(req.params.id);

        if (!venue) {
            return res.status(404).json({ success: false, error: 'Venue not found' });
        }

        res.status(200).json({ success: true, data: venue });
    } catch (err) {
        if (err.name === 'CastError') {
            return res.status(404).json({ success: false, error: 'Venue not found' });
        }
        res.status(500).json({ success: false, error: 'Server Error' });
    }
};

// @desc    Update a venue
// @route   PUT /api/venues/:id
// @access  Private (owner or admin)
exports.updateVenue = async (req, res) => {
    try {
        let venue = await Venue.findById(req.params.id);

        if (!venue) {
            return res.status(404).json({ success: false, error: 'Venue not found' });
        }

        if (venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({ success: false, error: 'Not authorized to update this venue' });
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
    } catch (err) {
        if (err.name === 'ValidationError') {
            const messages = Object.values(err.errors).map(val => val.message);
            return res.status(400).json({ success: false, error: messages });
        }
        res.status(500).json({ success: false, error: 'Server Error' });
    }
};

// @desc    Get venues owned by the logged-in user
// @route   GET /api/venues/mine
// @access  Private (venue_owner, admin)
exports.getMyVenues = async (req, res) => {
    try {
        const venues = await Venue.find({ owner: req.user.id });

        res.status(200).json({
            success: true,
            count: venues.length,
            data: venues
        });
    } catch(err) {
        res.status(500).json({
            success: false,
            error: 'Server Error'
        });
    }
};

exports.createVenue = async (req, res) => {
    try {
        req.body.owner = req.user.id;

        // --- NEW: Image Upload Logic ---
        let imageUrls = [];

        // Check if files were uploaded
        if (req.files && req.files.photo) {
            const file = req.files.photo; // 'photo' is the key we'll use in Postman/Flutter

            // Upload to Cloudinary
            const result = await cloudinary.uploader.upload(file.tempFilePath, {
                folder: 'turf-war-venues' // Folder name in Cloudinary
            });

            imageUrls.push(result.secure_url);
        }
        
        // If user provided image URLs as text (JSON), add them too
        if (req.body.images) {
             if (Array.isArray(req.body.images)) {
                 imageUrls = [...imageUrls, ...req.body.images];
             } else {
                 imageUrls.push(req.body.images);
             }
        }

        // Add final list to body
        req.body.images = imageUrls;
        // -------------------------------

        // --- Amenities Parsing ---
        // Mobile sends amenities as a JSON string; web sends as an array
        if (req.body.amenities) {
            if (typeof req.body.amenities === 'string') {
                try {
                    req.body.amenities = JSON.parse(req.body.amenities);
                } catch (e) {
                    // If it's not valid JSON, treat it as a single item
                    req.body.amenities = [req.body.amenities];
                }
            }
        } else {
            req.body.amenities = [];
        }
        // -------------------------

        const venue = await Venue.create(req.body);

        res.status(201).json({
            success: true,
            data: venue
        });
    } catch(err) {
        console.error(err);
        if( err.name === 'ValidationError') {
            const messages = Object.values(err.errors).map(val => val.message);
            return res.status(400).json({ success: false,
                error: messages
            });
        }
        res.status(500).json({
            success: false,
            error: 'Server Error'
        });
    }
};

exports.deleteVenue= async (req, res) => {
    try {
        const venue = await Venue.findById(req.params.id);

        if(!venue) {
            return res.status(404).json({
                success:false,
                error: 'Venue not found'
            });
        }

        if(venue.owner.toString() !== req.user.id && req.user.role !== 'admin') {
            return res.status(403).json({
                success: false,
                error: 'Not authorized to delete this venue'
            });
        }
        await venue.deleteOne();

        res.status(200).json({
            success: true, data: {} 
        });
        
    }
    catch(err) {
        res.status(500).json({success:false,
            error: 'Server Error'

        });
    }
};

// @desc    Search venues with filters
// @route   GET /api/venues/search
// @access  Public
exports.searchVenues = async (req, res) => {
    try {
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
            const amenitiesList = amenities.split(',').map(a => a.trim());
            dbQuery.amenities = { $all: amenitiesList };
        }

        const venues = await Venue.find(dbQuery);

        res.status(200).json({
            success: true,
            count: venues.length,
            data: venues
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ success: false, error: 'Server Error' });
    }
};
