#!/bin/bash

# ==============================================================================
# Script: install_shared_pdf_printer.sh
# Descripció: Instal·la i configura una impressora PDF compartida a la xarxa.
# Sistema operatiu: Ubuntu Desktop / Debian
# Autor: Antigravity
# ==============================================================================

# Colors per a la sortida
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Configurant Impressora PDF Compartida ===${NC}"

# Verificar si s'executa com a root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Aquest script s'ha d'executar com a root (sudo).${NC}"
   exit 1
fi

# 1. Actualitzar repositoris i instal·lar paquets
echo -e "${GREEN}[1/5] Instal·lant CUPS i el controlador PDF...${NC}"
apt update
apt install -y cups printer-driver-cups-pdf

# 2. Configurar CUPS per permetre l'accés des de la xarxa
echo -e "${GREEN}[2/5] Configurant CUPS per a compartir a la xarxa...${NC}"

# Permetre que CUPS escolti a totes les interfícies
cupsctl --remote-admin --remote-any --share-printers

# Alternativament, si cupsctl no és suficient, modifiquem el fitxer de configuració
# Assegurar que Listen localhost:631 es canvia per Port 631 o Listen *:631 si cal,
# però cupsctl --remote-any sol encarregar-se d'això.

# 3. Assegurar que la impressora PDF està compartida
echo -e "${GREEN}[3/5] Compartint la impressora PDF...${NC}"
# Obtenir el nom de la impressora PDF (habitualment es diu 'PDF')
PRINTER_NAME=$(lpstat -v | grep "cups-pdf:/" | cut -d' ' -f3 | sed 's/://')

if [ -z "$PRINTER_NAME" ]; then
    # Si no s'ha creat automàticament, la creem
    echo -e "${BLUE}Creant la impressora PDF manualment...${NC}"
    lpadmin -p PDF -v cups-pdf:/ -E -P /usr/share/ppd/cups-pdf/CUPS-PDF_no_dp.ppd
    PRINTER_NAME="PDF"
fi

# Marcar la impressora com a compartida
lpadmin -p "$PRINTER_NAME" -o printer-is-shared=true

# 4. Reiniciar el servei CUPS
echo -e "${GREEN}[4/5] Reiniciant el servei CUPS...${NC}"
systemctl restart cups

# 5. Mostrar informació de connexió
echo -e "${GREEN}[5/5] Configuració finalitzada!${NC}"

IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "\n${BLUE}Detalls per a connectar-se des d'altres ordinadors:${NC}"
echo -e "----------------------------------------------------"
echo -e "URL de la impressora: ${GREEN}http://$IP_ADDR:631/printers/$PRINTER_NAME${NC}"
echo -e "\n${BLUE}Instruccions per a Windows:${NC}"
echo -e "1. Afegeix una impressora nova."
echo -e "2. Selecciona 'La meva impressora no apareix'."
echo -e "3. Selecciona 'Selecciona una impressora compartida per nom' i posa la URL de dalt."
echo -e "4. Utilitza el controlador 'Generic -> MS Publisher Imagesetter' o un PS genèric."

echo -e "\n${BLUE}Instruccions per a GNU/Linux:${NC}"
echo -e "1. Utilitza CUPS o la configuració d'impressores del sistema."
echo -e "2. Afegeix una impressora de xarxa utilitzant el protocol IPP."
echo -e "3. Adreça: ${IP_ADDR} i recurs: /printers/${PRINTER_NAME}"

echo -e "\n${BLUE}Els fitxers PDF es guardaran a la carpeta: ${GREEN}/var/spool/cups-pdf/ANONYMOUS/${NC} (o a la carpeta PDF de l'usuari si imprimeix localment)"
echo -e "----------------------------------------------------"
