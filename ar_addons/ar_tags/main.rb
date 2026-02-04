# encoding: UTF-8
# Plugins/ar_addons/ar_tags/main
# Copyright (c) 2025 Artiom Gurduz
# SPDX-License-Identifier: LicenseRef-Proprietary
# Ownership remains with the author. Internal use by ART ROCKET is permitted.

require 'sketchup'
require 'json'

module ARAddons
  module ARTags

    RES_DIR     = File.join(__dir__, 'resources')
    UI_DIR      = File.join(__dir__, 'ui')
    HTML_TPL    = File.join(UI_DIR, 'tags.html')
    CSS_PATH    = File.join(UI_DIR, 'tags.css')
    JS_PATH     = File.join(UI_DIR, 'tags.js')
    TRANS_JSON  = File.join(RES_DIR, 'translations.json')

    @translations = {}
    @dialog = nil
    @layers_observer_attached = false
    @layers_observer = nil
    @cmd = nil

    # -------- локализация названия/описания команды (EN/RO/RU) --------
    T = {
      en: {
        name: 'Tags',
        desc: 'Quick control of tag section visibility. Click the “eye” to hide/show; each section has “hide all”.'
      },
      ro: {
        name: 'Etichete',
        desc: 'Control rapid al vizibilității secțiunilor de etichete. Clic pe „ochi” pentru a ascunde/afișa; fiecare secțiune are „ascunde tot”.'
      },
      ru: {
        name: 'Теги',
        desc: 'Быстрое управление видимостью разделов тегов. Клик по «глазу» прячет/показывает, у разделов есть «скрыть все».'
      }
    }.freeze

    # активный язык из ar_startup (fallback: :ru)
    def self.current_lang_sym
      base =
        if defined?(::ARAddons) && defined?(::ARAddons::ARStartup) && defined?(::ARAddons::ARStartup::Reader)
          ::ARAddons::ARStartup::Reader.active_lang_base rescue nil
        end
      case (base || 'ru').to_s.downcase
      when 'ro' then :ro
      when 'en' then :en
      else :ru
      end
    end

    def self.cmd_name ; (T[current_lang_sym] || T[:en])[:name] ; end
    def self.cmd_desc ; (T[current_lang_sym] || T[:en])[:desc] ; end

    # публичное обновление подписей команды (можно вызывать из ar_startup после смены языка)
    def self.refresh_command_labels!
      return unless @cmd
      @cmd.tooltip         = cmd_name
      @cmd.status_bar_text = cmd_desc
      @cmd.menu_text       = cmd_name
    rescue
    end

    # -------- набор/порядок тегов --------
    CATEGORIES = {
      'Компоненты' => ['1_Фасад','4_Столешница', '2_Освещение','3_Декор'],
      'Спецификация' => [
        ['0_Данные_Размеры', '4_Данные_Наполнение'],
        ['1_Фасад_открывание', '2_Данные_Фасад'],
        ['3_Данные_Корпус'],
        ['5_Данные_Детали'],
        ['0_Ценовое предложение']
      ]
    }

    # -------- переводы для контента окна --------
    def self.load_translations
      unless File.exist?(TRANS_JSON)
        puts "[ARTags] translations not found: #{TRANS_JSON}"
        @translations = {}
        return
      end
      @translations = JSON.parse(File.read(TRANS_JSON, encoding: 'UTF-8')) rescue {}
    end

    def self.t(original, lang_sym)
      lang = lang_sym.to_s
      (@translations.dig(original, lang) || original)
    end

    # -------- util --------
    def self.all_tag_names
      arr = []
      CATEGORIES.each_value do |list|
        if list.first.is_a?(Array)
          list.each { |sub| arr.concat(sub) }
        else
          arr.concat(list)
        end
      end
      arr.uniq
    end

    # -------- push states to UI --------
    def self.refresh_states
      return unless @dialog && @dialog.visible?
      model = Sketchup.active_model
      return unless model
      states = all_tag_names.map do |name|
        lay = model.layers[name]
        next nil unless lay
        { name: name, visible: !!lay.visible? }
      end.compact
      begin
        @dialog.execute_script("window.__applyTagStates && window.__applyTagStates(#{JSON.generate(states)})")
      rescue => e
        puts "[ARTags] refresh_states error: #{e.message}"
      end
    end

    # -------- observer (layers) --------
    class LayersObserver < ::Sketchup::LayersObserver
      def onLayerChanged(layers, layer)
        ::ARAddons::ARTags.refresh_states
      rescue => e
        puts "[ARTags] onLayerChanged: #{e.message}"
      end
      def onLayerAdded(layers, layer)
        ::ARAddons::ARTags.refresh_states
      rescue; end
      def onLayerRemoved(layers, layer)
        ::ARAddons::ARTags.refresh_states
      rescue; end
    end

    def self.ensure_layers_observer
      return if @layers_observer_attached
      model = Sketchup.active_model
      return unless model
      begin
        @layers_observer ||= LayersObserver.new
        model.layers.add_observer(@layers_observer)
        @layers_observer_attached = true
      rescue => e
        puts "[ARTags] cannot attach observer: #{e.message}"
      end
    end

    # -------- UI --------
    def self.show_dialog
      load_translations if @translations.empty?
      lang = current_lang_sym

      # Заголовок только для рамки окна ОС
      title = t('AR-TAGS 2.0', lang)
      @dialog ||= UI::HtmlDialog.new(
        dialog_title: title,
        preferences_key: 'ar_addons/artags',
        resizable: false,
        width: 160,
        height: 550
      )

      # callbacks
      @dialog.add_action_callback('toggle_tag') do |_d, json|
        data = JSON.parse(json) rescue {}
        if data['tag']
          set_tag_visibility(data['tag'], !!data['visible'])
          refresh_states
        end
      end
      @dialog.add_action_callback('get_states') { |_d, _| refresh_states }
      @dialog.add_action_callback('ready')      { |_d, _| refresh_states }

      # HTML + ресурсы
      html = File.read(HTML_TPL, encoding: 'UTF-8')

      css_url  = ARAddons::Utils.file_url(CSS_PATH)
      js_url   = ARAddons::Utils.file_url(JS_PATH)
      logo_png = ARAddons::Utils.shared_icon('logo_v2.png')
      logo_url = ARAddons::Utils.file_url(logo_png)

      hide_all_txt    = t('Скрыть все', lang)
      categories_html = build_categories_html(lang, hide_all_txt)

      html.sub!('{{css_url}}',         css_url)
      html.sub!('{{js_url}}',          js_url)
      html.sub!('{{logo_url}}',        logo_url)
      html.sub!('{{categories_html}}', categories_html)

      @dialog.set_html(html)

      ensure_layers_observer
      @dialog.show
    end

    def self.build_categories_html(lang, hide_all_txt)
      mdl = Sketchup.active_model
      layers = mdl.layers

      CATEGORIES.map do |cat_name, list|
        cat_title = t(cat_name, lang)
        cat_id = cat_title.downcase.gsub(/\s+/, '_')

        if list.first.is_a?(Array)
          sub_html = list.map do |sub|
            subset = sub.map { |n| layers[n] }.compact
            subset.select! { |l| !t(l.name, lang).nil? }
            next if subset.empty?
            items = subset.map { |l| tag_row_html(l, lang, cat_id) }.join("\n")
            %Q(<div class="subgroup-block">\n#{items}\n</div>)
          end.compact.join("\n")

          %Q(
<h4 id="#{cat_id}">
  <span class="h4-title">#{cat_title}</span>
  <button class="hide-all-btn" title="#{hide_all_txt}" data-category="#{cat_id}"></button>
</h4>
#{sub_html})
        else
          subset = list.map { |n| layers[n] }.compact
          subset.select! { |l| !t(l.name, lang).nil? }
          next if subset.empty?
          items = subset.map { |l| tag_row_html(l, lang, cat_id) }.join("\n")
          %Q(
<h4 id="#{cat_id}">
  <span class="h4-title">#{cat_title}</span>
  <button class="hide-all-btn" title="#{hide_all_txt}" data-category="#{cat_id}"></button>
</h4>
#{items})
        end
      end.compact.join("\n\n")
    end

    # «Название - Подзаголовок» -> две строки, с левой вертикальной линией
    def self.tag_row_html(layer, lang, cat_id)
      nm = t(layer.name, lang)
      head, tail = nm.split(' - ', 2)
      head ||= nm
      tail ||= ''
      cls = layer.visible? ? 'visible' : 'hidden'
      %Q(
<div class="tag-item">
  <span class="eye-icon #{cls}" data-category="#{cat_id}" data-tag="#{layer.name}"></span>
  <span class="tag-text">
    <span class="tag-title #{cls}">#{head}</span>
    #{ tail.empty? ? '' : %Q(<span class="tag-subtitle #{cls}">#{tail}</span>) }
  </span>
</div>)
    end

    def self.set_tag_visibility(tag_name, visible)
      mdl = Sketchup.active_model
      layer = mdl.layers[tag_name]
      return unless layer
      layer.visible = visible ? true : false
      mdl.active_view.refresh
    end

    # -------- команда / единая панель --------
    unless file_loaded?(__FILE__)
      @cmd = UI::Command.new(cmd_name) { self.show_dialog }

      # общая иконка инструмента
      shared = ARAddons::Utils.shared_icon('tags.png')
      begin
        if File.exist?(shared)
          @cmd.small_icon = shared
          @cmd.large_icon = shared
        end
      rescue
      end

      @cmd.tooltip         = cmd_name         # верхняя строка тултипа
      @cmd.status_bar_text = cmd_desc         # нижняя строка (описание)
      @cmd.menu_text       = cmd_name

      ARAddons::Registry.root_menu.add_item(@cmd)
      ARAddons::Registry.toolbar.add_item(@cmd)

      # одноразовое обновление подписей после загрузки ar_startup
      UI.start_timer(0.2, false) { ARAddons::ARTags.refresh_command_labels! }

      file_loaded(__FILE__)
    end

  end
end
