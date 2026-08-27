const env = require('./config/env');
async function start() {
  if (env.databaseDriver === 'mysql') { console.warn('Mode MySQL de transition'); require('./server'); return; }
  const { connectMongo } = require('./config/mongodb'); const { createApp } = require('./app');
  await connectMongo(); const server = createApp().listen(env.port, () => console.log(`GabConcours API v1 sur le port ${env.port} (MongoDB)`));
  const stop = signal => { console.log(`${signal}: arrêt en cours`); server.close(() => process.exit(0)); };
  process.on('SIGTERM', () => stop('SIGTERM')); process.on('SIGINT', () => stop('SIGINT'));
}
start().catch(error => { console.error('Démarrage impossible:', error.message); process.exit(1); });
