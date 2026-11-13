param(
    [Parameter(Mandatory)][ValidateSet('sesion','musica','podcast')][string]$Categoria,
    [Parameter(Mandatory)][string]$Url
)

$base = Join-Path $env:USERPROFILE 'Music\YouTube'
$limitePodcast = 1800   # 30 minutos, en segundos
$registro = Join-Path $PSScriptRoot 'descargados.txt'
$calidad = @('--audio-quality', '0')   # maxima calidad (musica y sesiones)

# 1. Consultar id y duracion del video
Write-Host "Consultando video..."
$info = yt-dlp --no-playlist --print "%(id)s|%(duration)s" $Url | Select-Object -Last 1
$partes = "$info" -split '\|'
$id = $partes[0]
if (-not $id) {
    Write-Host "No se pudo consultar el video." -ForegroundColor Red
    exit 1
}

# 2. Avisar si ya se descargo antes
if (Test-Path $registro) {
    $previo = Get-Content $registro -Encoding UTF8 | Where-Object { $_ -like "$id`t*" } | Select-Object -First 1
    if ($previo) {
        $campos = $previo -split "`t"
        Write-Host ""
        Write-Host "AVISO: este video ya se descargo el $($campos[1])" -ForegroundColor Yellow
        Write-Host "Carpeta: $($campos[2])" -ForegroundColor Yellow
        $respuesta = Read-Host "Descargar de nuevo? (s/N)"
        if ($respuesta -ne 's') { exit 2 }
    }
}

# 3. Elegir carpeta
switch ($Categoria) {
    'sesion'  { $destino = Join-Path $base 'Sesiones' }
    'musica'  { $destino = Join-Path $base 'Musica' }
    'podcast' {
        $segundos = 0
        if ([double]::TryParse($partes[1], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$segundos) -and $segundos -lt $limitePodcast) {
            $destino = Join-Path $base 'Podcasts\Cortos'
        } else {
            $destino = Join-Path $base 'Podcasts\Largos'
        }
        Write-Host "Duracion: $([math]::Round($segundos / 60)) min"
        # Voz: 64 kbps mono y sin trozos patrocinados (SponsorBlock)
        $calidad = @('--audio-quality', '64K', '--postprocessor-args', 'ExtractAudio:-ac 1', '--sponsorblock-remove', 'sponsor,selfpromo,interaction')
    }
}

New-Item -ItemType Directory -Force -Path $destino | Out-Null
Write-Host "Destino: $destino"

# 4. Descargar
yt-dlp -x --audio-format mp3 @calidad --embed-thumbnail --embed-metadata --no-playlist -P $destino -P "temp:$env:TEMP\ytdl" -o "%(title)s.%(ext)s" $Url
$codigo = $LASTEXITCODE

# 5. Apuntar en el registro si fue bien
if ($codigo -eq 0) {
    Add-Content -Path $registro -Encoding UTF8 -Value "$id`t$(Get-Date -Format 'yyyy-MM-dd')`t$destino"
}
exit $codigo
