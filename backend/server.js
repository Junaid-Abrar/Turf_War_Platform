require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');

const app = express();
const PORT = process.env.PORT || 3000;

// Request Logger
app.use((req, res, next) => {
  console.log(`➡️  Received Request: ${req.method} ${req.url}`);
  next();
});

const authRoutes = require('./routes/auth');

// Middleware
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);

mongoose.connect(process.env.MONGO_URI)
.then(() => {
    console.log('✅ Connected to MongoDB Atlas');

    app.listen(PORT, '0.0.0.0', () => {
        console.log(`🚀 Server is running on http://0.0.0.0:${PORT}`);
    });
})
.catch((err) => {
    console.error('❌ MongoDB Connection Error:', err);
});

app.get('/', (req,res) => {
    res.send('API is running...');
});
