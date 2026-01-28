#!/bin/bash

# Script per importar automàticament el dashboard "Node Exporter Full" (ID 1860)
# utilitzant el sistema de provisioning de Grafana.

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

DASHBOARD_ID="1860"
DASH_DIR="/var/lib/grafana/dashboards"
PROV_CONF="/etc/grafana/provisioning/dashboards/dashboards.yaml"

echo -e "${BLUE}Preparant la importació automàtica del dashboard ID $DASHBOARD_ID...${NC}"

# 1. Crear directoris necessaris
sudo mkdir -p $DASH_DIR
sudo mkdir -p /etc/grafana/provisioning/dashboards/

# 2. Configurar el Dashboard Provider
echo -e "${GREEN}Configurant el Dashboard Provider...${NC}"
sudo bash -c "cat > $PROV_CONF <<EOF
apiVersion: 1

providers:
  - name: 'Standard Dashboards'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    editable: true
    options:
      path: $DASH_DIR
EOF"

# 3. Descarregar el JSON del dashboard
# Nota: La URL directa de grafana.com sol ser https://grafana.com/api/dashboards/<ID>/revisions/latest/download
echo -e "${GREEN}Descarregant el JSON del dashboard ID $DASHBOARD_ID...${NC}"
DASH_JSON="$DASH_DIR/node_exporter_full.json"
sudo curl -sL "https://grafana.com/api/dashboards/$DASHBOARD_ID/revisions/latest/download" -o "$DASH_JSON"

# 4. Ajustar el Data Source (Prometheus)
# El dashboard descarregat sol tenir placeholders com "\${DS_PROMETHEUS}". 
# Els substituïm pel nom del nostre Data Source ("Prometheus")
sudo sed -i 's/${DS_PROMETHEUS}/Prometheus/g' "$DASH_JSON"

# 5. Reiniciar Grafana per aplicar els canvis
echo -e "${GREEN}Reiniciant Grafana per carregar el nou dashboard...${NC}"
sudo systemctl restart grafana-server

echo -e "${BLUE}Importació finalitzada!${NC}"
echo -e "El dashboard ja hauria de ser visible a Grafana dins la secció 'Dashboards'."
