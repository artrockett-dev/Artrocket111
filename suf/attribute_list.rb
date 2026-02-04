module SU_Furniture
	class AttributesList
		def attributes_list(entity=nil)
			@access_att = []
      @param_delete_hidden,@att_mode,@itemcode_to_name,@name_list,@edge_color_arr,@hidden_att,@panel_name_list,@global_options,@param_hash = Change_Attributes.read_param
			@sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a
			entity ? sel = [entity] : sel = @sel
			sel_length = sel.length
			tool_name = Sketchup.active_model.tools.active_tool_name
			if sel_length == 0
        command = "clear_selection()"
				$dlg_att.execute_script(command)
        else
				Sketchup.active_model.start_operation('att_list', true, false, true)
				@sections,@section_and_tr,@panel_section_hash,@shelve_section_hash,@drawer_section_hash,@accessory_section_hash,@frontal_hash = Change_Attributes.all_sections(sel)
				@section_array = Change_Attributes.sort_sections_array(@sections)
        @list_of_att,@list_of_hidden_att = Change_Attributes.attributes_of_all_selection(sel,@global_options,@access_att)
        @list_len,@list_of_attributes = Change_Attributes.list_of_att_all(@sel)
				Change_Attributes.name_to_dialog(sel[0],sel_length)
				attributes_to_dialog()
				Sketchup.active_model.commit_operation
      end
    end#def
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
                  $dlg_att.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_panel_section_"+panel_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_att.execute_script(command)
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
                  $dlg_att.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_shelve_section_"+shelve_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_att.execute_script(command)
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
                  $dlg_att.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_drawer_section_"+drawer_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_att.execute_script(command)
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
                  $dlg_att.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_accessory_section_"+accessory_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_att.execute_script(command)
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
                  $dlg_att.execute_script(command)
                  arr[0].each {|list|
                    list[0] += "_frontal_section_"+frontal_index.to_s
                    vend = list
                    command = "attribute_list(#{vend.inspect})"
                    $dlg_att.execute_script(command)
                  }
                  frontal_index -= 1
                end
              }
            end
          }
          Change_Attributes.panel_sections(@panel_sections)
          Change_Attributes.shelve_sections(@shelve_sections)
          Change_Attributes.drawer_sections(@drawer_sections)
          Change_Attributes.accessory_sections(@accessory_sections)
          Change_Attributes.frontal_sections(@frontal_sections)
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
				formulaunits = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formulaunits","0")
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
					value = Change_Attributes.round_without_zero(value.to_f*25.4,2) if formulaunits == "CENTIMETERS"
					options = ent.get_attribute("dynamic_attributes", "_" + attr + "_options","0")
					options = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_options","0") if options == "0"
					@options_typ, @options_val = Change_Attributes.options_array(ent,attr,"=",formulaunits,options)
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
              $dlg_att.execute_script(command)
              elsif @options_typ == "%u0414%u0430;%u041D%u0435%u0442"
              access = "CHECKBOX"
              if !value.include?("=>")
                value == @options_val.split(";")[0] ? value = "=>1" : value = "=>0"
              end
              vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
              command = "attribute_list(#{vend.inspect})"
              $dlg_att.execute_script(command)
              else
              value = value.to_f.round if Change_Attributes.is_number?(value)
              vend = [attr, access, @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide, att_formula.to_s]
              command = "attribute_list(#{vend.inspect})"
              $dlg_att.execute_script(command)
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
              @options_typ, @options_val = Change_Attributes.options_array(ent, "a09_"+attr+"_layer","=", "STRING",layer_options)
              Change_Attributes.set_att(ent,"a09_"+attr+"_layer",value,"a09_"+attr+"_layer","LIST","Слой панели","STRING","STRING",nil,layer_options)
              vend = ["a09_"+attr+"_layer", "LIST", "Слой панели", "STRING", value.to_s, @options_typ, @options_val, hide, ""]
              command = "attribute_list(#{vend.inspect})"
              $dlg_att.execute_script(command)
            end
          end
					elsif access == "TEXTBOX"
					if @name_list == "true" && attr == "a03_name" && ent.definition.get_attribute("dynamic_attributes", "edge_z1")
						vend = ["name_list", "VIEW", translation_formlabel('Список названий'), "STRING", translation_formlabel('Редактировать'), 0, 0, hide, ""]
						command = "attribute_list(#{vend.inspect})"
						$dlg_att.execute_script(command)
						vend = ["name_no_list", "TEXTBOX", translation_formlabel('Название не из списка'), "STRING", "", 0, 0, hide, "", value.to_s]
						command = "attribute_list(#{vend.inspect})"
						$dlg_att.execute_script(command)
						name_list = "&"
						@panel_name_list.each { |name| name_list += name+"="+name+"&" }
						name_list = "&"+value+"="+value+name_list if !name_list.include?(value)
						@options_typ, @options_val = Change_Attributes.options_array(ent, "a03_name","=", "STRING",name_list)
						vend = [attr, "LIST", @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide,""]
						command = "attribute_list(#{vend.inspect})"
						$dlg_att.execute_script(command)
						else
						if attr == "a03_name"
							a03_path = ent.definition.get_attribute('dynamic_attributes', "a03_path")
							if a03_path && a03_path == "Slab"
								@formlabel = @formlabel + translation_formlabel(' (_Фрезеровка; без "_" - "Модерн")')
              end
            end
						value_mm = Change_Attributes.round_without_zero(value.to_f*25.4, 1)
						value = Change_Attributes.converter(value, units, formulaunits)
						value = "=" + value.to_s if formula && formula.to_f == value.to_f/10
						vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, att_formula.to_s]
						command = "attribute_list(#{vend.inspect})"
						$dlg_att.execute_script(command)
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
									Change_Attributes.set_att(ent,"a01_gluing",2,nil,"LIST",translation_formlabel('Склейка'),"FLOAT","STRING",'IF(OR(ROUND('+len_att+',1)=3.2,ROUND('+len_att+',1)=3.6),2,1)',"&Нет=1&х2=2&х3=3&х4=4&")
									else
									Change_Attributes.set_att(ent,"a01_gluing",1,nil,"LIST",translation_formlabel('Склейка'),"FLOAT","STRING",'IF(OR(ROUND('+len_att+',1)=3.2,ROUND('+len_att+',1)=3.6),2,1)',"&Нет=1&х2=2&х3=3&х4=4&")
                end
								@options_typ, @options_val = Change_Attributes.options_array(ent, "a01_gluing","=", "STRING","&Нет=1&х2=2&х3=3&х4=4&")
								vend = ["a01_gluing", "LIST", translation_formlabel('Склейка'), "STRING", "1", @options_typ, @options_val, false, ""]
								command = "attribute_list(#{vend.inspect})"
								$dlg_att.execute_script(command)
              end
            end
          end
          elsif access == "CHECKBOX"
          vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
          command = "attribute_list(#{vend.inspect})"
          $dlg_att.execute_script(command)
					elsif access == "VIEW"
					value = Change_Attributes.converter(value, units, formulaunits)
					vend = [attr, access, @formlabel, formulaunits, value.to_s, 0, 0, hide, ""]
					command = "attribute_list(#{vend.inspect})"
					$dlg_att.execute_script(command)
					if attr == "y0"
						vend = ["y0_edit", "VIEW", translation_formlabel('Список фурнитуры/крепежа'), "STRING", translation_formlabel('Редактировать'), 0, 0, hide, ""]
						command = "attribute_list(#{vend.inspect})"
						$dlg_att.execute_script(command)
          end
        end
        all_att_hash[attr] = attributes_hash
      }
			if @att_mode == "advanced" && @list_of_hidden_att != []
				advanced = ent.definition.get_attribute("dynamic_attributes", "zzz_advanced")
				advanced = "&#9654;" if !advanced
				Change_Attributes.set_att(ent, "zzz_advanced", advanced, "zzz_advanced", "VIEW", "<font color=cc6600><b>Дополнительные параметры<b></font>", nil, "STRING")
				hide = false
				$dlg_att.execute_script("attribute_list(#{["zzz_advanced", "VIEW", translation_formlabel('Дополнительные параметры'), "CENTIMETERS", advanced, 0, 0, hide, ""].inspect})")
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
						@options_typ, @options_val = Change_Attributes.options_array(ent,attr,"=",formulaunits,options)
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
						value = Change_Attributes.round_without_zero(value.to_f*25.4,1) if formulaunits == "CENTIMETERS"
						else
						value = Change_Attributes.round_without_zero(value.to_f*10,2) if !attr.include?("edge")
						value = Change_Attributes.round_without_zero(value.to_f*2.54,1) if formulaunits == "CENTIMETERS"
						value = value.to_s+" mm" if !attr.include?("edge")
          end
					value = value.to_f.round.to_s if Change_Attributes.is_number?(value)
					vend = [attr+"_|_"+access[0..3], access, @formlabel, formulaunits, value.to_s, @options_typ, @options_val, hide, ""]
					command = "attribute_list(#{vend.inspect})"
					$dlg_att.execute_script(command)
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
			$dlg_att.execute_script(command)
      Change_Attributes.set_attributes_hash(all_att_hash)
    end#def
		def translation_formlabel(formlabel)
			if SUF_ATT_STR.strings != {}
				SUF_ATT_STR.strings.each_pair{|str,trans|
					if formlabel.include?(str) && !Change_Attributes.letter?(formlabel[formlabel.index(str)+str.length])
						formlabel = formlabel.gsub(str,trans)
          end
        }
      end
			return formlabel
    end#def
		def change_attributes(str)
			@model = Sketchup.active_model
			att_for_change_body = ["c1_left_panel","c2_right_panel","c3_up_panel","c4_down_panel","c4_plint","c5_back","c7_naves","c8_middle_panel","falsh_panel_left","falsh_panel_right"]
			change_carcass_material = nil
			@body1 = nil
			@body2 = nil
			$change_param = true
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
          e = Change_Attributes.panel_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_shelve_section_")
          attr = att.split("_shelve_section_")[0]
          number = att.split("_shelve_section_")[1]
          e = Change_Attributes.shelve_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_drawer_section_")
          attr = att.split("_drawer_section_")[0]
          number = att.split("_drawer_section_")[1]
          e = Change_Attributes.drawer_sections[number.to_i]
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
          e = Change_Attributes.accessory_sections[number.to_i]
          att_arr << attr
          redraw_section << e if !redraw_section.include?(e)
          
          elsif att.include?("_frontal_section_")
          attr = att.split("_frontal_section_")[0]
          number = att.split("_frontal_section_")[1]
          e = Change_Attributes.frontal_sections[number.to_i]
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
              attr,delete_hidden,comp_path,change_carcass_material = Change_Attributes.change_deep(e, attr, value, nil, att_for_change_body, @itemcode_to_name)
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
				Change_Attributes.len_formula(ent)
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
					Change_Attributes.make_unique_if_needed(ent)
          if att == "s1_position_x" || att == "s1_position_y" || att == "s1_position_z"
            Change_Attributes.set_position(ent,att,value)
            next
          end
          if att == "s2_rotation_x" || att == "s2_rotation_y" || att == "s2_rotation_z"
            Change_Attributes.set_rotation(ent,att,value)
            next
          end
          if att == "s3_mirror_x" || att == "s3_mirror_y" || att == "s3_mirror_z"
            Change_Attributes.set_mirror(ent,att,value)
            next
          end
          if att == "s4_size_x" || att == "s4_size_y" || att == "s4_size_z"
            Change_Attributes.set_len_formula(ent,att,value)
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
                Change_Attributes.set_att(entity, "d1_type_height",value,nil,"TEXTBOX")
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
              attr,delete_hidden,comp_path,change_carcass_material = Change_Attributes.change_deep(ent, att, value, item_code, att_for_change_body, @itemcode_to_name)
              att_arr << attr
              else
              attr,delete_hidden,comp_path,change_carcass_material = Change_Attributes.change_deep(ent, att, value, item_code, att_for_change_body, @itemcode_to_name)
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
					Change_Attributes.cut_att(ent)
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
          Change_Attributes.size_values(ent,@sizes)
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
          Change_Attributes.check_checkbox(ent,"s9_scale_grip")
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
					SU_Furniture::Change_Materials.read_param(type_material)
					SU_Furniture::Change_Materials.change_Carcass_material(ent,change_carcass_material)
        end
				if delete_hidden && @param_delete_hidden == "yes"
					@body1.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
						@body2.definition.entities.add_instance(entity.definition, entity.transformation)
          }
					@body1.erase!
					Change_Attributes.delete_hidden_components(@body2)
					@body2.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
						entity.definition.name = Change_Attributes.my_uniq_defn_name(@model,entity.definition.name.split("#")[0])
          }
        end
				ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| Change_Attributes.delete_if(entity) }
				if att_arr.include?("c4_plint_size")
					ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| Change_Attributes.redraw_leg(entity,att_arr) }
        end
				if att_arr.include?("a00_lenx")
					drawers_section = Change_Attributes.search_drawers_section(ent)
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
										Change_Attributes.change_deep(ent, "a00_lenx", new_lenx, item_code, att_for_change_body, @itemcode_to_name)
										elsif @drawer_width_param == "increase"
										new_lenx = (a00_lenx*25.4+((1-difference)*drawers_count.to_i).round).to_s
										if new_lenx.to_f > x_max_x.to_f*10
											max_input = UI.messagebox("#{SUF_STRINGS["Maximum module width"]} #{(x_max_x.to_f*10).round} #{SUF_STRINGS["mm"]}!\n#{SUF_STRINGS["Increase maximum width"]}?",MB_YESNO)
											if max_input == IDYES
												Change_Attributes.set_att(ent, "x_max_x", (new_lenx.to_f/10).to_s)
												Change_Attributes.set_att(ent, "z_max_width", (new_lenx.to_f/10).to_s)
                      end
                    end
										Change_Attributes.change_deep(ent, "a00_lenx", new_lenx, item_code, att_for_change_body, @itemcode_to_name)
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
			$dlg_att.execute_script("add_comp()")
			$change_param = false
			$dlg_suf.execute_script("add_comp()") if $attobserver == 2
			@model.definitions.purge_unused
			@model.commit_operation
      if SU_Furniture.observers_state == 1
				@model.selection.add_observer $SUFSelectionObserver
				@model.entities.add_observer $SUFEntitiesObserver
      end
			Sketchup.focus if Sketchup.version_number >= 2110000000
    end#def
  end #end Class
end#end Module
