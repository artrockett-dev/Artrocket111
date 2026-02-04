# encoding: UTF-8
# Plugins/ar_addons/ar_library/core
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'
require 'json'
require 'fileutils'
require 'tmpdir'
require 'digest'
begin
  # Подключаем один раз; если библиотеки нет — работаем без нормализации
  require 'unicode_normalize'
rescue LoadError
end

# Визуальный HUD (неинтерактивный) — рисует PNG со стрелками
Sketchup.require(File.join(__dir__, 'hud'))

module ARLIB
  PLUGIN_NAME     = 'LIBRARY 1.1'.freeze
  PREFERENCES_KEY = 'com.sketchup.ARLIB'.freeze

  HTML_FOLDER  = File.join(File.dirname(__FILE__), 'html').freeze
  ICONS_FOLDER = File.join(File.dirname(__FILE__), 'icons').freeze

  # ---------- ЕДИНЫЙ переключатель логов ----------
  DEBUG = false # вкл/выкл логи
  def self.log(msg)
    puts "[ARLIB] #{msg}" if DEBUG
  end

  # флаг опционального «снепшотного» рендера, если PNG не удалось достать
  USE_SNAPSHOT_FALLBACK = false

  # ---------- состояние окна диалога и «последней» замены / редроу ----------
  @dialog_active         = false
  @library_dialog        = nil
  @open_guard            = false   # защита от реентера при создании окна

  @last_replaced_pid     = nil            # последний pid, который надо редроу-нуть
  @last_replaced_mono    = 0.0            # время (mono) записи последнего pid

  # антидубликат: чем и когда последний раз реально редроу-нули
  @last_redraw_pid       = nil
  @last_redraw_mono      = 0.0

  REDRAW_DEBOUNCE_S      = 0.25           # защита от повторного redraw одного и того же pid
  REDRAW_KICK_DELAY_S    = 0.30           # отложенный запуск при неактивном окне
  REDRAW_INACTIVE_GRACE  = 0.12           # пауза после перехода в INACTIVE (пусть стабилизируется модель)

  def self.dialog_active?
    @dialog_active && (@library_dialog && @library_dialog.visible? rescue true)
  end

  def self.mark_dialog_active(flag, source = nil)
    prev = @dialog_active
    @dialog_active = !!flag
    # Лог только на переход
    if prev != @dialog_active
      ARLIB.log "dlg_focus <- #{flag ? 'ACTIVE' : 'INACTIVE'}#{source ? " (#{source})" : ''}"
    end

    # Включаем/выключаем HUD внизу
    begin
      ARLIB::HUD.on_dialog_focus(@dialog_active)
    rescue => e
      ARLIB.log "HUD focus hook error: #{e.class}: #{e.message}"
    end

    # Как только окно стало INACTIVE — пробуем выполнить общий, единичный redraw по последнему pid
    unless @dialog_active
      UI.start_timer(REDRAW_INACTIVE_GRACE, false) { attempt_redraw_last('dlg_inactive') }
    end
  end

  def self.library_dialog
    @library_dialog
  end

  # --- Кооперативный guard для программных правок выделения ---
  @__sel_guard = 0
  def self.with_sel_guard; @__sel_guard += 1; yield; ensure @__sel_guard -= 1; end
  def self.sel_guard?; @__sel_guard > 0; end

  # Выделение без очистки (и без спама событий во время операций), отложенно в UI-тик
  def self.defer_select(entity, delay: 0.0)
    return unless entity && entity.valid?
    UI.start_timer(delay, false) do
      begin
        mdl = Sketchup.active_model
        sel = mdl.selection
        # Ничего не делаем, если уже выделен
        if sel.respond_to?(:contains?) && sel.contains?(entity)
          # просто выходим из таймера
        else
          ARLIB.with_sel_guard do
            sel.add(entity)  # ВАЖНО: без sel.clear — дружественно к чужим SelectionObserver
          end
        end
      rescue => e
        ARLIB.log "defer_select error: #{e.class}: #{e.message}"
      end
    end
  end

  # --- Поиск инстанса по PID ---
  def self.find_entity_by_pid(pid)
    mdl = Sketchup.active_model
    return nil unless pid && mdl && mdl.respond_to?(:find_entity_by_persistent_id)
    mdl.find_entity_by_persistent_id(pid) rescue nil
  end

  # --- Универсальный redraw одного инстанса (одна операция, один вызов) ---
  def self.redraw_component(inst)
    return false unless inst && inst.valid?

    used = :none
    ok   = false
    mdl  = Sketchup.active_model

    mdl.start_operation('ARLIB: Redraw (coalesced)', true, false, true)
    begin
      # 1) DC API через ARRedraw (если доступен)
      begin
        if defined?(::ARAddons) && defined?(::ARAddons::ARRedraw) && ::ARAddons::ARRedraw.respond_to?(:dc_iface)
          dc = (::ARAddons::ARRedraw.dc_iface rescue nil)
          if dc && dc.respond_to?(:redraw_with_undo)
            begin
              dc.redraw_with_undo(inst)
              used = :dc_api
              ok   = true
              ARLIB.log "redraw_component: DC API ok (pid=#{inst.persistent_id rescue 'n/a'})"
            rescue => e
              used = :dc_api_failed
              ARLIB.log "redraw_component: DC API failed: #{e.class}: #{e.message}"
            end
          end
        end
      rescue => e
        ARLIB.log "redraw_component: dc_iface error: #{e.class}: #{e.message}"
      end

      # 2) Фолбэк — «шевельнуть» динамические атрибуты
      unless ok
        begin
          if defined?(::ARAddons) && defined?(::ARAddons::ARRedraw) && ::ARAddons::ARRedraw.respond_to?(:nudge_dynamic_attrs!)
            ::ARAddons::ARRedraw.nudge_dynamic_attrs!(inst)
            used = :nudge
            ok   = true
            ARLIB.log "redraw_component: nudged via ARRedraw (pid=#{inst.persistent_id rescue 'n/a'})"
          else
            inst.set_attribute('dynamic_attributes', '_arlib_refresh', (Time.now.to_f * 1000).to_i) rescue nil
            used = :attr_touch
            ok   = true
            ARLIB.log "redraw_component: attr_touch fallback (pid=#{inst.persistent_id rescue 'n/a'})"
          end
        rescue => e
          ARLIB.log "redraw_component: fallback error: #{e.class}: #{e.message}"
        end
      end

      mdl.active_view.invalidate rescue nil
    ensure
      mdl.commit_operation
    end

    ARLIB.log "redraw_component: used=#{used}, ok=#{ok}"
    ok
  end

  # --- Планирование общего redraw ТОЛЬКО по последнему PID ---
  def self.schedule_last_redraw(pid, reason: 'replace_component')
    return unless pid
    @last_replaced_pid  = pid
    @last_replaced_mono = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    ARLIB.log "schedule_last_redraw: pid=#{pid}, reason=#{reason}, dialog_active=#{dialog_active?}"

    if !dialog_active?
      # окно уже не активно — небольшая задержка и сразу пробуем
      UI.start_timer(REDRAW_KICK_DELAY_S, false) { attempt_redraw_last('immediate') }
    else
      # окно активно — ждём INACTIVE, никаких таймеров сейчас не плодим
      # (см. mark_dialog_active)
    end
  end

  # --- Попытка общего redraw по «последнему» PID (дебаунс и антидупликат) ---
  def self.attempt_redraw_last(trigger)
    pid = @last_replaced_pid
    if pid.nil?
      ARLIB.log "attempt_redraw_last(#{trigger}): nothing pending"
      return
    end

    # Антидубликат: если уже недавно редроу-нули этот же pid — не повторяем
    now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    if @last_redraw_pid == pid && (now - @last_redraw_mono) < REDRAW_DEBOUNCE_S
      ARLIB.log "attempt_redraw_last(#{trigger}): debounced (pid=#{pid})"
      return
    end

    ent = find_entity_by_pid(pid)
    if ent && ent.valid?
      ARLIB.log "attempt_redraw_last(#{trigger}): found -> redraw (pid=#{pid})"
      ok = redraw_component(ent)
      @last_redraw_pid  = pid if ok
      @last_redraw_mono = now if ok
    else
      ARLIB.log "attempt_redraw_last(#{trigger}): entity not found (pid=#{pid})"
    end

    # одноразовое «задание» — очищаем
    @last_replaced_pid  = nil
    @last_replaced_mono = 0.0
  end

  # ---------- связка с ARAddons/ARStartup (активный язык) ----------
  def self.active_lang_base
    if defined?(::ARAddons) &&
       defined?(::ARAddons::ARStartup) &&
       defined?(::ARAddons::ARStartup::Reader)
      (::ARAddons::ARStartup::Reader.active_lang_base rescue 'ru').to_s
    else
      'ru'
    end
  end

  # ---------- Кодировки / пути ----------
  module Enc
    extend self

    def to_fs(s)
      s = s.to_s
      begin
        s = s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
      rescue
        s = s.to_s.force_encoding('UTF-8')
      end
      begin
        if defined?(UnicodeNormalize) && s.respond_to?(:unicode_normalize)
          s = s.unicode_normalize(:nfc)
        end
      rescue Exception => e
        ARLIB.log "unicode_normalize skipped: #{e.class}: #{e.message}"
      end
      s
    end

    def to_utf8(s)
      s = s.to_s
      s.encoding == Encoding::UTF_8 ? s : s.encode(Encoding::UTF_8, invalid: :replace, undef: :replace)
    end

    def norm_slash_utf8(path)
      to_utf8(path).gsub('\\\\', '/')
    end

    def web_url(path)
      p = norm_slash_utf8(path)
      p.start_with?('file:///') ? p : "file:///#{p}"
    end

    def children_utf8(path)
      Dir.children(path, encoding: Encoding::UTF_8)
    rescue ArgumentError
      Dir.entries(path).reject { |e| e == '.' || e == '..' }.map { |e| to_utf8(e) }
    end

    def glob_utf8(pattern)
      Dir.glob(pattern, encoding: Encoding::UTF_8)
    rescue ArgumentError
      Dir.glob(pattern).map { |e| to_utf8(e) }
    end
  end

  # ---------- Пути ----------
  module Paths
    extend self

    def components_support_dir
      candidates = []
      begin; candidates << Sketchup.find_support_file('Components', ''); rescue; end
      begin
        plugins = Sketchup.find_support_file('Plugins', '')
        if plugins && File.directory?(plugins)
          candidates << File.expand_path('../Components', plugins)
          candidates << File.expand_path('../../SketchUp/Components', plugins)
        end
      rescue
      end
      dir = candidates.compact.find { |p| p && File.directory?(p) }
      dir || raise('ARLIB: Не удалось обнаружить папку SketchUp/Components')
    end

    def library_root
      root = File.join(components_support_dir, 'ARLIB')
      FileUtils.mkdir_p(root) unless File.directory?(root)
      root
    end

    def modules_root
      path = File.join(library_root, 'modules')
      FileUtils.mkdir_p(path) unless File.directory?(path)
      path
    end

    def components_root
      path = File.join(library_root, 'components')
      FileUtils.mkdir_p(path) unless File.directory?(path)
      path
    end

    def thumbs_cache_root
      root = File.join(Dir.tmpdir, 'ARLIB', 'thumbs')
      FileUtils.mkdir_p(root) unless File.directory?(root)
      root
    end

    def cached_thumb_path_for(skp_path)
      key = Digest::MD5.hexdigest(File.expand_path(Enc.to_fs(skp_path)))
      File.join(thumbs_cache_root, "#{key}.png")
    end
  end

  # текущая вкладка
  @current_library = :modules
  def self.set_active_library(library)
    case library.to_s
    when 'modules'    then @current_library = :modules
    when 'components' then @current_library = :components
    else                   @current_library = :modules
    end
  end
  def self.current_assets_folder
    @current_library == :components ? Paths.components_root : Paths.modules_root
  end

  # ---------- Просмотр содержимого ----------
  module ContentBrowser
    extend self
    ICONS_FOLDER = ARLIB::ICONS_FOLDER

    def first_component_in_folder(folder_fs)
      Enc.children_utf8(folder_fs).map { |e| File.join(folder_fs, Enc.to_fs(e)) }.find do |p|
        File.file?(p) && File.fnmatch?('*.skp', File.basename(p), File::FNM_CASEFOLD)
      end
    rescue => e
      ARLIB.log "first_component_in_folder error: #{e.class}: #{e.message}"
      nil
    end

    def icon_for_folder(entry_fs)
      shot = File.join(entry_fs, "#{File.basename(entry_fs)}.png")
      return Enc.web_url(shot) if File.exist?(shot)

      if (skp = first_component_in_folder(entry_fs))
        thumb_url = preview_for_component(skp)
        return thumb_url if thumb_url && !thumb_url.to_s.empty?
      end

      Enc.web_url(File.join(ICONS_FOLDER, 'folder_icon.png'))
    end

    # Пробуем несколько способов достать PNG из .skp
    def extract_png_from_skp(skp_fs, out_png)
      data = File.binread(skp_fs) rescue nil
      return false unless data && data.bytesize > 16
      sig  = "\x89PNG\r\n\x1A\n".b
      i    = data.index(sig)
      return false unless i
      tail = "\x00\x00\x00\x00IEND\xAE\x42\x60\x82".b
      j    = data.index(tail, i)
      return false unless j
      jend = j + tail.bytesize
      png  = data[i...jend]
      FileUtils.mkdir_p(File.dirname(out_png)) unless File.directory?(File.dirname(out_png))
      File.binwrite(out_png, png)
      true
    rescue => e
      ARLIB.log "extract_png_from_skp error: #{e.class}: #{e.message}"
      false
    end

    def render_thumb_via_snapshot(skp_fs, cache_png)
      return false unless ARLIB::USE_SNAPSHOT_FALLBACK
      model = Sketchup.active_model
      view  = model.active_view

      cam = view.camera
      cam_state = {
        eye: cam.eye.clone, target: cam.target.clone, up: cam.up.clone,
        persp: cam.perspective?, fov: (cam.perspective? ? cam.fov : 35.0)
      }
      ro = model.rendering_options
      ro_backup = {
        'RenderMode'        => ro['RenderMode'],
        'DisplaySketchAxes' => ro['DisplaySketchAxes'],
        'DisplaySky'        => ro['DisplaySky'],
        'DisplayGround'     => ro['DisplayGround']
      }
      tag_state = {}
      model.tags.each { |t| tag_state[t] = t.visible? }

      ents = model.active_entities
      existing = ents.to_a
      hidden_state = {}
      existing.each { |e| hidden_state[e] = (e.hidden? rescue false); e.hidden = true rescue nil }

      ok = false
      model.start_operation('ARLIB: Generate Thumbnail', true)
      begin
        model.tags.each { |t| t.visible = true rescue nil }

        inst = nil
        begin
          defn = model.definitions.load(skp_fs)
          inst = ents.add_instance(defn, Geom::Transformation.new) if defn
        rescue => e
          ARLIB.log "definitions.load failed: #{e.class}: #{e.message}"
          inst = nil
        end

        if inst.nil?
          before = ents.to_a
          begin
            model.import(skp_fs, false)
          rescue => e
            ARLIB.log "model.import failed: #{e.class}: #{e.message}"
          end
          delta = (ents.to_a - before)
          raise 'import delta empty' if delta.empty?
          inst = ents.add_group(delta)
        end

        ro['RenderMode']        = 3     rescue nil
        ro['DisplaySketchAxes'] = false rescue nil
        ro['DisplaySky']        = false rescue nil
        ro['DisplayGround']     = false rescue nil

        view.zoom(inst.bounds)

        FileUtils.mkdir_p(File.dirname(cache_png)) unless File.directory?(File.dirname(cache_png))
        view.write_image(cache_png, width: 600, height: 400, antialias: true, transparent: false, compression: 0)
        ok = File.exist?(cache_png)
        ARLIB.log "thumb saved (snapshot): #{cache_png}" if ok
      rescue => e
        ARLIB.log "snapshot pipeline error: #{e.class}: #{e.message}"
      ensure
        begin inst.erase! rescue nil end
        hidden_state.each { |e,h| e.hidden = h rescue nil }
        model.tags.each { |t| t.visible = tag_state[t] rescue nil }
        ro_backup.each { |k,v| ro[k] = v rescue nil }
        view.camera = Sketchup::Camera.new(cam_state[:eye], cam_state[:target], cam_state[:up], cam_state[:persp], cam_state[:fov]) rescue nil
        model.abort_operation
      end

      ok
    end

    def preview_for_component(skp_fs)
      custom_png = skp_fs.sub(/\.skp$/i, '.png')
      return Enc.web_url(custom_png) if File.exist?(custom_png)

      cache_png = ARLIB::Paths.cached_thumb_path_for(skp_fs)

      begin
        need = !File.exist?(cache_png) || (File.mtime(cache_png) < File.mtime(skp_fs))
        if need
          ARLIB.log "thumb regen: #{skp_fs}"

          if Sketchup.respond_to?(:save_thumbnail)
            begin
              ok = Sketchup.save_thumbnail(skp_fs, cache_png)
              if ok && File.exist?(cache_png) && File.size?(cache_png)
                ARLIB.log "thumb saved (save_thumbnail): #{cache_png}"
              else
                ARLIB.log 'save_thumbnail returned false/empty'
              end
            rescue => e
              ARLIB.log "save_thumbnail failed: #{e.class}: #{e.message}"
            end
          else
            ARLIB.log 'Sketchup.save_thumbnail not available'
          end

          if !File.exist?(cache_png) && Sketchup.respond_to?(:read_thumbnail)
            begin
              rep = Sketchup::ImageRep.new
              if Sketchup.read_thumbnail(skp_fs, rep) && rep.width.to_i > 0
                FileUtils.mkdir_p(File.dirname(cache_png)) unless File.directory?(File.dirname(cache_png))
                rep.save_file(cache_png)
                ARLIB.log "thumb saved (read_thumbnail): #{cache_png}"
              else
                ARLIB.log 'read_thumbnail: embedded not found'
              end
            rescue => e
              ARLIB.log "read_thumbnail failed: #{e.class}: #{e.message}"
            end
          end

          unless File.exist?(cache_png)
            if extract_png_from_skp(skp_fs, cache_png)
              ARLIB.log "thumb saved (binary extract): #{cache_png}"
            else
              ARLIB.log 'binary extract: not found'
            end
          end

          unless File.exist?(cache_png)
            render_thumb_via_snapshot(skp_fs, cache_png)
          end
        end

        return Enc.web_url(cache_png) if File.exist?(cache_png)
      rescue => e
        ARLIB.log "thumbnail pipeline error: #{e.class}: #{e.message}"
      end

      std = File.join(ICONS_FOLDER, 'skp_file.png')
      Enc.web_url(File.exist?(std) ? std : File.join(ICONS_FOLDER, 'default_component.png'))
    end

    # ---- поиск ----
    def parse_terms(search_query)
      return [] if search_query.nil? || search_query.strip.empty?
      begin
        data = JSON.parse(search_query)
        if data.is_a?(Hash)
          terms = []
          q = data['q'] || data[:q]
          terms << Enc.to_utf8(q).downcase.strip if q
          alts = data['alt_keys'] || data[:alt_keys]
          if alts.is_a?(Array)
            alts.each { |k| terms << Enc.to_utf8(k).downcase.strip }
          end
          return terms.compact.reject(&:empty?).uniq
        end
      rescue
      end
      [Enc.to_utf8(search_query).downcase.strip]
    end

    def match_any?(basename_utf, terms)
      return true if terms.nil? || terms.empty?
      terms.any? { |t| t && !t.empty? && basename_utf.include?(t) }
    end

    def get_folder_contents(folder, search_query = nil)
      root_fs   = ARLIB.current_assets_folder
      folder_fs = Enc.to_fs(folder.nil? || folder.strip.empty? ? root_fs : folder)

      ARLIB.log "scan: #{folder_fs} (root=#{root_fs})"

      items = { folders: [], components: [] }
      unless Dir.exist?(folder_fs)
        ARLIB.log "Папка не найдена: #{folder_fs}"
        return items.merge({ root: Enc.norm_slash_utf8(root_fs), cwd: Enc.norm_slash_utf8(folder_fs) })
      end

      terms = parse_terms(search_query)

      entries =
        if terms.any?
          Enc.glob_utf8(File.join(folder_fs, '**', '*')).select do |e|
            basename_utf = Enc.to_utf8(File.basename(e)).downcase
            match_any?(basename_utf, terms)
          end
        else
          Enc.children_utf8(folder_fs).map { |entry| File.join(folder_fs, Enc.to_fs(entry)) }
        end

      entries.each do |entry_fs|
        if File.directory?(entry_fs)
          items[:folders] << {
            name: Enc.to_utf8(File.basename(entry_fs)),
            path: Enc.norm_slash_utf8(entry_fs),
            icon: icon_for_folder(entry_fs),
            type: 'folder'
          }
        elsif File.fnmatch?('*.skp', File.basename(entry_fs), File::FNM_CASEFOLD)
          items[:components] << {
            name: Enc.to_utf8(File.basename(entry_fs, '.skp')),
            skp:  Enc.norm_slash_utf8(entry_fs),
            png:  preview_for_component(entry_fs),
            type: 'component'
          }
        end
      end

      items.merge({
        root: Enc.norm_slash_utf8(root_fs),
        cwd:  Enc.norm_slash_utf8(folder_fs)
      })
    end

    def save_selected_as_component(folder_path, component_name = '')
      model = Sketchup.active_model
      sel   = model.selection.to_a
      return nil if sel.empty?

      dir  = folder_path.to_s
      FileUtils.mkdir_p(dir)

      base = component_name.to_s.strip
      if base.empty? && sel.length == 1 && sel.first.is_a?(Sketchup::ComponentInstance)
        base = sel.first.definition.name.to_s
      end
      base = 'Component' if base.empty?
      base = base.gsub(/[\\\/:*?"<>|]/, '_').strip  # minimal sanitize

      skp  = File.join(dir, "#{base}.skp")

      # Single component instance: save its definition directly
      if sel.length == 1 && sel.first.is_a?(Sketchup::ComponentInstance)
        defn = sel.first.definition
        ok = defn.save_as(skp)
        Sketchup.save_thumbnail(skp, skp.sub(/\.skp$/i, '.png')) rescue nil if ok && Sketchup.respond_to?(:save_thumbnail)
        return ok ? skp : nil
      end

      # Arbitrary selection -> make a temp component, save, remove temp
      model.start_operation('ARLIB: Save Selected', true)
      begin
        grp  = model.active_entities.add_group(sel)
        comp = grp.to_component
        comp.definition.name = base
        ok = comp.definition.save_as(skp)
        Sketchup.save_thumbnail(skp, skp.sub(/\.skp$/i, '.png')) rescue nil if ok && Sketchup.respond_to?(:save_thumbnail)
        comp.erase!
        ok ? skp : nil
      ensure
        model.commit_operation
      end
    end



  end


  # ---------- Вставка / замена / поворот ----------
  module LibraryOps
    extend self

    unless defined?(VK_LEFT);  VK_LEFT  = 0x25; end
    unless defined?(VK_UP);    VK_UP    = 0x26; end
    unless defined?(VK_RIGHT); VK_RIGHT = 0x27; end
    unless defined?(VK_DOWN);  VK_DOWN  = 0x28; end
    ESC_KEY = 0x1B

    # Allow HtmlDialog to cancel the active tool via Esc
    def self.handle_escape_from_dialog
      t = active_tool
      if t && t.respond_to?(:onCancel)
        begin
          t.onCancel(0, Sketchup.active_model.active_view)
          return
        rescue => e
          ARLIB.log "handle_escape_from_dialog onCancel error: #{e.class}: #{e.message}"
        end
      end
      # Fallback: force-switch to Selection
      Sketchup.send_action('selectTool:')
    end

    @active_tool = nil
    def active_tool; @active_tool; end
    def set_active_tool(tool); @active_tool = tool; end
    def clear_active_tool; @active_tool = nil; end

    def rotate_selection(axis = 'z', dir = 'cw')
      model = Sketchup.active_model
      sel   = model.selection.to_a
      return if sel.empty?

      rotatables = sel.select { |e| e.respond_to?(:transformation) && e.respond_to?(:transform!) }
      return if rotatables.empty?

      bb = Geom::BoundingBox.new
      rotatables.each { |e| bb.add(e.bounds) }
      center = bb.center

      angle = 90.degrees * (dir.to_s == 'ccw' ? -1.0 : 1.0)
      axis_vec =
        case axis.to_s.downcase
        when 'x' then Geom::Vector3d.new(1,0,0)
        when 'y' then Geom::Vector3d.new(0,1,0)
        else           Geom::Vector3d.new(0,0,1)
        end

      tr = Geom::Transformation.rotation(center, axis_vec, angle)

      model.start_operation('ARLIB: Rotate Selection 90°', true)
      begin
        rotatables.each { |e| e.transform!(tr) }
        model.active_view.invalidate
      ensure
        model.commit_operation
      end
    end

    def handle_arrow_key(key)
      t = active_tool
      if t && t.respond_to?(:rotate_from_dialog)
        case key.to_s
        when 'ArrowLeft'  then t.rotate_from_dialog(:z, -90)
        when 'ArrowRight' then t.rotate_from_dialog(:z, +90)
        when 'ArrowUp'    then t.rotate_from_dialog(:x, +90)
        when 'ArrowDown'  then t.rotate_from_dialog(:x, -90)
        end
        return
      end

      case key.to_s
      when 'ArrowLeft'  then rotate_selection('z', 'ccw')
      when 'ArrowRight' then rotate_selection('z', 'cw')
      when 'ArrowUp'    then rotate_selection('x', 'cw')
      when 'ArrowDown'  then rotate_selection('x', 'ccw')
      end
    end

    USE_NATIVE_PLACE = false

    def add_component(component_path)
      unless File.exist?(component_path)
        UI.messagebox("File not found:\n#{component_path}")
        return
      end
      defn = Sketchup.active_model.definitions.load(component_path) rescue nil
      if defn.nil?
        UI.messagebox("Failed to load component:\n#{component_path}")
        return
      end

      if USE_NATIVE_PLACE
        begin
          Sketchup.active_model.place_component(defn)
        rescue
          tool = PlacementTool.new(defn)
          set_active_tool(tool)
          Sketchup.active_model.tools.push_tool(tool)
        end
      else
        tool = PlacementTool.new(defn)
        set_active_tool(tool)
        Sketchup.active_model.tools.push_tool(tool)
      end
    end

    def replace_component(component_path)
      model = Sketchup.active_model
      sel = model.selection
      if sel.empty?
        UI.messagebox('Select a component to replace.')
        return
      end
      inst = sel.first
      unless inst.is_a?(Sketchup::ComponentInstance)
        UI.messagebox('Only components can be replaced.')
        return
      end
      unless File.exist?(component_path)
        UI.messagebox("File not found:\n#{component_path}")
        return
      end

      new_def = model.definitions.load(component_path) rescue nil
      if new_def.nil?
        UI.messagebox('Failed to load new component.')
        return
      end

      old_tr  = inst.transformation
      old_bb  = inst.bounds
      old_ctr = old_bb.center

      model.start_operation('ARLIB: Replace Component', true)
      inst.erase!
      new_inst = model.active_entities.add_instance(new_def, old_tr)
      new_bb   = new_inst.bounds

      sx = new_bb.width  <= 0.0 ? 1.0 : old_bb.width  / new_bb.width
      sy = new_bb.height <= 0.0 ? 1.0 : old_bb.height / new_bb.height
      sz = new_bb.depth  <= 0.0 ? 1.0 : old_bb.depth  / new_bb.depth

      new_inst.transform!(Geom::Transformation.scaling(sx, sy, sz))
      new_inst.transform!(Geom::Transformation.translation(old_ctr - new_inst.bounds.center))

      # PID нового инстанса
      new_pid = (new_inst.persistent_id rescue nil)
      ARLIB.log "replace_component: created new inst pid=#{new_pid.inspect}"

      # Больше НЕ трогаем selection внутри операции — это дружелюбно к чужим observers
      model.commit_operation
      begin model.active_view.invalidate rescue nil end

      # Отложенно выделим новый инстанс (без clear)
      ARLIB.defer_select(new_inst, delay: 0.0)

      # Планируем общий redraw ТОЛЬКО для последнего PID
      if new_pid
        ARLIB.schedule_last_redraw(new_pid, reason: 'replace_component')
      else
        ARLIB.log "replace_component: pid is nil — fallback by live ref"
        UI.start_timer(REDRAW_KICK_DELAY_S, false) do
          begin
            if ARLIB.dialog_active?
              ARLIB.log "timer(redraw/ref): dialog ACTIVE -> wait for INACTIVE (skip)"
            else
              if new_inst && new_inst.valid?
                ARLIB.log "timer(redraw/ref): redraw by live ref"
                ARLIB.redraw_component(new_inst)
              else
                ARLIB.log "timer(redraw/ref): live ref invalid"
              end
            end
          rescue => e
            ARLIB.log "timer(redraw/ref) error: #{e.class}: #{e.message}"
          end
        end
      end
    end

    class PlacementTool
      def initialize(defn)
        @defn    = defn
        @ip      = Sketchup::InputPoint.new
        @angle_z = 0.0
        @angle_x = 0.0
        @ghost   = nil
        @started = false
        @last_pos   = nil
        @last_z     = nil
        @last_x     = nil
        @shown      = false

        @model = Sketchup.active_model
        begin
          @model.start_operation('ARLIB: Place Component', true)
          @started = true
          @ghost = @model.active_entities.add_instance(@defn, IDENTITY)
          @ghost.hidden = true
          begin @ghost.set_attribute('arlib_meta', 'ghost', 1) rescue nil end
        rescue => e
          ARLIB.log "PlacementTool init error: #{e.class}: #{e.message}"
        end
      end

      def rotate_from_dialog(axis, step_deg)
        case axis
        when :z then @angle_z += step_deg.degrees
        when :x then @angle_x += step_deg.degrees
        end
        apply_transform!
      end

      def onMouseMove(_flags, x, y, view)
        hid_tmp = false
        if @ghost && @ghost.valid? && !@ghost.hidden?
          @ghost.hidden = true
          hid_tmp = true
        end

        begin
          @ip.pick(view, x, y)
        ensure
          @ghost.hidden = false if hid_tmp && @shown && @ghost && @ghost.valid?
        end

        apply_transform!
      end

      # OPTION 3: Handle Esc directly in the tool
      def onKeyDown(key, _rpt, _flags, view)
        case key
        when ARLIB::LibraryOps::VK_LEFT  then @angle_z -= 90.degrees
        when ARLIB::LibraryOps::VK_RIGHT then @angle_z += 90.degrees
        when ARLIB::LibraryOps::VK_UP    then @angle_x += 90.degrees
        when ARLIB::LibraryOps::VK_DOWN  then @angle_x -= 90.degrees
        when ARLIB::LibraryOps::ESC_KEY
          # Cancel placement immediately, mirror standard SU behavior
          onCancel(0, view)
          return true # swallow Esc
        else
          return
        end
        apply_transform!
      end

      def onLButtonDown(_flags, _x, _y, _view)
        # Завершаем операцию и ОТЛОЖЕННО выделяем итоговый инстанс (ghost),
        # чтобы внешние SelectionObserver получили onSelectionAdded вне транзакции.
        if @started
          begin @model.commit_operation rescue nil end
          @started = false
        end
        begin
          if @ghost && @ghost.valid?
            @ghost.hidden = false
            ARLIB.defer_select(@ghost, delay: 0.0)
          end
        rescue
        end
        ARLIB::LibraryOps.clear_active_tool
        Sketchup.active_model.tools.pop_tool
      end

      def onCancel(_reason, _view)
        begin @ghost.erase! if @ghost && @ghost.valid? rescue nil end
        if @started
          begin @model.abort_operation rescue nil end
          @started = false
        end
        ARLIB::LibraryOps.clear_active_tool
        Sketchup.active_model.tools.pop_tool
      end

      def deactivate(_view)
        unless @ghost.nil? || !@ghost.valid?
          if @started
            begin @ghost.erase! rescue nil end
            begin @model.abort_operation rescue nil end
            @started = false
          end
        end
        ARLIB::LibraryOps.clear_active_tool
      end

      private

      def apply_transform!
        return unless @ghost && @ghost.valid?
        return unless @ip.valid?
        pos = @ip.position
        return if @last_pos && @last_z && @last_x &&
                  (@last_pos == pos) && (@last_z == @angle_z) && (@last_x == @angle_x)

        rz = Geom::Transformation.rotation(ORIGIN, Z_AXIS, @angle_z)
        rx = Geom::Transformation.rotation(ORIGIN, X_AXIS, @angle_x)
        tr = Geom::Transformation.translation(pos) * rz * rx

        begin
          @ghost.transformation = tr
          @last_pos = pos; @last_z = @angle_z; @last_x = @angle_x
          unless @shown
            @ghost.hidden = false
            @shown = true
          end
          Sketchup.active_model.active_view.invalidate
        rescue => e
          ARLIB.log "apply_transform! error: #{e.class}: #{e.message}"
        end
      end
    end
  end

  # ---------- HtmlDialog Bridge (singleton-safe) ----------
  def self.open_library_dialog
    # 1) Если уже есть видимое окно — поднять и вернуть ссылку
    begin
      if @library_dialog && @library_dialog.respond_to?(:visible?) && @library_dialog.visible?
        @library_dialog.bring_to_front rescue nil
        # Мягкий refresh внутреннего UI по желанию
        @library_dialog.execute_script('window.__arlib_refresh && window.__arlib_refresh()') rescue nil
        return @library_dialog
      end
    rescue => e
      ARLIB.log "visible?/bring_to_front failed: #{e.message}"
    end

    # 2) Анти-реентрантная защита — если уже в процессе создания, отдаём текущее
    return @library_dialog if @open_guard && @library_dialog

    @open_guard = true
    begin
      dialog = UI::HtmlDialog.new(
        dialog_title: PLUGIN_NAME,
        preferences_key: PREFERENCES_KEY,
        scrollable: true, resizable: true,
        width: 1000, height: 800,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      # Сохраняем ссылку и помечаем активность окна
      @library_dialog = dialog
      ARLIB.mark_dialog_active(true, 'open')

      # ВКЛЮЧАЕМ общий мост языка (из ar_startup), если доступен
      begin
        if defined?(::ARAddons) &&
           defined?(::ARAddons::ARStartup) &&
           defined?(::ARAddons::ARStartup::BridgeWiring)
          ::ARAddons::ARStartup::BridgeWiring.wire_dialog!(dialog)
        end
      rescue => e
        ARLIB.log "Bridge wiring error: #{e.class}: #{e.message}"
      end

      dialog.set_file(File.join(HTML_FOLDER, 'library.html'))

      dialog.add_action_callback('arrow_key') do |_d, key|
        ARLIB::LibraryOps.handle_arrow_key(key.to_s)
      end

      # Esc from dialog -> cancel placement / switch to Selection
      dialog.add_action_callback('escape_key') do |_d|
        ARLIB::LibraryOps.handle_escape_from_dialog
      end

      keys_js = <<~JS
        (function(){
          if (window.__arlib_keys_bound) return; window.__arlib_keys_bound = true;
          window.addEventListener('keydown', function(e){
            var k = e.key; if(!/^Arrow(Left|Right|Up|Down)$/.test(k)) return;
            e.preventDefault(); e.stopPropagation();
            try{ window.sketchup && window.sketchup.arrow_key && window.sketchup.arrow_key(k); }catch(_){ }
          }, {capture:true});
        })();
      JS

      # Esc key inside the dialog -> forward to Ruby
      esc_js = <<~JS
        (function(){
          if (window.__arlib_esc_bound) return; window.__arlib_esc_bound = true;
          window.addEventListener('keydown', function(e){
            if (e.key === 'Escape') {
              e.preventDefault(); e.stopPropagation();
              try { window.sketchup && window.sketchup.escape_key && window.sketchup.escape_key(); } catch(_) {}
            }
          }, {capture:true});
        })();
      JS

      # Активность (без спама — только на переход состояния)
      focus_js = <<~JS
        (function(){
          if (window.__arlib_focus_bound) return; window.__arlib_focus_bound = true;
          var __state = null; // true (active) / false (inactive)
          function compute(){
            return (document.visibilityState === 'visible') && document.hasFocus();
          }
          function pingIfChanged(src){
            var now = compute();
            if (__state === now) return;
            __state = now;
            try{ window.sketchup && window.sketchup.dlg_focus && window.sketchup.dlg_focus(now?1:0); }catch(_){ }
            try{ console.debug && console.debug('[ARLIB dlg_focus]', now ? 'ACTIVE' : 'INACTIVE', src||''); }catch(_){ }
          }
          window.addEventListener('focus',  function(){ pingIfChanged('focus');  }, {capture:true});
          window.addEventListener('blur',   function(){ pingIfChanged('blur');   }, {capture:true});
          document.addEventListener('visibilitychange', function(){ pingIfChanged('visibilitychange'); }, {capture:true});
          ['pointerdown','keydown','mousedown'].forEach(function(ev){
            document.addEventListener(ev, function(){ pingIfChanged('input:'+ev); }, {capture:true});
          });
          // первичная инициализация
          __state = !compute(); // чтобы принудительно залогировать первый переход
          pingIfChanged('init');
        })();
      JS

      dialog.add_action_callback('dlg_focus'){ |_d, flag|
        ARLIB.mark_dialog_active(flag.to_i == 1, 'js')
      }

      dialog.add_action_callback('get_folder_contents') do |_d, folder_path, search_query|
        folder_path = (folder_path || '').to_s
        folder_path = current_assets_folder if folder_path.strip.empty?
        contents = ContentBrowser.get_folder_contents(folder_path, (search_query || '').to_s)
        dialog.execute_script("populateFolderContents(#{contents.to_json(ascii_only: false)})")
      end

      dialog.add_action_callback('save_folder_contents') do |_d, folder_path|
        folder_path = (folder_path || '').to_s

        model = Sketchup.active_model
        sel   = model.selection

        default_name =
          if sel.length == 1 && sel.first.is_a?(Sketchup::ComponentInstance)
            sel.first.definition.name.to_s
          else
            'Component'
          end

        input = UI.inputbox(['Component name'], [default_name], 'Save Selected As')
        next unless input

        name = (input[0] || '').strip
        name = default_name if name.empty?

        skp = ContentBrowser.save_selected_as_component(folder_path, name)

        if skp
          # 👉 refresh the UI with the updated folder contents
          contents = ContentBrowser.get_folder_contents(folder_path, nil)
          dialog.execute_script("populateFolderContents(#{contents.to_json(ascii_only: false)})")
        else
          UI.messagebox("Save failed in: #{folder_path}")
          # fix broken string + remove undefined ValidatorPlugin call
          dialog.execute_script("alert('Save failed in: ' + #{folder_path.to_json})")
        end
      end



      dialog.add_action_callback('switch_library') do |_d, library|
        set_active_library(library.to_s)
        contents = ContentBrowser.get_folder_contents(current_assets_folder, nil)
        dialog.execute_script("populateFolderContents(#{contents.to_json(ascii_only: false)})")
      end

      dialog.add_action_callback('load_component')    { |_d, p| LibraryOps.add_component(p.to_s) }
      dialog.add_action_callback('replace_component') { |_d, p| LibraryOps.replace_component(p.to_s) }

      dialog.add_action_callback('rotate_selection') do |_d, axis, dir|
        LibraryOps.rotate_selection(axis.to_s, dir.to_s)
      end

      dialog.show
      UI.start_timer(0.1, false) do
        begin
          dialog.execute_script(keys_js)
          dialog.execute_script(esc_js)
          dialog.execute_script(focus_js)
        rescue => e
          ARLIB.log "inject js error: #{e.class}: #{e.message}"
        end
      end

      dialog.set_on_closed do
        ARLIB.mark_dialog_active(false, 'closed')
        @library_dialog = nil
      end

      # ВАЖНО: вернуть ссылку на HtmlDialog — это критично для верхнего уровня
      dialog
    ensure
      # снимаем защиту чуть позже, чтобы двойной клик не успевал создать второе окно
      UI.start_timer(0.15, false){ @open_guard = false } rescue (@open_guard = false)
    end
  end

  # ---------- Меню / тулбар ----------
  unless file_loaded?(__FILE__)
    if defined?(::ARAddons) && defined?(::ARAddons::Registry)
      # В составе бандла регистрацию (кнопку, порядок, локализацию)
      # делает ar_addons/ar_library/main — здесь ничего не создаём.
      file_loaded(__FILE__)
    else
      # Standalone-режим (вне бандла)
      UI.menu('Plugins').add_item(PLUGIN_NAME) { open_library_dialog }

      cmd = UI::Command.new(PLUGIN_NAME) { open_library_dialog }
      begin
        cmd.small_icon      = File.join(ICONS_FOLDER, 'icon_small.png')
        cmd.large_icon      = File.join(ICONS_FOLDER, 'icon_large.png')
      rescue
      end
      cmd.tooltip         = 'Open ARLIB'
      cmd.status_bar_text = 'Open ARLIB Library'

      tb = UI::Toolbar.new(PLUGIN_NAME)
      tb.add_item(cmd)
      tb.show if tb.get_last_state != TB_HIDDEN

      file_loaded(__FILE__)
    end
  end
end
