module SU_Furniture
	class ChangeAttributes
    def initialize
      @copied_att = {}
      @attributes_hash = {}
      @parent_array = []
      @checkbox_att = []
      @panel_sections = {}
      @shelve_sections = {}
      @drawer_sections = {}
      @accessory_sections = {}
      @frontal_sections = {}
    end
		def round_without_zero(value, z)
			value = value.round(z)
			if value.to_s.include?(".")
				while z > 0 && value.to_s[-1,1] == "0"
					z = z - 1
					value = value.round(z)
        end
      end
			return value
    end#def
    def att_list(ent,global_options,access_att)
      ent.set_attribute("dynamic_attributes", "_lengthunits", 'CENTIMETERS') if !ent.get_attribute("dynamic_attributes", "_lengthunits")
      dict = ent.definition.attribute_dictionary "dynamic_attributes"
      if dict #&& !ent.hidden?
        su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
        if su_type
          Redraw_Components.delete_cascading_attribute(ent,"su_type_layer") if ent.definition.get_attribute("dynamic_attributes", "su_type_layer")
          if su_type == "module"
            if ent.definition.get_attribute("dynamic_attributes", "hinge_z")
              if !ent.definition.get_attribute("dynamic_attributes", "hinge_type")
                set_att(ent,"hinge_type","1",nil,nil,nil,nil,nil,nil,"&")
              end
            end
            if !ent.definition.get_attribute("dynamic_attributes", "a04_itemcode") && ent.definition.get_attribute("dynamic_attributes", "itemcode")
              set_att(ent,"itemcode",ent.definition.get_attribute("dynamic_attributes", "itemcode"),nil,"TEXTBOX","Код изделия","STRING","STRING",nil,nil)
            end
            set_att(ent,"a09_su_type",su_type,"a09_su_type","NONE","Тип","STRING","STRING",nil,nil)
            elsif su_type =~ /furniture|handle|hinge|drawer|basket|bracket|leg|dryer|lift|holder|metal/i
            set_att(ent,"a09_su_type",su_type,"a09_su_type","LIST","Тип","STRING","STRING",nil,"&Фурнитура=furniture&Ручка=handle&Петля=hinge&Ящик=drawer&Корзина=basket&Навес=bracket&Опора=leg&Сушка=dryer&Подъемник=lift&Полкодержатель=holder&Металл=metal&")
            a09_su_type_layer = ent.definition.get_attribute("dynamic_attributes", "a09_su_type_layer")
            set_att(ent,"a09_su_type_layer",(a09_su_type_layer ? a09_su_type_layer : "9_Фурнитура"),"a09_su_type_layer","LIST","Слой","STRING","STRING",nil,"&4_Металл=4_Металл&9_Фурнитура=9_Фурнитура&")
            set_att(ent,"hole",ent.definition.get_attribute("dynamic_attributes", "hole", "yes"),"hole","LIST","Сверлить отверстия","STRING","STRING",nil,"&Нет=no&Да=yes&")
            elsif su_type =~ /frontal|carcass|back|glass/i
            set_att(ent,"a09_su_type",su_type,"a09_su_type","LIST","Тип","STRING","STRING",nil,"&Фасад=frontal&Каркас=carcass&Задняя_стенка=back&Стекло=glass&Металл=metal&")
            layer_options = "&1_Фасад=1_Фасад&1_Фасад_ящика=1_Фасад_ящика&2_Стекло=2_Стекло&3_Каркас=3_Каркас&3_Каркас_ящика=3_Каркас_ящика&4_Задняя_стенка=4_Задняя_стенка&4_Металл=4_Металл&"
            ent.definition.set_attribute("dynamic_attributes", "_a09_su_type_layer_options", layer_options)
            else
            set_att(ent,"a09_su_type",su_type,"a09_su_type","VIEW","Тип","STRING","STRING",nil,nil)
          end
          ent.definition.set_attribute("dynamic_attributes", "_su_type_formula", "a09_su_type")
        end
        if ent.definition.get_attribute("dynamic_attributes", "su_info")
          if ent.definition.get_attribute("dynamic_attributes", "a00_lenx") && ent.definition.get_attribute("dynamic_attributes", "_a00_lenx_access", "VIEW") == "VIEW"
            set_att(ent,"a00_lenx",ent.definition.get_attribute("dynamic_attributes", "a00_lenx"),"a00_lenx","TEXTBOX",nil,"CENTIMETERS","MILLIMETERS",nil,nil)
          end
          if ent.definition.get_attribute("dynamic_attributes", "a00_leny") && ent.definition.get_attribute("dynamic_attributes", "_a00_leny_access", "VIEW") == "VIEW"
            set_att(ent,"a00_leny",ent.definition.get_attribute("dynamic_attributes", "a00_leny"),"a00_leny","TEXTBOX",nil,"CENTIMETERS","MILLIMETERS",nil,nil)
          end
          if ent.definition.get_attribute("dynamic_attributes", "a00_lenz") && ent.definition.get_attribute("dynamic_attributes", "_a00_lenz_access", "VIEW") == "VIEW"
            set_att(ent,"a00_lenz",ent.definition.get_attribute("dynamic_attributes", "a00_lenz"),"a00_lenz","TEXTBOX",nil,"CENTIMETERS","MILLIMETERS",nil,nil)
          end
          if ent.definition.get_attribute("dynamic_attributes", "max_width_of_count") && ent.definition.get_attribute("dynamic_attributes", "_max_width_of_count_access", "NONE") == "NONE"
            set_att(ent,"max_width_of_count",ent.definition.get_attribute("dynamic_attributes", "max_width_of_count").to_s,"max_width_of_count","TEXTBOX","Макс. длина для расчета количества (в метрах)","STRING","STRING",nil,nil)
          end
        end
        if !ent.definition.get_attribute("dynamic_attributes", "a00_lenx") && !ent.definition.get_attribute("dynamic_attributes", "a00_leny") && !ent.definition.get_attribute("dynamic_attributes", "a00_lenz")
          if ent.definition.get_attribute("dynamic_attributes", "su_type") == "carcass" || ent.definition.get_attribute("dynamic_attributes", "su_type") == "back"
            if ent.definition.get_attribute("dynamic_attributes", "lenx") && ent.definition.get_attribute("dynamic_attributes", "_lenx_access", "NONE") == "NONE"
              set_att(ent,"lenx",ent.definition.get_attribute("dynamic_attributes", "lenx"),"LenX","TEXTBOX","Толщина","CENTIMETERS","MILLIMETERS",nil,nil)
            end
            if ent.definition.get_attribute("dynamic_attributes", "leny") && ent.definition.get_attribute("dynamic_attributes", "_leny_access", "NONE") == "NONE"
              set_att(ent,"leny",ent.definition.get_attribute("dynamic_attributes", "leny"),"LenY","TEXTBOX","Ширина","CENTIMETERS","MILLIMETERS",nil,nil)
            end
            if ent.definition.get_attribute("dynamic_attributes", "lenz") && ent.definition.get_attribute("dynamic_attributes", "_lenz_access", "NONE") == "NONE"
              set_att(ent,"lenz",ent.definition.get_attribute("dynamic_attributes", "lenz"),"LenZ","TEXTBOX","Длина","CENTIMETERS","MILLIMETERS",nil,nil)
            end
          end
        end
        
        if ent.definition.get_attribute("dynamic_attributes", "a03_name") && ent.definition.get_attribute("dynamic_attributes", "_a03_name_access", "NONE") == "NONE"
          set_att(ent,"a03_name",ent.definition.get_attribute("dynamic_attributes", "a03_name"),"a03_name","TEXTBOX","Название","STRING","STRING",nil,nil)
        end
        if ent.definition.get_attribute("dynamic_attributes", "c6_back")
          set_att(ent,"c6_back",ent.definition.get_attribute("dynamic_attributes", "c6_back"),"c6_back","LIST","Тип дна","STRING","STRING",nil,"&Накладное=2&Вкладное=3&В Паз=4&")
        end
        if ent.definition.get_attribute("dynamic_attributes", "k6_back")
          set_att(ent,"k6_back",ent.definition.get_attribute("dynamic_attributes", "k6_back"),"k6_back","LIST","Тип дна","STRING","STRING",nil,"&Накладное=2&Вкладное=3&В Паз=4&")
        end
        if ent.definition.get_attribute("dynamic_attributes", "c5_back")
          set_att(ent,"c5_back",ent.definition.get_attribute("dynamic_attributes", "c5_back"),"c5_back","LIST",nil,"STRING","STRING",nil,"&Нет=1&Накладная=2&Вкладная=3&В Паз=4&В четверть=5&")
        end
        if ent.definition.get_attribute("dynamic_attributes", "drawer_height")
          ent.definition.set_attribute("dynamic_attributes", "_drawer_height_options", '&1=1&2=2&3=3&4=4&5=5&6=6&7=7&8=8&')
        end
        if ent.definition.get_attribute("dynamic_attributes", "d1_type_in") && !ent.definition.get_attribute("dynamic_attributes", "_d1_type_in_access")
          set_att(ent,"d1_type_in",ent.definition.get_attribute("dynamic_attributes", "d1_type_in",'1'),nil,"LIST",translation_formlabel('Внутренний ящик'),"STRING","STRING",nil,'&Нет=1&Да=2&')
        end
        if ent.definition.name.include?("LIFT") || ent.definition.get_attribute("dynamic_attributes", "_name", "0").include?("LIFT")
          set_att(ent,"lift_pos",ent.definition.get_attribute("dynamic_attributes", "lift_pos", "1"),"lift_pos","LIST","Положение","STRING","STRING",nil,"&%u0421%u043B%u0435%u0432%u0430=1&%u0421%u043F%u0440%u0430%u0432%u0430=2&")
        end
        if ent.definition.get_attribute("dynamic_attributes", "s9_comp_name")
          set_att(ent,"s9_comp_name",ent.definition.name,"s9_comp_name","TEXTBOX","Название","STRING","STRING",nil,nil)
        end
        if ent.definition.get_attribute("dynamic_attributes", "y1_name")
          for i in 1..19
            y = "y"
            ent_opt = ent.definition.get_attribute("dynamic_attributes","_"+y+i.to_s+"_name_options")
            if !ent_opt
              y = "y0"
              ent_opt = ent.definition.get_attribute("dynamic_attributes", "_"+y+i.to_s+"_name_options")
            end
            if ent_opt
              ent.definition.set_attribute("dynamic_attributes", "_"+y+i.to_s+"_name_formlabel", '<b>'+i.to_s+'_Наименование<b>')
              ent.definition.set_attribute("dynamic_attributes", "_"+y+i.to_s+"_name_options", global_options)
              ent.definition.set_attribute("dynamic_attributes", "_"+y+i.to_s+"_unit_access", 'LIST')
              ent.definition.set_attribute("dynamic_attributes", "_"+y+i.to_s+"_unit_formlabel", i.to_s+'_Единица_измерения')
              ent.definition.set_attribute("dynamic_attributes", "_"+y+i.to_s+"_unit_options", '&%u0448%u0442=%u0448%u0442&%u043C=%u043C&')
              else
              break
            end
          end
        end
        
        dict.each_pair {|attr, v|
          if attr[0] != "_" && v
            access = ent.get_attribute("dynamic_attributes", "_" + attr + "_access")
            access = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_access") if access == nil
            if access == ("NONE")
              if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                @list_of_att.push (attr) if !@list_of_att.include?(attr)
              end
            end
            if access
              if access == ("LIST")
                options = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_options","0")
                if options != "0"
                  if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                    @list_of_att.push (attr) if !@list_of_att.include?(attr)
                  end
                end
                elsif access == ("CHECKBOX")
                if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                  @list_of_att.push (attr) if !@list_of_att.include?(attr)
                end
                elsif access == ("TEXTBOX")
                if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                  @list_of_att.push (attr) if !@list_of_att.include?(attr)
                end
                elsif access == ("VIEW")
                if !attr.include?("Z08_Paz") && v.to_s[0,2] == "__" && v.to_s[-2,2] == "__" && v != "&#9654;" && v != "&#9660;"
                  set_att(ent, attr, "&#9654;", attr, nil, "<font color=cc6600><b>" + v.gsub("_", "") + "<b></font>")
                end
                if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                  @list_of_att.push (attr) if !@list_of_att.include?(attr)
                end
              end
            end
            if @att_mode == "advanced" && @hidden_att.include?(attr)
              if access_att == [] || access_att.include?(attr) || access_att.detect{|att|attr.include?(att)}
                @list_of_hidden_att.push (attr)
              end
            end
          end
        }
      end
    end#def
    def copy_attribute(ent, id, new_id, i, new_i)
      att_hash = {}
      keys = ["_#{id}_label","_#{id}_access","_#{id}_formlabel","_#{id}_formulaunits","_#{id}_units","_#{id}_formula","_#{id}_options"]
      keys.each { |key|
        value = ent.definition.get_attribute("dynamic_attributes", key)
        att_hash[key.gsub(id,new_id)] = value.gsub("#{i}","#{new_i}") if value
      }
      value = ent.definition.get_attribute("dynamic_attributes", id)
      ent.set_attribute("dynamic_attributes", new_id, value)
      ent.definition.set_attribute("dynamic_attributes", new_id, value)
      att_hash.each { |key,value| ent.definition.set_attribute("dynamic_attributes", key, value) }
    end
    def check_visible_attribute(param)
      att_arr = []
      att = param.split('=')[0]
      val = param.split('=')[1]
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      if @sel.length == 1
        ent = @sel[0]
        dict = ent.definition.attribute_dictionary "dynamic_attributes"
        if dict #&& !ent.hidden?
          dict.each_pair {|attr, v|
            if v.to_s.include?("CHOOSE("+att+",")
              all_condition = v.split(';')
              all_condition.each {|cond|
                if cond.include?("CHOOSE("+att+",")
                  array = cond.split("CHOOSE("+att+",")
                  value_array = array[1][0..-2].split(",")
                  value_array[-1] = value_array[-1].gsub(")","")
                  if array[0].include?("SETACCESS")
                    if value_array[val.to_i-1] == "0"
                      att_arr.push(["SETACCESS",array[0][11..-3],"NONE"])
                      elsif value_array[val.to_i-1] == "1"
                      att_arr.push(["SETACCESS",array[0][11..-3],"VIEW"])
                      elsif value_array[val.to_i-1] == "2"
                      att_arr.push(["SETACCESS",array[0][11..-3],"TEXTBOX"])
                      elsif value_array[val.to_i-1] == "3"
                      att_arr.push(["SETACCESS",array[0][11..-3],"LIST"])
                    end
                    elsif array[0].include?("SETLABEL")
                    att_arr.push(["SETLABEL",array[0][10..-3],value_array[val.to_i-1][1..-2]])
                  end
                end
              }
            end
          }
          $dlg_suf.execute_script("show_hide_att(#{att_arr.inspect})") if $dlg_suf
          $dlg_att.execute_script("show_hide_att(#{att_arr.inspect})") if $dlg_att
        end
      end
    end#def
    def list_of_att_all(sel)
      @list_len = []
      @list_of_attributes = []
      @list_of_att.uniq
      for i in ["c2_shelve","d2_drawer","hinge_z","h2_dimension"]
        if @list_of_att.include?(i+"1")
          @list_of_att1 = @list_of_att[0..@list_of_att.index(i+"1")-1]
          c2_shelve_last = @list_of_att.index(i+"1")
          @list_of_att.each_with_index { |attr,index| c2_shelve_last = index if attr.include?(i) }
          middle = @list_of_att[@list_of_att.index(i+"1")..c2_shelve_last].sort { |a,b| b <=> a }
          @list_of_att = @list_of_att1+middle+@list_of_att[c2_shelve_last..-1]
        end
      end
      @list_of_att.each { |attr|
        include = 0
        sel.each { |ent|
          des_att = ent.definition.get_attribute("dynamic_attributes", attr)
          access = ent.get_attribute("dynamic_attributes", "_" + attr + "_access")
          access = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_access") if !access
          include = include + 1 if des_att != nil && access
        }
        if include == sel.length
          if attr == "lenx" || attr == "leny" || attr == "lenz" || attr == "rotx" || attr == "roty" || attr == "rotz" || attr == "material" || attr == "hidden"
            @list_len.push (attr) if !@list_len.include?(attr)
            else
            @list_of_attributes.push (attr)
          end
        end
      }
      @list_of_attributes = @list_len + @list_of_attributes
      return @list_len,@list_of_attributes
    end#def
    def read_param
      @param_delete_hidden = "no"
      @att_mode = "advanced"
      @itemcode_to_name = "no"
      @name_list = "false"
      @edge_color_arr = []
      @hidden_att = Hash.new("Hidden_attr")
      @panel_name_list = []
      @global_options = "&Нет=1&"
      @param_hash = {}
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
        path_param = File.join(param_temp_path,"parameters.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
        path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
        else
        path_param = File.join(PATH,"parameters","parameters.dat")
      end
      if File.file?(path_param)
        content = File.readlines(path_param, chomp: true)
        
        content.each { |line|
          parts = line.strip.split("=")
          key = parts[1]
          value = parts[2]
          case key
            when "delete_hidden" then @param_delete_hidden = value
            when "att_mode" then @att_mode = value
            when "itemcode_to_name" then @itemcode_to_name = value
            when "name_list" then @name_list = value
            when /edge_trim/ then @edge_color_arr << parts[4]
          end
        }
        else
        UI.messagebox(SUF_STRINGS["No such file"]+": parameters.dat")
      end
      
      hidden_att_path = File.join(PATH, "Resources", Language, "hidden_att.dat")
      if File.file?(hidden_att_path)
        hidden_content = File.readlines(hidden_att_path, chomp: true)
        hidden_content.each{|i| 
          @hidden_att[i.strip.split("=>")[0]] = i.strip.split("=>")[1]
          @hidden_att[i.strip.split("=>")[0]+"_access"] = i.strip.split("=>")[2]
          @hidden_att[i.strip.split("=>")[0]+"_option"] = i.strip.split("=>")[3]
        }
      end
      
      if param_temp_path && File.file?(File.join(param_temp_path,"panel_name.dat"))
        panel_name_path = File.join(param_temp_path,"panel_name.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","panel_name.dat"))
        panel_name_path = File.join(TEMP_PATH,"SUF","panel_name.dat")
        else
        panel_name_path = File.join(PATH,"parameters","panel_name.dat")
      end
      if File.file?(panel_name_path)
        @panel_name_list = File.readlines(panel_name_path, chomp: true)
      end
      if param_temp_path && File.file?(File.join(param_temp_path,"additional.dat"))
        path_param = File.join(param_temp_path,"additional.dat")
        else
        path_param = File.join(PATH_COMP,"additional.dat")
      end
      additional_path = File.join(PATH_COMP, "additional.dat")
      unless File.file?(additional_path)
        File.new(additional_path, "w").close
      end
      
      if File.file?(path_param)
        additional_content = File.readlines(path_param, chomp: true)
        additional_content.each { |line| 
          @global_options += "#{line.strip}=#{line.strip}&"
        }
      end
      if File.file?(File.join(TEMP_PATH, "SUF", "module_number.dat"))
        path_param = File.join(TEMP_PATH, "SUF", "module_number.dat")
        else
        path_param = File.join(PATH, "parameters", "module_number.dat")
      end
      param_file = File.new(path_param,"r")
      content = param_file.readlines
      param_file.close
			@param_hash["view_common"] = "Да" if !@param_hash["view_common"]
      @param_hash["view_number"] = "Перед модулем" if !@param_hash["view_number"]
			@param_hash["offset_z"] = "0" if !@param_hash["offset_z"]
			@param_hash["newline_space"] = "Нет" if !@param_hash["newline_space"]
      content.each { |cont| @param_hash[cont.split("=")[0]] = cont.split("=")[1].strip}
      return @param_delete_hidden,@att_mode,@itemcode_to_name,@name_list,@edge_color_arr,@hidden_att,@panel_name_list,@global_options,@param_hash
    end#def
    def attributes_list(entity=nil)
      @access_att = []
      @param_delete_hidden,@att_mode,@itemcode_to_name,@name_list,@edge_color_arr,@hidden_att,@panel_name_list,@global_options,@param_hash = read_param
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      entity ? sel = [entity] : sel = @sel
      sel_length = sel.length
      tool_name = Sketchup.active_model.tools.active_tool_name
      if sel_length == 0
        command = "clear_selection()"
        $dlg_suf.execute_script(command)
        else
        Sketchup.active_model.start_operation('att_list', true, false, true)
        @sections,@section_and_tr,@panel_section_hash,@shelve_section_hash,@drawer_section_hash,@accessory_section_hash,@frontal_hash = all_sections(sel)
        @section_array = sort_sections_array(@sections)
        @list_of_att,@list_of_hidden_att = attributes_of_all_selection(sel,@global_options,@access_att)
        @list_len,@list_of_attributes = list_of_att_all(@sel)
        name_to_dialog(sel[0],sel_length)
        attributes_to_dialog()
        Sketchup.active_model.commit_operation
      end
    end#def
    def attributes_of_all_selection(sel,global_options,access_att)
      @list_of_att = [] 
      @list_of_hidden_att = []
      sel.each { |ent| att_list(ent,global_options,access_att) }
      return @list_of_att,@list_of_hidden_att
    end#def
    def all_sections(sel)
      @sections = {}
      @section_and_tr = {}
      @panel_section_hash = {}
      @shelve_section_hash = {}
      @drawer_section_hash = {}
      @accessory_section_hash = {}
      @frontal_hash = {}
      sel.each { |ent|
        if Sketchup.active_model.tools.active_tool_name != "MoveTool"
          ent.make_unique if ent.definition.count_instances > 1
        end
        ent.definition.entities.grep(Sketchup::ComponentInstance).each{|e|
          search_section_att(e,ent.transformation*e.transformation,Geom::Transformation.new,ent,ent.definition.name)
        }
      }
      return @sections,@section_and_tr,@panel_section_hash,@shelve_section_hash,@drawer_section_hash,@accessory_section_hash,@frontal_hash
    end#def
    def search_section_att(ent,tr_global,tr,last_section,parent_name)
      if !ent.deleted?
        if ent.definition
          if !ent.hidden?
            if ent.definition.get_attribute("dynamic_attributes", "c2_panel1")
              if !@panel_section_hash[ent]
                att_arr = ["a0_panel_count","b1_p_thickness","b1_p_width","c1_fix","c1_panel_position","c2_panel1","c2_panel2","c2_panel3","c2_panel4","c2_panel5","c2_panel6","c2_panel7","c2_panel8","c2_panel9","c2_panel9_10","c2_panel9_11","c2_panel9_12","c2_panel9_13","c2_panel_carcass","c2_panel_carcass_type","h1_dimensions_pos","h2_dimension1","h2_dimension2","h2_dimension3","h2_dimension4","h2_dimension5","h2_dimension6","h2_dimension7","h2_dimension8","h2_dimension9","h2_dimension10","h2_dimension11","h2_dimension12","h2_dimension13"]
                att_hash = make_att_hash(ent,att_arr)
                ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                  if e.definition.name.include?("Body")
                    @section_and_tr[ent] = tr_global
                    pt = ent.transformation.origin.transform tr*e.transformation
                    @panel_section_hash[ent] = [att_hash]
                    @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                    last_section = ent
                  end
                }
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "c2_shelve1")
              if !@shelve_section_hash[ent]
                att_arr = ["b1_p_thickness","a0_shelves_count","a1_up_shelve","a2_down_shelve","c2_shelve1","c2_shelve2","c2_shelve3","c2_shelve4","c2_shelve5","c2_shelve6","c2_shelve7","c2_shelve8","c2_shelve9","c2_shelve9_10","c2_shelve9_11","c2_shelve9_12","c2_shelve9_13","h2_dimension1","h2_dimension2","h2_dimension3","h2_dimension4","h2_dimension5","h2_dimension6","h2_dimension7","h2_dimension8","h2_dimension9","h2_dimension10","h2_dimension11","h2_dimension12","h2_dimension13"]
                att_hash = make_att_hash(ent,att_arr.reverse)
                ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                  if e.definition.name.include?("Body")
                    @section_and_tr[ent] = tr_global
                    pt = ent.transformation.origin.transform tr*e.transformation
                    @shelve_section_hash[ent] = [att_hash]
                    @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                    last_section = ent
                  end
                }
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "d2_drawer1") || ent.definition.get_attribute("dynamic_attributes", "x_depth1")
              if !@drawer_section_hash[ent]
                att_arr = ["d1_type_in","d2_drawer1","d2_drawer2","d2_drawer3","d2_drawer4","d2_drawer5","d2_drawer6","d2_drawer7","a0_drawer_count","trim_z2","trim_z1","trim_y_size","k8_b_thickness","k7_back_indent","k6_back_indent","k6_back_dist","k6_back"]
                if ent.definition.get_attribute("dynamic_attributes", "d1_type_in") && !ent.definition.get_attribute("dynamic_attributes", "_d1_type_in_access")
                  set_att(ent,"d1_type_in",ent.definition.get_attribute("dynamic_attributes", "d1_type_in",'1'),nil,"LIST",translation_formlabel('Внутренний ящик'),"STRING","STRING",nil,'&Нет=1&Да=2&')
                end
                att_hash = make_att_hash(ent,att_arr.reverse)
                ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                  if e.definition.name.include?("Body")
                    @section_and_tr[ent] = tr_global
                    pt = ent.transformation.origin.transform tr*e.transformation
                    @drawer_section_hash[ent] = [att_hash]
                    @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                    last_section = ent
                  end
                }
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "b4_height_corob_trim_z2")
              if !@drawer_section_hash[ent]
                att_arr = ["a1_motion_technology","a2_extension_type","a3_mounting_method","a4_weight","a5_name","a6_producer","b1_b_thickness","b1_p_thickness","b2","b2_lw","b2_skw","b2_skw_indent","b3","b3_nl","b3_skl","b3_skl_indent","b4","b4_height","b4_height_corob_trim_z1","b4_height_corob_trim_z2","b4_height_corob_z","b4_niche_depth","b4_trim_bottom","b4_trim_z_front_panel","b4_trim_z_vert_panel","b4_z_napr"]
                ent.definition.name = parent_name
                att_hash = make_att_hash(ent,att_arr)
                @section_and_tr[ent] = tr_global*ent.transformation.inverse
                pt = ent.transformation.origin.transform tr*ent.transformation.inverse
                @drawer_section_hash[ent] = [att_hash]
                @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                last_section = ent
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "a05_front_offset") || ent.definition.get_attribute("dynamic_attributes", "a08_bottom_offset")
              if !@accessory_section_hash[ent]
                att_arr = ["a05_front_offset","a06_back_offset","a07_top_offset","a08_bottom_offset","a09_distance"]
                att_hash = make_att_hash(ent,att_arr)
                ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                  if e.definition.name.include?("Body")
                    @section_and_tr[ent] = tr_global
                    pt = ent.transformation.origin.transform tr*e.transformation
                    @accessory_section_hash[ent] = [att_hash]
                    @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                    last_section = ent
                  end
                }
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "su_type") == "body" && ent.definition.name.include?("Aventos HF") || ent.definition.get_attribute("dynamic_attributes", "su_type") == "frontal" && !ent.definition.name.include?("Essence")
              if !@frontal_hash[ent]
                att_arr = ["a00_lenx","a00_leny","a00_lenz","a00_lenz1","a09_vitr","a09_vitr_glass","open","hinge_auto_count","hinge_count","hinge_cup","hinge_mounting_plate","hinge_regulation","hinge_spacing","hinge_type","hinge_z5","hinge_z45","hinge_z4","hinge_z3","hinge_z2","hinge_z1","trim_y1","trim_y2","trim_z1","trim_z2"]
                if ent.parent.get_attribute("dynamic_attributes", "_name", "0").include?("Drawer")
                  att_arr << "drawer_height"
                  if ent.definition.get_attribute("dynamic_attributes", "drawer_height")
                    ent.definition.set_attribute("dynamic_attributes", "_drawer_height_options", '&1=1&2=2&3=3&4=4&5=5&6=6&7=7&8=8&')
                    else
                    set_att(ent,"drawer_height",ent.parent.get_attribute("dynamic_attributes", "d1_type_height",'2'),nil,"LIST",translation_formlabel('Высота ящика'),"FLOAT","STRING",ent.parent.get_attribute("dynamic_attributes", "_d1_type_height_formula",'SETLEN("d1_type_height",IF(a01_lenz>23.6,6,IF(a01_lenz>20,3,IF(a01_lenz>14.3,2,1))),1)'),'&1=1&2=2&3=3&4=4&5=5&6=6&7=7&8=8&')
                  end
                end
                att_hash = make_att_hash(ent,att_arr)
                ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                  if e.definition.name.include?("Body")
                    @section_and_tr[ent] = tr_global
                    pt = ent.transformation.origin.transform tr*e.transformation
                    @frontal_hash[ent] = [att_hash]
                    @sections[last_section] ? @sections[last_section] << [ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]] : @sections[last_section] = [[ent,[(pt.x*25.4).round(1),(pt.y*25.4).round(1),(pt.z*25.4).round(1)]]]
                    last_section = ent
                    return
                  end
                }
              end
            end
            ent.make_unique if ent.definition.count_instances > 1
            ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
            ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_section_att(e,tr_global*e.transformation,tr*ent.transformation,last_section,ent.definition.name) }
            else
            ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hide_in_browser(e) }
          end
        end
      end
    end#def
    def hide_in_browser(ent)
      ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hide_in_browser(e) }
    end
    def sort_sections_array(sections)
      sort_sections = {}
      sections.each_pair{|entity,entity_array|
        sort_array = entity_array.sort{|a,b|
          comp = (a[1][0] <=> b[1][0])
          if comp.zero?
            comp = (b[1][2] <=> a[1][2])
          end
          comp
        }
        sort_sections[entity] = sort_array
      }
      @sections_array = []
      sections.each_pair{|entity,entity_array|
        make_sections_array(sort_sections,entity)
      }
      return @sections_array
    end#def
    def make_sections_array(sections,entity)
      entity_array = sections[entity]
      entity_array.each{|arr|
        @sections_array << arr[0] if !@sections_array.include?(arr[0])
        if sections[arr[0]]
          make_sections_array(sections,arr[0])
        end
      }
    end#def
    def make_att_hash(ent,att_arr)
      att_hash = []
      att_arr.each{|attr|
        access = ent.get_attribute("dynamic_attributes", "_" + attr + "_access","NONE")
        access = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_access","NONE") if access == "NONE"
        #value = ent.definition.get_attribute("dynamic_attributes","_" + attr + "_nominal")
        value = ent.get_attribute("dynamic_attributes", attr)
        value = ent.definition.get_attribute("dynamic_attributes", attr) if !value
        formlabel = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formlabel","0")
        if formlabel && formlabel.include?("Еденица")
          formlabel.gsub!("Еденица","Единица")
          e.definition.set_attribute("dynamic_attributes", "_" + attr + "_formlabel", formlabel)
        end
        formlabel = translation_formlabel(formlabel)
        formula = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula")
        if formula
          formula = formula.gsub('"',"'")
          formlabel += " *" 
        end
        formulaunits = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formulaunits","0")
        units = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_units","0")
        @options_typ = "0"
        @options_val = "0"
        if value && access != "NONE"
          if access == "LIST"
            value = round_without_zero(value.to_f*25.4,2) if formulaunits == "CENTIMETERS"
            value = value.to_f.round.to_s if is_number?(value)
            options = ent.get_attribute("dynamic_attributes", "_" + attr + "_options","0")
            options = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_options","0") if options == "0"
            @options_typ, @options_val = options_array(ent,attr,"=",formulaunits,options)
            if @options_typ == "%u041D%u0435%u0442;%u0415%u0441%u0442%u044C"
              access = "CHECKBOX"
              if !value.include?("=>")
                value == @options_val.split(";")[0] ? value = "=>0" : value = "=>1"
              end
              elsif @options_typ == "%u0414%u0430;%u041D%u0435%u0442"
              access = "CHECKBOX"
              if !value.include?("=>")
                value == @options_val.split(";")[0] ? value = "=>1" : value = "=>0"
              end
            end
            elsif access == "TEXTBOX"
            value = converter(value, units, formulaunits)
            elsif access == "VIEW"
            value = converter(value, units, formulaunits)
          end
          att_hash << [attr, access, formlabel, formulaunits, value.to_s, @options_typ, @options_val, false, formula.to_s]
        end
      }
      return att_hash
    end#def
    def name_to_dialog(ent,sel_length)
      FileUtils.rm_rf(Dir.glob(PATH + "/html/cont/thumbnail/*"))
      thumbnail = ent.definition.save_thumbnail PATH + "/html/cont/thumbnail/" + ent.definition.name.gsub("#", "_") + ".png"
      @thumbnail = "cont/thumbnail/" + ent.definition.name.gsub("#", "_") + ".png"
      if sel_length > 4
        @des_name = sel_length.to_s + " "+translation_formlabel('Компонентов')
        @item_code = ""
        @summary = "nil"
        @description = ""
        elsif sel_length > 1
        @des_name = sel_length.to_s + " "+translation_formlabel('Компонента')
        @item_code = ""
        @summary = "nil"
        @description = ""
        else
        @des_name = ent.definition.get_attribute("dynamic_attributes", "name")
        @des_name = ent.definition.get_attribute("dynamic_attributes", "_name") if !@des_name
        @des_name = ent.definition.name if !@des_name
        @des_name = translation_formlabel(@des_name)
        @item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode","")
        @summary = ent.definition.get_attribute("dynamic_attributes", "summary", "nil")
        @description = ent.definition.get_attribute("dynamic_attributes", "description","")
        @description = translation_formlabel(@description)
      end
      if @list_of_attributes == []
        if sel_length > 1
          command = "no_attributes(#{@des_name.inspect})"
          $dlg_suf.execute_script(command) if $dlg_suf
          $dlg_att.execute_script(command) if $dlg_att
          else
          vend = [@des_name, @item_code, @thumbnail]
          command = "no_attributes_one(#{vend.inspect})"
          $dlg_suf.execute_script(command) if $dlg_suf
          $dlg_att.execute_script(command) if $dlg_att
        end
        else
        vend = [@des_name, @item_code, @summary, @description, @thumbnail]
        command = "name_list(#{vend.inspect})"
        $dlg_suf.execute_script(command) if $dlg_suf
        $dlg_att.execute_script(command) if $dlg_att
      end
    end#def
    def boolean(value)
      value == 0 ? value = "FALSE" : value = "TRUE"
      return value
    end#def
    def converter(value, units, formulaunits)
      case units 
        when "MILLIMETERS" then value = round_without_zero(value.to_f*25.4, 1).to_s + " mm"
        when "CENTIMETERS" then value = round_without_zero(value.to_f*2.54, 1).to_s + " cm"
        when "STRING" then
        if formulaunits == "CENTIMETERS"
          value = round_without_zero(value.to_f*25.4, 1).to_s + " mm"
        end
        when "METERS" then value = round_without_zero(value.to_f*0.0254, 3).to_s + " m"
        when "FEET" then value = round_without_zero(value.to_f*0.08333232, 3).to_s + "'"
        when "INCHES" then value = round_without_zero(value.to_f, 3).to_s + "''"
        when "INTEGER" then value = round_without_zero(value.to_f, 0).to_s
        when "FLOAT" then value = round_without_zero(value.to_f, 2).to_s
        when "PERCENT" then value = round_without_zero(value.to_f*100, 3).to_s + "%"
        when "BOOLEAN" then value = boolean(value)
        when "DEGREES" then value = round_without_zero(value.to_f, 2).to_s + "°"
        when "DOLLARS" then value = "$" + round_without_zero(value.to_f, 2).to_s
        when "EUROS" then value = "€" + round_without_zero(value.to_f, 2).to_s
        when "YEN" then value = "¥" + round_without_zero(value.to_f, 2).to_s
        when "POUNDS" then value = round_without_zero(value.to_f, 2).to_s + " lbs"
        when "KILOGRAMS" then value = round_without_zero(value.to_f*0.4535923745, 3).to_s + " kg"
      end
      return value
    end#def
    def options_array(ent, attr, sep, formulaunits, options)
      options_typ = []
      options_val = []
      options = options[1..-2].split("&")
      options.each { |option|
        key, value = option.split(sep)
        options_typ << key.to_s
        if formulaunits == "CENTIMETERS"
          value = round_without_zero(value.to_f * 25.4, 2)
        end
        options_val << value.to_s
      }
      return options_typ.join(";"), options_val.join(";")
    end
    def search_parent(entity,all_comp=[])
			if entity.parent.is_a?(Sketchup::ComponentDefinition)
				if entity.parent.instances[-1]
					all_comp << entity.parent.instances[-1]
					search_parent(entity.parent.instances[-1],all_comp)
        end
      end
      return all_comp.reverse
    end#def
    def сlick_att(id)
      # Создание HTML-диалога для SketchUp
      dialog_width = 420
      dialog_height = 200
      select_parent = ""
      up_button = ""
      @parent_array = search_parent(Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)[0])
      if !@parent_array.empty?
        dialog_height = 250
        up_button += "<button class=\"button up-button\" title=\"#{SUF_STRINGS["Copy this attribute to the parent component"]}\n#{SUF_STRINGS["Enter a dependency formula into this component"]}\" onclick=\"sketchup.upAttribute(['#{id}',document.getElementById('idInput').value,document.getElementById('labelInput').value,document.getElementById('valueInput').value,document.getElementById('parentSelect').value])\">#{SUF_STRINGS["Copy"]} #{SUF_STRINGS["Up"]}</button>"
        select_parent += "<select id='parentSelect' style='margin-top: 10px; width: 100%; padding: 5px; font-size: 14px; border: 1px solid #ccc;'>\n"
        @parent_array.each_with_index { |entity, index|
          select_parent += "  <option value='#{index}'>#{entity.definition.name}</option>\n"
        }
        select_parent += "</select>\n"
      end
      if @dlg && @dlg.visible?
        @dlg.close
      end
      @dlg = UI::HtmlDialog.new(
        dialog_title: " ",
        scrollable: false,
        resizable: false,
        width: dialog_width,
        height: dialog_height,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      
      # HTML-код для отображения в диалоге
      html_content = <<-HTML
        <!DOCTYPE html>
        <html lang="ru">
        <head>
        <meta charset="UTF-8">
        <title>#{SUF_STRINGS["Attribute dialog"]}</title>
        <style>
        body { font-family: Arial, sans-serif; margin: 10px; text-align: center; }
        .att_table { margin: 0 auto; border-collapse: collapse; text-align: left; border: 1px solid #ccc; width: 100%; }
        .button { 
        padding: 5px 10px;
        font-size: 14px;
        cursor: pointer;
        margin: 5px;
        margin-top: 15px;
        background-color: #4CAF50;
        color: white;
        border: none;
        border-radius: 3px;
        transition: background 0.3s;
        }
        .button:hover { background-color: #45a049; }
        .up-button { background-color: #2196F3; }
        .up-button:hover { background-color: #1976D2; }
        .delete-button { background-color: #f44336; }
        .delete-button:hover { background-color: #d32f2f; }
        </style>
        </head>
        <body>
        <table class="att_table">
        <tr>
        <td style="padding: 4px 8px; font-weight: bold; border: 1px solid #ccc;">Атрибут</td>
        <td style="padding: 4px 8px; border: 1px solid #ccc;">
        <input type="text" id="idInput" value="#{id}" style="width: 97%;">
        </td>
        </tr>
        <tr>
        <td style="padding: 4px 8px; font-weight: bold; border: 1px solid #ccc;">Название</td>
        <td style="padding: 4px 8px; border: 1px solid #ccc;">
        <input type="text" id="labelInput" value="#{@attributes_hash[id]["formlabel"]}" style="width: 97%;">
        </td>
        </tr>
        <tr>
        <td style="padding: 4px 8px; font-weight: bold; border: 1px solid #ccc;">Значение</td>
        <td style="padding: 4px 8px; border: 1px solid #ccc;">
        <input type="text" id="valueInput" value="#{@attributes_hash[id]["value"]}" style="width: 97%;">
        </td>
        </tr>
        </table>
        <button class="button" title="#{SUF_STRINGS["Copy this attribute for pasting into other components"]}" onclick="sketchup.copyAttribute(['#{id}',document.getElementById('idInput').value,document.getElementById('labelInput').value,document.getElementById('valueInput').value])">#{SUF_STRINGS["Copy"]}</button>
        #{up_button}
        <button class="button delete-button" title="#{SUF_STRINGS["Delete this attribute"]}" onclick="sketchup.deleteAttribute('#{id}')">#{SUF_STRINGS["Delete"]}</button>
        #{select_parent}
        </body>
        </html>
      HTML
      
      # Устанавливаем HTML-содержимое в диалог
      @dlg.set_html(html_content)
      x = Sketchup.active_model.active_view.vpwidth/2 - dialog_width/2
      y = Sketchup.active_model.active_view.vpheight/2 - dialog_height/2
      @dlg.set_position(x, y)
      @dlg.add_action_callback("copyAttribute") { |_, arr|
        copy_att(arr)
        @dlg.close
      }
      @dlg.add_action_callback("upAttribute") { |_, arr|
        copy_up(arr)
        @dlg.close
      }
      @dlg.add_action_callback("deleteAttribute") { |_, id|
        delete_att(id)
        @dlg.close
      }
      # Открываем диалог
      @dlg.show
    end
    def copied_att
      @copied_att != {}
    end
    def set_attributes_hash(hash)
      @attributes_hash = hash
    end
    def set_copied_att(arr)
      new_hash = {}
      new_hash[arr[1]] = @attributes_hash[arr[0]].clone
      new_hash[arr[1]]["att"] = arr[0]
      new_hash[arr[1]]["attr"] = arr[1]
      new_hash[arr[1]]["label"] = arr[1]
      new_hash[arr[1]]["formlabel"] = arr[2]
      new_hash[arr[1]]["value"] = arr[3]
      @copied_att = new_hash[arr[1]]
    end
    def get_copied_att(id)
      @copied_att
    end
    def copy_att(arr)
      set_copied_att(arr)
      if $dlg_suf
        $dlg_suf.execute_script("set_copied_att(true)")
        $dlg_suf.execute_script("add_comp()")
      end
      if $dlg_att
        $dlg_att.execute_script("set_copied_att(true)")
        $dlg_att.execute_script("add_comp()")
      end
    end
    def delete_att(id)
      Sketchup.active_model.start_operation('Delete attribute', true)
      Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).each { |ent|
        delete_attribute(ent,id)
      }
      Sketchup.active_model.commit_operation
      if $dlg_suf
        $dlg_suf.execute_script("set_copied_att(false)")
        $dlg_suf.execute_script("add_comp()")
      end
      if $dlg_att
        $dlg_att.execute_script("set_copied_att(false)")
        $dlg_att.execute_script("add_comp()")
      end
    end
    def delete_attribute(ent,id)
      ent.delete_attribute("dynamic_attributes", id)
      ent.definition.delete_attribute("dynamic_attributes", id)
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_label")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_access")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_formlabel")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_formulaunits")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_units")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_formula")
      ent.definition.delete_attribute("dynamic_attributes", "_"+id+"_options")
    end
    def copy_up(arr)
      set_copied_att(arr)
      add_attribute(@parent_array[arr[4].to_i])
    end
    def add_attribute(parent=false)
      Sketchup.active_model.start_operation('Copy attribute', true)
      if parent
        entities = [parent]
        att = @copied_att["att"]
        attr = @copied_att["attr"]
        Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).each { |ent|
          ent.definition.set_attribute("dynamic_attributes", "_"+att+"_formula", 'LOOKUP("'+attr+'")')
        }
        else
        entities = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
      end
      entities.each { |ent|
        attr = @copied_att["attr"]
        @copied_att.each{|att,value|
          if att != "att" && att != "attr" && value && value != ""
            if att == "value"
              ent.set_attribute("dynamic_attributes", attr, value)
              ent.definition.set_attribute("dynamic_attributes", attr, value)
              else
              ent.definition.set_attribute("dynamic_attributes", "_"+attr+"_"+att, value)
            end
          end
        }
      }
      Sketchup.active_model.commit_operation
      $dlg_suf.execute_script("add_comp()") if $dlg_suf
      $dlg_att.execute_script("add_comp()") if $dlg_att
    end
    def attributes_to_dialog()
      ent = @sel[0]
      all_att_hash = {}
      @list_of_attributes.each { |attr|
        if attr == "y0"
          panel_index = @panel_section_hash.count
          shelve_index = @shelve_section_hash.count
          drawer_index = @drawer_section_hash.count
          accessory_index = @accessory_section_hash.count
          frontal_index = @frontal_hash.count
          frontal_view_index = @frontal_hash.count
          @panel_sections = {}
          @shelve_sections = {}
          @drawer_sections = {}
          @accessory_sections = {}
          @frontal_sections = {}
          @section_array.each{|section_entity|
            if @panel_section_hash != {}
              @panel_section_hash.each_pair{|entity,arr|
                if entity == section_entity
                  @panel_sections[panel_index] = entity
                  ent.definition.get_attribute("dynamic_attributes", "_panel_section_"+panel_index.to_s) ? val = ent.definition.get_attribute("dynamic_attributes", "_panel_section_"+panel_index.to_s) : val = "&#9654;"
                  vend = ["_panel_section_"+panel_index.to_s, "VIEW", "<font color=cc6600><b>"+entity.definition.name.split("#")[0]+" "+panel_index.to_s+"</b></font>", "STRING", val.to_s, 0, 0, false, entity.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula","")]
                  command = "attribute_list(#{vend.inspect})"
                  $dlg_suf.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_panel_section_"+panel_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_suf.execute_script(command)
                  }
                  panel_index -= 1
                end
              }
            end
            if @shelve_section_hash != {}
              @shelve_section_hash.each_pair{|entity,arr|
                if entity == section_entity
                  @shelve_sections[shelve_index] = entity
                  ent.definition.get_attribute("dynamic_attributes", "_shelve_section_"+shelve_index.to_s) ? val = ent.definition.get_attribute("dynamic_attributes", "_shelve_section_"+shelve_index.to_s) : val = "&#9654;"
                  vend = ["_shelve_section_"+shelve_index.to_s, "VIEW", "<font color=cc6600><b>"+entity.definition.name.split("#")[0]+" "+shelve_index.to_s+"</b></font>", "STRING", val.to_s, 0, 0, false, entity.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula","")]
                  command = "attribute_list(#{vend.inspect})"
                  $dlg_suf.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_shelve_section_"+shelve_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_suf.execute_script(command)
                  }
                  shelve_index -= 1
                end
              }
            end
            if @drawer_section_hash != {}
              @drawer_section_hash.each_pair{|entity,arr|
                if entity == section_entity
                  @drawer_sections[drawer_index] = entity
                  ent.definition.get_attribute("dynamic_attributes", "_drawer_section_"+drawer_index.to_s) ? val = ent.definition.get_attribute("dynamic_attributes", "_drawer_section_"+drawer_index.to_s) : val = "&#9654;"
                  vend = ["_drawer_section_"+drawer_index.to_s, "VIEW", "<font color=cc6600><b>"+entity.definition.name.split("#")[0]+" "+drawer_index.to_s+"</b></font>", "STRING", val.to_s, 0, 0, false, entity.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula","")]
                  command = "attribute_list(#{vend.inspect})"
                  $dlg_suf.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_drawer_section_"+drawer_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_suf.execute_script(command)
                  }
                  drawer_index -= 1
                end
              }
            end
            if @accessory_section_hash != {}
              @accessory_section_hash.each_pair{|entity,arr|
                if entity == section_entity
                  @accessory_sections[accessory_index] = entity
                  ent.definition.get_attribute("dynamic_attributes", "_accessory_section_"+accessory_index.to_s) ? val = ent.definition.get_attribute("dynamic_attributes", "_accessory_section_"+accessory_index.to_s) : val = "&#9654;"
                  vend = ["_accessory_section_"+accessory_index.to_s, "VIEW", "<font color=cc6600><b>"+entity.definition.name.split("#")[0]+" "+accessory_index.to_s+"</b></font>", "STRING", val.to_s, 0, 0, false, entity.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula","")]
                  command = "attribute_list(#{vend.inspect})"
                  $dlg_suf.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_accessory_section_"+accessory_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_suf.execute_script(command)
                  }
                  accessory_index -= 1
                end
              }
            end
            if @frontal_hash != {}
              @frontal_hash.each_pair{|entity,arr|
                if entity == section_entity
                  @frontal_sections[frontal_index] = entity
                  ent.definition.get_attribute("dynamic_attributes", "_frontal_section_"+frontal_index.to_s) ? val = ent.definition.get_attribute("dynamic_attributes", "_frontal_section_"+frontal_index.to_s) : val = "&#9654;"
                  vend = ["_frontal_section_"+frontal_index.to_s, "VIEW", "<font color=cc6600><b>"+entity.definition.name.split("#")[0]+" "+frontal_index.to_s+"</b></font>", "STRING", val.to_s, 0, 0, false, entity.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula","")]
                  command = "attribute_list(#{vend.inspect})"
                  $dlg_suf.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_frontal_section_"+frontal_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_suf.execute_script(command)
                  }
                  frontal_index -= 1
                end
              }
            end
          }
          panel_sections(@panel_sections)
          shelve_sections(@shelve_sections)
          drawer_sections(@drawer_sections)
          accessory_sections(@accessory_sections)
          frontal_sections(@frontal_sections)
        end
        attributes_hash = {}
        formlabel_a = []
        formula_a = []
        @sel.each { |e|
          formlabel = e.definition.get_attribute("dynamic_attributes", "_" + attr + "_formlabel")
          if formlabel && formlabel.include?("Еденица")
            formlabel.gsub!("Еденица","Единица")
            e.definition.set_attribute("dynamic_attributes", "_" + attr + "_formlabel", formlabel)
          end
          formlabel_a.push formlabel if formlabel
          formula = e.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula")
          formula_a.push formula if formula
        }
        formlabel_a.uniq.length == 1 ? @formlabel = formlabel_a[0] : @formlabel = attr
        attributes_hash["attr"] = attr
        attributes_hash["formlabel"] = @formlabel
        @formlabel = translation_formlabel(@formlabel)
        att_formula = ""
        if formula_a != []
          att_formula = formula_a[0].gsub('"',"'")
          @formlabel = @formlabel + " *" 
        end
        access = ent.get_attribute("dynamic_attributes", "_" + attr + "_access")
        access = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_access") if !access
        formulaunits = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formulaunits")
        formula = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula")
        units = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_units","0")
        options = ent.get_attribute("dynamic_attributes", "_" + attr + "_options")
        options = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_options") if !options
        
        if attr == "material"
          if ent.material
            value = ent.material.display_name
            else
            value = ent.get_attribute("dynamic_attributes", attr)
            if !value
              value = ent.definition.get_attribute("dynamic_attributes", attr)
              value = "" if !value
            end
          end
          else
          #value = ent.definition.get_attribute("dynamic_attributes","_" + attr + "_nominal")
          #if !value || value == 0
          value = ent.get_attribute("dynamic_attributes", attr)
          if !value
            value = ent.definition.get_attribute("dynamic_attributes", attr)
            value = 0 if !value
          end
          #end
        end
        attributes_hash["access"] = access
        attributes_hash["formulaunits"] = formulaunits
        attributes_hash["units"] = units
        attributes_hash["options"] = options
        attributes_hash["formula"] = att_formula
        attributes_hash["value"] = value
        formulaunits = formulaunits.to_s
        hide = false
        options = nil
        if access == "NONE"
          if options && options != "&"
            access = "LIST"
            else
            access = "TEXTBOX"
          end
          hide = true
        end
        if access == "LIST"
          value = round_without_zero(value.to_f*25.4,2) if formulaunits == "CENTIMETERS"
          options = ent.get_attribute("dynamic_attributes", "_" + attr + "_options","0")
          options = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_options","0") if options == "0"
          @options_typ, @options_val = options_array(ent,attr,"=",formulaunits,options)
          if @att_mode == "advanced" && !attr.include?("gluing")
            if attr.include?("len") || attr.include?("thickness") || attr.include?("leg")
              access = "TEXTBOX"
              value = value.to_s + " mm"
            end
          end
          access = "TEXTBOX" if !@options_typ.include?(value.to_s) && attr[0] == "y" && attr[3..6] == "name" && value != "1"
          if @options_val != "0"
            if @options_typ == "%u041D%u0435%u0442;%u0415%u0441%u0442%u044C"
              access = "CHECKBOX"
              if !value.include?("=>")
                value == @options_val.split(";")[0] ? value = "=>0" : value = "=>1"
              end
              vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
              command = "attribute_list(#{vend.inspect})"
              $dlg_suf.execute_script(command)
              elsif @options_typ == "%u0414%u0430;%u041D%u0435%u0442"
              access = "CHECKBOX"
              if !value.include?("=>")
                value == @options_val.split(";")[0] ? value = "=>1" : value = "=>0"
              end
              vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
              command = "attribute_list(#{vend.inspect})"
              $dlg_suf.execute_script(command)
              else
              value = value.to_f.round if is_number?(value)
              vend = [attr, access, @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide, att_formula.to_s]
              command = "attribute_list(#{vend.inspect})"
              $dlg_suf.execute_script(command)
            end
          end
          if attr.include?("su_type") && !attr.include?("a09_su_type_layer")
            if !ent.definition.get_attribute("dynamic_attributes", "a09_su_type_layer")
              su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
              if su_type =~ /furniture|handle|hinge|drawer|basket|bracket|leg|dryer|lift|holder/i
                case su_type
                  when "metal" then value = "4_Металл"
                  else value = "9_Фурнитура"
                end
                layer_options = "&9_Фурнитура=9_Фурнитура&4_Металл=4_Металл&"
                else
                case su_type
                  when "frontal" then value = "1_Фасад"
                  when "glass" then value = "2_Стекло"
                  when "carcass" then value = "3_Каркас"
                  when "back" then value = "4_Задняя_стенка"
                end
                layer_options = "&1_Фасад=1_Фасад&1_Фасад_ящика=1_Фасад_ящика&2_Стекло=2_Стекло&3_Каркас=3_Каркас&3_Каркас_ящика=3_Каркас_ящика&4_Задняя_стенка=4_Задняя_стенка&"
              end
              @options_typ, @options_val = options_array(ent, "a09_"+attr+"_layer","=", "STRING",layer_options)
              set_att(ent,"a09_"+attr+"_layer",value,"a09_"+attr+"_layer","LIST","Слой панели","STRING","STRING",nil,layer_options)
              vend = ["a09_"+attr+"_layer", "LIST", "Слой панели", "STRING", value.to_s, @options_typ, @options_val, hide, ""]
              command = "attribute_list(#{vend.inspect})"
              $dlg_suf.execute_script(command)
            end
          end
          elsif access == "TEXTBOX"
          if @name_list == "true" && attr == "a03_name" && ent.definition.get_attribute("dynamic_attributes", "edge_z1")
            vend = ["name_list", "VIEW", translation_formlabel('Список названий'), "STRING", translation_formlabel('Редактировать'), 0, 0, hide, ""]
            command = "attribute_list(#{vend.inspect})"
            $dlg_suf.execute_script(command)
            vend = ["name_no_list", "TEXTBOX", translation_formlabel('Название не из списка'), "STRING", "", 0, 0, hide, "", value.to_s]
            command = "attribute_list(#{vend.inspect})"
            $dlg_suf.execute_script(command)
            name_list = "&"
            @panel_name_list.each { |name| name_list += name+"="+name+"&" }
            name_list = "&"+value+"="+value+name_list if !name_list.include?(value)
            @options_typ, @options_val = options_array(ent, "a03_name","=", "STRING",name_list)
            vend = [attr, "LIST", @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide,""]
            command = "attribute_list(#{vend.inspect})"
            $dlg_suf.execute_script(command)
            else
            if attr == "a03_name"
              a03_path = ent.definition.get_attribute('dynamic_attributes', "a03_path")
              if a03_path && a03_path == "Slab"
                @formlabel = @formlabel + translation_formlabel(' (_Фрезеровка; без "_" - "Модерн")')
              end
            end
            value_mm = round_without_zero(value.to_f*25.4, 1)
            value = converter(value, units, formulaunits)
            value = "=" + value.to_s if formula && formula.to_f == value.to_f/10
            vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, att_formula.to_s]
            command = "attribute_list(#{vend.inspect})"
            $dlg_suf.execute_script(command)
            if attr == "a00_lenz"
              len_att = nil
              if ent.definition.get_attribute("dynamic_attributes", "point_y_offset")
                len_att = "a00_leny"
                elsif ent.definition.get_attribute("dynamic_attributes", "point_x_offset")
                len_att = "a00_lenx"
                elsif ent.definition.get_attribute("dynamic_attributes", "point_z_offset")
                len_att = "a00_lenz"
              end
              if len_att && !ent.definition.get_attribute("dynamic_attributes", "a01_gluing")
                if value_mm.to_s == "32" || value_mm.to_s == "36"
                  set_att(ent,"a01_gluing",2,nil,"LIST",translation_formlabel('Склейка'),"FLOAT","STRING",'IF(OR(ROUND('+len_att+',1)=3.2,ROUND('+len_att+',1)=3.6),2,1)',"&Нет=1&х2=2&х3=3&х4=4&")
                  else
                  set_att(ent,"a01_gluing",1,nil,"LIST",translation_formlabel('Склейка'),"FLOAT","STRING",'IF(OR(ROUND('+len_att+',1)=3.2,ROUND('+len_att+',1)=3.6),2,1)',"&Нет=1&х2=2&х3=3&х4=4&")
                end
                @options_typ, @options_val = options_array(ent, "a01_gluing","=", "STRING","&Нет=1&х2=2&х3=3&х4=4&")
                vend = ["a01_gluing", "LIST", translation_formlabel('Склейка'), "STRING", "1", @options_typ, @options_val, false, ""]
                command = "attribute_list(#{vend.inspect})"
                $dlg_suf.execute_script(command)
              end
            end
          end
          elsif access == "CHECKBOX"
          vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
          command = "attribute_list(#{vend.inspect})"
          $dlg_suf.execute_script(command)
          elsif access == "VIEW"
          value = converter(value, units, formulaunits)
          vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
          command = "attribute_list(#{vend.inspect})"
          $dlg_suf.execute_script(command)
          if attr == "y0"
            vend = ["y0_edit", "VIEW", translation_formlabel('Список фурнитуры/крепежа'), "STRING", translation_formlabel('Редактировать'), 0, 0, hide, ""]
            command = "attribute_list(#{vend.inspect})"
            $dlg_suf.execute_script(command)
          end
        end
        all_att_hash[attr] = attributes_hash
      }
      if @att_mode == "advanced" && @list_of_hidden_att != []
        advanced = ent.definition.get_attribute("dynamic_attributes", "zzz_advanced")
        advanced = "&#9654;" if !advanced
        set_att(ent, "zzz_advanced", advanced, "zzz_advanced", "VIEW", "<font color=cc6600><b>Дополнительные параметры<b></font>", nil, "STRING")
        hide = false
        $dlg_suf.execute_script("attribute_list(#{["zzz_advanced", "VIEW", translation_formlabel('Дополнительные параметры'), "CENTIMETERS", advanced, 0, 0, hide, ""].inspect})")
        @list_of_hidden_att.each { |attr|
          @formlabel = @hidden_att[attr]
          formula = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formula")
          @formlabel = @formlabel + " *" if formula
          formulaunits = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formulaunits","0")
          units = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_units","0")
          access = @hidden_att[attr+"_access"]
          @options_typ = "0"
          @options_val = "0"
          if access == "LIST"
            options = @hidden_att[attr+"_option"]
            @options_typ, @options_val = options_array(ent,attr,"=",formulaunits,options)
          end
          if attr == "material"
            value = ent.material.display_name
            else
            #value = ent.definition.get_attribute("dynamic_attributes","_" + attr + "_nominal")
            #if !value || value == 0
            value = ent.get_attribute("dynamic_attributes", attr)
            if !value
              value = ent.definition.get_attribute("dynamic_attributes", attr)
              value = 0 if !value
            end
            #end
          end
          if attr == "edge_y1" && value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_y1_length", "0").to_f == 0
            value = "0"
          end
          if attr == "edge_y2" && value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_y2_length", "0").to_f == 0
            value = "0"
          end
          if attr == "edge_z1" && value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_z1_length", "0").to_f == 0
            value = "0"
          end
          if attr == "edge_z2" && value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_z2_length", "0").to_f == 0
            value = "0"
          end
          if access == "LIST"
            value = round_without_zero(value.to_f*25.4,1) if formulaunits == "CENTIMETERS"
            else
            value = round_without_zero(value.to_f*10,2) if !attr.include?("edge")
            value = round_without_zero(value.to_f*2.54,1) if formulaunits == "CENTIMETERS"
            value = value.to_s+" mm" if !attr.include?("edge")
          end
          value = value.to_f.round.to_s if is_number?(value)
          vend = [attr+"_|_"+access[0..3], access, @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide, ""]
          command = "attribute_list(#{vend.inspect})"
          $dlg_suf.execute_script(command)
        }
        else
        ent.delete_attribute("dynamic_attributes", "zzz_advanced")
        ent.definition.delete_attribute("dynamic_attributes", "zzz_advanced")
        ent.definition.delete_attribute("dynamic_attributes", "_zzz_advanced_label")
        ent.definition.delete_attribute("dynamic_attributes", "_zzz_advanced_access")
        ent.definition.delete_attribute("dynamic_attributes", "_zzz_advanced_formlabel")
        ent.definition.delete_attribute("dynamic_attributes", "_zzz_advanced_units")
      end
      command = "hidden_rows()"
      $dlg_suf.execute_script(command)
      set_attributes_hash(all_att_hash)
    end#def
    def translation_formlabel(formlabel)
      if SUF_ATT_STR.strings != {}
        SUF_ATT_STR.strings.each_pair{|str,trans|
          if formlabel.include?(str) && !letter?(formlabel[formlabel.index(str)+str.length])
            formlabel = formlabel.gsub(str,trans)
          end
        }
      end
      return formlabel
    end#def
    def is_number?(str)
      str.to_f.to_s == str.to_s || str.to_i.to_s == str.to_s ? true : false
    end#def
    def letter?(lookAhead)
      lookAhead.to_s =~ /[A-Za_zА-Яа-яЁё]/
    end#def
    def edit_name_list(file_name)
      @additional_list = ""
      path_param = nil
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,file_name))
        path_param = File.join(param_temp_path,file_name)
        elsif File.file?(File.join(PATH_COMP,file_name))
        path_param = File.join(PATH_COMP,file_name)
        elsif File.file?(File.join(TEMP_PATH,"SUF",file_name))
        path_param = File.join(TEMP_PATH,"SUF",file_name)
        else
        path_param = File.join(PATH,"parameters",file_name)
      end
      if path_param
        @additional_list = File.read(path_param)
        html = "<html><head>"
        html += "<meta charset=\"utf-8\">"
        html += "<title>Edit</title>"
        html += "<style>"
        html += "body { font-family: Arial; color: #696969; font-size: 12px; padding-bottom: 30px;}"
        html += ".text1 { width: 100%; height: 100%; font-size: 12px;}"
        html += ".footer { position: fixed; bottom: 0px; left: 0px; width: 100%; background-color: #FFFFFF; border-top: 1px solid #ccc; text-align: center; }"
        html += ".save { margin: 5px; height: 25px; background-color: #e08120; cursor: pointer; border: 1px solid transparent; color: #000000;}"
        html += ".save:hover { background-color: #c46500; }"
        html += "</style></head><body>"
        html += "<script>"
        html += "function save() { sketchup.save(document.getElementById(\"text1\").value); }"
        html += "</script>"
        html += "<textarea class=\"text1\" id=\"text1\">#{@additional_list}</textarea>"
        html += "<div class=\"footer\" >"
        html += "<button class=\"save\" onclick=\"save();\">#{SUF_STRINGS["Save"]}</button>"
        html += "</div>"
        html += "</body></html>"
        @edit_dlg = UI::HtmlDialog.new({
          :dialog_title => SUF_STRINGS["Edit_name_list"],
          :preferences_key => "Edit_name_list",
          :scrollable => true,
          :resizable => true,
          :width => 300,
          :height => 500,
          :left => 100,
          :top => 200,
          :min_width => 300,
          :min_height => 300,
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
        @edit_dlg.add_action_callback('save') { |web_dialog,action_name|
          if param_temp_path
            path_param = File.join(param_temp_path,file_name)
            else
            path_param = File.join(TEMP_PATH,"SUF",file_name)
          end
          File.write(path_param, action_name)
          @edit_dlg.close
        }
        @edit_dlg.set_html(html)
        @edit_dlg && (@edit_dlg.visible?) ? @edit_dlg.bring_to_front : @edit_dlg.show
      end
    end#def
    def delete_section(section_name)
      if section_name.include?("_panel_section_")
        number = section_name.split("_panel_section_")[1]
        e = @panel_sections[number.to_i]
        e.erase!
        elsif section_name.include?("_shelve_section_")
        number = section_name.split("_shelve_section_")[1]
        e = @shelve_sections[number.to_i]
        e.erase!
        elsif section_name.include?("_drawer_section_")
        number = section_name.split("_drawer_section_")[1]
        e = @drawer_sections[number.to_i]
        e.erase!
        elsif section_name.include?("_accessory_section_")
        number = section_name.split("_accessory_section_")[1]
        e = @accessory_sections[number.to_i]
        e.erase!
        elsif section_name.include?("_frontal_section_")
        number = section_name.split("_frontal_section_")[1]
        e = @frontal_sections[number.to_i]
        e.erase!
      end
      Sketchup.active_model.select_tool(nil)
      $dlg_att.execute_script("add_comp()") if $dlg_att
    end#def
    def draw_section(section_name)
      if section_name.include?("_panel_section_")
        number = section_name.split("_panel_section_")[1]
        e = @panel_sections[number.to_i]
        if section_name.include?("c2_panel") || section_name.include?("h2_dimension")
          str = section_name.include?("c2_panel") ? "c2_panel" : "h2_dimension"
          att = section_name.split("_panel_section_")[0]
          niche = att.split(str)[1]
          if e.definition.get_attribute("dynamic_attributes", "c1_panel_position") # секция фронтальная
            thick = e.definition.get_attribute("dynamic_attributes", "b1_p_width").to_f
            else
            thick = e.definition.get_attribute("dynamic_attributes", "b1_p_thickness").to_f
          end
          trim_x1 = e.definition.get_attribute("dynamic_attributes", "trim_x1").to_f
          x1 = e.definition.get_attribute("dynamic_attributes", "c2_panel"+(niche.to_i-1).to_s+"z").to_f
          x1 += thick if niche != "1"
          x2 = e.definition.get_attribute("dynamic_attributes", "c2_panel"+(niche.to_i).to_s+"z").to_f
          pts = comp_bound_pts(e,x1+trim_x1,x2+trim_x1)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
          else
          pts = comp_bound_pts(e)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
        end
        elsif section_name.include?("_shelve_section_")
        number = section_name.split("_shelve_section_")[1]
        e = @shelve_sections[number.to_i]
        if section_name.include?("c2_shelve") || section_name.include?("h2_dimension")
          str = section_name.include?("c2_shelve") ? "c2_shelve" : "h2_dimension"
          att = section_name.split("_shelve_section_")[0]
          niche = att.split(str)[1]
          thick = e.definition.get_attribute("dynamic_attributes", "b1_p_thickness").to_f
          trim_z2 = e.definition.get_attribute("dynamic_attributes", "trim_z2").to_f
          z1 = e.definition.get_attribute("dynamic_attributes", "c2_shelve"+(niche.to_i-1).to_s+"z").to_f
          z1 += thick if niche != "1"
          z2 = e.definition.get_attribute("dynamic_attributes", "c2_shelve"+(niche.to_i).to_s+"z").to_f
          pts = comp_bound_pts(e,nil,nil,nil,nil,z1+trim_z2,z2+trim_z2)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
          else
          pts = comp_bound_pts(e)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
        end
        elsif section_name.include?("_drawer_section_")
        number = section_name.split("_drawer_section_")[1]
        e = @drawer_sections[number.to_i]
        if section_name.include?("d2_drawer")
          att = section_name.split("_drawer_section_")[0]
          niche = att.split("d2_drawer")[1]
          thick = e.definition.get_attribute("dynamic_attributes", "b1_p_thickness").to_f
          trim_z2 = e.definition.get_attribute("dynamic_attributes", "trim_z2").to_f
          z1 = e.definition.get_attribute("dynamic_attributes", "d2_drawer"+(niche.to_i).to_s+"z").to_f
          z1 += thick if niche != "1"
          z2 = e.definition.get_attribute("dynamic_attributes", "d2_drawer"+(niche.to_i+1).to_s+"z").to_f
          pts = comp_bound_pts(e,nil,nil,nil,nil,z1+trim_z2,z2+trim_z2)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
          else
          pts = comp_bound_pts(e)
          Draw_Section.import_pts(pts)
          Sketchup.active_model.select_tool( Draw_Section )
        end
        elsif section_name.include?("_accessory_section_")
        number = section_name.split("_accessory_section_")[1]
        e = @accessory_sections[number.to_i]
        pts = comp_bound_pts(e)
        Draw_Section.import_pts(pts)
        Sketchup.active_model.select_tool( Draw_Section )
        elsif section_name.include?("_frontal_section_")
        number = section_name.split("_frontal_section_")[1]
        e = @frontal_sections[number.to_i]
        pts = comp_bound_pts(e)
        Draw_Section.import_pts(pts)
        Sketchup.active_model.select_tool( Draw_Section )
      end
    end#def
    def comp_bound_pts(entity, x1 = nil, x2 = nil, y1 = nil, y2 = nil, z1 = nil, z2 = nil)
      @pts = []
      if entity.definition.name.include?("Aventos HF") || entity.definition.get_attribute("dynamic_attributes", "b4_height_corob_trim_z2")
        e = entity
        else
        e = entity.definition.entities.grep(Sketchup::ComponentInstance).find { |ent| ent.definition.name.include?("Body") }
      end
      return @pts unless e
      bounds = e.bounds
      pts = (0..7).map { |i| bounds.corner(i) }
      pts.values_at(0, 2, 4, 6).each { |p| p.x = x1 } if x1
      pts.values_at(1, 3, 5, 7).each { |p| p.x = x2 } if x2
      pts.values_at(0, 1, 2, 3).each { |p| p.z = z1 } if z1
      pts.values_at(4, 5, 6, 7).each { |p| p.z = z2 } if z2
      @pts = [
        [pts[0], pts[1], pts[5], pts[4]],
        [pts[0], pts[1], pts[3], pts[2]],
        [pts[0], pts[2], pts[6], pts[4]],
        [pts[7], pts[6], pts[4], pts[5]],
        [pts[7], pts[5], pts[1], pts[3]],
        [pts[7], pts[6], pts[2], pts[3]]
      ]
      tr = @section_and_tr[entity]
      @pts.map! { |pts| pts.map! { |pt| pt.transform(tr) } }
      @pts
    end
    def len_formula(entity)
      if entity.definition.get_attribute("dynamic_attributes", "_lenx_formula", "0").gsub('&quot;','"') == 'IF(CURRENT("LenX")*2.54=a00_lenx,SETLEN("a00_lenx",IF(CURRENT("LenX")*2.54<x_min_x,x_min_x,IF(CURRENT("LenX")*2.54>x_max_x,x_max_x,ROUND(CURRENT("LenX")*2.54,1)))),a00_lenx)'
        entity.definition.set_attribute("dynamic_attributes", "_lenx_formula", 'IF(CURRENT("LenX")*2.54=a00_lenx,SETLEN("a00_lenx",IF(CURRENT("LenX")*2.54<x_min_x,x_min_x,IF(CURRENT("LenX")*2.54>x_max_x,x_max_x,ROUND(CURRENT("LenX")*2.54,1))),IF(CURRENT("LenX")*2.54>x_max_x,2,3)),a00_lenx)')
      end
      if entity.definition.get_attribute("dynamic_attributes", "_x_max_x_formula", "0") == 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_y1+trim_y2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_z1+trim_z2)')
        elsif entity.definition.get_attribute("dynamic_attributes", "_x_max_x_formula", "0") == 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_z1+trim_z2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_y1+trim_y2)')
      end
      if entity.definition.get_attribute("dynamic_attributes", "_leny_formula", "0").gsub('&quot;','"') == 'IF(CURRENT("LenY")*2.54=a00_leny,SETLEN("a00_leny",IF(CURRENT("LenY")*2.54<x_min_y,x_min_y,IF(CURRENT("LenY")*2.54>x_max_y,x_max_y,ROUND(CURRENT("LenY")*2.54,1)))),a00_leny)'
        entity.definition.set_attribute("dynamic_attributes", "_leny_formula", 'IF(CURRENT("LenY")*2.54=a00_leny,SETLEN("a00_leny",IF(CURRENT("LenY")*2.54<x_min_y,x_min_y,IF(CURRENT("LenY")*2.54>x_max_y,x_max_y,ROUND(CURRENT("LenY")*2.54,1))),IF(CURRENT("LenY")*2.54>x_max_y,2,3)),a00_leny)')
      end
      if entity.definition.get_attribute("dynamic_attributes", "_x_max_y_formula", "0") == 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_y1+trim_y2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_y_formula", 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_z1+trim_z2)')
        elsif entity.definition.get_attribute("dynamic_attributes", "_x_max_y_formula", "0") == 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_y1+trim_y2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_y_formula", 'CHOOSE(napr_texture,z_max_width+trim_z1+trim_z2,z_max_length+trim_z1+trim_z2)')
      end
      if entity.definition.get_attribute("dynamic_attributes", "_lenz_formula", "0").gsub('&quot;','"') == 'IF(CURRENT("LenZ")*2.54=a00_lenz,SETLEN("a00_lenz",IF(CURRENT("LenZ")*2.54<x_min_z,x_min_z,IF(CURRENT("LenZ")*2.54>x_max_z,x_max_z,ROUND(CURRENT("LenZ")*2.54,1)))),a00_lenz)'
        entity.definition.set_attribute("dynamic_attributes", "_lenz_formula", 'IF(CURRENT("LenZ")*2.54=a00_lenz,SETLEN("a00_lenz",IF(CURRENT("LenZ")*2.54<x_min_z,x_min_z,IF(CURRENT("LenZ")*2.54>x_max_z,x_max_z,ROUND(CURRENT("LenZ")*2.54,1))),IF(CURRENT("LenZ")*2.54>x_max_z,2,3)),a00_lenz)')
      end
      if entity.definition.get_attribute("dynamic_attributes", "_x_max_z_formula", "0") == 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_z1+trim_z2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_z_formula", 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_y1+trim_y2)')
        elsif entity.definition.get_attribute("dynamic_attributes", "_x_max_z_formula", "0") == 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_z1+trim_z2)'
        entity.definition.set_attribute("dynamic_attributes", "_x_max_z_formula", 'CHOOSE(napr_texture,z_max_length+trim_y1+trim_y2,z_max_width+trim_y1+trim_y2)')
      end
    end#def
    def get_position(ent,origin)
      position = []
      all_axis = ["x","y","z"]
      all_axis.each { |axis|
        case axis
          when "x" then origin_point = origin.x; bounds_size = Redraw_Components.get_attribute_value(ent.parent.instances[-1],'lenx').to_f
          when "y" then origin_point = origin.y; bounds_size = Redraw_Components.get_attribute_value(ent.parent.instances[-1],'leny').to_f
          when "z" then origin_point = origin.z; bounds_size = Redraw_Components.get_attribute_value(ent.parent.instances[-1],'lenz').to_f
        end
        if (origin_point*25.4+0.01).round(1) == (bounds_size*25.4+0.01).round(1)
          position << "3"
          elsif (origin_point*25.4+0.01).round(1) == ((bounds_size*25.4+0.01).round(1))/2
          position << "2"
          elsif (origin_point*25.4+0.01).round(1) == 0
          position << "1"
          else
          position << "0"
        end
      }
      return position
    end#def
    def set_position_att()
      if !Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).empty?
        Sketchup.active_model.start_operation('Set position attributes', true)
        Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).each { |ent|
          Redraw_Components.delete_cascading_attribute(ent,'o0') if ent.definition.get_attribute("dynamic_attributes", "o0")
          Redraw_Components.delete_cascading_attribute(ent,'o0_rotation_x') if ent.definition.get_attribute("dynamic_attributes", "o0_rotation_x")
          Redraw_Components.delete_cascading_attribute(ent,'o0_rotation_y') if ent.definition.get_attribute("dynamic_attributes", "o0_rotation_y")
          Redraw_Components.delete_cascading_attribute(ent,'o0_rotation_z') if ent.definition.get_attribute("dynamic_attributes", "o0_rotation_z")
          
          Redraw_Components.delete_cascading_attribute(ent,'o2') if ent.definition.get_attribute("dynamic_attributes", "o2")
          Redraw_Components.delete_cascading_attribute(ent,'o2_rotation_x') if ent.definition.get_attribute("dynamic_attributes", "o2_rotation_x")
          Redraw_Components.delete_cascading_attribute(ent,'o2_rotation_y') if ent.definition.get_attribute("dynamic_attributes", "o2_rotation_y")
          Redraw_Components.delete_cascading_attribute(ent,'o2_rotation_z') if ent.definition.get_attribute("dynamic_attributes", "o2_rotation_z")
          
          Redraw_Components.delete_cascading_attribute(ent,'o1') if ent.definition.get_attribute("dynamic_attributes", "o1") && ent.definition.get_attribute("dynamic_attributes", "_o1_formlabel") != '<font color=cc6600><b>Оси привязки<b></font>'
          Redraw_Components.delete_cascading_attribute(ent,'o1_position_x') if ent.definition.get_attribute("dynamic_attributes", "o1_position_x")
          Redraw_Components.delete_cascading_attribute(ent,'o1_position_y') if ent.definition.get_attribute("dynamic_attributes", "o1_position_y")
          Redraw_Components.delete_cascading_attribute(ent,'o1_position_z') if ent.definition.get_attribute("dynamic_attributes", "o1_position_z")
          
          if !ent.definition.get_attribute("dynamic_attributes", "a00_lenx") && !ent.definition.get_attribute("dynamic_attributes", "a00_leny") && !ent.definition.get_attribute("dynamic_attributes", "a00_lenz")
            if ent.definition.get_attribute("dynamic_attributes", "lenx") && ent.definition.get_attribute("dynamic_attributes", "_lenx_access", "NONE") == "NONE" || !ent.definition.get_attribute("dynamic_attributes", "lenx")
              set_att(ent,"lenx",Redraw_Components.get_live_value(ent,"lenx"),"LenX","TEXTBOX","<font color=cc0000>Длина (LenX)</font>","CENTIMETERS","MILLIMETERS",nil,nil)
            end
            if ent.definition.get_attribute("dynamic_attributes", "leny") && ent.definition.get_attribute("dynamic_attributes", "_leny_access", "NONE") == "NONE" || !ent.definition.get_attribute("dynamic_attributes", "leny")
              set_att(ent,"leny",Redraw_Components.get_live_value(ent,"leny"),"LenY","TEXTBOX","<font color=009900>Ширина (LenY)</font>","CENTIMETERS","MILLIMETERS",nil,nil)
            end
            if ent.definition.get_attribute("dynamic_attributes", "lenz") && ent.definition.get_attribute("dynamic_attributes", "_lenz_access", "NONE") == "NONE" || !ent.definition.get_attribute("dynamic_attributes", "lenz")
              set_att(ent,"lenz",Redraw_Components.get_live_value(ent,"lenz"),"LenZ","TEXTBOX","<font color=0033ff>Высота (LenZ)</font>","CENTIMETERS","MILLIMETERS",nil,nil)
            end
          end
          
          if ent.parent.is_a?(Sketchup::ComponentDefinition)
            tr = Sketchup.active_model.edit_transform
            origin = ent.transformation.origin.transform(tr.inverse)
            x,y,z = get_position(ent,origin)
            set_att(ent,"s1","&#9654;","s1","VIEW",'<font color=cc6600><b>Положение<b></font>',"STRING","STRING") if !ent.definition.get_attribute("dynamic_attributes", "s1")
            set_att(ent,"s1_position_x",x,"s1_position_x","LIST","По <font color=cc0000>оси X</font>","STRING","STRING",nil,'&Слева=1&По центру=2&Справа=3&')
            set_att(ent,"s1_position_x_offset",ent.definition.get_attribute("dynamic_attributes", "s1_position_x_offset", "0"),"s1_position_x_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
            set_att(ent,"s1_position_y",y,"s1_position_y","LIST","По <font color=009900>оси Y</font>","STRING","STRING",nil,'&Спереди=1&По центру=2&Сзади=3&')
            set_att(ent,"s1_position_y_offset",ent.definition.get_attribute("dynamic_attributes", "s1_position_y_offset", "0"),"s1_position_y_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
            set_att(ent,"s1_position_z",z,"s1_position_z","LIST","По <font color=0033ff>оси Z</font>","STRING","STRING",nil,'&Снизу=1&По центру=2&Сверху=3&')
            set_att(ent,"s1_position_z_offset",ent.definition.get_attribute("dynamic_attributes", "s1_position_z_offset", "0"),"s1_position_z_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
            
            set_att(ent,"s2","&#9654;","s2","VIEW",'<font color=cc6600><b>Поворот<b></font>',"STRING","STRING") if !ent.definition.get_attribute("dynamic_attributes", "s2")
            set_att(ent,"s2_rotation_x",ent.transformation.rotx,"s2_rotation_x","TEXTBOX","По <font color=cc0000>оси X</font>","STRING","STRING",nil,nil)
            set_att(ent,"s2_rotation_y",ent.transformation.roty,"s2_rotation_y","TEXTBOX","По <font color=009900>оси Y</font>","STRING","STRING",nil,nil)
            set_att(ent,"s2_rotation_z",ent.transformation.rotz,"s2_rotation_z","TEXTBOX","По <font color=0033ff>оси Z</font>","STRING","STRING",nil,nil)
            
            set_att(ent,"s3","&#9654;","s3","VIEW",'<font color=cc6600><b>Отражение<b></font>',"STRING","STRING") if !ent.definition.get_attribute("dynamic_attributes", "s3")
            set_att(ent,"s3_mirror_x",ent.definition.get_attribute("dynamic_attributes","s3_mirror_x","1"),"s3_mirror_x","LIST","По <font color=cc0000>оси X</font>","STRING","STRING",nil,'&Нет=1&Да=2&')
            set_att(ent,"s3_mirror_y",ent.definition.get_attribute("dynamic_attributes","s3_mirror_y","1"),"s3_mirror_y","LIST","По <font color=009900>оси Y</font>","STRING","STRING",nil,'&Нет=1&Да=2&')
            set_att(ent,"s3_mirror_z",ent.definition.get_attribute("dynamic_attributes","s3_mirror_z","1"),"s3_mirror_z","LIST","По <font color=0033ff>оси Z</font>","STRING","STRING",nil,'&Нет=1&Да=2&')
            
            set_att(ent,"s4","&#9654;","s4","VIEW",'<font color=cc6600><b>Формулы размеров<b></font>',"STRING","STRING") if !ent.definition.get_attribute("dynamic_attributes", "s4")
            set_att(ent,"s4_size_x",ent.definition.get_attribute("dynamic_attributes","s4_size_x","1"),"s4_size_x","LIST","По <font color=cc0000>оси X</font>","STRING","STRING",nil,'&Не менять=1&Текущий=2&parent!LenX=3&parent!LenX/2=4&')
            set_att(ent,"s4_size_y",ent.definition.get_attribute("dynamic_attributes","s4_size_y","1"),"s4_size_y","LIST","По <font color=009900>оси Y</font>","STRING","STRING",nil,'&Не менять=1&Текущий=2&parent!LenY=3&parent!LenY/2=4&')
            set_att(ent,"s4_size_z",ent.definition.get_attribute("dynamic_attributes","s4_size_z","1"),"s4_size_z","LIST","По <font color=0033ff>оси Z</font>","STRING","STRING",nil,'&Не менять=1&Текущий=2&parent!LenZ=3&parent!LenZ/2=4&')
          end
          
          set_att(ent,"s9","&#9654;","s9","VIEW",'<font color=cc6600><b>Компонент<b></font>',"STRING","STRING") if !ent.definition.get_attribute("dynamic_attributes", "s9")
          set_att(ent,"s9_comp_axis","Показать/Скрыть","s9_comp_axis","VIEW","Оси компонентов","STRING","STRING",nil,nil)
          set_att(ent,"s9_comp_copy","+","s9_comp_copy","VIEW","Создать копию","STRING","STRING",nil,nil)
          set_att(ent,"s9_comp_name",ent.definition.name,"s9_comp_name","TEXTBOX","Название","STRING","STRING",nil,nil)
          set_att(ent,'s9_scale_grip',ent.definition.get_attribute("dynamic_attributes", "s9_scale_grip", "X:=>1,Y:=>1,Z:=>1"),'s9_scale_grip',"CHECKBOX",'Ручки масштабирования',"STRING","STRING")
          if !ent.definition.get_attribute("dynamic_attributes", "scaletool")
            set_att(ent,'scaletool',"120","ScaleTool")
            behavior = ent.definition.behavior
            if behavior.respond_to? :no_scale_mask?
              behavior.no_scale_mask = 120
            end
          end
        }
        Sketchup.active_model.commit_operation
        $dlg_att.execute_script("add_comp()") if $dlg_att
        $dlg_suf.execute_script("add_comp()") if $dlg_suf
      end
    end#def
    def panel_sections(sections=nil)
      @panel_sections = sections if sections
      @panel_sections
    end
    def shelve_sections(sections=nil)
      @shelve_sections = sections if sections
      @shelve_sections
    end
    def drawer_sections(sections=nil)
      @drawer_sections = sections if sections
      @drawer_sections
    end
    def accessory_sections(sections=nil)
      @accessory_sections = sections if sections
      @accessory_sections
    end
    def frontal_sections(sections=nil)
      @frontal_sections = sections if sections
      @frontal_sections
    end
    def change_checkbox(param)
      att = param.split('=>')[0]
      @checkbox_att << att
      label = param.split('=>')[1]
      value = param.split('=>')[2]
      Sketchup.active_model.start_operation('change_checkbox', true, false, true)
      ent_arr = []
      if att.include?("_panel_section_")
        attr = att.split("_panel_section_")[0]
        number = att.split("_panel_section_")[1]
        ent_arr << panel_sections[number.to_i]
        
        elsif att.include?("_shelve_section_")
        attr = att.split("_shelve_section_")[0]
        number = att.split("_shelve_section_")[1]
        ent_arr << shelve_sections[number.to_i]
        
        elsif att.include?("_drawer_section_")
        attr = att.split("_drawer_section_")[0]
        number = att.split("_drawer_section_")[1]
        ent_arr << drawer_sections[number.to_i]
        
        elsif att.include?("_accessory_section_")
        attr = att.split("_accessory_section_")[0]
        number = att.split("_accessory_section_")[1]
        ent_arr << accessory_sections[number.to_i]
        
        elsif att.include?("_frontal_section_")
        attr = att.split("_frontal_section_")[0]
        number = att.split("_frontal_section_")[1]
        ent_arr << frontal_sections[number.to_i]
        
        else
        ent_arr = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
        attr = att
      end
      ent_arr.each { |ent|
        des_att = ent.definition.get_attribute("dynamic_attributes", attr)
        att_options = ent.definition.get_attribute("dynamic_attributes", "_#{attr}_options")
        checkbox_array = des_att.split(",")
        checkbox_hash = {}
        checkbox_array.each { |checkbox|
          if checkbox.include?("=>")
            ent_att_label = checkbox.split("=>")[0].to_s
            ent_att_value = checkbox.split("=>")[1].to_s
            if ent_att_label == label
              checkbox_hash[ent_att_label+"=>"] = (value=="true" ? "1" : "0")
              else
              checkbox_hash[ent_att_label+"=>"] = ent_att_value
            end
            else
            if att_options && att_options == "&%u0414%u0430=0&%u041D%u0435%u0442=1&"
              ent_att_label = ""
              ent_att_value = checkbox
              checkbox_hash[ent_att_label] = (value=="true" ? "0" : "1")
              else
              ent_att_label = ""
              ent_att_value = checkbox
              checkbox_hash[ent_att_label] = (value=="true" ? "2" : "1")
            end
          end
        }
        checkbox_string = []
        checkbox_hash.each { |key,val| checkbox_string << key+val }
        ent.definition.set_attribute("dynamic_attributes", attr, checkbox_string.join(","))
        ent.set_attribute("dynamic_attributes", attr, checkbox_string.join(","))
        ent.definition.delete_attribute("dynamic_attributes", "_#{attr}_formula")
        if attr == "s9_scale_grip"
          scaletool_value = get_scaletool_value(checkbox_hash)
          set_att(ent,'scaletool',scaletool_value)
          behavior = ent.definition.behavior
          if behavior.respond_to? :no_scale_mask?
            behavior.no_scale_mask = scaletool_value.to_i
          end
          if $SUFToolsObserver.last_tool_name == 'ScaleTool'
            Sketchup.active_model.select_tool(nil)
            Sketchup.send_action "selectScaleTool:" 
          end
        end
      }
      Sketchup.active_model.commit_operation
    end
    def check_checkbox(ent,att = "s9_scale_grip")
      des_att = ent.definition.get_attribute("dynamic_attributes", att)
      return if !des_att
      checkbox_array = des_att.split(",")
      checkbox_hash = {}
      checkbox_array.each { |checkbox|
        ent_att_label = checkbox.split("=>")[0]
        ent_att_value = checkbox.split("=>")[1]
        checkbox_hash[ent_att_label] = ent_att_value
      }
      if att == "s9_scale_grip"
        scaletool_value = get_scaletool_value(checkbox_hash)
        set_att(ent,'scaletool',scaletool_value)
        behavior = ent.definition.behavior
        if behavior.respond_to? :no_scale_mask?
          behavior.no_scale_mask = scaletool_value.to_i
        end
      end
    end
    def get_scaletool_value(checkbox_hash)
      if checkbox_hash["X:"] == "0" && checkbox_hash["Y:"] == "1" && checkbox_hash["Z:"] == "1"
        scaletool_value = "121"
        elsif checkbox_hash["X:"] == "1" && checkbox_hash["Y:"] == "0" && checkbox_hash["Z:"] == "1"
        scaletool_value = "122"
        elsif checkbox_hash["X:"] == "0" && checkbox_hash["Y:"] == "0" && checkbox_hash["Z:"] == "1"
        scaletool_value = "123"
        elsif checkbox_hash["X:"] == "1" && checkbox_hash["Y:"] == "1" && checkbox_hash["Z:"] == "0"
        scaletool_value = "124"
        elsif checkbox_hash["X:"] == "0" && checkbox_hash["Y:"] == "1" && checkbox_hash["Z:"] == "0"
        scaletool_value = "125"
        elsif checkbox_hash["X:"] == "1" && checkbox_hash["Y:"] == "0" && checkbox_hash["Z:"] == "0"
        scaletool_value = "126"
        elsif checkbox_hash["X:"] == "0" && checkbox_hash["Y:"] == "0" && checkbox_hash["Z:"] == "0"
        scaletool_value = "127"
        else
        scaletool_value = "120"
      end
      return scaletool_value
    end
    def set_position(entity,att=nil,value=nil)
      return unless entity.parent.is_a?(Sketchup::ComponentDefinition)
      if att && value
        set_att(entity, att, value)
      end
      if entity.definition.get_attribute("dynamic_attributes", "s1_position_x") && entity.definition.get_attribute("dynamic_attributes", "s1_position_y") && entity.definition.get_attribute("dynamic_attributes", "s1_position_z")
        tr = Sketchup.active_model.edit_transform
        origin = entity.transformation.origin.transform(tr.inverse)
        dx = compute_position(entity, "x", origin, att)
        dy = compute_position(entity, "y", origin, att)
        dz = compute_position(entity, "z", origin, att)
        translation_vector = Geom::Vector3d.new dx, dy, dz
        translation = Geom::Transformation.translation translation_vector
        entity.transform! translation
      end
    end#def
    def compute_position(entity, axis, origin, att)
      return 0 if !att && entity.definition.get_attribute("dynamic_attributes", "_#{axis}_formula")
      value = entity.definition.get_attribute("dynamic_attributes", "s1_position_#{axis}", "1")
      offset = entity.definition.get_attribute("dynamic_attributes", "s1_position_#{axis}_offset", "0")
      case value
        when "1" then delta = 0 - origin.send("#{axis}")+offset.to_f
        when "2" then delta = Redraw_Components.get_attribute_value(entity.parent.instances[-1],"len#{axis}").to_f/2 - origin.send("#{axis}")+offset.to_f
        when "3" then delta = Redraw_Components.get_attribute_value(entity.parent.instances[-1],"len#{axis}").to_f - origin.send("#{axis}")+offset.to_f
        else delta = 0
      end
      if att && att.include?(axis)
        Redraw_Components.delete_cascading_attribute(entity,"_inst__#{axis}_formula")
        Redraw_Components.delete_cascading_attribute(entity,"_#{axis}_formula")
        Redraw_Components.delete_cascading_attribute(entity,"_#{axis}_error")
      end
      return delta
    end#def
    def set_rotation(entity, att, value)
      set_att(entity, att, value)
      entity.transformation = Geom::Transformation.new(entity.transformation.origin, Z_AXIS)
      target_rotations = %w[s2_rotation_x s2_rotation_y s2_rotation_z].map { |attr|
        Redraw_Components.get_attribute_value(entity, attr).to_f
      }
      rotate_transform(entity, *target_rotations)      
      %w[rotx roty rotz].each { |axis|
        %W[_inst__#{axis}_formula _#{axis}_formula _#{axis}_error].each { |attr|
          Redraw_Components.delete_cascading_attribute(entity, attr)
        }
      }
    end#def
    def rotate_transform(entity, target_rotx, target_roty, target_rotz)
      axes = { x: entity.transformation.xaxis, y: entity.transformation.yaxis, z: entity.transformation.zaxis }
      rotations = { x: target_rotx, y: target_roty, z: target_rotz }
      axes.each do |key, axis|
        next unless axis.length > 0
        radians = rotations[key] * (Math::PI / 180)
        transformation = Geom::Transformation.rotation(entity.transformation.origin, axis, radians)
        entity.transform!(transformation)
      end
    end#def
    def set_mirror(entity, att, value)
      axes = { "s3_mirror_x" => :x, "s3_mirror_y" => :y, "s3_mirror_z" => :z }
      return unless axes.key?(att)
      reflected = (entity.transformation.xaxis * entity.transformation.yaxis).samedirection?(entity.transformation.zaxis)
      scale = (reflected ? value == "2" : value == "1") ? -1 : 1
      scale_factors = { x: 1, y: 1, z: 1 }
      scale_factors[axes[att]] = scale
      tr = Geom::Transformation.scaling(entity.transformation.origin, scale_factors[:x], scale_factors[:y], scale_factors[:z])
      entity.transform!(tr)
      set_att(entity, att, value)
    end#def
    def set_len_formula(entity,att,value)
      case value
        when "2" then set_att(entity,"len#{att[-1]}",nil,nil,nil,nil,nil,nil,(Redraw_Components.get_live_value(entity,"len#{att[-1]}")*2.54).round(2).to_s,nil)
        when "3" then set_att(entity,"len#{att[-1]}",nil,nil,nil,nil,nil,nil,"parent!len#{att[-1]}")
        when "4" then set_att(entity,"len#{att[-1]}",nil,nil,nil,nil,nil,nil,"parent!len#{att[-1]}/2")
      end
    end#def
    def axis_comp()
      Sketchup.active_model.rendering_options["DisplayInstanceAxes"] ? Sketchup.active_model.rendering_options["DisplayInstanceAxes"] = false : Sketchup.active_model.rendering_options["DisplayInstanceAxes"] = true
    end#def
    def copy_comp()
      Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).each { |ent|
        new_comp = ent.parent.entities.add_instance(ent.definition,ent.transformation.origin)
        new_comp.make_unique
      }
    end#def
    def reset_size_values
      selection = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      if !selection.empty?
        Sketchup.active_model.start_operation "Reset size values", true
        selection.each { |ent| reset_all_size_values(ent) }
        Sketchup.active_model.commit_operation
      end
    end#def
    def reset_all_size_values(entity,redraw=true)
      local_width,local_height,local_depth = bounds_size(entity.definition.entities,true)
      reset_size_att(entity,"lenx",local_width)
      reset_size_att(entity,"leny",local_height)
      reset_size_att(entity,"lenz",local_depth)
      Redraw_Components.redraw_entities_with_Progress_Bar([entity]) if redraw
    end#def
    def bounds_size(entities,take_shell)
      bb = Geom::BoundingBox.new
      entities.each { |entity|
        next if entity.is_a?(Sketchup::Group) && entity.name == "shell" && !take_shell
        bb.add(entity.bounds) if entity.respond_to?(:bounds)
      }
      local_width = get_size(bb.corner(0),bb.corner(1),"x")
      local_height = get_size(bb.corner(0),bb.corner(2),"y")
      local_depth = get_size(bb.corner(0),bb.corner(4),"z")
      return local_width,local_height,local_depth
    end#def
    def get_size(pt1,pt2,axis)
      pt2.send("#{axis}") - pt1.send("#{axis}")
    end#def
    def reset_size_att(entity, att, value)
      entity.definition.set_attribute('dynamic_attributes', "_#{att}_nominal", value)
      set_att(entity,att,value)
      return true
    end#def
    def set_len_value(entity, att, value)
      entity.set_attribute("dynamic_attributes", att, value)
      entity.definition.set_attribute("dynamic_attributes", att, value)
      return true
    end#def
    def size_values(entity,sizes={})
      change_size_values(entity,sizes)
    end
    def change_size_values(entity,sizes,is_recursive_call=false)
      if entity.is_a?(Sketchup::ComponentInstance)
        redraw = false
        visual_lenx,visual_leny,visual_lenz = entity.scaled_size
        if entity.definition.get_attribute('dynamic_attributes', "_lenx_access", "NONE") != "NONE"
          redraw = set_len_value(entity, "lenx", ((visual_lenx*25.4).round(2))/25.4) if !is_recursive_call
          if entity.definition.get_attribute('dynamic_attributes', "z_max_length")
            entity.definition.delete_attribute('dynamic_attributes', "_lenx_nominal")
            lenx = Redraw_Components.get_attribute_value(entity,'lenx').to_f
            z_max_length = entity.definition.get_attribute('dynamic_attributes', "z_max_length")
            z_min_length = entity.definition.get_attribute('dynamic_attributes', "z_min_length")
            redraw = set_len_value(entity,"lenx",z_max_length) if z_max_length && lenx > z_max_length
            redraw = set_len_value(entity,"lenx",z_min_length) if z_min_length && lenx < z_min_length
          end
        end
        if entity.definition.get_attribute('dynamic_attributes', "_leny_access", "NONE") != "NONE"
          redraw = set_len_value(entity, "leny", ((visual_leny*25.4).round(2))/25.4) if !is_recursive_call
          if entity.definition.get_attribute('dynamic_attributes', "z_max_width")
            entity.definition.delete_attribute('dynamic_attributes', "_leny_nominal")
            leny = Redraw_Components.get_attribute_value(entity,'leny').to_f
            z_max_width = entity.definition.get_attribute('dynamic_attributes', "z_max_width")
            z_min_width = entity.definition.get_attribute('dynamic_attributes', "z_min_width")
            redraw = set_len_value(entity,"leny",z_max_width) if z_max_width && leny > z_max_width
            redraw = set_len_value(entity,"leny",z_min_width) if z_min_width && leny < z_min_width
          end
        end
        if entity.definition.get_attribute('dynamic_attributes', "_lenz_access", "NONE") != "NONE"
          redraw = set_len_value(entity, "lenz", ((visual_lenz*25.4).round(2))/25.4) if !is_recursive_call
          if entity.definition.get_attribute('dynamic_attributes', "z_max_height")
            entity.definition.delete_attribute('dynamic_attributes', "_lenz_nominal")
            lenz = Redraw_Components.get_attribute_value(entity,'lenz').to_f
            z_max_height = entity.definition.get_attribute('dynamic_attributes', "z_max_height")
            z_min_height = entity.definition.get_attribute('dynamic_attributes', "z_min_height")
            redraw = set_len_value(entity,"lenz",z_max_height) if z_max_height && lenz > z_max_height
            redraw = set_len_value(entity,"lenz",z_min_height) if z_min_height && lenz < z_min_height
          end
        end
        if redraw
          redraw_size(entity)
          else
          Redraw_Components.run_visible_attributes_formulas(entity)
        end
        scale_essence(entity,sizes[entity]) if sizes.keys.include?(entity)
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| change_size_values(e,sizes,true) }
        if !is_recursive_call && 2==1
          local_width,local_height,local_depth = bounds_size(entity.definition.entities,true)
          if entity.definition.get_attribute('dynamic_attributes', "_lenx_access", "NONE") != "NONE" && !entity.definition.get_attribute('dynamic_attributes', "_lenx_formula")
            lenx = Redraw_Components.get_attribute_value(entity,'lenx').to_f
            reset_size_att(entity,"lenx",local_width) if (lenx*25.4).round(3) > (local_width*25.4).round(3) || (lenx*25.4).round(3) < (local_width*25.4).round(3)
          end
          if entity.definition.get_attribute('dynamic_attributes', "_leny_access", "NONE") != "NONE" && !entity.definition.get_attribute('dynamic_attributes', "_leny_formula")
            leny = Redraw_Components.get_attribute_value(entity,'leny').to_f
            reset_size_att(entity,"leny",local_height) if (leny*25.4).round(3) > (local_height*25.4).round(3) || (leny*25.4).round(3) < (local_height*25.4).round(3)
          end
          if entity.definition.get_attribute('dynamic_attributes', "_lenz_access", "NONE") != "NONE" && !entity.definition.get_attribute('dynamic_attributes', "_lenz_formula")
            lenz = Redraw_Components.get_attribute_value(entity,'lenz').to_f
            reset_size_att(entity,"lenz",local_depth) if (lenz*25.4).round(3) > (local_depth*25.4).round(3) || (lenz*25.4).round(3) < (local_depth*25.4).round(3)
          end
        end
        set_position(entity)
      end
      return true
    end#def
    def set_att(e,att,value,label=nil,access=nil,formlabel=nil,formulaunits=nil,units=nil,formula=nil,options=nil)
      e.set_attribute('dynamic_attributes', att, value) if value
      e.definition.set_attribute('dynamic_attributes', att, value) if value
      if label
        e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label)
        else
        if att.downcase == "lenx" || att.downcase == "leny" || att.downcase == "lenz" || att.downcase == "x" || att.downcase == "y" || att.downcase == "z"
          else
          e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
        end
      end
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
      if formula
        e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula)
        if att.downcase == "lenx" || att.downcase == "leny" || att.downcase == "lenz" || att.downcase == "x" || att.downcase == "y" || att.downcase == "z"
          e.set_attribute('dynamic_attributes', "_"+att+"_formula", formula)
        end
      end
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end#def
    def redraw_size(entity)
      if entity.is_a?(Sketchup::ComponentInstance)
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
      nominal_lenx = Redraw_Components.get_attribute_value(entity,'lenx').to_f
      nominal_leny = Redraw_Components.get_attribute_value(entity,'leny').to_f
      nominal_lenz = Redraw_Components.get_attribute_value(entity,'lenz').to_f
      nominal_lenx = Redraw_Components.second_if_nan(nominal_lenx,0.0)
      nominal_leny = Redraw_Components.second_if_nan(nominal_leny,0.0)
      nominal_lenz = Redraw_Components.second_if_nan(nominal_lenz,0.0)
      new_lenx = nominal_lenx * xscale
      new_leny = nominal_leny * yscale
      new_lenz = nominal_lenz * zscale
      Redraw_Components.store_nominal_size(entity,new_lenx,new_leny,new_lenz)
      target_lenx = Redraw_Components.second_if_empty(Redraw_Components.get_formula_result(entity,'lenx'), new_lenx).to_f
      target_leny = Redraw_Components.second_if_empty(Redraw_Components.get_formula_result(entity,'leny'), new_leny).to_f
      target_lenz = Redraw_Components.second_if_empty(Redraw_Components.get_formula_result(entity,'lenz'), new_lenz).to_f
      Redraw_Components.store_nominal_size(entity,target_lenx,target_leny,target_lenz)
      Redraw_Components.run_all_formulas(entity)
      Redraw_Components.fix_float(nominal_lenx) == 0.0 ? dlenx = 1.0 : dlenx = target_lenx/nominal_lenx
      Redraw_Components.fix_float(nominal_leny) == 0.0 ? dleny = 1.0 : dleny = target_leny/nominal_leny
      Redraw_Components.fix_float(nominal_lenz) == 0.0 ? dlenz = 1.0 : dlenz = (target_lenz/nominal_lenz)
      dlenx = 0.001 if dlenx == 0.0
      dleny = 0.001 if dleny == 0.0
      dlenz = 0.001 if dlenz == 0.0
      subentity_transform = Geom::Transformation.scaling definition_origin, dlenx, dleny, dlenz
      if dlenx != 1.0 || dleny != 1.0 || dlenz != 1.0
        naked_entities = []
        subentities.each { |subentity|
          if subentity.is_a?(Sketchup::ComponentInstance)
            subentity.transform! subentity_transform
            elsif subentity.is_a?(Sketchup::Group)
            subentity.transform! subentity_transform
            subentity.material = entity.material
            elsif subentity.is_a?(Sketchup::Face)
            naked_entities.push subentity
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
      new_lenx = $dc_observers.get_latest_class.second_if_empty($dc_observers.get_latest_class.get_forced_config_value(entity, 'lenx'),new_lenx)
      new_leny = $dc_observers.get_latest_class.second_if_empty($dc_observers.get_latest_class.get_forced_config_value(entity, 'leny'),new_leny)
      new_lenz = $dc_observers.get_latest_class.second_if_empty($dc_observers.get_latest_class.get_forced_config_value(entity, 'lenz'),new_lenz)
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
      $dc_observers.get_latest_class.store_nominal_size(entity,new_lenx,new_leny,new_lenz)
      entity.set_last_size(lenx,leny,lenz)
    end
    def fix_float(f)
			return ((f.to_f*10000000.0).round/10000000.0)
    end
    def change_attributes(str)
      @model = Sketchup.active_model
      att_for_change_body = ["c1_left_panel","c2_right_panel","c3_up_panel","c4_down_panel","c4_plint","c5_back","c7_naves","c8_middle_panel","falsh_panel_left","falsh_panel_right"]
      change_carcass_material = nil
      @body1 = nil
      @body2 = nil
      $change_att = true
      att_arr = []
      redraw_section = []
      @model.selection.remove_observer $SUFSelectionObserver
      @model.entities.remove_observer $SUFEntitiesObserver
      @model.start_operation('Change attributes', true)
      for i in 0..str.length-1
        deep = str[i][0..3]
        str_i = str[i][4..str[i].length-1]
        att = str_i.split("=>")[0]
        att_arr << 'a0_shelves_count' if att =~ /a1_up_shelve|a2_down_shelve/i
        value = str_i.split("=>")[1]
        value="" if !value
        formula = nil
        if value[0] == "="
          formula = value[1..-1].strip
          formula = formula.gsub(/(?<=^|[+\-])(\d+(\.\d+)?)(?=$|[^a-zA-Z0-9_])/i) { |num| (num.to_f / 10.0).to_s }
        end
        attr = nil
        if att.include?("_panel_section_")
          attr = att.split("_panel_section_")[0]
          number = att.split("_panel_section_")[1]
          e = @panel_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_shelve_section_")
          attr = att.split("_shelve_section_")[0]
          number = att.split("_shelve_section_")[1]
          e = @shelve_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_drawer_section_")
          attr = att.split("_drawer_section_")[0]
          number = att.split("_drawer_section_")[1]
          e = @drawer_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          if e.definition.get_attribute("dynamic_attributes", "b4_height_corob_trim_z2")
            e.parent.entities.grep(Sketchup::ComponentInstance).each { |entity|
              if entity.definition.get_attribute("dynamic_attributes", "su_type") == "furniture"
                redraw_section << entity if !redraw_section.include?(entity)
              end
            }
          end
          
          elsif att.include?("_accessory_section_")
          attr = att.split("_accessory_section_")[0]
          number = att.split("_accessory_section_")[1]
          e = @accessory_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_frontal_section_")
          attr = att.split("_frontal_section_")[0]
          number = att.split("_frontal_section_")[1]
          e = @frontal_sections[number.to_i]
          if e.parent.get_attribute("dynamic_attributes", "_name", "0").include?("Drawer")
            entity = e.parent.instances[-1]
            entity.definition.delete_attribute("dynamic_attributes", "_d1_type_height_formula") if entity.definition.get_attribute("dynamic_attributes", "_d1_type_height_formula")
            entity.definition.set_attribute("dynamic_attributes", "_d1_type_height_access","TEXTBOX")
            entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_access","LIST")
            entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_options","&Нет=1&Да=2")
            entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_formlabel","Внутренний ящик")
            change_deep(entity, "d1_type_height", value, nil, att_for_change_body, @itemcode_to_name) if attr == "drawer_height"
            att_arr << "d1_type_height"
            entity.definition.entities.grep(Sketchup::ComponentInstance) { |body|
              if body.definition.get_attribute("dynamic_attributes", "d1_type_height")
                body.definition.set_attribute("dynamic_attributes", "_d1_type_height_formula",'LOOKUP("d1_type_height",2)')
              end
            }
            else
            entity = e
          end
          att_arr << attr
          redraw_section << entity if !redraw_section.include?(entity)
        end
        if attr
          if deep != "chck"
            if formula
              e.definition.set_attribute("dynamic_attributes", "_#{attr}_formula",formula)
              else
              attr,delete_hidden,comp_path,change_carcass_material = change_deep(e, attr, value, nil, att_for_change_body, @itemcode_to_name)
            end
          end
        end
      end
      if redraw_section != []
        DCProgressBar::clear()
        redraw_section.each { |e|
          Redraw_Components.redraw(e,true)
        }
        DCProgressBar::clear()
        Change_Point.reset_essence_and_faces
        Change_Point.comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
        Sketchup.active_model.select_tool(nil)
      end
      att_arr = []
      @model.selection.grep(Sketchup::ComponentInstance).each { |ent|
        entities_to_redraw = []
        delete_hidden = false
        comp_path = nil
        item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "")
        len_formula(ent)
        for i in 0..str.length-1
          deep = str[i][0..3]
          str_i = str[i][4..str[i].length-1]
          att = str_i.split("=>")[0]
          if deep == "chck" && !att.include?("_section_")
            att_arr << att
            entities_to_redraw << ent if !entities_to_redraw.include?(ent)
            next
          end
          att_arr << 'a0_shelves_count' if att =~ /a1_up_shelve|a2_down_shelve/i
          value = str_i.split("=>")[1]
          value="" if !value
          make_unique_if_needed(ent)
          if att == "s1_position_x" || att == "s1_position_y" || att == "s1_position_z"
            set_position(ent,att,value)
            next
          end
          if att == "s2_rotation_x" || att == "s2_rotation_y" || att == "s2_rotation_z"
            set_rotation(ent,att,value)
            next
          end
          if att == "s3_mirror_x" || att == "s3_mirror_y" || att == "s3_mirror_z"
            set_mirror(ent,att,value)
            next
          end
          if att == "s4_size_x" || att == "s4_size_y" || att == "s4_size_z"
            set_len_formula(ent,att,value)
          end
          if att == "s9_comp_name"
            ent.definition.name = value
            next
          end
          next if att.include?("_section_")
          if value[0] == "="
            formula = value[1..-1].strip
            formula = formula.gsub(/(?<=^|[+\-])(\d+(\.\d+)?)(?=$|[^a-zA-Z0-9_])/i) { |num| (num.to_f / 10.0).to_s }
            ent.definition.set_attribute("dynamic_attributes", "_#{att}_formula",formula)
            entities_to_redraw << ent if !entities_to_redraw.include?(ent)
            else
            if att.include?("drawer_height")
              if ent.parent.get_attribute("dynamic_attributes", "_name", "0").include?("Drawer")
                entity = ent.parent.instances[-1]
                entity.definition.delete_attribute("dynamic_attributes", "_d1_type_height_formula") if entity.definition.get_attribute("dynamic_attributes", "_d1_type_height_formula")
                set_att(entity, "d1_type_height",value,nil,"TEXTBOX")
                entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_access","LIST")
                entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_options","&Нет=1&Да=2")
                entity.definition.set_attribute("dynamic_attributes", "_d1_type_in_formlabel","Внутренний ящик")
                att_arr << "d1_type_height"
                entities_to_redraw << entity if !entities_to_redraw.include?(entity)
                entity.definition.entities.grep(Sketchup::ComponentInstance) { |body|
                  if body.definition.get_attribute("dynamic_attributes", "d1_type_height")
                    body.definition.set_attribute("dynamic_attributes", "_d1_type_height_formula",'LOOKUP("d1_type_height",2)')
                  end
                }
              end
              attr,delete_hidden,comp_path,change_carcass_material = change_deep(ent, att, value, item_code, att_for_change_body, @itemcode_to_name)
              att_arr << attr
              else
              attr,delete_hidden,comp_path,change_carcass_material = change_deep(ent, att, value, item_code, att_for_change_body, @itemcode_to_name)
              att_arr << attr
              entities_to_redraw << ent if !entities_to_redraw.include?(ent)
            end
          end
        end
        if delete_hidden && @param_delete_hidden == "yes"
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
            if e.definition.name.include?("Body")
              e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
              e.make_unique if e.definition.count_used_instances > 1
              e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
              @body1 = e
              e.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
                if entity.definition.get_attribute("dynamic_attributes", "body_comp")
                  entity.erase!
                end
              }
            end
          }
          if Sketchup.version_number >= 2110000000
            comp = @model.definitions.load(comp_path, allow_newer: true)
            else
            comp = @model.definitions.load comp_path
          end
          t = Geom::Transformation.translation [0, 0, 0]
          inst = ent.definition.entities.add_instance(comp, t)
          inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
          inst.make_unique if inst.definition.count_used_instances > 1
          inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
          tr2 = Geom::Transformation.scaling(Geom::Point3d.new(0, 0, 0), 0.1)
          inst.transform! tr2
          array_of_ents = inst.explode
          array_of_ents.grep( Sketchup::Drawingelement ).to_a.each { |e|
            if e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("Body")
              e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
              e.make_unique if e.definition.count_used_instances > 1
              e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
              @body2 = e
              e.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
                entity.definition.set_attribute("dynamic_attributes", "body_comp", true)
              }
              elsif e.valid?
              e.erase!
            end
          }
        end
        if att_arr.any?{|att|att.include?("handle")}
          cut_att(ent)
        end
        if entities_to_redraw != []
          @sizes = {}
          DCProgressBar::clear()
          entities_to_redraw.each { |e|
            Redraw_Components.redraw(e,true)
          }
          if ent.definition.get_attribute("dynamic_attributes", "b4_height_corob_trim_z2")
            ent.parent.entities.grep(Sketchup::ComponentInstance).each { |e|
              if e.definition.get_attribute("dynamic_attributes", "su_type") == "furniture"
                Redraw_Components.redraw(e,false)
              end
            }
          end
          DCProgressBar::clear()
          size_values(ent,@sizes)
          @sizes = {}
          tr = Geom::Transformation.new
          Fasteners_Panel.search_parent(ent).reverse.each { |e| tr *= e.transformation }
          notch_arr = Fasteners_Panel.find_notch(ent,tr)
          ids = Fasteners_Panel.delete_all_notches(ent)
          if !ids.empty?
            entities_arr = Fasteners_Panel.find_entities_by_ids(ids)
            entities_arr.each { |entity|
              tr = Geom::Transformation.new
              Fasteners_Panel.search_parent(entity).reverse.each { |e| tr *= e.transformation }
              notch_arr += Fasteners_Panel.find_notch(entity,tr)
            }
          end
          Fasteners_Panel.modified_notch(notch_arr) if !notch_arr.empty?
          check_checkbox(ent,"s9_scale_grip")
        end
        if $SUFToolsObserver.last_tool_name == 'ScaleTool'
          Sketchup.active_model.select_tool(nil)
          Sketchup.send_action "selectScaleTool:"
        end
        @model.layers.add("Z_Face")
        #Change_Point.reset_essence_and_faces
        #Change_Point.comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
        if att_arr.include?("a00_leny") && ent.definition.get_attribute("dynamic_attributes", "point_y_offset") || att_arr.include?("a00_lenx") && ent.definition.get_attribute("dynamic_attributes", "point_x_offset") || att_arr.include?("a00_lenz") && ent.definition.get_attribute("dynamic_attributes", "point_z_offset")
          if ent.material
            if ent.material.display_name.index("_",-5)
              mat_name = ent.material.display_name[0..ent.material.display_name.index("_",-5)-1]
              else
              mat_name = ent.material.display_name
            end
            back_mat_name = ent.definition.get_attribute("dynamic_attributes", "back_material", ent.material.display_name)
            if back_mat_name.index("_",-5)
              back_mat_name = back_mat_name[0..back_mat_name.index("_",-5)-1]
            end
            Change_Materials.change_mat(ent,mat_name,back_mat_name)
            @model.materials.purge_unused
          end
        end
        if change_carcass_material
          type_material = SU_Furniture::Report_lists.search(change_carcass_material,["LDSP","LMDF"])
          if type_material[0]
            SU_Furniture::Change_Materials.read_param(type_material[0])
            SU_Furniture::Change_Materials.change_Carcass_material(ent,change_carcass_material)
          end
        end
        if delete_hidden && @param_delete_hidden == "yes"
          @body1.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
            @body2.definition.entities.add_instance(entity.definition, entity.transformation)
          }
          @body1.erase!
          delete_hidden_components(@body2)
          @body2.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
            entity.definition.name = my_uniq_defn_name(@model,entity.definition.name.split("#")[0])
          }
        end
        ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| delete_if(entity) }
        if att_arr.include?("c4_plint_size")
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| redraw_leg(entity,att_arr) }
        end
        if att_arr.include?("a00_lenx")
          drawers_section = search_drawers_section(ent)
          if drawers_section
            drawers_count = drawers_section.definition.get_attribute("dynamic_attributes", "_drawers_count", 1).to_f
            if drawers_count > 1
              a01_lenx = ent.definition.get_attribute("dynamic_attributes", "a01_lenx", 2).to_f
              b1_p_thickness = drawers_section.definition.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6).to_f
              difference = ((a01_lenx-b1_p_thickness*2-b1_p_thickness*(drawers_count-1))*25.4).round(1)/drawers_count.to_i - ((a01_lenx-b1_p_thickness*2-b1_p_thickness*(drawers_count-1))*25.4).to_i/drawers_count.to_i
              @drawer_width_param = false
              if difference != 0
                Place_Component.drawer_dialog(drawers_count.to_i,difference)
                @drawer_width_param = Place_Component.drawer_width_param
                if @drawer_width_param
                  a00_lenx = ent.definition.get_attribute("dynamic_attributes", "a00_lenx", 50/25.4)
                  x_max_x = ent.definition.get_attribute("dynamic_attributes", "x_max_x", 200/25.4)
                  if @drawer_width_param == "reduce"
                    new_lenx = (a00_lenx*25.4-(difference*drawers_count.to_i).round).to_s
                    change_deep(ent, "a00_lenx", new_lenx, item_code, att_for_change_body, @itemcode_to_name)
                    elsif @drawer_width_param == "increase"
                    new_lenx = (a00_lenx*25.4+((1-difference)*drawers_count.to_i).round).to_s
                    if new_lenx.to_f > x_max_x.to_f*10
                      max_input = UI.messagebox("#{SUF_STRINGS["Maximum module width"]} #{(x_max_x.to_f*10).round} #{SUF_STRINGS["mm"]}!\n#{SUF_STRINGS["Increase maximum width"]}?",MB_YESNO)
                      if max_input == IDYES
                        set_att(ent, "x_max_x", (new_lenx.to_f/10).to_s)
                        set_att(ent, "z_max_width", (new_lenx.to_f/10).to_s)
                      end
                    end
                    change_deep(ent, "a00_lenx", new_lenx, item_code, att_for_change_body, @itemcode_to_name)
                  end
                  DCProgressBar::clear()
                  Redraw_Components.redraw(ent,false)
                end
              end
              @drawer_width_param = false
            end
          end
        end
        if ent.definition.get_attribute("dynamic_attributes", "su_type")=="module"
          if att_arr.any?{|att|att.include?("itemcode")} || att_arr.any?{|att|att.include?("a05_in_front")}
            module_number = false
            ent.definition.entities.grep(Sketchup::Group).each { |g|
              if g.name == "module_number"
                g.erase!
                module_number = true
              end
            }
            if module_number
              a05_in_front = ent.definition.get_attribute("dynamic_attributes", "a05_in_front")
              if a05_in_front && a05_in_front != ""
                str = a05_in_front
                else
                str = value
              end
              Module_Number.view_number(ent,str,@param_hash["newline_space"],@param_hash["height_of_number"],@param_hash["offset_z"],@param_hash["view_number"],@param_hash["color_of_number"])
            end
          end
        end
      }
      $dlg_suf.execute_script("add_comp()")
      $change_att = false
      $dlg_att.execute_script("add_comp()") if $dlg_att
      @model.definitions.purge_unused
      @model.commit_operation
      if SU_Furniture.observers_state == 1
        @model.selection.add_observer $SUFSelectionObserver
        @model.entities.add_observer $SUFEntitiesObserver
      end
      Sketchup.focus if Sketchup.version_number >= 2110000000
    end#def
    def change_deep(ent, attibute, value, item_code, att_for_change_body, itemcode_to_name)
      change_carcass_material = nil
      delete_hidden = false
      comp_path = nil
      attibute = "a03_name" if attibute == "name_no_list"
      clean_value = value
      att = attibute
      att = attibute[0..-8] if attibute[-7..-5] == "_|_"
      att = attibute[1..-9] if attibute[-7..-1] == "formula"
      attr = ent.definition.get_attribute("dynamic_attributes", att)
      access = ent.get_attribute("dynamic_attributes", "_" + att + "_access")
      access = ent.definition.get_attribute("dynamic_attributes", "_" + att + "_access") if !access
      formula = ent.get_attribute("dynamic_attributes", "_" + att + "_formula")
      ent.delete_attribute('dynamic_attributes', "_"+att+"_formula") if formula
      formula = ent.definition.get_attribute("dynamic_attributes", "_" + att + "_formula") if !formula
      ent.definition.delete_attribute("dynamic_attributes", "_" + att + "_formula") if formula
      units = ent.definition.get_attribute("dynamic_attributes", "_" + att + "_units","0")
      formulaunits = ent.definition.get_attribute("dynamic_attributes", "_" + att + "_formulaunits","0")
      lengthunits = ent.get_attribute("dynamic_attributes", "_lengthunits","0")
      lengthunits = ent.definition.get_attribute("dynamic_attributes", "_lengthunits","0") if !lengthunits
      if ent.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module" && !ent.definition.get_attribute("dynamic_attributes", "b2_open")
        set_att(ent, "b2_open","5")
      end
      if attr != nil && access && attibute[-7..-1] == "formula"
        formula_value = value.to_f
        formula_value = value.to_f/10 if units == "MILLIMETERS"
        ent.definition.set_attribute("dynamic_attributes", "_" + att + "_formula", round_without_zero(formula_value, 1).to_s)
      end
      if attr != nil && access || attibute[-7..-5] == "_|_"
        if formulaunits != "STRING" && formulaunits != "FLOAT" && value != ""
          if value.include?(" ")
            value = value[0..value.index(" ")-1]
            elsif value.include?("'")
            value = value[0..value.index("'")-1]
          end
          clean_value = value
          case units
            when "MILLIMETERS" then value = value.gsub(",",".").to_f/25.4
            when "CENTIMETERS" then value = value.gsub(",",".").to_f/2.54
            when "METERS" then value = value.gsub(",",".").to_f/0.0254
            when "FEET" then value = value.gsub(",",".").to_f/0.08333232
            else  value = value.gsub(",",".").to_f/25.4 if formulaunits == "CENTIMETERS"
          end
        end
        if attibute[-7..-5] == "_|_" && attibute[-4..-1] != "LIST"
          value = round_without_zero(value.to_f/10,2) if formulaunits != "CENTIMETERS"
        end
        if att == "hinge_type" && item_code != "N1.LP"
          if value=="вкладная"
            value = "3"
            elsif value=="полунакладная"
            value = "2"
            elsif value=="накладная"
            value = "1"
          end
        end
        lenx,leny,lenz = ent.unscaled_size
        if att == "lenx" || att == "a00_lenx"
          scale_transform = Geom::Transformation.scaling(value/lenx,1,1)
          ent.transformation = ent.transformation * scale_transform
          change_len(ent, att, value)
          elsif att == "leny" || att == "a00_leny"
          scale_transform = Geom::Transformation.scaling(1,value/leny,1)
          ent.transformation = ent.transformation * scale_transform
          change_len(ent, att, value)
          elsif att == "lenz" || att == "a00_lenz"
          scale_transform = Geom::Transformation.scaling(1,1,value/lenz)
          ent.transformation = ent.transformation * scale_transform
          change_len(ent, att, value)
        end
        if att == "a00_lenx" || att == "a00_leny" || att == "a00_lenz"
          value = value.to_f/2.54 if lengthunits == "CENTIMETERS" && units == "STRING"
        end
        set_att(ent, att, value)
        if att == "b1_p_thickness"
          b1_p_material = ent.definition.get_attribute("dynamic_attributes", "b1_p_material")
          if b1_p_material
            if b1_p_material.index("_",-4)
              mat_name = b1_p_material[0..b1_p_material.index("_",-4)-1]
              else
              mat_name = b1_p_material
            end
            SU_Furniture::Change_Materials.add_material(mat_name,mat_name+"_"+clean_value)
            set_att(ent, "b1_p_material",mat_name+"_"+clean_value)
            change_carcass_material = mat_name
          end
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| thickness_formula(entity) }
          elsif item_code && item_code[0..1] == "P1" || item_code && item_code[0..1] == "N1"
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| thickness_formula(entity) }
        end
        if att.include?("back") || att.include?("thickness")
          process_back_panel(ent, "c8_b_thickness") # Дно ящика (c8)
          process_back_panel(ent, "k8_b_thickness")  # Дно ящика (k8)
          process_back_panel(ent, "c5_back_thick") # Задняя стенка
          a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name", "0")
          ent.definition.entities.grep(Sketchup::ComponentInstance){ |e| change_groove_formula(e,a03_name) }
        end
        if att.include?("b3_handle") && item_code == "N1.LP"
          hinge_type = ent.definition.get_attribute('dynamic_attributes', "hinge_type")
          if hinge_type
            value == "2" ? hinge_type = "накладная" : hinge_type = "вкладная"
            set_att(ent, "hinge_type", hinge_type)
          end
          change_hinge_name(ent, value)
        end
        if att == "hinge_type" || att == "cranking"
          change_hinge_type(ent, value)
        end
        if att == "d3_end"
          ent.definition.entities.grep(Sketchup::ComponentInstance){ |e|
            if e.definition.get_attribute('dynamic_attributes', "name", "0") == "Horizontal"
              if e.definition.get_attribute('dynamic_attributes', "_edge_y1_length_formula") == 'CHOOSE(LOOKUP("d3_end"),LenY,0,LenY)'
                e.definition.set_attribute('dynamic_attributes', "_edge_y1_length_formula", 'CHOOSE(LOOKUP("d3_end"),LenY,LenY,0)')
                elsif e.definition.get_attribute('dynamic_attributes', "_edge_y2_length_formula") == 'CHOOSE(LOOKUP("d3_end"),LenY,LenY,0)'
                e.definition.set_attribute('dynamic_attributes', "_edge_y2_length_formula", 'CHOOSE(LOOKUP("d3_end"),LenY,0,LenY)')
              end
            end
          }
        end
        if att == "edge_y1"
          if value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_y1_length", "0").to_f == 0
            ent.definition.delete_attribute('dynamic_attributes', "_edge_y1_length_formula")
            set_att(ent, "edge_y1_length", "1")
            elsif value == "1" && ent.definition.get_attribute('dynamic_attributes', "edge_y1_length", "0").to_f > 0
            set_att(ent, "edge_y1_length", "0")
          end
        end
        if att == "edge_y2"
          if value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_y2_length", "0").to_f == 0
            ent.definition.delete_attribute('dynamic_attributes', "_edge_y2_length_formula")
            set_att(ent, "edge_y2_length", "1")
            elsif value == "1" && ent.definition.get_attribute('dynamic_attributes', "edge_y2_length", "0").to_f > 0
            set_att(ent, "edge_y2_length", "0")
          end
        end
        if att == "edge_z1"
          if value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_z1_length", "0").to_f == 0
            ent.definition.delete_attribute('dynamic_attributes', "_edge_z1_length_formula")
            set_att(ent, "edge_z1_length", "1")
            elsif value == "1" && ent.definition.get_attribute('dynamic_attributes', "edge_z1_length", "0").to_f > 0
            set_att(ent, "edge_z1_length", "0")
          end
        end
        if att == "edge_z2"
          if value != "0" && ent.definition.get_attribute('dynamic_attributes', "edge_z2_length", "0").to_f == 0
            ent.definition.delete_attribute('dynamic_attributes', "_edge_z2_length_formula")
            set_att(ent, "edge_z2_length", "1")
            elsif value == "1" && ent.definition.get_attribute('dynamic_attributes', "edge_z2_length", "0").to_f > 0
            set_att(ent, "edge_z2_length", "0")
          end
        end
        if att == "a03_name"
          a03_path = ent.definition.get_attribute('dynamic_attributes', "a03_path")
          if a03_path && a03_path == "Slab"
            ent.definition.entities.grep(Sketchup::ComponentInstance){ |body|
              if body.definition.name.include?("Body")
                body.definition.entities.grep(Sketchup::ComponentInstance){ |e|
                  if e.definition.name.include?("Essence") || e.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                    e.definition.delete_attribute('dynamic_attributes', "_set_name_formula")
                  end
                }
              end
            }
          end
        end
        if att_for_change_body && att_for_change_body.include?(att)
          comp_path = ent.definition.get_attribute('dynamic_attributes', "comp_path")
          delete_hidden = true if comp_path
        end
        if att.include?("itemcode") && itemcode_to_name == "yes"
          ent.definition.name = value
        end
        if att.include?("su_type_layer")
          su_type_layer(ent,value)
          set_att(ent, att.gsub("a09_",""), value)
          set_att(ent, "a09_"+att.gsub("a09_",""), value)
        end
      end
      return att,delete_hidden,comp_path,change_carcass_material
    end#def
    def change_len(ent, att, value)
      len = ent.get_attribute("dynamic_attributes", att)
      len = ent.definition.get_attribute("dynamic_attributes", att) if !len
      value = -value if len.to_s.include?("-")
      ent.definition.delete_attribute("dynamic_attributes", "_" + att + "_nominal")
      ent.set_attribute("dynamic_attributes", att, value)
      ent.definition.set_attribute("dynamic_attributes", att, value)
    end#def
    def search_drawers_section(ent)
      if ent.definition.get_attribute("dynamic_attributes", "d2_drawer1") || ent.definition.get_attribute("dynamic_attributes", "x_depth1")
        return ent
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_drawers_section(e) }
      return nil
    end#def
    def cut_att(entity)
      if entity.definition.get_attribute("dynamic_attributes", "v0_cut")
        if entity.definition.get_attribute("dynamic_attributes", "v1_cut_type", "1").to_s != "1" || entity.definition.get_attribute("dynamic_attributes", "v2_cut_type", "1").to_s != "1"
          set_att(entity, "v0_cut", "1")
        end
      end
      entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| cut_att(e) }
    end#def
    def delete_if(entity)
      if !entity.deleted?
        if entity.definition
          if entity.definition.get_attribute("dynamic_attributes", "c2_erase", 0).to_f > 0
            entity.erase!
            else
            entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| delete_if(e) }
          end
        end
      end
    end#def
    def my_uniq_defn_name(model,name,index = 1)
      names = model.definitions.map(&:name)
      while names.include?("#{name}##{index}")
        index += 1
      end
      return "#{name}##{index}"
    end
    def redraw_leg(entity,att_arr)
      if entity.definition.get_attribute("dynamic_attributes", "a03_name", "0").include?("Ножк")
        DCProgressBar::clear()
        Redraw_Components.redraw(entity,true)
        DCProgressBar::clear()
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| redraw_leg(e,att_arr) }
      end
    end#def
    def thickness_formula(entity)
      if entity.definition.get_attribute("dynamic_attributes", "su_type", "0").include?("drawer") && entity.definition.get_attribute("dynamic_attributes", "_b1_p_thickness_formula", "0") == "1.6"
        entity.definition.set_attribute("dynamic_attributes", "_b1_p_thickness_formula", 'LOOKUP("b1_p_thickness")')
      end
    end#def
    def delete_hidden_components(ent)
      @hidden_objects = []
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hidden_components(e) }
      if @hidden_objects != []
        @hidden_objects.each { |e| e.erase! }
      end
    end#def
    def hidden_components(ent)
      @hidden_objects << ent if ent.hidden?
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hidden_components(e) }
    end#def
    def su_type_layer(ent,value)
      @model = Sketchup.active_model
      @model.layers.add("1_Фасад")
      @model.layers.add("1_Фасад_ящика")
      @model.layers.add("2_Стекло")
      @model.layers.add("3_Каркас")
      @model.layers.add("3_Каркас_ящика")
      @model.layers.add("4_Задняя_стенка")
      @model.layers.add("4_Металл")
      ent.layer = value
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
        if e.definition.name.include?("Essence") || e.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          e.layer = value
          elsif e.definition.name.include?("Body")
          e.layer = value
          e.definition.entities.grep(Sketchup::ComponentInstance).each { |ess| 
            if ess.definition.name.include?("Essence") || ess.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
              ess.layer = value
              elsif ess.definition.name.include?("Glass")
              ess.layer = "2_Стекло"
            end
          }
        end
      }
    end#def
    def change_hinge_name(e, value)
      name = e.definition.get_attribute("dynamic_attributes", "name", "0")
      if e.definition.name.include?("Hinge") || name.include?("Hinge")
        a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
        _a03_name_formula = e.definition.get_attribute("dynamic_attributes", "_a03_name_formula")
        if _a03_name_formula
          value == "2" ? _a03_name_formula = _a03_name_formula.gsub("вкладная","накладная") : _a03_name_formula = _a03_name_formula.gsub("накладная","вкладная")
          e.definition.set_attribute("dynamic_attributes", "_a03_name_formula", _a03_name_formula)
          else
          value == "2" ? a03_name = a03_name.gsub("вкладная","накладная") : a03_name = a03_name.gsub("накладная","вкладная")
          e.definition.set_attribute("dynamic_attributes", "a03_name", a03_name)
        end
        DCProgressBar::clear()
        Redraw_Components.run_all_formulas(e)
        DCProgressBar::clear()
        else
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_hinge_name(ent, value) }
      end
    end#def
    def change_hinge_type(e, value)
      name = e.definition.get_attribute("dynamic_attributes", "name", "0")
      if e.definition.name.include?("Hinge") || name.include?("Hinge")
        a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
        _a03_name_formula = e.definition.get_attribute("dynamic_attributes", "_a03_name_formula")
        if !_a03_name_formula
          case value
            when "1" then a03_name.include?(SUF_STRINGS["partial overlay"]) ? a03_name = a03_name.gsub(SUF_STRINGS["partial overlay"],SUF_STRINGS["full overlay"]) : a03_name = a03_name.gsub(SUF_STRINGS["inset"],SUF_STRINGS["full overlay"])
            when "2" then (!a03_name.include?(SUF_STRINGS["partial overlay"]) && a03_name.include?(SUF_STRINGS["full overlay"])) ? a03_name = a03_name.gsub(SUF_STRINGS["full overlay"],SUF_STRINGS["partial overlay"]) : a03_name = a03_name.gsub(SUF_STRINGS["inset"],SUF_STRINGS["partial overlay"])
            when "3" then a03_name.include?(SUF_STRINGS["partial overlay"]) ? a03_name = a03_name.gsub(SUF_STRINGS["partial overlay"],SUF_STRINGS["inset"]) : a03_name = a03_name.gsub(SUF_STRINGS["full overlay"],SUF_STRINGS["inset"])
            when "4" then a03_name.include?(SUF_STRINGS["partial overlay"]) ? a03_name = a03_name.gsub(SUF_STRINGS["partial overlay"],SUF_STRINGS["full overlay"]) : a03_name = a03_name.gsub(SUF_STRINGS["inset"],SUF_STRINGS["full overlay"])
            when "5" then a03_name.include?(SUF_STRINGS["partial overlay"]) ? a03_name = a03_name.gsub(SUF_STRINGS["partial overlay"],SUF_STRINGS["inset"]) : a03_name = a03_name.gsub(SUF_STRINGS["full overlay"],SUF_STRINGS["inset"])
          end
          set_att(e, "a03_name", a03_name)
          DCProgressBar::clear()
          Redraw_Components.run_all_formulas(e)
          DCProgressBar::clear()
        end
        else
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_hinge_type(ent, value) }
      end
    end#def
    def process_back_panel(ent, thickness_attr)
      return unless ent.definition.get_attribute("dynamic_attributes", thickness_attr)
      unless ent.definition.get_attribute("dynamic_attributes", "b1_b_thickness")
        set_att(ent, "b1_b_thickness", 4/25.4, "b1_b_thickness", "TEXTBOX", "Толщина ЗС/дна", "CENTIMETERS", "MILLIMETERS", thickness_attr, "&")
      end
    end
    def change_groove_formula(ent,a03_name="0")
      return if ent.definition.get_attribute("dynamic_attributes", "d_from_bottom")
      a03_name += ent.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      groove_formula = ent.definition.get_attribute("dynamic_attributes", "_groove_formula")
      if groove_formula
        new_groove_formula = groove_formula
        if !ent.definition.get_attribute("dynamic_attributes", "trim_z2")
          if new_groove_formula == 'IF(trim_z2=0,CHOOSE(LOOKUP("c5_back"),0,0,0,LOOKUP("c5_back_dist_r"),0.01),0)'
            new_groove_formula = 'CHOOSE(LOOKUP("c5_back"),0,0,0,LOOKUP("c5_back_dist_r"),0.01)'
            elsif new_groove_formula == 'IF(trim_z2=0,IF(LOOKUP("r4_left_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")<0,0,LOOKUP("r4_left_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")),0.01)'
            new_groove_formula = 'IF(LOOKUP("r4_left_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")<0,0,LOOKUP("r4_left_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness"))'
            elsif new_groove_formula == 'IF(trim_z2=0,IF(LOOKUP("r4_right_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")<0,0,LOOKUP("r4_right_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")),0.01)'
            new_groove_formula = 'IF(LOOKUP("r4_right_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness")<0,0,LOOKUP("r4_right_depth")-LOOKUP("a0_leny")-LOOKUP("b1_b_thickness"))'
          end
        end
        new_groove_formula = new_groove_formula.gsub(")0.01)",")") if new_groove_formula.include?(")0.01)")
        new_groove_formula = new_groove_formula.gsub("e0.01)","e") if new_groove_formula.include?("e0.01)")
        new_groove_formula = new_groove_formula.split("0)")[0]+'0.01)' if new_groove_formula.include?("0)") && !new_groove_formula.include?("0.01)")
        ent.definition.get_attribute("dynamic_attributes", "point_y_offset") ? trim = "trim_y2" : trim = "trim_z2"
        if ent.definition.get_attribute("dynamic_attributes", trim)
          new_groove_formula = 'IF('+trim+'=0,'+new_groove_formula+',0)' if !new_groove_formula.include?("trim_z2")
          new_groove_formula = new_groove_formula.gsub("trim_z2=0",trim+"=0")
        end
        ent.definition.set_attribute("dynamic_attributes", "_groove_formula", new_groove_formula)
        else
        ent.definition.entities.grep(Sketchup::ComponentInstance){ |e| change_groove_formula(e) }
      end
    end    
    def hide_att(att, value)
      Sketchup.active_model.selection.grep(Sketchup::ComponentInstance) { |ent|
        ent.set_attribute("dynamic_attributes", att, "&" + value)
        ent.definition.set_attribute("dynamic_attributes", att, "&" + value)
      }
    end#def
    def make_unique_if_needed(instance)
      if instance.is_a?(Sketchup::ComponentInstance)
        instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if instance.parent.is_a?(Sketchup::ComponentDefinition)
        instance.make_unique if instance.definition.count_used_instances > 1
        instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if instance.parent.is_a?(Sketchup::ComponentDefinition)
      end
    end#def
  end #end Class
end#end Module
