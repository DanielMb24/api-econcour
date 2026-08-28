const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const cookieParser = require('cookie-parser');
const rateLimit = require('express-rate-limit');
const env = require('./config/env');
const { correlation, notFound, errorHandler } = require('./utils/api');
function createApp() {
  const app = express(); app.disable('x-powered-by'); app.set('trust proxy', 1);
  app.use(correlation, helmet({
    crossOriginResourcePolicy: { policy: 'same-site' },
    frameguard: false,
    contentSecurityPolicy: {
      directives: {
        ...helmet.contentSecurityPolicy.getDefaultDirectives(),
        'frame-ancestors': [
          "'self'",
          'https://gabonconcours.vercel.app',
          'https://econcour.vercel.app',
        ],
      },
    },
  }));
  const allowedCorsOrigins = new Set([
    ...env.corsOrigins,
    'https://econcour.vercel.app',
    'https://gabonconcours.vercel.app',
  ]);
  const corsOptions = {
    origin(origin, cb) {
      const normalizedOrigin = origin?.replace(/\/$/, '');
      if (!normalizedOrigin || allowedCorsOrigins.has(normalizedOrigin)) return cb(null, true);
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
  app.use(express.json({ limit: '1mb', verify: (req, _res, buffer) => { req.rawBody = Buffer.from(buffer); } }), express.urlencoded({ extended: false, limit: '1mb' }), cookieParser());
  app.use('/api/v1', require('./routes/v1'));
  app.use(notFound, errorHandler); return app;
}
const serverlessApp = createApp();
let databaseConnection;
async function handler(req, res) {
  if (!databaseConnection) {
    const { connectMongo } = require('./config/mongodb');
    databaseConnection = connectMongo().catch(error => {
      databaseConnection = undefined;
      throw error;
    });
  }
  await databaseConnection;
  return serverlessApp(req, res);
}
module.exports = handler;
module.exports.createApp = createApp;
