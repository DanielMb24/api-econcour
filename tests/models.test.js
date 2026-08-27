const test = require('node:test');
const assert = require('node:assert/strict');
const { Application, Payment } = require('../models/mongo');
test('NUPCAN possède un index unique', () => { const index=Application.schema.indexes().find(([keys])=>keys.nupcan===1); assert.equal(index[1].unique,true); });
test('une candidature est unique par candidat et concours', () => { const index=Application.schema.indexes().find(([keys])=>keys.candidateId===1&&keys.contestId===1); assert.equal(index[1].unique,true); });
test('les références de paiement sont idempotentes', () => { for(const field of ['paymentReference','transactionId']) { const index=Payment.schema.indexes().find(([keys])=>keys[field]===1); assert.equal(index[1].unique,true); } });
test('les statuts de paiement couvrent le cycle complet', () => { assert.deepEqual(Payment.schema.path('status').enumValues,['pending','processing','paid','failed','cancelled','refunded']); });
