const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../routes/v1.js'), 'utf8');
const route = source.slice(source.indexOf("router.post('/admin/ai/chat'"), source.indexOf("router.delete('/concours/:id'"));
function setup(candidate, apiError) {
  let handler, request, result, calls = 0;
  const context = {
    router: { post: (...args) => { handler = args.at(-1); } },
    authenticate: () => {}, requirePermission: () => () => {}, asyncHandler: fn => fn,
    env: { geminiApiKey: 'test', geminiModel: 'gemini-3.6-flash' },
    Contest: { findOne: () => ({ populate: () => ({ lean: async () => ({ _id: 'contest', title: 'Concours' }) }) }) },
    DocumentRequirement: { find: () => ({ sort: () => ({ lean: async () => [] }) }) },
    contestFilter: id => id, assertContestAccess: () => {},
    axios: { post: async (...args) => { calls++; request = args; if (apiError) throw apiError; return { data: { candidates: [candidate] } }; } },
    AppError: class extends Error { constructor(status, code, message) { super(message); this.status = status; } },
    ok: (_res, data) => { result = data; }, console, setTimeout: fn => fn()
  };
  vm.runInNewContext(route, context);
  return { run: () => handler({ body: { contestId: 'contest', message: 'Bonjour', history: [{ role: 'assistant', content: 'Bienvenue' }] }, admin: {} }, {}), getRequest: () => request, getCalls: () => calls, getResult: () => result };
}
test('le chat convertit les roles Gemini et restitue la reponse', async () => {
  const state = setup({ finishReason: 'STOP', content: { parts: [{ thought: true, text: 'internal' }, { text: 'Bonjour !' }] } });
  await state.run();
  assert.equal(state.getRequest()[1].contents[0].role, 'model');
  assert.equal(state.getRequest()[1].contents[1].parts[0].text, 'Bonjour');
  assert.equal(state.getRequest()[2].headers['x-goog-api-key'], 'test');
  assert.equal(state.getRequest()[2].timeout, 25000);
  assert.equal(state.getResult().answer, 'Bonjour !');
});
test('le chat signale une reponse bloquee', async () => {
  await assert.rejects(setup({ finishReason: 'SAFETY' }).run(), error => error.status === 502);
});

test('le chat retourne une erreur explicite si Gemini depasse le delai', async () => {
  const error = Object.assign(new Error('timeout'), { code: 'ECONNABORTED' });
  await assert.rejects(setup(null, error).run(), error => error.status === 504 && error.message.includes('trop de temps'));
});

test('une surcharge 503 est retentée trois fois puis expliquée en français', async () => {
 const state = setup(null, {response:{status:503}});
 await assert.rejects(state.run(), error => error.status === 503 && error.message.includes('temporairement surchargé'));
 assert.equal(state.getCalls(), 3);
});
