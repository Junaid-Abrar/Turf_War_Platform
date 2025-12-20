const mongoose = require('mongoose');

const venueSchema = new mongoose.Schema({
    name: {
        type: String,
        required: [true, 'Please add a venue name'],
        trim:true,
        maxlength: [50, 'Name can not be more than 50 characters']
    },
    description: {
        type:String,
        required: [true, 'Please add a description'],
        maxlength: [500,'Description can not be more than 500 characters']
    },
    location: {
        type:String,
        required: [true, 'Please add a location']

    },
    pricePerHour: {
        type:Number,
        required: [true, 'Please add price per hour']
    },
    images: {
        type: [String],
        default: []
    },
    amenities: {
        type: [String],
        enum:['Parking', 'Water', 'Changing Room', 'Showers' , 'Lights', 'Lockers'],

    },

    owner: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required:true
    }
},
    {
        timestamps:true
    }
);

module.exports = mongoose.model('Venue', venueSchema);
