# ytdl-musica

Botón en YouTube (Chrome + Tampermonkey) que descarga el audio del vídeo en MP3, lo clasifica por categoría en el PC y lo deja en espejo en el móvil con Syncthing.

```
YouTube (botón) → ytdl:<categoria>?url=... → abrir.cmd → protocolo.ps1 → descargar.ps1 → yt-dlp
                                                                          ↓
                                       %USERPROFILE%\Music\YouTube ──Syncthing──→ móvil Music/YouTube
```

## Piezas

| Archivo | Qué hace |
|---|---|
| `ytdl.user.js` | Script de Tampermonkey. Añade el botón "⬇ Descargar audio" en la barra superior de YouTube (Sesión / Música / Podcast). Envía siempre la URL limpia (`watch?v=ID`), sin playlist. |
| `abrir.cmd` | Lo lanza Windows al abrir un enlace `ytdl:`. Llama a `protocolo.ps1`. |
| `protocolo.ps1` | Valida el enlace (solo 3 categorías y solo URLs de YouTube), llama a `descargar.ps1` y muestra el resultado. |
| `descargar.ps1` | Consulta id y duración, avisa si ya se descargó, elige carpeta y descarga con yt-dlp. |
| `instalar.ps1` | Registra el enlace `ytdl:` en el usuario actual (HKCU, sin admin). |

## Carpetas y calidad

| Categoría | Carpeta | Calidad |
|---|---|---|
| Sesión | `Music\YouTube\Sesiones` | MP3 máxima calidad |
| Música | `Music\YouTube\Musica` | MP3 máxima calidad |
| Podcast < 30 min | `Music\YouTube\Podcasts\Cortos` | MP3 64 kbps mono + SponsorBlock |
| Podcast ≥ 30 min | `Music\YouTube\Podcasts\Largos` | MP3 64 kbps mono + SponsorBlock |

- SponsorBlock quita en podcasts: `sponsor`, `selfpromo`, `interaction`.
- Los archivos intermedios se generan en `%TEMP%\ytdl`; a `Music\YouTube` solo llega el MP3 terminado (evita choques con Syncthing y que se sincronicen archivos a medias).
- `descargados.txt` (no versionado) guarda `id<TAB>fecha<TAB>carpeta` de cada descarga. Si un vídeo ya está, avisa en amarillo y pregunta si descargar de nuevo (por defecto, no).

## Instalación en un PC nuevo

1. Dependencias (PowerShell):
   ```powershell
   winget install --id yt-dlp.yt-dlp -e      # instala también Deno
   winget install --id Gyan.FFmpeg -e        # si ffmpeg no queda instalado
   ```
   Cerrar y abrir PowerShell y comprobar: `yt-dlp --version`, `deno --version`, `ffmpeg -version`.
2. Clonar este repo en `%USERPROFILE%\YTDL`.
3. **Avast**: añadir la excepción de carpeta `C:\Users\<usuario>\YTDL\*` (usar "Examinar"; si se escribe a mano puede crear excepciones de URL falsas tipo `http://C/*`).
4. Registrar el enlace:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\YTDL\instalar.ps1"
   ```
5. Tampermonkey: crear script nuevo y pegar `ytdl.user.js`. En Chrome reciente: `chrome://extensions` → Tampermonkey → Detalles → activar "Permitir scripts de usuario".
6. Primera vez que se pulsa el botón, Chrome pregunta si abrir el enlace: marcar "Permitir siempre" y Abrir.

## Móvil

- **Syncthing**: carpeta `YouTube Musica` → PC en **Sólo Enviar**, móvil en **Sólo Recibir**, ruta `/storage/emulated/0/Music/YouTube`. Si el selector de Android no deja elegir carpeta, aceptarla desde la Interfaz web de Syncthing del móvil y escribir la ruta a mano. Condiciones de ejecución: solo Wi-Fi.
- **AntennaPod**: Añadir podcast → "Añadir carpeta local" con `Podcasts/Cortos` y `Podcasts/Largos`. Da el check de escuchado y recuerda la posición.

## Si algo falla

| Síntoma | Qué hacer |
|---|---|
| `HTTP Error 403: Forbidden` | Reintentar. Si persiste, esperar 30-60 min (YouTube limita tras muchas descargas seguidas). |
| Las descargas dejan de funcionar en general | Actualizar a mano: `winget upgrade --id yt-dlp.yt-dlp -e` y `winget upgrade --id DenoLand.Deno -e` |
| El botón no hace nada | Comprobar `Get-ItemProperty 'HKCU:\Software\Classes\ytdl\shell\open\command'`. Si `(default)` está vacío, ejecutar `instalar.ps1`. |
| `WinError 32` (archivo en uso) | Comprobar que la línea de yt-dlp en `descargar.ps1` conserva `-P "temp:$env:TEMP\ytdl"`. |

## Lecciones (no repetir)

- **No actualizar yt-dlp desde scripts.** Una tarea programada oculta con `winget upgrade` y, después, el mismo `winget upgrade` dentro de `protocolo.ps1` hicieron saltar el Escudo de comportamiento de Avast (IDP.Generic). Avast puso los scripts en cuarentena, borró la tarea y vació y bloqueó el comando del registro `ytdl:` que lanzaba PowerShell directamente. Por eso el registro apunta ahora a `abrir.cmd`. La actualización se hace a mano.
- Los `.ps1` se guardan en ASCII (sin tildes): Windows PowerShell 5.1 lee mal UTF-8 sin BOM.
- Los decimales de `yt-dlp --print duration` se parsean con `InvariantCulture` (Windows en español usa coma decimal).
