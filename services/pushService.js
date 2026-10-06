const webpush = require('web-push');
const env = require('../config/env');
const { Notification, PushSubscription } = require('../models/mongo');

let configured = false;
const vapidPublicKey = String(process.env.VAPID_PUBLIC_KEY || '').trim();
const vapidPrivateKey = String(process.env.VAPID_PRIVATE_KEY || '').trim();
const vapidSubject = String(process.env.VAPID_SUBJECT || 'mailto:contact@gabconcours.ga').trim();
if (vapidPublicKey && vapidPrivateKey) {
  webpush.setVapidDetails(vapidSubject, vapidPublicKey, vapidPrivateKey);
  configured = true;
}

const getPublicKey = () => vapidPublicKey;
const isConfigured = () => configured;

async function saveSubscription({ candidateId, administratorId, endpoint, p256dh, auth, userAgent }) {
  if (!endpoint || !p256dh || !auth) {
    const error = new Error('Abonnement push incomplet');
    error.status = 422;
    error.code = 'INVALID_PUSH_SUBSCRIPTION';
    throw error;
  }
  return PushSubscription.findOneAndUpdate(
    { endpoint: String(endpoint) },
    { $set: { candidateId: candidateId || undefined, administratorId: administratorId || undefined, p256dh: String(p256dh), auth: String(auth), userAgent: String(userAgent || '').slice(0, 300), revokedAt: undefined } },
    { upsert: true, new: true, runValidators: true }
  );
}

async function removeSubscription({ candidateId, administratorId, endpoint }) {
  const filter = { revokedAt: null };
  if (endpoint) filter.endpoint = String(endpoint);
  else if (candidateId) filter.candidateId = candidateId;
  else if (administratorId) filter.administratorId = administratorId;
  else return null;
  if (candidateId) filter.candidateId = candidateId;
  if (administratorId) filter.administratorId = administratorId;
  return PushSubscription.updateMany(filter, { $set: { revokedAt: new Date() } });
}

async function sendToSubscriptions(subscriptions, payload) {
  if (!configured || !subscriptions.length) return { sent: 0, pruned: 0 };
  const body = JSON.stringify({ title: payload.title || 'GabConcours', body: payload.body || '', url: payload.url || '/', nupcan: payload.nupcan || '' });
  let sent = 0;
  const dead = [];
  await Promise.all(subscriptions.map(async (sub) => {
    try {
      await webpush.sendNotification({ endpoint: sub.endpoint, keys: { p256dh: sub.p256dh, auth: sub.auth } }, body);
      sent += 1;
    } catch (error) {
      if ([404, 410].includes(error.statusCode)) dead.push(sub._id);
      else console.error(JSON.stringify({ level: 'warn', code: 'PUSH_SEND_FAILED', message: error.message }));
    }
  }));
  if (dead.length) await PushSubscription.updateMany({ _id: { $in: dead } }, { $set: { revokedAt: new Date() } });
  return { sent, pruned: dead.length };
}

const sendToCandidate = (candidateId, payload) => {
  if (!candidateId) return Promise.resolve({ sent: 0, pruned: 0 });
  return PushSubscription.find({ candidateId, revokedAt: null }).lean()
    .then((subs) => sendToSubscriptions(subs, payload));
};

const sendToAdministrator = (administratorId, payload) => {
  if (!administratorId) return Promise.resolve({ sent: 0, pruned: 0 });
  return PushSubscription.find({ administratorId, revokedAt: null }).lean()
    .then((subs) => sendToSubscriptions(subs, payload));
};

// Crée la notification in-app ET pousse vers les appareils abonnés.
// N'échoue jamais l'appelant : le push est en best-effort.
async function notifyCandidate({ candidateId, applicationId, nupcan, title, body, url }) {
  const notification = await Notification.create({ candidateId, applicationId, legacyNupcan: nupcan, title, body, channel: 'in_app' });
  try {
    await sendToCandidate(candidateId, { title, body, url: url || (nupcan ? `/dashboard/candidature/${nupcan}` : '/'), nupcan });
  } catch (error) {
    console.error(JSON.stringify({ level: 'warn', code: 'PUSH_NOTIFY_FAILED', message: error.message }));
  }
  return notification;
}

module.exports = { getPublicKey, isConfigured, saveSubscription, removeSubscription, sendToCandidate, sendToAdministrator, notifyCandidate };
