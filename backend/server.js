require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

const authRoutes = require('./routes/auth');

// Middleware
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);

mongoose.connect(process.env.MONGO_URI)
.then(() => {
    console.log('✅ Connected to MongoDB Atlas');

    app.listen(PORT, () => {
        console.log(`🚀 Server is running on http://localhost:${PORT}`);
    });
})
.catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
});

app.get('/', (req,res) => {
    res.send('API is running...');
});
