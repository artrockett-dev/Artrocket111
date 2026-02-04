module SU_Furniture
  class Lists
    def ocl_call(material_attributes)
      if material_attributes && @param_mat && @param_mat != []
        mat = material_attributes.material
        if mat
					if Sketchup.active_model.get_attribute('su_lists','grain')
						@param_mat = Sketchup.active_model.get_attribute('su_lists','grain')
          end
          @param_mat.each { |param|
            if param[0].index("_",-5)
              mat_name = param[0][0..param[0].index("_",-5)-1]
              else
              mat_name = param[0]
            end
            if param[0] == mat.display_name && param[2] != "" && param[2] =~ /х|x/i
              param[2].include?("x") ? sep = "x" : sep = "х"
              param[3] && param[3] == "false" ? mat_grained=false : mat_grained=true
              material_attributes.grained=mat_grained
              material_attributes.type=2
              material_attributes.std_sizes=param[2].split(sep)[0]+"mm x "+param[2].split(sep)[1]+"mm"
              material_attributes.std_thicknesses=param[1]+"mm"
              material_attributes.thickness=param[1]+"mm"
              elsif mat_name+"_0.4" == mat.display_name || mat_name+"_0.5" == mat.display_name || mat_name+"_0.6" == mat.display_name || mat.display_name.end_with?("_0.4") || mat.display_name.end_with?("_0.5") || mat.display_name.end_with?("_0.6")
              material_attributes.type=4
              material_attributes.thickness="0,5mm"
              material_attributes.length_increase=(@edge_stock*1000).to_s+"mm"
              material_attributes.std_widths="4mm;6mm;8mm;9mm;10mm;12mm;15mm;16mm;18mm;19mm;20mm;21mm;22mm;25mm;26mm;28mm;30mm;32mm;36mm;38mm;40mm"
              material_attributes.grained=false
              #material_attributes.edge_decremented=false
              elsif mat_name+"_0.8" == mat.display_name || mat_name+"_1" == mat.display_name || mat_name+"_1.0" == mat.display_name || mat.display_name.end_with?("_0.8") || mat.display_name.end_with?("_1") || mat.display_name.end_with?("_1.0")
              material_attributes.type=4
              material_attributes.thickness="1mm"
              material_attributes.length_increase=(@edge_stock*1000).to_s+"mm"
              material_attributes.std_widths="4mm;6mm;8mm;9mm;10mm;12mm;15mm;16mm;18mm;19mm;20mm;21mm;22mm;25mm;26mm;28mm;30mm;32mm;36mm;38mm;40mm"
              material_attributes.grained=false
              #material_attributes.edge_decremented=false
              elsif mat_name+"_2" == mat.display_name || mat_name+"_2.0" == mat.display_name || mat.display_name.end_with?("_2") || mat.display_name.end_with?("_2.0")
              material_attributes.type=4
              material_attributes.thickness="2mm"
              material_attributes.length_increase=(@edge_stock*1000).to_s+"mm"
              material_attributes.std_widths="4mm;6mm;8mm;9mm;10mm;12mm;15mm;16mm;18mm;19mm;20mm;21mm;22mm;25mm;26mm;28mm;30mm;32mm;36mm;38mm;40mm"
              material_attributes.grained=false
              #material_attributes.edge_decremented=false
            end
          }
        end
      end
      return material_attributes
    end#def
    def std_width(std_info)
      edge_thickness = new_thickness(std_info[:dimension_real])
			std_info[:width] = edge_thickness.to_i
			std_info[:dimension] = edge_thickness.to_i
			return std_info
    end#def
    def comp_name(entity)
      name = entity.parent.get_attribute('dynamic_attributes', 'a03_name')
      if name
        itemcode = entity.parent.get_attribute('dynamic_attributes', 'itemcode')
        number = entity.parent.get_attribute('dynamic_attributes', 'number')
        if @itemcode == "1"
          name += " - "+itemcode if itemcode && itemcode != ""
          elsif @itemcode == "2"
          name = itemcode+" - "+name if itemcode && itemcode != ""
          else
          name = itemcode+"."+name if itemcode && itemcode != ""
        end
        if number
          number = "0"+number.to_s if number.to_f < 10
					number = "0"+number.to_s if number.to_f < 100
					number = "0"+number.to_s if number.to_f < 1000
          name = "["+number.to_s+"] "+name
        end
        
        else
        name = entity.parent.instances[-1].parent.get_attribute('dynamic_attributes', 'a03_name')
        if name
          itemcode = entity.parent.instances[-1].parent.get_attribute('dynamic_attributes', 'itemcode')
          number = entity.parent.instances[-1].parent.get_attribute('dynamic_attributes', 'number')
          su_info = entity.parent.get_attribute('dynamic_attributes', 'su_info')
          if @itemcode == "1"
            name += " - "+itemcode if itemcode && itemcode != ""
            elsif @itemcode == "2"
            name = itemcode+" - "+name if itemcode && itemcode != ""
            else
            name = itemcode+"."+name if itemcode && itemcode != ""
          end
          if number
            number = "0"+number.to_s if number.to_f < 10
						number = "0"+number.to_s if number.to_f < 100
					  number = "0"+number.to_s if number.to_f < 1000
            name = "["+number.to_s+"] "+name
          end
          
          else
          itemcode = entity.parent.get_attribute('dynamic_attributes', 'itemcode')
          if itemcode
            name = itemcode.split("/")[2]
            else
            itemcode = entity.parent.instances[-1].parent.get_attribute('dynamic_attributes', 'itemcode') if !name
            if itemcode
              name = itemcode.split("/")[2]
            end
          end
          name = entity.get_attribute('dynamic_attributes', 'name', nil) if !name
        end
      end
      return name
    end
    def comp_description(entity,description)
      name = entity.parent.get_attribute('dynamic_attributes', 'a03_name')
      if name
        su_info = entity.parent.get_attribute('dynamic_attributes', 'su_info')
        if su_info
          width = su_info.split("/")[3].to_f
          height = su_info.split("/")[4].to_f
          thickness = su_info.split("/")[5]
          a01_gluing = entity.parent.get_attribute("dynamic_attributes", "a01_gluing")
          if a01_gluing
            if a01_gluing.to_f != 1
              description = SUF_STRINGS["Gluing"]+a01_gluing.to_f.round.to_s+">"+width.round.to_s+"х"+height.round.to_s
            end
            else
            if thickness == "32" || thickness == "36"
              description = SUF_STRINGS["Gluing"]+"2>" + width.round.to_s + "х" + height.round.to_s
            end
          end
        end
        else
        name = entity.parent.instances[0].parent.get_attribute('dynamic_attributes', 'a03_name')
        if name
          itemcode = entity.parent.instances[0].parent.get_attribute('dynamic_attributes', 'itemcode')
          number = entity.parent.instances[0].parent.get_attribute('dynamic_attributes', 'number')
          su_info = entity.parent.get_attribute('dynamic_attributes', 'su_info')
          if su_info
            width = su_info.split("/")[3].to_f
            height = su_info.split("/")[4].to_f
            thickness = su_info.split("/")[5]
            a01_gluing = entity.parent.instances[0].parent.get_attribute("dynamic_attributes", "a01_gluing")
            if a01_gluing
              if a01_gluing.to_f != 1
                description = SUF_STRINGS["Gluing"]+a01_gluing.to_f.round.to_s+">"+width.round.to_s+"х"+height.round.to_s
              end
              else
              if thickness == "32" || thickness == "36"
                description = SUF_STRINGS["Gluing"]+"2>" + width.round.to_s + "х" + height.round.to_s
              end
            end
          end
        end
      end
      return description
    end
    def part_def_count(part_def,group_def)
      if part_def.description.include?(SUF_STRINGS["Gluing"])
        if part_def.description.include?("4>")
          group_def.part_count += part_def.count*3
          part_def.count = part_def.count*4
          part_def.entity_names[""] *= 4
          elsif part_def.description.include?("3>")
          group_def.part_count += part_def.count*2
          part_def.count = part_def.count*3
          part_def.entity_names[""] *= 3
          else
          group_def.part_count += part_def.count
          part_def.count = part_def.count*2
          part_def.entity_names[""] *= 2
        end
      end
      return part_def,group_def
    end
    def new_part_def(part_def)
      part_def.name = part_def.name.split("]")[1][1..-1] if part_def.name[0] == "[" && part_def.name.split("]")[1]
      part_def.edge_material_names.each_pair {|key,value|
        if part_def.description.include?(SUF_STRINGS["Gluing"])
          if part_def.description.include?("4>")
            thickness = (part_def.cutting_size.thickness*25.4).round(1)*4
            elsif part_def.description.include?("3>")
            thickness = (part_def.cutting_size.thickness*25.4).round(1)*3
            else
            thickness = (part_def.cutting_size.thickness*25.4).round(1)*2
          end
          edge_thickness = new_thickness(thickness)
          value = part_def.edge_std_dimensions[key]
          part_def.edge_std_dimensions[key] = value[0..-3]+edge_thickness.to_s
        end
        if part_def.edge_material_names[key].include?(part_def.material_name[0..-5])
          part_def.edge_material_names[key] = part_def.edge_std_dimensions[key]
          part_def.edge_std_dimensions[key] = ""
        end
      }
      return part_def
    end
    def comp_tags(entity,tags)
      su_info = entity.parent.get_attribute("dynamic_attributes", "su_info")
      if su_info
        su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
        napr_texture = su_info[8]
        groove_tag = ""
        groove = su_info[19]
        if groove && groove.to_f > 0
          groove = groove.to_f*10
          groove_thick = su_info[20]
          groove_width = su_info[21]
          if groove < 1
            groove_tag = "<"+SUF_STRINGS["Q"] + (groove_thick.to_f*10).round(0).to_s
            else
            groove_tag = "<"+SUF_STRINGS["G"] + groove.round(0).to_s + "+" + (groove_thick.to_f*10).round(0).to_s
          end
          groove_tag += "*" + (groove_width.to_f*10).round(0).to_s if groove_width
          groove_xy_pos = su_info[22]
          groove_z_pos = su_info[23]
          if groove_xy_pos
            if groove_xy_pos.to_i == 3 || groove_xy_pos.to_i == 4 #по ширине
              if @name_prefix.to_i > 1
                groove_tag += "-" + su_info[4].to_s
                if @name_prefix.to_i > 2
                  if groove_xy_pos.to_i == 3
                    groove_tag += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "↑" : "→") : (napr_texture.to_s == "2" ? "↓" : "←")) + ")"
                    else
                    groove_tag += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "↓" : "←") : (napr_texture.to_s == "2" ? "↑" : "→")) + ")"
                  end
                end
              end
              else #по длине
              if @name_prefix.to_i > 1
                groove_tag += "-" + su_info[3].to_s
                if @name_prefix.to_i > 2
                  if groove_xy_pos.to_i == 1
                    groove_tag += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "→" : "↓") : (napr_texture.to_s == "2" ? "←" : "↑")) + ")"
                    else
                    groove_tag += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "←" : "↑") : (napr_texture.to_s == "2" ? "→" : "↓")) + ")"
                  end
                end
              end
            end
          end
          groove_tag += ">"
          tags += [groove_tag] if !tags.include?(groove_tag)
        end
      end
      return tags
    end
    def comp_ignore_grain_direction(entity,ignore_grain_direction)
      a08_rotate = entity.parent.get_attribute('dynamic_attributes', 'a08_rotate')
      a08_rotate = entity.parent.instances[0].parent.get_attribute('dynamic_attributes', 'a08_rotate') if !a08_rotate
      if a08_rotate
        ignore_grain_direction = true if a08_rotate == "1"
      end
      return ignore_grain_direction
    end#def
    def set_saw_kerf(saw_kerf)
      return @saw_kerf.to_f/25.4
    end
    def param_mat(type,mat_name,thickness,sheet_size)
			if Sketchup.active_model.get_attribute('su_lists','grain')
				@param_mat = Sketchup.active_model.get_attribute('su_lists','grain')
        @param_mat << [mat_name,thickness,sheet_size,"true"] if !@param_mat.any? { |mat| mat.include?(mat_name) && mat.include?(thickness) }
				@param_mat.each_with_index { |mat,index| @param_mat[index][2] = sheet_size if mat_name == mat[0] && thickness == mat[1] && sheet_size != "" }
				Sketchup.active_model.set_attribute('su_lists','grain',@param_mat)
				else
				Sketchup.active_model.set_attribute('su_lists','grain',[[mat_name,thickness,sheet_size,"true"]])
				@param_mat = Sketchup.active_model.get_attribute('su_lists','grain')
      end
    end
    def param_mat_graned(grain,mat_param)
		  @param_mat = Sketchup.active_model.get_attribute('su_lists','grain')
      @param_mat.each_with_index { |mat,index| @param_mat[index][3] = grain if mat_param.split("=")[1] == mat[0] && mat_param.split("=")[3] == mat[1] }
			Sketchup.active_model.set_attribute("su_lists",'grain',@param_mat)
    end
    def new_list(entity)
      command = "lists_activate(#{Sketchup.active_model.path})"
      $dlg_suf.execute_script(command)
    end#def
    def search(new_mat_name,dir_arr_filter=nil)
      new_mat_name = new_mat_name.strip
      new_mat_name = new_mat_name.encode("utf-8")
      if new_mat_name.index("_",-5)
        my_str = new_mat_name[0..new_mat_name.index("_",-5)-1]
        else
        my_str = new_mat_name
      end
      if my_str.include?("RAL") || my_str.include?("NCS")
			  if my_str[0..1] == SUF_STRINGS["M_"] || my_str[0..1] == SUF_STRINGS["G_"]
				  my_str = my_str[2..-1]
        end
      end
      mat_dir = Dir.new(PATH_MAT+"")
      dir_arr = mat_dir.entries
      if dir_arr_filter
        filtered_arr = []
        dir_arr_filter.each { |filter| filtered_arr += dir_arr.select { |d| d.include?(filter) } }
        dir_arr = filtered_arr
      end
      dir_arr.each { |d|
        d = d.encode("utf-8")
        ext_arr = [".jpg",".jpeg",".png"]
        ext_arr.each { |ext|
          if File.file? PATH_MAT+"/" + d + "/" + my_str + ext
            return d,PATH_MAT+"/" + d + "/" + my_str + ext
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str.strip + ext
            return d,PATH_MAT+"/" + d + "/" + my_str.strip + ext
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str + " R-3" + ext
            return d,PATH_MAT+"/" + d + "/" + my_str + " R-3" + ext
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str + " R-6" + ext
            return d,PATH_MAT+"/" + d + "/" + my_str + " R-6" + ext
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str.gsub("(","[").gsub(")","]") + ext
            return d,PATH_MAT+"/" + d + "/" + my_str.gsub("(","[").gsub(")","]") + ext
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str.gsub("[","(").gsub("]",")") + ext
            return d,PATH_MAT+"/" + d + "/" + my_str.gsub("[","(").gsub("]",")") + ext
          end
        }
      }
      return nil,nil
    end
    def discount_list()
      content = File.readlines(File.join(PATH_PRICE,"Акции.xml"))
      materials = xml_value(content.join("").strip,"<Materials>","</Materials>")
      material_array = xml_array(materials,"<Material>","</Material>")
      discounts = []
      @markup_from_param = "1"
      material_array.each{|cont|
        discounts << xml_value(cont,"<Name>","</Name>")+"="+xml_value(cont,"<Value>","</Value>")
        @markup_from_param = xml_value(cont,"<Value>","</Value>") if xml_value(cont,"<Name>","</Name>") == "Общая наценка"
      }
      content = []
      content << 'var discount_content = { "discounts": ['
      discounts.each_index { |i|
        if discounts[i].split("=")[0] && discounts[i].split("=")[1]
          i == discounts.size-1 ? last = ' ' : last = ','
          content << '{"name":"'+discounts[i].split("=")[0]+'","value":"'+discounts[i].split("=")[1]+'"}' + last
        end
      }
      content << ']'
      content << '}'
      discount_list_js = PATH + "/html/cont/discount_list.js"
      file = File.new(discount_list_js,"w")
      content.each{|i| file.puts i}
      file.close
    end#def
    def read_param
      discount_list
      @oversize = 0
      @cost_coef = 1
      @sheet_waste = "15%"
      @sheet_count = "m2"
      @frontal_count = "m2"
      @itemcode = "1"
      @trim_stock = 20
			@panel_group = "yes"
      @linear_waste = "10%"
      @linear_count = "m"
      @edge_waste = "10%"
      @edge_stock = 0
      @edge_strips = "yes"
      @edge_groove_padding = 3
      @name_prefix = "1"
      @place_prefix = "0"
      @sheet_trim = "10"
			@saw_kerf = "3"
      @min_leftover_size = "100"
      @panel_positions = "1"
      @cutting_program = "OCL"
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      parameters_content = File.readlines(path_param)
      @edge_array = []
			@edge_width = []
			@edge_symbol = {}
      parameters_content.each { |line|
        line_arr = line.strip
        @sheet_waste = line_arr.split("=")[2] if line_arr.split("=")[1] == "sheet_waste" 
        @itemcode = line_arr.split("=")[2] if line_arr.split("=")[1] == "ItemCode"
        @trim_stock = line_arr.split("=")[2] if line_arr.split("=")[1] == "trim_stock"
				@panel_group = line_arr.split("=")[2] if line_arr.split("=")[1] == "panel_group"
        @oversize = line_arr.split("=")[2] if line_arr.split("=")[1] == "oversize"
        @cost_coef = line_arr.split("=")[2] if line_arr.split("=")[1] == "cost_coef"
        @sheet_count = line_arr.split("=")[2] if line_arr.split("=")[1] == "sheet_count"
        @frontal_count = line_arr.split("=")[2] if line_arr.split("=")[1] == "frontal_count"
        @linear_waste = line_arr.split("=")[2] if line_arr.split("=")[1] == "linear_waste"
        @linear_count = line_arr.split("=")[2] if line_arr.split("=")[1] == "linear_count"
        @edge_array << line_arr if line_arr.include?("edge_trim")
				@edge_width << [line_arr.split("=")[0],line_arr.split("=")[2],line_arr.split("=")[3]] if line_arr.split("=")[1].include?("edge_width")
				@edge_symbol[line_arr.split("=")[0][1]] = line_arr.split("=")[5] if line_arr.split("=")[1].include?("edge_trim") && line_arr.split("=")[1] != "edge_trim0"
        @edge_waste = line_arr.split("=")[2] if line_arr.split("=")[1] == "edge_waste"
        @edge_stock = line_arr.split("=")[2] if line_arr.split("=")[1] == "edge_stock"
				@edge_strips = line_arr.split("=")[2] if line_arr.split("=")[1] == "edge_strips"
				@edge_groove_padding = line_arr.split("=")[2] if line_arr.split("=")[1] == "edge_groove_padding"
				@name_prefix = line_arr.split("=")[2] if line_arr.split("=")[1] == "name_prefix"
				@place_prefix = line_arr.split("=")[2] if line_arr.split("=")[1] == "place_prefix"
				@sheet_trim = line_arr.split("=")[2] if line_arr.split("=")[1].include?("sheet_trim")
        @saw_kerf = line_arr.split("=")[2] if line_arr.split("=")[1].include?("saw_thickness")
        @min_leftover_size = line_arr.split("=")[2] if line_arr.split("=")[1].include?("min_leftover_size")
        @panel_positions = line_arr.split("=")[2] if line_arr.split("=")[1].include?("panel_positions")
        @cutting_program = line_arr.split("=")[2] if line_arr.split("=")[1].include?("cutting_program")
      }
      dict = Sketchup.active_model.attribute_dictionary 'su_specification'
      dict.to_a.each {|k,v| @cost_coef = v if k.include?("cost_coef") } if dict
      @edge_list = []
      @edge_name_hash = {}
      for edge_array in @edge_array
        @edge_list << edge_array.split("=")[0][4..-1]
        @edge_name_hash[edge_array.split("=")[0][1]] = edge_array.split("=")[0][4..-1].gsub(/[^0-9\.]/, '')
      end
      @sheet_waste = @sheet_waste[0..-2].to_f/100
      @edge_waste = @edge_waste[0..-2].to_f/100
      @edge_stock = @edge_stock.to_f/1000
			
      @auto_refresh = "вкл."
			if File.file?(File.join(TEMP_PATH,"SUF","auto_refresh.dat"))
				path_param = File.join(TEMP_PATH,"SUF","auto_refresh.dat")
				else
				path_param = File.join(PATH,"parameters","auto_refresh.dat")
      end
      content = File.readlines(path_param)
			@auto_refresh = content[0].strip
      Sketchup.active_model.set_attribute('su_parameters', "auto_refresh", @auto_refresh)
      
			@lists_panel_size = "Пильные без кромки"
			if File.file?(File.join(TEMP_PATH,"SUF","panel_size.dat"))
				path_param = File.join(TEMP_PATH,"SUF","panel_size.dat")
				else
				path_param = File.join(PATH,"parameters","panel_size.dat")
      end
      content = File.readlines(path_param)
			@lists_panel_size = content[0].strip
      
      @acc_lists = []
			if param_temp_path && File.file?(File.join(param_temp_path,"lists.dat"))
				path_param = File.join(param_temp_path,"lists.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","lists.dat"))
				path_param = File.join(TEMP_PATH,"SUF","lists.dat")
				else
				path_param = File.join(PATH,"parameters","lists.dat")
      end
      lists_content = File.readlines(path_param)
      lists_content.each { |i| @acc_lists<<i.strip }
			
			@worktop_name = {}
			if param_temp_path && File.file?(File.join(param_temp_path,"worktop.dat"))
				path_param = File.join(param_temp_path,"worktop.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","worktop.dat"))
				path_param = File.join(TEMP_PATH,"SUF","worktop.dat")
				else
				path_param = File.join(PATH,"parameters","worktop.dat")
      end
      content = File.readlines(path_param)
      content.each { |i|
        @worktop_name[i.split("=>")[0]] = i.split("=>")[1].strip
      }
			
			@fartuk_name = {}
			if param_temp_path && File.file?(File.join(param_temp_path,"fartuk.dat"))
				path_param = File.join(param_temp_path,"fartuk.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","fartuk.dat"))
				path_param = File.join(TEMP_PATH,"SUF","fartuk.dat")
				else
				path_param = File.join(PATH,"parameters","fartuk.dat")
      end
      content = File.readlines(path_param)
      content.each { |i|
        @fartuk_name[i.split("=>")[0]] = i.split("=>")[1].strip
      }
      
      @frontal_name = {}
			if param_temp_path && File.file?(File.join(param_temp_path,"frontal.dat"))
				path_param = File.join(param_temp_path,"frontal.dat")
        content = File.readlines(path_param)
        if content[0].include?("<=>")
          File.unlink(path_param)
          path_param = File.join(PATH,"parameters","frontal.dat")
        end
				elsif File.file?(File.join(TEMP_PATH,"SUF","frontal.dat"))
				path_param = File.join(TEMP_PATH,"SUF","frontal.dat")
        content = File.readlines(path_param)
        if content[0].include?("<=>")
          File.unlink(path_param)
          path_param = File.join(PATH,"parameters","frontal.dat")
        end
				else
				path_param = File.join(PATH,"parameters","frontal.dat")
      end
      content = File.readlines(path_param)
      content.each { |i|
        @frontal_name[i.split("=>")[0]] = i.split("=>")[1].strip
      }
			
			@panels_and_glue = {}
      return parameters_content,lists_content
    end#def
    def change_auto_refresh(auto_refresh)
      @auto_refresh = auto_refresh
			param_file = File.new(File.join(TEMP_PATH,"SUF","auto_refresh.dat"),"w")
			param_file.puts @auto_refresh
			param_file.close
      Sketchup.active_model.set_attribute('su_parameters', "auto_refresh", @auto_refresh)
    end#def
		def change_panel_size(panel_size)
		  @lists_panel_size = panel_size
			param_file = File.new(File.join(TEMP_PATH,"SUF","panel_size.dat"),"w")
			param_file.puts panel_size
			param_file.close
    end#def
		def edge_array
		  return @edge_array
    end
		def edge_name_hash
		  return @edge_name_hash
    end
		def edge_stock
		  return (@edge_stock*1000).round
    end
    def xml_value(content,text1,text2)
      pos1 = content.downcase.index(text1.downcase)
      return "" if !pos1
      substring = content[pos1..-1].downcase
      pos2 = pos1+substring.index(text2.downcase)
      return "" if !pos2
      return "" if pos1+text1.length>=pos2
      return content[pos1+text1.length..pos2-1]
    end#def
    def xml_array(content,text1,text2)
      pos = content.downcase.index(text1.downcase)
      content = content[pos+text1.length..-1].split(text1).join("")
      return content.split(text2)[0..-1]
    end#def
    def profiles_cost(profil_arr)
		  if !@price_hash["Фасады_Рамка"]
			  UI.messagebox(SUF_STRINGS["No price file"]+' "Фасады_Рамка"')
				return
      end
      profil_cost = 0
      net_profil_cost = 0
      mat_currency = "RUB"
      provider = ""
      article = ""
      profil_work = 0
      profil_type = profil_arr[0]
      profil_name = profil_arr[1].strip
      color = profil_name[profil_name.rindex("_")+1,4]
      profil_count = profil_arr[4].to_f
      profil_length = (profil_arr[2].to_f/1000+profil_arr[3].to_f/1000)*2*profil_count
      profil_length = profil_length+profil_length*0.1
      acc_in_profile = @acc_in_profile[[profil_name,profil_arr[2],profil_arr[3]]]
      if acc_in_profile != []
        for mat_price in @price_hash["Фасады_Рамка"]
          name_price = mat_price[2]
          cost_price = mat_price[7].gsub(",",".").to_f
          net_cost_price = mat_price[4].gsub(",",".").to_f
          mat_currency = mat_price[5]
          provider = mat_price[0]
          article = mat_price[1]
          work = mat_price[8].gsub(",",".").to_f
          acc_in_profile.each { |acc|
            if acc[1].gsub("|",",").gsub("~","=").gsub("плюс","+").gsub("]",")").gsub("[","(") == name_price
              profil_cost += cost_price*acc[3]*profil_count
              net_profil_cost += net_cost_price*acc[3]*profil_count
              profil_work += +work
            end
          }
        end
        else
        for mat_price in @price_hash["Фасады_Рамка"]
          name_price = mat_price[2]
          cost_price = mat_price[7].gsub(",",".").to_f
          net_cost_price = mat_price[4].gsub(",",".").to_f
          mat_currency = mat_price[5]
          provider = mat_price[0]
          article = mat_price[1]
          work = mat_price[8].gsub(",",".").to_f
          if name_price.include?("Рамочный профиль "+profil_type+" мм") && name_price.include?(color)
            profil_cost += cost_price*profil_length
            net_profil_cost += net_cost_price*profil_length
            profil_work += +work
          end
          if name_price.include?("Уплотнитель стекла прозрачный")
            profil_cost += cost_price*profil_length
            net_profil_cost += net_cost_price*profil_length
            profil_work += +work
          end
          if name_price.include?("Изготовление рамки")
            profil_cost += cost_price*profil_count
            net_profil_cost += net_cost_price*profil_count
            profil_work += +work
          end
          if name_price.include?("Уголок соединительный для широкого профиля")
            profil_cost += cost_price*4*profil_count
            net_profil_cost += net_cost_price*4*profil_count
            profil_work += +work
          end
          if name_price.include?("Крепежный винт М5 х 8 мм")
            profil_cost += cost_price*8*profil_count
            net_profil_cost += net_cost_price*8*profil_count
            profil_work += +work
          end
        end
      end
      for i in 0..@profil_name_cost_arr.length-1
        profil_array = @profil_name_cost_arr[i]
        if profil_array[0] == profil_name
          profil_cost += profil_array[1]
          net_profil_cost += profil_array[2]
          profil_work += profil_array[3]
          @profil_name_cost_arr.delete(profil_array)
        end
      end
      @profil_name_cost_arr << [profil_name,profil_cost,net_profil_cost,profil_work,mat_currency,provider,article]
    end
    def pipes_cost(pipe_arr)
		  if !@price_hash["Фасады_Рамка"]
			  UI.messagebox(SUF_STRINGS["No price file"]+' "Профиль"')
				return
      end
      pipe_cost = 0
      net_pipe_cost = 0
      mat_currency = "RUB"
      provider = ""
      article = ""
      pipe_work = 0
      opora_name = pipe_arr[1]
      opora_name = opora_name.strip
      opora_name = opora_name.gsub("~","=")
      opora_name = opora_name.gsub("|",",")
      opora_name = opora_name.gsub("плюс","+")
      opora_name = opora_name.gsub("[","(")
      opora_name = opora_name.gsub("]",")")
      opora_height = pipe_arr[2].to_f
      opora_width1 = pipe_arr[3].to_f
      pipe_count = pipe_arr[4].to_f
      opora_width2 = pipe_arr[6].to_f
      pipe_width = pipe_arr[7]
      pipe_thick = pipe_arr[8]
      hole = pipe_arr[9].to_f
      thread = pipe_arr[10].to_f
      corner = pipe_arr[11].to_f
      pipe_length = (opora_height*2+opora_width1+opora_width2)/1000
      
      for mat_price in @price_hash["Профиль"]
        name_price = mat_price[2]
        cost_price = mat_price[7].gsub(",",".").to_f
        net_cost_price = mat_price[6].gsub(",",".").to_f
        mat_currency = mat_price[5]
        provider = mat_price[0]
        article = mat_price[1]
        work = mat_price[8].gsub(",",".")
        if name_price.include?("Труба "+pipe_thick+"х"+pipe_width)
          pipe_cost += cost_price*pipe_length
          net_pipe_cost += net_cost_price*pipe_length
          if work[-1] == "%"
            pipe_work += work[0..-2].to_f*net_cost_price/100
            else
            pipe_work += work.to_f
          end
        end
        if name_price.include?("Отверстие")
          pipe_cost += cost_price*hole
          net_pipe_cost += net_cost_price*hole
          if work[-1] == "%"
            pipe_work += work[0..-2].to_f*net_cost_price/100
            else
            pipe_work += work.to_f
          end
        end
        if name_price.include?("Точка с резьбой")
          pipe_cost += cost_price*thread
          net_pipe_cost += net_cost_price*thread
          if work[-1] == "%"
            pipe_work += work[0..-2].to_f*net_cost_price/100
            else
            pipe_work += work.to_f
          end
        end
        if name_price.include?("Сваривание угла")
          pipe_cost += cost_price*corner*pipe_count
          net_pipe_cost += net_cost_price*4*pipe_count
          if work[-1] == "%"
            pipe_work += work[0..-2].to_f*net_cost_price/100
            else
            pipe_work += work.to_f
          end
        end
      end
      for i in 0..@pipe_name_cost_arr.length-1
        pipe_array = @pipe_name_cost_arr[i]
        if @pipe_name_cost_arr[i] == opora_name
          pipe_cost += pipe_array[1]
          net_pipe_cost += pipe_array[2]
          pipe_work += pipe_array[3]
          @pipe_name_cost_arr.delete_at(pipe_array)
        end
      end
      @pipe_name_cost_arr << [opora_name,pipe_cost,net_pipe_cost,pipe_work,mat_currency,provider,article]
    end
		def price_hash()
			path_price = File.join(PATH_PRICE, "*")
      @all_folder_price = Dir.glob(path_price).select { |file| File.extname(file).casecmp?(".xml") }
      @all_folder_price.map! { |file| File.basename(file, File.extname(file)) }
      @all_folder_price.reject! { |name| name == "Фреза_текстура" }
      @all_folder_price.each{|folder_price|
        content = File.read(File.join(PATH_PRICE, "#{folder_price}.xml"))
        materials = xml_value(content.strip,"<Materials>","</Materials>")
        next if materials.strip.empty?
        material_array = xml_array(materials,"<Material>","</Material>")
        price_array = []
        material_array.each{|cont|
          @digit_capacity = xml_value(cont,"<Digit_capacity>","</Digit_capacity>") if !@digit_capacity
          price_array << [xml_value(cont,"<Provider>","</Provider>"),xml_value(cont,"<Article>","</Article>"),xml_value(cont,"<Name>","</Name>"),xml_value(cont,"<Unit_Measure>","</Unit_Measure>"),xml_value(cont,"<Cost>","</Cost>"),xml_value(cont,"<Currency>","</Currency>"),xml_value(cont,"<Coef>","</Coef>"),xml_value(cont,"<Price>","</Price>"),xml_value(cont,"<Work>","</Work>"),xml_value(cont,"<Category>","</Category>"),xml_value(cont,"<Code>","</Code>"),xml_value(cont,"<Weight>","</Weight>"),xml_value(cont,"<Link>","</Link>"),xml_value(cont,"<Digit_capacity>","</Digit_capacity>")]
        }
        @price_hash[folder_price] = price_array
      }
    end
    def cbr_xml_daily(arr,entity,send)
      s = arr[1..-1]
      if arr[0] == true && s[1].split('=')[1] != '1'
        currency_rate = s
        command = "cbr_xml_daily(#{currency_rate.inspect})"
        $dlg_suf.execute_script(command)
        cost_calculation(entity,send)
        else
        currency, _, currency_name = s[0].split('=')
        currency_rate = []
        coef = 1.0
        download_path = File.join(TEMP_PATH,"SUF","cbr_xml_daily.xml")
        begin
          url = URI('https://www.cbr-xml-daily.ru/daily_utf8.xml')
          request = Sketchup::Http::Request.new(url.to_s, Sketchup::Http::GET)
          request.start { |request, response|
            File.open(download_path, 'wb') { |f| f.write(response.body) }
            file = File.open download_path, "r"
            xml_doc = file.readlines
            file.close
            valcurs = xml_value(xml_doc.join,'<ValCurs','</ValCurs>')
            valutes = xml_array(valcurs,'<Valute','</Valute>')
            valutes.each { |valute|
              char_code = xml_value(valute.to_s,'<CharCode>','</CharCode>')
              if s[0].include?(char_code)
                nominal = xml_value(valute.to_s,'<Nominal>','</Nominal>').to_f
                value = xml_value(valute.to_s,'<Value>','</Value>').gsub(',', '.').to_f
                coef = value / nominal
                break
              end
            }
            currency_rate << "#{currency}=#{coef}=#{currency_name}"
            valutes.each { |valute|
              char_code = xml_value(valute,'<CharCode>','</CharCode>')
              value = xml_value(valute,'<Value>','</Value>').gsub(',', '.').to_f
              if s.join.include?(char_code) && currency != char_code
                currency_rate << "#{char_code}=#{(value / coef * 100).ceil / 100.0}"
              end
            }
            path_currency_rate = PATH_PRICE + "/currency.dat"
            file_currency_rate = File.new(path_currency_rate,"w")
            currency_rate.each { |currency| file_currency_rate.puts currency}
            file_currency_rate.close
            command = "cbr_xml_daily(#{currency_rate.inspect})"
            $dlg_suf.execute_script(command)
            cost_calculation(entity,send)
          }
          rescue => e
          currency_rate = s
          command = "cbr_xml_daily(#{currency_rate.inspect})"
          $dlg_suf.execute_script(command)
          cost_calculation(entity,send)
        end
      end
    end
    def cost(entity,send=true)
      if send
        number = false
        currency = false
        @model = Sketchup.active_model
        dict = @model.attribute_dictionary 'su_specification'
        if dict
          dict.each {|k,v|
            number = true if k.include?("number") && !v.include?("___")
            currency = v if k.include?("currency")
          }
        end
        @param_list = []
        @param_list << number
        if number && currency
          currency_arr = currency.split(",")
          currency_arr.each{|i| @param_list << (i.strip)}
          else
          if File.file?( PATH_PRICE + "/currency.dat" )
            path_param_list = PATH_PRICE + "/currency.dat"
            param_list = File.new(path_param_list,"r")
            content = param_list.readlines 
            param_list.close
            content.each{|i| @param_list << (i.strip)}
            else
            @param_list = []
          end
        end
        cbr_xml_daily(@param_list,entity,send)
        else
        cost_calculation(entity,send)
      end
    end
    def cost_calculation(entity,send)
		  @price_hash = {}
      @digit_capacity = nil
			@all_folder_price = []
			price_hash()
      @specification_list = []
      @tech_list = []
      @mat_area = []
      @edge_count = []
      @profil_name_cost_arr = []
      @pipe_name_cost_arr = []
      #@list_groove = []
      @list_Jprofile = []
      @list_Jprofile_length = []
      @list_JprofileUp = []
      @list_JprofileUp_length = []
      parameters_content,lists_content = read_param
      cost_list(entity,send)
      #@list_groove.push(["groove","ЛДСП",8,@total_groove_count.to_f/1000,SUF_STRINGS["m"]])
      @list_Jprofile.push(["Jprofile",SUF_STRINGS["J-profile milling"],19,@total_Jprofile_count,SUF_STRINGS["pc"]])
      @list_Jprofile_length.push(["Jprofile",SUF_STRINGS["J-profile milling"],19,@total_Jprofile_length,SUF_STRINGS["m"]])
      @list_JprofileUp.push(["Jprofile",SUF_STRINGS["J-profile milling"]+" (UP)",19,@total_JprofileUp_count,SUF_STRINGS["pc"]])
      @list_JprofileUp_length.push(["Jprofile",SUF_STRINGS["J-profile milling"]+" (UP)",19,@total_JprofileUp_length,SUF_STRINGS["m"]])
      accessories_list(entity,{},send,false)
      @list_accessories.sort_by!{|array| array[1]}
      tech_list()
      list = @mat_area.uniq + @total_edge_count + @total_work_count + @list_accessories + @profil_count
      #list += @list_groove if @total_groove_count != 0
        #list += @list_Jprofile if @total_Jprofile_count != 0
      #list += @list_JprofileUp if @total_JprofileUp_count != 0
      list += @list_Jprofile_length if @total_Jprofile_length != 0
      list += @list_JprofileUp_length if @total_JprofileUp_length != 0
      if send
        command = "cost_table()" 
        $dlg_suf.execute_script(command) if $dlg_suf
        else
        command = "cost_table()" 
        $dlg_spec.execute_script(command) if $dlg_spec
      end
      @volume = 0
      @module_count = 0
      @worktop_count = 0
      @oversize_count = 0
      @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      @ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      @sel.length == 0 ? sel = @ent : sel = @sel
      sel.each { |ent|
        description = ent.definition.get_attribute("dynamic_attributes", "description", "0")
        item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
        lenx = ent.definition.get_attribute("dynamic_attributes", "lenx").to_f
        leny = ent.definition.get_attribute("dynamic_attributes", "leny").to_f
        lenz = ent.definition.get_attribute("dynamic_attributes", "lenz").to_f
        if description == SUF_STRINGS["product"]
          @module_count += 1
          lenz = lenz + ent.definition.get_attribute("dynamic_attributes", "a1_leg", 0).to_f
          @volume += (lenx.to_m.abs)*(leny.to_m.abs + 0.05)*(lenz.to_m.abs)
          @oversize_count += 1 if item_code[0] == "P" && lenz.to_mm+leny.to_mm>@oversize.to_f
        end
        @worktop_count += 1 if description.include?("Столешница")
        if description.include?("Столешницы") || description.include?("Фартуки")
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
            @oversize_count += 1 if lenx.to_mm+leny.to_mm>@oversize.to_f || lenx.to_mm+lenz.to_mm>@oversize.to_f
          }
          else
          @oversize_count += 1 if lenx.to_mm+leny.to_mm>@oversize.to_f || lenx.to_mm+lenz.to_mm>@oversize.to_f
        end
      }
      command = "compute_elements(#{[PATH_PRICE,@volume,@module_count,@worktop_count,@oversize_count].inspect})"
      $dlg_spec.execute_script(command) if $dlg_spec
      command = "compute_tech_list(#{@tech_list.inspect})"
      $dlg_spec.execute_script(command) if $dlg_spec
      
      @list_profil.each { |profil| profiles_cost(profil) }
      @list_pipe.each { |pipe| pipes_cost(pipe) }
      count_hash = {}
      list.each { |l|
        count_hash[l[1]] ? count_hash.store(l[1], count_hash[l[1]]+l[3].to_f) : count_hash.store(l[1], l[3].to_f)
      }
      list.each { |l|
        type = l[0]
        name = l[1]
        thickness = round(l[2])
        count = l[3].to_f
        unit = l[4]
        type_material = l[5]
        max_width_of_count = l[6]
        type_mat = nil
        width_count = nil
        if type != "edge" && !type.include?("frontal") && !type.include?("carcass") && !type.include?("back") && max_width_of_count && max_width_of_count != "0" && !name.include?("накладной") && !name.include?("интегрированный")
          if type.include?("worktop") || type.include?("fartuk")
            if @linear_count != "m" && max_width_of_count && max_width_of_count != "0" && max_width_of_count != 0
              width_count = count
              count = ((count.to_f + count.to_f*@linear_waste.to_f)/max_width_of_count.to_f).round(2)
              if count.to_f <= @linear_count.to_f
                count = @linear_count.to_f
                else
                count = (count.to_f/@linear_count.to_f).ceil
              end
              count = count*@linear_count.to_f
              unit = SUF_STRINGS["pc"]
            end
            else
            if @max_width_of_count[name] && @max_width_of_count[name] != "0" && @max_width_of_count[name] != 0
              width_count = count
              count = (count/@max_width_of_count[name]).ceil
              unit = SUF_STRINGS["pc"]
            end
          end
          elsif @max_width_of_count[name] && @max_width_of_count[name] != "0" && @max_width_of_count[name] != 0
          width_count = count
          count = (count/@max_width_of_count[name]).ceil
          unit = SUF_STRINGS["pc"]
        end
        case type
          when "groove" then name = SUF_STRINGS["Groove"]+" " if count != 0
          when "glass" then (name.include?("RAL") || name.include?("NCS")) ? name = SUF_STRINGS["glass"]+" "+SUF_STRINGS["painted"]+" "+name+" "+thickness+" "+SUF_STRINGS["mm"] : name = name+" "+thickness+" "+SUF_STRINGS["mm"]
          when "plinth" then name = SUF_STRINGS["Plinth"]+" "+name
          when "skirting" then name = SUF_STRINGS["Skirting"]+" "+name
          #when "hinge" then name = "hinge"+name
          when "work" then name = l[2]
          else name = name
        end
        if type.include?("metal")
          name = type.split("/")[1]+" "+SUF_STRINGS["metal"]+" "+name
        end
        
        if type.include?("edge")
          if l[2].include?("Фигурный")
            name = l[2]
            else
            if l[2][0] == "_"
              name = SUF_STRINGS["Edge"]+" "+l[2][l[2].rindex("_")+1..-1]+" "+l[2][1..l[2].rindex("_")-1]
              else
              name = SUF_STRINGS["Edge"]+" "+l[2]+" "+name
            end
          end
        end
        
        if type.include?("furniture")
          if name.index("_",-5) && name.index("_",-5) == name.length-2 || name.index("_",-5) == name.length-3
            name = name[0..name.index("_",-5)-1]
          end
        end
        
        if type.include?("handle")
          name = name[0..(name.index(" ") ? name.rindex(" ")-1 : -1)] if name.include?("кнопка")
        end
        
        if type.include?("worktop") || type.include?("fartuk")
          if type_material && type_material != ""
            type_mat_name = type_material.gsub("4000","").gsub("4100","").gsub("4200","")
            else
            type_mat_name,file_name = search(name,["WorkTop"])
          end
          if type_mat_name
            type_mat = type_mat_name[0..type_mat_name.rindex("_")-1] if type_mat_name.include?("_")
            type_mat = type_mat[type_mat.rindex("/")+1..-1] if type_mat && type_mat.include?("/")
          end
          mat_name = name
          @name_parts = {}
          @name_parts["name"] = type.split("/")[1]
          @name_parts["length"] = type.split("/")[2]
          @name_parts["width"] = type.split("/")[3]
          @name_parts["thickness"] = thickness
          @name_parts["material"] = mat_name
          parts = []
          
          
          if type.include?("Камень")
            if type.include?("fartuk")
              parts = @fartuk_name["Камень"].split(";")
              else
              parts = @worktop_name["Камень"].split(";")
            end
            name = ""
            parts.each { |part|
              if @name_parts[part]
                name += @name_parts[part]
                else
                name += part
              end
            }
            else
            
            if name.include?("Угловой элемент")
              name = type.split("/")[1]+" "
              name += thickness+" "
              name += mat_name
              if !type.include?("fartuk") && type.split("/")[4].to_s[0..4] != "White"
                name += " (2х стор)"
                elsif type.split("/")[4].to_s == "2"
                name += " (без завала)"
              end
              
              else
              p type_mat
              if type.include?("worktop") && @worktop_name[type_mat] || type.include?("fartuk") && @fartuk_name[type_mat]
                if type.include?("fartuk")
                  parts = @fartuk_name[type_mat].split(";")
                  else
                  parts = @worktop_name[type_mat].split(";")
                end
                name = ""
                parts.each { |part|
                  if @name_parts[part]
                    name += @name_parts[part]
                    if !type.include?("fartuk") && part == "material"
                      if type.split("/")[4].to_s[0..4] != "White"
                        name += " (2х стор)" if !type.include?("Compact")
                        elsif type.split("/")[5].to_s == "2"
                        name += " (без завала)" if !type.include?("Compact")
                      end
                    end
                    else
                    if part.include?("length")
                      name += @name_parts["length"]
                      elsif part.include?("width")
                      name += @name_parts["width"]
                      else
                      name += part
                    end
                  end
                }
              end
            end
          end
          
          name += ", "+type_mat if type_mat
          if name.include?("камень") || name.include?("камня")
            count = (count.to_f/0.25).ceil*0.25;
          end
        end
        
        if type.include?("back")
          if type_material && type_material != ""
            type_mat_name = type_material
            else
            type_mat_name,file_name = search(name,["HDF","COLOR"])
          end
          if type_mat_name
            type_mat = type_mat_name[0..type_mat_name.rindex("_")-1] if type_mat_name.include?("_")
            type_mat = type_mat[type_mat_name.rindex("/")+1..-1] if type_mat_name.include?("/")
          end
          name = SUF_STRINGS["HDF"]+" "+name
          if @sheet_count != "m2" && type_mat_name
            count,unit = count_in_pieces(parameters_content,type_mat_name,count,@sheet_count)
          end
        end
        
        if type.include?("carcass")
          if type_material && type_material != ""
            type_mat_name = type_material
            else
            type_mat_name,file_name = search(name,["LDSP","LMDF"])
          end
          if type_mat_name
            type_mat = type_mat_name[0..type_mat_name.rindex("_")-1] if type_mat_name.include?("_")
            type_mat = type_mat[type_mat_name.rindex("/")+1..-1] if type_mat_name.include?("/")
          end
          if type_material && type_material.include?("LMDF") || type_mat_name && type_mat_name.include?("LMDF")
            name = SUF_STRINGS["MDF"]+" "+thickness+SUF_STRINGS["mm"]+" "+name
            else
            name = SUF_STRINGS["chipboard"]+" "+thickness+SUF_STRINGS["mm"]+" "+name
          end
          name = name+" "+type_mat if type_mat
          if @sheet_count != "m2" && type_mat_name
            count,unit = count_in_pieces(parameters_content,type_mat_name,count,@sheet_count)
          end
        end
        
        if type.include?("frontal")
          type_arr = type.split("/") 
          if type_arr[4] && type_arr[4] != ""
            type_mat_name = type_arr[4]
            elsif type_material && type_material != ""
            type_mat_name = type_material
            else
            type_mat_name,file_name = search(name,["LDSP","LMDF","MDF","COLOR","PLASTIC"])
          end
          
          if type_mat_name
            if type_mat_name.include?("_")
              type_mat = type_mat_name[0..type_mat_name.rindex("_")-1]
              else
              type_mat = type_mat_name
            end
            type_mat = type_mat[type_mat.rindex("/")+1..-1] if type_mat.include?("/")
          end
          if !type_mat_name
            type_mat_name = "_LDSP"
            type_mat = ""
          end
          name_arr = [SUF_STRINGS["Frontals"]]
          for i in 5..9
            if !type_arr[i]
              name_arr[0] += ' '
              break
            end
            name_arr[0] += ',' if i > 5
            case type_arr[i]
              when "V" then name_arr[0] += ' '+SUF_STRINGS["of upper base"]
              when "P" then name_arr[0] += ' '+SUF_STRINGS["of high base"]
              when "N" then name_arr[0] += ' '+SUF_STRINGS["of lower base"]
              when "A" then name_arr[0] += ' '+SUF_STRINGS["of mezzanines"]
              when "E" then name_arr[0] += ' '+SUF_STRINGS["of slats"]
            end
          end
          @name_parts = {}
          @name_parts["thickness"] = thickness
          @name_parts["material"] = name
          @name_parts["patina"] = type_arr[3]
          @name_parts["supplier"] = type_mat
          parts = []
          @frontal_name["Default"] = "ЛДСП;thickness;material;supplier"
          
          if @frontal_name[type_mat_name[type_mat_name.rindex("_")+1..-1]]
            parts = @frontal_name[type_mat_name[type_mat_name.rindex("_")+1..-1]].split(";")
            else
            parts = @frontal_name["Default"].split(";")
          end
          
          if type_mat_name.include?("LDSP") || type_mat_name.include?("LMDF")
            if @sheet_count != "m2" && type_mat_name
              count,unit = count_in_pieces(parameters_content,type_mat_name,count,@sheet_count)
            end
            
            parts.each { |part|
              if @name_parts[part]
                if part == "thickness"
                  name_arr << ' ' + @name_parts[part] + SUF_STRINGS["mm"]
                  else
                  name_arr << ' '+@name_parts[part]
                end
                else
                name_arr << part
              end
            }
            
            else
            if @frontal_count != "m2" && type_mat_name
              count,unit = count_in_pieces(parameters_content,type_mat_name,count,@frontal_count)
            end
            parts.each { |part|
              if part == "milling"
                if type_arr[1].include?("Jprofile")
                  name_arr << '| '+SUF_STRINGS["milling"]+' '+SUF_STRINGS["J_profile"]
                  else
                  type_arr[1].index("_") ? name_arr << '| '+SUF_STRINGS["milling"]+' "' + type_arr[1][type_arr[1].index("_")+1..-1] + '"' : name_arr << '| '+SUF_STRINGS["milling"]+' "'+SUF_STRINGS["Modern"]+'"'
                end
                if type_arr[2] == "White"
                  name_arr << '| '+SUF_STRINGS["the reverse side"]+' '+SUF_STRINGS["White"]
                  elsif type_arr[2] == "White_and_stripe"
                  if name[0..1] == SUF_STRINGS["G_"] || name[0..1] == SUF_STRINGS["M_"]
                    stripe_name = name[2..-1]
                    else
                    stripe_name = name
                  end
                  name_arr << '| '+SUF_STRINGS["the reverse side"]+' '+SUF_STRINGS["White"]+' + '+SUF_STRINGS["stripe"]+' ' + stripe_name
                  else
                  if name[0..1] == SUF_STRINGS["G_"] || name[0..1] == SUF_STRINGS["M_"]
                    back_name = type_arr[2][2..type_arr[2].rindex("_")-1]
                    else
                    back_name = type_arr[2][0..type_arr[2].rindex("_")-1]
                  end
                  name_arr << '| '+SUF_STRINGS["the reverse side"]+' ' + back_name
                end
                else
                if @name_parts[part]
                  if part == "material"
                    if name[0..1] == SUF_STRINGS["G_"]
                      name_arr << ' "' + name[2..-1] + '" ' + SUF_STRINGS["gloss"]
                      elsif name[0..1] == SUF_STRINGS["M_"]
                      name_arr << ' "' + name[2..-1] + '" ' + SUF_STRINGS["matte"]
                      else
                      name_arr << ' "' + @name_parts[part] + '"'
                    end
                    elsif part == "thickness"
                    name_arr << '| ' + @name_parts[part] + ' ' + SUF_STRINGS["mm"]
                    else
                    name_arr << ' '+@name_parts[part] if @name_parts[part] != "0"
                  end
                  else
                  name_arr << part
                end
              end
            }
            name_arr << '| '+SUF_STRINGS["Order less than 1m2"] if count_hash[l[1]] < 1
          end
          name = name_arr
        end
        
        if width_count
          count = count.to_f.round(2) #.to_s + " ("+width_count.to_s+SUF_STRINGS["m"]+")"
          else
          count = count.to_f.round(2)
        end
        array = cost_row([name,count,SUF_ATT_STR[unit],PATH_PRICE,@all_folder_price,@cost_coef,@acc_group_hash])
        if array
          if send
            vend = array+[@digit_capacity,true]
            command = "cost_rows(#{vend.inspect})"
            $dlg_suf.execute_script(command) if $dlg_suf
          end
          @specification_list << array+[@digit_capacity]
        end
      }
      if send
        @volume = @volume.round(2)
        command = "total_cost(#{[@volume].inspect})"
        $dlg_suf.execute_script(command) if $dlg_suf
      end
      return @specification_list
    end#def
    def follow_the_link(link)
      status = UI.openURL(link)
    end
    def count_in_pieces(parameters_content,type_mat_name,count,sheet_count)
      sheet_size = nil
      parameters_content.each { |i|
        param_mat = i.strip.split("=")[0]
        if i.strip.split("=")[2] =~ /х|x/i
          if type_mat_name[0..param_mat.length-1] == param_mat || param_mat == type_mat_name[-param_mat.length..-1]
            sheet_size = i.strip.split("=")[2]
          end
        end
      }
      if sheet_size
        sheet_area = sheet_size.gsub("х","x").split("x")[0].to_f*sheet_size.gsub("х","x").split("x")[1].to_f/1000000
        count = ((count.to_f + count.to_f*@sheet_waste.to_f)/sheet_area).round(1)
        if count.to_f <= sheet_count.to_f
          count = sheet_count.to_f
          else
          count = (count.to_f/@sheet_count.to_f).ceil
        end
        count = count*sheet_count.to_f
        unit = SUF_STRINGS["pc"]
      end
      return count,unit
    end#def
		def folder_price(name,all_folder_price)
			if name[1].include?(SUF_STRINGS["MDF in PVC film"])
				if all_folder_price.include?("Фасады_ПВХ")
					all_folder_price = ["Фасады_ПВХ"];
        end
        elsif (name[1].include?(SUF_STRINGS["MDF in enamel"]))
        if all_folder_price.include?("Фасады_Эмаль")
          all_folder_price = ["Фасады_Эмаль"]
        end
        elsif name[1].include?(SUF_STRINGS["MDF in veneer"])
        if all_folder_price.include?("Фасады_Шпон")
          all_folder_price = ["Фасады_Шпон"]
          elsif all_folder_price.include?("Шпон")
          all_folder_price = ["Шпон"]
        end
        elsif name[1].include?(SUF_STRINGS["MDF in plastic"])
        if all_folder_price.include?("Фасады_Пластик")
          all_folder_price = ["Фасады_Пластик"]
        end
        elsif name.include?(SUF_STRINGS["Frontals"]) && name.include?(SUF_STRINGS["chipboard"])
        if all_folder_price.include?("Фасады_ЛДСП")
          all_folder_price = ["Фасады_ЛДСП"]
        end
        elsif name.include?(SUF_STRINGS["Frontals"]) && name.include?(SUF_STRINGS["MDF"])
        if all_folder_price.include?("Фасады_МДФ")
          all_folder_price = ["Фасады_МДФ"]
          elsif all_folder_price.include?("Фасады_ЛМДФ")
          all_folder_price = ["Фасады_ЛМДФ"]
        end
        elsif name.include?("Фрезеровка J-профиля")
        if all_folder_price.include?("Фасады_Эмаль")
          all_folder_price = ["Фасады_Эмаль"]
        end
        elsif (name.include?("Столешница")) || (name.include?("Угловой элемент 950")) || (name.include?("Стеновая панель")) || (name.include?("Кромка HPL")) || (name.include?("Кромка ABS"))
        if ((name.include?("камень")) || (name.include?("камня")))
          if all_folder_price.include?("Камень")
            all_folder_price = ["Камень"]
          end
          else
          all_folder_price = all_folder_price.select{|item| item.include?("ПФ") }+all_folder_price.select{|item| item.include?("Столеш") }
        end
        elsif ((name.to_s.downcase.include?("ручка")) && (!name.to_s.downcase.include?("schuco")) && (!name.to_s.downcase.include?("gola")) && (!name.to_s.downcase.include?("blum")) || (name.to_s.downcase.include?("заглушка на винт")))
        handle_price = all_folder_price.select{|item| item.include?("Руч") }
        if handle_price.length != 0
          all_folder_price = handle_price
        end
        elsif (name.to_s.include?("Blum"))
        if all_folder_price.include?("Blum")
          all_folder_price = ["Blum"]
        end
        else 
        all_folder_price = all_folder_price - ["Фасады_ПВХ","Фасады_Эмаль","Фасады_ЛДСП","Фасады_Шпон","Фасады_Массив","Фасады_Рамка","Blum","ПФ","Ручки","Акции"]
      end
      return all_folder_price
    end#def    
		def cost_row(s)
			name = s[0]
			return if name.include?("ЛДСП 30мм")
			count = s[1]
			unit = s[2]
			path_price = s[3]
			all_folder_price = s[4]
			cost_coef = s[5]
			markup = (@markup_from_param.to_s.gsub(",",".").to_f*cost_coef.to_s.gsub(",",".").to_f).to_s
			acc_group_hash = s[6]
			cost = 0
			net_cost = 0
			work = 0
			provider = "-------"
			article = "-------"
			mat_currency = ""
      code = ""
      weight = ""
      link = ""
			all_folder_price = folder_price(name,all_folder_price)
			if name.to_s.include?(SUF_STRINGS["Frontals"]) && name.is_a?(Array)
				comp_frontal = true
				else
				comp_frontal = false
				name = name.to_s.strip.gsub("~","=").gsub("|",",").gsub("плюс","+").gsub("[","(").gsub("]",")")
      end
			count = count.ceil if name.to_s.downcase.include?("кромка")
      
      if comp_frontal # фасады
				kf = 1
				begin_number = 2
				frontal_name_array = name.clone
        if frontal_name_array[1].include?("МДФ в эмали")
          begin_number = 3
					if frontal_name_array[5].include?("обр.стор.")
						if frontal_name_array[5].include?("обр.стор. Белая")
							frontal_name_array[5] = ""
							else
							frontal_name_array[5] = "Покраска обратной стороны"
            end
          end
          if frontal_name_array[2].include?("глянец")
						if frontal_name_array[4].include?("Модерн")
							frontal_name_array.insert(3,"| Надбавка модерн глянец")
							else
							frontal_name_array.insert(3,"| Надбавка фрезеровка глянец")
            end
          end
          
          
					elsif frontal_name_array[1].include?("МДФ в ПВХ пленке")
					if frontal_name_array[5].include?("обр.стор. Белая")
						frontal_name_array[5] = ""
						else
            frontal_name_array[5] = "| Пленка с двух сторон"
          end
          
          
          elsif frontal_name_array[1].include?("МДФ в шпоне")
          if frontal_name_array[5].include?("обр.стор. Белая")
            frontal_name_array[5] = ""
            else
            frontal_name_array[5] = "| Шпон с двух сторон"
          end
          
          
          elsif frontal_name_array[1].include?("МДФ в пластике")
          if frontal_name_array[5].include?("обр.стор. Белая")
            frontal_name_array[5] = ""
            else
            frontal_name_array[5] = "| Пластик с двух сторон"
          end
          
          
          elsif frontal_name_array[1].include?("ЛДСП") || frontal_name_array[1].include?("МДФ")
          begin_number = 1
        end
        
        
        if frontal_name_array[4]
          if (frontal_name_array[4].include?("Витрина")) || (frontal_name_array[4].include?("Решетка"))
            frontal_name_array[4] = frontal_name_array[4][0..-11]
          end
        end
        if frontal_name_array[5]
          if (frontal_name_array[5].include?("Витрина")) || (frontal_name_array[5].include?("Решетка"))
            frontal_name_array[5] = frontal_name_array[5][0..-11]
          end
        end
        if frontal_name_array[6] && frontal_name_array[6].include?("патина")
          if frontal_name_array[4].include?("R_")
            frontal_name_array[6] = "| R Патина"
            else
            frontal_name_array[6] = "| Патина"
          end
        end
        
        name = name.join.strip.gsub("[","(").gsub("]",")").gsub("|",",")
        cost_frontal = 0
        enter = 0
        frontal_name_array = frontal_name_array.reject { |c| c.empty? }
        @price_array = []
        @price_hash.each_pair { |folder_price,mat_price|
          if all_folder_price.include?(folder_price)
            @price_array += mat_price
          end
        }
        found_index = nil
        @price_array.each { |mat_price|
          name_price = mat_price[2].downcase.gsub("ё","е").gsub("й","и").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"")
          if name_price == frontal_name_array[begin_number..-1].join.downcase.gsub("ё","е").gsub("й","и").gsub("фр-ка","").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"").strip
            provider = mat_price[0]
            article = mat_price[1]
            net_cost = mat_price[4].to_s.gsub(",",".")
            mat_currency = mat_price[5]
            cost = mat_price[7].to_s.gsub(",",".")
            work = mat_price[8].to_s.gsub(",",".")
            code = mat_price[10]
            weight = mat_price[11]
            link = mat_price[12]
            cost = cost.to_f*markup.to_f
            net_cost = net_cost.to_f
            if work[-1] == "%"
              work = (work[0..-1].to_f)*net_cost/100
              else
              work = work.to_f
            end
            cost = cost*kf*markup.to_f
            net_cost = net_cost*kf
            return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
          end
          for i in begin_number..frontal_name_array.length-1
            next if i == found_index
            frontal_name = frontal_name_array[i].downcase.gsub("ё","е").gsub("й","и").gsub("фр-ка","").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"").strip
            if name_price == frontal_name
              found_index = i
              provider = mat_price[0]
              article = mat_price[1]
              mat_currency = mat_price[5]
              net_cost_frontal = mat_price[4].to_s.gsub(",",".")
              cost_frontal = mat_price[7].to_s.gsub(",",".")
              work_frontal = mat_price[8].to_s.gsub(",",".")
              
              if mat_currency == "KF"
                kf *= cost_frontal.to_f
                else
                cost += cost_frontal.to_f
                net_cost += net_cost_frontal.to_f
                if work_frontal[-1] == "%"
                  work+=(work_frontal[0..work_frontal.length-1])*net_cost_frontal/100
                  else
                  work += work_frontal.to_f
                end
              end
              enter += 1;
              if enter == frontal_name_array.length-begin_number
                cost = cost*kf*markup.to_f
                net_cost = net_cost*kf
                return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
              end
            end
          end
        }
        if enter != frontal_name_array.length-begin_number
          cost = 0
          work = 0
        end
        cost = cost*kf*markup.to_f
        net_cost = net_cost*kf
        return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
        
        
        elsif name.to_s.downcase !~ /фартук|стеновая панель|столешница|кромка/i && name.to_s.downcase =~ /рамка|integro|макмарт/i
        for i in 0..@profil_name_cost_arr.length-1
          profil_name_cost_arr = @profil_name_cost_arr[i]
          if (profil_name_cost_arr[0] == name)
            cost = profil_name_cost_arr[1]*markup.to_f
            net_cost = profil_name_cost_arr[2]
            work = profil_name_cost_arr[3]
            mat_currency = profil_name_cost_arr[4]
            provider = profil_name_cost_arr[5]
            article = profil_name_cost_arr[6]
            cost = cost/count;
            net_cost = net_cost/count
            return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
          end
        end
        
        elsif name.to_s.downcase.include?("опора") && name.downcase.include?("из трубы")
        for i in 0..@pipe_name_cost_arr.length-1
          pipe_name_cost_arr = @pipe_name_cost_arr[i]
          if (pipe_name_cost_arr[0] == name)
            cost = pipe_name_cost_arr[1]*markup.to_f
            net_cost = pipe_name_cost_arr[2]
            work = pipe_name_cost_arr[3]
            mat_currency = pipe_name_cost_arr[4]
            provider = pipe_name_cost_arr[5]
            article = pipe_name_cost_arr[6]
            cost = cost/count
            net_cost = net_cost/count
            return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
          end
        end
				
				else
				@price_array = []
				@price_hash.each_pair { |folder_price,mat_price|
					if all_folder_price.include?(folder_price)
						@price_array += mat_price
          end
        }
				
				acc_group = []
				acc_group_hash.each_pair{|group,acc_arr|
					if group[1].strip.gsub("~","=").gsub("|",",").gsub("плюс","+").gsub("[","(").gsub("]",")") == name
						if acc_arr[0][2]=="Цена частей"
							acc_arr[1..-1].each{|acc|
								acc_group << [acc[1],acc[3],acc[4]]
              }
            end
          end
        }
				if acc_group == []
					acc_group << [name,count,unit]
        end
        
				acc_group.each{|part|
					part_cost = 0
					part_net_cost = 0
					part_work = 0
					part_name = part[0].strip.gsub("~","=").gsub("|",",").gsub("плюс","+").gsub("[","(").gsub("]",")")
          part_name_for_search = part_name.to_s.downcase
          part_name_for_search = part_name_for_search.gsub("столешница иск. камень","").gsub("стеновая панель из камня","").strip
					part_count = part[1]
					if !part_name.include?(" ") # название без пробела
						@price_array.each { |mat_price|
							name_price = mat_price[2].gsub(",0","").gsub("ё","е").gsub("c","с").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"")
							if part_name_for_search.include?("труба")
								part_name_for_search = part_name_for_search[0..part_name_for_search.rindex(" ")]
              end
							if name_price.downcase.include?(part_name_for_search.downcase.gsub(",0","").gsub("ё","е").gsub("c","с").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,""))
								provider = mat_price[0]
								article = mat_price[1]
                part_net_cost = mat_price[4].to_s.gsub(",",".")
								mat_currency = mat_price[5]
								part_cost = mat_price[7].to_s.gsub(",",".")
                part_work = mat_price[8].to_s.gsub(",",".")
                code = mat_price[10]
                weight = mat_price[11]
                link = mat_price[12]
								break
              end
            }
						
						else # в названии есть пробелы
						
            name_of_edge = false
						if part_name_for_search.include?("ножка")
							part_name_for_search = part_name_for_search.gsub("84","100")
            end
						name_arr = part_name_for_search.downcase.gsub("ё","е").gsub("c","с").gsub("х","x").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"")
            if name_arr.include?("кромка")
              name_arr = name_arr.gsub("08х","1х").gsub("08x","1x")
              name_of_edge = true
            end
            name_arr = name_arr.split(" ")
						name_arr = name_arr.reject { |c| c.empty? }
						@price_array.each { |mat_price|
							name_price = mat_price[2].downcase.gsub("х","x").gsub("ё","е").gsub("c","с").gsub(",0","").gsub(/[^а-яА-ЯёЁa-zA-Z0-9\s]/,"")
							enter = 0;
							name_price = name_price.gsub("08х","1х").gsub("08x","1x") if name_of_edge
							for name_slice in name_arr
								if name_price.include?(name_slice)
									enter = enter+1
                end
								if enter == name_arr.length || part_name_for_search.include?("кромка") && enter > 1 && name_price.split(" ").length == 2 || part_name_for_search.include?("плинтус") && name_price.downcase.include?("плинтус") && enter == name_arr.length-1 || part_name_for_search.include?("труба") && name_price.downcase.include?("труба") && enter == name_arr.length-1 || part_name_for_search.include?("металл") && enter >= name_arr.length-1
									provider = mat_price[0]
									article = mat_price[1]
                  part_net_cost = mat_price[4].to_s.gsub(",",".")
									mat_currency = mat_price[5]
                  part_cost = mat_price[7].to_s.gsub(",",".")
                  part_work = mat_price[8].to_s.gsub(",",".")
                  code = mat_price[10]
                  weight = mat_price[11]
                  link = mat_price[12]
									break
                end
              end
							if enter == name_arr.length
								break
              end
            }
          end
					part_cost = part_cost.to_f*markup.to_f
					part_net_cost = part_net_cost.to_f
					if part_work[-1] == "%"
						part_work = (part_work[0..-1].to_f)*part_net_cost/100
						else
						part_work = part_work.to_f
          end
					if part_count!=0 && count!=0
						cost += part_cost*part_count.to_f/count.to_f
						net_cost += part_net_cost*part_count.to_f/count.to_f
						work += part_work*part_count.to_f/count.to_f
          end
        }
				return [name,count,unit,cost,net_cost,work,provider,article,mat_currency,code,weight,link]
      end
    end#def
		def name_to_dialog(ent,sel_length)
			FileUtils.rm_rf(Dir.glob(PATH + "/html/cont/thumbnail/*"))
			thumbnail = ent.definition.save_thumbnail PATH + "/html/cont/thumbnail/" + ent.definition.name.gsub("#", "_") + ".png"
			@thumbnail = "cont/thumbnail/" + ent.definition.name.gsub("#", "_") + ".png"
			if sel_length > 4
				@des_name = sel_length.to_s+' '+SUF_STRINGS["Componentov"]
				item_code = ""
				@summary = "nil"
				@description = ""
				elsif sel_length > 1
				@des_name = sel_length.to_s+' '+SUF_STRINGS["Componenta"]
				item_code = ""
				@summary = "nil"
				@description = ""
				else
				@des_name = ent.definition.get_attribute("dynamic_attributes", "name")
				@des_name = ent.definition.get_attribute("dynamic_attributes", "_name") if !@des_name
				@des_name = ent.definition.name if !@des_name
				@des_name = translation_formlabel(@des_name)
				item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode","")
				@summary = ent.definition.get_attribute("dynamic_attributes", "summary", "nil")
				@description = ent.definition.get_attribute("dynamic_attributes", "description","")
				@description = translation_formlabel(@description)
      end
			vend = [@des_name, item_code, @summary, @description, @thumbnail]
			command = "name_list(#{vend.inspect})"
			$dlg_suf.execute_script(command) if $dlg_suf
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
		def letter?(string)
			string =~ /[A-Za_zА-Яа-яЁё]/
    end#def
		def operations_list(entity=nil,send=true)
			sep = ","
			@model = Sketchup.active_model
			dict = @model.attribute_dictionary 'su_parameters'
			dict.each {|k,v| sep = v.split("=")[2] if k == "sep" } if dict
			read_param
			@groove_count = 0
			@groove_array = []
			@groove_hash = {}
			@components_cut = {}
			@holes = {}
			@edge_hash = {}
			@total_groove_count = 0
			@ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
			@ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
			@sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
			entity ? sel = entity : sel = @sel
			sel = @ent if sel.length == 0
			new_table = "new_table"
			if sel
				sel.each { |ent| search_operations(ent,Geom::Transformation.new,false)}
				if @groove_array != []
					@groove_array.each { |groove|
						if @groove_hash[[groove[6],groove[1]]]
							@groove_hash[[groove[6],groove[1]]] += groove[5].to_f
							else
							@groove_hash[[groove[6],groove[1]]] = groove[5].to_f
            end
          }
        end
				
				if send == true
					if @edge_hash != {}
						vend = [new_table,sep,SUF_STRINGS["Edge banding"],'edge_banding']
						command = "acc_table(#{vend.inspect})"
						$dlg_suf.execute_script(command)
						@edge_hash.each_pair{|name,count|
							vend = [SUF_STRINGS["Edge"]+" "+name,(count[0]/1000).round(2),SUF_STRINGS["m"],'edge_banding']
							command = "acc_rows(#{vend.inspect})"
							$dlg_suf.execute_script(command)
							vend = [SUF_STRINGS["Pasted strips"],count[1].round(2),SUF_STRINGS["pc"],'edge_banding']
							command = "acc_rows(#{vend.inspect})"
							$dlg_suf.execute_script(command)
            }
						new_table = ""
          end
					
					if @groove_hash != {}
						vend = [new_table,sep,SUF_STRINGS["Groove"],'groove']
						command = "acc_table(#{vend.inspect})"
						$dlg_suf.execute_script(command)
						@groove_hash.each_pair{|name,count|
							vend = [name[0],(count/1000).round(2),SUF_STRINGS["m"],'groove']
							command = "acc_rows(#{vend.inspect})"
							$dlg_suf.execute_script(command)
            }
						new_table = ""
          end
					
					@holes_count = 0
					if @holes != {}
						vend = [new_table,sep,SUF_STRINGS["Holes"],'hole']
						command = "acc_table(#{vend.inspect})"
						$dlg_suf.execute_script(command)
						@holes = @holes.to_a.sort_by{|arr|[arr[0].split("x")[0].to_f,arr[0].split("x")[1].to_f]}.to_h
						@holes.each_pair{|name,count|
							@holes_count += count
							#vend = ["total_hole_count",@holes.values.reduce(:+),@holes.to_a]
							vend = [name,count.round(2),SUF_STRINGS["pc"],'hole']
							command = "acc_rows(#{vend.inspect})"
							$dlg_suf.execute_script(command)
            }
						vend = ["<b>"+SUF_STRINGS["Count of all holes"]+"<b>","<b>"+@holes_count.round.to_s+"<b>","<b>"+SUF_STRINGS["pc"]+"<b>",'hole',"false"]
						command = "acc_rows(#{vend.inspect})"
						$dlg_suf.execute_script(command)
          end
        end
      end
			return [@edge_hash,@groove_hash,@holes]
    end#def
		def list_group(list_accessories)
			acc_group_hash = {}
			add_list = []
			@acc_lists.each { |list|
				delete_list = []
        acc_list = list.split("=")[3]
        
        if list.split("=")[5] == "Нет"
          list_accessories.each { |acc|
						if acc_list.gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~").include?(acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~"))
              delete_list << acc
            end
          }
          list_accessories = list_accessories - delete_list
          
				  elsif list.split("=")[5] == "Группа"
					include = 0
					min_count = 0
					acc_count = {}
					list_accessories.each { |acc|
						if acc_list.gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~").include?(acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~"))
							include += 1
							delete_list << acc
							min_count = acc[3] if min_count==0 || acc[3] < min_count
            end
          }
					acc_list.split(";").each { |acc| acc_count[acc.split("~")[0]] = acc.split("~")[1] }
					if list.split("=")[4] == "Если есть в списке" && include>0 || list.split("=")[4] == "Совпадение всех частей" && acc_list.split(";").length==include
						if list.split("=")[4] == "Если есть в списке"
							list_accessories = list_accessories - delete_list
							list_accessories << [delete_list[0][0],list.split("=")[0],delete_list[0][2],1,list.split("=")[2],""]
							acc_group_hash[[delete_list[0][0],list.split("=")[0],delete_list[0][2],1,list.split("=")[2],""]] = [[list.split("=")[5],list.split("=")[6],list.split("=")[7]]]+delete_list
							elsif delete_list.all?{|acc| delete_list[0][3] == acc[3]}
							list_accessories = list_accessories - delete_list
							list_accessories << [delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]
							acc_group_hash[[delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]] = [[list.split("=")[5],list.split("=")[6],list.split("=")[7]]]+delete_list
							else
							new_list_accessories = []
							new_list_accessories << [delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]
							acc_group_hash[[delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]] = [[list.split("=")[5],list.split("=")[6],list.split("=")[7]]]
							list_accessories.each{|acc|
								if delete_list.include?(acc)
                  if acc[3] == min_count
                    acc_group_hash[[delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]] << acc
                    else
                    count = acc[3]-acc_count[acc[1]].to_f
                    if count != 0
                      new_list_accessories << [acc[0],acc[1],acc[2],count,acc[4],""]
                    end
                    acc_group_hash[[delete_list[0][0],list.split("=")[0],delete_list[0][2],min_count,list.split("=")[2],""]] << [acc[0],acc[1],acc[2],acc[3],acc[4],acc[5]]
                  end
                  else
                  new_list_accessories << acc
                end
              }
              list_accessories = new_list_accessories
              list_accessories = list_accessories - delete_list
            end
						elsif list.split("=")[7] == "Цена частей"
						list_accessories.each { |acc|
							if list.split("=")[0].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~") == acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~")
								acc_group_hash[acc] = [[list.split("=")[5],list.split("=")[6],list.split("=")[7]]]
								list.split("=")[3].split(";").each{|acc_list|
									acc_group_hash[acc] << [acc[0],acc_list.split("~")[0],acc[2],acc[3].to_f*acc_list.split("~")[1].to_f,acc[4],acc[5]]
                }
              end
            }
          end
					
					else
					list_accessories.each { |acc|
						if list.split("=")[0].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~") == acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~")
							acc_group_hash[acc] = [[list.split("=")[5],list.split("=")[6],list.split("=")[7]]]
							list.split("=")[3].split(";").each{|acc_list|
								acc_group_hash[acc] << [acc[0],acc_list.split("~")[0],acc[2],acc[3].to_f*acc_list.split("~")[1].to_f,acc[4],acc[5]]
								add_list << [acc[0],acc_list.split("~")[0],acc[2],acc[3].to_f*acc_list.split("~")[1].to_f,acc[4],acc[5]] if !add_list.include?([acc[0],acc_list.split("~")[0],acc[2],acc[3].to_f*acc_list.split("~")[1].to_f,acc[4],acc[5]])
								delete_list << acc if !delete_list.include?(acc)
              }
            end
          }
					list_accessories.each_with_index { |acc,index|
						delete_list.each { |del_acc|
							if del_acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~") == acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~")
								if del_acc[3] == acc[3]
									list_accessories.delete_at(index)
									else
									list_accessories[index] = [acc[0],acc[1],acc[2],acc[3].to_f-del_acc[3].to_f,acc[4],acc[5]]
                end
              end
            }
          }
        end
      }
			add_list.each { |add_acc|
				if list_accessories.any?{|acc| add_acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~") == acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~")}
					list_accessories.each_with_index { |acc,index|
						if add_acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~") == acc[1].gsub("(","[").gsub(")","]").gsub(",","|").gsub("=","~")
							list_accessories[index] = [acc[0],acc[1],acc[2],add_acc[3].to_f+acc[3].to_f,acc[4],acc[5]]
            end
          }
					else
					list_accessories << add_acc
        end
      }
			return list_accessories,acc_group_hash
    end#def
    def add_accessories()
      @additional_list = []
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"additional.dat"))
        path_param = File.join(param_temp_path,"additional.dat")
        else
        path_param = File.join(PATH_COMP,"additional.dat")
      end
      content = File.readlines(path_param)
      content.each { |i| @additional_list << i.strip }
      dict = Sketchup.active_model.attribute_dictionary 'su_lists'
      model_accessories = []
      if dict
        if dict["accessories"]
          dict["accessories"].each { |acc|
            model_accessories << acc
          }
        end
      end
      html = "<style>"
      html += "body { font-family: Arial; color: #696969; font-size: 12px; padding-bottom: 30px; }"
      html += "#additional_accessories_table { width: 100%; }"
      html += "#additional_accessories_table th { text-align:left; }"
      html += "#additional_accessories_table td { height: 18px; width: 20px;}"
      html += "#additional_accessories_table td:nth-child(2) { width: 100%; }"
      html += ".footer { position: fixed; bottom: 0px; left: 0px; width: 100%; background-color: #FFFFFF; border-top: 1px solid #ccc; text-align: center; }"
      html += ".button { margin: 5px; height:20px; background-color: #FFFFFF; cursor:pointer; border: 1px solid #ccc; color: #000000;}"
      html += ".button:hover { background-color: #ccc; }"
      html += "</style>"
      html += "<script>"
      html += "function save() {"
      html += "let acc_list = [];"
      html += "var trs = document.querySelectorAll('tr');"
      html += "for (var i = 1; i < trs.length; i++) {"
      html += "if (trs[i].cells[0].childNodes[0].checked){"
      html += "if ((trs[i].cells[1].childNodes[0].value != '')&&(trs[i].cells[2].childNodes[0].value != '')) {"
      html += "acc_list.push([\"furniture\",trs[i].cells[1].childNodes[0].value,\"0\",trs[i].cells[2].childNodes[0].value,trs[i].cells[3].childNodes[0].value]);"
      html += "}}}"
      html += "sketchup.save(acc_list);"
      html += "}"
      html += "function edit() {sketchup.edit();}"
      html += "function cancel() {sketchup.cancel();}"
      html += "</script>"
      html += "<table id='additional_accessories_table'>"
      html += "<tr><th></th><th>#{SUF_STRINGS["name"]}</th><th>#{SUF_STRINGS["count"]}</th></tr>"
      @additional_list.each { |acc|
        if acc.include?("<->")
          name = acc.split("<->")[0]
          unit = acc.split("<->")[1]
          else
          name = acc
          unit = SUF_STRINGS["pc"]
        end
        checked = ''
        count = 1
        model_accessories.each{|model_acc|
          if model_acc[1]==name
            checked = 'checked'
            count = model_acc[3]
          end
        }
        html += "<tr><td><input type='checkbox' #{checked} style=\"width: 20px;\"</input></td><td><input style=\"width: 100%;\" value=\"#{name}\"></input></td><td><input style=\"width: 35px;\" value=\"#{count}\"></input></td><td><input disabled=true; style=\"width: 30px;\" value=\"#{unit}\"></input></td></tr>"
      }
      html += "</table>"
      html += "<div class=\"footer\" >"
      html += "<button class=\"button\" onclick=\"save();\">#{SUF_STRINGS["Save"]}</button>"
      html += "<button class=\"button\" onclick=\"edit();\">#{SUF_STRINGS["Edit list"]}</button>"
      html += "<button class=\"button\" onclick=\"cancel();\">#{SUF_STRINGS["Cancel"]}</button>"
      html += "</div>"
      @dlg.close if @dlg && (@dlg.visible?)
      @dlg = UI::HtmlDialog.new({
        :dialog_title => ' ',
        :preferences_key => "add_accessories",
        :scrollable => true,
        :resizable => true,
        :min_width => 400,
        :min_height => 300,
        :width => 400,
        :height => 500,
        :left => 100,
        :top => 100,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      @dlg.set_html(html)
      @dlg.add_action_callback("save") { |_, v|
        add_accessories_to_model(v)
        @dlg.close
      }
      @dlg.add_action_callback("edit") { |_, v|
        edit_name_list("additional.dat")
        @dlg.close
      }
      @dlg.add_action_callback("cancel") { |_, v|
        @dlg.close
      }
      OSX ? @dlg.show() : @dlg.show_modal()
    end#def
    def edit_name_list(file_name)
      @additional_list = ""
      path_param = nil
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,file_name))
				path_param = File.join(param_temp_path,file_name)
        elsif File.file?(File.join(TEMP_PATH,"SUF",file_name))
        path_param = File.join(TEMP_PATH,"SUF",file_name)
        elsif File.file?(File.join(PATH_COMP,file_name))
        path_param = File.join(PATH_COMP,file_name)
        else
        path_param = File.join(PATH,"parameters",file_name)
      end
      if path_param
        content = File.readlines(path_param)
        content.each { |i| @additional_list << i }
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
          param_file = File.new(path_param,"w")
          param_file.puts action_name
          param_file.close
          @edit_dlg.close
          add_accessories
        }
        @edit_dlg.set_html(html)
        @edit_dlg && (@edit_dlg.visible?) ? @edit_dlg.bring_to_front : @edit_dlg.show
      end
    end#def
    def add_accessories_to_model(param)
      Sketchup.active_model.set_attribute('su_lists',"accessories",param)
    end
    def accessories_list(entity,max_width_of_count={},send=true,param=true)
      @max_width_of_count = max_width_of_count
      sep = ","
      @model = Sketchup.active_model
      dict = @model.attribute_dictionary 'su_parameters'
      dict.each {|k,v| sep = v.split("=")[2] if k == "sep" } if dict
      dict = Sketchup.active_model.attribute_dictionary 'su_lists'
      model_accessories = []
      if dict
        if dict["accessories"]
          dict["accessories"].each { |acc|
            model_accessories << acc
          }
        end
      end
      @list_accessories = []
      @list_count_list = {}
      @acc_group_hash = {}
      @list_pipe = []
      @list_profil = []
      @acc_in_profile = {}
      @profil_count = []
      @count = 0
      read_param if param
      @drawer_tip_on = false
      @su_type = ["hinge","handle","hidden_handle","furniture","leg","frontal","profil","dryer"]
      @sel = @model.selection.grep(Sketchup::ComponentInstance).to_a
      entity ? sel = entity : sel = @sel
      sel_length = sel.length
      name_to_dialog(sel[0],sel_length) if sel_length != 0 && send
      sel = @model.entities.grep(Sketchup::ComponentInstance).to_a if sel_length == 0
      if sel != nil
        @module_acc = {}
        sel.each { |ent|
          @module_acc_count_list = {}
          if !ent.hidden?
            module_acc = accessories_array(ent,[])
            @module_acc[ent] = [module_acc,@module_acc_count_list]
          end
        }
        #@module_acc.each_pair {|k,v| p k.definition.get_attribute("dynamic_attributes", "itemcode", "0");p v }
        @list_accessories,@acc_group_hash = list_group(@list_accessories)
        @list_accessories += model_accessories
        if send
          vend = ["new_table",sep]
          command = "acc_table(#{vend.inspect})"
          $dlg_suf.execute_script(command)
          @list_accessories.sort_by!{|array| array[1]}
          @list_accessories.each { |acc|
            name = acc[1]
            count = acc[3].to_f
            unit = acc[4]
            if @max_width_of_count[name] && @max_width_of_count[name] != "0" && @max_width_of_count[name] != 0
              count = (count/@max_width_of_count[name]).ceil
              unit = SUF_STRINGS["pc"]
              else
              count = count.round(2)
            end
            if @list_count_list[name+unit] && @list_count_list[name+unit] != []
              name += " (#{@list_count_list[name+unit].join(", ")})"
            end
            group_arr = group_hash(@acc_group_hash,acc)
            vend = [name,count.round(2),SUF_ATT_STR[unit],group_arr]
            command = "acc_rows(#{vend.inspect})"
            $dlg_suf.execute_script(command)
          }
          if @list_profil != []
            vend = ["Рамочные фасады"]
            command = "acc2_table(#{vend.inspect})"
            $dlg_suf.execute_script(command) if send == true
            #@list_profil = @list_profil.sort
            @list_profil.each { |acc|
              name = acc[1]
              width = acc[2]
              height = acc[3]
              count = acc[4].to_f
              unit = acc[5]
              vend = [name,width,height,count.round(2),SUF_ATT_STR[unit]]
              command = "acc2_rows(#{vend.inspect})"
              $dlg_suf.execute_script(command) if send == true
            }
          end
        end
      end
      return [@list_accessories,@acc_group_hash,@list_pipe,@list_profil,@module_acc,@list_count_list]
    end#def
    def group_hash(acc_group_hash,acc)
      group_arr = []
      if @acc_group_hash[acc] && @acc_group_hash[acc][0][0] == "Группа"
        @acc_group_hash[acc][1..-1].each{|part|
          group_arr << [part[1],part[3].round.to_s,part[4],@acc_group_hash[acc][0][1]]
          group_arr += group_hash(acc_group_hash,part) if group_hash(acc_group_hash,part) != []
        }
      end
      return group_arr
    end#def
    def accessories_array(entity,module_accessories=[])
      unit = SUF_STRINGS["pc"]
      su_info = entity.definition.get_attribute("dynamic_attributes", "su_info")
      su_type = entity.definition.get_attribute("dynamic_attributes", "su_type")
      summary = entity.definition.get_attribute("dynamic_attributes", "summary", "0")
      a03_name = entity.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      tip_on = entity.definition.get_attribute("dynamic_attributes", "tip_on", "1")
      max_width_of_count = entity.definition.get_attribute("dynamic_attributes", "max_width_of_count", "0")
      @drawer_tip_on = true if su_type=="drawer" && tip_on.to_s=="2"
      if max_width_of_count && max_width_of_count != "0"
        if @max_width_of_count[a03_name] == nil || @max_width_of_count[a03_name] == 0
          @max_width_of_count[a03_name] = max_width_of_count.to_f
          else
          @max_width_of_count[a03_name] = max_width_of_count.to_f if max_width_of_count.to_f < @max_width_of_count[a03_name]
        end
      end
      if !su_info || !su_type
        if summary.include?("EasyKitchen")
          su_info,su_type = Lists_EasyKitchen.EasyKitchen(entity)
          if !su_info
            entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
              break if su_info
              su_info,su_type = Lists_EasyKitchen.EasyKitchen(e)
            }
          end
          if su_info
            component_102_article = entity.definition.get_attribute("dynamic_attributes", "component_102_article")
            if su_info && su_info.include?("GOLA") || component_102_article && component_102_article.include?("штанга") || component_102_article && component_102_article.include?("Linear")
              entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
                if !ent.hidden?
                  item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
                  l1_component_102_article = ent.definition.get_attribute("dynamic_attributes", "l1_component_102_article")
                  if l1_component_102_article
                    name = l1_component_102_article
                    count = 1
                    module_acc_count = 1
                    @list_accessories.each {|acc|
                      if acc.include?(name)
                        count += acc[3]
                        @list_accessories.delete(acc)
                      end
                    }
                    module_accessories.each {|acc|
                      if acc.include?(name)
                        module_acc_count += acc[3]
                        module_accessories.delete(acc)
                      end
                    }
                    @list_accessories.push(["furniture",name,1,count,SUF_STRINGS["pc"],""])
                    module_accessories.push(["furniture",name,1,module_acc_count,SUF_STRINGS["pc"],""])
                    elsif item_code.include?("штанга") || item_code.include?("Linear")
                    @list_accessories.push(["furniture",item_code.split("/")[2],1,item_code.split("/")[5].to_f/1000,SUF_STRINGS["m"],""])
                    module_accessories.push(["furniture",item_code.split("/")[2],1,item_code.split("/")[5].to_f/1000,SUF_STRINGS["m"],""])
                    elsif item_code.include?("Держатель")
                    name = item_code.split("/")[2]
                    count = item_code.split("/")[4]
                    module_acc_count = item_code.split("/")[4]
                    @list_accessories.each {|acc|
                      if acc.include?(name)
                        count += acc[3]
                        @list_accessories.delete(acc)
                      end
                    }
                    module_accessories.each {|acc|
                      if acc.include?(name)
                        module_acc_count += acc[3]
                        module_accessories.delete(acc)
                      end
                    }
                    @list_accessories.push(["furniture",name,1,count,SUF_STRINGS["pc"],""])
                    module_accessories.push(["furniture",name,1,module_acc_count,SUF_STRINGS["pc"],""])
                  end
                end
              }
            end
          end
          else
          su_info,su_type = Lists_SDCF.sdcf_info(entity)
        end
      end
      ents = entity.definition.entities.grep(Sketchup::ComponentInstance)
      if su_info && su_info != "" && su_info != " " && !su_info.include?("Без ручки") && su_info[0] != "module" && su_info[0] != "body" && su_type && su_type != "" && su_type != " " && !su_type.include?(SUF_STRINGS["Product"]) && !su_type.include?("Изделие") && !su_type.include?("Тело")
        if @su_type.include?(su_type)
          if su_type != "fartuk" && su_type != "worktop" && su_info.downcase =~ /рамка|integro|макмарт/i
            @ramka = nil
            profile_accessories = []
            ents.each { |e|
              if e.definition.name.include?("Essence") || e.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                @color = e.material.name
                @ramka = e.definition.get_attribute("dynamic_attributes", "ramka")
                profile_accessories = additional_acc(e,[],true)
                elsif !e.definition.name.include?("Body")
                accessories_array(e,module_accessories) if !e.hidden?
              end
              if !@ramka
                e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
                  if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                    @color = ent.material.name
                    @ramka = ent.definition.get_attribute("dynamic_attributes", "ramka")
                    profile_accessories = additional_acc(ent,[],true)
                    else
                    accessories_array(ent,module_accessories) if !ent.hidden?
                  end
                }
              end
            }
            if @ramka
              @ramka = @ramka.to_f*25.4
              su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
              name = su_info[1]
              width = su_info[3]
              height = su_info[4]
              @acc_in_profile[[name+"_"+@color,width,height]] = profile_accessories
              count = 1
              @list_profil.each {|acc|
                if acc.include?(name+"_"+@color) && acc.include?(width) && acc.include?(height)
                  count = acc[4] + 1
                  @list_profil.delete(acc)
                  module_accessories.delete(acc)
                end
              }
              @list_profil.push(["ramka",name+"_"+@color,width,height,count,unit])
              module_accessories.push(["ramka",name+"_"+@color,width,height,@count,unit])
              @profil_count.each {|acc|
                if acc.include?(name+"_"+@color)
                  count = acc[3] + 1
                  @profil_count.delete(acc)
                end
              }
              # для сметы
              @profil_count.push(["ramka",name+"_"+@color,@ramka.round(0).to_s,count,unit])
            end
            
            elsif su_info.to_s.include?("Опора") && su_info.to_s.include?("из трубы")
            su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
            name = su_info[1]
            height = su_info[3]
            width1 = su_info[4]
            width2 = su_info[5]
            pipe_depth = su_info[11]
            pipe_width = su_info[12]
            hole = su_info[13]
            thread = su_info[14]
            corner = su_info[15]
            count = 1
            @list_pipe.each {|acc|
              if acc.include?(name) && acc.include?(width) && acc.include?(height)
                count = acc[3] + 1
                @list_pipe.delete(acc)
              end
            }
            @list_pipe.push(["pipe",name,height,(width1>width2 ? width1 : width2),count,unit,(width1>width2 ? width2 : width1),pipe_depth,pipe_width,hole,thread,corner])
            #@list_pipe.push(["pipe",name,height,width1,count,unit])
            
            @profil_count.each {|acc|
              if acc.include?(name)
                count = acc[3] + 1
                @profil_count.delete(acc)
              end
            }
            # для сметы
            @profil_count.push(["ramka",name,pipe_depth,count,unit])
            
            else
            if @drawer_tip_on && su_info.include?("Tip-on") && su_type.include?("handle")
              
              else
              su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
              if su_info[1]
                name = su_info[1]
                thickness = su_info[5]
                count = su_info[9].to_f
                edge_y1 = entity.definition.get_attribute("dynamic_attributes", "edge_y1", "1")
                edge_y2 = entity.definition.get_attribute("dynamic_attributes", "edge_y2", "1")
                module_acc_count = su_info[9].to_f
                unit = su_info[10]
                if unit == SUF_STRINGS["m"]
                  count_name = (count*1000).round.to_s
                  if su_type == "hidden_handle"
                    count_name += "L" if edge_y2.to_i == 2
                    count_name += "R" if edge_y1.to_i == 2
                  end
                  @list_count_list[name+unit] = [] if !@list_count_list[name+unit]
                  if @list_count_list[name+unit].any?{|a|a.include?(count_name)}
                    @list_count_list[name+unit].each_with_index{|count_list,index|
                      if count_list.include?(count_name)
                        if count_list.include?("x")
                          count_name_arr = count_list.split("x")
                          @list_count_list[name+unit][index] = count_name+"x"+(count_name_arr[1].to_i+1).to_s
                          else
                          @list_count_list[name+unit][index] += "x2"
                        end
                      end
                    }
                    else
                    @list_count_list[name+unit] << count_name
                  end
                  @module_acc_count_list[name] = [] if !@module_acc_count_list[name]
                  @module_acc_count_list[name] << count_name
                end
                @list_accessories.each {|acc|
                  if acc.include?(name) && acc.include?(unit)
                    count += acc[3]
                    @list_accessories.delete(acc)
                  end
                }
                module_accessories.each {|acc|
                  if acc.include?(name) && acc.include?(unit)
                    module_acc_count += acc[3]
                    module_accessories.delete(acc)
                  end
                }
                if su_type != "frontal"
                  @list_accessories.push([su_type,name,thickness,count.round(2),unit,""])
                  module_accessories.push([su_type,name,thickness,module_acc_count.round(2),unit,""])
                end
              end
            end
          end
        end
      end
      if su_info && su_info.to_s.include?("Опора") && su_info.to_s.include?("из трубы") || su_info && su_info.to_s.downcase =~ /рамка|integro|макмарт/i && su_type != "fartuk" && su_type != "worktop"
        module_accessories = additional_acc(entity,module_accessories,false)
        else
        module_accessories = additional_acc(entity,module_accessories,false)
        ents.each { |e| module_accessories = accessories_array(e,module_accessories) if !e.hidden? }
      end
      return module_accessories
    end#def
    def additional_acc(entity,module_accessories,profile_acc)
      su_type = "furniture"
      if entity.definition.get_attribute("dynamic_attributes", "y1_name") || entity.definition.get_attribute("dynamic_attributes", "y01_name")
        for number in 1..19
          y_name = entity.definition.get_attribute("dynamic_attributes", "y"+number.to_s+"_name")
          if !y_name
            y_name = entity.definition.get_attribute("dynamic_attributes", "y0"+number.to_s+"_name")
            number = "0"+number.to_s
          end
          if y_name && y_name != "Нет" && y_name != "1" && y_name != "0" && y_name.strip != ""
            name = y_name
            thickness = "0"
            count = entity.definition.get_attribute("dynamic_attributes", "y"+number.to_s+"_quantity").to_f
            module_acc_count = count
            unit = entity.definition.get_attribute("dynamic_attributes", "y"+number.to_s+"_unit", SUF_STRINGS["pc"])
            if !profile_acc
              @list_accessories.each {|acc|
                if acc.include?(name) && acc.include?(unit)
                  count = count + acc[3]
                  @list_accessories.delete(acc)
                end
              }
              @list_accessories.push([su_type,name,thickness,count,unit,""])
            end
            module_accessories.each {|acc|
              if acc.include?(name) && acc.include?(unit)
                module_acc_count = module_acc_count + acc[3]
                module_accessories.delete(acc)
              end
            }
            module_accessories.push([su_type,name,thickness,module_acc_count,unit,""])
          end
        end
      end
      dict = entity.definition.attribute_dictionary "dynamic_attributes"
      if dict
        dict.each_pair {|attr, v|
          if attr.include?("z") && attr.include?("_name") && v  && v != "Нет" && v != "1" && v != "0" && v.strip != ""
            name = v
            thickness = "0"
            count = entity.definition.get_attribute("dynamic_attributes", attr.gsub("_name","")+"_quantity").to_f
            module_acc_count = count
            unit = SUF_STRINGS["pc"]
            if !profile_acc
              @list_accessories.each {|acc|
                if acc.include?(name) && acc.include?(unit)
                  count = count + acc[3]
                  @list_accessories.delete(acc)
                end
              }
              @list_accessories.push([su_type,name,thickness,count,unit,""])
            end
            module_accessories.each {|acc|
              if acc.include?(name) && acc.include?(unit)
                module_acc_count = module_acc_count + acc[3]
                module_accessories.delete(acc)
              end
            }
            module_accessories.push([su_type,name,thickness,module_acc_count,unit,""])
          end
        }
      end
      if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        module_accessories = search_holes(entity,module_accessories,profile_acc,su_type)
      end
      return module_accessories
    end#def
    def search_holes(entity,module_accessories,profile_acc,su_type)
      entity.definition.entities.grep(Sketchup::Group).each { |e|
        if e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
          dict = e.attribute_dictionary "dynamic_attributes"
          if dict
            dict.each_pair {|attr, v|
              if attr.include?("z") && attr.include?("_name") && v  && v != "Нет" && v != "1" && v != "0" && v.strip != ""
                name = v
                thickness = "0"
                count = e.get_attribute("dynamic_attributes", attr.gsub("_name","")+"_quantity").to_f
                module_acc_count = count
                unit = SUF_STRINGS["pc"]
                if !profile_acc
                  @list_accessories.each {|acc|
                    if acc.include?(name) && acc.include?(unit)
                      count = count + acc[3]
                      @list_accessories.delete(acc)
                    end
                  }
                  @list_accessories.push([su_type,name,thickness,count,SUF_ATT_STR[unit],""])
                end
                module_accessories.each {|acc|
                  if acc.include?(name) && acc.include?(unit)
                    module_acc_count = module_acc_count + acc[3]
                    module_accessories.delete(acc)
                  end
                }
                module_accessories.push([su_type,name,thickness,module_acc_count,unit,""])
              end
            }
          end
        end
      }
      return module_accessories
    end#def
    def find_tech_cost(tech_type,tech_article)
      return "0" if !File.file?(File.join(PATH_PRICE,"Техника.xml"))
      content = File.readlines(File.join(PATH_PRICE,"Техника.xml"))
      return "0" if content==""
      materials = xml_value(content.join("").strip,"<Materials>","</Materials>")
      return "0" if materials==""
      material_array = xml_array(materials,"<Material>","</Material>")
      material_array.each{|cont|
        name = xml_value(cont,"<Name>","</Name>")
        article = xml_value(cont,"<Article>","</Article>")
        if article.downcase == tech_article.downcase
          return xml_value(cont,"<Price>","</Price>")
          elsif name.downcase.include?(tech_type.downcase) && name.downcase.include?(tech_article.downcase)
          return xml_value(cont,"<Price>","</Price>")
        end
      }
      return "0"
    end#def
    def tech_list()
      sel = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      if sel != nil
        sel.each { |entity|
          if !entity.hidden?
            for number in 1..5
              tech_type = entity.definition.get_attribute("dynamic_attributes", "tech"+number.to_s+"_type")
              tech_article = entity.definition.get_attribute("dynamic_attributes", "tech"+number.to_s+"_article")
              tech_provider = entity.definition.get_attribute("dynamic_attributes", "tech"+number.to_s+"_provider")
              tech_services = entity.definition.get_attribute("dynamic_attributes", "tech"+number.to_s+"_services")
              tech_count = entity.definition.get_attribute("dynamic_attributes", "tech"+number.to_s+"_count","1")
              if tech_type 
                case tech_services
                  when "1" then tech_services = " ("+SUF_STRINGS["w/o inst"]+")"
                  when "2" then tech_services = " ("+SUF_STRINGS["inst"]+")"
                  when "3" then tech_services = " ("+SUF_STRINGS["inst and con"]+")"
                end
                case tech_type
                  when "Мойка" then tech_name = "sink"
                  when "Смеситель" then tech_name = "mixer"
                  when "ПММ" then tech_name = "PMM"
                  when "Вытяжка" then tech_name = "hood"
                  when "ВП" then tech_name = "hob"
                  when "ДШ" then tech_name = "DS"
                  when "СВЧ" then tech_name = "SVH"
                  when "Хол." then tech_name = "fridge"
                  when "СМ" then tech_name = "washer"
                end
                tech_cost = find_tech_cost(tech_type,tech_article)
                if !@tech_list.include?([tech_name,tech_type,tech_article,tech_provider,tech_services,tech_count,tech_cost])
                  @tech_list.push ([tech_name,tech_type,tech_article,tech_provider,tech_services,tech_count,tech_cost])
                  else
                  @tech_list.push ([tech_name,tech_type,tech_article,tech_provider,tech_services,tech_count,tech_cost])
                end
              end
            end
          end
        }
      end
      #p @tech_list
    end#def
    def cost_list(entity,send_dialog=true)
      @groove_components = {}
      su_type_list = ["frontal","carcass","back","glass","edge","worktop","fartuk","plinth","skirting","metal"]
      @total_edge_count = []
      @total_work_count = []
      @total_groove_count = 0
      @total_Jprofile_count = 0
      @total_Jprofile_length = 0
      @total_JprofileUp_count = 0
      @total_JprofileUp_length = 0
      @holes = {}
      material_name_arr = []
      @components_cut = {}
      @mat_ent_components = {}
      @max_width_of_count = {}
      @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      @ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      entity ? sel = entity : sel = @sel
      name_to_dialog(sel[0],sel.length) if sel.length != 0 && send_dialog
      sel = @ent if sel.length == 0
      if sel
        sel.each { |ent|
          su_info = ent.definition.get_attribute("dynamic_attributes", "su_info", "0")
          if !su_info.to_s.include?("Опора")
            material_list(ent,su_type_list,material_name_arr,true,true,true) if !ent.hidden?
          end
        }
        material_name_arr = material_name_arr.uniq.sort{ |a, b| b <=> a }
        @frontal_carcass_mat = []
        material_name_arr.each_with_index { |mat_a,index|
          if mat_a.split("=")[0].include?("frontal")
            material_name_arr.each { |mat|
              if mat.split("=")[0] == "carcass" && mat_a.split("=")[1].to_s == mat.split("=")[1].to_s && mat_a.split("=")[2].to_s == mat.split("=")[2].to_s && mat_a.split("=")[3].to_s == mat.split("=")[3].to_s && mat_a.split("=")[4].to_s == mat.split("=")[4].to_s && mat_a.split("=")[5].to_s == mat.split("=")[5].to_s
                mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
                mat_a.split("=")[6] ? max_width_of_count = mat_a.split("=")[6] : max_width_of_count = "0"
                material_name_arr[index] = 'carcass='+mat_a.split("=")[1]+'='+mat_a.split("=")[2]+'='+mat_a.split("=")[3]+'='+mat_a.split("=")[4]+'='+type_material+'='+max_width_of_count
                @frontal_carcass_mat.push(mat)
              end
            }
          end
        }
        material_name_arr.uniq!
        frontal_mat = [] # для добавления буквы модуля (если несколько материалов на фасадах)
        material_name_arr.each { |mat_a|
          frontal_mat.push (mat_a.split("=")[1].to_s+" "+mat_a.split("=")[0].split("/")[4].to_s) if mat_a.split("=")[0].split("/")[0] == "frontal" && !frontal_mat.include?(mat_a.split("=")[1].to_s+" "+mat_a.split("=")[0].split("/")[4].to_s)
        }
        material_name_arr.each { |mat_a|
          @ent_components = {}
          total_mat_area = 0
          area = 0
          edge_count = []
          work_count = []
          @add_work = []
          type = mat_a.split("=")[0]
          mat = mat_a.split("=")[1].to_s
          mat = mat.encode("utf-8").strip
          back_mat = mat_a.split("=")[2].to_s
          back_mat = back_mat.encode("utf-8")
          thickness = mat_a.split("=")[3]
          unit = mat_a.split("=")[4]
          mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
          mat_a.split("=")[6] ? max_width_of_count = mat_a.split("=")[6] : max_width_of_count = "0"
          list_of_comp = []
          list_of_components = []
          @groove_count = 0
          type.include?("Jprofile") ? j_profile = true : j_profile = false
          sel.each { |ent|
            @Jprofile_count = 0
            @Jprofile_length = 0
            @JprofileUp_count = 0
            @JprofileUp_length = 0
            @z1_type,@z2_type,@y1_type,@y2_type = nil
            if @frontal_carcass_mat.include?("carcass="+mat+"="+back_mat+"="+thickness+"="+unit+"="+type_material+"="+max_width_of_count)
              component_list(Geom::Transformation.new,false,false,ent.definition.name,ent,["carcass","frontal"],mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,[],send_dialog,j_profile,true) if !ent.hidden?
              else
              component_list(Geom::Transformation.new,false,false,ent.definition.name,ent,su_type_list,mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,[],send_dialog,j_profile,false) if !ent.hidden?
            end
            @total_Jprofile_count += @Jprofile_count
            @total_Jprofile_length += @Jprofile_length
            @total_JprofileUp_count += @JprofileUp_count
            @total_JprofileUp_length += @JprofileUp_length
          }
          @total_groove_count += @groove_count
          mat.rindex("_") == mat.length-2 || mat.rindex("_") == mat.length-3 || mat.rindex("_") == mat.length-4 || mat.rindex("_") == mat.length-5 ? mat_name = mat[0..mat.rindex("_")-1] : mat_name = mat
          mat_name = mat_name.strip
          @number_of_strips = []
          type_mat = type_material.gsub("_WorkTop","").gsub("_Worktop","").gsub("_worktop","")
          list_of_components.each { |comp|
            edge_thickness = thickness
            if unit == SUF_STRINGS["pc"]
              area += comp[10]
              if type.include?("worktop") && !comp[4].include?("Угловой элемент")
                edge_count,work_count = calc_stone_edge(comp,edge_count,work_count,mat_name,edge_thickness)
              end
              elsif unit == SUF_STRINGS["m"]
              if type.include?("/")
                if type.include?("worktop")
                  if type.split("/")[6] && type.split("/")[1]+" "+type.split("/")[6] == comp[4]
                    area += comp[6].to_f*comp[10].to_f/1000
                    edge_count,work_count = calc_worktop_edge(comp,edge_count,work_count,mat_name,edge_thickness)
                    elsif !type.split("/")[6]
                    default_array = ["3050","600"]
                    if @worktop_name[type_mat]
                      length = length_width(@worktop_name[type_mat],comp[6],"length",default_array[0])
                      width = length_width(@worktop_name[type_mat],comp[8],"width",default_array[1])
                      elsif @worktop_name["Default"]
                      length = length_width(@worktop_name["Default"],comp[6],"length",default_array[0])
                      width = length_width(@worktop_name["Default"],comp[8],"width",default_array[1])
                      else
                      length = default_array[0]
                      width = (comp[8].to_f > 600 ? "1200" : "600")
                    end
                    if length == type.split("/")[2] && width == type.split("/")[3] && back_mat == type.split("/")[4] && comp[12] == type.split("/")[5]
                      area += comp[6].to_f*comp[10].to_f/1000
                      edge_count,work_count = calc_worktop_edge(comp,edge_count,work_count,mat_name,edge_thickness)
                    end
                  end
                  elsif type.include?("fartuk")
                  area += comp[6].to_f*comp[10].to_f/1000
                  elsif type.include?("metal")
                  area += comp[6].to_f*comp[10].to_f/1000
                end
                else
                area += comp[6].to_f*comp[10].to_f/1000
                edge_count,work_count = calc_worktop_edge(comp,edge_count,work_count,mat_name,edge_thickness)
              end
              else
              if type.include?("fartuk")
                area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                elsif type.include?("metal")
                area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                else
                if type.include?("/")
                  frontal_name = comp[4]
                  patina = ""
                  back = "White"
                  if frontal_name.include?("патина")
                    patina = frontal_name[frontal_name.index("патина")+7..-2]
                    patina_index = frontal_name.index("(патина")
                    patina_end = patina_index+frontal_name[patina_index..-1].index(")")
                    frontal_name = frontal_name[0..patina_index-2]+frontal_name[patina_end+1..-1]
                  end
                  if frontal_name.include?("обр.стор.")
                    back = frontal_name[frontal_name.index("обр.стор.")+10..-2]
                    back_index = frontal_name.index("(обр.стор.")
                    back_end = back_index+frontal_name[back_index..-1].index(")")
                    frontal_name = frontal_name[0..back_index-2]+frontal_name[back_end+1..-1]
                  end
                  #frontal_name = frontal_name[frontal_name.index("Фасад")..-1] if frontal_name.index("Фасад") == 0
                  frontal_name = frontal_name.gsub(/Нар/,"_R").gsub(/Вн/,"_R")
                  frontal_name = SUF_STRINGS["frontal"] if !frontal_name.include?("Фасад_") && !frontal_name.include?("ФасадРадиус")
                  if comp[22] && comp[22] != ""
                    if type.split("/")[4] == comp[22] || type.split("/")[4]+"/"+type.split("/")[5] == comp[22]
                      if type.split("/")[3] == patina
                        area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                        elsif frontal_name.include?("ФасадРадиус") && type.include?("ФасадРадиус")
                        area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                        elsif type.split("/")[3] == "0" && patina == ""
                        if type.split("/")[1] == frontal_name || type.split("/")[1] == frontal_name.split(">")[1]
                          area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                          elsif type.split("/")[1] == "Фасад_Модерн" && frontal_name == "Фасад"
                          area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                        end
                      end
                    end
                    else
                    if type.split("/")[3] == patina
                      area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                      elsif frontal_name.include?("ФасадРадиус") && type.include?("ФасадРадиус")
                      area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                      elsif type.split("/")[3] == "0" && patina == ""
                      if type.split("/")[1] == frontal_name || type.split("/")[1] == frontal_name.split(">")[1]
                        area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                        elsif type.split("/")[1] == "Фасад_Модерн" && frontal_name == "Фасад"
                        area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                      end
                    end
                  end
                  type += "/"+comp[5][0] if comp[5] != "" && frontal_mat.length > 1 && type[-1] != comp[5][0]
                  else
                  area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
                end
                if comp[4].include?(SUF_STRINGS["Gluing"])
                  if comp[4].include?("4>")
                    edge_thickness = comp[2].to_f.round(0)*4
                    elsif comp[4].include?("3>")
                    edge_thickness = comp[2].to_f.round(0)*3
                    else
                    edge_thickness = comp[2].to_f.round(0)*2
                  end
                end
                @comp_count = comp[10].to_i
                if comp[12].to_s != "0"
                  edge_count = calc_edge(comp,12,6,edge_count,mat_name,edge_thickness,@edge_stock)
                end
                if comp[14].to_s != "0"
                  edge_count = calc_edge(comp,14,6,edge_count,mat_name,edge_thickness,@edge_stock)
                end
                if comp[16].to_s != "0"
                  edge_count = calc_edge(comp,16,8,edge_count,mat_name,edge_thickness,@edge_stock)
                end
                if comp[18].to_s != "0"
                  edge_count = calc_edge(comp,18,8,edge_count,mat_name,edge_thickness,@edge_stock)
                end
              end
              work_count.push([SUF_STRINGS["Gluing"]],[(comp[6].to_f*comp[8].to_f/1000000).round(2)],[SUF_STRINGS["sq.m."]]) if comp[4].include?(SUF_STRINGS["Gluing"])
            end
          }
          area = area.round(2).to_s
          mat_area(type,mat_name,back_mat,thickness,area,unit,type_material,max_width_of_count.to_s)
          edge_count = 0 if edge_count == []
          @edge_count = []
          edge_type_count(type,mat_name,edge_count) if edge_count != 0
          work_count += @add_work
          work_count = 0 if work_count == []
          @work_count = []
          work_type_count(type,mat_name,work_count) if work_count != 0
        }
        @total_edge_count.each_with_index { |edge_arr,index|
          @total_edge_count.each_with_index { |edge_arr2,index2| 
            if edge_arr[1] == edge_arr2[1] && edge_arr[2] == edge_arr2[2] && index != index2
              edge_arr[3] += edge_arr2[3]
              @total_edge_count.delete_at(index2)
            end
          }
        }
        @total_work_count.each_with_index { |work_arr,index|
          @total_work_count.each_with_index { |work_arr2,index2| 
            if work_arr[1] == work_arr2[1] && work_arr[2] == work_arr2[2] && index != index2
              work_arr[3] += work_arr2[3]
              @total_work_count.delete_at(index2)
            end
          }
        }
      end
    end#def
    def mat_area(type,mat,back_mat,thickness,area,unit,type_material,max_width_of_count="0")
      @mat_area = [] if !@mat_area
      @mat_area = @mat_area.push([type,mat,thickness,area,unit,type_material,max_width_of_count])
    end#def
    def new_thickness(thickness)
      edge_thickness = "19"
      @edge_width.each { |param| edge_thickness = param[2].to_s if thickness.to_i >= param[0].to_i && thickness.to_i <= param[1].to_i }
      return edge_thickness
    end#def
    def edge_type_count(su_type,mat,edge_count)
      @edge_count = []
      if su_type.include?("worktop")
        for i in [0,2,4,6]
          if edge_count[i]
            type = edge_count[i][0].to_s.split("х")[0].gsub(".",",")
            count = edge_count[i+1][0].round(2)
            thickness = edge_count[i][0].to_s.split("х")[1]
            edge_thickness = ""
            edge_thickness = "45мм" if thickness.to_i == 38 && type == "HPL"
            edge_thickness = "42х1,5мм" if thickness.to_i == 38 && type == "ABS"
            @edge_count = @edge_count.push(["edge",mat,type+" "+edge_thickness,count,SUF_STRINGS["m"]])
          end
        end
        else
        for i in [0,2,4,6]
          if edge_count[i]
            thickness = edge_count[i][0].to_s.split("х")[1]
            edge_thickness = ""
            edge_thickness = new_thickness(thickness)
            type = edge_count[i][0].to_s.split("х")[0].gsub(".",",")
            count = edge_count[i+1][0].round(2)
            if @edge_strips == "yes"
              @edge_count = @edge_count.push(["edge",mat,type+"х"+edge_thickness,count+count*@edge_waste,SUF_STRINGS["m"],@number_of_strips[i+1][0].to_s])
              else
              @edge_count = @edge_count.push(["edge",mat,type+"х"+edge_thickness,count+count*@edge_waste,SUF_STRINGS["m"]])
            end
          end
        end
      end
      @total_edge_count += @edge_count
    end#def
    def work_type_count(type,mat,work_count)
      @work_count = []
      for i in 0..30
        if i%3==0
          if work_count[i]
            type = work_count[i][0].to_s.split("х")[0].gsub(".",",")
            count = work_count[i+1][0].round(2)
            unit = work_count[i+2][0]
            @work_count = @work_count.push(["work",mat,type,count,unit])
          end
        end
      end
      @total_work_count += @work_count
    end#def
    def calc_worktop_edge(comp,edge_count,work_count,mat_name,edge_thickness)
      for i in [12,14,17,19]
        z1_name = comp[i].to_s
        i == 12 || i == 14 ? j = 6 : j = 8
        if z1_name == "2" || z1_name == "3"
          z1_name = "ABS" if z1_name == "2"
          z1_name = "HPL" if z1_name == "3"
          if edge_count.include?([z1_name+"х"+edge_thickness.to_s])
            ind = edge_count.index([z1_name+"х"+edge_thickness.to_s])
            new_count = comp[j].to_f/1000
            if comp[4].include?(SUF_STRINGS["Gluing"])
              if comp[4].include?("4>")
                new_count = (new_count)*comp[10]/4
                elsif comp[4].include?("3>")
                new_count = (new_count)*comp[10]/3
                else
                new_count = (new_count)*comp[10]/2
              end
              else
              new_count = (new_count)*comp[10]
            end
            edge_count[ind+1] = [edge_count[ind+1][0] + new_count]
            else
            edge_count = edge_count.push([z1_name+"х"+edge_thickness.to_s])
            count = comp[j].to_f/1000
            if comp[4].include?(SUF_STRINGS["Gluing"])
              if comp[4].include?("4>")
                count = (count)*comp[10]/4
                elsif comp[4].include?("3>")
                count = (count)*comp[10]/3
                else
                count = (count)*comp[10]/2
              end
              else
              count = (count)*comp[10]
            end
            edge_count = edge_count.push([count])
          end
          elsif z1_name == "7"
          z1_name = "Еврозапил"
          work_count = work_count.push([z1_name],[1],[SUF_STRINGS["pc"]])
        end
      end
      for i in [13,16,18]
        z1_name = comp[i].to_s
        if i == 13
          if z1_name == "2" || z1_name == "3" || z1_name == "4"
            z1_name == "4" ? count = 2 : count = 1
            z1_name = "Еврозапил"
            work_count = work_count.push([z1_name],[count],[SUF_STRINGS["pc"]])
          end
          else
          if z1_name == "2" || z1_name == "3"
            z1_name = "Радиус столешницы"
            work_count = work_count.push([z1_name],[1],[SUF_STRINGS["pc"]])
            elsif z1_name == "4"
            z1_name = "Спил столешницы"
            work_count = work_count.push([z1_name],[1],[SUF_STRINGS["pc"]])
          end
        end
      end
      return edge_count,work_count
    end#def
    def calc_stone_edge(comp,edge_count,work_count,mat_name,edge_thickness)
      for i in [12,14,17,19]
        z1_name = comp[i].to_s
        i == 12 || i == 14 ? j = 6 : j = 8
        if z1_name == "1"
          z1_name = "Фигурный торец" 
          if edge_count.include?([z1_name+"х"+edge_thickness.to_s])
            ind = edge_count.index([z1_name+"х"+edge_thickness.to_s])
            new_count = comp[j].to_f/1000
            edge_count[ind+1] = [edge_count[ind+1][0] + new_count]
            else
            edge_count = edge_count.push([z1_name+"х"+edge_thickness.to_s])
            count = comp[j].to_f/1000
            edge_count = edge_count.push([count])
          end
        end
      end
      for i in [13,16,18]
        z1_name = comp[i]
        if i == 13
          if z1_name.to_f != 0
            work_count = work_count.push(["Портальный выступ"],[z1_name.to_f/100],[SUF_STRINGS["m"]])
          end
          else
          if z1_name.to_s == "2" || z1_name.to_s == "3"
            z1_name = "Радиус столешницы"
            work_count = work_count.push([z1_name],[1],[SUF_STRINGS["pc"]])
            elsif z1_name.to_s == "4"
            z1_name = "Спил столешницы"
            work_count = work_count.push([z1_name],[1],[SUF_STRINGS["pc"]])
          end
        end
      end
      return edge_count,work_count
    end#def
    def calc_edge(comp,i,j,edge_count,mat_name,edge_thickness,edge_stock)
      comp[i+1].rindex("_") == comp[i+1].length-2 || comp[i+1].rindex("_") == comp[i+1].length-3 || comp[i+1].rindex("_") == comp[i+1].length-4 || comp[i+1].rindex("_") == comp[i+1].length-5 ? z1_name = comp[i+1][0..comp[i+1].rindex("_")-1] : z1_name = comp[i+1]
      z1_name = z1_name.strip
      z1_name != mat_name ? z1_name = "_"+z1_name.to_s+"_"+comp[i].to_s : z1_name = comp[i].to_s
      if edge_count.include?([z1_name+"х"+edge_thickness.to_s])
        ind = edge_count.index([z1_name+"х"+edge_thickness.to_s])
        new_count = comp[j].to_f/1000
        if comp[4].include?(SUF_STRINGS["Gluing"])
          if comp[4].include?("4>")
            new_count = (new_count+edge_stock)*comp[10]/4
            elsif comp[4].include?("3>")
            new_count = (new_count+edge_stock)*comp[10]/3
            else
            new_count = (new_count+edge_stock)*comp[10]/2
          end
          else
          new_count = (new_count+edge_stock)*comp[10]
        end
        edge_count[ind+1] = [edge_count[ind+1][0] + new_count]
        @number_of_strips[ind+1] = [@number_of_strips[ind+1][0] + @comp_count]
        else
        edge_count = edge_count.push([z1_name+"х"+edge_thickness.to_s])
        count = comp[j].to_f/1000
        if comp[4].include?(SUF_STRINGS["Gluing"])
          if comp[4].include?("4>")
            count = (count+edge_stock)*comp[10]/4
            elsif comp[4].include?("3>")
            count = (count+edge_stock)*comp[10]/3
            else
            count = (count+edge_stock)*comp[10]/2
          end
          else
          count = (count+edge_stock)*comp[10]
        end
        edge_count = edge_count.push([count])
        @number_of_strips.push([z1_name+"х"+edge_thickness.to_s])
        @number_of_strips.push([@comp_count])
      end
      return edge_count
    end#def
    def linear_list(entity,send_dialog=true)
      su_type_list = ["edge","worktop","fartuk","plinth","skirting"]
      lists_list(entity,su_type_list,send_dialog,true)
    end#def
    def sheets_list(entity,send_dialog=true)
      su_type_list = ["frontal","carcass","back","glass","metal"]
      lists_list(entity,su_type_list,send_dialog,true)
    end#def
    def lists_list(entity,su_type_list,send_dialog,list,layout=false)
      @layout = layout
      @panel_count = 0
      @holes = {}
      @param_mat = []
      @max_width_of_count = {}
      @total_edge_count = []
      @total_groove_count = 0
      entity_components = []
      @components_cut = {}
      @all_material_name_arr = []
      all_material_name_arr = []
      material_name_arr = []
      list_of_components_all = []
      @groove_components = {}
      @mat_ent_components = {}
      @auto_refresh = "вкл."
      @lists_panel_size = "Пильные без кромки"
      parameters_content,lists_content = read_param
      lists_to_dialog("new","","","","","","","","","","","","","","","","","","","","","","","","") if send_dialog
      @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      @ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      sel_parent = "model"
      sel_parent = "no model" if @sel[0] && !@sel[0].parent.is_a?(Sketchup::Model)
      entity ? sel = entity : sel = @sel
      name_to_dialog(sel[0],sel.length) if sel.length != 0 && send_dialog
      sel = @ent if sel.length == 0
      if sel != nil
        @frontal_carcass_mat = []
        @ent.each { |ent| material_list(ent,su_type_list,all_material_name_arr,false,false,false,false) if !ent.hidden? }
        #UI.refresh_inspectors
        all_material_name_arr = all_material_name_arr.uniq.sort{ |a, b| b <=> a }
        all_material_name_arr.each_with_index { |mat_a,index|
          if mat_a.split("=")[0] == "frontal"
            all_material_name_arr.each { |mat|
              if mat.split("=")[0] == "carcass" && mat_a.split("=")[1].to_s == mat.split("=")[1].to_s && mat_a.split("=")[2].to_s == mat.split("=")[2].to_s && mat_a.split("=")[3].to_s == mat.split("=")[3].to_s && mat_a.split("=")[4].to_s == mat.split("=")[4].to_s && mat_a.split("=")[5].to_s == mat.split("=")[5].to_s
                mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
                mat_a.split("=")[6] ? max_width_of_count = mat_a.split("=")[6] : max_width_of_count = "0"
                all_material_name_arr[index] = 'carcass='+mat_a.split("=")[1]+'='+mat_a.split("=")[2]+'='+mat_a.split("=")[3]+'='+mat_a.split("=")[4]+'='+type_material+'='+max_width_of_count
                @frontal_carcass_mat.push(mat)
              end
            }
          end
        }
        panel_number = 0
        all_mat = []
        all_material_name_arr.uniq.each { |mat_a|
          @ent_components = {}
          list_of_comp = []
          list_of_components = []
          @list_components_mat = []
          @groove_count = 0
          @add_work = []
          type = mat_a.split("=")[0]
          mat = mat_a.split("=")[1].to_s
          mat = mat.encode("utf-8").strip
          back_mat = mat_a.split("=")[2].to_s
          back_mat = back_mat.encode("utf-8")
          thickness = mat_a.split("=")[3]
          unit = mat_a.split("=")[4]
          mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
          @z1_type,@z2_type,@y1_type,@y2_type = nil
          if @frontal_carcass_mat.include?(mat_a)
            @ent.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,["carcass","frontal"],mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,[],send_dialog,false,true) if !ent.hidden? }
            else
            @ent.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,type,mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,[],send_dialog,false,false) if !ent.hidden? }
          end
          list_of_components = list_of_components.sort_by {|comp| [(comp[5]=="" ? "яяя" : comp[5]),comp[4],9999-comp[6].to_f]	}
          if @panel_positions == "1"
            panel_number = 0
            elsif @panel_positions == "2"
            panel_number = 0 if !all_mat.include?(mat)
            all_mat << mat
            elsif @panel_positions == "3"
            panel_number = 0 if !all_mat.include?(mat[0..-6])
            all_mat << mat[0..-6]
          end
          list_of_components.each_with_index { |comp,index|
            panel_number += 1
            @list_components_mat = @list_components_mat.push([panel_number] + comp)
          }
          list_of_components_all = list_of_components_all.push([mat_a] + [@list_components_mat])
        }
        @frontal_carcass_mat = []
        material_name_arr = []
        sel.each { |ent| material_list(ent,su_type_list,material_name_arr,false,false,false,false) if !ent.hidden? }
        material_name_arr = material_name_arr.uniq.sort{ |a, b| b <=> a }
        if list == true
          material_name_arr.each_with_index { |mat_a,index|
            if mat_a.split("=")[0] == "frontal"
              all_material_name_arr.each { |mat|
                if mat.split("=")[0] == "carcass" && mat_a.split("=")[1].to_s == mat.split("=")[1].to_s && mat_a.split("=")[2].to_s == mat.split("=")[2].to_s && mat_a.split("=")[3].to_s == mat.split("=")[3].to_s && mat_a.split("=")[4].to_s == mat.split("=")[4].to_s && mat_a.split("=")[5].to_s == mat.split("=")[5].to_s
                  mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
                  mat_a.split("=")[6] ? max_width_of_count = mat_a.split("=")[6] : max_width_of_count = "0"
                  material_name_arr[index] = 'carcass='+mat_a.split("=")[1]+'='+mat_a.split("=")[2]+'='+mat_a.split("=")[3]+'='+mat_a.split("=")[4]+'='+type_material+'='+max_width_of_count
                  @frontal_carcass_mat.push(mat)
                end
              }
            end
          }
        end
        @components_cut = {} if entity
        @all_material_name_arr = all_material_name_arr
        number_comp = Sketchup.active_model.get_attribute('su_lists','number_comp','false')
        @holes = {}
        material_name_arr.uniq.each { |mat_a|
          @ent_components = {}
          area = 0
          edge_count = []
          work_count = []
          @add_work = []
          type = mat_a.split("=")[0]
          mat = mat_a.split("=")[1].to_s
          mat = mat.encode("utf-8").strip
          back_mat = mat_a.split("=")[2].to_s
          back_mat = back_mat.encode("utf-8")
          thickness = mat_a.split("=")[3]
          unit = mat_a.split("=")[4]
          mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
          mat_a.split("=")[6] ? max_width_of_count = mat_a.split("=")[6] : max_width_of_count = "0"
          list_of_comp = []
          list_of_components = []
          @list_components_mat = []
          @groove_count = 0
          @z1_type,@z2_type,@y1_type,@y2_type = nil
          if @frontal_carcass_mat.include?(mat_a)
            sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,["carcass","frontal"],mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,list_of_components_all,number_comp,false,true) if !ent.hidden? }
            else
            sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,type,mat,back_mat,thickness,unit,type_material,nil,list_of_comp,list_of_components,list_of_components_all,number_comp,false,false) if !ent.hidden? }
          end
          @mat_ent_components[mat_a] = @ent_components
          @total_groove_count += @groove_count
          mat.rindex("_") == mat.length-2 || mat.rindex("_") == mat.length-3 || mat.rindex("_") == mat.length-4 || mat.rindex("_") == mat.length-5 ? mat_name = mat[0..mat.rindex("_")-1] : mat_name = mat
          mat_name = mat_name.strip
          @number_of_strips = []
          list_of_components.each { |comp|
            edge_thickness = thickness
            if unit == SUF_STRINGS["pc"]
              area += comp[10].to_f
              elsif unit == SUF_STRINGS["m"]
              area += comp[6].to_f*comp[10].to_f/1000
              if type.include?("worktop")
                edge_count,work_count = calc_worktop_edge(comp,edge_count,work_count,mat_name,edge_thickness)
              end
              else
              area += comp[6].to_f*comp[8].to_f*comp[10].to_f/1000000
              if comp[4].include?(SUF_STRINGS["Gluing"])
                if comp[4].include?("4>")
                  edge_thickness = comp[2].to_f.round(0)*4
                  elsif comp[4].include?("3>")
                  edge_thickness = comp[2].to_f.round(0)*3
                  else
                  edge_thickness = comp[2].to_f.round(0)*2
                end
              end
              @comp_count = comp[10].to_i
              if comp[12].to_s != "0"
                edge_count = calc_edge(comp,12,6,edge_count,mat_name,edge_thickness,@edge_stock)
              end
              if comp[14].to_s != "0"
                edge_count = calc_edge(comp,14,6,edge_count,mat_name,edge_thickness,@edge_stock)
              end
              if comp[16].to_s != "0"
                edge_count = calc_edge(comp,16,8,edge_count,mat_name,edge_thickness,@edge_stock)
              end
              if comp[18].to_s != "0"
                edge_count = calc_edge(comp,18,8,edge_count,mat_name,edge_thickness,@edge_stock)
              end
            end
          }
          area = area.round(2).to_s
          edge_count = 0 if edge_count == []
          list_list(mat,back_mat,thickness,unit,type_material,list_of_components_all)
          material_src = "cont/style/default.png"
          Sketchup.active_model.materials.each { |material|
            if material.display_name == mat
              if material.texture
                material.write_thumbnail(PATH + "/html/cont/thumbnail/#{mat}.jpg", 32)
                if File.file? PATH + "/html/cont/thumbnail/#{mat}.jpg"
                  material_src = PATH + "/html/cont/thumbnail/#{mat}.jpg"
                end
                else
                material.write_thumbnail(PATH + "/html/cont/thumbnail/#{mat}.jpg", 32)
                material_src = PATH + "/html/cont/thumbnail/#{mat}.jpg"
              end
            end
          }
          mat_area(type,mat_name,back_mat,thickness,area,unit,type_material)
          @edge_count = []
          edge_type_count(type,mat_name,edge_count) if edge_count != 0
          if type_material && type_material != ""
            path_material = type_material
            else
            path_material,file_name = search(mat_name)
          end
          sheet_size = ""
          sheet_count = ""
          if path_material
            parameters_content.each { |i|
              if i.strip.split("=")[1] == "edge_vendor"
                if i.strip.split("=")[0] == path_material.gsub("_LDSP","").gsub("_LMDF","") || path_material.include?(i.strip.split("=")[0])
                  sheet_size = i.strip.split("=")[2]
                end
              end
            }
          end
          if sheet_size != ""
            sheet_length = sheet_size.gsub("х","x").split("x")[0]
            sheet_width = sheet_size.gsub("х","x").split("x")[1]
            if sheet_width
              sheet_area = sheet_length.to_f*sheet_width.to_f/1000000
              sheet_count = ((area.to_f + area.to_f*@sheet_waste.to_f)/sheet_area).round(1)
              else
              sheet_area = sheet_length.to_f/1000
              sheet_count = ((area.to_f + area.to_f*@sheet_waste.to_f)/sheet_area).round(1)
            end
            elsif Sketchup.active_model.get_attribute('su_lists','grain')
            param_mat = Sketchup.active_model.get_attribute('su_lists','grain')
            param_mat.each { |mat|
              if mat[0].include?(mat_name) && mat[1].include?(thickness)
                sheet_size = mat[2]
                if sheet_size != ""
                  sheet_area = sheet_size.gsub("х","x").split("x")[0].to_f*sheet_size.gsub("х","x").split("x")[1].to_f/1000000
                  sheet_count = ((area.to_f + area.to_f*@sheet_waste.to_f)/sheet_area).round(1)
                  break
                end
              end
            }
          end
          param_mat(type,mat,thickness,sheet_size)
          mat_name = mat_name.strip+" "+SUF_STRINGS["double-sided"] if type.include?("frontal") && back_mat != "White" && path_material && !path_material.include?("_LDSP") && !path_material.include?("_LMDF")
          mat_grained = "true"
          @param_mat.each { |mat| mat_grained = mat[3] if mat[3] && mat[0].include?(mat_name) && mat[1].include?(thickness) }
          lists_to_dialog("new_table",type,mat_name,mat,back_mat,thickness,unit,material_src,area,@edge_count,"",sheet_size,"",sheet_count,"","","","","","","","","","",type_material,max_width_of_count,mat_grained) if send_dialog
          @mat_panel_count = 0
          @list_components_mat.each { |comp|
            list_of_components.each { |comp_ent|
              sel_parent == "no model" ? index = 19 : index = 20
              if comp_ent[0..9] == comp[1..10] && comp_ent[11..index] == comp[12..index+1] && comp_ent[22..24] == comp[23..25]
                if comp_ent[21] == comp[22] || comp_ent[21] == "frontal" && comp[22] == "carcass"
                  number = comp[0]
                  thickness = comp[3]
                  unit = comp[4]
                  name = comp[5]
                  item_code = comp[6]
                  if @itemcode == "1"
                    name += " - "+item_code if item_code && item_code != ""
                    elsif @itemcode == "2"
                    name = item_code+" - "+name if item_code && item_code != ""
                    else
                    name = item_code+"."+name if item_code && item_code != ""
                  end
                  width_panel = comp[7]
                  width = comp[8]
                  height_panel = comp[9]
                  height = comp[10]
                  count = comp_ent[10]
                  rotate = comp[12]
                  z1 = comp[13]
                  z1_texture = comp[14]
                  z2 = comp[15]
                  z2_texture = comp[16]
                  y1 = comp[17]
                  y1_texture = comp[18]
                  y2 = comp[19]
                  y2_texture = comp[20]
                  e_n = comp[21]
                  su_type = comp[22]
                  type_material = comp[23]
                  if !entity_components.include?([number,mat_name,thickness,unit,name,item_code,width_panel,width,height_panel,height,count.to_f.round,z1,z2,y1,y2,e_n,su_type,type_material])
                    lists_to_dialog(number,type,mat_name,mat,back_mat,thickness,unit,@sel.length,name,item_code,width_panel,width,height_panel,height,count.round(2),rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,type_material,max_width_of_count) if send_dialog
                    entity_components = entity_components.push([number,mat_name,thickness,unit,name,item_code,width_panel,width,height_panel,height,count.to_f.round,z1,z2,y1,y2,e_n,su_type,type_material])
                    @panel_count += count.to_f
                    @mat_panel_count += count.to_f
                  end
                end
              end
            }
          }
          lists_to_dialog("panel_count",type,mat_name,mat,back_mat,thickness,unit,material_src,area,@edge_count,"",sheet_size,"",@mat_panel_count.round,mat_grained,"","","","","","","","","",type_material,max_width_of_count) if send_dialog
        }
        lists_to_dialog("total_panel_count",@panel_count.round,"","","","","","","","","","","","","","","","","","","","","","","") if send_dialog
        Sketchup.active_model.set_attribute('su_lists','number_comp','true') if number_comp == 'false' && !send_dialog
      end
      p "Количество деталей: #{@panel_count.round}"
      return [@frontal_carcass_mat,entity_components,@components_cut,@mat_ent_components]
    end#def
    def length_width(name_array,comp_length,str,default)
      parts = name_array.split(";")
      length_part = parts.select {|part|part.include?(str)}
      if length_part != []
        if length_part[0].include?("<->")
          length_arr = length_part[0].split("<->")[1..-1]
          length_arr = length_arr.sort_by {|length|length.to_f}
          length_arr.uniq.each { |length| return length if comp_length.to_f <= length.to_f }
          else
          return length_part[0]
        end
      end
      return default
    end
    def material_list(entity,su_type_list,material_name_arr,frontal_type=true,worktop_type=true,fartuk_type=true,metal_type=true)
      entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
      if !entity.hidden?
        su_type = entity.definition.get_attribute("dynamic_attributes", "su_type")
        su_info = entity.definition.get_attribute("dynamic_attributes", "su_info")
        a03_path = entity.definition.get_attribute("dynamic_attributes", "a03_path","0")
        summary = entity.definition.get_attribute("dynamic_attributes", "summary", "0")
        type_material = entity.definition.get_attribute("dynamic_attributes", "type_material", "")
        back_material = entity.definition.get_attribute("dynamic_attributes", "back_material", "White")
        max_width_of_count = entity.definition.get_attribute("dynamic_attributes", "max_width_of_count", "0")
        if !su_info || !su_type
          if summary.include?("EasyKitchen")
            su_info,su_type = Lists_EasyKitchen.EasyKitchen(entity)
            back_material = "White"
            if !su_info
              entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
                su_info,su_type = Lists_EasyKitchen.EasyKitchen(e) if !su_info
              }
            end
            else
            su_info,su_type = Lists_SDCF.sdcf_info(entity)
          end
        end
        if su_info || su_type
          entity.make_unique if entity.definition.count_used_instances > 1
          entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
        end
        if su_info && su_info != "" && su_info != " " && su_info[0] != "module" && su_info[0] != "body" && su_type && su_type != "" && su_type != " " && !su_type.include?(SUF_STRINGS["Product"]) && !su_type.include?("Изделие") && !su_type.include?("Тело")
          if su_type != "fartuk" && su_type != "worktop" && su_info.downcase =~ /рамка|integro|макмарт/i || su_type != "fartuk" && su_type != "worktop" && a03_path.downcase =~ /рамка|integro|макмарт/i
            
            else
            if su_type_list.include?(su_type)
              su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
              thickness_comp = su_info[5].to_f.round(1).to_s
              a01_gluing = entity.definition.get_attribute("dynamic_attributes", "a01_gluing")
              if a01_gluing
                thickness = (thickness_comp.to_f/a01_gluing.to_f).round(1).to_s
                else
                if thickness_comp == "32"
                  thickness = "16.0"
                  elsif thickness_comp == "36"
                  thickness = "18.0"
                  else
                  thickness = thickness_comp
                end
              end
              #name = su_info[6]
              unit = su_info[10]
              if entity.material == nil
                mat_name = su_info[7].gsub('"','').strip
                else
                mat_name = entity.material.display_name.strip
              end
              if max_width_of_count && max_width_of_count != "0"
                if !@max_width_of_count[mat_name] || @max_width_of_count[mat_name] == 0
                  @max_width_of_count[mat_name] = max_width_of_count.to_f
                  else
                  @max_width_of_count[mat_name] = max_width_of_count.to_f if max_width_of_count.to_f < @max_width_of_count[mat_name]
                end
              end
              if su_type.include?("metal") && metal_type == true
                su_type += "/" + su_info[1]
              end
              if su_type.include?("frontal") && frontal_type == true
                if su_info[1].include?("Радиус")
                  su_info[1].index("_") ? frontal_name = su_info[1].gsub(/Нар/,"_R").gsub(/Вн/,"_R") : frontal_name = su_info[1].gsub(/Нар/,"_R").gsub(/Вн/,"_R") + "_Модерн"
                  else
                  su_info[1].index("Фасад_") ? frontal_name = su_info[1] : frontal_name = SUF_STRINGS["frontal"]+"_"+SUF_STRINGS["Modern"]   #"Фасад_Модерн"
                end
                ad_material = entity.definition.get_attribute("dynamic_attributes", "ad_material", "0")
                su_type += "/" + frontal_name
                su_type += "/" + back_material
                su_type += "/" + ad_material
                su_type += "/" + type_material
              end
              
              type_mat = type_material.gsub("_WorkTop","").gsub("_Worktop","").gsub("_worktop","")
              if su_type.include?("worktop") && worktop_type
                if su_info[6].include?("Камень")
                  su_type += "/" + su_info[1]
                  su_type += "/" + su_info[6][0..21]
                  else
                  su_type += "/" + su_info[1]
                  if su_info[1].include?("Угловой элемент")
                    su_type += "/" + su_info[3]
                    su_type += "/" + su_info[4]
                    su_type += "/" + back_material
                    su_type += "/" + su_info[11]
                    else
                    default_array = ["3050","600"]
                    if @worktop_name[type_mat]
                      su_type += "/"+length_width(@worktop_name[type_mat],su_info[3],"length",default_array[0])
                      su_type += "/"+length_width(@worktop_name[type_mat],su_info[4],"width",default_array[1])
                      elsif @worktop_name["Default"]
                      su_type += "/"+length_width(@worktop_name["Default"],su_info[3],"length",default_array[0])
                      su_type += "/"+length_width(@worktop_name["Default"],su_info[4],"width",default_array[1])
                      else
                      su_type += "/"+default_array[0]+"/"+(su_info[4].to_f > 600 ? "1200" : "600")
                    end
                    su_type += "/" + back_material
                    su_type += "/" + su_info[11]
                  end
                end
              end
              if su_type.include?("fartuk") && fartuk_type
                if su_info[6].include?("Камень")
                  su_type += "/" + su_info[6]
                  su_type += "/600"
                  su_type += "/" + back_material
                  su_type += "/" + su_info[11]
                  else
                  su_type += "/" + su_info[1]
                  default_array = ["3000","600"]
                  if @fartuk_name[type_mat]
                    su_type += "/"+length_width(@fartuk_name[type_mat],su_info[3],"length",default_array[0])
                    su_type += "/"+length_width(@fartuk_name[type_mat],su_info[4],"width",default_array[1])
                    elsif @fartuk_name["Default"]
                    su_type += "/"+length_width(@fartuk_name["Default"],su_info[3],"length",default_array[0])
                    su_type += "/"+length_width(@fartuk_name["Default"],su_info[4],"width",default_array[1])
                    else
                    su_type += "/"+default_array[0]+"/"+(su_info[4].to_f > 600 ? "1200" : "600")
                  end
                  su_type += "/" + back_material
                  su_type += "/" + su_info[11]
                end
              end
              if !material_name_arr.include?(su_type+"="+mat_name+"="+back_material+"="+thickness+"="+unit+"="+type_material+"="+(@max_width_of_count[mat_name] ? @max_width_of_count[mat_name].to_s : "0"))
                material_name_arr.push(su_type+"="+mat_name+"="+back_material+"="+thickness+"="+unit+"="+type_material+"="+(@max_width_of_count[mat_name] ? @max_width_of_count[mat_name].to_s : "0"))
              end
              @material_name_arr = material_name_arr
            end
          end
        end
        if entity.definition.count_used_instances > 1
          entity.make_unique
          entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
        end
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| material_list(e,su_type_list,material_name_arr,frontal_type,worktop_type,fartuk_type,metal_type) }
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hide_in_browser(e) }
      end
    end#def
    def hide_in_browser(ent)
      ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hide_in_browser(e) }
    end
    def component_list(tr,module_origin,body_flipped,e_n,entity,su_type_list,mat,back_mat,thickness_mat,unit_mat,type_material_mat,file_name,list_of_comp,list_of_components,list_of_components_all=[],send_dialog=true,j_profile=false,list=false)
      easy_kitchen_panel = false
      type = entity.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = entity.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = entity.definition.get_attribute("dynamic_attributes", "su_info")
      z1_type = entity.definition.get_attribute("dynamic_attributes", "edge_z1")
      z2_type = entity.definition.get_attribute("dynamic_attributes", "edge_z2")
      y1_type = entity.definition.get_attribute("dynamic_attributes", "edge_y1")
      y2_type = entity.definition.get_attribute("dynamic_attributes", "edge_y2")
      @z1_type = z1_type if z1_type
      @z2_type = z1_type if z2_type
      @y1_type = z1_type if y1_type
      @y2_type = z1_type if y2_type
      edge_z1_length = entity.definition.get_attribute("dynamic_attributes", "edge_z1_length", "0")
      edge_z2_length = entity.definition.get_attribute("dynamic_attributes", "edge_z2_length", "0")
      edge_y1_length = entity.definition.get_attribute("dynamic_attributes", "edge_y1_length", "0")
      edge_y2_length = entity.definition.get_attribute("dynamic_attributes", "edge_y2_length", "0")
      v0_cut = entity.definition.get_attribute("dynamic_attributes", "v0_cut")
      v1_cut_type = entity.definition.get_attribute("dynamic_attributes", "v1_cut_type")
      v2_cut_type = entity.definition.get_attribute("dynamic_attributes", "v2_cut_type")
      v3_cut_type = entity.definition.get_attribute("dynamic_attributes", "v3_cut_type")
      v4_cut_type = entity.definition.get_attribute("dynamic_attributes", "v4_cut_type")
      _fastener = entity.definition.get_attribute("dynamic_attributes", "_fastener", false)
      type_material = entity.definition.get_attribute("dynamic_attributes", "type_material", "")
      back_material = entity.definition.get_attribute("dynamic_attributes", "back_material", "White")
      back_stripe_width = entity.definition.get_attribute("dynamic_attributes", "back_stripe_width", "0").to_f
      edge_trim = entity.definition.get_attribute("dynamic_attributes", "edge_trim", "0").to_f
      summary = entity.definition.get_attribute("dynamic_attributes", "summary", "0")
      edge_z1_texture = entity.definition.get_attribute("dynamic_attributes", "edge_z1_texture")
      a00_mat_krom = entity.definition.get_attribute("dynamic_attributes", "a00_mat_krom", "0").to_s
      a00_mat_krom = a00_mat_krom[0..a00_mat_krom.rindex("_")-1] if a00_mat_krom.rindex("_") == a00_mat_krom.length-2 || a00_mat_krom.rindex("_") == a00_mat_krom.length-3 || a00_mat_krom.rindex("_") == a00_mat_krom.length-4 || a00_mat_krom.rindex("_") == a00_mat_krom.length-5
      if !su_info || !su_type
        if summary.include?("EasyKitchen")
          su_info,su_type = Lists_EasyKitchen.EasyKitchen(entity)
          back_material = "White"
          if !su_info
            entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
              su_info,su_type = Lists_EasyKitchen.EasyKitchen(e) if !su_info
            }
          end
          easy_kitchen_panel = true if su_info
          else
          su_info,su_type = Lists_SDCF.sdcf_info(entity)
        end
      end
      if su_info && su_info != "" && su_info != " " && su_info[0] != "module" && su_info[0] != "body" && su_type && su_type != "" && su_type != " " && !su_type.include?(SUF_STRINGS["Product"]) && !su_type.include?("Изделие") && !su_type.include?("Тело")
        if su_type_list.include?(su_type)
          su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
          if entity.material == nil
            mat_name = su_info[7].gsub('"','').strip
            else
            mat_name = entity.material.display_name.strip
          end
          
          if easy_kitchen_panel
            z1_texture = mat_name
            z2_texture = mat_name
            y1_texture = mat_name
            y2_texture = mat_name
            else
            if mat_name.rindex("_") == mat_name.length-2 || mat_name.rindex("_") == mat_name.length-3 || mat_name.rindex("_") == mat_name.length-4 || mat_name.rindex("_") == mat_name.length-5
              mat_krom = mat_name[0..mat_name.rindex("_")-1] 
              else
              mat_krom = mat_name
            end
            z1_texture = mat_krom
            z2_texture = mat_krom
            y1_texture = mat_krom
            y2_texture = mat_krom
          end
          thickness_comp = su_info[5].to_f.round(1).to_s
          a01_gluing = entity.definition.get_attribute("dynamic_attributes", "a01_gluing")
          if a01_gluing
            a01_gluing = a01_gluing.to_f
            thickness = (thickness_comp.to_f/a01_gluing).round(1).to_s
            else
            if thickness_comp == "32"
              thickness = "16.0"
              a01_gluing = 2
              elsif thickness_comp == "36"
              thickness = "18.0"
              a01_gluing = 2
              else
              thickness = thickness_comp
            end
          end
          unit = su_info[10]
          if mat == mat_name && back_mat == back_material && thickness_mat == thickness && unit_mat == unit && type_material_mat == type_material
            item_code = entity.get_attribute("dynamic_attributes", "itemcode")
            item_code = entity.definition.get_attribute("dynamic_attributes", "itemcode") if !item_code
            item_code = su_info[0] if !item_code
            item_code = "" if !item_code
            napr_texture = su_info[8]
            
            if su_info[2] == "worktop" || su_info[2] == "fartuk"
              width = (su_info[3].to_f).round
              width_panel = width
              height = (su_info[4].to_f).round
              height_panel = height  
              z1 = su_info[11]
              z2 = su_info[13]
              y1 = su_info[15]
              y2 = su_info[17]
              z1_texture = su_info[12]
              z2_texture = su_info[14]
              y1_texture = su_info[16]
              y2_texture = su_info[18]
              else
              width,width_panel,height,height_panel,z1,z2,y1,y2,z1_type,z2_type,y1_type,y2_type,z1_texture,z2_texture,y1_texture,y2_texture = get_param(entity,napr_texture.to_s,su_info,edge_trim,edge_z1_texture,(z1_type ? z1_type : @z1_type),(z2_type ? z2_type : @z2_type),(y1_type ? y1_type : @y1_type),(y2_type ? y2_type : @y2_type),edge_z1_length,edge_z2_length,edge_y1_length,edge_y2_length,z1_texture,z2_texture,y1_texture,y2_texture,a00_mat_krom)
            end
            if su_type.include?("frontal") || su_type.include?("carcass")
              z1_texture = a00_mat_krom if !edge_z1_texture && a00_mat_krom != "0"
            end
            if su_type.include?("glass")
              z1 = "0"
              z2 = "0"
              y1 = "0"
              y2 = "0"
              z1_type = "1"
              z2_type = "1"
              y1_type = "1"
              y2_type = "1"
            end
            name_of_groove = ""
            groove_name = ""
            groove_designation = ""
            groove_padding = @edge_groove_padding.to_f
            groove_base = 0
            groove = su_info[19]
            groove_array = []
            if groove && groove.to_f > 0
              groove = groove.to_f*10
              groove_thick = su_info[20]
              groove_width = su_info[21]
              if groove < 1
                if (groove_thick.to_f*10).round(0) > 4
                  groove_name += "Четверть шире 4мм"
                  else
                  groove_name += "Четверть до 4мм"
                end
                groove_designation += "<"+ SUF_STRINGS["Q"] + (groove_thick.to_f*10).round(0).to_s
                else
                if (groove_thick.to_f*10).round(0) > 4
                  groove_name += "Паз шире 4мм"
                  else
                  groove_name += "Паз сквозной 4мм"
                end
                groove_designation += "<"+ SUF_STRINGS["G"] + groove.round(0).to_s + "+" + (groove_thick.to_f*10).round(0).to_s
              end
              groove_designation += "*" + (groove_width.to_f*10).round(0).to_s if groove_width
              edge_z1_texture ? groove_xy_pos = su_info[22] : groove_xy_pos = "1"
              edge_z1_texture ? groove_z_pos = su_info[23] : groove_z_pos = entity.definition.get_attribute("dynamic_attributes", "point_x", "1")
              groove_cut = nil
              if @groove_count && groove_xy_pos
                groove_z_pos=="1" ? groove_cut = "groove_R" : groove_cut = "groove_L"
                if groove_xy_pos.to_i == 3 || groove_xy_pos.to_i == 4 #по ширине
                  groove_length = su_info[4].to_i
                  if groove_padding != 0
                    if z1_type.to_i > 1
                      groove_base = groove_padding
                      groove_length -= groove_padding
                      if z1_type == "7"
                        groove_base += 2
                        elsif z1_type == "5"
                        groove_base += 1
                        elsif z1_type == "3"
                        groove_base += 0.5
                      end
                    end
                    if z2_type.to_i > 1
                      groove_length -= groove_padding
                    end
                    if z1_type.to_i > 1 || z2_type.to_i > 1
                      groove_name.gsub!("сквозной","глухой")
                      groove_name.gsub!("до","глухая до")
                    end
                  end
                  if @name_prefix.to_i > 1
                    groove_designation += " - " + su_info[4].to_f.round.to_s
                    if @name_prefix.to_i > 2
                      if groove_xy_pos.to_i == 3
                        groove_designation += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "▲" : "►") : (napr_texture.to_s == "2" ? "▼" : "◄")) + ")"
                        else
                        groove_designation += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "▼" : "◄") : (napr_texture.to_s == "2" ? "▲" : "►")) + ")"
                      end
                    end
                  end
                  
                  else #по длине
                  groove_length = su_info[3].to_i
                  if groove_padding != 0
                    if y2_type.to_i > 1
                      groove_base = groove_padding
                      groove_length -= groove_padding
                      if y2_type == "7"
                        groove_base += 2
                        elsif y2_type == "5"
                        groove_base += 1
                        elsif y2_type == "3"
                        groove_base += 0.5
                      end
                    end
                    if y1_type.to_i > 1
                      groove_length -= groove_padding
                    end
                    if y1_type.to_i > 1 || y2_type.to_i > 1
                      groove_name.gsub!("сквозной","глухой")
                      groove_name.gsub!("до","глухая до")
                    end
                  end
                  if @name_prefix.to_i > 1
                    groove_designation += " - " + su_info[3].to_f.round.to_s
                    if @name_prefix.to_i > 2
                      if groove_xy_pos.to_i == 1
                        groove_designation += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "►" : "▼") : (napr_texture.to_s == "2" ? "◄" : "▲")) + ")"
                        else
                        groove_designation += "(" + (groove_z_pos=="1" ? (napr_texture.to_s == "2" ? "◄" : "▲") : (napr_texture.to_s == "2" ? "►" : "▼")) + ")"
                      end
                    end
                  end
                end
                @groove_count += groove_length
              end
              groove_designation += ">"
              entity.definition.entities.grep(Sketchup::ComponentInstance).each { |essence| set_groove_name(entity,essence,groove_designation) }
              groove_array << [groove,[groove_thick.to_f*10,groove_width.to_f*10],[[groove,0,0],[groove+groove_thick.to_f*10,0,0],[groove+groove_thick.to_f*10,groove_width.to_f*10,0],[groove,groove_width.to_f*10,0]],groove_xy_pos,groove_z_pos,groove_length,groove_name,groove_base]
            end
            if @place_prefix.to_i > 0
              a03_name = su_info[1]+groove_designation.gsub(" ","")
              else
              a03_name = groove_designation.gsub(" ","")+su_info[1]
            end
            a03_name = "Panel" if !a03_name || a03_name == "" || a03_name == " "
            a08_rotate = entity.definition.get_attribute("dynamic_attributes", "a08_rotate", "0")
            a08_rotate = "0" if a08_rotate != "1"
            if su_type.include?("frontal")
              if mat_name.include?("RAL") || mat_name.include?("NCS")
                if back_material != "White"
                  if back_material == "White_and_stripe"
                    back_stripe_width = (back_stripe_width*25.4).round.to_s
                    a03_name += " ("+SUF_STRINGS["the reverse side"]+" "+SUF_STRINGS["stripe"]+" "+back_stripe_width+" "+SUF_STRINGS["mm"]+" "+mat_name[2..mat_name.rindex("_")-1] + ")"
                    else
                    a03_name += " ("+SUF_STRINGS["the reverse side"]+" " + back_material[2..back_material.rindex("_")-1] + ")"
                  end
                end
              end
              ad_material = entity.definition.get_attribute("dynamic_attributes", "ad_material", "0")
              a03_name += " ("+SUF_STRINGS["patina"]+" " + ad_material + ")" if ad_material != "0"
              if list == true
                su_type = "carcass" 
                back_material = mat_name
              end
            end
            if a01_gluing
              if a01_gluing.to_f != 1
                a03_name = SUF_STRINGS["Gluing"]+a01_gluing.to_f.round.to_s+">" + width.round.to_s + "х" + height.round.to_s + " " + a03_name
                width += @trim_stock.to_f
                height += @trim_stock.to_f
                count = a01_gluing.to_f.round
                else
                unit == SUF_STRINGS["pc"] ? count = su_info[9].to_f : count = 1
              end
              else
              if thickness_comp == "32" || thickness_comp == "36"
                a03_name = SUF_STRINGS["Gluing"]+"2>" + width.round.to_s + "х" + height.round.to_s + " " + a03_name
                width += @trim_stock.to_f
                #width_panel += @trim_stock.to_f
                height += @trim_stock.to_f
                #height_panel += @trim_stock.to_f
                count = 2
                else
                unit == SUF_STRINGS["pc"] ? count = su_info[9].to_f : count = 1
              end
            end
            if j_profile != false
              if @JprofileUp_count && a03_name.include?("JprofileUp")
                @JprofileUp_count += 1 if mat_name.include?("RAL") || mat_name.include?("NCS")
                @JprofileUp_length += height/1000 if mat_name.include?("RAL") || mat_name.include?("NCS")
                elsif @Jprofile_count && a03_name.include?("Jprofile")
                @Jprofile_count += 1 if mat_name.include?("RAL") || mat_name.include?("NCS")
                @Jprofile_length += height/1000 if mat_name.include?("RAL") || mat_name.include?("NCS")
              end
            end
            if su_type.include?("worktop") && !a03_name.include?("Угловой элемент") && su_info[6].include?("Антарес")
              if back_material[0..4] != "White"
                a03_name += " (2х стор)"
                elsif z1 == "2"
                a03_name += " (без завала)"
              end
            end
            if su_info[6].include?("Камень")
              for i in 1..20
                w_count = entity.definition.get_attribute("dynamic_attributes", "w"+i.to_s+"_count", "0")
                w_count_name = entity.definition.get_attribute("dynamic_attributes", "_w"+i.to_s+"_count_formlabel", "0")
                if w_count.to_f != 0 
                  @add_work << [w_count_name]
                  @add_work << [w_count.to_f]
                  @add_work << [SUF_STRINGS["pc"]]
                end
              end
            end
            @fastener_array = {}
            @fastener_array["facedrilling"] = []
            @fastener_array["backdrilling"] = []
            @fastener_array["edgedrilling"] = []
            search_fastener(entity)
            if @fastener_array["facedrilling"] != [] || @fastener_array["backdrilling"] != [] || @fastener_array["edgedrilling"] != []
              @components_cut[entity] = [] if !@components_cut[entity]
              @components_cut[entity] << ["fastener",width,height,body_flipped]
            end
            if groove_cut
              @components_cut[entity] = [] if !@components_cut[entity]
              @components_cut[entity] << [groove_cut,width,height,body_flipped]
            end
            groove_array = search_groove(entity,entity,groove_array,width,height,body_flipped)
            count_new = count
            @sorted_fastener_array = {}
            @fastener_array.each_pair {|drilling,array|
              if array != []
                sorted_array = []
                array.each {|arr|
                  sorted_a = []
                  arr[4..-1].each {|a| sorted_a << a.sort_by{|point|[point[1],point[0]]} }
                  sorted_array << [arr[0],arr[1],arr[2],arr[3]]+sorted_a
                }
                @sorted_fastener_array[drilling] = sorted_array
                else
                @sorted_fastener_array[drilling] = array
              end
            }
            if @panel_group == "yes" && list_of_comp.include?([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
              ind = list_of_comp.index([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
              comp = list_of_components[ind]
              count_old = comp[10]
              count_new = count_old + count
              list_of_components.delete([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),count_old,a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
              list_of_comp.delete([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
            end
            list_of_comp.push([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
            list_of_components.push([mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0),count_new,a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,e_n,su_type,type_material,groove_array,@sorted_fastener_array])
            if a03_name.include?("Вырез") && !a03_name.include?("ЗС") && thickness.to_f > 5
              @components_cut[entity] = [] if !@components_cut[entity]
              @components_cut[entity] << ["cut",width,height,body_flipped]
              elsif v0_cut && v0_cut.to_s == "1"
              if v1_cut_type && v1_cut_type.to_s != "1" || v2_cut_type && v2_cut_type.to_s != "1" || v3_cut_type && v3_cut_type.to_s != "1" || v4_cut_type && v4_cut_type.to_s != "1"
                @components_cut[entity] = [] if !@components_cut[entity]
                @components_cut[entity] << ["cut",width,height,body_flipped]
              end
            end
            @ent_components[entity] = [[mat_name,back_material,thickness,unit,su_info[1],item_code,width_panel,width.round(1),height_panel,height.round(1),count,a08_rotate,z1_type,z1_texture,z2_type,z2_texture,y1_type,y1_texture,y2_type,y2_texture,e_n,su_type,type_material,file_name],groove_array,@fastener_array,tr,module_origin,body_flipped]
            if list_of_components_all != []
              list_of_components_all.each { |comp_mat|
                if comp_mat[0].split("=")[0] == su_type && comp_mat[0].split("=")[1] == mat_name && comp_mat[0].split("=")[2] == back_material && comp_mat[0].split("=")[3] == thickness
                  comp_mat[1].each { |comp|
                    if comp[1..10] == [mat_name,back_material,thickness,unit,a03_name,item_code,width_panel.round(0),width.round(0),height_panel.round(0),height.round(0)] && comp[12..20] == [a08_rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture] && comp[22..comp.length-1] == [su_type,type_material,groove_array,@sorted_fastener_array]
                      if comp[21] == e_n
                        number = comp[0]
                        entity.set_attribute("dynamic_attributes", "number", number)
                        entity.definition.set_attribute("dynamic_attributes", "number", number)
                        entity.definition.set_attribute("dynamic_attributes", "_number_label", "number")
                        entity.definition.set_attribute("dynamic_attributes", "_number_access", "VIEW")
                      end
                    end
                  }
                end
              }
            end
            e_n = "false" if entity.parent.is_a?(Sketchup::Model)
          end
        end
      end
      
      entity_transformation = entity.transformation
      module_origin = (entity_transformation.origin.y*25.4+0.01).round.to_s+","+(entity_transformation.origin.z*25.4+0.01).round.to_s+","+(entity_transformation.origin.x*25.4+0.01).round.to_s if !module_origin
      if type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.to_s.downcase.include?("body") || su_type.to_s.downcase.include?("section") || type.include?("frontal")
        lenx = entity.definition.get_attribute("dynamic_attributes", "lenx", 0).to_f
        if !(entity_transformation.xaxis * entity_transformation.yaxis).samedirection?(entity_transformation.zaxis)
          if !body_flipped
            body_flipped = tr.xaxis.normalize.y.to_s+","+tr.xaxis.normalize.z.to_s+","+tr.xaxis.normalize.x.to_s 
            else
            body_flipped = false
          end
          if lenx < 0
            entity_transformation = Geom::Transformation.new(entity_transformation.xaxis.reverse,entity_transformation.yaxis,entity_transformation.zaxis,[entity_transformation.origin.x+lenx*2,entity_transformation.origin.y,entity_transformation.origin.z])
            else
            entity_transformation = Geom::Transformation.new(entity_transformation.xaxis.reverse,entity_transformation.yaxis,entity_transformation.zaxis,entity_transformation.origin)
          end
        end
      end
      entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| component_list(tr * entity_transformation,module_origin,body_flipped,e_n,e,su_type_list,mat,back_mat,thickness_mat,unit_mat,type_material_mat,file_name,list_of_comp,list_of_components,list_of_components_all,send_dialog,j_profile,list) if !e.hidden? }
    end#def
    def get_param(entity,napr_texture,su_info,edge_trim,edge_z1_texture,z1_type,z2_type,y1_type,y2_type,edge_z1_length,edge_z2_length,edge_y1_length,edge_y2_length,z1_texture,z2_texture,y1_texture,y2_texture,a00_mat_krom)
      width = (su_info[(napr_texture=="2" ? 4 : 3)].to_f).round(1) - edge_trim
      width_panel = width
      height = (su_info[(napr_texture=="2" ? 3 : 4)].to_f).round(1) - edge_trim
      height_panel = height
      z1 = su_info[11]
      z2 = su_info[13]
      y1 = su_info[15]
      y2 = su_info[17]
      hf = false
      if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        hf = true
        elsif !edge_z1_texture
        z1_type = "0" if edge_z1_length.to_f == 0
        z2_type = "0" if edge_z2_length.to_f == 0
        y1_type = "0" if edge_y1_length.to_f == 0
        y2_type = "0" if edge_y2_length.to_f == 0
        z1 = entity.definition.get_attribute("dynamic_attributes", "edge_z1", "0") if z1=="0" && edge_z1_length.to_f != 0
        z2 = entity.definition.get_attribute("dynamic_attributes", "edge_z2", "0") if z2=="0" && edge_z2_length.to_f != 0
        y1 = entity.definition.get_attribute("dynamic_attributes", "edge_y1", "0") if y1=="0" && edge_y1_length.to_f != 0
        y2 = entity.definition.get_attribute("dynamic_attributes", "edge_y2", "0") if y2=="0" && edge_y2_length.to_f != 0
      end
      
      z1_type = edge_type(z1_type,z1)
      z2_type = edge_type(z2_type,z2)
      y1_type = edge_type(y1_type,y1)
      y2_type = edge_type(y2_type,y2)
      for edge_array in @edge_array
        edge_value = edge_array.split("=")[0]
        edge_thickness = edge_value.split(")")[1][0..4].gsub(SUF_STRINGS["mm"],"").gsub("мм","").strip
        if z1_type != "1" && z1_type == edge_value[1]
          if napr_texture=="2"
            width -= edge_array.split("=")[2].to_f if !z1_type.to_i.odd? || z1.include?("подрезкой")
            else
            height -= edge_array.split("=")[2].to_f if !z1_type.to_i.odd? || z1.include?("подрезкой")
          end
          z1 = edge_thickness
          if edge_z1_texture || hf
            if z1_type == "3" && z2_type == "3"
              (napr_texture=="2" ? width_panel += 1 : height_panel += 1)
              elsif z1_type == "5"
              (napr_texture=="2" ? width_panel += 1 : height_panel += 1)
              elsif z1_type == "7"
              (napr_texture=="2" ? width_panel += 2 : height_panel += 2)
            end
          end
        end
        if z2_type != "1" && z2_type == edge_value[1]
          if napr_texture=="2"
            width -= edge_array.split("=")[2].to_f if !z2_type.to_i.odd? || z2.include?("подрезкой")
            else
            height -= edge_array.split("=")[2].to_f if !z2_type.to_i.odd? || z2.include?("подрезкой")
          end
          z2 = edge_thickness
          if edge_z1_texture || hf
            if z2_type == "5"
              (napr_texture=="2" ? width_panel += 1 : height_panel += 1)
              elsif z2_type == "7"
              (napr_texture=="2" ? width_panel += 2 : height_panel += 2)
            end
          end
        end
        if y1_type != "1" && y1_type == edge_value[1]
          if napr_texture=="2"
            height -= edge_array.split("=")[2].to_f if !y1_type.to_i.odd? || y1.include?("подрезкой")
            else
            width -= edge_array.split("=")[2].to_f if !y1_type.to_i.odd? || y1.include?("подрезкой")
          end
          y1 = edge_thickness
          if edge_z1_texture || hf
            if y1_type == "3" && y2_type == "3"
              (napr_texture=="2" ? height_panel += 1 : width_panel += 1)
              elsif y1_type == "5"
              (napr_texture=="2" ? height_panel += 1 : width_panel += 1)
              elsif y1_type == "7"
              (napr_texture=="2" ? height_panel += 2 : width_panel += 2)
            end
          end
        end
        if y2_type != "1" && y2_type == edge_value[1]
          if napr_texture=="2"
            height -= edge_array.split("=")[2].to_f if !y2_type.to_i.odd? || y2.include?("подрезкой")
            else
            width -= edge_array.split("=")[2].to_f if !y2_type.to_i.odd? || y2.include?("подрезкой")
          end
          y2 = edge_thickness
          if edge_z1_texture || hf
            if y2_type == "5"
              (napr_texture=="2" ? height_panel += 1 : width_panel += 1)
              elsif y2_type == "7"
              (napr_texture=="2" ? height_panel += 2 : width_panel += 2)
            end
          end
        end
      end
      if napr_texture=="2"
        edge_arr = [z1,z2,y1,y2]
        z1,z2,y1,y2 = edge_arr[2],edge_arr[3],edge_arr[1],edge_arr[0]
        edge_type_arr = [z1_type,z2_type,y1_type,y2_type]
        z1_type,z2_type,y1_type,y2_type = edge_type_arr[2],edge_type_arr[3],edge_type_arr[1],edge_type_arr[0]
      end
      if a00_mat_krom != "0"
        z1_texture = a00_mat_krom if su_info[(napr_texture=="2" ? 16 : 12)].include?(a00_mat_krom)
        z2_texture = a00_mat_krom if su_info[(napr_texture=="2" ? 18 : 14)].include?(a00_mat_krom)
        y1_texture = a00_mat_krom if su_info[(napr_texture=="2" ? 14 : 16)].include?(a00_mat_krom)
        y2_texture = a00_mat_krom if su_info[(napr_texture=="2" ? 12 : 18)].include?(a00_mat_krom)
      end
      edge_glue = entity.definition.get_attribute("dynamic_attributes", "edge_glue")
      @panels_and_glue[entity] = edge_glue
      if edge_glue
        z1_texture += " ("+edge_glue+")"
        z2_texture += " ("+edge_glue+")"
        y1_texture += " ("+edge_glue+")"
        y2_texture += " ("+edge_glue+")"
      end
      return width,width_panel,height,height_panel,z1,z2,y1,y2,z1_type,z2_type,y1_type,y2_type,z1_texture,z2_texture,y1_texture,y2_texture
    end#def
    def edge_type(edge_yz_type,edge)
      if !edge_yz_type || edge_yz_type == edge || edge == "0"
        @edge_list.each_with_index { |edge_list,index| edge_yz_type = index+1 if edge_list.to_s.gsub("c","с").gsub(" мм","").gsub(" #{SUF_STRINGS["mm"]}","").strip == edge.to_s.gsub("c","с").strip }
      end
      return edge_yz_type.to_s
    end#def
    def edge_count_length(edge,edge_thickness,length)
      if edge != "1" && @edge_name_hash[edge]
        if @edge_hash[@edge_name_hash[edge]+"х"+edge_thickness.to_s]
          @edge_hash[@edge_name_hash[edge]+"х"+edge_thickness.to_s] = [@edge_hash[@edge_name_hash[edge]+"х"+edge_thickness.to_s][0]+length,@edge_hash[@edge_name_hash[edge]+"х"+edge_thickness.to_s][1]+1]
          else
          @edge_hash[@edge_name_hash[edge]+"х"+edge_thickness.to_s] = [length,1]
        end
      end
    end
    def wortop_edge_count_length(edge,edge_thickness,length)
      if @edge_hash[edge+" "+edge_thickness.to_s]
        @edge_hash[edge+" "+edge_thickness.to_s] = [@edge_hash[edge+" "+edge_thickness.to_s][0]+length,@edge_hash[edge+" "+edge_thickness.to_s][1]+1]
        else
        @edge_hash[edge+" "+edge_thickness.to_s] = [length,1]
      end
    end
    def search_operations(entity,tr,body_flipped)
      if !entity.hidden?
        su_type = entity.definition.get_attribute("dynamic_attributes", "su_type")
        su_info = entity.definition.get_attribute("dynamic_attributes", "su_info")
        if su_info && su_info != "" && su_info != " " && su_info[0] != "module" && su_info[0] != "body" && su_type && su_type != "" && su_type != " " && su_type != "body" && !su_type.include?(SUF_STRINGS["Product"]) && !su_type.include?("Изделие") && !su_type.include?("Тело") && !su_type.include?("module") && !su_type.include?("drawer")
          su_info.include?("/") ? su_info = su_info.split("/") : su_info = su_info.split(",")
          # кромка
          if su_type != "fartuk" && su_type != "worktop" && su_info[1].downcase =~ /рамка|integro|макмарт/i
            else
            if su_info[2] =~ /worktop|fartuk|carcass|frontal|glass|back/i
              thickness_comp = su_info[5]
              a01_gluing = entity.definition.get_attribute("dynamic_attributes", "a01_gluing")
              if a01_gluing
                thickness = (thickness_comp.to_f/a01_gluing.to_f).round.to_s
                else
                if thickness_comp == "32"
                  thickness = "16"
                  elsif thickness_comp == "36"
                  thickness = "18"
                  else
                  thickness = thickness_comp
                end
              end
              edge_thickness = new_thickness(thickness)
              napr_texture = su_info[8]
              z1_type = entity.definition.get_attribute("dynamic_attributes", "edge_z1")
              z2_type = entity.definition.get_attribute("dynamic_attributes", "edge_z2")
              y1_type = entity.definition.get_attribute("dynamic_attributes", "edge_y1")
              y2_type = entity.definition.get_attribute("dynamic_attributes", "edge_y2")
              if su_info[2] == "worktop"
                z1 = su_info[11]
                z2 = su_info[13]
                y1 = su_info[15]
                y2 = su_info[17]
                wortop_edge_count_length((z1 == "2" ? "ABS" : "HPL"),(z1 == "2" ? "42х1,5мм" : "45мм"),su_info[4].to_f) if su_info[11] != "1"
                wortop_edge_count_length((z2 == "2" ? "ABS" : "HPL"),(z2 == "2" ? "42х1,5мм" : "45мм"),su_info[4].to_f) if su_info[13] != "1"
                wortop_edge_count_length((y1 == "2" ? "ABS" : "HPL"),(y1 == "2" ? "42х1,5мм" : "45мм"),su_info[3].to_f) if su_info[15] != "1"
                wortop_edge_count_length((y2 == "2" ? "ABS" : "HPL"),(y1 == "2" ? "42х1,5мм" : "45мм"),su_info[3].to_f) if su_info[17] != "1"
                elsif su_info[2] != "fartuk"
                edge_count_length(edge_type(z1_type,su_info[11]),edge_thickness,su_info[3].to_f)
                edge_count_length(edge_type(z2_type,su_info[13]),edge_thickness,su_info[3].to_f)
                edge_count_length(edge_type(y1_type,su_info[15]),edge_thickness,su_info[4].to_f)
                edge_count_length(edge_type(y2_type,su_info[17]),edge_thickness,su_info[4].to_f)
              end
            end
          end
          
          # пазы и отверстия
          @fastener_array = {}
          @fastener_array["facedrilling"] = []
          @fastener_array["backdrilling"] = []
          @fastener_array["edgedrilling"] = []
          edge_z1_texture = entity.definition.get_attribute("dynamic_attributes", "edge_z1_texture")
          groove = entity.definition.get_attribute("dynamic_attributes", "groove")
          _groove_formulaunits = entity.definition.get_attribute("dynamic_attributes", "_groove_formulaunits")
          if groove && groove.to_f > 0
            if !_groove_formulaunits || _groove_formulaunits == "STRING"
              groove = groove.to_f
              else
              groove = (groove*2.54).round(1)
            end
            groove_thick = su_info[20]
            groove_width = su_info[21]
            edge_z1_texture ? groove_xy_pos = su_info[22] : groove_xy_pos = "1"
            edge_z1_texture ? groove_z_pos = su_info[23] : groove_z_pos = entity.definition.get_attribute("dynamic_attributes", "point_x", "1")
            if groove_xy_pos.to_i == 3 || groove_xy_pos.to_i == 4 #по ширине
              groove_length = su_info[4].to_i
              else
              groove_length = su_info[3].to_i
            end
            @groove_array << [groove,[groove_thick.to_f*10,groove_width.to_f*10],[[groove,0,0],[groove+groove_thick.to_f*10,0,0],[groove+groove_thick.to_f*10,groove_width.to_f*10,0],[groove,groove_width.to_f*10,0]],groove_xy_pos,groove_z_pos,groove_length,(groove<1 ? SUF_STRINGS["Q"]:SUF_STRINGS["G"]+(groove.to_f*10).round.to_s)+"+"+(groove_thick.to_f*10).round.to_s+"*"+(groove_width.to_f*10).round.to_s]
          end
          @groove_array = search_groove(entity,entity,@groove_array,su_info[4],su_info[3],body_flipped)
          search_fastener(entity)
          else
          entity_transformation = entity.transformation
          if !(entity_transformation.xaxis * entity_transformation.yaxis).samedirection?(entity_transformation.zaxis)
            if !body_flipped
              body_flipped = tr.xaxis.normalize.y.to_s+","+tr.xaxis.normalize.z.to_s+","+tr.xaxis.normalize.x.to_s 
              else
              body_flipped = false
            end
          end
          entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_operations(e,tr * entity_transformation,body_flipped) }
        end
      end
    end#def
    def search_groove(parent,entity,groove_array,width,height,body_flipped)
      dict = entity.definition.attribute_dictionary "dynamic_attributes"
      if dict
        dict.each_pair {|attr, v|
          if attr.include?("groove_param") && attr[0] != "_"
            if entity.definition.get_attribute("dynamic_attributes", "_groove")
              groove = entity.definition.get_attribute("dynamic_attributes", attr)
              if groove.is_a?(Array)
                pt = entity.transformation.origin
                groove[3] = [(pt.z*25.4).round(1),(pt.y*25.4).round(1),0,groove[3][3],groove[3][4],groove[3][5]]
                if entity.definition.get_attribute("dynamic_attributes", "_leny_formula") == "parent!leny"
                  groove[5] = (entity.definition.get_attribute("dynamic_attributes", "leny").to_f*25.4).round(1)
                  elsif entity.definition.get_attribute("dynamic_attributes", "_lenx_formula") == "parent!lenz"
                  groove[5] = (entity.definition.get_attribute("dynamic_attributes", "lenx").to_f*25.4).round(1)
                end
                groove_array << groove
                @groove_count += groove[5].to_i if @groove_count
                @components_cut[parent] = [] if !@components_cut[parent]
                @components_cut[parent] << ["groove_comp",width,height,body_flipped]
              end
              else
              groove = entity.definition.get_attribute("dynamic_attributes", attr)
              if groove.is_a?(Array)
                groove_array << groove
                @groove_count += groove[5].to_i if @groove_count
                @components_cut[parent] = [] if !@components_cut[parent]
                @components_cut[parent] << ["groove_comp",width,height,body_flipped]
              end
            end
          end
        }
      end
      entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
        groove_array = search_groove(parent,e,groove_array,width,height,body_flipped)
      }
      return groove_array
    end
    def trim_stock
      @trim_stock.to_f
    end
    def set_groove_name(parent,entity,groove_designation)
      if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |groove|
          if groove.definition.name.include?("groove")
            if !groove.hidden?
              @groove_components[parent] = groove
              groove.name = groove_designation
            end
          end
        }
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |essence| set_groove_name(parent,essence,groove_designation) }
      end
    end#def
    def drilling_array(drilling,fastener_array,drilling_type)
      if fastener_array[drilling_type] == []
        fastener_array[drilling_type] = [[drilling[0],drilling[1],drilling[2],drilling[3],[drilling[4]]]]
        else
        fastener_array[drilling_type].each { |array|
          if array.include?(drilling[0]) && array.include?(drilling[1]) && array.include?(drilling[2]) && array.include?(drilling[3])
            array[4] << drilling[4] if !array[4].include?(drilling[4])
            else
            include = false
            fastener_array[drilling_type].each { |arr| include = true if arr.include?(drilling[0]) && arr.include?(drilling[1]) && arr.include?(drilling[2]) && arr.include?(drilling[3])}
            fastener_array[drilling_type] += [[drilling[0],drilling[1],drilling[2],drilling[3],[drilling[4]]]] if include == false
          end
        }
      end
      return fastener_array
    end#def
    def search_fastener(entity)
      if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        entity.definition.entities.grep(Sketchup::Group).each { |e|
          if e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
            
            all_facedrilling = e.get_attribute("_suf", "facedrilling")
            if all_facedrilling
              all_facedrilling.each { |drilling|
                depth = (drilling[2] == (entity.definition.get_attribute("dynamic_attributes","lenx")*25.4).round.to_s ? " скв." : "x"+drilling[2].to_s)
                @holes[drilling[0]+depth] ? @holes[drilling[0]+depth] += 1 : @holes[drilling[0]+depth] = 1
                if drilling[4]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],drilling[4]]
                  else
                  point = e.transformation.origin
                  points = [(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,-1]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],points]
                end
                @fastener_array = drilling_array(drilling_arr,@fastener_array,"facedrilling")
              }
            end
            
            all_backdrilling = e.get_attribute("_suf", "backdrilling")
            if all_backdrilling
              all_backdrilling.each { |drilling|
                depth = (drilling[2] == (entity.definition.get_attribute("dynamic_attributes","lenx")*25.4).round.to_s ? " скв." : "x"+drilling[2].to_s)
                @holes[drilling[0]+depth] ? @holes[drilling[0]+depth] += 1 : @holes[drilling[0]+depth] = 1
                if drilling[4]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],drilling[4]]
                  else
                  point = e.transformation.origin
                  points = [(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,1]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],points]
                end
                @fastener_array = drilling_array(drilling_arr,@fastener_array,"backdrilling")
              }
            end
            
            all_edgedrilling = e.get_attribute("_suf", "edgedrilling")
            if all_edgedrilling
              all_edgedrilling.each { |drilling|
                @holes[drilling[0]+"x"+drilling[2]+" торц."] ? @holes[drilling[0]+"x"+drilling[2]+" торц."] += 1 : @holes[drilling[0]+"x"+drilling[2]+" торц."] = 1
                if drilling[4]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],drilling[4]]
                  else
                  vec = e.get_attribute("_suf", "drilling_normal")
                  vec.normalize!
                  point = e.transformation.origin
                  points = [(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),vec[2],vec[1],vec[0]]
                  drilling_arr = [drilling[0],drilling[1],drilling[2],drilling[3],points]
                end
                @fastener_array = drilling_array(drilling_arr,@fastener_array,"edgedrilling")
              }
            end
          end
        }
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |essence| search_fastener(essence) }
      end
    end#def
    def groove_components
      return @groove_components
    end
    def list_list(mat,back_mat,thickness,unit,type_material,list_of_components_all)
      @list_components_mat = []
      list_of_components_all.each { |comp_mat|
        type_material_of_mat = comp_mat[0].split("=")[5] || ""
        if comp_mat[0].split("=")[1..4] == [mat, back_mat, thickness, unit] && type_material_of_mat == type_material
          comp_mat[1].each { |comp|
            @list_components_mat.push(comp)
          }
        end
      }
    end#def
    def lists_to_dialog(table,type,mat_name,mat,back_mat,thickness,unit,material_src,name,item_code,width_panel,width,height_panel,height,count,rotate,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,type_material="",max_width_of_count="",mat_grained="true")
      if table == "new"
        vend = [table,@auto_refresh,@lists_panel_size]
        command = "lists_list(#{vend.inspect})"
        $dlg_suf.execute_script(command)
        elsif table == "new_table"
        vend = [table,type,mat_name,mat,back_mat,thickness,SUF_ATT_STR[unit],material_src,name,item_code,width,height,count,type_material,max_width_of_count,mat_grained]
        command = "lists_list(#{vend.inspect})"
        $dlg_suf.execute_script(command)
        elsif table == "panel_count"
        vend = [table,type,mat_name,mat,back_mat,thickness,SUF_ATT_STR[unit],material_src,name,item_code,width,height,count,type_material,max_width_of_count]
        command = "lists_list(#{vend.inspect})"
        $dlg_suf.execute_script(command)
        elsif table == "total_panel_count"
        vend = [table,type]
        command = "lists_list(#{vend.inspect})"
        $dlg_suf.execute_script(command)
        else
        vend = [table,type,mat_name,mat,back_mat,thickness,SUF_ATT_STR[unit],name,item_code,width_panel,width,height_panel,height,count,z1,z1_texture,z2,z2_texture,y1,y1_texture,y2,y2_texture,material_src,rotate,type_material,max_width_of_count]
        command = "lists_list(#{vend.inspect})"
        $dlg_suf.execute_script(command)  
      end
    end#def
    def round(str)
      str = str.to_f.round(1).to_s
      if str[-1]=="0"
        return str.to_f.round.to_s
        else
        return str
      end
    end#def
    def cut2_edge(e)
      e == "0" ? k_left = "0" : k_left = "1"
      case e
        when "2" then k_left_color = "255"; viyar = "2"
        when "1" then k_left_color = "16776960"; viyar = "1"
        when "0.4" then k_left_color = "0"; viyar = "1"
        else k_left_color = "0"; viyar = "0"
      end
      return k_left,k_left_color,viyar
    end#def
    def cut_rotate(ent,rotate,comp_param)
      model = Sketchup.active_model
      param = comp_param.split("=")
      number = ent.definition.get_attribute("dynamic_attributes", "number", "0")
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = ent.definition.get_attribute("dynamic_attributes", "su_info")
      if su_info
        if ent.material == nil
          mat_name = su_info.split("/")[7]
          else
          mat_name = ent.material.display_name
        end
        if number.to_s == param[1] && su_type == param[2] && mat_name == param[3] && su_info.split("/")[5].to_f == param[5].to_f
          model.start_operation('Change rotate', true)
          ent.set_attribute("dynamic_attributes", "a08_rotate", rotate)
          ent.definition.set_attribute("dynamic_attributes", "a08_rotate", rotate)
          ent.definition.set_attribute("dynamic_attributes", "_a08_rotate_label", "a08_rotate")
          Redraw_Components.redraw_entities_with_Progress_Bar([ent])
          model.commit_operation
        end
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| cut_rotate(e,rotate,comp_param) }
    end#def
    def select_accessories(accessory_name)
      model = Sketchup.active_model
      @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      @sel.length == 0 ? entities = @ent : entities = @sel
      model.selection.clear
      entities.grep(Sketchup::ComponentInstance).each { |ent| select_all_accessories(model,ent,accessory_name) }
    end#def
    def select_all_accessories(model,ent,accessory_name)
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = ent.definition.get_attribute("dynamic_attributes", "su_info")
      a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      if su_info && su_type
        a03_name = a03_name.gsub("=","~").gsub(",","|").gsub("+","плюс").gsub("(","[").gsub(")","]")
        accessory_name = accessory_name.gsub("=","~").gsub(",","|").gsub("+","плюс").gsub("(","[").gsub(")","]")
        if a03_name == accessory_name
          model.selection.add ent
        end
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| select_all_accessories(model,e,accessory_name) }
    end#def
    def select_holes(hole_name)
      model = Sketchup.active_model
      @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
      @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
      @sel.length == 0 ? entities = @ent : entities = @sel
      @holes = []
      entities.grep(Sketchup::ComponentInstance).each { |ent| select_all_holes(model,ent,hole_name) }
      if @holes != []
        e = @holes[0]
        diam_depth = []
        if e.get_attribute("_suf", "facedrilling")
          diam_depth = [e.get_attribute("_suf", "facedrilling")[0][0],e.get_attribute("_suf", "facedrilling")[0][2]]
        end
        if e.get_attribute("_suf", "backdrilling")
          diam_depth = [e.get_attribute("_suf", "backdrilling")[0][0],e.get_attribute("_suf", "backdrilling")[0][2]]
        end
        if e.get_attribute("_suf", "edgedrilling")
          diam_depth = [e.get_attribute("_suf", "edgedrilling")[0][0],e.get_attribute("_suf", "edgedrilling")[0][2]]
        end
        input = UI.inputbox ["#{SUF_STRINGS["Name"]} ","#{SUF_STRINGS["Diameter"]} ","#{SUF_STRINGS["Depth"]} "], [hole_name]+diam_depth, "#{@holes.length} #{SUF_STRINGS["holes"]}"
        if input
          if input[1] != "" && input[1] != " " && input[2] != "" && input[2] != " "
            new_name = input[0].strip
            model.start_operation('change_name', true)
            @holes.each {|e|
              normal = nil
              if e.get_attribute("_suf", "facedrilling")
                drilling_array = e.get_attribute("_suf", "facedrilling")
                new_arr = []
                drilling_array.each { |arr|
                  if [arr[0],arr[2]] == diam_depth
                    new_arr << [input[1],input[1],input[2],input[2],arr[4]]
                  end
                }
                e.name = e.name.gsub(hole_name,new_name)
                e.set_attribute("_suf", "facedrilling", new_arr)
                curves = []
                e.entities.grep(Sketchup::Face).each { |face|
                  curve = face.edges[0].curve
                  if !curves.include?(curve) && curve.is_a?(Sketchup::ArcCurve) && curve.normal.parallel?(face.normal)
                    diam_scaling = ((input[1].to_f)/2)/(curve.radius*25.4)
                    normal = face.normal
                    tr = Geom::Transformation.scaling(curve.center, 1, diam_scaling, diam_scaling)
                    Sketchup.active_model.entities.transform_entities tr,curve
                    curves << curve
                  end
                }
                if normal
                  depth_scaling = (input[2].to_f)/(diam_depth[1].to_f)
                  tr = Geom::Transformation.scaling(e.transformation.origin, depth_scaling, 1, 1)
                  Sketchup.active_model.entities.transform_entities tr,e
                end
              end
              if e.get_attribute("_suf", "backdrilling")
                drilling_array = e.get_attribute("_suf", "backdrilling")
                new_arr = []
                drilling_array.each { |arr|
                  if [arr[0],arr[2]] == diam_depth
                    new_arr << [input[1],input[1],input[2],input[2],arr[4]]
                  end
                }
                e.name = e.name.gsub(hole_name,new_name)
                e.set_attribute("_suf", "backdrilling", new_arr)
                curves = []
                e.entities.grep(Sketchup::Face).each { |face|
                  curve = face.edges[0].curve
                  if !curves.include?(curve) && curve.is_a?(Sketchup::ArcCurve) && curve.normal.parallel?(face.normal)
                    diam_scaling = ((input[1].to_f)/2)/(curve.radius*25.4)
                    normal = face.normal
                    tr = Geom::Transformation.scaling(curve.center, 1, diam_scaling, diam_scaling)
                    Sketchup.active_model.entities.transform_entities tr,curve
                    curves << curve
                  end
                }
                if normal
                  depth_scaling = (input[2].to_f)/(diam_depth[1].to_f)
                  tr = Geom::Transformation.scaling(e.transformation.origin, depth_scaling, 1, 1)
                  Sketchup.active_model.entities.transform_entities tr,e
                end
              end
              if e.get_attribute("_suf", "edgedrilling")
                drilling_array = e.get_attribute("_suf", "edgedrilling")
                new_arr = []
                drilling_array.each { |arr|
                  if [arr[0],arr[2]] == diam_depth
                    new_arr << [input[1],input[1],input[2],input[2],arr[4]]
                  end
                }
                e.name = e.name.gsub(hole_name,new_name)
                e.set_attribute("_suf", "edgedrilling", new_arr)
                curves = []
                e.entities.grep(Sketchup::Face).each { |face|
                  curve = face.edges[0].curve
                  if !curves.include?(curve) && curve.is_a?(Sketchup::ArcCurve) && curve.normal.parallel?(face.normal)
                    diam_scaling = ((input[1].to_f)/2)/(curve.radius*25.4)
                    normal = face.normal
                    diam_array = [(normal.x.round==0 ? diam_scaling : 1),(normal.y.round==0 ? diam_scaling : 1),(normal.z.round==0 ? diam_scaling : 1)]
                    tr = Geom::Transformation.scaling(curve.center, diam_array[0], diam_array[1], diam_array[2])
                    Sketchup.active_model.entities.transform_entities tr,curve
                    curves << curve
                  end
                }
                if normal
                  depth_scaling = (input[2].to_f)/(diam_depth[1].to_f)
                  depth_array = [(normal.x.round==0 ? 1 : depth_scaling),(normal.y.round==0 ? 1 : depth_scaling),(normal.z.round==0 ? 1 : depth_scaling)]
                  tr = Geom::Transformation.scaling(e.transformation.origin, depth_array[0], depth_array[1], depth_array[2])
                  Sketchup.active_model.entities.transform_entities tr,e
                end
              end
            }
            model.commit_operation
          end
        end
      end
    end#def
    def select_all_holes(model,ent,hole_name)
      if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        ent.definition.entities.grep(Sketchup::Group).each { |e|
          if e.name.include?(hole_name)
            if e.name.include?("x") && hole_name.include?("x")
              if e.name.gsub("ø","").split("x")[0] == hole_name.split("x")[0]
                @holes << e
              end
              else
              @holes << e
            end
          end
        }
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| select_all_holes(model,e,hole_name) }
    end#def
    def name_furniture(ent,old_name,new_name,delete_formula)
      model = Sketchup.active_model
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = ent.definition.get_attribute("dynamic_attributes", "su_info")
      a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name")
      _a03_name_formula = ent.definition.get_attribute("dynamic_attributes", "_a03_name_formula")
      if su_info && su_type
        old_name = old_name.gsub("=","~").gsub(",","|").gsub("+","плюс").gsub("(","[").gsub(")","]")
        new_name = new_name.gsub("=","~").gsub(",","|").gsub("+","плюс").gsub("(","[").gsub(")","]")
        if a03_name == old_name.strip
          model.start_operation('Change name', true)
          p "old_name: #{old_name}"
          p "new_name: #{new_name}"
          if _a03_name_formula
            str = ""
            old_name.strip.split(" ").each{|n|
              if _a03_name_formula.include?(n)
                str+=n+" "
              end
            }
            p "_a03_name_formula:"
            p _a03_name_formula
            if _a03_name_formula.include?(str)
              new_name+=" " if new_name[-1]!=" "
              _a03_name_formula = _a03_name_formula.gsub(str,new_name.lstrip)
              ent.definition.set_attribute("dynamic_attributes", "_a03_name_formula", _a03_name_formula)
              p "_a03_name_new_formula:"
              p _a03_name_formula
              else
              if !delete_formula
                delete_formula = UI.messagebox(SUF_STRINGS["It is not possible to change the formula in the name"]+".\n"+SUF_STRINGS["Delete Formula"]+"?",MB_YESNO)
              end
              if delete_formula == IDYES
                ent.set_attribute("dynamic_attributes", "a03_name", new_name.strip)
                ent.definition.set_attribute("dynamic_attributes", "a03_name", new_name.strip)
                ent.definition.delete_attribute("dynamic_attributes", "_a03_name_formula")
              end
            end
            else
            ent.set_attribute("dynamic_attributes", "a03_name", new_name.strip)
            ent.definition.set_attribute("dynamic_attributes", "a03_name", new_name.strip)
          end
          Redraw_Components.redraw_entities_with_Progress_Bar([ent])
          model.commit_operation
        end
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| name_furniture(e,old_name,new_name,delete_formula) }
    end#def
    def set_new_name(ent,name,comp_param)
      param = comp_param.split("=")
      model = Sketchup.active_model
      sel = model.selection
      number = ent.definition.get_attribute("dynamic_attributes", "number", "0")
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = ent.definition.get_attribute("dynamic_attributes", "su_info")
      a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name")
      if su_info
        if ent.material == nil
          mat_name = su_info.split("/")[7]
          else
          mat_name = ent.material.display_name
        end
        if number.to_s == param[1] && su_type == param[2] && mat_name == param[3] && su_info.split("/")[5] == param[5] && param[6].include?(a03_name)
          model.start_operation('change_name', true)
          name = name.strip
          ent.set_attribute("dynamic_attributes", "a03_name", name)
          ent.definition.set_attribute("dynamic_attributes", "a03_name", name)
          ent.definition.set_attribute("dynamic_attributes", "_a03_name_label", "a03_name")
          ent.definition.delete_attribute("dynamic_attributes", "_a03_name_formula")
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
          Redraw_Components.redraw_entities_with_Progress_Bar([ent])
          model.commit_operation
          sel.clear if ent == sel[0]
        end
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| set_new_name(e,name,comp_param) }
    end#def
    def select_panel(ent,arr)
      model = Sketchup.active_model
      number = ent.definition.get_attribute("dynamic_attributes", "number", "0")
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type")
      su_info = ent.definition.get_attribute("dynamic_attributes", "su_info")
      a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name","0")
      l1_component_102_article = ent.definition.get_attribute("dynamic_attributes", "l1_component_102_article")
      l0_component_100_thickness = ent.definition.get_attribute("dynamic_attributes", "l0_component_100_thickness")
      var_l0_lenx = ent.definition.get_attribute("dynamic_attributes", "var_l0_lenx")
      var_l0_leny = ent.definition.get_attribute("dynamic_attributes", "var_l0_leny")
      var_l0_lenz = ent.definition.get_attribute("dynamic_attributes", "var_l0_lenz")
      
      a03_name = l1_component_102_article if l1_component_102_article
      if su_info || l1_component_102_article
        if ent.material
          mat_name = ent.material.display_name
          else
          mat_name = su_info.split("/")[7] if su_info
        end
        arr.each { |param|
          param = param.split("=")
          if number.to_s == param[1] && mat_name == param[3] && su_info && su_info!= "" && su_info!= " " && param[6].include?(su_info.split("/")[1])
            width_comp = su_info.split("/")[3].to_f.round(1)
            height_comp = su_info.split("/")[4].to_f.round(1)
            thickness_comp = su_info.split("/")[5].to_f.round(1).to_s
            a01_gluing = ent.definition.get_attribute("dynamic_attributes", "a01_gluing")
            if a01_gluing
              thickness = (thickness_comp.to_f/a01_gluing.to_f).round(1).to_s
              width_comp += @trim_stock.to_f
              height_comp += @trim_stock.to_f
              else
              if thickness_comp == "32"
                thickness = "16.0"
                width_comp += @trim_stock.to_f
                height_comp += @trim_stock.to_f
                elsif thickness_comp == "36"
                thickness = "18.0"
                width_comp += @trim_stock.to_f
                height_comp += @trim_stock.to_f
                else
                thickness = thickness_comp
              end
            end
            if thickness.to_f.round(1) == param[5].to_f.round(1) # толщина
              if su_type == param[2] || param[2] == "carcass" && su_type == "frontal"
                if param[7].to_f.round(1)==width_comp && param[8].to_f.round(1)==height_comp || param[7].to_f.round(1)==height_comp && param[8].to_f.round(1)==width_comp
                  model.selection.add ent
                  elsif param[7].include?(su_info.split("/")[3]) && param[8].include?(su_info.split("/")[4]) || param[7].include?(su_info.split("/")[4]) && param[8].include?(su_info.split("/")[3])
                  model.selection.add ent
                  elsif param[7].to_f <= width_comp && param[7].to_f+4 >= width_comp && param[8].gsub("|","").to_f <= height_comp && param[8].gsub("|","").to_f+4 >= height_comp || param[7].to_f <= height_comp && param[7].to_f+4 >= height_comp && param[8].gsub("|","").to_f <= width_comp && param[8].gsub("|","").to_f+4 >= width_comp
                  model.selection.add ent
                end
              end
            end
            elsif l1_component_102_article && number.to_s == param[1] && mat_name == param[3] && param[6].include?(a03_name)
            if (var_l0_lenx*25.4).round(1) == param[5].to_f && (var_l0_leny*25.4).round(1) == param[7].to_f && (var_l0_lenz*25.4).round(1) == param[8].to_f || (var_l0_lenz*25.4).round(1) == param[7].to_f && (var_l0_leny*25.4).round(1) == param[8].to_f
              model.selection.add ent
            end
          end
        }
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| select_panel(e,arr) }
    end#def
    def create_html(program_list,program,base_list,base)
      html = ""
      html += "<style>"
      html += "body { font-family: Arial; color: #696969; font-size: 16px; padding-top: 35px; padding-bottom: 40px; } "
      html += "#header { position: fixed; top: 0; left: 0; width: 100%; height: 33px; border-bottom: 1px solid gray; background-color: white;} "
      html += "table.export_param_table { position: fixed; margin-left: 20px; } "
      html += "table.material_name_table { border: 1px solid gray; border-collapse: separate; border-spacing: 0; border-radius: 3px; width: 100%; padding: 5px; z-index: 5; } "
      html += "table.material_name_table th { position: sticky; top: 34; height: 33px; border-bottom: 1px solid gray; background: white; text-align: center; } "
      html += "table.material_name_table td { padding-top: 10px; vertical-align: middle; } "
      html += "#footer { position: fixed; bottom: 0; left: 0; width: 100%; height: 33px; border-top: 1px solid gray; background-color: white; padding: 3px;} "
      html += "</style>"
      html += "<script>"
      html += "var material_name_arr = [];\n"
      html += "function callback(array) {\n"
      html += "let program = array[0];\n"
      html += "let mat_arr = array[1];\n"
      html += "let base = array[2];\n"
      html += "for (let i = 0; i < mat_arr.length; i++) {\n"
      html += "if (document.getElementById(mat_arr[i].id).checked) { \n"
      html += "material_name_arr.push([mat_arr[i].id,document.getElementById('name_for_product_'+mat_arr[i].id).value,document.getElementById('article_'+mat_arr[i].id).value]);\n"
      html += "}\n"
      html += "}\n"
      html += "sketchup.callback([program,base,material_name_arr]);\n"
      html += "}\n"
      html += "function change_program(program) {\n"
      html += "sketchup.change_program(program);\n"
      html += "}\n"
      html += "function change_base(base) {\n"
      html += "sketchup.change_base(base);\n"
      html += "}\n"
      html += "function add_file_to_base(base) {\n"
      html += "sketchup.add_file_to_base(base);\n"
      html += "}\n"
      html += "function delete_base(base) {\n"
      html += "sketchup.delete_base(base);\n"
      html += "}\n"
      html += "function previous_value(mat_a) {\n"
      html += "sketchup.previous_value(mat_a);\n"
      html += "}\n"
      html += "function next_value(mat_a) {\n"
      html += "sketchup.next_value(mat_a);\n"
      html += "}\n"
      html += "function find_base(mat_a) {\n"
      html += "sketchup.find_base(mat_a);\n"
      html += "}\n"
      html += "</script>"
      html += "<div id=\"header\">"
      html += "<table class=\"export_param_table\" ><tr><td></td><td>#{SUF_STRINGS["Export"]} #{SUF_STRINGS["to the program"]}: </td><td>"
      html += "<select id=\"program\" style=\"width: 100px; margin-left:5px; margin-right:15px;\" type=\"text\" onchange=\"change_program(this.value)\">"
      program_list.each { |option|
        option == program ? html += "<option selected value=\"#{option}\">#{option}</option>" : html += "<option value=\"#{option}\">#{option}</option>"
      }
      html += "</select></td><td>#{SUF_STRINGS["Name database"]}: </td>"
      html += "<td><select id=\"base_list\" style=\"width: 100px; margin-left:5px;\" type=\"text\" onchange=\"change_base(this.value)\">"
      base_list.each { |option|
        option == base ? html += "<option selected value=\"#{option}\">#{option}</option>" : html += "<option value=\"#{option}\">#{option}</option>"
      }
      html += "</select></td><td><button style=\"margin-left:5px;\" onclick=\"add_file_to_base(document.getElementById('base_list').value)\">#{SUF_STRINGS["Add file to database"]}</button></td><td><button style=\"margin-left:5px;\" onclick=\"delete_base(document.getElementById('base_list').value)\">#{SUF_STRINGS["Delete database"]}</button></td></tr></table><br>"
      html += "</div>"
      
      html += "<table class=\"material_name_table\" >"
      html += "<tr><th></th><th>#{SUF_STRINGS["name"]}</th><th>#{SUF_STRINGS["Name for production"]}</th><th>#{SUF_STRINGS["Article number"]}</th><th></th><th></th><th></th></tr>"
      p @material_hash
      @material_hash.each_pair { |mat_a,mat_array|
        arr = mat_array[@material_value[mat_a]]
        mat = mat_a.split("=")[1]
        length = (4.6*mat.length).round+10
        html += "<tr><td style=\"width:20px;\"><input title=\"#{SUF_STRINGS["Include in export"]}\" class=\"export_mat\" id=\"#{mat_a}\" type=\"checkbox\" checked></td><td style=\"width:#{length}px;\"><div style=\"width:#{length}px; min-width:165px;\">#{mat}<div></td><td style=\"width:100%;\"><input style=\"margin-left:5px; width:100%;\" id=\"name_for_product_#{mat_a}\" type=\"textbox\" value=\"#{arr[0]}\"></td><td style=\"width:170px;\"><input style=\"margin-left:5px; width:170px;\" id=\"article_#{mat_a}\" type=\"textbox\" value=\"#{arr[1]}\"></td><td style=\"width:20px;\"><input type=\"button\" value=\"▲\" id=\"previous_#{mat_a}\" title=\"#{SUF_STRINGS["Previous value"]} (#{mat_array.length})\" #{(@material_value[mat_a]>0 ? '' : 'disabled="true"')} onclick=\"previous_value('#{mat_a}')\"></td><td style=\"width:20px;\"><input type=\"button\" value=\"▼\" id=\"next_#{mat_a}\" title=\"#{SUF_STRINGS["Next value"]} (#{mat_array.length})\" #{((mat_array.length>1 && @material_value[mat_a]<mat_array.length-1) ? '' : 'disabled="true"')} onclick=\"next_value('#{mat_a}')\"></td><td style=\"width:20px;\"><input type=\"button\" value=\"...\" id=\"find_#{mat_a}\" title=\"#{SUF_STRINGS["Search the database"]}\"} onclick=\"find_base('#{mat_a}')\"></td></tr>"
      }
      html += "</table>"
      html += "<div id=\"footer\">"
      html += "<button style=\"margin-left:10px; position:fixed; bottom:10;\" onclick=\"callback([document.getElementById('program').value,document.getElementsByClassName('export_mat'),document.getElementById('base_list').value])\">ОK</button>"
      html += "<button style=\"margin-left:55px; position:fixed; bottom:10;\" onclick=\"sketchup.close(false)\">#{SUF_STRINGS["Cancel"]}</button></div>"
      return html
    end#def
    def change_program(dlg,program)
      @program = program
    end#def
    def change_base(dlg,base)
      if base == SUF_STRINGS["New"]
        name_base = UI.inputbox ["#{SUF_STRINGS["Folder name for new materials database"]} "], [""], " "
        if name_base
          if !File.directory?(File.join(TEMP_PATH,"SUF","Name_database",name_base[0]))
            FileUtils.mkdir_p(File.join(TEMP_PATH,"SUF","Name_database",name_base[0]))
          end
          chosen_file = UI.openpanel("#{SUF_STRINGS["Select Excel file"]} (#{SUF_STRINGS["Column 1 - Article | Column 2 - Name"]})", Dir.pwd, "Excel File|*.xlsx||")
          if chosen_file
            cwd = Dir.chdir(File.dirname(chosen_file))
            @base = name_base[0]
            @base_list << @base
            FileUtils.cp(chosen_file, File.join(TEMP_PATH,"SUF","Name_database",@base))
          end
        end
        else
        @base = base
      end
      Sketchup.active_model.set_attribute("su_lists", "material_hash", [])
      export_dialog(dlg)
    end#def
    def add_file_to_base(dlg,base)
      chosen_file = UI.openpanel("#{SUF_STRINGS["Select Excel file"]} (#{SUF_STRINGS["Column 1 - Article | Column 2 - Name"]})", Dir.pwd, "Excel File|*.xlsx||")
      if chosen_file
        cwd = Dir.chdir(File.dirname(chosen_file))
        FileUtils.cp(chosen_file, File.join(TEMP_PATH,"SUF","Name_database",base))
        base_hash = {}
        Dir.entries(File.join(TEMP_PATH,"SUF","Name_database",base)).each{|f|
          f = f.encode("utf-8")
          if !f.include?("~") && File.file?(File.join(TEMP_PATH,"SUF","Name_database",base,f))
            hash = SU_Furniture::Read_XLSX.read_file(File.join(TEMP_PATH,"SUF","Name_database",base,f),[1,0])
            base_hash[f] = hash
          end
        }
        @base_hash[base] = base_hash
        Sketchup.active_model.set_attribute("su_lists", "material_hash", [])
        export_dialog(dlg)
      end
    end#def
    def delete_base(dlg,base)
      result = UI.messagebox("#{SUF_STRINGS["Delete database folder"]} #{base} #{SUF_STRINGS["and all its files"]}?",MB_YESNO)
      if result == IDYES
        if File.directory?(File.join(TEMP_PATH,"SUF","Name_database",base))
          FileUtils.rm_rf(File.join(TEMP_PATH,"SUF","Name_database",base))
        end
        @base_list.delete(base)
        @base_hash.delete(base)
        Sketchup.active_model.set_attribute("su_lists", "material_hash", [])
        @base = SUF_STRINGS["From price list"]
        export_dialog(dlg)
      end
    end#def
    def previous_value(dlg,mat_a)
      if @material_value[mat_a] != 0
        @material_value[mat_a] = @material_value[mat_a] - 1
      end
      export_dialog(dlg)
    end#def
    def next_value(dlg,mat_a)
      if @material_value[mat_a] < @material_hash[mat_a].length-1
        @material_value[mat_a] = @material_value[mat_a] + 1
      end
      export_dialog(dlg)
    end#def
    def find_base(dlg,mat_a)
      case mat_a.split("=")[0]
        when "frontal" then price_group_array = ["ЛДСП","LDSP","LMDF","Фасад"]
        when "carcass" then price_group_array = ["ЛДСП","LDSP","LMDF"]
        when "back" then price_group_array = ["HDF","ХДФ","Материалы"]
        else price_group_array = ["Материалы"]
      end
      mat_array = []
      if @base == SUF_STRINGS["From price list"]
        full_path_price = Dir.glob(File.join(PATH_PRICE, "*")).find_all { |l| File.extname(l)[/(xml)/i] }
        all_folder_price = full_path_price.map { |f| File.basename(f, File.extname(f)) }.reject { |f| f == "Фреза_текстура" || price_group_array.none? { |pg| f.include?(pg) } }
        all_folder_price.each{|price|
          content = File.read(File.join(PATH_PRICE, "#{price}.xml"))
          materials = xml_value(content.strip,"<Materials>","</Materials>")
          next if materials.empty?
          material_array = xml_array(materials,"<Material>","</Material>")
          @price_array = []
          material_array.each{|cont|
            mat_array << [xml_value(cont,"<Name>","</Name>"),xml_value(cont,"<Article>","</Article>")]
          }
        }
        else
        @base_hash[@base].each_pair{|base_file,base_hash|
          if price_group_array.any?{|price_group|base_file.include?(price_group)}
            base_hash.each_pair{|sheet,sheet_hash|
              sheet_hash.each_pair{|name,array|
                mat_array << array
              }
            }
          end
        }
      end
      show_materials_table(dlg,mat_a,@base,mat_array)
    end#def
    def show_materials_table(dlg, mat_a, base, mat_array)
      html = <<~HTML
        <html><head><meta charset="UTF-8">
        <style>
        body { font-family: Arial, sans-serif; padding: 10px; }
        table { border-collapse: collapse; width: 100%; margin-top: 10px; }
        th, td { border: 1px solid #ccc; padding: 5px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #ddeeff; cursor: pointer; }
        input[type="text"] { width: 100%; padding: 5px; margin-top: 5px; margin-bottom: 10px; box-sizing: border-box; font-size: 14px; }
        </style>
        <script>
        function rowClicked(name, article) {
        window.sketchup.row_selected(name, article);
        }
        
        function filterTable() {
        const input = document.getElementById("searchInput");
        const filter = input.value.toLowerCase();
        const rows = document.querySelectorAll("#materialsTable tr");
        
        rows.forEach(row => {
        const nameCell = row.cells[0];
        const articleCell = row.cells[1];
        if (!nameCell || !articleCell) return;
        
        const name = nameCell.textContent.toLowerCase();
        const article = articleCell.textContent.toLowerCase();
        const match = name.includes(filter) || article.includes(filter);
        
        row.style.display = match ? "" : "none";
        });
        }
        </script>
        </head><body>
        <h3>#{SUF_STRINGS["Materials in database"]} #{base}</h3>
        <input type="text" id="searchInput" placeholder="#{SUF_STRINGS["Search by name or article..."]}" onkeyup="filterTable()">
        <table>
        <thead><tr><th>#{SUF_STRINGS["name"]}</th><th>#{SUF_STRINGS["Article number"]}</th></tr></thead>
        <tbody id="materialsTable">
      HTML
      
      mat_array.each { |name, article|
        html += %Q{<tr onclick="rowClicked('#{name}', '#{article}')"><td>#{name}</td><td>#{article}</td></tr>\n}
      }
      html += <<~HTML
        </tbody></table></body></html>
      HTML
      table_dlg = UI::HtmlDialog.new({
        :dialog_title => SUF_STRINGS["Materials table"],
        :preferences_key => "material_table_dialog",
        :scrollable => true,
        :resizable => true,
        :width => 600,
        :min_width => 600,
        :height => 400,
        :min_height => 400,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      table_dlg.add_action_callback("row_selected") { |_, name, article|
        if dlg && dlg.visible?
          selected_row = [name, article]
          @material_hash[mat_a] = [selected_row]
          @material_value[mat_a] = 0
          Sketchup.active_model.set_attribute("su_lists", "material_hash", @material_hash.to_a)
          export_dialog(dlg)
        end
        table_dlg.close
      }
      table_dlg.set_html(html)
      table_dlg.show
    end
    
    def parse_xml(path,mat,thickness,price_group_array,article="")
      mat_array = []
      mat.rindex("_") == mat.length-2 || mat.rindex("_") == mat.length-3 || mat.rindex("_") == mat.length-4 || mat.rindex("_") == mat.length-5 ? mat_name = mat[0..mat.rindex("_")-1] : mat_name = mat
      full_path_price = Dir.glob(File.join(path, "*")).find_all { |l| File.extname(l)[/(xml)/i] }
      all_folder_price = full_path_price.map { |f| File.basename(f, File.extname(f)) }.reject { |f| f == "Фреза_текстура" || price_group_array.none? { |pg| f.include?(pg) } }
      all_folder_price.each{|price|
        content = File.read(File.join(path, "#{price}.xml"))
        materials = xml_value(content.strip,"<Materials>","</Materials>")
        next if materials.empty?
        material_array = xml_array(materials,"<Material>","</Material>")
        @price_array = []
        material_array.each{|cont|
          name = xml_value(cont,"<Name>","</Name>")
          if name.downcase.include?(mat_name.downcase) && name.include?(thickness)
            mat_array << [name,xml_value(cont,"<Article>","</Article>")]
          end
        }
      }
      mat_array.empty? ? [[mat, article]] : mat_array
    end
    def parse_base(base,mat,thickness,price_group_array,article="")
      mat_array = []
      mat.rindex("_") == mat.length-2 || mat.rindex("_") == mat.length-3 || mat.rindex("_") == mat.length-4 || mat.rindex("_") == mat.length-5 ? mat_name = mat[0..mat.rindex("_")-1] : mat_name = mat
      mat_name = mat_name.downcase.gsub("ый","ая").gsub("ое","ая").gsub("(","").gsub(")","").gsub("[","").gsub("]","").strip
      thickness = round(thickness)
      if @base_hash[base]
        @base_hash[base].each_pair{|base_file,base_hash|
          if price_group_array.any?{|price_group|base_file.include?(price_group)}
            base_hash.each_pair{|sheet,sheet_hash|
              sheet_hash.each_pair{|name,array|
                if name.include?(thickness.gsub("4","3")+"мм") || name.include?(thickness.gsub("4","3")+" мм") || name.include?("x"+thickness.gsub("4","3")) || name.include?("х"+thickness.gsub("4","3"))
                  if name.downcase.gsub("ый","ая").gsub("ое","ая").gsub("(","").gsub(")","").gsub("[","").gsub("]","").include?(mat_name)
                    return [array]
                    else
                    mat_name_array = mat_name.split(" ")
                    include = 0
                    mat_name_array.each {|name_part|
                      if name_part.length > 1
                        include += 1 if array[0].downcase.include?(name_part.downcase)
                        include += 1 if array[1].downcase.include?(name_part.downcase)
                      end
                    }
                    mat_array << array if include > 2
                    mat_name_array = mat_name.split("_")
                    include = 0
                    mat_name_array.each {|name_part|
                      if name_part.length > 1
                        include += 1 if array[1].downcase.include?(name_part.downcase)
                      end
                    }
                    mat_array << array if include > 1
                  end
                end
              }
            }
          end
        }
      end
      mat_array.empty? ? [[mat, article]] : mat_array
    end#def
    def search_mat_name_and_mat_code(mat_a)
      case mat_a.split("=")[0]
        when "frontal" then price_group_array = ["ЛДСП","LDSP","LMDF","Фасад"]
        when "carcass" then price_group_array = ["ЛДСП","LDSP","LMDF"]
        when "back" then price_group_array = ["HDF","ХДФ","Материалы"]
        else price_group_array = ["Материалы"]
      end
      if @base == SUF_STRINGS["From price list"]
        mat_array = parse_xml(PATH_PRICE,mat_a.split("=")[1],mat_a.split("=")[3],price_group_array)
        else
        mat_array = parse_base(@base,mat_a.split("=")[1],mat_a.split("=")[3],price_group_array)
      end
      return mat_array
    end
    def export_dialog(reload=false)
      @program_list.include?(@default_prog) ? @program = @default_prog : @program = @program_list[0]
      saved_material_hash = Sketchup.active_model.get_attribute("su_lists", "material_hash")
      if saved_material_hash && saved_material_hash != []
        @all_material_name_arr.each { |mat_a|
          saved_material_hash = saved_material_hash.to_h
          if saved_material_hash[mat_a]
            @material_hash[mat_a] = saved_material_hash[mat_a]
            @material_value[mat_a] = 0
            else
            @material_hash[mat_a] = search_mat_name_and_mat_code(mat_a)
            @material_value[mat_a] = 0 if !@material_value[mat_a]
          end
        }
        else
        @all_material_name_arr.each { |mat_a|
          @material_hash[mat_a] = search_mat_name_and_mat_code(mat_a)
          @material_value[mat_a] = 0 if !@material_value[mat_a]
        }
      end
      html = create_html(@program_list,@program,@base_list,@base)
      dlg_height = 300+23*@material_hash.count
      if reload
        @dlg = reload
        else
        @dlg = UI::HtmlDialog.new({
          :dialog_title => ' ',
          :preferences_key => "export_dialog",
          :scrollable => true,
          :resizable => true,
          :width => 1000,
          :min_width => 1000,
          :height => dlg_height,
          :min_height => 500,
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
      end
      @dlg.set_html(html)
      if !reload
        @dlg.add_action_callback("callback") { |_, v|
          mat_arr = v[2]
          @material_hash = {}
          @material_value = {}
          mat_arr.each { |arr|
            @material_hash[arr[0]] = [[arr[1],arr[2]]]
          }
          @base = v[1]
          @prog = v[0]
          @dlg.close
          export_from_dialog
        }
        @dlg.add_action_callback("change_base") { |_, v|
          change_base(@dlg,v)
        }
        @dlg.add_action_callback("add_file_to_base") { |_, v|
          add_file_to_base(@dlg,v)
        }
        @dlg.add_action_callback("change_program") { |_, v|
          change_program(@dlg,v)
        }
        @dlg.add_action_callback("delete_base") { |_, v|
          delete_base(@dlg,v)
        }
        @dlg.add_action_callback("previous_value") { |_, v|
          previous_value(@dlg,v)
        }
        @dlg.add_action_callback("next_value") { |_, v|
          next_value(@dlg,v)
        }
        @dlg.add_action_callback("find_base") { |_, v|
          find_base(@dlg,v)
        }
        @dlg.add_action_callback("close") { |_, v|
          @dlg.close
        }
        @dlg.show
      end
    end#def
    def cutting_dialog(all_panels)
      if @cutting_program == "OCL"
        if OCL
          Sketchup.active_model.layers.each { |l| l.visible = true if l.name.include?("Z_Edge") || l.name.include?("Z_Face") }
          presets = Sketchup.active_model.get_attribute("ladb_opencutlist", "core.presets", nil)
          new_presets = '{"cutlist_options":{"0":{"auto_orient":true,"smart_material":true,"dynamic_attributes_name":true,"part_number_with_letters":false,"part_number_sequence_by_group":true,"part_folding":false,"hide_entity_names":false,"hide_tags":false,"hide_cutting_dimensions":false,"hide_bbox_dimensions":false,"hide_untyped_material_dimensions":false,"hide_final_areas":true,"hide_edges":false,"minimize_on_highlight":true,"part_order_strategy":"name>-length>-width>-thickness>-count>-edge_pattern>tags","dimension_column_order_strategy":"length>width>thickness","tags":[""],"hidden_group_ids":[]}}}'
          Sketchup.active_model.set_attribute("ladb_opencutlist", "core.presets", new_presets) if !presets || presets == '{}'
          if Ladb::OpenCutList::EXTENSION_VERSION.to_f > 5
            Ladb::OpenCutList::Plugin.instance.toggle_tabs_dialog
            else
            Ladb::OpenCutList::Plugin.instance.toggle_dialog
          end
          else
          UI.messagebox(SUF_STRINGS["OCL plugin for cutting is not installed!"])
        end
        elsif @cutting_program.include?("nesting")
        Panels_Nesting.show_cutting_dialog(([@sheet_trim,@saw_kerf,@min_leftover_size]+JSON.parse(all_panels)).to_json)
        else
        Panels_Cutting.show_cutting_dialog(([@sheet_trim,@saw_kerf,@min_leftover_size]+JSON.parse(all_panels)).to_json)
      end
    end
    def export_list(active) # нижняя кнопка при активных вкладках листы и погонаж
      @active = active
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
        @path_param = File.join(param_temp_path,"parameters.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
        @path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
        else
        @path_param = File.join(PATH,"parameters","parameters.dat")
      end
      @content = File.readlines(@path_param)
      @default_prog = "Cutting2"
      @content.each { |i| 
        @default_prog = i.strip.split("=")[2] if i.strip.split("=")[1] == "cut_prog"
      }
      prompts = [SUF_STRINGS["Export"]+" "+SUF_STRINGS["to the program"]+": "]
      @program_list = ["Excel","Bazis","GibLab","DXF"]
      @material_hash = {}
      @material_value = {}
      @prog = nil
      @price_hash = {}
      @digit_capacity = nil
      @base = SUF_STRINGS["From price list"]
      path_param = File.join(TEMP_PATH, "SUF", "name_database.dat")
      if File.file?(path_param)
        name_database_content = File.readlines(path_param)
        @base = name_database_content[0].strip
      end
      @base_list = [SUF_STRINGS["New"],SUF_STRINGS["From price list"]]
      @base_hash = {}
      Dir.entries(File.join(TEMP_PATH,"SUF","Name_database")).each{|base|
        base_hash = {}
        base = base.encode("utf-8")
        if !base.include?('.') && File.directory?(File.join(TEMP_PATH,"SUF","Name_database",base))
          @base_list << base
          Dir.entries(File.join(TEMP_PATH,"SUF","Name_database",base)).each{|f|
            f = f.encode("utf-8")
            if !f.include?("~") && File.file?(File.join(TEMP_PATH,"SUF","Name_database",base,f))
              hash = SU_Furniture::Read_XLSX.read_file(File.join(TEMP_PATH,"SUF","Name_database",base,f),[1,0])
              base_hash[f] = hash
            end
          }
        end
        @base_hash[base] = base_hash
      }
      export_dialog()
    end
    def export_from_dialog()
      param_file = File.new(File.join(TEMP_PATH,"SUF","name_database.dat"),"w")
      param_file.puts @base
      param_file.close
      if @prog
        Sketchup.active_model.set_attribute("su_lists", "material_hash", @material_hash.to_a)
        param_file = File.new(@path_param,"w")
        @content.each{|i|
          if i.split("=")[1] == "cut_prog"
            param_file.puts "Программа раскроя по умолчанию=cut_prog="+@prog+"=SELECT=&Astra^Astra&Cutting2^Cutting2&Cutting3^Cutting3&Cutting Optimization^Cutting Optimization&ВиЯр^ВиЯр&Quadro^Quadro&Excel^Excel&#{SUF_STRINGS["List of fronts"]}^#{SUF_STRINGS["List of fronts"]}&Bazis^Bazis&GibLab^GibLab&DXF^DXF"
            else
            param_file.puts i
          end
        }
        param_file.close
        Sketchup::set_status_text "Export.."
        if @prog == "Excel"
          command = "export_excel(#{@active.inspect})"
          $dlg_suf.execute_script(command)
          else
          @holes = {}
          @mat_ent_components = {}
          @material_hash.each_pair { |mat_a,name_arr|
            @ent_components = {}
            @add_work = []
            material_type = mat_a.split("=")[0]
            su_type_list = [material_type]
            mat_name = mat_a.split("=")[1]
            path_name,file_name = search(mat_name)
            back_mat = mat_a.split("=")[2]
            material_thickness = mat_a.split("=")[3]
            unit = mat_a.split("=")[4]
            mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
            mat_a.split("=")[6] ? max_width_of_count = "" : max_width_of_count = "=0"
            list_of_comp = []
            list_of_components = []
            @list_components_mat = []
            list_of_components_all = []
            @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
            @ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
            @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
            sel_parent = "model"
            sel_parent = "no model" if @sel[0] && !@sel[0].parent.is_a?(Sketchup::Model)
            @sel.length == 0 ? sel = @ent : sel = @sel
            @z1_type,@z2_type,@y1_type,@y2_type = nil
            if @frontal_carcass_mat.include?(mat_a+max_width_of_count)
              sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,["carcass","frontal"],mat_name,back_mat,material_thickness,unit,type_material,file_name,list_of_comp,list_of_components,list_of_components_all,false,false,true) if !ent.hidden? }
              else
              sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,su_type_list,mat_name,back_mat,material_thickness,unit,type_material,file_name,list_of_comp,list_of_components,list_of_components_all,false,false,false) if !ent.hidden? }
            end
            sheet_size = ""
            mat_grained = "true"
            @param_mat.each { |mat| 
              if mat[0].include?(mat_name) && mat[1].include?(material_thickness)
                sheet_size = mat[2].gsub("х","x")
                mat_grained = mat[3] if mat[3]
              end
            }
            @mat_ent_components[mat_a+"="+sheet_size+"="+mat_grained+"="+name_arr[0][0]+"="+name_arr[0][1]] = @ent_components
          }
          Export_Xml_DXF.import_comp(@prog,@mat_ent_components,Sketchup.active_model.title)
          Sketchup::set_status_text ""
        end
      end
    end
    def copyToClipboard(param_mat,prog) # оранжевая кнопка
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
        path_param = File.join(param_temp_path,"parameters.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
        path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
        else
        path_param = File.join(PATH,"parameters","parameters.dat")
      end
      content = File.readlines(path_param)
      @itemcode = "1"
      defaults = ["Cutting2"]
      content.each { |i| 
        defaults = [i.strip.split("=")[2]] if i.strip.split("=")[1] == "cut_prog"
        @itemcode = i.strip.split("=")[2] if i.strip.split("=")[1] == "ItemCode"
      }
      if prog == "Excel"
        input = ["Excel"]
        else
        prompts = [SUF_STRINGS["Export"]+" "+SUF_STRINGS["to the program"]+": "]
        list = ["Astra|Cutting2|Cutting3|Cutting Optimization|ВиЯр|Quadro|Excel|#{SUF_STRINGS["List of fronts"]}|Bazis|GibLab|DXF"]
        input = UI.inputbox prompts, defaults, list, ""
      end
      if input
        prog = input[0]
        param_file = File.new(path_param,"w")
        content.each{|i|
          if i.split("=")[1] == "cut_prog"
            param_file.puts "Программа раскроя по умолчанию=cut_prog="+(prog == "Excel" ? defaults[0] : input[0])+"=SELECT=&Astra^Astra&Cutting2^Cutting2&Cutting3^Cutting3&Cutting Optimization^Cutting Optimization&ВиЯр^ВиЯр&Quadro^Quadro&Excel^Excel&Bazis^Bazis&GibLab^GibLab&DXF^DXF"
            else
            param_file.puts i
          end
        }
        param_file.close
        
        order_number = Sketchup.active_model.get_attribute("suf","order_number")
        mat_number = "1"
        order_number = "1" if !order_number
        if input[0] == "Cutting3"
          mat_param = UI.inputbox ["#{SUF_STRINGS["Material number"]} ","#{SUF_STRINGS["Order number"]} "], [mat_number,order_number], SUF_STRINGS["Parameters for Cutting3"]
          if mat_param
            mat_number = mat_param[0] 
            order_number = mat_param[1]
            Sketchup.active_model.set_attribute("suf","order_number",order_number)
          end
        end
        
        @row = []
        list_list_js = PATH + "/html/cont/list_list.txt"
        file = File.new(list_list_js,"w")
        @holes = {}
        @mat_ent_components = {}
        param_mat.each { |mat_a|
          @ent_components = {}
          @add_work = []
          material_type = mat_a.split("=")[0]
          su_type_list = [material_type]
          mat_name = mat_a.split("=")[1]
          path_name,file_name = search(mat_name)
          back_mat = mat_a.split("=")[2]
          material_thickness = mat_a.split("=")[3]
          unit = mat_a.split("=")[4]
          mat_a.split("=")[5] ? type_material = mat_a.split("=")[5] : type_material = ""
          mat_a.split("=")[6] ? max_width_of_count = "" : max_width_of_count = "=0"
          mat_grained = "true"
          @param_mat.each { |mat| mat_grained = mat[3] if mat[3] && mat[0].include?(mat_name) && mat[1].include?(material_thickness) }
          row = []
          list_of_comp = []
          list_of_components = []
          @list_components_mat = []
          list_of_components_all = []
          @ent = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a
          @ent = @ent.sort_by { |ent| ent.definition.get_attribute("dynamic_attributes", "itemcode", "0") }
          @sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
          sel_parent = "model"
          sel_parent = "no model" if @sel[0] && !@sel[0].parent.is_a?(Sketchup::Model)
          @sel.length == 0 ? sel = @ent : sel = @sel
          @z1_type,@z2_type,@y1_type,@y2_type = nil
          if @frontal_carcass_mat.include?(mat_a+max_width_of_count)
            sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,["carcass","frontal"],mat_name,back_mat,material_thickness,unit,type_material,file_name,list_of_comp,list_of_components,list_of_components_all,false,false,true) if !ent.hidden? }
            else
            sel.each { |ent| component_list(Geom::Transformation.new,false,false,(!ent.parent.is_a?(Sketchup::Model) || sel_parent == "no model") ? ent.definition.name.split("#")[0] : ent.definition.name,ent,su_type_list,mat_name,back_mat,material_thickness,unit,type_material,file_name,list_of_comp,list_of_components,list_of_components_all,false,false,false) if !ent.hidden? }
          end
          sheet_size = ""
          mat_grained = "true"
          @param_mat.each { |mat| 
            if mat[0].include?(mat_name) && mat[1].include?(material_thickness)
              sheet_size = mat[2]
              mat_grained = mat[3] if mat[3]
            end
          }
          @mat_ent_components[mat_a+"="+sheet_size+"="+mat_grained+"="+mat_name+"="] = @ent_components
          list_of_components = list_of_components.sort_by {|comp| [(comp[5]=="" ? "яяя" : comp[5]),comp[4],9999-comp[6].to_f]	}
          list_of_components.each.with_index { |comp,index|  @list_components_mat = @list_components_mat.push([index+1] + comp) }
          list_of_components_all = list_of_components_all.push([mat_a] + [@list_components_mat])
          list_list(mat_name,back_mat,material_thickness,unit,type_material,list_of_components_all)
          list_of_comp = @list_components_mat.sort
          row_excel = SUF_STRINGS["material"]+"	"+SUF_STRINGS["Group"]+"	"+(@itemcode == "1" ? SUF_STRINGS["name"]+"-"+SUF_STRINGS["itemcode"] : (@itemcode == "1" ? SUF_STRINGS["itemcode"]+"-"+SUF_STRINGS["name"] : SUF_STRINGS["itemcode"]+"."+SUF_STRINGS["name"]))+"	"+SUF_STRINGS["length"]+"	"+SUF_STRINGS["width"]+"	"+SUF_STRINGS["count"]+"	"+SUF_STRINGS["thickness"]
          if input[0] == "Bazis"
            Export_Xml_DXF.import_comp(input[0],@mat_ent_components,"false")
            elsif input[0] == "GibLab"
            Export_Xml_DXF.import_comp(input[0],@mat_ent_components,"false") 
            elsif input[0] == "DXF"
            Export_Xml_DXF.import_comp(input[0],@mat_ent_components,mat_name)
            else
            list_of_comp.each { |i|
              if i[1].to_s.include?(mat_name)
                number = i[0].to_s
                mat = i[1].to_s
                mat.rindex("_") == mat.length-2 || mat.rindex("_") == mat.length-3 || mat.rindex("_") == mat.length-4 || mat.rindex("_") == mat.length-5 ? mat = mat[0..mat.rindex("_")-1] : mat = mat
                thickness = i[3].to_s
                unit = i[4].to_s
                name = i[5].to_s
                item_code = i[6].to_s
                if @itemcode == "1"
                  name += "-" + item_code if item_code && item_code != ""
                  elsif @itemcode == "2"
                  name = item_code+"-"+name if item_code && item_code != ""
                  else
                  name = item_code+"."+name if item_code && item_code != ""
                end
                if @lists_panel_size == "Готовые с кромкой"
                  width = i[7].to_s
                  height = i[9].to_s
                  else
                  width = i[8].to_s
                  height = i[10].to_s
                end
                count = i[11].to_s
                rotate = i[12].to_s
                z1 = i[13].to_s
                z2 = i[15].to_s
                y1 = i[19].to_s
                y2 = i[17].to_s
                group = i[21].to_s
                if z1 == "0"
                  k_up_astra = "- нет кромки -"
                  k_up_cut3 = "false"
                  k_up_cut3_name = "-"
                  k_up_quadro = ""
                  k_up_excel = ""
                  else
                  k_up_astra = z1
                  k_up_cut3 = "true"
                  k_up_cut3_name = z1
                  k_up_quadro = z1
                  if z1.to_f > 1
                    k_up_excel = @edge_symbol["6"]
                    elsif z1.to_f > 0.6
                    k_up_excel = @edge_symbol["4"]
                    else
                    k_up_excel = @edge_symbol["2"]
                  end
                end
                if z2 == "0"
                  k_down_astra = "- нет кромки -"
                  k_down_cut3 = "false"
                  k_down_cut3_name = "-"
                  k_down_quadro = ""
                  k_down_excel = ""
                  else
                  k_down_astra = z2
                  k_down_cut3 = "true"
                  k_down_cut3_name = z2
                  k_down_quadro = z2
                  if z2.to_f > 1
                    k_down_excel = @edge_symbol["6"]
                    elsif z2.to_f > 0.6
                    k_down_excel = @edge_symbol["4"]
                    else
                    k_down_excel = @edge_symbol["2"]
                  end
                end
                if y1 == "0"
                  k_left_astra = "- нет кромки -"
                  k_left_cut3 = "false"
                  k_left_cut3_name = "-"
                  k_left_quadro = ""
                  k_left_excel = ""
                  else
                  k_left_astra = y1
                  k_left_cut3 = "true"
                  k_left_cut3_name = y1
                  k_left_quadro = y1
                  if y1.to_f > 1
                    k_left_excel = @edge_symbol["6"]
                    elsif y1.to_f > 0.6
                    k_left_excel = @edge_symbol["4"]
                    else
                    k_left_excel = @edge_symbol["2"]
                  end
                end
                if y2 == "0"
                  k_right_astra = "- нет кромки -"
                  k_right_cut3 = "false"
                  k_right_cut3_name = "-"
                  k_right_quadro = ""
                  k_right_excel = ""
                  else
                  k_right_astra = y2
                  k_right_cut3 = "true"
                  k_right_cut3_name = y2
                  k_right_quadro = y2
                  k_right_excel = "/"
                  if y2.to_f > 1
                    k_right_excel = @edge_symbol["6"]
                    elsif y2.to_f > 0.6
                    k_right_excel = @edge_symbol["4"]
                    else
                    k_right_excel = @edge_symbol["2"]
                  end
                end
                k_up,k_up_color,viyar_up = cut2_edge(z1)
                k_down,k_down_color,viyar_down = cut2_edge(z2)
                k_left,k_left_color,viyar_left = cut2_edge(y1)
                k_right,k_right_color,viyar_right = cut2_edge(y2)
                rotate = "1" if mat_grained == "false"
                case input[0]
                  when "Astra" then row << number+"	"+width+"	"+height+"	"+count+"	"+rotate+"	"+thickness+"	"+mat+"	"+name+"	"+k_up_astra+"	"+k_down_astra+"	"+k_left_astra+"	"+k_right_astra
                  when "Cutting2" then row << width+"	"+height+"	"+count+"	"+name.gsub(" ","•")+"	"+mat.gsub(" ","•")+"	"+rotate+"	"+"0"+"	"+k_left_color+"	"+k_right_color+"	"+k_up_color+"	"+k_down_color+"	"+k_left+"	"+k_right+"	"+k_up+"	"+k_down
                  when "Cutting3" then row << mat_number+"	"+width+"	"+height+"	"+count+"	"+rotate+"	"+"кромка"+"	"+k_left_cut3+"	"+k_up_cut3+"	"+k_right_cut3+"	"+k_down_cut3+"	"+"False"+"	"+"№"+order_number+"	"+name.gsub(" ","•")+"	"+"D"+"	"+k_left_cut3_name+"	"+k_up_cut3_name+"	"+k_right_cut3_name+"	"+k_down_cut3_name
                  when "Cutting Optimization" then row << width+"	"+height+"	"+count+"	"+mat+"	"+rotate+"	"+name+"	"+z1+"	"+y1+"	"+z2+"	"+y2
                  when "Аконто-М" then row << width+"	"+height+"	"+count+"	"+(z1=="0" ? "" : "ПВХ")+"	"+(y1=="0" ? "" : "ПВХ")+"	"+(z2=="0" ? "" : "ПВХ")+"	"+(y2=="0" ? "" : "ПВХ")+"	"+name+"	"+(rotate=="1" ? "УДАЛИТЬ ЕСЛИ ДЕТАЛЬ НЕ ВРАЩАЕТСЯ" : "")
                  when "#{SUF_STRINGS["List of fronts"]}" then row << width+"	"+height+"	"+count
                  when "ВиЯр" then row << width+"	"+height+"	"+count+"	"+viyar_up+"	"+viyar_down+"	"+viyar_left+"	"+viyar_right+"	"+(rotate=="0" ? "1":"0")+"	"+name+"	"+"1"
                  when "Quadro" then row << number+"	"+width+"	"+height+"	"+count+"	"+k_up_quadro+"	"+k_down_quadro+"	"+k_left_quadro+"	"+k_right_quadro+"	"+""+"	"+name+"	"+(rotate=="1" ? "V" : "")
                  when "Excel" then row << mat+"	"+group+"	"+name+"	"+width+k_up_excel+k_down_excel+"	"+height+k_left_excel+k_right_excel+"	"+count+"	"+thickness
                end
              end
            }
            if input && input[0] == "Excel"
              @row << [mat_a] + [row.unshift(row_excel)]
              else
              @row << [mat_a] + [row]
            end
          end
        }
        file.puts @row
        file.close
        if prog == "Excel"
          @row = [@row] + ["Excel"]
          else
          @row = [@row] + ["Cut"]
        end
        vend = @row
        command = "copy_board(#{vend.inspect})"
        $dlg_suf.execute_script(command)
      end
    end#def
  end #end Class
end #module
