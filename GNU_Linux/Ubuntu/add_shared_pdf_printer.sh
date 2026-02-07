#!/bin/bash

# ==============================================================================
# Script: add_shared_pdf_printer.sh
# Descripció: Afegeix una impressora PDF compartida des d'un servidor Linux (CUPS).
# Sistema operatiu: Ubuntu / Debian / Linux Mint (Client)
# Autor: Antigravity
# ==============================================================================

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}=== Configuració d'Impressora PDF de Xarxa (Client Linux) ===${NC}"

# Verificar si s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Aquest script s'ha d'executar com a root (sudo).${NC}"
   exit 1
fi

# 1. Verificar si CUPS està instal·lat
if ! command -v lpadmin &> /dev/null; then
    echo -e "${BLUE}CUPS no està instal·lat. Instal·lant...${NC}"
    apt update && apt install -y cups
fi

# 2. Demanar la IP del servidor
read -p "Introdueix l'adreça IP del servidor Ubuntu (ex: 192.168.1.50): " SERVER_IP

if [ -z "$SERVER_IP" ]; then
    echo -e "${RED}L'adreça IP no pot estar buida.${NC}"
    exit 1
fi

# 3. Definir paràmetres de la impressora
PRINTER_NAME="PDF_Xarxa_Ubuntu"
PRINTER_URL="ipp://$SERVER_IP:631/printers/PDF"

echo -e "${GREEN}Configurant la impressora $PRINTER_NAME des de $PRINTER_URL...${NC}"

# 4. Esborrar si ja existeix
lpadmin -x "$PRINTER_NAME" 2>/dev/null

# 5. Afegir la impressora
# Utilitzem el driver genèric de PDF o IPP Everywhere
lpadmin -p "$PRINTER_NAME" -v "$PRINTER_URL" -E -m everywhere

if [ $? -eq 0 ]; then
    echo -e "${GREEN}S'ha afegit la impressora correctament!${NC}"
    echo -e "Pots comprovar-ho amb la comanda: ${BLUE}lpstat -p $PRINTER_NAME${NC}"
    
    # Establir com a predeterminada (opcional)
    read -p "Vols establir-la com a impressora predeterminada? (s/n): " DEFAULT
    if [[ "$DEFAULT" =~ ^[Ss]$ ]]; then
        lpadmin -d "$PRINTER_NAME"
        echo -e "${GREEN}Impressora establerta com a predeterminada.${NC}"
    fi
else
    echo -e "${RED}Error en afegir la impressora. Revisa que el servidor sigui accessible.${NC}"
fi

echo -e "\n${BLUE}Finalitzat.${NC}"
