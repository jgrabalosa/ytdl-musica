param([string]$Enlace)

$Host.UI.RawUI.WindowTitle = 'YTDL - Descargando...'

function Salir-ConError($mensaje) {
    $Host.UI.RawUI.WindowTitle = 'YTDL - Error'
    Write-Host ""
    Write-Host "  ERROR: $mensaje" -ForegroundColor Red
    Read-Host "  Pulsa Enter para cerrar"
    exit 1
}

if ($Enlace -notmatch '^ytdl:(sesion|musica|podcast)\?url=(.+)$') {
    Salir-ConError "Enlace no valido: $Enlace"
}
$categoria = $Matches[1]
$url = [System.Uri]::UnescapeDataString($Matches[2])

if ($url -notmatch '^https://((www|m|music)\.)?youtube\.com/|^https://youtu\.be/') {
    Salir-ConError "Solo se aceptan URLs de YouTube: $url"
}

Write-Host ""
Write-Host "  ==============================================" -ForegroundColor Cyan
Write-Host "    YTDL - Descarga de audio" -ForegroundColor Cyan
Write-Host "  ==============================================" -ForegroundColor Cyan

& "$PSScriptRoot\descargar.ps1" -Categoria $categoria -Url $url
$codigo = $LASTEXITCODE

if ($codigo -eq 0) {
    $Host.UI.RawUI.WindowTitle = 'YTDL - Listo'
    Write-Host "  LISTO. Se cierra en 3 segundos..." -ForegroundColor Green
    Start-Sleep -Seconds 3
} elseif ($codigo -eq 2) {
    $Host.UI.RawUI.WindowTitle = 'YTDL - Sin cambios'
    Write-Host "  No se ha descargado nada. Se cierra en 3 segundos..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
} else {
    Salir-ConError "La descarga fallo (codigo $codigo)"
}
