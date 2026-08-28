const { connectMongo, disconnectMongo } = require('../config/mongodb');
const { Administrator } = require('../models/mongo');

const permissionsByRole = {
  reviewer: ['view_applications', 'view_documents', 'validate_documents', 'enter_grades', 'validate_grades', 'view_payments', 'view_reports', 'manage_messages', 'manage_subadmins'],
  admin_etablissement: ['view_applications', 'manage_applications', 'view_documents', 'validate_documents', 'enter_grades', 'validate_grades', 'view_payments', 'manage_payments', 'view_reports', 'manage_messages', 'manage_subadmins'],
  finance: ['view_payments'],
  sub_admin: ['view_applications']
};

async function migrate() {
  await connectMongo();
  const updates = [];
  for (const [role, permissions] of Object.entries(permissionsByRole)) {
    const result = await Administrator.updateMany({ role, permissions: { $exists: false } }, { $set: { permissions } });
    updates.push({ role, modified: result.modifiedCount });
  }
  console.log(JSON.stringify({ success: true, updates }, null, 2));
}

migrate().catch(error => { console.error(JSON.stringify({ success: false, message: error.message })); process.exitCode = 1; }).finally(disconnectMongo);