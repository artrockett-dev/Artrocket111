require 'fileutils'
require 'extensions.rb'
require 'uri'
require 'open-uri'
Sketchup::require("suf/core/logger_helper")
Sketchup::require("suf/validator_plugin")

ValidatorPlugin::LicenseValidator.verify_license

unless ValidatorPlugin::LicenseValidator.registration_expired?
  Sketchup::require("suf/kernel")
  ValidatorPlugin::LicenseValidator.license_denied = true
  Sketchup::require("suf/observers/suf_observer") 
  Sketchup::require("suf/observers/add_remove_observers")
  Sketchup::require("suf/observers/my_selection_observer")
  Sketchup::require("suf/activation")
  Sketchup::require("suf/su_attribute")
  Sketchup::require("suf/change_component")
  Sketchup::require("suf/change_material")
  Sketchup::require("suf/suf_language")
  Sketchup.add_observer(ValidatorPlugin::ShutdownObserver.new)

  module SU_Furniture
    logger = LoggerHelper.logger
    logger.info("Plugin started")
    # UI.messagebox("Logging to: #{LoggerHelper::LOG_PATH}")
    begin
      DICT = 'dynamic_attributes'
      MAX_ENTITY_NAME_LENGTH = 64
      E = "File Error"
      IS_WIN = Sketchup.platform == :platform_win
      OSX = Sketchup.platform == :platform_osx unless defined? SU_Furniture::OSX
      language = nil
      toolbar_activation = "yes"
      Exception_array = ["edge_label","edgemat","front_mat","frontmat","texture_mat","texturemat","cut_out","cutout"]
      icon_style = "style1"
      all_param_files = ["parameters","fasteners","template","hinge","drawer","accessories","groove","lists","texts","worktop","fartuk","frontal"]
      PARAM_PATH = File.join(PATH,"parameters")
      if !File.directory?(File.join(TEMP_PATH,"SUF"))
        Dir.mkdir(File.join(TEMP_PATH,"SUF"))
      end
      
      path_param = nil
      if !File.file?(File.join(TEMP_PATH,"SUF","parameters.dat")) && !File.file?(File.join(TEMP_PATH,"SUF","Default","parameters.dat"))
        FileUtils.mkdir_p(File.join(TEMP_PATH,"SUF","Default"))
        Dir.entries(PARAM_PATH).each{|f|
          if File.file?(File.join(PARAM_PATH,f))
            if all_param_files.include?(File.basename(f,".dat"))
              FileUtils.cp(File.join(PARAM_PATH,f), File.join(TEMP_PATH,"SUF","Default"))
              else
              FileUtils.cp(File.join(PARAM_PATH,f), File.join(TEMP_PATH,"SUF"))
            end
          end
        }
        PARAM_TEMP_PATH = File.join(TEMP_PATH,"SUF","Default")
        elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat")) && !File.file?(File.join(TEMP_PATH,"SUF","Default","parameters.dat"))
        FileUtils.mkdir_p(File.join(TEMP_PATH,"SUF","Default"))
        all_param_files.each { |f|
          if File.file?(File.join(TEMP_PATH,"SUF",f+".dat"))
            FileUtils.cp(File.join(TEMP_PATH,"SUF",f+".dat"), File.join(TEMP_PATH,"SUF","Default"))
            FileUtils.rm_rf(File.join(TEMP_PATH,"SUF",f+".dat"))
          end
        }
        PARAM_TEMP_PATH = File.join(TEMP_PATH,"SUF","Default")
        else
        param_profile = "Default"
        path_param = File.join(TEMP_PATH,"SUF","Default","parameters.dat")
        content_temp = File.readlines(path_param)
        if content_temp.length < 100
          FileUtils.cp(File.join(PARAM_PATH,"parameters.dat"), File.join(TEMP_PATH,"SUF","Default"))
          content_temp = File.readlines(path_param)
        end
        content_temp.each { |cont_temp|
          if cont_temp.split("=")[1] == "param_profile"
            param_profile = cont_temp.split("=")[2]
            break
          end
        }
        PARAM_TEMP_PATH = File.join(TEMP_PATH,"SUF",param_profile)
      end
      Sketchup.write_default("SUF", "PARAM_TEMP_PATH", PARAM_TEMP_PATH)
      
      if !File.directory?(File.join(TEMP_PATH,"SUF","Name_database"))
        FileUtils.mkdir_p(File.join(TEMP_PATH,"SUF","Name_database"))
      end
      
      if File.file?(File.join(PARAM_TEMP_PATH,"parameters.dat"))
        temp_path = File.join(PARAM_TEMP_PATH,"parameters.dat")
        content_temp = File.readlines(temp_path)
        @model = Sketchup.active_model
        ValidatorPlugin::LicenseValidator.start_time_tracker
        @model.start_operation "att", true, false, true
        attrdicts = @model.attribute_dictionaries
        attrdicts.delete 'su_parameters' if attrdicts
        dict = @model.attribute_dictionary('su_parameters', true)
        content_temp.each {|i| @model.set_attribute('su_parameters', i.split("=")[1], i) if i.split("=")[1] && !i.split("=")[1].empty?}
        @model.set_attribute('pages_properties','hide_new_objects',"false")
        @model.commit_operation
        path_param = File.join(PATH,"parameters","parameters.dat")
        param_file = File.new(path_param,"r")
        content = param_file.readlines
        param_file.close
        
        path_array = []
        content_temp.each { |cont_temp|
          language = cont_temp.split("=")[2] if cont_temp.split("=")[1] == "language"
          icon_style = cont_temp.split("=")[2] if cont_temp.split("=")[1] == "icon_style"
          toolbar_activation = cont_temp.split("=")[2] if cont_temp.split("=")[1] == "toolbar_activation"
        }
        
        content.each { |cont| language = cont.split("=")[2] if cont.split("=")[1] == "language"} if !language
        
        content.each_with_index { |cont,index| path_array << index if cont.split("=")[1] == "edge_vendor_header" } # строка начала папок
        content_temp.each { |cont_temp|
          if cont_temp.split("=")[1] == "edge_vendor"
            path_array << cont_temp if !path_array.include?(cont_temp)
          end
        }
        if path_array.length > 1
          content.delete_if {|cont| cont.split("=")[1] == "edge_vendor" }
        end
        content.each_with_index { |cont,index|
          if cont.split("=")[1] != "menu_row"
            content_temp.each { |cont_temp|
              if cont_temp.split("=")[1] != "edge_vendor" && cont.split("=")[1] == cont_temp.split("=")[1]
                content[index] = cont_temp
              end
            }
          end
        }
        if path_array.length > 1
          if path_array[0].to_s.length < 4
            for i in 1..path_array.length-1
              content.insert(i+path_array[0],path_array[i]) if !content.include?(path_array[i])
            end
          end
        end
        temp_path_file = File.new(temp_path,"w")
        content.each{|i| temp_path_file.puts i }
        temp_path_file.close
      end
      
      path_icons = PATH_ICONS+"/"+icon_style
      language = "ru" if !language || language == "" || language == " "
      Language = language
      SUF_STRINGS = SUFLanguage.new(FILENAMESPACE + ".strings", language)
      SUF_ATT_STR = SUFLanguage.new("su_attribute.strings", language)
      SUF_EXP_STR = SUFLanguage.new("su_export.strings", language)
      SUF_VIEW_STR = SUFLanguage.new("su_view.strings", language)
      Param_comp = SUF_STRINGS["Component options"]
      SU_Attribute = SUAttribute.new
      Change_Components = ChangeComponents.new
      Change_Materials = ChangeMaterials.new
      
      # Create toolbars
      $SU_Furniture_tb = SU_Furniture_tb = UI::Toolbar.new(PLUGIN_NAME)
      $SUF_scenes_tb = SUF_scenes_tb = UI::Toolbar.new("SUF_scenes")
      $SUF_att_tb = SUF_att_tb = UI::Toolbar.new("SUF_attribute")

      Activate.new.Activate_plugin()

      Sketchup::require(PATH + "/suf_menu")
      
      SU_Furniture_tb.get_last_state == TB_NEVER_SHOWN ? SU_Furniture_tb.show : SU_Furniture_tb.restore
      
      # Add item "Component Parameters"
      Att_dialog_cmd = UI::Command.new("SU_Furniture") { $dlg_att && ($dlg_att.visible?) ? $dlg_att.bring_to_front : SU_Attribute.activate }
      Att_dialog_cmd.small_icon = Att_dialog_cmd.large_icon = File.join(path_icons, "attribute.png")
      Att_dialog_cmd.tooltip = Param_comp
      Att_dialog_cmd.status_bar_text = Param_comp
      SUF_att_tb.add_item(Att_dialog_cmd)
      SUF_att_tb.get_last_state == TB_NEVER_SHOWN ? SUF_att_tb.show : SUF_att_tb.restore

      UI.menu("Edit").add_item("#{SUF_STRINGS["Remove guides other than"]} #{PLUGIN_NAME}",9) { delete_lines }
      UI.menu("Plugins").add_item("Redraw Group") { redraw_component }
      @observers_state = 1
      
      model = Sketchup.active_model
      # Add item "Kitchen scenes"
      kitchen_scenes_cmd = UI::Command.new(SUF_STRINGS["Kitchen scenes"]) { Kitchen_Scenes.scenes(false,true,false,false) }
      kitchen_scenes_cmd.small_icon = kitchen_scenes_cmd.large_icon = File.join(path_icons, "kitchen_scene.png")
      kitchen_scenes_cmd.tooltip = SUF_STRINGS["Kitchen scenes"]
      kitchen_scenes_cmd.status_bar_text = SUF_STRINGS["Kitchen scenes"]
      SUF_scenes_tb.add_item(kitchen_scenes_cmd)
      # Add item "Scene for carcass"
      carcass_scenes_cmd = UI::Command.new(SUF_STRINGS["Scene for carcass"]) { Kitchen_Scenes.scenes(['Корпуса'],true,false,false) }
      carcass_scenes_cmd.small_icon = carcass_scenes_cmd.large_icon = File.join(path_icons, "carcass_scene.png")
      carcass_scenes_cmd.tooltip = SUF_STRINGS["Scene for carcass"]
      carcass_scenes_cmd.status_bar_text = SUF_STRINGS["Scene for carcass"]
      SUF_scenes_tb.add_item(carcass_scenes_cmd)
      # Add item "Scene for carcass for current Scene"
      carcass_for_current_cmd = UI::Command.new(SUF_STRINGS["Scene for carcass for current Scene"]) { Kitchen_Scenes.scenes(['Корпуса'],true,true,false) }
      carcass_for_current_cmd.small_icon = carcass_for_current_cmd.large_icon = File.join(path_icons, "current_scene.png")
      carcass_for_current_cmd.tooltip = SUF_STRINGS["Scene for carcass for current Scene"]
      carcass_for_current_cmd.status_bar_text = SUF_STRINGS["Scene for carcass for current Scene"]
      SUF_scenes_tb.add_item(carcass_for_current_cmd)
      carcass_for_current_cmd.set_validation_proc { MF_DISABLED | MF_GRAYED if model.pages.size == 0 }
      # Add item "Scene for selection"
      selection_scenes_cmd = UI::Command.new(SUF_STRINGS["Scene for selection"]) { Kitchen_Scenes.scenes(true,true,false,false) }
      selection_scenes_cmd.small_icon = selection_scenes_cmd.large_icon = File.join(path_icons, "selection_scene.png")
      selection_scenes_cmd.tooltip = SUF_STRINGS["Scene for selection"]
      selection_scenes_cmd.status_bar_text = SUF_STRINGS["Scene for selection"]
      SUF_scenes_tb.add_item(selection_scenes_cmd)
      selection_scenes_cmd.set_validation_proc { MF_DISABLED | MF_GRAYED if model.selection.size == 0 }
      # Add item "Scenes for Modules"
      modules_scenes_cmd = UI::Command.new(SUF_STRINGS["Scenes for Modules"]) { Export_to_layout.scenes_for_modules }
      modules_scenes_cmd.small_icon = modules_scenes_cmd.large_icon = File.join(path_icons, "module_scene.png")
      modules_scenes_cmd.tooltip = SUF_STRINGS["Scenes for Modules"]
      modules_scenes_cmd.status_bar_text = SUF_STRINGS["Scenes for Modules"]
      SUF_scenes_tb.add_item(modules_scenes_cmd)
      # Add item "Update Camera"
      update_camera_cmd = UI::Command.new(SUF_STRINGS["Update Camera in Kitchen scenes"]) { Kitchen_Scenes.update_camera }
      update_camera_cmd.small_icon = update_camera_cmd.large_icon = File.join(path_icons, "update_camera.png")
      update_camera_cmd.tooltip = SUF_STRINGS["Update Camera in Kitchen scenes"]
      update_camera_cmd.status_bar_text = SUF_STRINGS["Update Camera in Kitchen scenes"]
      SUF_scenes_tb.add_item(update_camera_cmd)
      # Add item "Add Scene"
      add_scene_cmd = UI::Command.new(SUF_STRINGS["Add Scene with name"]) { Kitchen_Scenes.scenes("new",true,false,false) }
      add_scene_cmd.small_icon = add_scene_cmd.large_icon = File.join(path_icons, "add_scene.png")
      add_scene_cmd.tooltip = SUF_STRINGS["Add Scene with name"]
      add_scene_cmd.status_bar_text = SUF_STRINGS["Add Scene with name"]
      SUF_scenes_tb.add_item(add_scene_cmd)
      # Add item "Delete Scenes"
      delete_scenes_cmd = UI::Command.new(SUF_STRINGS["Delete Scenes"]) { Kitchen_Scenes.delete_scenes }
      delete_scenes_cmd.small_icon = delete_scenes_cmd.large_icon = File.join(path_icons, "delete_scenes.png")
      delete_scenes_cmd.tooltip = SUF_STRINGS["Delete Scenes"]
      delete_scenes_cmd.status_bar_text = SUF_STRINGS["Delete Scenes"]
      SUF_scenes_tb.add_item(delete_scenes_cmd)
      delete_scenes_cmd.set_validation_proc { MF_DISABLED | MF_GRAYED if model.pages.size == 0 }
      # SUF_scenes_tb.get_last_state == TB_NEVER_SHOWN ? SUF_scenes_tb.show : SUF_scenes_tb.restore
      
      suf_submenu = UI.menu("Plugins").add_submenu(PLUGIN_NAME)
      suf_submenu.add_item(SUF_STRINGS["Import"] + " OBJ") { SU_Furniture::ImportOBJ.new() }
      suf_submenu.add_item("#{SUF_STRINGS["Remove guides other than"]} #{PLUGIN_NAME}") { delete_lines }
      suf_submenu.add_item(SUF_STRINGS["Import components from folder"]) { import_components }
      observers_item = suf_submenu.add_item(SUF_STRINGS["On/Off observers"]) { add_remove_observers(@observers_state) }
      suf_submenu.set_validation_proc(observers_item) { @observers_state == 1 ? MF_CHECKED : MF_UNCHECKED }
      item = suf_submenu.add_item(SUF_STRINGS["White faces and color holes"]) { change_style(model) }
      suf_submenu.set_validation_proc(item)  {
        if model.styles.active_style.name == "HiddenColorLine"
          MF_CHECKED
          else
          MF_UNCHECKED
        end
      }
      
      suf_submenu = UI.menu("Plugins").add_submenu(PLUGIN_NAME+" "+SUF_STRINGS["Scenes"])
      suf_submenu.add_item(SUF_STRINGS["Kitchen scenes"]) { Kitchen_Scenes.scenes(false,model.active_view.camera.direction,false,false) }
      suf_submenu.add_item(SUF_STRINGS["Scene for carcass"]) { Kitchen_Scenes.scenes(['Корпуса'],model.active_view.camera.direction,false,false) }
      suf_submenu.add_item(SUF_STRINGS["Scene for carcass for current Scene"]) { Kitchen_Scenes.scenes(['Корпуса'],model.active_view.camera.direction,true,false) }
      suf_submenu.add_item(SUF_STRINGS["Scene for selection"]) { Kitchen_Scenes.scenes(true,model.active_view.camera.direction,false,false) }
      suf_submenu.add_item(SUF_STRINGS["Scenes for Modules"]) { Export_to_layout.scenes_for_modules }
      suf_submenu.add_item(SUF_STRINGS["Update Camera in Kitchen scenes"]) { Kitchen_Scenes.update_camera }
      suf_submenu.add_item(SUF_STRINGS["Add Scene with name"]) { Kitchen_Scenes.scenes("new",true,false,false) }
      suf_submenu.add_item(SUF_STRINGS["Delete Scenes"]) { Kitchen_Scenes.delete_scenes }
      
      suf_submenu = UI.menu("Plugins").add_submenu(PLUGIN_NAME+" "+SUF_STRINGS["Tools"])
      suf_submenu.add_item(SUF_STRINGS["Interact with Dynamic Components"]) { model.tools.push_tool(SU_InteractTool) }
      suf_submenu.add_item(SUF_STRINGS["Select nested panels"]) { model.tools.push_tool( Select_Nested ) }
      suf_submenu.add_item(SUF_STRINGS["Panel options"]) { model.tools.push_tool( Change_Point ) }
      suf_submenu.add_item(SUF_STRINGS["Fasteners"]) { model.tools.push_tool( Fasteners_Panel ) }
      suf_submenu.add_item(SUF_STRINGS["Groove"]) { model.tools.push_tool( Groove_Panel ) }
      suf_submenu.add_item(SUF_STRINGS["Draw mouldings"]) { SU_Furniture::ComponentBrowser.make_browser }
      suf_submenu.add_item(SUF_STRINGS["Trim of panels"]) { model.tools.push_tool( Trim_Panel ) }
      suf_submenu.add_item(SUF_STRINGS["Dimensions of panels/niche"]) { model.tools.push_tool( Panel_dimensions ) }
      suf_submenu.add_item(SUF_STRINGS["Throw_to_face"]) { model.tools.push_tool( Throw_to_face ) }
    rescue => e 
      logger.info(e.backtrace.join("/"))
    end
  end # module SU_Furniture

  unless file_loaded?(__FILE__)
    file_loaded(__FILE__)
  end
  $SUF_scenes_tb.hide if $SUF_scenes_tb
  $SUF_att_tb.hide if $SUF_att_tb
  SU_Furniture.add_remove_observers(0)
  DCProgressBar.const_set("DEFAULT_TIME_LIMIT", 60.0)
  # ValidatorPlugin::UIHelpers.show_notification
