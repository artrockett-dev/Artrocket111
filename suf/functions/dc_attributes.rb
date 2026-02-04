require('sketchup.rb')
require('su_dynamiccomponents.rb')

if defined?($dc_observers)
  # Open SketchUp's Dynamic Component Functions (V1) class. only if DC extension is active
  class DCFunctionsV1
    protected
    @@text_font = "Arial"
    language = "en-US"
    FILENAMESPACE = File.basename("suf", "suf_loader")
    path = File.dirname(__FILE__)
    path.force_encoding("UTF-8") if path.respond_to?(:force_encoding)
    PATH = File.dirname(path).freeze
    PATH_ROOT = File.dirname(PATH).freeze
    PATH_COMP = File.join(File.dirname(PATH_ROOT), "Components", "SUF")
    @model = Sketchup.active_model
    dict = @model.attribute_dictionary 'su_parameters'
    if dict
      dict.each {|k,v|
        if k == "lib_path"
          if v.split("=")[2] != "По умолчанию"
            send(:remove_const, "PATH_COMP") if const_defined?("PATH_COMP")
            PATH_COMP = v.split("=")[2]+"/Components/SUF"
          end
          elsif k == "text_font"
          @@text_font = v.split("=")[2]
          elsif k == "language"
          language = v.split("=")[2]
        end
      }
    end
    SUF_STRINGS = SU_Furniture::SUFLanguage.new(FILENAMESPACE + ".strings", language)
    
    def text_font()
      return @@text_font
    end#def
    def js_escape(string)
      string.gsub(/[^\w @\*\-\+\.\/\=\&]/) { |m|
        code = m.ord
        code < 256 ? "%" + ("0" + code.to_s(16))[-2..-1].upcase : "%u" + ("000" + code.to_s(16))[-4..-1].upcase
      }
    end
    def js_unescape(string)
      encoding = string.encoding
      string.gsub("%20"," ").gsub(/%(u[\dA-F]{4}|[\dA-F]{2})/) { |m| 
        m[2..-1].hex.chr(Encoding::UTF_8)
      }.force_encoding(encoding)
    end
    def suf_unescape(string,encoding='UTF-8')
      str=string.tr('+', ' ').b.gsub(/((?:%[0-9a-fA-F]{2})+)/) { |m|
        [m.delete('%')].pack('H*')
      }.force_encoding(encoding)
      str.valid_encoding? ? str : str.force_encoding(string.encoding)
    end
    
    unless DCFunctionsV1.method_defined?(:message)
      def message(str)
        SU_Furniture::Test.test_param([@source_entity,str])
      end#def
    end#unless
    protected:message
    
    unless DCFunctionsV1.method_defined?(:setval)
      def setval(s)
        @att == nil
        @att = s[0]
        @val = ""
        @val = s[1]
        @set_prnt = nil
        @set_prnt = s[2]
        @attribute = nil
        if @att == nil
          raise "no attribute"
          else
          @att = @att.to_s.downcase
          if @val != ""
            @val = suf_unescape(@val.to_s)
            if @val[0] == "="
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_formula", @val[1..-1])
              return (@val[1..-1])
              else
              if @set_prnt == "1" || @set_prnt == 1
                setval_parent(@source_entity)
                elsif @set_prnt != nil
                setval_entity(@source_entity,@set_prnt)
                raise "attribute " + @att + " not found" if  @attribute == nil
              end
              entity = @source_entity
              if @att == "material"
                mat_names = []
                Sketchup.active_model.materials.each { |m| mat_names << m.name.downcase }
                entity.material = @val if mat_names.include?(@val.downcase)
                else
                #puts entity.definition.name + " : " + @att + " : " + s[1].to_s
                entity.definition.delete_attribute("dynamic_attributes", "_" + @att + "_formula")
                entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_label", @att)
                entity.definition.set_attribute("dynamic_attributes", @att, @val)
                entity.set_attribute("dynamic_attributes", @att, @val)
              end#if
              return (@val)
            end
          end#if
        end#if
      end#def
      def setval_parent(entity)
        parent_def = entity.parent
        if parent_def.is_a?(Sketchup::ComponentDefinition)
          @attribute = parent_def.get_attribute("dynamic_attributes", @att)
          if @attribute
            @source_entity = parent_def.instances[-1]
            return
            else
            setval_parent(parent_def.instances[-1])
          end
        end#if
        return entity
      end#def
      def setval_entity(entity,search_entity)
        parent_def = entity.parent
        if parent_def.is_a?(Sketchup::ComponentDefinition)
          parent = parent_def.instances[-1]
          parent.definition.entities.grep(Sketchup::ComponentInstance) { |ent|
            name = ent.definition.get_attribute("dynamic_attributes", "_name")
            if name == search_entity
              @attribute = ent.definition.get_attribute("dynamic_attributes", @att)
              if @attribute
                @source_entity = ent
                return
              end
            end
          }
        end#if
      end#def
    end#unless
		protected:setval
		
		unless DCFunctionsV1.method_defined?(:setvalrange)
			def setvalrange(s)
        @value = nil
        @value = s[0]
        @valmin = nil
        @valmin = s[1]
        @valmax = nil
        @valmax = s[2]
        if @value == nil
          raise "no value"
          elsif @valmin == nil
          raise "no minimum and maximum value"
          elsif @valmax == nil
          raise "no maximum value"
          else
          @value = @value.to_f
          @valmin = @valmin.to_f
          @valmax = @valmax.to_f
          if @value < @valmin
            @value = @valmin
            elsif @value > @valmax
            @value = @valmax
          end#if
          return (@value)
        end#if
      end#def
    end#unless
		protected:setvalrange
		
		unless DCFunctionsV1.method_defined?(:nearestsmaller)
			def nearestsmaller(s)
        @value = nil
        @value = s[0]
        @valmin = nil
        @valarr = s[1..-1]
        if @value == nil
          raise "no value"
          elsif @valarr == nil
          raise "no array"
          else
          @valarr.reverse.each{|val|
            return val if @value.to_f >= val.to_f
          }
          return (@value)
        end#if
      end#def
    end#unless
		protected:nearestsmaller
		
		unless DCFunctionsV1.method_defined?(:setlen)
			def setlen(l)
        #puts "setlen: #{@source_entity.definition.name} - #{l}"
        @len = nil
        @len = l[0]
        @setlen = ""
        @setlen = l[1]
        @set_prnt = nil
        @set_prnt = l[2]
        @attribute = nil
        if @len == nil
          raise "no attribute"
          else
          if @setlen != "" && @setlen != "false"
            @setlen = @setlen.to_f
            @len = @len.to_s.downcase
            if @set_prnt != nil && @set_prnt.to_s == "1"
              setlen_parent(@source_entity)
              elsif @set_prnt != nil && @set_prnt.to_s == "2"
              error_dialog(@len)
              setlen_entity(@source_entity) if @setlen > 0
              else
              setlen_entity(@source_entity) if @setlen > 0
            end
            return (@len_unit)
          end#if
        end#if
      end#def
      def setlen_parent(entity)
        parent_def = entity.parent
        if parent_def.is_a?(Sketchup::ComponentDefinition)
          parent = parent_def.instances[-1]
          @attribute = parent.definition.get_attribute("dynamic_attributes", @len)
          @attribute == nil ? setlen_parent(parent) : setlen_entity(parent)
          raise "attribute " + @len + " not found" if  @attribute == nil
        end#if
      end#def
      def setlen_entity(entity)
        @formulaunits = entity.definition.get_attribute("dynamic_attributes", "_" + @len + "_formulaunits","0")
        if @formulaunits == "CENTIMETERS" || @len == "lenx" || @len == "leny" || @len == "lenz"
          @setlen = @setlen/2.54
          @len_unit = @setlen.to_cm
          else
          @len_unit = @setlen
        end#if
        if @set_prnt != nil && @set_prnt.to_s == "0"
          return (@len_unit)
          else
          if @len == "lenx" || @len == "leny" || @len == "lenz"
            #entity.definition.delete_attribute("dynamic_attributes", "_" + @len + "_nominal")
            else
            entity.definition.set_attribute("dynamic_attributes", "_" + @len + "_label", @len)
          end#if
          entity.definition.set_attribute("dynamic_attributes", @len, @setlen)
          entity.set_attribute("dynamic_attributes", @len, @setlen)
          #puts @len + " = " + @setlen.to_s + " > " + @len_unit.to_s
          return (@len_unit)
        end#if
      end#def
      def error_dialog(len)
        if $scale_error_dlg && ($scale_error_dlg.visible?)
          else
          html = '<html><head><meta charset="utf-8"><title>Edit</title></head><body></body></html>'
          $scale_error_dlg = UI::HtmlDialog.new({
            :dialog_title => SUF_STRINGS["The size is larger than the maximum!"]+" : "+len,
            :preferences_key => "scale_error",
            :scrollable => false,
            :resizable => false,
            :width => 350,
            :height => 39,
            :left => 100,
            :top => 100,
            :style => UI::HtmlDialog::STYLE_DIALOG
          })
          $scale_error_dlg.set_html(html)
          $scale_error_dlg.show
          $scale_error_dlg.set_position(Sketchup.active_model.active_view.vpwidth / 2, 100)
          UI.start_timer(2, false) { $scale_error_dlg.close }
        end
      end
    end#unless
		protected:setlen
		
		unless DCFunctionsV1.method_defined?(:setoptions)
			def setoptions(s)
        return 0 if @source_entity.hidden?
        @att = nil
        @att = s[0]
        @options = ""
        @options = s[1]
        @set_prnt = nil
        @set_prnt = s[2]
        if @options != ""
          @options = suf_unescape(@options.to_s)
          if @att == nil
            raise "no attribute"
            else
            @att = @att.to_s.downcase
            if @set_prnt == nil || @set_prnt == ""
              @attribute = @source_entity.definition.get_attribute("dynamic_attributes", @att)
              else
              @source_entity = setoptions_parent(@source_entity)
            end
            if @attribute == nil
              raise "attribute " + @att + " not found"
              else
              options_list = options(@options)
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_options", js_escape(options_list))
            end#if
          end#if
          return (1)
          else
          return (0)
        end#if
      end#def
      def setoptions_parent(entity)
        parent_def = entity.parent
        if parent_def.is_a?(Sketchup::ComponentDefinition)
          parent = parent_def.instances[-1]
          @attribute = parent.definition.get_attribute("dynamic_attributes", @att)
          if @attribute
            return parent
            else
            setoptions_parent(parent)
          end
        end#if
      end#def
      def options(opt)
        opt = opt.gsub("~","=").gsub("^","&").gsub("┴"," ").gsub("│","-")
        @units = @source_entity.definition.get_attribute("dynamic_attributes", "_" + @att + "_formulaunits")
        if @units == "CENTIMETERS"
          opts = ""
          opt_array = opt.split("&")
          opt_array.map{|option|
            opt_key = option.split("=")[0]
            opt_val = option.split("=")[1]
            opt_val = opt_val.to_f/2.54
            opts = opts + "&" + opt_key + "=" + opt_val.to_s
          } 
          opt = opts
        end#if
        opt = "&" + opt if opt[0] != "&"
        opt = opt + "&" if opt[opt.length-1] != "&"
        return opt
      end#def
    end#unless
		protected:setoptions
		
		unless DCFunctionsV1.method_defined?(:setlist)
			def setlist(s)
        return 0 if @source_entity.hidden?
        @list_att = "0"
        @list_att = s[0]
        new_list = @source_entity.definition.get_attribute("dynamic_attributes", @list_att)
        return 0 if new_list == "0"
        if new_list
          param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
          if param_temp_path && File.file?(File.join(param_temp_path,"additional.dat"))
            path_param = File.join(param_temp_path,"additional.dat")
            else
            path_param = File.join(PATH_COMP,"additional.dat")
          end
          @global_options = []
          options = "&Нет=1&"
          list_content = File.readlines(path_param).map(&:strip)
          list_content.each { |i|
            @global_options << i
            options += "#{i}=#{i}&"
          }
          options_length = options[1..-1].split("&").length+1
          options += "#{new_list}=#{new_list}&" if new_list.length > 2 && !@global_options.include?(new_list)
          File.write(path_param, @global_options.join("\n"))
          File.open(path_param, "a") { |file|
            file.puts "\n"+new_list if new_list.length > 2 && !@global_options.include?(new_list)
          }
          (1..19).each { |i| 
            y = "y"
            ent_val = @source_entity.definition.get_attribute("dynamic_attributes", y+i.to_s+"_name")
            if !ent_val
              y = "y0"
              ent_val = @source_entity.definition.get_attribute("dynamic_attributes", y+i.to_s+"_name")
            end
            if ent_val && ent_val == "1" && new_list.length > 2
              @source_entity.definition.set_attribute("dynamic_attributes", "#{y}#{i}_name", new_list)
              @source_entity.set_attribute("dynamic_attributes", "#{y}#{i}_name", new_list)
              @source_entity.definition.set_attribute("dynamic_attributes", "_#{y}#{i}_name_options", options)
              break
            end
          }
          @source_entity.definition.set_attribute("dynamic_attributes", @list_att, "0")
          @source_entity.set_attribute("dynamic_attributes", @list_att, "0")
          return options_length
          else
          return 0
        end
      end#def
    end#unless
		protected:setlist
		
		unless DCFunctionsV1.method_defined?(:setaccess)
			def setaccess(s)
        return 0 if @source_entity.hidden?
        @att = nil
        @att = s[0]
        @access = ""
        @access = s[1].to_i
        if @att == nil
          raise "no attribute"
          else
          @att = @att.to_s.downcase
          @attribute = @source_entity.definition.get_attribute("dynamic_attributes", @att)
          if @attribute == nil
            raise "attribute " + @att + " not found"
            else
            if @access == 3
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_access", "LIST")
              elsif @access == 2
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_access", "TEXTBOX")
              elsif @access == 1
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_access", "VIEW")
              elsif @access == 0
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_access", "NONE")
              else
              raise @access.to_s + " is out of range"
            end#if
            #puts "_" + @att + "_access" + " : " + @access.to_s 
          end#if
          return (@access)
        end#if
      end#def
    end#unless
		protected:setaccess
		
		unless DCFunctionsV1.method_defined?(:setlabel)
			def setlabel(s)
        return 0 if @source_entity.hidden?
        @att = nil
        @att = s[0]
        @label = ""
        @label = s[1]
        if @label != ""
          @label = suf_unescape(@label.to_s)
          if @att == nil
            raise "no attribute"
            else
            @att = @att.to_s.downcase
            @attribute = @source_entity.definition.get_attribute("dynamic_attributes", @att)
            if @attribute == nil
              raise "attribute " + @att + " not found"
              else
              @label = @label.gsub("┴"," ").gsub("│","-").gsub("┤","<").gsub("├",">").gsub("╡","<font").gsub("╞","</font>").gsub("║","color=")
              #puts "_" + @att + "_formlabel : " + @label
              @source_entity.definition.set_attribute("dynamic_attributes", "_" + @att + "_formlabel", @label)
            end#if
            return (1)
          end#if
        end#if
      end#def
    end#unless
		protected:setlabel
		
		unless DCFunctionsV1.method_defined?(:lookup)
			def lookup(att)
        @att = nil
        @att = att[0]
        @default = nil
        @default = att[1]
        @attribute = nil
        @attribute_unit = nil
        if @att == nil
          raise "no attribute"
          else
          @att = @att.to_s.downcase
          parent_ent(@source_entity)
          
          if @attribute == nil
            if @att == "material"
              return (nil)
              elsif @default == nil
              raise "attribute " + @att + " not found"
              else
              return (@default)
            end
            else
            if @att == "lenx" || @att == "leny" || @att == "lenz"
              lengthunits = @source_entity.get_attribute("dynamic_attributes", "_lengthunits")
              lengthunits = @source_entity.definition.get_attribute("dynamic_attributes", "_lengthunits") if !lengthunits
              if lengthunits == "CENTIMETERS" && @attribute_unit != "CENTIMETERS"
                @attribute = @attribute.to_f
                @attribute = @attribute.to_cm
              end
            end
            return (@attribute)
          end#if
        end#if
      end#def
      def parent_ent(entity)
        parent = entity.parent
        if parent.is_a?(Sketchup::ComponentDefinition)
          parent = parent.instances[-1]
          if @att == "lenx" || @att == "leny" || @att == "lenz" || @att == "rotx" || @att == "roty" || @att == "rotz" || @att == "x" || @att == "y" || @att == "z"
            @attribute = parent.get_attribute("dynamic_attributes", @att)
            elsif @att == "material"
            material = parent.material
            if material != nil
              material_name = material.name
              material_name = material_name.gsub(/^\[/,'')
              material_name = material_name.gsub(/\]$/,'')
              material_name = material_name.gsub(/^\</,'')
              material_name = material_name.gsub(/\>$/,'')
              @attribute = material_name
            end
            else
            @attribute = parent.definition.get_attribute("dynamic_attributes", @att)
            @attribute_unit = parent.definition.get_attribute("dynamic_attributes", "_" + @att + "_formulaunits")
          end#if
          if @attribute == nil
            parent_ent(parent)
            else
            if @attribute_unit && @attribute_unit == "CENTIMETERS"
              @attribute = @attribute.to_f
              @attribute = @attribute.to_cm
            end
            return @attribute
          end#if
        end#if
      end#def
    end#unless
		protected:lookup
		
		unless DCFunctionsV1.method_defined?(:drawerheight)
			def drawerheight(s)
        return 0 if @source_entity.hidden?
        entity = @source_entity
        @a01_lenz == nil
        @a01_lenz = s[0]
        @count = 0
        @count = s[1]
        @drawers = s[2,@count]
        @drawers_without_formula = 0
        @drawers_with_formula = []
        @drawer_all_formula = []
        @all_formula_nil = false
        @all_value_zero = 0
        if @a01_lenz == nil
          raise "no attribute"
          elsif @count == 0
          raise "count error"
          elsif !@drawers || @drawers == []
          raise "no drawers"
          else
          @a01_lenz = @a01_lenz.to_s.downcase
          lenz = entity.definition.get_attribute("dynamic_attributes", @a01_lenz).to_f
          if @drawers != ""
            d2_drawer0_template = entity.definition.get_attribute("dynamic_attributes", "d2_drawer0_template")
            if d2_drawer0_template && d2_drawer0_template != "1"
              template_arr = d2_drawer0_template.split(",")
            end
            if d2_drawer0_template && d2_drawer0_template != "1" && template_arr.count == @drawers.count
              @drawers.reverse.each_with_index{|drawer,index|
                numerator = template_arr[index].split("/")[0].to_i
                denominator = template_arr[index].split("/")[1].to_i
                height = lenz*numerator/denominator
                height_formula = "(" + @a01_lenz + ")*" + numerator.to_s + "/" + denominator.to_s
                entity.definition.set_attribute("dynamic_attributes", "_" + drawer + "_formula", height_formula)
                entity.definition.set_attribute("dynamic_attributes", drawer, height)
                entity.set_attribute("dynamic_attributes", drawer, height)
              }
              d2_drawer0_position = entity.definition.get_attribute("dynamic_attributes", "d2_drawer0_position")
              if d2_drawer0_position && d2_drawer0_position != "1"
                p d2_drawer0_position
                else
                drawerZ = 0
                for drawer in @drawers
                  height = entity.definition.get_attribute("dynamic_attributes", drawer).to_f
                  entity.definition.set_attribute("dynamic_attributes", drawer+"z", drawerZ)
                  entity.set_attribute("dynamic_attributes", drawer+"z", drawerZ)
                  drawerZ += height
                end
              end
              else
              @height_formula = "(" + @a01_lenz
              for drawer in @drawers
                drawer_formula = entity.definition.get_attribute("dynamic_attributes", "_" + drawer + "_formula")
                @drawer_all_formula.push(drawer_formula)
                @all_value_zero += entity.definition.get_attribute("dynamic_attributes", drawer).to_f
              end
              @all_formula_nil = true if @drawer_all_formula.compact.length == 0
              count = @count
              for drawer in @drawers
                drawer_formula = entity.definition.get_attribute("dynamic_attributes", "_" + drawer + "_formula")
                drawer_value = entity.definition.get_attribute("dynamic_attributes", drawer).to_f
                drawer_value = 0 if @all_formula_nil == true
                if !drawer_formula
                  if drawer_value != 0
                    if drawer_value < (lenz - (count-1)*2.5)
                      lenz = lenz-drawer_value
                      @height_formula += "-" + drawer
                      @drawers_without_formula += 1
                      else
                      UI.messagebox(SUF_STRINGS["Drawer height must be at least 64 mm"])
                      @drawers_with_formula.push(drawer)
                    end
                    else
                    @drawers_with_formula.push(drawer)
                  end
                  else
                  @drawers_with_formula.push(drawer)
                end
                count -= 1
              end
              height = lenz/(@count - @drawers_without_formula)
              @height_formula += ")/" + (@count - @drawers_without_formula).to_s
              delete_formulas = []
              for drawer in @drawers_with_formula
                delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + drawer + "_formula")
                delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + drawer + "z_formula")
                entity.definition.set_attribute("dynamic_attributes", "_" + drawer + "_formula", @height_formula)
                entity.definition.set_attribute("dynamic_attributes", drawer, height)
                entity.set_attribute("dynamic_attributes", drawer, height)
              end
              if d2_drawer0_position && d2_drawer0_position != "1"
                p d2_drawer0_position
                else
                drawerZ = 0
                for drawer in @drawers
                  height = entity.definition.get_attribute("dynamic_attributes", drawer).to_f
                  entity.definition.set_attribute("dynamic_attributes", drawer+"z", drawerZ)
                  entity.set_attribute("dynamic_attributes", drawer+"z", drawerZ)
                  drawerZ += height
                end
              end
              UI.messagebox("#{SUF_STRINGS["All values cannot be changed"]}!") if @all_formula_nil == true && @all_value_zero != 0
            end#if
            return (1)
          end#if
        end#if
      end#def
    end#unless
		protected:drawerheight
		
		unless DCFunctionsV1.method_defined?(:shelvesheight)
			def shelvesheight(s)
        return 0 if @source_entity.hidden?
        entity = @source_entity
        @a01_lenz == nil
        @a01_lenz = s[0]
        @b1_p_thickness = nil
        @b1_p_thickness = s[1]
        @count = 0
        @count = s[2].to_f
        @shelves = s[3,@count+1]
        @shelves_without_formula = 0
        @shelves_with_formula = []
        @shelve_all_formula = []
        @all_formula_nil = false
        if @a01_lenz == nil
          raise "no attribute"
          elsif @count == 0
          return (0)
          elsif !@shelves || @shelves == []
          raise "no shelves"
          else
          @a01_lenz = @a01_lenz.to_s.downcase
          entity.definition.set_attribute("dynamic_attributes", "_"+@b1_p_thickness+"_formulaunits","CENTIMETERS")
          @lenz = entity.definition.get_attribute("dynamic_attributes", @a01_lenz).to_f
          @a0_shelves_count_formula = entity.definition.get_attribute("dynamic_attributes", "_a0_shelves_count_formula")
          @a1_up_shelve = entity.definition.get_attribute("dynamic_attributes", "a1_up_shelve", "1").to_s
          @a2_down_shelve = entity.definition.get_attribute("dynamic_attributes", "a2_down_shelve", "1").to_s
          @thickness = entity.definition.get_attribute("dynamic_attributes", @b1_p_thickness).to_f
          
          @height_formula = "(" + @a01_lenz
          
          if @a1_up_shelve == "2"
            @lenz -= @thickness
            @height_formula += "-" + @b1_p_thickness
          end
          if @a2_down_shelve == "2"
            @lenz -= @thickness
            @height_formula += "-" + @b1_p_thickness
          end
          
          if @shelves != ""
            for shelve in @shelves
              shelve_formula = entity.definition.get_attribute("dynamic_attributes", "_" + shelve + "_formula")
              @shelve_all_formula.push(shelve_formula)
            end
            @all_formula_nil = true if @shelve_all_formula.compact.length == 0
            without_formula = false
            @shelve_all_formula.each { |formula| if !formula then without_formula = true; break end}
            without_formula = true if !@a0_shelves_count_formula
            check = true
            check = false if @shelve_all_formula.to_s.include?("LOOKUP") && without_formula == false
            for shelve in @shelves
              shelve_formula = entity.definition.get_attribute("dynamic_attributes", "_" + shelve + "_formula")
              shelve_value = entity.definition.get_attribute("dynamic_attributes", shelve, "")
              shelve_value = "" if @all_formula_nil == true
              if !shelve_formula
                if shelve_value != "" && shelve_value.to_f < (@lenz - @count*(@thickness+1))
                  @lenz = @lenz-shelve_value
                  @height_formula += "-" + shelve
                  @shelves_without_formula += 1
                  else
                  @shelves_with_formula.push(shelve)
                end
                else
                @shelves_with_formula.push(shelve)
              end
            end
            if check == true 
              height = (((@lenz - @thickness*@count)*25.4/(@count + 1 - @shelves_without_formula)).round(1))/25.4
              @height_formula += "-" + @b1_p_thickness + "*" + @count.round.to_s + ")/" + (@count + 1 - @shelves_without_formula).to_s
              delete_formulas = []
              for shelve in @shelves_with_formula
                delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + shelve + "_formula")
                delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + shelve + "z_formula")
                entity.definition.set_attribute("dynamic_attributes", "_" + shelve + "_formula", @height_formula)
                entity.definition.set_attribute("dynamic_attributes", "_"+shelve+"_label", shelve)
                entity.definition.set_attribute("dynamic_attributes", shelve, height)
                entity.set_attribute("dynamic_attributes", shelve, height)
              end
              @shelvesZ = 0
              for shelve in @shelves
                height = entity.definition.get_attribute("dynamic_attributes", shelve).to_f
                @shelvesZ += height
                entity.definition.set_attribute("dynamic_attributes", "_"+shelve+"z_label", shelve+"z")
                entity.definition.set_attribute("dynamic_attributes", shelve+"z", @shelvesZ)
                entity.set_attribute("dynamic_attributes", shelve+"z", @shelvesZ)
                @shelvesZ += @thickness
              end
              UI.messagebox("#{SUF_STRINGS["All values cannot be changed"]}!") if @all_formula_nil == true
              return (1)
              else
              return (0)
            end
          end#if
        end#if
      end#def
    end#unless
		protected:shelvesheight
		
		unless DCFunctionsV1.method_defined?(:panelposition)
			def panelposition(s)
        return 0 if @source_entity.hidden?
        entity = @source_entity
        @a01_len == nil
        @a01_len = s[0]
        @b1_p_thickness = nil
        @b1_p_thickness = s[1]
        @count = 0
        @count = s[2].to_f
        @panels = s[3,@count+1]
        @panels_without_formula = 0
        @panels_with_formula = []
        @panels_all_formula = []
        @all_formula_nil = false
        if @a01_len == nil
          raise "no attribute"
          elsif @count == 0
          return (0)
          elsif !@panels || @panels == []
          raise "no panels"
          else
          @a01_len = @a01_len.to_s.downcase
          @len = entity.definition.get_attribute("dynamic_attributes", @a01_len).to_f
          @a1_right_panel = entity.definition.get_attribute("dynamic_attributes", "a1_right_panel", "1").to_s
          @thickness = entity.definition.get_attribute("dynamic_attributes", @b1_p_thickness).to_f
          @len -= @thickness if @a1_right_panel != "1"
          @height_formula = "(" + @a01_len
          if @panels != ""
            for panel in @panels
              panel_formula = entity.definition.get_attribute("dynamic_attributes", "_" + panel + "_formula")
              @panels_all_formula.push(panel_formula)
            end
            @all_formula_nil = true if @panels_all_formula.compact.length == 0
            for panel in @panels
              panel_formula = entity.definition.get_attribute("dynamic_attributes", "_" + panel + "_formula")
              panel_value = entity.definition.get_attribute("dynamic_attributes", panel, "")
              panel_value = "" if @all_formula_nil == true
              if !panel_formula
                if panel_value != "" && panel_value.to_f < (@len - @count*(@thickness+1))
                  @len = @len-panel_value.to_f
                  @height_formula += "-" + panel
                  @panels_without_formula += 1
                  else
                  @panels_with_formula.push(panel)
                end
                else
                @panels_with_formula.push(panel)
              end
            end
            panel_position = ((((@len - @thickness*@count)*25.4/(@count + 1 - @panels_without_formula))+0.1).floor)/25.4
            @height_formula += "-" + @b1_p_thickness + "*" + @count.round.to_s + ")/" + (@count + 1 - @panels_without_formula).to_s
            delete_formulas = []
            for panel in @panels_with_formula
              delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + panel + "_formula")
              delete_formulas << entity.definition.get_attribute("dynamic_attributes", "_" + panel + "z_formula")
              entity.definition.set_attribute("dynamic_attributes", "_" + panel + "_formula", @height_formula)
              entity.definition.set_attribute("dynamic_attributes", "_"+panel+"_label", panel)
              entity.definition.set_attribute("dynamic_attributes", panel, panel_position)
              entity.set_attribute("dynamic_attributes", panel, panel_position)
            end
            @panelsZ = 0
            for panel in @panels
              panel_position = entity.definition.get_attribute("dynamic_attributes", panel).to_f
              @panelsZ += panel_position
              entity.definition.set_attribute("dynamic_attributes", "_"+panel+"z_label", panel+"z")
              entity.definition.set_attribute("dynamic_attributes", panel+"z", @panelsZ)
              entity.set_attribute("dynamic_attributes", panel+"z", @panelsZ)
              @panelsZ += @thickness
            end
            UI.messagebox("#{SUF_STRINGS["All values cannot be changed"]}!") if @all_formula_nil == true
            return (1)
          end#if
        end#if
      end#def
    end#unless
		protected:panelposition
		
		unless DCFunctionsV1.method_defined?(:eraseif)
			def eraseif(s)
				return s[0]
      end
    end#unless
		protected:eraseif
		
		unless DCFunctionsV1.method_defined?(:cutout)
			# def cutout(s)
      #   return 0 if @source_entity.hidden?
      #   @v0_cut = s[0]
      #   if @v0_cut.to_f == 1
      #     entity = @source_entity
      #     model = Sketchup.active_model
      #     @lenx = entity.definition.get_attribute("dynamic_attributes", "lenx")
      #     @leny = entity.definition.get_attribute("dynamic_attributes", "leny")
      #     @lenz = entity.definition.get_attribute("dynamic_attributes", "lenz")
      #     @v1_type = s[1]
      #     @v1_size_length = s[2].to_f/2.54
      #     @v1_size_width = s[3].to_f/2.54
      #     @v2_type = s[4]
      #     @v2_size_length = s[5].to_f/2.54
      #     @v2_size_width = s[6].to_f/2.54
      #     @v3_type = s[7]
      #     @v3_size_length = s[8].to_f/2.54
      #     @v3_size_width = s[9].to_f/2.54
      #     @v4_type = s[10]
      #     @v4_size_length = s[11].to_f/2.54
      #     @v4_size_width = s[12].to_f/2.54
          
      #     @offset_vector1_length = Geom::Vector3d.new(0, 0, (s[13] ? s[13].to_f/2.54 : 0))
      #     @offset_vector1_width = Geom::Vector3d.new(0, (s[14] ? s[14].to_f/2.54 : 0), 0)
      #     @offset_vector2_length = Geom::Vector3d.new(0, 0, (s[15] ? s[15].to_f/2.54 : 0))
      #     @offset_vector2_width = Geom::Vector3d.new(0, (s[16] ? s[16].to_f/2.54 : 0), 0)
      #     @offset_vector3_length = Geom::Vector3d.new(0, 0, (s[17] ? s[17].to_f/2.54 : 0))
      #     @offset_vector3_width = Geom::Vector3d.new(0, (s[18] ? s[18].to_f/2.54 : 0), 0)
      #     @offset_vector4_length = Geom::Vector3d.new(0, 0, (s[19] ? s[19].to_f/2.54 : 0))
      #     @offset_vector4_width = Geom::Vector3d.new(0, (s[20] ? s[20].to_f/2.54 : 0), 0)
          
      #     edge_layer = false
      #     model.layers.each { |l| edge_layer = true if l.name.include?("Z_Edge") && l.visible? }
      #     model.layers.each { |l| l.visible = true if l.name.include?("Z_Edge") && edge_layer == false }
      #     face_layer = false
      #     model.layers.each { |l| face_layer = true if l.name.include?("Z_Face") && l.visible? }
      #     model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") && face_layer == false }
      #     p "load"
      #     if Sketchup.version_number >= 2110000000
      #       essence_comp = model.definitions.load(PATH + "/additions/Essence.skp", allow_newer: true)
      #       else
      #       essence_comp = model.definitions.load PATH + "/additions/Essence.skp"
      #     end

      #     t = Geom::Transformation.translation [0, 0, 0]
      #     essence_instance = entity.definition.entities.add_instance essence_comp, t
      #     essence_instance.material = entity.material
      #     redraw_size(essence_instance)
      #     groove_comp = []
      #     groove_edges = []
      #     entity.definition.entities.each { |ent|
      #       if ent.is_a?(Sketchup::Group)
      #         ent.erase! if !ent.name.include?("_SUF")
      #         elsif ent.is_a?(Sketchup::ComponentInstance) && ent.get_attribute("dynamic_attributes", "_groove")
      #         groove_comp << ent
      #         elsif ent.is_a?(Sketchup::Edge) && ent.get_attribute("dynamic_attributes","edge")
      #         groove_edges << [ent.start,ent.end,ent.hidden?,ent.attribute_dictionary("dynamic_attributes").to_h]
      #         else
      #         ent.erase! if ent != essence_instance
      #       end
      #     }
      #     essence_instance.explode
      #     if groove_edges != []
      #       groove_edges.each { |edge_arr|
      #         edges = entity.definition.entities.add_edges(edge_arr[0],edge_arr[1])
      #         edges[0].hidden = edge_arr[2]
      #         edge_arr[3].each_pair { |key,value|
      #           edges[0].set_attribute("dynamic_attributes",key,value)
      #         }
      #       }
      #     end
      #     @down_edge = nil
      #     @up_edge = nil
      #     @front_edge = nil
      #     @back_edge = nil
      #     entity.definition.entities.grep(Sketchup::Face).each { |f|
      #       if groove_comp != []
      #         groove_comp.each {|comp|
      #           if f.bounds.center.x == comp.transformation.origin.x
      #             comp.definition.behavior.is2d = true
      #             comp.definition.behavior.snapto = SnapTo_Arbitrary
      #             comp.definition.behavior.cuts_opening = true
      #             comp.glued_to = f
      #           end
      #         }
      #         if f.edges.all?{|e|e.get_attribute("dynamic_attributes","edge")}
      #           f.erase!
      #           next
      #         end
      #       end
      #       face = f.get_attribute("dynamic_attributes", "face", "0")
      #       if face.include?("primary")
      #         f.edges.each {|e|
      #           if e.start.position.x != 0 && e.end.position.x != 0
      #             if e.line[1][1].round == 1
      #               if e.start.position.z == 0 
      #                 @down_edge = e
      #                 @down_start = e.start.position
      #                 @down_end = e.end.position
      #                 else
      #                 @up_edge = e
      #                 @up_start = e.start.position
      #                 @up_end = e.end.position
      #               end
      #               elsif e.line[1][2].round == 1
      #               if e.start.position.y == 0
      #                 @front_edge = e
      #                 @front_start = e.start.position
      #                 @front_end = e.end.position
      #                 else
      #                 @back_edge = e
      #                 @back_start = e.start.position
      #                 @back_end = e.end.position
      #               end
      #             end
      #           end
      #         }
      #       end
      #     }
      #     model.definitions.to_a.each { |definition| model.definitions.remove(definition) if definition.name.include?("Essence") && definition.count_used_instances == 0 }
      #     if @v1_type.to_s == "1" && @v2_type.to_s == "1" && @v3_type.to_s == "1" && @v4_type.to_s == "1"
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #       return 1
      #       elsif @v1_type.to_s != "1" && s[2].to_f.round(2) > (@lenz*2.54).round(2) || @v2_type.to_s != "1" && s[5].to_f.round(2) > (@lenz*2.54).round(2) || @v3_type.to_s != "1" && s[8].to_f.round(2) > (@lenz*2.54).round(2) || @v4_type.to_s != "1" && s[11].to_f.round(2) > (@lenz*2.54).round(2)
      #       UI.messagebox(SUF_STRINGS["Cutout length/radius exceeds part length!"])
      #       set_att_default(entity)
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #       return 1
      #       elsif @v1_type.to_s == "4" && s[3].to_f.round(2) > (@leny*2.54).round(2) || @v1_type.to_s == "5" && s[3].to_f.round(2) > (@leny*2.54).round(2) || @v2_type.to_s == "4" && s[6].to_f.round(2) > (@leny*2.54).round(2) || @v2_type.to_s == "5" && s[6].to_f.round(2) > (@leny*2.54).round(2) || @v3_type.to_s == "4" && s[9].to_f.round(2) > (@leny*2.54).round(2) || @v3_type.to_s == "5" && s[9].to_f.round(2) > (@leny*2.54).round(2) || @v4_type.to_s == "4" && s[12].to_f.round(2) > (@leny*2.54).round(2) || @v4_type.to_s == "5" && s[12].to_f.round(2) > (@leny*2.54).round(2)
      #       UI.messagebox(SUF_STRINGS["Cutout width exceeds part width!"])
      #       set_att_default(entity)
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #       return 1
      #       elsif @v1_type.to_s != "1" && @v2_type.to_s != "1" && s[2].to_f.round(2) + s[5].to_f.round(2) > (@lenz*2.54).round(2) || @v3_type.to_s != "1" && @v4_type.to_s != "1" && s[8].to_f.round(2) + s[11].to_f.round(2) > (@lenz*2.54).round(2)
      #       UI.messagebox(SUF_STRINGS["Cutouts length/radius exceeds part length!"])
      #       set_att_default(entity)
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #       return 1
      #       elsif (@v1_type.to_s == "4" || @v1_type.to_s == "5") && (@v3_type.to_s == "4" || @v3_type.to_s == "5") && s[3].to_f.round(2) + s[9].to_f.round(2) > (@leny*2.54).round(2) || (@v2_type.to_s == "4" || @v2_type.to_s == "5") && (@v4_type.to_s == "4" || @v4_type.to_s == "5") && s[6].to_f.round(2) + s[12].to_f.round(2) > (@leny*2.54).round(2) || (@v1_type.to_s == "2" || @v1_type.to_s == "3") && (@v3_type.to_s == "2" || @v3_type.to_s == "3") && s[2].to_f.round(2) + s[8].to_f.round(2) > (@leny*2.54).round(2) || (@v2_type.to_s == "2" || @v2_type.to_s == "3") && (@v4_type.to_s == "2" || @v4_type.to_s == "3") && s[5].to_f.round(2) + s[11].to_f.round(2) > (@leny*2.54).round(2)
      #       UI.messagebox(SUF_STRINGS["Cutouts width exceeds part width!"])
      #       set_att_default(entity)
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #       model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #       return 1
      #       else
      #       @faces = []
      #       @rad_nar_edges = []
      #       cut_rad_nar(entity,1) if @v1_type.to_i == 2
      #       cut_rad_vn(entity,1) if @v1_type.to_i == 3
      #       cut_skos(entity,1) if @v1_type.to_i == 4
      #       cut_ugol(entity,1) if @v1_type.to_i == 5
      #       cut_rad_nar(entity,2) if @v2_type.to_i == 2
      #       cut_rad_vn(entity,2) if @v2_type.to_i == 3
      #       cut_skos(entity,2) if @v2_type.to_i == 4
      #       cut_ugol(entity,2) if @v2_type.to_i == 5
      #       cut_rad_nar(entity,3) if @v3_type.to_i == 2
      #       cut_rad_vn(entity,3) if @v3_type.to_i == 3
      #       cut_skos(entity,3) if @v3_type.to_i == 4
      #       cut_ugol(entity,3) if @v3_type.to_i == 5
      #       cut_rad_nar(entity,4) if @v4_type.to_i == 2
      #       cut_rad_vn(entity,4) if @v4_type.to_i == 3
      #       cut_skos(entity,4) if @v4_type.to_i == 4
      #       cut_ugol(entity,4) if @v4_type.to_i == 5
      #       pushpull_faces
      #       if @rad_nar_edges != []
      #         for rad_edge in @rad_nar_edges
      #           edges = rad_edge.all_connected
      #           edges.grep(Sketchup::Edge).each { |edge|
      #             if edge.start.position == rad_edge.start.position || edge.start.position == rad_edge.end.position || edge.end.position == rad_edge.start.position || edge.end.position == rad_edge.end.position
      #               if edge.start.position.x == 0 || edge.end.position.x == 0
      #                 edge.soft = true
      #               end
      #             end
      #           }
      #         end
      #       end
      #       entity.definition.entities.grep(Sketchup::Face).each { |f| f.layer = "Z_Edge" if f.normal.x.abs != 1}
      #       entity.definition.entities.grep(Sketchup::Edge).each { |e| e.layer = "Z_Edge" }
      #     end
      #     model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
      #     model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
      #     return [@v1_type,@v2_type,@v3_type,@v4_type].to_s
      #     else
      #     return 0
      #   end
      # end#def

    def cutout(s)
      return 0 if @source_entity.hidden?
      @v0_cut = s[0]

      if @v0_cut.to_f == 1
        entity = @source_entity
        model = Sketchup.active_model

        # --- BEGIN: print once per size change ---
        # Get this instance's current size
        cur_lenx = entity.get_attribute("dynamic_attributes", "lenx")
        cur_leny = entity.get_attribute("dynamic_attributes", "leny")
        cur_lenz = entity.get_attribute("dynamic_attributes", "lenz")

        current_size_signature = [cur_lenx, cur_leny, cur_lenz]

        # What size did we already log?
        last_logged_size = entity.get_attribute("dynamic_attributes", "_last_logged_size")

        # Only print if it's a new size (so we print once per edit operation)
        if last_logged_size != current_size_signature
          p "load"
          # $dlg_suf.close
          # SU_Furniture::SUF_Dialog.activate unless $dlg_suf.visible?
          SU_Furniture::SUFDialog.refresh
          entity.set_attribute("dynamic_attributes", "_last_logged_size", current_size_signature)
        end
        # --- END: print once per size change ---

        @lenx = entity.definition.get_attribute("dynamic_attributes", "lenx")
        @leny = entity.definition.get_attribute("dynamic_attributes", "leny")
        @lenz = entity.definition.get_attribute("dynamic_attributes", "lenz")

        @v1_type = s[1]
        @v1_size_length = s[2].to_f/2.54
        @v1_size_width  = s[3].to_f/2.54
        @v2_type = s[4]
        @v2_size_length = s[5].to_f/2.54
        @v2_size_width  = s[6].to_f/2.54
        @v3_type = s[7]
        @v3_size_length = s[8].to_f/2.54
        @v3_size_width  = s[9].to_f/2.54
        @v4_type = s[10]
        @v4_size_length = s[11].to_f/2.54
        @v4_size_width  = s[12].to_f/2.54

        @offset_vector1_length = Geom::Vector3d.new(0, 0, (s[13] ? s[13].to_f/2.54 : 0))
        @offset_vector1_width  = Geom::Vector3d.new(0, (s[14] ? s[14].to_f/2.54 : 0), 0)
        @offset_vector2_length = Geom::Vector3d.new(0, 0, (s[15] ? s[15].to_f/2.54 : 0))
        @offset_vector2_width  = Geom::Vector3d.new(0, (s[16] ? s[16].to_f/2.54 : 0), 0)
        @offset_vector3_length = Geom::Vector3d.new(0, 0, (s[17] ? s[17].to_f/2.54 : 0))
        @offset_vector3_width  = Geom::Vector3d.new(0, (s[18] ? s[18].to_f/2.54 : 0), 0)
        @offset_vector4_length = Geom::Vector3d.new(0, 0, (s[19] ? s[19].to_f/2.54 : 0))
        @offset_vector4_width  = Geom::Vector3d.new(0, (s[20] ? s[20].to_f/2.54 : 0), 0)

        edge_layer = false
        model.layers.each { |l| edge_layer = true if l.name.include?("Z_Edge") && l.visible? }
        model.layers.each { |l| l.visible = true if l.name.include?("Z_Edge") && edge_layer == false }
        face_layer = false
        model.layers.each { |l| face_layer = true if l.name.include?("Z_Face") && l.visible? }
        model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") && face_layer == false }

        # (removed: p "load")

        if Sketchup.version_number >= 2110000000
          essence_comp = model.definitions.load(PATH + "/additions/Essence.skp", allow_newer: true)
        else
          essence_comp = model.definitions.load PATH + "/additions/Essence.skp"
        end

        t = Geom::Transformation.translation [0, 0, 0]
        essence_instance = entity.definition.entities.add_instance essence_comp, t
        essence_instance.material = entity.material
        redraw_size(essence_instance)

        groove_comp = []
        groove_edges = []
        entity.definition.entities.each { |ent|
          if ent.is_a?(Sketchup::Group)
            ent.erase! if !ent.name.include?("_SUF")
          elsif ent.is_a?(Sketchup::ComponentInstance) && ent.get_attribute("dynamic_attributes", "_groove")
            groove_comp << ent
          elsif ent.is_a?(Sketchup::Edge) && ent.get_attribute("dynamic_attributes","edge")
            groove_edges << [ent.start,ent.end,ent.hidden?,ent.attribute_dictionary("dynamic_attributes").to_h]
          else
            ent.erase! if ent != essence_instance
          end
        }

        essence_instance.explode

        if groove_edges != []
          groove_edges.each { |edge_arr|
            edges = entity.definition.entities.add_edges(edge_arr[0],edge_arr[1])
            edges[0].hidden = edge_arr[2]
            edge_arr[3].each_pair { |key,value|
              edges[0].set_attribute("dynamic_attributes",key,value)
            }
          }
        end

        @down_edge  = nil
        @up_edge    = nil
        @front_edge = nil
        @back_edge  = nil

        entity.definition.entities.grep(Sketchup::Face).each { |f|
          if groove_comp != []
            groove_comp.each {|comp|
              if f.bounds.center.x == comp.transformation.origin.x
                comp.definition.behavior.is2d = true
                comp.definition.behavior.snapto = SnapTo_Arbitrary
                comp.definition.behavior.cuts_opening = true
                comp.glued_to = f
              end
            }

            if f.edges.all?{|e|e.get_attribute("dynamic_attributes","edge")}
              f.erase!
              next
            end
          end

          face = f.get_attribute("dynamic_attributes", "face", "0")
          if face.include?("primary")
            f.edges.each {|e|
              if e.start.position.x != 0 && e.end.position.x != 0
                if e.line[1][1].round == 1
                  if e.start.position.z == 0 
                    @down_edge = e
                    @down_start = e.start.position
                    @down_end = e.end.position
                  else
                    @up_edge = e
                    @up_start = e.start.position
                    @up_end = e.end.position
                  end
                elsif e.line[1][2].round == 1
                  if e.start.position.y == 0
                    @front_edge = e
                    @front_start = e.start.position
                    @front_end = e.end.position
                  else
                    @back_edge = e
                    @back_start = e.start.position
                    @back_end = e.end.position
                  end
                end
              end
            }
          end
        }

        model.definitions.to_a.each { |definition|
          model.definitions.remove(definition) if definition.name.include?("Essence") && definition.count_used_instances == 0
        }

        if @v1_type.to_s == "1" && @v2_type.to_s == "1" && @v3_type.to_s == "1" && @v4_type.to_s == "1"
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
          return 1

        elsif @v1_type.to_s != "1" && s[2].to_f.round(2) > (@lenz*2.54).round(2) ||
              @v2_type.to_s != "1" && s[5].to_f.round(2) > (@lenz*2.54).round(2) ||
              @v3_type.to_s != "1" && s[8].to_f.round(2) > (@lenz*2.54).round(2) ||
              @v4_type.to_s != "1" && s[11].to_f.round(2) > (@lenz*2.54).round(2)

          UI.messagebox(SUF_STRINGS["Cutout length/radius exceeds part length!"])
          set_att_default(entity)
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
          return 1

        elsif @v1_type.to_s == "4" && s[3].to_f.round(2) > (@leny*2.54).round(2) ||
              @v1_type.to_s == "5" && s[3].to_f.round(2) > (@leny*2.54).round(2) ||
              @v2_type.to_s == "4" && s[6].to_f.round(2) > (@leny*2.54).round(2) ||
              @v2_type.to_s == "5" && s[6].to_f.round(2) > (@leny*2.54).round(2) ||
              @v3_type.to_s == "4" && s[9].to_f.round(2) > (@leny*2.54).round(2) ||
              @v3_type.to_s == "5" && s[9].to_f.round(2) > (@leny*2.54).round(2) ||
              @v4_type.to_s == "4" && s[12].to_f.round(2) > (@leny*2.54).round(2) ||
              @v4_type.to_s == "5" && s[12].to_f.round(2) > (@leny*2.54).round(2)

          UI.messagebox(SUF_STRINGS["Cutout width exceeds part width!"])
          set_att_default(entity)
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
          return 1

        elsif @v1_type.to_s != "1" && @v2_type.to_s != "1" && s[2].to_f.round(2) + s[5].to_f.round(2) > (@lenz*2.54).round(2) ||
              @v3_type.to_s != "1" && @v4_type.to_s != "1" && s[8].to_f.round(2) + s[11].to_f.round(2) > (@lenz*2.54).round(2)

          UI.messagebox(SUF_STRINGS["Cutouts length/radius exceeds part length!"])
          set_att_default(entity)
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
          return 1

        elsif (@v1_type.to_s == "4" || @v1_type.to_s == "5") && (@v3_type.to_s == "4" || @v3_type.to_s == "5") && s[3].to_f.round(2) + s[9].to_f.round(2) > (@leny*2.54).round(2) ||
              (@v2_type.to_s == "4" || @v2_type.to_s == "5") && (@v4_type.to_s == "4" || @v4_type.to_s == "5") && s[6].to_f.round(2) + s[12].to_f.round(2) > (@leny*2.54).round(2) ||
              (@v1_type.to_s == "2" || @v1_type.to_s == "3") && (@v3_type.to_s == "2" || @v3_type.to_s == "3") && s[2].to_f.round(2) + s[8].to_f.round(2) > (@leny*2.54).round(2) ||
              (@v2_type.to_s == "2" || @v2_type.to_s == "3") && (@v4_type.to_s == "2" || @v4_type.to_s == "3") && s[5].to_f.round(2) + s[11].to_f.round(2) > (@leny*2.54).round(2)

          UI.messagebox(SUF_STRINGS["Cutouts width exceeds part width!"])
          set_att_default(entity)
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
          model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
          return 1

        else
          @faces = []
          @rad_nar_edges = []

          cut_rad_nar(entity,1) if @v1_type.to_i == 2
          cut_rad_vn(entity,1)  if @v1_type.to_i == 3
          cut_skos(entity,1)    if @v1_type.to_i == 4
          cut_ugol(entity,1)    if @v1_type.to_i == 5

          cut_rad_nar(entity,2) if @v2_type.to_i == 2
          cut_rad_vn(entity,2)  if @v2_type.to_i == 3
          cut_skos(entity,2)    if @v2_type.to_i == 4
          cut_ugol(entity,2)    if @v2_type.to_i == 5

          cut_rad_nar(entity,3) if @v3_type.to_i == 2
          cut_rad_vn(entity,3)  if @v3_type.to_i == 3
          cut_skos(entity,3)    if @v3_type.to_i == 4
          cut_ugol(entity,3)    if @v3_type.to_i == 5

          cut_rad_nar(entity,4) if @v4_type.to_i == 2
          cut_rad_vn(entity,4)  if @v4_type.to_i == 3
          cut_skos(entity,4)    if @v4_type.to_i == 4
          cut_ugol(entity,4)    if @v4_type.to_i == 5

          pushpull_faces

          if @rad_nar_edges != []
            for rad_edge in @rad_nar_edges
              edges = rad_edge.all_connected
              edges.grep(Sketchup::Edge).each { |edge|
                if edge.start.position == rad_edge.start.position || edge.start.position == rad_edge.end.position || edge.end.position == rad_edge.start.position || edge.end.position == rad_edge.end.position
                  if edge.start.position.x == 0 || edge.end.position.x == 0
                    edge.soft = true
                  end
                end
              }
            end
          end

          entity.definition.entities.grep(Sketchup::Face).each { |f|
            f.layer = "Z_Edge" if f.normal.x.abs != 1
          }
          entity.definition.entities.grep(Sketchup::Edge).each { |e|
            e.layer = "Z_Edge"
          }
        end

        model.layers.each { |l| l.visible = false if l.name.include?("Z_Edge") && edge_layer == false }
        model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") && face_layer == false }
        return [@v1_type,@v2_type,@v3_type,@v4_type].to_s

      else
        return 0
      end
    end

      def redraw_size(entity,is_recursive_call=false)
				dc = $dc_observers.get_latest_class
				if is_recursive_call == false
					dc.has_behaviors(entity)
        end
				if entity.is_a?(Sketchup::ComponentInstance)
					dc.make_unique_if_needed(entity)
					subentities = entity.definition.entities
					else
					subentities = entity.entities
        end
				definition_origin = Geom::Point3d.new(0,0,0)
				xscale,yscale,zscale = entity.last_scaling_factors
				scale_transform = Geom::Transformation.scaling definition_origin,
				1.0/entity.transformation.xscale,
				1.0/entity.transformation.yscale,
				1.0/entity.transformation.zscale
				entity.transformation = entity.transformation * scale_transform
				start_lenx,start_leny,start_lenz = entity.unscaled_size
				nominal_lenx = dc.get_attribute_value(entity,'lenx').to_f
				nominal_leny = dc.get_attribute_value(entity,'leny').to_f
				nominal_lenz = dc.get_attribute_value(entity,'lenz').to_f
				nominal_lenx = dc.second_if_nan(nominal_lenx,0.0)
				nominal_leny = dc.second_if_nan(nominal_leny,0.0)
				nominal_lenz = dc.second_if_nan(nominal_lenz,0.0)
				new_lenx = nominal_lenx * xscale
				new_leny = nominal_leny * yscale
				new_lenz = nominal_lenz * zscale
				dc.store_nominal_size(entity,new_lenx,new_leny,new_lenz)
				target_lenx = dc.second_if_empty(dc.get_formula_result(entity,'lenx'), new_lenx).to_f
				target_leny = dc.second_if_empty(dc.get_formula_result(entity,'leny'), new_leny).to_f
				target_lenz = dc.second_if_empty(dc.get_formula_result(entity,'lenz'), new_lenz).to_f
				dc.store_nominal_size(entity,target_lenx,target_leny,target_lenz)
				dc.run_all_formulas(entity)
				dc.fix_float(nominal_lenx) == 0.0 ? dlenx = 1.0 : dlenx = target_lenx/nominal_lenx
				dc.fix_float(nominal_leny) == 0.0 ? dleny = 1.0 : dleny = target_leny/nominal_leny
				dc.fix_float(nominal_lenz) == 0.0 ? dlenz = 1.0 : dlenz = (target_lenz/nominal_lenz)
				dlenx = 0.001 if dlenx == 0.0
				dleny = 0.001 if dleny == 0.0
				dlenz = 0.001 if dlenz == 0.0
				subentity_transform = Geom::Transformation.scaling definition_origin, dlenx, dleny, dlenz
				if dlenx != 1.0 || dleny != 1.0 || dlenz != 1.0
					naked_entities = []
					subentities.each { |subentity|
						if subentity.is_a?(Sketchup::ComponentInstance) ||subentity.is_a?(Sketchup::Group)
							subentity.transform! subentity_transform
							elsif subentity.is_a?(Sketchup::Face)
              naked_entities.push subentity
              face = subentity.get_attribute("dynamic_attributes", "face", "0")
              if face.include?("primary")
                subentity.material = entity.material
              end
              elsif subentity.is_a?(Sketchup::Edge)
							naked_entities.push subentity
            end
          }
					if naked_entities.length > 0
						subentities.transform_entities subentity_transform, naked_entities
          end
        end
				if entity.is_a?(Sketchup::ComponentInstance)
					entity.definition.invalidate_bounds
        end
				new_lenx = dc.second_if_empty(dc.get_forced_config_value(entity, 'lenx'),new_lenx)
				new_leny = dc.second_if_empty(dc.get_forced_config_value(entity, 'leny'),new_leny)
				new_lenz = dc.second_if_empty(dc.get_forced_config_value(entity, 'lenz'),new_lenz)
				dc.clear_forced_config_values(entity)
				lenx,leny,lenz = entity.unscaled_size
				if lenx == start_lenx && xscale != 1.0
					new_lenx = lenx
        end
				if leny == start_leny && yscale != 1.0
					new_leny = leny
        end
				if lenz == start_lenz && zscale != 1.0
					new_lenz = lenz
        end
				dc.store_nominal_size(entity,new_lenx,new_leny,new_lenz)
				entity.set_last_size(lenx,leny,lenz)
      end
      def set_att_default(entity)
        parent = entity.parent
        parent = parent.instances[-1].parent if parent.name.include?("Body")
        parent.instances[-1].set_attribute("dynamic_attributes", "_onclick_state1", 0)
        parent.instances[-1].set_attribute("dynamic_attributes", "v1_cut_type", 1)
        parent.set_attribute("dynamic_attributes", "v1_cut_type", 1)
        parent.instances[-1].set_attribute("dynamic_attributes", "v2_cut_type", 1)
        parent.set_attribute("dynamic_attributes", "v2_cut_type", 1)
        parent.instances[-1].set_attribute("dynamic_attributes", "v3_cut_type", 1)
        parent.set_attribute("dynamic_attributes", "v3_cut_type", 1)
        parent.instances[-1].set_attribute("dynamic_attributes", "v4_cut_type", 1)
        parent.set_attribute("dynamic_attributes", "v4_cut_type", 1)
      end#def
			def cut_rad_nar(entity,pos)
        if pos.to_s == "1"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v1_size_length)
          vector2 = Geom::Vector3d.new(0, @v1_size_length, 0)
          vector3 = Geom::Vector3d.new(0, -@v1_size_length, 0)
          edge1 = entity.definition.entities.add_line @front_start,@front_start+vector1
          @v1_size_length < 11.8 ? segments = 12 : segments = 36
          edges = entity.definition.entities.add_arc @front_start+vector1+vector2, vector3, vector, @v1_size_length, 0, 90.degrees, segments
          edge2 = edges.first
          @rad_nar_edges << edges[0]
          @rad_nar_edges << edges[-1]
          elsif pos.to_s == "2"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v2_size_length)
          vector2 = Geom::Vector3d.new(0, @v2_size_length, 0)
          vector3 = Geom::Vector3d.new(0, 0, @v2_size_length)
          edge1 = entity.definition.entities.add_line @front_end,@front_end-vector1
          @v2_size_length < 11.8 ? segments = 12 : segments = 36
          edges = entity.definition.entities.add_arc @front_end-vector1+vector2, vector3, vector, @v2_size_length, 0, 90.degrees, segments
          edge2 = edges.first
          @rad_nar_edges << edges[0]
          @rad_nar_edges << edges[-1]
          elsif pos.to_s == "3"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v3_size_length)
          vector2 = Geom::Vector3d.new(0, @v3_size_length, 0)
          vector3 = Geom::Vector3d.new(0, 0, -@v3_size_length)
          edge1 = entity.definition.entities.add_line @back_start,@back_start+vector1
          @v3_size_length < 11.8 ? segments = 12 : segments = 36
          edges = entity.definition.entities.add_arc @back_start+vector1-vector2, vector3, vector, @v3_size_length, 0, 90.degrees, segments
          edge2 = edges.first
          @rad_nar_edges << edges[0]
          @rad_nar_edges << edges[-1]
          elsif pos.to_s == "4"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v4_size_length)
          vector2 = Geom::Vector3d.new(0, @v4_size_length, 0)
          vector3 = Geom::Vector3d.new(0, @v4_size_length, 0)
          edge1 = entity.definition.entities.add_line @back_end,@back_end-vector1
          @v4_size_length < 11.8 ? segments = 12 : segments = 36
          edges = entity.definition.entities.add_arc @back_end-vector1-vector2, vector3, vector, @v4_size_length, 0, 90.degrees, segments
          edge2 = edges.first
          @rad_nar_edges << edges[0]
          @rad_nar_edges << edges[-1]
        end
        face = edge1.common_face edge2
        @faces << face
      end#def
      def cut_rad_vn(entity,pos)
        if pos.to_s == "1"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v1_size_length)
          vector2 = Geom::Vector3d.new(0, @v1_size_length, 0)
          edge1 = entity.definition.entities.add_line @front_start,@front_start+vector1
          edges = entity.definition.entities.add_arc @front_start, vector2, vector, @v1_size_length, 0, 90.degrees, 36
          edge2 = edges.first
          elsif pos.to_s == "2"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v2_size_length)
          vector2 = Geom::Vector3d.new(0, 0, -@v2_size_length)
          edge1 = entity.definition.entities.add_line @front_end,@front_end-vector1
          edges = entity.definition.entities.add_arc @front_end, vector2, vector, @v2_size_length, 0, 90.degrees, 36
          edge2 = edges.first
          elsif pos.to_s == "3"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v3_size_length)
          vector2 = Geom::Vector3d.new(0, 0, @v3_size_length)
          edge1 = entity.definition.entities.add_line @back_start,@back_start+vector1
          edges = entity.definition.entities.add_arc @back_start, vector2, vector, @v3_size_length, 0, 90.degrees, 36
          edge2 = edges.first
          elsif pos.to_s == "4"
          vector = Geom::Vector3d.new(1, 0, 0).normalize!
          vector1 = Geom::Vector3d.new(0, 0, @v4_size_length)
          vector2 = Geom::Vector3d.new(0, -@v4_size_length, 0)
          edge1 = entity.definition.entities.add_line @back_end,@back_end-vector1
          edges = entity.definition.entities.add_arc @back_end, vector2, vector, @v4_size_length, 0, 90.degrees, 36
          edge2 = edges.first
        end
        face = edge1.common_face edge2
        @faces << face
      end#def
      def cut_skos(entity,pos)
        if pos.to_s == "1"
          vector1 = Geom::Vector3d.new(0, 0, @v1_size_length)
          vector2 = Geom::Vector3d.new(0, @v1_size_width, 0)
          edge1 = entity.definition.entities.add_line @front_start,@front_start+vector1
          edge2 = entity.definition.entities.add_line @front_start+vector1,@down_start+vector2
          elsif pos.to_s == "2"
          vector1 = Geom::Vector3d.new(0, 0, @v2_size_length)
          vector2 = Geom::Vector3d.new(0, @v2_size_width, 0)
          edge1 = entity.definition.entities.add_line @front_end,@front_end-vector1
          edge2 = entity.definition.entities.add_line @front_end-vector1,@up_start+vector2
          elsif pos.to_s == "3"
          vector1 = Geom::Vector3d.new(0, 0, @v3_size_length)
          vector2 = Geom::Vector3d.new(0, @v3_size_width, 0)
          edge1 = entity.definition.entities.add_line @back_start,@back_start+vector1
          edge2 = entity.definition.entities.add_line @back_start+vector1,@down_end-vector2
          elsif pos.to_s == "4"
          vector1 = Geom::Vector3d.new(0, 0, @v4_size_length)
          vector2 = Geom::Vector3d.new(0, @v4_size_width, 0)
          edge1 = entity.definition.entities.add_line @back_end,@back_end-vector1
          edge2 = entity.definition.entities.add_line @back_end-vector1,@up_end-vector2
        end
        face = edge1.common_face edge2
        @faces << face
      end#def
      def cut_ugol(entity,pos)
        if pos.to_s == "1"
          vector1 = Geom::Vector3d.new(0, 0, @v1_size_length)
          vector2 = Geom::Vector3d.new(0, @v1_size_width, 0)
          edge1 = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_width,@front_start+vector1+@offset_vector1_length+@offset_vector1_width
          edge2 = entity.definition.entities.add_line @front_start+vector1+@offset_vector1_length+@offset_vector1_width,@front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_width
          edge3 = entity.definition.entities.add_line @front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_width,@down_start+vector2+@offset_vector1_length+@offset_vector1_width
          edge4 = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_width,@front_start+vector2+@offset_vector1_length+@offset_vector1_width
          
          if entity.parent.get_attribute("dynamic_attributes", "v1_z_copy",0).to_f == 2 || entity.parent.get_attribute("dynamic_attributes", "v1_z_copy",0).to_f == 3
            v1_z_copy1_pos = entity.parent.get_attribute("dynamic_attributes", "v1_z_copy1_pos")
            @offset_vector1_copy_length = Geom::Vector3d.new(0, 0, (v1_z_copy1_pos ? v1_z_copy1_pos.to_f : 0))+vector1
            edge1_copy = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector1+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge2_copy = entity.definition.entities.add_line @front_start+vector1+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge3_copy = entity.definition.entities.add_line @front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@down_start+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge4_copy = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge2_copy.find_faces
            face = nil
            entity.definition.entities.grep(Sketchup::Face).each { |f| face = f if f.edges.include?(edge1_copy) && f.edges.include?(edge2_copy) && f.edges.include?(edge3_copy) && f.edges.include?(edge4_copy) }
            @faces << face if face
          end
          
          if entity.parent.get_attribute("dynamic_attributes", "v1_z_copy",0).to_f == 3
            v1_z_copy2_pos = entity.parent.get_attribute("dynamic_attributes", "v1_z_copy2_pos")
            @offset_vector1_copy_length += Geom::Vector3d.new(0, 0, (v1_z_copy2_pos ? v1_z_copy2_pos.to_f : 0))+vector1
            edge1_copy = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector1+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge2_copy = entity.definition.entities.add_line @front_start+vector1+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge3_copy = entity.definition.entities.add_line @front_start+vector1+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@down_start+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge4_copy = entity.definition.entities.add_line @front_start+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width,@front_start+vector2+@offset_vector1_length+@offset_vector1_copy_length+@offset_vector1_width
            edge2_copy.find_faces
            face = nil
            entity.definition.entities.grep(Sketchup::Face).each { |f| face = f if f.edges.include?(edge1_copy) && f.edges.include?(edge2_copy) && f.edges.include?(edge3_copy) && f.edges.include?(edge4_copy) }
            @faces << face if face
          end
          
          elsif pos.to_s == "2"
          vector1 = Geom::Vector3d.new(0, 0, @v2_size_length)
          vector2 = Geom::Vector3d.new(0, @v2_size_width, 0)
          edge1 = entity.definition.entities.add_line @front_end-@offset_vector2_length+@offset_vector2_width,@front_end-vector1-@offset_vector2_length+@offset_vector2_width
          edge2 = entity.definition.entities.add_line @front_end-vector1-@offset_vector2_length+@offset_vector2_width,@front_end-vector1+vector2-@offset_vector2_length+@offset_vector2_width
          edge3 = entity.definition.entities.add_line @front_end-vector1+vector2-@offset_vector2_length+@offset_vector2_width,@up_start+vector2-@offset_vector2_length+@offset_vector2_width
          edge4 = entity.definition.entities.add_line @front_end-@offset_vector2_length+@offset_vector2_width,@front_end+vector2-@offset_vector2_length+@offset_vector2_width
          
          elsif pos.to_s == "3"
          vector1 = Geom::Vector3d.new(0, 0, @v3_size_length)
          vector2 = Geom::Vector3d.new(0, @v3_size_width, 0)
          edge1 = entity.definition.entities.add_line @back_start+@offset_vector3_length-@offset_vector3_width,@back_start+vector1+@offset_vector3_length-@offset_vector3_width
          edge2 = entity.definition.entities.add_line @back_start+vector1+@offset_vector3_length-@offset_vector3_width,@back_start+vector1-vector2+@offset_vector3_length-@offset_vector3_width
          edge3 = entity.definition.entities.add_line @back_start+vector1-vector2+@offset_vector3_length-@offset_vector3_width,@down_end-vector2+@offset_vector3_length-@offset_vector3_width
          edge4 = entity.definition.entities.add_line @back_start+@offset_vector3_length-@offset_vector3_width,@back_start-vector2+@offset_vector3_length-@offset_vector3_width
          
          elsif pos.to_s == "4"
          vector1 = Geom::Vector3d.new(0, 0, @v4_size_length)
          vector2 = Geom::Vector3d.new(0, @v4_size_width, 0)
          edge1 = entity.definition.entities.add_line @back_end-@offset_vector4_length-@offset_vector4_width,@back_end-vector1-@offset_vector4_length-@offset_vector4_width
          edge2 = entity.definition.entities.add_line @back_end-vector1-@offset_vector4_length-@offset_vector4_width,@back_end-vector1-vector2-@offset_vector4_length-@offset_vector4_width
          edge3 = entity.definition.entities.add_line @back_end-vector1-vector2-@offset_vector4_length-@offset_vector4_width,@up_end-vector2-@offset_vector4_length-@offset_vector4_width
          edge4 = entity.definition.entities.add_line @back_end-@offset_vector4_length-@offset_vector4_width,@back_end-vector2-@offset_vector4_length-@offset_vector4_width
        end
        edge2.find_faces
        face = nil
        entity.definition.entities.grep(Sketchup::Face).each { |f| face = f if f.edges.include?(edge1) && f.edges.include?(edge2) && f.edges.include?(edge3) && f.edges.include?(edge4) }
        @faces << face if face
      end#def
      def pushpull_faces
        for face in @faces
          face.pushpull(-1*@lenx,false)
        end
      end#def
    end#unless
		protected:cutout
    
		unless DCFunctionsV1.method_defined?(:edgemat)
			def edgemat(s)
        return 0 if @source_entity.hidden?
        mat_names = []
        Sketchup.active_model.materials.each { |m| mat_names << m.name.downcase }
        @mat_suf = s[4]
        @edgemat_up = edge_material(Sketchup.active_model.materials,mat_names,s[0],"edge_y1")
        @edgemat_down = edge_material(Sketchup.active_model.materials,mat_names,s[1],"edge_y2")
        @edgemat_front = edge_material(Sketchup.active_model.materials,mat_names,s[2],"edge_z1")
        @edgemat_rear = edge_material(Sketchup.active_model.materials,mat_names,s[3],"edge_z2")
        @lenx = @source_entity.get_attribute("dynamic_attributes", "lenx")
        @leny = @source_entity.get_attribute("dynamic_attributes", "leny")
        @lenz = @source_entity.get_attribute("dynamic_attributes", "lenz")
        @source_entity.definition.entities.grep(Sketchup::Face).each { |f|
          face = f.get_attribute("dynamic_attributes", "face", "0")
          if face == "up" then f.material = @edgemat_up; f.back_material = @edgemat_up end
          if face == "down" then f.material = @edgemat_down; f.back_material = @edgemat_down end
          if face == "front" then f.material = @edgemat_front; f.back_material = @edgemat_front end 
          if face == "rear" then f.material = @edgemat_rear; f.back_material = @edgemat_rear end
          align_material(f) if face != "0" && !face.include?("primary") && f.material && f.material.texture
        }
        return 1
      end#def
      def edge_material(materials,mat_names,edge,att)
        edge.index("_",-5) ? ind = edge.index("_",-5)-1 : ind = -1
        if edge == "0" || !mat_names.any?{|m|m.include?(edge[0..ind].downcase)}
          return nil
          else
          @att = att
          @attribute = nil
          parent_ent(@source_entity) if !@mat_suf
          edge_thick = edge_thickness(@attribute.to_s)
          if mat_names.include?((edge[0..ind]+edge_thick).downcase)
            edge_mat = materials[edge[0..ind]+edge_thick]
            else
            edge_mat = materials.add(edge[0..ind]+edge_thick)
            mat_names << edge_mat.display_name.downcase
          end
          info_mat = materials.detect { |m| m.display_name.downcase.include?(edge[0..ind].downcase) }
          if info_mat
            if info_mat.name != edge_mat.name
              if info_mat.texture
                edge_mat.texture = info_mat.texture.image_rep
                mat_width= info_mat.texture.image_width
                mat_height= info_mat.texture.image_height
                edge_mat.texture.size= [mat_width.to_f.mm, mat_height.to_f.mm]
                else
                edge_mat.color = info_mat.color
              end
            end
          end
          return edge_mat
        end
        return nil
      end#def
      def edge_thickness(attribute)
        case attribute
          when "1" then edge_thick = ""
          when "2" then edge_thick = "_0.4"
          when "3" then edge_thick = "_0.4"
          when "4" then edge_thick = "_1.0"
          when "5" then edge_thick = "_1.0"
          when "6" then edge_thick = "_2.0"
          when "7" then edge_thick = "_2.0"
          else edge_thick = ""
        end
        return edge_thick
      end#def
    end#unless
		protected:edgemat
		
		unless DCFunctionsV1.method_defined?(:frontmat)
			def frontmat(s)
        return 0 if @source_entity.hidden?
        mat_names = []
        Sketchup.active_model.materials.each { |m| mat_names << m.name.downcase }
        @mat = nil
        @mat = s[0]
        if @mat != nil && @mat != "0"
          @edgemat_front = edge_material(Sketchup.active_model.materials,mat_names,s[0],"edge_z1")
          @source_entity.definition.entities.grep(Sketchup::Face) { |f|
            face = f.get_attribute("dynamic_attributes", "face", "0")
            if @source_entity.material
              if f.material == nil
                f.material = @source_entity.material
                f.back_material = @source_entity.material
              end
            end
            if face == "front" then f.material = @edgemat_front; f.back_material = @edgemat_front end 
          }
        end
        return @mat
      end#def
    end#unless
		protected:frontmat
		
		unless DCFunctionsV1.method_defined?(:texturemat)
			def texturemat(s)
        return 0 if @source_entity.hidden?
        @random_texture = "yes"
        @model = Sketchup.active_model
        dict = @model.attribute_dictionary 'su_parameters'
        dict.each {|k,v| @random_texture = v.strip.split("=")[2] if k == "random_texture" } if dict
        mat_names = []
        Sketchup.active_model.materials.each { |m| mat_names << m.name.downcase }
        napr_texture = nil
        napr_texture = s[0]
        front_material = nil
        front_material = s[1] if mat_names.include?(s[1].to_s.downcase)
        back_material = nil
        back_material = s[2] if mat_names.include?(s[2].to_s.downcase)
        back_material = "White" if s[2] && s[2].start_with?("White")
        stripe_on_back = false
        stripe_on_back = true if s[2] && s[2].include?("stripe")
        random_panel_texture = "1"
        random_panel_texture = s[3] if s[3]
        back_side = "1"
        back_side = s[4] if s[4]
        stripe_width = 100/25.4
        stripe_width = s[5].to_f/2.54 if s[5]
        @lenx = @source_entity.get_attribute("dynamic_attributes", "lenx")
        @leny = @source_entity.get_attribute("dynamic_attributes", "leny")
        @lenz = @source_entity.get_attribute("dynamic_attributes", "lenz")
        @source_entity.definition.entities.grep(Sketchup::Edge).each { |e| e.erase! if e.get_attribute("dynamic_attributes", "stripe_edge") }
        stripe_face_pts = []
        @source_entity.definition.entities.grep(Sketchup::Face).each { |f|
          face = f.get_attribute("dynamic_attributes", "face", "0")
          f.material = nil if face == "0"
          f.back_material = nil if face == "0"
          if face.include?("primary")
            bounds_center = f.bounds.center.x.round(3)
            f.back_material = nil
            f.material = @source_entity.material 
            if front_material != nil
              if back_side == "1"
                f.material = front_material if bounds_center==@lenx.round(3)
                else
                f.material = front_material if bounds_center==0
              end
            end
            if back_material != nil
              if back_side == "1"
                if bounds_center==0
                  f.material = back_material
                  if stripe_on_back
                    pts = f.outer_loop.vertices.map { |vertex| vertex.position }
                    pts = pts.select {|pt| pt.y == 0 && pt.z == 0 || pt.y == 0 && pt.z == @lenz}
                    pt1 = Geom::Point3d.new(f.bounds.center.x,stripe_width,0)
                    pt2 = Geom::Point3d.new(f.bounds.center.x,stripe_width,@lenz)
                    stripe_pts = [pt1,pt2]
                    edges = @source_entity.definition.entities.add_edges stripe_pts
                    edges[0].find_faces
                    edges.each {|e| e.set_attribute("dynamic_attributes", "stripe_edge", true)}
                    stripe_pts += pts
                    stripe_face_pts << stripe_pts
                  end
                end
                else
                if bounds_center==@lenx.round(3)
                  f.material = back_material
                  if stripe_on_back
                    pts = f.outer_loop.vertices.map { |vertex| vertex.position }
                    pts = pts.select {|pt| pt.y == 0 && pt.z == 0 || pt.y == 0 && pt.z == @lenz}
                    pt1 = Geom::Point3d.new(f.bounds.center.x,stripe_width,0)
                    pt2 = Geom::Point3d.new(f.bounds.center.x,stripe_width,@lenz)
                    stripe_pts = [pt1,pt2]
                    edges = @source_entity.definition.entities.add_edges stripe_pts
                    edges[0].find_faces
                    edges.each {|e| e.set_attribute("dynamic_attributes", "stripe_edge", true)}
                    stripe_pts += pts
                    stripe_face_pts << stripe_pts
                  end
                end
              end
            end
            if f.material && f.material.texture
              if napr_texture == "1"
                align_material(f)
                depatternize(f) if @random_texture == "yes" && random_panel_texture == "1"
                else
                align_material(f)
                rotateTexture(f,90)
                depatternize(f) if @random_texture == "yes" && random_panel_texture == "1"
              end
            end
          end
        }
        if stripe_face_pts != []
          @source_entity.definition.entities.grep(Sketchup::Face).each { |f|
            vertices = f.outer_loop.vertices.map { |vertex| vertex.position }
            if stripe_face_pts.any? {|pts| pts.all? {|pt|vertices.include?(pt)}}
              f.material = front_material
            end
          }
        end
        
        groove_edges1 = []
        groove_edges2 = []
        @source_entity.definition.entities.grep(Sketchup::Edge).each { |e|
          if e.get_attribute("dynamic_attributes","edge")
            if e.get_attribute("dynamic_attributes","side") == 1
              groove_edges1 << e
              elsif e.get_attribute("dynamic_attributes","side") == 2
              groove_edges2 << e
            end
          end
        }
        if groove_edges1 != [] || groove_edges2 != []
          @glued_hash = {}
          @source_entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
            if ent.definition.get_attribute("dynamic_attributes","_groove")
              if ent.glued_to.is_a?(Sketchup::Face)
                @glued_hash[ent] = ent.glued_to.vertices.map{|v|v.position}
              end
            end
          }
          
          edges_arr1 = []
          edges1 = nil
          if groove_edges1 != []
            edges1,edges_arr1 = edges_arr(groove_edges1)
          end
          
          edges_arr2 = []
          edges2 = nil
          if groove_edges2 != []
            edges2,edges_arr2 = edges_arr(groove_edges2)
          end
          
          move_line(edges_arr1,edges1) if edges_arr1 != []
          move_line(edges_arr2,edges2) if edges_arr2 != []
          
          @glued_hash.each_pair { |ent,verts|
            if !ent.glued_to
              @source_entity.definition.entities.grep(Sketchup::Face).each { |f|
                if all_points_on_face(f,verts)
                  ent.glued_to = f
                end
              }
            end
          }
        end
        return 1
      end#def
			def edges_arr(groove_edges)
        edges_y_arr = []
        if groove_edges.all? { |e| e.start.position.y == groove_edges[0].start.position.y && e.end.position.y == groove_edges[0].start.position.y}
          edges_y_arr = groove_edges.select { |e| e if e.start.position.y == e.end.position.y}
        end
        edges_z_arr = []
        if groove_edges.all? { |e| e.start.position.z == groove_edges[0].start.position.z && e.end.position.z == groove_edges[0].start.position.z}
          edges_z_arr = groove_edges.select { |e| e if e.start.position.z == e.end.position.z}
        end
        if edges_y_arr.count > 2
          return 1,edges_y_arr.group_by { |e| e.start.position.z.round(2) < @lenz/2 }.values + edges_y_arr.group_by { |e| e.start.position.z.round(2) >= @lenz/2 }.values
          elsif edges_z_arr.count > 2
          return 2,edges_z_arr.group_by { |e| e.start.position.y.round(2) < @leny/2 }.values + edges_z_arr.group_by { |e| e.start.position.y.round(2) >= @leny/2 }.values
        end
        return nil,[]
      end#def
      def move_line(edges_array,edges)
        edges_array.each{|e_arr|
          groove_thick = 0   # должная толщина паза
          current_thick = 0  # текущая толщина паза
          groove_width = 0   # должная ширина паза
          current_width = 0  # текущая ширина паза
          e_arr.each{|e|
            if (e.start.position.x*25.4).round(2) == (e.end.position.x*25.4).round(2)
              if groove_width < e.start.position.distance(e.end.position)
                groove_width = e.get_attribute("dynamic_attributes","length","0").to_f
                current_width = e.start.position.distance(e.end.position)
              end
              else
              if groove_thick < e.start.position.distance(e.end.position)
                groove_thick = e.get_attribute("dynamic_attributes","length","0").to_f
                current_thick = e.start.position.distance(e.end.position)
              end
            end
          }
          
          if groove_width != 0 && groove_thick != 0
            if (groove_width*25.4).round(2) != (current_width*25.4).round(2)
              e_arr.each{|e|
                if (e.start.position.x*25.4).round(2) != (e.end.position.x*25.4).round(2)
                  if e.get_attribute("dynamic_attributes","koef")
                    koef = e.get_attribute("dynamic_attributes","koef")
                    if edges == 1
                      vector = Geom::Vector3d.new(0, 0, koef*(groove_width - current_width))
                      else
                      vector = Geom::Vector3d.new(0, koef*(groove_width - current_width), 0)
                    end
                    tr = Geom::Transformation.translation(vector)
                    @source_entity.definition.entities.transform_entities(tr,e)
                  end
                end
              }
            end
          end
        }
      end#def
      def all_points_on_face(face,points)
        points.all?{|pt|
          face.classify_point(pt) == Sketchup::Face::PointInside ||
          face.classify_point(pt) == Sketchup::Face::PointOnEdge ||
          face.classify_point(pt) == Sketchup::Face::PointOnVertex
        }
      end#def
      def align_material(f)
        achorPoint = f.edges[0].line[0]
        points = [achorPoint, [0,0,1]]
        f.position_material(f.material, points, true)
      end#def
      def rotateTexture(f,angle)
        tw = Sketchup.create_texture_writer
        uvh = f.get_UVHelper true, false, tw
        trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, angle * Math::PI / 180	#Define rotation
        pointPairs = []
        (0..1).each do |j|									# Loop some points around face
          point3d = f.outer_loop.vertices[j].position		#  Selet a 3d point
          point3dRotated = point3d.transform(trans)		#  Rotate 3d pont
          pointPairs << point3dRotated					#  Save model's 3d point to array
          point2d = uvh.get_front_UVQ(point3d)
          pointPairs << point2d							#  Save material's corresponding 2d point to array
        end#each
        f.position_material(f.material, pointPairs, true)
      end#def
      def depatternize(f)
        tw = Sketchup.create_texture_writer
        uvh = f.get_UVHelper true, false, tw
        vector = f.edges[0].line[1]							# Get a vector in the face's plane
        vector.length = Random.rand(f.material.texture.height+f.material.texture.width)							# Set random length (between 0 and materials height + width)
        trans = Geom::Transformation.rotation f.outer_loop.vertices[0].position, f.normal, Random.rand(Math::PI*2)	# Rotate vector randomly in plane
        vector.transform! trans
        trans = Geom::Transformation.translation vector		# Create translation, move point by vector
        pointPairs = []
        (0..1).each do |j|									# Loop some points around face
          point3d = f.outer_loop.vertices[j].position		#  Select a 3d point
          point3dRotated = point3d.transform(trans)		#  Move 3d point
          pointPairs << point3dRotated					#  Save model's 3d point to array
          point2d = uvh.get_front_UVQ(point3d)
          pointPairs << point2d							#  Save material's corresponding 2d point to array
        end#each
        f.position_material(f.material, pointPairs, true)	#Set material position (pair up model 3d points with texture 2d point)
      end#def
    end#unless
		protected:texturemat
		
		unless DCFunctionsV1.method_defined?(:swapcomponent)
			def swapcomponent(c)
        return 0 if @source_entity.hidden?
        model = Sketchup.active_model
        path = nil
        path = c[0].to_s
        if path[0..2] == "SUF"
          path = path[4..-1]
          elsif path[0..3] == "/SUF"
          path = path[5..-1]
        end
        path_component = File.join(PATH_COMP,path)
        name_component = path_component.split("/")[-1]
        swap = ""
        swap = c[1].to_s
        body_entity = false
        a00_lenx_formula = false
        a00_lenz_formula = false
        if swap != nil && swap != "" && swap != 0 && swap != "0" && File.file?(path_component)
          source_entity = @source_entity
          lenx = source_entity.get_attribute("dynamic_attributes", "lenx")
          leny = source_entity.get_attribute("dynamic_attributes", "leny")
          lenz = source_entity.get_attribute("dynamic_attributes", "lenz")
          _old_len = source_entity.definition.get_attribute("dynamic_attributes", "_old_len")
          _old_path = source_entity.definition.get_attribute("dynamic_attributes", "_old_path")
          vitr = source_entity.definition.get_attribute("dynamic_attributes", "vitr")
          _old_vitr = source_entity.definition.get_attribute("dynamic_attributes", "_old_vitr")
          if _old_len && _old_len == [lenx,leny,lenz] && _old_path && _old_path == path && _old_vitr == vitr
            return 0
            else
            dim_rotation = nil
            @dimensions = []
            search_dimensions(source_entity)
            @dim_param_arr = {}
            @dimensions.each { |entity| copy_dimension(entity) }
            a03_path = source_entity.definition.get_attribute("dynamic_attributes", "a03_path", "0")
            lenx_formula = source_entity.definition.get_attribute("dynamic_attributes", "_a00_lenx_formula")
            lenz_formula = source_entity.definition.get_attribute("dynamic_attributes", "_a00_lenz_formula")
            lengthunits = source_entity.get_attribute("dynamic_attributes", "_lengthunits")
            lengthunits = source_entity.definition.get_attribute("dynamic_attributes", "_lengthunits") if !lengthunits
            if lengthunits == "CENTIMETERS"
              att_lenx = lenx.to_cm.to_s
              att_lenz = lenz.to_cm.to_s
              else
              att_lenx = lenx.to_s
              att_lenz = lenz.to_s
            end
            if !lenx_formula
              source_entity.set_attribute("dynamic_attributes", "a00_lenx", att_lenx)
              source_entity.definition.set_attribute("dynamic_attributes", "a00_lenx", att_lenx)
              source_entity.definition.set_attribute("dynamic_attributes", "_a00_lenx_formula", att_lenx)
              else
              a00_lenx_formula = true
            end
            if !lenz_formula
              source_entity.set_attribute("dynamic_attributes", "a00_lenz", att_lenz)
              source_entity.definition.set_attribute("dynamic_attributes", "a00_lenz", att_lenz)
              source_entity.definition.set_attribute("dynamic_attributes", "_a00_lenz_formula", att_lenz)
              else
              a00_lenz_formula = true
            end
            
            name = source_entity.definition.get_attribute("dynamic_attributes", "_name", "0")
            entity = source_entity
            source_entity.definition.entities.grep(Sketchup::ComponentInstance) { |enx|
              if enx.definition.name.include?("Body")
                body_entity = true
                entity = enx
              end
            }
            @glass_material = nil
            entity.definition.entities.each { |enx|
              if enx.is_a?(Sketchup::ComponentInstance)
                if enx.definition.name.include?("Essence") || enx.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                  @v_edge = enx.definition.get_attribute("dynamic_attributes", "v_edge")
                  @color_ramka = enx.definition.get_attribute("dynamic_attributes", "color_ramka")
                  dim_rotation = enx.definition.get_attribute("dynamic_attributes", "dimensions")
                  enx.erase!
                  elsif enx.definition.name.include?("control_vitr")
                  enx.erase!
                  elsif a03_path.include?("Рамка") || a03_path.include?("рамка")
                  if enx.definition.name.include?("Glass") && !enx.hidden?
                    @glass_material = enx.material
                    enx.erase!
                  end
                  source_entity.set_attribute("dynamic_attributes", "a09_vitr", "1")
                  source_entity.definition.set_attribute("dynamic_attributes", "a09_vitr", "1")
                end
                else
                enx.erase!
              end
            }
            if Sketchup.version_number >= 2110000000
              new_comp = model.definitions.load(path_component, allow_newer: true)
              else
              new_comp = model.definitions.load path_component
            end
            t = Geom::Transformation.translation [0, 0, 0]
            new_comp_place = entity.definition.entities.add_instance new_comp, t
            new_comp_place.explode
            essences = []
            entity.definition.entities.grep(Sketchup::ComponentInstance) { |enx| 
              if enx.definition.name.include?("Essence") || enx.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                enx.make_unique
                enx.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
                essences << enx
                enx.set_attribute("dynamic_attributes", "v_edge", @v_edge) if @v_edge
                enx.definition.set_attribute("dynamic_attributes", "v_edge", @v_edge) if @v_edge
                enx.set_attribute("dynamic_attributes", "color_ramka", @color_ramka) if @color_ramka
                enx.definition.set_attribute("dynamic_attributes", "color_ramka", @color_ramka) if @color_ramka
                enx.definition.delete_attribute("dynamic_attributes", "_set_path_formula")
                target_hidden = $dc_observers.get_latest_class.get_formula_result(enx,'hidden')
                target_hidden = $dc_observers.get_latest_class.get_attribute_value(enx,'hidden') if !target_hidden
                if target_hidden && target_hidden.to_f > 0.0
                  enx.erase!
                  else
                  $dc_observers.get_latest_class.redraw(enx)
                end
                elsif enx.definition.name.include?("Glass") && !enx.hidden?
                if a03_path.include?("Рамка") || a03_path.include?("рамка")
                  enx.material = @glass_material if @glass_material
                end
                elsif enx.definition.name.include?("control_vitr")
                enx.erase! if !name.include?("Frontal")
              end
            }
            $dc_observers.get_latest_class.redraw(source_entity)
            essences.each { |essence| explode_essence(essence) if !path.include?("Slab") && !path.include?("Лоток") }
            if dim_rotation
              essences.each { |essence|
                new_dimension(essence)
                update_dimension(dim_rotation)
                essence.set_attribute("dynamic_attributes", "dimensions",dim_rotation.to_s)
                essence.definition.set_attribute("dynamic_attributes", "dimensions",dim_rotation.to_s)
                essence.definition.set_attribute("dynamic_attributes", "_dimensions_label","dimensions")
                essence.definition.set_attribute("dynamic_attributes", "_dimensions_formula", "update_dimension("+dim_rotation.to_s+")")
              }
            end
            
            if a00_lenx_formula == false
              source_entity.definition.delete_attribute("dynamic_attributes", "_a00_lenx_formula")
            end
            if a00_lenz_formula == false
              source_entity.definition.delete_attribute("dynamic_attributes", "_a00_lenz_formula")
            end
            source_entity.definition.set_attribute("dynamic_attributes", "_old_len", [lenx,leny,lenz])
            source_entity.definition.set_attribute("dynamic_attributes", "_old_path", path)
            source_entity.definition.set_attribute("dynamic_attributes", "_old_vitr", vitr)
          end
        end
        return (swap)
      end#def
      def search_dimensions(entity)
        if entity.is_a?(Sketchup::ComponentInstance)
          entity.definition.entities.grep(Sketchup::DimensionLinear).each{|e| @dimensions << e }
          entity.definition.entities.grep(Sketchup::ComponentInstance).each{|e| search_dimensions(e) }
        end
      end#def
      def copy_dimension(entity)
        @dim_param_arr = {
          :text => entity.text,
          :layer => entity.layer.name,
          :offset => entity.offset_vector,
          :dim_start => entity.start,
          :dim_end => entity.end
        }
      end
      def new_dimension(entity)
        dim = entity.definition.entities.add_dimension_linear(@dim_param_arr[:dim_start][1], @dim_param_arr[:dim_end][1], @dim_param_arr[:offset])
        dim.layer = @dim_param_arr[:layer]
        distance = @dim_param_arr[:dim_end][1].distance(@dim_param_arr[:dim_start][1])
        if distance*25.4 != @dim_param_arr[:text].to_f
          dim.text = @dim_param_arr[:text]
          dim.arrow_type = Sketchup::Dimension::ARROW_NONE
        end
      end#def
      def update_dimension(dim_rotation)
        redraw_dimension(@source_entity,dim_rotation[0])
        return dim_rotation[0]
      end
      def redraw_dimension(entity,dim_rotation)
        if !entity.hidden?
          lenx = entity.get_attribute("dynamic_attributes", "lenx", "0")
          leny = entity.get_attribute("dynamic_attributes", "leny", "0")
          lenz = entity.get_attribute("dynamic_attributes", "lenz", "0")
          result,error = $dc_observers.get_latest_class.get_formula_result(entity,"napr_texture")
          result,error = $dc_observers.get_latest_class.get_formula_result(entity,"texturemat") if !result
          if entity.parent.instances[-1].definition.name.include?("Body")
            panel = entity.parent.instances[-1].parent.instances[-1]
            else
            panel = entity.parent.instances[-1]
          end
          if panel.definition.get_attribute("dynamic_attributes", "a05_napr")
            napr_texture_att = "a05_napr"
            else
            napr_texture_att = "napr_texture"
          end
          napr_texture = panel.definition.get_attribute("dynamic_attributes", napr_texture_att)
          entity.definition.entities.grep(Sketchup::DimensionLinear).each {|dim|
            if dim_rotation=="1"
              dim.start = Geom::Point3d.new(dim.start[1].x,leny/2-1,lenz/2)
              dim.end = Geom::Point3d.new(dim.start[1].x,leny/2+1,lenz/2)
              else
              dim.start = Geom::Point3d.new(dim.start[1].x,leny/2,lenz/2-1)
              dim.end = Geom::Point3d.new(dim.start[1].x,leny/2,lenz/2+1)
            end
            if napr_texture == "1"
              dim.text = (lenz*25.4).round.to_s+"x"+(leny*25.4).round.to_s
              else
              dim.text = (leny*25.4).round.to_s+"x"+(lenz*25.4).round.to_s
            end
          }
        end
      end
      def explode_essence(e)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |enx|
          if enx.hidden?
            enx.erase!
            elsif !enx.definition.name.include?("Scaler")
            enx.explode
          end
        }
        e.definition.entities.grep(Sketchup::Edge) { |enx| enx.erase! if enx.hidden? }
        e.definition.entities.grep(Sketchup::Edge) { |enx|
          enx.erase! if enx.vertices.any? { |vertex| vertex.edges.count < 2 }
        }
        temp_edges = []
        e.definition.entities.grep(Sketchup::Edge) { |enx|
          enx.vertices.each { |vertex|
            if vertex.edges.count == 2
              v1 = vertex.edges[0].line[1]
              v2 = vertex.edges[1].line[1]
              if v1.parallel?(v2)
                pt1 = vertex.position
                pt2 = pt1.clone
                pt2.x += 0.01
                pt2.y += 0.01
                pt2.z += 0.01
                temp_edge = e.definition.entities.add_line( pt1, pt2 )
                temp_edges << temp_edge if temp_edge
              end
            end
          }
        }
        e.definition.entities.erase_entities(temp_edges) if !temp_edges.empty?
        e.definition.entities.grep(Sketchup::Face) { |enx|
          if enx.bounds.center.x==0 && (enx.normal.x+0.01).round(1).abs == 1 && enx.area>0.1 
            enx.set_attribute("dynamic_attributes", "face", "primary_back") 
          end
        }
      end#def
    end#unless
		protected:swapcomponent
		
    unless DCFunctionsV1.method_defined?(:update_dimension)
			def update_dimension(dim_rotation)
        redraw_dimension(@source_entity,dim_rotation[0])
        return dim_rotation[0]
      end
      def redraw_dimension(entity,dim_rotation)
        if !entity.hidden?
          lenx = entity.get_attribute("dynamic_attributes", "lenx", "0")
          leny = entity.get_attribute("dynamic_attributes", "leny", "0")
          lenz = entity.get_attribute("dynamic_attributes", "lenz", "0")
          result,error = $dc_observers.get_latest_class.get_formula_result(entity,"napr_texture")
          result,error = $dc_observers.get_latest_class.get_formula_result(entity,"texturemat") if !result
          if entity.parent.instances[-1].definition.name.include?("Body")
            panel = entity.parent.instances[-1].parent.instances[-1]
            else
            panel = entity.parent.instances[-1]
          end
          if panel.definition.get_attribute("dynamic_attributes", "a05_napr")
            napr_texture_att = "a05_napr"
            else
            napr_texture_att = "napr_texture"
          end
          napr_texture = panel.definition.get_attribute("dynamic_attributes", napr_texture_att)
          entity.definition.entities.grep(Sketchup::DimensionLinear).each {|dim|
            if dim_rotation=="1"
              dim.start = Geom::Point3d.new(dim.start[1].x,leny/2-1,lenz/2)
              dim.end = Geom::Point3d.new(dim.start[1].x,leny/2+1,lenz/2)
              else
              dim.start = Geom::Point3d.new(dim.start[1].x,leny/2,lenz/2-1)
              dim.end = Geom::Point3d.new(dim.start[1].x,leny/2,lenz/2+1)
            end
            if napr_texture == "1"
              dim.text = (lenz*25.4).round.to_s+"x"+(leny*25.4).round.to_s
              else
              dim.text = (leny*25.4).round.to_s+"x"+(lenz*25.4).round.to_s
            end
          }
        end
      end
    end#unless
		protected:update_dimension
    
		unless DCFunctionsV1.method_defined?(:swaptext)
			def swaptext(c)
        entity = @source_entity
        string = nil
        string = c[0].to_s
        font = text_font
        align = 2
        align = c[2]
        swap = ""
        swap = c[3].to_s
        split_text = nil
        split_text = c[4]
        max_width = []
        if string != nil && string != "" && swap != nil && swap != "" && swap != 0 && swap != "0"
          if split_text != nil && split_text.to_s != "0"
            if split_text.to_s == "2"
              string = replacetext(string,3)
              else
              string = replacetext(string,2)
            end
          end
          str_arr = string.split("/n").reverse
          count = str_arr.length
          entity.make_unique
          entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)  if entity.parent.is_a?(Sketchup::ComponentDefinition)
          entity.definition.entities.each { |enx| enx.erase! }
          for i in 0..count-1
            str = str_arr[i]
            leny = entity.definition.get_attribute("dynamic_attributes", "leny").to_f
            entity.definition.name = str
            entity.set_attribute("dynamic_attributes", "_name", str)
            entity.definition.set_attribute("dynamic_attributes", "_name", str)
            group=entity.definition.entities.add_group
            group.entities.add_3d_text(str, TextAlignCenter, font, false, false, leny/count-0.3, 0.0, 0.0, true, 0.0)
            #string,alignment,fontName,bold,italic,height,tolerance,baseZ,filled,extrusion
            comp=group.to_component
            comp.definition.entities.each { |face| face.reverse! if face.is_a?(Sketchup::Face) }
            bounds = comp.bounds
            proportion = bounds.width/bounds.height/count
            max_width << proportion
            case align
              when 1 then transform_x = 0
              when 2 then transform_x = -bounds.width/2
              when 3 then transform_x = -bounds.width
              else transform_x = 0
            end
            align_top = swap.to_i
            case align_top
              when 1 then transform_y = 0
              when 2 then transform_y = -bounds.height/2
              when 3 then transform_y = -bounds.height
              else transform_y = 0
            end
            comp.move!(Geom::Transformation.translation([transform_x, transform_y+leny/count*i, 0]))
            comp.explode
          end
          proportion_x = max_width.sort{|a, b| b <=> a} [0]
          entity.definition.set_attribute("dynamic_attributes", "_lenx_formula", 'LenY*' + proportion_x.to_s)
          entity.set_attribute("dynamic_attributes", "proportion", proportion_x)
          entity.definition.set_attribute("dynamic_attributes", "proportion", proportion_x)
          entity.definition.set_attribute("dynamic_attributes", "_proportion_label", "proportion")
          $dc_observers.get_latest_class.redraw(entity)
        end
        return (swap)
      end#def
      def replacetext(string,count)
        replaced_text = " "
        replacement_text = "/n"
        if string != nil
          if count == 3
            start1 = string.length/count
            start2 = string.length/count*2
            str1 = string[0..start1]
            str2 = string[start1+1..start2]
            str3 = string[start2+1..-1]
            search2 = str2.index(replaced_text)
            if search2
              str2 = str2.sub(replaced_text,replacement_text)
            end
            search3 = str3.index(replaced_text)
            if search3
              str3 = str3.sub(replaced_text,replacement_text)
            end
            string = str1+str2+str3
            else
            start = string.length/count
            str1 = string[0..start]
            str2 = string[start+1..-1]
            search = str2.index(replaced_text)
            if search
              str2 = str2.sub(replaced_text,replacement_text)
            end
            string = str1+str2
          end
        end
        return string
      end#def
    end#unless
		protected:swaptext
		
  end#class
end#if
