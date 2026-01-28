#!/bin/bash

# Script per aturar els contenidors de monitorització (Prometheus, Grafana, Node Exporter)

# Directori on s'ha instal·lat la configuració (definit a install_monitoring_docker.sh)
INSTALL_DIR="$HOME/docker_monitoring"

if [ -d "$INSTALL_DIR" ]; then
    echo "Aturant els serveis de monitorització..."
    cd "$INSTALL_DIR"
    sudo docker compose down
    echo "Contenidors aturats i eliminats correctament."
else
    echo "Error: No s'ha trobat el directori de configuració: $INSTALL_DIR"
    echo "Assegura't que has executat primer 'install_monitoring_docker.sh'."
    exit 1
fi
