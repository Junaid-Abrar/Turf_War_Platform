require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const fileupload = require('express-fileupload');

const app = express();
const PORT = process.env.PORT || 3000;

// 1. Core Middleware (Body Parsers)
// IMPORTANT: Stripe Webhook needs the raw body for signature verification.
// We must put it BEFORE express.json()
const paymentRoutes = require('./routes/payments');
app.use('/api/payments/webhook', express.raw({ type: 'application/json' }));

app.use(express.json()); // Parse JSON body
app.use(fileupload({ useTempFiles: true })); // Parse Files

// 2. Request Logger
app.use((req, res, next) => {
  console.log(`➡️  Received Request: ${req.method} ${req.url}`);
  if (req.body && Object.keys(req.body).length > 0 && req.url !== '/api/payments/webhook') {
    console.log('📦 Body:', JSON.stringify(req.body, null, 2));
  }
  next();
});

// 3. Routes
const venueRoutes = require('./routes/venues');
const authRoutes = require('./routes/auth');
const bookingRoutes = require('./routes/bookings');

app.use('/api/venues', venueRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);

// 4. Database Connection
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
