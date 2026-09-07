const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');

function setup({ key = 'test-key', mimeType = 'application/pdf', candidate, apiError } = {}) {
  const updates = [];
  const requests = [];
  const models = {
    ApplicationDocument: {
      findById: () => ({ lean: async () => ({ type: 'Diplome', contentData: `data:${mimeType};base64,dGVzdA==`, applicationId: 'application' }) }),
      findByIdAndUpdate: (id, update) => {
        updates.push(update.$set);
        return { lean: async () => ({ _id: id }) };
      }
    },
    Application: { findById: () => ({ populate: () => ({ lean: async () => null }) }) }
  };
  const context = {
    module: { exports: {} }, console, setImmediate,
    require: name => {
      if (name === '../config/env') return { geminiApiKey: key, geminiModel: 'gemini-3.6-flash' };
      if (name === '../models/mongo') return models;
      if (name === 'axios') return { post: async (...args) => {
        requests.push(args);
        if (apiError) throw apiError;
        return { data: { candidates: [candidate] } };
      } };
      throw new Error(`Unexpected dependency: ${name}`);
    }
  };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../services/documentAiService.js'), 'utf8'), context);
  return { analyze: context.module.exports.analyzeDocument, updates, requests };
}

for (const mimeType of ['application/pdf', 'image/jpeg']) {
  test(`Gemini recoit le fichier ${mimeType} et sauvegarde son analyse`, async () => {
    const state = setup({ mimeType, candidate: { finishReason: 'STOP', content: { parts: [{ text: JSON.stringify({ recommendation: 'review', confidence: 0.8, reason: 'Verification requise' }) }] } } });
    await state.analyze('document');
    const [url, body, options] = state.requests[0];
    assert.match(url, /generativelanguage\.googleapis\.com.*:generateContent$/);
    assert.equal(options.headers['x-goog-api-key'], 'test-key');
    assert.equal(body.contents[0].parts[1].inlineData.mimeType, mimeType);
    assert.equal(body.contents[0].parts[1].inlineData.data, 'dGVzdA==');
    assert.equal(state.updates.at(-1).aiStatus, 'completed');
    assert.equal(state.updates.at(-1).status, 'uploaded');
  });
}

test('sans cle Gemini aucun appel externe', async () => {
  const state = setup({ key: '' });
  await state.analyze('document');
  assert.equal(state.requests.length, 0);
  assert.equal(state.updates[0].aiStatus, 'disabled');
});

for (const candidate of [
  { finishReason: 'SAFETY' },
  { finishReason: 'MAX_TOKENS' },
  { finishReason: 'STOP', content: { parts: [] } },
  { finishReason: 'STOP', content: { parts: [{ text: 'invalid json' }] } },
  { finishReason: 'STOP', content: { parts: [{ text: '{"recommendation":"approve"}' }] } }
]) {
  test(`une reponse inutilisable ne valide pas le document (${JSON.stringify(candidate)})`, async () => {
    const state = setup({ candidate });
    await assert.rejects(state.analyze('document'));
    assert.equal(state.updates.at(-1).aiStatus, 'failed');
    assert.equal(state.updates.some(update => update.status === 'approved'), false);
  });
}

test('une erreur API est enregistree', async () => {
  const state = setup({ apiError: new Error('API unavailable') });
  await assert.rejects(state.analyze('document'), /API unavailable/);
  assert.equal(state.updates.at(-1).aiStatus, 'failed');
});
