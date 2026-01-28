#!/bin/bash

# Script per instal·lar prometheus-snmp-exporter i configurar el dashboard de MikroTik
# SAAP - Salvador Rueda

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciant la instal·lació de prometheus-snmp-exporter...${NC}"

# 1. Instal·lar el paquet
echo -e "${GREEN}Instal·lant prometheus-snmp-exporter...${NC}"
sudo apt update
sudo apt install -y prometheus-snmp-exporter

# 2. Habilitar i iniciar el servei
echo -e "${GREEN}Habilitant el servei...${NC}"
sudo systemctl enable --now prometheus-snmp-exporter

# 3. Configurar el dashboard de MikroTik (ID 14420 o similar)
echo -e "${GREEN}Configurant el dashboard de MikroTik a Grafana...${NC}"

DASHBOARD_ID="14420"
DASH_DIR="/var/lib/grafana/dashboards"
PROV_CONF="/etc/grafana/provisioning/dashboards/mikrotik.yaml"

sudo mkdir -p $DASH_DIR
sudo mkdir -p /etc/grafana/provisioning/dashboards/

# Crear provider si no existeix
echo -e "${GREEN}Configurant el Dashboard Provider...${NC}"
sudo bash -c "cat > $PROV_CONF <<EOF
apiVersion: 1

providers:
  - name: 'MikroTik Dashboards'
    orgId: 1
    folder: 'MikroTik'
    type: file
    disableDeletion: false
    editable: true
    options:
      path: $DASH_DIR
EOF"

# Descarregar el JSON del dashboard
echo -e "${GREEN}Descarregant el JSON del dashboard ID $DASHBOARD_ID...${NC}"
DASH_JSON="$DASH_DIR/mikrotik_dashboard.json"
sudo curl -sL "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download" -o "$DASH_JSON"

# Ajustar el Data Source (Prometheus)
echo -e "${GREEN}Ajustant el Data Source a 'Prometheus'...${NC}"
sudo sed -i 's/\${DS_PROMETHEUS}/Prometheus/g' "$DASH_JSON"
# Alguns dashboards fan servir altres noms de variable
sudo sed -i 's/"datasource": "Prometheus"/"datasource": "Prometheus"/g' "$DASH_JSON"

# 4. Reiniciar Grafana
echo -e "${GREEN}Reiniciant Grafana...${NC}"
sudo systemctl restart grafana-server

echo -e "${BLUE}Instal·lació de l'exportador i dashboard completada!${NC}"
echo -e "Ara pots fer servir l'script 'add_mikrotik_router.sh' per afegir routers."
