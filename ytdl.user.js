// ==UserScript==
// @name         YTDL - Descargar audio
// @namespace    quim.ytdl
// @version      1.1
// @description  Boton para descargar el audio del video actual via ytdl:
// @match        https://www.youtube.com/*
// @grant        none
// @run-at       document-idle
// ==/UserScript==

(function () {
  'use strict';

  const CATEGORIAS = [
    { id: 'sesion',  texto: '🏋️ Sesión' },
    { id: 'musica',  texto: '🎵 Música' },
    { id: 'podcast', texto: '🎙️ Podcast' },
  ];

  function urlLimpia() {
    const u = new URL(location.href);
    if (u.pathname === '/watch' && u.searchParams.get('v')) {
      return 'https://www.youtube.com/watch?v=' + u.searchParams.get('v');
    }
    const m = u.pathname.match(/^\/shorts\/([\w-]+)/);
    if (m) return 'https://www.youtube.com/shorts/' + m[1];
    return null;
  }

  function lanzar(categoria) {
    const url = urlLimpia();
    if (!url) return;
    const a = document.createElement('a');
    a.href = 'ytdl:' + categoria + '?url=' + encodeURIComponent(url);
    document.body.appendChild(a);
    a.click();
    a.remove();
  }

  function boton(texto, fondo) {
    const b = document.createElement('button');
    b.textContent = texto;
    Object.assign(b.style, {
      background: fondo, color: '#fff', border: 'none', borderRadius: '18px',
      padding: '8px 14px', fontSize: '14px', cursor: 'pointer',
      boxShadow: '0 2px 6px rgba(0,0,0,.4)'
    });
    return b;
  }

  const caja = document.createElement('div');
  Object.assign(caja.style, {
    position: 'fixed', top: '11px', left: '75%', zIndex: '10000',
    display: 'none', flexDirection: 'column', alignItems: 'flex-start', gap: '6px',
    fontFamily: 'Roboto, Arial, sans-serif'
  });

  const menu = document.createElement('div');
  Object.assign(menu.style, { display: 'none', flexDirection: 'column', gap: '6px' });

  CATEGORIAS.forEach(c => {
    const b = boton(c.texto, '#333');
    b.addEventListener('click', () => { lanzar(c.id); menu.style.display = 'none'; });
    menu.appendChild(b);
  });

  const principal = boton('⬇ Descargar audio', '#cc0000');
  principal.addEventListener('click', () => {
    menu.style.display = menu.style.display === 'none' ? 'flex' : 'none';
  });

  caja.appendChild(principal);
  caja.appendChild(menu);
  document.body.appendChild(caja);

  function actualizar() {
    caja.style.display = urlLimpia() ? 'flex' : 'none';
    menu.style.display = 'none';
  }
  window.addEventListener('yt-navigate-finish', actualizar);
  actualizar();
})();
