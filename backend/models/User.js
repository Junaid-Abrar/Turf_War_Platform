const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Please add a name']
  },
  email: {
    type: String,
    required: [true, 'Please add an email'],
    unique: true,
    match: [
        /^\w+([\.-]?\w+)*@\w+([\.-]?\w+)*(\.\w{2,3})+$/,
        'Please add a valid email'
    ]
  },
  password: {
    type: String,
    required: [true, 'Please add a password'],
    minlength: 6,
    select: false
    
  },
  role: {
    type: String,
    enum: ['user', 'admin', 'venue_owner'],
    default: 'user'
  }
}, {
  timestamps: true // Automatically creates 'createdAt' and 'updatedAt' fields
});

// REMOVE 'next' - Mongoose supports pure async/await
userSchema.pre('save', async function() {
    if(!this.isModified('password')) {
        return;
    }
    
    // Hash password
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
});

userSchema.methods.matchPassword = async function(
    enteredpassword
) {
    return await bcrypt.compare(enteredpassword, this.password);
};


module.exports = mongoose.model('User', userSchema);