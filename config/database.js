const mysql = require('mysql2/promise');
const {createPool} = require("mysql2");
require('dotenv').config();

const dbConfig = {
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'gabconcours',
    port: process.env.DB_PORT || 3306,
    charset: 'utf8mb4',
    timezone: '+00:00'
};

let pool;

const createConnection = async () => {
    try {
        pool = mysql.createPool({
            ...dbConfig,
            waitForConnections: true,
            connectionLimit: 10,
            queueLimit: 0
        });

        console.log(' Connexion à MySQL établie');
        return pool;
    } catch (error) {
        console.error(' Erreur de connexion à MySQL:', error);
        throw error;
    }
};

const getConnection = () => {
    if (!pool) {
        throw new Error('Base de données non initialisée');
    }
    return pool;
};

const testConnection = async () => {
    try {
        if (!pool) {
            await createConnection();
        }
        const connection = await pool.getConnection();
        await connection.execute('SELECT 1');
        connection.release();
        return {success: true, message: 'Connexion à la base de données réussie'};
    } catch (error) {
        console.error('Erreur de test de connexion:', error);
        throw error;
    }
};




// Gestion auto-reconnexion si pool fermé
process.on('uncaughtException', async (err) => {
    console.error(' Exception non gérée:', err);
    if (err.message.includes('Pool is closed')) {
        console.log(' Tentative de recréation du pool...');
        await createConnection();
    }
});

process.on('unhandledRejection', async (err) => {
    console.error(' Rejection non gérée:', err);
    if (err.message.includes('Pool is closed')) {
        console.log(' Tentative de recréation du pool...');
        await createConnection();
    }
});

module.exports = {
    createConnection,
    getConnection,
    testConnection,
    dbConfig
};
//
// const { Pool } = require('pg');
// require('dotenv').config();
//
// let pool;
//
// /**
//  * Crée le pool de connexions PostgreSQL
//  */
// const createConnection = async () => {
//     try {
//         pool = new Pool({
//             connectionString: process.env.DATABASE_URL, // Utilise DATABASE_URL Render
//             ssl: { rejectUnauthorized: false },         // Obligatoire sur Render
//             max: 10,                                    // Connexions max
//             idleTimeoutMillis: 30000,                   // Temps avant libération
//         });
//
//         // Test rapide de la connexion
//         const client = await pool.connect();
//         await client.query('SELECT NOW()');
//         client.release();
//
//         console.log(' Connexion à PostgreSQL établie');
//         return pool;
//     } catch (error) {
//         console.error(' Erreur de connexion à PostgreSQL :', error);
//         throw error;
//     }
// };
//
// /**
//  * Récupère le pool existant
//  */
// const getConnection = () => {
//     if (!pool) {
//         throw new Error('Base de données non initialisée. Appelez createConnection() d’abord.');
//     }
//     return pool;
// };
//
// /**
//  * Test de connexion
//  */
// const testConnection = async () => {
//     try {
//         if (!pool) await createConnection();
//         const client = await pool.connect();
//         const result = await client.query('SELECT 1');
//         client.release();
//         return { success: true, message: 'Connexion PostgreSQL réussie ✅', result: result.rows };
//     } catch (error) {
//         console.error('❌ Erreur de test de connexion :', error);
//         throw error;
//     }
// };
//
// /**
//  * Gestion auto-reconnexion si le pool plante
//  */
// process.on('uncaughtException', async (err) => {
//     console.error('💥 Exception non gérée :', err);
//     if (err.message.includes('pool')) {
//         console.log('🔄 Tentative de recréation du pool...');
//         await createConnection();
//     }
// });
//
// process.on('unhandledRejection', async (err) => {
//     console.error('💥 Rejection non gérée :', err);
//     if (err.message.includes('pool')) {
//         console.log('🔄 Tentative de recréation du pool...');
//         await createConnection();
//     }
// });
//
// module.exports = {
//     createConnection,
//     getConnection,
//     testConnection,
// };
