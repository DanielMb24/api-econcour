const { Candidate, Contest, Program, Application, Counter } = require('../models/mongo');
const { AppError } = require('../utils/api');
async function nextNupcan(now = new Date()) {
  const year = now.getUTCFullYear();
  const counter = await Counter.findByIdAndUpdate(`nupcan:${year}`, { $inc: { seq: 1 } }, { new: true, upsert: true, setDefaultsOnInsert: true });
  return `GC-${year}-${String(counter.seq).padStart(7, '0')}`;
}
async function nextNipcan(now = new Date()) {
  const year = now.getUTCFullYear();
  const counter = await Counter.findByIdAndUpdate(`nipcan:${year}`, { $inc: { seq: 1 } }, { new: true, upsert: true, setDefaultsOnInsert: true });
  return `NIP${year}${String(counter.seq).padStart(6, '0')}`;
}
async function createApplication(input) {
  const [contest, program] = await Promise.all([Contest.findById(input.contestId), Program.findById(input.programId)]);
  if (!contest || !program) throw new AppError(404, 'SELECTION_NOT_FOUND', 'Concours ou filière introuvable');
  if (contest.status !== 'open') throw new AppError(409, 'CONTEST_NOT_OPEN', "Ce concours n'accepte pas de candidature");
  if (contest.closesAt && contest.closesAt < new Date()) throw new AppError(409, 'CONTEST_CLOSED', 'Les inscriptions à ce concours sont clôturées');
  if (contest.opensAt && contest.opensAt > new Date()) throw new AppError(409, 'CONTEST_NOT_STARTED', "Les inscriptions à ce concours ne sont pas encore ouvertes");
  if (contest.programIds?.length && !contest.programIds.some(id => id.equals(program._id))) throw new AppError(422, 'PROGRAM_NOT_AVAILABLE', 'Cette filière ne fait pas partie du concours');
  const email = input.candidate?.email?.trim().toLowerCase() || undefined;
  if (!input.candidateId && email && await Candidate.exists({ email })) throw new AppError(409, 'CANDIDATE_EMAIL_ALREADY_EXISTS', 'Cette adresse e-mail appartient déjà à un candidat. Utilisez son NIPCAN pour une nouvelle candidature.');
  const candidate = input.candidateId
    ? await Candidate.findById(input.candidateId)
    : await Candidate.create({ ...input.candidate, email, nipcan: input.candidate?.nipcan || await nextNipcan() });
  if (!candidate) throw new AppError(404, 'CANDIDATE_NOT_FOUND', 'Candidat introuvable');
  const existingApplication = await Application.findOne({ candidateId: candidate._id, contestId: contest._id }).select('nupcan').lean();
  if (existingApplication) throw new AppError(409, 'APPLICATION_ALREADY_EXISTS', `Ce candidat est déjà inscrit à ce concours (${existingApplication.nupcan})`);
  try {
    return await Application.create({ candidateId: candidate._id, contestId: contest._id, programId: program._id, nupcan: await nextNupcan(), completedSteps: ['candidate'], contestSnapshot: { title: contest.title, fee: contest.fee, currency: contest.currency, programName: program.name }, statusHistory: [{ status: 'draft' }] });
  } catch (error) {
    if (error.code === 11000 && !input.candidateId) await Candidate.deleteOne({ _id: candidate._id });
    if (error.code === 11000 && error.keyPattern?.email) throw new AppError(409, 'CANDIDATE_EMAIL_ALREADY_EXISTS', 'Cette adresse e-mail appartient déjà à un candidat.');
    if (error.code === 11000) throw new AppError(409, 'APPLICATION_ALREADY_EXISTS', 'Ce candidat possède déjà une candidature pour ce concours');
    throw error;
  }
}
module.exports = { nextNipcan, nextNupcan, createApplication };
