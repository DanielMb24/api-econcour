const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const rateLimit = require('express-rate-limit');
const router = require('express').Router();
const {Candidate, Session, VerificationCode} = require('../models/mongo');
const {nextNipcan} = require('../services/applicationService');
const emailService = require('../services/emailService');
const {AppError, asyncHandler, ok} = require('../utils/api');
const hash = value => crypto.createHash('sha256').update(String(value)).digest('hex');
const normalizePhone = value => String(value || '').replace(/[\s().-]/g, '').replace(/^00/, '+');
const limiter = rateLimit({windowMs: 15 * 60 * 1000, limit: 15, standardHeaders: 'draft-7', legacyHeaders: false});
async function authenticateCandidate(req, res, next) {
  try {
    const token = req.headers['x-candidate-token'];
    const session = token && await Session.findOne({tokenHash: hash(token), actorType: 'candidate', revokedAt: null, expiresAt: {$gt: new Date()}});
    const candidate = session && await Candidate.findById(session.candidateId);
    if (!candidate) throw new AppError(401, 'CANDIDATE_LOGIN_REQUIRED', 'Connectez-vous à votre compte candidat');
    req.candidate = candidate; req.candidateSession = session; next();
  } catch (error) {next(error);}
}
async function sessionResponse(res, candidate) {
  const token = crypto.randomBytes(32).toString('hex');
  await Session.create({candidateId: candidate._id, actorType: 'candidate', tokenHash: hash(token), expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)});
  ok(res, {token, nipcan: candidate.nipcan, prenom: candidate.firstName, nom: candidate.lastName}, 'Connexion réussie');
}
router.post('/candidate-auth/code', limiter, asyncHandler(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new AppError(422, 'INVALID_EMAIL', 'Adresse email invalide');
  const code = String(crypto.randomInt(100000, 1000000));
  await VerificationCode.updateMany({purpose: 'email_verification', destinationHash: hash(email), consumedAt: null}, {$set: {consumedAt: new Date()}});
  const verification = await VerificationCode.create({purpose: 'email_verification', destinationHash: hash(email), codeHash: hash(code), expiresAt: new Date(Date.now() + 10 * 60 * 1000)});
  try {await emailService.sendEmail(email, 'Votre code GabConcours', `<p>Votre code de vérification est <strong>${code}</strong>. Il expire dans 10 minutes.</p>`);}
  catch (error) {await verification.deleteOne(); throw new AppError(503, 'EMAIL_UNAVAILABLE', 'Impossible d’envoyer le code. Réessayez plus tard.');}
  ok(res, {verificationId: String(verification._id)}, 'Code envoyé par email');
}));
router.post('/candidate-auth/register', limiter, asyncHandler(async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase(), username = String(req.body.username || '').trim().toLowerCase(), phone = normalizePhone(req.body.phone), password = String(req.body.password || '');
  if (!/^[a-z][a-z0-9_.-]{2,39}$/.test(username) || !/^\+?\d{8,15}$/.test(phone) || password.length < 10 || Buffer.byteLength(password) > 72) throw new AppError(422, 'INVALID_ACCOUNT', 'Identifiant : 3 à 40 caractères commençant par une lettre. Téléphone : 8 à 15 chiffres. Mot de passe : 10 caractères minimum, 72 octets maximum.');
  if (!String(req.body.firstName || '').trim() || !String(req.body.lastName || '').trim()) throw new AppError(422, 'NAME_REQUIRED', 'Nom et prénom requis');
  if (!/^[a-f\d]{24}$/i.test(String(req.body.verificationId))) throw new AppError(422, 'INVALID_CODE', 'Demandez un code par email');
  const verification = await VerificationCode.findOneAndUpdate({_id: req.body.verificationId, destinationHash: hash(email), purpose: 'email_verification', consumedAt: null, attempts: {$lt: 5}, expiresAt: {$gt: new Date()}}, {$inc: {attempts: 1}}, {new: true}).select('+codeHash');
  if (!verification || verification.codeHash !== hash(req.body.code)) throw new AppError(422, 'INVALID_CODE', 'Code invalide ou expiré');
  const candidate = await Candidate.findOne({email}).select('+passwordHash');
  if (req.body.nipcan && candidate?.nipcan !== String(req.body.nipcan).trim().toUpperCase()) throw new AppError(422, 'NIPCAN_MISMATCH', 'Utilisez l’adresse email associée à votre NIPCAN');
  const duplicate = await Candidate.exists({$or: [{username}, {accountPhone: phone}], ...(candidate ? {_id: {$ne: candidate._id}} : {})});
  if (duplicate) throw new AppError(409, 'ACCOUNT_EXISTS', 'Ce téléphone ou cet identifiant est déjà utilisé');
  const consumed = await VerificationCode.updateOne({_id: verification._id, consumedAt: null}, {$set: {consumedAt: new Date()}});
  if (!consumed.modifiedCount) throw new AppError(422, 'INVALID_CODE', 'Ce code a déjà été utilisé');
  const passwordHash = await bcrypt.hash(password, 12);
  let account;
  try {
    if (candidate) {
      // La preuve de possession de l’email permet également de réinitialiser le mot de passe.
      candidate.username = username; candidate.accountPhone = phone; candidate.phone = phone; candidate.passwordHash = passwordHash;
      if (!candidate.nipcan) candidate.nipcan = await nextNipcan();
      account = await candidate.save();
      await Session.updateMany({candidateId: account._id, actorType: 'candidate', revokedAt: null}, {$set: {revokedAt: new Date()}});
    } else account = await Candidate.create({email, username, phone, accountPhone: phone, passwordHash, firstName: String(req.body.firstName).trim(), lastName: String(req.body.lastName).trim(), nipcan: await nextNipcan()});
  } catch (error) {if(error.code === 11000) throw new AppError(409, 'ACCOUNT_EXISTS', 'Ce compte existe déjà. Connectez-vous.'); throw error;}
  await sessionResponse(res, account);
}));
router.post('/candidate-auth/login', limiter, asyncHandler(async (req, res) => {
  const identifier = String(req.body.identifier || '').trim().toLowerCase();
  const candidate = await Candidate.findOne({$or: [{email: identifier}, {username: identifier}, {accountPhone: normalizePhone(identifier)}]}).select('+passwordHash');
  if (!candidate?.passwordHash || !await bcrypt.compare(String(req.body.password || ''), candidate.passwordHash)) throw new AppError(401, 'INVALID_CREDENTIALS', 'Identifiant ou mot de passe incorrect');
  await sessionResponse(res, candidate);
}));
router.get('/candidate-auth/me', authenticateCandidate, (req, res) => ok(res, {nipcan: req.candidate.nipcan}));
router.post('/candidate-auth/logout', authenticateCandidate, asyncHandler(async (req, res) => {req.candidateSession.revokedAt = new Date(); await req.candidateSession.save(); ok(res, null, 'Déconnexion effectuée');}));
module.exports = {router, authenticateCandidate, normalizePhone};
