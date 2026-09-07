const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../routes/v1.js'), 'utf8');
const route = source.slice(source.indexOf("router.post('/admin/ai/chat'"), source.indexOf("router.delete('/concours/:id'"));
function setup(candidate) {
  let handler, request, result;
  const context = {
    router: { post: (...args) => { handler = args.at(-1); } },
    authenticate: () => {}, requirePermission: () => () => {}, asyncHandler: fn => fn,
    env: { geminiApiKey: 'test', geminiModel: 'gemini-2.5-flash' },
    Contest: { findOne: () => ({ populate: () => ({ lean: async () => ({ _id: 'contest', title: 'Concours' }) }) }) },
    DocumentRequirement: { find: () => ({ sort: () => ({ lean: async () => [] }) }) },
    contestFilter: id => id, assertContestAccess: () => {},
    axios: { post: async (...args) => { request = args; return { data: { candidates: [candidate] } }; } },
    AppError: class extends Error { constructor(status, code, message) { super(message); this.status = status; } },
    ok: (_res, data) => { result = data; }, console
  };
  vm.runInNewContext(route, context);
  return { run: () => handler({ body: { contestId: 'contest', message: 'Bonjour', history: [{ role: 'assistant', content: 'Bienvenue' }] }, admin: {} }, {}), getRequest: () => request, getResult: () => result };
}
test('le chat convertit les roles Gemini et restitue la reponse', async () => {
  const state = setup({ finishReason: 'STOP', content: { parts: [{ thought: true, text: 'internal' }, { text: 'Bonjour !' }] } });
  await state.run();
  assert.equal(state.getRequest()[1].contents[0].role, 'model');
  assert.equal(state.getRequest()[1].contents[1].parts[0].text, 'Bonjour');
  assert.equal(state.getRequest()[2].headers['x-goog-api-key'], 'test');
  assert.equal(state.getResult().answer, 'Bonjour !');
});
test('le chat signale une reponse bloquee', async () => {
  await assert.rejects(setup({ finishReason: 'SAFETY' }).run(), error => error.status === 502);
});
