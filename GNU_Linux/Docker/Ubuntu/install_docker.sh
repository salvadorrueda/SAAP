#!/bin/bash

# Script per instal·lar Docker en Ubuntu Desktop
# Referència: https://docs.docker.com/engine/install/ubuntu/

set -e

echo "S'està actualitzant l'índex de paquets..."
sudo apt-get update

echo "S'estan instal·lant els requisits previs..."
sudo apt-get install -y ca-certificates curl

echo "S'està afegint la clau GPG oficial de Docker..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "S'està afegint el repositori de Docker a les fonts d'Apt..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "S'està actualitzant l'índex de paquets (amb el nou repositori)..."
sudo apt-get update

echo "S'està instal·lant Docker Engine i Docker Compose..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "S'està configurant l'usuari actual per utilitzar Docker sense sudo..."
sudo usermod -aG docker $USER

echo "------------------------------------------------------------"
echo "Instal·lació completada!"
echo "ATENCIÓ: Has de tancar la sessió i tornar-la a obrir perquè els canvis de grup tinguin efecte."
echo "Pots verificar la instal·lació amb: docker --version"
echo "------------------------------------------------------------"
