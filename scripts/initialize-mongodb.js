const { connectMongo, disconnectMongo } = require('../config/mongodb');
const models = require('../models/mongo');

async function initialize() {
  const connection = await connectMongo();
  const uniqueModels = [...new Map(Object.values(models).filter(Model => Model?.modelName).map(Model => [Model.modelName, Model])).values()];
  const result = [];

  for (const Model of uniqueModels) {
    const exists = await connection.db.listCollections({ name: Model.collection.name }, { nameOnly: true }).hasNext();
    if (!exists) await Model.createCollection();
    await Model.syncIndexes();
    result.push({ model: Model.modelName, collection: Model.collection.name, created: !exists, indexes: (await Model.listIndexes()).length });
  }

  console.log(JSON.stringify({ success: true, database: connection.name, collections: result }, null, 2));
}

initialize()
  .catch(error => { console.error(JSON.stringify({ success: false, name: error.name, code: error.code, message: error.message })); process.exitCode = 1; })
  .finally(disconnectMongo);
