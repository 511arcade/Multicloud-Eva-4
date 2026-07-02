const express = require('express');
const os = require('os');

const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(requireAuth);

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
    albDns: process.env.ALB_DNS || 'cruz-azul-erp-alb-1638459563.us-east-1.elb.amazonaws.com',
    region: process.env.AWS_REGION || 'us-east-1',
    accountId: process.env.AWS_ACCOUNT_ID || '564671741661',
    jwtExpires: process.env.JWT_EXPIRES_IN || '1h',
    mfaEnabled: String(process.env.MFA_ENABLED).toLowerCase() === 'true',
  });
});

router.get('/productos', async (req, res) => {
  try {
    const r = await db.query(
      'SELECT sku, nombre, laboratorio, precio, stock FROM products ORDER BY nombre LIMIT 200'
    );
    res.render('productos', { user: req.user, productos: r.rows, instance: os.hostname() });
  } catch (err) {
    res.render('productos', { user: req.user, productos: [], error: err.message, instance: os.hostname() });
  }
});

router.get('/logs', async (req, res) => {
  try {
    const r = await db.query(
      `SELECT a.id, a.action, a.ip, a.created_at, u.email
       FROM access_log a JOIN users u ON u.id = a.user_id
       ORDER BY a.created_at DESC LIMIT 100`
    );
    res.render('logs', { user: req.user, logs: r.rows, instance: os.hostname() });
  } catch (err) {
    res.render('logs', { user: req.user, logs: [], error: err.message, instance: os.hostname() });
  }
});

router.get('/infraestructura', (req, res) => {
  res.render('infraestructura', {
    user: req.user,
    instance: os.hostname(),
    albDns: process.env.ALB_DNS || 'cruz-azul-erp-alb-1638459563.us-east-1.elb.amazonaws.com',
    asgDesired: 4,
    asgMin: 1,
    asgMax: 8,
    scalingPolicy: 'CPU 60%',
    dbHost: process.env.DB_HOST || '10.0.10.10',
  });
});

router.get('/monitoreo', (req, res) => {
  res.render('monitoreo', {
    user: req.user,
    instance: os.hostname(),
    cpuHighAlarm: 'OK',
    cpuLowAlarm: 'OK',
  });
});

router.get('/seguridad', (req, res) => {
  res.render('seguridad', {
    user: req.user,
    instance: os.hostname(),
    jwtExpires: process.env.JWT_EXPIRES_IN || '1h',
    mfaEnabled: String(process.env.MFA_ENABLED).toLowerCase() === 'true',
  });
});

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
