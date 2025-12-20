const Venue = require('../models/Venue');

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

        const venue = await Venue.create(req.body);

        res.status(201).json({
            success: true,
            data: venue
        });
    } catch(err) {
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
