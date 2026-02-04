require "fileutils"
Sketchup::require("suf/suf_dialog")
Sketchup::require("suf/attribute_list")
Sketchup::require("suf/change_attribute")
Sketchup::require("suf/lists")
Sketchup::require("suf/price")

Sketchup::require("suf/functions/dc_redraw")
Sketchup::require("suf/functions/dc_attributes")

Sketchup::require("suf/additions/lists_EasyKitchen")
Sketchup::require("suf/additions/lists_SDCF")
Sketchup::require("suf/additions/copy")
Sketchup::require("suf/additions/close_doors")
Sketchup::require("suf/additions/make_component")
Sketchup::require("suf/additions/rotate90")
Sketchup::require("suf/additions/redraw_component")
Sketchup::require("suf/additions/scenes")
Sketchup::require("suf/additions/dimensions")
Sketchup::require("suf/additions/parameters")
Sketchup::require("suf/additions/new_module")
Sketchup::require("suf/additions/new_section")
Sketchup::require("suf/additions/new_furniture")
Sketchup::require("suf/additions/delete_guides")
Sketchup::require("suf/additions/delete_objects")
Sketchup::require("suf/additions/import_components")
Sketchup::require("suf/additions/intersect")
Sketchup::require("suf/additions/manual")
Sketchup::require("suf/additions/pages_properties")
Sketchup::require("suf/additions/module_number")
Sketchup::require("suf/additions/hide_walls")
Sketchup::require("suf/additions/save_copy")
Sketchup::require("suf/additions/view")
Sketchup::require("suf/additions/style")
Sketchup::require("suf/additions/read_XLSX")

Sketchup::require("suf/tools/draw_mouldings")
Sketchup::require("suf/tools/mouldings_browser")
Sketchup::require("suf/tools/draw_section")
Sketchup::require("suf/tools/drill_hole")
Sketchup::require("suf/tools/explode_view")
Sketchup::require("suf/tools/groove_panel")
Sketchup::require("suf/tools/move_to_face")
Sketchup::require("suf/tools/panel_drawing")
Sketchup::require("suf/tools/panel_fasteners")
Sketchup::require("suf/tools/dimensions")
Sketchup::require("suf/tools/panel_options")
Sketchup::require("suf/tools/place_component")
Sketchup::require("suf/tools/select_nested")
Sketchup::require("suf/tools/su_interact_tool")
Sketchup::require("suf/tools/trim_panel")
Sketchup::require("suf/tools/visible_side")
Sketchup::require("suf/tools/without_fastener")

Sketchup::require("suf/import/obj_importer")

Sketchup::require("suf/lib/write_xlsx")
Sketchup::require("suf/lib/zip")

