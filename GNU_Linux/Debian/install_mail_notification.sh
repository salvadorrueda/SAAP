#!/bin/bash

# Script per configurar l'enviament de correu a Debian utilitzant msmtp
# Autor: Antigravity
# Data: 2026-01-22

# Comprovació de root
if [ "$EUID" -ne 0 ]; then
  echo "Si us plau, executa aquest script com a root (sudo)."
  exit 1
fi

echo "--- Configuració de Notificacions per Correu (msmtp) ---"

# Paràmetres predeterminats
RECIPIENT_EMAIL="salvador.rueda@gmail.com"
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"

# Demanar dades a l'usuari
read -p "Introdueix la teva adreça de Gmail (ex: usuari@gmail.com): " GMAIL_USER
read -s -p "Introdueix la Contrasenya d'Aplicació de Gmail: " GMAIL_PASS
echo ""

# 1. Instal·lació de paquets
echo "Instal·lant msmtp i msmtp-mta..."
apt update && apt install -y msmtp msmtp-mta mailutils

# 2. Configuració de /etc/msmtprc
echo "Configurant /etc/msmtprc..."
cat <<EOF > /etc/msmtprc
# Configuració global
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/msmtp.log

# Compte Gmail
account        gmail
host           ${SMTP_SERVER}
port           ${SMTP_PORT}
from           ${GMAIL_USER}
user           ${GMAIL_USER}
password       ${GMAIL_PASS}

# Compte per defecte
account default : gmail
EOF

# Ajustar permisos de seguretat
chmod 600 /etc/msmtprc
chown root:msmtp /etc/msmtprc

# 3. Configuració d'àlies per al sistema
echo "Configurant àlies de correu..."
# Redirigir root i default a l'adreça de destí
if ! grep -q "root:" /etc/aliases; then
    echo "root: ${RECIPIENT_EMAIL}" >> /etc/aliases
else
    sed -i "s/^root:.*/root: ${RECIPIENT_EMAIL}/" /etc/aliases
fi

if ! grep -q "default:" /etc/aliases; then
    echo "default: ${RECIPIENT_EMAIL}" >> /etc/aliases
else
    sed -i "s/^default:.*/default: ${RECIPIENT_EMAIL}/" /etc/aliases
fi

# 4. Crear el fitxer de log amb permisos correctes
touch /var/log/msmtp.log
chown root:msmtp /var/log/msmtp.log
chmod 664 /var/log/msmtp.log

echo ""
echo "--- Configuració finalitzada ---"
echo "Pots fer una prova executant:"
echo "echo \"Prova enviament\" | mail -s \"Test Debian\" root"
echo "Revisa /var/log/msmtp.log si hi ha problemes."
