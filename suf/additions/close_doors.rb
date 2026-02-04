
module SU_Furniture
  class CloseDoors
    def close_doors(model)
      model.start_operation('Close doors', true)
      model.selection.grep(Sketchup::ComponentInstance).each { |ent| close(ent) }
      model.commit_operation
      end
    def close(e)
      description = e.definition.get_attribute("dynamic_attributes", "description", 0)
      open_hf = e.definition.get_attribute("dynamic_attributes", "open_hf")
      name_frontal = e.definition.get_attribute("dynamic_attributes", "_name", "0")
      animation = e.definition.get_attribute("dynamic_attributes", "animation")
      a_open = e.definition.get_attribute("dynamic_attributes", "a_open")
      if name_frontal.include?("Фасад") || name_frontal.include?("Frontal") || name_frontal.include?("Hinge") || name_frontal.include?("LIFT") || name_frontal.include?("Aventos") || name_frontal.include?("Drawer") || description.to_s.include?(SUF_STRINGS["Product"]) || description.to_s.include?("Изделие") || description.to_s.include?("frontal") || description.to_s.include?("Body") || description.to_s.include?("body")
        if open_hf != nil && open_hf.to_s != "1"
          e.set_attribute("dynamic_attributes", "open_hf", 1)
          e.definition.set_attribute("dynamic_attributes", "open_hf", 1)
          Redraw_Components.redraw_entities_with_Progress_Bar([e])
        end
        if animation != nil && animation.to_s != "0"
          e.set_attribute("dynamic_attributes", "animation", 0)
          e.definition.set_attribute("dynamic_attributes", "animation", 0)
          Redraw_Components.redraw_entities_with_Progress_Bar([e])
        end
        if a_open != nil && a_open.to_s != "1"
          e.set_attribute("dynamic_attributes", "a_open", 1)
          e.definition.set_attribute("dynamic_attributes", "a_open", 1)
          Redraw_Components.redraw_entities_with_Progress_Bar([e])
        end
        e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| close(ent) }
      end
    end
  end # class
end # module
