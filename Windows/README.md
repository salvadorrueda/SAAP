# Monitorització de Windows (SAAP)

Aquest directori conté els scripts necessaris per preparar una màquina Windows per ser monitoritzada amb Prometheus i Grafana.

## Instruccions d'ús

1. Copia el fitxer `install_windows_exporter.ps1` a la màquina Windows.
2. Obre una terminal de **PowerShell com a Administrador**.
3. Executa l'escript:
   ```powershell
   .\install_windows_exporter.ps1
   ```
4. Un cop finalitzat, el servei estarà actiu al port `9182`.
5. Ara, des del servidor Linux (SAAP), executa l'escript `add_windows_host.sh` per afegir aquesta màquina a Prometheus.

## Dashboard de Grafana recomanat
- **ID:** `14694` (Windows Exporter Dashboard)
