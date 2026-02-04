
module SU_Furniture
  class PanelDrawing
    def activate
      if Sketchup.version_number >= 2000000000
        @flags = PAGE_USE_HIDDEN_GEOMETRY | PAGE_USE_HIDDEN_OBJECTS
        else
        @flags = PAGE_USE_HIDDEN
      end
      @comp_and_essence = {}
      @panel_with_drawing = {}
      @model=Sketchup.active_model
      @view = @model.active_view
      @sel=@model.selection
      if @model.pages.count == 0
        Kitchen_Scenes.scenes(['Общий_вид'],@view.camera.direction,false,false)
        @model.pages.selected_page = @model.pages[0]
      end
      @model.start_operation('Panel drawing', true)
      y = 0
      @model.entities.remove_observer $SUFEntitiesObserver
      @model.layers.remove_observer $SUFLayersObserver
      @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'P_' }
      @model.entities.grep(Sketchup::ComponentInstance).each { |comp| comp.erase! if comp.definition.name.include?("drawing") }
      @sel.grep(Sketchup::ComponentInstance).each { |comp| search_comp_with_essence(comp) }
      @sel.clear
      @comp_and_essence.each_pair { |comp,essence|
        a03_name = comp.definition.get_attribute("dynamic_attributes", "a03_name", "Panel")
        lenx = comp.get_attribute("dynamic_attributes", "lenx")
        lenx = comp.definition.get_attribute("dynamic_attributes", "lenx") if !lenx
        leny = comp.get_attribute("dynamic_attributes", "leny")
        leny = comp.definition.get_attribute("dynamic_attributes", "leny") if !leny
        lenz = comp.get_attribute("dynamic_attributes", "lenz")
        lenz = comp.definition.get_attribute("dynamic_attributes", "lenz") if !lenz
				if comp.definition.get_attribute("dynamic_attributes", "a05_napr")
					napr_texture_att = "a05_napr"
					else
					napr_texture_att = "napr_texture"
        end
				napr_texture = comp.definition.get_attribute("dynamic_attributes", napr_texture_att)
        v0_cut = comp.definition.get_attribute("dynamic_attributes", "v0_cut", "2")
        v1_cut_type = comp.definition.get_attribute("dynamic_attributes", "v1_cut_type", "1")
        v2_cut_type = comp.definition.get_attribute("dynamic_attributes", "v2_cut_type", "1")
        v3_cut_type = comp.definition.get_attribute("dynamic_attributes", "v3_cut_type", "1")
        v4_cut_type = comp.definition.get_attribute("dynamic_attributes", "v4_cut_type", "1")
        uniq_name = a03_name+(lenx.to_f*25.4).round.to_s+(leny.to_f*25.4).round.to_s+(lenz.to_f*25.4).round.to_s+napr_texture.to_s+v0_cut.to_s+v1_cut_type.to_s+v2_cut_type.to_s+v3_cut_type.to_s+v4_cut_type.to_s
        if a03_name.include?("Вырез") || a03_name.include?("вырез") || a03_name.include?("Скос") || a03_name.include?("Угол") || v1_cut_type != "1" && v0_cut != "2" || v2_cut_type != "1" && v0_cut != "2" || v3_cut_type != "1" && v0_cut != "2" || v4_cut_type != "1" && v0_cut != "2"
          if @panel_with_drawing[uniq_name]
            @model.pages.to_a.each { |this_page| this_page.name = 'P_'+a03_name if this_page.name.to_s.include?('P_'+a03_name) }
            @panel_with_drawing[uniq_name] += 1
            @model.pages.to_a.each { |this_page| this_page.name += ' '+@panel_with_drawing[uniq_name].to_s+' шт' if this_page.name.to_s.include?('P_'+a03_name) }
            else
            @panel_with_drawing[uniq_name] = 1
            this_page = @model.pages.add 'P_'+a03_name
            inst = @model.entities.add_instance(essence.definition,Geom::Transformation.translation(Geom::Point3d.new(0, y, 0)))
            inst.make_unique
            inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
            inst.definition.name = "drawing"
            face = face_of_essence(inst)
            if face
              dimensions(inst,face,napr_texture)
              @model.pages.each { |page|
                if page != this_page
                  @model.pages.selected_page = page
                  inst.hidden = true
                  page.update(@flags)
                end
              }
              inst.hidden = false
              @model.entities.each { |comp| comp.hidden = true if comp != inst }
              new_camera = Sketchup::Camera.new
              new_camera.perspective = false
              new_camera.set [1, 0, 0], [0, 0, 0], [0, 0, 1]
              @view.camera = new_camera
              view = @view.zoom inst
              this_page.delay_time = 0.1
              this_page.transition_time=0.1
              status = this_page.update(PAGE_USE_ALL)
              inst.attribute_dictionaries.delete("dynamic_attributes") if inst.attribute_dictionaries && inst.attribute_dictionaries["dynamic_attributes"]
              inst.definition.attribute_dictionaries.delete("dynamic_attributes") if inst.definition.attribute_dictionaries && inst.definition.attribute_dictionaries["dynamic_attributes"]
              
              #y-=(inst.bounds.height+10)
              #inst.explode
            end
          end
        end
      }
      p @panel_with_drawing
      @model.pages.selected_page=@model.pages[0]
      if SU_Furniture.observers_state == 1
        @model.entities.add_observer $SUFEntitiesObserver
      end
      @model.layers.add_observer $SUFLayersObserver
      @model.commit_operation
    end#def
    def dimensions(inst,face,napr_texture)
      face_edges = face.edges
      frontal_edge = nil
      face_edges.each{|edge|
        if edge.start.position.y==0 && edge.end.position.y==0
          frontal_edge=edge
        end
      }
      all_edges = []
      height = inst.bounds.height #Y
      depth = inst.bounds.depth   #Z
      up_handle = 0
      inst.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
        if !ent.hidden? && ent.definition.name.include?("Virez_VLU")
          up_handle = ent.definition.get_attribute("dynamic_attributes", "leny")
        end
      }
      inst.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
        if !ent.hidden?
          lenx = ent.get_attribute("dynamic_attributes", "lenx")
          lenx = ent.definition.get_attribute("dynamic_attributes", "lenx") if !lenx
          leny = ent.get_attribute("dynamic_attributes", "leny")
          leny = ent.definition.get_attribute("dynamic_attributes", "leny") if !leny
          if lenx && leny
            
            if ent.definition.name.include?("Skos_U") #скос 45
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,0,ent.transformation.origin.z-lenx),Geom::Point3d.new(0,leny,ent.transformation.origin.z))
              
              elsif ent.definition.name.include?("Ugol_U") #внутренний угол
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,0,ent.transformation.origin.z-lenx),Geom::Point3d.new(0,lenx,ent.transformation.origin.z-lenx))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,leny,ent.transformation.origin.z-lenx),Geom::Point3d.new(0,leny,ent.transformation.origin.z))
              
              elsif ent.definition.name.include?("Virez_VLU") #верхняя скрытая ручка
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,0,ent.transformation.origin.z),Geom::Point3d.new(0,lenx,ent.transformation.origin.z))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,lenx,ent.transformation.origin.z),Geom::Point3d.new(0,lenx,depth))
              
              elsif ent.definition.name.include?("Virez_VLM") #средняя скрытая ручка
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,0,ent.transformation.origin.z), Geom::Point3d.new(0,lenx,ent.transformation.origin.z))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,lenx,ent.transformation.origin.z),Geom::Point3d.new(0,lenx,ent.transformation.origin.z+leny))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,lenx,ent.transformation.origin.z+leny),Geom::Point3d.new(0,0,ent.transformation.origin.z+leny))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,0,ent.transformation.origin.z+leny),Geom::Point3d.new(0,0,depth-up_handle))
              
              elsif ent.definition.name.include?("Virez_U") #вырез вытяжки
              lenx = lenx/2
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,height,0),Geom::Point3d.new(0,height,ent.transformation.origin.z-lenx))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,height,ent.transformation.origin.z-lenx),Geom::Point3d.new(0,height-leny,ent.transformation.origin.z-lenx))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,height-leny,ent.transformation.origin.z-lenx), Geom::Point3d.new(0,height-leny,ent.transformation.origin.z+lenx))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,height-leny,ent.transformation.origin.z+lenx), Geom::Point3d.new(0,height,ent.transformation.origin.z+lenx))
              all_edges << inst.definition.entities.add_line(Geom::Point3d.new(0,height,ent.transformation.origin.z+lenx), Geom::Point3d.new(0,height,depth))
              frontal_edge.faces.each {|f| face = f if f.normal.parallel?(Geom::Vector3d.new(1,0,0)) }
            end
          end
        end
      }
      all_edges += face.edges
      inst.definition.entities.to_a.each { |entity|
        if entity != face && !all_edges.include?(entity)
          entity.erase! if !entity.deleted?
        end
      }
      all_edges[0].find_faces
      curves = []
      height_dim = inst.definition.entities.add_dimension_linear([0,0,0],[0,height,0],[0,0,-2])
      depth_dim = inst.definition.entities.add_dimension_linear([0,height,0],[0,height,depth],[0,2,0])
      inst.definition.entities.grep(Sketchup::Edge).each { |edge|
        if edge.curve && !curves.include?(edge.curve)
          curves << edge.curve
          if edge.start.position.y < height/2 || edge.end.position.y < height/2
            max_edge_y = [edge.curve.last_edge.bounds.max.y,edge.curve.first_edge.bounds.max.y].max
            if edge.start.position.z < depth/2 || edge.end.position.z < depth/2
              max_edge_z = [edge.curve.last_edge.bounds.max.z,edge.curve.first_edge.bounds.max.z].max
              point = [0, max_edge_y/2, max_edge_z/2]
              else
              min_edge_z = [edge.curve.last_edge.bounds.min.z,edge.curve.first_edge.bounds.min.z].min
              point = [0, max_edge_y/2, depth-(depth-min_edge_z)/2]
            end
            else
            min_edge_y = [edge.curve.last_edge.bounds.min.y,edge.curve.first_edge.bounds.min.y].min
            if edge.start.position.z < depth/2 || edge.end.position.z < depth/2
              max_edge_z = [edge.curve.last_edge.bounds.max.z,edge.curve.first_edge.bounds.max.z].max
              point = [0, height-(height-min_edge_y)/2, max_edge_z/2]
              else
              min_edge_z = [edge.curve.last_edge.bounds.min.z,edge.curve.first_edge.bounds.min.z].min
              point = [0, height-(height-min_edge_y)/2, depth-(depth-min_edge_z)/2]
            end
          end
          dim = inst.definition.entities.add_dimension_radial edge.curve, point
          
          elsif !edge.curve
          vector = []
          if edge.start.position.y == edge.end.position.y #вертикальные
            if (depth*25.4).round(1) != (edge.start.position.distance(edge.end.position)*25.4).round(1)
              if edge.start.position.y < height/2
                vector = [0,-1,0] #слева
                else
                vector = [0,1,0] #справа
              end
            end
            elsif edge.start.position.z == edge.end.position.z #горизонтальные
            if (height*25.4).round(1) != (edge.start.position.distance(edge.end.position)*25.4).round(1)
              if edge.start.position.z < depth/2
                vector = [0,0,-1] #снизу
                else
                vector = [0,0,1] #сверху
              end
            end
            else #скос
            face = edge.faces[0]
            ang = -90.degrees
            ang = -ang if edge.reversed_in?(face)
            vector = edge.start.position.vector_to edge.end.position
            vector.normalize!
            vector_trans = Geom::Transformation.rotation(edge.bounds.center, face.normal, ang)
            vector.transform!(vector_trans)
          end
          dim = inst.definition.entities.add_dimension_linear(edge.start.position,edge.end.position,vector) if vector != []
        end
      }
      if napr_texture == "1"
        inst.definition.entities.add_line Geom::Point3d.new(0,height/3,depth/4), Geom::Point3d.new(0,height/3,depth/4*3)
        inst.definition.entities.add_line Geom::Point3d.new(0,height/3*2,depth/4), Geom::Point3d.new(0,height/3*2,depth/4*3)
        else
        inst.definition.entities.add_line Geom::Point3d.new(0,height/3,depth/4), Geom::Point3d.new(0,height/3*2,depth/4)
        inst.definition.entities.add_line Geom::Point3d.new(0,height/3,depth/4*3), Geom::Point3d.new(0,height/3*2,depth/4*3)
      end
    end
    def search_comp_with_essence(comp)
      if !comp.hidden?
        if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          lenx = comp.definition.get_attribute("dynamic_attributes", "lenx")
          napr_texture = comp.definition.get_attribute("dynamic_attributes", "napr_texture")
          napr_texture = comp.definition.get_attribute("dynamic_attributes", "texturemat") if !napr_texture
          if comp.parent.is_a?(Sketchup::ComponentDefinition) && lenx && lenx.to_f > 0.4 && napr_texture
            all_comp=search_parent(comp)
            
            if all_comp != []
              all_comp.reverse.each { |parent_comp|
                parent_comp.make_unique if parent_comp.definition.count_instances > 1
                parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
              }
            end
            if comp.definition.count_instances > 1
              comp.make_unique
              comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
            end
            if comp.parent.instances[0].definition.name.include?("Body")
              inst = comp.parent.instances[0].parent.instances[0]
              @comp_and_essence[inst] = comp
              else
              inst = comp.parent.instances[0]
              @comp_and_essence[inst] = comp
            end
          end
          else
          comp.definition.entities.grep(Sketchup::ComponentInstance).each { |body| search_comp_with_essence(body) }
        end
      end
    end#def
    def search_parent(entity,all_comp=[])
			if entity.parent.is_a?(Sketchup::ComponentDefinition)
				if entity.parent.instances[-1]
					all_comp << entity.parent.instances[-1]
					search_parent(entity.parent.instances[-1],all_comp)
        end
      end
      return all_comp
    end#def
    def face_of_essence(essence)
      face = nil
      essence.definition.entities.grep(Sketchup::Face).each { |entity|
        if entity.bounds.center.x==0 && entity.normal.parallel?(Geom::Vector3d.new(1,0,0))
          entity.edges.each { |edge| edge.hidden = false }
          return entity
        end
      }
      return face
    end#def
  end #end Class 
end