module SU_Furniture
  # Create menu items
  unless file_loaded?(__FILE__) 
    SUF_Dialog = SUFDialog.new
    Attributes_List = AttributesList.new
    Change_Attributes = ChangeAttributes.new
    Report_lists = Lists.new
    SU_Price = SUPrice.new
    Lists_EasyKitchen = ListsEasyKitchen.new
    Lists_SDCF = ListsSDCF.new
    Copy_Comp = CopyComp.new
    Make_Components = MakeComponents.new
    Close_Doors = CloseDoors.new
    Throw_to_face = ThrowToFace.new
    Dimensions = Dimension.new
    Kitchen_Scenes = KitchenScenes.new
    Parameters_dialog = Parameter.new
    Make_module = New_module.new
    Make_section = New_section.new
    Make_furniture = New_furniture.new
    Change_Point = ChangePoint.new
    Place_Component = PlaceComponent.new
    SU_InteractTool = SUInteractTool.new
    Draw_mouldings = DrawMouldings.new
    Explode_View = ExplodeView.new
    Intersect_Components = IntersectComponents.new
    Fasteners_Panel = FastenersPanel.new
    Groove_Panel = GroovePanel.new
    Visible_Side = VisibleSide.new
    Without_Fastener = WithoutFastener.new
    Drill_Hole = DrillHole.new
    Trim_Panel = TrimPanel.new
    Panel_Dimensions = PanelDimensions.new
    Manual_Browser = ManualBrowser.new
    Pages_Properties = PagesProperties.new
    Select_Nested = SelectNested.new
    Module_Number = ModuleNumber.new
    Panel_Drawing = PanelDrawing.new
    Draw_Section = DrawSection.new
    Hide_Walls = HideWalls.new
    Save_Copy = SaveCopy.new
		Redraw_Components = RedrawComponents.new
		Read_XLSX = ReadXLSX.new
    
    const_defined?("Ladb") ? OCL = true : OCL = false
    
    param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
		if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
			path_param = File.join(param_temp_path,"parameters.dat")
			elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
			path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
			else
			path_param = File.join(PATH,"parameters","parameters.dat")
    end
    param_file = File.new(path_param,"r")
    content = param_file.readlines
    param_file.close
		icon_style = "style1"
		path_icons = PATH_ICONS+"/"+icon_style
    content.each { |i|
      if i.split("=")[1] == "lib_path" && i.split("=")[2] != "По умолчанию"
        send(:remove_const, "PATH_COMP") if const_defined?("PATH_COMP")
        PATH_COMP = i.split("=")[2]+"/Components/SUF"
        send(:remove_const, "PATH_MAT") if const_defined?("PATH_MAT")
        PATH_MAT = i.split("=")[2]+"/Materials/SUF"
        send(:remove_const, "PATH_PRICE") if const_defined?("PATH_PRICE")
        PATH_PRICE = i.split("=")[2]+"/Materials/price"
      end
			icon_style = i.split("=")[2] if i.split("=")[1] == "icon_style"
    }
		path_icons = PATH_ICONS+"/"+icon_style
    # Add item "Interact"
    Interact_cmd = UI::Command.new(SUF_STRINGS["Interact with Dynamic Components"]) { Sketchup.active_model.tools.push_tool(SU_InteractTool) }
    Interact_cmd.small_icon = Interact_cmd.large_icon = File.join(path_icons, "interact_tool.png")
    Interact_cmd.tooltip = SUF_STRINGS["Interact with Dynamic Components"]
    Interact_cmd.status_bar_text = SUF_STRINGS["One click at a time changes the interaction objects"]     
    SU_Furniture_tb.add_item(Interact_cmd)
    
    # Add item "select_nested"
    Select_Nested_cmd = UI::Command.new(SUF_STRINGS["Select nested panels"]) { Sketchup.active_model.tools.push_tool( Select_Nested ) }
    Select_Nested_cmd.small_icon = Select_Nested_cmd.large_icon = File.join(path_icons, "select_nested.png")
    Select_Nested_cmd.tooltip = SUF_STRINGS["Select nested panels"]
    Select_Nested_cmd.status_bar_text = SUF_STRINGS["Select nested panels"]
    SU_Furniture_tb.add_item(Select_Nested_cmd)
    
    # Add item "module_number"
    Module_Number_cmd = UI::Command.new(SUF_STRINGS["Numbering of Modules"]) { Module_Number.add_number }
    Module_Number_cmd.small_icon = Module_Number_cmd.large_icon = File.join(path_icons, "module_number.png")
    Module_Number_cmd.tooltip = SUF_STRINGS["Numbering of Modules"]
    Module_Number_cmd.status_bar_text = SUF_STRINGS["Numbering of Modules"]+" "+SUF_STRINGS["by parameters"]     
    SU_Furniture_tb.add_item(Module_Number_cmd)
    
    SU_Furniture_tb.add_separator
    
    # Add item "Dialog"
    Dialog_cmd = UI::Command.new("SU_Furniture") { $dlg_suf && ($dlg_suf.visible?) ? $dlg_suf.bring_to_front : SUF_Dialog.activate }
    Dialog_cmd.small_icon = Dialog_cmd.large_icon = File.join(path_icons, "Dialog.png")
    Dialog_cmd.tooltip = SUF_STRINGS["Main"]+" "+PLUGIN_NAME
    #Dialog_cmd.set_validation_proc { $dlg_suf && ($dlg_suf.visible?) ?  MF_CHECKED : MF_UNCHECKED }
    Dialog_cmd.status_bar_text = SUF_STRINGS["Main"]+" "+PLUGIN_NAME  
    SU_Furniture_tb.add_item(Dialog_cmd)
    
    # Add item "Screenshot"
    ScreenShot_cmd = UI::Command.new(SUF_STRINGS["ScreenShot"]) { Screen_shots.screenshot }
    ScreenShot_cmd.small_icon = ScreenShot_cmd.large_icon = File.join(path_icons, "foto.png")
    ScreenShot_cmd.tooltip = SUF_STRINGS["ScreenShot"]
    ScreenShot_cmd.status_bar_text = SUF_STRINGS["Make"] + SUF_STRINGS["ScreenShot"]      
    SU_Furniture_tb.add_item(ScreenShot_cmd)
    
    # Add item "Specification"
    Spec_cmd = UI::Command.new(SUF_STRINGS["Specification"]) { $dlg_spec && ($dlg_spec.visible?) ? $dlg_spec.bring_to_front : Specification_dialog.activate }
    Spec_cmd.small_icon = Spec_cmd.large_icon = File.join(path_icons, "Spec.png")
    Spec_cmd.tooltip = SUF_STRINGS["Specification"]
    Spec_cmd.status_bar_text = SUF_STRINGS["Specification"]
    SU_Furniture_tb.add_item(Spec_cmd)
    
    SU_Furniture_tb.add_separator
    
    # Add item "Panel options"
    Options_cmd = UI::Command.new(SUF_STRINGS["Panel options"]) { Sketchup.active_model.tools.push_tool( Change_Point ) }
    Options_cmd.small_icon = Options_cmd.large_icon = File.join(path_icons, "Options.png")
    Options_cmd.tooltip = SUF_STRINGS["Panel options"]
    Options_cmd.status_bar_text = SUF_STRINGS["Panel options"]     
    SU_Furniture_tb.add_item(Options_cmd)
    
    # Add item "Close_doors"
    Close_doors_cmd = UI::Command.new(SUF_STRINGS["Close all doors"]) { Close_Doors.close_doors(Sketchup.active_model) }
    Close_doors_cmd.large_icon = Close_doors_cmd.small_icon = File.join(path_icons, "door.png")
    Close_doors_cmd.tooltip = SUF_STRINGS["Close all doors"]
    Close_doors_cmd.status_bar_text = SUF_STRINGS["Close all doors"]     
    SU_Furniture_tb.add_item(Close_doors_cmd)
    
    # Add item "Panel_Fasteners"
    Fasteners_cmd = UI::Command.new(SUF_STRINGS["Fasteners"]) { Sketchup.active_model.tools.push_tool( Fasteners_Panel ) }
    Fasteners_cmd.small_icon = Fasteners_cmd.large_icon = File.join(path_icons, "Fasteners.png")
    Fasteners_cmd.tooltip = SUF_STRINGS["Fasteners"]
    Fasteners_cmd.status_bar_text = SUF_STRINGS["Add "]+SUF_STRINGS["Fasteners"]     
    SU_Furniture_tb.add_item(Fasteners_cmd)
    
    # Add item ""Hidden_color_edge""
    Hidden_color_cmd = UI::Command.new(SUF_STRINGS["Hidden_color_edge"]) { change_style(Sketchup.active_model)	}
    Hidden_color_cmd.small_icon = Hidden_color_cmd.large_icon = File.join(path_icons, "hidden_color.png")
    Hidden_color_cmd.tooltip = SUF_STRINGS["Hidden_color_edge"]
    Hidden_color_cmd.status_bar_text = SUF_STRINGS["Hidden_color_edge"]
    SU_Furniture_tb.add_item(Hidden_color_cmd)
    if Sketchup.active_model.styles
      Hidden_color_cmd.set_validation_proc  {
        if Sketchup.active_model.styles.active_style.name == "HiddenColorLine"
          MF_CHECKED
          else
          MF_UNCHECKED
        end
      }
    end
    
    # Add item "Panel_Groove"
    Groove_cmd = UI::Command.new(SUF_STRINGS["Groove"]) { Sketchup.active_model.tools.push_tool( Groove_Panel ) }
    Groove_cmd.small_icon = Groove_cmd.large_icon = File.join(path_icons, "panel_groove.png")
    Groove_cmd.tooltip = SUF_STRINGS["Groove"]
    Groove_cmd.status_bar_text = SUF_STRINGS["Add "]+SUF_STRINGS["Groove"]     
    SU_Furniture_tb.add_item(Groove_cmd)
    
    # Add item "Draw_mouldings"
    Draw_mouldings_cmd = UI::Command.new(SUF_STRINGS["Draw mouldings"]) { SU_Furniture::ComponentBrowser.make_browser }
    Draw_mouldings_cmd.small_icon = Draw_mouldings_cmd.large_icon = File.join(path_icons, "mouldings.png")
    Draw_mouldings_cmd.tooltip = SUF_STRINGS["Draw mouldings"]
    Draw_mouldings_cmd.status_bar_text = SUF_STRINGS["Draw mouldings"]     
    SU_Furniture_tb.add_item(Draw_mouldings_cmd)
    
    # Add item "Trim_panel"
    Trim_panel_cmd = UI::Command.new(SUF_STRINGS["Trim of panels"]) { Sketchup.active_model.tools.push_tool( Trim_Panel ) }
    Trim_panel_cmd.small_icon = Trim_panel_cmd.large_icon = File.join(path_icons, "saw.png")
    Trim_panel_cmd.tooltip = SUF_STRINGS["Trim of panels"]
    Trim_panel_cmd.status_bar_text = SUF_STRINGS["Change "]+SUF_STRINGS["Trim of panels"]     
    SU_Furniture_tb.add_item(Trim_panel_cmd)
    
    # Add item "Dimensions"
    Panel_dimensions_cmd = UI::Command.new(SUF_STRINGS["Dimensions of panels/niche"]) { Sketchup.active_model.tools.push_tool( Panel_Dimensions ) }
    Panel_dimensions_cmd.small_icon = Panel_dimensions_cmd.large_icon = File.join(path_icons, "panel_dimensions.png")
    Panel_dimensions_cmd.tooltip = SUF_STRINGS["Dimensions of panels/niche"]
    Panel_dimensions_cmd.status_bar_text = SUF_STRINGS["Add "]+SUF_STRINGS["Dimensions of panels/niche"]
    SU_Furniture_tb.add_item(Panel_dimensions_cmd)
    
    # Add item "throw_to_face"
    Throw_to_face_cmd = UI::Command.new(SUF_STRINGS["Throw_to_face"]) { Sketchup.active_model.tools.push_tool( Throw_to_face ) }
    Throw_to_face_cmd.small_icon = Throw_to_face_cmd.large_icon = File.join(path_icons, "throw_to.png")
    Throw_to_face_cmd.tooltip = SUF_STRINGS["Throw_to_face"]
    Throw_to_face_cmd.status_bar_text = SUF_STRINGS["Throw_to_face"]
    SU_Furniture_tb.add_item(Throw_to_face_cmd)
    
    SU_Furniture_tb.add_separator
    
    # Add item "Make_Component"
    Make_Component_cmd = UI::Command.new(SUF_STRINGS["Change "] + SUF_STRINGS["Components"]) { Make_Components.make_Component }
    Make_Component_cmd.small_icon = Make_Component_cmd.large_icon = File.join(path_icons, "new_comp.png")
    Make_Component_cmd.tooltip = SUF_STRINGS["Components"] + SUF_STRINGS[" in a library"]
    Make_Component_cmd.status_bar_text = SUF_STRINGS["Add "] + SUF_STRINGS["Components"] + SUF_STRINGS[" in a library"]    
    SU_Furniture_tb.add_item(Make_Component_cmd)
    
    # Add item "Parameters"
    Parameters_cmd = UI::Command.new(SUF_STRINGS["Change "] + SUF_STRINGS["Parameters"]) { $dlg_param && ($dlg_param.visible?) ? $dlg_param.bring_to_front : Parameters_dialog.activate }
    Parameters_cmd.small_icon = Parameters_cmd.large_icon = File.join(path_icons, "parameters.png")
    Parameters_cmd.tooltip = SUF_STRINGS["Parameters"]
    Parameters_cmd.status_bar_text = SUF_STRINGS["Change "] + SUF_STRINGS["Parameters"]  
    SU_Furniture_tb.add_item(Parameters_cmd)
    
    # Add item "Manual"
    # Manual_cmd = UI::Command.new(SUF_STRINGS["Manual"]) { Manual_Browser.manual_dialog }
    # Manual_cmd.small_icon = Manual_cmd.large_icon = File.join(path_icons, "manual.png")
    # Manual_cmd.tooltip = SUF_STRINGS["Manual"]
    # Manual_cmd.status_bar_text = SUF_STRINGS["Open"] + " " + SUF_STRINGS["Manual"]  
    # SU_Furniture_tb.add_item(Manual_cmd)

    update_plugin_icon = ValidatorPlugin::LicenseValidator.plugin_has_updates ? 'update_plugin_2.png' : 'update_plugin_1.png'
    Plugin_cmd = $Plugin_cmd = UI::Command.new(SUF_STRINGS["Update Plugin"]) do

      msg = "This will download and install Plugin \n\nProceed?"
      if UI.messagebox(msg, MB_YESNO) == IDYES
        begin
          url = $debug ? "https://artrocket.ro/sketchup-prerelease.php?license=DEV&version=#{$version}" : "https://artrocket.ro/sketchup-download.php?license=#{$registration_code}"
          plugins_root = Sketchup.find_support_file("Plugins")
          dest         = File.join(plugins_root, "suf")
          ValidatorPlugin::Updater.update(
            url,
            plugins_root,             # <-- pass Plugins root (dest is ignored/overridden anyway)
            keep: [
                "suf/license.lic"
            ],
            verbose: false
          )
        rescue => e
          UI.messagebox("Update failed:\n#{e.message}")
        end
      end
    end    
    Plugin_cmd.small_icon = Plugin_cmd.large_icon = File.join(path_icons, update_plugin_icon)
    Plugin_cmd.tooltip = SUF_STRINGS["Update Plugin"]
    Plugin_cmd.status_bar_text = SUF_STRINGS["Update Plugin"]  
    SU_Furniture_tb.add_item(Plugin_cmd)

    update_price_icon = ValidatorPlugin::LicenseValidator.price_has_updates ? 'update_price_2.png' : 'update_price_1.png'
    Price_cmd = $Price_cmd = UI::Command.new(SUF_STRINGS["Update Price"]) do

      msg = "This will download and install Price Db \n\nProceed?"
      if UI.messagebox(msg, MB_YESNO) == IDYES
        begin
          ValidatorPlugin::Updater.update_prices(
            "https://artrocket.s3.eu-central-1.amazonaws.com/prices.tar.gz",
            verbose:     false
          )
        rescue => e
          UI.messagebox("Update failed:\n#{e.message}")
        end
      end
    end
    Price_cmd.small_icon = Price_cmd.large_icon = File.join(path_icons, update_price_icon)
    Price_cmd.tooltip = SUF_STRINGS["Update Price Db"]
    Price_cmd.status_bar_text = SUF_STRINGS["Update Price Db"]  
    SU_Furniture_tb.add_item(Price_cmd)
    

    update_resource_icon = ValidatorPlugin::LicenseValidator.resource_has_updates ? 'update_library_2' : 'update_library_1'
    Resource_cmd = $Resource_cmd = UI::Command.new(SUF_STRINGS["Update Plugin"]) do
      msg = "This will download and install Resources \nRequires ~30 GB free on the SketchUp install drive to proceed. \n\nProceed?"
      if UI.messagebox(msg, MB_YESNO) == IDYES
        begin
          ValidatorPlugin::Updater.update_resource(
            "https://artrocket-eu.s3.eu-central-1.amazonaws.com/AR_RESOURCES.tar.gz",
            verbose:     false
          )
        rescue => e
          UI.messagebox("Update failed:\n#{e.message}")
        end
      end
    end

    Resource_cmd.small_icon      = Resource_cmd.large_icon = File.join(path_icons, update_resource_icon)
    Resource_cmd.tooltip         = SUF_STRINGS["Update Resource"]
    Resource_cmd.status_bar_text = SUF_STRINGS["Update Resource"]
    SU_Furniture_tb.add_item(Resource_cmd)

    UI.add_context_menu_handler { | menu |
      if Sketchup.active_model.selection
        menu.add_separator
        submenu = menu.add_submenu(PLUGIN_NAME)
        if Sketchup.active_model.selection.to_a.to_s.include?("ComponentInstance")
          #submenu.add_item("Копировать компоненты") { Copy_Comp.comp_copy }
          submenu.add_item(SUF_STRINGS["Make module"]) { Make_module.activate }
          submenu.add_item(SUF_STRINGS["Explode module"]) { Make_module.explode_module }
          submenu.add_item(SUF_STRINGS["Make section"]) { Make_section.activate }
          submenu.add_item(SUF_STRINGS["Explode section"]) { Make_section.explode_section }
          submenu.add_item(SUF_STRINGS["Make hardware"]) { Make_furniture.input_param }
          submenu.add_item(SUF_STRINGS["Explode hardware"]) { Make_furniture.explode_hardware }
          submenu.add_item(SUF_STRINGS["Reset size values"]) { Change_Attributes.reset_size_values }
          submenu.add_item(SUF_STRINGS["Exploded View"]) { Sketchup.active_model.tools.push_tool( Explode_View ) }
          submenu.add_item(SUF_STRINGS["Update dimensions"]) { Dimensions.update_dimensions(Sketchup.active_model) }
          submenu.add_item(SUF_STRINGS["Delete hidden"]) { delete_hidden }
          submenu.add_item(SUF_STRINGS["Drawing of Panels with cutout"]) { Panel_Drawing.activate }
          submenu.add_item(SUF_STRINGS["Resave for LayOut"]) { Export_to_layout.resave_all_modules(Sketchup.active_model,Sketchup.active_model.selection.grep(Sketchup::ComponentInstance).to_a) }
          else
          submenu.add_item(SUF_STRINGS["Make hardware"]) { Make_furniture.input_param }
        end
        menu.add_item(SUF_STRINGS["Hide other"],3) { Pages_Properties.hide_other(Sketchup.active_model,Sketchup.active_model.selection.to_a,Sketchup.active_model.active_entities.to_a) }
        menu.add_item(SUF_STRINGS["Hide in other scenes"],4) { Pages_Properties.hide_show_entity(Sketchup.active_model,Sketchup.active_model.selection.to_a,"true") } if Sketchup.active_model.pages.count > 0
        menu.add_item(SUF_STRINGS["Show hidden objects"],5) { Pages_Properties.show_hidden_objects(Sketchup.active_model) }
      end
    }
  end
end # module SU_Furniture
file_loaded(__FILE__)
