const test=require('node:test'),assert=require('node:assert/strict'),vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const bcrypt=require('bcryptjs');
function setup(existing=false) {
 let created;
 const models={
  Contest:{findById:async()=>({_id:'contest',title:'Concours',status:'open',programIds:[]})},
  Program:{findById:async()=>({_id:'program',name:'Informatique'})},
  Counter:{findByIdAndUpdate:async()=>({seq:1})},
  Candidate:{exists:async()=>false,create:async data=>{created={...data,_id:'candidate'};return created;},findById:async()=>({_id:'candidate'})},
  Application:{findOne:()=>({select:()=>({lean:async()=>null})}),create:async data=>({...data,$locals:{}})}
 };
 const context={module:{exports:{}},require:name=>name.includes('models/mongo')?models:name.includes('utils/api')?{AppError:class extends Error{constructor(_status,_code,message){super(message);}}}:require(name)};
 vm.runInNewContext(fs.readFileSync(path.join(__dirname,'../services/applicationService.js'),'utf8'),context);
 return {run:()=>context.module.exports.createApplication({contestId:'contest',programId:'program',...(existing?{candidateId:'candidate'}:{}),candidate:{email:'eleve@example.test',phone:'+24177123456',firstName:'Test',lastName:'Test'}}),getCreated:()=>created};
}
test('la première candidature crée un mot de passe temporaire individuel et ne stocke que son hash',async()=>{
 const first=setup(),second=setup(),a=await first.run(),b=await second.run();
 const password=a.$locals.accountCredentials.temporaryPassword;
 assert.ok(password.length>=16);assert.notEqual(password,b.$locals.accountCredentials.temporaryPassword);
 assert.equal(await bcrypt.compare(password,first.getCreated().passwordHash),true);
 assert.equal(first.getCreated().temporaryPassword,undefined);assert.equal(first.getCreated().mustChangePassword,true);
 assert.equal(first.getCreated().username,first.getCreated().nipcan.toLowerCase());
});
test('une nouvelle candidature du compte existant conserve son mot de passe',async()=>{
 const state=setup(true),application=await state.run();assert.equal(state.getCreated(),undefined);assert.equal(application.$locals.accountCredentials,undefined);
});
