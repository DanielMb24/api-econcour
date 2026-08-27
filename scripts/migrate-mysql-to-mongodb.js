#!/usr/bin/env node
const fs = require('fs');
const path = require('path');
const mysql = require('mysql2/promise');
const { connectMongo, disconnectMongo } = require('../config/mongodb');
const legacyDb = require('../config/database').dbConfig;
const M = require('../models/mongo');
const dryRun = process.argv.includes('--dry-run');
const batchArg = process.argv.find(v => v.startsWith('--batch-size='));
const batchSize = Math.max(1, Number(batchArg?.split('=')[1] || 250));
const report = { startedAt: new Date().toISOString(), dryRun, batchSize, entities: {}, missingReferences: [], duplicates: [], errors: [] };
const mappings = [
  ['etablissements', M.Establishment, r => ({ legacyId:r.id, name:r.nom || r.libelle, code:r.code, province:r.province })],
  ['filieres', M.Program, r => ({ legacyId:r.id, name:r.nom || r.libelle, code:r.code, level:r.niveau })],
  ['matieres', M.Subject, r => ({ legacyId:r.id, name:r.nom || r.libelle, code:r.code, coefficient:r.coefficient })],
  ['concours', M.Contest, r => ({ legacyId:r.id, title:r.titre || r.nom, slug:String(r.slug || r.code || `concours-${r.id}`).toLowerCase(), description:r.description, opensAt:r.date_ouverture, closesAt:r.date_cloture, fee:Number(r.montant || r.frais || 0), status:r.statut === 'ouvert' ? 'open' : 'draft' })],
  ['administrateurs', M.Administrator, r => ({ legacyId:r.id, firstName:r.prenom, lastName:r.nom, email:r.email, passwordHash:r.password || r.mot_de_passe, role:r.role === 'super_admin' ? 'super_admin' : 'admin' })],
  ['candidats', M.Candidate, r => ({ legacyId:r.id, firstName:r.prenom || 'Inconnu', lastName:r.nom || 'Inconnu', birthDate:r.date_naissance, phone:r.telephone || r.phone || `legacy-${r.id}`, email:r.email, nationalId:r.numero_piece })],
];
async function tableExists(db, table) { const [rows] = await db.query('SHOW TABLES LIKE ?', [table]); return rows.length > 0; }
async function migrateTable(db, table, Model, transform) {
  const stats = report.entities[table] = { mysql:0, mongodbBefore:await Model.countDocuments(), migrated:0, skipped:0, errors:0, mongodbAfter:0 };
  if (!await tableExists(db, table)) { stats.missingTable = true; stats.mongodbAfter = stats.mongodbBefore; return; }
  const [[count]] = await db.query(`SELECT COUNT(*) total FROM \`${table}\``); stats.mysql = Number(count.total);
  for (let offset=0; offset<stats.mysql; offset+=batchSize) {
    const [rows] = await db.query(`SELECT * FROM \`${table}\` ORDER BY id LIMIT ? OFFSET ?`, [batchSize, offset]);
    for (const row of rows) try {
      const document = transform(row);
      if (!document.legacyId) { stats.skipped++; report.errors.push({ table, id:row.id, reason:'legacyId absent' }); continue; }
      if (!dryRun) await Model.updateOne({ legacyId:document.legacyId }, { $set:document }, { upsert:true, runValidators:true });
      stats.migrated++;
    } catch (error) { stats.errors++; report.errors.push({ table, id:row.id, reason:error.message }); }
    console.log(`${table}: ${Math.min(offset+batchSize, stats.mysql)}/${stats.mysql}`);
  }
  stats.mongodbAfter = dryRun ? stats.mongodbBefore : await Model.countDocuments();
}
function writeReport() {
  const dir = path.join(__dirname, '..', 'migration-reports'); fs.mkdirSync(dir, { recursive:true });
  const stamp = new Date().toISOString().replace(/[:.]/g,'-'); const base = path.join(dir, `migration-${stamp}`);
  report.finishedAt = new Date().toISOString(); fs.writeFileSync(`${base}.json`, JSON.stringify(report,null,2));
  const lines = ['# Rapport de migration MySQL → MongoDB','',`- Mode : ${dryRun ? 'dry-run' : 'écriture'}`,`- Début : ${report.startedAt}`,`- Fin : ${report.finishedAt}`,'','| Entité | MySQL | Mongo avant | Migrés | Ignorés | Erreurs | Mongo après |','|---|---:|---:|---:|---:|---:|---:|',...Object.entries(report.entities).map(([k,v])=>`| ${k} | ${v.mysql} | ${v.mongodbBefore} | ${v.migrated} | ${v.skipped} | ${v.errors} | ${v.mongodbAfter} |`),'',`Erreurs détaillées : ${report.errors.length} (voir JSON).`];
  fs.writeFileSync(`${base}.md`, lines.join('\n')); console.log(`Rapports: ${base}.json et ${base}.md`);
}
(async()=>{ let db; try { await connectMongo(); db=await mysql.createConnection(legacyDb); for (const args of mappings) await migrateTable(db,...args); } catch(error) { report.errors.push({ fatal:error.message || String(error), name:error.name, code:error.code }); process.exitCode=1; } finally { if(db) await db.end(); await disconnectMongo(); writeReport(); } })();
