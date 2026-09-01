const jwt = require('jsonwebtoken');
const env = require('../config/env');
const { Administrator } = require('../models/mongo');
const { AppError, asyncHandler } = require('../utils/api');
const authenticate = asyncHandler(async (req, _res, next) => {
  const bearer = req.get('authorization');
  const token = req.cookies?.admin_session || (bearer?.startsWith('Bearer ') ? bearer.slice(7) : null);
  if (!token) throw new AppError(401, 'AUTH_REQUIRED', 'Authentification requise');
  const payload = jwt.verify(token, env.jwtSecret);
  const admin = await Administrator.findById(payload.sub);
  if (!admin?.active) throw new AppError(401, 'INVALID_SESSION', 'Session invalide');
  if (admin.passwordChangedAt && payload.iat * 1000 < new Date(admin.passwordChangedAt).getTime()) throw new AppError(401, 'SESSION_EXPIRED', 'Reconnectez-vous après le changement de mot de passe');
  req.admin = admin; next();
});
const scopeEstablishment = (req, _res, next) => {
  if (req.admin.role === 'super_admin') return next();
  const requested = req.params.establishmentId || req.body.establishmentId || req.query.establishmentId;
  if (requested && !req.admin.establishmentIds.some(id => id.equals(requested))) return next(new AppError(403, 'ESTABLISHMENT_FORBIDDEN', 'Établissement non attribué'));
  next();
};
const requirePasswordChanged = (req, _res, next) => {
  if (!req.admin?.mustChangePassword) return next();
  next(new AppError(403, 'PASSWORD_CHANGE_REQUIRED', 'Vous devez modifier votre mot de passe temporaire'));
};
module.exports = { authenticate, scopeEstablishment, requirePasswordChanged };
