# ==============================================================================
# Script: add_shared_pdf_printer.ps1
# Descripció: Afegeix una impressora PDF compartida des d'un servidor Linux (CUPS).
# Sistema operatiu: Windows 10 / 11
# Autor: Antigravity
# ==============================================================================

Write-Host "=== Configuració d'Impressora PDF de Xarxa ===" -ForegroundColor Cyan

# 1. Demanar la IP del servidor
$serverIp = Read-Host "Introdueix l'adreça IP del servidor Ubuntu (ex: 192.168.1.50)"

if ([string]::IsNullOrWhitespace($serverIp)) {
    Write-Host "ERROR: L'adreça IP no pot estar buida." -ForegroundColor Red
    exit
}

# 2. Definir la URL de la impressora
$printerUrl = "http://$($serverIp):631/printers/PDF"
$printerName = "PDF_Xarxa_Ubuntu"

Write-Host "Intentant connectar a: $printerUrl" -ForegroundColor Blue

# 3. Comprovar si la impressora ja existeix
$existingPrinter = Get-Printer | Where-Object { $_.Name -eq $printerName }
if ($existingPrinter) {
    Write-Host "La impressora '$printerName' ja existeix. Esborrant per re-configurar..." -ForegroundColor Yellow
    Remove-Printer -Name $printerName
}

# 4. Afegir la impressora
try {
    Write-Host "Afegint la impressora... Això pot trigar uns segons." -ForegroundColor Green
    
    # Utilitzem Add-Printer amb la URL del recurs
    # Nota: Windows necessita tenir activat el "Client d'impressió per Internet"
    Add-Printer -Name $printerName -ConnectionName $printerUrl
    
    Write-Host "S'ha afegit la impressora correctament!" -ForegroundColor Green
    Write-Host "Ara pots imprimir seleccionant '$printerName' des de qualsevol aplicació." -ForegroundColor Cyan
}
catch {
    Write-Host "ERROR: No s'ha pogut afegir la impressora." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor White
    Write-Host "`nSuggeriments:" -ForegroundColor Yellow
    Write-Host "1. Assegura't que el servidor Ubuntu està encès i CUPS està funcionant."
    Write-Host "2. Comprova que pots arribar a la IP: ping $serverIp"
    Write-Host "3. Verifica que el 'Client d'impressió per Internet' està activat a Windows (Característiques de Windows)."
}

Write-Host "`nPrem qualsevol tecla per sortir..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
