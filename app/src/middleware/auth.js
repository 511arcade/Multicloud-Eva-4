const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET;
if (!JWT_SECRET) {
  console.error('[AUTH] JWT_SECRET no está definido en el entorno. Asignando valor por defecto (solo para desarrollo).');
}

function extractToken(req) {
  if (req.cookies && req.cookies.token) {
    return req.cookies.token;
  }
  const header = req.headers.authorization;
  if (header && header.startsWith('Bearer ')) {
    return header.slice(7);
  }
  return null;
}

function requireAuth(req, res, next) {
  const token = extractToken(req);
  if (!token) {
    return denyAccess(req, res, 'No autenticado: token ausente');
  }
  try {
    const secret = JWT_SECRET || 'dev-secret';
    const payload = jwt.verify(token, secret);
    req.user = payload;
    return next();
  } catch (err) {
    return denyAccess(req, res, 'Token inválido o expirado');
  }
}

function requireRole(...roles) {
  return (req, res, next) => {
    if (!req.user || !roles.includes(req.user.role)) {
      return denyAccess(req, res, 'No autorizado para este recurso', 403);
    }
    return next();
  };
}

function denyAccess(req, res, message, status = 401) {
  const wantsJson = req.headers.accept && req.headers.accept.includes('application/json');
  if (wantsJson) {
    return res.status(status).json({ error: message });
  }
  return res.redirect('/login?error=' + encodeURIComponent(message));
}

module.exports = { requireAuth, requireRole, extractToken, JWT_SECRET };
