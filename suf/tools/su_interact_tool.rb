# encoding: UTF-8

module SU_Furniture

  # =========================
  # Платформа/пути (шымы как в рабочем окружении)
  # =========================
  unless const_defined?(:IS_WIN)
    IS_WIN = (defined?(Sketchup) && Sketchup.platform == :platform_win)
  end
  unless const_defined?(:OSX)
    OSX = (defined?(Sketchup) && Sketchup.platform == :platform_osx)
  end
  unless const_defined?(:PATH)
    PATH = File.expand_path(File.dirname(__FILE__))
  end

  # Безопасные обёртки для observer’ов (не меняют логику, лишь защищают от nil)
  def self.safe_remove_observer(obj, observer)
    return unless obj && observer
    obj.remove_observer(observer) if obj.respond_to?(:remove_observer)
  end
  def self.safe_add_observer(obj, observer)
    return unless obj && observer
    obj.add_observer(observer) if obj.respond_to?(:add_observer)
  end

  # =========================
  # Язык и шрифты
  # =========================
  unless const_defined?(:LANG)
    # :ru, :en, :ro
    LANG = :ru
  end

  unless const_defined?(:UI_FONTS)
    UI_FONTS = {
      ru: 'Arial',   # кириллица
      en: 'Verdana', # латиница
      ro: 'Verdana'
    }
  end

  def self.current_font
    UI_FONTS[LANG] || 'Verdana'
  end

  # =========================
  # HUD/статусбар строки
  # =========================
  unless const_defined?(:STRINGS)
    STRINGS = {
      ru: {
        hold_shift:        "Удерживайте Shift для первоначального значения",
        layer_enabled:     "Включен слой: ",
        open_percent_lbl:  "Процент открывания (от 10 до 175)",
      },
      en: {
        hold_shift:        "Hold Shift to reset to initial value",
        layer_enabled:     "Layer enabled: ",
        open_percent_lbl:  "Opening percentage (10 to 175)",
      },
      ro: {
        hold_shift:        "Țineți apăsat Shift pentru valoarea inițială",
        layer_enabled:     "Stratul activ: ",
        open_percent_lbl:  "Procent de deschidere (de la 10 la 175)",
      }
    }
  end

  def self.t(key)
    lang = LANG
    (STRINGS[lang] && STRINGS[lang][key]) ||
      (STRINGS[:en] && STRINGS[:en][key]) ||
      key.to_s
  end

  # =========================
  # SUF_STRINGS: клики/тултипы/диалоги
  # =========================
  unless const_defined?(:SUF_STRINGS_RU)
    SUF_STRINGS_RU = {
      "Open"                            => "Открыть",
      "Handle position"                 => "Позиция ручки",
      "Opening direction"               => "Направление открывания",
      "Showcase/grilles"                => "Витрина/решётки",
      "Reduce the length of the handle" => "Уменьшить длину ручки",
      "Turn the handle"                 => "Повернуть ручку",
      "Increase the length of the handle"=>"Увеличить длину ручки",
      "Panel cutout"                    => "Вырез панели",
      "Texture direction"               => "Направление текстуры",
      "Edge length 1"                   => "Длина кромки 1",
      "Edge length 2"                   => "Длина кромки 2",
      "Edge width 1"                    => "Ширина кромки 1",
      "Edge width 2"                    => "Ширина кромки 2",
      "Click to activate."              => "Щёлкните для активации.",
      "No click behaviors."             => "Нет доступных действий.",
      "Layer enabled"                   => "Включен слой",
      "The width of the material is less than the width of the panel." =>
        "Ширина материала меньше ширины панели.",
      "Change the direction of the texture and reduce the size?" =>
        "Изменить направление текстуры и уменьшить размер?"
    }
  end

  unless const_defined?(:SUF_STRINGS_EN)
    SUF_STRINGS_EN = {
      "Open"                            => "Open",
      "Handle position"                 => "Handle position",
      "Opening direction"               => "Opening direction",
      "Showcase/grilles"                => "Showcase / Grilles",
      "Reduce the length of the handle" => "Shorten handle",
      "Turn the handle"                 => "Rotate handle",
      "Increase the length of the handle"=>"Lengthen handle",
      "Panel cutout"                    => "Panel cutout",
      "Texture direction"               => "Texture direction",
      "Edge length 1"                   => "Edge length 1",
      "Edge length 2"                   => "Edge length 2",
      "Edge width 1"                    => "Edge width 1",
      "Edge width 2"                    => "Edge width 2",
      "Click to activate."              => "Click to activate.",
      "No click behaviors."             => "No clickable actions.",
      "Layer enabled"                   => "Layer enabled",
      "The width of the material is less than the width of the panel." =>
        "Material width is less than panel width.",
      "Change the direction of the texture and reduce the size?" =>
        "Change texture direction and reduce size?"
    }
  end

  unless const_defined?(:SUF_STRINGS_RO)
    SUF_STRINGS_RO = {
      "Open"                            => "Deschide",
      "Handle position"                 => "Poziția mânerului",
      "Opening direction"               => "Direcția de deschidere",
      "Showcase/grilles"                => "Vitrină / grile",
      "Reduce the length of the handle" => "Scurtează mânerul",
      "Turn the handle"                 => "Rotește mânerul",
      "Increase the length of the handle"=>"Lungește mânerul",
      "Panel cutout"                    => "Decupaj panou",
      "Texture direction"               => "Direcția texturii",
      "Edge length 1"                   => "Lungime cant 1",
      "Edge length 2"                   => "Lungime cant 2",
      "Edge width 1"                    => "Lățime cant 1",
      "Edge width 2"                    => "Lățime cant 2",
      "Click to activate."              => "Click pentru activare.",
      "No click behaviors."             => "Nicio acțiune disponibilă.",
      "Layer enabled"                   => "Strat activ",
      "The width of the material is less than the width of the panel." =>
        "Lățimea materialului este mai mică decât lățimea panoului.",
      "Change the direction of the texture and reduce the size?" =>
        "Schimbați direcția texturii și micșorați dimensiunea?"
    }
  end

  unless const_defined?(:SUF_STRINGS)
    case LANG
    when :ru
      SUF_STRINGS = SUF_STRINGS_RU.dup
    when :ro
      SUF_STRINGS = SUF_STRINGS_RO.dup
    else
      SUF_STRINGS = SUF_STRINGS_EN.dup
    end
  end

  # =========================
  # Читабельные подписи слоёв
  # =========================
  unless const_defined?(:LAYER_LABEL)
    LAYER_LABEL = {
      /Фасад_опции/i     => { ru: "Фасад: опции",       en: "Front: options",     ro: "Fațadă: opțiuni" },
      /Ручки_опции/i     => { ru: "Ручки: опции",       en: "Handles: options",   ro: "Mânere: opțiuni" },
      /Толщина_кромки/i  => { ru: "Толщина кромки",     en: "Edge band thickness",ro: "Grosime cant" },
      /Фасад_текстура/i  => { ru: "Текстура фасада",    en: "Front texture",      ro: "Textură fațadă" },
      /Каркас_текстура/i => { ru: "Текстура каркаса",   en: "Box texture",        ro: "Textură carcasă" },
      /открывание/i      => { ru: "Открывание фасада",  en: "Hinge swing",        ro: "Deschidere fațadă" },
      /Габаритная_рамка/i=> { ru: "Габаритная рамка",   en: "Bounding frame",     ro: "Cadru de gabarit" }
    }
  end

  def self.pretty_layer_name(layer_name)
    dict = LAYER_LABEL.find { |regex, _| layer_name =~ regex }&.last
    dict ? (dict[LANG] || dict[:en] || layer_name) : layer_name
  end

  # =====================================================================
  # ИНСТРУМЕНТ
  # =====================================================================
  class SUInteractTool

    def initialize(panel_mode=0)
      # Курсоры — как в рабочей версии (pdf на macOS, svg на Windows для SU >= 16)
      if(Sketchup.version.to_i >= 16)
        if(RUBY_PLATFORM =~ /darwin/)
          @default   = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.pdf')           unless defined? @default
          @active    = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.pdf')    unless defined? @active
          @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.pdf') unless defined? @noactions
        else
          @default   = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.svg')           unless defined? @default
          @active    = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.svg')    unless defined? @active
          @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.svg') unless defined? @noactions
        end
      else
        @default   = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.png')           unless defined? @default
        @active    = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.png')    unless defined? @active
        @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.png') unless defined? @noactions
      end

      @text_size = (OSX ? 20 : 13)

      @text_default_options = {
        color: "gray",
        font:  SU_Furniture.current_font,
        size:  @text_size,
        align: TextAlignCenter,
        bold:  false
      }
      @text_left_options = {
        color: "gray",
        font:  SU_Furniture.current_font,
        size:  @text_size,
        align: TextAlignLeft,
        bold:  false
      }

      @shift_press   = false
      @control_press = false
      @activate      = false

      @cursor_default   = UI.create_cursor(@default, 3, 2)   rescue nil
      @cursor_active    = UI.create_cursor(@active, 9, 9)    rescue nil
      @cursor_noactions = UI.create_cursor(@noactions, 9, 9) rescue nil

      @is_over_entity  = false
      @su_click        = false
      @animation_list  = []

      # Ровно как в старой версии: сначала строка, потом через $dc_strings
      @hover_message = "Hover over a component to find its click behaviors."
      @hover_message = (defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString(@hover_message) : @hover_message

      @is_animating = false
      @conv = DCConverter.new   # как в рабочей версии: обязателен DC
      @exception_array = ["edge_label","edgemat","front_mat","frontmat","texture_mat","texturemat","cut_out","cutout"]
    end

    def activate
      @model = Sketchup.active_model
      SU_Furniture.safe_remove_observer(@model.entities, $SUFEntitiesObserver)

      Sketchup::set_status_text((defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString(@hover_message) : @hover_message)

      @model.layers.remove("1_Фасад_текстура", true) if @model.layers["1_Фасад_текстура"]
      @model.layers.remove("3_Каркас_текстура", true) if @model.layers["3_Каркас_текстура"]
      @model.layers.remove("8_Толщина_кромки", true) if @model.layers["8_Толщина_кромки"]

      @model.layers.add("1_Фасад_открывание") if !@model.layers.detect { |layer| layer.name.include?("открывание") }

      @model.start_operation "layers", true, false, true

      if !@activate
        @visible_layer = {}
        @model.layers.to_a.each { |layer| @visible_layer[layer] = layer.visible? if !layer.name.include?("опции") }
      end

      @activate = true
      @layer_visible = []

      @model.layers.to_a.each { |layer|
        if layer.name.include?("опции") && layer.visible? && @layer_visible == []
          @model.layers.each { |l|
            if l.name.include?("открывание")
              SU_Furniture.safe_remove_observer(l, $SUFLayersObserver)
              l.visible = true
              @layer_visible << l.name
            end
          }
          layer.visible = false

        elsif layer.name.include?("открывание") && layer.visible? && @layer_visible == []
          layer.visible = false
          @model.layers.each { |l|
            if l.name.include?("опции")
              SU_Furniture.safe_remove_observer(l, $SUFLayersObserver)
              l.visible = true
              @layer_visible << l.name
            end
          }
          layer.visible = false
        end
      }

      if @layer_visible == []
        @model.layers.each { |l|
          if l.name.include?("опции")
            SU_Furniture.safe_remove_observer(l, $SUFLayersObserver)
            l.visible = true
            @layer_visible << l.name
          end
        }
      end

      @model.layers.each { |l| l.visible = false if l.name.include?("Габаритная_рамка") }

      @model.commit_operation
      SU_Furniture.safe_add_observer(@model.entities, $SUFEntitiesObserver)
    end

    def draw_text(view, position, text, options)
      native_options = options.dup
      native_options[:size] = pix_pt(options[:size]) if options.key?(:size)
      view.draw_text(position, text, native_options)
    end

    def pix_pt(pixels)
      return ((pixels.to_f / 96.0) * 72.0).round if IS_WIN
      pixels
    end

    def draw(view)
      # Левая подсказка — локализована через словарь
      draw_text(view, Geom::Point3d.new(30, 25, 0), SU_Furniture.t(:hold_shift), @text_left_options)

      # Центр — включённые слои, но через pretty_layer_name
      if @layer_visible != []
        pretty = @layer_visible.map { |raw| SU_Furniture.pretty_layer_name(raw) }
        draw_text(view, Geom::Point3d.new(view.vpwidth/2, 25, 0), SU_Furniture.t(:layer_enabled) + pretty.join(", "), @text_default_options)
      end
    end

    def deactivate(view)
      @activate = false
      UI.start_timer(0.1, false) {
        if !@activate && !((defined?(Change_Point) && Change_Point.respond_to?(:active)) ? Change_Point.active : false)
          @model.start_operation "layers", true, false, true
          SU_Furniture.safe_remove_observer(@model.layers, $SUFLayersObserver)
          @visible_layer.each_pair { |l,v| l.visible = v if !l.deleted? } if @visible_layer
          @model.layers.each { |l| l.visible = true  if l.name.include?("Z_Face") || l.name.include?("Z_Edge") }
          @model.layers.each { |l| l.visible = false if l.name.include?("Толщина_кромки") || l.name.include?("опции") }
          SU_Furniture.safe_add_observer(@model.layers, $SUFLayersObserver)
          @model.commit_operation
        end
      }
      @animation_list = []
      stop_last_timer()
      SU_Furniture.safe_add_observer(@model.entities, $SUFEntitiesObserver)
    end

    def resume(view)
      view.invalidate
    end

    def getExtents
      if @animation_list.length > 0
        new_bounds = Geom::BoundingBox.new
        for animation in @animation_list
          entity = animation['entity']
          is_camera = entity.to_s.include? "Sketchup::Camera"
          new_bounds.add entity.bounds unless is_camera
        end
        return new_bounds
      end
    end

    def onSetCursor()
      if @onclick_action.to_s != ''
        UI.set_cursor(@cursor_active || 0)
      elsif @is_over_entity == true
        UI.set_cursor(@cursor_noactions || 0)
      else
        UI.set_cursor(@cursor_default || 0)
      end
    end

    def onMouseMove(flags, x, y, view)
      return if camera_is_animating() || @is_animating
      stop_last_timer()
      @onclick_action = ''
      @onclick_entity = nil
      @options_layer = false
      ph = view.pick_helper
      ph.do_pick x,y
      pick_list = ph.path_at(0)
      @is_over_entity = false

      if pick_list
        ph.count.times { |pick_path_index|
          break if @onclick_entity
          pick_list = ph.path_at(pick_path_index)
          for i in 0..pick_list.length-1
            entity = pick_list[i]
            @is_over_entity = true
            if entity.is_a?(Sketchup::ComponentInstance)
              @dc = $dc_observers.get_class_by_version(entity)
              @onclick_action = @dc.get_attribute_value(entity,'onclick')

              @model.layers.each { |l|
                @options_layer = l.name if (l.name.include?("Фасад_опции") && l.visible?) ||
                                           (l.name.include?("Ручки_опции") && l.visible?) ||
                                           (l.name.include?("Фасад_текстура") && l.visible?) ||
                                           (l.name.include?("Каркас_текстура") && l.visible?) ||
                                           (l.name.include?("Толщина_кромки") && l.visible?)
              }

              if @onclick_action && @options_layer && @onclick_action.downcase.include?('animate')
                @onclick_action = nil
                @model.active_view.tooltip = '  ' + SUF_STRINGS["Layer enabled"] + ' "' + @options_layer + '"'
              end

              if !@onclick_action
                @onclick_action = @dc.get_attribute_value(entity,'su_click')
                if @onclick_action
                  @su_click = true
                  @onclick_name = 'su_click'
                else
                  @su_click = false
                  @onclick_name = 'onclick'
                end
              end

              if @onclick_action
                make_unique_if_needed(entity)
                @onclick_entity = entity
                Sketchup::set_status_text((defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString("Click to activate.") : "Click to activate.")
                msg = click_hint(entity)
                @model.active_view.tooltip = '   ' + msg

                if entity.definition.name.include?("item_5")
                  if entity.get_attribute("dynamic_attributes", "onclick") != 'SET("parent!handle_roty",90,0,-90,180)'
                    entity.set_attribute("dynamic_attributes", "onclick", 'SET("parent!handle_roty",90,0,-90,180)')
                    entity.definition.set_attribute("dynamic_attributes", "onclick", 'SET("parent!handle_roty",90,0,-90,180)')
                  end
                end

                if msg == SUF_STRINGS["Open"]
                  Sketchup::set_status_text(SU_Furniture.t(:open_percent_lbl), SB_VCB_LABEL)
                  Sketchup::set_status_text(@open_kf.to_s, SB_VCB_VALUE)
                end

                break
              else
                Sketchup::set_status_text((defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString("No click behaviors.") : "No click behaviors.")
                @model.active_view.tooltip = '' if !@options_layer
              end
            end
          end
        }
      else
        Sketchup::set_status_text((defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString(@hover_message) : @hover_message)
      end
    end

    def click_hint(entity)
      if    entity.definition.name.include?("edge_front"); msg = SUF_STRINGS["Edge length 1"]
      elsif entity.definition.name.include?("edge_rear");  msg = SUF_STRINGS["Edge length 2"]
      elsif entity.definition.name.include?("edge_up");    msg = SUF_STRINGS["Edge width 1"]
      elsif entity.definition.name.include?("edge_down");  msg = SUF_STRINGS["Edge width 2"]
      elsif entity.definition.name.include?("Texture");    msg = SUF_STRINGS["Texture direction"]
      elsif @onclick_action.include?("cut_type");          msg = SUF_STRINGS["Panel cutout"]
      elsif entity.definition.name.include?("item_open");  msg = SUF_STRINGS["Opening direction"]
      elsif entity.definition.name.include?("item_vitr");  msg = SUF_STRINGS["Showcase/grilles"]
      elsif entity.definition.name.include?("item_1") || entity.definition.name.include?("item_2") || entity.definition.name.include?("item_3")
        msg = SUF_STRINGS["Handle position"]
      elsif entity.definition.name.include?("item_4");     msg = SUF_STRINGS["Reduce the length of the handle"]
      elsif entity.definition.name.include?("item_5");     msg = SUF_STRINGS["Turn the handle"]
      elsif entity.definition.name.include?("item_6");     msg = SUF_STRINGS["Increase the length of the handle"]
      else
        if @onclick_action.include?("ANIMATECUSTOM")
          msg = SUF_STRINGS["Open"]
        else
          msg = entity.definition.get_attribute("dynamic_attributes", "_"+@onclick_name+"_formlabel",
                (defined?($dc_strings) && $dc_strings) ? $dc_strings.GetString("Click to activate.") : "Click to activate.")
        end
      end
      msg
    end

    def onUserText(text, view)
      if text.to_f >= 10 && text.to_f <= 175
        @open_kf=text
        view.invalidate
        draw(view)
      end
    end

    def onLButtonUp(flags, x, y, view)
      return if camera_is_animating()

      @onclick_action = @onclick_action.to_s
      return if @onclick_action == ''

      onclick_entity = @onclick_entity

      if (@onclick_action.downcase.include?('animate') || @onclick_action.downcase.include?('set(')) && @is_animating == false
        if !@shift_press && !@su_click && !onclick_entity.definition.name.include?("Texture")
          @model.start_operation "Interact", true
          @is_animating = true
        end
      end

      escaped_action = @onclick_action.gsub(/\"([^\"]+)?\"/) { |match|
        quoted_string = @dc.second_if_empty($1,'')
        '"' + @dc.escape(quoted_string,false) + '"'
      }

      commands = escaped_action.split(';')
      command_count = 0

      for command in commands
        next if command.to_s == ''
        next if command.index(/\w/) == nil

        command_count += 1
        first_parens = command.index('(')
        last_parens  = command.rindex(')')
        if first_parens == nil || last_parens == nil
          UI.messagebox(@dc.translate('ERROR: Unmatched parenthesis in ') + command)
          return
        end

        function = command[0..first_parens-1].strip.downcase
        param_string = command[first_parens+1..last_parens-1]
        param_string = escape_commas_in_parens(param_string)
        params = param_string.split(',')
        for i in 0..params.length-1
          params[i] = params[i].gsub(/\+/,'%2B')
          params[i] = @dc.unescape(params[i])
        end

        if function.index('animate') == 0 or function == 'set'
          @dc.make_unique_if_needed(onclick_entity)
          if function == 'set'
            function = 'animateinstant'
          end
          animate_type = function[7..999]

          reference_string = params.shift
          reference,error = @dc.parse_formula(reference_string,onclick_entity)
          if error.to_s.include?('subformula-error') || reference == nil || reference == ''
            UI.messagebox(@dc.translate('ERROR: Invalid entity to animate: ') + ' (' + reference_string + ')')
            return
          end

          if @conv.reserved_attribute_group[reference_string.downcase] == 'STRING'
            reference = reference_string.downcase
          elsif reference == nil || reference == '' || reference.to_s =~ /^\d+\.*\d*$/
            reference = reference_string.downcase
          end
          return if reference == nil || reference == ''

          if    animate_type == "custom"
            length  = params.shift
            easein  = params.shift
            easeout = params.shift
            length,  _ = @dc.parse_formula(length,  onclick_entity)
            easein,  _ = @dc.parse_formula(easein,  onclick_entity)
            easeout, _ = @dc.parse_formula(easeout, onclick_entity)
            length  = length.to_f
            easein  = easein.to_f / 100.0
            easeout = easeout.to_f / 100.0
          elsif animate_type == "slow"
            length, easein, easeout = 1.0, 0.0, 1.0
          elsif animate_type == "fast"
            length, easein, easeout = 0.25, 0.0, 1.0
          elsif animate_type == "instant"
            length, easein, easeout = 0.0, 0.0, 0.0
          else
            length, easein, easeout = 0.5, 0.0, 1.0
          end

          entity_array,attribute = parse_command_reference(reference)

          if @open_kf && attribute == 'animation'
            params = ["0", (@open_kf.to_f/100).to_s] # угол открывания
          end

          value_list = params
          return if value_list.length < 1
          value_list = parse_as_formulas(value_list, onclick_entity, reference)

          if entity_array == nil
            UI.messagebox(@dc.translate('ERROR: Invalid entity to animate: ') + ' (' + reference + ')')
            return
          end

          for entity in entity_array
            @dc.make_unique_if_needed(entity)
            current_value   = @dc.get_attribute_value(entity,attribute)
            last_list_index = @dc.get_attribute_value(entity, '_' + @onclick_name + '_state' + command_count.to_s)
            next_value, next_index = next_value_from(value_list, current_value, last_list_index)

            if @shift_press == true
              @model.start_operation @dc.translate("Interact"), true
              @dc.set_attribute(entity, '_' + @onclick_name + '_state' + command_count.to_s,  0)
              @dc.set_attribute(entity, attribute, value_list[0])
              @dc.update_last_sizes(entity)
              @dc.set_attribute_formula(entity, attribute, nil)
              @model.active_view.invalidate
              @dc.redraw(entity,false)
              onMouseMove(flags, x, y, view)
              @model.commit_operation

            elsif @su_click == true || onclick_entity.definition.name.include?("Texture")
              @model.start_operation @dc.translate("Interact"), true

              if @onclick_entity.definition.name.include?("Texture")
                napr_texture    = entity.definition.get_attribute("dynamic_attributes", "napr_texture", "1")
                a0_lenz         = entity.definition.get_attribute("dynamic_attributes", "a0_lenz")
                a0_leny         = entity.definition.get_attribute("dynamic_attributes", "a0_leny")
                a0_lenx         = entity.definition.get_attribute("dynamic_attributes", "a0_lenx")
                x_max_z         = entity.definition.get_attribute("dynamic_attributes", "x_max_z")
                x_max_y         = entity.definition.get_attribute("dynamic_attributes", "x_max_y")
                x_max_x         = entity.definition.get_attribute("dynamic_attributes", "x_max_x")
                x_max_x_formula = entity.definition.get_attribute("dynamic_attributes", "_x_max_x_formula")

                if x_max_x_formula == 'z_max_width+trim_z1+trim_z2'
                  entity.definition.set_attribute("dynamic_attributes","_x_max_x_formula",
                    'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_y1+trim_y2)')
                end

                if a0_lenz || a0_leny || a0_lenx
                  if a0_lenx*2.54 > x_max_x.to_f || a0_leny*2.54 > x_max_y.to_f || a0_lenz*2.54 > x_max_z.to_f
                    result = UI.messagebox(
                      SUF_STRINGS["The width of the material is less than the width of the panel."]+"\n"+
                      SUF_STRINGS["Change the direction of the texture and reduce the size?"], MB_YESNO)
                    return if result == IDNO
                  end
                end
              end

              @dc.set_attribute(entity, '_' + @onclick_name + '_state' + command_count.to_s,  next_index)
              @dc.set_attribute(entity, attribute, next_value)
              @dc.redraw(entity,false)
              @dc.update_last_sizes(entity)
              @dc.set_attribute_formula(entity, attribute, nil)
              @dc.clear_instance_cache(entity, false)
              @model.active_view.invalidate
              onMouseMove(flags, x, y, view)
              @model.commit_operation

            else
              if is_already_animating(entity, attribute) == false
                attach_animation(entity, attribute, next_value, length, easein, easeout)
              end
              @dc.set_attribute(entity, '_onclick_state' + command_count.to_s,  next_index)
            end
          end
        else
          UI.messagebox(@dc.translate('ERROR: Unknown function:') + ' (' + command + ')')
        end
      end

      UI.set_cursor(@cursor_default || 0)
    end

    def onKeyDown(key, repeat, flags, view)
      if key==VK_SHIFT
        @shift_press=true
      elsif key==VK_CONTROL || key==VK_COMMAND
        @control_press=true
      elsif key==VK_ALT
        @alt_press=true
      end
    end

    def onKeyUp(key, repeat, flags, view)
      if key==VK_SHIFT
        UI.start_timer(0.1, false) { @shift_press=false }
        view.lock_inference if view.inference_locked?
      elsif key==VK_CONTROL || key==VK_COMMAND
        UI.start_timer(0.1, false) { @control_press=false }
        view.lock_inference if view.inference_locked?
      elsif key==VK_ALT
        @alt_press=false
        view.lock_inference if view.inference_locked?
      end
    end

    def make_unique_if_needed(instance)
      if instance.is_a?(Sketchup::ComponentInstance) && instance.definition.count_used_instances > 1
        if !instance.parent.is_a?(Sketchup::Model)
          all_comp = search_parent(instance)
          if all_comp != []
            all_comp.reverse_each { |ent|
              ent.make_unique
              ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
            }
          end
        end
        instance.make_unique
        instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if instance.parent.is_a?(Sketchup::ComponentDefinition)
      end
    end

    def search_parent(entity,all_comp=[])
      if entity.parent.is_a?(Sketchup::ComponentDefinition)
        if entity.parent.instances[-1]
          all_comp << entity.parent.instances[-1]
          search_parent(entity.parent.instances[-1],all_comp)
        end
      end
      all_comp
    end

    def escape_commas_in_parens(formula)
      opening_parens_count = 0
      escaped_formula = ''
      for i in 0..(formula.length-1)
        char = formula[i..i]
        if opening_parens_count > 0 && char == ','
          escaped_formula << '%2C'
        else
          escaped_formula << char
        end
        if char == '('
          opening_parens_count += 1
        elsif char == ')'
          opening_parens_count -= 1
        end
      end
      escaped_formula
    end

    def stop_last_timer
      if @animation_list.length == 0 && @timer != nil
        UI.stop_timer @timer
        @timer = nil
      end
    end

    def is_already_animating(entity, attribute)
      for animation in @animation_list
        if animation['entity'] == entity && animation['attribute'] == attribute
          return true
        end
      end
      false
    end

    def parse_as_formulas(params, entity, attribute)
      for i in 0..params.length-1
        formula = params[i]
        params[i],error = @dc.parse_formula(formula, entity, attribute)
        if error.to_s.include? 'subformula-error'
          UI.messagebox(@dc.translate('ERROR: could not parse formula: ') + formula.to_s)
        end
      end
      params
    end

    def parse_command_reference(reference)
      source_entity = @onclick_entity
      if reference.to_s.index('!')
        sheet_name     = reference[0..reference.index('!')-1]
        attribute_name = reference[reference.index('!')+1..999]
        entity = find_entity_by_sheet_name(source_entity,sheet_name)
        return entity,attribute_name
      else
        attribute_name = reference
        entity = find_entity_by_attribute(source_entity,attribute_name)
        return entity,reference
      end
    end

    def find_entity_by_attribute(source_entity,attribute_name)
      if @dc.get_attribute_value(source_entity,attribute_name) != nil
        return [source_entity]
      end
      if source_entity.parent
        if !source_entity.parent.to_s.index('Sketchup::Model')
          if source_entity.parent.is_a?(Sketchup::ComponentDefinition)
            parent_entity = source_entity.parent.instances[0]
            find_entity_by_attribute(parent_entity,attribute_name)
          else
            return nil
          end
        end
      end
    end

    def find_entity_by_sheet_name(source_entity,sheet_name)
      subentity_array = []
      sheet_name = sheet_name.downcase

      return [source_entity] if @dc.name_of_entity_is(source_entity,sheet_name)

      if source_entity.parent
        if !source_entity.parent.to_s.index('Sketchup::Model')
          if source_entity.parent.is_a?(Sketchup::ComponentDefinition)
            parent_entity = source_entity.parent.instances[0]

            if sheet_name.downcase == "parent"
              return [parent_entity]
            elsif @dc.name_of_entity_is(parent_entity,sheet_name,'parent')
              return [parent_entity]
            else
              if parent_entity.parent.is_a?(Sketchup::ComponentDefinition)
                for subentity in parent_entity.parent.entities
                  if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)
                    return [subentity] if @dc.name_of_entity_is(subentity,sheet_name,'parent')
                  end
                end
              end
            end
          end
        end

        if source_entity.is_a?(Sketchup::ComponentInstance)
          for subentity in source_entity.definition.entities
            if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)
              subentity_array.push(subentity) if @dc.name_of_entity_is(subentity,sheet_name,'children')
            end
          end
        end

        for subentity in source_entity.parent.entities
          if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)
            subentity_array.push(subentity) if @dc.name_of_entity_is(subentity,sheet_name,'sibs')
          end
        end
      end

      subentity_array || nil
    end

    def next_value_from(params, current_value, current_index=0)
      return params[0], 0 if current_value == nil || current_value == ''

      current_index = current_index.to_i
      found_index = nil
      last_matched_index = nil

      for i in 0..params.length-1
        value = params[i]
        if current_value.to_s == value.to_s
          if i < current_index
            last_matched_index = i
          else
            found_index = i
            break
          end
        end
      end

      if found_index == nil
        for i in 0..params.length-1
          value = params[i]
          if (current_value.to_f - value.to_f).abs < 0.001
            if i < current_index
              last_matched_index = i
            else
              found_index = i
              break
            end
          end
        end
      end

      found_index = last_matched_index if found_index == nil

      if found_index==nil
        next_index = 0
      else
        next_index = found_index + 1
        next_index = 0 if next_index == params.length
      end

      next_value = params[next_index]
      return next_value, next_index
    end

    def attach_animation(entity,attribute,targetval,length,easein,easeout)
      easein = [[easein, 1.0].min, 0.0].max  # клэмп

      animation = {}
      animation['entity']     = entity
      animation['attribute']  = attribute
      animation['start_time'] = Time.new
      animation['length']     = length.to_f

      is_camera = entity.to_s.include? "Sketchup::Camera"
      if is_camera
        animation['startval']   = Sketchup::Camera.new entity.eye, entity.target, entity.up
        animation['targetval']  = targetval
      else
        animation['startval'] = @dc.get_attribute_value(entity,attribute)
        animation['targetval'] = (targetval.is_a?(Numeric) || targetval.to_f.to_s == targetval.to_s || targetval.to_i.to_s == targetval.to_s) ? targetval.to_f : targetval.to_s
      end

      center_weight = (1.0-easein)*easein + (1.0-easeout)*easeout
      total_weight  = center_weight+easein+easeout
      easein_end    = (total_weight != 0.0) ? (easein/total_weight) : 0.0
      easeout_start = (total_weight != 0.0) ? (1.0-(easeout/total_weight)) : 1.0

      animation['easein_end']    = easein_end
      animation['easeout_start'] = easeout_start

      @animation_list.push animation
      DCProgressBar.clear()

      if @timer == nil
        @timer = UI.start_timer(1.0/12.0,true) {
          begin
            $SUFToolsObserver.register_timer_id(@timer) if defined?($SUFToolsObserver) && $SUFToolsObserver
            if @is_in_timer_handler == true
              # no-op
            else
              @is_in_timer_handler = true
              current_time = Time.new
              finished = []

              @animation_list.each do |animation|
                entity        = animation['entity']
                attribute     = animation['attribute']
                startval      = animation['startval']
                targetval     = animation['targetval']
                start_time    = animation['start_time']
                length        = animation['length']
                easein_end    = animation['easein_end']
                easeout_start = animation['easeout_start']

                is_camera = entity.to_s.include? "Sketchup::Camera"
                seconds_complete   = (current_time - start_time).to_f
                fraction_complete  = length.to_f.zero? ? 1.0 : seconds_complete/length

                unless is_camera
                  if entity.valid? == false
                    finished << animation
                    next
                  end
                end

                if fraction_complete >= 1.0
                  newval = targetval
                  finished << animation
                  if is_camera
                    @model.active_view.camera = newval
                  end
                else
                  if fraction_complete < easein_end
                    fraction_eased = easein_end.zero? ? 1.0 : fraction_complete/easein_end
                    fraction_complete = fraction_complete *
                      (1.0-(Math.sin((Math::PI/2)*(1.0-fraction_eased))))
                  elsif fraction_complete > easeout_start
                    fraction_eased = (1.0-easeout_start).zero? ? 1.0 :
                      (fraction_complete-easeout_start)/(1.0-easeout_start)
                    fraction_complete = fraction_complete +
                      (1.0-fraction_complete) *
                      Math.sin((Math::PI/2)*fraction_eased)
                  end

                  if is_camera
                    neweye = Geom::Point3d.linear_combination(
                      1.0-fraction_complete, startval.eye,
                      fraction_complete,     targetval.eye
                    )
                    newtarget = Geom::Point3d.linear_combination(
                      1.0-fraction_complete, startval.target,
                      fraction_complete,     targetval.target
                    )
                    newup = Geom::Vector3d.linear_combination(
                      1.0-fraction_complete, startval.up,
                      fraction_complete,     targetval.up
                    )
                    @model.active_view.camera.set(neweye, newtarget, newup)
                  elsif targetval.is_a? Float
                    newval = startval.to_f + ((targetval.to_f-startval.to_f)*fraction_complete)
                  else
                    newval = startval
                  end
                end

                unless is_camera
                  formula = newval.is_a?(String) ? '"' + newval + '"' :
                    @conv.from_base(newval, @dc.get_attribute_formulaunits(entity, attribute, true)).to_s

                  @dc.set_attribute(entity,attribute,newval,formula)

                  if attribute == 'animation'
                    @dc.run_all_formulas(entity)

                    open        = entity.definition.get_attribute("dynamic_attributes", 'open')
                    open_depth  = entity.definition.get_attribute("dynamic_attributes", 'b2_open_depth')
                    open_depth  = entity.definition.get_attribute("dynamic_attributes", 'open_depth') if !open_depth
                    b2_open_d2  = entity.get_attribute("dynamic_attributes", 'b2_open_d2')
                    b2_open_d3  = entity.get_attribute("dynamic_attributes", 'b2_open_d3')

                    if entity.get_attribute("dynamic_attributes", 'a_y')
                      if b2_open_d3 && b2_open_d3.to_i != 0
                        @dc.set_attribute(entity,'a_y',-1*newval*b2_open_d3.to_f)
                      elsif b2_open_d2 && b2_open_d2.to_i != 0
                        @dc.set_attribute(entity,'a_y',-1*newval*b2_open_d2.to_f)
                      elsif open_depth && !open
                        @dc.set_attribute(entity,'a_y',-1*newval*open_depth.to_f)
                      end
                    end

                    redraw(entity,open)
                  else
                    @dc.redraw(entity,false)
                  end

                  if fraction_complete >= 1.0
                    @dc.update_last_sizes(entity)
                    @dc.set_attribute_formula(entity, attribute, nil)
                    @dc.clear_instance_cache(entity, false)
                  end
                end
              end

              unless finished.empty?
                @animation_list.reject! { |a|
                  finished.include?(a) ||
                  (!a['entity'].to_s.include?('Sketchup::Camera') && !a['entity'].valid?)
                }
              end

              @model.active_view.invalidate

              if @animation_list.length == 0 && @is_animating == true
                @is_animating = false
                @model.commit_operation
                if @dc != nil
                  if IS_WIN
                    stop_last_timer()
                  end
                end
              end

              @is_in_timer_handler = false
              if @animation_list.length == 0 && @timer
                UI.stop_timer @timer
                @timer = nil
              end
            end
          rescue
            @is_in_timer_handler = false
            if @timer
              UI.stop_timer @timer
              @timer = nil
            end
          end
        }
      end
    end

    def redraw(entity,open)
      x_formula   = entity.definition.get_attribute("dynamic_attributes", '_inst__x_formula')
      x_formula   = entity.get_attribute("dynamic_attributes", '_x_formula') if !x_formula
      y_formula   = entity.definition.get_attribute("dynamic_attributes", '_inst__y_formula')
      y_formula   = entity.get_attribute("dynamic_attributes", '_y_formula') if !y_formula
      z_formula   = entity.definition.get_attribute("dynamic_attributes", '_inst__z_formula')
      z_formula   = entity.get_attribute("dynamic_attributes", '_z_formula') if !z_formula
      a_y_formula = entity.definition.get_attribute("dynamic_attributes", '_a_y_formula')

      result_x = entity.transformation.origin.x.to_f
      result_y = entity.transformation.origin.y.to_f
      result_z = entity.transformation.origin.z.to_f

      rotz_formula = entity.definition.get_attribute("dynamic_attributes", '_inst__rotz_formula')
      rotz_formula = entity.get_attribute("dynamic_attributes", '_rotz_formula') if !rotz_formula

      # двери купе (анимация в X)
      if x_formula && x_formula.include?('animation') && !entity.definition.get_attribute("dynamic_attributes", 'open')
        local_origin_transform = entity.local_transformation
        entity.transform! local_origin_transform.inverse
        result_x,_ = @dc.parse_formula(x_formula,entity,'x')
        new_pos = Geom::Point3d.new(
          second_if_empty(result_x,entity.transformation.origin.x.to_f),
          result_y,
          result_z
        )
        entity.transform! Geom::Transformation.new(entity.transformation.origin.vector_to(new_pos))
        entity.transform! local_origin_transform

      # фасады распашные (open != 5)
      elsif open && open.to_i != 5
        if rotz_formula && rotz_formula.include?('a_rotz')
          @dc.redraw(entity,false)
        elsif entity.definition.get_attribute("dynamic_attributes", 'open')
          @dc.run_all_formulas(entity)
          if (x_formula && x_formula.include?('animation')) || (y_formula && y_formula.include?('animation'))
            @dc.redraw(entity,false)
          else
            for subentity in entity.definition.entities.grep(Sketchup::ComponentInstance)
              redraw(subentity,open)
            end
          end
        end

      # фасад с анимацией поворота/выноса (a_rotz + a_y)
      elsif rotz_formula && rotz_formula.include?('a_rotz') && a_y_formula && a_y_formula.include?('animation')
        @dc.redraw(entity,false)

      # ящики/фасады с open==5 (выдвижение по Y)
      elsif y_formula && y_formula.include?('a_y') && y_formula =~ /parent|LOOKUP/i
        if !open || (open && open.to_i == 5)
          local_origin_transform = entity.local_transformation
          entity.transform! local_origin_transform.inverse
          result_y,_ = @dc.parse_formula(y_formula,entity,'y')
          new_pos = Geom::Point3d.new(
            result_x,
            second_if_empty(result_y,entity.transformation.origin.y.to_f),
            result_z
          )
          entity.transform! Geom::Transformation.new(entity.transformation.origin.vector_to(new_pos))
          entity.transform! local_origin_transform
        end

      # тело фасада при open == 5
      elsif open && open.to_i == 5 && rotz_formula && rotz_formula.include?('a_rotz')
        @dc.redraw(entity,false)

      # направляющие (движущиеся рельсы)
      elsif entity.definition.get_attribute("dynamic_attributes", 'su_type',"0")=='furniture' &&
            entity.definition.get_attribute("dynamic_attributes", 'animation')
        @dc.redraw(entity,false)

      else
        for subentity in entity.definition.entities.grep(Sketchup::ComponentInstance)
          redraw(subentity,open)
        end
      end
    end

    def second_if_empty(val1,val2)
      return val2 if !val1
      val1
    end

    def camera_is_animating
      if @animation_list.length > 0
        for animation in @animation_list
          if animation['entity'].to_s.include? "Sketchup::Camera"
            @onclick_action = ''
            @is_over_entity = false
            return true
          end
        end
      end
      false
    end

  end # class SUInteractTool
end # module SU_Furniture
