#!/bin/bash

# Script per afegir una màquina Windows com a target de Prometheus (DOCKER)
# SAAP - Salvador Rueda

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Directori de monitorització Docker
INSTALL_DIR="$HOME/docker_monitoring"
PROM_CONF="$INSTALL_DIR/prometheus.yml"

echo -e "${BLUE}--- Afegir Màquina Windows a la Monitorització (DOCKER) ---${NC}"

# Comprovar si el directori existeix
if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: No s'ha trobat el directori $INSTALL_DIR.${NC}"
    echo -e "Assegura't que has instal·lat la monitorització amb Docker primer."
    exit 1
fi

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
    # Afegim la IP a la llista de targets
    sed -i "/job_name: 'windows_exporter'/,/static_configs/ s/targets: \[/targets: ['$WINDOWS_IP:9182', /" "$PROM_CONF"
else
    echo -e "${BLUE}Creant nou job 'windows_exporter' a Prometheus...${NC}"
    cat >> "$PROM_CONF" <<EOF

  - job_name: 'windows_exporter'
    static_configs:
      - targets: ['$WINDOWS_IP:9182']
EOF
fi

# 2. Validar configuració i reiniciat Prometheus a Docker
echo -e "${GREEN}Validant la configuració i reiniciant Prometheus al contenidor...${NC}"

cd "$INSTALL_DIR"

if sudo docker exec prometheus promtool check config /etc/prometheus/prometheus.yml &> /dev/null; then
    echo -e "${GREEN}Configuració vàlida. Reiniciant contenidor Prometheus...${NC}"
    sudo docker compose restart prometheus
else
    echo -e "${RED}Error: La configuració de Prometheus no és vàlida.${NC}"
    echo -e "Si us plau, revisa el fitxer $PROM_CONF manualment."
    exit 1
fi

echo -e "${BLUE}Màquina Windows $WINDOWS_IP afegida correctament!${NC}"
echo -e "Recorda que a la màquina Windows has d'haver executat l'script d'instal·lació."
