#!/bin/bash

# Script per instal·lar Node Exporter en un servidor Linux remot
# SAAP - Salvador Rueda

set -e

# Colors per a la sortida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciant la instal·lació de Node Exporter...${NC}"

# 1. Actualització de repositoris
echo -e "${GREEN}Actualitzant llistes de paquets...${NC}"
sudo apt update

# 2. Instal·lació de Node Exporter
echo -e "${GREEN}Instal·lant prometheus-node-exporter...${NC}"
sudo apt install -y prometheus-node-exporter

# 3. Habilitar i iniciar el servei
echo -e "${GREEN}Configurant el servei per iniciar-se automàticament...${NC}"
sudo systemctl enable --now prometheus-node-exporter

# 4. Verificació
echo -e "${BLUE}Instal·lació completada correctament!${NC}"
echo -e "Node Exporter està corrent al port 9100."
echo -e "Pots verificar-ho amb: curl http://localhost:9100/metrics"

# 5. Recordatori de Firewall
echo -e "${BLUE}IMPORTANT:${NC} Recorda obrir el port 9100/TCP al tallafocs si és necessari."
echo -e "Exemple amb UFW: sudo ufw allow 9100/tcp"
