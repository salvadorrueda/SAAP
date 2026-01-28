#!/bin/bash

# Script per instal·lar Grafana i Prometheus amb Docker i Docker Compose
# Monitorització de CPU, RAM i Disc mitjançant Node Exporter

set -e

# Colors per a la sortida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Iniciant la instal·lació del sistema de monitorització amb Docker...${NC}"

# 1. Comprovació i instal·lació de Docker
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}Docker no detectat. Instal·lant Docker...${NC}"
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo \
      "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
      "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
else
    echo -e "${GREEN}Docker ja està instal·lat.${NC}"
fi

# 2. Configuració del directori i fitxers
echo -e "${GREEN}Configurant directori i fitxers...${NC}"
INSTALL_DIR="$HOME/docker_monitoring"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Prometheus config
cat > prometheus.yml <<EOF
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node-exporter:9100']
EOF

# Grafana Datasource config
mkdir -p grafana_provisioning/datasources
cat > grafana_provisioning/datasources/datasource.yml <<EOF
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

# Docker Compose
cat > docker-compose.yml <<EOF
services:
  prometheus:
    image: prom/prometheus:latest
    container_name: prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus_data:/prometheus
    ports:
      - "9090:9090"
    command:
      - "--config.file=/etc/prometheus/prometheus.yml"
    networks:
      - monitoring

  node-exporter:
    image: prom/node-exporter:latest
    container_name: node-exporter
    volumes:
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /:/rootfs:ro
    command:
      - '--path.procfs=/host/proc'
      - '--path.sysfs=/host/sys'
      - '--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/)'
    ports:
      - "9100:9100"
    networks:
      - monitoring

  grafana:
    image: grafana/grafana:latest
    container_name: grafana
    ports:
      - "3000:3000"
    volumes:
      - ./grafana_provisioning:/etc/grafana/provisioning
      - grafana_data:/var/lib/grafana
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=admin
    networks:
      - monitoring

networks:
  monitoring:
    driver: bridge

volumes:
  grafana_data:
  prometheus_data:
EOF

# 3. Executar contenidors
echo -e "${GREEN}Aixecant contenidors...${NC}"
sudo docker compose up -d

echo -e "${BLUE}Instal·lació completada correctament!${NC}"
echo -e "---------------------------------------------------"
echo -e "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (usuari/clau defecte: admin/admin)"
echo -e "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
echo -e "---------------------------------------------------"
