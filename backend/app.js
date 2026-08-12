const express = require('express');
const mongoose = require('mongoose');
const fileupload = require('express-fileupload');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const sanitize = require('./middleware/sanitize');
const pinoHttp = require('pino-http');
const swaggerUi = require('swagger-ui-express');

const logger = require('./config/logger');
const swaggerSpec = require('./config/swagger');
const errorHandler = require('./middleware/errorHandler');

const app = express();
app.set('trust proxy', 1);

// CORS: explicit allow-list driven by env, comma-separated. Falls back to local dev origins.
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:5173,http://localhost:3001')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

app.use(cors({
  origin(origin, callback) {
    // Allow no-origin requests (curl, mobile apps, server-to-server)
    if (!origin || allowedOrigins.includes(origin)) {
      return callback(null, true);
    }
    return callback(new Error('Not allowed by CORS'));
  }
}));

app.use(helmet());

// 1. Core Middleware (Body Parsers)
// IMPORTANT: Stripe Webhook needs the raw body for signature verification.
// We must put it BEFORE express.json()
const paymentRoutes = require('./routes/payments');
app.use('/api/payments/webhook', express.raw({ type: 'application/json' }));

app.use(express.json()); // Parse JSON body
app.use(fileupload({ useTempFiles: true })); // Parse Files
app.use(sanitize); // Strip $/. keys from req.body/query/params to block NoSQL injection

// 2. Structured request logging
app.use(pinoHttp({ logger, autoLogging: process.env.NODE_ENV !== 'test' }));

// 3. Global rate limit — lenient, just a backstop against abuse
app.use(rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300,
  standardHeaders: true,
  legacyHeaders: false
}));

// 4. Health check
app.get('/health', (req, res) => {
  const dbState = mongoose.connection.readyState; // 1 = connected
  res.status(dbState === 1 ? 200 : 503).json({
    status: dbState === 1 ? 'ok' : 'degraded',
    uptime: process.uptime(),
    db: ['disconnected', 'connected', 'connecting', 'disconnecting'][dbState] || 'unknown'
  });
});

// 5. API docs
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

// 6. Routes
const venueRoutes = require('./routes/venues');
const authRoutes = require('./routes/auth');
const bookingRoutes = require('./routes/bookings');
const analyticsRoutes = require('./routes/analytics');

app.use('/api/venues', venueRoutes);
app.use('/api/auth', authRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/analytics', analyticsRoutes);

app.get('/', (req, res) => {
  res.send('API is running...');
});

// 7. 404 + centralized error handler (must be registered last)
app.use((req, res) => {
  res.status(404).json({ success: false, error: `Route not found: ${req.method} ${req.originalUrl}` });
});
app.use(errorHandler);

module.exports = app;
