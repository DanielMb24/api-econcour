// services/emailService.js
const nodemailer = require('nodemailer');
require('dotenv').config();

// ---------------------------
// CONFIGURATION DU TRANSPORTEUR SMTP
// ---------------------------
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: process.env.EMAIL_USER, // ex: tonadresse@gmail.com
        pass: process.env.EMAIL_PASSWORD, // mot de passe ou "App Password"
    },
});

// Vérification initiale (utile en dev)
transporter.verify((error, success) => {
    if (error) {
        console.error('❌ Erreur de configuration email:', error);
    } else {
        console.log('✅ Serveur mail prêt à envoyer des messages');
    }
});

// ---------------------------
// SERVICE : Envoi du reçu PDF
// ---------------------------
async function sendReceiptEmail({ to, nupcan, candidatData }) {
    const { prncan, nomcan } = candidatData.candidat || {};
    const concours = candidatData.concours?.libcnc || 'Concours';

    const html = `
    <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
      <h2>🎓 GABConcours</h2>
      <p>Bonjour <strong>${prncan || ''} ${nomcan || ''}</strong>,</p>
      <p>Votre candidature pour <strong>${concours}</strong> a été enregistrée.</p>
      <p><strong>NUPCAN :</strong> ${nupcan}</p>
      <p>Conservez bien ce numéro, il vous servira pour le suivi de votre dossier.</p>
      <p><a href="${process.env.APP_URL || 'http://localhost:3001'}/dashboard/${nupcan}">Accéder à votre espace candidat</a></p>
      <p>Cordialement,<br/>L'équipe GABConcours</p>
    </div>
  `;

    await transporter.sendMail({
        from: `"GABConcours" <${process.env.EMAIL_USER}>`,
        to,
        subject: `📋 Reçu de candidature - ${nupcan}`,
        html,
    });
}

// ---------------------------
// SERVICE : Envoi du reçu image (Base64 PNG ou JPEG)
// ---------------------------
async function sendReceiptImageEmail({ to, nupcan, candidatData, imageData }) {
    const { prncan, nomcan } = candidatData.candidat || {};

    const html = `
    <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
      <h2>🎓 Reçu de candidature GABConcours</h2>
      <p>Bonjour <strong>${prncan || ''} ${nomcan || ''}</strong>,</p>
      <p>Veuillez trouver ci-joint le reçu de votre candidature (format image).</p>
      <p><strong>NUPCAN :</strong> ${nupcan}</p>
      <p>Cordialement,<br/>L'équipe GABConcours</p>
    </div>
  `;

    await transporter.sendMail({
        from: `"GABConcours" <${process.env.EMAIL_USER}>`,
        to,
        subject: `📋 Reçu image - ${nupcan}`,
        html,
        attachments: [
            {
                filename: `Recu_Candidature_${nupcan}.png`,
                content: imageData.split(',')[1], // retire "data:image/png;base64,"
                encoding: 'base64',
                contentType: 'image/png',
            },
        ],
    });
}

// ---------------------------
// SERVICE : Notification de validation/rejet de document
// ---------------------------
async function sendDocumentValidationEmail({ to, documentName, statut, commentaire }) {
    const isValidated = statut.toLowerCase() === 'valide';
    const subject = isValidated
        ? `✅ Document validé - ${documentName}`
        : `❌ Document rejeté - ${documentName}`;

    const html = `
    <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
      <h2>${isValidated ? '✅ Document validé' : '❌ Document rejeté'}</h2>
      <p>Bonjour,</p>
      <p>Le document <strong>${documentName}</strong> a été <strong>${isValidated ? 'validé' : 'rejeté'}</strong>.</p>
      ${
        commentaire
            ? `<div style="background:#f3f4f6;padding:10px;border-radius:6px;margin:15px 0;">
              <strong>Commentaire :</strong><p>${commentaire}</p>
            </div>`
            : ''
    }
      <p>Cordialement,<br/>L'équipe GABConcours</p>
    </div>
  `;

    await transporter.sendMail({
        from: `"GABConcours" <${process.env.EMAIL_USER}>`,
        to,
        subject,
        html,
    });
}

// ---------------------------
// EXPORT
// ---------------------------
module.exports = {
    sendReceiptEmail,
    sendReceiptImageEmail,
    sendDocumentValidationEmail,
};
