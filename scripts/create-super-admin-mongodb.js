const bcrypt = require('bcryptjs');
const { connectMongo, disconnectMongo } = require('../config/mongodb');
const { Administrator } = require('../models/mongo');

async function run() {
  const email = String(process.env.SUPER_ADMIN_EMAIL || '').trim().toLowerCase();
  const password = String(process.env.SUPER_ADMIN_PASSWORD || '');
  if (!/^\S+@\S+\.\S+$/.test(email)) throw new Error('SUPER_ADMIN_EMAIL invalide');
  if (password.length < 10) throw new Error('SUPER_ADMIN_PASSWORD doit contenir au moins 10 caractères');
  await connectMongo();
  const passwordHash = await bcrypt.hash(password, Number(process.env.BCRYPT_STRENGTH || 12));
  const existing = await Administrator.findOne({ email }).select('_id').lean();
  const admin = await Administrator.findOneAndUpdate(
    { email },
    { $set: { passwordHash, role: 'super_admin', active: true }, $setOnInsert: { firstName: 'Daniel', lastName: 'Administrateur', establishmentIds: [] } },
    { upsert: true, new: true, runValidators: true }
  ).lean();
  console.log(JSON.stringify({ success: true, action: existing ? 'updated' : 'created', id: String(admin._id), email: admin.email, role: admin.role, active: admin.active }));
}
run().catch(error => { console.error(JSON.stringify({ success: false, message: error.message, code: error.code })); process.exitCode = 1; }).finally(disconnectMongo);
