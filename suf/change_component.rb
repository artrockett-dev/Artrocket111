module SU_Furniture
  class ChangeComponents
    def list
      begin_time = Time.new
      content=[]
      folder_list=[]
      all_folder = []
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"component.dat"))
        path_param = File.join(param_temp_path,"component.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","component.dat"))
        path_param = File.join(TEMP_PATH,"SUF","component.dat")
        elsif File.file?(File.join(PATH_COMP,"component.dat"))
        path_param = File.join(PATH_COMP,"component.dat")
        else
        path_param = File.join(PATH,"parameters","component.dat")
      end
      content = File.readlines(path_param, chomp: true).reject { |c| c.empty? }
			content.map! {|i| i.force_encoding("UTF-8") if i.respond_to?(:force_encoding) }
      folder_list << 'var component_content = {'
      folder_list << '"CompSections": ['
      content.each_with_index{|folder,index|
				index==content.length-1 ? last = " " : last = ","
        name_alias = []
        name_alias=folder.split("=")
        name_alias[1] == nil ? name_alias[1] = '""' : name_alias[1] = name_alias[1].chomp
        folder_list << '{"name":"' + name_alias[0].gsub('"','') + '","alias":"' + name_alias[1].gsub('"','') +'"}' + last
      }                                                              
      folder_list << '],'
      folder_list << '"CompVendors": {'
      content.each_with_index{|folder,index|
				index==content.length-1 ? last = " " : last = ","
        name_alias = []
        name_alias=folder.split("=")
        name_alias[1] == nil ? name_alias[1] = '""' : name_alias[1] = name_alias[1].gsub('"','').chomp
        full_path_vendor = Dir.glob(File.join(PATH_COMP,name_alias[1],"*"))
        all_folder_vendor = full_path_vendor.select {|f| File.directory? f}
        all_folder.push(File.join(PATH_COMP,name_alias[1]))
        if all_folder_vendor.length == 0
          folder_list << '"' + name_alias[0].gsub('"','') + '":["' + name_alias[1].gsub('"','') + '"]' + last
          else
          all_folder_vendor = all_folder_vendor.map { |i| i.split(/[\/]/)[-2] + "/" + i.split(/[\/]/)[-1] }
          all_folder_vendor = all_folder_vendor.sort
          folder_list << '"' + name_alias[0].gsub('"','') + '":["' + name_alias[1].gsub('"','') + '","' + "#{all_folder_vendor.join('","')}" + '"]' + last
          all_folder_vendor.each { |vendor| all_folder.push(File.join(PATH_COMP,vendor.gsub("/","^"))) }
        end
      }                                                              
      folder_list << '},'
      folder_list << ' ' *2+'"full_path_comp": "'  + PATH_COMP + '",'
      folder_list << ' ' *2+'"components": {'
      all_image_files_count = 0
      all_folder.each_with_index{|folder,index|
				index==all_folder.length-1 ? last = " " : last = ","
        shot_folder = folder.split(/[\/]/)[-1].gsub('"','').gsub("^","/")
        image_files = File.join(folder.gsub('"','').gsub("^","/"),"*.{jpg,jpeg,png}")
        all_image_files = Dir.glob(image_files).map {|d| File.basename(d, "*.*")}.uniq.sort
        all_image_files_count+=all_image_files.length
        folder_list << ' ' *4 + '"'+"#{shot_folder}"+'":['+'"'+"#{all_image_files.join('","')}"+'"]' + last
      }
      folder_list << "}" 
      folder_list << "}"
      File.open(File.join(PATH, "html", "cont", "component_list.js"), "w") { |file|
        folder_list.each { |i| file.puts(i) }
      }
      #p "#{all_image_files_count} files processed in #{Time.new - begin_time} sec"
      return true
    end
    def search_mat(entity)
      if !entity.hidden?
        type = entity.definition.get_attribute("dynamic_attributes", "description", "0")
        if type.include?("Фасад") || type.include?("МДФ")
          mat_path = nil
          if entity.material
            mat_path = Change_Materials.search(entity.material.display_name)
          end
          @ldsp = true if mat_path && mat_path.include?("LDSP")
        end
        entity.definition.entities.grep(Sketchup::ComponentInstance){ |e| search_mat(e) }
      end
    end#def
    def replace_comp(ents,sel,new_comp,new_comp_place)
      ent = sel.grep(Sketchup::ComponentInstance)[0]
      all_att = {}
      dict = ent.definition.attribute_dictionary "dynamic_attributes"
      dict.each_pair { |attr, value| all_att[attr] = value }
      ent_transformation = ent.transformation
      sel.clear
      ents.erase_entities ent
      new_comp_place.transform! ent_transformation
      new_comp_dict = new_comp_place.definition.attribute_dictionary "dynamic_attributes"
      new_comp_dict.each_pair { |attr, value|
        if all_att[attr] && attr[0..1] != "z_"
          new_comp_place.definition.set_attribute("dynamic_attributes", attr, all_att[attr])
          new_comp_place.set_attribute("dynamic_attributes", attr, all_att[attr])
        end
      }
			Redraw_Components.redraw_entities_with_Progress_Bar([new_comp_place])
      sel.add new_comp_place
    end
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
    def comp_from_dialog(action_name)
      @model = Sketchup.active_model
      sel = @model.selection
      ents = @model.entities
      df = @model.definitions
      @replace = false
      @att_arr = []
			@hinge_select = "yes"
      @purge_unused = "yes"
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      content = File.readlines(path_param)
      content.each { |i|
			  @hinge_select = i.strip.split("=")[2] if i.strip.split("=")[1] == "hinge_select"
        @purge_unused = i.strip.split("=")[2] if i.strip.split("=")[1] == "purge_unused"
        @metabox_max = i.strip.split("=")[2] if i.strip.split("=")[1] == "metabox_max"
        @tandembox_max = i.strip.split("=")[2] if i.strip.split("=")[1] == "tandembox_max"
        @legrabox_max = i.strip.split("=")[2] if i.strip.split("=")[1] == "legrabox_max"
      }
      if param_temp_path && File.file?(File.join(param_temp_path,"hinge.dat"))
				path_hinge = File.join(param_temp_path,"hinge.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","hinge.dat"))
				path_hinge = File.join(TEMP_PATH,"SUF","hinge.dat")
				else
				path_hinge = File.join(PATH,"parameters","hinge.dat")
      end
      hinges = File.readlines(path_hinge)
      @hinges = {}
      hinges.each { |hinge_arr|
        new_hinge = hinge_arr.split("<=>")
        hinges_hash = {}
        new_hinge[1..-1].each{|hinge|
          hinge_names = hinge.split("=")[1..-1].each_slice(2).to_a
          hinges_hash[hinge.split("=")[0]] = hinge_names
        }
        @hinges[new_hinge[0]] = hinges_hash
      }
      param_comp = action_name.split('/')
      size_comp = param_comp.size
      change_for_type = param_comp[1]
      link = "SUF/" + param_comp[2].gsub("^","/") + "/"
      comp_name = param_comp[3].split(".")[0..-2].join(".")
      @replace = true if param_comp[4] == "replace"
      folder_comp = PATH_COMP+"/" + param_comp[2].gsub("^","/")
      if comp_name == "Без уст. и подкл."
        sel.grep(Sketchup::ComponentInstance).each { |e|
          for i in 1..20
            tech_services = e.definition.get_attribute("dynamic_attributes", "tech"+i.to_s+"_services")
            if tech_services
              e.set_attribute("dynamic_attributes", "tech"+i.to_s+"_services", 1)
              e.definition.set_attribute("dynamic_attributes", "tech"+i.to_s+"_services", 1)
            end
          end
        }
        else
        if (change_for_type.include? "Element")
          $add_component = 1
          ent = sel.grep(Sketchup::ComponentInstance)[0]
          if @replace && sel.grep(Sketchup::ComponentInstance).count == 1
					  @model.start_operation('Load component', true)
					  @model.layers.each { |l| l.visible = true  if l.name.include?("Направляющие") || l.name.include?("Размеры") }
            if Sketchup.version_number >= 2110000000
              new_comp = df.load(folder_comp + "/" + comp_name + ".skp", allow_newer: true)
              else
              new_comp = df.load(folder_comp + "/" + comp_name + ".skp")
            end
						@model.commit_operation
            result = UI.messagebox("#{SUF_STRINGS["Change"]} #{ent.definition.name} #{SUF_STRINGS["with"]} #{new_comp.name}?", MB_YESNO)
            if result == IDYES
						  @model.start_operation('Replace components', true,false,true)
              t = Geom::Transformation.translation [0, 0, 0]
              new_comp_place = ents.add_instance new_comp, t
              replace_comp(ents,sel,new_comp,new_comp_place)
              new_comp.instances.each { |instance| instance.make_unique if !instance.deleted? }
              @model.commit_operation
              else
              if Sketchup.version_number >= 2110000000
                Place_Component.import_comp_path(folder_comp + "/" + comp_name + ".skp")
                Sketchup.active_model.tools.push_tool( Place_Component )
                else
                @model.start_operation('Place component', true,false,true)
                place = @model.place_component new_comp
                new_comp.instances.each { |instance| instance.make_unique if !instance.deleted? }
                @model.commit_operation
              end
            end
            else
            if Sketchup.version_number >= 2110000000
              Place_Component.import_comp_path(folder_comp + "/" + comp_name + ".skp")
              Sketchup.active_model.tools.push_tool( Place_Component )
              else
              @model.start_operation('Place component', true)
              new_comp = df.load folder_comp + "/" + comp_name + ".skp"
              place = @model.place_component new_comp
              new_comp.instances.each { |instance| instance.make_unique if !instance.deleted? }
              @model.commit_operation
            end
          end
          else
          if sel.count == 0
            UI.messagebox(SUF_STRINGS["No Components Selected"])
            return nil
            else
						begin_time = Time.new
						@model.start_operation('Change components', true)
            if Sketchup.version_number >= 2110000000
              new_comp_slab = df.load(folder_comp + "/" + "Slab.skp", allow_newer: true) if File.exist?(File.join(folder_comp, "Slab.skp"))
              else
              new_comp_slab = df.load folder_comp + "/" + "Slab.skp" if File.exist?(File.join(folder_comp, "Slab.skp"))
            end
            if Sketchup.version_number >= 2110000000
              new_comp_up = df.load(folder_comp + "/" + comp_name + "Up.skp", allow_newer: true) if File.exist?(File.join(folder_comp, comp_name + "Up.skp"))
              else
              new_comp_up = df.load folder_comp + "/" + comp_name + "Up.skp" if File.exist?(File.join(folder_comp, comp_name + "Up.skp"))
            end
            new_comps = {}
						if comp_name.include?("Сушка")
              if Sketchup.version_number >= 2110000000
                (450..900).step(50) { |suffix|
                  filename = "#{folder_comp}/#{comp_name}_#{suffix}.skp"
                  new_comps["new_comp_#{suffix}"] = df.load(filename, allow_newer: true) if File.file?(filename)
                }
                else
                (450..900).step(50) { |suffix|
                  filename = "#{folder_comp}/#{comp_name}_#{suffix}.skp"
                  new_comps["new_comp_#{suffix}"] = df.load(filename) if File.file?(filename)
                }
              end
            end
            if Sketchup.version_number >= 2110000000
              new_comp = df.load(folder_comp + "/" + comp_name + ".skp", allow_newer: true)
              else
              new_comp = df.load folder_comp + "/" + comp_name + ".skp"
            end
						@model.commit_operation
            
            if change_for_type.include?("Frontal")
						  @model.start_operation('Change', true,false,true)
              component_name = new_comp.name.split("#")[0]
              param = 2
							@hinge_hash = {}
							@hinges_to_redraw = []
							@frontal_entities = []
							hinge_producers = []
							@hinges.each_pair{|type,hash|
								hash.each_key{|prod|
                  hinge_producers << prod if !hinge_producers.include?(prod)
                }
              }
              color_list = ["#{SUF_STRINGS["Silver"]}|#{SUF_STRINGS["Black"]}","#{SUF_STRINGS["No"]}|"+hinge_producers.join("|")]
              defaults = ["#{SUF_STRINGS["Black"]}","#{SUF_STRINGS["No"]}"]
              att_hash = {}
              change_hinges = nil
              if component_name.include?("Рамка")
                new_comp.entities.grep(Sketchup::ComponentInstance) { |enx|
                  if enx.definition.name.include?("Essence") || enx.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
                    if enx.definition.get_attribute("dynamic_attributes", "color_ramka")
                      value = enx.definition.get_attribute("dynamic_attributes", "color_ramka")
                      options = enx.definition.get_attribute("dynamic_attributes", "_color_ramka_options")
                      if options
                        att_list = js_unescape(options)[1..-2].split("&")
                        att_list.each {|list|att_hash[list.split("=")[0]] = list.split("=")[1]}
                        color_list = [att_hash.keys.join("|"),"#{SUF_STRINGS["No"]}|"+hinge_producers.join("|")]
                        defaults = [att_hash.key(value),"#{SUF_STRINGS["No"]}"]
                      end
                    end
                  end
                }
                prompts = ["#{SUF_STRINGS["Frame color"]} ","#{SUF_STRINGS["Change hinges"]} "]
                input = UI.inputbox prompts, defaults, color_list, SUF_STRINGS["Parameters"]
                return if !input
                param = att_hash[input[0]]
                change_hinges = input[1] if input[1] != SUF_STRINGS["No"]
              end			
              
              freza = {}
              param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
              if param_temp_path && File.file?(File.join(param_temp_path,"freza.dat"))
                path_param = File.join(param_temp_path,"freza.dat")
                elsif File.file?(File.join(TEMP_PATH,"SUF","freza.dat"))
                path_param = File.join(TEMP_PATH,"SUF","freza.dat")
                elsif File.file?(File.join(PATH_COMP,"freza.dat"))
                path_param = File.join(PATH_COMP,"freza.dat")
                else
                path_param = File.join(PATH,"parameters","freza.dat")
              end
              content = File.readlines(path_param, chomp: true).reject { |c| c.empty? }
              content.each { |i| freza[i.split("=")[0]] = i.strip.split("=")[1] }
              if freza[component_name]
                prompts = ["#{SUF_STRINGS["Milling"]} "]
                defaults = [freza[component_name].split("|")[0]]
                list = [freza[component_name]]
                param = UI.inputbox prompts, defaults, list, SUF_STRINGS["Front parameters"]
                sel.grep(Sketchup::ComponentInstance).each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) } if param
                elsif component_name.include?("Slab") || component_name.include?("Рамка")
                sel.grep(Sketchup::ComponentInstance).each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) }
                else
                @ldsp = false
                sel.grep(Sketchup::ComponentInstance).each { |e| search_mat(e) }
                if @ldsp == true
                  result = UI.messagebox("#{SUF_STRINGS["Selection contains chipboard fronts"]}! \n#{SUF_STRINGS["Apply milling and reset color"]}?", MB_YESNO)
                  if result == IDYES
                    param = 1
                    sel.grep(Sketchup::ComponentInstance).each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) }
                  end
                  else
                  sel.grep(Sketchup::ComponentInstance).each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) }
                end
              end
              df.purge_unused if @purge_unused == "yes"
              @model.commit_operation
              if change_hinges
                @model.start_operation('Change',true,false,true)
                sel.grep(Sketchup::ComponentInstance) { |e|
                  @item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "")
                  @b3_handle = e.definition.get_attribute("dynamic_attributes", "b3_handle", "1")
                  change_Hinge(e, change_hinges)
                }
                change_hinge_dialog()
              end
              
              elsif change_for_type.include?("Handle")
              @model.start_operation('Change', true,false,true)
              @hinge_hash = {}
              @hinges_to_redraw = []
              @frontal_entities = []
              handle_name = new_comp.name.split("#")[0]
              tip_on = false
              new_comp.entities.grep(Sketchup::ComponentInstance) { |enx|
                if enx.definition.name.include?("handle_body") && enx.definition.get_attribute("dynamic_attributes", "handle_type")
                  tip_on = true
                end
              }
              if handle_name[0..1] == "1_" || handle_name[0..1] == "2_" || handle_name[0..1] == "3_"
                handle_width = SUF_STRINGS["Do not change"]
                prompts = ["#{SUF_STRINGS["Handle article number"]} ","#{SUF_STRINGS["Handle size"]} "]
                defaults = [" ","#{SUF_STRINGS["Do not change"]}"]
                list = [" ","#{SUF_STRINGS["Do not change"]}|0|32|64|96|128|160|192|224|256|288|320|352|384|416|448|480"]
                input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Handle parameters"]
                if input
                  handle_a03_name = "#{SUF_STRINGS["Handle"]} "+input[0].gsub("/","_")
                  handle_a03_name = handle_a03_name[0..-2] if handle_a03_name[-1] == "_"
                  handle_width = input[1]
                  else
                  handle_a03_name = handle_name
                end
                elsif handle_name.include?("Tip") || tip_on
                prompts = ["#{SUF_STRINGS["Name"]} ","#{SUF_STRINGS["Type"]} ","#{SUF_STRINGS["Color"]} ","#{SUF_STRINGS["Manufacturer"]} "]
                defaults = ["Tip-on","#{SUF_STRINGS["recessed long"]}","#{SUF_STRINGS["white"]}","#{SUF_STRINGS["(Blum, Austria)"]}"]
                list = ["","#{SUF_STRINGS["recessed long"]}|#{SUF_STRINGS["recessed short"]}|#{SUF_STRINGS["with holder long"]}|#{SUF_STRINGS["with holder short"]}","#{SUF_STRINGS["white"]}|#{SUF_STRINGS["grey"]}|#{SUF_STRINGS["black"]}",""]
                
                new_comp.entities.grep(Sketchup::ComponentInstance) { |enx|
                  if enx.definition.name.include?("handle_body") && get_att(enx,"handle_type")
                    handle_name = get_att(enx,"handle_name")
                    handle_type_options = js_unescape(get_att(enx,"_handle_type_options")).split("&").reject(&:empty?).map{|str|str.split("=")[0]}
                    handle_color_options = js_unescape(get_att(enx,"_handle_color_options")).split("&").reject(&:empty?).map{|str|str.split("=")[0]}
                    prompts = [get_att(enx,"_handle_name_formlabel")+" ",get_att(enx,"_handle_type_formlabel")+" ",get_att(enx,"_handle_color_formlabel")+" ",get_att(enx,"_handle_prod_formlabel")+" "]
                    defaults = [get_att(enx,"handle_name"),get_att(enx,"handle_type"),get_att(enx,"handle_color"),get_att(enx,"handle_prod")]
                    list = ["",handle_type_options.join("|"),handle_color_options.join("|"),""]
                  end
                }
                
                input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Parameters"]
                if input
                  handle_a03_name = input[0]+" "+input[1]+", "+input[2]+" "+input[3].gsub("(","[").gsub(")","]")
                  else
                  return
                end
                else
                handle_a03_name = handle_name
                handle_width = false
              end
              @a03_name = []
              @old_name_tip_on = false
              sel.grep(Sketchup::ComponentInstance) { |e| change_Handle(e,new_comp,handle_a03_name,handle_width) }
              df.purge_unused if @purge_unused == "yes"
              @model.commit_operation
              hinge_producers = []
              @hinges.each_pair{|type,hash|
                hash.each_key{|prod|
                  hinge_producers << prod if !hinge_producers.include?(prod)
                }
              }
              change_hinges = nil
              if handle_name.include?("Tip") || tip_on
                input = UI.inputbox ["#{SUF_STRINGS["Change hinges"]} "], ["#{SUF_STRINGS["No"]}"], ["#{SUF_STRINGS["No"]}|#{SUF_STRINGS["Yes"]}"], SUF_STRINGS["Parameters"]
                change_hinges = handle_name if input && input[0] != "#{SUF_STRINGS["No"]}"
                elsif !handle_name.include?("Tip") && !tip_on && @old_name_tip_on
                input = UI.inputbox ["#{SUF_STRINGS["Change hinges"]} "], ["#{SUF_STRINGS["No"]}"], ["#{SUF_STRINGS["No"]}|"+hinge_producers.join("|")], SUF_STRINGS["Parameters"]
                change_hinges = input[0] if input && input[0] != "#{SUF_STRINGS["No"]}"
              end
              if change_hinges
                @model.start_operation('Change', true)
                sel.grep(Sketchup::ComponentInstance) { |e|
                  @item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "")
                  @b3_handle = e.definition.get_attribute("dynamic_attributes", "b3_handle", "1")
                  change_Hinge(e, change_hinges)
                }
                change_hinge_dialog()
              end
              
              elsif change_for_type.include?("Accessories")
              if param_comp[2].include?("Петл")
                @model.start_operation('Change', true,false,true)
                @hinge_hash = {}
                @hinges_to_redraw = []
                @frontal_entities = []
                sel.grep(Sketchup::ComponentInstance) { |e|
                  @item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "")
                  @b3_handle = e.definition.get_attribute("dynamic_attributes", "b3_handle", "1")
                  change_Hinge(e, comp_name)
                }
                change_hinge_dialog()
                elsif param_comp[2].include?("Ящик") || param_comp[2].include?("Корзин") && new_comp.name.include?("Сушк")
                @model.start_operation('Change', true,false,true)
                @b1_b_material = nil
                param_arr = nil
                new_comp.entities.grep(Sketchup::ComponentInstance) { |enx|
                  if enx.definition.get_attribute("dynamic_attributes", "d2_color")
                    value = enx.definition.get_attribute("dynamic_attributes", "d2_color")
                    options = enx.definition.get_attribute("dynamic_attributes", "_d2_color_options")
                    if options
                      att_hash = {}
                      att_list = js_unescape(options)[1..-2].split("&")
                      att_list.each {|list|att_hash[list.split("=")[0]] = list.split("=")[1]}
                      color_list = [att_hash.keys.join("|")]
                      defaults = [att_hash.key(value)]
                      input = UI.inputbox ["#{SUF_STRINGS["Side color"]} "], defaults, color_list, SUF_STRINGS["Parameters"]
                      return if !input
                      enx.definition.set_attribute("dynamic_attributes", "d2_color", att_hash[input[0]])
                      enx.set_attribute("dynamic_attributes", "d2_color", att_hash[input[0]])
                    end
                    elsif !param_arr && enx.definition.get_attribute("dynamic_attributes", "a1_motion_technology")
                    @att_arr = ["a1_motion_technology","a2_extension_type","a3_mounting_method","a4_weight","a6_producer","b2_skw_indent","b3_skl_indent","b4_height_corob_trim_z1","b4_height_corob_trim_z2","b4_niche_depth","b4_z_napr"]
                    prompts = []
                    defaults = []
                    list = []
                    opt_val = {}
                    val_opt = {}
                    @att_arr.each{|att|
                      prompts << enx.definition.get_attribute("dynamic_attributes", "_"+att+"_formlabel")
                      value = enx.definition.get_attribute("dynamic_attributes", att)
                      if enx.definition.get_attribute("dynamic_attributes", "_"+att+"_access")=="LIST"
                        options = enx.definition.get_attribute("dynamic_attributes", "_"+att+"_options")
                        options = js_unescape(options)[1..-2].split("&")
                        options.each{|opt|
                          opt_val[opt.split("=")[1]] = opt.split("=")[0]
                          val_opt[opt.split("=")[0]] = opt.split("=")[1]
                        }
                        list << options.map{|item|item.split("=")[0]}.join("|")
                        defaults << opt_val[value]
                        else
                        list << ""
                        value = ((value.to_f)*25.4).round.to_s if !letter?(value)
                        defaults << value
                      end
                    }
                    b1_b_thickness = enx.definition.get_attribute("dynamic_attributes", "b1_b_thickness")
                    _b1_b_thickness_formlabel = enx.definition.get_attribute("dynamic_attributes", "_b1_b_thickness_formlabel")
                    c6_back = new_comp.get_attribute("dynamic_attributes", "c6_back")
                    _c6_back_formlabel = new_comp.get_attribute("dynamic_attributes", "_c6_back_formlabel")
                    _c6_back_options = new_comp.get_attribute("dynamic_attributes", "_c6_back_options")
                    options = js_unescape(_c6_back_options)[1..-2].split("&")
                    options.each{|opt|
                      opt_val[opt.split("=")[1]] = opt.split("=")[0]
                      val_opt[opt.split("=")[0]] = opt.split("=")[1]
                    }
                    c6_back_list = options.map{|item|item.split("=")[0]}.join("|")
                    prompts += [_b1_b_thickness_formlabel,_c6_back_formlabel]
                    defaults += [b1_b_thickness.to_mm.round(1),opt_val[c6_back]]
                    list += ["",c6_back_list]
                    param_arr = UI.inputbox prompts, defaults, list, "Параметры ящика"
                    if !param_arr
                      return
                      else
                      param_arr.map!{|param| val_opt[param] ? val_opt[param] : (!letter?(param) ? param.to_f/25.4 : param)}
                      @att_arr.each_with_index{|att,index|
                        enx.definition.set_attribute("dynamic_attributes", att, param_arr[index])
                        enx.set_attribute("dynamic_attributes", att, param_arr[index])
                      }
                    end
                  end
                }
                sel.grep(Sketchup::ComponentInstance) { |e|
                  @change = false
                  @x_drawer = []
                  change_Drawer(e,new_comp,new_comps,param_arr)
                  if @change
                    redraw = false
                    if @x_drawer != []
                      a00_lenx = e.definition.get_attribute("dynamic_attributes", "a00_lenx", "0")
                      @x_drawer.each{ |drawer|
                        e.set_attribute("dynamic_attributes", "x_"+drawer.split("_")[0].downcase, drawer.split("_")[1].to_f)
                        e.definition.set_attribute("dynamic_attributes", "x_"+drawer.split("_")[0].downcase, drawer.split("_")[1].to_f)
                        if a00_lenx.to_f*2.54 > drawer.split("_")[1].to_f
                          e.set_attribute("dynamic_attributes", "a00_lenx", drawer.split("_")[1].to_f/2.54)
                          e.definition.set_attribute("dynamic_attributes", "a00_lenx", drawer.split("_")[1].to_f/2.54)
                          redraw = true
                        end
                      }
                    end
                    if redraw || param_arr
                      Redraw_Components.redraw_entities_with_Progress_Bar([e])
                    end
                  end
                }
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Корзин")
                @model.start_operation('Change', true,false,true)
                sel.grep(Sketchup::ComponentInstance) { |e| change_Basket(e, new_comp) }
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Навес") || param_comp[2].include?("Подвес")
                @model.start_operation('Change', true,false,true)
                @back_panels = []
                @module_lenx = 0
                sel.grep(Sketchup::ComponentInstance) { |e| change_Bracket(e, new_comp) }
                Redraw_Components.redraw_entities_with_Progress_Bar(@back_panels)
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Опор")
                @model.start_operation('Change', true,false,true)
                sel.grep(Sketchup::ComponentInstance) { |e|
                  @leg_components = []
                  change_leg(e, new_comp)
                  if @leg_components != []
                    Redraw_Components.redraw(e,false)
                    @leg_components.each { |ent|
                      Redraw_Components.redraw(ent,false)
                    }
                  end
                }
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Сушк")
                @model.start_operation('Change', true,false,true)
                sel.grep(Sketchup::ComponentInstance) { |e| change_Dryer(e, new_comp) }
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Подъемник")
                @model.start_operation('Change', true,false,true)
                sel.grep(Sketchup::ComponentInstance) { |e| change_Lift(e, new_comp) }
                df.purge_unused if @purge_unused == "yes"
                @model.commit_operation
                elsif param_comp[2].include?("Профиль купе")
                @model.start_operation('Change', true,false,true)
                @new_body = {}
                sel.grep(Sketchup::ComponentInstance) { |e| change_Profile(e, new_comp) }
                df.purge_unused
                @model.commit_operation
              end
            end
						end_time = Time.new
					  p "change_components in #{end_time - begin_time} seconds"
          end
        end
      end
    end
		def get_att(enx,att)
		  enx.definition.get_attribute("dynamic_attributes", att)
    end#def
    def letter?(str)
      str.to_s =~ /[A-Za_zА-Яа-яЁё]/
    end#def
    def change_Frontal(ent, link, new_comp, new_comp_up, new_comp_slab, param)
      if !ent.hidden?
        type = ent.definition.get_attribute("dynamic_attributes", "description", "0")
        name = ent.definition.get_attribute("dynamic_attributes", "_name", "0")
        item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
        if type[0..4] == "Фасад" || type.include?("МДФ")
          ent.make_unique if ent.definition.count_instances > 1
          ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
          if new_comp.name.include?("Jprofile")
            if item_code[0] == "N"
              new_comp = new_comp_slab if name == "Frontal3" || name == "Frontal4" || name == "Panel"
              elsif item_code[0] == "V" || item_code[0] == "A"
              new_comp = new_comp_up if name == "Frontal1" || name == "Frontal2"
              elsif item_code[0] == "P"
              new_comp = new_comp_up if name == "Frontal2"
            end
          end
          a00_lenx_formula = false
          a00_lenz_formula = false
          lenx = ent.definition.get_attribute("dynamic_attributes", "lenx")
          lenx_formula = ent.definition.get_attribute("dynamic_attributes", "_a00_lenx_formula")
          lenz = ent.definition.get_attribute("dynamic_attributes", "lenz")
          lenz_formula = ent.definition.get_attribute("dynamic_attributes", "_a00_lenz_formula")
          lengthunits = ent.get_attribute("dynamic_attributes", "_lengthunits")
          lengthunits = ent.definition.get_attribute("dynamic_attributes", "_lengthunits") if !lengthunits
          if lengthunits == "CENTIMETERS"
            lenx = lenx.to_cm.to_s
            lenz = lenz.to_cm.to_s
          end
          if lenx_formula == nil
            ent.set_attribute("dynamic_attributes", "a00_lenx", lenx)
            ent.definition.set_attribute("dynamic_attributes", "a00_lenx", lenx)
            ent.definition.set_attribute("dynamic_attributes", "_a00_lenx_formula", lenx)
            else
            a00_lenx_formula = true
          end
          if lenz_formula == nil
            ent.set_attribute("dynamic_attributes", "a00_lenz", lenz)
            ent.definition.set_attribute("dynamic_attributes", "a00_lenz", lenz)
            ent.definition.set_attribute("dynamic_attributes", "_a00_lenz_formula", lenz)
            else
            a00_lenz_formula = true
          end
          if new_comp.name.include?("Фрезеровки")
            ent.set_attribute("dynamic_attributes", "a03_path", "Slab")
            ent.definition.set_attribute("dynamic_attributes", "a03_path", "Slab")
            ent.definition.set_attribute("dynamic_attributes", "_a03_name_formula", 'CONCATENATE('+'Фасад_'+param[0]+',CHOOSE(a09_vitr,,_Витрина1,_Решетка4,_Решетка6,_Решетка8))')
            frontal_change(ent, new_comp, item_code, name, param)
            Redraw_Components.redraw_entities_with_Progress_Bar([ent])
            elsif new_comp.name.include?("Slab")
            ent.set_attribute("dynamic_attributes", "a03_path", "Slab")
            ent.definition.set_attribute("dynamic_attributes", "a03_path", "Slab")
            frontal_change(ent, new_comp, item_code, name, param)
            Redraw_Components.redraw_entities_with_Progress_Bar([ent])
            else
            ent.set_attribute("dynamic_attributes", "a03_path", link + new_comp.name + ".skp")
            ent.definition.set_attribute("dynamic_attributes", "a03_path", link + new_comp.name + ".skp")
            frontal_change(ent, new_comp, item_code, name, param)
            if param == 1
              Change_Materials.change_krom(ent, "Фасад_Базовая", "1")
              Change_Materials.change_mat(ent, "Фасад_Базовая", "Фасад_Базовая")
            end
          end
					Redraw_Components.redraw_entities_with_Progress_Bar(ent.parent.entities.grep(Sketchup::ComponentInstance).select{|e|e.definition.name.include?("dimension")})
          if item_code[0] == "N" || item_code[0] == "P" && name == "Frontal1" || item_code[0] == "A" && !name.include?("Frontal") || item_code[0] == "V" && !name.include?("Frontal")
            ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |enx| enx.erase! if enx.definition.name.include?("control_vitr") }
          end
          if a00_lenx_formula == false
            ent.definition.delete_attribute("dynamic_attributes", "_a00_lenx_formula")
          end
          if a00_lenz_formula == false
            ent.definition.delete_attribute("dynamic_attributes", "_a00_lenz_formula")
          end
          elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Тело") || type.include?("Каркас") || type.include?("Body") || type.include?("body")
          ent.make_unique if ent.definition.count_instances > 1
          ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
          if item_code.include?("LP") 
            if new_comp.name.include?("Slab") || new_comp.name.include?("Jprofile")
              planka = "1"
              else
              planka = "2"
            end
            ent.set_attribute("dynamic_attributes", "a00_form_planka", planka)
            ent.definition.set_attribute("dynamic_attributes", "a00_form_planka", planka)
            ent.definition.set_attribute("dynamic_attributes", "_a00_form_planka_label", "a00_form_planka")
            ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) }
            Redraw_Components.redraw_entities_with_Progress_Bar([ent])
          end
          ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Frontal(e, link, new_comp, new_comp_up, new_comp_slab, param) }
        end
      end
    end#def
    
    def frontal_change(e, new_comp, item_code, name, param)
      if !e.definition.name.include?("Стойка")
        frontal_entity = e
        frontal_entity.make_unique if frontal_entity.definition.count_instances > 1
        frontal_entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
        a09_vitr = frontal_entity.definition.get_attribute("dynamic_attributes", "a09_vitr", "1") if frontal_entity.definition.get_attribute("dynamic_attributes", "a09_vitr")
        body_ent_arr = []
				frontal_entity.definition.delete_attribute("dynamic_attributes", "_old_len")
				frontal_entity.definition.delete_attribute("dynamic_attributes", "_old_path")
        frontal_entity.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |enx| body_ent_arr << enx if enx.definition.name.include?("Body") }
				att_arr = ["a00_mat_krom","a06_mat_panel","a07_mat_krom","back_material","edge_label","number","su_info","su_type","type_material"]
        body_ent_arr.each{|body|
          body.make_unique if body.definition.count_instances > 1
          body.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
					att_hash = {}
          body.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |enx|
            if enx.definition.name.include?("Essence") || enx.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
							dict = enx.definition.attribute_dictionary "dynamic_attributes"
              dict.each_pair { |attr, value| att_hash[attr] = value if att_arr.any?{|att|attr.include?(att)} }
							enx.erase!
						  elsif enx.definition.name.include?("control_vitr")
              enx.erase!
              elsif enx.definition.name.include?("Glass") && a09_vitr == "1" && !enx.hidden?
              enx.erase!
            end
          }
          t = Geom::Transformation.translation [0, 0, 0]
          new_comp_place = body.definition.entities.add_instance new_comp, t
          new_comp_place.explode
          DCProgressBar::clear()
          body.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |enx|
            if enx.definition.name.include?("Essence") || enx.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
              enx.make_unique if enx.definition.count_instances > 1
              enx.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true)
              if new_comp.name.include?("Рамка")
                body.set_attribute("dynamic_attributes", "a09_vitr", "1")
                body.definition.set_attribute("dynamic_attributes", "a09_vitr", "1")
                enx.set_attribute("dynamic_attributes", "color_ramka", param)
                enx.definition.set_attribute("dynamic_attributes", "color_ramka", param)
              end
							att_hash.each_pair { |attr, value|
                if attr =~ /lenx|leny|lenz/i
                  else
                  enx.set_attribute("dynamic_attributes", attr, value)
                  enx.definition.set_attribute("dynamic_attributes", attr, value)
                end
              }
              enx.definition.delete_attribute("dynamic_attributes", "_set_path_formula")
							target_hidden = Redraw_Components.get_formula_result(enx,'hidden')
							target_hidden = Redraw_Components.get_attribute_value(enx,'hidden') if !target_hidden
							if target_hidden && target_hidden.to_f > 0.0
								enx.erase!
								else
								Redraw_Components.redraw(enx,false)
              end
              explode_essence(enx) if enx.definition.get_attribute("dynamic_attributes", "set_path") != "Slab" && !new_comp.name.include?("Slab") && !new_comp.name.include?("Лоток")
            end
          }
          Redraw_Components.redraw(e,false)
          DCProgressBar::clear()
        }
      end	 
    end # def frontal_change
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
						if !v1.length.zero? && !v2.length.zero? && v1.parallel?(v2)
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
    
    def change_Handle(e,new_comp,handle_name,handle_width)
      @new_comp = new_comp
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
			@old_name_tip_on = true if a03_name.include?("Tip")
      item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
      if type.include?("lift") || type.include?("Каркас") && a03_name.downcase.include?("tandembox") || (type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие")) && a03_name.downcase.include?("tandembox") || a03_name.include?("Тандем Blum")
        if @new_comp.name.include?("Tip")
          tip_on = 2
          @a03_name.push(a03_name)
					else
					tip_on = 1
        end
        e.definition.set_attribute("dynamic_attributes", "_tip_on_label", "tip_on")
        e.definition.set_attribute("dynamic_attributes", "tip_on", tip_on)
        e.set_attribute("dynamic_attributes", "tip_on", tip_on)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Handle(e,new_comp,handle_name,handle_width) }
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
      end
      if e.definition.name.include?("Руч") || type.downcase.include?("handle") || su_type.downcase.include?("handle")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        handle_change(e,handle_name,handle_width)
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif type.include?("Каркас") && a03_name.downcase.include?("metabox") && @new_comp.name.include?("Tip")
        UI.messagebox(a03_name+" "+SUF_STRINGS["incompatible with Tip-on"])
        elsif type.include?("Каркас") && a03_name.downcase.include?("legrabox") && @new_comp.name.include?("Tip")
        UI.messagebox(a03_name+" "+SUF_STRINGS["incompatible with Tip-on"])
        elsif type.include?("Фасад")
        @a03_name.push(a03_name)
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Handle(e,new_comp,handle_name,handle_width) }
        elsif (type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие")) && !a03_name.downcase.include?("tandembox") || type.include?("Тело") || type.include?("Каркас") && !a03_name.downcase.include?("tandembox") || type.include?("Body") && !a03_name.downcase.include?("tandembox") || type.include?("body") && !a03_name.downcase.include?("tandembox")
        @a03_name = []
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Handle(e,new_comp,handle_name,handle_width) }
      end
      
    end #def change_Handle
    
    def handle_change(handle,handle_name,handle_width)
      if @new_comp.name.include?("Без")
        handle.definition.set_attribute("dynamic_attributes", "c1_ruch_tip", 1)
        handle.set_attribute("dynamic_attributes", "c1_ruch_tip", 1)
        elsif @new_comp.name.include?("RC035")
        handle.definition.set_attribute("dynamic_attributes", "c1_ruch_tip", 2)
        handle.set_attribute("dynamic_attributes", "c1_ruch_tip", 2)
        elsif @new_comp.name.include?("RR002")
        handle.definition.set_attribute("dynamic_attributes", "c1_ruch_tip", 5)
        handle.set_attribute("dynamic_attributes", "c1_ruch_tip", 5)
        elsif @new_comp.name.include?("Tip")
        handle.definition.set_attribute("dynamic_attributes", "c1_ruch_tip", 6)
        handle.set_attribute("dynamic_attributes", "c1_ruch_tip", 6)
        else
        handle.definition.set_attribute("dynamic_attributes", "c1_ruch_tip", 4)
        handle.set_attribute("dynamic_attributes", "c1_ruch_tip", 4)
      end
      
      handle.definition.delete_attribute("dynamic_attributes", "_su_quantity_formula")
      handle.definition.set_attribute("dynamic_attributes", "su_quantity", 1)
      handle.set_attribute("dynamic_attributes", "su_quantity", 1)
      if handle_width
			  if handle.parent.name.include?("Body")
					handle.parent.instances[-1].parent.set_attribute("dynamic_attributes", "handle_width", (handle_width.to_f-64)/32)
					else
					handle.parent.set_attribute("dynamic_attributes", "handle_width", (handle_width.to_f-64)/32)
        end
      end
      tandembox = false
      @a03_name.each { |name| tandembox = true if name.downcase.include?("tandembox") }
      if tandembox == true && handle_name.include?("Tip")
        handle.definition.set_attribute("dynamic_attributes", "a08_su_unit", 1)
        handle.set_attribute("dynamic_attributes", "a08_su_unit", 1)
        else
        handle.definition.set_attribute("dynamic_attributes", "a08_su_unit", 6)
        handle.set_attribute("dynamic_attributes", "a08_su_unit", 6)
      end
      handle.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
				@old_name_tip_on = true if body.definition.get_attribute("dynamic_attributes", "handle_type")
        if body.definition.name.include?("Telo") || body.definition.name.include?("Choose") || body.definition.name.include?("Tip") || body.definition.name.include?("body")
          body.erase!
        end 
      }
			ent = handle.definition.entities
			t = Geom::Transformation.translation [0, 0, 0]
			new_comp_place = ent.add_instance @new_comp, t
      new_comp_place.explode
      Redraw_Components.redraw_entities_with_Progress_Bar([handle])
      current_handle_width = handle.definition.get_attribute("dynamic_attributes", "c2_width")
      current_handle_width = 2 if current_handle_width.to_f < 1
      current_handle_width = -1 if handle_name.include?("32") || handle_name.include?("кнопка")
      formula = nil
      if handle_width == false && current_handle_width
        handle_name = handle_name.gsub("-кнопка","").gsub("-скоба","").gsub("-релинг","")
        if ((current_handle_width.to_f*32)+64) > 64
          formula = 'CONCATENATE("'+handle_name+' ",ROUND(c2_width*32+64))'
        end
      end
      if formula
        handle.definition.set_attribute("dynamic_attributes", "_a03_name_formula", formula)
        else
        handle.definition.delete_attribute("dynamic_attributes", "_a03_name_formula")
        handle.definition.set_attribute("dynamic_attributes", "a03_name", handle_name)
        handle.set_attribute("dynamic_attributes", "a03_name", handle_name)
      end
      Redraw_Components.redraw_entities_with_Progress_Bar([handle])
    end # handle_change
    
    def change_Hinge(e, comp_name)
		  if !e.hidden?
				name = e.definition.get_attribute("dynamic_attributes", "name", "0")
				a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
				name_hinge = e.definition.get_attribute("dynamic_attributes", "name_hinge")
				opening_angle = e.definition.get_attribute("dynamic_attributes", "opening_angle")
				type = e.definition.get_attribute("dynamic_attributes", "description", "0")
        su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
				item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
				if su_type.include?("hinge") || e.definition.name.include?("Hinge") || name.downcase.include?("hinge") || e.definition.name.include?("plate") || !type.include?("frontal") && name.downcase.include?("планка") || e.definition.name.include?("175H9100")
          if e.definition.name.include?("175H9100") && !e.definition.get_attribute("dynamic_attributes", "a03_name")
            e.transform!(Geom::Transformation.scaling(e.transformation.origin, 1, 1, -1)) if e.transformation.zaxis.z != 1
            e.transform!(Geom::Transformation.scaling(e.transformation.origin, -1, 1, 1))
            myentities = e.definition.entities
            myentities.transform_entities(Geom::Transformation.scaling(e.transformation.origin, -1, 1, 1), myentities.to_a)
            e.set_attribute("dynamic_attributes", "a03_name", '0')
            e.definition.set_attribute("dynamic_attributes", "a03_name", '0')
            e.definition.set_attribute("dynamic_attributes", "_a03_name_label", 'a03_name')
            e.definition.set_attribute("dynamic_attributes", "_a03_name_formula", 'CONCATENATE("CLIP ответная планка, крест.| ",CHOOSE(LOOKUP("spacing",1),"0 мм","3 мм","6 мм","9 мм","18 мм"),"| сталь| ",IF(LOOKUP("mounting_plate",2)=2,"с предвар. вмонт. евровинтами","на саморезы"), " [Blum| Австрия]")')
            e.set_attribute("dynamic_attributes", "su_type", 'furniture')
            e.definition.set_attribute("dynamic_attributes", "su_type", 'furniture')
            e.definition.set_attribute("dynamic_attributes", "_su_type_label", 'su_type')
            e.set_attribute("dynamic_attributes", "su_info", '0')
            e.definition.set_attribute("dynamic_attributes", "su_info", '0')
            e.definition.set_attribute("dynamic_attributes", "_su_info_label", 'su_info')
            e.definition.set_attribute("dynamic_attributes", "_su_info_formula", 'LOOKUP("ItemCode")&"/"&a03_name&"/"&su_type&"/"&LenZ*10&"/"&LenY*10&"/"&LenX*10&"/"&"Ответная планка крест"&"/"&Material&"/"&1&"/"&1&"/"&"шт"&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0')
            Redraw_Components.redraw_entities_with_Progress_Bar([e])
            a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
          end
					if @item_code == "N1.LP"
						@b3_handle == "2" ? a03_name = a03_name.gsub(SUF_STRINGS["semi-folding"],SUF_STRINGS["overhead"]) : a03_name = a03_name.gsub(SUF_STRINGS["overhead"],SUF_STRINGS["semi-folding"])
          end
					e.make_unique
					e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
					split_string = ""
					if a03_name.include?(SUF_STRINGS["inset"])
						split_string = SUF_STRINGS["inset"]
						elsif a03_name.include?(SUF_STRINGS["partial overlay"])
						split_string = SUF_STRINGS["partial overlay"]
						elsif a03_name.include?(SUF_STRINGS["full overlay"])
						split_string = SUF_STRINGS["full overlay"]
          end
					
					hinge_type = {}
					@hinges.each_pair { |type,hash|
						hash.each_pair{|producer,array|
							array.each { |hinge|
								if hinge[0].tr('^A-Za-zА-Яа-я0-9', '') == a03_name.tr('^A-Za-zА-Яа-я0-9', '')
									hinge_type[type] = producer
                end
              }
            }
          }
					@hinges.each_pair { |type,hash|
						hash.each_pair{|producer,array|
							array.each { |hinge|
								if type.split("=")[1].downcase == split_string && producer == comp_name
									hinge_type[type] = producer if !hinge_type[type]
                end
              }
            }
          }
					if hinge_type != {}
						hinge_type.each_pair { |this_type,this_producer|
							@hinges[this_type].each_pair { |producer,array|
								if producer == comp_name
									if @hinge_hash[a03_name]
										if !@hinge_hash[a03_name].any? { |arr| arr.include?(e) }
											@hinge_hash[a03_name] << [e,array,name_hinge,comp_name,split_string,opening_angle]
											else
											a03_name_new_array = []
											@hinge_hash[a03_name].each { |arr|
											  array.each { |new_array|
													arr[1] << new_array if !arr[1].include?(new_array) && !new_array.include?("Отсутствует")
                        }
												a03_name_new_array << arr
                      }
											@hinge_hash[a03_name] = a03_name_new_array
                    end
										else
										@hinge_hash[a03_name] = [[e,array,name_hinge,comp_name,split_string,opening_angle]]
                  end
                end
              }
            }
						else
						@hinges.each_pair { |type,hash|
							hash.each_pair { |producer,array|
								if producer == comp_name
									if @hinge_hash[a03_name]
										if !@hinge_hash[a03_name].any? { |arr| arr.include?(e) }
											@hinge_hash[a03_name] << [e,array,name_hinge,comp_name,split_string,opening_angle]
                    end
										else
										@hinge_hash[a03_name] = [[e,array,name_hinge,comp_name,split_string,opening_angle]]
                  end
                end
              }
            }
          end
					e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent| change_Hinge(ent, comp_name) }
					
					elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Тело") || type.include?("Каркас") || type.include?("Body") || type.include?("body") || type.include?("Фасад") || type.include?("frontal") || type.include?("lift")
					e.make_unique
          e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
					if type.include?("Фасад") || type.include?("frontal")
						@frontal_entities << e if !@frontal_entities.include?(e)
          end
					hinge_type = e.definition.get_attribute("dynamic_attributes", "hinge_type")
					if hinge_type
						if hinge_type.to_i < 1
							e.set_attribute("dynamic_attributes", "hinge_type", "1")
							e.definition.set_attribute("dynamic_attributes", "hinge_type", "1")
            end
          end
					e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent| change_Hinge(ent, comp_name) }
        end
      end
    end #def change_Hinge
    def hinge_change(e,name_hinge,comp_name,new_name,split_string,opening_angle)
			e.set_attribute("dynamic_attributes", "a03_name", new_name)
			e.definition.set_attribute("dynamic_attributes", "a03_name", new_name)
			e.definition.delete_attribute("dynamic_attributes", "_a03_name_formula")
			if @frontal_entities != []
				@frontal_entities.each { |frontal_entity|
				  ["hinge_name","hinge_producer","hinge_opening_angle"].each { |att| delete_hinge_att(frontal_entity,att) }
        }
				["name_hinge","producer","opening_angle","cup"].each { |att| delete_hinge_att(e,att) }
      end
			@hinges_to_redraw << e
    end#def
		def delete_hinge_att(e,att)
		  att_names = []
		  dict = e.attribute_dictionary "dynamic_attributes"
			dict.each_key {|k| att_names << k if k.include?(att) } if dict
			att_names.each { |name| dict.delete_key(name) }
			att_names = []
			dict = e.definition.attribute_dictionary "dynamic_attributes"
			dict.each_key {|k| att_names << k if k.include?(att) } if dict
			att_names.each { |name| dict.delete_key(name) }
    end#def
		def change_hinge_dialog()
			@change_hinge_dlg.close if @change_hinge_dlg && (@change_hinge_dlg.visible?)
			head = <<-HEAD
				<html><head>
				<meta charset="utf-8">
				<title>Edit</title>
				<style>
				body { font-family: Arial; color: #696969; font-size: 14px; padding-bottom: 40px;}
				#name_table { width: 100%; border-collapse: collapse; font-size: 12px; }          
					#name_table th{ padding: 3px; text-align:center; }				
					#name_table td { padding: 3px; border: 1px solid gray; }
        #name_table td:nth-child(2){ text-align:right; }
				.edit_name { width: 100%; height: 17px; }
				#footer { position : fixed; bottom: 0; left: 0; width: 100%; line-height: 20px; text-align: center; border-top: 1px solid gray; background-color: #e2ded7; padding: 3px; }
				.save { display:inline-block; margin-right:5px; width:100px; height:30px; background-color: #e08120; cursor:pointer; border: 1px solid transparent; color: #000000;}
				.save:hover { background-color: #c46500; }
				.close { display:inline-block; margin-left:5px; width:100px; height:30px; background-color: #9B9B9B; cursor:pointer; border: 1px solid transparent; color: #000000;}
				.close:hover { background-color: #8D8D8D; }
				</style>
				</head>
        <body>
      HEAD
			body = ''
			body << %(
			<table id="name_table" ><th style="width: 50%; height: 24px;">#{SUF_STRINGS["Old name"]}</th><th style="width: 50%; height: 24px;">#{SUF_STRINGS["New name"]}</th>)
			@hinge_hash.each_pair { |name,array|
				options = array[0][1]
        body << %(<tr>
        <td style="width: 50%; height: 24px;" id="#{name}">#{name}</td>
				<td style="width: 50%; height: 24px;" ><select id="select_#{name}"><option value="#{SUF_STRINGS["Do not change"]}">#{SUF_STRINGS["Do not change"]}</option>)
				options.each_with_index { |option,index|
					if index == 0
					  body << %(<option selected value="#{option[0]}">#{option[0]}</option>)
					  else
					  body << %(<option value="#{option[0]}">#{option[0]}</option>)
          end
        }
				body << %(</select></td></tr>)
      }
      body << %(</table>
      <div id="footer">
      <button class="save" onclick="save_or_close('save');">#{SUF_STRINGS["Save"]}</button>
			<button class="close" onclick="save_or_close('close');">#{SUF_STRINGS["Cancel"]}</button>
      </div>)
      tail = <<-TAIL
        <script>
        function save_or_close(str) {
				if(str=='save') {
        let name_list = [];
        var trs = document.querySelectorAll('tr');
        for (var i = 1; i < trs.length; i++) {
				e = trs[i].cells[1].childNodes[0];
        name_list.push([trs[i].cells[0].innerHTML,e.options[e.selectedIndex].text]);
        }
        sketchup.change(name_list);
				} else {sketchup.close(); }
				}
        </script>
        </body></html>
      TAIL
      html = head + body + tail
      @change_hinge_dlg = UI::HtmlDialog.new({
        :dialog_title => SUF_STRINGS["Edit_list"],
        :preferences_key => "change_hinge",
        :scrollable => true,
        :resizable => true,
        :width => 1000,
        :height => 600,
        :left => 100,
        :top => 200,
        :min_width => 800,
        :min_height => 300,
        :max_width =>1600,
        :max_height => 800,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      @change_hinge_dlg.add_action_callback('change') { |dialog,param|
				@change_hinge_dlg.close
				if param.all?{|names|names[1] == SUF_STRINGS["Do not change"] || names[1] == SUF_STRINGS["Not available"] || names[1] == SUF_STRINGS["No"]}
					@model.abort_operation
					else
					param.each{|names|
						if names[1] != "" && names[1] != SUF_STRINGS["Do not change"] && names[1] != SUF_STRINGS["Not available"] && names[1] != SUF_STRINGS["No"]
							@hinge_hash[names[0]].each { |hinge|
								hinge_change(hinge[0],hinge[2],hinge[3],names[1],hinge[4],hinge[5])
              }
            end
          }
					Redraw_Components.redraw_entities_with_Progress_Bar(@hinges_to_redraw+@frontal_entities)
					@model.definitions.purge_unused if @purge_unused == "yes"
					@model.commit_operation
        end
      }
			@change_hinge_dlg.add_action_callback('close') { |dialog,param|
			  @change_hinge_dlg.close
				@model.abort_operation
      }
      @change_hinge_dlg.set_html(html)
			if @hinge_select == "yes"
        @change_hinge_dlg && (@change_hinge_dlg.visible?) ? @change_hinge_dlg.bring_to_front : @change_hinge_dlg.show
			  else
				@hinge_hash.each { |name,array|
					array.each { |hinge|
						#hinge_change(e,name_hinge,comp_name,new_name,split_string,opening_angle)
						p [hinge[0],hinge[2],hinge[3],hinge[1][0][0],hinge[4],hinge[5]]
					  hinge_change(hinge[0],hinge[2],hinge[3],hinge[1][0][0],hinge[4],hinge[5])
          }
        }
			  Redraw_Components.redraw_entities_with_Progress_Bar(@hinges_to_redraw+@frontal_entities)
				@model.definitions.purge_unused if @purge_unused == "yes"
				@model.commit_operation
      end
    end#def
		def change_Drawer(e,new_comp,new_comps,param_arr=nil)
			su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
			a0_lenz = e.definition.get_attribute("dynamic_attributes", "a0_lenz", "0")
      a0_leny = e.definition.get_attribute("dynamic_attributes", "a0_leny", "0")
      a0_lenx = e.definition.get_attribute("dynamic_attributes", "a0_lenx", "0")
			tip_on = e.definition.get_attribute("dynamic_attributes", "tip_on", 0)
			a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
			item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
			if param_arr
				b1_b_thickness = e.definition.get_attribute("dynamic_attributes", "b1_b_thickness")
				if b1_b_thickness
					_b1_b_thickness_formula = e.definition.get_attribute("dynamic_attributes", "_b1_b_thickness_formula")
					if _b1_b_thickness_formula
						if _b1_b_thickness_formula.include?("c8_b_thickness")
							e.definition.set_attribute("dynamic_attributes", "_b1_b_thickness_formula", 'LOOKUP("c8_b_thickness",'+(param_arr[-2]*2.54).to_s+')')
							else
							e.definition.set_attribute("dynamic_attributes", "_b1_b_thickness_formula", 'LOOKUP("b1_b_thickness",'+(param_arr[-2]*2.54).to_s+')')
            end
						else
						e.definition.set_attribute("dynamic_attributes", "b1_b_thickness", param_arr[-2])
						e.set_attribute("dynamic_attributes", "b1_b_thickness", param_arr[-2])
          end
        end
				k6_back = e.definition.get_attribute("dynamic_attributes", "k6_back")
				c6_back = e.definition.get_attribute("dynamic_attributes", "c6_back")
				if k6_back
					e.definition.set_attribute("dynamic_attributes", "k6_back", param_arr[-1])
					e.set_attribute("dynamic_attributes", "k6_back", param_arr[-1])
					elsif c6_back
					_c6_back_formula = e.definition.get_attribute("dynamic_attributes", "_c6_back_formula")
					if _c6_back_formula
						if _c6_back_formula.include?("k6_back")
							e.definition.set_attribute("dynamic_attributes", "_c6_back_formula", 'LOOKUP("k6_back",'+param_arr[-1]+')')
            end
          end
					e.definition.set_attribute("dynamic_attributes", "c6_back", param_arr[-1])
					e.set_attribute("dynamic_attributes", "c6_back", param_arr[-1])
        end
      end
			if su_type.include?("drawer") && !e.hidden?
				if e.definition.get_attribute("dynamic_attributes", "_a00_leny_formula","0") == 'nearest(int((LOOKUP("a01_leny",45)-a01_indent)*2/10)*10/2,x_depth1,x_depth2,x_depth3,x_depth4,x_depth5,x_depth6,x_depth7,x_depth8,x_depth9,x_depth91,x_depth92,x_depth93,x_depth94,x_depth95,x_depth96,x_depth97,x_depth98,x_depth99,x_depth991)'
					e.definition.set_attribute("dynamic_attributes", "_a00_leny_formula",'nearestsmaller((LOOKUP("a01_leny",45)-a01_indent),x_depth1,x_depth2,x_depth3,x_depth4,x_depth5,x_depth6,x_depth7,x_depth8,x_depth9,x_depth91,x_depth92,x_depth93,x_depth94,x_depth95,x_depth96,x_depth97,x_depth98,x_depth99,x_depth991)')
        end
				if e.definition.get_attribute("dynamic_attributes", "_leny_formula", "0") == 'nearest(int((LOOKUP("a0_leny")-a01_indent)*2/10)*10/2,x_depth1,x_depth2,x_depth3,x_depth4,x_depth5,x_depth6,x_depth7,x_depth8,x_depth9)' || e.definition.get_attribute("dynamic_attributes", "_leny_formula","0") == 'nearest(int((LOOKUP("a01_leny",45)-a01_indent)*2/10)*10/2,x_depth1,x_depth2,x_depth3,x_depth4,x_depth5,x_depth6,x_depth7,x_depth8,x_depth9,x_depth91,x_depth92,x_depth93,x_depth94,x_depth95,x_depth96,x_depth97,x_depth98,x_depth99,x_depth991)'
					e.definition.set_attribute("dynamic_attributes", "_leny_formula",'nearestsmaller((LOOKUP("a01_leny",45)-a01_indent),x_depth1,x_depth2,x_depth3,x_depth4,x_depth5,x_depth6,x_depth7,x_depth8,x_depth9,x_depth91,x_depth92,x_depth93,x_depth94,x_depth95,x_depth96,x_depth97,x_depth98,x_depth99,x_depth991)')
					if !e.definition.get_attribute("dynamic_attributes", "x_depth91")
						set_att(e,"x_depth91","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth92","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth93","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth94","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth95","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth96","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth97","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth98","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth99","60",nil,nil,nil,"STRING",nil,nil,nil)
						set_att(e,"x_depth991","60",nil,nil,nil,"STRING",nil,nil,nil)
          end
					set_att(e,"trim_z1",nil,nil,"TEXTBOX","Отступ короба сверху",nil,nil,nil,"&")
					set_att(e,"trim_z2",nil,nil,"TEXTBOX","Отступ короба снизу",nil,nil,nil,"&")
					set_att(e,"trim_y_size",a0_leny,nil,"TEXTBOX","Глубина короба","CENTIMETERS","MILLIMETERS",'a0_leny',"&")
        end
				_name = e.definition.get_attribute("dynamic_attributes", "_name", "0")
				e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
				drawer_name = new_comp.name.split("#")[0]
				if drawer_name.include?("Сушка")
				  width_list = []
					width_list << "450" if new_comps["new_comp_450"]
          width_list << "500" if new_comps["new_comp_500"]
					width_list << "600" if new_comps["new_comp_600"]
					width_list << "700" if new_comps["new_comp_700"]
					width_list << "800" if new_comps["new_comp_800"]
					width_list << "900" if new_comps["new_comp_900"]
          min_height = 35
					if a0_lenz >= min_height/2.54
						if a0_lenx == 45/2.54 && new_comps["new_comp_450"]
							drawer_change(e,new_comps["new_comp_450"],drawer_name)
							@change = true
							elsif a0_lenx == 50/2.54 && new_comps["new_comp_500"]
							drawer_change(e,new_comps["new_comp_500"],drawer_name)
							@change = true
							elsif a0_lenx == 60/2.54 && new_comps["new_comp_600"]
							drawer_change(e,new_comps["new_comp_600"],drawer_name)
							@change = true
							elsif a0_lenx == 70/2.54 && new_comps["new_comp_700"]
							drawer_change(e,new_comps["new_comp_700"],drawer_name)
							@change = true
							elsif a0_lenx == 80/2.54 && new_comps["new_comp_800"]
							drawer_change(e,new_comps["new_comp_800"],drawer_name)
							@change = true
							elsif a0_lenx == 90/2.54 && new_comps["new_comp_900"]
							drawer_change(e,new_comps["new_comp_900"],drawer_name)
							@change = true
							else
              UI.messagebox(SUF_STRINGS["The width of the module should be:"]+"\n"+width_list.join(", ")+" "+SUF_STRINGS["mm"])
            end
            else
            UI.messagebox(SUF_STRINGS["The height of the box should be from:"]+"\n#{min_height*10} "+SUF_STRINGS["mm"])
          end
					elsif a03_name.downcase.include?("tandembox") && tip_on == 2
					if drawer_name.downcase.include?("tandembox") || drawer_name.include?("Tandem") || drawer_name.include?("Тандем Blum")
						drawer_change(e,new_comp,drawer_name)
						else
						UI.messagebox(a03_name+" "+SUF_STRINGS["with Tip-on. Install the handle"])
          end
					else
					@x_drawer.push(_name+"_"+(@metabox_max.to_f/10).round.to_s) if @metabox_max && drawer_name.include?("Metabox")
					@x_drawer.push(_name+"_"+(@tandembox_max.to_f/10).round.to_s) if @tandembox_max && drawer_name.include?("Tandembox")
					@x_drawer.push(_name+"_"+(@legrabox_max.to_f/10).round.to_s) if @legrabox_max && drawer_name.include?("Legrabox")
					drawer_change(e,new_comp,drawer_name)
					@change = true
        end
				set_att(e,"trim_z_size","",nil,"TEXTBOX","Высота короба","CENTIMETERS","MILLIMETERS",'CEILING(a0_lenz-trim_z1-trim_z2+0.01)-1',"&")
				if !e.definition.get_attribute("dynamic_attributes","d1_type_height")
					set_att(e,"d1_type_height","2",nil,"TEXTBOX","Высота ящика","STRING",nil,nil,nil)
        end
				#if drawer_name.include?("направл") || drawer_name.include?("Tandem") || drawer_name.include?("Тандем Blum")
				Redraw_Components.redraw_entities_with_Progress_Bar([e])
				#end
				elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || e.definition.name.include?("body") || e.definition.name.include?("Body")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent| change_Drawer(ent,new_comp,new_comps,param_arr) }
      end
    end #def change_Drawer
    
    def drawer_change(drawer_ent,new_comp,drawer_name)
      drawer_ent.set_attribute("dynamic_attributes", "a03_name", drawer_name)
      drawer_ent.definition.name = drawer_name
      drawer_ent.definition.set_attribute("dynamic_attributes", "a03_name", drawer_name)
      @b1_b_material,@b_type_material,@b1_p_material,@p_type_material = nil
      drawer_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body| search_drawer_mat(body) }
      drawer_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body| 
        name = body.definition.get_attribute("dynamic_attributes", "_name", "0")
        body.erase! if !name.include?("Frontal") && !name.include?("Trend") && !name.include?("Volpato")
      }
      entities = drawer_ent.definition.entities
      t = Geom::Transformation.translation [0, 0, 0]
      new_comp_place = entities.add_instance new_comp, t
      DCProgressBar::clear()
      Redraw_Components.run_all_formulas(new_comp_place)
      new_comp_place.explode
      drawer_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
        name = body.definition.get_attribute("dynamic_attributes", "_name", "0")
        if !name.include?("Frontal") && !name.include?("Trend") && !name.include?("Volpato")
          DCProgressBar::clear()
          Redraw_Components.redraw(body,false)
        end
      }
      DCProgressBar::clear()
      Change_Materials::change_Drawer_material(drawer_ent,@b1_p_material,true,@p_type_material) if @b1_p_material
      Change_Materials::change_Back_material(drawer_ent,@b1_b_material,true,@b_type_material) if @b1_b_material
    end # drawer_change
    def search_drawer_mat(ent)
      if !@b1_b_material
        type = ent.definition.get_attribute("dynamic_attributes", "description", "0")
        if type.include?("ЗС") && !type.include?("Ящик") && !type.include?("carcass") || type.include?("ХДФ") && !type.include?("glass") || type.include?("back")
          @b1_b_material = ent.definition.get_attribute("dynamic_attributes", "material")
          if @b1_b_material && @b1_b_material.index("_",-5)
            @b1_b_material = @b1_b_material[0..@b1_b_material.index("_",-5)-1]
          end
          @b_type_material = ent.definition.get_attribute("dynamic_attributes", "type_material")
        end
      end
      if !@b1_p_material
        type = ent.definition.get_attribute("dynamic_attributes", "description", "0")
        if type.include?("carcass") || type.include?("ЛДСП") && !type.include?("frontal") && !type.include?("glass") && !type.include?("Фасад") && !type.include?("ЗС") && !type.include?("ХДФ")
          @b1_p_material = ent.definition.get_attribute("dynamic_attributes", "material")
          if @b1_p_material && @b1_p_material.index("_",-5)
            @b1_p_material = @b1_p_material[0..@b1_p_material.index("_",-5)-1]
          end
          @p_type_material = ent.definition.get_attribute("dynamic_attributes", "type_material")
        end
      end
      ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body| search_drawer_mat(body) }
    end#def
    def change_Basket(e,new_comp)
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      a0_lenz = e.definition.get_attribute("dynamic_attributes", "a0_lenz", "0")
      a0_lenx = e.definition.get_attribute("dynamic_attributes", "a0_lenx", "0")
      tip_on = e.definition.get_attribute("dynamic_attributes", "tip_on", 0)
      a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      if su_type.include?("basket") || su_type.include?("furniture") && a03_name.include?("Бутылочница")
        basket_change(e,new_comp)
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || e.definition.name.include?("body") || e.definition.name.include?("Body")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Basket(e,new_comp) }
      end
    end #def change_Basket
    
    def basket_change(drawer_ent,new_comp)
      drawer_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body| body.erase! }
      ent = drawer_ent.definition.entities
      t = Geom::Transformation.translation [0, 0, 0]
      new_comp_place = ent.add_instance new_comp, t
      new_comp_place.explode
    end # basket_change
    
    def change_Bracket(e,new_comp)
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      if su_type.include?("furniture") || su_type.include?("bracket")
        if e.definition.name.include?("Навес") && e.definition.name.include?("Скрытый")
          e.erase!
          elsif a03_name.include?("Подвес") && !e.definition.get_attribute("dynamic_attributes", "a00_lenz")
          e.erase!
          elsif a03_name.include?("Навес") || a03_name.include?("навес") || a03_name.include?("Подвес") || su_type.include?("bracket")
          e.make_unique
          e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
          bracket_change(e,new_comp)
        end
        elsif su_type.include?("back")
        @back_panels << e
        elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || e.definition.name.include?("body") || e.definition.name.include?("Body")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        @module_lenx = e.definition.get_attribute("dynamic_attributes", "lenx", 0)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Bracket(e,new_comp) }
      end
    end #def change_Bracket
    def bracket_change(ent,new_comp)
      a00_lenz = ent.definition.get_attribute("dynamic_attributes", "a00_lenz")
      if a00_lenz
        att_hash,att_hash2 = get_all_att(ent)
        e_parent = ent.parent
        t = ent.transformation
        ent.erase!
        new_comp_place = e_parent.entities.add_instance new_comp, t
        new_comp_place.definition.name = "Навес"
        new_comp_place.make_unique
        new_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if new_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
        _point_y_offset_formula = new_comp_place.definition.get_attribute("dynamic_attributes", "_point_y_offset_formula")
        if !_point_y_offset_formula
          att_hash2["_point_y_offset_formula"] = "0"
          else
          att_hash2["_point_y_offset_formula"] = _point_y_offset_formula
        end
        
        set_all_att(new_comp_place,att_hash,att_hash2,["a_name_left","a_name_left_cap","a_name_right","a_name_right_cap","a_name_shina","back_cut_y","back_cut_z"])
        new_comp_place.definition.delete_attribute("dynamic_attributes", "_a00_lenx_formula")
        new_comp_place.definition.delete_attribute("dynamic_attributes", "_a00_leny_formula")
        new_comp_place.definition.delete_attribute("dynamic_attributes", "_a00_lenz_formula")
        new_comp_place.definition.set_attribute("dynamic_attributes", "_lenx_formula", 'a00_lenx')
        new_comp_place.definition.set_attribute("dynamic_attributes", "_leny_formula", 'a00_leny')
        new_comp_place.definition.set_attribute("dynamic_attributes", "_lenz_formula", 'a00_lenz')
        new_comp_place.definition.set_attribute("dynamic_attributes", "_hidden_formula", 'CHOOSE(LOOKUP("c7_naves",2),1,0,1)')
        DCProgressBar::clear()
        new_comp_place.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
          Redraw_Components.redraw(body,false)
          Redraw_Components.run_all_formulas(body) if body.hidden?
          setname = body.definition.get_attribute("dynamic_attributes", "setname")
          if @module_lenx != 0
            if new_comp_place.transformation.origin.x < @module_lenx/2
              if setname
                new_comp_place.definition.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[0])
                new_comp_place.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[0])
                if setname.split(";")[2]
                  new_comp_place.definition.set_attribute("dynamic_attributes", "y1_name", setname.split(";")[2])
                  new_comp_place.set_attribute("dynamic_attributes", "y1_name", setname.split(";")[2])
                end
              end
              else
              xaxis = new_comp_place.transformation.xaxis
              if setname
                new_comp_place.definition.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[1])
                new_comp_place.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[1])
                if setname.split(";")[3]
                  new_comp_place.definition.set_attribute("dynamic_attributes", "y1_name", setname.split(";")[3])
                  new_comp_place.set_attribute("dynamic_attributes", "y1_name", setname.split(";")[3])
                end
                if new_comp_place.definition.get_attribute("dynamic_attributes", "_point_x_offset_formula", "0") == '-LOOKUP("b1_p_thickness",1.6)'
                  new_comp_place.definition.set_attribute("dynamic_attributes", "_point_x_offset_formula", 'LOOKUP("b1_p_thickness",1.6)')
                end
                if xaxis.x == 1
                  new_comp_place.transform!(Geom::Transformation.scaling(new_comp_place.transformation.origin, -1, 1, 1))
                end
              end
              myentities = new_comp_place.definition.entities
              myentities.transform_entities(Geom::Transformation.scaling(new_comp_place.transformation.origin, -1, 1, 1), myentities.to_a)
            end
          end
        }
        Redraw_Components.redraw(new_comp_place,false)
        DCProgressBar::clear()
        else
        _x_formula,_y_formula,_z_formula = position_formula(ent)
        e_parent = ent.parent
        t = ent.transformation
        ent.erase!
        new_comp_place = e_parent.entities.add_instance new_comp, t
        new_comp_place.definition.name = "Навес"
        new_comp_place.make_unique
        new_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if new_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
        new_comp_place.set_attribute("dynamic_attributes", "_x_formula", _x_formula) if _x_formula
        new_comp_place.set_attribute("dynamic_attributes", "_y_formula", "0")
        if _z_formula
          if _z_formula == 'LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness")'
            new_comp_place.set_attribute("dynamic_attributes", "_z_formula", 'LOOKUP("a0_lenz")')
            new_comp_place.set_attribute("dynamic_attributes", "_point_z_offset_formula", '-LOOKUP("b1_p_thickness",1.6)')
            else
            new_comp_place.set_attribute("dynamic_attributes", "_z_formula", _z_formula)
          end
        end
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__x_formula", _x_formula) if _x_formula
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__y_formula", "0")
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__z_formula", _z_formula) if _z_formula
        DCProgressBar::clear()
        new_comp_place.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
          body.make_unique
          body.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if body.parent.is_a?(Sketchup::ComponentDefinition)
          Redraw_Components.redraw(body,false)
          setname = body.definition.get_attribute("dynamic_attributes", "setname")
          if @module_lenx != 0
            if new_comp_place.transformation.origin.x < @module_lenx/2
              if setname
                new_comp_place.definition.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[0])
                new_comp_place.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[0])
              end
              else
              xaxis = new_comp_place.transformation.xaxis
              if setname
                new_comp_place.definition.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[1])
                new_comp_place.set_attribute("dynamic_attributes", "a03_name", setname.split(";")[1])
                if xaxis.x == 1
                  new_comp_place.transform!(Geom::Transformation.scaling(new_comp_place.transformation.origin, -1, 1, 1))
                end
              end
              myentities = new_comp_place.definition.entities
              myentities.transform_entities(Geom::Transformation.scaling(new_comp_place.transformation.origin, -1, 1, 1), myentities.to_a)
            end
          end
        }
        new_comp_place.definition.entities.grep(Sketchup::Group).to_a.each { |body| body.erase! }
        Redraw_Components.redraw(new_comp_place,false)
        DCProgressBar::clear()
      end
    end # basket_change
    def get_all_att(ent,att_arr=[])
      att_hash = {}
      att_hash2 = {}
      dict = ent.attribute_dictionary "dynamic_attributes"
      att_arr==[] ? all_att_arr = dict.keys : all_att_arr = att_arr
      dict.each_pair {|k, v| att_hash[k] = v if all_att_arr.any? {|att| k.include?(att) }} if dict
      dict2 = ent.definition.attribute_dictionary "dynamic_attributes"
      att_arr==[] ? all_att_arr = dict2.keys : all_att_arr = att_arr
      dict2.each_pair {|k, v| att_hash2[k] = v if all_att_arr.any? {|att| k.include?(att) }} if dict2
      return att_hash,att_hash2
    end
    def set_all_att(ent,att_hash,att_hash2,exceptions=[])
      att_hash.each_pair {|k,v| ent.set_attribute("dynamic_attributes", k, v) if !exceptions.include?(k)}
      att_hash2.each_pair {|k,v| ent.definition.set_attribute("dynamic_attributes", k, v) if !exceptions.include?(k)}
    end
    def delete_att(ent,att_hash,att_hash2,att_arr=[])
      att_hash.each_pair {|k,v| ent.delete_attribute("dynamic_attributes", k) if att_arr.any? {|att| k.include?(att)}; ent.definition.delete_attribute("dynamic_attributes", k) if att_arr.any? {|att| k.include?(att)}}
      att_hash2.each_pair {|k,v| ent.delete_attribute("dynamic_attributes", k) if att_arr.any? {|att| k.include?(att)}; ent.definition.delete_attribute("dynamic_attributes", k) if att_arr.any? {|att| k.include?(att)}}
    end
    def change_leg(ent,new_comp)
      su_type = ent.definition.get_attribute("dynamic_attributes", "su_type", "0")
      if su_type.include?("furniture") || su_type.include?("leg")
        leg = false
        if su_type.include?("leg")
          leg = true
          else
          ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e|
            leg = true if e.definition.name.downcase.include?("leg")
            e.erase! if leg
          }
        end
        if leg
          ent.definition.entities.grep(Sketchup::Group).to_a.each { |e| e.erase! }
          ent.make_unique
          ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
          t = Geom::Transformation.translation [0, 0, 0]
          new_comp_place = ent.definition.entities.add_instance new_comp, t
          a03_name = new_comp.get_attribute("dynamic_attributes", "a03_name", "0")
          a03_name_formula = new_comp.get_attribute("dynamic_attributes", "_a03_name_formula")
          att_hash,att_hash2 = get_all_att(new_comp_place,["a01_plint_support_pos_y","a01_plint_support_pos_y_set","a01_trim","a01_trim_set","a01_plint_x1","a01_plint_x1_set","a01_plint_x2","a01_plint_x2_set","y1_name","y1_quantity","y1_unit","y2_name","y2_quantity","y2_unit","y3_name","y3_quantity","y3_unit","y4_name","y4_quantity","y4_unit","y5_name","y5_quantity","y5_unit"])
          new_comp_place.explode
          set_all_att(ent,att_hash,att_hash2)
          ent.definition.name = new_comp.name
          if a03_name_formula
            ent.definition.set_attribute("dynamic_attributes", "_a03_name_formula", a03_name_formula)
            else
            ent.definition.delete_attribute("dynamic_attributes", "_a03_name_formula")
          end
          ent.definition.set_attribute("dynamic_attributes", "a03_name", a03_name)
          ent.set_attribute("dynamic_attributes", "a03_name", a03_name)
          @leg_components << ent
          Redraw_Components.redraw(ent,false)
          delete_att(ent,att_hash,att_hash2,["a01_plint_support_pos_y","a01_plint_support_pos_y_set","a01_trim","a01_trim_set","a01_plint_x1","a01_plint_x1_set","a01_plint_x2","a01_plint_x2_set"])
        end
        elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || ent.definition.name.include?("body") || ent.definition.name.include?("Body")
        ent.make_unique
        ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
        ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_leg(e,new_comp) }
      end
    end
    def change_Dryer(e,new_comp)
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      if su_type.include?("furniture") && a03_name.include?("Сушка") || su_type.include?("dryer")
        _x_formula,_y_formula,_z_formula = position_formula(e)
        e_parent = e.parent
        t = e.transformation
        e.erase!
        new_comp_place = e_parent.entities.add_instance new_comp, t
        new_comp_place.set_attribute("dynamic_attributes", "_x_formula", _x_formula) if _x_formula
        new_comp_place.set_attribute("dynamic_attributes", "_y_formula", _y_formula) if _y_formula
        new_comp_place.set_attribute("dynamic_attributes", "_z_formula", _z_formula) if _z_formula
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__x_formula", _x_formula) if _x_formula
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__y_formula", _y_formula) if _y_formula
        new_comp_place.definition.set_attribute("dynamic_attributes", "_inst__z_formula", _z_formula) if _z_formula
        Redraw_Components.redraw_entities_with_Progress_Bar([new_comp_place])
        elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || e.definition.name.include?("Body")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Dryer(e,new_comp) }
      end
    end #def change_Dryer
    
    def change_Lift(e, new_comp)
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      if su_type.include?("lift")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        lift_change(e, new_comp)
        e.set_attribute("dynamic_attributes", "a03_name", new_comp.name)
        e.definition.set_attribute("dynamic_attributes", "a03_name", new_comp.name)
        e.definition.set_attribute("dynamic_attributes", "_a03_name_label", "a03_name")
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif su_type.include?("furniture") || su_type.include?("module") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || su_type.include?("frontal") || e.definition.name.include?("Body")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Lift(e, new_comp) }
      end
    end #def change_Lift
    def lift_change(lift_ent, new_comp)
      lift_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body| body.erase! }
      ent = lift_ent.definition.entities
      t = Geom::Transformation.translation [0, 0, 0]
      new_comp_place = ent.add_instance new_comp, t
      new_comp_place.explode
      Redraw_Components.redraw_entities_with_Progress_Bar([lift_ent])
    end # lift_change
    
    def change_Profile(e, new_comp)
      if e.definition.name.include?("Дверь купе")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        profile_change(e, new_comp)
        elsif e.definition.name.include?("Двери купе")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Profile(e, new_comp) }
        Redraw_Components.redraw_entities_with_Progress_Bar([e],true)
        else
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| change_Profile(e, new_comp) }
      end
    end #def change_Profile
    def profile_change(door_ent, new_comp)
      @body_hash = {}
      door_ent.definition.entities.grep(Sketchup::Group).to_a.each { |shell| shell.erase! }
      door_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
        if body.definition.name.include?("Body")
          search_body(nil,body,false)
          else
          body.erase! 
        end
      }
      @old_body = @body_hash
      ent = door_ent.definition.entities
      t = Geom::Transformation.translation [0, 0, 0]
      new_comp_place = ent.add_instance new_comp, t
      if @new_body == {}
        @body_hash = {}
        new_comp_place.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
          if body.definition.name.include?("Body")
            @y_formula = body.definition.get_attribute("dynamic_attributes", "_inst__y_formula")
            search_body(new_comp_place,body,true)
          end
        }
        @new_body = @body_hash
      end
      @old_body.each_pair { |body,section_name|
        @new_body.each_pair { |new_body,new_body_section_name|
          if section_name.include?(new_body_section_name)
            parent = body.parent
            body.erase!
            t = Geom::Transformation.translation [0, 0, 0]
            parent.entities.add_instance new_body.definition, t
          end
        }
      }
      new_comp_place.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
        body.erase! if !body.deleted? && body.definition.name.include?("Body")
      }
      door_ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |body|
        if body.definition.name.include?("Body")
          body.set_attribute("dynamic_attributes", "_y_formula", @y_formula) if @y_formula
          body.definition.set_attribute("dynamic_attributes", "_inst__y_formula", @y_formula) if @y_formula
          set_att_frontal(body)
        end
      }
      Redraw_Components.redraw_entities_with_Progress_Bar([new_comp_place])
      new_comp_place.explode
    end # profile_change
    
    def search_body(new_comp_place,ent,split_text)
      if ent.definition.name.include?("Разделитель")
        body_arr = ent.parent.instances
        body_arr.each { |body|
          section = body.parent.instances[0].parent.instances[0]
          new_comp_place && new_comp_place == section ? section_name = "Дверь купе" : section_name = section.definition.name
          section_name = section_name.split("#")[0] if split_text
          @body_hash[body] = section_name if !@body_hash.value?(section_name)
        }
        elsif ent.definition.name.include?("Фронтальная")
        @y1_name_formula = ent.definition.get_attribute("dynamic_attributes", "_y1_name_formula")
        @y1_quantity = ent.definition.get_attribute("dynamic_attributes", "_y1_quantity_formula")
        @y2_name_formula = ent.definition.get_attribute("dynamic_attributes", "_y2_name_formula")
        @y2_quantity = ent.definition.get_attribute("dynamic_attributes", "_y2_quantity_formula")
        ent.set_attribute("dynamic_attributes", "_y_formula", "0")
        ent.definition.set_attribute("dynamic_attributes", "_inst__y_formula", "0")
        Redraw_Components.redraw_entities_with_Progress_Bar([ent])
        else
        ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| search_body(new_comp_place,e,split_text) }
      end
    end#def
    def set_att_frontal(ent)
      if ent.definition.name.include?("Фронтальная")
        if @y1_name_formula
          ent.definition.set_attribute("dynamic_attributes", "_y1_name_formula", @y1_name_formula)
          ent.definition.set_attribute("dynamic_attributes", "_y1_quantity_formula", @y1_quantity) if @y1_quantity
          ent.definition.set_attribute("dynamic_attributes", "y1_unit", "м")
          ent.set_attribute("dynamic_attributes", "y1_unit", "м")
          else
          ent.definition.set_attribute("dynamic_attributes", "_y1_name_formula", "1")
          ent.definition.set_attribute("dynamic_attributes", "_y1_quantity_formula", "1")
          ent.definition.set_attribute("dynamic_attributes", "y1_unit", "шт")
          ent.set_attribute("dynamic_attributes", "y1_unit", "шт")
        end
        if @y2_name_formula
          ent.definition.set_attribute("dynamic_attributes", "_y2_name_formula", @y2_name_formula)
          ent.definition.set_attribute("dynamic_attributes", "_y2_quantity_formula", @y2_quantity) if @y2_quantity
          ent.definition.set_attribute("dynamic_attributes", "y2_unit", "м")
          ent.set_attribute("dynamic_attributes", "y2_unit", "м")
          else
          ent.definition.set_attribute("dynamic_attributes", "_y2_name_formula", "1")
          ent.definition.set_attribute("dynamic_attributes", "_y2_quantity_formula", "1")
          ent.definition.set_attribute("dynamic_attributes", "y2_unit", "шт")
          ent.set_attribute("dynamic_attributes", "y2_unit", "шт")
        end
        else
        ent.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |e| set_att_frontal(e) }
      end
    end#def
    def position_formula(ent)
      _x_formula = ent.get_attribute("dynamic_attributes", "_x_formula")
      _x_formula = ent.definition.get_attribute("dynamic_attributes", "_inst__x_formula") if !_x_formula
      _y_formula = ent.get_attribute("dynamic_attributes", "_y_formula")
      _y_formula = ent.definition.get_attribute("dynamic_attributes", "_inst__y_formula") if !_y_formula
      _z_formula = ent.get_attribute("dynamic_attributes", "_z_formula")
      _z_formula = ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula") if !_z_formula
      return _x_formula,_y_formula,_z_formula
    end#def
    def set_att(e,att,value,label=nil,access=nil,formlabel=nil,formulaunits=nil,units=nil,formula=nil,options=nil)
      e.set_attribute('dynamic_attributes', att, value) if value
      e.definition.set_attribute('dynamic_attributes', att, value) if value
      label ? e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label) : e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula) if formula
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end#def
  end # class ChangeComponents
end # module SU_Furniture

