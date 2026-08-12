require('dotenv').config(); // Safety net
const express = require('express');
const router = express.Router();
const User = require('../models/User');

const { protect, authorize } = require('../middleware/auth');


router.post('/register', async(req , res) => {
    try{

        const {name , email , password} = req.body;

        const user = new User({
            name,
            email,
            password,
            role: 'user', // Force all new registrations to 'user' role
        });

        await user.save();

        res.status(201).json({
            success: true,
            data: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            }
        });
    } catch(err) {
        res.status(400).json({
            success:false,
            error: err.message
        })
    }
});

const jwt = require('jsonwebtoken');

// @route   POST /api/auth/login
// @desc    Login user
// @access  Public
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    // 1. Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({ success: false, error: 'Please provide email and password' });
    }

    // 2. Check for user (and explicitly include password because we set select: false)
    const user = await User.findOne({ email }).select('+password');

    if (!user) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    // 3. Check if password matches
    const isMatch = await user.matchPassword(password);

    if (!isMatch) {
      return res.status(401).json({ success: false, error: 'Invalid credentials' });
    }

    // 4. Create Token
    const token = jwt.sign(
      { 
        id: user._id, 
        role: user.role, 
        name: user.name, 
        email: user.email 
      }, 
      process.env.JWT_SECRET, 
      {
        expiresIn: process.env.JWT_EXPIRE
      }
    );

    res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role
      }
    });

  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// ... (imports remain the same)
// @route   GET /api/auth/me
// @desc    Get current logged in user
// @access  Private
router.get('/me', protect, async (req, res) => {
  res.status(200).json({
    success: true,
    data: req.user
  });
});

// @route   PUT /api/auth/fcm-token

// @desc    Update FCM Token for notifications

// @access  Private

router.put('/fcm-token', protect, async (req, res) => {

  try {

    const { fcmToken } = req.body;

    

    await User.findByIdAndUpdate(req.user.id, { fcmToken });



    res.status(200).json({

      success: true,

      message: 'FCM Token updated'

    });

  } catch (err) {

    res.status(500).json({ success: false, error: err.message });

  }

});



// @route   GET /api/auth/users
// @desc    Get all users (Admin only)
// @access  Private/Admin
router.get('/users', protect, authorize('admin'), async (req, res) => {
  try {
    const users = await User.find().select('-password').sort('-createdAt');
    res.status(200).json({ success: true, count: users.length, data: users });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// @route   PUT /api/auth/users/:id/role
// @desc    Update user role (Admin only)
// @access  Private/Admin
router.put('/users/:id/role', protect, authorize('admin'), async (req, res) => {
  try {
    const { role } = req.body;
    
    if (!['user', 'venue_owner', 'admin'].includes(role)) {
      return res.status(400).json({ success: false, error: 'Invalid role' });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, error: 'User not found' });
    }

    res.status(200).json({ success: true, data: user });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

module.exports = router; 

 