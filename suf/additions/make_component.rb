module SU_Furniture
  class MakeComponents
    def new_name(name,ents)
      prompts = [SUF_STRINGS["New name"]]
      defaults = [name]
      input = UI.inputbox(prompts, defaults, SUF_STRINGS["The name contains the symbol #"])
      if input
        if input[0].include?("#")
          new_name(name,ents)
          else
          unique_name = true
          ents.each { |e| unique_name = false if input[0] == e.name }
          if unique_name == true
            return input[0]
            else
            result=UI.messagebox("#{SUF_STRINGS["The model has a component with the same name"]}.\n#{SUF_STRINGS["The name must be unique"]}.\n#{SUF_STRINGS["Try to purge unused components from the model"]}?",MB_YESNO)
            if result==IDYES
              ents.purge_unused
            end
            new_name(name,ents)
          end
        end
        else
        return nil
      end
    end
    def make_Component
      @model = Sketchup.active_model
      ents = @model.definitions
      sel = @model.selection
      info = @model.shadow_info
			save_version = Sketchup::Model::VERSION_2021
			#save_version = Sketchup::Model::VERSION_2018
      if sel.count == 0
        UI.messagebox(SUF_STRINGS["No Components Selected"])
        return nil
        elsif sel.to_a.to_s.include?("Group")
        UI.messagebox("#{SUF_STRINGS["The selection includes groups"]}!\n#{SUF_STRINGS["Please select only components"]}")
        else
        names_with_symbol = 0
        sel.grep(Sketchup::ComponentInstance).each { |e|
          if e.definition.name.include?("#")
            names_with_symbol += 1
            result=UI.messagebox("#{SUF_STRINGS["Component names must not contain #"]}\n#{SUF_STRINGS["Do you want to rename it"]}?",MB_YESNO)
            new_definition_name = nil
            if result==IDYES
              new_definition_name = new_name(e.definition.name,ents)
            end
            if new_definition_name
              e.definition.name = new_definition_name
              names_with_symbol -= 1
            end
          end
        }
        if names_with_symbol == 0
          folder_list=[]
          list_tip=[]
          content=[]
          @visible_layer = []
          view = @model.active_view
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
          content = File.readlines(path_param).map(&:strip)
          content.each{|line| 
            folder = line.delete('"').strip.split("=")[1]
            path_vendor = File.join(PATH_COMP,folder, "*")
            all_folder_vendor = Dir.glob(path_vendor).select {|f| File.directory? f}
            folder_list << folder
            if all_folder_vendor.length != 0
              all_folder_vendor = all_folder_vendor.map { |i| i.split(/[\/]/)[-2] + "/" + i.split(/[\/]/)[-1] }.sort
              folder_list = folder_list + all_folder_vendor
            end
          }
          list = folder_list.join("|")
          default_path = folder_list[0]
					if @model.get_attribute("suf","default_path")
					  default_path = @model.get_attribute("suf","default_path")
          end
          prompts = ["#{SUF_STRINGS["Component type"]} ","#{SUF_STRINGS["Image"]} ","#{SUF_STRINGS["Select folder"]} "]
          defaults = [default_path,SUF_STRINGS["Do not save"],SUF_STRINGS["No"]]
          list = [list,"#{SUF_STRINGS["Zoom and Save"]}|#{SUF_STRINGS["Save as is"]}|#{SUF_STRINGS["Do not save"]}","#{SUF_STRINGS["No"]}|#{SUF_STRINGS["Yes"]}"]
          if sel.count == 1
            prompts += ["#{SUF_STRINGS["Component name"]} "]
            defaults += [sel[0].definition.name]
            list += [""]
          end
          input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Select parameters"]
          p input
          if input
					  @model.set_attribute("suf","default_path",input[0])
            if input[2] == SUF_STRINGS["No"]
              plugins_comp = PATH_COMP+"/" + input[0]
              else
              plugins_comp = UI.select_directory(
                title: SUF_STRINGS["Select a folder"],
                directory: Dir.pwd,
                select_multiple: false
              )
            end
            p plugins_comp
            dir_scr = ""
            param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
            if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
              path_param = File.join(param_temp_path,"parameters.dat")
              elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
              path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
              else
              path_param = File.join(PATH,"parameters","parameters.dat")
            end
            content = File.readlines(path_param)
            content.each { |i| dir_scr = i.strip.split("=")[2] if i.strip.split("=")[1] == "work_path" }
            @active_file = Sketchup.active_model.path
            if plugins_comp
              cwd = Dir.chdir(plugins_comp)
              @model.layers.each { |l|
                @visible_layer.push l if l.visible?
                l.visible = false if l.name.include?("1_Фасад_опции") || l.name.include?("1_Фасад_текстура") || l.name.include?("7_Размеры") || l.name.include?("8_Направляющие") || l.name.include?("Z_Napr")
              }
              info["DisplayShadows"] = false
              ents_for_resave = []
              sel.grep(Sketchup::ComponentInstance).each { |e|
                e.definition.name = input[3] if input[3] && input[3] != e.definition.name
								e.definition.attribute_dictionaries.delete 'su_parameters'
								e.definition.attribute_dictionaries.delete 'ladb_opencutlist'
								refresh_thumbnails(e)
                e.definition.save_as(plugins_comp + "/" + e.definition.name + ".skp")
                ents_for_resave << plugins_comp + "/" + e.definition.name + ".skp"
                if input[1].include?(SUF_STRINGS["Save"])
                  if input[1] == SUF_STRINGS["Zoom and Save"]
                    t1 = Geom::Transformation.translation [-2000, 0, 0]
                    e.transform! t1
										view.camera.aspect_ratio= 1
										Zoom.zoom_entities e
                    #view.zoom e
                  end
                  keys = {
                    :filename => plugins_comp + "/" + e.definition.name + ".png",
                    :width => 200,
                    :height => 200,
                    :antialias => true,
                    :compression => 0.9,
                    :transparent => true
                  }
                  view.write_image keys
                  if input[1] == SUF_STRINGS["Zoom and Save"]
                    t2 = Geom::Transformation.translation [2000, 0, 0]
                    e.transform! t2
										view.camera.aspect_ratio= 0
                    view.zoom_extents
                  end
                end
              }
							@visible_layer.each { |l| l.visible = true }
            end
          end
        end
      end
    end #def
		def refresh_thumbnails(entity)
			if entity.is_a?(Sketchup::ComponentInstance)
				entity.definition.refresh_thumbnail
				refresh_thumbnails(entity.parent)
				elsif entity.is_a?(Sketchup::ComponentDefinition)
				entity.refresh_thumbnail
				entity.instances.each { |instance|
					refresh_thumbnails(instance.parent)
        }
				elsif entity.is_a?(Sketchup::Group)
				refresh_thumbnails(entity.parent)
      end
    end #def
  end # class MakeComponents
	
end # module SU_Furniture
