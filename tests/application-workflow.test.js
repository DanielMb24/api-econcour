const test = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('crypto');
const {paymentAttemptAction,nextApplicationStatus,contestPaymentBlockReason,verifyWebhookSignature,documentReadabilityError}=require('../services/applicationWorkflow');

test('un paiement confirmé ou en cours est réutilisé, un échec est retenté',()=>{
  assert.equal(paymentAttemptAction('paid'),'reuse');
  assert.equal(paymentAttemptAction('pending'),'reuse');
  assert.equal(paymentAttemptAction('failed'),'retry');
  assert.equal(paymentAttemptAction('cancelled'),'retry');
  assert.equal(paymentAttemptAction(undefined),'create');
});

test('la validation finale exige paiement et totalité des pièces approuvées',()=>{
  assert.equal(nextApplicationStatus({hasRejected:false,allDocumentsApproved:true,paymentRequired:true,paymentPaid:true,hasDocuments:true}),'approved');
  assert.equal(nextApplicationStatus({hasRejected:false,allDocumentsApproved:true,paymentRequired:true,paymentPaid:false,hasDocuments:true}),'under_review');
  assert.equal(nextApplicationStatus({hasRejected:true,allDocumentsApproved:false,paymentRequired:true,paymentPaid:true,hasDocuments:true}),'rejected');
  assert.equal(nextApplicationStatus({hasRejected:false,allDocumentsApproved:false,paymentRequired:false,paymentPaid:true,hasDocuments:true}),'under_review');
});

test('la fenêtre de paiement respecte statut et dates du concours',()=>{
  const now=new Date('2026-08-28T12:00:00Z');
  assert.equal(contestPaymentBlockReason({status:'open',opensAt:'2026-08-01',closesAt:'2026-09-01'},now),null);
  assert.match(contestPaymentBlockReason({status:'closed'},now),/fermé/);
  assert.match(contestPaymentBlockReason({status:'open',closesAt:'2026-08-01'},now),/dépassée/);
});

test('le webhook exige une signature HMAC exacte',()=>{
  const body=Buffer.from('{"eventId":"evt-1"}'),secret='test-secret';
  const signature=crypto.createHmac('sha256',secret).update(body).digest('hex');
  assert.equal(verifyWebhookSignature(body,signature,secret),true);
  assert.equal(verifyWebhookSignature(body,'0'.repeat(64),secret),false);
});

test('le contrôle de lisibilité rejette les fichiers tronqués et accepte un PDF structuré',()=>{
  assert.match(documentReadabilityError({mimetype:'application/pdf',buffer:Buffer.from('%PDF-1.4')}),/vide|illisible/);
  const pdf=Buffer.from(`%PDF-1.4\n1 0 obj << /Type /Page >> endobj\n${'x'.repeat(120)}\n%%EOF`);
  assert.equal(documentReadabilityError({mimetype:'application/pdf',buffer:pdf}),null);
});
