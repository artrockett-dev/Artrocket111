module SU_Furniture
  class PlaceComponent
    def initialize
      @shift_press = false
      @control_press = false
      @line_black_text_options = {
        color: Sketchup::Color.new(0, 0, 0),
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @orange = Sketchup::Color.new(210, 130, 0, 150)
      @input = false
      @defaults_other = [SUF_STRINGS["Left"],SUF_STRINGS["Bottom"],SUF_STRINGS["Front"]]
			@drawer_width_param = false
    end#def
    def import_comp_path(comp_path=nil)
      @model = Sketchup.active_model
      if @input
        @model.abort_operation
      end
      @model.start_operation('SUF place component', true)
      p comp_path
      @comp_path = comp_path
      @input = true
    end
    def activate
      @model = Sketchup.active_model
      @sel = @model.selection
      @sel.remove_observer $SUFSelectionObserver
      @model.layers.remove_observer $SUFLayersObserver
      @model.entities.remove_observer $SUFEntitiesObserver
      @model.tools.remove_observer($SUFToolsObserver)
      read_param
      @placed = false
      @canceled = false
      @ip=Sketchup::InputPoint.new
      @shift_press = false
      @control_press = false
			@place_with_control = false
			@points = []
			@model.layers.add("Z_Face")
			#@model.start_operation('layer', true,false,true)
			@visible_layer = {}
      @old_layers = []
			@model.layers.each { |l|
				@visible_layer[l] = l.visible?
        @old_layers << l
				l.visible = true if l.name.include?("Габаритная_рамка") || l.name.include?("Направляющие") || l.name.include?("Z_Face") || l.name.include?("Z_Edge")
				l.visible = false if l.name.include?("Фасад_открывание") || l.name.include?("Толщина_кромки")
      }
			clean_modules()
			#@model.commit_operation
			Sketchup.focus if Sketchup.version_number >= 2110000000
			#@model.start_operation('load', true,false,true)
			skp_name = File.basename(@comp_path, ".*")
      if Sketchup.version_number >= 2110000000
        @comp = @model.definitions.load(@comp_path, allow_newer: true)
        else
        @comp = @model.definitions.load(@comp_path)
      end
			@comp.instances.each { |instance| instance.make_unique if !instance.deleted? }
			@inst = @model.active_entities.add_instance(@comp,IDENTITY)
			@inst.make_unique if @inst.definition.count_used_instances > 1
			hide_objects_in_pages(@inst) if @model.pages.count > 0
			@inst.hidden = true
			@inst.move!(Geom::Transformation.translation(Geom::Point3d.new(0, 0, 1000)))
			@inst.hidden = false
			@model.entities.grep(Sketchup::Group).each { |ent| ent.erase! if ent.name.include?("intersect") }
			#@model.commit_operation
			@point_x_offset = @inst.definition.get_attribute("dynamic_attributes", "point_x_offset") #Vertical
			@point_y_offset = @inst.definition.get_attribute("dynamic_attributes", "point_y_offset") #Frontal
			@point_z_offset = @inst.definition.get_attribute("dynamic_attributes", "point_z_offset") #Gorizontal
      @b1_f_thickness = @inst.definition.get_attribute("dynamic_attributes", "b1_f_thickness")
      @b1_p_thickness = @inst.definition.get_attribute("dynamic_attributes", "b1_p_thickness")
      @b1_b_thickness = @inst.definition.get_attribute("dynamic_attributes", "b1_b_thickness")
			@su_type = @inst.definition.get_attribute("dynamic_attributes", "su_type")
			@a03_type = @inst.definition.get_attribute("dynamic_attributes", "a03_type")
			@trim_x1 = @inst.definition.get_attribute("dynamic_attributes", "trim_x1") #Изделие
			@trim_x2 = @inst.definition.get_attribute("dynamic_attributes", "trim_x2") #Изделие
			@a0_door_count = @inst.definition.get_attribute("dynamic_attributes", "a0_door_count")
			@a0_shelves_count = @inst.definition.get_attribute("dynamic_attributes", "a0_shelves_count")
			@a0_panel_count = @inst.definition.get_attribute("dynamic_attributes", "a0_panel_count")
			@a0_drawer_count = @inst.definition.get_attribute("dynamic_attributes", "a0_drawer_count")
			
			@line4_text = ""
			@line5_text = ""
			if @point_y_offset
				@len = "a0_leny"
				@line4_text = "#{SUF_STRINGS["Leftward"]} - #{SUF_STRINGS["Left"]} | #{SUF_STRINGS["Rightward"]} - #{SUF_STRINGS["Right"]} | #{SUF_STRINGS["Upward"]} - #{SUF_STRINGS["Top"]} | #{SUF_STRINGS["Downward"]} - #{SUF_STRINGS["Bottom"]}"
				if @thickness_carcass != "no" && @su_type == "carcass"
          set_attribute_with_formula(@inst,"a00_leny",@thickness_carcass.to_f/25.4,'LOOKUP("b1_p_thickness",'+(@thickness_carcass.to_f/10).to_s+')')
          @thickness = @thickness_carcass.to_f.round
          elsif @thickness_back != "no" && @su_type == "back"
          set_attribute_with_formula(@inst,"a00_leny",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",LOOKUP("c5_back_thick",LOOKUP("c8_b_thickness",'+(@thickness_back.to_f/10).to_s+')))')
          @thickness = @thickness_back.to_f.round
          elsif @thickness_frontal != "no" && @su_type == "frontal"
          set_attribute_with_formula(@inst,"a00_leny",@thickness_frontal.to_f/25.4,'LOOKUP("b1_f_thickness",'+(@thickness_frontal.to_f/10).to_s+')')
          @thickness = @thickness_frontal.to_f.round
          else
          @thickness = (@inst.definition.get_attribute("dynamic_attributes", "a00_leny", "0").to_f*25.4).round
        end
        elsif @point_x_offset
        @len = "a0_lenx"
        @line4_text = "#{SUF_STRINGS["Leftward"]} - #{SUF_STRINGS["Front"]} | #{SUF_STRINGS["Rightward"]} - #{SUF_STRINGS["Back"]} | #{SUF_STRINGS["Upward"]} - #{SUF_STRINGS["Top"]} | #{SUF_STRINGS["Downward"]} - #{SUF_STRINGS["Bottom"]}"
        if @thickness_carcass != "no" && @su_type == "carcass"
          set_attribute_with_formula(@inst,"a00_lenx",@thickness_carcass.to_f/25.4,'LOOKUP("b1_p_thickness",'+(@thickness_carcass.to_f/10).to_s+')')
          @thickness = @thickness_carcass.to_f.round
          elsif @thickness_back != "no" && @su_type == "back"
          set_attribute_with_formula(@inst,"a00_lenx",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",LOOKUP("c5_back_thick",LOOKUP("c8_b_thickness",'+(@thickness_back.to_f/10).to_s+')))')
          @thickness = @thickness_back.to_f.round
          elsif @thickness_frontal != "no" && @su_type == "frontal"
          set_attribute_with_formula(@inst,"a00_lenx",@thickness_frontal.to_f/25.4,'LOOKUP("b1_f_thickness",'+(@thickness_frontal.to_f/10).to_s+')')
          @thickness = @thickness_frontal.to_f.round
          else
          @thickness = (@inst.definition.get_attribute("dynamic_attributes", "a00_lenx", "0").to_f*25.4).round
        end
        elsif @point_z_offset
        @len = "a0_lenz"
        @line4_text = "#{SUF_STRINGS["Leftward"]} - #{SUF_STRINGS["Left"]} | #{SUF_STRINGS["Rightward"]} - #{SUF_STRINGS["Right"]} | #{SUF_STRINGS["Upward"]} - #{SUF_STRINGS["Back"]} | #{SUF_STRINGS["Downward"]} - #{SUF_STRINGS["Front"]}"
        if @thickness_carcass != "no" && @su_type == "carcass"
          set_attribute_with_formula(@inst,"a00_lenz",@thickness_carcass.to_f/25.4,'LOOKUP("b1_p_thickness",'+(@thickness_carcass.to_f/10).to_s+')')
          @thickness = @thickness_carcass.to_f.round
          elsif @thickness_back != "no" && @su_type == "back"
          set_attribute_with_formula(@inst,"a00_lenz",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",LOOKUP("c5_back_thick",LOOKUP("c8_b_thickness",'+(@thickness_back.to_f/10).to_s+')))')
          @thickness = @thickness_back.to_f.round
          elsif @thickness_frontal != "no" && @su_type == "frontal"
          set_attribute_with_formula(@inst,"a00_lenz",@thickness_frontal.to_f/25.4,'LOOKUP("b1_f_thickness",'+(@thickness_frontal.to_f/10).to_s+')')
          @thickness = @thickness_frontal.to_f.round
          else
          @thickness = (@inst.definition.get_attribute("dynamic_attributes", "a00_lenz", "0").to_f*25.4).round
        end
        elsif @trim_x1 || @trim_x2
        @len = "b1_p_thickness"
        @line4_text = "#{SUF_STRINGS["Leftward"]} - #{SUF_STRINGS["Left"]} | #{SUF_STRINGS["Rightward"]} - #{SUF_STRINGS["Right"]} | #{SUF_STRINGS["Upward"]} - #{SUF_STRINGS["Top"]} | #{SUF_STRINGS["Downward"]} - #{SUF_STRINGS["Bottom"]}"
        if @thickness_back != "no"
          if @b1_b_thickness
            set_attribute_with_formula(@inst,"b1_b_thickness",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",'+(@thickness_back.to_f/10).to_s+')')
          end
          if @inst.definition.get_attribute("dynamic_attributes", "c8_b_thickness")
            set_attribute_with_formula(@inst,"c8_b_thickness",@thickness_back.to_f/25.4,'LOOKUP("c5_back_thick",'+(@thickness_back.to_f/10).to_s+')')
            elsif @inst.definition.get_attribute("dynamic_attributes", "k8_b_thickness")
            set_attribute_with_formula(@inst,"k8_b_thickness",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",'+(@thickness_back.to_f/10).to_s+')')
            elsif @inst.definition.get_attribute("dynamic_attributes", "c5_back_thick")
            set_attribute_with_formula(@inst,"b1_b_thickness",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",'+(@thickness_back.to_f/10).to_s+')')
          end
        end
        if @a0_door_count
          @line5_text = " +/- #{SUF_STRINGS["Number of doors"]}"
          elsif @a0_shelves_count
          @line5_text = " +/- #{SUF_STRINGS["Number of shelves"]}"
          elsif @a0_panel_count
          @line5_text = " +/- #{SUF_STRINGS["Number of panels"]}"
          elsif @a0_drawer_count
          @line5_text = " +/- #{SUF_STRINGS["Number of drawers"]}"
        end
      end
			if @point_x_offset || @point_y_offset || @point_z_offset
				Sketchup::set_status_text(SUF_STRINGS["Thickness"], SB_VCB_LABEL)
				Sketchup::set_status_text(@thickness, SB_VCB_VALUE)
      end
			$SUF_Place_Component = true
    end#def
    def read_param
      @delete_hidden = "no"
      @auto_option = "no"
      @thickness_carcass = "no"
      @thickness_back = "no"
      @thickness_frontal = "no"
      @auto_dimension = "no"
      @intersect = "no"
      @pages_properties = "no"
      @purge_unused = "yes"
      @defaults_HF = []
      if File.file?( TEMP_PATH+"/SUF/place_HF.dat")
        path_param = TEMP_PATH+"/SUF/place_HF.dat"
        else
        path_param = PATH + "/parameters/place_HF.dat"
      end
      content = File.readlines(path_param)
      content.each { |i| @defaults_HF << i.strip }
      @defaults_drawer = []
      if File.file?( TEMP_PATH+"/SUF/drawers_place.dat")
        path_param = TEMP_PATH+"/SUF/drawers_place.dat"
        else
        path_param = PATH + "/parameters/drawers_place.dat"
      end
      content = File.readlines(path_param)
      content.each { |i| @defaults_drawer << i.strip }
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      content = File.readlines(path_param)
      content.each { |i|
        @delete_hidden = i.strip.split("=")[2] if i.strip.split("=")[1] == "delete_hidden"
        @auto_option = i.strip.split("=")[2] if i.strip.split("=")[1] == "auto_option"
        @thickness_carcass = i.strip.split("=")[2] if i.strip.split("=")[1] == "thickness_carcass"
        @thickness_back = i.strip.split("=")[2] if i.strip.split("=")[1] == "thickness_back"
        @thickness_frontal = i.strip.split("=")[2] if i.strip.split("=")[1] == "thickness_frontal"
        @auto_dimension = i.strip.split("=")[2] if i.strip.split("=")[1] == "auto_dimension"
        @intersect = i.strip.split("=")[2] if i.strip.split("=")[1] == "intersect"
        @pages_properties = i.strip.split("=")[2] if i.strip.split("=")[1] == "pages_properties"
        @purge_unused = i.strip.split("=")[2] if i.strip.split("=")[1] == "purge_unused"
      }
    end#def
		def clean_modules()
		  @model.active_entities.grep(Sketchup::ComponentInstance).each { |e|
				if e.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module"
					body = e.definition.entities.grep(Sketchup::ComponentInstance).find { |body_ent| body_ent.definition.name.include?("Body") }
					e.definition.entities.grep(Sketchup::Edge).to_a.each {|e| e.erase! if !e.deleted?} if body
        end
      }
    end
		def deactivate(view)
			#p "deactivate place_component"
			$SUF_Place_Component = false
			@shift_press = false
			@control_press = false
			view.invalidate
			if @placed && !@canceled
				@model.commit_operation
				$dlg_att.execute_script("add_comp()") if $dlg_att
				if @auto_option == "yes"
					UI.start_timer(0.1, false) { @model.tools.push_tool( Change_Point ) }
					else
					Sketchup.send_action("selectMoveTool:") if !@place_with_control
					@model.layers.add_observer $SUFLayersObserver
					if SU_Furniture.observers_state == 1
						@sel.add_observer $SUFSelectionObserver
						@model.entities.add_observer $SUFEntitiesObserver
						UI.start_timer(0.9, false) { @model.tools.add_observer($SUFToolsObserver) }
          end
        end
				else
				@model.abort_operation
				@model.layers.add_observer $SUFLayersObserver
				if SU_Furniture.observers_state == 1
					@sel.add_observer $SUFSelectionObserver
					@model.entities.add_observer $SUFEntitiesObserver
					UI.start_timer(0.9, false) { @model.tools.add_observer($SUFToolsObserver) }
        end
      end
			@model.start_operation "clear", true, false, true
			@inst.erase! if !@inst.deleted?
			clean_modules()
			@model.definitions.purge_unused if @purge_unused == "yes"
			@model.layers.each { |l|
				l.visible = false if l.name.include?("Габаритная_рамка") || l.name.include?("Направляющие")
				l.visible = true if l.name.include?("Фасад_открывание")
      }
			@visible_layer.each_pair { |l,v| l.visible = v if !l.deleted? } if @visible_layer
      @new_layers = @model.layers.to_a - @old_layers
			@model.pages.each {|page|
				@new_layers.each {|layer|
					page.set_visibility(layer, layer.visible?)
        }
      }
			number_comp = @model.get_attribute('su_lists','number_comp')
			@model.set_attribute('su_lists','number_comp','false') if !number_comp || number_comp != 'false'
			@model.commit_operation
			@input = false
			@place_with_control = false
    end#def
		def resume(view)
			view.invalidate
    end#def
		def onSetCursor
			UI.set_cursor(641)
    end#def
		def draw(view)
			OSX ? ctrl_text = "Command" : ctrl_text = "Ctrl"
			view.draw_text(Geom::Point3d.new(30, 25, 0), "#{SUF_STRINGS["Hold"]} "+ctrl_text+" #{SUF_STRINGS["to install in niche"]}", @line_black_text_options)
			
			if @point_x_offset || @point_y_offset || @point_z_offset
				view.draw_text(Geom::Point3d.new(30, 55, 0), SUF_STRINGS["Press Tab to switch point by thickness"], @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 85, 0), SUF_STRINGS["Press Arrows to switch points along axes"], @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 115, 0), "Shift + #{SUF_STRINGS["Arrows move by panel thickness"]}:", @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 145, 0), @line4_text, @line_black_text_options)
				Sketchup::set_status_text(SUF_STRINGS["Thickness"], SB_VCB_LABEL)
				Sketchup::set_status_text(@thickness, SB_VCB_VALUE)
				elsif @trim_x1 || @trim_x2
				view.draw_text(Geom::Point3d.new(30, 55, 0), SUF_STRINGS["Press Tab to switch point by width"], @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 85, 0), SUF_STRINGS["Press Arrows to switch points along axes"], @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 115, 0), "Shift + #{SUF_STRINGS["Arrows move by edges"]}:", @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 145, 0), @line4_text, @line_black_text_options)
				view.draw_text(Geom::Point3d.new(30, 175, 0), @line5_text, @line_black_text_options) if @line5_text != ""
      end
			@ip.draw(view) if @ip.display?
			if @control_press && @points != []
				#p @points
				draw_points = [
					Geom::Point3d.new(@points[0], @points[2], @points[4]),
					Geom::Point3d.new(@points[0], @points[2], @points[5]),
					Geom::Point3d.new(@points[1], @points[2], @points[5]),
					Geom::Point3d.new(@points[1], @points[2], @points[4]),#спереди
					Geom::Point3d.new(@points[0], @points[3], @points[4]),
					Geom::Point3d.new(@points[0], @points[3], @points[5]),
					Geom::Point3d.new(@points[1], @points[3], @points[5]),
					Geom::Point3d.new(@points[1], @points[3], @points[4]),#сзади
					Geom::Point3d.new(@points[0], @points[2], @points[4]),
					Geom::Point3d.new(@points[0], @points[2], @points[5]),
					Geom::Point3d.new(@points[0], @points[3], @points[5]),
					Geom::Point3d.new(@points[0], @points[3], @points[4]),#слева
					Geom::Point3d.new(@points[1], @points[2], @points[4]),
					Geom::Point3d.new(@points[1], @points[2], @points[5]),
					Geom::Point3d.new(@points[1], @points[3], @points[5]),
					Geom::Point3d.new(@points[1], @points[3], @points[4]),#справа
					Geom::Point3d.new(@points[0], @points[2], @points[4]),
					Geom::Point3d.new(@points[1], @points[2], @points[4]),
					Geom::Point3d.new(@points[1], @points[3], @points[4]),
					Geom::Point3d.new(@points[0], @points[3], @points[4]),#снизу
					Geom::Point3d.new(@points[0], @points[2], @points[5]),
					Geom::Point3d.new(@points[1], @points[2], @points[5]),
					Geom::Point3d.new(@points[1], @points[3], @points[5]),
					Geom::Point3d.new(@points[0], @points[3], @points[5]) #сверху
        ]
				draw_points.map!{|pt|pt.transform @transformation}
				view.drawing_color = @orange
				view.draw(GL_QUADS, draw_points)
      end
    end#def
    def bounds_size(entities)
      bb = Geom::BoundingBox.new
      entities.each { |entity|
        bb.add(entity.bounds) if entity.respond_to?(:bounds)
      }
      local_width = get_size(bb.corner(0),bb.corner(1),"x")
      local_height = get_size(bb.corner(0),bb.corner(2),"y")
      local_depth = get_size(bb.corner(0),bb.corner(4),"z")
      return local_width,local_height,local_depth
    end#def
    def get_size(pt1,pt2,axis)
      pt2.send("#{axis}") - pt1.send("#{axis}")
    end#def
		def onMouseMove(flags, x, y, view)
			if @inst && !@inst.deleted?
				behavior = @inst.definition.behavior
				if behavior.is2d? && behavior.snapto == SnapTo_Arbitrary
					else
					@tr_x = @inst.transformation.xaxis
					@tr_y = @inst.transformation.yaxis
					@tr_z = @inst.transformation.zaxis
        end
				@inst.move!(Geom::Transformation.translation(Geom::Point3d.new(0, 0, 1000)))
				if @sel[0] != @inst
					@sel.clear
					@sel.add @inst
          $SUFSelectionObserver.clear_selection()
          add_selection(@inst)
					$dlg_att.execute_script("add_comp()") if $dlg_att
        end
				@screen_x = x
				@screen_y = y
				@ip.pick view,x,y
				ph = view.pick_helper
				ph.do_pick(x, y)
				@pt = @ip.position
				view.tooltip = @ip.tooltip if @ip.valid?
				
				if ph.picked_face
					face = ph.picked_face
					if face.normal.x.abs == 1
						index = ph.count.times.find { |i| ph.leaf_at(i) == face }
						transformation = index ? ph.transformation_at(index) : IDENTITY
						projected_point = @ip.position.transform(transformation.inverse).project_to_plane( face.plane )
						@ip = Sketchup::InputPoint.new(projected_point.transform(transformation))
						@ip_face = face
						@face_normal = @ip_face.normal.transform!(transformation)
          end
					else
					@ip_face = nil
					if behavior.is2d? && behavior.snapto == SnapTo_Arbitrary
						tr = Geom::Transformation.new(@pt, Z_AXIS)
						@inst.transformation = tr
          end
        end
				
				if @control_press
					@points = []
					@picked_comp = ph.best_picked
					if @picked_comp && @picked_comp.is_a?(Sketchup::ComponentInstance)
						@picked_comp.make_unique if @picked_comp.definition.count_instances > 1
            @picked_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if @picked_comp.parent.is_a?(Sketchup::ComponentDefinition)
						@body = @picked_comp.definition.entities.grep(Sketchup::ComponentInstance).find { |ent| ent.definition.name.include?("Body")}
						if @body
              local_width,local_height,local_depth = bounds_size(@body.definition.entities)
							@transformation = @picked_comp.transformation
							@transformation *= @body.transformation
							@body_transformation = @picked_comp.transformation*@body.transformation
							@pt_in_comp = @pt.transform( @transformation.inverse )
							@body_and_level = {}
							@pts_for_bounds = {}
							@pts_for_bounds["min_x"] = []
							@pts_for_bounds["min_z"] = []
							@pts_for_bounds["max_x"] = []
							@pts_for_bounds["max_z"] = []
							@pts_for_bounds["max_y"] = []
							@body.make_unique if @body.definition.count_instances > 1
              @body.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if @body.parent.is_a?(Sketchup::ComponentDefinition)
							@body.definition.entities.grep(Sketchup::ComponentInstance).each { |comp| essence_pts(comp,Geom::Transformation.new,@body,1) }
							if @body_and_level == {}
								@body_and_level[@body] = [1,@transformation]
              end
							if @pts_for_bounds["min_x"] == []
								@min_x = [(@pts_for_bounds["min_z"]==[] ? 0: @pts_for_bounds["min_z"].map{|pt|pt.x}.sort[0]),(@pts_for_bounds["max_z"]==[] ? 0 : @pts_for_bounds["max_z"].map{|pt|pt.x}.sort[0])].sort[-1]
								else
								@min_x = @pts_for_bounds["min_x"][0].x
              end
							if @pts_for_bounds["max_x"] == []
								@max_x = [(@pts_for_bounds["min_z"]==[] ? local_width : @pts_for_bounds["min_z"].map{|pt|pt.x}.sort[-1]),(@pts_for_bounds["max_z"]==[] ? local_width : @pts_for_bounds["max_z"].map{|pt|pt.x}.sort[-1])].sort[0]
								else
								@max_x = @pts_for_bounds["max_x"][0].x
              end
							if @pts_for_bounds["min_z"] == []
								@min_z = [(@pts_for_bounds["min_x"]==[] ? 0 : @pts_for_bounds["min_x"].map{|pt|pt.z}.sort[0]),(@pts_for_bounds["max_x"]==[] ? 0 : @pts_for_bounds["max_x"].map{|pt|pt.z}.sort[0])].sort[-1]
								else
								@min_z = @pts_for_bounds["min_z"][0].z
              end
							if @pts_for_bounds["max_z"] == []
								@max_z = [(@pts_for_bounds["min_x"]==[] ? local_depth : @pts_for_bounds["min_x"].map{|pt|pt.z}.sort[-1]),(@pts_for_bounds["max_x"]==[] ? local_depth : @pts_for_bounds["max_x"].map{|pt|pt.z}.sort[-1])].sort[0]
								else
								@max_z = @pts_for_bounds["max_z"][0].z
              end
							if @inst.definition.name.include?("купе")
								@min_y = 0
								else
								@min_y = [(@pts_for_bounds["min_x"]==[] ? 0 : @pts_for_bounds["min_x"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["max_x"]==[] ? 0 : @pts_for_bounds["max_x"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["min_z"]==[] ? 0 : @pts_for_bounds["min_z"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["max_z"]==[] ? 0 : @pts_for_bounds["max_z"].map{|pt|pt.y}.sort[0])].sort[-1]
              end
							if @pts_for_bounds["max_y"] == []
								@max_y = [(@pts_for_bounds["min_x"]==[] ? local_height : @pts_for_bounds["min_x"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["max_x"]==[] ? local_height : @pts_for_bounds["max_x"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["min_z"]==[] ? local_height : @pts_for_bounds["min_z"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["max_z"]==[] ? local_height : @pts_for_bounds["max_z"].map{|pt|pt.y}.sort[-1])].sort[0]
								else
								@max_y = @pts_for_bounds["max_y"][0].y
              end
							if @min_x<@max_x && @min_y<@max_y && @min_z<@max_z
								@points = [@min_x,@max_x,@min_y,@max_y,@min_z,@max_z]
              end
            end
          end
        end
				@inst_tr = Geom::Transformation.new(@pt)
				
				if behavior.is2d? && behavior.snapto == SnapTo_Arbitrary
					if @ip_face && @ip_face.parent.instances[-1].definition.name.include?("Essence") || @ip_face && @ip_face.parent.instances[-1].definition.get_attribute("dynamic_attributes", "_name") == "Essence"
						tr = Geom::Transformation.new(@pt, @face_normal)
						@inst_tr.set!(tr)
          end
					else
					tr = Geom::Transformation.axes(@pt, @tr_x, @tr_y, @tr_z)
					@inst_tr.set!(tr)
        end
				@inst.move!(@inst_tr)
				view.invalidate
      end
    end#def
		def set_transformation(view)
			@tr_x = @inst.transformation.xaxis
			@tr_y = @inst.transformation.yaxis
			@tr_z = @inst.transformation.zaxis
			tr = Geom::Transformation.axes(@inst.transformation.origin, @tr_x, @tr_y, @tr_z)
			@inst_tr.set!(tr)
			view.invalidate
    end
		def essence_pts(comp,transformation,body,level)
			if !comp.hidden?
				if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
					panel = comp.parent.instances[-1]
					panel = panel.parent.instances[-1] if panel.definition.name.include?("Body")
					if panel.definition.get_attribute("dynamic_attributes", "animation", "0").to_s == "0"
						comp.make_unique if comp.definition.count_instances > 1
            comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
						transformation*=comp.transformation
						#@body_transformation *= comp.transformation
            #p @pt_in_comp
						comp.definition.entities.grep(Sketchup::Face).each { |f|
							if f.get_attribute("dynamic_attributes", "face", "0").include?("primary")
								f_normal = f.normal.transform transformation
								f_max = f.bounds.max.transform transformation
								f_center = f.bounds.center.transform transformation
								f_min = f.bounds.min.transform transformation
								#p "#{comp.definition.name}: #{f_normal}"
									#p f_min
									#p f_center
                #p f_max
								f_normal.normalize!
								#p f_normal.z
								if f_normal.x == 1 && f_center.x <= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z && f_min.y <= @pt_in_comp.y && f_max.y >= @pt_in_comp.y
									if @pts_for_bounds["min_x"] == []
										@pts_for_bounds["min_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
										@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
										else
										@pts_for_bounds["min_x"].each { |pts|
											if @inst.definition.name.include?("купе")
												if f_center.x < pts.x
													@pts_for_bounds["min_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
												else
												if f_center.x > pts.x
													@pts_for_bounds["min_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
                      end
                    }
                  end
									
									elsif f_normal.x == -1 && f_center.x >= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z && f_min.y <= @pt_in_comp.y && f_max.y >= @pt_in_comp.y
									if @pts_for_bounds["max_x"] == []
										@pts_for_bounds["max_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
										@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
										else
										@pts_for_bounds["max_x"].each { |pts|
											if @inst.definition.name.include?("купе")
												if f_center.x > pts.x
													@pts_for_bounds["max_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
												else
												if f_center.x < pts.x
													@pts_for_bounds["max_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
                      end
                    }
                  end
									
									elsif f_normal.z == 1 && f_center.z <= @pt_in_comp.z && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x && f_min.y <= @pt_in_comp.y && f_max.y >= @pt_in_comp.y
									if @pts_for_bounds["min_z"] == []
										@pts_for_bounds["min_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
										@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
										else
										@pts_for_bounds["min_z"].each { |pts|
											if @inst.definition.name.include?("купе")
												if f_center.z < pts.z
													@pts_for_bounds["min_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
												else
												if f_center.z > pts.z
													@pts_for_bounds["min_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
                      end
                    }
                  end
									
									elsif f_normal.z == -1 && f_center.z >= @pt_in_comp.z && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x && f_min.y <= @pt_in_comp.y && f_max.y >= @pt_in_comp.y
									if @pts_for_bounds["max_z"] == []
										@pts_for_bounds["max_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
										@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
										else
										@pts_for_bounds["max_z"].each { |pts|
											if @inst.definition.name.include?("купе")
												if f_center.z > pts.z
													@pts_for_bounds["max_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
												else 
												if f_center.z < pts.z
													@pts_for_bounds["max_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
													@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                        end
                      end
                    }
                  end
									
									elsif f_normal.y == -1 && f_center.y >= @pt_in_comp.y && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z
									if @pts_for_bounds["max_y"] == []
										@pts_for_bounds["max_y"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
										@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
										else
										@pts_for_bounds["max_y"].each { |pts|
											if f_center.y < pts.y
												@pts_for_bounds["max_y"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
												@body_and_level[body] = [level,@body_transformation] if !comp.layer.name.include?("Фасад")
                      end
                    }
                  end
                end
              end
            }
          end
					else
					level += 1
					comp.make_unique if comp.definition.count_instances > 1
          comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
					if comp.definition.name.include?("Body") && !comp.get_attribute("dynamic_attributes", "_copies_formula") && !comp.definition.get_attribute("dynamic_attributes", "_copies_formula")
						body = comp
						@body_transformation = @transformation*transformation
          end
					transformation*=comp.transformation
					comp.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| essence_pts(ent,transformation,body,level) }
        end
      end
    end#def
		def new_body_transform(tr1,tr2,x,y,z)
			point = Geom::Point3d.new(x,y,z)
			point = point.transform tr1
			point = point.transform tr2.inverse
			return point.x,point.y,point.z
    end#def
		def hide_objects_in_pages(inst)
			@hidden_objects = []
			inst.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hidden_components(e) }
			@model.pages.each {|page|
				@hidden_objects.each { |e| page.set_drawingelement_visibility(e, false) }
      }
    end#def
		def drawer_width_param
			@drawer_width_param
    end
		def drawer_dialog(count,difference)
			count.to_i > 4 ? ending = SUF_STRINGS["partes"] : ending = SUF_STRINGS["parts"]
			@drawer_width_param = false
			html =
			"<style>
			body { font-family: Arial; color: #696969; font-size: 16px; }</style>"\
			"#{SUF_STRINGS["Internal module width is not divisible evenly"]} #{count} #{ending}</br></br>"\
			"#{SUF_STRINGS["Change module width"]}?</br></br></br>"\
			"<button style=\"margin-left:5px;\" onclick=\"sketchup.callback('reduce')\">#{SUF_STRINGS["Decrease by"]} #{(difference*count.to_i).round} #{SUF_STRINGS["mm"]}</button>"\
			"<button style=\"margin-left:9px;\" onclick=\"sketchup.callback('increase')\">#{SUF_STRINGS["Increase by"]} #{((1-difference)*count.to_i).round} #{SUF_STRINGS["mm"]}</button>"\
			"<button style=\"margin-left:9px;\" onclick=\"sketchup.callback(false)\">#{SUF_STRINGS["Leave unchanged"]}</button>"
      @dlg.close if @dlg && (@dlg.visible?)
			@dlg = UI::HtmlDialog.new({
				:dialog_title => ' ',
				:preferences_key => "drawer_width_param",
				:scrollable => false,
				:resizable => false,
				:width => 500,
				:height => 200,
				:style => UI::HtmlDialog::STYLE_DIALOG
      })
			@dlg.set_html(html)
			@dlg.add_action_callback("callback") { |_, v|
				@drawer_width_param = v
				@dlg.close
      }
			OSX ? @dlg.show() : @dlg.show_modal()
    end#def
		def onLButtonDown(flags, x, y, view)
      $SUFSelectionObserver.clear_selection()
			if @control_press
				if @points != []
					@sel.clear
					a01_lenx = @picked_comp.definition.get_attribute("dynamic_attributes", "a01_lenx", 50/25.4)
					a01_leny = @picked_comp.definition.get_attribute("dynamic_attributes", "a01_leny", 50/25.4)
					a00_lenz = @picked_comp.definition.get_attribute("dynamic_attributes", "a00_lenz", 50/25.4)
					@body_and_level = @body_and_level.sort_by{|key,value|value[0]}.reverse.to_h
					new_body = @body_and_level.keys[0]
					min_x,min_y,min_z = new_body_transform(@transformation,@body_and_level[new_body][1],@min_x,@min_y,@min_z)
					max_x,max_y,max_z = new_body_transform(@transformation,@body_and_level[new_body][1],@max_x,@max_y,@max_z)
					p "min_x: #{min_x}, max_x: #{max_x}, min_y: #{min_y}, max_y: #{max_y}, min_z: #{min_z}, max_z: #{max_z}"
					lenx = new_body.definition.get_attribute("dynamic_attributes", "lenx")
					leny = new_body.definition.get_attribute("dynamic_attributes", "leny")
					lenz = new_body.definition.get_attribute("dynamic_attributes", "lenz")
					b1_f_thickness = new_body.parent.get_attribute("dynamic_attributes", "b1_f_thickness", 1.6/25.4).to_f
					b1_p_thickness = new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f
					t = Geom::Transformation.translation [0, 0, 0]
					if @trim_x1 || @trim_x2
						if @inst.definition.get_attribute("dynamic_attributes", "d2_drawer1") || @inst.definition.get_attribute("dynamic_attributes", "su_type", "0") == "drawer" # ящики
							if !@inst.definition.get_attribute("dynamic_attributes", "d2_drawer1")
								UI.messagebox(SUF_STRINGS["Use Ctrl only for sections with drawers"])
								@control_press = false
								return
              end
							prompts = ["#{SUF_STRINGS["Drawer installation type"]} ","#{SUF_STRINGS["Drawer width"]} ","#{SUF_STRINGS["Number across width"]} ","#{SUF_STRINGS["Drawer depth"]} ","#{SUF_STRINGS["Depth (if Fixed)"]} ","#{SUF_STRINGS["Rear clearance"]} ","#{SUF_STRINGS["Section height"]} ","#{SUF_STRINGS["Height (if Fixed)"]} ","#{SUF_STRINGS["Front top clearance"]} ","#{SUF_STRINGS["Front bottom clearance"]} ","#{SUF_STRINGS["Front left clearance"]} ","#{SUF_STRINGS["Front right clearance"]} "]
							list = ["#{SUF_STRINGS["Overlay"]}|#{SUF_STRINGS["Inset"]}","#{SUF_STRINGS["Niche width"]}|#{SUF_STRINGS["Module width"]}","1|2|3|4|5|6|7","#{SUF_STRINGS["Maximum possible"]}|#{SUF_STRINGS["Fixed"]}","","","#{SUF_STRINGS["Between shelves"]}|#{SUF_STRINGS["Module height"]}|#{SUF_STRINGS["Fixed"]}","","","","",""]
							input = UI.inputbox prompts, @defaults_drawer, list, SUF_STRINGS["Drawer section parameters"]
							if input
								@defaults_drawer = input
								save_drawer_param(input)
								@model.start_operation('load_instance', true,false,true)
								# ширина
								drawer_instances = []
								if input[1] == SUF_STRINGS["Module width"] && input[2].to_i > 1 || input[6] == SUF_STRINGS["Module height"]
									if input[0] == SUF_STRINGS["Overlay"] && input[2].to_i > 1
										difference = ((a01_lenx-b1_p_thickness*2-b1_p_thickness*(input[2].to_i-1))*25.4).round(1)/input[2].to_i - ((a01_lenx-b1_p_thickness*2-b1_p_thickness*(input[2].to_i-1))*25.4).to_i/input[2].to_i
										@drawer_width_param = false
										if difference != 0
											drawer_dialog(input[2],difference)
											if @drawer_width_param
												a00_lenx = @picked_comp.definition.get_attribute("dynamic_attributes", "a00_lenx", 50/25.4)
												x_max_x = @picked_comp.definition.get_attribute("dynamic_attributes", "x_max_x", 200/25.4)
												if @drawer_width_param == "reduce"
													new_lenx = (a00_lenx*25.4-(difference*input[2].to_i).round).to_s
													Change_Attributes.change_deep(@picked_comp, "a00_lenx", new_lenx)
													elsif @drawer_width_param == "increase"
													new_lenx = (a00_lenx*25.4+((1-difference)*input[2].to_i).round).to_s
													if new_lenx.to_f > x_max_x.to_f*10
														max_input = UI.messagebox("#{SUF_STRINGS["Maximum module width"]} #{(x_max_x.to_f*10).round} #{SUF_STRINGS["mm"]}!\n#{SUF_STRINGS["Increase maximum width"]}?",MB_YESNO)
														if max_input == IDYES
															@picked_comp.set_attribute("dynamic_attributes", "x_max_x", (new_lenx.to_f/10).to_s)
															@picked_comp.definition.set_attribute("dynamic_attributes", "x_max_x", (new_lenx.to_f/10).to_s)
															@picked_comp.set_attribute("dynamic_attributes", "z_max_width", (new_lenx.to_f/10).to_s)
															@picked_comp.definition.set_attribute("dynamic_attributes", "z_max_width", (new_lenx.to_f/10).to_s)
                            end
                          end
													Change_Attributes.change_deep(@picked_comp, "a00_lenx", new_lenx)
                        end
												DCProgressBar::clear()
												Redraw_Components.redraw(@picked_comp,false)
                      end
                    end
										@drawer_width_param = false
                  end
									(1..input[2].to_i).each { |index|
										inst = @body.definition.entities.add_instance(@comp, t) # ставим в модуль
										inst.make_unique if inst.definition.count_used_instances > 1
                    inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
										@inst.erase! if !@inst.deleted?
										inst.definition.set_attribute("dynamic_attributes", "_drawers_count", input[2].to_i)
										hide_objects_in_pages(inst) if @model.pages.count > 0
										drawer_instances << inst
                    inst.definition.set_attribute("dynamic_attributes", "_t0_y1_frontal_formula", 'IF(LOOKUP("handle1_location",1)>1,LOOKUP("handle_frontal_trim",0),'+(input[8].gsub(",",".").to_f/10).to_s+')+IF(LOOKUP("c3_up_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)')
										set_attribute_with_formula(inst,"t0_y2_frontal",input[9].gsub(",",".").to_f/25.4)
										set_attribute_with_formula(inst,"t0_z1_frontal",input[10].gsub(",",".").to_f/25.4)
										set_attribute_with_formula(inst,"t0_z2_frontal",input[11].gsub(",",".").to_f/25.4)
										
										if input[0] == SUF_STRINGS["Inset"]
											trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,@body,a01_lenx)
											set_len_attribute(inst,"lenx",a01_lenx,'LOOKUP("a01_lenx")',"x1","x2",trim_x1,trim_x1_formula+'+CHOOSE(falsh_panel_left,0,0,falsh_panel_left_width,0)',trim_x2,trim_x2_formula+'+CHOOSE(falsh_panel_right,0,0,falsh_panel_right_width,0)')
											else
											if input[2].to_i > 1
												if index==1
													set_len_attribute(inst,"lenx",a01_lenx,'LOOKUP("a01_lenx")',"x1","x2",0,'LOOKUP("b1_p_thickness",1.6)/2+CHOOSE(falsh_panel_left,0,0,falsh_panel_left_width,0)',0,'(LOOKUP("a01_lenx")-LOOKUP("b1_p_thickness",1.6)*2-LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s+')/'+input[2]+'*'+(input[2].to_i-1).to_s+'+LOOKUP("b1_p_thickness",1.6)/2'+'+LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s)
													set_attribute_with_formula(inst,"t1_x1",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
													set_attribute_with_formula(inst,"t1_x2",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
													set_attribute_with_formula(inst,"t0_z1_frontal",b1_p_thickness/2,(input[10].to_f/10).to_s+'-LOOKUP("b1_p_thickness",1.6)/2')
													elsif index==input[2].to_i
													set_len_attribute(inst,"lenx",a01_lenx,'LOOKUP("a01_lenx")',"x1","x2",0,'(LOOKUP("a01_lenx")-LOOKUP("b1_p_thickness",1.6)*2-LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s+')/'+input[2]+'*'+(input[2].to_i-1).to_s+'+LOOKUP("b1_p_thickness",1.6)/2'+'+LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s,0,'LOOKUP("b1_p_thickness",1.6)/2+CHOOSE(falsh_panel_right,0,0,falsh_panel_right_width,0)')
													set_attribute_with_formula(inst,"t1_x1",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
													set_attribute_with_formula(inst,"t1_x2",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
													set_attribute_with_formula(inst,"t0_z2_frontal",b1_p_thickness/2,(input[11].to_f/10).to_s+'-LOOKUP("b1_p_thickness",1.6)/2')
													else
													set_len_attribute(inst,"lenx",a01_lenx,'LOOKUP("a01_lenx")',"x1","x2",0,'(LOOKUP("a01_lenx")-LOOKUP("b1_p_thickness",1.6)*2-LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s+')/'+input[2]+'*'+(index-1).to_s+'+LOOKUP("b1_p_thickness",1.6)/2'+'+LOOKUP("b1_p_thickness",1.6)*'+(index-1).to_s,0,'(LOOKUP("a01_lenx")-LOOKUP("b1_p_thickness",1.6)*2-LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-1).to_s+')/'+input[2]+'*'+(input[2].to_i-index).to_s+'+LOOKUP("b1_p_thickness",1.6)/2'+'+LOOKUP("b1_p_thickness",1.6)*'+(input[2].to_i-index).to_s)
													set_attribute_with_formula(inst,"t1_x1",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
													set_attribute_with_formula(inst,"t1_x2",b1_p_thickness/2,'LOOKUP("b1_p_thickness",1.6)/2')
                        end
												else
												set_attribute_with_formula(inst,"a00_lenx",a01_lenx,'LOOKUP("a01_lenx")')
												set_attribute_with_formula(inst,"lenx",a01_lenx)
                      end
                    end
                  }
									
									else
									
									inst = new_body.definition.entities.add_instance(@comp, t) # ставим в нишу
									inst.make_unique if inst.definition.count_used_instances > 1
                  add_selection(inst)
                  inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
									@inst.erase! if !@inst.deleted?
									hide_objects_in_pages(inst) if @model.pages.count > 0
									drawer_instances << inst
                  set_attribute_with_formula(inst,"t0_y1_frontal",input[8].gsub(",",".").to_f/25.4)
                  set_attribute_with_formula(inst,"t0_y2_frontal",input[9].gsub(",",".").to_f/25.4)
                  set_attribute_with_formula(inst,"t0_z1_frontal",input[10].gsub(",",".").to_f/25.4)
                  set_attribute_with_formula(inst,"t0_z2_frontal",input[11].gsub(",",".").to_f/25.4)
									trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,new_body,lenx)
									if input[0] == SUF_STRINGS["Overlay"]
										trim_x1_formula ? trim_x1_formula += '-LOOKUP("b1_p_thickness",1.6)' : trim_x1_formula = '-LOOKUP("b1_p_thickness",1.6)'
										trim_x2_formula ? trim_x2_formula += '-LOOKUP("b1_p_thickness",1.6)' : trim_x2_formula = '-LOOKUP("b1_p_thickness",1.6)'
                  end
									set_len_attribute(inst,"lenx",lenx,'LOOKUP("a01_lenx")',"x1","x2",trim_x1,trim_x1_formula+'+CHOOSE(falsh_panel_left,0,0,falsh_panel_left_width,0)',trim_x2,trim_x2_formula+'+CHOOSE(falsh_panel_right,0,0,falsh_panel_right_width,0)')
                end
								DCProgressBar::clear()
								drawer_instances.each { |inst|
									
									# глубина
									trim_y1,trim_y1_formula,trim_y2,trim_y2_formula = trim_y_formula(inst,min_y,max_y,new_body,leny) 
									if input[0] == SUF_STRINGS["Inset"]
										trim_y1_formula ? trim_y1_formula += '+LOOKUP("b1_f_thickness",1.6)' : trim_y1_formula = 'LOOKUP("b1_f_thickness",1.6)'
                  end
									set_attribute_with_formula(inst,"a04_type",input[0] == "Вкладные" ? "2" : "1")
									set_attribute_with_formula(inst,"d1_back_indent",input[5].to_f/25.4)
									if input[3] == SUF_STRINGS["Fixed"]
										set_attribute_with_formula(inst,"a00_leny",input[4].to_f/25.4,(input[4].to_f/10).to_s)
										#set_attribute_with_formula(inst,"leny",input[4].to_f/25.4)
										else
										set_len_attribute(inst,"leny",leny,'LOOKUP("a01_leny")',"y1","y2",trim_y1,trim_y1_formula,trim_y2,trim_y2_formula)
                  end
									
									# высота
									if input[6] == SUF_STRINGS["Between shelves"]
										trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz) 
										set_len_attribute(inst,"lenz",lenz,'LOOKUP("a01_lenz")',"z1","z2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
										elsif input[6] == SUF_STRINGS["Module height"]
										trim_z1_formula = 'IF(LOOKUP("c3_up_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)'
										trim_z2_formula = 'IF(LOOKUP("c4_down_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)'
										if new_body.parent.get_attribute("dynamic_attributes", "_trim_z2_formula") != 'CHOOSE(c4_plint,0,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size)'
											trim_z2_formula += '+CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))'
                    end
										set_len_attribute(inst,"lenz",a00_lenz,'LOOKUP("a01_lenz")',"z1","z2",0,trim_z1_formula,0,trim_z2_formula)
										else
										set_attribute_with_formula(inst,"a00_lenz",input[7].to_f/25.4,(input[7].to_f/10).to_s)
										set_attribute_with_formula(inst,"lenz", input[7].to_f/25.4)
                  end
									Redraw_Components.redraw(inst,false)
									inst.definition.entities.grep(Sketchup::ComponentInstance).each { |e| 
										if e.definition.name.include?("Body")
											e.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
												entity.definition.set_attribute("dynamic_attributes", "body_comp", true)
                      }
                    end
                  }
									if @delete_hidden == "yes"
										inst.definition.set_attribute("dynamic_attributes", "comp_path", @comp_path)
										delete_hidden_components(inst)
										@model.definitions.purge_unused
                  end
									material_formula(inst,true)
									element_add(inst,false,false)
									@sel.add inst
                  add_selection(inst)
									Change_Point.place_component(inst)
                }
								DCProgressBar::clear()
								@model.commit_operation
								view.invalidate
								@placed = true
								@place_with_control = true
								@model.select_tool(nil)
								else
								view.invalidate
								@model.select_tool(nil)
              end
							
							else # секции
              
							if @inst.definition.name.include?("фасад")
								lenx = @body.definition.get_attribute("dynamic_attributes", "lenx")
								lenz = @body.definition.get_attribute("dynamic_attributes", "lenz")
								frontal_parameters_dialog(view,@body,min_x,max_x,lenx,min_z,max_z,lenz,false)
								else
								@model.start_operation('load_instance', true,false,true)
								new_body = @body if @a03_type && @a03_type == "furniture"
								inst = new_body.definition.entities.add_instance(@comp, t)
								inst.make_unique if inst.definition.count_used_instances > 1
                inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
								@inst.erase! if !@inst.deleted?
                
								hide_objects_in_pages(inst) if @model.pages.count > 0
								trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,new_body,lenx)
								set_len_attribute(inst,"lenx",lenx,'LOOKUP("a01_lenx")',"x1","x2",trim_x1,trim_x1_formula,trim_x2,trim_x2_formula)
                trim_y1,trim_y1_formula,trim_y2,trim_y2_formula = trim_y_formula(inst,min_y,max_y,new_body,leny)
                set_len_attribute(inst,"leny",leny,'LOOKUP("a01_leny")',"y1","y2",trim_y1,trim_y1_formula,trim_y2,trim_y2_formula)
								trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz)
								set_len_attribute(inst,"lenz",lenz,'LOOKUP("a01_lenz")',"z1","z2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
								material_formula(inst,true)
								element_add(inst,false,false)
								Redraw_Components.run_all_formulas(inst)
                Redraw_Components.redraw(inst,false)
								@sel.add inst
                add_selection(inst)
								Change_Point.place_component(inst)
								@model.commit_operation
								view.invalidate
								@placed = true
								@place_with_control = true
								@model.select_tool(nil)
              end
            end
						
						else
						
						if @inst.definition.name.include?("Штанга")
              
							if @inst.definition.name.include?("вертикальная")
                @model.start_operation('load_instance', true,false,true)
                t = Geom::Transformation.translation [lenx/2, leny/2, 0]
                inst = new_body.definition.entities.add_instance(@comp, t)
                inst.make_unique if inst.definition.count_used_instances > 1
                inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
                @inst.erase! if !@inst.deleted?
                hide_objects_in_pages(inst) if @model.pages.count > 0
                trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz)
                inst.set_attribute("dynamic_attributes", "_z_formula",trim_z2_formula)
                inst.definition.set_attribute("dynamic_attributes", "_inst__z_formula",trim_z2_formula)
                set_attribute_with_formula(inst,"a00_lenz",max_z-min_z,'LOOKUP("a01_lenz")-'+trim_z1_formula+'-'+trim_z2_formula)
                set_attribute_with_formula(inst,"lenz",max_z-min_z)
                Redraw_Components.redraw_entities_with_Progress_Bar([inst])
                @sel.add inst
                add_selection(inst)
                Change_Point.place_component(inst)
                @model.commit_operation
                view.invalidate
                @placed = true
                @place_with_control = true
                @model.select_tool(nil)
                else # горизонтальные
                prompts = ["#{SUF_STRINGS["Number of rails by height"]} "]
                defaults = ["1"]
                list = ["1|2"]
                input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Rail section parameters"]
                if input
                  @model.start_operation('load_instance', true,false,true)
                  t = Geom::Transformation.translation [0, leny/2, max_z]
                  inst = new_body.definition.entities.add_instance(@comp, t)
                  inst.make_unique if inst.definition.count_used_instances > 1
                  inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
                  @inst.erase! if !@inst.deleted?
                  hide_objects_in_pages(inst) if @model.pages.count > 0
                  
                  trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz)
                  inst.set_attribute("dynamic_attributes", "_z_formula",'LOOKUP("a01_lenz")-('+trim_z1_formula+')')
                  inst.definition.set_attribute("dynamic_attributes", "_inst__z_formula",'LOOKUP("a01_lenz")-('+trim_z1_formula+')')
                  
                  trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,new_body,lenx)
                  inst.set_attribute("dynamic_attributes", "_x_formula",trim_x1_formula)
                  inst.definition.set_attribute("dynamic_attributes", "_inst__x_formula",trim_x1_formula)
                  set_attribute_with_formula(inst,"a00_lenx",max_x-min_x,'LOOKUP("a01_lenx")-('+trim_x1_formula+')-('+trim_x2_formula+')')
                  
                  Redraw_Components.redraw_entities_with_Progress_Bar([inst])
                  @sel.add inst
                  add_selection(inst)
                  if input[0] == "2"
                    t = Geom::Transformation.translation [0, leny/2, (max_z+min_z)/2]
                    inst2 = new_body.definition.entities.add_instance(@comp, t)
                    inst2.make_unique if inst2.definition.count_used_instances > 1
                    inst2.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst2.parent.is_a?(Sketchup::ComponentDefinition)
                    hide_objects_in_pages(inst2) if @model.pages.count > 0
                    inst2.set_attribute("dynamic_attributes", "_z_formula",'(LOOKUP("a01_lenz")-('+trim_z1_formula+'))/2')
                    inst2.definition.set_attribute("dynamic_attributes", "_inst__z_formula",'(LOOKUP("a01_lenz")-('+trim_z1_formula+'))/2')
                    inst2.set_attribute("dynamic_attributes", "_x_formula",trim_x1_formula)
                    inst2.definition.set_attribute("dynamic_attributes", "_inst__x_formula",trim_x1_formula)
                    set_attribute_with_formula(inst2,"a00_lenx",max_x-min_x,'LOOKUP("a01_lenx")-('+trim_x1_formula+')-('+trim_x2_formula+')')
                    Redraw_Components.redraw_entities_with_Progress_Bar([inst2])
                    @sel.add inst2
                    add_selection(inst2)
                  end
                  @model.commit_operation
                  view.invalidate
                  @placed = true
                  @place_with_control = true
                  @model.select_tool(nil)
                  else
                  view.invalidate
                  @model.select_tool(nil)
                end
              end
							
							else # не штанга
							
							if @inst.definition.name.include?("Фасад")
								lenx = @body.definition.get_attribute("dynamic_attributes", "lenx")
								lenz = @body.definition.get_attribute("dynamic_attributes", "lenz")
								input = nil
								prompts = ["#{SUF_STRINGS["Thickness"]} ","#{SUF_STRINGS["Top clearance"]} ","#{SUF_STRINGS["Bottom clearance"]} ","#{SUF_STRINGS["Left clearance"]} ","#{SUF_STRINGS["Right clearance"]} "]
								if @inst.definition.name.include?("Aventos HF")
									if (max_y-min_y)*25.4 < 278
										UI.messagebox("#{SUF_STRINGS["Aventos HF installation requires"]}\n#{SUF_STRINGS["minimum 278 mm in depth!"]}")
										view.invalidate
										@model.select_tool(nil)
										else
										list = ["","","","",""]
										input = UI.inputbox prompts, @defaults_HF, list, SUF_STRINGS["Front parameters"]
										if input
											@defaults_HF = input
											save_HF_param(input)
											param = "auto<=>auto;3;#{input[1]};#{input[2]};#{input[3]};#{input[4]};1|auto<=>|auto<=>|auto<=>|#{SUF_STRINGS["Front width"]}=frontal_width=1=SELECT=&1^#{SUF_STRINGS["Module width"]}&2^#{SUF_STRINGS["Niche width"]}&3^#{SUF_STRINGS["Fixed"]}|#{SUF_STRINGS["Fixed width"]} (#{SUF_STRINGS["mm"]})=frontal_width_input=2000=INPUT|#{SUF_STRINGS["Horizontal position"]}=hor_position=1=SELECT=&1^#{SUF_STRINGS["Left"]}&2^#{SUF_STRINGS["Right"]}|#{SUF_STRINGS["Front height"]}=frontal_height=1=SELECT=&1^#{SUF_STRINGS["Module height"]}&2^#{SUF_STRINGS["Niche height"]}&3^#{SUF_STRINGS["Fixed"]}|#{SUF_STRINGS["Fixed height"]} (#{SUF_STRINGS["mm"]})=frontal_height_input=1600=INPUT|#{SUF_STRINGS["Vertical position"]}=ver_position=1=SELECT=&1^#{SUF_STRINGS["Bottom"]}&2^#{SUF_STRINGS["Top"]}|#{SUF_STRINGS["Front thickness"]}=frontal_thickness=#{input[0]}=INPUT"
											place_frontal(param,view,@body,min_x,max_x,lenx,min_z,max_z,lenz)
											else
											view.invalidate
											@model.select_tool(nil)
                    end
                  end
									else
									@shift_press = false
									@control_press = false
									@place_with_control = false
									frontal_parameters_dialog(view,@body,min_x,max_x,lenx,min_z,max_z,lenz)
                end
								
								else
								prompts = ["#{SUF_STRINGS["By width"]} ","#{SUF_STRINGS["By height"]} ","#{SUF_STRINGS["By depth"]} "]
								list = ["#{SUF_STRINGS["Left"]}|#{SUF_STRINGS["Center of niche"]}|#{SUF_STRINGS["Right"]}","#{SUF_STRINGS["Bottom"]}|#{SUF_STRINGS["Center of niche"]}|#{SUF_STRINGS["Top"]}","#{SUF_STRINGS["Front"]}|#{SUF_STRINGS["Center of niche"]}|#{SUF_STRINGS["Back"]}"]
								input = UI.inputbox prompts, @defaults_other, list, SUF_STRINGS["Placement parameters"]
								if input
									@defaults_other = input
									case input[0]
										when "#{SUF_STRINGS["Left"]}" then x = 0;point_x=1
										when "#{SUF_STRINGS["Center of niche"]}" then x = (min_x+max_x)/2;point_x=2
										when "#{SUF_STRINGS["Right"]}" then x = lenx;point_x=3
                  end
									case input[1]
										when "#{SUF_STRINGS["Bottom"]}" then z = 0;point_z=1
										when "#{SUF_STRINGS["Center of niche"]}" then z = (min_z+max_z)/2;point_z=2
										when "#{SUF_STRINGS["Top"]}" then z = lenz;point_z=3
                  end
									case input[2]
										when "#{SUF_STRINGS["Front"]}" then y = 0;point_y=1
										when "#{SUF_STRINGS["Center of niche"]}" then y = (min_y+max_y)/2;point_y=2
										when "#{SUF_STRINGS["Back"]}" then y = max_y;point_y=3
                  end
									t = Geom::Transformation.translation [x, y, z]
									@model.start_operation('load_instance', true,false,true)
									inst = new_body.definition.entities.add_instance(@comp, t)
									inst.make_unique if inst.definition.count_used_instances > 1
                  inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
									hide_objects_in_pages(inst) if @model.pages.count > 0
									if @point_y_offset #фронтальная
										trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,new_body,lenx)
										set_len_attribute(inst,"lenx",lenx,'LOOKUP("a01_lenx")',"z1","z2",trim_x1,trim_x1_formula,trim_x2,trim_x2_formula)
										trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz)
										set_len_attribute(inst,"lenz",lenz,'LOOKUP("a01_lenz")',"y1","y2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
										_a00_leny_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_leny_formula")
										set_attribute_with_formula(inst,"a00_leny",@thickness/25.4,_a00_leny_formula)
										set_attribute_with_formula(inst,"point_x",point_x)
										set_attribute_with_formula(inst,"point_y",point_y)
										set_attribute_with_formula(inst,"point_z",point_z)
										elsif @point_x_offset #вертикальная
										trim_y1,trim_y1_formula,trim_y2,trim_y2_formula = trim_y_formula(inst,min_y,max_y,new_body,leny)
										set_len_attribute(inst,"leny",leny,'LOOKUP("a01_leny")',"z1","z2",trim_y1,trim_y1_formula,trim_y2,trim_y2_formula)
										trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,new_body,lenz)
										set_len_attribute(inst,"lenz",lenz,'LOOKUP("a01_lenz")',"y1","y2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
										_a00_lenx_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_lenx_formula")
										set_attribute_with_formula(inst,"a00_lenx",@thickness/25.4,_a00_lenx_formula)
										inst.definition.delete_attribute("dynamic_attributes", "_groove_formula")
										set_attribute_with_formula(inst,"point_x",point_x)
										set_attribute_with_formula(inst,"point_y",point_y)
										set_attribute_with_formula(inst,"point_z",point_z)
										elsif @point_z_offset #горизонтальная
										trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,new_body,lenx)
										set_len_attribute(inst,"lenx",lenx,'LOOKUP("a01_lenx")',"y1","y2",trim_x1,trim_x1_formula,trim_x2,trim_x2_formula)
										trim_y1,trim_y1_formula,trim_y2,trim_y2_formula = trim_y_formula(inst,min_y,max_y,new_body,leny)
										set_len_attribute(inst,"leny",leny,'LOOKUP("a01_leny")',"z1","z2",trim_y1,trim_y1_formula,trim_y2,trim_y2_formula)
										_a00_lenz_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_lenz_formula")
										set_attribute_with_formula(inst,"a00_lenz",@thickness/25.4,_a00_lenz_formula)
										inst.definition.delete_attribute("dynamic_attributes", "_groove_formula")
										set_attribute_with_formula(inst,"point_x",point_x)
										set_attribute_with_formula(inst,"point_y",point_y)
										set_attribute_with_formula(inst,"point_z",point_z)
										else
										if !inst.definition.get_attribute("dynamic_attributes", "_leny_formula")
											set_attribute_with_formula(inst,"leny",max_y-min_y,((max_y-min_y)*2.54).round.to_s)
                    end
                  end
                  @inst.erase! if !@inst.deleted?
									Redraw_Components.redraw_entities_with_Progress_Bar([inst])
									material_formula(inst,true)
									element_add(inst,false,false)
									@sel.add inst
                  add_selection(inst)
									Change_Point.place_component(inst)
									@model.commit_operation
									view.invalidate
									@placed = true
									@place_with_control = true
									@model.select_tool(nil)
                end
              end
            end
          end
					else
					view.invalidate
					@place_with_control = false
					@model.select_tool(nil)
        end
				
				else # без ctrl
				
				@model.start_operation('load_instance', true,false,true)
				@inst.move!(Geom::Transformation.translation(Geom::Point3d.new(0, 0, 1000)))
				ip = view.inputpoint( x,y )
				t = Geom::Transformation.translation ip.position
				t.set!(@inst_tr)
				inst = @model.active_entities.add_instance(@comp,t)
				#inst.make_unique if inst.definition.count_used_instances > 1
				@inst.erase! if !@inst.deleted?
				hide_objects_in_pages(inst) if @model.pages.count > 0
				if @delete_hidden == "yes"
					include_body = false
					if !inst.definition.name.include?("купе") && !inst.definition.name.include?("асад")
						inst.definition.entities.grep(Sketchup::ComponentInstance).each { |e| 
							if e.definition.name.include?("Body")
								include_body = true
								e.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
									entity.definition.set_attribute("dynamic_attributes", "body_comp", true)
                }
              end
            }
          end
					if include_body
						inst.definition.set_attribute("dynamic_attributes", "comp_path", @comp_path)
						delete_hidden_components(inst)
						@model.definitions.purge_unused
          end
        end
        if @thickness_carcass != "no" && @b1_p_thickness
          set_attribute_with_formula(inst,"b1_p_thickness",@thickness_carcass.to_f/25.4,'LOOKUP("b1_p_thickness",'+(@thickness_carcass.to_f/10).to_s+')','CENTIMETERS','MILLIMETERS')
        end
        if @thickness_frontal != "no" && @b1_f_thickness
          set_attribute_with_formula(inst,"b1_f_thickness",@thickness_frontal.to_f/25.4,'LOOKUP("b1_f_thickness",'+(@thickness_frontal.to_f/10).to_s+')','CENTIMETERS','MILLIMETERS')
        end
        if @thickness_back != "no" && @b1_b_thickness
          set_attribute_with_formula(inst,"b1_b_thickness",@thickness_back.to_f/25.4,'LOOKUP("b1_b_thickness",'+(@thickness_back.to_f/10).to_s+')','CENTIMETERS','MILLIMETERS')
        end
				if inst.parent.is_a?(Sketchup::ComponentDefinition)
					material_formula(inst,true)
					Redraw_Components.redraw_entities_with_Progress_Bar([inst])
					else
					inst.definition.delete_attribute("dynamic_attributes", "_b1_p_material_formula")
					if @thickness_carcass != "no" || @thickness_back != "no" || @thickness_frontal != "no"
						Redraw_Components.redraw_entities_with_Progress_Bar([inst])
          end
					material_formula(inst,false) if @trim_x1 || @trim_x2
        end
        all_comp = Fasteners_Panel.search_parent(inst)
        tr = Geom::Transformation.new
        all_comp.reverse.each { |comp| tr *= comp.transformation }
        notch_arr = Fasteners_Panel.find_notch(inst,tr)
        if !notch_arr.empty?
          Fasteners_Panel.reset_comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance))
          essence_and_faces,essence_and_transformation = Fasteners_Panel.all_essences
          notch_arr.each {|notch| Fasteners_Panel.process_notch(notch[0],notch[1],notch[2],notch[3],essence_and_faces,essence_and_transformation) }
        end
				element_add(inst)
				view.invalidate
				@placed = true
				@sel.clear
				@sel.add inst
        add_selection(inst)
				Change_Point.place_component(inst)
				@model.commit_operation
				@place_with_control = false
				@model.select_tool(nil)
      end
    end#def
    def add_selection(entity)
      $SUFSelectionObserver.add_selection(entity)
    end
		def frontal_parameters_dialog(view,body,min_x,max_x,lenx,min_z,max_z,lenz,show_dialog=true)
			is_visible=$dlg_frontal.visible? if $dlg_frontal
			$dlg_frontal.close if $dlg_frontal && (is_visible==true)
			if show_dialog
				$dlg_frontal = UI::HtmlDialog.new({
					:dialog_title => " ",
					:preferences_key => "frontal",
					:scrollable => true,
					:resizable => true,
					:width => 480,
					:height => 520,
					:left => 100,
					:top => 200,
					:min_width => 480,
					:min_height => 520,
					:max_width =>1120,
					:max_height => 780,
					:style => UI::HtmlDialog::STYLE_DIALOG
        })
				html_path = PATH + "/html/Frontal_place.html"
				$dlg_frontal.set_file(html_path)	
				$dlg_frontal.add_action_callback("get_data") { |web_dialog,action_name|
					if action_name.to_s.include?("read_param")
						read_frontal_param(body)
						elsif action_name.to_s.include?("save_changes")
						param = action_name[13..-1]
						save_frontal_param(param)
						elsif action_name.to_s.include?("place_frontal")
						param = action_name[14..-1]
						$dlg_frontal.close
						place_frontal(param,view,body,min_x,max_x,lenx,min_z,max_z,lenz)
          end
        }
        OSX ? $dlg_frontal.show() : $dlg_frontal.show_modal()
				else
        param = "auto<=>auto;0;0;0;0;0;1|auto<=>|auto<=>|auto<=>|#{SUF_STRINGS["Front width"]}=frontal_width=1=SELECT=&1^#{SUF_STRINGS["Module width"]}&2^#{SUF_STRINGS["Niche width"]}&3^#{SUF_STRINGS["Fixed"]}|#{SUF_STRINGS["Fixed width"]} (#{SUF_STRINGS["mm"]})=frontal_width_input=2000=INPUT|#{SUF_STRINGS["Horizontal position"]}=hor_position=1=SELECT=&1^#{SUF_STRINGS["Left"]}&2^#{SUF_STRINGS["Right"]}|#{SUF_STRINGS["Front height"]}=frontal_height=1=SELECT=&1^#{SUF_STRINGS["Module height"]}&2^#{SUF_STRINGS["Niche height"]}&3^#{SUF_STRINGS["Fixed"]}|#{SUF_STRINGS["Fixed height"]} (#{SUF_STRINGS["mm"]})=frontal_height_input=1600=INPUT|#{SUF_STRINGS["Vertical position"]}=ver_position=1=SELECT=&1^#{SUF_STRINGS["Bottom"]}&2^#{SUF_STRINGS["Top"]}|#{SUF_STRINGS["Front thickness"]}=frontal_thickness=16=INPUT"
				place_frontal(param,view,body,min_x,max_x,lenx,min_z,max_z,lenz)
      end
    end#def
		def place_frontal(param,view,body,min_x,max_x,lenx,min_z,max_z,lenz)
			param = param.split("|")
			frontal_array = param[0..3]
			width = param[4].split("=")[2]
			width_input = param[5].split("=")[2]
			hor_pos = param[6].split("=")[2]
			height = param[7].split("=")[2]
			height_input = param[8].split("=")[2]
			ver_pos = param[9].split("=")[2]
			thickness = param[10].split("=")[2]
			global_param = [width,width_input,hor_pos,height,height_input,ver_pos,thickness]
			if width == "3" && width_input.to_f/25.4 > lenx
				UI.messagebox(SUF_STRINGS["Fixed width must not exceed module width"])
				view.invalidate
				@place_with_control = false
				@model.select_tool(nil)
      end
			if height == "3" && height_input.to_f/25.4 > lenz
				UI.messagebox(SUF_STRINGS["Fixed height must not exceed module height"])
				view.invalidate
				@place_with_control = false
				@model.select_tool(nil)
      end
			@model.start_operation('load_instance', true,false,true)
			@auto_height = 0
			@manual_height = 0
			@gor_count = 0
			@auto_width = 0
			@manual_width = 0
			@ver_count = 0
			frontal_array.each_with_index {|frontal_param,ver_index|
				if frontal_param.split("<=>")[1]
					@ver_count += 1
					if frontal_param.split("<=>")[0] == "auto"
						@auto_height += 1
						else
						@manual_height += frontal_param.split("<=>")[0].to_f/10
          end
					@auto_width = 0
					@manual_width = 0
					@gor_count = 0
					frontal_param.split("<=>")[1..-1].each{|frontal|
						frontal_width = frontal.split(";")[0]
						@gor_count += 1
						if frontal_width == "auto"
							@auto_width += 1
							else
							@manual_width += frontal_width.to_f/10
            end
          }
        end
      }
			@height_from_bottom = 0
			@width_from_left = 0
			ver_index = 0
			frontal_array.reverse.each {|frontal_param|
				if frontal_param.split("<=>")[1]
					ver_index += 1
					frontal_height = frontal_param.split("<=>")[0]
					@width_from_left = 0
					frontal_param.split("<=>")[1..-1].each_with_index{|frontal,gor_index|
						frontal_width = frontal.split(";")[0]
						open = frontal.split(";")[1].to_i+1
						trim_up = frontal.split(";")[2]
						trim_dn = frontal.split(";")[3]
						trim_lf = frontal.split(";")[4]
						trim_rt = frontal.split(";")[5]
						hinge = frontal.split(";")[6]
						local_param = [frontal_height,frontal_width,open,trim_up,trim_dn,trim_lf,trim_rt,hinge]
						new_frontal(ver_index,gor_index+1,body,min_x,max_x,lenx,min_z,max_z,lenz,global_param,local_param)
						if width == "3"
							@width_from_left += (frontal_width=="auto" ? (width_input.to_f/25.4-@manual_width.to_f/2.54)/@auto_width : frontal_width.to_f/25.4)
							else
							@width_from_left += (frontal_width=="auto" ? (lenx-@manual_width.to_f/2.54)/@auto_width : frontal_width.to_f/25.4)
            end
          }
					if height == "3"
						@height_from_bottom += (frontal_height=="auto" ? (height_input.to_f/25.4-@manual_height.to_f/2.54)/@auto_height : frontal_height.to_f/25.4)
						else
						@height_from_bottom += (frontal_height=="auto" ? (lenz-@manual_height.to_f/2.54)/@auto_height : frontal_height.to_f/25.4)
          end
        end
      }
			@model.commit_operation
			view.invalidate
			@placed = true
			@place_with_control = true
			@model.select_tool(nil)
    end#def
		def new_frontal(ver_index,gor_index,body,min_x,max_x,lenx,min_z,max_z,lenz,global_param,local_param)
			t = Geom::Transformation.translation [@width_from_left, 0, @height_from_bottom]
			if @comp.deleted?
        if Sketchup.version_number >= 2110000000
          @comp = @model.definitions.load(@comp_path, allow_newer: true)
          else
          @comp = @model.definitions.load(@comp_path)
        end
      end
			inst = body.definition.entities.add_instance(@comp, t)
			inst.make_unique if inst.definition.count_used_instances > 1
      inst.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if inst.parent.is_a?(Sketchup::ComponentDefinition)
			@inst.erase! if !@inst.deleted?
			hide_objects_in_pages(inst) if @model.pages.count > 0
			set_attribute_with_formula(inst,"point_x","1") if !inst.definition.get_attribute("dynamic_attributes", "_point_x_formula")
			set_attribute_with_formula(inst,"point_z","1")
			trim_x1,trim_x1_formula,trim_x2,trim_x2_formula = trim_x_formula(inst,min_x,max_x,body,lenx)
			trim_z1,trim_z1_formula,trim_z2,trim_z2_formula = trim_z_formula(inst,min_z,max_z,body,lenz)
			set_attribute_with_formula(inst,"open",local_param[2])
			set_attribute_with_formula(body.parent.instances[-1],"b1_f_thickness",global_param[6].to_f/25.4)
      set_attribute_with_formula(inst,"a00_leny",global_param[6].to_f/25.4,'LOOKUP("b1_f_thickness",'+global_param[6]+')')
			inst.definition.set_attribute("dynamic_attributes", "_b1_f_thickness_formulaunits", "CENTIMETERS")
			hinge_z1 = inst.definition.get_attribute("dynamic_attributes", "hinge_z1")
			hinge_z9 = inst.definition.get_attribute("dynamic_attributes", "hinge_z9")
			
			if local_param[0] == "auto"
				if global_param[3] == "3"
					lenz_formula = '('+(global_param[4].to_f/10).to_s+'-'+@manual_height.to_s+')/'+@auto_height.to_s
          else
          lenz_formula = '(LOOKUP("a01_lenz")-'+@manual_height.to_s+')/'+@auto_height.to_s
        end
				else
				lenz_formula = (local_param[0].to_f/10).to_s
      end
			if hinge_z1 && local_param[2].to_i < 3
				inst.definition.set_attribute("dynamic_attributes", "hinge_z1", hinge_z1-(local_param[4].to_f/25.4))
      end
			
			if global_param[3] == "1" # высота модуля
				if @ver_count == ver_index
					trim_z1_formula = 'IF(LOOKUP("handle1_location",1)>1,LOOKUP("handle_frontal_trim",0),'+(local_param[3].to_f/10).to_s+')+'+'IF(LOOKUP("c3_up_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)'
					else
					trim_z1_formula = (local_param[3].to_f/10).to_s
        end
				if ver_index == 1
					if body.parent.get_attribute("dynamic_attributes", "c8_middle_panel")
						trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,LOOKUP("c4_down_size"),LOOKUP("c4_down_size"),0)+'+(local_param[4].to_f/10).to_s
						else
						trim_z2_formula = 'IF(LOOKUP("c4_down_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)+'+(local_param[4].to_f/10).to_s
						if body.parent.get_attribute("dynamic_attributes", "_trim_z2_formula") != 'CHOOSE(c4_plint,0,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size)'
							trim_z2_formula += '+CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))'
            end
          end
					else
					trim_z2_formula = (local_param[4].to_f/10).to_s
        end
				set_len_attribute(inst,"lenz",lenz,lenz_formula,"y1","y2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
				
				elsif global_param[3] == "3" # фиксированная
				if ver_index == 1
					if body.parent.get_attribute("dynamic_attributes", "c8_middle_panel")
						trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,LOOKUP("c4_down_size"),LOOKUP("c4_down_size"),0)+'+(local_param[4].to_f/10).to_s
						else
						trim_z2_formula = 'IF(LOOKUP("c4_down_protrusion_front")>0,LOOKUP("b1_p_thickness"),0)+'+(local_param[4].to_f/10).to_s
          end
					else
					trim_z2_formula = (local_param[4].to_f/10).to_s
        end
				set_len_attribute(inst,"lenz",lenz,lenz_formula,"y1","y2",trim_z1,(local_param[3].to_f/10).to_s,trim_z2,trim_z2_formula)
				
				else # высота ниши
				trim_z1_formula = (local_param[3].to_f/10).to_s
				trim_z2_formula = (local_param[4].to_f/10).to_s
				if @ver_count == ver_index
					trim_z1_formula = 'LOOKUP("b1_p_thickness")+'+(local_param[3].to_f/10).to_s
        end
				if ver_index == 1
					if body.parent.get_attribute("dynamic_attributes", "c8_middle_panel") && body.parent.get_attribute("dynamic_attributes", "c8_middle_panel_z").to_f < (min_z+max_z)/2 # корпус шкафа над полкой
						trim_z2_formula = 'IF(LOOKUP("c8_middle_panel")=1,CHOOSE(LOOKUP("c4_down_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0,0),LOOKUP("c8_middle_panel_z")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+')+'+(local_param[4].to_f/10).to_s
						
						#set_attribute_with_formula(inst,"c2_erase",0,'ERASEIF(LOOKUP("c8_middle_panel")=1)')
						elsif body.parent.get_attribute("dynamic_attributes", "c4_down_panel") 
						if body.parent.get_attribute("dynamic_attributes", "c8_middle_panel") # корпус шкафа под полкой
							trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,LOOKUP("c4_down_size")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',LOOKUP("c4_down_size")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0)+'+(local_param[4].to_f/10).to_s
							elsif body.parent.get_attribute("dynamic_attributes", "_trim_z2_formula") == 'CHOOSE(c4_plint,0,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size)'
							trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("b1_p_thickness"))+'+(local_param[4].to_f/10).to_s
							else # тумба
							trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("b1_p_thickness"))+'+(local_param[4].to_f/10).to_s
            end
						elsif (trim_z2.to_f*25.4+0.01).round == (body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
						trim_z2_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+'+(local_param[4].to_f/10).to_s
          end
        end
				set_len_attribute(inst,"lenz",lenz,lenz_formula,"y1","y2",trim_z1,trim_z1_formula,trim_z2,trim_z2_formula)
				hinge_z_position(inst)
      end
			
			if local_param[1] == "auto"
				if global_param[0] == "3"
					lenx_formula = '('+(global_param[1].to_f/10).to_s+'-'+@manual_width.to_s+')/'+@auto_width.to_s
					else
					lenx_formula = '(LOOKUP("a01_lenx")-'+@manual_width.to_s+')/'+@auto_width.to_s
        end
				else
				lenx_formula = (local_param[1].to_f/10).to_s
      end
			
			if global_param[0] == "1" # ширина модуля
				set_attribute_with_formula(inst,"point_y","3")
				set_len_attribute(inst,"lenx",lenx,lenx_formula,"z1","z2",trim_x1,(local_param[5].to_f/10).to_s,trim_x2,(local_param[6].to_f/10).to_s)
				
				elsif global_param[0] == "3" # фиксированная
				if local_param[7]== "1"
					set_attribute_with_formula(inst,"point_y","3")
					elsif local_param[7]== "2"
					set_attribute_with_formula(inst,"point_y","3")
					else
					set_attribute_with_formula(inst,"point_y","1")
        end
				set_len_attribute(inst,"lenx",lenx,lenx_formula,"z1","z2",trim_x1,(local_param[5].to_f/10).to_s,trim_x2,(local_param[6].to_f/10).to_s)
				
				else # ширина ниши
				set_attribute_with_formula(inst,"point_y","1")
				trim_x1_formula += '+'+(local_param[5].to_f/10).to_s
				trim_x2_formula += '+'+(local_param[6].to_f/10).to_s
				if @gor_count > 1
					if @gor_count == gor_index
						trim_x1_formula = (local_param[5].to_f/10).to_s
						elsif gor_index == 1
						trim_x2_formula = (local_param[6].to_f/10).to_s
						else
						trim_x1_formula = (local_param[5].to_f/10).to_s
						trim_x2_formula = (local_param[6].to_f/10).to_s
          end
        end
				set_len_attribute(inst,"lenx",lenx,lenx_formula,"z1","z2",trim_x1,trim_x1_formula,trim_x2,trim_x2_formula)
				hinge_x_position(inst)
      end
			
			set_attribute_with_formula(inst,"hinge_type",local_param[7])
			
			#_a00_leny_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_leny_formula")
      #set_attribute_with_formula(inst,"a00_leny",@thickness/25.4,_a00_leny_formula)
			Redraw_Components.redraw_entities_with_Progress_Bar([inst],true)
			material_formula(inst,true)
			element_add(inst,false,false)
			@sel.add inst
			Change_Point.place_component(inst)
    end#def
		def hinge_z_position(e)
			name = e.definition.get_attribute("dynamic_attributes", "name", "0")
			if e.definition.name.include?("Hinge") || name.include?("Hinge") || e.definition.name.include?("plate") || name.include?("Планка")
				e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
				if e.get_attribute("dynamic_attributes", "_z_formula") == 'CHOOSE(LOOKUP("open"),LOOKUP(CONCATENATE("hinge_z",ROUND(COPY+1),"z"))+LOOKUP("trim_y2"),LOOKUP(CONCATENATE("hinge_z",ROUND(COPY+1),"z"))+LOOKUP("trim_y2"),LOOKUP("b1_p_thickness")+LOOKUP("trim_y2")-CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),parent!a0_lenz-LOOKUP("b1_p_thickness"))-CHOOSE(parent!point_z,0,parent!a0_lenz/2,parent!a0_lenz)'
					set_formula(e,"z",'CHOOSE(LOOKUP("open"),LOOKUP(CONCATENATE("hinge_z",ROUND(COPY+1),"z"))+LOOKUP("trim_y2"),LOOKUP(CONCATENATE("hinge_z",ROUND(COPY+1),"z"))+LOOKUP("trim_y2"),LOOKUP("b1_p_thickness"),parent!a0_lenz-LOOKUP("b1_p_thickness"))-CHOOSE(parent!point_z,0,parent!a0_lenz/2,parent!a0_lenz)')
					elsif e.get_attribute("dynamic_attributes", "_z_formula") == 'CHOOSE(LOOKUP("open"),LOOKUP("a0_lenz")-LOOKUP("hinge_z9",LOOKUP("hinge_z9"))-LOOKUP("trim_y1"),LOOKUP("a0_lenz")-LOOKUP("hinge_z9",LOOKUP("hinge_z9"))-LOOKUP("trim_y1"),LOOKUP("b1_p_thickness")+LOOKUP("trim_y2")-CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),parent!a0_lenz-LOOKUP("b1_p_thickness"))-CHOOSE(parent!point_z,0,parent!a0_lenz/2,parent!a0_lenz)'
					set_formula(e,"z",'CHOOSE(LOOKUP("open"),LOOKUP("a0_lenz")-LOOKUP("hinge_z9",LOOKUP("hinge_z9"))-LOOKUP("trim_y1"),LOOKUP("a0_lenz")-LOOKUP("hinge_z9",LOOKUP("hinge_z9"))-LOOKUP("trim_y1"),LOOKUP("b1_p_thickness"),parent!a0_lenz-LOOKUP("b1_p_thickness"))-CHOOSE(parent!point_z,0,parent!a0_lenz/2,parent!a0_lenz)')
					elsif e.get_attribute("dynamic_attributes", "_z_formula") == 'LOOKUP("lenz")-LOOKUP("b1_p_thickness")+CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness"))'
					set_formula(e,"z",'LOOKUP("lenz")-LOOKUP("b1_p_thickness")')
        end
				else
				e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent| hinge_z_position(ent) }
      end
    end#def
		def hinge_x_position(e)
			name = e.definition.get_attribute("dynamic_attributes", "name", "0")
			if e.definition.name.include?("Hinge") || name.include?("Hinge") || e.definition.name.include?("plate") || name.include?("Планка")
				e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
				if e.get_attribute("dynamic_attributes", "_x_formula") == 'CHOOSE(Frontal1!open,LOOKUP("b1_p_thickness")-CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),parent!a0_lenx-LOOKUP("b1_p_thickness")+CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),LOOKUP("hinge_z9"),LOOKUP("hinge_z"))-CHOOSE(parent!point_x,0,parent!a0_lenx/2,parent!a0_lenx)'
					set_formula(e,"x",'CHOOSE(Frontal1!open,LOOKUP("b1_p_thickness"),parent!a0_lenx-LOOKUP("b1_p_thickness"),LOOKUP("hinge_z9"),LOOKUP("hinge_z"))-CHOOSE(parent!point_x,0,parent!a0_lenx/2,parent!a0_lenx)')
					elsif e.get_attribute("dynamic_attributes", "_x_formula") == 'CHOOSE(Frontal1!open,LOOKUP("b1_p_thickness")-CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),parent!a0_lenx-LOOKUP("b1_p_thickness")+CHOOSE(cranking,0,LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness")),LOOKUP("a0_lenx")-LOOKUP("hinge_z1"),LOOKUP("hinge_z"))-CHOOSE(parent!point_x,0,parent!a0_lenx/2,parent!a0_lenx)'
					set_formula(e,"x",'CHOOSE(Frontal1!open,LOOKUP("b1_p_thickness"),parent!a0_lenx-LOOKUP("b1_p_thickness"),LOOKUP("a0_lenx")-LOOKUP("hinge_z1"),LOOKUP("hinge_z"))-CHOOSE(parent!point_x,0,parent!a0_lenx/2,parent!a0_lenx)')
        end
				else
				e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent| hinge_x_position(ent) }
      end
    end#def
		def set_formula(e,att,formula)
			e.set_attribute("dynamic_attributes", "_"+att+"_formula", formula)
			e.definition.set_attribute("dynamic_attributes", "_"+att+"_formula", formula)
			e.definition.set_attribute("dynamic_attributes", "_inst__"+att+"_formula", formula)
    end#def
    def calculate_bounding_box(entities)
      bb = Geom::BoundingBox.new
      entities.each { |entity| bb.add(entity.bounds) if entity.respond_to?(:bounds) }
      bb
    end#def
		def read_frontal_param(body)
      bb = calculate_bounding_box(body.definition.entities)
			param = [(bb.width*25.4).round(1),(bb.depth*25.4).round(1)]
			if File.file?( TEMP_PATH+"/SUF/place_frontal.dat")
				path_param = TEMP_PATH+"/SUF/place_frontal.dat"
				else
				path_param = PATH + "/parameters/place_frontal.dat"
      end
			param_file = File.new(path_param,"r")
			content = param_file.readlines
			param_file.close
			content.each{|i| param << i.strip }
			command = "parameters(#{param.inspect})"
			$dlg_frontal.execute_script(command)
    end#def
		def save_frontal_param(param)
			param = param.split("|")
			path_param = TEMP_PATH+"/SUF/place_frontal.dat"
			param_file = File.new(path_param,"w")
			param.each{|i| param_file.puts i }
			param_file.close
    end#def
		def save_HF_param(param)
			path_param = TEMP_PATH+"/SUF/place_HF.dat"
			param_file = File.new(path_param,"w")
			param.each{|i| param_file.puts i }
			param_file.close
    end#def
		def save_drawer_param(param)
			path_param = TEMP_PATH+"/SUF/drawers_place.dat"
			param_file = File.new(path_param,"w")
			param.each{|i| param_file.puts i }
			param_file.close
    end#def
		def set_len_attribute(inst,len,lenx,len_formula,trim_1,trim_2,trim_1_val,trim_1_formula,trim_2_val,trim_2_formula)
			set_attribute_with_formula(inst,"a00_"+len,lenx,len_formula)
			set_attribute_with_formula(inst,len,lenx)
			set_attribute_with_formula(inst,"trim_"+trim_1,trim_1_val,trim_1_formula)
			set_attribute_with_formula(inst,"trim_"+trim_2,trim_2_val,trim_2_formula)
    end#def
		def trim_x_formula(inst,min_x,max_x,new_body,lenx)
			niche_number = 0
			trim_x1 = min_x.to_f - new_body.transformation.origin.x
			trim_x1_formula = nil
			#if min_x != 0
			if new_body.parent.get_attribute("dynamic_attributes", "c2_panel1") # секция с панелями
        if new_body.parent.get_attribute("dynamic_attributes", "c1_panel_position") # секция фронтальная
          trim_x1_formula = "0"
          else
          a0_panel_count = new_body.parent.get_attribute("dynamic_attributes", "a0_panel_count", "1").to_i
          mid = (min_x.to_f + max_x.to_f)/2
          for i in 0..a0_panel_count
            c2_panel_1 = new_body.parent.get_attribute("dynamic_attributes", "c2_panel"+(i).to_s+"z", 0).to_f
            c2_panel_2 = new_body.parent.get_attribute("dynamic_attributes", "c2_panel"+(i+1).to_s+"z", 0).to_f
            trim_x1 = new_body.parent.get_attribute("dynamic_attributes", "trim_x1", 0).to_f
            trim_x2 = new_body.parent.get_attribute("dynamic_attributes", "trim_x2", 0).to_f
            if mid > c2_panel_1+trim_x1 && mid < c2_panel_2+trim_x1
              niche_number = i
            end
          end
          set_attribute_with_formula(inst,"c2_number",niche_number.to_s)
          set_attribute_with_formula(inst,"c2_erase",0,'ERASEIF(c2_number>LOOKUP("a0_panel_count"))')
          for i in 0..niche_number
            if trim_x1_formula
              trim_x1_formula += '+LOOKUP("c2_panel'+i.to_s+'")+LOOKUP("b1_p_thickness")'
              else
              trim_x1_formula = 'LOOKUP("c2_panel'+i.to_s+'z")'
            end
          end
        end
				elsif new_body.parent.get_attribute("dynamic_attributes", "c2_shelve1") # секция с полками
				trim_x1 = 0
				
				elsif new_body.parent.get_attribute("dynamic_attributes", "c1_left_panel") # корпус шкафа
				if new_body.parent.get_attribute("dynamic_attributes", "c1_left_panel", "4").to_i == 4 && min_x != 0
					if (trim_x1.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
						trim_x1_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_left_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')
						else
						trim_x1_formula = trim_x1
          end
					else
					trim_x1_formula = 'CHOOSE(LOOKUP("c1_left_panel"),0,LOOKUP("b1_p_thickness"),0,0)'
        end
				
				elsif new_body.parent.get_attribute("dynamic_attributes", "c4_down_x1_offset") # тумба
				trim_x1_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_left_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("c4_down_x1_offset",0)'
				
				elsif (trim_x1.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
				trim_x1_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_left_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("c4_down_x1_offset",0)'
      end
      #end
			
			trim_x2 = lenx - max_x.to_f
			trim_x2_formula = nil
			#if max_x.to_f != lenx
			if new_body.parent.get_attribute("dynamic_attributes", "c2_panel1") # секция с панелями
        if new_body.parent.get_attribute("dynamic_attributes", "c1_panel_position") # секция фронтальная
          trim_x2_formula = "0"
          else
          a0_panel_count = new_body.parent.get_attribute("dynamic_attributes", "a0_panel_count", "1").to_i
          if niche_number==a0_panel_count
            trim_x2 = 0
            else
            last_niche_len_formula = '+(LOOKUP("a01_lenx")'
            for i in 0..a0_panel_count
              if i != a0_panel_count
                last_niche_len_formula += '-LOOKUP("c2_panel'+(i+1).to_s+'")'
                if i > niche_number
                  if trim_x2_formula
                    trim_x2_formula += '+LOOKUP("c2_panel'+(i+1).to_s+'")'
                    else
                    trim_x2_formula = 'LOOKUP("c2_panel'+(i+1).to_s+'")'
                  end
                end
              end
            end
            # ширина последней ниши
            if trim_x2_formula
              trim_x2_formula += last_niche_len_formula+')'
              else
              trim_x2_formula = last_niche_len_formula+')'
            end
            trim_x2_formula += '-LOOKUP("b1_p_thickness")*'+(niche_number).to_s
          end
        end
				elsif new_body.parent.get_attribute("dynamic_attributes", "c2_shelve1") # секция с полками
				trim_x2 = 0
				elsif new_body.parent.get_attribute("dynamic_attributes", "c2_right_panel") # корпус шкафа
				if new_body.parent.get_attribute("dynamic_attributes", "c2_right_panel", "4").to_i == 4 && max_x.to_f != lenx
					if (trim_x2.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
						trim_x2_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_right_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')
						else
						trim_x2_formula = trim_x2
          end
					else
					trim_x2_formula = 'CHOOSE(LOOKUP("c2_right_panel"),0,LOOKUP("b1_p_thickness"),0,0)'
        end
				elsif new_body.parent.get_attribute("dynamic_attributes", "c4_down_x2_offset") # тумба
				trim_x2_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_right_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("c4_down_x2_offset",0)'
				elsif (trim_x2.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
				trim_x2_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_panel_right_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("c4_down_x2_offset",0)'
      end
			#end
			return trim_x1,(trim_x1_formula ? trim_x1_formula : "0"),trim_x2,(trim_x2_formula ? trim_x2_formula : "0")
    end#def
		def trim_y_formula(inst,min_y,max_y,new_body,leny)
			trim_y1 = min_y.to_f
			trim_y1_formula = nil
      if !inst.definition.name.include?("купе")
        if new_body.parent.get_attribute("dynamic_attributes", "c8_middle_trim")
          trim_y1_formula = 'LOOKUP("c8_middle_trim")'
          elsif new_body.parent.get_attribute("dynamic_attributes", "c1_panel_position")
          trim_y1_formula = 'CHOOSE(LOOKUP("c1_panel_position"),LOOKUP("b1_p_thickness"),0,0)'
        end
      end
			trim_y2 = 0
			trim_y2_formula = nil
			if max_y.to_f != leny
				trim_y2 = leny - max_y.to_f
				if new_body.parent.get_attribute("dynamic_attributes", "c2_panel1") || new_body.parent.get_attribute("dynamic_attributes", "c2_shelve1")
					trim_y1 = 0
					trim_y2 = 0
          if new_body.parent.get_attribute("dynamic_attributes", "c1_panel_position")
            trim_y2_formula = 'CHOOSE(LOOKUP("c1_panel_position"),0,LOOKUP("a01_leny")/2+LOOKUP("b1_p_thickness")/2,LOOKUP("b1_p_thickness"))'
          end
					else
					if new_body.parent.get_attribute("dynamic_attributes", "c5_back")
						trim_y2_formula = 'CHOOSE(LOOKUP("c5_back",2),0,0,LOOKUP("c5_back_dist_r",1.6)+LOOKUP("b1_p_thickness",0.4),LOOKUP("c5_back_dist_r",1.6)+LOOKUP("c5_back_thick",0.4),LOOKUP("c5_back_thick",0.4))'
          end
        end
      end
			return trim_y1,(trim_y1_formula ? trim_y1_formula : "0"),trim_y2,(trim_y2_formula ? trim_y2_formula : "0")
    end#def
		def trim_z_formula(inst,min_z,max_z,new_body,lenz)
			niche_number = 0
			trim_z2 = 0 # снизу
			trim_z2_formula = nil
			#if min_z != 0
			trim_z2 = min_z.to_f
			if new_body.parent.get_attribute("dynamic_attributes", "c2_panel1") # секция с панелями
        trim_z2 = 0
        elsif new_body.parent.get_attribute("dynamic_attributes", "c2_shelve1") # секция с полками
        a0_shelves_count = new_body.parent.get_attribute("dynamic_attributes", "a0_shelves_count", "1").to_i
        mid = (min_z.to_f + max_z.to_f)/2
        for i in 0..a0_shelves_count
          c2_shelve_1 = new_body.parent.get_attribute("dynamic_attributes", "c2_shelve"+(i).to_s+"z", 0).to_f
          c2_shelve_2 = new_body.parent.get_attribute("dynamic_attributes", "c2_shelve"+(i+1).to_s+"z", 0).to_f
          trim_z1 = new_body.parent.get_attribute("dynamic_attributes", "trim_z1", 0).to_f
          trim_z2 = new_body.parent.get_attribute("dynamic_attributes", "trim_z2", 0).to_f
          if 1==12
            p 11111111111111111
            p mid
            p 22222222222222222
            p i
            p 33333333333333333
            p c2_shelve_1
            p 44444444444444444
            p c2_shelve_2
            p 55555555555555555
            p c2_shelve_1+trim_z2
            p 66666666666666666
            p c2_shelve_2+trim_z2
            p 77777777777777777
          end
          if mid > c2_shelve_1+trim_z2 && mid < c2_shelve_2+trim_z2
            niche_number = i
          end
        end
        set_attribute_with_formula(inst,"c2_number",niche_number.to_s)
        set_attribute_with_formula(inst,"c2_erase",0,'ERASEIF(c2_number>LOOKUP("a0_shelves_count"))')
        for i in 0..niche_number
          if trim_z2_formula
            trim_z2_formula += '+LOOKUP("c2_shelve'+i.to_s+'")+LOOKUP("b1_p_thickness")'
            else
            trim_z2_formula = 'LOOKUP("c2_shelve'+i.to_s+'z")'
          end
        end
        
        elsif new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel") && new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel_z").to_f < (min_z+max_z)/2 # корпус шкафа над полкой
        trim_z2_formula = 'IF(LOOKUP("c8_middle_panel")=1,CHOOSE(LOOKUP("c4_down_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0,0),LOOKUP("c8_middle_panel_z")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+')'
        
        #set_attribute_with_formula(inst,"c2_erase",0,'ERASEIF(LOOKUP("c8_middle_panel")=1)')
        elsif new_body.parent.get_attribute("dynamic_attributes", "c4_down_panel") 
        if new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel") # корпус шкафа под полкой
          trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,LOOKUP("c4_down_size")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',LOOKUP("c4_down_size")+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0)'
          elsif new_body.parent.get_attribute("dynamic_attributes", "_trim_z2_formula") == 'CHOOSE(c4_plint,0,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size,c4_plint_size)'
          trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("b1_p_thickness"))'
          else # тумба
          trim_z2_formula = 'CHOOSE(LOOKUP("c4_down_panel"),0,CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',CHOOSE(LOOKUP("c4_plint"),0,LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"),LOOKUP("c4_plint_size"))+'+(@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("b1_p_thickness"))'
        end
        elsif (trim_z2.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
        trim_z2_formula = (@body_and_level.length==1 ? 'LOOKUP("c4_down_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')
      end
			#end
			
			trim_z1 = 0 # сверху
			trim_z1_formula = nil
			#if max_z.to_f != lenz
			trim_z1 = lenz - max_z.to_f
			if new_body.parent.get_attribute("dynamic_attributes", "c2_panel1") # секция с панелями
				trim_z1 = 0
				elsif new_body.parent.get_attribute("dynamic_attributes", "c2_shelve1") # секция с полками
				a0_shelves_count = new_body.parent.get_attribute("dynamic_attributes", "a0_shelves_count", "1").to_i
				if niche_number==a0_shelves_count
					trim_z1 = 0
					else
					last_niche_len_formula = '+(LOOKUP("a01_lenz")'
					for i in 0..a0_shelves_count
						if i != a0_shelves_count
							last_niche_len_formula += '-LOOKUP("c2_shelve'+(i+1).to_s+'")'
							if i > niche_number
								if trim_z1_formula
									trim_z1_formula += '+LOOKUP("c2_shelve'+(i+1).to_s+'")'
									else
									trim_z1_formula = 'LOOKUP("c2_shelve'+(i+1).to_s+'")'
                end
              end
            end
          end
					# высота последней ниши
					if trim_z1_formula
						trim_z1_formula += last_niche_len_formula+')'
						else
						trim_z1_formula = last_niche_len_formula+')'
          end
					trim_z1_formula += '-LOOKUP("b1_p_thickness")*'+(niche_number).to_s
        end
				elsif new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel") && new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel_z").to_f > (min_z+max_z)/2 # корпус шкафа
				if inst.definition.name.include?("купе")
          trim_z1_formula = 'CHOOSE(LOOKUP("c3_up_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0,0)'
          else
          trim_z1_formula = 'IF(LOOKUP("c8_middle_panel")=1,CHOOSE(LOOKUP("c3_up_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0,0),LOOKUP("a01_lenz")-LOOKUP("c8_middle_panel_z"))'
        end
				elsif new_body.parent.get_attribute("dynamic_attributes", "c3_up_panel") # тумба
				if new_body.parent.get_attribute("dynamic_attributes", "c8_middle_panel")
					trim_z1_formula = 'CHOOSE(LOOKUP("c3_up_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+',0,0)'
					else
					trim_z1_formula = 'CHOOSE(LOOKUP("c3_up_panel"),0,'+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+','+(@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')+'+LOOKUP("b1_p_thickness"))'
        end
				elsif (trim_z1.to_f*25.4+0.01).round == (new_body.parent.get_attribute("dynamic_attributes", "b1_p_thickness", 1.6/25.4).to_f*25.4+0.01).round
				trim_z1_formula = (@body_and_level.length==1 ? 'LOOKUP("c3_up_panel_thickness",LOOKUP("b1_p_thickness"))' : 'LOOKUP("b1_p_thickness")')
      end
			#end
			return trim_z1,(trim_z1_formula ? trim_z1_formula : "0"),trim_z2,(trim_z2_formula ? trim_z2_formula : "0")
    end#def
		def material_formula(instance,redraw=false)
			su_type = instance.definition.get_attribute("dynamic_attributes", "su_type", "0")
			b1_p_material = instance.definition.get_attribute("dynamic_attributes", "b1_p_material")
			instance.definition.set_attribute("dynamic_attributes", "_b1_p_material_formula", 'LOOKUP("b1_p_material","'+b1_p_material+'")') if b1_p_material
			if su_type == "carcass"
				instance.definition.set_attribute("dynamic_attributes", "_material_formula", 'LOOKUP("b1_p_material")')
				instance.definition.set_attribute("dynamic_attributes", "_a00_mat_krom_formula", 'LOOKUP("b1_p_material")')
				instance.definition.set_attribute("dynamic_attributes", "_back_material_formula", 'LOOKUP("b1_p_material")')
				if !instance.hidden?
					instance_material = Redraw_Components.get_formula_result(instance,'material')
					instance_material = instance.material.display_name if !instance_material && instance.material
					if instance_material
						Redraw_Components.set_attribute(instance,'material',instance_material)
						if !@model.materials.any?{|mat|mat.display_name == instance_material}
							type_material,file_name = SU_Furniture::Report_lists.search(instance_material,["LDSP","LMDF"])
							if file_name
								new_mat= @model.materials.add instance_material
								new_mat.texture= file_name
								if new_mat.texture
									mat_width= new_mat.texture.image_width
									mat_height= new_mat.texture.image_height
									new_mat.texture.size= [mat_width.to_f.mm, mat_height.to_f.mm]
                end
              end
            end
						if @model.materials.any?{|mat|mat.display_name == instance_material}
							instance.material = instance_material
							type_material,file_name = SU_Furniture::Report_lists.search(instance.material.display_name,["LDSP","LMDF"])
							if type_material
								instance.set_attribute("dynamic_attributes", "type_material", type_material)
								instance.definition.set_attribute("dynamic_attributes", "type_material", type_material)
								instance.definition.set_attribute("dynamic_attributes", "type_material", type_material)
              end
							redraw_essence(instance,instance_material) if redraw
            end
          end
        end
				elsif su_type == "frontal"
				#instance.definition.set_attribute("dynamic_attributes", "_material_formula", 'LOOKUP("b1_f_material")')
				instance.definition.set_attribute("dynamic_attributes", "_a00_mat_krom_formula", 'LOOKUP("b1_f_material",Material)')
				instance.definition.set_attribute("dynamic_attributes", "_back_material_formula", 'CHOOSE(LOOKUP("back_material_input",back_material_input),"White",Material,"White")')
				instance.definition.set_attribute("dynamic_attributes", "_drawer_height_access", "LIST")
				instance.definition.set_attribute("dynamic_attributes", "_drawer_height_options", '&1=1&2=2&3=3&4=4&5=5&')
				instance.definition.set_attribute("dynamic_attributes", "_drawer_height_formlabel", 'Высота ящика')
				instance.definition.set_attribute("dynamic_attributes", "_drawer_height_formulaunits", 'FLOAT')
				instance.definition.set_attribute("dynamic_attributes", "_drawer_height_units", 'STRING')
				set_attribute_with_formula(instance,"drawer_height",'3','SETLEN("d1_type_height",IF(a01_lenz>23.6,5,IF(a01_lenz>20,3,IF(a01_lenz>14.3,2,1))),1)') if !instance.definition.get_attribute("dynamic_attributes", "drawer_height")
				if !instance.hidden?
					instance_material = Redraw_Components.get_formula_result(instance,'material')
					instance_material = instance.material.display_name if !instance_material && instance.material
					if instance_material
						Redraw_Components.set_attribute(instance,'material',instance_material)
						if !@model.materials.any?{|mat|mat.display_name == instance_material}
							type_material,file_name = SU_Furniture::Report_lists.search(instance_material,["MDF","COLOR","PLASTIC","LDSP","LMDF"])
							if file_name
								new_mat= @model.materials.add instance_material
								new_mat.texture= file_name
								if new_mat.texture
									mat_width= new_mat.texture.image_width
									mat_height= new_mat.texture.image_height
									new_mat.texture.size= [mat_width.to_f.mm, mat_height.to_f.mm]
                end
              end
            end
						if @model.materials.any?{|mat|mat.display_name == instance_material}
							instance.material = instance_material
							type_material,file_name = SU_Furniture::Report_lists.search(instance.material.display_name,["MDF","COLOR","PLASTIC","LDSP","LMDF"])
							if type_material
								instance.set_attribute("dynamic_attributes", "type_material", type_material)
								instance.definition.set_attribute("dynamic_attributes", "type_material", type_material)
								instance.definition.set_attribute("dynamic_attributes", "_type_material_label", "type_material")
              end
							redraw_essence(instance,instance_material) if redraw
            end
          end
        end
				else
				instance_material = Redraw_Components.get_formula_result(instance,'material')
				instance_material = instance.material.display_name if !instance_material && instance.material
				Redraw_Components.set_attribute(instance,'material',instance_material) if instance_material
				instance.definition.delete_attribute("dynamic_attributes", "_d1_type_height_formula") if instance.definition.get_attribute("dynamic_attributes", "_d1_type_height_formula")
				instance.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| material_formula(entity,redraw) }
      end
    end#def
		def redraw_essence(entity,mat_name)
			entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
				if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
					ent.material = mat_name
					edge_label = ent.definition.get_attribute("dynamic_attributes", "edge_label")
					if edge_label
						ent.definition.set_attribute("dynamic_attributes", "_edge_label_formula", 'EDGEMAT(IF(AND(LOOKUP("edge_y1")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_y1_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_y2")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_y2_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_z1")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_z1_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_z2")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_z2_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))))')
          end
					ent.definition.entities.grep(Sketchup::Face).each { |f| f.material = nil }
					Redraw_Components.run_all_formulas(ent)
					elsif ent.layer.name.include?("Фасад_открывание")
					Redraw_Components.redraw(ent,false)
					elsif ent.definition.name.include?("Body")
					redraw_essence(ent,mat_name)
        end
      }
    end#def
		def element_add(entity,intersect=true,auto_dimension=true)
			Intersect_Components.intersect_bound(@model.entities, entity, @point_x_offset, @point_y_offset, @point_z_offset) if intersect && @intersect == "yes"
			Dimensions.place_component_with_dimension(@model.entities,entity,"added",@auto_dimension) if auto_dimension
			set_attribute_with_formula(entity,"b2_open",'5') if entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module" && !entity.definition.get_attribute("dynamic_attributes", "b2_open")
    end#def
		def delete_hidden_components(ent)
			@hidden_objects = []
			ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hidden_components(e) }
			if @hidden_objects != []
				@hidden_objects.each { |e| e.erase! }
      end
    end#def
		def hidden_components(ent)
			@hidden_objects << ent if ent.hidden?
			ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| hidden_components(e) }
    end#def
		def make_body_faces(e,body,bb,a)
			pts = [bb.corner(a[0]),bb.corner(a[1]),bb.corner(a[2]),bb.corner(a[3])]
			f = e.definition.entities.add_face(pts.map{|pt|pt.transform(body.transformation)})
			f_center = f.bounds.center
			if f.normal.x == -1 && f_center.x < bb.center.x || f.normal.x == 1 && f_center.x > bb.center.x
				f.reverse!
				elsif f.normal.y == -1 && f_center.y < bb.center.y
				f.reverse!
				elsif f.normal.z == -1 && f_center.z < bb.center.z || f.normal.z == 1 && f_center.z > bb.center.z
				f.reverse!
      end
			f.material = "onClick"
			f.back_material = "onClick"
    end#def
		def onKeyDown(key, repeat, flags, view)
			if key==VK_SHIFT 
				@shift_press=true
				elsif key==VK_CONTROL || key==VK_COMMAND
				@control_press=true
				#@model.start_operation('make_body_faces', true,false,true)
				@model.active_entities.grep(Sketchup::ComponentInstance).each { |e|
					if !@inst.definition.instances.index(e) && !e.deleted? && e.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module"
						body = e.definition.entities.grep(Sketchup::ComponentInstance).find { |body_ent| body_ent.definition.name.include?("Body") }
						if body
						  bb = Geom::BoundingBox.new
							body.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
								bb.add ent.bounds if ent.definition.get_attribute("dynamic_attributes", "animation", "0").to_s == "0"
              }
							make_body_faces(e,body,bb,[0,1,3,2])
							make_body_faces(e,body,bb,[0,2,6,4])
							make_body_faces(e,body,bb,[7,6,4,5])
							make_body_faces(e,body,bb,[7,5,1,3])
							make_body_faces(e,body,bb,[7,6,2,3])
            end
          end
        }
				#@model.commit_operation
				view.invalidate
      end
    end#def
		def onKeyUp(key, repeat, flags, view)
			if key==VK_SHIFT
				UI.start_timer(0.1, false) { @shift_press=false }
				view.lock_inference if view.inference_locked?
				elsif key==VK_CONTROL || key==VK_COMMAND
				UI.start_timer(0.1, false) {
					@control_press=false
					@sel.clear
					@sel.add @inst if @inst && !@inst.deleted?
					view.invalidate
        }
				view.lock_inference if view.inference_locked?
				elsif ( key==9 || ((key==15 || key==48) && (OSX)))
				if @point_y_offset
					change_point(@inst,"point_y",3)
					elsif @point_x_offset || @trim_x1 || @trim_x2
					change_point(@inst,"point_x",3)
					elsif @point_z_offset
					change_point(@inst,"point_z",3)
        end
				elsif key==VK_LEFT && @control_press != true
				if @shift_press == true
					if @point_x_offset || @point_y_offset
						change_trim(@inst,"trim_z1",@len)
						elsif @point_z_offset
						change_trim(@inst,"trim_y2",@len)
						elsif @trim_x1 || @trim_x2
						change_trim(@inst,"trim_x1",@len)
          end
					else
					if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
						change_point(@inst,"point_y",3)
          end
        end
				elsif key==VK_RIGHT && @control_press != true
				if @shift_press == true
					if @point_x_offset || @point_y_offset
						change_trim(@inst,"trim_z2",@len)
						elsif @point_z_offset
						change_trim(@inst,"trim_y1",@len)
						elsif @trim_x1 || @trim_x2
						change_trim(@inst,"trim_x2",@len)
          end
					else
					if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
						change_point(@inst,"point_x",3)
          end
        end
				elsif key==VK_UP && @control_press != true
				if @shift_press == true
					if @point_x_offset || @point_y_offset
						change_trim(@inst,"trim_y1",@len)
						elsif @point_z_offset
						change_trim(@inst,"trim_z2",@len)
						elsif @trim_x1 || @trim_x2
						change_trim(@inst,"trim_z1",@len)
          end
					else
					if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
						change_point(@inst,"point_z",3)
          end
        end
				elsif key==VK_DOWN && @control_press != true
				if @shift_press == true
					if @point_x_offset || @point_y_offset
						change_trim(@inst,"trim_y2",@len)
						elsif @point_z_offset
						change_trim(@inst,"trim_z1",@len)
						elsif @trim_x1 || @trim_x2
						change_trim(@inst,"trim_z2",@len)
          end
					else
					if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
						change_point(@inst,"point_z",3)
          end
        end
				elsif OSX && key==61 || !OSX && key==107 || !OSX && key==187
				if @trim_x1 || @trim_x2
					if @a0_door_count
						@a0_door_count = change_count(@inst,@a0_door_count,"a0_door_count",5)
						elsif @a0_shelves_count
						@a0_shelves_count = change_count(@inst,@a0_shelves_count,"a0_shelves_count",12)
						elsif @a0_panel_count
						@a0_panel_count = change_count(@inst,@a0_panel_count,"a0_panel_count",12)
						elsif @a0_drawer_count
						@a0_drawer_count = change_count(@inst,@a0_drawer_count,"a0_drawer_count",5)
          end
        end
				elsif OSX && key==45 || !OSX && key==109 || !OSX && key==189
				if @trim_x1 || @trim_x2
					if @a0_door_count
						@a0_door_count = change_count(@inst,@a0_door_count,"a0_door_count",1)
						elsif @a0_shelves_count
						@a0_shelves_count = change_count(@inst,@a0_shelves_count,"a0_shelves_count",1)
						elsif @a0_panel_count
						@a0_panel_count = change_count(@inst,@a0_panel_count,"a0_panel_count",1)
						elsif @a0_drawer_count
						@a0_drawer_count = change_count(@inst,@a0_drawer_count,"a0_drawer_count",1)
          end
        end
      end
    end#def
		def onCancel(reason, view)
			puts "Cancel reason: #{reason}"
			@canceled = true
			if reason == 2
				@model.abort_operation
				@model.start_operation "clear", true, false, true
				@inst.erase! if !@inst.deleted?
				#@model.definitions.purge_unused if @purge_unused == "yes"
				@model.layers.each { |l|
					l.visible = false if l.name.include?("Габаритная_рамка") || l.name.include?("Направляющие")
					l.visible = true if l.name.include?("Фасад_открывание")
        }
				@visible_layer.each_pair { |l,v| l.visible = v if !l.deleted? } if @visible_layer
				@model.commit_operation
				@model.layers.add_observer $SUFLayersObserver
				if SU_Furniture.observers_state == 1
					@sel.add_observer $SUFSelectionObserver
					@model.entities.add_observer $SUFEntitiesObserver
					UI.start_timer(0.9, false) { @model.tools.add_observer($SUFToolsObserver) }
        end
      end
			@model.select_tool(nil)
    end#def
		def enableVCB?
			return true
    end#def
		def onUserText(text, view)
			thickness = text.to_i
			if @point_y_offset
				@model.start_operation "thickness", true, false, true
				@inst.set_attribute("dynamic_attributes", "a00_leny", thickness/25.4)
				@inst.definition.set_attribute("dynamic_attributes", "a00_leny", thickness/25.4)
				_a00_leny_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_leny_formula")
				if _a00_leny_formula
					if _a00_leny_formula.include?(","+(@thickness.to_f/10).to_s)
						@inst.definition.set_attribute("dynamic_attributes", "_a00_leny_formula", _a00_leny_formula.gsub(","+(@thickness.to_f/10).to_s,","+(thickness.to_f/10).to_s))
          end
        end
				Redraw_Components.redraw_entities_with_Progress_Bar([@inst])
				@model.commit_operation
				elsif @point_x_offset
				@model.start_operation "thickness", true, false, true
				@inst.set_attribute("dynamic_attributes", "a00_lenx", thickness/25.4)
				@inst.definition.set_attribute("dynamic_attributes", "a00_lenx", thickness/25.4)
				_a00_lenx_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_lenx_formula")
				if _a00_lenx_formula
					if _a00_lenx_formula.include?(","+(@thickness.to_f/10).to_s)
						@inst.definition.set_attribute("dynamic_attributes", "_a00_lenx_formula", _a00_lenx_formula.gsub(","+(@thickness.to_f/10).to_s,","+(thickness.to_f/10).to_s))
          end
        end
				Redraw_Components.redraw_entities_with_Progress_Bar([@inst])
				@model.commit_operation
				elsif @point_z_offset
				@model.start_operation "thickness", true, false, true
				@inst.set_attribute("dynamic_attributes", "a00_lenz", thickness/25.4)
				@inst.definition.set_attribute("dynamic_attributes", "a00_lenz", thickness/25.4)
				_a00_lenz_formula = @inst.definition.get_attribute("dynamic_attributes", "_a00_lenz_formula")
				if _a00_lenz_formula
					if _a00_lenz_formula.include?(","+(@thickness.to_f/10).to_s)
						@inst.definition.set_attribute("dynamic_attributes", "_a00_lenz_formula", _a00_lenz_formula.gsub(","+(@thickness.to_f/10).to_s,","+(thickness.to_f/10).to_s))
          end
        end
				Redraw_Components.redraw_entities_with_Progress_Bar([@inst])
				@model.commit_operation
      end
			@thickness = thickness
			rescue ArgumentError
			view.tooltop = 'Invalid length'
    end#def
		def change_point(ent,point,max_value)
			point_value = ent.definition.get_attribute("dynamic_attributes", point).to_i
			@model.start_operation "change_point", true, false, true
			new_value= (point_value==max_value ? 1 : point_value+1)
			set_attribute_with_formula(ent, point, new_value)
			Redraw_Components.redraw_entities_with_Progress_Bar([ent])
			@model.commit_operation
    end#def
		def change_trim(ent,trim,len)
			@model.start_operation "change_trim", true, false, true
			trim_value = ent.definition.get_attribute("dynamic_attributes", trim).to_f
			len_value = ent.definition.get_attribute("dynamic_attributes", len).to_f
			if trim_value.to_s == "0.0" 
				set_attribute_with_formula(ent, trim, len_value, len)
				else 
				set_attribute_with_formula(ent, trim, 0.0)
      end
			Redraw_Components.redraw_entities_with_Progress_Bar([ent])
			@model.commit_operation
    end#def
		def change_count(ent,count,att,max_value)
			@model.start_operation "change_count", true, false, true
			if max_value == 1
				new_count= (count.to_i==1) ? 1 : (count.to_i-1)
				else
				new_count= (count.to_i==max_value) ? max_value : (count.to_i+1)
      end
			set_attribute_with_formula(ent,att,new_count)
			Redraw_Components.redraw_entities_with_Progress_Bar([ent])
			count = new_count
			@model.commit_operation
			return count
    end#def
		def set_attribute_with_formula(entity,attribute,value,formula=nil,formulaunits=nil,units=nil)
			entity.set_attribute("dynamic_attributes", attribute, value)
			entity.definition.set_attribute("dynamic_attributes", attribute, value)
			entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_label", attribute)
			entity.definition.delete_attribute("dynamic_attributes", "_"+attribute+"_formula") if attribute != "lenx" && attribute != "leny" && attribute != "lenz"
			entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_formula", formula) if formula && formula != ""
      entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_formulaunits", formulaunits) if formulaunits
      entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_units", units) if units
    end#def
  end # Class
end
