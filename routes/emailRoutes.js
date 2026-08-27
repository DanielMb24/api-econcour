// routes/emailRoutes.js
const express = require('express');
const router = express.Router();
require('dotenv').config();

const { sendEmail } = require('../mailer'); // ✅ Vérifie le bon chemin selon ta structure

/**
 * 🔧 Fonction utilitaire : détermine l'email destinataire
 */
function resolveRecipient(body) {
    return (
        body.to ||
        body.maican ||
        body.email ||
        body.candidat?.maican ||
        body.candidatData?.maican ||
        body.candidatData?.candidat?.maican ||
        null
    );
}

/* ============================================================
   1️⃣  ROUTE : Envoi du reçu de candidature
   Endpoint : POST /api/email/receipt
   ============================================================ */
router.post('/receipt', async (req, res) => {
    try {
        const { maican, nupcan, candidatData = {}, pdfAttachment, attachmentType } = req.body;
        const to = resolveRecipient(req.body);
        if (!to) return res.status(400).json({ success: false, message: 'Adresse email manquante.' });
        if (!nupcan) return res.status(400).json({ success: false, message: 'NUPCAN manquant.' });

        const attachments = [];
        if (pdfAttachment) {
            attachments.push({
                filename: `Recu_Candidature_${nupcan}.pdf`,
                content: pdfAttachment,
                encoding: 'base64',
                contentType: 'application/pdf'
            });
        }

        const html = `
            <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
                <h2 style="color:#0b5394;">🎓 GABConcours</h2>
                <p>Bonjour <strong>${candidatData?.candidat?.prncan || ''} ${candidatData?.candidat?.nomcan || ''}</strong>,</p>
                <p>Votre candidature pour <strong>${candidatData?.concours?.libcnc || ''}</strong> a été enregistrée avec succès.</p>
                <p><strong>NUPCAN :</strong> ${nupcan}</p>
                <p>Documents soumis : <strong>${(candidatData?.documents?.length) || 0}</strong></p>
                <p>Veuillez conserver ce reçu. Il est joint en pièce jointe (PDF).</p>
                <p><a href="${process.env.APP_URL || 'http://localhost:8080'}/dashboard/${nupcan}">Accéder à votre espace candidat</a></p>
                <p style="margin-top:20px;">Cordialement,<br/><strong>L'équipe GABConcours</strong></p>
            </div>
        `;

        const result = await sendEmail(to, `📋 Reçu de candidature - ${nupcan} - GABConcours`, html, attachments);

        if (!result.success) throw new Error(result.message || 'Erreur envoi email.');
        return res.json({ success: true, message: 'Reçu envoyé par email avec succès.' });
    } catch (error) {
        console.error('❌ Erreur /receipt:', error);
        return res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi du reçu', error: error.message });
    }
});


/* ============================================================
   2️⃣  ROUTE : Notification de validation ou rejet de document
   Endpoint : POST /api/email/document-validation
   ============================================================ */
router.post('/document-validation', async (req, res) => {
    try {
        const { candidat, document, statut, commentaire } = req.body;
        const to = resolveRecipient(req.body);

        if (!to) return res.status(400).json({ success: false, message: 'Email destinataire manquant.' });
        if (!document || !document.nomdoc) return res.status(400).json({ success: false, message: 'Document manquant.' });

        const isValidated = String(statut).toLowerCase() === 'valide';
        const subject = isValidated
            ? `✅ Document validé - ${candidat?.nupcan || ''} - GABConcours`
            : `❌ Document rejeté - ${candidat?.nupcan || ''} - GABConcours`;

        const html = `
            <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
                <h2 style="color:${isValidated ? '#008000' : '#d00000'};">
                    ${isValidated ? '✅ Document Validé' : '❌ Document Rejeté'}
                </h2>
                <p>Bonjour <strong>${candidat?.prncan || ''} ${candidat?.nomcan || ''}</strong>,</p>
                <p>Le document <strong>${document.nomdoc}</strong> a été <strong>${isValidated ? 'validé' : 'rejeté'}</strong>.</p>
                ${commentaire ? `
                    <div style="background:#f3f4f6;padding:10px;border-radius:6px;margin:15px 0;">
                        <strong>Commentaire :</strong><p>${commentaire}</p>
                    </div>` : ''
                }
                <p><a href="${process.env.APP_URL || 'http://localhost:8080'}/dashboard/${candidat?.nupcan || ''}">Accéder à mon espace candidat</a></p>
                <p style="margin-top:20px;">Cordialement,<br/><strong>L'équipe GABConcours</strong></p>
            </div>
        `;

        const result = await sendEmail(to, subject, html);

        if (!result.success) throw new Error(result.message || 'Erreur lors de l\'envoi du mail.');

        return res.json({ success: true, message: 'Notification envoyée avec succès.' });
    } catch (error) {
        console.error('❌ Erreur /document-validation:', error);
        return res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi de la notification', error: error.message });
    }
});


/* ============================================================
   3️⃣  ROUTE : Envoi des identifiants à un nouvel administrateur
   Endpoint : POST /api/email/admin-credentials
   ============================================================ */
router.post('/admin-credentials', async (req, res) => {
    try {
        const { admin } = req.body;
        if (!admin || !admin.email) return res.status(400).json({ success: false, message: 'Objet admin ou email manquant.' });

        const passwordDisplay = admin.password
            ? `<p><strong>Mot de passe :</strong> ${admin.password}</p>`
            : '';

        const html = `
            <div style="font-family: Arial, sans-serif; max-width:600px;margin:0 auto;">
                <h2 style="color:#0b5394;">Bienvenue sur GABConcours</h2>
                <p>Bonjour <strong>${admin.prenom || ''} ${admin.nom || ''}</strong>,</p>
                <p>Votre compte administrateur a été créé avec succès.</p>
                <p><strong>Email :</strong> ${admin.email}</p>
                ${passwordDisplay}
                <p>Connectez-vous ici : 
                    <a href="${process.env.APP_URL || 'http://localhost:8080'}/login">
                        ${process.env.APP_URL || 'http://localhost:8080'}/login
                    </a>
                </p>
                <p>⚠️ Pour votre sécurité, changez votre mot de passe dès la première connexion.</p>
                <p style="margin-top:20px;">Cordialement,<br/><strong>L'équipe GABConcours</strong></p>
            </div>
        `;

        const result = await sendEmail(admin.email, 'Identifiants administrateur - GABConcours', html);

        if (!result.success) throw new Error(result.message || 'Erreur lors de l\'envoi.');

        return res.json({ success: true, message: 'Identifiants envoyés avec succès.' });
    } catch (error) {
        console.error('❌ Erreur /admin-credentials:', error);
        return res.status(500).json({ success: false, message: 'Erreur lors de l\'envoi des identifiants', error: error.message });
    }
});

module.exports = router;
