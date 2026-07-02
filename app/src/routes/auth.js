const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const speakeasy = require('speakeasy');
const rateLimit = require('express-rate-limit');

const db = require('../db');
const { JWT_SECRET } = require('../middleware/auth');

const router = express.Router();
const MFA_ENABLED = String(process.env.MFA_ENABLED).toLowerCase() === 'true';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '1h';

function parseDuration(str) {
  const match = String(str).match(/^(\d+)\s*(s|m|h|d)$/);
  if (!match) return 3600000;
  const val = parseInt(match[1], 10);
  const mul = { s: 1000, m: 60000, h: 3600000, d: 86400000 };
  return val * (mul[match[2]] || 3600000);
}

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { error: 'Demasiados intentos. Intente nuevamente en 15 minutos.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Formulario de login
router.get('/login', (req, res) => {
  res.render('login', { error: req.query.error || null });
});

// Procesa el login: valida credenciales y emite el token JWT (acceso condicional)
router.post('/login', loginLimiter, async (req, res) => {
  const { email, password, totp } = req.body;
  try {
    const result = await db.query(
      'SELECT id, email, password_hash, role, mfa_secret FROM users WHERE email = $1',
      [email]
    );

    if (result.rows.length === 0) {
      return res.render('login', { error: 'Credenciales inválidas' });
    }

    const user = result.rows[0];
    const passwordOk = await bcrypt.compare(password || '', user.password_hash);
    if (!passwordOk) {
      return res.render('login', { error: 'Credenciales inválidas' });
    }

    // Segundo factor (MFA/TOTP) — parte del modelo AAA + MFA
    if (MFA_ENABLED && user.mfa_secret) {
      const verified = speakeasy.totp.verify({
        secret: user.mfa_secret,
        encoding: 'base32',
        token: totp || '',
        window: 1,
      });
      if (!verified) {
        return res.render('login', { error: 'Código MFA inválido' });
      }
    }

    // Emitir token de acceso
    const token = jwt.sign(
      { sub: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    // Accounting: registrar el acceso
    await db.query(
      'INSERT INTO access_log (user_id, action, ip) VALUES ($1, $2, $3)',
      [user.id, 'login', req.ip]
    );

    const maxAgeMs = parseDuration(JWT_EXPIRES_IN);
    res.cookie('token', token, {
      httpOnly: true,
      sameSite: 'lax',
      maxAge: maxAgeMs,
    });
    return res.redirect('/erp/dashboard');
  } catch (err) {
    console.error('[AUTH] Error en login:', err.message);
    return res.render('login', { error: 'Error del servidor. Intente más tarde.' });
  }
});

// Cierre de sesión
router.get('/logout', (req, res) => {
  res.clearCookie('token');
  res.redirect('/login');
});

module.exports = router;
