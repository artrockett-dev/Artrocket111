/* Copyright (c) 2025 Artiom Gurduz
   SPDX-License-Identifier: LicenseRef-Proprietary
   Ownership remains with the author. Internal use by ART ROCKET is permitted. */
console.log("ARLIB global.js loaded");

// ---------------- i18n (двойной язык: UI и Assets) ----------------
const ARLIB_LANG_SUPPORTED = ['en','ro','ru'];
const ARLIB_DEFAULT_UI     = 'en';
const ARLIB_DEFAULT_ASSETS = 'en';

// Глобальное состояние
window.ARLIB_I18N = window.ARLIB_I18N || {
  ui: ARLIB_DEFAULT_UI,
  assets: ARLIB_DEFAULT_ASSETS,
  system: {},
  assetsDict: {}
};

// Фолбэк для UI (EN)
const FALLBACK_SYSTEM_EN = {
  'tabs.modules': 'Modules',
  'tabs.components': 'Components',
  'search.placeholder.modules': 'Search modules...',
  'search.placeholder.components': 'Search components...',
  'loading': 'Loading...',
  'no.results': 'No results.'
};

// --- utils: язык из URL / localStorage / override ---
function getParam(name){
  const p = new URLSearchParams(window.location.search);
  const v = p.get(name);
  return (v && typeof v === 'string') ? v.toLowerCase() : null;
}
function safeLang(x, def){
  const v = (x || '').toLowerCase();
  return ARLIB_LANG_SUPPORTED.includes(v) ? v : def;
}

let __overrideUI = null;
let __overrideAssets = null;

function resolveLangUI(){
  if (__overrideUI) return __overrideUI;
  const url = getParam('lang_ui') || getParam('lang');
  if (url) return safeLang(url, ARLIB_DEFAULT_UI);
  const ls  = localStorage.getItem('arlib.uiLang');
  if (ls)   return safeLang(ls, ARLIB_DEFAULT_UI);
  return ARLIB_DEFAULT_UI;
}
function resolveLangAssets(){
  if (__overrideAssets) return __overrideAssets;
  const url = getParam('lang_assets') || getParam('lang');
  if (url) return safeLang(url, ARLIB_DEFAULT_ASSETS);
  const ls  = localStorage.getItem('arlib.assetsLang');
  if (ls)   return safeLang(ls, ARLIB_DEFAULT_ASSETS);
  return ARLIB_DEFAULT_ASSETS;
}

function setLangs(ui, assets){
  const uiLang = safeLang(ui, ARLIB_DEFAULT_UI);
  const asLang = safeLang(assets, uiLang);
  __overrideUI = uiLang;
  __overrideAssets = asLang;
  localStorage.setItem('arlib.uiLang', uiLang);
  localStorage.setItem('arlib.assetsLang', asLang);
  window.ARLIB_I18N.ui = uiLang;
  window.ARLIB_I18N.assets = asLang;
}

// --- загрузка файлов с переводами ---
function loadScript(src){
  return new Promise((res) => {
    const s = document.createElement('script');
    s.type='text/javascript'; s.src=src; s.defer=true;
    s.onload=()=>res(true);
    s.onerror=()=>{ console.warn('ARLIB: failed to load', src); res(false); };
    document.head.appendChild(s);
  });
}

/* ===== Индекс словаря для безопасной замены (один проход) ===== */
let __ARLIB_DICT_INDEX = null;
function __escapeRegex(s){ return String(s).replace(/[.*+?^${}()|[\]\\]/g,'\\$&'); }
function __normalizeLowerNFC(s){ return String(s ?? '').normalize('NFC').toLowerCase(); }
function __buildDictIndex(dict){
  const keys = Object.keys(dict || {});
  const mapLowerToVal = new Map();
  const valueSetLower = new Set();
  keys.forEach(k=>{
    const val = dict[k];
    mapLowerToVal.set(__normalizeLowerNFC(k), val);
    valueSetLower.add(__normalizeLowerNFC(val));
  });
  // Единый регекс с «не буквенно-цифровыми» границами
  const escaped = keys
    .filter(k=>k && k.length)
    .sort((a,b)=>b.length - a.length)
    .map(__escapeRegex);
  const alternation = escaped.length ? "(?:" + escaped.join("|") + ")" : "(?!)";
  const regex = new RegExp(`(?<![\\p{L}\\p{N}])${alternation}(?![\\p{L}\\p{N}])`, 'giu');
  __ARLIB_DICT_INDEX = { mapLowerToVal, valueSetLower, regex };
}
function __ensureDictIndex(){
  if (!__ARLIB_DICT_INDEX) __buildDictIndex(window.ARLIB_I18N.assetsDict || {});
  return __ARLIB_DICT_INDEX;
}