end

timer_id = nil
loop_count = 0

timer_id = UI.start_timer(1, true) do
  loop_count += 1

  lang = ::ARAddons::ARStartup::Reader.active_lang_base.to_sym
  SU_Furniture::LANG = lang

  # Stop if language is not :ru
  if lang != :ru
    UI.stop_timer(timer_id)
    next
  end

  # Stop after 10 loops even if it's still :ru
  if loop_count >= 10
    UI.stop_timer(timer_id)
  end
end

UI.start_timer(300, true) {
  unless ValidatorPlugin::LicenseValidator.verify_license
    if File.exist?(ValidatorPlugin::LicenseValidator.license_path)
      Process.exit!(0)
    else
      UI.messagebox("Please register the product")
      Process.exit!(0)
    end
  else
    # ValidatorPlugin::UIHelpers.show_notification
    GC.start
    m = Sketchup.active_model
    m.start_operation("Purge Unused", true)
    begin
      # Recommended order: definitions → layers (tags) → materials → styles
      m.definitions.purge_unused
      m.layers.purge_unused
      m.materials.purge_unused
      m.styles.purge_unused

      # Optional: also remove empty tag folders (SU 2021+)
      m.layers.purge_unused_folders if m.layers.respond_to?(:purge_unused_folders)
    ensure
      m.commit_operation
    end
  end
}