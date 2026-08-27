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
  app.use(cors({ origin(origin, cb) { if (!origin || env.corsOrigins.includes(origin)) return cb(null, true); cb(new Error('Origine CORS refusée')); }, credentials: true }));
  app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-7', legacyHeaders: false }));
  app.use(express.json({ limit: '1mb' }), express.urlencoded({ extended: false, limit: '1mb' }), cookieParser());
  app.use('/api/v1', require('./routes/v1'));
  app.use(notFound, errorHandler); return app;
}
module.exports = { createApp };
