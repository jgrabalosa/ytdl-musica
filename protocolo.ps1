param([string]$Enlace)

function Salir-ConError($mensaje) {
    Write-Host "ERROR: $mensaje" -ForegroundColor Red
    Read-Host "Pulsa Enter para cerrar"
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

Write-Host "Categoria: $categoria"
Write-Host "URL: $url"
& "$PSScriptRoot\descargar.ps1" -Categoria $categoria -Url $url

if ($LASTEXITCODE -eq 0) {
    Write-Host "Listo." -ForegroundColor Green
    Start-Sleep -Seconds 3
} elseif ($LASTEXITCODE -eq 2) {
    Write-Host "No se ha descargado nada." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
} else {
    Salir-ConError "La descarga fallo (codigo $LASTEXITCODE)"
}
