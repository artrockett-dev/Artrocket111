
module SU_Furniture
  
  class CopyComp
    
    def comp_copy
      model = Sketchup.active_model
      selection = model.selection
      entities = model.active_entities
      if selection[1] != nil
        group = model.active_entities.add_group(selection)
        entity = group.to_component
        entity.definition.name = "Вариант#" + entity.definition.count_instances.to_s
        else
        entity = selection[0]
      end
      if !entity.nil?
        if entity.is_a?(Sketchup::ComponentInstance)
          entity_def = entity.definition
          point = Geom::Point3d.new(0,0,0)
          entity.definition.insertion_point = point
          model.place_component entity_def
          else
          UI.messagebox('This function copies a components only')
        end
      end
    end
    
    def erase_instance(entities)
      if entities[0].definition.name.include?("Вариант")
        entities[0].definition.entities.each { |ent|
          defn = ent.definition
          description = ent.definition.get_attribute("dynamic_attributes", "description", "0")
          #if description.include?(SUF_STRINGS["Product"])
          proxy = Sketchup.active_model.definitions[defn.name + "_proxy"]
          unless proxy
            proxy = Sketchup.active_model.definitions.add(defn.name + "_proxy")
            corners = []
            for i in 0..8
              corners.push Geom::Point3d.new((i & 1)!=0 ? defn.bounds.min.x : defn.bounds.max.x,
                (i & 2)!=0 ? defn.bounds.min.y : defn.bounds.max.y,
              (i & 4)!=0 ? defn.bounds.min.z : defn.bounds.max.z)
            end
            
            proxy.entities.add_face(corners[0],corners[1],corners[3],corners[2])
            proxy.entities.add_face(corners[4],corners[5],corners[7],corners[6])
            proxy.entities.add_face(corners[0],corners[1],corners[5],corners[4])
            proxy.entities.add_face(corners[3],corners[2],corners[6],corners[7])
            proxy.entities.add_face(corners[1],corners[3],corners[7],corners[5])
            proxy.entities.add_face(corners[2],corners[0],corners[4],corners[6])
          end
          ent.definition = proxy if ent.definition == defn && !ent.definition.name.include?("Стены") && (description.include?(SUF_STRINGS["Product"]) || description.include?("Изделие"))
        }
      end
    end
    
  end # class
  
end # module
