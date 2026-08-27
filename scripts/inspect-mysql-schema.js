const mysql = require('mysql2/promise');
const { dbConfig } = require('../config/database');

(async () => {
  const db = await mysql.createConnection(dbConfig);
  try {
    let [tables] = await db.query(`SELECT TABLE_NAME tableName, TABLE_ROWS estimatedRows FROM information_schema.TABLES WHERE TABLE_SCHEMA = ? ORDER BY TABLE_NAME`, [dbConfig.database]);
    const selectedArg = process.argv.find(arg => arg.startsWith('--tables='));
    if (selectedArg) { const selected = new Set(selectedArg.slice(9).split(',').filter(Boolean)); tables = tables.filter(table => selected.has(table.tableName)); }
    const result = [];
    for (const table of tables) {
      const [columns] = await db.query(`SELECT COLUMN_NAME name, DATA_TYPE type, IS_NULLABLE nullable, COLUMN_KEY columnKey FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY ORDINAL_POSITION`, [dbConfig.database, table.tableName]);
      const [[count]] = await db.query(`SELECT COUNT(*) total FROM \`${table.tableName}\``);
      result.push({ table: table.tableName, rows: Number(count.total), columns });
    }
    if (process.argv.includes('--summary')) console.log(JSON.stringify({ database: dbConfig.database, tables: result.map(({ table, rows }) => ({ table, rows })) }, null, 2));
    else console.log(JSON.stringify({ database: dbConfig.database, tables: result }, null, 2));
  } finally { await db.end(); }
})().catch(error => { console.error(JSON.stringify({ name: error.name, code: error.code, message: error.message })); process.exit(1); });
