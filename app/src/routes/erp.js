const express = require('express');
const os = require('os');

const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

// Todas las rutas de /erp requieren token válido (acceso condicional)
router.use(requireAuth);

// Panel principal del ERP
router.get('/dashboard', async (req, res) => {
  let productCount = 0;
  let dbStatus = 'desconocido';
  try {
    const r = await db.query('SELECT COUNT(*)::int AS n FROM products');
    productCount = r.rows[0].n;
    dbStatus = 'conectada';
  } catch (err) {
    dbStatus = 'error: ' + err.message;
  }
  res.render('dashboard', {
    user: req.user,
    instance: os.hostname(),
    productCount,
    dbStatus,
  });
});

// Inventario de productos (recurso protegido, lee de PostgreSQL)
router.get('/productos', async (req, res) => {
  try {
    const r = await db.query(
      'SELECT sku, nombre, laboratorio, precio, stock FROM products ORDER BY nombre LIMIT 200'
    );
    res.render('productos', { user: req.user, productos: r.rows });
  } catch (err) {
    res.render('productos', { user: req.user, productos: [], error: err.message });
  }
});

// API JSON protegida (consumo seguro por token). Ej: para pruebas de estrés/benchmark.
router.get('/api/productos', (req, res) => {
  db.query('SELECT sku, nombre, precio, stock FROM products ORDER BY nombre LIMIT 500')
    .then((r) => res.json({ instance: os.hostname(), count: r.rowCount, data: r.rows }))
    .catch((err) => res.status(500).json({ error: err.message }));
});

function burnCPU(durationMs) {
  return new Promise((resolve) => {
    const end = Date.now() + durationMs;
    let x = 0;
    function tick() {
      if (Date.now() >= end) {
        return resolve(x);
      }
      for (let i = 0; i < 50000; i++) {
        x += Math.sqrt(Math.random() * 1e9);
      }
      setImmediate(tick);
    }
    tick();
  });
}

router.get('/api/cpu-load', requireRole('admin'), async (req, res) => {
  const ms = Math.min(Number(req.query.ms) || 2000, 15000);
  const checksum = await burnCPU(ms);
  res.json({ instance: os.hostname(), busyMs: ms, checksum });
});

module.exports = router;
