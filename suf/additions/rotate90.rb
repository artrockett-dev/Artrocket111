
module SU_Furniture
  def SU_Furniture.selected_comps_and_groups
    sel = $SUFSelectionObserver.selected
    return nil if sel.empty?
    sel.each { |cc| 
      return nil if not ((cc.instance_of? Sketchup::ComponentInstance) or (cc.instance_of? Sketchup::Group))
    }
    sel
  end
  def SU_Furniture.rotate90(sel, axis)
    rv = case axis
      when "z" then Geom::Vector3d.new(0, 0, 1)
      when "y" then Geom::Vector3d.new(0, 1, 0)
      when "x" then Geom::Vector3d.new(1, 0, 0)
      else return
    end
    ra = 90.degrees
    rp = Geom::Point3d.new(sel.first.transformation.origin)
		if !$SUF_Place_Component
      Sketchup.active_model.start_operation 'Rotate 90', true
    end
    sel.each { |ent|
			behavior = ent.definition.behavior
			if $SUF_Place_Component && behavior.is2d? && behavior.snapto == SnapTo_Arbitrary
				else
				ent.transform!(Geom::Transformation.rotation(rp, rv, ra))
				if ent.is_a?(Sketchup::ComponentInstance)
					%w[rotx roty rotz].each do |axis|
            ent.delete_attribute("dynamic_attributes", "_#{axis}_formula")
            ent.definition.delete_attribute("dynamic_attributes", "_inst__#{axis}_formula")
          end
        end
      end
    }
		if $SUF_Place_Component
			SU_Furniture::Place_Component.set_transformation(Sketchup.active_model.active_view)
    end
		if !$SUF_Place_Component
      Sketchup.active_model.commit_operation
    end
    if $SUFToolsObserver.last_tool_name == 'ScaleTool'
      Sketchup.active_model.select_tool(nil)
      Sketchup.send_action "selectScaleTool:"
    end
  end
end # module
if( not file_loaded?("rotate90") )
  UI.add_context_menu_handler do |menu|
		if menu == nil
			UI.messagebox("Error setting context menu handler")
      else
			if (sel = SU_Furniture.selected_comps_and_groups)
				sbm = menu.add_submenu("Rotate 90")
				sbm.add_item("Around Red") {SU_Furniture.rotate90(sel, "x")}
				sbm.add_item("Around Green") {SU_Furniture.rotate90(sel, "y")}
				sbm.add_item("Around Blue") {SU_Furniture.rotate90(sel, "z")}
      end
    end 
  end
end

file_loaded("rotate90")
