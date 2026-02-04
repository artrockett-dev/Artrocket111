# encoding: UTF-8
# Plugins/ar_addons/ar_rebuild/main
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'
require 'tmpdir'
require 'fileutils'

module ARAddons
  module ARRebuild
    DEBUG         = false
    PREFIX        = 'UltraClean Rebuild'.freeze
    RES_DIR       = File.join(__dir__, 'resources')
    UI_DIR        = File.join(__dir__, 'ui')
    TEMPLATE_PATH = File.join(RES_DIR, 'transfer_template.skp')
    LOG_FILE      = File.join(Dir.tmpdir, "ultraclean_rebuild_#{Time.now.to_i}.log")

    PROGRESS_HTML = File.join(UI_DIR, 'progress.html')
    PROGRESS_CSS  = File.join(UI_DIR, 'progress.css')
    PROGRESS_JS   = File.join(UI_DIR, 'progress.js')

    # ---- localization for tool name/description (EN/RO/RU) ----
    T = {
      en: {
        name: 'Rebuild',
        desc: 'Creates a new file from a template and transfers components. Handy for a new design variant or when the model runs slowly.'
      },
      ro: {
        name: 'Reconstrucție',
        desc: 'Creează un fișier nou din șablon și transferă componentele. Util pentru o variantă nouă de design sau când modelul rulează lent.'
      },
      ru: {
        name: 'Пересборка',
        desc: 'Создаёт новый файл из шаблона и переносит компоненты. Удобно для нового варианта дизайна или когда модель медленно работает.'
      }
    }.freeze

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

    # ---------- logging ----------
    def log(line)
      stamp = Time.now.strftime('%H:%M:%S')
      msg   = "#{PREFIX}: #{line}"
      puts msg if DEBUG          # консоль — только при DEBUG
      File.open(LOG_FILE, 'a'){ |f| f.puts("#{stamp}  #{msg}") }
    rescue
    end

    # ---------- маленькое окно прогресса ----------
    class ProgressUI
      def initialize(title = 'Rebuild')
        @dlg = UI::HtmlDialog.new(
          dialog_title: title,
          preferences_key: 'ARAddons/RebuildProgress',
          scrollable: false,
          resizable: false,
          width: 460, height: 130,
          style: UI::HtmlDialog::STYLE_UTILITY
        )

        html = File.read(PROGRESS_HTML, encoding: 'UTF-8')
        css  = ARAddons::Utils.file_url(PROGRESS_CSS)
        js   = ARAddons::Utils.file_url(PROGRESS_JS)

        logo = ARAddons::Utils.shared_icon('logo_v2.png')
        logo_url = ARAddons::Utils.file_url(logo)

        html.sub!('{{css_url}}',  css)
        html.sub!('{{js_url}}',   js)
        html.sub!('{{logo_url}}', logo_url)

        @dlg.set_html(html)
      end

      def show ; @dlg.show rescue nil ; end
      def close; @dlg.close rescue nil ; end

      def set(pct, label=nil)
        ARAddons::ARRebuild.log("Progress #{pct.to_i}% — #{label}") if label
        safe_label = label ? label.gsub('"','\"') : nil
        @dlg.execute_script(%(window.setProgress(#{pct.to_i}, #{safe_label ? '"' + safe_label + '"' : 'null'});)) rescue nil
      end
    end

    # ---------- helpers ----------
    def mm_units!(model)
      opts = model.options['UnitsOptions'] rescue nil
      return unless opts
      opts['LengthUnit']=2; opts['LengthFormat']=0; opts['LengthPrecision']=3
      log 'Units set: Millimeters.'
    rescue => e
      log "Units set error: #{e.class} – #{e.message}"
    end

    def capture_axes(model)
      ax = model.axes
      ax ? { origin: ax.origin, xaxis: ax.xaxis, yaxis: ax.yaxis } : nil
    rescue
      nil
    end

    def apply_axes!(model, data)
      return unless data
      ax = model.axes; return unless ax
      if ax.method(:set).arity.abs == 4
        z = (data[:xaxis] * data[:yaxis]) rescue Geom::Vector3d.new(0,0,1)
        ax.set(data[:origin], data[:xaxis], data[:yaxis], z)
      else
        ax.set(data[:origin], data[:xaxis], data[:yaxis])
      end
    rescue => e
      log "Axes apply error: #{e.class} – #{e.message}"
    end

    def export_all_to_temp(model)
      sel = model.selection; sel.clear; model.entities.each{|e| sel.add(e)}
      if sel.empty?
        UI.messagebox("#{PREFIX}: Source is empty — nothing to transfer.")
        log 'Export: selection empty'
        return nil
      end
      path = File.join(Dir.tmpdir, "ultraclean_rebuild_#{Time.now.to_i}.skp")
      model.start_operation('UltraClean TMP Export', true, false, true)
      begin
        grp = model.entities.add_group(sel.to_a)
        inst= grp.to_component
        defn= inst.definition
        tr  = inst.transformation
        ok  = defn.save_as(path); raise "Definition.save_as failed" unless ok
        { path: path, transform: tr }
      ensure
        model.abort_operation
      end
    rescue => e
      UI.messagebox("#{PREFIX}: Export error\n#{e.class}: #{e.message}")
      log "Export error: #{e.class} – #{e.message}\n#{e.backtrace.first(6).join("\n")}"
      nil
    end

    def import_and_explode!(model, temp_info)
      defn = model.definitions.load(temp_info[:path]); raise "definitions.load failed" unless defn
      inst = model.entities.add_instance(defn, temp_info[:transform])
      inst.explode rescue nil
      true
    rescue => e
      UI.messagebox("#{PREFIX}: Import error\n#{e.class}: #{e.message}")
      log "Import error: #{e.class} – #{e.message}\n#{e.backtrace.first(6).join("\n")}"
      false
    ensure
      begin; FileUtils.rm_f(temp_info[:path]) if temp_info && temp_info[:path]; rescue; end
    end

    # ---------- подготовка целевого файла ----------
    def copy_template_to_src_dir(src_model)
      src_path = src_model.path.to_s
      base_dir = if !src_path.empty? && File.directory?(File.dirname(src_path))
                   File.dirname(src_path)
                 else
                   Dir.home
                 end
      oldname  = File.basename(src_path, '.*'); oldname = 'Untitled' if oldname.to_s.empty?
      dst_name = "#{oldname} REBUILD.skp"
      dst_path = File.join(base_dir, dst_name)

      if File.exist?(TEMPLATE_PATH)
        FileUtils.cp(TEMPLATE_PATH, dst_path)
        log "Template copied to: #{dst_path}"
        dst_path
      else
        log 'Template file not found; will use newDocument.'
        nil
      end
    rescue => e
      log "copy_template_to_src_dir error: #{e.class} – #{e.message}"
      nil
    end

    def open_destination_model(src_model)
      target = copy_template_to_src_dir(src_model)
      if target && File.exist?(target)
        path = target.tr('\\','/')
        log "Open destination: #{path}"
        begin
          if Sketchup.method(:open_file).parameters.any?{|a| a.include?(:with_status)}
            Sketchup.open_file(path, with_status: true)
          else
            Sketchup.open_file(path)
          end
        rescue
          Sketchup.send_action("open:#{path}")
        end
        path
      else
        log 'newDocument (no local template)'
        Sketchup.send_action('newDocument:')
        nil
      end
    end

    # ---------- основной сценарий ----------
    @pending = nil
    @poll_timer_id = nil
    @proceeded = false

    class RebuildObserver < Sketchup::AppObserver
      def onNewModel(m)      ; ARAddons::ARRebuild.observer_continue(m) ; end
      def onOpenModel(m)     ; ARAddons::ARRebuild.observer_continue(m) ; end
      def onActivateModel(m) ; ARAddons::ARRebuild.observer_continue(m) ; end
    end

    def rebuild_start
      log "LOG → #{LOG_FILE}"
      ui = ProgressUI.new('Rebuild'); ui.show; ui.set(0,'Initializing…')

      src = Sketchup.active_model
      unless src && src.valid?
        UI.messagebox("#{PREFIX}: Source model is not available."); ui.close; return
      end

      ui.set(10,'Capturing axes…')
      axes = capture_axes(src)

      ui.set(15,'Preparing temp file…')
      temp = export_all_to_temp(src)
      unless temp
        ui.set(100,"Export failed.\nLog: #{LOG_FILE}"); UI.start_timer(0.6,false){ui.close}; return
      end
      log "Temp saved: #{temp[:path]}"

      ui.set(20,'Opening destination model…')
      target_path = open_destination_model(src)

      @pending = {
        ui: ui, axes: axes, temp: temp,
        observer: RebuildObserver.new,
        target_path: (target_path ? target_path.tr('\\','/') : nil),
        src_dir: (File.directory?(File.dirname(src.path.to_s)) ? File.dirname(src.path.to_s) : Dir.home)
      }
      @proceeded = false
      Sketchup.add_observer(@pending[:observer])
      start_poll_activation!
    rescue => e
      ui.close rescue nil
      UI.messagebox("#{PREFIX}: Start error\n#{e.class}: #{e.message}")
      log "Start error: #{e.class} – #{e.message}\n#{e.backtrace.first(8).join("\n")}"
      cleanup
    end
    module_function :rebuild_start

    def start_poll_activation!
      return unless @pending
      tries = 0
      @poll_timer_id = UI.start_timer(0.3, true) do
        tries += 1
        dst = Sketchup.active_model
        ok = !!dst
        ok &&= (!@pending[:target_path] || dst.path.to_s.tr('\\','/') == @pending[:target_path])
        log "POLL ##{tries}: path=#{dst&.path} ok=#{ok}"
        if ok
          UI.stop_timer(@poll_timer_id) rescue nil
          proceed_in(dst)
        elsif tries >= 70
          UI.stop_timer(@poll_timer_id) rescue nil
          log "POLL TIMEOUT — proceeding anyway"
          proceed_in(dst || Sketchup.active_model)
        end
      end
    end
    module_function :start_poll_activation!

    def observer_continue(_model)
      proceed_in(Sketchup.active_model)
    end
    module_function :observer_continue

    def proceed_in(dst)
      return unless @pending
      return if @proceeded
      @proceeded = true

      ui = @pending[:ui]
      begin
        Sketchup.remove_observer(@pending[:observer]) rescue nil

        ui.set(30,'Units (mm)…')
        mm_units!(dst)

        ui.set(40,'Importing content…')
        ok = import_and_explode!(dst, @pending[:temp])
        unless ok
          ui.set(100,"Import failed.\nLog: #{LOG_FILE}")
          UI.start_timer(0.8,false){ ui.close }; cleanup; return
        end

        ui.set(70,'Axes…')
        apply_axes!(dst, @pending[:axes])

        ui.set(90,'Saving…')
        begin
          if @pending[:target_path]
            dst.save
          else
            suggested = File.join(@pending[:src_dir], 'Rebuilt.skp')
            path = UI.savepanel('Save rebuilt model', @pending[:src_dir], File.basename(suggested))
            dst.save if path && dst.save_as(path)
          end
        rescue => e
          log "Save error: #{e.class} – #{e.message}"
        end

        ui.set(100,"Done.\nLog: #{LOG_FILE}")
        UI.start_timer(0.6,false){ ui.close }
        cleanup
      rescue => e
        ui.set(100,"Error: #{e.class}. See log: #{LOG_FILE}")
        UI.start_timer(0.8,false){ ui.close }
        log "Proceed error: #{e.class} – #{e.message}\n#{e.backtrace.first(8).join("\n")}"
        cleanup
      end
    end
    module_function :proceed_in

    def cleanup
      if @pending && @pending[:observer]
        Sketchup.remove_observer(@pending[:observer]) rescue nil
      end
      UI.stop_timer(@poll_timer_id) rescue nil
      begin
        if @pending && @pending[:temp] && File.exist?(@pending[:temp][:path])
          FileUtils.rm_f(@pending[:temp][:path])
        end
      rescue
      end
      log "LOG saved → #{LOG_FILE}"
      @pending=nil
      @poll_timer_id=nil
      @proceeded=false
    end
    module_function :cleanup

    # ---------- команда / единая панель ----------
    unless file_loaded?(__FILE__)
      # cmd = UI::Command.new(tr(:name)) { ARAddons::ARRebuild.rebuild_start }

      # # общая иконка для панели
      # icon = ARAddons::Utils.shared_icon('rebuild.png')
      # begin
      #   cmd.small_icon = icon if File.exist?(icon)
      #   cmd.large_icon = icon if File.exist?(icon)
      # rescue
      # end

      # cmd.tooltip         = tr(:name)  # ВЕРХНЯЯ строка
      # cmd.status_bar_text = tr(:desc)  # НИЖНЯЯ строка (описание)
      # cmd.menu_text       = tr(:name)

      # ARAddons::Registry.root_menu.add_item(cmd)
      # ARAddons::Registry.toolbar.add_item(cmd)

      # file_loaded(__FILE__)
      # ARAddons::ARRebuild.log "v19.0 loaded. Log → #{LOG_FILE}"
    end
  end
end
