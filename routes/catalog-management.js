const router = require('express').Router();
const { Program, Subject, Contest, Establishment, ProgramSubject, Application } = require('../models/mongo');
const { authenticate, requirePasswordChanged } = require('../middleware/mongoAuth');
const { AppError, asyncHandler, ok } = require('../utils/api');
const filter = value => /^[a-f\d]{24}$/i.test(String(value)) ? { _id: value } : { legacyId: Number(value) };
const superAdmin = (req, res, next) => req.admin.role === 'super_admin' ? next() : next(new AppError(403, 'FORBIDDEN', 'Accès réservé au superadministrateur'));
router.post('/filieres', authenticate, requirePasswordChanged, superAdmin, asyncHandler(async (req, res) => {
  const name = String(req.body.nomfil || '').trim();
  if (!name) throw new AppError(422, 'NAME_REQUIRED', 'Le nom de la filière est obligatoire');
  const establishment = req.body.etablissement_id ? await Establishment.findOne(filter(req.body.etablissement_id)) : null;
  if (req.body.etablissement_id && !establishment) throw new AppError(422, 'INVALID_ESTABLISHMENT', 'Établissement introuvable');
  const item = await Program.create({ name, establishmentIds: establishment ? [establishment._id] : [] });
  ok(res, { id: String(item._id), nomfil: item.name }, 'Filière créée', 201);
}));
router.post('/matieres', authenticate, requirePasswordChanged, superAdmin, asyncHandler(async (req, res) => {
  const name = String(req.body.nom_matiere || '').trim();
  if (!name) throw new AppError(422, 'NAME_REQUIRED', 'Le nom de la matière est obligatoire');
  const item = await Subject.create({ name, coefficient: 1 });
  ok(res, { id: String(item._id), nom_matiere: item.name }, 'Matière créée', 201);
}));
async function context(programValue, contestValue) {
  const [program, contest] = await Promise.all([Program.findOne(filter(programValue)), Contest.findOne(filter(contestValue))]);
  if (!program || !contest || !contest.programIds.some(id => String(id) === String(program._id))) throw new AppError(422, 'INVALID_SELECTION', 'Sélectionnez une filière liée à ce concours');
  return { programId: program._id, contestId: contest._id };
}
router.get('/filiere-matieres/filiere/:id', authenticate, superAdmin, asyncHandler(async (req, res, next) => {
  if (!req.query.concours_id) return next();
  const scope = await context(req.params.id, req.query.concours_id);
  const links = await ProgramSubject.find(scope).populate('subjectId').lean();
  ok(res, links.filter(l => l.subjectId).map(l => ({ id: String(l._id), matiere_id: l.subjectId.legacyId || String(l.subjectId._id), nom_matiere: l.subjectId.name, coefficient: l.coefficient, obligatoire: l.required })));
}));
router.post('/filiere-matieres/filiere/:id/bulk', authenticate, requirePasswordChanged, superAdmin, asyncHandler(async (req, res) => {
  if (!req.body.concours_id || !Array.isArray(req.body.matieres)) throw new AppError(422, 'INVALID_SELECTION', 'Concours et matières requis');
  const scope = await context(req.params.id, req.body.concours_id);
  const resolved = [];
  for (const input of req.body.matieres) {
    const subject = await Subject.findOne(filter(input.matiere_id));
    const coefficient = Number(input.coefficient);
    if (!subject || !Number.isFinite(coefficient) || coefficient <= 0) throw new AppError(422, 'INVALID_SUBJECT', 'Matière ou coefficient invalide');
    if (resolved.some(item => String(item.subjectId) === String(subject._id))) throw new AppError(422, 'DUPLICATE_SUBJECT', 'Matière en double');
    resolved.push({ ...scope, subjectId: subject._id, coefficient, required: Boolean(input.obligatoire) });
  }
  for (const item of resolved) await ProgramSubject.updateOne({ ...scope, subjectId: item.subjectId }, { $set: item }, { upsert: true, runValidators: true });
  await ProgramSubject.deleteMany({ ...scope, subjectId: { $nin: resolved.map(item => item.subjectId) } });
  ok(res, { count: resolved.length }, 'Matières du concours enregistrées');
}));
router.get('/statistics/global', authenticate, requirePasswordChanged, superAdmin, asyncHandler(async (req, res) => {
  const query = {};
  if (req.query.etablissement_id) {
    const establishment = await Establishment.findOne(filter(req.query.etablissement_id));
    if (!establishment) throw new AppError(422, 'INVALID_ESTABLISHMENT', 'Établissement introuvable');
    query.establishmentId = establishment._id;
  }
  if (req.query.concours_id) Object.assign(query, filter(req.query.concours_id));
  const contests = await Contest.find(query).populate('establishmentId').lean();
  const appQuery = { contestId: { $in: contests.map(c => c._id) } };
  if (req.query.filiere_id) {
    const program = await Program.findOne(filter(req.query.filiere_id));
    if (!program) throw new AppError(422, 'INVALID_PROGRAM', 'Filière introuvable');
    appQuery.programId = program._id;
  }
  const start = new Date();
  if (req.query.periode === 'week') start.setDate(start.getDate() - 7);
  else if (req.query.periode === 'month') start.setDate(1);
  else if (req.query.periode === 'year') start.setMonth(0, 1);
  if (['day', 'week', 'month', 'year'].includes(req.query.periode)) { start.setHours(0, 0, 0, 0); appQuery.createdAt = { $gte: start }; }
  const apps = await Application.find(appQuery).populate('programId').lean();
  const byContest = new Map(contests.map(c => [String(c._id), c]));
  const dates = {}, establishments = {}, programs = {}, statuses = {};
  const labels = { draft: 'Brouillon', submitted: 'Soumise', under_review: 'En examen', approved: 'Validée', rejected: 'Rejetée', cancelled: 'Annulée' };
  for (const app of apps) {
    const date = app.createdAt.toISOString().slice(0, 10), establishment = byContest.get(String(app.contestId))?.establishmentId?.name || 'Non renseigné', program = app.programId?.name || 'Non renseignée';
    dates[date] = (dates[date] || 0) + 1; establishments[establishment] = (establishments[establishment] || 0) + 1; programs[program] = (programs[program] || 0) + 1; statuses[app.status] = (statuses[app.status] || 0) + 1;
  }
  const decided = (statuses.approved || 0) + (statuses.rejected || 0);
  ok(res, {
    total_candidats: new Set(apps.map(a => String(a.candidateId))).size, total_candidatures: apps.length,
    total_etablissements: req.query.etablissement_id || req.query.concours_id ? new Set(contests.map(c => String(c.establishmentId?._id))).size : await Establishment.countDocuments(),
    concours_actifs: contests.filter(c => c.status === 'open' && (!c.closesAt || c.closesAt >= new Date())).length,
    taux_reussite: decided ? Math.round((statuses.approved || 0) / decided * 1000) / 10 : 0,
    evolution_inscriptions: Object.keys(dates).sort().map(date => ({ date, inscriptions: dates[date] })),
    repartition_etablissements: Object.entries(establishments).map(([nom, candidats]) => ({ nom, candidats })),
    repartition_filieres: Object.entries(programs).map(([nom, candidats]) => ({ nom, candidats })),
    statut_candidatures: Object.entries(statuses).map(([status, value]) => ({ name: labels[status] || status, value }))
  });
}));
module.exports = router;
