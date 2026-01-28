#!/bin/bash

# Script per configurar alertes a Grafana utilitzant provisioning
# Defineix alertes per a gran consum de CPU i de Xarxa.

set -e

# Colors per a la sortida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Configurant alertes de Grafana...${NC}"

# 1. Crear directoris necessaris
ALERT_PROV_DIR="/etc/grafana/provisioning/alerting"
sudo mkdir -p "$ALERT_PROV_DIR"

# 2. Configurar el fitxer de regles (rules.yaml)
# Nota: Utilitzem el format de Provisioning de Unified Alerting (Grafana 9+)
RULES_FILE="$ALERT_PROV_DIR/rules.yaml"

echo -e "${GREEN}Creant el fitxer de regles a $RULES_FILE...${NC}"

sudo bash -c "cat > $RULES_FILE <<EOF
apiVersion: 1

groups:
  - orgId: 1
    name: 'Standard Resource Alerts'
    folder: 'Infrastructura'
    interval: 1m
    rules:
      - uid: high_cpu_usage
        title: 'CPU Usage High'
        condition: B
        data:
          - refId: A
            relativeTimeRange:
              from: 600
              to: 0
            datasourceUid: 'Prometheus'
            model:
              expr: '100 - (avg by (instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)'
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              refId: A
          - refId: B
            relativeTimeRange:
              from: 600
              to: 0
            datasourceUid: '__expr__'
            model:
              conditions:
                - evaluator:
                    params: [80]
                    type: gt
                  operator:
                    type: and
                  query:
                    params: [A]
                  reducer:
                    params: []
                    type: last
                  type: query
              datasource:
                name: Expression
                type: __expr__
                uid: __expr__
              expression: A
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              refId: B
              type: classic_conditions
        for: 5m
        annotations:
          summary: 'High CPU usage on {{ \$labels.instance }}'
          description: 'CPU usage has been above 80% for more than 5 minutes.'
        labels:
          severity: critical

      - uid: high_network_traffic
        title: 'Network Traffic High'
        condition: B
        data:
          - refId: A
            relativeTimeRange:
              from: 600
              to: 0
            datasourceUid: 'Prometheus'
            model:
              expr: 'sum by (instance) (irate(node_network_receive_bytes_total[5m]) + irate(node_network_transmit_bytes_total[5m]))'
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              refId: A
          - refId: B
            relativeTimeRange:
              from: 600
              to: 0
            datasourceUid: '__expr__'
            model:
              conditions:
                - evaluator:
                    params: [10000000] # 10 MB/s
                    type: gt
                  operator:
                    type: and
                  query:
                    params: [A]
                  reducer:
                    params: []
                    type: last
                  type: query
              datasource:
                name: Expression
                type: __expr__
                uid: __expr__
              expression: A
              hide: false
              intervalMs: 1000
              maxDataPoints: 43200
              refId: B
              type: classic_conditions
        for: 2m
        annotations:
          summary: 'High Network Traffic on {{ \$labels.instance }}'
          description: 'Combined network traffic (In/Out) is above 10MB/s for more than 2 minutes.'
        labels:
          severity: warning
EOF"

# 3. Reiniciar Grafana per carregar les noves alertes
echo -e "${GREEN}Reiniciant Grafana per aplicar les alertes...${NC}"
sudo systemctl restart grafana-server

echo -e "${BLUE}Configuració d'alertes finalitzada correctament!${NC}"
echo -e "Pots veure les alertes a Grafana dins la secció 'Alerting > Alert rules'."
echo -e "Nota: Recorda que has de configurar un 'Contact Point' (Email, Telegram, etc.) manualment a la interfície de Grafana."
