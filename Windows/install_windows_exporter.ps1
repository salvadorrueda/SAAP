# Script per instal·lar windows_exporter a Windows
# Per executar-lo: powershell.exe -ExecutionPolicy Bypass -File "install_windows_exporter.ps1"
# SAAP - Salvador Rueda

$Version = "0.31.3" # Darrera versió a 31 de gener de 2026 
$Arch = "amd64"
$URL = "https://github.com/prometheus-community/windows_exporter/releases/download/v$Version/windows_exporter-$Version-$Arch.msi"
$TempPath = "$env:TEMP\windows_exporter.msi"

Write-Host "--- Instal·lador de windows_exporter ---" -ForegroundColor Cyan

# 1. Descarregar l'instal·lador
Write-Host "Descarregant windows_exporter v$Version..." -ForegroundColor Green
Invoke-WebRequest -Uri $URL -OutFile $TempPath

# 2. Instal·lar com a servei
Write-Host "Instal·lant el servei (Port 9182)..." -ForegroundColor Green
Start-Process msiexec.exe -ArgumentList "/i $TempPath /quiet /qn /norestart ENABLED_COLLECTORS=ad,adfs,cache,cpu,cpu_info,cs,container,dfsr,dhcp,dns,fsrmquota,iis,logical_disk,logon,memory,msmq,mssql,netframework_clrexceptions,netframework_clrinterop,netframework_clrjit,netframework_clrloading,netframework_clrlocksandthreads,netframework_clrmemory,netframework_clrremoting,netframework_clrsecurity,net,os,process,remote_fx,service,tcp,time,vmware" -Wait

# 3. Obrir el tallafocs
Write-Host "Configurant el Firewall de Windows..." -ForegroundColor Green
New-NetFirewallRule -DisplayName "Prometheus windows_exporter" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 9182

# 4. Neteja
Remove-Item $TempPath

Write-Host "Instal·lació completada!" -ForegroundColor Cyan
Write-Host "Pots verificar les mètriques a: http://localhost:9182/metrics" -ForegroundColor Cyan
