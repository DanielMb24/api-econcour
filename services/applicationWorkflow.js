const crypto = require('crypto');

const paymentAttemptAction = status => status === 'paid' || ['pending', 'processing'].includes(status)
  ? 'reuse'
  : ['failed', 'cancelled'].includes(status) ? 'retry' : 'create';

const nextApplicationStatus = ({ hasRejected, allDocumentsApproved, paymentRequired, paymentPaid, hasDocuments }) =>
  hasRejected ? 'rejected' : allDocumentsApproved && (!paymentRequired || paymentPaid) ? 'approved' : hasDocuments ? 'under_review' : 'draft';

const contestPaymentBlockReason = (contest, now = new Date()) => {
  if (!contest || contest.status !== 'open') return 'Le concours est fermé';
  if (contest.opensAt && now < new Date(contest.opensAt)) return 'Le concours n’est pas encore ouvert';
  if (contest.closesAt && now > new Date(contest.closesAt)) return 'La date limite du concours est dépassée';
  return null;
};

const verifyWebhookSignature = (rawBody, signature, secret) => {
  const normalized = String(signature || '').replace(/^sha256=/, '').toLowerCase();
  if (!secret || !/^[a-f0-9]{64}$/.test(normalized)) return false;
  const expected = crypto.createHmac('sha256', secret).update(rawBody).digest('hex');
  return crypto.timingSafeEqual(Buffer.from(normalized, 'hex'), Buffer.from(expected, 'hex'));
};

const imageDimensions = buffer => {
  if (buffer.subarray(1, 4).toString('hex') === '504e47' && buffer.length >= 24) return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20), complete: buffer.subarray(-8, -4).toString() === 'IEND' };
  if (buffer[0] === 0xff && buffer[1] === 0xd8) { let offset = 2; while (offset + 9 < buffer.length) { if (buffer[offset] !== 0xff) { offset++; continue; } const marker = buffer[offset + 1], length = buffer.readUInt16BE(offset + 2); if ([0xc0,0xc1,0xc2,0xc3,0xc5,0xc6,0xc7,0xc9,0xca,0xcb,0xcd,0xce,0xcf].includes(marker)) return { height: buffer.readUInt16BE(offset + 5), width: buffer.readUInt16BE(offset + 7), complete: buffer.at(-2) === 0xff && buffer.at(-1) === 0xd9 }; if (length < 2) break; offset += 2 + length; } }
  return null;
};

const documentReadabilityError = file => {
  const buffer = file?.buffer;
  if (!buffer || buffer.length < 100) return 'Le fichier est vide ou illisible';
  if (file.mimetype === 'application/pdf') { const head = buffer.subarray(0, 8).toString('ascii'), tail = buffer.subarray(Math.max(0, buffer.length - 2048)).toString('latin1'); return !head.startsWith('%PDF-') || !tail.includes('%%EOF') || !buffer.includes(Buffer.from('/Page')) ? 'Le PDF est corrompu ou ne contient aucune page lisible' : null; }
  const dimensions = imageDimensions(buffer);
  return !dimensions?.complete || dimensions.width < 300 || dimensions.height < 300 ? 'L’image est corrompue ou sa résolution est insuffisante (minimum 300 × 300 px)' : null;
};

module.exports = { paymentAttemptAction, nextApplicationStatus, contestPaymentBlockReason, verifyWebhookSignature, documentReadabilityError };
