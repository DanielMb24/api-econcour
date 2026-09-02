const test = require('node:test');
const assert = require('node:assert/strict');
const { allowedMimeTypes } = require('../middleware/fileSignature');

test('seuls les formats documentaires attendus sont autorisés après inspection binaire', () => {
  assert.deepEqual([...allowedMimeTypes].sort(), ['application/pdf', 'image/jpeg', 'image/png', 'image/webp'].sort());
  assert.equal(allowedMimeTypes.has('text/html'), false);
  assert.equal(allowedMimeTypes.has('image/svg+xml'), false);
});
