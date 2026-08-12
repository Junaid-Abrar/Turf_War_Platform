const ErrorResponse = require('../utils/ErrorResponse');

// Centralized error handler. Controllers either throw/next() an ErrorResponse with an
// explicit statusCode, or let a raw Mongoose/driver error bubble up to be translated here.
// eslint-disable-next-line no-unused-vars -- Express requires 4 args to identify error-handling middleware
function errorHandler(err, req, res, next) {
  let error = err;

  if (req.log) {
    req.log.error({ err }, err.message);
  } else {
    console.error(err);
  }

  if (err.name === 'CastError') {
    error = new ErrorResponse(`Resource not found`, 404);
  }

  if (err.name === 'ValidationError') {
    const message = Object.values(err.errors).map((val) => val.message);
    error = new ErrorResponse(message.join(', '), 400);
  }

  if (err.code === 11000) {
    error = new ErrorResponse('Duplicate field value entered', 400);
  }

  res.status(error.statusCode || 500).json({
    success: false,
    error: error.message || 'Server Error'
  });
}

module.exports = errorHandler;
