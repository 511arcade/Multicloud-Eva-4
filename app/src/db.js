const { Pool } = require('pg');

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT) || 5432,
  database: process.env.DB_NAME || 'cruz_azul_erp',
  user: process.env.DB_USER || 'erp_app',
  password: process.env.DB_PASSWORD || 'erp_app_pass',
  max: 10,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

pool.on('error', (err) => {
  console.error('[DB] Error inesperado en el pool de PostgreSQL:', err.message);
});

async function connectWithRetry(retries = 5, delay = 2000) {
  for (let i = 1; i <= retries; i++) {
    try {
      const client = await pool.connect();
      await client.query('SELECT 1');
      client.release();
      console.log('[DB] Conexión a PostgreSQL establecida.');
      return;
    } catch (err) {
      console.error(`[DB] Intento ${i}/${retries} — ${err.message}`);
      if (i === retries) {
        console.error('[DB] No se pudo conectar a PostgreSQL después de varios intentos.');
        return;
      }
      await new Promise((r) => setTimeout(r, delay * i));
    }
  }
}

connectWithRetry();

module.exports = {
  query: (text, params) => pool.query(text, params),
  pool,
};
