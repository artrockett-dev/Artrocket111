module SU_Furniture

  def self.deep_make_unique(instance, visited_defs = Set.new)
    return unless instance&.valid?
    return unless instance.respond_to?(:definition)

    defn = instance.definition
    return if visited_defs.include?(defn)
    visited_defs << defn

    # Unlock if needed
    was_locked = instance.respond_to?(:locked?) ? instance.locked? : false
    instance.locked = false if was_locked rescue nil

    # Always make unique (per your request)
    begin
      instance.make_unique
    rescue
      # Ignore and continue; some special cases may refuse (rare)
    end

    # Recurse into children of THIS instance's (now-unique) definition
    ents = instance.definition.entities

    ents.grep(Sketchup::ComponentInstance).each do |child|
      next unless child&.valid?
      deep_make_unique(child, visited_defs)
    end

    ents.grep(Sketchup::Group).each do |grp|
      next unless grp&.valid?
      deep_make_unique(grp, visited_defs)
    end

    # Restore lock state
    instance.locked = true if was_locked rescue nil
  end

  class SUFAppObserver < Sketchup::AppObserver
    def expectsStartupModelNotifications
      return true
    end
    def onActivateModel(model)
      
    end
    def onNewModel(model)
      begin
      model.selection.remove_observer $SUFSelectionObserver
      #$SUFSelectionObserver = SUFSelectionObserver.new
      model.selection.add_observer $SUFSelectionObserver
      
      model.entities.remove_observer $SUFEntitiesObserver
      #$SUFEntitiesObserver = SUFEntitiesObserver.new
      model.entities.add_observer $SUFEntitiesObserver
      
      model.layers.remove_observer $SUFLayersObserver
      #$SUFLayersObserver = SUFLayersObserver.new
      model.layers.add_observer $SUFLayersObserver
      
      model.pages.remove_observer $SUFPagesObserver
      #$SUFPagesObserver = SUFPagesObserver.new
      model.pages.add_observer $SUFPagesObserver
      
      model.tools.remove_observer $SUFToolsObserver
      model.tools.add_observer $SUFToolsObserver
      
      model.add_observer(SUFModelObserver.new)
      
      $dlg_param.close if $dlg_param && ($dlg_param.visible?)
      $dlg_suf.close if $dlg_suf && ($dlg_suf.visible?)
      $dlg_spec.close if $dlg_spec && ($dlg_spec.visible?)
			path_param = nil
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      if path_param
        content_temp = File.readlines(path_param)
        model.start_operation "att", true, false, true
        attrdicts = model.attribute_dictionaries
        attrdicts.delete 'su_parameters'
        dict = model.attribute_dictionary('su_parameters', true)
        content_temp.each {|i| model.set_attribute('su_parameters', i.split("=")[1], i) }
        model.commit_operation
      end
      presets = Sketchup.active_model.get_attribute("ladb_opencutlist", "core.presets", nil)
      new_presets = '{"cutlist_options":{"0":{"auto_orient":true,"smart_material":true,"dynamic_attributes_name":true,"part_number_with_letters":false,"part_number_sequence_by_group":true,"part_folding":false,"hide_entity_names":false,"hide_tags":false,"hide_cutting_dimensions":false,"hide_bbox_dimensions":false,"hide_untyped_material_dimensions":false,"hide_final_areas":true,"hide_edges":false,"minimize_on_highlight":true,"part_order_strategy":"name>-length>-width>-thickness>-count>-edge_pattern>tags","dimension_column_order_strategy":"length>width>thickness","tags":[""],"hidden_group_ids":[]}}}'
      Sketchup.active_model.set_attribute("ladb_opencutlist", "core.presets", new_presets) if !presets || presets != '{}'
    rescue => e
      SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
    end
    end#def
    def onOpenModel(model)
      begin
      model.selection.remove_observer $SUFSelectionObserver
      #$SUFSelectionObserver = SUFSelectionObserver.new
      model.selection.add_observer $SUFSelectionObserver
      
      model.entities.remove_observer $SUFEntitiesObserver
      #$SUFEntitiesObserver = SUFEntitiesObserver.new
      model.entities.add_observer $SUFEntitiesObserver
      
      model.layers.remove_observer $SUFLayersObserver
      #$SUFLayersObserver = SUFLayersObserver.new
      model.layers.add_observer $SUFLayersObserver
      
      model.pages.remove_observer $SUFPagesObserver
      #$SUFPagesObserver = SUFPagesObserver.new
      model.pages.add_observer $SUFPagesObserver
      
      model.tools.remove_observer $SUFToolsObserver
      model.tools.add_observer $SUFToolsObserver
      
      model.add_observer(SUFModelObserver.new)
      
      $dlg_param.close if $dlg_param && ($dlg_param.visible?)
      $dlg_suf.close if $dlg_suf && ($dlg_suf.visible?)
      $dlg_spec.close if $dlg_spec && ($dlg_spec.visible?)
      path_param = nil
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      if path_param
        content_temp = File.readlines(path_param)
        model.start_operation "att", true, false, true
        attrdicts = model.attribute_dictionaries
        attrdicts.delete 'su_parameters'
        dict = model.attribute_dictionary('su_parameters', true)
        content_temp.each {|i| model.set_attribute('su_parameters', i.split("=")[1], i) }
        model.commit_operation
      end
      presets = Sketchup.active_model.get_attribute("ladb_opencutlist", "core.presets", nil)
      new_presets = '{"cutlist_options":{"0":{"auto_orient":true,"smart_material":true,"dynamic_attributes_name":true,"part_number_with_letters":false,"part_number_sequence_by_group":true,"part_folding":false,"hide_entity_names":false,"hide_tags":false,"hide_cutting_dimensions":false,"hide_bbox_dimensions":false,"hide_untyped_material_dimensions":false,"hide_final_areas":true,"hide_edges":false,"minimize_on_highlight":true,"part_order_strategy":"name>-length>-width>-thickness>-count>-edge_pattern>tags","dimension_column_order_strategy":"length>width>thickness","tags":[""],"hidden_group_ids":[]}}}'
      Sketchup.active_model.set_attribute("ladb_opencutlist", "core.presets", new_presets) if !presets || presets != '{}'
    rescue => e
      SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
    end
    end#def
		
  end
  
  class SUFToolsObserver < Sketchup::ToolsObserver
	  def initialize()
			@started_move = false
			@started_scale = false
			@last_tool_name = ''
			@last_state = nil
			@timer_ids = []
      @selected_entity = nil
      @sizes = {}
    end
    def onActiveToolChanged(tools, tool_name, tool_id)
      #p "onActiveToolChanged: #{tool_name}:#{tool_id}"
			tool_name = fix_mac_tool_name(tool_name)
			set_last_tool_name(tool_name)
			camera = Sketchup.active_model.active_view.camera
			if @camera_orbit
				if SU_Furniture::const_defined?(:SUF_View) && @values != [camera.up,camera.perspective?]
					SUF_View.reset_camera_values
        end
				@camera_orbit = nil
      end
			if @select_nested && tool_name == "SelectionTool"
				if(Sketchup.version.to_i >= 20)
					Sketchup.active_model.select_tool( Select_Nested )
					@select_nested = nil
        end
				elsif tool_name == "CameraOrbitTool"
				@camera_orbit = true
				@values = [camera.up,camera.perspective?]
      end
    end
		def set_last_tool_name(tool_name)
			@last_tool_name = tool_name
    end
		def last_tool_name()
			return @last_tool_name
    end
		def register_timer_id(timer_id)
			@timer_ids.push timer_id
    end
		def get_timer_ids
			return @timer_ids
    end
		def fix_mac_tool_name(tool_name)
      if tool_name == "eTool"
        tool_name = "ScaleTool"
				elsif tool_name == "ool"
        tool_name = "MoveTool"
				elsif tool_name == "onentCSTool"
        tool_name = "ComponentCSTool"
				elsif tool_name == "PullTool"
        tool_name = "PushPullTool"
      end
      return tool_name
    end
    def onToolStateChanged(tools, tool_name, tool_id, tool_state)
    begin
      #p "onToolStateChanged: #{tool_name}:#{tool_state}"
			tool_name = fix_mac_tool_name(tool_name)
      if tool_name=="ScaleTool" || tool_name=="MoveTool"
        Sketchup.active_model.selection.remove_observer $SUFSelectionObserver
        Sketchup.active_model.entities.remove_observer $SUFEntitiesObserver
        model = Sketchup.active_model
        selection = model.selection.grep(Sketchup::ComponentInstance)
        
        if selection.count > 0
          if(Sketchup.version.to_i >= 20)
            instance = selection[0]
            parent = instance.parent
            if !parent.to_s.include?("Sketchup::Model")
              if !model.active_path
                model.start_operation "active_path", true, false, true
                @select_nested = true 
                all_comp = search_parent(instance)
                arr_comp = []
                all_comp.reverse.each { |comp|
                  arr_comp += [comp]
                  model.selection.clear
                  model.selection.add comp
                  model.active_path = arr_comp
                }
                model.selection.clear
                model.selection.add selection
                model.commit_operation
              end
            end
          end
          
          if tool_name=="MoveTool"
            if tool_state==0 && !@started_move
              if model.active_path
                model.start_operation "delete_formula", true, false, true
                selection.each { |entity|
                  if is_dynamic?(entity)
                    _x_formula = entity.get_attribute("dynamic_attributes", "_x_formula")
                    _y_formula = entity.get_attribute("dynamic_attributes", "_y_formula")
                    _z_formula = entity.get_attribute("dynamic_attributes", "_z_formula")
                    if _x_formula || _y_formula || _z_formula
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__x_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__y_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__z_formula")
                      entity.delete_attribute("dynamic_attributes", "_x_formula")
                      entity.delete_attribute("dynamic_attributes", "_y_formula")
                      entity.delete_attribute("dynamic_attributes", "_z_formula")
                    end
                  end
                }
                model.commit_operation
              end
              @started_move = false
              
              elsif tool_state==1
              if selection.count == 1
                @selected_entity = selection[0]
              end
              @started_move = true
              
              elsif tool_state==0 && @started_move
              model.start_operation "move_notch", true, false, true
              selection.each { |entity|
                tr = Geom::Transformation.new
                Fasteners_Panel.search_parent(entity).reverse.each { |e| tr *= e.transformation }
                notch_arr = Fasteners_Panel.find_notch(entity,tr)
                ids = Fasteners_Panel.delete_all_notches(entity)
                if !ids.empty?
                  entities_arr = Fasteners_Panel.find_entities_by_ids(ids)
                  entities_arr.each { |ent|
                    tr = Geom::Transformation.new
                    Fasteners_Panel.search_parent(ent).reverse.each { |e| tr *= e.transformation }
                    notch_arr += Fasteners_Panel.find_notch(ent,tr)
                  }
                end
                Fasteners_Panel.modified_notch(notch_arr) if !notch_arr.empty?
              }
              model.commit_operation
              @selected_entity = nil
              @started_move = false
            end
          end
          
          if tool_name=="ScaleTool"
            if tool_state==0
              DCProgressBar.clear()
              return if @inside_observer_event
              @inside_observer_event = true
              model.start_operation "scale_mask", true, false, true
              scaled_entities = []
              selection.each { |entity|
                if is_dynamic?(entity)
                  if !entity.parent.is_a?(Sketchup::Model)
                    @point_x_offset = entity.definition.get_attribute("dynamic_attributes", "point_x_offset") #Vertical
                    @point_y_offset = entity.definition.get_attribute("dynamic_attributes", "point_y_offset") #Frontal
                    @point_z_offset = entity.definition.get_attribute("dynamic_attributes", "point_z_offset") #Gorizontal
                    scaletool = entity.definition.get_attribute("dynamic_attributes", "scaletool", "0")
                    s9_scale_grip = entity.definition.get_attribute("dynamic_attributes", "s9_scale_grip")
                    edge_y1 = entity.definition.get_attribute("dynamic_attributes", "edge_y1")
                    su_type = entity.definition.get_attribute("dynamic_attributes", "su_type")
                    if !@point_x_offset && !@point_y_offset && !@point_z_offset
                      if entity.definition.name.include?("Направляющая")
                        entity.set_attribute("dynamic_attributes", "scaletool", "126")
                        entity.definition.set_attribute("dynamic_attributes", "scaletool", "126")
                        entity.definition.behavior.no_scale_mask = 126
                        elsif edge_y1 && scaletool != "105" && scaletool != "120"
                        entity.set_attribute("dynamic_attributes", "scaletool", "105")
                        entity.definition.set_attribute("dynamic_attributes", "scaletool", "105")
                        entity.definition.behavior.no_scale_mask = 105
                        elsif su_type && !s9_scale_grip
                        entity.set_attribute("dynamic_attributes", "scaletool", "120")
                        entity.definition.set_attribute("dynamic_attributes", "scaletool", "120")
                        entity.definition.behavior.no_scale_mask = 120
                      end
                    end
                  end
                  if @started_scale==true
                    Export_to_layout.resave_single_module(model,entity) if entity.parent.is_a?(Sketchup::Model)
                    scaled_entities << entity
                    Change_Attributes.size_values(entity,@sizes)
                    @sizes = {}
                    tr = Geom::Transformation.new
                    Fasteners_Panel.search_parent(entity).reverse.each { |e| tr *= e.transformation }
                    notch_arr = Fasteners_Panel.find_notch(entity,tr)
                    ids = Fasteners_Panel.delete_all_notches(entity)
                    if !ids.empty?
                      entities_arr = Fasteners_Panel.find_entities_by_ids(ids)
                      entities_arr.each { |ent|
                        tr = Geom::Transformation.new
                        Fasteners_Panel.search_parent(ent).reverse.each { |e| tr *= e.transformation }
                        notch_arr += Fasteners_Panel.find_notch(ent,tr)
                      }
                    end
                    if !notch_arr.empty?
                      Fasteners_Panel.modified_notch(notch_arr)
                      lenx,leny,lenz = entity.unscaled_size
                      entity.set_last_size(lenx,leny,lenz)
                    end
                  end
                end
              }
              if @started_scale==true && scaled_entities != []
                if $attobserver == 2
                  $dlg_suf.execute_script("add_comp()")
                  elsif $attobserver == 4
                  if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
                    $dlg_suf.execute_script("check_listtablinks()")
                  end
                  end
                  $dlg_att.execute_script("add_comp()") if $dlg_att
                end
                model.commit_operation
                
                @started_scale = false
                @inside_observer_event = false
                
                elsif tool_state==1
                
                model.start_operation "delete_formula", true, false, true
                selection.each { |entity|
                  len_formula(entity)
                  if !entity.parent.to_s.include?("Sketchup::Model")
                    @point_x_offset = entity.definition.get_attribute("dynamic_attributes", "point_x_offset") #Vertical
                    @point_y_offset = entity.definition.get_attribute("dynamic_attributes", "point_y_offset") #Frontal
                    @point_z_offset = entity.definition.get_attribute("dynamic_attributes", "point_z_offset") #Gorizontal
                    _a00_lenx_formula = entity.definition.get_attribute("dynamic_attributes", "_a00_lenx_formula")
                    _a00_leny_formula = entity.definition.get_attribute("dynamic_attributes", "_a00_leny_formula")
                    _a00_lenz_formula = entity.definition.get_attribute("dynamic_attributes", "_a00_lenz_formula")
                    _x_formula = entity.get_attribute("dynamic_attributes", "_x_formula")
                    _y_formula = entity.get_attribute("dynamic_attributes", "_y_formula")
                    _z_formula = entity.get_attribute("dynamic_attributes", "_z_formula")
                    scaletool = entity.definition.get_attribute("dynamic_attributes", "scaletool", "0")
                    
                    if @point_y_offset
                      if _a00_lenx_formula || _a00_lenz_formula
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_lenx_formula") 
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_lenz_formula")
                        entity.delete_attribute("dynamic_attributes", "_x_formula")
                        entity.delete_attribute("dynamic_attributes", "_y_formula")
                        entity.delete_attribute("dynamic_attributes", "_z_formula")
                      end
                      elsif @point_x_offset
                      if _a00_leny_formula || _a00_lenz_formula
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_leny_formula") 
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_lenz_formula")
                        entity.definition.delete_attribute("dynamic_attributes", "_inst__x_formula")
                        entity.definition.delete_attribute("dynamic_attributes", "_inst__y_formula")
                        entity.definition.delete_attribute("dynamic_attributes", "_inst__z_formula")
                        entity.delete_attribute("dynamic_attributes", "_x_formula")
                        entity.delete_attribute("dynamic_attributes", "_y_formula")
                        entity.delete_attribute("dynamic_attributes", "_z_formula")
                      end
                      elsif @point_z_offset
                      if _a00_lenx_formula || _a00_leny_formula
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_lenx_formula") 
                        entity.definition.delete_attribute("dynamic_attributes", "_a00_leny_formula")
                        entity.delete_attribute("dynamic_attributes", "_x_formula")
                        entity.delete_attribute("dynamic_attributes", "_y_formula")
                        entity.delete_attribute("dynamic_attributes", "_z_formula")
                      end
                      elsif scaletool == "126"
                      entity.definition.delete_attribute("dynamic_attributes", "_lenx_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__x_formula")
                      entity.delete_attribute("dynamic_attributes", "_x_formula")
                      
                      elsif scaletool != "120"
                      entity.definition.delete_attribute("dynamic_attributes", "_leny_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_lenz_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__x_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__y_formula")
                      entity.definition.delete_attribute("dynamic_attributes", "_inst__z_formula")
                      entity.delete_attribute("dynamic_attributes", "_x_formula")
                      entity.delete_attribute("dynamic_attributes", "_y_formula")
                      entity.delete_attribute("dynamic_attributes", "_z_formula")
                    end
                  end
                }
                model.commit_operation
                @started_scale = true
            end
          end
        end
        if SU_Furniture.observers_state == 1
          Sketchup.active_model.selection.add_observer $SUFSelectionObserver
          Sketchup.active_model.entities.add_observer $SUFEntitiesObserver
        end
      end
			@last_state = tool_state
			set_last_tool_name(tool_name)
    rescue => e
      SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
    end
    end#def
		def is_dynamic?(entity)
			return false unless entity.respond_to?(:definition)
			return true if entity.attribute_dictionary('dynamic_attributes')
			return true if entity.definition.attribute_dictionary('dynamic_attributes')
			return false
    end
		def len_formula(entity)
			if entity.definition.get_attribute("dynamic_attributes", "_lenx_formula") == 'IF(CURRENT("LenX")*2.54=a00_lenx,SETLEN("a00_lenx",IF(CURRENT("LenX")*2.54<x_min_x,x_min_x,IF(CURRENT("LenX")*2.54>x_max_x,x_max_x,ROUND(CURRENT("LenX")*2.54,1)))),a00_lenx)' || entity.definition.get_attribute("dynamic_attributes", "_lenx_formula") == 'IF(CURRENT(&quot;LenX&quot;)*2.54=a00_lenx,SETLEN(&quot;a00_lenx&quot;,IF(CURRENT(&quot;LenX&quot;)*2.54<x_min_x,x_min_x,IF(CURRENT(&quot;LenX&quot;)*2.54>x_max_x,x_max_x,ROUND(CURRENT(&quot;LenX&quot;)*2.54,1)))),a00_lenx)'
				entity.definition.set_attribute("dynamic_attributes", "_lenx_formula", 'IF(CURRENT("LenX")*2.54=a00_lenx,SETLEN("a00_lenx",IF(CURRENT("LenX")*2.54<x_min_x,x_min_x,IF(CURRENT("LenX")*2.54>x_max_x,x_max_x,ROUND(CURRENT("LenX")*2.54,1))),IF(CURRENT("LenX")*2.54>x_max_x,2,3)),a00_lenx)')
      end
			if entity.definition.get_attribute("dynamic_attributes", "_leny_formula") == 'IF(CURRENT("LenY")*2.54=a00_leny,SETLEN("a00_leny",IF(CURRENT("LenY")*2.54<x_min_y,x_min_y,IF(CURRENT("LenY")*2.54>x_max_y,x_max_y,ROUND(CURRENT("LenY")*2.54,1)))),a00_leny)' || entity.definition.get_attribute("dynamic_attributes", "_leny_formula") == 'IF(CURRENT(&quot;LenY&quot;)*2.54=a00_leny,SETLEN(&quot;a00_leny&quot;,IF(CURRENT(&quot;LenY&quot;)*2.54<x_min_y,x_min_y,IF(CURRENT(&quot;LenY&quot;)*2.54>x_max_y,x_max_y,ROUND(CURRENT(&quot;LenY&quot;)*2.54,1)))),a00_leny)'
				entity.definition.set_attribute("dynamic_attributes", "_leny_formula", 'IF(CURRENT("LenY")*2.54=a00_leny,SETLEN("a00_leny",IF(CURRENT("LenY")*2.54<x_min_y,x_min_y,IF(CURRENT("LenY")*2.54>x_max_y,x_max_y,ROUND(CURRENT("LenY")*2.54,1))),IF(CURRENT("LenY")*2.54>x_max_y,2,3)),a00_leny)')
      end
			if entity.definition.get_attribute("dynamic_attributes", "_lenz_formula") == 'IF(CURRENT("LenZ")*2.54=a00_lenz,SETLEN("a00_lenz",IF(CURRENT("LenZ")*2.54<x_min_z,x_min_z,IF(CURRENT("LenZ")*2.54>x_max_z,x_max_z,ROUND(CURRENT("LenZ")*2.54,1)))),a00_lenz)' || entity.definition.get_attribute("dynamic_attributes", "_lenz_formula") == 'IF(CURRENT(&quot;LenZ&quot;)*2.54=a00_lenz,SETLEN(&quot;a00_lenz&quot;,IF(CURRENT(&quot;LenZ&quot;)*2.54<x_min_z,x_min_z,IF(CURRENT(&quot;LenZ&quot;)*2.54>x_max_z,x_max_z,ROUND(CURRENT(&quot;LenZ&quot;)*2.54,1)))),a00_lenz)'
				entity.definition.set_attribute("dynamic_attributes", "_lenz_formula", 'IF(CURRENT("LenZ")*2.54=a00_lenz,SETLEN("a00_lenz",IF(CURRENT("LenZ")*2.54<x_min_z,x_min_z,IF(CURRENT("LenZ")*2.54>x_max_z,x_max_z,ROUND(CURRENT("LenZ")*2.54,1))),IF(CURRENT("LenZ")*2.54>x_max_z,2,3)),a00_lenz)')
      end
    end
		def search_parent(entity,all_comp=[])
			if entity.parent.is_a?(Sketchup::ComponentDefinition)
				if entity.parent.instances[-1]
					all_comp << entity.parent.instances[-1]
					search_parent(entity.parent.instances[-1],all_comp)
        end
      end
      return all_comp
    end#def
  end
  
  class SUFEntitiesObserver < Sketchup::EntitiesObserver
    # def onElementAdded(entities, entity)
    #   begin
    #   if entity.valid?
    #     if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::Text) || entity.is_a?(Sketchup::Dimension) || entity.is_a?(Sketchup::ConstructionPoint) || entity.is_a?(Sketchup::ConstructionLine)
          
    #       @model = Sketchup.active_model
    #       @auto_save = @model.get_attribute('su_parameters', "auto_save")
    #       @auto_option = @model.get_attribute('su_parameters', "auto_option")
    #       @auto_dimension = @model.get_attribute('su_parameters', "auto_dimension")
    #       @intersect = @model.get_attribute('su_parameters', "intersect")
    #       @pages_properties = @model.get_attribute('su_parameters', "pages_properties")
    #       if @pages_properties == "no"
    #         @model.start_operation "set_attribute", true, false, true
    #         @model.set_attribute('pages_properties','hide_new_objects',"false") 
    #         @model.commit_operation
    #       end
    #       if @model.pages.count > 1 && @pages_properties == "yes"
    #         Pages_Properties.activate(entity)
    #       end
    #       number_comp = @model.get_attribute('su_lists','number_comp')
    #       if entity.is_a?(Sketchup::ComponentInstance)
    #         p "onElementAdded: #{entity.definition.name}"
    #         tool_name = @model.tools.active_tool_name
    #         su_type = entity.definition.get_attribute("dynamic_attributes", "su_type", "0")
		# 				if tool_name == "MoveTool"
    #           Dimensions.place_component_with_dimension(entities,entity,"added",@auto_dimension.split("=")[2]) if su_type != "furniture"
    #           else
    #           if su_type != "furniture"
    #             @model.start_operation "ElementAdded", true, false, true
    #             @point_x_offset = entity.definition.get_attribute("dynamic_attributes", "point_x_offset") #Vertical
    #             @point_y_offset = entity.definition.get_attribute("dynamic_attributes", "point_y_offset") #Frontal
    #             @point_z_offset = entity.definition.get_attribute("dynamic_attributes", "point_z_offset") #Gorizontal
    #             @trim_x1 = entity.definition.get_attribute("dynamic_attributes", "trim_x1") #Изделие
    #             @trim_x2 = entity.definition.get_attribute("dynamic_attributes", "trim_x2") #Изделие
                
    #             entities.grep(Sketchup::Group).each { |ent| ent.erase! if ent.name.include?("intersect") } if @intersect == "no"
    #             notch_arr = []
    #             if entity.parent.to_s.include?("Sketchup::Model")
    #               notch_arr = Fasteners_Panel.find_notch(entity,Geom::Transformation.new)
    #             end
    #             Intersect_Components.intersect_bound(entities, entity, @point_x_offset, @point_y_offset, @point_z_offset) if @intersect == "yes" && notch_arr == []
                
    #             if entity.definition.count_instances > 1
    #               #UI.start_timer(0.1, false) { entity.make_unique if !entity.deleted? }
    #               #Copy_Comp.erase_instance(entity.definition.instances)
    #             end
    #             if $attobserver == 2
    #               $dlg_suf.execute_script("add_comp()")
    #               elsif $attobserver == 4
    #               if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
    #                 $dlg_suf.execute_script("check_listtablinks()")
    #               end
    #             end
    #             $dlg_att.execute_script("add_comp()") if $dlg_att
    #             if Sketchup.version_number < 2110000000
    #               if $add_component && $add_component == 1
    #                 if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
    #                   if @auto_option == "yes"
    #                     option_timer = UI.start_timer(0.2, false) { Sketchup.active_model.tools.push_tool(Change_Point) }
    #                   end
    #                 end
    #               end
    #             end
    #             @model.set_attribute('su_lists','number_comp','false') if !number_comp || number_comp != 'false'
    #             @model.commit_operation
    #           end
    #         end
    #       end
    #     end
    #   end
    #   rescue => e
    #     SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
    #   end

    def onElementAdded(entities, entity)
      begin
        if entity.valid?
          if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::Text) || entity.is_a?(Sketchup::Dimension) || entity.is_a?(Sketchup::ConstructionPoint) || entity.is_a?(Sketchup::ConstructionLine)

            @model = Sketchup.active_model
            @auto_save        = @model.get_attribute('su_parameters', "auto_save")
            @auto_option      = @model.get_attribute('su_parameters', "auto_option")
            @auto_dimension   = @model.get_attribute('su_parameters', "auto_dimension")
            @intersect        = @model.get_attribute('su_parameters', "intersect")
            @pages_properties = @model.get_attribute('su_parameters', "pages_properties")

            if @pages_properties == "no"
              @model.start_operation "set_attribute", true, false, true
              @model.set_attribute('pages_properties','hide_new_objects',"false")
              @model.commit_operation
            end

            if @model.pages.count > 1 && @pages_properties == "yes"
              Pages_Properties.activate(entity)
            end

            number_comp = @model.get_attribute('su_lists','number_comp')

            if entity.is_a?(Sketchup::ComponentInstance)
              @model.selection.clear
              p "onElementAdded: #{entity.definition.name}"
              tool_name = @model.tools.active_tool_name
              su_type   = entity.definition.get_attribute("dynamic_attributes", "su_type", "0")

              # ------------------------------------------------------------------
              # NEW: Force deep uniqueness for the added component and all children
              # ------------------------------------------------------------------
              sel = @model.selection
              begin
                sel.remove_observer($SUFSelectionObserver) if defined?($SUFSelectionObserver) && $SUFSelectionObserver
                @model.start_operation "Deep Make Unique (added)", true, false, true
                if SU_Furniture.respond_to?(:deep_make_unique)
                  SU_Furniture.deep_make_unique(entity)  # requires helper defined in SU_Furniture module
                else
                  # Fallback: at least make the root unique
                  entity.make_unique rescue nil
                end
                @model.commit_operation
              ensure
                sel.add_observer($SUFSelectionObserver) if defined?($SUFSelectionObserver) && $SUFSelectionObserver
              end
              # ------------------------------------------------------------------

              if tool_name == "MoveTool"
                Dimensions.place_component_with_dimension(entities, entity, "added", @auto_dimension.split("=")[2]) if su_type != "furniture"
              else
                if su_type != "furniture"
                  @model.start_operation "ElementAdded", true, false, true

                  @point_x_offset = entity.definition.get_attribute("dynamic_attributes", "point_x_offset") # Vertical
                  @point_y_offset = entity.definition.get_attribute("dynamic_attributes", "point_y_offset") # Frontal
                  @point_z_offset = entity.definition.get_attribute("dynamic_attributes", "point_z_offset") # Gorizontal
                  @trim_x1        = entity.definition.get_attribute("dynamic_attributes", "trim_x1")        # Изделие
                  @trim_x2        = entity.definition.get_attribute("dynamic_attributes", "trim_x2")        # Изделие

                  entities.grep(Sketchup::Group).each { |ent| ent.erase! if ent.name.include?("intersect") } if @intersect == "no"

                  notch_arr = []
                  if entity.parent.to_s.include?("Sketchup::Model")
                    notch_arr = Fasteners_Panel.find_notch(entity, Geom::Transformation.new)
                  end

                  Intersect_Components.intersect_bound(entities, entity, @point_x_offset, @point_y_offset, @point_z_offset) if @intersect == "yes" && notch_arr == []

                  if $attobserver == 2
                    $dlg_suf.execute_script("add_comp()")
                  elsif $attobserver == 4
                    if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
                      $dlg_suf.execute_script("check_listtablinks()")
                    end
                  end
                  $dlg_att.execute_script("add_comp()") if $dlg_att

                  if Sketchup.version_number < 2110000000
                    if $add_component && $add_component == 1
                      if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
                        if @auto_option == "yes"
                          option_timer = UI.start_timer(0.2, false) { Sketchup.active_model.tools.push_tool(Change_Point) }
                        end
                      end
                    end
                  end

                  @model.set_attribute('su_lists','number_comp','false') if !number_comp || number_comp != 'false'
                  @model.commit_operation
                end
              end
            end
            model.selection.clear
          end
        end
      rescue => e
        if SU_Furniture::LoggerHelper.respond_to?(:logger)
          SU_Furniture::LoggerHelper.logger.error("[#{self.class}##{__method__}] #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}")
        end
      end
    end#def 

    def onElementModified(entities, entity)
      begin
      if entity.is_a?(Sketchup::ComponentInstance)
        "onElementModified: #{entity.definition.name}"
        @model = Sketchup.active_model
        @auto_save = @model.get_attribute('su_parameters', "auto_save")
        @auto_option = @model.get_attribute('su_parameters', "auto_option")
        @auto_dimension = @model.get_attribute('su_parameters', "auto_dimension")
        @intersect = @model.get_attribute('su_parameters', "intersect")
        @pages_properties = @model.get_attribute('su_parameters', "pages_properties")
        tool_name = @model.tools.active_tool_name
        Save_Copy.save if tool_name != "MoveTool" && !entity.hidden?
        if !$onTransactionUndo
          @model.start_operation "ElementModified", true, false, true
          entities.grep(Sketchup::Group).each { |ent| ent.erase! if ent.name.include?("intersect") }
          entity.definition.delete_attribute("dynamic_attributes", "_draw_edges") if entity.definition.get_attribute("dynamic_attributes", "_draw_edges")
          Dimensions.place_component_with_dimension(entities,entity,"modified",@auto_dimension.split("=")[2]) if $attobserver > 0 && $attobserver < 4 && tool_name == "MoveTool"
          
          if entity.parent.to_s.include?("Sketchup::Model")
            Change_Point.reset_essence_and_faces
          end
          notch_arr = []
          if tool_name != "MoveTool" && tool_name != "ScaleTool"
            if !@modified_notch
              @modified_notch = true
              tr = Geom::Transformation.new
              Fasteners_Panel.search_parent(entity).reverse.each { |e| tr *= e.transformation }
              notch_arr = Fasteners_Panel.find_notch(entity,tr)
              ids = Fasteners_Panel.delete_all_notches(entity)
              if !ids.empty?
                entities_arr = Fasteners_Panel.find_entities_by_ids(ids)
                entities_arr.each { |ent|
                  tr = Geom::Transformation.new
                  Fasteners_Panel.search_parent(ent).reverse.each { |e| tr *= e.transformation }
                  notch_arr += Fasteners_Panel.find_notch(ent,tr)
                }
              end
              Fasteners_Panel.modified_notch(notch_arr) if !notch_arr.empty?
            end
            if $attobserver == 2 && !$change_att
              UI.start_timer(0.1, false) { $dlg_suf.execute_script("add_comp()") }
              elsif $attobserver == 4 && @model.selection.count > 0
              UI.stop_timer(@false_timer) if @false_timer
              if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
                @false_timer = UI.start_timer(1, false) { $dlg_suf.execute_script("check_listtablinks()") }
              end
            end
            $dlg_att.execute_script("add_comp()") if $dlg_att && !$change_param
            # Export_to_layout.resave_single_module(@model,entity)
          end
          Intersect_Components.intersect_bound(entities, entity, @point_x_offset, @point_y_offset, @point_z_offset) if @intersect == "yes" && notch_arr.empty?
          number_comp = @model.get_attribute('su_lists','number_comp')
          @model.set_attribute('su_lists','number_comp','false') if !number_comp || number_comp != 'false'
          @model.commit_operation
        end
      end
      UI.start_timer(0.5, false) { @modified_notch = false }
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end#def
    def onElementRemoved(entities, entity_id)
      #p "onElementRemoved: #{entity_id}"
      @model = Sketchup.active_model
      all_entities = $SUFSelectionObserver.all_entities
      deleted_id = all_entities - entities.grep(Sketchup::ComponentInstance).to_a.map{|ent|ent.persistent_id}
      @model.start_operation "ElementRemoved", true, false, true
      entities.grep(Sketchup::ComponentInstance).each { |ent| Fasteners_Panel.delete_all_notches(ent,deleted_id) }
      @model.commit_operation
      if $attobserver > 0 && $attobserver < 4
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("delete_ok_image()") }
      end
      @sel_change = false
      if $attobserver == 2
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("clear_selection()") if !@sel_change }
        elsif $attobserver == 4
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("clear_selection_list()") if !@sel_change }
      end
      UI.start_timer(0.1, false) { $dlg_att.execute_script("clear_selection()") if $dlg_att && !@sel_change }
      Change_Point.reset_essence_and_faces
    end#def
  end
  
  class SUFViewObserver < Sketchup::ViewObserver
    def onViewChanged(view)
      if Sketchup.active_model.active_path == nil
        Hide_Walls.hide_walls(view.camera) unless ValidatorPlugin::LicenseValidator.license_denied
      end
    end
  end
  
  class SUFPagesObserver < Sketchup::PagesObserver
    def onElementAdded(pages, page)
      p "PageAdded: #{page.name}"
    end
    def onContentsModified(pages)
      $PagesModified = true
      UI.start_timer(1, false) { $PagesModified = false }
    end
  end
  
  class SUFLayersObserver < Sketchup::LayersObserver
    def onLayerChanged(layers, layer)
      begin
      UI.start_timer(0.1, false) {
        @hide_face = Sketchup.active_model.get_attribute('su_parameters', "hide_face")
        if $PagesModified != true && !layer.deleted?
          Sketchup.active_model.start_operation "layers", true, false, true
          if layer.name == "1_Фасад"
            if layer.visible? 
              layers.each { |l| l.visible = true if l.name == "1_Фасад_ящика" }
              elsif !layer.visible?
              layers.each { |l| l.visible = false if l.name == "1_Фасад_ящика" }
            end
          end
          if layer.name.include?("опции") && layer.visible?
            layers.each { |l| l.visible = false if l.name.include?("открывание") }
          end
          if layer.name.include?("открывание") && layer.visible?
            layers.each { |l| l.visible = false if l.name.include?("опции") }
          end
          Sketchup.active_model.commit_operation
        end
        Sketchup::focus if Sketchup.respond_to?(:focus)
      }
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end#def
  end
  
  class SUFModelObserver <  Sketchup::ModelObserver
    def initialize()
      @last_active_path = []
      @undo_timer = nil
    end
    def onActivePathChanged(model)
      #p "onActivePathChanged"
      if model.active_path == nil
        active_path_length = 0
        else
        active_path_length = model.active_path.length
      end
      if @last_active_path == nil
        last_path_length = 0
        else
        last_path_length = @last_active_path.length
      end
      
      if last_path_length > active_path_length
        entity = @last_active_path.pop
        if $attobserver == 2 || $dlg_att || $attobserver == 4 && Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
          Sketchup.active_model.selection.add(entity) if !entity.deleted?
        end
        elsif last_path_length < active_path_length
        entity = model.active_path.last
      end
      @last_active_path = model.active_path
    end#def
    def onTransactionUndo(model)
      #p "Transaction undone."
      UI.stop_timer(@undo_timer) if @undo_timer
      $onTransactionUndo = true
      @undo_timer = UI.start_timer(1, false) { $onTransactionUndo = false }
    end#def
    def onDeleteModel(model)
      $SUFToolsObserver.get_timer_ids.each { |timer_id|
        UI.stop_timer(timer_id)
      }
    end
  end
  
  class SUFSelectionObserver < Sketchup::SelectionObserver
    def initialize
      @selection = []
      @all_entities = []
    end
    def onSelectionAdded(selection, entity)
      begin
        SU_Furniture.add_remove_observers(1)
        p "onSelectionAdded: #{entity}"
        @all_entities = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a.map{|ent|ent.persistent_id}
        if $SUFToolsObserver.last_tool_name == "PushPullTool" || $SUFToolsObserver.last_tool_name == "MoveTool" || $SUFToolsObserver.last_tool_name == "EraseTool"
          return
        end
        @sel_change = true 
        if entity.is_a?(Sketchup::ComponentInstance)
          @selection << entity
          if $attobserver == 2
            $dlg_suf.execute_script("add_comp()")
            elsif $attobserver == 4
            if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
              $dlg_suf.execute_script("check_listtablinks()")
            end
          end
          $dlg_att.execute_script("add_comp()") if $dlg_att
          # if selection.count == 1
          #   entity = selection[0]
          #   if entity && entity.valid? && entity.is_a?(Sketchup::ComponentInstance)
          #     @make_unique = Sketchup.active_model.get_attribute('su_parameters', "make_unique")
          #     @make_unique = "true" if !@make_unique
          #     if @make_unique.include?("true") && entity.definition.count_instances > 1
          #       selection.remove_observer $SUFSelectionObserver
          #       Sketchup.active_model.start_operation "make_unique", true, false, true
          #       entity.make_unique 
          #       Sketchup.active_model.commit_operation
          #       selection.add_observer $SUFSelectionObserver
          #     end
          #     get_dimensions(entity)
          #   end
          # end
          if selection.count == 1
            entity = selection[0]
            if entity && entity.valid? && entity.is_a?(Sketchup::ComponentInstance)
              # Always deep-make-unique per user request
              selection.remove_observer $SUFSelectionObserver
              model = Sketchup.active_model
              model.start_operation "Deep Make Unique (selection)", true, false, true
              begin
                SU_Furniture.deep_make_unique(entity)
              ensure
                model.commit_operation
                selection.add_observer $SUFSelectionObserver
              end
              get_dimensions(entity)
            end
          end
        end
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end
    def onSelectionBulkChange(selection)
      begin
      #p "onSelectionBulkChange: #{selection.count}"
      @all_entities = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a.map{|ent|ent.persistent_id}
      selection.remove_observer $SUFSelectionObserver
      if selection.empty?
        clear_selection
        elsif selection.count == 1 && selection[0].is_a?(Sketchup::ComponentInstance)
        clear_selection
        @selection << selection[0]
        else
        entity = selection.detect{|ent|ent.is_a?(Sketchup::ComponentInstance)}
        if entity && entity.valid? && entity.is_a?(Sketchup::ComponentInstance)
          @selection &= selection.grep(Sketchup::ComponentInstance).to_a
          @selection += selection.grep(Sketchup::ComponentInstance).to_a - @selection
        end
      end
      selection.add_observer $SUFSelectionObserver
      if $SUFToolsObserver.last_tool_name == "PushPullTool" || $SUFToolsObserver.last_tool_name == "MoveTool" || $SUFToolsObserver.last_tool_name == "EraseTool"
        return
      end
      tool_name = Sketchup.active_model.tools.active_tool_name
      @sel_change = true
      if selection.count == 1 && !selection[0].is_a?(Sketchup::ComponentInstance) || tool_name == "DimensionTool" || tool_name == "3DTextTool" || tool_name == "TextTool"
        UI.start_timer(0.1, false) {
          $dlg_suf.execute_script("clear_selection()") if $attobserver == 2
          $dlg_suf.execute_script("clear_selection_list(false)") if $attobserver == 4
          $dlg_att.execute_script("clear_selection()") if $dlg_att
        }
        elsif selection.count > 0
        entity = selection.detect{|ent|ent.is_a?(Sketchup::ComponentInstance)}
        if entity && entity.valid? && entity.is_a?(Sketchup::ComponentInstance)
          if $attobserver == 1 || $attobserver == 3
            UI.start_timer(0.1, false) { $dlg_suf.execute_script("delete_ok_image()") }
          end
          $dlg_att.execute_script("add_comp()") if $dlg_att
          if $attobserver == 2
            $dlg_suf.execute_script("add_comp()")
            elsif $attobserver == 4
            if Sketchup.active_model.get_attribute('su_parameters', "auto_refresh", "вкл.") == "вкл."
              $dlg_suf.execute_script("check_listtablinks()")
            end
          end
          if selection.count == 1
            @make_unique = Sketchup.active_model.get_attribute('su_parameters', "make_unique")
            @make_unique = "0=make_unique=false" if !@make_unique
            if @make_unique.split("=")[2] == "true" && entity.definition.count_instances > 1
              selection.remove_observer $SUFSelectionObserver
              Sketchup.active_model.start_operation "make_unique", true, false, true
              entity.make_unique 
              Sketchup.active_model.commit_operation
              selection.add_observer $SUFSelectionObserver
            end
            get_dimensions(entity)
          end
        end
      end
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end#def
    def onSelectionCleared(selection)
      begin
      #p "onSelectionCleared: #{selection.count}"
      if $SUFToolsObserver.last_tool_name == "PushPullTool" || $SUFToolsObserver.last_tool_name == "MoveTool" || $SUFToolsObserver.last_tool_name == "EraseTool"
        return
      end
      @all_entities = Sketchup.active_model.entities.grep(Sketchup::ComponentInstance).to_a.map{|ent|ent.persistent_id}
      selection.remove_observer $SUFSelectionObserver
      clear_selection
      selection.add_observer $SUFSelectionObserver
      @purge_unused = Sketchup.active_model.get_attribute('su_parameters', "purge_unused")
      @purge_unused = "0=purge_unused=no" if !@purge_unused
      Sketchup.active_model.definitions.purge_unused if @purge_unused.split("=")[2] == "yes"
      if $attobserver == 1 || $attobserver == 3
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("delete_ok_image()") }
      end
      @sel_change = false
      if $attobserver == 2
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("clear_selection()") if !@sel_change }
        elsif $attobserver == 4
        UI.start_timer(0.1, false) { $dlg_suf.execute_script("clear_selection_list()") if !@sel_change }
      end
      UI.start_timer(0.1, false) { $dlg_att.execute_script("clear_selection()") if $dlg_att && !@sel_change }
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end#def
    def get_dimensions(entity)
      begin
      a03_name = entity.definition.get_attribute("dynamic_attributes", "a03_name", "")
      a03_name = " ("+a03_name+")" if a03_name != ""
      width = entity.definition.get_attribute("dynamic_attributes", "_lenx_nominal", 0).to_f*25.4
      height = entity.definition.get_attribute("dynamic_attributes", "_leny_nominal", 0).to_f*25.4
      depth = entity.definition.get_attribute("dynamic_attributes", "_lenz_nominal", 0).to_f*25.4
      entity.material ? material_name = " | Material: "+entity.material.display_name : material_name = ""
      Sketchup::set_status_text(("Name: "+entity.definition.name+a03_name+" | LenX: "+width.ceil.abs.to_s+" мм. LenY: "+height.ceil.abs.to_s+" мм. LenZ: "+depth.ceil.abs.to_s+" мм."+material_name), SB_PROMPT)
      rescue => e
        SU_Furniture::LoggerHelper.logger.info(e.backtrace.join("/"))
      end
    end#def
    def selected
      @selection
    end
    def add_selection(entity)
      @selection << entity
    end
    def clear_selection()
      @selection = []
    end
    def all_entities
      @all_entities
    end
  end
  
  $SUFAppObserver = SUFAppObserver.new
  Sketchup.add_observer($SUFAppObserver)
  
  $SUFViewObserver = SUFViewObserver.new
  Sketchup.active_model.active_view.add_observer($SUFViewObserver)
  
  $SUFToolsObserver = SUFToolsObserver.new
  Sketchup.active_model.tools.add_observer($SUFToolsObserver)
  
  $SUFModelObserver = SUFModelObserver.new
  Sketchup.active_model.add_observer(SUFModelObserver.new)
  
  $SUFPagesObserver = SUFPagesObserver.new
  Sketchup.active_model.pages.add_observer $SUFPagesObserver
  
end
