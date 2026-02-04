module SU_Furniture
  def SU_Furniture.redraw_component
	  Sketchup.active_model.start_operation('Redraw_components', true)
    selection = Sketchup.active_model.selection.grep(Sketchup::ComponentInstance)
	  Redraw_Components.redraw_entities_with_Progress_Bar(selection)
    selection.grep(Sketchup::ComponentInstance).each { |e| Change_Attributes.size_values(e) }
    Sketchup.active_model.commit_operation
  end
end
