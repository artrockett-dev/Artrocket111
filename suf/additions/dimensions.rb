module SU_Furniture
  class Dimension
    def place_component_with_dimension(entities,entity,element,auto_dimension)
      entities.grep(Sketchup::ComponentInstance).each { |ent| @wall_ent = ent if ent.definition.name.include?("Стены") || ent.definition.name.include?("стены") }
			item_code = entity.definition.get_attribute("dynamic_attributes", "itemcode")
      if entity && @wall_ent && !@wall_ent.deleted? && item_code
        camera = Sketchup.active_model.active_view.camera
        name = entity.definition.get_attribute("dynamic_attributes", "name", "0")
        if item_code[0] == "N" || name[0..2] == "Низ" || item_code[0] == "P" || name[0..4] == "Пенал" || item_code[0] == "V" || name[0..3] == "Верх"
				  Sketchup.active_model.start_operation("dimensions",true,false,true)
          dimension_to_wall(entities,entity,item_code[0],name,auto_dimension)
					Sketchup.active_model.commit_operation
				end
        if camera.up.to_a[1] == 1 && element == "added" || camera.up.to_a[1] == 1 && element == "modified"
          z_array = []
          entities.grep(Sketchup::ComponentInstance).each { |ent|
            item_code_ent = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
            name_ent = ent.definition.get_attribute("dynamic_attributes", "name", "0")
            z_array << ent.bounds.corner(6)[2] if item_code_ent[0] == "N" || name_ent[0..2] == "Низ"
					}
					new_z = nil
          if item_code[0] == "N" || item_code[0] == "P" || name[0..2] == "Низ" || name[0..4] == "Пенал"
            z = entity.bounds.corner(0)[2]
						new_z = -z if z != 0
            elsif item_code[0] == "C" || name[0..5] == "Цоколь"
            z = entity.bounds.corner(0)[2]
						new_z = -z if z != 0
            elsif item_code[0] == "S" || name[0..9] == "Столешница"
            z_new = z_array[0]
            z = entity.bounds.corner(0)[2]
						new_z = -z+z_new if z != z_new
            elsif item_code[0] == "F" || item_code[0] == "L" || name[0..5] == "Фартук" || name[0..3] == "Угол" || name[0..6] == "Плинтус"
            z_new = z_array[0]+3.8/2.54
            z = entity.bounds.corner(0)[2]
						new_z = -z+z_new if z != z_new
            elsif item_code[0] == "V" || name[0..3] == "Верх" && item_code[0] != "A"
            z_new = (82+4+60)/2.54
            z = entity.bounds.corner(0)[2]
						new_z = -z+z_new if z != z_new
					end
					if new_z
						Sketchup.active_model.start_operation("dimensions",true,false,true)
						entity.transform! Geom::Transformation.new([0, 0, new_z]) 
						Sketchup.active_model.commit_operation
					end
				end
			end
		end#def
    def dimension_to_wall(entities,entity,ent_item_code,ent_name,auto_dimension)
      entities.each { |ent| ent.erase! if ent.layer.name == "Z_Top_dimension" }
      if auto_dimension == "yes"
        max_x = 0
        max_y = 0
			min_x = 0
			min_y = 0
			entities.grep(Sketchup::ComponentInstance).each { |ent|
				if !ent.definition.name.include?("Стены")
					item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
					name = ent.definition.get_attribute("dynamic_attributes", "name", "0")
					if item_code[0] == ent_item_code || name[0..2] == ent_name[0..2] || item_code[0] == ent_item_code || name[0..4] == ent_name[0..4] || item_code[0] == ent_item_code || name[0..3] == ent_name[0..3]
						for i in 0..7 
							bounds = ent.bounds
							max_x = bounds.corner(i)[0] if max_x < bounds.corner(i)[0]
							max_y = bounds.corner(i)[1] if max_y < bounds.corner(i)[1]
							min_x = bounds.corner(i)[0] if min_x > bounds.corner(i)[0]
							min_y = bounds.corner(i)[1] if min_y > bounds.corner(i)[1]
						end
					end
				end
			}
			bounds = @wall_ent.bounds
			wall_min_x = bounds.min.x.to_f
			wall_max_x = bounds.max.x.to_f
			wall_min_y = bounds.min.y.to_f
			wall_max_y = bounds.max.y.to_f
			dim_layer = Sketchup.active_model.layers.add "Z_Top_dimension"
			dim = entities.add_dimension_linear([wall_min_x, wall_max_y, 0], [max_x, wall_max_y, 0], [0, 1, 0])
			dim.layer = dim_layer
			dim = entities.add_dimension_linear([max_x, wall_max_y, 0], [wall_max_x, wall_max_y, 0], [0, 1, 0]) if max_x != wall_max_x
			dim.material = "red" if max_x > wall_max_x
			dim.layer = dim_layer
			dim = entities.add_dimension_linear([wall_min_x, wall_max_y, 0], [wall_min_x, min_y, 0], [-1, 0, 0])
			dim.layer = dim_layer
			dim = entities.add_dimension_linear([wall_min_x, min_y, 0], [wall_min_x, wall_min_y, 0], [-1, 0, 0]) if min_y != wall_min_y
			dim.material = "red" if min_y < wall_min_y
			dim.layer = dim_layer
      end
		end#def
    def update_dimensions(model)
      model.layers.add("7_Размеры")
      model.start_operation("Update dimensions",true)
      model.selection.grep(Sketchup::ComponentInstance).to_a.each { |entity| new_dimensions(entity) }
      model.commit_operation
		end#def
    def new_dimensions(entity)
      if entity.is_a?(Sketchup::Dimension) && !entity.hidden?
        parent = entity.parent
        vec = entity.offset_vector
        text = entity.text
        
        dim_end = nil
        arr_end = entity.end
        if arr_end[0] == nil
          arr_end = arr_end[1]
          dim_end = arr_end
				end
        
        dim_start = nil
        arr_start = entity.start
        if arr_start[0] == nil
          arr_start = arr_start[1]
          dim_start = arr_start
				end
        
        entity.erase!
        dim = parent.entities.add_dimension_linear(arr_start, arr_end, vec)
        dim.layer = "7_Размеры"
        if dim_end && dim_start
          distance = dim_end.distance(dim_start)
          if distance*25.4 != text.to_f
            dim.text = text
					end
				end
        elsif entity.is_a?(Sketchup::ComponentInstance) && !entity.definition.name.include?("handle")
        entity.definition.entities.to_a.each { |e| new_dimensions(e) }
			end
		end#def
	end
end