async function loadLanguageBundles(uiLang, assetsLang){
  const ui    = safeLang(uiLang, resolveLangUI());
  const assets= safeLang(assetsLang, resolveLangAssets());

  window.ARLIB_I18N.system     = {};
  window.ARLIB_I18N.assetsDict = {};

  await Promise.all([
    loadScript(`i18n/system/system_${ui}.js`),
    loadScript(`i18n/assets/assets_${assets}.js`)
  ]);

  const sys    = (window.ARLIB_I18N && window.ARLIB_I18N.system) || {};
  const assetsDict = (window.ARLIB_I18N && (window.ARLIB_I18N.assets || window.ARLIB_I18N.assetsDict)) || {};

  window.ARLIB_I18N.ui         = ui;
  window.ARLIB_I18N.assets     = assets;
  window.ARLIB_I18N.system     = { ...FALLBACK_SYSTEM_EN, ...sys };
  window.ARLIB_I18N.assetsDict = assetsDict;

  __buildDictIndex(window.ARLIB_I18N.assetsDict);

  window.t    = t;
  window.tKey = tKey;
}

// --- публичный API для смены языков из Ruby/моста ---
window.ARLIB_setLanguages = async function(ui, assets){
  setLangs(ui, assets);
  await loadLanguageBundles(ui, assets);
  applyI18n();
  if (typeof window.currentPath !== 'undefined') {
    document.getElementById('loading')?.style && (document.getElementById('loading').style.display='block');
    try { window.sketchup.get_folder_contents(window.currentPath || ''); } catch(_){}
  }
};

// --- обработчик вызова из bridge.rb ---
window.__setActiveLang = function(base){
  const lang = safeLang(base, 'en');
  window.ARLIB_setLanguages(lang, lang);
};

// --- ключевые функции t() / tKey() ---
function t(key, fallback){
  const sys = (window.ARLIB_I18N && window.ARLIB_I18N.system) || {};
  return sys[key] ?? fallback ?? key;
}

/* tKey: см. комментарии выше */
function tKey(name){
  const dict = (window.ARLIB_I18N && window.ARLIB_I18N.assetsDict) || {};
  if(name==null) return '';
  let raw = String(name).normalize('NFC').trim();
  if (!raw) return '';

  const { mapLowerToVal, valueSetLower, regex } = __ensureDictIndex();

  const rawLower = __normalizeLowerNFC(raw);
  if (valueSetLower.has(rawLower)) return raw;
  if (Object.prototype.hasOwnProperty.call(dict, raw)) return dict[raw];
  if (!regex) return raw;

  const out = raw.replace(regex, (m)=>{
    const repl = mapLowerToVal.get(__normalizeLowerNFC(m));
    return (typeof repl === 'string') ? repl : m;
  });

  return out;
}

/* ===== отображаемое имя для плитки ===== */
function normalizeUnderscoresToSpace(str){
  return String(str).replace(/_/g,' ').replace(/\s{2,}/g,' ').trim();
}
function formatDisplayName(raw){
  return normalizeUnderscoresToSpace(tKey(raw));
}

/* ===== helper: очистка имени папки от ведущих чисел ===== */
function stripLeadingIndex(str){
  return String(str)
    .replace(/^\s*\d+(?:\.\d+)?\s*([._\-–—\)]\s*)?/u, '')
    .trim();
}

/* ===== ведущий номер из подписи карточки ===== */
function extractLeadingIndex(txt){
  const s = String(txt || '');
  const m = s.match(/^\s*(\d+(?:[.,]\d+)?)\s+/);
  if (!m) return [null, s];
  const idx = m[1].replace(',', '.');
  const rest = s.slice(m[0].length);
  return [idx, rest.trim()];
}

