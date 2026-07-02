require('dotenv').config();

const express = require('express');
const helmet = require('helmet');
const morgan = require('morgan');
const cookieParser = require('cookie-parser');
const path = require('path');

const authRoutes = require('./routes/auth');
const erpRoutes = require('./routes/erp');
const healthRoutes = require('./routes/health');

const app = express();
const PORT = process.env.PORT || 3000;

app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

app.use(helmet());
app.use(morgan('short'));
app.use(express.urlencoded({ extended: true }));
app.use(express.json());
app.use(cookieParser());
app.use('/static', express.static(path.join(__dirname, 'public')));

app.get('/favicon.ico', (req, res) => {
  res.set('Content-Type', 'image/svg+xml');
  res.send(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64"><rect width="64" height="64" rx="12" fill="#0a3d91"/><text x="32" y="44" font-size="36" text-anchor="middle" fill="#fff" font-family="sans-serif">C</text></svg>'
  );
});

app.get('/', (req, res) => {
  if (req.cookies && req.cookies.token) {
    return res.redirect('/erp/dashboard');
  }
  return res.redirect('/login');
});

app.use('/', healthRoutes);
app.use('/', authRoutes);
app.use('/erp', erpRoutes);

app.use((req, res) => {
  res.status(404).render('error', {
    code: 404,
    message: 'Recurso no encontrado',
  });
});

app.use((err, req, res, next) => {
  console.error('[ERROR]', err.message);
  res.status(500).render('error', {
    code: 500,
    message: 'Error interno del servidor',
  });
});

const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Cruz Azul ERP (Frontend) escuchando en http://0.0.0.0:${PORT}`);
});

function gracefulShutdown(signal) {
  console.log(`\n[SERVER] Señal ${signal} recibida. Cerrando servidor...`);
  server.close(() => {
    const { pool } = require('./db');
    pool.end(() => {
      console.log('[SERVER] Conexiones a BD cerradas. Servidor detenido.');
      process.exit(0);
    });
  });
  setTimeout(() => {
    console.error('[SERVER] Forzando cierre por timeout.');
    process.exit(1);
  }, 10000);
}

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));

module.exports = app;
