const express = require('express');
const multer = require('multer');
const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const env = require('../config/env');
const { Contest, Program, ProgramSubject, DocumentRequirement, Application, ApplicationDocument, Payment, Message, Notification, Grade, Candidate, Establishment, Administrator, SupportRequest, Province, EducationLevel, Session } = require('../models/mongo');
const { createApplication } = require('../services/applicationService');
const emailService = require('../services/emailService');
const { AppError, ok, asyncHandler } = require('../utils/api');
const { authenticate, scopeEstablishment } = require('../middleware/mongoAuth');
const router = express.Router();
const required = (...paths) => (req, _res, next) => { const missing = paths.filter(path => path.split('.').reduce((v,k) => v?.[k], req.body) == null); missing.length ? next(new AppError(422, 'VALIDATION_ERROR', 'Données invalides', missing.map(field => ({ field, message: 'Champ obligatoire' })))) : next(); };
const requireSuperAdmin=(req,_res,next)=>req.admin?.role==='super_admin'?next():next(new AppError(403,'SUPER_ADMIN_REQUIRED','Accès réservé au super-administrateur'));
const isObjectId = value => typeof value === 'string' && /^[a-f\d]{24}$/i.test(value.trim());
const idFilter = value => isObjectId(value) ? { _id: value.trim() } : { legacyId: Number(value) };
const candidatePhotoUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
  fileFilter: (_req, file, cb) => cb(null, /^image\/(jpeg|png|webp)$/.test(file.mimetype))
});
const documentUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024, files: 15 },
  fileFilter: (_req, file, cb) => cb(null, /^(application\/pdf|image\/(jpeg|png|webp))$/.test(file.mimetype))
});
router.get('/health', asyncHandler(async (_req, res) => ok(res, { database: 'mongodb', status: 'ready' }, 'Service disponible')));
router.get('/sessions', asyncHandler(async (_req, res) => ok(res, [], 'Sessions chargées')));
router.post('/sessions', asyncHandler(async (req, res) => {
  const nupcan = String(req.body?.nupcan || '').trim().toUpperCase();
  const application = await Application.findOne({ nupcan }).select('candidateId').lean();
  if (!application) throw new AppError(404, 'APPLICATION_NOT_FOUND', 'Candidature introuvable');
  const token = crypto.randomBytes(32).toString('hex');
  const session = await Session.create({
    candidateId: application.candidateId,
    actorType: 'candidate',
    tokenHash: crypto.createHash('sha256').update(token).digest('hex'),
    expiresAt: new Date(Date.now() + 24 * 60 * 60 * 1000)
  });
  ok(res, { id: String(session._id), token, nupcan, expiresAt: session.expiresAt }, 'Session créée', 201);
}));
router.get('/contests', asyncHandler(async (req, res) => { const query = req.query.includeClosed === 'true' ? {} : { status: 'open' }; if (req.query.q) query.$text = { $search: String(req.query.q).slice(0, 100) }; ok(res, await Contest.find(query).populate('establishmentId educationLevelId').sort({ closesAt: -1 }).limit(Math.min(Number(req.query.limit) || 20, 100)).lean(), 'Concours disponibles'); }));
router.get('/contests/:id', asyncHandler(async (req, res) => { const item = await Contest.findById(req.params.id).populate('programIds establishmentId').lean(); if (!item) throw new AppError(404, 'CONTEST_NOT_FOUND', 'Concours introuvable'); ok(res, item); }));
const contestFilter = idFilter;
const toLegacyContest = (item, totals={}) => ({ id: String(item._id), legacyId: item.legacyId, libcnc: item.title, description_concours:item.description||'', fracnc: item.fee, debcnc: item.opensAt, fincnc: item.closesAt, stacnc: item.status==='open'?'1':'0', status:item.status, etablissement_id: item.establishmentId?.legacyId || item.establishmentId?._id || item.establishmentId, etablissement_object_id:item.establishmentId?._id, etablissement_nomets: item.establishmentId?.name||'', etablissement_nom:item.establishmentId?.name||'', niveau_id: item.educationLevelId?.legacyId || item.educationLevelId?._id || item.educationLevelId, niveau_object_id:item.educationLevelId?._id, niveau_nomniv: item.educationLevelId?.name||'', nomniv:item.educationLevelId?.name||'', filieres: item.programIds || [], total_candidatures:totals.applications||0, total_documents:totals.documents||0, total_paiements:totals.payments||0, montant_paiements:totals.amount||0 });
router.get('/concours', asyncHandler(async (_req, res) => {
  const [items,applicationTotals,paymentTotals,documentTotals]=await Promise.all([
    Contest.find().populate('establishmentId educationLevelId programIds').sort({closesAt:-1}).lean(),
    Application.aggregate([{$group:{_id:'$contestId',count:{$sum:1}}}]),
    Payment.aggregate([{$lookup:{from:'applications',localField:'applicationId',foreignField:'_id',as:'application'}},{$unwind:'$application'},{$group:{_id:'$application.contestId',count:{$sum:1},amount:{$sum:'$amount'}}}]),
    ApplicationDocument.aggregate([{$lookup:{from:'applications',localField:'applicationId',foreignField:'_id',as:'application'}},{$unwind:'$application'},{$group:{_id:'$application.contestId',count:{$sum:1}}}])
  ]);
  const totals=new Map();
  for(const row of applicationTotals)totals.set(String(row._id),{applications:row.count});
  for(const row of paymentTotals)Object.assign(totals.get(String(row._id))||totals.set(String(row._id),{}).get(String(row._id)),{payments:row.count,amount:row.amount});
  for(const row of documentTotals)Object.assign(totals.get(String(row._id))||totals.set(String(row._id),{}).get(String(row._id)),{documents:row.count});
  ok(res,items.map(item=>toLegacyContest(item,totals.get(String(item._id)))),'Concours chargés');
}));
router.get('/concours/:id/filieres', asyncHandler(async (req,res)=>{const contest=await Contest.findOne(contestFilter(req.params.id)).populate('programIds').lean();if(!contest)throw new AppError(404,'CONTEST_NOT_FOUND','Concours introuvable');ok(res,(contest.programIds||[]).map(p=>({id:String(p._id),filiere_id:p.legacyId,nomfil:p.name,description:p.description})));}));
router.get('/concours/:id', asyncHandler(async (req,res)=>{const item=await Contest.findOne(contestFilter(req.params.id)).populate('establishmentId educationLevelId programIds').lean();if(!item)throw new AppError(404,'CONTEST_NOT_FOUND','Concours introuvable');const result=toLegacyContest(item);result.documents_requis=(await DocumentRequirement.find({contestId:item._id,active:true}).sort({createdAt:1}).lean()).map(requirementView);ok(res,result);}));
const contestInput=async body=>{const update={};if(body.libcnc!=null)update.title=String(body.libcnc).trim();if(body.description_concours!=null)update.description=String(body.description_concours);if(body.fracnc!=null)update.fee=Number(body.fracnc);if(body.debcnc)update.opensAt=new Date(body.debcnc);if(body.fincnc)update.closesAt=new Date(body.fincnc);if(body.stacnc!=null)update.status=['1',1,true,'open'].includes(body.stacnc)?'open':(body.status||'closed');if(body.etablissement_id!=null){const e=await Establishment.findOne(establishmentFilter(body.etablissement_id)).select('_id');if(!e)throw new AppError(422,'INVALID_ESTABLISHMENT','Établissement introuvable');update.establishmentId=e._id;}if(body.niveau_id!=null){const n=await EducationLevel.findOne(idFilter(body.niveau_id)).select('_id');if(!n)throw new AppError(422,'INVALID_LEVEL','Niveau introuvable');update.educationLevelId=n._id;}return update;};
const normalizeRequirementCode = (name, index) => `${String(name).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toUpperCase().replace(/[^A-Z0-9]+/g,'_').replace(/(^_|_$)/g,'') || 'DOCUMENT'}_${index + 1}`;
const parseDocumentRequirements = value => {
  if (value == null) return null;
  let items = value;
  if (typeof items === 'string') { try { items = JSON.parse(items); } catch { throw new AppError(422,'INVALID_DOCUMENT_REQUIREMENTS','La liste des documents requis est invalide'); } }
  if (!Array.isArray(items)) throw new AppError(422,'INVALID_DOCUMENT_REQUIREMENTS','La liste des documents requis doit être un tableau');
  return items.map((item,index)=>({code:normalizeRequirementCode(item.nom||item.name,index),name:String(item.nom||item.name||'').trim(),description:String(item.description||'').trim(),required:item.obligatoire!==false&&item.required!==false,acceptedMimeTypes:Array.isArray(item.acceptedMimeTypes)?item.acceptedMimeTypes:['application/pdf','image/jpeg','image/png','image/webp'],maxSizeBytes:Number(item.maxSizeBytes)||10*1024*1024,active:true})).filter(item=>item.name);
};
const syncDocumentRequirements = async (contestId, value) => {
  const requirements=parseDocumentRequirements(value); if(requirements===null)return;
  await DocumentRequirement.updateMany({contestId},{$set:{active:false}});
  for(const requirement of requirements)await DocumentRequirement.findOneAndUpdate({contestId,programId:null,code:requirement.code},{$set:requirement,$setOnInsert:{contestId}},{upsert:true,new:true,runValidators:true});
};
const requirementView = item => ({id:String(item._id),code:item.code,nom:item.name,description:item.description||'',obligatoire:item.required,acceptedMimeTypes:item.acceptedMimeTypes||[],maxSizeBytes:item.maxSizeBytes});
router.post('/concours',authenticate,requireSuperAdmin,required('libcnc','etablissement_id','niveau_id','documents_requis'),asyncHandler(async(req,res)=>{const requirements=parseDocumentRequirements(req.body.documents_requis);if(!requirements?.length)throw new AppError(422,'DOCUMENT_REQUIREMENTS_REQUIRED','Définissez au moins un document pour ce concours');const input=await contestInput(req.body);input.slug=`${String(input.title).normalize('NFD').replace(/[\u0300-\u036f]/g,'').toLowerCase().replace(/[^a-z0-9]+/g,'-').replace(/(^-|-$)/g,'')}-${crypto.randomBytes(4).toString('hex')}`;const item=await Contest.create(input);await syncDocumentRequirements(item._id,requirements);const result=toLegacyContest(await Contest.findById(item._id).populate('establishmentId educationLevelId programIds').lean());result.documents_requis=(await DocumentRequirement.find({contestId:item._id,active:true}).sort({createdAt:1}).lean()).map(requirementView);ok(res,result,'Concours créé',201);}));
router.put('/concours/:id',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{const item=await Contest.findOneAndUpdate(contestFilter(req.params.id),{$set:await contestInput(req.body)},{new:true,runValidators:true}).populate('establishmentId educationLevelId programIds').lean();if(!item)throw new AppError(404,'CONTEST_NOT_FOUND','Concours introuvable');await syncDocumentRequirements(item._id,req.body.documents_requis);const result=toLegacyContest(item);result.documents_requis=(await DocumentRequirement.find({contestId:item._id,active:true}).sort({createdAt:1}).lean()).map(requirementView);ok(res,result,'Concours modifié');}));
router.delete('/concours/:id',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{const item=await Contest.findOneAndUpdate(contestFilter(req.params.id),{$set:{status:'archived'}},{new:true});if(!item)throw new AppError(404,'CONTEST_NOT_FOUND','Concours introuvable');ok(res,{id:String(item._id),status:item.status},'Concours archivé');}));
router.get('/filieres', asyncHandler(async (_req,res)=>ok(res,(await Program.find().lean()).map(p=>({id:p.legacyId||String(p._id),_id:p._id,nomfil:p.name,description:p.description,niveau_id:p.educationLevelId})),'Filières chargées')));
router.get('/filieres/:id/matieres',asyncHandler(async(req,res)=>{const program=await Program.findOne(idFilter(req.params.id)).populate('educationLevelId').lean();if(!program)throw new AppError(404,'PROGRAM_NOT_FOUND','Filière introuvable');const links=await ProgramSubject.find({programId:program._id}).populate('subjectId').lean();ok(res,{id:program.legacyId||String(program._id),_id:program._id,nomfil:program.name,niveau_id:program.educationLevelId?.legacyId||program.educationLevelId?._id,niveau_nom:program.educationLevelId?.name||'',matieres:links.map(l=>({id:l.subjectId?.legacyId||String(l.subjectId?._id),_id:l.subjectId?._id,nom_matiere:l.subjectId?.name||'',code:l.subjectId?.code||'',coefficient:l.coefficient,obligatoire:l.required}))},'Filière et matières chargées');}));
const establishmentFilter = idFilter;
const resolveProvinceId = async value => {
  if (value == null || value === '') return undefined;
  const province = await Province.findOne(idFilter(value)).select('_id').lean();
  if (!province) throw new AppError(422, 'INVALID_PROVINCE', 'Province introuvable');
  return province._id;
};
const toLegacyEstablishment = e => ({ id: e.legacyId || String(e._id), _id: e._id, nomets: e.name, nom: e.name, adretes: e.address || '', telefs: e.phone || '', maiets: e.email || '', code: e.code, province_id: e.provinceId?.legacyId || e.provinceId, province: e.provinceId?.name || '', ville: '', statut: e.active ? 'actif' : 'inactif', active: e.active, created_at: e.createdAt, updated_at: e.updatedAt });
router.get('/etablissements',asyncHandler(async(_req,res)=>{const items=await Establishment.find().populate('provinceId').sort({name:1}).lean();ok(res,items.map(toLegacyEstablishment),'Établissements chargés');}));
router.post('/etablissements', authenticate, requireSuperAdmin, required('nomets'), asyncHandler(async (req, res) => {
  const establishment = await Establishment.create({ name: String(req.body.nomets).trim(), address: req.body.adretes, phone: req.body.telefs, email: req.body.maiets, code: req.body.code, provinceId: await resolveProvinceId(req.body.province_id) });
  ok(res, toLegacyEstablishment(await establishment.populate('provinceId')), 'Établissement créé', 201);
}));
router.put('/etablissements/:id', authenticate, requireSuperAdmin, asyncHandler(async (req, res) => {
  const update = {};
  if (req.body.nomets != null) update.name = String(req.body.nomets).trim();
  if (req.body.adretes != null) update.address = req.body.adretes;
  if (req.body.telefs != null) update.phone = req.body.telefs;
  if (req.body.maiets != null) update.email = req.body.maiets;
  if (req.body.code != null) update.code = req.body.code;
  if (req.body.province_id != null) update.provinceId = await resolveProvinceId(req.body.province_id);
  if (req.body.active != null) update.active = Boolean(req.body.active);
  const establishment = await Establishment.findOneAndUpdate(establishmentFilter(req.params.id), { $set: update }, { new: true, runValidators: true }).populate('provinceId').lean();
  if (!establishment) throw new AppError(404, 'ESTABLISHMENT_NOT_FOUND', 'Établissement introuvable');
  ok(res, toLegacyEstablishment(establishment), 'Établissement modifié');
}));
router.delete('/etablissements/:id', authenticate, requireSuperAdmin, asyncHandler(async (req, res) => {
  const establishment = await Establishment.findOneAndUpdate(establishmentFilter(req.params.id), { $set: { active: false } }, { new: true }).populate('provinceId').lean();
  if (!establishment) throw new AppError(404, 'ESTABLISHMENT_NOT_FOUND', 'Établissement introuvable');
  ok(res, toLegacyEstablishment(establishment), 'Établissement désactivé');
}));
const toLegacyProvince = province => ({ id: province.legacyId || String(province._id), _id: province._id, nompro: province.name, nom: province.name, cdepro: province.code, code: province.code, active: province.active });
router.get('/provinces', asyncHandler(async (_req, res) => ok(res, (await Province.find({ active: true }).sort({ name: 1 }).lean()).map(toLegacyProvince), 'Provinces chargées')));
const toLegacyLevel = level => ({ id: level.legacyId || String(level._id), _id: level._id, nomniv: level.name, nom: level.name, code: level.code, description: level.description || '', rank: level.rank, active: level.active, created_at: level.createdAt, updated_at: level.updatedAt });
router.get('/niveaux', asyncHandler(async (_req, res) => ok(res, (await EducationLevel.find({ active: true }).sort({ rank: 1, name: 1 }).lean()).map(toLegacyLevel), 'Niveaux chargés')));
router.post('/niveaux', authenticate, requireSuperAdmin, required('nomniv'), asyncHandler(async (req, res) => {
  const name = String(req.body.nomniv).trim();
  const level = await EducationLevel.create({ name, code: String(req.body.code || name).trim(), description: req.body.description, rank: req.body.rank });
  ok(res, toLegacyLevel(level.toObject()), 'Niveau créé', 201);
}));
router.put('/niveaux/:id', authenticate, requireSuperAdmin, asyncHandler(async (req, res) => {
  const filter = idFilter(req.params.id);
  const update = {};
  if (req.body.nomniv != null) update.name = String(req.body.nomniv).trim();
  if (req.body.code != null) update.code = String(req.body.code).trim();
  if (req.body.description != null) update.description = String(req.body.description).trim();
  if (req.body.rank != null) update.rank = req.body.rank;
  if (req.body.active != null) update.active = Boolean(req.body.active);
  const level = await EducationLevel.findOneAndUpdate(filter, { $set: update }, { new: true, runValidators: true }).lean();
  if (!level) throw new AppError(404, 'LEVEL_NOT_FOUND', 'Niveau introuvable');
  ok(res, toLegacyLevel(level), 'Niveau modifié');
}));
router.delete('/niveaux/:id', authenticate, requireSuperAdmin, asyncHandler(async (req, res) => {
  const filter = idFilter(req.params.id);
  const level = await EducationLevel.findOneAndUpdate(filter, { $set: { active: false } }, { new: true }).lean();
  if (!level) throw new AppError(404, 'LEVEL_NOT_FOUND', 'Niveau introuvable');
  ok(res, toLegacyLevel(level), 'Niveau désactivé');
}));
router.post('/admin/auth/login', required('email','password'), asyncHandler(async (req,res)=>{
  const email=String(req.body.email).trim().toLowerCase();
  const admin=await Administrator.findOne({email,active:true}).select('+passwordHash').populate('establishmentIds').lean();
  if(!admin||!await bcrypt.compare(String(req.body.password),admin.passwordHash))throw new AppError(401,'INVALID_CREDENTIALS','Email ou mot de passe incorrect');
  if(!env.jwtSecret)throw new AppError(503,'AUTH_NOT_CONFIGURED',"L'authentification n'est pas configurée");
  const token=jwt.sign({sub:String(admin._id),role:admin.role},env.jwtSecret,{expiresIn:process.env.JWT_EXPIRES_IN||'24h'});
  await Administrator.updateOne({_id:admin._id},{$set:{lastLoginAt:new Date()}});
  res.cookie('admin_session',token,{httpOnly:true,secure:env.nodeEnv==='production',sameSite:'lax',maxAge:24*60*60*1000,path:'/'});
  const establishment=admin.establishmentIds?.[0];
  ok(res,{token,admin:{id:String(admin._id),legacyId:admin.legacyId,nom:admin.lastName,prenom:admin.firstName,email:admin.email,role:admin.role,admin_role:admin.role==='finance'?'paiements':'documents',etablissement_id:establishment?.legacyId,etablissement_object_id:establishment?._id,etablissement_nom:establishment?.name}},'Connexion réussie');
}));
router.post('/admin/auth/logout',(_req,res)=>{res.clearCookie('admin_session',{path:'/'});ok(res,null,'Déconnexion réussie')});
router.get('/statistics',asyncHandler(async(_req,res)=>{
  const [candidates,applications,contests,openContests,documents,payments,messages,paidAgg]=await Promise.all([Candidate.countDocuments(),Application.countDocuments(),Contest.countDocuments(),Contest.countDocuments({status:'open'}),ApplicationDocument.countDocuments(),Payment.countDocuments(),Message.countDocuments(),Payment.aggregate([{$match:{status:'paid'}},{$group:{_id:null,total:{$sum:'$amount'},count:{$sum:1}}}])]);
  const [approvedDocs,rejectedDocs,pendingDocs,approvedApps,pendingApps,unreadMessages]=await Promise.all([ApplicationDocument.countDocuments({status:'approved'}),ApplicationDocument.countDocuments({status:'rejected'}),ApplicationDocument.countDocuments({status:{$in:['uploaded','under_review','pending']}}),Application.countDocuments({status:'approved'}),Application.countDocuments({status:{$in:['draft','submitted','under_review']}}),Message.countDocuments({readAt:null,senderType:'candidate'})]);
  ok(res,{totalConcours:contests,concours:{total:contests,ouverts:openContests,fermes:contests-openContests},totalCandidatures:applications,totalCandidats:candidates,candidats:{total:candidates,complets:approvedApps,en_attente:pendingApps,validation_admin:await Application.countDocuments({status:'under_review'})},documents:{total:documents,en_attente:pendingDocs,valides:approvedDocs,rejetes:rejectedDocs},paiements:{total:payments,valides:paidAgg[0]?.count||0,en_attente:await Payment.countDocuments({status:{$in:['pending','processing']}}),montant_total:paidAgg[0]?.total||0},messages:{total:messages,non_lus:unreadMessages}},'Statistiques réelles');
}));
router.get('/admin/etablissement/:establishmentId/concours',authenticate,asyncHandler(async(req,res)=>{const id=req.params.establishmentId;const establishment=await Establishment.findOne(establishmentFilter(id)).lean();if(!establishment)throw new AppError(404,'ESTABLISHMENT_NOT_FOUND','Établissement introuvable');if(req.admin.role!=='super_admin'&&!req.admin.establishmentIds.some(assigned=>assigned.equals(establishment._id)))throw new AppError(403,'ESTABLISHMENT_FORBIDDEN','Établissement non attribué');const items=await Contest.find({establishmentId:establishment._id}).populate('educationLevelId programIds').sort({createdAt:-1}).lean();ok(res,items.map(toLegacyContest),'Concours de l’établissement');}));
router.get('/messages/admin',authenticate,asyncHandler(async(req,res)=>{const query={};if(req.query.nupcan)query.legacyNupcan=String(req.query.nupcan);const items=await Message.find(query).populate('candidateId administratorId applicationId').sort({createdAt:-1}).limit(200).lean();ok(res,items.map(m=>({id:String(m._id),legacyId:m.legacyId,candidat_nupcan:m.applicationId?.nupcan||m.legacyNupcan||'',admin_id:m.administratorId?.legacyId,sujet:m.subject||'',message:m.body,expediteur:m.senderType==='administrator'?'admin':'candidat',statut:m.readAt?'lu':'non_lu',created_at:m.createdAt,updated_at:m.updatedAt,nomcan:m.candidateId?.lastName||'',prncan:m.candidateId?.firstName||'',maican:m.candidateId?.email||'',admin_nom:m.administratorId?.lastName||'',admin_prenom:m.administratorId?.firstName||''})),'Messages chargés');}));
const adminView=a=>({id:String(a._id),legacyId:a.legacyId,nom:a.lastName,prenom:a.firstName,email:a.email,role:a.role,admin_role:a.role==='finance'?'paiements':'documents',etablissement_id:a.establishmentIds?.[0]?.legacyId,etablissement_object_id:a.establishmentIds?.[0]?._id,etablissement_nom:a.establishmentIds?.[0]?.name||'',statut:a.active?'actif':'inactif',active:a.active,derniere_connexion:a.lastLoginAt,created_at:a.createdAt});
router.get('/admin/management/admins',authenticate,requireSuperAdmin,asyncHandler(async(_req,res)=>ok(res,(await Administrator.find().populate('establishmentIds').sort({createdAt:-1}).lean()).map(adminView),'Administrateurs chargés')));
router.post('/admin/management/admins',authenticate,requireSuperAdmin,required('email'),asyncHandler(async(req,res)=>{
  const establishmentId=req.body.etablissement_id?await Establishment.findOne(establishmentFilter(req.body.etablissement_id)).select('_id').lean():null;
  if(req.body.etablissement_id&&!establishmentId)throw new AppError(422,'INVALID_ESTABLISHMENT','Établissement introuvable');
  const role=['super_admin','admin','reviewer','finance'].includes(req.body.role)?req.body.role:(req.body.admin_role==='paiements'?'finance':'reviewer');
  const temporaryPassword=String(req.body.password||crypto.randomBytes(12).toString('base64url'));
  const admin=await Administrator.create({firstName:req.body.prenom||req.body.firstName||'',lastName:req.body.nom||req.body.lastName||'',email:String(req.body.email).trim().toLowerCase(),passwordHash:await bcrypt.hash(temporaryPassword,12),role,establishmentIds:establishmentId?[establishmentId._id]:[],active:true});
  const populated=await Administrator.findById(admin._id).populate('establishmentIds').lean();
  let emailSent=false;
  try{
    await emailService.sendAdminCredentials({email:populated.email,prenom:populated.firstName,nom:populated.lastName,temp_password:temporaryPassword,etablissement_nom:populated.establishmentIds?.[0]?.name});
    emailSent=true;
  }catch(error){
    console.error(JSON.stringify({level:'error',code:'ADMIN_CREDENTIALS_EMAIL_FAILED',administratorId:String(admin._id),message:error.message}));
  }
  ok(res,{...adminView(populated),delivery:{emailSent,...(!emailSent&&{temporaryPassword})}},emailSent?'Administrateur créé et identifiants envoyés par email':"Administrateur créé, mais l'email n'a pas pu être envoyé",201);
}));
router.put('/admin/management/admins/:id',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{const update={};if(req.body.nom!=null)update.lastName=req.body.nom;if(req.body.prenom!=null)update.firstName=req.body.prenom;if(req.body.email!=null)update.email=String(req.body.email).toLowerCase();if(req.body.role!=null&&['super_admin','admin','reviewer','finance'].includes(req.body.role))update.role=req.body.role;if(req.body.statut!=null)update.active=req.body.statut!=='inactif';if(req.body.password)update.passwordHash=await bcrypt.hash(String(req.body.password),12);if(req.body.etablissement_id){const e=await Establishment.findOne(establishmentFilter(req.body.etablissement_id));if(!e)throw new AppError(422,'INVALID_ESTABLISHMENT','Établissement introuvable');update.establishmentIds=[e._id];}const admin=await Administrator.findByIdAndUpdate(req.params.id,{$set:update},{new:true,runValidators:true}).populate('establishmentIds').lean();if(!admin)throw new AppError(404,'ADMIN_NOT_FOUND','Administrateur introuvable');ok(res,adminView(admin),'Administrateur modifié');}));
const resetAdministratorPassword=async id=>{const temporaryPassword=crypto.randomBytes(12).toString('base64url');const admin=await Administrator.findOneAndUpdate(idFilter(id),{$set:{passwordHash:await bcrypt.hash(temporaryPassword,12),active:true}},{new:true,runValidators:true}).populate('establishmentIds').lean();if(!admin)throw new AppError(404,'ADMIN_NOT_FOUND','Administrateur introuvable');return{admin,temporaryPassword};};
router.post('/admin/management/admins/:id/regenerate-password',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{const {admin,temporaryPassword}=await resetAdministratorPassword(req.params.id);ok(res,{admin:adminView(admin),temporaryPassword},'Nouveau mot de passe temporaire généré');}));
router.post('/admin/management/admins/:id/resend-credentials',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{const {admin,temporaryPassword}=await resetAdministratorPassword(req.params.id);let emailSent=false;try{await emailService.sendAdminCredentials({email:admin.email,prenom:admin.firstName,nom:admin.lastName,temp_password:temporaryPassword,etablissement_nom:admin.establishmentIds?.[0]?.name});emailSent=true;}catch(error){console.error(JSON.stringify({level:'error',code:'ADMIN_CREDENTIALS_RESEND_FAILED',administratorId:String(admin._id),message:error.message}));}ok(res,{admin:adminView(admin),delivery:{emailSent,...(!emailSent&&{temporaryPassword})}},emailSent?'Identifiants régénérés et envoyés par email':"Mot de passe régénéré, mais l'email n'a pas pu être envoyé");}));
router.delete('/admin/management/admins/:id',authenticate,requireSuperAdmin,asyncHandler(async(req,res)=>{if(req.admin._id.equals(req.params.id))throw new AppError(409,'SELF_DELETE_FORBIDDEN','Vous ne pouvez pas supprimer votre propre compte');const admin=await Administrator.findByIdAndUpdate(req.params.id,{$set:{active:false}},{new:true});if(!admin)throw new AppError(404,'ADMIN_NOT_FOUND','Administrateur introuvable');ok(res,{id:String(admin._id)},'Administrateur désactivé');}));
router.get('/support',authenticate,asyncHandler(async(req,res)=>{const page=Math.max(1,Number(req.query.page)||1),limit=Math.min(100,Math.max(1,Number(req.query.limit)||20));const query={};if(req.query.status&&req.query.status!=='all')query.status=req.query.status;if(req.query.search){const q=String(req.query.search).slice(0,100);query.$or=[{subject:{$regex:q,$options:'i'}},{body:{$regex:q,$options:'i'}}];}const [items,total]=await Promise.all([SupportRequest.find(query).populate('candidateId applicationId').sort({createdAt:-1}).skip((page-1)*limit).limit(limit).lean(),SupportRequest.countDocuments(query)]);ok(res,{requests:items.map(s=>({id:String(s._id),legacyId:s.legacyId,name:s.candidateId?`${s.candidateId.firstName} ${s.candidateId.lastName}`.trim():'',email:s.candidateId?.email||'',subject:s.subject,message:s.body,status:s.status,createdAt:s.createdAt,updatedAt:s.updatedAt,nupcan:s.applicationId?.nupcan||''})),page,total,totalPages:Math.max(1,Math.ceil(total/limit))},'Demandes de support chargées');}));
router.get('/candidats',authenticate,asyncHandler(async(_req,res)=>{const [candidates,applications,documents,payments]=await Promise.all([Candidate.find().populate('originProvinceId currentProvinceId assignedProvinceId').sort({createdAt:-1}).lean(),Application.find().populate('contestId programId').lean(),ApplicationDocument.find().lean(),Payment.find().sort({createdAt:-1}).lean()]);const result=candidates.map(c=>{const apps=applications.filter(a=>String(a.candidateId)===String(c._id));const appIds=new Set(apps.map(a=>String(a._id))),docs=documents.filter(d=>appIds.has(String(d.applicationId))),pays=payments.filter(p=>appIds.has(String(p.applicationId))),latest=apps.sort((a,b)=>new Date(b.createdAt)-new Date(a.createdAt))[0];return{id:String(c._id),legacyId:c.legacyId,nupcan:latest?.nupcan||'',nipcan:c.nipcan||'',nomcan:c.lastName,prncan:c.firstName,maican:c.email||'',telcan:c.phone,dtncan:c.birthDate,province_origine:c.originProvinceId?.name||'',province_actuelle:c.currentProvinceId?.name||'',province_affectation:c.assignedProvinceId?.name||'',participations:apps.map(a=>({id:String(a._id),nupcan:a.nupcan,statut:a.status,concours:a.contestId?.title||'',filiere:a.programId?.name||''})),documents:docs.map(d=>({id:String(d._id),type:d.type,statut:d.status})),paiements:pays.map(p=>({id:String(p._id),montant:p.amount,statut:p.status,reference:p.paymentReference})),paiement:pays[0]?{statut:{paid:'valide',pending:'en_attente',processing:'en_attente',failed:'rejete',cancelled:'rejete'}[pays[0].status]||pays[0].status,montant:pays[0].amount}:null,created_at:c.createdAt,updated_at:c.updatedAt};});ok(res,result,'Candidats et informations liées chargés');}));
router.post('/candidats', candidatePhotoUpload.single('phtcan'), required('nomcan','prncan','telcan','concours_id','filiere_id'), asyncHandler(async(req,res)=>{
  const [contest,program,originProvince,currentProvince,assignedProvince]=await Promise.all([
    Contest.findOne(contestFilter(req.body.concours_id)).lean(),
    Program.findOne(idFilter(req.body.filiere_id)).lean(),
    req.body.proorg?Province.findOne(idFilter(req.body.proorg)).lean():null,
    req.body.proact?Province.findOne(idFilter(req.body.proact)).lean():null,
    req.body.proaff?Province.findOne(idFilter(req.body.proaff)).lean():null
  ]);
  if(!contest||!program)throw new AppError(422,'INVALID_SELECTION','Concours ou filière introuvable');
  if(contest.programIds?.length&&!contest.programIds.some(id=>String(id)===String(program._id)))throw new AppError(422,'PROGRAM_NOT_AVAILABLE','Cette filière ne fait pas partie du concours');
  const photoData=req.file?`data:${req.file.mimetype};base64,${req.file.buffer.toString('base64')}`:undefined;
  const existingCandidate=req.body.nipcan?await Candidate.findOne({nipcan:String(req.body.nipcan).trim().toUpperCase()}):null;
  if(req.body.nipcan&&!existingCandidate)throw new AppError(404,'CANDIDATE_NOT_FOUND','Aucun candidat ne correspond à ce NIPCAN');
  if(existingCandidate){
    Object.assign(existingCandidate,{firstName:String(req.body.prncan).trim(),lastName:String(req.body.nomcan).trim(),email:req.body.maican?String(req.body.maican).trim().toLowerCase():existingCandidate.email,phone:String(req.body.telcan).trim(),birthDate:req.body.dtncan?new Date(req.body.dtncan):existingCandidate.birthDate,birthPlace:req.body.ldncan?String(req.body.ldncan).trim():existingCandidate.birthPlace,photoData:photoData||existingCandidate.photoData,originProvinceId:originProvince?._id||existingCandidate.originProvinceId,currentProvinceId:currentProvince?._id||existingCandidate.currentProvinceId,assignedProvinceId:assignedProvince?._id||existingCandidate.assignedProvinceId});
    await existingCandidate.save();
  }
  const application=await createApplication({
    contestId:contest._id,
    programId:program._id,
    candidateId:existingCandidate?._id,
    candidate:{
      nipcan:req.body.nipcan?String(req.body.nipcan).trim().toUpperCase():undefined,
      firstName:String(req.body.prncan).trim(),
      lastName:String(req.body.nomcan).trim(),
      email:req.body.maican?String(req.body.maican).trim().toLowerCase():undefined,
      phone:String(req.body.telcan).trim(),
      birthDate:req.body.dtncan?new Date(req.body.dtncan):undefined,
      birthPlace:req.body.ldncan?String(req.body.ldncan).trim():undefined,
      photoData,
      originProvinceId:originProvince?._id,
      currentProvinceId:currentProvince?._id,
      assignedProvinceId:assignedProvince?._id
    }
  });
  const candidate=existingCandidate||await Candidate.findById(application.candidateId).lean();
  let emailSent=false;
  if (candidate.email) {
    try {
      await emailService.sendRegistrationConfirmation({
        nipcan: candidate.nipcan,
        nupcan: application.nupcan,
        nomcan: candidate.lastName,
        prncan: candidate.firstName,
        maican: candidate.email
      }, { libcnc: contest.title, documents_requis: [] });
      emailSent=true;
    } catch (error) {
      console.error(JSON.stringify({level:'error',code:'CANDIDATE_CREDENTIALS_EMAIL_FAILED',candidateId:String(candidate._id),message:error.message}));
    }
  }
  ok(res,{id:String(application.candidateId),nupcan:application.nupcan,nipcan:candidate.nipcan,concours_id:contest.legacyId||String(contest._id),filiere_id:program.legacyId||String(program._id),nomcan:req.body.nomcan,prncan:req.body.prncan,maican:req.body.maican||'',dtncan:req.body.dtncan||'',telcan:req.body.telcan,ldncan:req.body.ldncan||'',phtcan:candidate.photoData||null,niveau_id:req.body.niveau_id||null,proorg:originProvince?.legacyId||req.body.proorg||null,proact:currentProvince?.legacyId||req.body.proact||null,proaff:assignedProvince?.legacyId||req.body.proaff||null,created_at:application.createdAt,updated_at:application.updatedAt,delivery:{emailSent}},emailSent?'Candidature créée et identifiants envoyés par email':"Candidature créée, mais l'email n'a pas pu être envoyé",201);
}));
router.post('/candidats/nipcan/verify', required('nipcan'), asyncHandler(async (req, res) => {
  const nipcan = String(req.body.nipcan).trim().toUpperCase();
  const candidate = await Candidate.findOne({ nipcan }).lean();
  if (!candidate) throw new AppError(404, 'CANDIDATE_NOT_FOUND', 'NIPCAN invalide. Aucun candidat trouvé avec cet identifiant.');
  ok(res, { id: String(candidate._id), nipcan: candidate.nipcan, nom: candidate.lastName, prenom: candidate.firstName, maican: candidate.email || '' }, 'NIPCAN valide');
}));
const legacyDocumentStatus = status => ({ approved: 'valide', rejected: 'rejete', under_review: 'en_attente', uploaded: 'en_attente', pending: 'en_attente' }[status] || status);
const legacyPaymentStatus = status => ({ paid: 'valide', pending: 'en_attente', processing: 'en_attente', failed: 'rejete', cancelled: 'rejete', refunded: 'rembourse' }[status] || status);
router.get('/candidats/nipcan/:nipcan/dashboard', asyncHandler(async (req, res) => {
  const nipcan = String(req.params.nipcan).trim().toUpperCase();
  const candidate = await Candidate.findOne({ nipcan }).lean();
  if (!candidate) throw new AppError(404, 'CANDIDATE_NOT_FOUND', 'Candidat introuvable avec ce NIPCAN');
  const applications = await Application.find({ candidateId: candidate._id }).populate('contestId').populate('programId').sort({ createdAt: -1 }).lean();
  const applicationIds = applications.map(application => application._id);
  const [documents, payments] = await Promise.all([
    ApplicationDocument.find({ applicationId: { $in: applicationIds } }).lean(),
    Payment.find({ applicationId: { $in: applicationIds } }).sort({ createdAt: -1 }).lean()
  ]);
  const candidatures = applications.map(application => {
    const applicationDocuments = documents.filter(document => String(document.applicationId) === String(application._id));
    const validDocuments = applicationDocuments.filter(document => document.status === 'approved').length;
    const payment = payments.find(item => String(item.applicationId) === String(application._id));
    const documentsComplete = applicationDocuments.length > 0 && validDocuments === applicationDocuments.length;
    const paymentComplete = payment?.status === 'paid';
    const resultAvailable = ['approved', 'rejected'].includes(application.status);
    const completed = [true, documentsComplete, paymentComplete, resultAvailable].filter(Boolean).length;
    return {
      nupcan: application.nupcan,
      concours: { id: application.contestId?.legacyId || String(application.contestId?._id || ''), libcnc: application.contestId?.title || application.contestSnapshot?.title || '', etablissement: application.contestSnapshot?.establishmentName || '' },
      filiere: { id: application.programId?.legacyId || String(application.programId?._id || ''), nomfil: application.programId?.name || application.contestSnapshot?.programName || '' },
      statut: application.status,
      progression: completed * 25,
      created_at: application.createdAt,
      documents_count: applicationDocuments.length,
      documents_valides: validDocuments,
      paiement_statut: payment ? legacyPaymentStatus(payment.status) : null,
      etapes: { inscription: true, documents: documentsComplete, paiement: paymentComplete, resultats: resultAvailable }
    };
  });
  ok(res, {
    candidat: { id: String(candidate._id), nipcan: candidate.nipcan, nomcan: candidate.lastName, prncan: candidate.firstName, maican: candidate.email || '', telcan: candidate.phone, phtcan: candidate.photoData || '' },
    candidatures,
    statistiques: { total: candidatures.length, en_cours: applications.filter(application => ['draft', 'submitted', 'under_review'].includes(application.status)).length, completes: applications.filter(application => application.status === 'approved').length }
  }, 'Dashboard candidat chargé');
}));
router.get('/candidats/nip/:nip',asyncHandler(async(req,res)=>{
  const c=await Candidate.findOne({nipcan:String(req.params.nip).trim().toUpperCase()}).lean();
  if(!c)throw new AppError(404,'CANDIDATE_NOT_FOUND','Candidat introuvable avec ce NIPCAN');
  const application=await Application.findOne({candidateId:c._id}).sort({createdAt:-1}).populate('contestId').populate('programId').lean();
  ok(res,{id:String(c._id),nupcan:application?.nupcan||'',nipcan:c.nipcan,concours_id:application?.contestId?.legacyId||String(application?.contestId?._id||''),filiere_id:application?.programId?.legacyId||String(application?.programId?._id||''),nomcan:c.lastName,prncan:c.firstName,maican:c.email||'',telcan:c.phone,dtncan:c.birthDate,ldncan:c.birthPlace||'',phtcan:c.photoData||null,proorg:c.originProvinceId,proact:c.currentProvinceId,proaff:c.assignedProvinceId,statut:application?.status||'',created_at:c.createdAt,updated_at:c.updatedAt},'Candidat chargé');
}));
router.get('/candidats/nupcan/:nupcan',authenticate,asyncHandler(async(req,res)=>{const application=await Application.findOne({nupcan:String(req.params.nupcan).toUpperCase()}).populate('candidateId').populate('contestId').populate('programId').lean();if(!application)throw new AppError(404,'CANDIDATE_NOT_FOUND','Candidat introuvable');const c=application.candidateId;ok(res,{id:String(c._id),nupcan:application.nupcan,nipcan:c.nipcan||'',concours_id:application.contestId?.legacyId||String(application.contestId?._id),filiere_id:application.programId?.legacyId||String(application.programId?._id),nomcan:c.lastName,prncan:c.firstName,maican:c.email||'',telcan:c.phone,dtncan:c.birthDate,ldncan:c.birthPlace||'',phtcan:c.photoData||null,proorg:c.originProvinceId,proact:c.currentProvinceId,proaff:c.assignedProvinceId,statut:application.status,created_at:c.createdAt,updated_at:c.updatedAt},'Candidat chargé');}));
router.get('/candidats/nupcan/:nupcan/nipcan', asyncHandler(async (req, res) => { const application = await Application.findOne({ nupcan: String(req.params.nupcan).toUpperCase() }).populate('candidateId').lean(); if (!application?.candidateId?.nipcan) throw new AppError(404, 'CANDIDATE_NOT_FOUND', 'NIPCAN introuvable pour cette candidature'); ok(res, { nipcan: application.candidateId.nipcan, nupcan: application.nupcan }, 'NIPCAN trouvé'); }));
const documentView = d => ({ id: String(d._id), document_id: String(d._id), requirement_id: d.requirementId ? String(d.requirementId) : null, nomdoc: d.type, nom_fichier: d.originalName || d.safeName, chemin_fichier: d.storageKey, type: d.type, obligatoire: d.required, taille: d.size, statut: legacyDocumentStatus(d.status), commentaire_validation: d.rejectionReason || '', created_at: d.createdAt, updated_at: d.updatedAt });
router.get('/dossiers/nupcan/:nupcan', asyncHandler(async(req,res)=>{const application=await Application.findOne({nupcan:String(req.params.nupcan).toUpperCase()}).lean();if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const docs=await ApplicationDocument.find({applicationId:application._id}).sort({createdAt:-1}).lean();ok(res,docs.map(documentView),'Documents chargés');}));
router.get('/candidats/nupcan/:nupcan/documents', asyncHandler(async(req,res)=>{const application=await Application.findOne({nupcan:String(req.params.nupcan).trim().toUpperCase()}).lean();if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');ok(res,(await ApplicationDocument.find({applicationId:application._id}).sort({createdAt:-1}).lean()).map(documentView),'Documents chargés');}));
router.get('/candidats/nupcan/:nupcan/document-checklist', asyncHandler(async(req,res)=>{const application=await Application.findOne({nupcan:String(req.params.nupcan).trim().toUpperCase()}).lean();if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const [requirements,documents]=await Promise.all([DocumentRequirement.find({contestId:application.contestId,active:true,$or:[{programId:null},{programId:application.programId}]}).sort({required:-1,createdAt:1}).lean(),ApplicationDocument.find({applicationId:application._id}).sort({createdAt:-1}).lean()]);const byRequirement=new Map(documents.filter(document=>document.requirementId).map(document=>[String(document.requirementId),document]));const linkedDocumentIds=new Set([...byRequirement.values()].map(document=>String(document._id)));const checklist=requirements.map(requirement=>({requirement:requirementView(requirement),document:byRequirement.has(String(requirement._id))?documentView(byRequirement.get(String(requirement._id))):null}));const supplemental=documents.filter(document=>!linkedDocumentIds.has(String(document._id))).map(documentView);ok(res,{nupcan:application.nupcan,checklist,supplemental,summary:{required:requirements.filter(item=>item.required).length,submitted:checklist.filter(item=>item.document).length,approved:checklist.filter(item=>item.document?.status==='approved').length,missing:checklist.filter(item=>item.requirement.required&&!item.document).length,rejected:checklist.filter(item=>item.document?.status==='rejected').length}},'Checklist documentaire chargée');}));
router.post('/dossiers', documentUpload.array('documents', 15), asyncHandler(async (req, res) => {
  const nupcan = String(req.body?.nupcan || '').trim().toUpperCase();
  const application = await Application.findOne({ nupcan }).lean();
  if (!application) throw new AppError(404, 'APPLICATION_NOT_FOUND', 'Candidature introuvable');
  if (!req.files?.length) throw new AppError(422, 'DOCUMENTS_REQUIRED', 'Au moins un document est requis');
  const documents = await ApplicationDocument.insertMany(req.files.map(file => ({
    applicationId: application._id,
    candidateId: application.candidateId,
    type: file.originalname,
    storageKey: `documents/${nupcan}/${crypto.randomUUID()}`,
    contentData: `data:${file.mimetype};base64,${file.buffer.toString('base64')}`,
    originalName: file.originalname,
    safeName: file.originalname.replace(/[^a-zA-Z0-9._-]/g, '_'),
    mimeType: file.mimetype,
    size: file.size,
    checksum: crypto.createHash('sha256').update(file.buffer).digest('hex'),
    status: 'uploaded'
  })));
  ok(res, documents.map(documentView), 'Documents chargés', 201);
}));
router.post('/documents', documentUpload.single('file'), asyncHandler(async(req,res)=>{const nupcan=String(req.body?.nupcan||'').trim().toUpperCase();const application=await Application.findOne({nupcan}).lean();if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');if(!req.file)throw new AppError(422,'DOCUMENT_REQUIRED','Un document est requis');let requirement=null;if(req.body.requirement_id){requirement=await DocumentRequirement.findOne({_id:req.body.requirement_id,contestId:application.contestId,active:true}).lean();if(!requirement)throw new AppError(422,'INVALID_DOCUMENT_REQUIREMENT','Ce document ne fait pas partie des pièces demandées pour ce concours');const exists=await ApplicationDocument.exists({applicationId:application._id,requirementId:requirement._id});if(exists)throw new AppError(409,'DOCUMENT_ALREADY_SUBMITTED','Cette pièce a déjà été téléversée. Utilisez le remplacement.');}const file=req.file;if(requirement?.acceptedMimeTypes?.length&&!requirement.acceptedMimeTypes.includes(file.mimetype))throw new AppError(422,'INVALID_DOCUMENT_TYPE','Format de fichier non autorisé pour cette pièce');if(requirement?.maxSizeBytes&&file.size>requirement.maxSizeBytes)throw new AppError(422,'DOCUMENT_TOO_LARGE','Le fichier dépasse la taille autorisée');const document=await ApplicationDocument.create({applicationId:application._id,candidateId:application.candidateId,requirementId:requirement?._id,type:requirement?.name||String(req.body.nomdoc||file.originalname),required:requirement?.required||false,storageKey:`documents/${nupcan}/${crypto.randomUUID()}`,contentData:`data:${file.mimetype};base64,${file.buffer.toString('base64')}`,originalName:file.originalname,safeName:file.originalname.replace(/[^a-zA-Z0-9._-]/g,'_'),mimeType:file.mimetype,size:file.size,checksum:crypto.createHash('sha256').update(file.buffer).digest('hex'),status:'uploaded'});ok(res,documentView(document),'Document ajouté',201);}));
router.put('/documents/:id/replace', documentUpload.single('file'), asyncHandler(async(req,res)=>{if(!req.file)throw new AppError(422,'DOCUMENT_REQUIRED','Un document est requis');const old=await ApplicationDocument.findById(req.params.id);if(!old)throw new AppError(404,'DOCUMENT_NOT_FOUND','Document introuvable');const file=req.file;old.type=String(req.body.nomdoc||old.type);old.contentData=`data:${file.mimetype};base64,${file.buffer.toString('base64')}`;old.originalName=file.originalname;old.safeName=file.originalname.replace(/[^a-zA-Z0-9._-]/g,'_');old.mimeType=file.mimetype;old.size=file.size;old.checksum=crypto.createHash('sha256').update(file.buffer).digest('hex');old.status='uploaded';old.rejectionReason=undefined;old.version+=1;await old.save();ok(res,documentView(old),'Document remplacé');}));
router.delete('/documents/:id', asyncHandler(async(req,res)=>{const item=await ApplicationDocument.findByIdAndDelete(req.params.id);if(!item)throw new AppError(404,'DOCUMENT_NOT_FOUND','Document introuvable');ok(res,{id:String(item._id)},'Document supprimé');}));
router.get('/documents/:id/download', asyncHandler(async(req,res)=>{const item=await ApplicationDocument.findById(req.params.id).lean();if(!item?.contentData)throw new AppError(404,'DOCUMENT_NOT_FOUND','Fichier introuvable');const match=/^data:([^;]+);base64,(.*)$/.exec(item.contentData);if(!match)throw new AppError(500,'INVALID_DOCUMENT_DATA','Fichier illisible');res.type(match[1]).set('Content-Disposition',`inline; filename="${String(item.safeName||item.originalName||'document').replace(/["\r\n]/g,'_')}"`).send(Buffer.from(match[2],'base64'));}));
const applicationByNupcan = nupcan => Application.findOne({ nupcan: String(nupcan).trim().toUpperCase() }).lean();
const notificationView = item => ({ id: String(item._id), titre: item.title || 'Notification', message: item.body || '', type: item.channel || 'information', statut: item.readAt ? 'lu' : 'non_lu', created_at: item.createdAt });
router.get('/notifications/candidat/:nupcan', asyncHandler(async(req,res)=>{const application=await applicationByNupcan(req.params.nupcan);if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const items=await Notification.find({$or:[{applicationId:application._id},{candidateId:application.candidateId},{legacyNupcan:application.nupcan}]}).sort({createdAt:-1}).lean();ok(res,items.map(notificationView),'Notifications chargées');}));
router.put('/notifications/:id/read', asyncHandler(async(req,res)=>{const item=await Notification.findByIdAndUpdate(req.params.id,{$set:{readAt:new Date()}},{new:true}).lean();if(!item)throw new AppError(404,'NOTIFICATION_NOT_FOUND','Notification introuvable');ok(res,notificationView(item),'Notification lue');}));
router.delete('/notifications/:id', asyncHandler(async(req,res)=>{const item=await Notification.findByIdAndDelete(req.params.id);if(!item)throw new AppError(404,'NOTIFICATION_NOT_FOUND','Notification introuvable');ok(res,{id:String(item._id)},'Notification supprimée');}));
router.delete('/notifications/candidat/:nupcan', asyncHandler(async(req,res)=>{const application=await applicationByNupcan(req.params.nupcan);if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const result=await Notification.deleteMany({$or:[{applicationId:application._id},{candidateId:application.candidateId},{legacyNupcan:application.nupcan}]});ok(res,{deletedCount:result.deletedCount},'Notifications supprimées');}));
const messageView = item => ({id:String(item._id),sujet:item.subject||'',message:item.body,expediteur:item.senderType==='administrator'?'admin':'candidat',statut:item.readAt?'lu':'non_lu',created_at:item.createdAt,admin_nom:item.administratorId?.lastName||'',admin_prenom:item.administratorId?.firstName||''});
router.get('/messages/candidat/:nupcan', asyncHandler(async(req,res)=>{const application=await applicationByNupcan(req.params.nupcan);if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const items=await Message.find({$or:[{applicationId:application._id},{legacyNupcan:application.nupcan}]}).populate('administratorId').sort({createdAt:1}).lean();ok(res,items.map(messageView),'Messages chargés');}));
router.post('/messages/candidat', required('nupcan','message'), asyncHandler(async(req,res)=>{const application=await applicationByNupcan(req.body.nupcan);if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const item=await Message.create({applicationId:application._id,candidateId:application.candidateId,legacyNupcan:application.nupcan,subject:String(req.body.sujet||'Sans objet').trim(),body:String(req.body.message).trim(),senderType:'candidate'});ok(res,messageView(item),'Message envoyé',201);}));
router.get('/grades/candidat/:nupcan', asyncHandler(async(req,res)=>{const application=await applicationByNupcan(req.params.nupcan);if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const grades=await Grade.find({applicationId:application._id}).populate('subjectId').lean();const notes=grades.map(grade=>({id:String(grade._id),note:grade.score,nommat:grade.subjectId?.name||'',coefmat:grade.coefficient||1}));const coefficientTotal=notes.reduce((sum,note)=>sum+note.coefmat,0);const moyenneGenerale=coefficientTotal?Number((notes.reduce((sum,note)=>sum+note.note*note.coefmat,0)/coefficientTotal).toFixed(2)):null;ok(res,{notes,moyenneGenerale},'Notes chargées');}));
router.get('/paiements/nupcan/:nupcan',authenticate,asyncHandler(async(req,res)=>{const application=await Application.findOne({nupcan:String(req.params.nupcan).toUpperCase()}).lean();if(!application)throw new AppError(404,'APPLICATION_NOT_FOUND','Candidature introuvable');const p=await Payment.findOne({applicationId:application._id}).sort({createdAt:-1}).lean();if(!p)return ok(res,null,'Aucun paiement');ok(res,{id:String(p._id),reference_paiement:p.paymentReference,montant:p.amount,methode:p.provider,statut:{paid:'valide',pending:'en_attente',processing:'en_attente',failed:'rejete',cancelled:'rejete',refunded:'rembourse'}[p.status]||p.status,created_at:p.createdAt},'Paiement chargé');}));
router.get('/paiements',authenticate,asyncHandler(async(_req,res)=>{const items=await Payment.find().populate('candidateId').populate({path:'applicationId',populate:[{path:'contestId'},{path:'programId'}]}).sort({createdAt:-1}).lean();ok(res,items.map(p=>({id:String(p._id),legacyId:p.legacyId,candidat_nom:p.candidateId?`${p.candidateId.firstName} ${p.candidateId.lastName}`.trim():'',candidat_email:p.candidateId?.email||'',nupcan:p.applicationId?.nupcan||'',concours:p.applicationId?.contestId?.title||'',filiere:p.applicationId?.programId?.name||'',reference:p.paymentReference,transaction_id:p.transactionId,montant:p.amount,devise:p.currency,methode:p.provider,statut:{paid:'valide',pending:'en_attente',processing:'en_attente',failed:'rejete',cancelled:'rejete',refunded:'rembourse'}[p.status]||p.status,date_paiement:p.createdAt,created_at:p.createdAt})),'Paiements complets chargés');}));
router.patch('/paiements/:id/status',authenticate,asyncHandler(async(req,res)=>{const status={valide:'paid',rejete:'failed',en_attente:'pending'}[req.body.statut]||req.body.status;if(!['paid','failed','pending','processing','cancelled','refunded'].includes(status))throw new AppError(422,'INVALID_PAYMENT_STATUS','Statut de paiement invalide');const item=await Payment.findByIdAndUpdate(req.params.id,{$set:{status}},{new:true,runValidators:true});if(!item)throw new AppError(404,'PAYMENT_NOT_FOUND','Paiement introuvable');ok(res,{id:String(item._id),statut:item.status},'Statut du paiement modifié');}));
router.post('/applications', required('contestId','programId','candidate.firstName','candidate.lastName','candidate.phone'), asyncHandler(async (req, res) => ok(res, await createApplication(req.body), 'Brouillon créé', 201)));
router.get('/applications/:nupcan', asyncHandler(async (req, res) => { const item = await Application.findOne({ nupcan: req.params.nupcan.toUpperCase() }).populate('candidateId contestId programId').lean(); if (!item) throw new AppError(404, 'APPLICATION_NOT_FOUND', 'Candidature introuvable'); ok(res, item); }));
router.patch('/applications/:nupcan', asyncHandler(async (req, res) => { const update = {}; if (Array.isArray(req.body.completedSteps)) update.completedSteps = req.body.completedSteps; const item = await Application.findOneAndUpdate({ nupcan: req.params.nupcan.toUpperCase(), status: 'draft' }, update, { new: true, runValidators: true }); if (!item) throw new AppError(404, 'DRAFT_NOT_FOUND', 'Brouillon introuvable'); ok(res, item, 'Brouillon enregistré'); }));
router.post('/payments', required('applicationId','paymentReference','provider','amount'), asyncHandler(async (req, res) => { if (process.env.NODE_ENV === 'production' && req.body.provider === 'development') throw new AppError(400, 'SIMULATION_DISABLED', 'Le paiement simulé est désactivé en production'); const payment = await Payment.findOneAndUpdate({ paymentReference: req.body.paymentReference }, { $setOnInsert: { applicationId: req.body.applicationId, candidateId: req.body.candidateId, provider: req.body.provider, paymentReference: req.body.paymentReference, amount: req.body.amount, currency: req.body.currency || 'XAF', status: 'pending' } }, { upsert: true, new: true, runValidators: true }); ok(res, payment, 'Paiement initialisé', 201); }));
router.get('/admin/applications', authenticate, scopeEstablishment, asyncHandler(async (req, res) => { const query = {}; if (req.query.status) query.status = req.query.status; if (req.query.contestId) query.contestId = req.query.contestId; if (req.query.nupcan) query.nupcan = req.query.nupcan.toUpperCase(); ok(res, await Application.find(query).populate('candidateId', 'firstName lastName phone').sort({ createdAt: -1 }).limit(100).lean()); }));
module.exports = router;
