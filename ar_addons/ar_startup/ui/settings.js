// ar_startup/ui/settings.js
/* Copyright (c) 2025 Artiom Gurduz
   SPDX-License-Identifier: LicenseRef-Proprietary
   Ownership remains with the author. Internal use by ART ROCKET is permitted. */
;(function(){
  // --- словарь интерфейса ---
  const I18N = {
    en: {
      choose_lang: "Choose your language",
      markup_coef: "Markup coefficient",
      coef_hint:   "Format: 1.10 · Minimum: 1.00",
      currency:    "Currency",
      cancel:      "Cancel",
      save:        "Save"
    },
    ro: {
      choose_lang: "Alege limba",
      markup_coef: "Coeficientul de adaos",
      coef_hint:   "Format: 1.10 · Minim: 1.00",
      currency:    "Valuta",
      cancel:      "Anulează",
      save:        "Salvează"
    },
    ru: {
      choose_lang: "Выберите язык",
      markup_coef: "Коэффициент наценки",
      coef_hint:   "Формат: 1.10 · Минимум: 1.00",
      currency:    "Валюта",
      cancel:      "Отмена",
      save:        "Сохранить"
    }
  };

  const FX_ALLOWED = ['MDL','EUR','USD','RON'];

  function applyI18n(lang){
    const dict = I18N[lang] || I18N.ru;
    document.querySelectorAll('[data-i18n]').forEach(function(el){
      var k = el.getAttribute('data-i18n');
      if (dict[k]) el.textContent = dict[k];
    });
    var coef = document.getElementById('coef');
    if (coef) coef.setAttribute('placeholder','1.10');
  }

  // — добавляем в форму строку «Валюта», если её нет в HTML
  function ensureCurrencyRow(){
    if (document.getElementById('curr')) return;
    var langSel = document.getElementById('lang');
    var anchor = langSel ? langSel.closest('.form-row') || langSel.parentNode : document.body;

    var row = document.createElement('div');
    row.className = 'form-row';
    row.innerHTML = ''+
      '<label><span data-i18n="currency">Currency</span></label>'+
      '<div class="field"><select id="curr"></select></div>';
    (anchor && anchor.parentNode) ? anchor.parentNode.insertBefore(row, anchor.nextSibling) : document.body.appendChild(row);

    var sel = row.querySelector('#curr');
    FX_ALLOWED.forEach(function(c){
      var opt = document.createElement('option');
      opt.value = c; opt.textContent = c;
      sel.appendChild(opt);
    });
  }

  // Ruby → текущие значения
  window.__applyCurrent = function(payload){
    try{
      ensureCurrencyRow();
      var lang = payload && payload.lang ? String(payload.lang) : 'ru';
      var coef = payload && payload.coef ? String(payload.coef) : '1.00';
      var curr = payload && payload.curr ? String(payload.curr) : 'EUR';

      document.getElementById('lang').value  = lang;
      document.getElementById('coef').value  = coef;
      var curSel = document.getElementById('curr');
      if (curSel) curSel.value = curr;

      applyI18n(lang);
    }catch(e){}
  };

  // Язык из бриджа
  window.__setActiveLang = function(base){
    try{
      var lang = (base || 'ru').toLowerCase();
      applyI18n(lang);
      try { window.sketchup.getCurrent(); } catch(e){}
    }catch(e){}
  };

  // FX-настройки (если кто-то захочет подтянуть в это окно)
  window.__applyFxSettings = function(payload){
    try{
      ensureCurrencyRow();
      var show = (payload && payload.show) ? String(payload.show) : 'EUR';
      var curSel = document.getElementById('curr');
      if (curSel) curSel.value = show;
    }catch(e){}
  };

  // первичный запрос
  (function boot(){
    var asked = false;
    try {
      if (window.sketchup && typeof window.sketchup.getActiveLang === 'function') {
        window.sketchup.getActiveLang();
        asked = true;
      }
    } catch(e){}
    if (!asked) {
      applyI18n('ru');
      try { window.sketchup.getCurrent(); } catch(e){}
    }
    try {
      if (window.sketchup && typeof window.sketchup.getFxSettings === 'function') {
        window.sketchup.getFxSettings();
      }
    } catch(e){}
  })();

  // локальное обновление подписей при смене языка
  document.addEventListener('DOMContentLoaded', function(){
    var sel = document.getElementById('lang');
    if (sel) {
      sel.addEventListener('change', function(){
        applyI18n(this.value);
      });
    }
  });

  // Сохранение
  document.getElementById('save').addEventListener('click', function(){
    var lang = document.getElementById('lang').value;
    var coef = document.getElementById('coef').value.trim();
    var currEl = document.getElementById('curr');
    var curr = currEl ? currEl.value : 'EUR';
    if(!coef){ coef = '1.00'; }
    coef = coef.replace(',', '.');
    try{ window.sketchup.saveSettings(JSON.stringify({lang: lang, coef: coef, curr: curr})); }catch(e){}
  });

  // Закрыть
  document.getElementById('cancel').addEventListener('click', function(){
    try{ window.close(); }catch(e){}
  });
})();
