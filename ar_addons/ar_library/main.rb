# encoding: UTF-8
# ar_library/main
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted. 

# ВАЖНО: грузим наше ядро через Sketchup.require и БЕЗ расширения
begin
  Sketchup.require(File.join(__dir__, 'core'))
rescue LoadError => e
  puts "[ARLIB] failed to load core: #{e.class}: #{e.message}"
  # не выходим исключением — позволим остальному коду загрузиться, чтобы видеть лог
end

module ARAddons
  module ARLibrary
    module_function

    # ---- локализация названия/описания кнопки ----
    T = {
      en: { name: 'Library',    desc: 'Open component/module library (insert, replace, rotate).' },
      ro: { name: 'Bibliotecă', desc: 'Deschide biblioteca de componente/module (inserare, înlocuire, rotire).' },
      ru: { name: 'Библиотека', desc: 'Открыть библиотеку компонентов/модулей (вставка, замена, поворот).' }
    }.freeze

    def current_lang
      if defined?(::ARAddons) && defined?(::ARAddons::ARStartup) && defined?(::ARAddons::ARStartup::Reader)
        (::ARAddons::ARStartup::Reader.active_lang_base rescue 'ru').to_s.downcase.to_sym
      else
        :ru
      end
    end

    def tr(key)
      lang = current_lang
      (T[lang] && T[lang][key]) || T[:en][key] || key.to_s
    end

    def show
      ::ARLIB.open_library_dialog
    end

    unless file_loaded?(__FILE__)
      cmd = ::UI::Command.new(tr(:name)) { show }

      # поставить кнопку первой на общей панели
      cmd.instance_variable_set(:@__ar_order, :first)

      # Иконка: сперва свои, затем общий fallback
      begin
        small = File.join(__dir__, 'icons', 'icon_small.png')
        large = File.join(__dir__, 'icons', 'icon_large.png')
        if File.exist?(small) then cmd.small_icon = small end
        if File.exist?(large) then cmd.large_icon = large end
        if !File.exist?(small) || !File.exist?(large)
          shared = ARAddons::Utils.shared_icon('library.png')
          if File.exist?(shared)
            cmd.small_icon = shared
            cmd.large_icon = shared
          end
        end
      rescue
      end

      cmd.tooltip         = tr(:name)
      cmd.status_bar_text = tr(:desc)
      cmd.menu_text       = tr(:name)

      # меню и буфер панели бандла
      ARAddons::Registry.root_menu.add_item(cmd)
      ARAddons::Registry.toolbar.add_item(cmd)

      # Обновление локализованных подписей (при смене языка в ar_startup)
      define_singleton_method(:_refresh_labels!) do
        begin
          cmd.tooltip         = tr(:name)
          cmd.status_bar_text = tr(:desc)
          cmd.menu_text       = tr(:name)
          cmd.set_validation_proc { ::MF_ENABLED } # триггернуть перерисовку тулбара
        rescue
        end
      end

      # Оборачиваем show: перед показом диалога обновляем подписи
      orig_show = method(:show)
      define_singleton_method(:show) do
        _refresh_labels!
        orig_show.call
      end
      module_function :show

      file_loaded(__FILE__)
    end
  end
end
