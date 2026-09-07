const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

function setup({ document = { _id: 'doc1' }, error, skipped = false } = {}) {
  let query, contestQuery, calls = 0;
  const context = { module: { exports: {} }, require: name => {
    if (name === './documentAiService') return {
      eligibleForAnalysis: () => ({ status: 'uploaded' }),
      analyzeDocument: async () => { calls++; if (error) throw error; return { skipped }; }
    };
    return {
      Application: { find: filter => { contestQuery = filter; return { distinct: async () => ['app1'] }; } },
      ApplicationDocument: { findOne: filter => { query = filter; return { sort: () => ({ select: () => ({ lean: async () => document }) }) }; } }
    };
  } };
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../services/documentAiBackfillService.js'), 'utf8'), context);
  return { run: context.module.exports.processNextDocument, state: () => ({ query, contestQuery, calls }) };
}

test('limite le traitement au concours, au curseur et aux documents existants au lancement', async () => {
  const state = setup();
  const before = new Date();
  const result = await state.run('contest1', 'doc0', before);
  assert.equal(result.cursor, 'doc1');
  assert.equal(result.outcome, 'completed');
  const { query, contestQuery, calls } = state.state();
  assert.equal(contestQuery.contestId, 'contest1');
  assert.equal(query.applicationId.$in[0], 'app1');
  assert.equal(query._id.$gt, 'doc0');
  assert.equal(query.createdAt.$lte, before);
  assert.equal(calls, 1);
});
test('termine sans appel IA quand aucun document ne reste', async () => {
  const state = setup({ document: null });
  assert.equal((await state.run('contest', null, new Date())).done, true);
  assert.equal(state.state().calls, 0);
});
test('un fichier invalide avance le curseur pour ne pas bloquer les suivants', async () => {
  const result = await setup({ error: new Error('Fichier indisponible') }).run('contest', null, new Date());
  assert.equal(result.outcome, 'failed');
  assert.equal(result.cursor, 'doc1');
});
test('un quota Gemini epuise interrompt le traitement', async () => {
  const error = Object.assign(new Error('quota'), { response: { status: 429 } });
  await assert.rejects(setup({ error }).run('contest', null, new Date()), /quota/);
});
test('une reservation concurrente est ignoree', async () => {
  assert.equal((await setup({ skipped: true }).run('contest', null, new Date())).outcome, 'skipped');
});
