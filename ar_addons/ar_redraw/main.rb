# encoding: UTF-8
# Plugins/ar_addons/ar_redraw/main
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'

module ARAddons
  module ARRedraw
    DEBUG = false
    @cmd_generic = nil
    module_function

    def log(msg) ; puts "[ARRedraw] #{msg}" if DEBUG ; end

    # ---------- локализация (EN/RO/RU) ----------
    T = {
      en: {
        name: 'Redraw',
        desc: 'Redraw components. Helps refresh their state after edits or glitches.',
        pick: 'Select one or more components to redraw.'
      },
      ro: {
        name: 'Reîmprospătare',
        desc: 'Reîmprospătează componentele. Ajută la actualizarea stării după modificări sau blocaje.',
        pick: 'Selectează unul sau mai multe componente pentru reîmprospătare.'
      },
      ru: {
        name: 'Перерисовать',
        desc: 'Перерисовать компоненты. Помогает обновить их состояние после изменений или сбоев.',
        pick: 'Выберите один или несколько компонентов для перерисовки.'
      }
    }.freeze

    def current_lang
      if defined?(::ARAddons) && defined?(::ARAddons::ARStartup) && defined?(::ARAddons::ARStartup::Reader)
        (::ARAddons::ARStartup::Reader.active_lang_base rescue 'ru').to_s.downcase.to_sym
      else
        :ru
      end
    end
    def tr(key) ; (T[current_lang] && T[current_lang][key]) || T[:en][key] || key.to_s end

    def refresh_command_labels!
      return unless @cmd_generic
      @cmd_generic.tooltip         = tr(:name)
      @cmd_generic.status_bar_text = tr(:desc)
      @cmd_generic.menu_text       = tr(:name)
    rescue
    end

    # ---------- DC API ----------
    def dc_iface
      if defined?($dc_observers) && $dc_observers.respond_to?(:get_latest_class)
        $dc_observers.get_latest_class
      end
    rescue
      nil
    end

    def selection_instances
      sel = Sketchup.active_model&.selection
      return [] unless sel && sel.respond_to?(:to_a)
      (sel.grep(Sketchup::ComponentInstance) + sel.grep(Sketchup::Group)).uniq
    end

    def nudge_dynamic_attrs!(inst)
      inst.set_attribute('dynamic_attributes', '_lastmodified', Time.now.to_f) rescue nil
      inst.set_attribute('dynamic_attributes', '_refresh', true)               rescue nil
    end

    def redraw_batch(instances, op_name = tr(:name))
      return 0 if instances.nil? || instances.empty?
      model = Sketchup.active_model
      dc    = dc_iface
      used_fallback = false
      cnt = 0
      started = false

      model.start_operation(op_name, true, false, true)
      started = true
      instances.each do |i|
        if dc && (dc.respond_to?(:redraw) || dc.respond_to?(:redraw_with_undo))
          begin
            if dc.respond_to?(:redraw)
              dc.redraw(i)
            else
              dc.redraw_with_undo(i)
            end
            cnt += 1
          rescue
            nudge_dynamic_attrs!(i); cnt += 1; used_fallback = true
          end
        else
          nudge_dynamic_attrs!(i); cnt += 1; used_fallback = true
        end
      end
      model.commit_operation
      started = false
      log "redraw_batch: processed=#{cnt} fallback=#{used_fallback}"
      cnt
    rescue => e
      begin model.abort_operation if started rescue nil end
      ::UI.messagebox("Redraw failed:\n#{e.class}: #{e.message}")
      0
    ensure
      begin model.commit_operation if started rescue nil end
    end

    def redraw_selected
      inst = selection_instances
      if inst.empty?
        ::UI.messagebox(tr(:pick))
        return
      end
      redraw_batch(inst, tr(:name))
    end

    # ---------- Команды / интеграция ----------
    unless file_loaded?(__FILE__)
      # Подключаем подписчика на события из окна материалов (без кнопок)
      begin
        Sketchup.require(File.join(__dir__, 'mat_redraw'))
      rescue => e
        puts "[ARRedraw] mat_redraw load error: #{e.class}: #{e.message}"
      end

      # Обычная команда Redraw (как была)
      @cmd_generic = ::UI::Command.new(tr(:name)) { ARAddons::ARRedraw.redraw_selected }
      begin
        icon = ARAddons::Utils.shared_icon('redraw.png')
        if File.exist?(icon)
          @cmd_generic.small_icon = icon
          @cmd_generic.large_icon = icon
        end
      rescue
      end
      @cmd_generic.tooltip         = tr(:name)
      @cmd_generic.status_bar_text = tr(:desc)
      @cmd_generic.menu_text       = tr(:name)

      ARAddons::Registry.root_menu.add_item(@cmd_generic)
      ARAddons::Registry.toolbar.add_item(@cmd_generic)

      ::UI.start_timer(0.2, false) { ARAddons::ARRedraw.refresh_command_labels! }

      file_loaded(__FILE__)
      log 'loaded'
    end
  end
end
