#!/bin/bash

# Script per iniciar els contenidors de monitorització (Prometheus, Grafana, Node Exporter)

# Directori on s'ha instal·lat la configuració (definit a install_monitoring_docker.sh)
INSTALL_DIR="$HOME/docker_monitoring"

if [ -d "$INSTALL_DIR" ]; then
    echo "Iniciant els serveis de monitorització..."
    cd "$INSTALL_DIR"
    sudo docker compose up -d
    echo "Contenidors iniciats correctament."
    echo -e "---------------------------------------------------"
    echo -e "Grafana: http://$(hostname -I | awk '{print $1}'):3000 (usuari/clau defecte: admin/admin)"
    echo -e "Prometheus: http://$(hostname -I | awk '{print $1}'):9090"
    echo -e "---------------------------------------------------"
else
    echo "Error: No s'ha trobat el directori de configuració: $INSTALL_DIR"
    echo "Assegura't que has executat primer 'install_monitoring_docker.sh'."
    exit 1
fi
