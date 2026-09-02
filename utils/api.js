const { randomUUID } = require('crypto');
class AppError extends Error {
  constructor(status, code, message, errors = []) { super(message); Object.assign(this, { status, code, errors }); }
}
const ok = (res, data, message = 'Opération effectuée', status = 200) => res.status(status).json({ success: true, data, message, errors: [] });
const asyncHandler = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const correlation = (req, res, next) => { req.correlationId = req.get('x-correlation-id') || randomUUID(); res.set('x-correlation-id', req.correlationId); next(); };
const notFound = (req, _res, next) => next(new AppError(404, 'ROUTE_NOT_FOUND', 'Route introuvable'));
const errorHandler = (err, req, res, _next) => {
  const status = err.status || (err.code === 11000 ? 409 : (err.name === 'ValidationError' ? 422 : 500));
  const code = err.code === 11000 ? 'DUPLICATE_VALUE' : (err.code || 'INTERNAL_ERROR');
  const duplicateField = err.keyPattern && Object.keys(err.keyPattern)[0];
  const duplicateMessages = { email: 'Cette adresse e-mail appartient déjà à un candidat', nupcan: 'Ce NIPCAN existe déjà', candidateId: 'Ce candidat est déjà inscrit à ce concours' };
  const message = err.code === 11000 ? (duplicateMessages[duplicateField] || 'Cette valeur existe déjà') : (status === 500 ? 'Une erreur interne est survenue' : err.message);
  if (status >= 500) console.error(JSON.stringify({ level: 'error', correlationId: req.correlationId, code, message: err.message }));
  res.status(status).json({ success: false, data: null, message, errors: err.errors || [], correlationId: req.correlationId });
};
module.exports = { AppError, ok, asyncHandler, correlation, notFound, errorHandler };
