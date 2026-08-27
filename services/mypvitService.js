// services/mypvitService.js
const axios = require('axios');

const MYPVIT_API_KEY = process.env.MYPVIT_API_KEY;
const MYPVIT_MERCHANT_ID = process.env.MYPVIT_MERCHANT_ID;
const MYPVIT_BASE_URL = process.env.MYPVIT_BASE_URL || "https://api.mypvit.com/v1";

/**
 * Initialise un paiement MyPVIT (Push USSD/STK)
 * @param {Object} paiementData - Données du paiement
 * @returns {Promise<Object>} Résultat de l'initialisation
 */
async function initPayment(paiementData) {
    try {
        const payload = {
            merchant_id: MYPVIT_MERCHANT_ID,
            api_key: MYPVIT_API_KEY,
            reference: paiementData.reference_paiement,
            amount: parseFloat(paiementData.montant),
            currency: "XAF",
            description: `Frais concours - ${paiementData.nupcan}`,
            callback_url: `${process.env.APP_URL}/api/mypvit/callback`,
            return_url: `${process.env.APP_URL}/candidat/${paiementData.nupcan}/paiement-success`,
            customer_phone: paiementData.numero_telephone,
            customer_name: paiementData.nupcan,
            metadata: JSON.stringify({
                nupcan: paiementData.nupcan,
                candidat_id: paiementData.candidat_id,
                concours_id: paiementData.concours_id
            })
        };

        console.log("🔵 MyPVIT - Initialisation paiement:", payload);

        const response = await axios.post(`${MYPVIT_BASE_URL}/payment/init`, payload, {
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${MYPVIT_API_KEY}`
            }
        });

        if (response.data.status === "success" || response.data.code === "00") {
            return {
                success: true,
                message: "Paiement initialisé avec succès",
                payment_url: response.data.data?.payment_url,
                transaction_id: response.data.data?.transaction_id,
                ussd_code: response.data.data?.ussd_code
            };
        } else {
            throw new Error(response.data.message || "Erreur MyPVIT");
        }
    } catch (error) {
        console.error("❌ MyPVIT - Erreur initPayment:", error.message);
        return {
            success: false,
            message: error.response?.data?.message || error.message
        };
    }
}

/**
 * Vérifie le statut d'un paiement MyPVIT
 * @param {string} transaction_id - ID de la transaction
 * @returns {Promise<Object>} Statut du paiement
 */
async function verifyPayment(transaction_id) {
    try {
        const response = await axios.get(`${MYPVIT_BASE_URL}/payment/status/${transaction_id}`, {
            headers: {
                'Authorization': `Bearer ${MYPVIT_API_KEY}`
            }
        });

        return {
            success: true,
            status: response.data.status,
            data: response.data.data
        };
    } catch (error) {
        console.error("❌ MyPVIT - Erreur verifyPayment:", error.message);
        throw error;
    }
}

module.exports = { initPayment, verifyPayment };
