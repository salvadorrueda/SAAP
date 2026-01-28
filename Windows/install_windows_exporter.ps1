# Script per instal·lar windows_exporter a Windows
# SAAP - Salvador Rueda

$Version = "0.25.1"
$Arch = "amd64"
$URL = "https://github.com/prometheus-community/windows_exporter/releases/download/v$Version/windows_exporter-$Version-$Arch.msi"
$TempPath = "$env:TEMP\windows_exporter.msi"

Write-Host "--- Instal·lador de windows_exporter ---" -ForegroundColor Cyan

# 1. Descarregar l'instal·lador
Write-Host "Descarregant windows_exporter v$Version..." -ForegroundColor Green
Invoke-WebRequest -Uri $URL -OutFile $TempPath

# 2. Instal·lar com a servei
Write-Host "Instal·lant el servei (Port 9182)..." -ForegroundColor Green
Start-Process msiexec.exe -ArgumentList "/i $TempPath /quiet /qn /norestart ENABLED_COLLECTORS=cpu,memory,net,logical_disk,os,system" -Wait

# 3. Obrir el tallafocs
Write-Host "Configurant el Firewall de Windows..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Prometheus windows_exporter" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9182

# 4. Neteja
Remove-Item $TempPath

Write-Host "Instal·lació completada!" -ForegroundColor Cyan
Write-Host "Pots verificar les mètriques a: http://localhost:9182/metrics" -ForegroundColor Cyan
