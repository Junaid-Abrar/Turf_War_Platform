const express = require('express');
const router = express.Router();
const User = require('../models/User');


router.post('/register', async(req , res) => {
    try{

        const {name , email , password , role} = req.body;

        const user = new User({
            name,
            email,
            password,
            role,
        });

        await user.save();

        res.status(201).json({
            success: true,
            data: user
        });
    } catch(err) {
        res.status(400).json({
            success:false,
            error: err.message
        })
    }
});

module.exports = router; 