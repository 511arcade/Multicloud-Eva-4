# 07 — Seguridad: AAA + MFA

## Modelo AAA en la solución

| Pilar | Implementación en el ERP | Evidencia |
|---|---|---|
| **Authentication** | Login con usuario/contraseña (bcrypt) y emisión de **JWT** firmado (`app/src/routes/auth.js`). | Cookie `token` httpOnly. |
| **Authorization** | Middleware `requireAuth`/`requireRole` valida el token y el rol en cada recurso protegido de `/erp/*`. | Acceso denegado (401/403) sin token válido. |
| **Accounting** | Registro de accesos en la tabla `access_log` (usuario, acción, IP, timestamp). | Consulta `SELECT * FROM access_log`. |

## Acceso condicional por token
- Los recursos bajo `/erp/*` **solo** son accesibles con un **JWT válido y no expirado**.
- El token se emite tras autenticación correcta y caduca según `JWT_EXPIRES_IN` (por defecto 1h).
- Peticiones API sin token reciben `401`; peticiones de navegador se redirigen al login.

## Multifactor (MFA / TOTP)
### A nivel de aplicación
1. Activa `MFA_ENABLED=true` en el `.env` del Web ERP.
2. Genera un secreto TOTP para el usuario y guárdalo en `users.mfa_secret`:
   ```js
   const speakeasy = require('speakeasy');
   const secret = speakeasy.generateSecret({ name: 'CruzAzulERP (admin)' });
   console.log(secret.base32);        // guardar en users.mfa_secret
   console.log(secret.otpauth_url);   // generar QR para Google Authenticator
   ```
3. En el login, además de correo/contraseña se exige el **código TOTP** (campo del formulario).

### A nivel de infraestructura (IAM)
- Habilita **MFA** en el usuario IAM: **IAM → Users → Security credentials → Assign MFA device**.
- Aplica políticas que **exijan MFA** para acciones sensibles.

## Controles de red (defensa en profundidad)
- **Security Groups por capa**: ALB (80/443 público), Web (3000 solo desde ALB), BD (5432 solo desde Web).
- **Subredes privadas** para Web ERP y BD; salida controlada por **NAT Gateway**.
- **S3** con ACL, bloqueo de acceso público de políticas y versionado.
