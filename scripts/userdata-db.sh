#!/bin/bash
# =====================================================================
# user-data: Instancia EC2 de BASE DE DATOS (PostgreSQL dockerizado - IaaS)
# Amazon Linux 2023. Se ejecuta al primer arranque de la instancia.
# =====================================================================
set -euxo pipefail

dnf update -y
dnf install -y docker git
systemctl enable --now docker

# docker compose plugin
DOCKER_CONFIG=/usr/local/lib/docker
mkdir -p "$DOCKER_CONFIG/cli-plugins"
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o "$DOCKER_CONFIG/cli-plugins/docker-compose"
chmod +x "$DOCKER_CONFIG/cli-plugins/docker-compose"

# Clonar el proyecto en la ruta mandatoria
mkdir -p /srv
cd /srv
if [ ! -d /srv/cruz_azul-erp ]; then
  git clone https://github.com/CHANGE_ME/cruz_azul-erp.git
fi
cd /srv/cruz_azul-erp/database

# Variables de BD (ajústalas o usa Secrets Manager en producción)
cat > .env <<'EOF'
POSTGRES_DB=cruz_azul_erp
POSTGRES_USER=erp_admin
POSTGRES_PASSWORD=CHANGE_ME_STRONG_PASSWORD
EOF

# Levantar PostgreSQL. Nota: para permitir conexiones desde el SG-Web,
# el contenedor ya expone 5432; el acceso se restringe por Security Group.
docker compose up -d

echo "PostgreSQL dockerizado en ejecución en el puerto 5432" > /var/log/cruz-azul-db-init.log
