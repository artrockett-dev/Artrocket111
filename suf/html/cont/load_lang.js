// cont/load_lang.js
;(function(){
  const SUPPORTED = ['en','ro','ru'];
  const FALLBACK  = 'ru'; // на случай полного отсутствия Ruby-моста

  // ——— утилиты ———
  function removeExistingLangScripts(){
    const re = /\/lang_(en|ro|ru)\.js(?:\?|#|$)/;
    [...document.querySelectorAll('script[src]')].forEach(s=>{
      if (re.test(s.getAttribute('src'))) s.parentNode.removeChild(s);
    });
    // чистим глобальные словари/функции, чтобы не осталось «ro»
    try { delete window.translate; } catch(_) { window.translate = undefined; }
    try { delete window.translateFromDB; } catch(_) {}
    try { delete window.translationDB; } catch(_) {}
  }

  function loadLocale(lang){
    const code = SUPPORTED.includes(lang) ? lang : FALLBACK;
    const s = document.createElement('script');
    s.type = 'text/javascript';
    s.src  = `../Resources/lang_${code}.js`;
    s.defer = false;           // важно: грузим синхронно до остального
    s.onload = () => {
      // Сигнал для всего остального кода: язык загружен
      window.__langReady = true;
      window.dispatchEvent(new CustomEvent('lang-ready', { detail: { lang: code }}));
      console.log('[load_lang] ready:', code);
    };
    document.head.appendChild(s);
  }

  // Ruby вызовет это, когда прочитает parameters.dat/.txt
  window.__setActiveLang = function(x){
    const lang = (x || '').toLowerCase();
    console.log('[load_lang] bridge says:', lang);
    removeExistingLangScripts();
    loadLocale(lang);
  };

  function askSketchup(){
    try {
      if (window.sketchup && typeof window.sketchup.getActiveLang === 'function') {
        window.sketchup.getActiveLang();
        return true;
      }
    } catch(_) {}
    return false;
  }

  // ——— основной запуск ———
  // Пытаемся запросить язык у Ruby; если моста нет, жёстко грузим FALLBACK
  if (!askSketchup()) {
    console.warn('[load_lang] no bridge -> fallback:', FALLBACK);
    removeExistingLangScripts();
    loadLocale(FALLBACK);
  }

  // На случай, если ответ придёт очень поздно: держим текущую стратегию — не грузим до ответа.
  // Если нужен таймаут, можно раскомментировать (обычно не требуется):
  // setTimeout(() => { if (!window.__langReady) { removeExistingLangScripts(); loadLocale(FALLBACK); } }, 2000);
})();
