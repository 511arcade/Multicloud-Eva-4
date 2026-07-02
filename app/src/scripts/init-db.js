/**
 * Inicializa el esquema y datos de ejemplo desde la app (alternativa al seed de Docker).
 * Uso: npm run init-db
 *
 * NOTA: 01-schema.sql ejecuta CREATE ROLE / GRANT, por lo que este script debe correr
 * con un usuario SUPERUSUARIO de PostgreSQL (ej. erp_admin), no con erp_app.
 * Ajusta temporalmente DB_USER/DB_PASSWORD en el .env al superusuario para inicializar.
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const db = require('../db');

async function main() {
  const projectRoot = path.resolve(__dirname, '..', '..', '..');
  const sql = fs.readFileSync(
    path.join(projectRoot, 'database', 'init', '01-schema.sql'),
    'utf8'
  );
  const seed = fs.readFileSync(
    path.join(projectRoot, 'database', 'init', '02-seed.sql'),
    'utf8'
  );
  console.log('Aplicando esquema...');
  await db.query(sql);
  console.log('Insertando datos de ejemplo...');
  await db.query(seed);
  console.log('Listo.');
  await db.pool.end();
}

main().catch((err) => {
  console.error('Error inicializando BD:', err.message);
  process.exit(1);
});
