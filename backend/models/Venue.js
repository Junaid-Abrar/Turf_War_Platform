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
    default: []
  },
  owner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  averageRating: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Cascade: remove bookings and reviews when their venue is deleted
venueSchema.pre('deleteOne', { document: true, query: false }, async function () {
  await Promise.all([
    this.model('Booking').deleteMany({ venue: this._id }),
    this.model('Review').deleteMany({ venue: this._id })
  ]);
});

module.exports = mongoose.model('Venue', venueSchema);
