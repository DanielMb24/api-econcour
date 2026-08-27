#!/usr/bin/env node
const { connectMongo, disconnectMongo } = require('../config/mongodb');
const { Candidate, Application, Counter } = require('../models/mongo');

async function migrate() {
  const applications = await Application.find({ legacyNipcan: { $exists: true, $nin: [null, ''] } }).select('candidateId legacyNipcan').lean();
  let migrated = 0;
  for (const application of applications) {
    const nipcan = String(application.legacyNipcan).trim().toUpperCase();
    const owner = await Candidate.findOne({ nipcan }).select('_id').lean();
    if (owner && String(owner._id) !== String(application.candidateId)) {
      throw new Error(`NIPCAN ${nipcan} attribué à plusieurs candidats`);
    }
    const result = await Candidate.updateOne({ _id: application.candidateId, $or: [{ nipcan: { $exists: false } }, { nipcan: null }, { nipcan: '' }] }, { $set: { nipcan } });
    migrated += result.modifiedCount;
  }
  const missing = await Candidate.countDocuments({ $or: [{ nipcan: { $exists: false } }, { nipcan: null }, { nipcan: '' }] });
  if (missing) throw new Error(`${missing} candidat(s) restent sans NIPCAN`);
  await Application.updateMany({ legacyNipcan: { $exists: true } }, { $unset: { legacyNipcan: '' } });
  const values = await Candidate.find({ nipcan: /^NIP\d{10}$/ }).select('nipcan').lean();
  for (const value of values) {
    const year = value.nipcan.slice(3, 7);
    const seq = Number(value.nipcan.slice(7));
    await Counter.updateOne({ _id: `nipcan:${year}` }, { $max: { seq } }, { upsert: true });
  }
  await Candidate.syncIndexes();
  console.log(JSON.stringify({ success: true, migrated, candidates: await Candidate.countDocuments(), applications: await Application.countDocuments() }));
}

(async()=>{try{await connectMongo();await migrate();}catch(error){console.error(error);process.exitCode=1;}finally{await disconnectMongo();}})();
