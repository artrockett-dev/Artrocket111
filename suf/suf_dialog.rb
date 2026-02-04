module SU_Furniture
  class SUFDialog
    def activate
      $add_component = 0
			@mat_list = false
      $dlg_suf = UI::HtmlDialog.new({
        :dialog_title => PLUGIN_NAME+"_"+PLUGIN_VERSION,
        :preferences_key => "suf",
        :scrollable => true,
        :resizable => true,
        :width => 340,
        :height => 580,
        :left => 100,
        :top => 200,
        :min_width => 340,
        :min_height => 340,
        :max_width =>1000,
        :max_height => 1000,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      html_path = PATH + "/html/SU_Furniture.html"
      $dlg_suf.set_file(html_path)
      $dlg_suf.show()
      $dlg_suf.add_action_callback("get_data") { |web_dialog,action_name|
        
        if action_name=="end_of_dialog"
          $dlg_suf.close
          $dlg_suf=nil
          result=0
          
          elsif action_name.to_s.include?("read_param")
					#Change_Materials.list
          param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
					if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
						path_param = File.join(param_temp_path,"parameters.dat")
						elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
						path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
						else
						path_param = File.join(PATH,"parameters","parameters.dat")
          end
          content = File.readlines(path_param)
          activate_item = "no"
          content.each { |i| 
            activate_item = i.strip.split("=")[2] if i.strip.split("=")[1] == "activate_item"
          }
          if activate_item != "no"
            vend = activate_item
            command = "activate_item(#{vend.inspect})"
            $dlg_suf.execute_script(command)
          end
          
          elsif action_name.to_s.include?("update_dialog")
          Update_lib.update_dialog()
          
          elsif action_name.to_s.include?("sendComp")
          Change_Components.comp_from_dialog(action_name)
          
          elsif action_name[0..3]=="comp"
          $attobserver = 1
          result = Change_Components.list
          Change_Components.list if result
          
          elsif action_name.include?("delete_comp")
          file_name = action_name[12..-1]
          File.delete(PATH_COMP+"/" + file_name + ".skp") if File.file?( PATH_COMP+"/" + file_name + ".skp" )
          File.delete(PATH_COMP+"/" + file_name + ".png") if File.file?( PATH_COMP+"/" + file_name + ".png" )
          Change_Components.list
          
          elsif action_name[0..2]=="att"
          $attobserver = 2
          Change_Attributes.attributes_list
          
          elsif action_name.include?("hidden_att")
          param = action_name[11..action_name.length-1]
          att = param.split('/')[0]
          val = param.split('/')[1]
          Change_Attributes.hide_att(att, val)
          
          elsif action_name.include?("set_position_att")
          Change_Attributes.set_position_att()
          
          elsif action_name.include?("сlick_att")
          Change_Attributes.сlick_att(action_name.split('/')[1])
          
          elsif action_name.include?("copied_att")
          vend = Change_Attributes.copied_att
          $dlg_suf.execute_script("set_copied_att(#{vend.inspect})")
          
          elsif action_name.include?("add_attribute")
          Change_Attributes.add_attribute()
          
          elsif action_name.include?("draw_section")
          Change_Attributes.draw_section(action_name.split('/')[1])
					
					elsif action_name.include?("delete_section")
          Change_Attributes.delete_section(action_name.split('/')[1])
          
          elsif action_name.include?("select_tool")
          Sketchup.active_model.select_tool(nil)
          
          elsif action_name.include?("edit_additional")
          Change_Attributes.edit_name_list("additional.dat")
          
          elsif action_name.include?("edit_name_list")
          Change_Attributes.edit_name_list("panel_name.dat")
          
          elsif action_name.include?("copy_comp")
          Change_Attributes.copy_comp()
          
          elsif action_name.include?("axis_comp")
          Change_Attributes.axis_comp()
          
          elsif action_name.include?("check_visible_attribute")
          Change_Attributes.check_visible_attribute(action_name.split('/')[1])
          
          elsif action_name.include?("change_checkbox")
          Change_Attributes.change_checkbox(action_name.split('/')[1])
          
          elsif action_name[0] == "submit"
          my_str=action_name[1..action_name.length-1]
          Change_Attributes.change_attributes(my_str)
          
          elsif action_name[0..2]=="mat"
          $attobserver = 3
          @mat_list = Change_Materials.list if !@mat_list
          param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
					if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
						path_param = File.join(param_temp_path,"parameters.dat")
						elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
						path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
						else
						path_param = File.join(PATH,"parameters","parameters.dat")
          end
          content = File.readlines(path_param)
          edge_mat = "false"
          content.each { |i| 
            edge_mat = i.strip.split("=")[2] if i.strip.split("=")[1] == "edge_mat"
          }
          vend = edge_mat
          command = "change_edge_mat(#{vend.inspect})"
          $dlg_suf.execute_script(command)
          
          elsif action_name.include?("delete_mat")
          file_name = action_name[11..-1]
          File.delete(PATH_MAT+"/" + file_name) if File.file?(PATH_MAT+"/" + file_name)
          Change_Materials.list
          
          elsif action_name[0..3]=="list"
          $attobserver = 4
          entity = nil
          param = action_name[5..action_name.length-1]
          model = Sketchup.active_model
          model.start_operation 'Lists', true, false, true
          case param
            when "Accessories" then Report_lists.accessories_list(entity,{},true,true)
            when "Sheet" then Report_lists.sheets_list(entity)
            when "Linear" then Report_lists.linear_list(entity)
            when "Operations" then Report_lists.operations_list(entity)
            when "Cost" then Report_lists.cost(entity)
            when "Price" then SU_Price.price()
            end
          model.commit_operation
          
          elsif action_name.include?("model_name")
          command = "get_model_name(#{Sketchup.active_model.title.inspect})"
          $dlg_suf.execute_script(command)
          
          elsif action_name.include?("activate_price")
          SU_Price.price()
          
          elsif action_name.include?("rotate")
          param = action_name.split('/')
          Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).each { |ent| Report_lists.cut_rotate(ent,param[1],param[2]) }
          
          elsif action_name.include?("new_name")
          param = action_name.split('/')
          Sketchup.active_model.selection.remove_observer $SUFSelectionObserver
          Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).each { |ent| Report_lists.set_new_name(ent,param[1],param[2]) }
          if SU_Furniture.observers_state == 1
            Sketchup.active_model.selection.add_observer $SUFSelectionObserver
          end
          #Report_lists.sheets_list(nil)
          
          elsif action_name.include?("add_accessories")
          Report_lists.add_accessories()
          
          elsif action_name.include?("select_accessories")
          param = action_name.split('/')
          Sketchup.active_model.selection.remove_observer $SUFSelectionObserver
					Report_lists.select_accessories(param[1])
					$change_att = false
					$dlg_att.execute_script("add_comp()") if $dlg_att
          if SU_Furniture.observers_state == 1
            Sketchup.active_model.selection.add_observer $SUFSelectionObserver
          end
					
					elsif action_name.include?("select_holes")
          param = action_name.split('/')
          Sketchup.active_model.selection.remove_observer $SUFSelectionObserver
					Report_lists.select_holes(param[1])
					$change_att = false
					$dlg_att.execute_script("add_comp()") if $dlg_att
          if SU_Furniture.observers_state == 1
            Sketchup.active_model.selection.add_observer $SUFSelectionObserver
          end
          
          elsif action_name.include?("select_panel")
          param = action_name.split('/')[1]
          
          Sketchup.active_model.selection.remove_observer $SUFSelectionObserver
          Sketchup.active_model.selection.clear
          if param
            arr = param.split(",")
            Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).each { |ent| Report_lists.select_panel(ent,arr) }
            if SU_Furniture.observers_state == 1
              Sketchup.active_model.selection.add_observer $SUFSelectionObserver
            end
            else
            if SU_Furniture.observers_state == 1
              Sketchup.active_model.selection.add_observer $SUFSelectionObserver
            end
          end
          
					elsif action_name.include?("change_auto_refresh")
          param = action_name.split('/')
					Report_lists.change_auto_refresh(param[1])
          
          elsif action_name.include?("change_panel_size")
          param = action_name.split('/')
					Report_lists.change_panel_size(param[1])
					
          elsif action_name.include?("grain")
          param = action_name.split('/')
          Report_lists.param_mat_graned(param[1],param[2])
          
          elsif action_name.include?("save_currency_rate")
          param = action_name.split('/')
          if param[1]
            currency_rate = param[1].split(',')
            path_currency_rate = PATH_PRICE + "/currency.dat"
            file_currency_rate = File.new(path_currency_rate,"w")
            currency_rate.each { |currency| file_currency_rate.puts currency}
            file_currency_rate.close
          end
          
          elsif action_name.include?("follow_the_link")
          Report_lists.follow_the_link(action_name.split('=>')[1])
          
          elsif action_name.include?("save_currency")
          currency = action_name.split('=>')[1]
          currency_name = action_name.split('=>')[2]
          currency_file = PATH_PRICE + "/currency.dat"
          new_file = File.open currency_file, "w"
          new_file.write currency+"=1="+currency_name+"\n"
          new_file.write "EUR=1\n"
          new_file.write "USD=1\n"
          new_file.close
          
          elsif action_name[0..7]=="cut_list"
          param_mat = action_name.split('<=>')
          Report_lists.cutting_dialog(param_mat[1])
          
          elsif action_name[0..14]=="copyToClipboard"
          param_mat = action_name.split('<=>')
          material_array = param_mat[1].split("=>")
          prog = param_mat[2]
          Report_lists.copyToClipboard(material_array,prog)
          
          elsif action_name.to_s.include?("export_list")
          active = action_name.split('<=>')[1]
          Report_lists.export_list(active)
          
          elsif action_name == "selection"
          sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
          if sel.count == 0
            vend = "false"
            command = "selected_comp(#{vend.inspect})"
            $dlg_suf.execute_script(command)
            else
            vend = [sel[0].definition.name]
            command = "selected_comp(#{vend.inspect})"
            $dlg_suf.execute_script(command)
          end
          
          elsif action_name == "pick"
          my_tool = PickMat.new
          Sketchup.active_model.tools.push_tool(my_tool)
          
          elsif action_name[0..5] == "search"
          param_mat = action_name.split('/')
          change_for_type = param_mat[1]
          new_mat_name = param_mat[2].gsub("^","/")
          patina_name = param_mat[3]
          patina_arr = param_mat[4]
          edge_mat = param_mat[5]
          type_mat = Change_Materials.search(new_mat_name,change_for_type)
          Change_Materials.replace_mat(change_for_type,new_mat_name,type_mat,patina_name,patina_arr,edge_mat)
          
          elsif action_name.to_s.include?("load_material")
          param_mat = action_name.split('/')
          change_for_type = param_mat[1]
          type_mat = param_mat[2].gsub("^","/")
          frontal_section = param_mat[3]
          frontal_vendor = param_mat[4]
          Change_Materials.load_material(change_for_type,type_mat,frontal_section,frontal_vendor)
          
          elsif action_name.to_s.include?("sendMat")
          param_mat = action_name.split('/')
          change_for_type = param_mat[1]
          type_mat = param_mat[2].gsub("^","/")
          new_mat_name = param_mat[3]
          patina_name = param_mat[4]
          patina_arr = param_mat[5]
          edge_mat = param_mat[6]
          Change_Materials.replace_mat(change_for_type,new_mat_name,type_mat,patina_name,patina_arr,edge_mat)
          elsif action_name.to_s.include?("registration_code")
              js = %(receiveData('registration_code', #{JSON.generate($registration_code).inspect}))
              $dlg_suf.execute_script(js)
          elsif action_name.to_s.include?("project_id")
            model = Sketchup.active_model
            path     = model.path            # full path to the current SKP ("" if never saved)
            filename = File.basename(path)   # e.g. "House.skp"
            name     = File.basename(path, '.*') # e.g. "House" (no extension)
            title    = model.title   
            js = %(receiveData('project_id', #{JSON.generate(title).inspect}))
            $dlg_suf.execute_script(js)
          elsif action_name.to_s.include?("path_materials")
            js = %(receiveData('path_materials', #{JSON.generate(SU_Furniture::PATH_MAT).inspect}))
            $dlg_suf.execute_script(js)
          elsif action_name.to_s.include?("size_furniture")
            $dlg_suf.set_size(550, 580)
          elsif action_name.to_s.include?("size_attributes")
            $dlg_suf.set_size(1020, 765)
        end
      }
    end #def activate
    def self.refresh
      if !$dlg_suf || !$dlg_suf.visible?
        self.activate
        return
      end

      $dlg_suf.execute_script(<<~JS)
        if (typeof refreshCurrentTab === "function") {
          refreshCurrentTab();
        }
      JS
    end
  end #end Class 
	
end