/* ===== бейджи на карточках компонентов ===== */
function decorateComponentBadges(){
  const cards = document.querySelectorAll('.component-card');
  cards.forEach(card=>{
    if (card.hasAttribute('data-idx')) return;
    const nameEl = card.querySelector('.component-name');
    if (!nameEl) return;
    const rawText = nameEl.textContent || '';
    const [idx, rest] = extractLeadingIndex(rawText);
    const caption = normalizeUnderscoresToSpace(rest || rawText);
    nameEl.textContent = caption;
    if (idx) card.setAttribute('data-idx', idx);
  });
}

function updateBreadcrumbs(root, cwd){
  const wrap = document.getElementById('breadcrumbs');
  if (!wrap) return;

  const rootN = String(root||'').replace(/\\/g,'/');
  const cwdN  = String(cwd ||'').replace(/\\/g,'/');
  let rel = cwdN.startsWith(rootN) ? cwdN.slice(rootN.length) : cwdN;
  rel = rel.replace(/^\/+/, '');

  const parts = rel ? rel.split('/').filter(Boolean) : [];
  wrap.style.display = parts.length ? 'flex' : 'none';
  wrap.innerHTML = '';
  if (!parts.length) return;

  let acc = rootN;
  parts.forEach((p, i) => {
    acc = (acc + '/' + p).replace(/\/+/g,'/');

    const crumb = document.createElement('span');
    crumb.className = 'crumb';
    crumb.setAttribute('data-path', acc);
    crumb.setAttribute('tabindex', '0');
    crumb.textContent = stripLeadingIndex(tKey(p));
    wrap.appendChild(crumb);

    if (i < parts.length - 1) {
      const sep = document.createElement('span');
      sep.className = 'sep';
      sep.textContent = '›';
      wrap.appendChild(sep);
    }
  });

  // Append the trailing "+" control pointing to the final accumulated path
  const plus = document.createElement('span');
  plus.className = 'crumb_plus';
  plus.setAttribute('data-path', acc);
  plus.setAttribute('tabindex', '0');
  plus.setAttribute('aria-label', 'Add here');
  plus.textContent = '+';
  wrap.appendChild(plus);
}

document.addEventListener('click',(e)=>{
  const e1 = e.target.closest?.('.crumb');
  const e2 = e.target.closest?.('.crumb_plus');
  if(e1){
    const path = e1.getAttribute('data-path'); if(!path) return;
    openCrumbPath(path);
  } else if(e2) {
    const path = e2.getAttribute('data-path'); if(!path) return;
    saveCrumbPath(path);
  }
});
document.addEventListener('keydown',(e)=>{
  if(e.key!=='Enter') return;
  const el = e.target.closest?.('.crumb'); if(!el) return;
  const path = el.getAttribute('data-path'); if(!path) return;
  openCrumbPath(path);
});
function openCrumbPath(path){
  window.currentPath = path.replace(/\\/g,'/');
  document.getElementById('loading').style.display='block';
  window.sketchup.get_folder_contents(window.currentPath);
}
function saveCrumbPath(path){
  window.currentPath = path.replace(/\\/g,'/');
  document.getElementById('loading').style.display='block';
  window.sketchup.save_folder_contents(window.currentPath);
}
window.openCrumbPath = openCrumbPath;

// -------------- общий рендер ответа от Ruby --------------
function populateFolderContents(contents){
  const safe = JSON.parse(JSON.stringify(contents||{}));

  if(safe && Array.isArray(safe.folders)){
    safe.folders = safe.folders.map(f=>({
      ...f,
      name: stripLeadingIndex(tKey(f.name))
    }));
  }

  if(safe && safe.root && safe.cwd) updateBreadcrumbs(safe.root, safe.cwd);

  const tKeyFormatted = (s) => formatDisplayName(s);

  if(window.currentLibrary === 'components'){
    Components.populateFolderContents(safe, tKeyFormatted);
  } else {
    Modules.populateFolderContents(safe, tKeyFormatted);
  }

  requestAnimationFrame(()=> setTimeout(decorateComponentBadges, 0));
  // Армируем авто-сброс увеличений после любого рендера (чистый JS)
  requestAnimationFrame(()=> setTimeout(arlibArmAutoCollapseZoom, 0));
}
window.populateFolderContents = populateFolderContents;

// -------------- поиск / навигация --------------
window.currentLibrary = 'modules';
window.currentPath = '';

