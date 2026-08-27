const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '..', '.env') });

const env = {
  nodeEnv: process.env.NODE_ENV || 'development',
  port: Number(process.env.PORT || 3001),
  databaseDriver: process.env.DATABASE_DRIVER || 'mongodb',
  mongodbUri: process.env.MONGODB_URI || process.env.AUTH_MONGODB_URI || 'mongodb://127.0.0.1:27017/gabconcours',
  mongodbDbName: process.env.MONGODB_DB_NAME || 'gabconcours',
  jwtSecret: process.env.JWT_SECRET,
  corsOrigins: [...new Set(`${process.env.CORS_ORIGINS || 'http://localhost:8001,http://localhost:5173,http://localhost:3000'},https://econcour.vercel.app`.split(',').map(v => v.trim()).filter(Boolean))],
  maxUploadBytes: Number(process.env.MAX_UPLOAD_MB || 10) * 1024 * 1024,
  storagePath: process.env.PRIVATE_STORAGE_PATH || path.join(__dirname, '..', 'storage', 'private'),
};

if (!['mysql', 'mongodb'].includes(env.databaseDriver)) throw new Error('DATABASE_DRIVER doit valoir mysql ou mongodb');
if (env.nodeEnv === 'production' && !env.jwtSecret) throw new Error('JWT_SECRET est obligatoire en production');
module.exports = env;
