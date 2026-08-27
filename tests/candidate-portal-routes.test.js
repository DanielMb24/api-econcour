const test = require('node:test');
const assert = require('node:assert/strict');
const router = require('../routes/v1');

const registered = new Set(router.stack
  .filter(layer => layer.route)
  .map(layer => `${Object.keys(layer.route.methods)[0].toUpperCase()} ${layer.route.path}`));

test('toutes les routes du portail candidat sont centralisées dans API v1', () => {
  for (const route of [
    'GET /candidats/nipcan/:nipcan/dashboard',
    'GET /candidats/nupcan/:nupcan/nipcan',
    'GET /candidats/nupcan/:nupcan/documents',
    'GET /candidats/nupcan/:nupcan/document-checklist',
    'POST /documents',
    'PUT /documents/:id/replace',
    'DELETE /documents/:id',
    'GET /documents/:id/download',
    'GET /notifications/candidat/:nupcan',
    'GET /messages/candidat/:nupcan',
    'POST /messages/candidat',
    'GET /grades/candidat/:nupcan'
  ]) assert.ok(registered.has(route), `Route manquante: ${route}`);
});