function buildSearchPayload(q){
  const dict = (window.ARLIB_I18N && window.ARLIB_I18N.assetsDict) || {};
  const qLC  = String(q).toLowerCase();
  const alts = [];
  Object.keys(dict).forEach(k=>{
    const v = String(dict[k]||'');
    if(!k) return;
    if(k.toLowerCase().includes(qLC) || v.toLowerCase().includes(qLC)) alts.push(k);
  });
  return JSON.stringify({ q, alt_keys: Array.from(new Set(alts)) });
}

// debounce helper
function debounce(fn, wait){
  let t; return function(...args){
    clearTimeout(t); t = setTimeout(()=>fn.apply(this,args), wait);
  };
}
const debouncedSearch = debounce(()=>{
  const el = document.getElementById('search-bar');
  if(!el) return;
  const q = el.value.trim();
  if(!q) return;
  window.sketchup.get_folder_contents(window.currentPath || '', buildSearchPayload(q));
}, 300);

function handleSearch(){ debouncedSearch(); }
window.handleSearch = handleSearch;

document.addEventListener('keydown', (e)=>{
  if(e.key === 'Enter'){
    const el = document.activeElement;
    if(el && el.id === 'search-bar'){
      e.preventDefault();
      const q = el.value.trim();
      if(q) window.sketchup.get_folder_contents(window.currentPath || '', buildSearchPayload(q));
    }
  }
});

function goToRoot(){
  window.currentPath = '';
  document.getElementById('loading').style.display='block';
  window.sketchup.get_folder_contents('');
}
function goUp(){
  if(!window.currentPath) return;
  const norm = window.currentPath.replace(/\\/g,'/');
  const parts = norm.split('/').filter(Boolean); parts.pop();
  window.currentPath = parts.join('/');
  document.getElementById('loading').style.display='block';
  window.sketchup.get_folder_contents(window.currentPath);
}
function switchLibrary(library){
  document.querySelectorAll('.library-button').forEach(b=>b.classList.remove('active'));
  const btn = document.getElementById(`btn-${library}`); if(btn) btn.classList.add('active');
  window.currentLibrary = library; window.currentPath = '';
  applyI18n();
  window.sketchup.switch_library(library);
}
window.switchLibrary = switchLibrary;
window.goToRoot = goToRoot;
window.goUp = goUp;

// -------------- i18n в UI --------------
function applyI18n(){
  const btnM = document.getElementById('btn-modules');
  const btnC = document.getElementById('btn-components');
  if(btnM) btnM.textContent = t('tabs.modules','Modules');
  if(btnC) btnC.textContent = t('tabs.components','Components');
  const loading = document.getElementById('loading');
  if(loading) loading.textContent = t('loading','Loading...');
  const sb = document.getElementById('search-bar');
  if(sb) sb.placeholder = window.currentLibrary==='components'
    ? t('search.placeholder.components','Search components...')
    : t('search.placeholder.modules','Search modules...');
}
window.applyI18n = applyI18n;

// --- Монитор активности окна (без спама — только переходы) ---
(function attachActivePings(){
  if (window.__arlib_focus_bound) return; window.__arlib_focus_bound = true;
  let state = null;
  const compute = ()=> document.visibilityState === 'visible' && document.hasFocus();
  const pingIfChanged = (src)=>{
    const now = compute();
    if (now === state) return;
    state = now;
    try { window.sketchup && window.sketchup.dlg_focus && window.sketchup.dlg_focus(now ? 1 : 0); } catch(_) {}
    try { console.debug && console.debug('[ARLIB dlg_focus]', now ? 'ACTIVE' : 'INACTIVE', src||''); } catch(_) {}
  };
  window.addEventListener('focus',  ()=> pingIfChanged('focus'),  {capture:true});
  window.addEventListener('blur',   ()=> pingIfChanged('blur'),   {capture:true});
  document.addEventListener('visibilitychange', ()=> pingIfChanged('visibilitychange'), {capture:true});
  ['pointerdown','keydown','mousedown'].forEach(ev=>{
    document.addEventListener(ev, ()=> pingIfChanged('input:'+ev), {capture:true});
  });
  state = !compute();
  pingIfChanged('init');
})();

