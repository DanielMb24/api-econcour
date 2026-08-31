const { connectMongo, disconnectMongo } = require('../config/mongodb');
const { Administrator } = require('../models/mongo');

async function migrate(){
  await connectMongo();
  const result=await Administrator.updateMany({role:{$ne:'super_admin'},passwordChangedAt:null},{$set:{mustChangePassword:true}});
  console.log(JSON.stringify({success:true,matched:result.matchedCount,modified:result.modifiedCount},null,2));
}
migrate().catch(error=>{console.error(JSON.stringify({success:false,message:error.message}));process.exitCode=1;}).finally(disconnectMongo);
