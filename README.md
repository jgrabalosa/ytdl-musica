# 🎧 ytdl-musica

![Windows](https://img.shields.io/badge/Windows-10%2F11-0078D6?logo=windows&logoColor=white)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1-5391FE?logo=powershell&logoColor=white)
![Tampermonkey](https://img.shields.io/badge/Tampermonkey-userscript-00485B)
![yt-dlp](https://img.shields.io/badge/powered%20by-yt--dlp-red)
![License: MIT](https://img.shields.io/badge/License-MIT-green)

Un botón en YouTube que descarga el audio del vídeo en MP3, lo clasifica solo (**Sesión**, **Música** o **Podcast**) y lo deja en espejo en el móvil con Syncthing. Sin servicios en segundo plano, sin nube y sin nada oculto: una ventana te enseña lo que pasa.

> ⚠️ **Uso responsable.** Proyecto de uso personal. Descargar contenido puede ir contra los términos de servicio de YouTube; respeta esos términos y los derechos de autor de lo que descargues. El código se ofrece tal cual, sin garantías (ver [LICENSE](LICENSE)).

## ✨ Qué hace

- **Un clic** desde la barra superior de YouTube: ⬇ Descargar audio → 🏋️ Sesión · 🎵 Música · 🎙️ Podcast.
- **Podcasts clasificados por duración**: menos de 30 min a `Cortos`, el resto a `Largos`.
- **Podcasts ligeros y sin anuncios**: MP3 64 kbps mono (≈ 3 veces menos espacio) y [SponsorBlock](https://sponsor.ajay.app/) quita patrocinios, autopromoción y "suscríbete".
- **Música con carátula y metadatos** (título, artista) incrustados.
- **Aviso de duplicados**: si ya lo descargaste (en cualquier categoría), te avisa y te dice dónde está.
- **Espejo al móvil** con Syncthing, y **check de escuchado** en los podcasts con AntennaPod.

## 🧩 Cómo funciona

```
YouTube (botón) → ytdl:<categoria>?url=... → abrir.cmd → protocolo.ps1 → descargar.ps1 → yt-dlp
                                                                          ↓
                                       %USERPROFILE%\Music\YouTube ──Syncthing──→ móvil Music/YouTube
```

| Archivo | Qué hace |
|---|---|
| `ytdl.user.js` | Script de Tampermonkey. Añade el botón en la barra superior de YouTube. Envía siempre la URL limpia (`watch?v=ID`), sin playlist. |
| `abrir.cmd` | Lo lanza Windows al abrir un enlace `ytdl:`. Llama a `protocolo.ps1`. |
| `protocolo.ps1` | Valida el enlace (solo 3 categorías y solo URLs de YouTube), llama a `descargar.ps1` y muestra el resultado. |
| `descargar.ps1` | Consulta id y duración, avisa si ya se descargó, elige carpeta y descarga con yt-dlp. |
| `instalar.ps1` | Registra el enlace `ytdl:` en el usuario actual (HKCU, sin admin). |

### Carpetas y calidad

| Categoría | Carpeta | Calidad |
|---|---|---|
| 🏋️ Sesión | `Music\YouTube\Sesiones` | MP3 máxima calidad |
| 🎵 Música | `Music\YouTube\Musica` | MP3 máxima calidad |
| 🎙️ Podcast < 30 min | `Music\YouTube\Podcasts\Cortos` | MP3 64 kbps mono + SponsorBlock |
| 🎙️ Podcast ≥ 30 min | `Music\YouTube\Podcasts\Largos` | MP3 64 kbps mono + SponsorBlock |

- Los archivos intermedios se generan en `%TEMP%\ytdl`; a `Music\YouTube` solo llega el MP3 terminado (evita choques con Syncthing y que se sincronicen archivos a medias).
- `descargados.txt` (local, no versionado) guarda `id<TAB>fecha<TAB>carpeta` de cada descarga.

## 🚀 Instalación

1. **Dependencias** (PowerShell):
   ```powershell
   winget install --id yt-dlp.yt-dlp -e      # instala también Deno
   winget install --id Gyan.FFmpeg -e        # si ffmpeg no queda instalado
   ```
   Cierra y abre PowerShell y comprueba: `yt-dlp --version`, `deno --version`, `ffmpeg -version`.
2. **Clona** este repo en `%USERPROFILE%\YTDL`.
3. **Registra el enlace** `ytdl:`:
   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\YTDL\instalar.ps1"
   ```
4. **Tampermonkey**: crea un script nuevo y pega `ytdl.user.js`. En Chrome reciente: `chrome://extensions` → Tampermonkey → Detalles → activa "Permitir scripts de usuario".
5. La primera vez que pulses el botón, Chrome pregunta si abrir el enlace: marca **"Permitir siempre"** y **Abrir**.

> 🛡️ **Antivirus.** Algunos antivirus (p. ej. Avast, detección heurística *IDP.Generic*) desconfían de scripts de PowerShell lanzados desde un enlace. Si el tuyo los bloquea, revisa el código (es corto) y añade una excepción **solo para la carpeta** `YTDL`, usando el botón "Examinar" del antivirus.

## 📱 Móvil (opcional)

- **Syncthing**: comparte `Music\YouTube` con el móvil. PC en **Sólo Enviar**, móvil en **Sólo Recibir** (espejo en un solo sentido), ruta `/storage/emulated/0/Music/YouTube`. Si el selector de Android no deja elegir la carpeta, acéptala desde la Interfaz web de Syncthing del móvil y escribe la ruta a mano. Recomendado: sincronizar solo con Wi-Fi.
- **AntennaPod**: Añadir podcast → "Añadir carpeta local" con `Podcasts/Cortos` y `Podcasts/Largos`. Marca los episodios escuchados y recuerda por dónde ibas.

## 🔧 Si algo falla

| Síntoma | Qué hacer |
|---|---|
| `HTTP Error 403: Forbidden` | Reintentar. Si persiste, esperar 30-60 min (YouTube limita tras muchas descargas seguidas). |
| Las descargas dejan de funcionar en general | Actualizar a mano: `winget upgrade --id yt-dlp.yt-dlp -e` y `winget upgrade --id DenoLand.Deno -e` |
| El botón no hace nada | Comprobar `Get-ItemProperty 'HKCU:\Software\Classes\ytdl\shell\open\command'`. Si `(default)` está vacío, ejecutar `instalar.ps1`. |
| `WinError 32` (archivo en uso) | Comprobar que la línea de yt-dlp en `descargar.ps1` conserva `-P "temp:$env:TEMP\ytdl"`. |
| El antivirus bloquea o pone en cuarentena `protocolo.ps1` | Revisar el código y añadir una excepción para la carpeta `YTDL` (con "Examinar"). Si después el registro `ytdl:` queda vacío y no deja escribirlo, reiniciar el PC y ejecutar `instalar.ps1`. |

## 📝 Notas de diseño

- **yt-dlp se actualiza a mano, no desde los scripts.** Actualizarlo automáticamente (con una tarea programada oculta y, después, dentro de `protocolo.ps1`) hizo saltar el escudo de comportamiento del antivirus, que puso los scripts en cuarentena y bloqueó el comando del registro que lanzaba PowerShell directamente. Por eso el registro apunta a `abrir.cmd`.
- **Seguridad del enlace `ytdl:`**: cualquier web podría intentar abrir un enlace `ytdl:`, así que `protocolo.ps1` solo acepta las tres categorías y URLs de YouTube, y nunca ejecuta texto recibido.
- Los `.ps1` están en ASCII (sin tildes): Windows PowerShell 5.1 lee mal UTF-8 sin BOM.
- Las duraciones de `yt-dlp --print duration` se leen con `InvariantCulture` (Windows en español usa coma decimal).

## 📄 Licencia

[MIT](LICENSE). Basado en [yt-dlp](https://github.com/yt-dlp/yt-dlp), [FFmpeg](https://ffmpeg.org/), [Deno](https://deno.com/), [SponsorBlock](https://sponsor.ajay.app/), [Tampermonkey](https://www.tampermonkey.net/) y [Syncthing](https://syncthing.net/).
