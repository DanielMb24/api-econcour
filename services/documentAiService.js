const axios = require('axios');
const { randomUUID } = require('crypto');
const eligibleForAnalysis = () => ({ status: 'uploaded', $or: [
  { aiStatus: { $in: ['pending', 'disabled', 'failed', null] } },
  { aiStatus: 'running', aiStartedAt: { $lt: new Date(Date.now() - 5 * 60 * 1000) } },
  { aiStatus: 'running', aiStartedAt: { $exists: false }, updatedAt: { $lt: new Date(Date.now() - 5 * 60 * 1000) } }
] });
const env = require('../config/env');
const { ApplicationDocument, DocumentRequirement, Application, Administrator, Notification } = require('../models/mongo');

const parseDataUrl = value => {
  const match = /^data:([^;]+);base64,(.+)$/.exec(value || '');
  return match ? { mimeType: match[1], base64: match[2] } : null;
};

const extractJson = content => JSON.parse(String(content || '').trim().replace(/^```json\s*/i, '').replace(/```$/i, '').trim());

const buildPrompt = (document, requirement) => `Tu es un assistant de pre-verification documentaire. Analyse uniquement le fichier fourni. Ne prends jamais la decision administrative finale sans regle explicite. Retourne exclusivement un JSON valide avec les cles recommendation (approve, reject ou review), confidence (nombre entre 0 et 1) et reason (phrase courte en francais). Type : "${document.type}". Description : "${requirement?.description || 'Aucune'}". Consignes de validation : "${requirement?.validationInstructions || 'Verifier la lisibilite, le type et les informations attendues.'}". Regles de rejet : "${requirement?.rejectionInstructions || 'Rejeter si le document est illisible, incomplet, du mauvais type ou non conforme.'}". En cas de doute, choisis review.`;

async function analyzeDocument(documentId) {
  if (!env.geminiApiKey) {
    await ApplicationDocument.findByIdAndUpdate(documentId, { $set: { aiStatus: 'disabled', aiError: 'GEMINI_API_KEY non configuree' } });
    return;
  }
  const aiRunToken = randomUUID();
  const document = await ApplicationDocument.findOneAndUpdate(
    { _id: documentId, ...eligibleForAnalysis() },
    { $set: { aiStatus: 'running', aiRunToken, aiStartedAt: new Date() }, $unset: { aiError: 1 } },
    { new: true }
  ).lean();
  if (!document) return { skipped: true };
  const ownership = { _id: documentId, aiRunToken, aiStatus: 'running', status: 'uploaded' };
  try {
    const [requirement, application] = await Promise.all([
      document.requirementId ? DocumentRequirement.findById(document.requirementId).lean() : null,
      Application.findById(document.applicationId).populate('contestId').lean()
    ]);
    const data = parseDataUrl(document.contentData);
    if (!data) throw new Error('Contenu du document indisponible');

    const response = await axios.post(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(env.geminiModel)}:generateContent`, {
      contents: [{ role: 'user', parts: [
        { text: buildPrompt(document, requirement) },
        { inlineData: { mimeType: data.mimeType, data: data.base64 } }
      ] }],
      generationConfig: {
        temperature: 0,
        responseMimeType: 'application/json',
        responseSchema: {
          type: 'OBJECT',
          properties: {
            recommendation: { type: 'STRING', enum: ['approve', 'reject', 'review'] },
            confidence: { type: 'NUMBER' },
            reason: { type: 'STRING' }
          },
          required: ['recommendation', 'confidence', 'reason']
        }
      }
    }, { headers: { 'x-goog-api-key': env.geminiApiKey, 'Content-Type': 'application/json' }, timeout: 60000 });
    const candidate = response.data?.candidates?.[0];
    if (candidate?.finishReason !== 'STOP') throw new Error('Gemini : analyse bloquee ou incomplete');
    const content = candidate.content?.parts?.filter(part => !part.thought).map(part => part.text || '').join('');
    if (!content) throw new Error('Gemini : reponse vide');
    const result = extractJson(content);
    if (!result || !['approve', 'reject', 'review'].includes(result.recommendation)
      || typeof result.confidence !== 'number' || !Number.isFinite(result.confidence)
      || result.confidence < 0 || result.confidence > 1
      || typeof result.reason !== 'string' || !result.reason.trim()) {
      throw new Error('Gemini : resultat documentaire invalide');
    }
    const recommendation = ['approve', 'reject', 'review'].includes(result.recommendation) ? result.recommendation : 'review';
    const confidence = Math.min(1, Math.max(0, Number(result.confidence) || 0));
    const reason = String(result.reason || 'Verification administrative requise').slice(0, 500);
    const status = recommendation === 'approve' ? 'approved' : recommendation === 'reject' ? 'rejected' : 'uploaded';
    const saved = await ApplicationDocument.findOneAndUpdate(ownership, { $set: { aiStatus: 'completed', aiRecommendation: recommendation, aiConfidence: confidence, aiReason: reason, aiAnalyzedAt: new Date(), status, ...(status === 'rejected' ? { rejectionReason: `Rejet automatique IA : ${reason}` } : { rejectionReason: undefined }) } }, { new: true });
    if (!saved) return { skipped: true };
    if (!application) return { completed: true };
    try {
      const label = document.type || document.originalName || 'document';
      await Notification.create({ candidateId: application.candidateId, applicationId: application._id, legacyNupcan: application.nupcan, title: recommendation === 'approve' ? 'Document valide automatiquement' : recommendation === 'reject' ? 'Document rejete automatiquement' : 'Verification humaine requise', body: recommendation === 'approve' ? `Votre document « ${label} » a ete valide automatiquement.` : recommendation === 'reject' ? `Votre document « ${label} » a ete rejete automatiquement. Motif : ${reason}` : `Votre document « ${label} » a ete analyse. Une verification humaine est requise.`, channel: 'in_app' });
      const establishmentId = application.contestId?.establishmentId;
      if (establishmentId) {
        const administrators = await Administrator.find({ active: true, $and: [{ $or: [{ role: 'super_admin' }, { establishmentIds: establishmentId }] }, { $or: [{ permissions: 'view_documents' }, { permissions: 'validate_documents' }, { role: { $in: ['super_admin', 'admin', 'admin_etablissement', 'reviewer'] } }] }] }).select('_id').lean();
        if (administrators.length) await Notification.insertMany(administrators.map(admin => ({ recipientAdministratorId: admin._id, applicationId: application._id, legacyNupcan: application.nupcan, title: 'Rapport de controle IA disponible', body: `${label} : ${recommendation} (${Math.round(confidence * 100)} %). ${reason}`, channel: 'in_app' })));
      }
    } catch (notificationError) {
      console.error(JSON.stringify({ level: 'error', code: 'DOCUMENT_AI_NOTIFICATION_FAILED', documentId: String(documentId), message: notificationError.message }));
    }
  } catch (error) {
    await ApplicationDocument.findOneAndUpdate(ownership, { $set: { aiStatus: 'failed', aiError: String(error.response?.data?.error?.message || error.message).slice(0, 500), aiAnalyzedAt: new Date() } });
    throw error;
  }
}

function queueDocumentAnalysis(documentId) {
  setImmediate(() => analyzeDocument(documentId).catch(error => console.error(JSON.stringify({ level: 'error', code: 'DOCUMENT_AI_ANALYSIS_FAILED', documentId: String(documentId), message: error.message }))));
}

module.exports = { analyzeDocument, queueDocumentAnalysis, eligibleForAnalysis };
