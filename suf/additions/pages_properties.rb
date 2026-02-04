module SU_Furniture
  class PagesProperties
	  def initialize
		  @hidden_objects = []
		end#def
    def activate(entity)
      @model = Sketchup.active_model
      hide_new_objects = @model.get_attribute('pages_properties','hide_new_objects',"true")
      is_visible=$dlg_pages.visible? if $dlg_pages
      #$dlg_pages.close if $dlg_pages && (is_visible==true)
      if is_visible!=true
        $dlg_pages = UI::HtmlDialog.new({
          :dialog_title => "Pages_properties_"+PLUGIN_VERSION,
          :preferences_key => "pages",
          :scrollable => false,
          :resizable => false,
          :width => 180,
          :height => 110,
          :left => 50,
          :top => 200,
          :min_width => 180,
          :min_height => 110,
          :max_width =>180,
          :max_height => 110,
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
        html_path = PATH + "/html/Pages_properties.html"
        $dlg_pages.set_file(html_path)	
        $dlg_pages.show()
        $dlg_pages.add_action_callback("get_data") { |web_dialog,action_name|
          if action_name.to_s.include?("read_param")
            read_param(hide_new_objects)
            elsif action_name.to_s.include?("hide_new_objects")
            @model.set_attribute('pages_properties','hide_new_objects',action_name.split("=>")[1])
            hide_show_entity(@model,[entity],action_name.split("=>")[1])
          end
        }
      end
      hide_show_entity(@model,[entity],hide_new_objects)
    end#def
    def hide_show_entity(model,ents,hide_new_objects)
      pages = model.pages
      if pages.count < 1
        UI.messagebox(SUF_STRINGS["No scenes created"])
        elsif pages.count < 2
        UI.messagebox(SUF_STRINGS["Only one scene exists"])
        elsif hide_new_objects == "true"
        if Sketchup.version_number >= 2000000000
          @flags = PAGE_USE_HIDDEN_GEOMETRY | PAGE_USE_HIDDEN_OBJECTS | PAGE_USE_LAYER_VISIBILITY
          else
          @flags = PAGE_USE_HIDDEN | PAGE_USE_LAYER_VISIBILITY
        end
        view = model.active_view
        last_camera=save_Camera(view.camera)
        display_shadows = model.shadow_info["DisplayShadows"]
        visible_layer = {}
        model.start_operation "hide_show_entity", true, false, true
        model.layers.each { |l| visible_layer[l] = l.visible? }
        selected_page = pages.selected_page
        time = selected_page.transition_time
        selected_page.transition_time=0
        pages.each { |page|
          if page != selected_page
            pages.selected_page = page
            ents.each { |entity| entity.hidden = true }
            page.update(@flags)
          end
        }
        ents.each { |entity| entity.hidden = false }
        pages.selected_page = selected_page
        selected_page.transition_time=time
        set_Camera(last_camera)
        model.shadow_info["DisplayShadows"] = display_shadows
        visible_layer.each_pair { |l,v| l.visible = v if !l.deleted? } if visible_layer
        model.commit_operation
        view.invalidate
      end
    end#def
		def hide_other(model,sel,ents)
		  model.start_operation SUF_STRINGS["Hide other"], true
		  @hidden_objects = ents - sel
		  @hidden_objects.each { |entity| entity.hidden = true }
			model.commit_operation
		end
		def show_hidden_objects(model)
		  model.start_operation SUF_STRINGS["Show hidden objects"], true
		  @hidden_objects.each { |entity| entity.hidden = false }
			model.commit_operation
		end
    def save_Camera(camera=Sketchup.active_model.active_view.camera)
      values = [camera.eye,camera.target,camera.up,camera.perspective?]
      if camera.perspective?
        values.concat([camera.fov,camera.aspect_ratio,camera.focal_length,camera.image_width])
        else
        values.concat([nil,camera.aspect_ratio,camera.height,nil])
      end
      return values
    end#def
    def set_Camera(values)
      eye,target,up,pers,fov,ar,fl,iw = values
      if pers
        cam1 = Sketchup::Camera.new(eye,target,up,pers,fov)
        cam1.aspect_ratio = ar
        cam1.focal_length = fl
        cam1.image_width = iw
        else
        cam1 = Sketchup::Camera.new(eye,target,up,pers)
        cam1.aspect_ratio = ar
        cam1.height = fl
      end
      Sketchup.active_model.active_view.camera = cam1
    end#def
    def read_param(hide_new_objects)
      vend = [hide_new_objects]
      command = "parameters(#{vend.inspect})"
      $dlg_pages.execute_script(command)
    end#def
  end #end Class 
end
