const mongoose = require('mongoose');
const env = require('./env');

async function connectMongo() {
  mongoose.set('strictQuery', true);
  await mongoose.connect(env.mongodbUri, { dbName: env.mongodbDbName, autoIndex: env.nodeEnv !== 'production' });
  return mongoose.connection;
}

async function disconnectMongo() { await mongoose.disconnect(); }
module.exports = { connectMongo, disconnectMongo };
