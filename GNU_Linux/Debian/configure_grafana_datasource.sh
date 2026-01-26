#!/bin/bash

# Script per configurar automàticament Prometheus com a Data Source a Grafana
# utilitzant el sistema de provisioning de Grafana.

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configurant Prometheus com a Data Source a Grafana...${NC}"

# Ruta del fitxer de configuració de provisioning
DATASOURCE_CONF="/etc/grafana/provisioning/datasources/prometheus.yaml"

# Creem el directori si no existeix (tot i que grafana ja el sol crear)
sudo mkdir -p /etc/grafana/provisioning/datasources/

# Creem el fitxer de configuració YAML
sudo bash -c "cat > $DATASOURCE_CONF <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090
    isDefault: true
    editable: true
EOF"

# Reiniciem Grafana per aplicar els canvis
echo -e "${GREEN}Reiniciant Grafana per aplicar la configuració...${NC}"
sudo systemctl restart grafana-server

echo -e "${BLUE}Configuració finalitzada!${NC}"
echo -e "Prometheus ja s'hauria de veure com a Data Source per defecte a Grafana."
