const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { correlation, notFound, errorHandler } = require('./utils/api');
function createApp() {
  const app = express(); app.disable('x-powered-by'); app.set('trust proxy', 1);
  app.use(correlation, helmet({ crossOriginResourcePolicy: { policy: 'same-site' } }));
  const corsOptions = {
    origin(origin, cb) {
      const normalizedOrigin = origin?.replace(/\/$/, '');
      if (!normalizedOrigin || env.corsOrigins.includes(normalizedOrigin)) return cb(null, true);
      cb(new Error('Origine CORS refusée'));
    },
    credentials: true,
    methods: ['GET', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept', 'X-Requested-With'],
    optionsSuccessStatus: 204,
  };
  app.use(cors(corsOptions));
  app.options('*', cors(corsOptions));
  app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-7', legacyHeaders: false }));
  app.use(express.json({ limit: '1mb' }), express.urlencoded({ extended: false, limit: '1mb' }), cookieParser());
  app.use('/api/v1', require('./routes/v1'));
  app.use(notFound, errorHandler); return app;
}
module.exports = { createApp };
