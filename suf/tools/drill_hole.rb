module SU_Furniture
  class DrillHole
    def initialize()
      @text_size = (OSX ? 20 : 13)
      @circle_text_size = (OSX ? 27 : 22)
      @x_offset = (OSX ? 30 : 0)
      @y_offset = (OSX ? 10 : 0)
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
      @line_black_bold_center_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignCenter,
        bold: true
			}
      @active_diameter = 5
      @hole_depth = 13
      @type_hole = "yes"
			@fastener_dimension = "no"
      @hole_color = "gray"
		end#def
    def activate
      @model=Sketchup.active_model
      @sel=@model.selection
      @sel.remove_observer $SUFSelectionObserver
      read_param
      read_draw_param
      @sel.clear
      view = @model.active_view
      @ents = @model.entities
      @ip=Sketchup::InputPoint.new
      @ip1=Sketchup::InputPoint.new
      @diameter_array = [2,2.5,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65]
      @fastener_layer = @model.layers.add "Z_fastener"
      @tr = Geom::Transformation.new
      @blue = Sketchup::Color.new(0, 50, 100, 70)
      @screen_x=0
      @screen_y=0
      @button_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignRight
			}
      self.reset(view)
		end#def
    def import_essence_and_transformation(essence_and_transformation)
      @essence_and_transformation = essence_and_transformation
		end#def
    def read_param
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
			end
      content = File.readlines(path_param)
      content.each_with_index { |i,index|
				@type_hole = i.split("=")[2] if i.split("=")[1] == "type_hole" 
				@fastener_dimension = i.split("=")[2] if i.split("=")[1] == "fastener_dimension"
			}
      if File.file?( TEMP_PATH+"/SUF/hole_color.dat")
        path_param = TEMP_PATH+"/SUF/hole_color.dat"
        else
        path_param = PATH + "/parameters/hole_color.dat"
			end
      content = File.readlines(path_param)
      @hole_color = content[0].split(",").map(&:to_i)
			if File.file?( TEMP_PATH+"/SUF/hole_list.dat")
        path_param = TEMP_PATH+"/SUF/hole_list.dat"
        else
        path_param = PATH + "/parameters/hole_list.dat"
			end
      content = File.readlines(path_param)
      @diameter_array = content[0].split(",").map{|x|x.to_f}
		end#def
    def read_draw_param
      @draw_param = []
      if File.file?( TEMP_PATH+"/SUF/draw_options.dat")
        path = TEMP_PATH+"/SUF/draw_options.dat"
        else
        path = PATH + "/parameters/draw_options.dat"
			end
      file = File.new(path,"r")
      content = file.readlines
      file.close
      content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
      content.each { |i| @draw_param << i }
		end#def
    def deactivate(view)
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
			end
      view.invalidate
		end#def
    def draw_text(view, position, text, options)
      native_options = options.dup
      if IS_WIN && options.key?(:size)
        native_options[:size] = pix_pt(options[:size])
			end
      view.draw_text(position, text, native_options)
		end#def
    def pix_pt(pixels)
      ((pixels.to_f / 96.0) * 72.0).round
		end#def
    def draw(view)
		  view.drawing_color = "orange"
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(31+@x_offset, 26, 0), Geom::Point3d.new(99+@x_offset, 26, 0), Geom::Point3d.new(99+@x_offset, pix_pt(63)+@y_offset, 0), Geom::Point3d.new(31+@x_offset, pix_pt(63)+@y_offset, 0) ])
      @change_diameter = false
      if @screen_x > 30+@x_offset && @screen_x < 100+@x_offset && @screen_y > 25 && @screen_y < 60
        view.drawing_color = "black"
        @change_diameter = true
        else
        view.drawing_color = "gray"
			end
      view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(30+@x_offset, 25, 0), Geom::Point3d.new(100+@x_offset, 25, 0), Geom::Point3d.new(100+@x_offset, pix_pt(64)+@y_offset, 0), Geom::Point3d.new(30+@x_offset, pix_pt(64)+@y_offset, 0) ])
      draw_text(view,Geom::Point3d.new(36, 27, 0), SUF_STRINGS["Diameter"], @text_default_options)
			
      view.drawing_color = @hole_color
      view.draw2d(GL_QUADS, [ Geom::Point3d.new(111+@x_offset, 26, 0), Geom::Point3d.new(179+@x_offset, 26, 0), Geom::Point3d.new(179+@x_offset, pix_pt(63)+@y_offset, 0), Geom::Point3d.new(111+@x_offset, pix_pt(63)+@y_offset, 0) ])
      @change_color = false
      if @screen_x > 110+@x_offset && @screen_x < 180+@x_offset && @screen_y > 25 && @screen_y < 60
        view.drawing_color = "black"
        @change_color = true
        else
        view.drawing_color = "gray"
			end
      view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(110+@x_offset, 25, 0), Geom::Point3d.new(180+@x_offset, 25, 0), Geom::Point3d.new(180+@x_offset, pix_pt(64)+@y_offset, 0), Geom::Point3d.new(110+@x_offset, pix_pt(64)+@y_offset, 0) ])
      draw_text(view,Geom::Point3d.new(130+@x_offset, 27, 0), SUF_STRINGS["Color"], @text_default_options)
      y = 55
      @selection_hole = 0
      @diameter_array.each { |key|
        if @active_diameter == key
          draw_text(view,Geom::Point3d.new(35, y, 0), "•", @circle_active_options)
          draw_text(view,Geom::Point3d.new(50, y+6, 0), key.to_s.sub(/(?:(\..*[^0])0+|\.0+)$/, '\1'), @text_active_options)
          else
          if @screen_x > 20 && @screen_x < 50 && @screen_y > y && @screen_y < y+30+@y_offset
            @circle = "○"
            @selection_hole = key
            else
						@circle = "•"
					end
          draw_text(view,Geom::Point3d.new(35, y, 0), @circle, @circle_default_options)
          draw_text(view,Geom::Point3d.new(50, y+6, 0), key.to_s.sub(/(?:(\..*[^0])0+|\.0+)$/, '\1'), @text_default_options)
				end
				y += 25+@y_offset
			}
			draw_text(view,Geom::Point3d.new(view.vpwidth/2, 25, 0), "#{SUF_STRINGS["Hole"]}: "+@active_diameter.to_s+"x"+@hole_depth.to_s, @line_black_bold_center_text_options)
			view.line_width=2
			view.drawing_color = "gray"
			width1 = pix_pt(110)
			case @draw_param[0]
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth-25;x1=x-width1;x2=x+5;y=25;@button_text_options[:align] = TextAlignRight
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth-25;x1=x-width1;x2=x+5;y=view.vpheight-50;@button_text_options[:align] = TextAlignRight
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["below the list"]}" then x=30;x1=x-5;x2=x+width1;y+=30;@button_text_options[:align] = TextAlignLeft
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["Bottom"]}" then x=30;x1=x-5;x2=x+width1;y=view.vpheight-50;@button_text_options[:align] = TextAlignLeft
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth/2;x1=x-width1/2;x2=x+width1/2;y=60;@button_text_options[:align] = TextAlignCenter
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth/2;x1=x-width1/2;x2=x+width1/2;y=view.vpheight-50;@button_text_options[:align] = TextAlignCenter
				else x=view.vpwidth-25;x1=x-width1;x2=x+5;y=80;@button_text_options[:align] = TextAlignRight
			end
			
			@exit = false
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@exit = true
			end
			@button_text_options[:bold] = @exit
			draw_text(view,Geom::Point3d.new(x, y, 0), SUF_STRINGS["Exit"], @button_text_options )
			view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
			
			
			if @ipface
				view.drawing_color = "orange"
				@ipface.outer_loop.edges.each { |edge| view.draw_lines [edge.start.position.transform(@tr),edge.end.position.transform(@tr)]}
				
				mesh = @ipface.mesh(0)
				points = mesh.points
				points.map!{|pt| pt.transform(@tr)}
				triangles = []
				mesh.polygons.each { |polygon|
          polygon.each { |index|
						triangles << points[index.abs - 1]
					}
				}
				view.drawing_color = @blue
				view.draw(GL_TRIANGLES, triangles)
			end
			
			if @pt
				#@ip1.draw(view)
				view.tooltip = @ip1.tooltip
				view.line_width=3
				view.drawing_color = "red"
				draw_hole(view,@essence,@pt.transform(@tr.inverse),@tr,@active_diameter/25.4,@hole_depth)
			end
			Sketchup::set_status_text(SUF_STRINGS["Drilling depth"], SB_VCB_LABEL)
			Sketchup::set_status_text(@hole_depth, SB_VCB_VALUE)
		end#def
		def draw_hole(view,essence,pt,tr,diameter,depth)
			if @ipface.classify_point(pt) == Sketchup::Face::PointInside
				vector = @ipface.edges[0].start.position - @ipface.edges[0].end.position
				vector.normalize!
				number_of_edge_curves = 24
				rot_tr = Geom::Transformation.rotation( pt, @ipface.normal, 360.degrees/number_of_edge_curves )
				point = pt + Geom::Vector3d.new( vector.x*diameter/2, vector.y*diameter/2, vector.z*diameter/2 ) + Geom::Vector3d.new( @ipface.normal.x*0.01, @ipface.normal.y*0.01, @ipface.normal.z*0.01 )
				pts = []
				pts << point.clone
				number_of_edge_curves.times do
          point.transform!( rot_tr )
          pts << point.clone
				end
				view.draw(GL_LINE_STRIP, pts.map{|pt|pt.transform(tr)})
			end
		end#def
		def onMouseMove(flags, x, y, view)
			@screen_x = x
			@screen_y = y
			ph_fe = view.pick_helper
			ph_fe.do_pick(x, y, 0)
			@ip.pick view,x,y
			@pt = nil
			@face_type = nil
			@essence = nil
			@sel.clear
			@tr = Geom::Transformation.new
			Sketchup::set_status_text SUF_STRINGS["Hover over the panel"]
			if (@ip.valid?)
				@ipface=nil if @sel.length==0
				if @ip.face
          comp = @ip.face.parent.instances[-1]
          if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
						@ipface = @ip.face
						@essence = comp
						all_comp=search_parent(@essence)
						if all_comp != []
							all_comp.reverse.each { |parent_comp|
								parent_comp.make_unique
                parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
								@tr *= parent_comp.transformation
							}
						end
						@essence.make_unique if @essence.definition.count_instances > 1
            @essence.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if @essence.parent.is_a?(Sketchup::ComponentDefinition)
						@tr *= @essence.transformation
						ph_fe.count.times{|i|
							if ph_fe.leaf_at(i) == @ipface
								@tr_face_c = ph_fe.transformation_at(i)
								@pt = points_inside_face(@ipface,@tr_face_c,@ip.position)
								if @pt
									@ip1.copy! @ip
								end
							end
						}
					end
          select_fastener(@essence,@ip.position) if @essence
				end
				view.invalidate
			end
		end#def
		def points_inside_face(face,tr,pt)
			if face.classify_point(pt.transform(tr.inverse)) == Sketchup::Face::PointInside ||
				face.classify_point(pt.transform(tr.inverse)) == Sketchup::Face::PointOnEdge ||
				face.classify_point(pt.transform(tr.inverse)) == Sketchup::Face::PointOnVertex
				return pt
				else
				return nil
			end
		end
		def select_fastener(entity,point)
			fastener_hash = {}
			comp_transformation = @tr
			entity.definition.entities.each { |e|
				if e.is_a?(Sketchup::Group)
          if e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
						origin_point = e.transformation.origin
						pt_point = point.transform(comp_transformation.inverse)
						if origin_point.z+40/25.4 > pt_point.z && origin_point.z-40/25.4 < pt_point.z
							if origin_point.y+40/25.4 > pt_point.y && origin_point.y-40/25.4 < pt_point.y
								@sel.add e
							end
						end
					end
          elsif e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("dimension")
          origin_point = e.transformation.origin
          pt_point = point.transform(comp_transformation.inverse)
          if origin_point.z+40/25.4 > pt_point.z && origin_point.z-40/25.4 < pt_point.z
						if origin_point.y+40/25.4 > pt_point.y && origin_point.y-40/25.4 < pt_point.y
							@sel.add e
						end
					end
				end
			}
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
		def onLButtonDown(flags, x, y, view)
			if @change_diameter
				edit_diameter_list(@diameter_array.map{|x|x.to_s.sub(/(?:(\..*[^0])0+|\.0+)$/, '\1')})
				elsif @change_color
				edit_hole_color(@hole_color)
				elsif @exit
				@model.select_tool( Fasteners_Panel )
				elsif @selection_hole != 0
				save_selection_hole(view,@selection_hole)
				elsif @essence && @pt && @ipface.classify_point(@pt.transform(@tr.inverse)) == Sketchup::Face::PointInside
				@model.start_operation "Hole", true
				@essences_with_hole = []
				make_hole(@essence,@pt,@tr,@hole_depth,@active_diameter)
				@model.commit_operation
			end
		end#def
		def edit_diameter_list(diameter_array)
			@edit_diameter_list_dlg.close if @edit_diameter_list_dlg && (@edit_diameter_list_dlg.visible?)
			head = <<-HEAD
				<html><head>
				<meta charset="utf-8">
				<title>Edit</title>
				<style>
				body { font-family: Arial; color: #696969; font-size: 14px; }
				#diameter_list_input { width: 100%; height: 30px; }
				.save { position: fixed; bottom: 8px; left: 50%; margin-left: -50px; width:100px; height:30px; background-color: #e08120; cursor:pointer; border: 1px solid transparent; color: #000000;}
				.save:hover { background-color: #c46500; }
				</style>
				</head>
				<body>
			HEAD
			body = ''
			body << %(
			<input type="text" value="#{diameter_array.join(",")}" id="diameter_list_input">
			<button class="save" onclick="save();">#{SUF_STRINGS["Save"]}</button>
			)
			tail = <<-TAIL
				<script>
				function save() {
				let value = document.getElementById("diameter_list_input").value;
				sketchup.edit('save'+value);
				}
				</script>
				</body></html>
			TAIL
			html = head + body + tail
			@edit_diameter_list_dlg = UI::HtmlDialog.new({
				:dialog_title => SUF_STRINGS["Edit_diameter_list"],
				:preferences_key => "edit_diameter_list",
				:scrollable => true,
				:resizable => true,
				:width => 400,
				:height => 130,
				:left => 150,
				:top => 100,
				:min_width => 400,
				:min_height => 130,
				:max_width =>1000,
				:max_height => 130,
				:style => UI::HtmlDialog::STYLE_DIALOG
			})
			@edit_diameter_list_dlg.add_action_callback('edit') { |web_dialog,action_name|
				if action_name.include?("save")
					value = action_name[4..-1]
					path_param = TEMP_PATH+"/SUF/hole_list.dat"
					param_file = File.new(path_param,"w")
					param_file.puts value
					param_file.close
					@edit_diameter_list_dlg.close
					@diameter_array = value.split(",").map{|x|x.to_f}
					@model.active_view.invalidate
				end
			}
			@edit_diameter_list_dlg.set_html(html)
			@edit_diameter_list_dlg && (@edit_diameter_list_dlg.visible?) ? @edit_diameter_list_dlg.bring_to_front : @edit_diameter_list_dlg.show
		end#def
		def edit_hole_color(rgb)
			@edit_color_dlg.close if @edit_color_dlg && (@edit_color_dlg.visible?)
			head = <<-HEAD
				<html><head>
				<meta charset="utf-8">
				<title>Edit</title>
				<style>
				body { font-family: Arial; color: #696969; font-size: 14px; }
				#color_well { width: 100%; height: 30px; }
				.save { position: fixed; bottom: 8px; left: 50%; margin-left: -50px; width:100px; height:30px; background-color: #e08120; cursor:pointer; border: 1px solid transparent; color: #000000;}
				.save:hover { background-color: #c46500; }
				</style>
				</head>
				<body>
			HEAD
			color = "#" + rgb[0].to_s(16).rjust(2, '0').upcase + rgb[1].to_s(16).rjust(2, '0').upcase + rgb[2].to_s(16).rjust(2, '0').upcase
			body = ''
			body << %(
			<input type="color" value="#{color}" rgb_value="#{rgb}" onchange="change_color(this);" id="color_well">
			<button class="save" onclick="save();">#{SUF_STRINGS["Save"]}</button>
			)
			tail = <<-TAIL
				<script>
        var rgb = "#{rgb[0]},#{rgb[1]},#{rgb[2]}";
				function change_color(obj) {
				let bigint = parseInt(obj.value.split('#')[1], 16);
				let r = (bigint >> 16) & 255;
				let g = (bigint >> 8) & 255;
				let b = bigint & 255;
				rgb = r+","+g+","+b;
				}
				function save() {
				sketchup.edit('save'+rgb);
				}
				</script>
				</body></html>
			TAIL
			html = head + body + tail
			@edit_color_dlg = UI::HtmlDialog.new({
				:dialog_title => SUF_STRINGS["Edit_color"],
				:preferences_key => "edit_color",
				:scrollable => true,
				:resizable => true,
				:width => 100,
				:height => 130,
				:left => 100,
				:top => 100,
				:min_width => 100,
				:min_height => 130,
				:max_width =>100,
				:max_height => 130,
				:style => UI::HtmlDialog::STYLE_DIALOG
			})
			@edit_color_dlg.add_action_callback('edit') { |web_dialog,action_name|
				if action_name.include?("save")
					rgb = action_name[4..-1]
          p rgb
					path_param = TEMP_PATH+"/SUF/hole_color.dat"
					param_file = File.new(path_param,"w")
					param_file.puts rgb
					param_file.close
					@edit_color_dlg.close
					@hole_color = rgb.split(",").map(&:to_i)
					@model.active_view.invalidate
				end
			}
			@edit_color_dlg.set_html(html)
			@edit_color_dlg && (@edit_color_dlg.visible?) ? @edit_color_dlg.bring_to_front : @edit_color_dlg.show
		end#def
		def make_hole(essence,pt,tr,depth,active_diameter)
			new_depth = 0
			transform_pt = pt.transform(tr.inverse)
			comp = essence.parent.instances[-1]
			comp = comp.parent.instances[-1] if comp.definition.name.include?("Body")
			v0_cut = comp.definition.get_attribute("dynamic_attributes", "v0_cut")
			if v0_cut
				comp.set_attribute("dynamic_attributes", "v0_cut", "2")
				comp.definition.set_attribute("dynamic_attributes", "v0_cut", "2")
			end
			essence.definition.set_attribute("dynamic_attributes", "_fastener", true)
			essence.definition.set_attribute("dynamic_attributes", "_hole", true)
			thickness = essence.definition.get_attribute("dynamic_attributes", "lenx")
			group = essence.definition.entities.add_group
			group.layer = @fastener_layer
			group.material = @hole_color
			group.move!(transform_pt)
			text = "x"+depth.to_s
			if @ipface.normal.x.abs == 1
				if group.transformation.origin.x != 0
					essence.definition.set_attribute("dynamic_attributes", "_fastener_position_front", true)
					text += SUF_STRINGS["front"] if @type_hole == "yes"
					else
					essence.definition.set_attribute("dynamic_attributes", "_fastener_position_back", true)
					text += SUF_STRINGS["flip"] if @type_hole == "yes"
				end
				else
				essence.definition.set_attribute("dynamic_attributes", "_fastener_position_edge", true)
				text += SUF_STRINGS["flank"] if @type_hole == "yes"
			end
			
			if depth/25.4 >= thickness && @ipface.normal.x.abs == 1
				if depth/25.4 > thickness
					new_depth = depth - (thickness*25.4).round
				end
				depth = (thickness*25.4).round
				text = SUF_STRINGS["through"] if @type_hole == "yes"
			end
			group.name = "ø"+active_diameter.to_s+text
			
			edges = group.definition.entities.add_circle  Geom::Point3d.new(0, 0, 0), @ipface.normal, active_diameter/50.8
			edges[0].find_faces
			group.definition.entities.grep(Sketchup::Face).each { |face|
				face.normal == @ipface.normal ? koef = -1 : koef = 1
				face.pushpull(koef*depth/25.4)
			}
			fastener_array = []
			fastener_array << [active_diameter.to_s,active_diameter.to_s,depth.to_s,depth.to_s]
			if @ipface.normal.x.abs == 1
				if group.transformation.origin.x != 0
					group.set_attribute("_suf", "facedrilling", fastener_array)
					else
					group.set_attribute("_suf", "backdrilling", fastener_array)
				end
				else
				group.set_attribute("_suf", "edgedrilling", fastener_array)
				group.set_attribute("_suf", "drilling_normal", @ipface.normal.reverse)
			end
			group.set_attribute("_suf", "_hole", true)
			@essences_with_hole << essence
			if new_depth != 0
				transform_pt.x == 0 ? transform_pt.x = thickness : transform_pt.x = 0
				pt = transform_pt.transform(tr)
				second_essence,tr = search_touch_essence(pt)
				if second_essence
					make_hole(second_essence,pt,tr,new_depth,active_diameter) 
					if @fastener_dimension.include?("1") || @fastener_dimension.include?("2") || @fastener_dimension.include?("3")
						Fasteners_Panel.dimensions(second_essence)
					end
				end
			end
			if @fastener_dimension.include?("1") || @fastener_dimension.include?("2") || @fastener_dimension.include?("3")
			  Fasteners_Panel.dimensions(essence)
			end
		end#def
		def search_touch_essence(pt) 
			@essence_and_transformation.each_pair{|ess,tr|
				if !@essences_with_hole.include?(ess)
					ess.definition.entities.grep(Sketchup::Face).each { |face|
						if face.classify_point(pt.transform(tr.inverse)) == Sketchup::Face::PointInside
						  @ipface = face
							return ess,tr
						end
						}
				end
			}
			return nil,nil
		end#def
		def save_selection_hole(view,selection_hole)
			@active_diameter = selection_hole
			view.invalidate
		end#def
		def onUserText(text, view)
			if text.to_i > 0
				@hole_depth=text.to_i
				view.invalidate
				draw(view)
				else
				UI.messagebox(SUF_STRINGS["Minimum drilling depth is 1 mm"])
				Sketchup::set_status_text(@hole_depth, SB_VCB_VALUE)
			end
		end#def
		def onCancel(reason, view)
			if reason == 2
				@model.abort_operation
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
	end#Class
end#Module
