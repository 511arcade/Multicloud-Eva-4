-- Esquema de la BD del ERP Cruz Azul (PostgreSQL IaaS)
CREATE TABLE IF NOT EXISTS users (
    id            SERIAL PRIMARY KEY,
    email         VARCHAR(150) UNIQUE NOT NULL,
    password_hash VARCHAR(200) NOT NULL,
    role          VARCHAR(30) NOT NULL DEFAULT 'operador',
    mfa_secret    VARCHAR(100),
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS products (
    id           SERIAL PRIMARY KEY,
    sku          VARCHAR(30) UNIQUE NOT NULL,
    nombre       VARCHAR(150) NOT NULL,
    laboratorio  VARCHAR(100),
    precio       NUMERIC(10,2) NOT NULL DEFAULT 0,
    stock        INTEGER NOT NULL DEFAULT 0,
    created_at   TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS access_log (
    id         SERIAL PRIMARY KEY,
    user_id    INTEGER REFERENCES users(id),
    action     VARCHAR(50) NOT NULL,
    ip         VARCHAR(64),
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_products_nombre ON products (nombre);
CREATE INDEX IF NOT EXISTS idx_access_log_user ON access_log (user_id);

-- Usuario de aplicación con privilegios acotados (buena práctica: no usar el superusuario)
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'erp_app') THEN
        CREATE ROLE erp_app LOGIN PASSWORD 'erp_app_pass';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE cruz_azul_erp TO erp_app;
GRANT USAGE ON SCHEMA public TO erp_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO erp_app;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO erp_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO erp_app;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT USAGE, SELECT ON SEQUENCES TO erp_app;
