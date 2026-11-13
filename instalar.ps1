# Registra el enlace ytdl: para el usuario actual (no necesita administrador).
# Uso: powershell -NoProfile -ExecutionPolicy Bypass -File .\instalar.ps1

$cmd = '"' + (Join-Path $PSScriptRoot 'abrir.cmd') + '" "%1"'

New-Item -Path 'HKCU:\Software\Classes\ytdl\shell\open\command' -Force | Out-Null
Set-ItemProperty -Path 'HKCU:\Software\Classes\ytdl' -Name '(Default)' -Value 'URL:YTDL Protocol'
Set-ItemProperty -Path 'HKCU:\Software\Classes\ytdl' -Name 'URL Protocol' -Value ''
Set-ItemProperty -Path 'HKCU:\Software\Classes\ytdl\shell\open\command' -Name '(Default)' -Value $cmd

Write-Host "Enlace ytdl: registrado. Comando:"
(Get-ItemProperty 'HKCU:\Software\Classes\ytdl\shell\open\command').'(default)'
