#!/bin/bash

# Script per afegir un servidor Linux remot com a target de Prometheus
# SAAP - Salvador Rueda

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROM_CONF="/etc/prometheus/prometheus.yml"

echo -e "${BLUE}--- Afegir Servidor Linux Remot a la Monitorització ---${NC}"

# Demanar dades
read -p "IP o Nom del servidor remot: " REMOTE_IP

if [ -z "$REMOTE_IP" ]; then
    echo -e "${RED}Error: La IP o nom és obligatori.${NC}"
    exit 1
fi

echo -e "${GREEN}Afegint el servidor $REMOTE_IP...${NC}"

# 1. Comprovar si el job ja existeix
if grep -q "job_name: 'node_exporter_remote'" "$PROM_CONF"; then
    echo -e "${BLUE}El job 'node_exporter_remote' ja existeix. Afegint target...${NC}"
    # Afegim la IP a la llista de targets
    sudo sed -i "/job_name: 'node_exporter_remote'/,/static_configs/ s/targets: \[/targets: ['$REMOTE_IP:9100', /" "$PROM_CONF"
else
    echo -e "${BLUE}Creant nou job 'node_exporter_remote' a Prometheus...${NC}"
    sudo bash -c "cat >> $PROM_CONF <<EOF

  - job_name: 'node_exporter_remote'
    static_configs:
      - targets: ['$REMOTE_IP:9100']
EOF"
fi

# 2. Validar configuració de Prometheus
echo -e "${GREEN}Validant la configuració de Prometheus...${NC}"
if command -v promtool &> /dev/null; then
    if sudo promtool check config "$PROM_CONF" &> /dev/null; then
        echo -e "${GREEN}Configuració vàlida. Reiniciant Prometheus...${NC}"
        sudo systemctl restart prometheus
    else
        echo -e "${RED}Error: La configuració de Prometheus no és vàlida. Revisa $PROM_CONF${NC}"
        exit 1
    fi
else
    echo -e "${BLUE}Promtool no detectat, reiniciant Prometheus directament...${NC}"
    sudo systemctl restart prometheus
fi

echo -e "${BLUE}Servidor $REMOTE_IP afegit correctament!${NC}"
