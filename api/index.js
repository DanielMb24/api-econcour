const { createApp } = require('../app');
const { connectMongo } = require('../config/mongodb');

const app = createApp();
let connectionPromise;

module.exports = async (req, res) => {
  try {
    connectionPromise ||= connectMongo();
    await connectionPromise;
    return app(req, res);
  } catch (error) {
    connectionPromise = undefined;
    console.error('Connexion MongoDB impossible:', error.message);
    return res.status(503).json({ success: false, data: null, message: 'Base de données indisponible', errors: [] });
  }
};
