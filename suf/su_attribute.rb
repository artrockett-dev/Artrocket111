module SU_Furniture
  class SUAttribute
    def activate
      level = 1
      $dlg_att = UI::HtmlDialog.new({
        :dialog_title => SUF_STRINGS["Component Options"]+" "+PLUGIN_NAME,
        :preferences_key => "su_att",
        :scrollable => true,
        :resizable => true,
        :width => 340,
        :height => 580,
        :left => 100,
        :top => 200,
        :min_width => 340,
        :min_height => 340,
        :max_width =>800,
        :max_height => 1000,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      html_path = PATH + "/html/SU_Attribute.html"
      $dlg_att.set_file(html_path)
      $dlg_att.show()
      $dlg_att.add_action_callback("get_att_data") { |web_dialog,action_name|
        
        if action_name=="end_of_dialog"
          $dlg_att.close
          $dlg_att=nil
          
          elsif action_name[0..2]=="att"
          Attributes_List.attributes_list
          
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
          $dlg_att.execute_script("set_copied_att(#{vend.inspect})")
          
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
          
          elsif action_name.include?("axis_comp")
          Change_Attributes.axis_comp()
          
          elsif action_name.include?("copy_comp")
          Change_Attributes.copy_comp()
          
          elsif action_name.include?("check_visible_attribute")
          Change_Attributes.check_visible_attribute(action_name.split('/')[1])
          
          elsif action_name.include?("change_checkbox")
          Change_Attributes.change_checkbox(action_name.split('/')[1])
          
          elsif action_name[0] == "submit"
          my_str=action_name[1..action_name.length-1]
          Attributes_List.change_attributes(my_str)
          
          elsif action_name == "selection"
          sel = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
          if sel.count == 0
            vend = "false"
            command = "selected_comp(#{vend.inspect})"
            $dlg_att.execute_script(command)
            else
            vend = [sel[0].definition.name]
            command = "selected_comp(#{vend.inspect})"
            $dlg_att.execute_script(command)
          end
          
        end
      }
    end #def activate
    
  end #end Class 
  
end