// -------------- стрелки = поворот выделения в модели --------------
(function attachArrowRotate(){
  const isTypingTarget = el => {
    if(!el) return false;
    const tag = (el.tagName || '').toLowerCase();
    return tag === 'input' || tag === 'textarea' || el.isContentEditable;
  };
  document.addEventListener('keydown', (e)=>{
    if(!['ArrowLeft','ArrowRight','ArrowUp','ArrowDown'].includes(e.key)) return;
    if(isTypingTarget(document.activeElement)) return;
    e.preventDefault();
    const map = {
      ArrowLeft:  ['z','ccw'],
      ArrowRight: ['z','cw'],
      ArrowUp:    ['x','cw'],
      ArrowDown:  ['x','ccw'],
    };
    const [axis, dir] = map[e.key];
    try { window.sketchup && window.sketchup.dlg_focus && window.sketchup.dlg_focus(1); } catch(_){}
    try { window.sketchup.rotate_selection(axis, dir); } catch(_){}
  });
})();

/* ============================
   === Auto-collapse for expanded component tiles (pure JS/CSS) ===
   Фикс «залипания» увеличения плитки (класс .expanded):
   - отслеживаем появление класса .expanded на .component-card img;
   - ставим таймер 2s и снимаем класс;
   - без каких-либо коллбэков из Ruby.
   ============================ */
(function arlibAutoCollapseZoom(){
  const TIMEOUT_MS = 2000;
  const timers = new WeakMap();

  function scheduleCollapse(img, delay = TIMEOUT_MS){
    try{
      const prev = timers.get(img);
      if (prev) clearTimeout(prev);
      const id = setTimeout(()=>{
        img.classList.remove('expanded');
        timers.delete(img);
      }, delay);
      timers.set(img, id);
    }catch(_){}
  }

  // утилита: снять все «залипшие» увеличения вручную (чистый JS)
  window.ARLIB_collapseAllExpandedNow = function(){
    document.querySelectorAll('.component-card img.expanded').forEach(img=>{
      img.classList.remove('expanded');
      const prev = timers.get(img); if (prev) clearTimeout(prev);
      timers.delete(img);
    });
  };

  function bindObserver(){
    if (window.__arlib_zoomObserverBound) return;
    window.__arlib_zoomObserverBound = true;

    const obs = new MutationObserver((mutList)=>{
      for (const m of mutList){
        // Изменение классов на IMG
        if (m.type === 'attributes' && m.attributeName === 'class'){
          const el = m.target;
          if (el && el.tagName === 'IMG' && el.closest('.component-card')){
            if (el.classList.contains('expanded')) scheduleCollapse(el);
          }
        }
        // Появление новых IMG
        if (m.type === 'childList' && (m.addedNodes?.length)){
          m.addedNodes.forEach(node=>{
            if (!(node instanceof Element)) return;
            if (node.tagName === 'IMG' && node.classList.contains('expanded') && node.closest('.component-card')){
              scheduleCollapse(node);
            }
            node.querySelectorAll?.('.component-card img.expanded')?.forEach(img=> scheduleCollapse(img));
          });
        }
      }
    });

    obs.observe(document.documentElement, {
      subtree:true, childList:true, attributes:true, attributeFilter:['class']
    });

    // начальный проход: на случай уже выставленного expanded
    document.querySelectorAll('.component-card img.expanded').forEach(img=> scheduleCollapse(img));
  }

  // Экспорт «армирования» для вызова после перерисовки грида
  window.arlibArmAutoCollapseZoom = bindObserver;

  // Армируем сразу на раннем кадре — чисто JS
  requestAnimationFrame(bindObserver);
})();

// -------------- init --------------
function requestBridgeLang(){
  try{
    if(window.sketchup && typeof window.sketchup.getActiveLang === 'function'){
      window.sketchup.getActiveLang();
      return true;
    }
  }catch(_){}
  return false;
}

window.addEventListener('load', async ()=>{
  const asked = requestBridgeLang();
  let timedOut = false;
  setTimeout(()=>{ timedOut = true; }, 300);

  await new Promise(r => setTimeout(r, 120));

  if (!asked || timedOut) {
    const ui = resolveLangUI();
    const as = resolveLangAssets();
    setLangs(ui, as);
    await loadLanguageBundles(ui, as);
    applyI18n();
    switchLibrary('modules');
  } else {
    setTimeout(async ()=>{
      if (!window.ARLIB_I18N.system || Object.keys(window.ARLIB_I18N.system).length === 0) {
        const ui = resolveLangUI();
        const as = resolveLangAssets();
        setLangs(ui, as);
        await loadLanguageBundles(ui, as);
        applyI18n();
        switchLibrary('modules');
      } else {
        switchLibrary('modules');
      }
    }, 400);
  }
});
