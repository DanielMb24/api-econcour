const { connectMongo, disconnectMongo } = require('../config/mongodb');
const models = require('../models/mongo');

(async () => {
  const connection = await connectMongo();
  const entries = [];
  for (const Model of [...new Map(Object.values(models).filter(Model => Model?.modelName).map(Model => [Model.modelName, Model])).values()]) {
    const indexes = await Model.listIndexes();
    entries.push({ collection: Model.collection.name, documents: await Model.estimatedDocumentCount(), uniqueIndexes: indexes.filter(index => index.unique).map(index => Object.keys(index.key).join('+')) });
  }
  console.log(JSON.stringify({ success: true, database: connection.name, collections: entries }, null, 2));
})().catch(error => { console.error(JSON.stringify({ success: false, name: error.name, code: error.code, message: error.message })); process.exitCode = 1; }).finally(disconnectMongo);
