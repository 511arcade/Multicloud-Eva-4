#!/bin/bash
set -euxo pipefail

dnf update -y
dnf install -y git

curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
dnf install -y nodejs

rm -rf /srv/cruz_azul-erp
mkdir -p /srv
cd /srv
git clone https://github.com/511arcade/Multicloud-Eva-4.git /srv/cruz_azul-erp
cd /srv/cruz_azul-erp/app

npm install --omit=dev

cat > .env <<'EOF'
PORT=3000
DB_HOST=CHANGE_ME_DB_PRIVATE_IP
DB_PORT=5432
DB_NAME=cruz_azul_erp
DB_USER=erp_app
DB_PASSWORD=erp_app_pass
JWT_SECRET=CHANGE_ME_LONG_RANDOM_SECRET
JWT_EXPIRES_IN=1h
MFA_ENABLED=false
EOF

cat > /etc/systemd/system/cruz-azul-erp.service <<'EOF'
[Unit]
Description=Cruz Azul ERP Frontend
After=network.target

[Service]
Type=simple
WorkingDirectory=/srv/cruz_azul-erp/app
ExecStart=/usr/bin/node src/server.js
Restart=always
RestartSec=5
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cruz-azul-erp.service

echo "Frontend Web ERP en ejecucion en el puerto 3000" > /var/log/cruz-azul-web-init.log
