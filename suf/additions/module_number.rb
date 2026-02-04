module SU_Furniture
  class ModuleNumber
    def read_param
      if File.file?(File.join(TEMP_PATH, "SUF", "module_number.dat"))
        path_param = File.join(TEMP_PATH, "SUF", "module_number.dat")
        else
        path_param = File.join(PATH, "parameters", "module_number.dat")
      end
      param_file = File.new(path_param,"r")
      content = param_file.readlines
      param_file.close
			@param_hash["view_common"] = SUF_STRINGS["Yes"] if !@param_hash["view_common"]
      @param_hash["view_number"] = SUF_STRINGS["Before module"] if !@param_hash["view_number"]
			@param_hash["offset_z"] = "0" if !@param_hash["offset_z"]
			@param_hash["newline_space"] = SUF_STRINGS["No"] if !@param_hash["newline_space"]
      content.each { |cont| @param_hash[cont.split("=")[0]] = cont.split("=")[1].strip}
    end
    def save_param(input)
      @param_hash["numbering_type"] = input[0]
      @param_hash["end_to_end_numbering"] = input[1]
      @param_hash["sorting_method"] = input[2]
      @param_hash["sorting_type"] = input[3]
      @param_hash["common_prefix"] = input[4]
			@param_hash["view_common"] = input[5]
      @param_hash["down_prefix"] = input[6]
      @param_hash["upper_prefix"] = input[7]
      @param_hash["upper_z"] = input[8]
      @param_hash["antresol_prefix"] = input[9]
      @param_hash["antresol_z"] = input[10]
      @param_hash["write_type"] = input[11]
      @param_hash["view_number"] = input[12]
      @param_hash["color_of_number"] = input[13]
      @param_hash["height_of_number"] = input[14]
			@param_hash["offset_z"] = input[15]
      @param_hash["begin_number"] = input[16]
			@param_hash["newline_space"] = input[17]
      path_param = TEMP_PATH+"/SUF/module_number.dat"
      param_file = File.new(path_param,"w")
      @param_hash.each{|key,value| param_file.puts key+"="+value }
      param_file.close
    end
    def add_number
      @number_to_letter = (1..26).zip('a'..'z').to_h
      @model = Sketchup.active_model
      @param_hash = {}
      @param_hash["begin_number"] = "1"
      read_param
      prompts = ["#{SUF_STRINGS["Numbering type"]} ","#{SUF_STRINGS["Continuous numbering"]} ","#{SUF_STRINGS["Sorting method"]} ","#{SUF_STRINGS["Module order"]} ","#{SUF_STRINGS["General prefix"]} ","#{SUF_STRINGS["Show general prefix"]} ","#{SUF_STRINGS["Lower units prefix"]} ","#{SUF_STRINGS["Upper units prefix"]} ","#{SUF_STRINGS["Upper from floor"]} (#{SUF_STRINGS["mm"]}) ","#{SUF_STRINGS["Overhead units prefix"]} ","#{SUF_STRINGS["Overhead from floor"]} (#{SUF_STRINGS["mm"]}) ","#{SUF_STRINGS["Save to"]} ","#{SUF_STRINGS["Show code"]} ","#{SUF_STRINGS["Code color"]} ","#{SUF_STRINGS["Code size"]} ","#{SUF_STRINGS["Height offset"]} ","#{SUF_STRINGS["Starting number"]} ","#{SUF_STRINGS["Newline instead of symbol"]} "]
      if @model.selection.grep(Sketchup::ComponentInstance).to_a.empty? && @param_hash["sorting_method"] == SUF_STRINGS["In selection order"]
        @param_hash["sorting_method"] = SUF_STRINGS["Clockwise"]
      end
      defaults = [@param_hash["numbering_type"],@param_hash["end_to_end_numbering"],@param_hash["sorting_method"],@param_hash["sorting_type"],@param_hash["common_prefix"],@param_hash["view_common"],@param_hash["down_prefix"],@param_hash["upper_prefix"],@param_hash["upper_z"],@param_hash["antresol_prefix"],@param_hash["antresol_z"],@param_hash["write_type"],@param_hash["view_number"],@param_hash["color_of_number"],@param_hash["height_of_number"],@param_hash["offset_z"],@param_hash["begin_number"],@param_hash["newline_space"]]
      lists = ["#{SUF_STRINGS["Current module code"]}|1,2,3...|01,02,03...|a,b,c...|aa,ab,ac...","#{SUF_STRINGS["No"]}|#{SUF_STRINGS["Yes"]}","#{SUF_STRINGS["From corner"]}|#{SUF_STRINGS["Left to right"]}|#{SUF_STRINGS["Clockwise"]}","#{SUF_STRINGS["Bottom to top"]}|#{SUF_STRINGS["Top to bottom"]}","","#{SUF_STRINGS["No"]}|#{SUF_STRINGS["Yes"]}","","","","","","#{SUF_STRINGS["Product code"]}|#{SUF_STRINGS["Component name"]}|#{SUF_STRINGS["Everywhere"]}","#{SUF_STRINGS["No"]}|#{SUF_STRINGS["Before module"]}|#{SUF_STRINGS["Above module"]}|#{SUF_STRINGS["Everywhere"]}","red|orange|yellow|green|blue|purple|white|black","1|2|3|4|5","","","#{SUF_STRINGS["No"]}|#{SUF_STRINGS["All spaces"]}|#{SUF_STRINGS["First space"]}|#{SUF_STRINGS["Last space"]}|#{SUF_STRINGS["All dots"]}|#{SUF_STRINGS["First dot"]}|#{SUF_STRINGS["Last dot"]}"]
      
      number_of_selection = "false"
      if @model.selection.grep(Sketchup::ComponentInstance).to_a.length > 0
        prompts = ["#{SUF_STRINGS["Number selected"]} "] + prompts
        defaults = [SUF_STRINGS["Yes"]] + defaults
        lists[2] += "|#{SUF_STRINGS["In selection order"]}"
        lists = ["#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["All"]}"] + lists
        number_of_selection = "true"
      end
      
      input = UI.inputbox(prompts, defaults, lists, SUF_STRINGS["Parameters"])
      if input
        if number_of_selection == "true"
          number_of_selection = input[0]
          input = input[1..-1]
        end
        if input[8].to_i < 500
          UI.messagebox(SUF_STRINGS["Upper modules must be more than 500 mm above the floor"])
          input[8] = "500"
          return
          elsif input[10].to_i <= input[8].to_i
          UI.messagebox(SUF_STRINGS["Overhead units must be above Upper units from the floor"])
          input[10] = (input[8].to_i+300).to_s
          return
        end
        
        save_param(input)
        
        @model.start_operation "Module number", true
        down_module_array = []
        upper_module_array = []
        antresol_module_array = []
        all_bounds = Geom::BoundingBox.new
        bounds_arr = []
        
        if number_of_selection == SUF_STRINGS["Yes"]
          entities_array = $SUFSelectionObserver.selected
          else
          entities_array = @model.entities.grep(Sketchup::ComponentInstance).to_a
        end
        
        entities_array.each { |ent|
          delete_module_numbers(ent)
          if ent.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module"
            ent.make_unique
            all_bounds.add ent.bounds
            bounds_arr << ent.bounds
            if ent.transformation.origin.z < @param_hash["upper_z"].to_f/25.4
              down_module_array << ent
              elsif ent.transformation.origin.z < @param_hash["antresol_z"].to_f/25.4
              upper_module_array << ent
              else
              antresol_module_array << ent
            end
          end
        }
        
        zero_vector = Geom::Vector3d.new(0,-1,0)
        if !intersect_bounds(all_bounds,bounds_arr,-1000,0)
          zero_vector = Geom::Vector3d.new(-1,0,0)
          elsif !intersect_bounds(all_bounds,bounds_arr,1000,0)
          zero_vector = Geom::Vector3d.new(1,0,0)
          elsif !intersect_bounds(all_bounds,bounds_arr,0,1000)
          zero_vector = Geom::Vector3d.new(0,1,0)
          elsif !intersect_bounds(all_bounds,bounds_arr,0,-1000)
          zero_vector = Geom::Vector3d.new(0,-1,0)
        end
        case @param_hash["sorting_method"]
          when SUF_STRINGS["In selection order"]
          
          when SUF_STRINGS["Left to right"]
          down_module_array.sort! { |a, b| [a.bounds.max.y,a.bounds.max.x] <=> [b.bounds.max.y,b.bounds.max.x] }
          upper_module_array.sort! { |a, b| [a.bounds.max.y,a.bounds.max.x] <=> [b.bounds.max.y,b.bounds.max.x] }
          antresol_module_array.sort! { |a, b| [a.bounds.max.y,a.bounds.max.x] <=> [b.bounds.max.y,b.bounds.max.x] }
          when SUF_STRINGS["Clockwise"]
          down_module_array.sort! { |a, b| [angle_in_plane(all_bounds.center - b.bounds.center,zero_vector)] <=> [angle_in_plane(all_bounds.center - a.bounds.center,zero_vector)] }
          upper_module_array.sort! { |a, b| [angle_in_plane(all_bounds.center - b.bounds.center,zero_vector)] <=> [angle_in_plane(all_bounds.center - a.bounds.center,zero_vector)] }
          antresol_module_array.sort! { |a, b| [angle_in_plane(all_bounds.center - b.bounds.center,zero_vector)] <=> [angle_in_plane(all_bounds.center - a.bounds.center,zero_vector)] }
          when SUF_STRINGS["From corner"]
          down_module_array.sort! { |a, b| [distance_to_origin(all_bounds,a.bounds.max),a.bounds.max.x,a.bounds.max.y] <=> [distance_to_origin(all_bounds,b.bounds.max),b.bounds.max.x,b.bounds.max.y] }
          upper_module_array.sort! { |a, b| [distance_to_origin(all_bounds,a.bounds.max),a.bounds.max.x,a.bounds.max.y] <=> [distance_to_origin(all_bounds,b.bounds.max),b.bounds.max.x,b.bounds.max.y] }
          antresol_module_array.sort! { |a, b| [distance_to_origin(all_bounds,a.bounds.max),a.bounds.max.x,a.bounds.max.y] <=> [distance_to_origin(all_bounds,b.bounds.max),b.bounds.max.x,b.bounds.max.y] }
        end
        
        module_index = @param_hash["begin_number"].to_i
        if @param_hash["sorting_type"] == SUF_STRINGS["Bottom to top"]
          down_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["down_prefix"]) } if down_module_array != []
          module_index = 1 if @param_hash["end_to_end_numbering"] == SUF_STRINGS["No"] && @param_hash["upper_prefix"] != ""
          upper_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["upper_prefix"]) } if upper_module_array != []
          module_index = 1 if @param_hash["end_to_end_numbering"] == SUF_STRINGS["No"] && @param_hash["antresol_prefix"] != ""
          antresol_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["antresol_prefix"]) } if antresol_module_array != []
          else
          antresol_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["antresol_prefix"]) } if antresol_module_array != []
          module_index = 1 if @param_hash["end_to_end_numbering"] == SUF_STRINGS["No"] && @param_hash["upper_prefix"] != ""
          upper_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["upper_prefix"]) } if upper_module_array != []
          module_index = 1 if @param_hash["end_to_end_numbering"] == SUF_STRINGS["No"] && @param_hash["down_prefix"] != ""
          down_module_array.each_with_index { |ent,index| module_index += module_number(ent,module_index,@param_hash["down_prefix"]) } if down_module_array != []
        end
        @model.commit_operation
        end
      end
      def delete_module_numbers(ent)
      ent.definition.entities.grep(Sketchup::Group).each { |g| g.erase! if g.name == "module_number"}
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| delete_module_numbers(e) }
    end
    def angle_in_plane(vector1, vector2, normal = Z_AXIS)
      Math.atan2((vector2 * vector1) % normal, vector1 % vector2)
    end
    def intersect_bounds(all_bounds,bounds_arr,x,y)
      bounds = Geom::BoundingBox.new
      point1 = Geom::Point3d.new(all_bounds.center.x,all_bounds.center.y, 0)
      point2 = Geom::Point3d.new(all_bounds.center.x,all_bounds.center.y, 300)
      point3 = Geom::Point3d.new(all_bounds.center.x+x,all_bounds.center.y+y, 0)
      point4 = Geom::Point3d.new(all_bounds.center.x+x,all_bounds.center.y+y, 300)
      bounds.add(point1,point2,point3,point4)
      bounds_arr.any?{|bb| !bb.intersect(bounds).empty? }
    end
    def distance_to_origin(all_bounds,point)
      distance = point.distance Geom::Point3d.new(all_bounds.min.x,all_bounds.max.y,point.z)
    end
    def module_number(ent,index,prefix)
      if @param_hash["numbering_type"] == SUF_STRINGS["Current module code"]
        if ent.definition.get_attribute("dynamic_attributes", "a04_itemcode")
          index_str = ent.definition.get_attribute("dynamic_attributes", "a04_itemcode")
          elsif ent.definition.get_attribute("dynamic_attributes", "itemcode")
          index_str = ent.definition.get_attribute("dynamic_attributes", "itemcode")
        end
        if @param_hash["view_number"] != SUF_STRINGS["No"]
				  a05_in_front = ent.definition.get_attribute("dynamic_attributes", "a05_in_front")
					if a05_in_front && a05_in_front != ""
					  str = a05_in_front
					  else
						str = index_str
          end
          view_number(ent,index_str,@param_hash["newline_space"],@param_hash["height_of_number"],@param_hash["offset_z"],@param_hash["view_number"],@param_hash["color_of_number"])
        end
        else
        if @param_hash["numbering_type"] == "aa,ab,ac..."
          index_str = @number_to_letter[(index > 26 ? (index/26).floor+1 : 1)] + @number_to_letter[(index%26.1).round]
          elsif @param_hash["numbering_type"] == "a,b,c..."
          index_str = @number_to_letter[(index%26.1).round]
          index_str = @number_to_letter[(index/26).floor] + index_str if index > 26
          elsif @param_hash["numbering_type"] == "01,02,03..."
          index < 10 ? index_str = "0"+index.to_s : index_str = index.to_s
          else
          index_str = index.to_s
        end
        if @param_hash["write_type"] == SUF_STRINGS["Product code"]
          write_itemcode(ent,@param_hash["common_prefix"]+prefix+index_str)
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| redraw_panel(e,@param_hash["common_prefix"]+prefix+index_str) }
          elsif @param_hash["write_type"] == SUF_STRINGS["Component name"]
          ent.definition.name = @param_hash["common_prefix"]+prefix+index_str if ent.definition.name != @param_hash["common_prefix"]+prefix+index_str
          else
          write_itemcode(ent,@param_hash["common_prefix"]+prefix+index_str)
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| redraw_panel(e,@param_hash["common_prefix"]+prefix+index_str) }
          ent.definition.name = @param_hash["common_prefix"]+prefix+index_str if ent.definition.name != @param_hash["common_prefix"]+prefix+index_str
        end
				
				if @param_hash["view_number"] != SUF_STRINGS["No"]
				  if @param_hash["view_common"] == SUF_STRINGS["Yes"]
					  ent.set_attribute("dynamic_attributes", "a05_in_front", @param_hash["common_prefix"]+prefix+index_str)
					  ent.definition.set_attribute("dynamic_attributes", "a05_in_front", @param_hash["common_prefix"]+prefix+index_str)
					  ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_label", "a05_in_front")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_units", "STRING")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_formulaunits", "STRING")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_formlabel", SUF_STRINGS["Code before module"])
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_access", "TEXTBOX")
						str = @param_hash["common_prefix"]+prefix+index_str
						else
						ent.set_attribute("dynamic_attributes", "a05_in_front", prefix+index_str)
					  ent.definition.set_attribute("dynamic_attributes", "a05_in_front", prefix+index_str)
					  ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_label", "a05_in_front")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_units", "STRING")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_formulaunits", "STRING")
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_formlabel", SUF_STRINGS["Code before module"])
						ent.definition.set_attribute("dynamic_attributes", "_a05_in_front_access", "TEXTBOX")
						str = prefix+index_str
          end
					view_number(ent,str,@param_hash["newline_space"],@param_hash["height_of_number"],@param_hash["offset_z"],@param_hash["view_number"],@param_hash["color_of_number"])
        end
      end
      return 1
    end
    def view_number(ent,str,newline_space,height_of_number,offset,view_number,color_of_number)
      number_layer = @model.layers.add("0_Код_модуля")
      number_group = ent.definition.entities.add_group
      coef_x = 1
      offset_x = 0
      offset_y = 0
      rotate_z = 0
			count = 1
			case newline_space
			  when SUF_STRINGS["All spaces"] then str = str.gsub(" ","\n")
				when SUF_STRINGS["First space"] then str = str.sub(" ","\n")
				when SUF_STRINGS["Last space"] then str = str.sub(/.*\K /,"\n")
				when SUF_STRINGS["All dots"] then str = str.gsub(".","\n")
				when SUF_STRINGS["First dot"] then str = str.sub(".","\n")
				when SUF_STRINGS["Last dot"] then str = str.sub(/.*\K\./,"\n")
      end
			count = str.count("\n")+1
      number_group.definition.entities.add_3d_text(str, TextAlignCenter, "Arial", false, false, height_of_number.to_f)
      
      lenx = ent.definition.get_attribute("dynamic_attributes", "lenx", "0").to_f
      leny = ent.definition.get_attribute("dynamic_attributes", "leny", "0").to_f
      lenz = ent.definition.get_attribute("dynamic_attributes", "lenz", "0").to_f
      a1_leg = ent.definition.get_attribute("dynamic_attributes", "a1_leg", "0").to_f
			c4_plint = ent.definition.get_attribute("dynamic_attributes", "c4_plint", "1").to_f
			c4_plint_size = ent.definition.get_attribute("dynamic_attributes", "c4_plint_size", "0").to_f
			c4_plint_size = 0 if c4_plint < 2
      
      cut_size = ent.definition.get_attribute("dynamic_attributes", "cut_size")
      cut_size_x = ent.definition.get_attribute("dynamic_attributes", "cut_size_x")
      a00_fix_planka = ent.definition.get_attribute("dynamic_attributes", "a00_fix_planka")
      
      if cut_size || cut_size_x
        b2_lr_type = ent.definition.get_attribute("dynamic_attributes", "b2_lr_type")
        
        if b2_lr_type == "2"
          offset_x += ent.definition.get_attribute("dynamic_attributes", "a00_f_lenx_r", 0)/2
          if !a00_fix_planka
            if cut_size
              offset_x += ent.definition.get_attribute("dynamic_attributes", "cut_size", 0).to_f/5.08-2.6
              offset_y += ent.definition.get_attribute("dynamic_attributes", "cut_size", 0).to_f/5.08-2.6
              elsif cut_size_x
              offset_x += ent.definition.get_attribute("dynamic_attributes", "cut_size_x", 0).to_f/5.08-2.6
              offset_y += ent.definition.get_attribute("dynamic_attributes", "cut_size_y", 0).to_f/5.08-2.6
            end
            rotate_z = 45
          end
          coef_x = -1 if lenx < 0
          pos_x = coef_x*lenx-offset_x-number_group.bounds.max.x/2
          
          elsif b2_lr_type == "1"
          offset_x += ent.definition.get_attribute("dynamic_attributes", "a00_f_lenx_r", 0)/2
          coef_x = -1
          pos_x = -lenx+offset_x-number_group.bounds.max.x/2
          if !a00_fix_planka
            if cut_size
              offset_x += ent.definition.get_attribute("dynamic_attributes", "cut_size", 0).to_f/5.08-4
              offset_y += ent.definition.get_attribute("dynamic_attributes", "cut_size", 0).to_f/5.08
              elsif cut_size_x
              offset_x += ent.definition.get_attribute("dynamic_attributes", "cut_size_x", 0).to_f/5.08-2.6
              offset_y += ent.definition.get_attribute("dynamic_attributes", "cut_size_y", 0).to_f/5.08+2.6
            end
            pos_x = offset_x+number_group.bounds.max.x/2-(lenx > 0 ? lenx : 0)
            rotate_z = -45
          end
        end
        
        else
        pos_x = (lenx-number_group.bounds.max.x)/2
      end
      
      #p ent.definition.name
        #p lenx
        #p offset_y
      #p pos_x
			count==1 ? offset_z = 0 : offset_z = number_group.bounds.max.y/count
      bb = Geom::BoundingBox.new
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| bb.add e.bounds }
      r0_indent = ent.definition.get_attribute("dynamic_attributes", "r0_indent","0")
			offset_z += -offset.to_f/25.4
      if view_number == SUF_STRINGS["Before module"] || view_number == SUF_STRINGS["Everywhere"]
        front_number_group = number_group.copy
        front_number_group.name = "module_number"
        front_number_group.material = color_of_number
        front_number_group.layer = number_layer
        front_number_group.move!(Geom::Point3d.new(pos_x,bb.min.y-1,(lenz+c4_plint_size-front_number_group.bounds.max.z)/2+a1_leg-offset_z))
        front_number_group.transform!(Geom::Transformation.rotation(front_number_group.transformation.origin, Geom::Vector3d.new(1, 0, 0), 90.degrees))
        front_number_group.transform!(Geom::Transformation.rotation(front_number_group.transformation.origin, Geom::Vector3d.new(0, 0, 1), rotate_z.degrees))
      end
      if view_number == SUF_STRINGS["Above module"] || view_number == SUF_STRINGS["Everywhere"]
        top_number_group = number_group.copy
        top_number_group.name = "module_number"
        top_number_group.material = color_of_number
        top_number_group.layer = number_layer
        top_number_group.move!(Geom::Point3d.new(pos_x,(bb.min.y+bb.max.y-top_number_group.bounds.height)/2,lenz+c4_plint_size+a1_leg))
        top_number_group.transform!(Geom::Transformation.rotation(top_number_group.transformation.origin, Geom::Vector3d.new(0, 0, 1), rotate_z.degrees))
      end
      number_group.erase!
    end
    def write_itemcode(ent,itemcode)
      if ent.definition.get_attribute("dynamic_attributes", "a04_itemcode")
        ent.set_attribute("dynamic_attributes", "a04_itemcode", itemcode)
        ent.definition.set_attribute("dynamic_attributes", "a04_itemcode", itemcode)
        else
        ent.definition.delete_attribute("dynamic_attributes", "_itemcode_formula")
      end
      ent.set_attribute("dynamic_attributes", "itemcode", itemcode)
      ent.definition.set_attribute("dynamic_attributes", "itemcode", itemcode)
    end
    def redraw_panel(ent,itemcode)
      if !ent.hidden?
        if ent.definition.get_attribute("dynamic_attributes", "itemcode")
          if ent.definition.get_attribute("dynamic_attributes", "_itemcode_formula") == 'CONCATENATE(LOOKUP("itemcode"),".",a04_itemcode)'
            itemcode = itemcode+"."+ent.definition.get_attribute("dynamic_attributes", "a04_itemcode")
            elsif ent.definition.get_attribute("dynamic_attributes", "_itemcode_formula") == 'CONCATENATE(LOOKUP("itemcode"),"-",a04_itemcode)'
            itemcode = itemcode+"-"+ent.definition.get_attribute("dynamic_attributes", "a04_itemcode")
          end
          ent.set_attribute("dynamic_attributes", "itemcode", itemcode)
          ent.definition.set_attribute("dynamic_attributes", "itemcode", itemcode)
          if ent.definition.name.include?("Aventos HF")
            ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
              if e.definition.name.include?("Body")
                e.set_attribute("dynamic_attributes", "itemcode", itemcode)
                e.definition.set_attribute("dynamic_attributes", "itemcode", itemcode)
                e.definition.entities.grep(Sketchup::ComponentInstance).each { |essence|
                  if essence.definition.name.include?("Essence") || essence.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                    if essence.definition.get_attribute("dynamic_attributes", "_back_material_formula", "0") == 'CHOOSE(back_material_input,"White",Material)'
                      essence.definition.set_attribute("dynamic_attributes", "_back_material_formula", 'CHOOSE(LOOKUP("back_material_input",1),"White",Material,"White")')
                    end
                    Redraw_Components.run_all_formulas(essence)
                  end
                }
              end
            }
          end
        end
        ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| redraw_panel(e,itemcode) }
      end
    end
  end # class ModuleNumber
end # module SU_Furniture
