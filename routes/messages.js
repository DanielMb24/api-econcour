const express = require('express');
const router = express.Router();
const { getConnection } = require('../config/database');
const { sendEmail } = require('../services/emailService');
const emailService = require("../services/emailService");

// Récupérer les messages d'un candidat
router.get('/candidat/:nupcan', async (req, res) => {
    try {
        const { nupcan } = req.params;
        const connection = getConnection();
        
        const [messages] = await connection.execute(
            `SELECT m.*, 
                    c.nomcan, c.prncan, c.maican,
                    a.nom as admin_nom, a.prenom as admin_prenom
             FROM messages m
             LEFT JOIN candidats c ON m.candidat_nupcan = c.nupcan
             LEFT JOIN administrateurs a ON m.admin_id = a.id
             WHERE m.candidat_nupcan = ?
             ORDER BY m.created_at DESC`,
            [nupcan]
        );
        
        res.json({ success: true, data: messages });
    } catch (error) {
        console.error('Erreur récupération messages:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Récupérer tous les messages (admin) - filtrés par établissement
router.get('/admin', async (req, res) => {
    try {
        const connection = getConnection();
        const { concours_id, etablissement_id } = req.query;
        
        let query = `
            SELECT m.*, 
                   c.nomcan, c.prncan, c.maican, c.concours_id,
                   a.nom as admin_nom, a.prenom as admin_prenom,
                   con.libcnc,
                   con.etablissement_id
            FROM messages m
            LEFT JOIN candidats c ON m.candidat_nupcan = c.nupcan
            LEFT JOIN administrateurs a ON m.admin_id = a.id
            LEFT JOIN concours con ON c.concours_id = con.id
            WHERE m.expediteur = 'candidat'
        `;
        
        const params = [];
        
        // Filtrer par établissement (important pour les admins)
        if (etablissement_id) {
            query += ' AND con.etablissement_id = ?';
            params.push(etablissement_id);
        }
        
        if (concours_id) {
            query += ' AND c.concours_id = ?';
            params.push(concours_id);
        }
        
        query += ' ORDER BY m.created_at DESC';
        
        const [messages] = await connection.execute(query, params);
        res.json({ success: true, data: messages });
    } catch (error) {
        console.error('Erreur récupération messages admin:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Envoyer un message (candidat)
// Envoyer un message (candidat)
router.post('/candidat', async (req, res) => {
    try {
        const { nupcan, sujet, message, admin_id } = req.body;

        // Vérification des champs obligatoires
        if (!nupcan || !sujet || !message) {
            return res.status(400).json({
                success: false,
                message: 'NUPCAN, sujet et message requis'
            });
        }

        const connection = getConnection();

        // Vérifier que le candidat existe
        const [candidats] = await connection.execute(
            'SELECT * FROM candidats WHERE nupcan = ?',
            [nupcan]
        );

        if (candidats.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Candidat non trouvé'
            });
        }

        const candidat = candidats[0];

        // Insertion sécurisée (admin_id peut être null)
        const [result] = await connection.execute(
            `INSERT INTO messages 
                (candidat_nupcan, sujet, message, admin_id, expediteur, statut, created_at)
             VALUES (?, ?, ?, ?, 'candidat', 'non_lu', NOW())`,
            [nupcan, sujet, message, admin_id ?? null]
        );

        // Notification email aux admins
        try {
            await sendEmail(
                process.env.SMTP_USER || 'admin@gabconcours.ga',
                `Nouveau message de ${candidat.prncan} ${candidat.nomcan}`,
                `
                <div style="font-family: Arial, sans-serif; max-width: 600px;">
                    <h2>Nouveau message reçu</h2>
                    <p><strong>De:</strong> ${candidat.prncan} ${candidat.nomcan} (${nupcan})</p>
                    <p><strong>Email:</strong> ${candidat.maican}</p>
                    <p><strong>Sujet:</strong> ${sujet}</p>
                    <p><strong>Message:</strong></p>
                    <div style="background: #f5f5f5; padding: 15px; border-radius: 5px; margin: 10px 0;">
                        ${message}
                    </div>
                    <p><a href="${process.env.APP_URL || 'http://localhost:3001'}/admin/messages">Répondre au message</a></p>
                </div>
                `
            );
        } catch (emailError) {
            console.error('Erreur envoi email admin:', emailError);
        }

        res.json({
            success: true,
            message: 'Message envoyé avec succès',
            data: { id: result.insertId }
        });
    } catch (error) {
        console.error('Erreur envoi message:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Répondre à un message (admin)
router.post('/admin/repondre', async (req, res) => {
    try {
        const { message_id, nupcan, sujet, message, admin_id } = req.body;

        console.log('📩 Requête reçue pour répondre:', { message_id, nupcan, sujet, message, admin_id });

        if (!nupcan || !message) {
            return res.status(400).json({
                success: false,
                message: 'NUPCAN et message requis',
                received: { nupcan, message }
            });
        }

        if (!admin_id) {
            return res.status(400).json({
                success: false,
                message: 'admin_id requis',
                received: { admin_id }
            });
        }

        const connection = getConnection();

        // Vérifier que le candidat existe
        const [candidats] = await connection.execute(
            'SELECT * FROM candidats WHERE nupcan = ?',
            [nupcan]
        );

        if (candidats.length === 0) {
            return res.status(404).json({
                success: false,
                message: 'Candidat non trouvé'
            });
        }

        const candidat = candidats[0];

        // Insertion sécurisée de la réponse
        const [result] = await connection.execute(
            `INSERT INTO messages 
                (candidat_nupcan, admin_id, sujet, message, expediteur, statut, created_at)
             VALUES (?, ?, ?, ?, 'admin', 'non_lu', NOW())`,
            [nupcan, admin_id, sujet ?? 'Réponse à votre message', message]
        );

        // Marquer le message original comme lu
        if (message_id) {
            await connection.execute(
                'UPDATE messages SET statut = "lu" WHERE id = ?',
                [message_id]
            );
        }

        // Envoyer email au candidat
        try {
            await sendEmail(
                candidat.maican,
                `Réponse à votre message - GabConcours`,
                `
                <h2>Réponse de l'administration</h2>
                <p>Bonjour ${candidat.prncan} ${candidat.nomcan},</p>
                <p>Vous avez reçu une réponse à votre message:</p>
                <p><strong>Sujet:</strong> ${sujet ?? 'Réponse à votre message'}</p>
                <p><strong>Message:</strong></p>
                <p>${message}</p>
                <p>Connectez-vous à votre espace candidat pour voir l'historique complet.</p>
                `
            );
        } catch (emailError) {
            console.error('Erreur envoi email:', emailError);
        }

        // Notification interne
        await connection.execute(
            `INSERT INTO notifications 
                (user_type, user_id, type, titre, message, created_at)
             VALUES ('candidat', ?, 'message', 'Nouvelle réponse', ?, NOW())`,
            [nupcan, 'Vous avez reçu une réponse de l\'administration']
        );

        res.json({
            success: true,
            message: 'Réponse envoyée avec succès',
            data: { id: result.insertId }
        });

    } catch (error) {
        console.error('Erreur réponse message:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});






// Marquer un message comme lu
router.put('/:id/marquer-lu', async (req, res) => {
    try {
        const { id } = req.params;
        const connection = getConnection();
        
        await connection.execute(
            'UPDATE messages SET statut = "lu" WHERE id = ?',
            [id]
        );
        
        res.json({ success: true, message: 'Message marqué comme lu' });
    } catch (error) {
        console.error('Erreur marquage message:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

// Statistiques messages (admin)
router.get('/stats', async (req, res) => {
    try {
        const connection = getConnection();
        
        const [stats] = await connection.execute(`
            SELECT 
                COUNT(*) as total,
                SUM(CASE WHEN statut = 'non_lu' THEN 1 ELSE 0 END) as non_lus,
                SUM(CASE WHEN expediteur = 'candidat' THEN 1 ELSE 0 END) as de_candidats,
                SUM(CASE WHEN expediteur = 'admin' THEN 1 ELSE 0 END) as de_admins
            FROM messages
        `);
        
        res.json({ success: true, data: stats[0] });
    } catch (error) {
        console.error('Erreur stats messages:', error);
        res.status(500).json({ success: false, message: error.message });
    }
});

module.exports = router;
