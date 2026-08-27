const mongoose = require('mongoose');
const env = require('./env');

async function connectMongo() {
  mongoose.set('strictQuery', true);
  if (mongoose.connection.readyState === 1) return mongoose.connection;
  await mongoose.connect(env.mongodbUri, { dbName: env.mongodbDbName, autoIndex: env.nodeEnv !== 'production' });
  return mongoose.connection;
}

async function disconnectMongo() { await mongoose.disconnect(); }
module.exports = { connectMongo, disconnectMongo };
