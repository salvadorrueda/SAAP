# Guia de Monitorització Remota (SAAP)

Aquesta guia explica com afegir servidors remots (Linux i Windows) al sistema de monitorització SAAP.

## 1. Servidors GNU/Linux

### Al servidor remot:
1. Copia l'escript `GNU_Linux/Debian/install_node_exporter.sh` al servidor remot.
2. Executa'l amb permisos de superusuari:
   ```bash
   sudo ./install_node_exporter.sh
   ```
3. L'escript instal·larà `node_exporter` i obrirà el servei al port `9100`.

### Al servidor SAAP:
1. Executa l'escript per afegir el host:
   ```bash
   ./GNU_Linux/Debian/add_linux_host.sh
   ```
2. Introdueix la IP del servidor remot quan se't demani.

---

## 2. Servidors Windows

### A la màquina Windows:
1. Copia el fitxer `Windows/install_windows_exporter.ps1` a la màquina Windows.
2. Obre **PowerShell com a Administrador**.
3. Executa l'escript:
   ```powershell
   .\install_windows_exporter.ps1
   ```
4. El servei estarà actiu al port `9182`.

### Al servidor SAAP:
1. Executa l'escript per afegir el host:
   ```bash
   ./GNU_Linux/Debian/add_windows_host.sh
   ```
2. Introdueix la IP de la màquina Windows.

---

## 3. Visualització a Grafana

- **Linux:** Utilitza el dashboard per defecte de Node Exporter o importa el ID `1860`.
- **Windows:** Importa el dashboard ID `14694`.
