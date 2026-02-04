module SU_Furniture
  def SU_Furniture.delete_lines()
    model = Sketchup.active_model
    model.start_operation "Delete guides", true
    model.entities.each{|ent| SU_Furniture.search_lines(ent) }
    model.commit_operation
  end#def
  def SU_Furniture.search_lines(entity)
    if entity.is_a?(Sketchup::ConstructionLine) || entity.is_a?(Sketchup::ConstructionPoint)
      entity.erase!
      elsif entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group) && !entity.name.include?("shell")
      entity.definition.entities.each{|ent| SU_Furniture.search_lines(ent) } if !entity.layer.name.include?("Фасад")
    end
  end#def
end
