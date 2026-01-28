#!/bin/bash

# Script per afegir una màquina Windows com a target de Prometheus
# SAAP - Salvador Rueda

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROM_CONF="/etc/prometheus/prometheus.yml"

echo -e "${BLUE}--- Afegir Màquina Windows a la Monitorització ---${NC}"

# Demanar dades
read -p "IP de la màquina Windows: " WINDOWS_IP

if [ -z "$WINDOWS_IP" ]; then
    echo -e "${RED}Error: La IP de la màquina és obligatòria.${NC}"
    exit 1
fi

echo -e "${GREEN}Afegint la màquina $WINDOWS_IP...${NC}"

# 1. Comprovar si el job ja existeix
if grep -q "job_name: 'windows_exporter'" "$PROM_CONF"; then
    echo -e "${BLUE}El job 'windows_exporter' ja existeix. Afegint target...${NC}"
    # Afegim la IP a la llista de targets (intentem ser robustos amb el format)
    sudo sed -i "/job_name: 'windows_exporter'/,/static_configs/ s/targets: \[/targets: ['$WINDOWS_IP:9182', /" "$PROM_CONF"
else
    echo -e "${BLUE}Creant nou job 'windows_exporter' a Prometheus...${NC}"
    sudo bash -c "cat >> $PROM_CONF <<EOF

  - job_name: 'windows_exporter'
    static_configs:
      - targets: ['$WINDOWS_IP:9182']
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

echo -e "${BLUE}Màquina Windows $WINDOWS_IP afegida correctament!${NC}"
echo -e "Recorda que a la màquina Windows has d'haver executat l'script d'instal·lació."
