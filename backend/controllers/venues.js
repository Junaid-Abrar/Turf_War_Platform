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
