module SU_Furniture
  def SU_Furniture.add_remove_observers(state)
    @model = Sketchup.active_model
    if state == 1
      remove_observers(@model)
      @observers_state = 2
      else
      add_observers(@model)
      @observers_state = 1
    end
  end#def
  def SU_Furniture.add_observers(model)
    model.selection.add_observer $SUFSelectionObserver
    model.entities.add_observer $SUFEntitiesObserver
    model.layers.add_observer $SUFLayersObserver
    model.pages.add_observer $SUFPagesObserver
    model.tools.add_observer $SUFToolsObserver
  end#def
  def SU_Furniture.remove_observers(model)
    model.selection.remove_observer $SUFSelectionObserver
    model.entities.remove_observer $SUFEntitiesObserver
    model.layers.remove_observer $SUFLayersObserver
    model.pages.remove_observer $SUFPagesObserver
    model.tools.remove_observer $SUFToolsObserver
  end
  def SU_Furniture.observers_state
    @observers_state
  end
  def SU_Furniture.add_new_observers(model)
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
  end
end
