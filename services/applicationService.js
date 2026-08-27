const { Candidate, Contest, Program, Application, Counter } = require('../models/mongo');
const { AppError } = require('../utils/api');
async function nextNupcan(now = new Date()) {
  const year = now.getUTCFullYear();
  const counter = await Counter.findByIdAndUpdate(`nupcan:${year}`, { $inc: { seq: 1 } }, { new: true, upsert: true, setDefaultsOnInsert: true });
  return `GC-${year}-${String(counter.seq).padStart(7, '0')}`;
}
async function createApplication(input) {
  const [contest, program] = await Promise.all([Contest.findById(input.contestId), Program.findById(input.programId)]);
  if (!contest || !program) throw new AppError(404, 'SELECTION_NOT_FOUND', 'Concours ou filière introuvable');
  if (contest.status !== 'open') throw new AppError(409, 'CONTEST_NOT_OPEN', "Ce concours n'accepte pas de candidature");
  const candidate = await Candidate.create(input.candidate);
  try {
    return await Application.create({ candidateId: candidate._id, contestId: contest._id, programId: program._id, legacyNipcan: input.legacyNipcan || undefined, nupcan: await nextNupcan(), completedSteps: ['candidate'], contestSnapshot: { title: contest.title, fee: contest.fee, currency: contest.currency, programName: program.name }, statusHistory: [{ status: 'draft' }] });
  } catch (error) { if (error.code === 11000) await Candidate.deleteOne({ _id: candidate._id }); throw error; }
}
module.exports = { nextNupcan, createApplication };
