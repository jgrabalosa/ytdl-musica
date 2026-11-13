param(
    [Parameter(Mandatory)][ValidateSet('sesion','musica','podcast')][string]$Categoria,
    [Parameter(Mandatory)][string]$Url
)

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$musica = Join-Path $env:USERPROFILE 'Music'
$base = Join-Path $musica 'YouTube'
$limitePodcast = 1800   # 30 minutos, en segundos
$registro = Join-Path $PSScriptRoot 'descargados.txt'
$calidad = @('--audio-quality', '0')   # maxima calidad (musica y sesiones)
$linea = '  ' + ('-' * 46)

# 1. Consultar id, duracion y titulo del video
Write-Host "  Consultando video..." -ForegroundColor DarkGray
$info = yt-dlp --no-playlist --no-warnings --encoding utf-8 --print "%(id)s|%(duration)s|%(title)s" $Url | Select-Object -Last 1
$partes = "$info" -split '\|', 3
$id = $partes[0]
$titulo = $partes[2]
if (-not $id) {
    Write-Host "  No se pudo consultar el video." -ForegroundColor Red
    exit 1
}

# 2. Elegir carpeta y calidad
switch ($Categoria) {
    'sesion'  { $destino = Join-Path $base 'Sesiones'; $tipo = 'Sesion' }
    'musica'  { $destino = Join-Path $base 'Musica';   $tipo = 'Musica' }
    'podcast' {
        $segundos = 0
        $leido = [double]::TryParse($partes[1], [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$segundos)
        if ($leido -and $segundos -lt $limitePodcast) {
            $destino = Join-Path $base 'Podcasts\Cortos'; $tipo = 'Podcast corto'
        } else {
            $destino = Join-Path $base 'Podcasts\Largos'; $tipo = 'Podcast largo'
        }
        if ($leido) { $tipo += " ($([math]::Round($segundos / 60)) min)" }
        # Voz: 64 kbps mono y sin trozos patrocinados (SponsorBlock)
        $calidad = @('--audio-quality', '64K', '--postprocessor-args', 'ExtractAudio:-ac 1', '--sponsorblock-remove', 'sponsor,selfpromo,interaction')
    }
}
$carpeta = $destino.Replace($musica + '\', '')

Write-Host "  Titulo : $titulo"
Write-Host "  Tipo   : $tipo"
Write-Host "  Carpeta: $carpeta"
Write-Host $linea -ForegroundColor DarkCyan

# 3. Avisar si ya se descargo antes
if (Test-Path $registro) {
    $previo = Get-Content $registro -Encoding UTF8 | Where-Object { $_ -like "$id`t*" } | Select-Object -First 1
    if ($previo) {
        $campos = $previo -split "`t"
        Write-Host "  AVISO: ya lo descargaste el $($campos[1])" -ForegroundColor Yellow
        Write-Host "  Esta en: $($campos[2].Replace($musica + '\', ''))" -ForegroundColor Yellow
        $respuesta = Read-Host "  Descargar de nuevo? (s/N)"
        if ($respuesta -ne 's') {
            Write-Host $linea -ForegroundColor DarkCyan
            exit 2
        }
    }
}

# 4. Descargar (solo se ve la barra de progreso; los errores se siguen mostrando)
New-Item -ItemType Directory -Force -Path $destino | Out-Null
Write-Host "  Descargando y convirtiendo..." -ForegroundColor DarkGray
yt-dlp -q --progress -x --audio-format mp3 @calidad --embed-thumbnail --embed-metadata --no-playlist -P $destino -P "temp:$env:TEMP\ytdl" -o "%(title)s.%(ext)s" $Url
$codigo = $LASTEXITCODE
Write-Host $linea -ForegroundColor DarkCyan

# 5. Apuntar en el registro si fue bien
if ($codigo -eq 0) {
    Add-Content -Path $registro -Encoding UTF8 -Value "$id`t$(Get-Date -Format 'yyyy-MM-dd')`t$destino"
}
exit $codigo
