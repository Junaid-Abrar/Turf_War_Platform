require('dotenv').config();
const mongoose = require('mongoose');
const app = require('./app');
const logger = require('./config/logger');

const PORT = process.env.PORT || 3000;

mongoose.connect(process.env.MONGO_URI)
  .then(() => {
    logger.info('Connected to MongoDB Atlas');

    app.listen(PORT, () => {
      logger.info(`Server is running on http://localhost:${PORT}`);
    });
  })
  .catch((err) => {
    logger.error({ err }, 'MongoDB connection error');
    process.exit(1);
  });
