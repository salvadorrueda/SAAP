#!/bin/bash

# Comprovar si s'executa com a root
if [ "$EUID" -ne 0 ]; then
  echo "Si us plau, executa l'script com a root (sudo)."
  exit 1
fi

echo "Actualitzant la llista de paquets..."
apt update

# Comprovar si ssh està instal·lat
if ! dpkg -l | grep -q openssh-server; then
  echo "SSH no està instal·lat. Instal·lant openssh-server..."
  apt install -y openssh-server
else
  echo "SSH ja està instal·lat."
fi

# Configurar el port 2222
echo "Configurant el port 2222..."
sed -i 's/^#Port 22/Port 2222/' /etc/ssh/sshd_config
sed -i 's/^Port 22/Port 2222/' /etc/ssh/sshd_config

# Configurar el banner
BANNER_FILE="/etc/ssh/banner"
echo "Benvingut al servidor" > "$BANNER_FILE"
echo "Configurant el banner..."
sed -i 's|^#Banner none|Banner '"$BANNER_FILE"'|' /etc/ssh/sshd_config
sed -i 's|^Banner .*|Banner '"$BANNER_FILE"'|' /etc/ssh/sshd_config

# Reiniciar el servei per aplicar els canvis
echo "Reiniciant el servei SSH..."
systemctl restart ssh

echo "Configuració finalitzada amb èxit."
echo "Port: 2222"
echo "Banner: $BANNER_FILE"
