module SU_Furniture
  class HideWalls
    def hide_walls(camera)
      @model = Sketchup.active_model
      @wall_ent = nil
      @model.entities.grep(Sketchup::ComponentInstance).each { |ent| @wall_ent = ent if ent.definition.name.include?("Стены") || ent.definition.name.include?("стены") }
      if @wall_ent && !@wall_ent.deleted?
        @model.start_operation "Hide walls", true,false,true
        tr = Geom::Transformation.new
        tr*=@wall_ent.transformation
        @wall_ent.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
          ent.definition.entities.grep(Sketchup::Face).each { |f|
            if f.normal.transform(tr*ent.transformation).x == 1 && camera.eye.x < f.bounds.center.transform(tr*ent.transformation).x
              f.hidden = true
              elsif f.normal.transform(tr*ent.transformation).x == -1 && camera.eye.x > f.bounds.center.transform(tr*ent.transformation).x
              f.hidden = true
              elsif f.normal.transform(tr*ent.transformation).y == -1 && camera.eye.y > f.bounds.center.transform(tr*ent.transformation).y
              f.hidden = true
              elsif f.normal.transform(tr*ent.transformation).y == 1 && camera.eye.y < f.bounds.center.transform(tr*ent.transformation).y
              f.hidden = true
              else
              f.hidden = false
            end
          }
        }
        @model.commit_operation
      end
    end#def
  end #end Class 
end