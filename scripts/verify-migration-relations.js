const {connectMongo,disconnectMongo}=require('../config/mongodb');
const M=require('../models/mongo');
(async()=>{await connectMongo();const checks={
 establishmentsWithoutProvince:await M.Establishment.countDocuments({provinceId:null}),
 contestsWithoutEstablishment:await M.Contest.countDocuments({establishmentId:null}),
 contestsWithoutLevel:await M.Contest.countDocuments({educationLevelId:null}),
 contestProgramsWithMissingReference:await M.ContestProgram.countDocuments({$or:[{contestId:null},{programId:null}]}),
 programSubjectsWithMissingReference:await M.ProgramSubject.countDocuments({$or:[{programId:null},{subjectId:null}]}),
 applicationsWithMissingReference:await M.Application.countDocuments({$or:[{candidateId:null},{contestId:null},{programId:null}]}),
 documentsWithMissingReference:await M.ApplicationDocument.countDocuments({$or:[{applicationId:null},{candidateId:null}]}),
 gradesWithMissingReference:await M.Grade.countDocuments({$or:[{applicationId:null},{subjectId:null}]}),
 preservedOrphanNotifications:await M.Notification.countDocuments({candidateId:null}),
 preservedOrphanMessages:await M.Message.countDocuments({applicationId:null})};
const critical=Object.entries(checks).filter(([key,value])=>!key.startsWith('preserved')&&value>0);console.log(JSON.stringify({success:critical.length===0,checks},null,2));if(critical.length)process.exitCode=1;})().catch(e=>{console.error(e.message);process.exitCode=1}).finally(disconnectMongo);
