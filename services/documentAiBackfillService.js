const { Application, ApplicationDocument } = require('../models/mongo');
const { analyzeDocument, eligibleForAnalysis } = require('./documentAiService');

// One awaited analysis per HTTP request; no background work after Vercel responds.
async function processNextDocument(contestId, after, before) {
  const applicationIds = await Application.find({ contestId }).distinct('_id');
  const document = await ApplicationDocument.findOne({
    ...eligibleForAnalysis(),
    applicationId: { $in: applicationIds },
    createdAt: { $lte: before },
    ...(after ? { _id: { $gt: after } } : {})
  }).sort({ _id: 1 }).select('_id').lean();
  if (!document) return { done: true };
  try {
    const result = await analyzeDocument(document._id);
    return { done: false, cursor: String(document._id), outcome: result?.skipped ? 'skipped' : 'completed' };
  } catch (error) {
    // Stop on provider errors (quota, credentials, timeout) rather than failing the whole backlog.
    if (error.response || ['ECONNABORTED', 'ETIMEDOUT', 'ENOTFOUND', 'ECONNRESET'].includes(error.code)) throw error;
    return { done: false, cursor: String(document._id), outcome: 'failed' };
  }
}

module.exports = { processNextDocument };
