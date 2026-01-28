#!/bin/bash

# Script per afegir un router MikroTik com a target de Prometheus (SNMP)
# SAAP - Salvador Rueda

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

PROM_CONF="/etc/prometheus/prometheus.yml"

echo -e "${BLUE}--- Afegir Router MikroTik a la Monitorització ---${NC}"

# Demanar dades
read -p "IP del router MikroTik: " ROUTER_IP
read -p "Comunitat SNMP [public]: " SNMP_COMMUNITY
SNMP_COMMUNITY=${SNMP_COMMUNITY:-public}

if [ -z "$ROUTER_IP" ]; then
    echo -e "${RED}Error: La IP del router és obligatòria.${NC}"
    exit 1
fi

echo -e "${GREEN}Afegint el router $ROUTER_IP amb comunitat $SNMP_COMMUNITY...${NC}"

# 1. Crear el directori de configuració si no existeix (opcional, però millor si fem servir fitxers separats)
# Per simplicitat, editarem el fitxer principal prometheus.yml com fan els altres scripts.

# 2. Afegir el grup de jobs si no existeix, o afegir el target si ja existeix el job
if grep -q "job_name: 'snmp_mikrotik'" "$PROM_CONF"; then
    echo -e "${BLUE}El job 'snmp_mikrotik' ja existeix. Afegint target...${NC}"
    # Aquesta part és més complexa amb sed si volem mantenir l'estructura. 
    # Per ara, si ja existeix, avisem o ho implementem de forma robusta.
    # Com que és un script d'ajuda, el farem senzill:
    sudo sed -i "/job_name: 'snmp_mikrotik'/,/static_configs/ s/targets: \[/targets: ['$ROUTER_IP', /" "$PROM_CONF"
else
    echo -e "${BLUE}Creant nou job 'snmp_mikrotik' a Prometheus...${NC}"
    sudo bash -c "cat >> $PROM_CONF <<EOF

  - job_name: 'snmp_mikrotik'
    static_configs:
      - targets:
        - $ROUTER_IP
    metrics_path: /snmp
    params:
      module: [if_mib]
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: localhost:9116
EOF"
fi

# 3. Validar configuració de Prometheus
echo -e "${GREEN}Validant la configuració de Prometheus...${NC}"
if promtool check config "$PROM_CONF" &> /dev/null; then
    echo -e "${GREEN}Configuració vàlida. Reiniciant Prometheus...${NC}"
    sudo systemctl restart prometheus
else
    echo -e "${RED}Error: La configuració de Prometheus no és vàlida. Revisa $PROM_CONF${NC}"
    exit 1
fi

echo -e "${BLUE}Router $ROUTER_IP afegit correctament!${NC}"
echo -e "Recorda que a MikroTik has d'executar: ${NC}"
echo -e "  /snmp set enabled=yes contact=\"Admin\""
echo -e "  /snmp community set [find name=public] addresses=0.0.0.0/0"
