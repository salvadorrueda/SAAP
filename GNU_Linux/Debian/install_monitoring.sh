#!/bin/bash

# Script per instal·lar Grafana i Prometheus en un servidor Debian GNU/Linux
# Monitorització de CPU, RAM i Disc mitjançant Node Exporter

set -e

# Colors per a la sortida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Iniciant la instal·lació del sistema de monitorització...${NC}"

# 1. Actualització del sistema i dependències
echo -e "${GREEN}Actualitzant el sistema i instal·lant dependències...${NC}"
sudo apt update
sudo apt install -y apt-transport-https wget curl gnupg2

# 2. Instal·lació de Grafana
echo -e "${GREEN}Instal·lant Grafana...${NC}"
sudo mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt update
sudo apt install -y grafana
sudo systemctl enable --now grafana-server

# 3. Instal·lació de Prometheus i Node Exporter
# Nota: Debian inclou paquets de prometheus i node-exporter als seus repositoris oficials
echo -e "${GREEN}Instal·lant Prometheus i Node Exporter...${NC}"
sudo apt install -y prometheus prometheus-node-exporter

# 4. Configuració de Prometheus per fer scrape de Node Exporter
echo -e "${GREEN}Configurant Prometheus...${NC}"
# El paquet de Debian ja sol venir preconfigurat per fer scrape de localhost:9100 si node-exporter està instal·lat,
# però ens assegurem que la configuració és correcta.

PROM_CONF="/etc/prometheus/prometheus.yml"

if [ -f "$PROM_CONF" ]; then
    # Verifiquem si node_exporter ja hi és
    if ! grep -q "node_exporter" "$PROM_CONF"; then
        sudo bash -c "cat >> $PROM_CONF <<EOF

  - job_name: 'node_exporter'
    static_configs:
      - targets: ['localhost:9100']
EOF"
    fi
fi

sudo systemctl restart prometheus
sudo systemctl enable prometheus
sudo systemctl enable prometheus-node-exporter

# 5. Configuració automàtica de Prometheus com a Data Source a Grafana
echo -e "${GREEN}Configurant Prometheus com a Data Source a Grafana...${NC}"

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

echo -e "${BLUE}Instal·lació completada correctament!${NC}"
echo -e "---------------------------------------------------"
echo -e "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (usuari/clau defecte: admin/admin)"
echo -e "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo -e "---------------------------------------------------"
echo -e "${BLUE}Prometheus ja està configurat com a Data Source per defecte a Grafana.${NC}"
