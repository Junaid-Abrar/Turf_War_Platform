const swaggerJsdoc = require('swagger-jsdoc');

const spec = swaggerJsdoc({
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Turf War API',
      version: '1.0.0',
      description: 'Sports-venue booking platform API — auth, venues, bookings, payments, reviews, and analytics.'
    },
    servers: [{ url: '/api', description: 'API root' }],
    components: {
      securitySchemes: {
        bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' }
      }
    }
  },
  apis: ['./routes/*.js']
});

module.exports = spec;
