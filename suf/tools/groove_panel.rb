module SU_Furniture
  class GroovePanel
    def initialize()
      @text_size = (OSX ? 20 : 13)
      @text_indent = (OSX ? 15 : 9)
      @circle_text_size = (OSX ? 27 : 22)
      @x_offset = (OSX ? 10 : 0)
      @y_offset = (OSX ? 10 : 0)
      @shift_press=false
      @control_press=false
      @active_groove = nil
      @text_black_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft,
        bold: false
      }
      @text_default_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft,
        bold: false
      }
      @text_active_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft,
        bold: true
      }
      @circle_default_options = {
        color: "gray",
        font: 'Verdana',
        size: @circle_text_size,
        align: TextAlignCenter,
        bold: false
      }
      @circle_active_options = {
        color: "black",
        font: 'Verdana',
        size: @circle_text_size,
        align: TextAlignCenter,
        bold: true
      }
			@button_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignCenter
      }
      @vector = 1
    end#def
    def activate
      @model=Sketchup.active_model
      @sel=@model.selection
      @sel.remove_observer $SUFSelectionObserver
      read_param
      view = @model.active_view
      @ents = @model.entities
      @comp_and_bounds = {}
      @comp_and_essence = {}
      @essence_and_transformation = {}
      @essence_and_flipped_body = {}
      @model.entities.grep(Sketchup::ComponentInstance).each { |comp|
        search_comp_and_bounds(comp,comp.bounds)
      }
      @groove_parameters.each { |key,value| @active_groove = key if !@active_groove }
      @groove_param = @groove_parameters[@active_groove]
      @groove_pts = []
      param_arr = @groove_param.split("&")
      param_arr.each_with_index {|param,index|
        @groove_pts << Geom::Point3d.new(param.split(";")[0].to_f/25.4,param.split(";")[1].to_f/25.4,0) if param
      }
			@face = nil
			@exception_faces = []
      @face_normal = nil
      @all_intersect_points = []
			@blue = Sketchup::Color.new(0, 50, 100, 70)
      @face_points = {}
      @face_transform = {}
      @state=0
      @edit_transform=axes_edit_transform
      @ip0=Sketchup::InputPoint.new
      @ip1=Sketchup::InputPoint.new
      @ip2=Sketchup::InputPoint.new
      @ip3=Sketchup::InputPoint.new
      @ip=Sketchup::InputPoint.new
      @screen_x=0
      @screen_y=0
      self.reset(view)
    end#def
    def read_param
      @groove_parameters = Hash.new
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"groove.dat"))
				path = File.join(param_temp_path,"groove.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","groove.dat"))
        path = File.join(TEMP_PATH,"SUF","groove.dat")
        else
				path = File.join(PATH,"parameters","groove.dat")
      end
      content = File.readlines(path)
      content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
      content.each { |i| @groove_parameters[i.split("=>")[0]]=i.split("=>")[1] if i.split("=>")[1] }
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      content = File.readlines(path_param)
      @groove_material = nil
      @groove_offset = 1
      content.each { |i|
        @groove_material = i.split("=")[2] if i.split("=")[1] == "groove_material"
        @groove_offset = i.split("=")[2].to_f if i.split("=")[1] == "groove_offset"
      }
      if @groove_material == "no"
        @groove_material = nil
        else
        @groove_material = nil
        @model.materials.each{|i| @groove_material = i.display_name if i.display_name.include?("DSP")}
      end
    end#def
    def search_comp_and_bounds(comp,parent_bounds)
      if !comp.hidden?
        if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          lenx = comp.definition.get_attribute("dynamic_attributes", "lenx")
          napr_texture = comp.definition.get_attribute("dynamic_attributes", "napr_texture")
          napr_texture = comp.definition.get_attribute("dynamic_attributes", "texturemat") if !napr_texture
          if lenx && lenx.to_f > 0.3 && napr_texture
            all_comp=search_parent(comp)
            body_flipped = false
            tr = Geom::Transformation.new
            if all_comp != []
              all_comp.reverse.each_with_index { |parent_comp,index|
                parent_comp.make_unique if parent_comp.definition.count_instances > 1
                parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
                comp_tr = parent_comp.transformation
                if !body_flipped && !(comp_tr.xaxis * comp_tr.yaxis).samedirection?(comp_tr.zaxis)
                  body_flipped = true
                end
                tr *= comp_tr
              }
            end
            comp.make_unique if comp.definition.count_instances > 1
            comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
            tr *= comp.transformation
            @comp_and_bounds[comp] = parent_bounds
            @essence_and_transformation[comp] = tr
            @essence_and_flipped_body[comp] = body_flipped
          end
          else
          comp.definition.entities.grep(Sketchup::ComponentInstance).each { |body| search_comp_and_bounds(body,parent_bounds) }
        end
      end
    end#def
    def deactivate(view)
		  @face = nil
      @sel.clear
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
      end
      view.invalidate
    end#def
    def setstatus(view=nil)
      text = ""
      if @state==0
        text+=SUF_STRINGS["Select First point"]
        elsif @state==1
        text+= SUF_STRINGS["Select Next point"]
      end
      Sketchup.status_text=text
      view.invalidate if view
    end
    def draw_text(view, position, text, options)
      native_options = options.dup
      if options.key?(:size)
        native_options[:size] = pix_pt(options[:size])
      end
      view.draw_text(position, text, native_options)
    end#def
    def pix_pt(pixels)
      return ((pixels.to_f / 96.0) * 72.0).round if IS_WIN
      return pixels
    end#def
    def draw(view)
      view.drawing_color = "white"
      count = @groove_parameters.count
      if @screen_x > 0 && @screen_x < 340 && @screen_y > 0 && @screen_y < pix_pt(160)+(30+@y_offset)*count
        view.draw2d(GL_QUADS, [ Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(340, 0, 0), Geom::Point3d.new(340, pix_pt(160)+(30+@y_offset)*count, 0), Geom::Point3d.new(0, pix_pt(160)+(30+@y_offset)*count, 0) ])
      end
      view.drawing_color = "gray"
      view.line_width=2
      draw_text(view,Geom::Point3d.new(30, 25, 0), "TAB - #{SUF_STRINGS["Change groove position from line"]}", @text_default_options)
			
			view.drawing_color = "gray"
      view.line_width=2
      draw_text(view,Geom::Point3d.new(30, 50, 0), "Ctrl - #{SUF_STRINGS["Select another plane"]}", @text_default_options)
      
      y = 80+@y_offset
      @groove_point = 0
      @groove_parameters.each_pair { |key,value|
        if @active_groove == key
          draw_text(view,Geom::Point3d.new(35, y, 0), "•", @circle_active_options)
          draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_active_options)
          else
          if @screen_x > 20 && @screen_x < 100 && @screen_y > y && @screen_y < y+30+@y_offset
            @groove_point = key
            draw_text(view,Geom::Point3d.new(35, y, 0), "○", @circle_default_options)
            draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_black_options)
            else
            draw_text(view,Geom::Point3d.new(35, y, 0), "•", @circle_default_options)
            draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_default_options)
          end
        end
        y += 30+@y_offset
      }
      @delete_groove = false
			x=view.vpwidth/2
			button_width = pix_pt(160)
			x1=x-button_width/2
			x2=x+button_width/2
			y=30
      view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20+@y_offset
        @delete_groove = true
      end
			@button_text_options[:bold] = @delete_groove
			draw_text(view,Geom::Point3d.new(x, y, 0), SUF_STRINGS["Delete grooves"], @button_text_options)
      
      @accessories_groove = false
      #view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(view.vpwidth-20, 96, 0), Geom::Point3d.new(view.vpwidth-200, 96, 0), Geom::Point3d.new(view.vpwidth-200, 120, 0), Geom::Point3d.new(view.vpwidth-20, 120, 0) ])
      if @screen_x > view.vpwidth-200 && @screen_x < view.vpwidth-20 && @screen_y > 96 && @screen_y < 120
        #@accessories_groove = true
        #draw_text(view,Geom::Point3d.new(view.vpwidth-25, 100, 0), "Паз фурнитуры", @text_default_options)
        else
        #draw_text(view,Geom::Point3d.new(view.vpwidth-25, 100, 0), "Паз фурнитуры", @text_default_options)
      end
      
      @face_points = {}
      view.line_width=2
      view.drawing_color="black"
      if @ip && @ip.valid?
        if @ip.display?
          @ip.draw(view) if !@delete_groove && @groove_point == 0
          view.tooltip = @ip.tooltip
          view.drawing_color="black"
          view.draw(GL_LINES,[@ip1.position,@ip.position]) if @state==1
        end
      end
      
			if @face
			  tr = @essence_and_transformation[@face.parent.instances[-1]]
				view.drawing_color = "orange"
				@face.outer_loop.edges.each { |edge| view.draw_lines [edge.start.position.transform(tr),edge.end.position.transform(tr)]}
				mesh = @face.mesh(0)
				points = mesh.points
				triangles = []
				points.map!{|pt| pt.transform(tr)}
				mesh.polygons.each { |polygon|
					polygon.each { |index|
						triangles << points[index.abs - 1]
          }
        }
				view.drawing_color = @blue
				view.draw(GL_TRIANGLES, triangles)
      end
			
      if @face_normal
        @pts.each_pair { |face,face_pts|
          face_pts.each{|pts|
            view.set_color_from_line pts[0],pts[1]
            self.draw_geometry(face,pts[0],pts[1],view)
          }
        }
      end
      self.setstatus
    end#def
    def points_outside_face(face,points)
      points.any?{|pt|
        face.classify_point(pt.transform(@face_transform[face].inverse)) == Sketchup::Face::PointOutside
      }
    end
    def points_inside_face(face,points)
      points.any?{|pt|
        face.classify_point(pt.transform(@face_transform[face].inverse)) == Sketchup::Face::PointInside
      }
    end
    def points_on_edge(face,points)
      points.any?{|pt|
        face.classify_point(pt.transform(@face_transform[face].inverse)) == Sketchup::Face::PointOnEdge ||
        face.classify_point(pt.transform(@face_transform[face].inverse)) == Sketchup::Face::PointOnVertex
      }
    end#def
		def points_on_face(face,points)
			points.all?{|pt|
				face.classify_point(pt) == Sketchup::Face::PointInside ||
				face.classify_point(pt) == Sketchup::Face::PointOnEdge ||
				face.classify_point(pt) == Sketchup::Face::PointOnVertex
      }
    end#def
		def points_plane_not_parallel_edge(face,points)
			points_on_edge(face,points) && points_inside_face(face,points)
    end
		def intersect_points_with_edge(face,points,vec)
			intersect_points = {}
			points.each {|pt|
				intersect_pts = []
				face.edges.each{|e|
					e.faces.each{|f|
						if f != face && @face_transform[f]
							pts = Geom.intersect_line_plane([pt.transform(@face_transform[f].inverse),vec.transform(@face_transform[f].inverse)],f.plane)
							intersect_pts << pts.transform(@face_transform[f]) if pts
            end
          }
        }
				intersect_points[pt] = intersect_pts.sort_by{|point|point.distance(pt)}[0]
      }
			points = intersect_points.values
    end
		def draw_geometry(face,pt1, pt2, view)
			vec = pt2 - pt1
			if vec.length>0
				points=@groove_pts.collect {|pt| pt}
				object_origin=pt1
				@vector == 1 ? object_zaxis=vec.reverse : object_zaxis=vec # если менять, рушится экспорт в базис
				trans=Geom::Transformation.new(@face_normal*object_zaxis,@face_normal,object_zaxis,object_origin)
				points=points.collect {|pt| pt.transform(trans)}
				end_points=points.collect {|pt| pt.offset(vec)}
				
				points = intersect_points_with_edge(face,points,vec) if points_outside_face(face,points) || points_plane_not_parallel_edge(face,points)
				end_points = intersect_points_with_edge(face,end_points,vec) if points_outside_face(face,end_points) || points_plane_not_parallel_edge(face,end_points)
				
				view.line_width=1
				view.draw(GL_LINE_LOOP, points)
				view.draw(GL_LINE_LOOP, end_points)
				points.each_index {|i| view.draw(GL_LINES,[points[i],end_points[i]])}
				
				if points_inside_face(face,points) || points_on_edge(face,points)
					if @face_points[face]
						@face_points[face] << [points,end_points,[pt1,pt2]]
						else
						@face_points[face] = [[points,end_points,[pt1,pt2]]]
          end
        end
      end
    end
		def search_intersect_points(pt1,pt2)
			@all_intersect_points = []
			boundingbox = Geom::BoundingBox.new
			boundingbox.add(pt1,pt2)
			@comp_and_bounds.each_pair { |comp,bounds|
				if !comp.deleted? && comp.layer.visible?
					if bounds.intersect(boundingbox)
						search_face_and_pts(comp,pt1,pt2)
          end
        end
      }
			#p @face_normal
			boundingbox.clear
			if @all_intersect_points != []
				@all_intersect_points.each{|hash|
					hash.each_pair{|face,all_points|
						all_points.each_slice(2).to_a.each{|pts|
							points_between = []
							if pts[1]
								points_between << pts[0] if point_between?(pts[0],pts[1],pt1) && !points_between.include?(pts[0])
								points_between << pts[0] if point_between?(pts[0],pts[1],pt2) && !points_between.include?(pts[0])
								points_between << pts[1] if point_between?(pts[1],pts[0],pt1) && !points_between.include?(pts[1])
								points_between << pts[1] if point_between?(pts[1],pts[0],pt2) && !points_between.include?(pts[1])
								points_between << pt1 if point_between?(pt1,pts[0],pts[1]) && !points_between.include?(pt1)
								points_between << pt2 if point_between?(pt2,pts[0],pts[1]) && !points_between.include?(pt2)
              end
							if points_between.count > 1
								if @pts[face]
									@pts[face] << points_between.sort_by{|pt|[pt.x,pt.y,pt.z]}
									else
									@pts[face] = [points_between.sort_by{|pt|[pt.x,pt.y,pt.z]}]
                end
              end
            }
          }
        }
      end
    end
		def search_face_and_pts(comp,pt1,pt2)
			face_normal = nil
			face_arr = comp.definition.entities.grep(Sketchup::Face).find_all { |face| face if face.normal.x.abs == 1} + comp.definition.entities.grep(Sketchup::Face).find_all { |face| face if face.normal.x.abs != 1}
			face_arr.each { |face|
				if !@exception_faces.include?(face)
					@face_transform[face] = @essence_and_transformation[comp]
					face_normal = edge_on_face(face,pt1,pt2,@essence_and_transformation[comp])
					if !@face_normal
						@face = face
						@face_normal = face_normal if face_normal
          end
        end
      }
    end#def
		def edge_on_face(face,pt1,pt2,tr)
			intersect_points = {}
			intersect_points[face] = []
			edge_line = [pt1.transform(tr.inverse),(pt2-pt1).transform(tr.inverse)]
			face.edges.each {|e|
				intersect_pt = Geom.intersect_line_line(edge_line, e.line)
				if intersect_pt && face.bounds.contains?(intersect_pt) && !intersect_points[face].include?(intersect_pt.transform(tr))
					if face.classify_point(intersect_pt) == Sketchup::Face::PointOnEdge || face.classify_point(intersect_pt) == Sketchup::Face::PointOnVertex
						intersect_points[face] << intersect_pt.transform(tr)
          end
        end
      }
			if intersect_points[face].count > 1
				@all_intersect_points << intersect_points
				return face.normal.reverse.transform(tr) if face.normal.x.abs == 1
      end
			return nil
    end
		def point_between?(point, point1, point2)
			return true if point == point1 || point == point2
			point.on_line?([point1, point2]) && !point.vector_to(point1).samedirection?( point.vector_to(point2) )
    end
		def onMouseMove(flags, x, y, view)
			@screen_x = x
			@screen_y = y
			@face_normal = nil
			@pts = {}
			@face_transform = {}
			@new_entity = nil
			if @state==0
				@ip.pick view,x,y
				if @ip.valid?
					if @ip.face && @ip.face.parent.is_a?(Sketchup::ComponentDefinition)
						if @ip.face.parent.name.include?("Essence") || @ip.face.parent.get_attribute("dynamic_attributes", "_name") == "Essence"
							@new_entity = @ip.face.parent.instances[0]
							@sel.clear
            end
          end
					view.invalidate 
        end
				elsif @state==1
				@ip.pick view,x,y,@ip1
				if @ip1.position!=@ip.position
					view.invalidate if @ip.valid?
					length = @ip1.position.distance(@ip.position)
					Sketchup::set_status_text length.to_s, SB_VCB_VALUE
					search_intersect_points(@ip1.position, @ip.position)
        end
      end
			view.invalidate
    end#def
		def delete_all_groove(entity)
			if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
				entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
          ent.erase! if ent.definition.get_attribute("dynamic_attributes", "groove_param") || ent.definition.name.include?("Groove") || ent.definition.get_attribute("dynamic_attributes", "_name")=="Groove"|| ent.definition.name.include?("Notch") || ent.definition.get_attribute("dynamic_attributes", "_name")=="Notch"
        }
				dict = entity.definition.attribute_dictionary "dynamic_attributes"
				if dict
					dict.each_pair {|attr, v|
						if attr.include?("groove_param")
							entity.delete_attribute("dynamic_attributes", attr)
							entity.definition.delete_attribute("dynamic_attributes", attr)
            end
          }
        end
				edges_to_delete = []
				entity.definition.entities.grep(Sketchup::Edge).each { |e|
					if e.get_attribute("dynamic_attributes", "edge")
						if !e.visible? || e.get_attribute("dynamic_attributes", "essence")
							e.visible = true
							e.find_faces
							e.delete_attribute("dynamic_attributes", "edge")
              e.delete_attribute("dynamic_attributes", "id")
							else
							edges_to_delete << e
            end
						elsif e.get_attribute("dynamic_attributes", "koef")
						edges_to_delete << e
          end
        }
				edges_to_delete.each { |e| e.erase! }
        entity.definition.entities.grep(Sketchup::Face).each { |f| f.visible = true }
				else
				entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| delete_all_groove(ent) }
      end
    end
		def onLButtonDown(flags, x, y, view)
			if @delete_groove
				prompts = ["#{SUF_STRINGS["Delete grooves"]}: "]
				input = ["#{SUF_EXP_STR["All"]}"]
				if @sel.grep(Sketchup::ComponentInstance).length > 0
					prompts = ["#{SUF_STRINGS["Delete grooves"]}: "]
					defaults = ["#{SUF_STRINGS["From selection only"]}"]
					list = ["#{SUF_STRINGS["All"]}|#{SUF_STRINGS["From selection only"]}"]
					input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Parameters"]
        end
				if input
					@model.start_operation "Delete groove", true
					if input[0] == "#{SUF_STRINGS["From selection only"]}"
						ents = @sel.grep(Sketchup::ComponentInstance)
						else
						ents = @ents.grep(Sketchup::ComponentInstance)
          end
					ents.each { |comp| delete_all_groove(comp) }
					@model.commit_operation
        end
				elsif @groove_point != 0
				@active_groove = @groove_point
				@groove_param = @groove_parameters[@active_groove]
				@groove_pts = []
				param_arr = @groove_param.split("&")
				param_arr.each {|param|
					@groove_pts << Geom::Point3d.new(param.split(";")[0].to_f/25.4,param.split(";")[1].to_f/25.4,0) if param
        }
				view.invalidate
				elsif @state==0
				if @ip.valid?
					@ip1.copy! @ip
					@state=1
					view.lock_inference if view.inference_locked?
        end
				elsif @state==1
				if @pts != {} && @ip.valid? && (@ip1.position!=@ip.position)
					make_groove
					@face = nil
					view.lock_inference if view.inference_locked?
					view.invalidate
        end
				@state=0
      end
    end#def
		def points_on_vertex(face,points)
			points.any?{|pt|
        face.classify_point(pt) == Sketchup::Face::PointOnVertex
      }
    end#def
		def cut_offset(face,points,group,offset1,offset2)
			min_y =  points.map{|pts|pts.y}.min
			max_y =  points.map{|pts|pts.y}.max
			min_z =  points.map{|pts|pts.z}.min
			max_z =  points.map{|pts|pts.z}.max
			points = points.map{|pt|
				if face.normal.z.abs == 1
					pt.y = pt.y-offset1/25.4 if pt.y == min_y
					pt.y = pt.y+offset1/25.4 if pt.y == max_y
					pt.z = pt.z-offset2/25.4 if pt.z == min_z && pt.transform(group.transformation.inverse).z != 0
					pt.z = pt.z+offset2/25.4 if pt.z == max_z && pt.transform(group.transformation.inverse).z != 0
					elsif face.normal.y.abs == 1
					pt.y = pt.y-offset2/25.4 if pt.y == min_y && pt.transform(group.transformation.inverse).z != 0
					pt.y = pt.y+offset2/25.4 if pt.y == max_y && pt.transform(group.transformation.inverse).z != 0
					pt.z = pt.z-offset1/25.4 if pt.z == min_z
					pt.z = pt.z+offset1/25.4 if pt.z == max_z
        end
				Geom::Point3d.new(pt.x,pt.y,pt.z)
      }
			return points
    end
		def make_groove
			@model.start_operation "Groove", true
			@groove_attribute = {}
			@face_points.each_pair{|face,face_points|
				@essense = nil
				lenz = face.parent.get_attribute("dynamic_attributes", "lenz")
				leny = face.parent.get_attribute("dynamic_attributes", "leny")
				lenx = face.parent.get_attribute("dynamic_attributes", "lenx")
				@essense_with_groove = []
				face_points.each{|points|
					points1_on_edge_of_face = []
					points2_on_edge_of_face = []
					points = points.map{|pts|pts.map{|pt|pt.transform(@face_transform[face].inverse)}}
					if points.all? {|pts| pts.all? {|pt| face.parent.bounds.contains?(pt) }}
						group = face.parent.entities.add_group
						group.move! points[2][0]
						if face.normal.x.abs == 1
							group.transform! Geom::Transformation.rotation(points[2][0], Geom::Vector3d.new(0, 1, 0), -90.degrees)
							elsif face.normal.y.abs == 1
							group.transform! Geom::Transformation.rotation(points[2][0], Geom::Vector3d.new(1, 0, 0), -90.degrees)
            end
						temp_vertices = []
						
						# расширяем вырез, если паз проходит по торцу и не в конечной точке
						if face.normal.x.abs != 1 && @face_normal.normalize == face.normal.reverse.transform(@face_transform[face]).normalize
							if !points_on_vertex(face,points[0])
								points[0] = cut_offset(face,points[0],group,@groove_offset,@groove_offset*2)
              end
            end
						
						# лицо в начале группы паза
						f1 = group.entities.add_face (points[0].map{|pt|pt.transform(group.transformation.inverse)})
						
						# ищем и собираем точки на ребре лица.
						if !@essense_with_groove.include?(face.parent)
							points1_on_edge_of_face = point_on_the_edge(points[0],face)
            end
						
						# если есть точки на ребре лица (паз начинается с края панели)
						if points1_on_edge_of_face != []
							# скрываем края
							f1.edges.each{|e|e.visible = false if points1_on_edge_of_face.include?(e.start.position.transform(group.transformation)) && points1_on_edge_of_face.include?(e.end.position.transform(group.transformation))}
							# удаляем лицо
							f1.erase!
							
							if !@essense
								# вектор для смещения линии при масштабировании Essence
								koef = 1
								x_pts = points[0].select { |pt| pt if pt.x == 0}
								x_pts = points[0].select { |pt| pt if pt.x == lenx} if x_pts.count < 2
								if x_pts.count >= 2
									vec_pts = x_pts[1]-x_pts[0]
									koef = -1 if vec_pts.y.round(3) < 0 || vec_pts.z.round(3) < 0
                end
								
								# ребро лица делим и делаем отрезок невидимым
								f = face.parent.entities.add_face (points[0].map{|pt|pt})
								f.edges.each{|e|
									e.set_attribute("dynamic_attributes","edge","groove")
									e.set_attribute("dynamic_attributes","side",1)
									e.set_attribute("dynamic_attributes","length",e.length)
									e_vec = e.end.position-e.start.position
									if e_vec.normalize.x.round(2).abs == 1 || e_vec.normalize.y.round(2).abs == 1 || e_vec.normalize.z.round(2).abs == 1
										if points1_on_edge_of_face.include?(e.start.position) && points1_on_edge_of_face.include?(e.end.position)
											e.visible = false
											else
											e.set_attribute("dynamic_attributes","koef",koef)
                    end
                  end
                }
								temp_vertices << f.vertices.map{|v|v.position}
								
								# дополнительная линия для фаски
								if points[0].count == 3
									f.edges.each{|e|
										if e.start.position.x == e.end.position.x
											f.edges.each{|edge|
												if e != edge && !(e.start.position - e.end.position).perpendicular?(edge.start.position - edge.end.position)
													intersect_pt = Geom.intersect_line_line(edge.line, e.line)
													if intersect_pt.x == 0
														x = 0.1
														else
														x = intersect_pt.x - 0.1
                          end
													edges = face.parent.entities.add_edges intersect_pt,[x,intersect_pt.y,intersect_pt.z]
													edges[0].set_attribute("dynamic_attributes","edge","groove")
													edges[0].set_attribute("dynamic_attributes","side",1)
													edges[0].set_attribute("dynamic_attributes","length",edges[0].length)
													edges[0].set_attribute("dynamic_attributes","koef",koef)
													edges[0].visible = false
                        end
                      }
                    end
                  }
                end
								f.erase!
              end
            end
						
						# расширяем вырез, если паз проходит по торцу и не в конечной точке
						if face.normal.x.abs != 1 && @face_normal.normalize == face.normal.reverse.transform(@face_transform[face]).normalize
							if !points_on_vertex(face,points[1])
								points[1] = cut_offset(face,points[1],group,@groove_offset,@groove_offset*2)
              end
            end
						
						# лицо в конце группы паза
						f2 = group.entities.add_face (points[1].map{|pt|pt.transform(group.transformation.inverse)})
						
						# ищем и собираем точки на ребре лица.
						if !@essense_with_groove.include?(face.parent)
							points2_on_edge_of_face = point_on_the_edge(points[1],face)
            end
						
						# если есть точки на ребре лица (паз заканчивается на краю панели)
						if points2_on_edge_of_face != []
							# скрываем края
							f2.edges.each{|e|e.visible = false if points2_on_edge_of_face.include?(e.start.position.transform(group.transformation)) && points2_on_edge_of_face.include?(e.end.position.transform(group.transformation))}
							# удаляем лицо
							f2.erase!
							
							if !@essense
								# вектор для смещения линии при масштабировании Essence
								koef = 1
								x_pts = points[1].select { |pt| pt if pt.x == 0}
								x_pts = points[1].select { |pt| pt if pt.x == lenx} if x_pts.count < 2
								if x_pts.count >= 2
									vec_pts = x_pts[1]-x_pts[0]
									koef = -1 if vec_pts.y.round(3) < 0 || vec_pts.z.round(3) < 0
                end
								
								# ребро лица делим и делаем отрезок невидимым
								f = face.parent.entities.add_face (points[1].map{|pt|pt})
								f.edges.each{|e|
									e.set_attribute("dynamic_attributes","edge","groove")
									e.set_attribute("dynamic_attributes","side",2)
									e.set_attribute("dynamic_attributes","length",e.length)
									
									e_vec = e.end.position-e.start.position
									if e_vec.normalize.x.round(2).abs == 1 || e_vec.normalize.y.round(2).abs == 1 || e_vec.normalize.z.round(2).abs == 1
										if points2_on_edge_of_face.include?(e.start.position) && points2_on_edge_of_face.include?(e.end.position)
											e.visible = false
											else
											e.set_attribute("dynamic_attributes","koef",koef)
                    end
                  end
                }
								temp_vertices << f.vertices.map{|v|v.position}
								
								# дополнительная линия для фаски
								if points[1].count == 3
									f.edges.each{|e|
										if e.start.position.x == e.end.position.x
											f.edges.each{|edge|
												if e != edge && !(e.start.position - e.end.position).perpendicular?(edge.start.position - edge.end.position)
													intersect_pt = Geom.intersect_line_line(edge.line, e.line)
													if intersect_pt.x == 0
														x = 0.1
														else
														x = intersect_pt.x - 0.1
                          end
													edges = face.parent.entities.add_edges intersect_pt,[x,intersect_pt.y,intersect_pt.z]
													edges[0].set_attribute("dynamic_attributes","edge","groove")
													edges[0].set_attribute("dynamic_attributes","side",2)
													edges[0].set_attribute("dynamic_attributes","length",edges[0].length)
													edges[0].set_attribute("dynamic_attributes","koef",koef)
													edges[0].visible = false
                        end
                      }
                    end
                  }
                end
								f.erase!
              end
            end
						
						# линии вдоль паза
						all_edges = {}
						groove_length = 0
						points[0].each_index{|i|
							pt1 = points[0][i]
							pt2 = points[1][i]
							groove_length = (pt1.distance(pt2))*25.4 if (pt1.distance(pt2))*25.4 > groove_length
							edges = group.entities.add_edges pt1.transform(group.transformation.inverse),pt2.transform(group.transformation.inverse)
							if edges
								edges[0].find_faces if !@essense
								all_edges[edges[0]] = [pt1,pt2]
              end
            }
						
						# скрываем линию торца, если паз на краю панели
						all_edges.each_pair{|e,pts|
							if face.classify_point(Geom::Point3d.new((pts[1].x+pts[0].x)/2,(pts[1].y+pts[0].y)/2,(pts[1].z+pts[0].z)/2)) == Sketchup::Face::PointOnEdge
								edges = face.parent.entities.add_edges pts
								edges[0].set_attribute("dynamic_attributes","edge","panel")
								edges[0].visible = false
								e.faces.each{|f|f.visible = false}
								e.visible = false
              end
            }
						
						# скрываем лицо в группе
						group.entities.grep(Sketchup::Face).each{|f|
							f.erase! if f.bounds.center.z == 0
            }
						comp = group.to_component
						comp.definition.behavior.is2d = true
						comp.definition.behavior.snapto = SnapTo_Arbitrary
						comp.definition.behavior.cuts_opening = true
						comp.glued_to = face
						comp.material = @groove_material
						comp.definition.name=@active_groove.to_s
						comp.set_attribute("dynamic_attributes", "_lengthunits", "CENTIMETERS")
						att,value,label,access,formlabel,formulaunits,units,formula,options = nil
						set_att(comp,"name",@active_groove.to_s,"Name",access,formlabel,formulaunits,units,formula,options)
						set_att(comp,"_groove",true,label,access,formlabel,formulaunits,units,formula,options)
						
						@groove_points = []
						param_arr = @groove_param.split("&")
						param_arr.each {|param|
							if param
								@groove_points << [param.split(";")[0],param.split(";")[1]]
              end
            }
						
						groove_thick = @groove_points.map {|pts|pts[0].to_f}.max - @groove_points.map {|pts|pts[0].to_f}.min
						
						groove_width = @groove_points.map {|pts|pts[1].to_f}.max - @groove_points.map {|pts|pts[1].to_f}.min
						
						boundingbox = Geom::BoundingBox.new
						comp.definition.entities.each{|entity|boundingbox.add(entity.bounds)}
						
						if (boundingbox.width*25.4).round(2) == groove_thick || (boundingbox.width*25.4).round(2) == groove_width
							set_att(comp,"lenx","0","LenX",access,formlabel,"CENTIMETERS","MILLIMETERS",((boundingbox.width*2.54).round(2)).to_s,"&")
            end
						if (boundingbox.height*25.4).round(2) == groove_thick || (boundingbox.height*25.4).round(2) == groove_width
							set_att(comp,"leny","0","LenY",access,formlabel,"CENTIMETERS","MILLIMETERS",((boundingbox.height*2.54).round(2)).to_s,"&")
            end
						if (boundingbox.depth*25.4).round(2) == groove_thick || (boundingbox.depth*25.4).round(2) == groove_width
							set_att(comp,"lenz","0","LenZ",access,formlabel,"CENTIMETERS","MILLIMETERS",((boundingbox.depth*2.54).round(2)).to_s,"&")
            end
						
						vec = points[1][0]-points[0][0]
						vec.normalize!
						tr = comp.transformation
						x_formula = ((comp.transformation.origin.x*2.54).round(2)).to_s
						y_formula = ((comp.transformation.origin.y*2.54).round(2)).to_s
						z_formula = ((comp.transformation.origin.z*2.54).round(2)).to_s
						if (comp.transformation.origin.x*2.54).round(2) == 0
							x_formula = '0'
							elsif (comp.transformation.origin.x*2.54).round(2) == (lenx*2.54).round(2)
							x_formula = 'parent!lenx'
            end
						if (comp.transformation.origin.y*2.54).round(2) == 0
							y_formula = '0'
							elsif (comp.transformation.origin.y.to_f*2.54).round(2) == (leny*2.54).round(2)
							y_formula = 'parent!leny'
            end
						if (comp.transformation.origin.z*2.54).round(2) == 0
							z_formula = '0'
							elsif (comp.transformation.origin.z*2.54).round(2) == (lenz*2.54).round(2)
							z_formula = 'parent!lenz'
            end
						comp.set_attribute('dynamic_attributes', 'x', comp.transformation.origin.x.to_f)
						comp.set_attribute('dynamic_attributes', '_x_label', 'X')
						comp.set_attribute('dynamic_attributes', '_x_formula', x_formula)
						comp.definition.set_attribute('dynamic_attributes', '_inst_x', comp.transformation.origin.x.to_f)
						comp.definition.set_attribute('dynamic_attributes', '_inst__x_formula', x_formula)
						comp.set_attribute('dynamic_attributes', 'y', comp.transformation.origin.y.to_f)
						comp.set_attribute('dynamic_attributes', '_y_label', 'Y')
						comp.set_attribute('dynamic_attributes', '_y_formula', y_formula)
						comp.definition.set_attribute('dynamic_attributes', '_inst_y', comp.transformation.origin.y.to_f)
						comp.definition.set_attribute('dynamic_attributes', '_inst__y_formula', y_formula)
						comp.set_attribute('dynamic_attributes', 'z', comp.transformation.origin.z.to_f)
						comp.set_attribute('dynamic_attributes', '_z_label', 'Z')
						comp.set_attribute('dynamic_attributes', '_z_formula', z_formula)
						comp.definition.set_attribute('dynamic_attributes', '_inst_z', comp.transformation.origin.z.to_f)
						comp.definition.set_attribute('dynamic_attributes', '_inst__z_formula', z_formula)
						
						if (boundingbox.width*25.4).round(2) == (lenz*25.4).round(2) && vec.z.round(2) == 1
							set_att(comp,"lenx","0","LenX",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!lenz',"&")
            end
						if (boundingbox.width*25.4).round(2) == (leny*25.4).round(2) && vec.y.round(2) == 1
							set_att(comp,"lenx","0","LenX",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!leny',"&")
            end
						if (boundingbox.height*25.4).round(2) == (lenz*25.4).round(2) && vec.z.round(2) == 1
							set_att(comp,"leny","0","LenY",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!lenz',"&")
            end
						if (boundingbox.height*25.4).round(2) == (leny*25.4).round(2) && vec.y.round(2) == 1
							set_att(comp,"leny","0","LenY",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!leny',"&")
            end
						if (boundingbox.depth*25.4).round(2) == (lenz*25.4).round(2) && vec.z.round(2) == 1
							set_att(comp,"lenz","0","LenZ",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!lenz',"&")
            end
						if (boundingbox.depth*25.4).round(2) == (leny*25.4).round(2) && vec.y.round(2) == 1
							set_att(comp,"lenz","0","LenZ",access,formlabel,"CENTIMETERS","MILLIMETERS",'parent!leny',"&")
            end
						
						if !@essense
							if face.normal.x.abs == 1 || face.normal.x.abs != 1 && @face_normal.normalize != face.normal.reverse.transform(@face_transform[face]).normalize
								@essense = face.parent
								
								groove_xy_pos = [(points[2][0].z*25.4).round(2),(points[2][0].y*25.4).round(2),0,vec.z,vec.y,0]
								
								groove_offset = @groove_points.map {|pts|pts[0].to_f}.min
								
								groove_thick = @groove_points.map {|pts|pts[0].to_f}.max - @groove_points.map {|pts|pts[0].to_f}.min
								
								groove_width = @groove_points.map {|pts|pts[1].to_f}.max - @groove_points.map {|pts|pts[1].to_f}.min
								
								face.bounds.center.x == 0 ? groove_z_pos = "2" : groove_z_pos = "1"
								
								points_mm = points.map{|pts|pts.map{|pt|[(pt.x*25.4).round(2),(pt.y*25.4).round(2),(pt.z*25.4).round(2)]}} # для dxf
								x_vector = 1
								if vec.z.round(2) == 1
									x_vector = -1 if points[0][0].y > points[2][0].y || points[0][1].y > points[2][0].y
                end
								if vec.y.round(2) == 1
									x_vector = -1 if points[0][0].z < points[2][0].z || points[0][1].z < points[2][0].z
                end
								x_vector = -1*x_vector if @essence_and_flipped_body[face.parent.instances[-1]]
								groove_att = [groove_offset,[groove_thick,groove_width],@groove_points.map{|pts|[x_vector*pts[0].to_f,pts[1].to_f]},groove_xy_pos,groove_z_pos,(groove_length+0.001).round(1),@active_groove,points_mm]
								
								groove_index = essence_groove_index(face.parent)
                #set_att(face.parent.instances[-1],"groove_param"+groove_index.to_s,groove_att,label,access,formlabel,formulaunits,units,formula,options)
								if !@groove_attribute[@essense]
									set_att(comp,"groove_param",groove_att,label,access,formlabel,formulaunits,units,formula,options)
									@groove_attribute[@essense] = true
                end
              end
            end
						Redraw_Components.redraw_entities_with_Progress_Bar([comp])
						face.parent.entities.grep(Sketchup::Face).to_a.each{|f|
							v_position = f.vertices.map{|v|v.position}
							temp_vertices.each{|pt|
								if v_position.all?{|pos|pt.include?(pos)}
									f.erase!
                end
              }
            }
          end
        }
      }
			@model.commit_operation
    end
		def essence_groove_index(ent)
			(1..10).each{|i|
				if !ent.get_attribute("dynamic_attributes", "groove_param"+i.to_s)
					return i
        end
      }
    end
		def point_on_the_edge(points,face)
			points_on_edge_of_face = []
			points.each{|pt|
				if face.classify_point(pt) == Sketchup::Face::PointOnEdge
					points_on_edge_of_face << pt if !points_on_edge_of_face.include?(pt)
					elsif face.classify_point(pt) == Sketchup::Face::PointOnVertex
					points_on_edge_of_face << pt if !points_on_edge_of_face.include?(pt)
					points.each{|s_pt|
						if !points_on_edge_of_face.include?(s_pt)
							points_on_edge_of_face << s_pt if s_pt.x == pt.x && s_pt.y == pt.y || s_pt.x == pt.x && s_pt.z == pt.z || s_pt.y == pt.y && s_pt.z == pt.z
            end
          }
        end
      }
			return points_on_edge_of_face
    end
		def set_att(e,att,value,label,access,formlabel,formulaunits,units,formula,options)
			e.set_attribute('dynamic_attributes', att, value) if att && value
			e.definition.set_attribute('dynamic_attributes', att, value) if att && value
			label ? e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label) : e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula) if formula
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end
		def onKeyDown(key, repeat, flags, view)
			if key==CONSTRAIN_MODIFIER_KEY
				if view.inference_locked?
					view.lock_inference
					elsif (@state==0 && @ip.valid? )
					view.lock_inference @ip
					elsif (@state==1 && @ip.valid?)
					view.lock_inference @ip,@ip1
        end
				elsif key==VK_UP || key==VK_DOWN
				view.lock_inference if view.inference_locked?
				if @ip.valid? && @state>0
					p1=@ip1.position + @edit_transform.zaxis
					ip1 = Sketchup::InputPoint.new(p1)
					ip = Sketchup::InputPoint.new(@ip1.position)
					view.lock_inference ip1,ip
        end
				elsif key==VK_LEFT
				view.lock_inference if view.inference_locked?
				if @ip.valid? && @state>0
					p1=@ip1.position + @edit_transform.yaxis
					ip1 = Sketchup::InputPoint.new(p1)
					ip = Sketchup::InputPoint.new(@ip1.position)
					view.lock_inference ip1,ip
        end
				elsif key==VK_RIGHT
				view.lock_inference if view.inference_locked?
				if @ip.valid? && @state>0
					p1=@ip1.position + @edit_transform.xaxis
					ip1 = Sketchup::InputPoint.new(p1)
					ip = Sketchup::InputPoint.new(@ip1.position)
					view.lock_inference ip1,ip
        end
      end
    end
		def onKeyUp(key, repeat, flags, view)
			if key==VK_SHIFT 
				@shift_press==false ? @shift_press=true : @shift_press=false
				elsif key==VK_CONTROL || key==VK_COMMAND
				@control_press==false ? @control_press=true : @control_press=false
				@exception_faces.pop
				@exception_faces << @face
				view.invalidate
				draw(view)
				onMouseMove(flags, @screen_x, @screen_y, view)
				elsif ( key==9 || ((key==15 || key==48) && (RUBY_PLATFORM.include?('darwin'))))
				change_vector(@vector)
				view.invalidate
				draw(view)
				onMouseMove(flags, @screen_x, @screen_y, view)
				elsif key==27
				view.model.select_tool nil
				self.deactivate(view)
      end
    end#def
		def onUserText(text, view)
			if @state==1
			  @pts = {}
				if @ip.valid?
					if @ip.position!=@ip1.position
						vec=@ip.position-@ip1.position
						vec.length=self.parse_length(text)
						if vec.length>0
							p2=@ip1.position + vec
							ip = Sketchup::InputPoint.new(p2)
							@ip.copy! ip
							view.lock_inference if view.inference_locked?
							@face_points = {}
							search_intersect_points(@ip1.position,@ip.position)
							if @face_normal
								@pts.each_pair { |face,face_pts|
									face_pts.each{|pts|
										self.draw_geometry(face,pts[0],pts[1],view)
                  }
                }
								make_groove
              end
							@state=0
            end
          end
        end
      end
			self.setstatus(view)
    end
		def parse_length(input)
			(return 0) if !input
			begin
				value=input.to_s.to_l
				rescue ArgumentError
				value=input.to_s.to_f
      end
			return value
    end
		def onCancel(reason, view)
			if reason == 2
				@model.commit_operation
      end
    end#def
		def resume(view)
			view.invalidate
			draw(view)
    end#def
		def onSetCursor
			UI.set_cursor(633)
    end#def
		def reset(view=nil)
			view.lock_inference if view && view.inference_locked?
    end#def
		def onLButtonDoubleClick(flags, x, y, view)
			if @new_entity
				@model.start_operation "Delete groove", true
				delete_all_groove(@new_entity)
				@pts = {}
				@state=0
				@model.commit_operation
      end
    end#def
		def change_vector(vector)
			vector == 1 ? @vector = -1 : @vector = 1
    end
		def make_unique_if_needed(instance)
			if instance.is_a?(Sketchup::ComponentInstance) && instance.definition.count_used_instances > 1
				if !instance.parent.is_a?(Sketchup::Model)
					all_comp = search_parent(instance)
					
					if all_comp != []
						all_comp.reverse_each { |ent|
              ent.make_unique
              ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
            }
          end
        end
				instance.make_unique
        instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if instance.parent.is_a?(Sketchup::ComponentDefinition)
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
		def axes_edit_transform
			model=Sketchup.active_model
			ents=model.active_entities
			begin
				model.start_operation "Panel Tools",true,false,true
				g=ents.add_group(ents.add_group)
				t=Geom::Transformation.new(g.transformation.xaxis,g.transformation.yaxis,g.transformation.zaxis,g.transformation.origin)
				g.erase! if g && g.valid? && !g.deleted?
				model.commit_operation
				rescue
				t=model.edit_transform
      end
			return t
    end
  end#Class
end#Module
