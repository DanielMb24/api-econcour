const {connectMongo, disconnectMongo} = require('../config/mongodb');
const {Candidate} = require('../models/mongo');
(async () => {
  try {
    await connectMongo();
    // Ajout uniquement : ne supprime aucun index ni aucun profil existant.
    await Candidate.collection.createIndex({username: 1}, {unique: true, sparse: true});
    await Candidate.collection.createIndex({accountPhone: 1}, {unique: true, sparse: true});
    console.log('Index des comptes candidats créés.');
  } finally {await disconnectMongo();}
})().catch(error => {console.error(error.message); process.exitCode = 1;});
