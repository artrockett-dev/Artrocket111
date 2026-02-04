# encoding: UTF-8
# ar_startup/main 
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

Sketchup.require(File.join(__dir__, 'bridge'))
Sketchup.require(File.join(__dir__, 'ui', 'dialog'))

module ARAddons
  module ARStartup
    PLUGIN_DIR = File.expand_path(File.dirname(__FILE__))

    module_function

    def current_lang
      if defined?(::ARAddons) && defined?(::ARAddons::ARStartup) && defined?(::ARAddons::ARStartup::Reader)
        (::ARAddons::ARStartup::Reader.active_lang_base rescue 'ru').to_s.downcase.to_sym
      else
        :ru
      end
    end

    def tr(key)
      lang = current_lang
      T[lang][key] || T[:en][key] || key.to_s
    end

    T = {
      en: {
        name: 'Startup Settings',
        desc: 'Open Startup Settings (language, markup coefficient, display currency)'
      },
      ro: {
        name: 'Setări inițiale',
        desc: 'Deschide setările inițiale (limba, coeficientul de adaos, valuta de afișare)'
      },
      ru: {
        name: 'Стартовые настройки',
        desc: 'Открыть стартовые настройки (язык, коэффициент наценки, валюта отображения)'
      }
    }.freeze

    def show
      ARAddons::ARStartup::UI::Dialog.show
    end

    unless defined?(@registered)
      @registered = true

      cmd = ::UI::Command.new(tr(:name)) { show }
      cmd.tooltip         = tr(:name)
      cmd.status_bar_text = tr(:desc)
      cmd.menu_text       = tr(:name)

      cmd.instance_variable_set(:@__ar_role, :startup)

      begin
        start_icon = ARAddons::Utils.shared_icon('startup.png')
        if File.exist?(start_icon)
          cmd.small_icon = start_icon
          cmd.large_icon = start_icon
        end
      rescue
      end

      ARAddons::Registry.root_menu.add_item(cmd)
      ARAddons::Registry.toolbar.add_item(cmd)

      define_singleton_method(:_refresh_labels!) do
        begin
          cmd.tooltip         = tr(:name)
          cmd.status_bar_text = tr(:desc)
          cmd.menu_text       = tr(:name)
          cmd.set_validation_proc { MF_ENABLED }
        rescue
        end
      end

      orig_show = method(:show)
      define_singleton_method(:show) do
        _refresh_labels!
        orig_show.call
      end
      module_function :show
    end
  end
end
