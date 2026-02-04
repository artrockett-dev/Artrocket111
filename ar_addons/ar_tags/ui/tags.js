// Plugins/ar_addons/ar_tags/ui/tags.js
/* Copyright (c) 2025 Artiom Gurduz
   SPDX-License-Identifier: LicenseRef-Proprietary
   Ownership remains with the author. Internal use by ART ROCKET is permitted. */
(function () {
  // Глобальная функция — Ruby пушит сюда состояния
  window.__applyTagStates = function (states) {
    try {
      (states || []).forEach(function (s) {
        var icon = document.querySelector('.eye-icon[data-tag="' + s.name + '"]');
        if (!icon) return;
        toggleClasses(icon, !!s.visible);
      });
    } catch (e) {}
  };

  function toggleClasses(iconEl, makeVisible) {
    iconEl.classList.toggle('visible', makeVisible);
    iconEl.classList.toggle('hidden', !makeVisible);
    var box = iconEl.parentElement.querySelector('.tag-text');
    if (box) {
      var t1 = box.querySelector('.tag-title');
      var t2 = box.querySelector('.tag-subtitle');
      if (t1) { t1.classList.toggle('visible', makeVisible); t1.classList.toggle('hidden', !makeVisible); }
      if (t2) { t2.classList.toggle('visible', makeVisible); t2.classList.toggle('hidden', !makeVisible); }
    }
  }

  function bindHandlers() {
    // Переключение отдельных тегов
    document.querySelectorAll('.eye-icon').forEach(function (icon) {
      icon.addEventListener('click', function (event) {
        var iconEl = event.currentTarget;
        var tagName = iconEl.getAttribute('data-tag');
        var currentlyVisible = iconEl.classList.contains('visible');

        // Локально сразу
        toggleClasses(iconEl, !currentlyVisible);

        // Сообщаем в Ruby
        try {
          window.sketchup.toggle_tag(
            JSON.stringify({ action: 'toggle', tag: tagName, visible: !currentlyVisible })
          );
        } catch (e) {
          console.warn('[ARTags] toggle_tag error:', e);
        }
      });
    });

    // Кнопки Hide all
    document.querySelectorAll('.hide-all-btn').forEach(function (btn) {
      btn.addEventListener('click', function (event) {
        var categoryId = event.currentTarget.getAttribute('data-category');
        var icons = document.querySelectorAll('.eye-icon.visible[data-category="' + categoryId + '"]');
        icons.forEach(function (iconEl) {
          toggleClasses(iconEl, false);
          var tagName = iconEl.getAttribute('data-tag');
          try {
            window.sketchup.toggle_tag(
              JSON.stringify({ action: 'toggle', tag: tagName, visible: false })
            );
          } catch (e) {}
        });
      });
    });
  }

  document.addEventListener('DOMContentLoaded', function () {
    bindHandlers();
    try { window.sketchup.ready(); } catch (e) {}
    try { window.sketchup.get_states(); } catch (e) {}
  });

  window.addEventListener('focus', function () {
    try { window.sketchup.get_states(); } catch (e) {}
  });
})();
