const test = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
function setup(models) {
  const handlers = {};
  const router = Object.fromEntries(['get','post'].map(method => [method, (route, ...callbacks) => {handlers[method + route] = callbacks.at(-1);} ]));
  vm.runInNewContext(fs.readFileSync(path.join(__dirname, '../routes/catalog-management.js'), 'utf8'), {module: {exports: {}}, require: name => {
    if (name === 'express') return {Router: () => router};
    if (name === '../models/mongo') return models;
    if (name.includes('mongoAuth')) return {};
    if (name.includes('utils/api')) return {asyncHandler: fn => fn, ok: (res, data) => {res.data = data;}, AppError: class extends Error {constructor(status, code, message) {super(message); this.status = status;}}};
    throw new Error(name);
  }});
  return handlers;
}
test('la lecture des matières isole le couple concours–filière', async () => {
  let scope;
  const handlers = setup({Program: {findOne: async () => ({_id: 'program'})}, Contest: {findOne: async () => ({_id: 'contest', programIds: ['program']})}, ProgramSubject: {find: query => {scope = query; return {populate: () => ({lean: async () => []})};}}});
  await handlers['get/filiere-matieres/filiere/:id']({params: {id: '1'}, query: {concours_id: '2'}}, {});
  assert.equal(scope.programId, 'program'); assert.equal(scope.contestId, 'contest');
});
test('une filière étrangère au concours est refusée avant toute écriture', async () => {
  let writes = 0;
  const handlers = setup({Program: {findOne: async () => ({_id: 'other'})}, Contest: {findOne: async () => ({_id: 'contest', programIds: ['program']})}, ProgramSubject: {updateOne: () => writes++}});
  await assert.rejects(handlers['post/filiere-matieres/filiere/:id/bulk']({params: {id: '1'}, body: {concours_id: '2', matieres: []}}, {}), /liée à ce concours/);
  assert.equal(writes, 0);
});
test('retirer toutes les matières ne touche que le concours sélectionné', async () => {
  let deletion;
  const handlers = setup({Program: {findOne: async () => ({_id: 'program'})}, Contest: {findOne: async () => ({_id: 'contest', programIds: ['program']})}, ProgramSubject: {deleteMany: async query => {deletion = query;}}});
  await handlers['post/filiere-matieres/filiere/:id/bulk']({params: {id: '1'}, body: {concours_id: '2', matieres: []}}, {});
  assert.equal(deletion.contestId, 'contest'); assert.equal(deletion.programId, 'program');
});
