module SU_Furniture
  class IntersectComponents
    def intersect_bound(entities, entity, point_x_offset, point_y_offset, point_z_offset)
      p "intersect"
      @model = Sketchup.active_model
      @model.start_operation "intersect",true,false,true
      entity_bounds_array = []
      if !entity.parent.is_a?(Sketchup::ComponentDefinition)
      if !entity.definition.name.include?("intersect") && !entity.definition.name.include?("Группа") && !entity.definition.name.include?("Group")
        entity_name = entity.definition.name
        entity_bounds_array = search_essence_bounds(entity,entity.transformation)
        entities.grep(Sketchup::ComponentInstance).each {|ent|
          ent_bounds_array = []
          if !ent.definition.name.include?("Стен") && ent.definition.name != entity.definition.name
            ent_name = ent.definition.name
            
            ent_bounds_array = search_essence_bounds(ent,ent.transformation)
            if entity_bounds_array != [] && ent_bounds_array != []
              for entity_bounds in entity_bounds_array
                if entity_bounds && entity_bounds.valid?
                  for ent_bounds in ent_bounds_array
                    if ent_bounds && ent_bounds.valid?
                      #entities.add_line entity_bounds.corner(0),entity_bounds.corner(7)
                      if not(entity_bounds.intersect(ent_bounds).empty?)
                        result = entity_bounds.intersect(ent_bounds)
                        if result.width.round(3) != 0 && result.height.round(3) != 0 && result.depth.round(3) != 0
                          group=entities.add_group
                          face1 = group.entities.add_face(result.corner(0),result.corner(1),result.corner(5),result.corner(4))
                          face1.reverse!
                          mat_names = [] 
                          @model.materials.each{|i| mat_names << i.display_name} 
                          if mat_names.include?("intersect_material")
                            intersect_material = "intersect_material"
                            else
                            intersect_material = @model.materials.add("intersect_material")
                            intersect_material.color = Sketchup::Color.new(250, 0, 0)
                            intersect_material.alpha = 0.5
                          end
                          face1.material = intersect_material
                          face1.back_material = intersect_material
                          face1.pushpull(result.height)
                          group.entities.grep(Sketchup::Edge).each { |e| e.hidden = true }
                          group.name="intersect_#{entity_name}_#{ent_name}"
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        }
      end
    end
      @model.commit_operation
    end#def
    def search_essence_bounds(e,transformation)
      @essence_bounds = []
      e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| search_essence(ent,transformation) } if !e.hidden?
      return @essence_bounds
    end#def
    def search_essence(ent,transformation)
      if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        essence_bounds = Geom::BoundingBox.new
        for i in 0..7
          essence_bounds.add(transform_vertex(ent.bounds.corner(i), transformation))
        end
        @essence_bounds << essence_bounds
        elsif !ent.hidden?
        ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_essence(e,transformation * ent.transformation) }
      end
    end#def
    def transform_vertex(vertex, tform)
      point = Geom::Point3d.new(vertex.x, vertex.y, vertex.z)
      point.transform! tform
      point
    end
  end #end Class 
end
