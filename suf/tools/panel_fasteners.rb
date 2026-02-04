module SU_Furniture
  class FastenersPanel
    def initialize()
		  @instance_cache_prefix = '_inst_'
      @reverse_type_fastener1 = "0"
      @reverse_type_fastener2 = "0"
      @fastener_position = "symmetrical"
		  @indent32_1 = 0
      @fastener_indent = 0
      @fastener_indent2 = 0
			@panel_fastener_count = {}
      @text_size = (OSX ? 20 : 13)
      @text_indent = (OSX ? 15 : 9)
      @circle_text_size = (OSX ? 27 : 22)
      @x_offset = (OSX ? 10 : 0)
      @y_offset = (OSX ? 10 : 0)
      @shift_press=false
      @control_press=false
      @reverse_fastener=false
      @reverse_pt = nil
      @offset_fastener_check = nil
      @offset_fastener_value = nil
      @shelf_fastener_check = nil
      @shelf_fastener_value = nil
      @shelf_depth_check = nil
      @shelf_depth_value = nil
      @module = nil
      @essence_and_comp = {}
      @essence_and_faces = {}
			@essence_and_all_faces = {}
			@faces_and_triangles = {}
      @essence_and_transformation_of_module = {}
      @essence_and_module = {}
      @essence_and_transformation = {}
      @arrow_type = Sketchup::Dimension::ARROW_CLOSED
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
      @right_text_default_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignRight,
        bold: false
      }
      @right_text_active_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignRight,
        bold: true
      }
      @title_default_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignCenter,
        bold: false
      }
      @title_active_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignCenter,
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
    end#def
    def activate
      @canceled = false
      @model=Sketchup.active_model
      @sel=@model.selection
			@ents = @model.active_entities
      @sel.remove_observer $SUFSelectionObserver
			@model.entities.remove_observer $SUFEntitiesObserver
      #@model.options['UnitsOptions']['LengthPrecision'] = 0
      @sc_f = UI.scale_factor
      @scale_tr = Geom::Transformation.scaling(@sc_f)
			view = @model.active_view
			unit = [ [ view.vpheight / 150, 8 ].min, 4 * UI.scale_factor ].max
			@mouse_down = nil
      @rule1 = nil
      @rule2 = nil
      @active_fastener2 = nil
      @fastener_param2 = nil
      @shelf_fastener = false
      @reverse_type_fastener1 = "0"
      @reverse_type_fastener2 = "0"
			mat_names = []
      @model.materials.each{|i| mat_names << i.display_name}
      @model.start_operation "search", true, false, true
			@fastener_layer = @model.layers.add "Z_fastener"
      @dim_layer = @model.layers.add "Z_fastener_dimension"
      @text_layer = @model.layers.add "Z_fastener_text"
      reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance))
      @dim_y0 = @model.definitions.find{|e|e if e.name.include?("dimensionY0")} || @model.definitions.load(PATH+"/additions/dimensionY0.skp")
      @dim_z0 = @model.definitions.find{|e|e if e.name.include?("dimensionZ0")} || @model.definitions.load(PATH+"/additions/dimensionZ0.skp")
      @dim_z1 = @model.definitions.find{|e|e if e.name.include?("dimensionZ1")} || @model.definitions.load(PATH+"/additions/dimensionZ1.skp")
      @dim_z2 = @model.definitions.find{|e|e if e.name.include?("dimensionZ2")} || @model.definitions.load(PATH+"/additions/dimensionZ2.skp")
      @model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") }
      @fastener_layer.visible = true
      #@dim_layer.visible = true
      @text_layer.visible = true
			@blue = Sketchup::Color.new(0, 50, 100, 70)
      @button1 = image_rep(view,mat_names,"button1.png")
      @button2 = image_rep(view,mat_names,"button2.png")
      @button3 = image_rep(view,mat_names,"button3.png")
      @button4 = image_rep(view,mat_names,"button4.png")
      @button5 = image_rep(view,mat_names,"button5.png")
      @button6 = image_rep(view,mat_names,"button6.png")
      @settings = image_rep(view,mat_names,"settings.png")
      @settings_active = image_rep(view,mat_names,"settings_active.png")
      @model.commit_operation
      @ip=Sketchup::InputPoint.new
      @fastener_pts = {}
      @fastener_select = false
			@all_fastener_select = false
      @constlines_pts = {}
      @dimension_pts = {}
			@draw_other_side = false
      @process_by_template = false
      @process_accessories = false
      @fastener_dimension = "no"
      @dimension_base = "2side"
      @type_hole = "yes"
      read_param
      read_template
      read_draw_param
      @active_fastener = @fastener_parameters.keys[0]
      @fastener_parameters.each { |key,value|
        @active_fastener = key if value["active"] == "true"
      }
      @fastener_param = @fastener_parameters[@active_fastener]
      @comp=nil
      @ipface=nil
      @ipface_normal=nil
      @touch_comp_fastener_array = []
			@a03_name = nil
      @selected_fasteners = []
			@fastener_or_dimension_selected = false
      @current_edge=nil
      @current_pt=nil
      @screen_x=0
      @screen_y=0
      self.reset(view)
      Sketchup::set_status_text(SUF_STRINGS["Fastener position from edge"], SB_VCB_LABEL)
      Sketchup::set_status_text(@fastener_indent, SB_VCB_VALUE)
    end#def
    def mat_from_name(mat_name)
      @model.materials.each{|mat| return mat if mat_name == mat.display_name }
    end#def
    def image_rep(view,mat_names,mat_name)
      if mat_names.include?(mat_name)
        new_mat = mat_from_name(mat_name)
        image_rep = new_mat.texture.image_rep
        return view.load_texture(image_rep)
        else
        new_mat= @model.materials.add mat_name
        new_mat.texture= PATH_ICONS+"/"+mat_name
        image_rep = new_mat.texture.image_rep
        return view.load_texture(image_rep)
      end
    end#def
    def reset_comp_with_essence(ents)
      @module = nil
      @essence_and_comp = {}
      @essence_and_faces = {}
			@essence_and_all_faces = {}
			@faces_and_triangles = {}
      @essence_and_transformation_of_module = {}
      @essence_and_module = {}
      @essence_and_transformation = {}
      ents.each { |entity|
        entity.make_unique if entity.definition.count_instances > 1
        entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
				tr = Geom::Transformation.new
				all_comp = search_parent(entity)
				all_comp.reverse.each { |ent|	tr *= ent.transformation }
        if entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module" || entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "Body" || entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "body"
          @module = entity
          lenx = entity.definition.get_attribute("dynamic_attributes", "lenx")
          leny = entity.definition.get_attribute("dynamic_attributes", "leny")
          lenz = entity.definition.get_attribute("dynamic_attributes", "lenz")
          search_comp_with_essence(entity,entity.transformation,tr,lenx,leny,lenz)
          else
          search_comp_with_essence(entity,entity.transformation,tr)
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
    def search_comp_with_essence(entity,tr,tr2,p_lenx=nil,p_leny=nil,p_lenz=nil)
      if !entity.hidden?
        if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence" || entity.definition.name.include?("axe_position") || entity.definition.get_attribute("dynamic_attributes", "_name") == "axe_position"
          entity.make_unique if entity.definition.count_instances > 1
          entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
          napr_texture = entity.definition.get_attribute("dynamic_attributes", "napr_texture")
          napr_texture = entity.definition.get_attribute("dynamic_attributes", "texturemat") if !napr_texture
					napr_texture = entity.definition.get_attribute("dynamic_attributes", "component_201_texture") if !napr_texture
          if entity.parent.is_a?(Sketchup::ComponentDefinition) && napr_texture
            if entity.parent.instances[-1].definition.name.include?("Body")
              @essence_and_comp[entity] = entity.parent.instances[-1].parent.instances[-1]
              else
              @essence_and_comp[entity] = entity.parent.instances[-1]
            end
            faces = []
						all_faces = []
            entity.definition.entities.grep(Sketchup::Face).each { |f|
						  triangles = []
							if f.normal.x.abs == 1
								faces << f
								all_faces << f
                mesh = f.mesh(0)
                points = mesh.points
                points.map!{|pt| pt.transform(tr)}
                mesh.polygons.each { |polygon|
                  polygon.each { |index|
                    triangles << points[index.abs - 1]
                  }
                }
								@faces_and_triangles[f] = triangles
								else
								all_faces << f
              end
            }
						@essence_and_faces[entity] = faces
						@essence_and_all_faces[entity] = all_faces
						@essence_and_transformation_of_module[entity] = [tr2,p_lenx,p_leny,p_lenz]
						@essence_and_module[entity] = @module
						@essence_and_transformation[entity] = tr
          end
					else
					if entity.definition.name.include?("confirmat_box")
						entity.erase!
						else
						entity.make_unique if entity.definition.count_instances > 1
            entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
						entity.definition.entities.grep(Sketchup::ComponentInstance).each { |body| search_comp_with_essence(body,tr*body.transformation,tr2*body.transformation,p_lenx,p_leny,p_lenz) }
          end
        end
      end
    end#def
    def all_essences()
      reset_comp_with_essence(Sketchup.active_model.entities.grep(Sketchup::ComponentInstance)) if @essence_and_faces == {}
      return @essence_and_faces,@essence_and_transformation
    end
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
				if i.split("=")[1] == "fastener_position"
					@fastener_position_index = index
					@fastener_position = i.split("=")[2]
					@fastener_position_array = i
					elsif i.split("=")[1] == "fastener_dimension"
					@fastener_dimension = i.split("=")[2]
					elsif i.split("=")[1] == "dimension_base"
					@dimension_base = i.split("=")[2]
					elsif i.split("=")[1] == "type_hole"
					@type_hole = i.split("=")[2]
        end
      }
			@fastener_parameters = Hash.new
			if param_temp_path && File.file?(File.join(param_temp_path,"fasteners.dat"))
				path_fastener = File.join(param_temp_path,"fasteners.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","fasteners.dat"))
				path_fastener = File.join(TEMP_PATH,"SUF","fasteners.dat")
				else
				path_fastener = File.join(PATH,"parameters","fasteners.dat")
      end
			content = File.readlines(path_fastener)
			@fastener_list = []
			content.each { |i|
				param_array = i.strip.gsub("{","").gsub("}","").split(",")
				fastener_param = Hash.new
				@fastener_parameters[param_array[0].split("=>")[1]]=fastener_param
				param_array.each { |param|
					param = param.gsub("{","").gsub("}","")
					fastener_param[param.split("=>")[0]]=param.split("=>")[1]
        }
				@fastener_list << param_array[0].split("=>")[1] if fastener_param["visible"] == "true"
      }
			@hinge_parameters = Hash.new
			if param_temp_path && File.file?(File.join(param_temp_path,"hinge.dat"))
				path_hinge = File.join(param_temp_path,"hinge.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","hinge.dat"))
				path_hinge = File.join(TEMP_PATH,"SUF","hinge.dat")
				else
				path_hinge = File.join(PATH,"parameters","hinge.dat")
      end
			content_hinge = File.readlines(path_hinge)
			content_hinge.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
			content_hinge.each { |i|
				param_array = i.split("<=>")[1..-1]
				param_array.each { |param|
					hinge_names = param.split("=")[1..-1].each_slice(2).to_a
					hinge_names.each { |hinge|
            name = hinge[0].gsub("°","").gsub("˚","").gsub(",","").gsub("|","").gsub(".","")
            name = name.split("<#>")[0] if name.include?("<#>")
						@hinge_parameters[name]=hinge[1]
          }
        }
      }
			@drawer_parameters = Hash.new
			if param_temp_path && File.file?(File.join(param_temp_path,"drawer.dat"))
				path_drawer = File.join(param_temp_path,"drawer.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","drawer.dat"))
				path_drawer = File.join(TEMP_PATH,"SUF","drawer.dat")
				else
				path_drawer = File.join(PATH,"parameters","drawer.dat")
      end
			content = File.readlines(path_drawer)
			content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
			content.reject! { |i| i.nil? || i == '' }
			content.each { |i|
				param_array = i.split(",")
				param_array[3..-1].each { |param|
					if param.split("=>")[1]
            @drawer_parameters[param_array[0].split("=>")[1]+" "+param.split("=>")[0]]=param.split("=>")[1]+param_array[2].split("=>")[1]
          end
        }
      }
			@accessories_parameters = Hash.new
			if param_temp_path && File.file?(File.join(param_temp_path,"accessories.dat"))
				path_accessories = File.join(param_temp_path,"accessories.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","accessories.dat"))
				path_accessories = File.join(TEMP_PATH,"SUF","accessories.dat")
				else
				path_accessories = File.join(PATH,"parameters","accessories.dat")
      end
			content = File.readlines(path_accessories)
			content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
			content.each { |i|
				param_array = i.split("=>")
				@accessories_parameters[param_array[0].gsub("°","").gsub("˚","").gsub(",","").gsub("|","").gsub(".","")]=param_array[1] if param_array[1]
      }
    end#def
		def read_template
			@a03_name = nil
			@min_width_panel = 30
			@min_indent = 15
			@place_fastener = "out"
			@check_depth = "Шкант"
			@template = Hash.new
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"template.dat"))
				path = File.join(param_temp_path,"template.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","template.dat"))
				path = File.join(TEMP_PATH,"SUF","template.dat")
				else
				path = File.join(PATH,"parameters","template.dat")
      end
			content = File.readlines(path)
			content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
			content.each { |i|
				param_array = i.split("=")
				@template[param_array[1]]=param_array
      }
			@fastener_indent = @template["template1"][2].to_f.round if @fastener_indent == 0
      @fastener_indent2 = @template["template1"][2].to_f.round if @fastener_indent2 == 0
			@min_width_panel = @template["min_width_panel"][2].to_f
			@min_indent = @template["min_indent"][2].to_f if @template["min_indent"]
			@place_fastener = @template["place_fastener"][2] if @template["place_fastener"]
			@check_depth = @template["check_depth"][2] if @template["check_depth"]
			@additional_fastener_hash = {}
			if @template["third_fastener"][2].include?("-")
				additional_fastener_array = @template["third_fastener"][2].split(";")
				additional_fastener_array.each { |additional_fastener|
					@additional_fastener_hash[additional_fastener.split("-")[0].to_f] = additional_fastener.split("-")[1].to_i
        }
				else
				@additional_fastener_hash[@template["third_fastener"][2].to_f] = 3
      end
    end#def
		def read_draw_param
			@draw_param = []
			if File.file?( TEMP_PATH+"/SUF/draw_options.dat")
				path = TEMP_PATH+"/SUF/draw_options.dat"
				else
				path = PATH + "/parameters/draw_options.dat"
      end
			content = File.readlines(path)
			param_file = File.new(TEMP_PATH+"/SUF/draw_options.dat","w")
			content.each{|i| param_file.puts i }
			param_file.close
			content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
			content.each { |i| @draw_param << i }
    end#def
		def deactivate(view)
			@shift_press=false
			@control_press=false
			@reverse_fastener=false
			@reverse_pt = nil
			@sel.clear
			@fastener_or_dimension_selected = false
			if @canceled
				@model.abort_operation
				else
				#@model.select_tool nil
      end
			if SU_Furniture.observers_state == 1
				@sel.add_observer $SUFSelectionObserver
				@model.entities.add_observer $SUFEntitiesObserver
      end
			view.release_texture(@button1)
			view.release_texture(@button2)
			view.release_texture(@button3)
			view.release_texture(@button4)
			view.release_texture(@button5)
			view.release_texture(@button6)
			view.release_texture(@settings)
			view.release_texture(@settings_active)
			view.invalidate
    end#def
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
			count = 0
			@fastener_parameters.each_pair { |key,value| count += 1 if value["visible"] == "true" }
			@draw_background = false
			if @screen_x > 0 && @screen_x < 360 && @screen_y > 0 && @screen_y < pix_pt(160)+(30+@y_offset)*count
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(360, 0, 0), Geom::Point3d.new(360, pix_pt(160)+(30+@y_offset)*count, 0), Geom::Point3d.new(0, pix_pt(160)+(30+@y_offset)*count, 0) ])
				@draw_background = true
      end
			
			view.drawing_color = "gray"
			view.line_width=2
			
			fastener_position_text = SUF_STRINGS["Symmetrical"]
			fastener_position_text = SUF_STRINGS["From front edge"] if @fastener_position == "front"
			fastener_position_text = SUF_STRINGS["From back edge"] if @fastener_position == "back"
			draw_text(view,Geom::Point3d.new(30, 25, 0), "TAB - #{SUF_STRINGS["Fitting installation"]}: ", @text_default_options)
			draw_text(view,Geom::Point3d.new(230, 25, 0), fastener_position_text, @text_active_options)
			draw_text(view,Geom::Point3d.new(30, 55+@y_offset, 0), SUF_STRINGS["Hold Shift - symmetrical"], @text_default_options)
			draw_text(view,Geom::Point3d.new(30+pix_pt(235)+@x_offset*2, 48+@y_offset, 0), "↕", @circle_default_options)
			draw_text(view,Geom::Point3d.new(30, 85+@y_offset*2, 0), SUF_STRINGS["Hold Ctrl - symmetrical"], @text_default_options)
			draw_text(view,Geom::Point3d.new(30+pix_pt(235)+@x_offset*2, 78+@y_offset*2, 0), "↔", @circle_default_options)
			
			y = 110+@y_offset*3
			@fastener_point = 0
			@fastener_parameters.each_pair { |key,value|
				if value["visible"] == "true"
					if @active_fastener == key
						draw_text(view,Geom::Point3d.new(35, y, 0), "•", @circle_active_options)
						draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_active_options)
						else
						if @screen_x > 20 && @screen_x < 100 && @screen_y > y && @screen_y < y+30+@y_offset
							@fastener_point = key
							draw_text(view,Geom::Point3d.new(35, y, 0), "○", @circle_default_options)
							draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_black_options)
							else
							draw_text(view,Geom::Point3d.new(35, y, 0), "•", @circle_default_options)
							draw_text(view,Geom::Point3d.new(47+@x_offset, y+6, 0), key, @text_default_options)
            end
          end
					y += 30+@y_offset
        end
      }
			
			#@essence && @panel_fastener_count[@essence] ? fastener_count = " (#{@panel_fastener_count[@essence]})" : 
			fastener_count = ""
			draw_text(view,Geom::Point3d.new(view.vpwidth-30, 25, 0), SUF_STRINGS["Delete fitting: Double-click on the fitting"], @right_text_default_options)
			draw_text(view,Geom::Point3d.new(view.vpwidth-30, 55, 0), SUF_STRINGS["Fitting on the other side: Up arrow"], @right_text_default_options)
			draw_text(view,Geom::Point3d.new(view.vpwidth-30, 85, 0), "#{SUF_STRINGS["Number of fittings"]} #{fastener_count}: #{SUF_STRINGS["Left/Right arrows"]}", @right_text_default_options)
			draw_text(view,Geom::Point3d.new(view.vpwidth-30, 115, 0), SUF_STRINGS["Set all to side: Down arrow"], @right_text_default_options)
			
			text1 = SUF_STRINGS["Delete drilling"]
			text2 = SUF_STRINGS["Visible side"]
			text3 = SUF_STRINGS["Panels without drilling"]
			text4 = SUF_STRINGS["Drilling by template"]
			text5 = SUF_STRINGS["Hardware drilling"]
			text6 = SUF_STRINGS["Separate hole"]
			
			uvs = [ [0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0] ]
			b_count = 6
			width1 = pix_pt(240)
			width2 = pix_pt(90)
			gap = pix_pt(30)
			case @draw_param[0]
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth-30;x1=x-width1-@x_offset*3;x2=x+5;y=60+@y_offset;options1=@right_text_default_options;options2=@right_text_active_options
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth-30;x1=x-width1-@x_offset*3;x2=x+5;y=view.vpheight-(40+@y_offset)*b_count-@y_offset-20;options1=@right_text_default_options;options2=@right_text_active_options
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["below the list"]}" then x=35;x1=x-5;x2=x+width1+@x_offset*3;y+=20+@y_offset;options1=@text_default_options;options2=@text_active_options
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["Bottom"]}" then x=35;x1=x-5;x2=x+width1+@x_offset*3;y=view.vpheight-(40+@y_offset)*b_count-@y_offset-20;options1=@text_default_options;options2=@text_active_options
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth/2-(width2*(b_count-1)+gap*(b_count-1))/2;x1=x-width2/2;x2=x+width2/2;y=30;options1=@title_default_options;options2=@title_active_options
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth/2-(width2*(b_count-1)+gap*(b_count-1))/2;x1=x-width2/2;x2=x+width2/2;y=view.vpheight-50;options1=@title_default_options;options2=@title_active_options
				else x=view.vpwidth-25;x1=x-width1;x2=x+5;y=80;options1=@right_text_default_options;options2=@right_text_active_options
      end
			
			@delete_fastener = false
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@delete_fastener = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text1, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text1, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text1, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+25+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+25+@x_offset/2, y-@y_offset, 0) ], texture: @button1, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			@visible_side = false
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				x += width2+gap
				x1 += width2+gap
				x2 += width2+gap
      end
			y += 40+@y_offset if !@draw_param[0].include?(SUF_STRINGS["Centered"])
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@visible_side = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text2, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text2, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text2, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+21+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-21-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-21-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+21+@x_offset/2, y-@y_offset, 0) ], texture: @button2, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			@without_fastener = false
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				x += width2+gap
				x1 += width2+gap
				x2 += width2+gap
      end
			y += 40+@y_offset if !@draw_param[0].include?(SUF_STRINGS["Centered"])
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@without_fastener = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text3, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text3, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text3, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+25+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+25+@x_offset/2, y-@y_offset, 0) ], texture: @button3, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			@fastener_by_template = false
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				x += width2+gap
				x1 += width2+gap
				x2 += width2+gap
      end
			y += 40+@y_offset if !@draw_param[0].include?(SUF_STRINGS["Centered"])
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@fastener_by_template = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text4, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text4, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text4, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+25+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+25+@x_offset/2, y-@y_offset, 0) ], texture: @button4, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			@fastener_furniture = false
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				x += width2+gap
				x1 += width2+gap
				x2 += width2+gap
      end
			y += 40+@y_offset if !@draw_param[0].include?(SUF_STRINGS["Centered"])
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@fastener_furniture = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text5, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text5, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text5, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+25+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+25+@x_offset/2, y-@y_offset, 0) ], texture: @button5, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			@fastener_hole = false
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				x += width2+gap
				x1 += width2+gap
				x2 += width2+gap
      end
			y += 40+@y_offset if !@draw_param[0].include?(SUF_STRINGS["Centered"])
			if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20
				view.drawing_color = "black"
				@fastener_hole = true
				draw_text(view,Geom::Point3d.new(x, y, 0), text6, options2) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
				draw_text(view,Geom::Point3d.new(x, y+25, 0), text6, @title_default_options) if @draw_param[0].include?(SUF_STRINGS["Centered"])
				else
				draw_text(view,Geom::Point3d.new(x, y, 0), text6, options1) if !@draw_param[0].include?(SUF_STRINGS["Centered"])
      end
			if @draw_param[0].include?(SUF_STRINGS["Centered"])
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(x1+25+@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y+16, 0), Geom::Point3d.new(x2-25-@x_offset/2, y-@y_offset, 0), Geom::Point3d.new(x1+25+@x_offset/2, y-@y_offset, 0) ], texture: @button6, uvs: uvs)
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4-@y_offset, 0), Geom::Point3d.new(x2, y-4-@y_offset, 0), Geom::Point3d.new(x2, y+20, 0), Geom::Point3d.new(x1, y+20, 0) ])
				else
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
      end
			view.drawing_color = "gray"
			
			
			# настройки
			@draw_options = false
			if @screen_x > view.vpwidth-40-@x_offset && @screen_x < view.vpwidth-10 && @screen_y > view.vpheight-25-@y_offset && @screen_y < view.vpheight-5
				@draw_options = true
				draw_text(view,Geom::Point3d.new(view.vpwidth-50-@x_offset, view.vpheight-28-@y_offset, 0), SUF_STRINGS["Settings"], @right_text_default_options)
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(view.vpwidth-20, view.vpheight-10, 0), Geom::Point3d.new(view.vpwidth-20, view.vpheight-30-@y_offset, 0), Geom::Point3d.new(view.vpwidth-40-@x_offset, view.vpheight-30-@y_offset, 0), Geom::Point3d.new(view.vpwidth-40-@x_offset, view.vpheight-10, 0) ], texture: @settings_active, uvs: uvs)
				else
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(view.vpwidth-20, view.vpheight-10, 0), Geom::Point3d.new(view.vpwidth-20, view.vpheight-30-@y_offset, 0), Geom::Point3d.new(view.vpwidth-40-@x_offset, view.vpheight-30-@y_offset, 0), Geom::Point3d.new(view.vpwidth-40-@x_offset, view.vpheight-10, 0) ], texture: @settings, uvs: uvs)
      end
			
			view.line_width=2
			if @touch_hash
				if !@process_accessories
					if !@process_by_template || @draw_other_side
						for i in 0..3
							if @touch_hash[i] && @touch_hash[i] != []
								@touch_hash[i].each{|arr|
									view.drawing_color = "blue"
									view.draw_lines arr[4]
									face = arr[5]
									tr = arr[6]
									if !face.deleted?
										view.drawing_color = "orange"
										face.outer_loop.edges.each { |edge| view.draw_lines [edge.start.position.transform(tr),edge.end.position.transform(tr)]}
										if @faces_and_triangles[face]
											view.drawing_color = @blue
											view.draw(GL_TRIANGLES, @faces_and_triangles[face])
                    end
                  end
                }
              end
            end
          end
        end
      end
			
			view.drawing_color = "red"
			@fastener_pts = {}
			@fastener_select = false
			if @constlines_pts != {}
				if @shift_press==true && @control_press==true
					view.line_stipple = ""
					@fastener_select = true
					fastener_pts_collect(view)
					else
					single_fastener = true
					@constlines_pts.each_pair {|edge_index,arr|                 # номер торца
						if !@fastener_pts[edge_index]
							@fastener_pts[edge_index] = []
							arr.each_with_index{|constlines_arr,j|                    # номер стыка
								fastener_pts = []
								constlines_arr.each_with_index { |constline_pts,index|  # номер направляющей
									if constline_pts[0] && constline_pts[1] && !fastener_pts[index]
										view.drawing_color = "red"
										
										if @dimension_pts[constline_pts[0]]
											pt = @dimension_pts[constline_pts[0]]
											if index==0 || index==1 || index==2
												
												else
												prev_index = index-1
												prev_index = index-2 if !constlines_arr[prev_index][0]
												point = view.screen_coords(mid_point(pt[0],@dimension_pts[constlines_arr[prev_index][0]][0]))
												dist_val = (pt[1]-@dimension_pts[constlines_arr[prev_index][0]][1]).abs
												draw_text(view,point, dist_val.to_s, @title_default_options)
												if index==constlines_arr.length-1
												  point = view.screen_coords(mid_point(pt[0],@dimension_pts[constlines_arr[0][0]][0]))
												  draw_text(view,point, dist_val.to_s, @title_default_options)
                        end
                      end
                    end
										
										ph = view.pick_helper
										picked1 = ph.test_point(constline_pts[1],@screen_x,@screen_y,40)
										picked2 = ph.test_point(constline_pts[0],@screen_x,@screen_y,40)
										if picked1 || picked2
											view.line_stipple = ""
											@fastener_select = true
											
											if @shift_press==true
												view.draw_lines constline_pts
												if @dimension_pts[constline_pts[0]]
													point = view.screen_coords(@dimension_pts[constline_pts[0]][0])
													draw_text(view,point, @dimension_pts[constline_pts[0]][1].to_s, @title_default_options)
                        end
												fastener_pts[index] = constlines_arr[index][0]
												if index == 0 && constlines_arr[2]
													view.draw_lines constlines_arr[2]
													if @dimension_pts[constlines_arr[2][0]]
														point = view.screen_coords(@dimension_pts[constlines_arr[2][0]][0])
														draw_text(view,point, @dimension_pts[constlines_arr[2][0]][1].to_s, @title_default_options)
                          end
													fastener_pts[2] = constlines_arr[2][0]
													elsif index == 2 && constlines_arr[0]
													view.draw_lines constlines_arr[0]
													if @dimension_pts[constlines_arr[0][0]]
														point = view.screen_coords(@dimension_pts[constlines_arr[0][0]][0])
														draw_text(view,point, @dimension_pts[constlines_arr[0][0]][1].to_s, @title_default_options)
                          end
													fastener_pts[0] = constlines_arr[0][0]
													elsif index == 1 && constlines_arr[0] && constlines_arr[2]
													view.draw_lines constlines_arr[0]
													view.draw_lines constlines_arr[2]
													if @dimension_pts[constlines_arr[0][0]]
														point = view.screen_coords(@dimension_pts[constlines_arr[0][0]][0])
														draw_text(view,point, @dimension_pts[constlines_arr[0][0]][1].to_s, @title_default_options)
                          end
													if @dimension_pts[constlines_arr[2][0]]
														point = view.screen_coords(@dimension_pts[constlines_arr[2][0]][0])
														draw_text(view,point, @dimension_pts[constlines_arr[2][0]][1].to_s, @title_default_options)
                          end
													fastener_pts[0] = constlines_arr[0][0]
													fastener_pts[2] = constlines_arr[2][0]
                        end
												
												elsif @control_press==true
												view.draw_lines constline_pts
												if @dimension_pts[constline_pts[0]]
													point = view.screen_coords(@dimension_pts[constline_pts[0]][0])
													draw_text(view,point, @dimension_pts[constline_pts[0]][1].to_s, @title_default_options)
                        end
												fastener_pts[index] = constlines_arr[index][0]
												@constlines_pts.each_pair{|e_i,e_a|
													if e_i != edge_index
														@fastener_pts[e_i] = []
														e_a.each_with_index{|c_lines_arr,c_j|
															f_pts = [nil,nil,nil]
															if c_j == j
																c_lines_arr.each_with_index { |c_pts,c_i|
																	if c_i == index && c_pts
																		view.line_stipple = ""
																		view.draw_lines @constlines_pts[e_i][c_j][c_i]
																		if @dimension_pts[@constlines_pts[e_i][c_j][c_i][0]]
																			point = view.screen_coords(@dimension_pts[@constlines_pts[e_i][c_j][c_i][0]][0])
																			draw_text(view,point, @dimension_pts[@constlines_pts[e_i][c_j][c_i][0]][1].to_s, @title_default_options)
                                    end
																		f_pts[c_i] = @constlines_pts[e_i][c_j][c_i][0]
																		else
																		view.line_stipple = "-"
																		view.draw_lines @constlines_pts[e_i][c_j][c_i]
                                  end
                                }
																else
																view.line_stipple = "-"
																c_lines_arr.each_with_index { |c_pts,c_i|
																	view.draw_lines @constlines_pts[e_i][c_j][c_i]
                                }
                              end
															@fastener_pts[e_i] << f_pts
                            }
                          end
                        }
												
												else
												if @all_fastener_select
													view.line_stipple = ""
													@constlines_pts.each_pair{|e_i,e_a|
														if e_i == edge_index
															@fastener_pts[e_i] = []
															e_a.each_with_index{|c_lines_arr,c_j|
																f_pts = [nil,nil,nil]
																if c_j == j
																	c_lines_arr.each_with_index { |c_pts,c_i|
																		if c_pts
																			view.line_stipple = ""
																			view.draw_lines @constlines_pts[e_i][c_j][c_i]
																			if @dimension_pts[@constlines_pts[e_i][c_j][c_i][0]]
																				point = view.screen_coords(@dimension_pts[@constlines_pts[e_i][c_j][c_i][0]][0])
																				draw_text(view,point, @dimension_pts[@constlines_pts[e_i][c_j][c_i][0]][1].to_s, @title_default_options)
                                      end
																			f_pts[c_i] = @constlines_pts[e_i][c_j][c_i][0]
                                    end
                                  }
                                end
																@fastener_pts[e_i] << f_pts
                              }
                            end
                          }
													else
													if single_fastener == true
														view.line_stipple = ""
														view.draw_lines constline_pts
														if @dimension_pts[constline_pts[0]]
															#view.tooltip = @dimension_pts[constline_pts[0]][1].to_s
															point = view.screen_coords(@dimension_pts[constline_pts[0]][0])
															draw_text(view,point, @dimension_pts[constline_pts[0]][1].to_s, @title_default_options)
                            end
														fastener_pts[index] = constlines_arr[index][0]
														single_fastener = false
														else
														view.line_stipple = "-"
														view.draw_lines constline_pts
														fastener_pts[index] = nil
                          end
                        end
                      end
											else
											view.line_stipple = "-"
											view.draw_lines constline_pts
											fastener_pts[index] = nil
                    end
										view.line_stipple = ""
                  end
                }
								@fastener_pts[edge_index] << fastener_pts
              }
            end
          }
        end
      end
			#@essence_and_comp.each_pair { |essence,comp| draw_fastener_groups(view,comp,essence) if essence.layer.visible?}
			if @indent32_1
				if @indent32_1 == 0
					Sketchup::set_status_text("#{SUF_STRINGS["Fastener position from edge"]}", SB_VCB_LABEL)
					else
					Sketchup::set_status_text("#{SUF_STRINGS["Fastener position from edge"]} (#{SUF_STRINGS["system32"]} - #{@indent32_1},#{@indent32_1+16},#{@indent32_1+32},#{@indent32_1+48},#{@indent32_1+64})", SB_VCB_LABEL)
        end
      end
			if !@ipface
				Sketchup::set_status_text SUF_STRINGS["Hover over the panel"]
				else
				Sketchup::set_status_text SUF_STRINGS["Click on the guide line when it becomes solid"]
      end
			view.drawing_color = "gray"
			if dragging?
				view.line_stipple = drag_pick_inside ? "" : "_"
				view.draw2d(GL_LINE_LOOP, mouse_rectangle)
      end
    end#def
		def mid_point(point1, point2)
		  point1.x == point2.x ? x = point1.x : x = (point1.x + point2.x)/2
			point1.y == point2.y ? y = point1.y : y = (point1.y + point2.y)/2
			point1.z == point2.z ? z = point1.z : z = (point1.z + point2.z)/2
			return Geom::Point3d.new(x,y,z)
    end
		def draw_fastener_groups(view,comp,essence)
			if !comp.deleted?
				lenx = essence.definition.get_attribute("dynamic_attributes", "lenx")
				essence.definition.entities.grep(Sketchup::Group).each { |ent|
					if ent.get_attribute("_suf", "facedrilling") || ent.get_attribute("_suf", "backdrilling") || ent.get_attribute("_suf", "edgedrilling")
						view.line_stipple = ""
						view.line_width=2
						if ent.material
							view.drawing_color = ent.material.color
							else
							view.drawing_color = "gray"
            end
						start_point = ent.transformation.origin
						tr = @essence_and_transformation[essence]
						pts = ent.entities.grep(Sketchup::Face).select { |f| f.edges.all?{|e|e.curve}}
						pts = pts.map{|f|f.outer_loop.vertices.map { |v|v.position } }
						pts = []
						edges = ent.entities.grep(Sketchup::Edge)
						edges.each{|edge|edge.vertices.each { |v|pts << v.position } }
						fastener_pts = pts.collect{|pt|pt.transform(tr*ent.transformation)}
						
						#fastener_pts.each{|pt|view.draw(GL_POLYGON, pt)}
						
						view.drawing_color = "red"
						fastener_pts.each{|pt|view.draw(GL_LINES, pt)}
						
						mesh = face.mesh(0)
						points = mesh.points
						points.map!{|pt| pt.transform(tr)}
						triangles = []
						mesh.polygons.each { |polygon|
							polygon.each { |index|
								triangles << points[index.abs - 1]
              }
            }
						view.drawing_color = @blue
						view.draw(GL_TRIANGLES, triangles)
						
						#view.drawing_color = "red"
							#pts = pts.collect{|pt|pt.collect{|p|p.transform(ent.transformation)}}
							#red_pts = pts.select{|pt| pt.all?{|p|p.x==0} }+pts.select{|pt| pt.all?{|p|p.x==lenx} }
							#red_pts = red_pts.collect{|pt|pt.collect{|p|p.transform(tr)}}
            #red_pts.each{|pt|view.draw(GL_POLYGON, pt)}
          end
        }
      end
    end#def
		def onMouseMove(flags, x, y, view)
		  @mouse_position = Geom::Point3d.new(x, y, 0)
			@essence = nil
      @selected_fasteners = []
			@touch_hash = {}
			@screen_x = x
			@screen_y = y
			@indent32_1=0.0
			@ip.pick view,x,y
			if !@draw_background && @ip.valid?
				@ipface=nil if @sel.length==0
				@constlines_pts = {}
				if @ip.face
					if !@ipface || @ipface.deleted?
						@ipface=@ip.face
						pt=@ip.position
						else
						pt=@ip.position
						@ipface=@ip.face if (@ipface!=@ip.face)
          end
					if @ipface && @ipface.parent.is_a?(Sketchup::ComponentDefinition)
						@essence = @ipface.parent.instances[-1]
						if @essence_and_comp[@essence]
							if @essence.definition.name.include?("Essence") || @essence.definition.get_attribute("dynamic_attributes", "_name") == "Essence" || @essence.definition.name.include?("axe_position") || @essence.definition.get_attribute("dynamic_attributes", "_name") == "axe_position"
								@lenx = @essence.definition.get_attribute("dynamic_attributes", "lenx")
								@leny = @essence.definition.get_attribute("dynamic_attributes", "leny")
								@lenz = @essence.definition.get_attribute("dynamic_attributes", "lenz")
								napr_texture = @essence.definition.get_attribute("dynamic_attributes", "napr_texture")
								napr_texture = @essence.definition.get_attribute("dynamic_attributes", "texturemat") if !napr_texture
								napr_texture = @essence.definition.get_attribute("dynamic_attributes", "component_201_texture") if !napr_texture
								edge_length = true
								@ip.face.edges.each { |edge|
									pt1=edge.start.position
									pt2=edge.end.position
									if (pt1.z*25.4).round(1) == 0 && (pt2.z*25.4).round(1) == 0 || (pt1.z*25.4).round(1) == (@lenz*25.4).round(1) && (pt2.z*25.4).round(1) == (@lenz*25.4).round(1) || (pt1.y*25.4).round(1) == (@leny*25.4).round(1) && (pt2.y*25.4).round(1) == (@leny*25.4).round(1) || (pt1.y*25.4).round(1) == 0 && (pt2.y*25.4).round(1) == 0
										if edge.length < @min_width_panel/25.4
											edge_length = false
											break
                    end
                  end
                }
								if edge_length
									if napr_texture
										@comp = @essence.parent.instances[-1]
										@comp = @comp.parent.instances[-1] if @comp.definition.name.include?("Body")
										@point_y_offset = @comp.definition.get_attribute("dynamic_attributes", "point_y_offset")
										@width_length = 10
										@height_length = 10
										@a01_gluing = @comp.definition.get_attribute("dynamic_attributes", "a01_gluing", "1").to_f
										if @a01_gluing > 1
											@thick = @lenx/@a01_gluing
											else
											@thick = @lenx
                    end
										search_elements
										costruction_lines_pts
                  end
									else
									@ipface=nil
                end
								@selected_fasteners = select_fastener(@essence,@ip.position)
              end
            end
          end
        end
      end
			view.invalidate
    end#def
		def select_fastener(essence,point)
			comp_transformation = @essence_and_transformation[essence]
			if @fastener_or_dimension_selected
				@sel.clear
				@fastener_or_dimension_selected = false
      end
			fastener_groups = {}
			essence.definition.entities.grep(Sketchup::Group).each { |e|
				if e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
					origin_point = e.transformation.origin
					pt_point = point.transform(comp_transformation.inverse)
					if origin_point.z+1 > pt_point.z && origin_point.z-1 < pt_point.z && origin_point.y+1 > pt_point.y && origin_point.y-1 < pt_point.y
						@fastener_or_dimension_selected = true
						fastener_groups[essence.definition] = [] if !fastener_groups[essence.definition]
						fastener_groups[essence.definition] << e
						if e.get_attribute("_suf", "other_groups")
							other_groups_pid = e.get_attribute("_suf", "other_groups").compact
							if other_groups_pid != []
								other_groups = @model.find_entity_by_persistent_id(other_groups_pid)
								other_groups.each{|group|
									if group
										ess = group.parent
										fastener_groups[ess] = [] if !fastener_groups[ess]
										fastener_groups[ess] << group
                  end
                }
              end
            end
          end
        end
      }
			fastener_entities = []
			fastener_groups.each_pair { |ess,arr|
				arr.each{|group|
					fastener_entities << group
					points = []
					points << group.transformation.origin
					points += pts_from_array(group,group.get_attribute("_suf", "facedrilling")) if group.get_attribute("_suf", "facedrilling")
					points += pts_from_array(group,group.get_attribute("_suf", "backdrilling")) if group.get_attribute("_suf", "backdrilling")
					points += pts_from_array(group,group.get_attribute("_suf", "edgedrilling")) if group.get_attribute("_suf", "edgedrilling")
					points.each{|pt_point|
						ess.entities.grep(Sketchup::ComponentInstance).each { |e|
							if e.definition.name.include?("dimension")
								origin_point = e.transformation.origin
								if origin_point.z+1 > pt_point.z && origin_point.z-1 < pt_point.z && origin_point.y+1 > pt_point.y && origin_point.y-1 < pt_point.y
									fastener_entities << e
                end
              end
            }
          }
        }
      }
			@sel.clear if @fastener_or_dimension_selected
			fastener_entities.each { |e| @sel.add e }
      return fastener_entities
    end#def
		def pts_from_array(group,pt_array)
			points = []
			pt_array.each{|pt|
				points << Geom::Point3d.new(pt[4][2]/25.4,pt[4][1]/25.4,pt[4][0]/25.4) if pt[4]
      }
			return points
    end#def
		def search_elements
			comp_transformation = @essence_and_transformation[@essence]
			@ipface_normal = @ipface.normal.transform(comp_transformation)
			@ipface.edges.each { |edge|
				parallel_face = nil
				parallel_face_normal = nil
				#edge.find_faces
				edge.faces.each { |face|
					if face != @ipface
						parallel_face_normal = face.normal.transform(comp_transformation)
						parallel_face = face
          end
        }
				pt1=[edge.start.position,edge.end.position].sort_by{|pt|[pt.x,pt.y,pt.z]}[0]
				
				pt2=[edge.start.position,edge.end.position].sort_by{|pt|[pt.x,pt.y,pt.z]}[1]
				
				e_start_position = pt1.transform(comp_transformation)
				e_end_position = pt2.transform(comp_transformation)
				edge_index = 4
				
				# замена index для фронтальной панели
				if (pt1.z*25.4).round(1) == 0 && (pt2.z*25.4).round(1) == 0
					@point_y_offset ? edge_index = 3 : edge_index = 0
					elsif (pt1.z*25.4).round(1) == (@lenz*25.4).round(1) && (pt2.z*25.4).round(1) == (@lenz*25.4).round(1)
					@point_y_offset ? edge_index = 2 : edge_index = 1
					elsif (pt1.y*25.4).round(1) == (@leny*25.4).round(1) && (pt2.y*25.4).round(1) == (@leny*25.4).round(1)
					@point_y_offset ? edge_index = 1 : edge_index = 2
					elsif (pt1.y*25.4).round(1) == 0 && (pt2.y*25.4).round(1) == 0
					@point_y_offset ? edge_index = 0 : edge_index = 3
        end
				
				if edge_index==0 || edge_index==1
					@point_y_offset ? @width_length = @lenz : @width_length = @leny
					elsif edge_index==2 || edge_index==3
					@point_y_offset ? @height_length = @leny : @height_length = @lenz
        end
				
				if parallel_face && edge_index != 4
					@touch_hash[edge_index]=[]
					touch_face=nil
					face_normal=nil
					touch_essence=nil
					touch_edge=[]
					new_comp_transformation=nil
					@essence_and_faces.each_pair { |essence,faces|
						if essence.layer.visible?
							if !@essence.definition.instances.index(essence) && !essence.deleted? && !essence.hidden?
								if @process_by_template
									if @essence_and_module[@essence] && @essence_and_module[@essence].definition.get_attribute("dynamic_attributes", "description") == SUF_STRINGS["product"] && @essence_and_module[essence] && @essence_and_module[essence].definition.get_attribute("dynamic_attributes", "description") == SUF_STRINGS["product"]
										if @essence_and_module[@essence] != @essence_and_module[essence]
											next
                    end
                  end
                end
								if !@fastener_furniture && essence.definition.get_attribute("dynamic_attributes", "without_fastener")
								  else
									touch_edges = search_touch_edges(essence,faces,e_start_position,e_end_position)
									if touch_edges != []
										touch_edges.each {|touch_edge|
											if touch_edge.all?{|pt|@ipface.bounds.contains?(pt.transform(comp_transformation.inverse))}
												vector1 = touch_edge[1]-touch_edge[0]
												vector1.normalize!
												vector2 = vector1.reverse
												pt3=touch_edge[0]+Geom::Vector3d.new(vector1.x*@min_width_panel/25.4,vector1.y*@min_width_panel/25.4,vector1.z*@min_width_panel/25.4)
												pt1 = touch_edge[0].transform(comp_transformation.inverse)
												pt1_thick = Geom::Point3d.new((pt1.x==0 ? pt1.x+@thick : @lenx-@thick),pt1.y,pt1.z)
												pt5=pt1_thick.transform(comp_transformation)+Geom::Vector3d.new(vector1.x*@min_width_panel/25.4,vector1.y*@min_width_panel/25.4,vector1.z*@min_width_panel/25.4)
												touch_face,face_normal,touch_essence,new_comp_transformation,distance=ask_for_touch_component(essence,touch_edge[0],pt3,pt5,@ipface_normal,parallel_face_normal)
												if !touch_face
													pt4=touch_edge[1]+Geom::Vector3d.new(vector2.x*@min_width_panel/25.4,vector2.y*@min_width_panel/25.4,vector2.z*@min_width_panel/25.4)
													pt2 = touch_edge[1].transform(comp_transformation.inverse)
													pt2_thick = Geom::Point3d.new((pt2.x==0 ? pt2.x+@thick : @lenx-@thick),pt2.y,pt2.z)
													pt6=pt2_thick.transform(comp_transformation)+Geom::Vector3d.new(vector2.x*@min_width_panel/25.4,vector2.y*@min_width_panel/25.4,vector2.z*@min_width_panel/25.4)
													touch_face,face_normal,touch_essence,new_comp_transformation,distance=ask_for_touch_component(essence,touch_edge[1],pt4,pt6,@ipface_normal,parallel_face_normal)
                        end
												if touch_face
													@touch_hash[edge_index] << [touch_essence,face_normal,parallel_face.normal,comp_transformation,touch_edge,touch_face,new_comp_transformation,distance]
													edge_length = touch_edge[0].distance touch_edge[1]
													if edge_index == 0 || edge_index == 1
														@indent32_1 = ((edge_length*25.4).round-((((edge_length*25.4).round-@min_indent*2)/32).floor)*32).to_f/2
														@indent32_1 = @indent32_1.round if @indent32_1.to_s[-1] == "0"
                          end
                        end
                      end
                    }
                  end
                end
              end
            end
          }
					@touch_hash[edge_index].sort_by!{|arr|[arr[4][0].x,arr[4][0].y,arr[4][0].z]}
        end
      }
    end#def
		def costruction_lines_pts(rule1=nil,rule2=nil,template=false)
			@constlines_pts = {}
			@dimension_pts = {}
			current_fastener_indent = @fastener_indent
			current_fastener_position = @fastener_position
			fastener_indent = @fastener_indent
			if @touch_hash
				for index in 0..3
					if @touch_hash[index] && @touch_hash[index] != []
						@constlines_pts[index] = []
						@touch_hash[index].each{|arr|
							constlines_pts = []
							edge = arr[4]
							normal = arr[1]
							if edge
                
								if rule2 && index > 1
									rule = rule2
									fastener_indent = @fastener_indent2
									else
									rule = rule1
									fastener_indent = @fastener_indent
                end
                
								edge_vector = edge[1] - edge[0]
								edge_vector.normalize!
								tr = @essence_and_transformation[@essence].inverse
								if edge[0].transform(tr).x > edge[1].transform(tr).x || edge[0].transform(tr).y > edge[1].transform(tr).y || edge[0].transform(tr).z > edge[1].transform(tr).z
									start_point = edge[1]
									end_point = edge[0]
									edge_vector.reverse!
									else
									start_point = edge[0]
									end_point = edge[1]
                end
								edge_length = edge[0].distance edge[1]
								
								single_fastener = false
								if rule 
									if rule == "template1"
										if (edge_length*25.4).round(1) < current_fastener_indent*2+32
											if @template["auto1"][2] == "template2"
												fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
												single_fastener = true if (edge_length*25.4).round(1) < fastener_indent*2+32
												elsif @template["auto1"][2] == "template3"
												single_fastener = true
												fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
												elsif @template["auto1"][2] == "template5"
												@fastener_position = "symmetrical"
												elsif @template["auto1"][2] == "template6"
												single_fastener = true
												else
												single_fastener = true
												fastener_indent = (edge_length*25.4).round(1)/2
                      end
                    end
										elsif rule == "template2"
										fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
										single_fastener = true if (edge_length*25.4).round(1) < fastener_indent*2+32
										elsif rule == "template3"
										single_fastener = true
										fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
										elsif rule == "template4"
										single_fastener = true
										fastener_indent = (edge_length*25.4).round(1)/2
										elsif rule == "template5"
										@fastener_position = "symmetrical"
										elsif rule == "template6"
										single_fastener = true
                  end
                end
                
                if @panel_fastener_count[@essence] && @panel_fastener_count[@essence][index]
									fastener_count = @panel_fastener_count[@essence][index]
									else
									fastener_count = additional_fastener_count(edge_length)
                end
                
                if fastener_count > 2
									@second_indent = (edge_length*25.4).round(1) - ((((edge_length*25.4).round(1) - fastener_indent*2)/(fastener_count-1)/32).floor)*32*(fastener_count-1) - fastener_indent
									else
									@second_indent = (edge_length*25.4).round(1) - ((((edge_length*25.4).round(1) - fastener_indent*2)/32).floor)*32 - fastener_indent
                end
                
								if !rule && template
									constlines_pts << [nil, nil]
									constlines_pts << [nil, nil]
									constlines_pts << [nil, nil]
									else
                  vector1 = Geom::Vector3d.new(edge_vector.x*fastener_indent/25.4,edge_vector.y*fastener_indent/25.4,edge_vector.z*fastener_indent/25.4)
                  vector2 = Geom::Vector3d.new(edge_vector.x*@second_indent/25.4,edge_vector.y*@second_indent/25.4,edge_vector.z*@second_indent/25.4)
                  
									if @fastener_position == "front"
                    if @reverse_type_fastener1 == "2" && index < 2 || @reverse_type_fastener2 == "2" && index > 1
                      start_point,end_point = end_point,start_point
                      vector1.reverse!
                      vector2.reverse!
                    end
                    fastener_point1=start_point+vector1
                    fastener_point3=end_point-vector2
										
										if start_point.distance(fastener_point1) <= edge_length/2
											constlines_pts << [fastener_point1, fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (start_point.distance(fastener_point1)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point1] = [fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if !single_fastener && edge_length > 1 && edge_length*25.4 - @second_indent > fastener_indent+32
											if fastener_count > 2
												constlines_pts << [nil, nil]
												else
												fastener_point2 = Geom::Point3d.new((start_point.x+end_point.x)/2.0, (start_point.y+end_point.y)/2.0, (start_point.z+end_point.z)/2.0)
												constlines_pts << [fastener_point2, fastener_point2+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
                      end
											else
											constlines_pts << [nil, nil]
                    end
										
										if !single_fastener && fastener_point3 != fastener_point1 && end_point.distance(fastener_point3) < edge_length/2
											constlines_pts << [fastener_point3, fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (end_point.distance(fastener_point3)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point3] = [fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if fastener_count > 2
										  distance = ((fastener_point1.distance(fastener_point3)*25.4)/(fastener_count-1)).round(1)
											for i in 0..fastener_count-3
												fastener_point4 = fastener_point1+Geom::Vector3d.new(edge_vector.x*(distance*(i+1))/25.4,edge_vector.y*(distance*(i+1))/25.4,edge_vector.z*(distance*(i+1))/25.4)
												constlines_pts << [fastener_point4, fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
												dist_val = (end_point.distance(fastener_point4)*25.4).round(1)
												dist_val = dist_val.round if dist_val.to_s[-1]=="0"
												@dimension_pts[fastener_point4] = [fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
                      end
                    end
										
										elsif @fastener_position == "back"
                    if @reverse_type_fastener1 == "1" && index < 2 || @reverse_type_fastener2 == "1" && index > 1
                      start_point,end_point = end_point,start_point
                      vector1.reverse!
                      vector2.reverse!
                    end
										fastener_point1=start_point+vector2
										fastener_point3=end_point-vector1
										if !single_fastener && fastener_point3 != fastener_point1 && ((edge_length*25.4).round(1) - fastener_indent*2)/32 >= 1
											constlines_pts << [fastener_point1, fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (start_point.distance(fastener_point1)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point1] = [fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if !single_fastener && edge_length > 1 && edge_length*25.4 - @second_indent > fastener_indent+32
										  if fastener_count > 2
												constlines_pts << [nil, nil]
												else
												fastener_point2 = Geom::Point3d.new((start_point.x+end_point.x)/2.0, (start_point.y+end_point.y)/2.0, (start_point.z+end_point.z)/2.0)
												constlines_pts << [fastener_point2, fastener_point2+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
                      end
											else
											constlines_pts << [nil, nil]
                    end
										
										if end_point.distance(fastener_point3) <= edge_length/2
											constlines_pts << [fastener_point3, fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (end_point.distance(fastener_point3)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point3] = [fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if fastener_count > 2
										  distance = ((fastener_point1.distance(fastener_point3)*25.4)/(fastener_count-1)).round(1)
											for i in 0..fastener_count-3
												fastener_point4 = fastener_point3-Geom::Vector3d.new(edge_vector.x*(distance*(i+1))/25.4,edge_vector.y*(distance*(i+1))/25.4,edge_vector.z*(distance*(i+1))/25.4)
												constlines_pts << [fastener_point4, fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
												dist_val = (end_point.distance(fastener_point4)*25.4).round(1)
												dist_val = dist_val.round if dist_val.to_s[-1]=="0"
												@dimension_pts[fastener_point4] = [fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
                      end
                    end
                    
										else #symmetrical
                    if @reverse_type_fastener1 == "2" && index < 2 || @reverse_type_fastener2 == "2" && index > 1
                      start_point,end_point = end_point,start_point
                      vector1.reverse!
                      vector2.reverse!
                    end
										fastener_point1=start_point+vector1
                    fastener_point3=end_point-vector1
										
										if start_point.distance(fastener_point1) <= edge_length/2
											constlines_pts << [fastener_point1, fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (start_point.distance(fastener_point1)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point1] = [fastener_point1+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if !single_fastener && edge_length > 1
											if fastener_count > 2
												constlines_pts << [nil, nil]
												else
												fastener_point2 = Geom::Point3d.new((start_point.x+end_point.x)/2.0, (start_point.y+end_point.y)/2.0, (start_point.z+end_point.z)/2.0)
												constlines_pts << [fastener_point2, fastener_point2+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
                      end
											else
											constlines_pts << [nil, nil]
                    end
										
										if !single_fastener && fastener_point3 != fastener_point1
											constlines_pts << [fastener_point3, fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
											dist_val = (end_point.distance(fastener_point3)*25.4).round(1)
											dist_val = dist_val.round if dist_val.to_s[-1]=="0"
											@dimension_pts[fastener_point3] = [fastener_point3+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
											else
											constlines_pts << [nil, nil]
                    end
										
										if fastener_count > 2
										  distance = (fastener_point1.distance(fastener_point3)*25.4)/(fastener_count-1)
											for i in 0..fastener_count-3
												fastener_point4 = fastener_point3-Geom::Vector3d.new(edge_vector.x*(distance*(i+1))/25.4,edge_vector.y*(distance*(i+1))/25.4,edge_vector.z*(distance*(i+1))/25.4)
												constlines_pts << [fastener_point4, fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4)]
												dist_val = (end_point.distance(fastener_point4)*25.4).round(1)
												dist_val = dist_val.round if dist_val.to_s[-1]=="0"
												@dimension_pts[fastener_point4] = [fastener_point4+Geom::Vector3d.new(normal.x*1.4,normal.y*1.4,normal.z*1.4),dist_val]
                      end
                    end
                  end
                end
                else
                constlines_pts << [nil, nil]
                constlines_pts << [nil, nil]
                constlines_pts << [nil, nil]
              end
              @constlines_pts[index] << constlines_pts
              @fastener_indent = current_fastener_indent
              @fastener_position = current_fastener_position
            }
          end
        end
      end
      @fastener_indent = current_fastener_indent
      @fastener_position = current_fastener_position
      #@constlines_pts.each_pair{|index,pts|pts.each_with_index { |pt,i| p "#{i}: #{pt}" }}
    end#def
    def search_points_between(pt1,pt2,pt3,pt4)
      points_between = []
      points_between << pt1 if point_between?(pt1,pt3,pt4) && !points_between.include?(pt1)
      points_between << pt2 if point_between?(pt2,pt3,pt4) && !points_between.include?(pt2)
      points_between << pt3 if point_between?(pt3,pt1,pt2) && !points_between.include?(pt3)
      points_between << pt4 if point_between?(pt4,pt1,pt2) && !points_between.include?(pt4)
			if points_between.count > 1
				return points_between
      end
			return [pt1,pt2]
    end#def
		def point_between?(point, point1, point2)
			return true if point == point1 || point == point2
			point.on_line?([point1, point2]) && !point.vector_to(point1).samedirection?( point.vector_to(point2) )
    end
		def search_touch_edges(essence,faces,e_start_position,e_end_position)
			touch_edges = []
			all_touch_points = []
			points_project_to_plane = []
			radius = 15/25.4
			tr = @essence_and_transformation[essence]
			lenx = essence.definition.get_attribute("dynamic_attributes", "lenx")
			leny = essence.definition.get_attribute("dynamic_attributes", "leny")
			lenz = essence.definition.get_attribute("dynamic_attributes", "lenz")
			start_point = e_start_position.transform(tr.inverse)
			end_point = e_end_position.transform(tr.inverse)
			faces.each{|face|
				face.edges.each{|face_edge|
					pt1=face_edge.start.position
					pt2=face_edge.end.position
					#if (pt1.z*25.4).round(1) == 0 && (pt2.z*25.4).round(1) == 0 || (pt1.z*25.4).round(1) == (lenz*25.4).round(1) && (pt2.z*25.4).round(1) == (lenz*25.4).round(1) || (pt1.y*25.4).round(1) == (leny*25.4).round(1) && (pt2.y*25.4).round(1) == (leny*25.4).round(1) || (pt1.y*25.4).round(1) == 0 && (pt2.y*25.4).round(1) == 0
					if (pt1.x*25.4).round(1) == 0 || (pt1.x*25.4).round(1) == (lenx*25.4).round(1) ||(pt2.x*25.4).round(1) == 0 || (pt2.x*25.4).round(1) == (lenx*25.4).round(1)
						intersect_pt = Geom.intersect_line_line(face_edge.line, [start_point,(end_point-start_point)])
						if !intersect_pt
							intersect_pt = Geom.intersect_line_line(face_edge.line, [end_point,(end_point-start_point)])
            end
						if !intersect_pt
							start_point_to_plane = start_point.project_to_plane face.plane
							end_point_to_plane = end_point.project_to_plane face.plane
							if start_point_to_plane.distance(start_point) < radius
								if start_point_to_plane != end_point_to_plane
									edge_line = [start_point_to_plane,(end_point_to_plane-start_point_to_plane)]
									intersect_pt = Geom.intersect_line_line(face_edge.line, edge_line)
									if !intersect_pt
									  edge_line = [end_point_to_plane,(end_point_to_plane-start_point_to_plane)]
									  intersect_pt = Geom.intersect_line_line(face_edge.line, edge_line)
                  end
									if intersect_pt
										points_project_to_plane = [start_point_to_plane,end_point_to_plane]						
                  end
                end
              end
            end
						if intersect_pt && point_between?(intersect_pt,pt1,pt2) && face.bounds.contains?(intersect_pt) && !all_touch_points.include?(intersect_pt)
							all_touch_points << intersect_pt
            end
          end
        }
				end_points = []
				if all_touch_points.count>1
				  all_touch_points.sort_by!{|pt|[pt.x,pt.y,pt.z]}
					for i in 0..all_touch_points.length-2
					  if points_project_to_plane != []
						  start_point = Geom::Point3d.new(all_touch_points[i].x,start_point.y,start_point.z)
							end_point = Geom::Point3d.new(all_touch_points[i].x,end_point.y,end_point.z)
            end
						touch_points = search_points_between(all_touch_points[i],all_touch_points[i+1],start_point,end_point)
						boundingbox = Geom::BoundingBox.new
						boundingbox.add(all_touch_points[i], all_touch_points[i+1])
						mp = boundingbox.center
						if point_between?(touch_points[0],start_point,end_point) && point_between?(touch_points[1],start_point,end_point)
							end_points << touch_points[0] if i == 0
							end_points << touch_points[1] if i == all_touch_points.length-2
							if face.classify_point(Geom::Point3d.new(mp.x,mp.y+0.01,mp.z+0.01)) == Sketchup::Face::PointInside && face.classify_point(Geom::Point3d.new(mp.x,mp.y-0.01,mp.z+0.01)) == Sketchup::Face::PointInside && face.classify_point(Geom::Point3d.new(mp.x,mp.y+0.01,mp.z-0.01)) == Sketchup::Face::PointInside && face.classify_point(Geom::Point3d.new(mp.x,mp.y-0.01,mp.z-0.01)) == Sketchup::Face::PointInside
								if points_project_to_plane != []
									points = touch_points.map{|pt|Geom::Point3d.new(e_start_position.transform(tr.inverse).x,pt.y,pt.z).transform(tr)}
									else
									points = touch_points.map{|pt|pt.transform(tr)}
                end
								touch_edges << points if !touch_edges.include?(points)
              end
            end
          end
					if touch_edges == [] && end_points.count>1
						if points_project_to_plane != []
							points = end_points.map{|pt|Geom::Point3d.new(e_start_position.transform(tr.inverse).x,pt.y,pt.z).transform(tr)}
							else
							points = end_points.map{|pt|pt.transform(tr)}
            end
						touch_edges << points if !touch_edges.include?(points)
          end
        end
      }
			return touch_edges
    end  
		def search_furniture(ent,tr)
			@touch_hash = {}
			if !ent.hidden? && ent.definition.get_attribute("dynamic_attributes", "hidden", "0").to_f <= 0
        if ent.definition.get_attribute("dynamic_attributes", "hole", "0").to_s != "no"
          if ent.definition.name.include?("Hinge")
            if ent.definition.get_attribute("dynamic_attributes", "_name", "0") == "Hinge2"
              if ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'CHOOSE(Frontal1!open,Panel!LenZ-LOOKUP("hinge_z"),Panel!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'CHOOSE(Frontal1!open,Panel!LenZ-LOOKUP("hinge_z"),Panel!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))'
                ent.definition.set_attribute("dynamic_attributes", "_inst__z_formula", 'CHOOSE(Frontal1!open,Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))')
                ent.set_attribute("dynamic_attributes", "_z_formula", 'CHOOSE(Frontal1!open,Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))')
                Redraw_Components.redraw_entities_with_Progress_Bar([ent])
                elsif ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal2!Z+Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'CHOOSE(Frontal1!open,Frontal2!Z+Frontal1!LenZ-LOOKUP("hinge_z"),Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z"),LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))'
                ent.definition.set_attribute("dynamic_attributes", "_inst__z_formula", 'CHOOSE(Frontal1!open,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))')
                ent.set_attribute("dynamic_attributes", "_z_formula", 'CHOOSE(Frontal1!open,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,Frontal1!Z+Frontal1!LenZ-LOOKUP("hinge_z")-Frontal1!trim_y1,LOOKUP("b1_p_thickness"),LOOKUP("a0_lenz")-LOOKUP("b1_p_thickness"))')
                Redraw_Components.redraw_entities_with_Progress_Bar([ent])
              end
              elsif ent.definition.get_attribute("dynamic_attributes", "_name", "0") == "Hinge4"
              if ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'Frontal1!LenZ-LOOKUP("hinge_z")' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'Frontal1!LenZ-LOOKUP("hinge_z")' || ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'Frontal2!LenZ-LOOKUP("hinge_z")' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'Frontal2!LenZ-LOOKUP("hinge_z")'
                ent.definition.set_attribute("dynamic_attributes", "_inst__z_formula", 'Frontal2!LenZ-LOOKUP("hinge_z")-Frontal2!trim_y1')
                ent.set_attribute("dynamic_attributes", "_z_formula", 'Frontal2!LenZ-LOOKUP("hinge_z")-Frontal2!trim_y1')
                Redraw_Components.redraw_entities_with_Progress_Bar([ent])
                elsif ent.definition.get_attribute("dynamic_attributes", "_inst__z_formula", "0") == 'Frontal2!Z+Frontal2!LenZ-LOOKUP("hinge_z")' || ent.get_attribute("dynamic_attributes", "_z_formula", "0") == 'Frontal2!Z+Frontal2!LenZ-LOOKUP("hinge_z")'
                ent.definition.set_attribute("dynamic_attributes", "_inst__z_formula", 'Frontal2!Z+Frontal2!LenZ-LOOKUP("hinge_z")-Frontal2!trim_y1')
                ent.set_attribute("dynamic_attributes", "_z_formula", 'Frontal2!Z+Frontal2!LenZ-LOOKUP("hinge_z")-Frontal2!trim_y1')
                Redraw_Components.redraw_entities_with_Progress_Bar([ent])
              end
            end
            ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e|
              if e.definition.name.include?("175H9100") && !e.definition.get_attribute("dynamic_attributes", "a03_name")
                e.transform!(Geom::Transformation.scaling(e.transformation.origin, 1, 1, -1)) if e.transformation.zaxis.z != 1
                e.transform!(Geom::Transformation.scaling(e.transformation.origin, -1, 1, 1))
                myentities = e.definition.entities
                myentities.transform_entities(Geom::Transformation.scaling(e.transformation.origin, -1, 1, 1), myentities.to_a)
                e.set_attribute("dynamic_attributes", "a03_name", '0')
                e.definition.set_attribute("dynamic_attributes", "a03_name", '0')
                e.definition.set_attribute("dynamic_attributes", "_a03_name_label", 'a03_name')
                e.definition.set_attribute("dynamic_attributes", "_a03_name_formula", 'CONCATENATE("CLIP ответная планка, крест.| ",CHOOSE(LOOKUP("spacing",1),"0 мм","3 мм","6 мм","9 мм","18 мм"),"| сталь| ",IF(LOOKUP("mounting_plate",2)=2,"с предвар. вмонт. евровинтами","на саморезы"), " [Blum| Австрия]")')
                e.set_attribute("dynamic_attributes", "su_type", 'furniture')
                e.definition.set_attribute("dynamic_attributes", "su_type", 'furniture')
                e.definition.set_attribute("dynamic_attributes", "_su_type_label", 'su_type')
                e.set_attribute("dynamic_attributes", "su_info", '0')
                e.definition.set_attribute("dynamic_attributes", "su_info", '0')
                e.definition.set_attribute("dynamic_attributes", "_su_info_label", 'su_info')
                e.definition.set_attribute("dynamic_attributes", "_su_info_formula", 'LOOKUP("ItemCode")&"/"&a03_name&"/"&su_type&"/"&LenZ*10&"/"&LenY*10&"/"&LenX*10&"/"&"Ответная планка крест"&"/"&Material&"/"&1&"/"&1&"/"&"шт"&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0')
                Redraw_Components.redraw_entities_with_Progress_Bar([ent])
              end
            }
            @hinge = false
            @comp = ent
            pt_transformation = @comp.transformation
            pt = pt_transformation.origin
            @a03_name = @comp.definition.get_attribute("dynamic_attributes", "a03_name", "0").gsub("°","").gsub("˚","").gsub(",","").gsub("|","").gsub(".","")
            regulation = @comp.definition.get_attribute("dynamic_attributes", "regulation")
            if !regulation
              regulation = 0
              @comp.set_attribute("dynamic_attributes", "regulation", 0)
              @comp.definition.set_attribute("dynamic_attributes", "regulation", 0)
              @comp.definition.set_attribute("dynamic_attributes", "_regulation_label", 'regulation')
              @comp.definition.set_attribute("dynamic_attributes", "_regulation_formula", 'LOOKUP("hinge_regulation",0)')
              @comp.definition.set_attribute("dynamic_attributes", "_regulation_formulaunits", 'CENTIMETERS')
            end
            spacing = @comp.definition.get_attribute("dynamic_attributes","spacing",1)
            spacing_arr = [0,0,3,6,9,18]
            hinge_array = []
            if @hinge_parameters[@a03_name]
              hinge_array = @hinge_parameters[@a03_name].split("&")
            end
            if hinge_array == []
              @hinge_parameters.each_pair{|name,array|
                if @a03_name.gsub(" ","") == name.gsub(" ","")
                  if array
                    hinge_array = array.split("&")
                    break
                  end
                end
              }
            end
            if hinge_array == [] && @accessories_parameters[@a03_name]
              hinge_array = @accessories_parameters[@a03_name].split("&")
            end
            hinge_array = param_array_from_name(@a03_name,@hinge_parameters) if hinge_array == []
            hinge_array = param_array_from_name(@a03_name,@accessories_parameters) if hinge_array == []
            if hinge_array != []
              hinge_array.each { |param|
                param_arr = param.split(";")
                if param_arr[1] != "" && param_arr[2] != "" && param_arr[3] != ""
                  param_arr[3] = (param_arr[3].to_f+regulation.to_f*25.4).round(1).to_s
                  if param_arr[0]=="-Y"
                    param_arr[3] = (param_arr[3].to_f+spacing_arr[spacing.to_i].to_f).round(1).to_s
                  end
                  @hinge = true
                  essence = make_holes(param_arr,pt,pt_transformation,tr)
                end
              }
            end
            
            elsif ent.definition.get_attribute("dynamic_attributes", "su_type", "0") == "furniture" || ent.definition.get_attribute("dynamic_attributes", "su_type", "0") == "leg" || ent.definition.get_attribute("dynamic_attributes", "su_type", "0") == "handle"
            @hinge = false
            @comp = ent
            @a03_name = @comp.definition.get_attribute("dynamic_attributes", "a03_name", "0").gsub("°","").gsub("˚","")
            point_x = @comp.definition.get_attribute("dynamic_attributes", "point_x", "1")
            point_y = @comp.definition.get_attribute("dynamic_attributes", "point_y", "1")
            point_z = @comp.definition.get_attribute("dynamic_attributes", "point_z", "1")
            point_x_offset = @comp.definition.get_attribute("dynamic_attributes", "point_x_offset", "0").to_f
            point_y_offset = @comp.definition.get_attribute("dynamic_attributes", "point_y_offset", "0").to_f
            point_z_offset = @comp.definition.get_attribute("dynamic_attributes", "point_z_offset", "0").to_f
            lenx = @comp.definition.get_attribute("dynamic_attributes", "lenx", "0").to_f
            leny = @comp.definition.get_attribute("dynamic_attributes", "leny", "0").to_f
            lenz = @comp.definition.get_attribute("dynamic_attributes", "lenz", "0").to_f
            pt_transformation = @comp.transformation
            
            pt_xaxis = pt_transformation.xaxis
            pt_yaxis = pt_transformation.yaxis
            pt_zaxis = pt_transformation.zaxis
            pt_x_offset = point_x_offset
            pt_y_offset = point_y_offset
            pt_z_offset = point_z_offset
            if point_x_offset.to_f == 0
              if point_x == "2"
                pt_x_offset = -lenx/2
                elsif point_x == "3"
                pt_x_offset = -lenx
              end
            end
            if point_y_offset.to_f == 0
              if point_y == "2"
                pt_y_offset = -leny/2
                elsif point_y == "3"
                pt_y_offset = -leny
              end
            end
            if point_z_offset.to_f == 0
              if point_z == "2"
                pt_z_offset = -lenz/2
                elsif point_z == "3"
                pt_z_offset = -lenz
              end
            end
            #pt = pt_transformation.origin+Geom::Vector3d.new(pt_xaxis.x*point_x_offset,pt_yaxis.y*point_y_offset,pt_zaxis.z*point_z_offset)
            pt = pt_transformation.origin+Geom::Vector3d.new(pt_xaxis.x*pt_x_offset.to_f,pt_xaxis.y*pt_x_offset.to_f,pt_xaxis.z*pt_x_offset.to_f)+Geom::Vector3d.new(pt_yaxis.x*pt_y_offset.to_f,pt_yaxis.y*pt_y_offset.to_f,pt_yaxis.z*pt_y_offset.to_f)+Geom::Vector3d.new(pt_zaxis.x*pt_z_offset.to_f,pt_zaxis.y*pt_z_offset.to_f,pt_zaxis.z*pt_z_offset.to_f)
            
            drawer_array = []
            hinge_array = []
            accessories_array = []
            
            essence1 = nil
            essence2 = nil
            
            drawer_array = param_array_from_name(@a03_name,@drawer_parameters,"Tandembox","Tandem")
            
            if drawer_array != []
              drawer_array[0..-2].each { |param|
                if @a03_name.include?("внутр") && param.split(";")[0].include?("Y") || @a03_name.include?("внутр") && param.split(";")[0].include?("y")
                  else
                  hole_param = param.split(";")
                  hole_param[3] = (lenz*25.4).round+hole_param[3][1..-1].to_f if hole_param[3][0] == "+"
                  hole_param[4] = (lenz*25.4).round+hole_param[4][1..-1].to_f if hole_param[4][0] == "+"
                  hole_param[5] = (lenz*25.4).round+hole_param[5][1..-1].to_f if hole_param[5][0] == "+"
                  if point_x_offset.to_f < 0
                    hole_param[3][0] == "-" ? hole_param[3] = hole_param[3][1..-1] : hole_param[3] = "-"+hole_param[3]
                  end
                  if point_y_offset.to_f < 0
                    hole_param[4][0] == "-" ? hole_param[4] = hole_param[4][1..-1] : hole_param[4] = "-"+hole_param[4]
                  end
                  if point_z_offset.to_f < 0
                    hole_param[5][0] == "-" ? hole_param[5] = hole_param[5][1..-1] : hole_param[5] = "-"+hole_param[5]
                  end
                  essence1 = make_holes(hole_param,pt,pt_transformation,tr)
                  if drawer_array[-1] == "yes"
                    essence2 = make_holes(param.split(";"),pt,pt_transformation,tr,lenx)
                  end
                end
              }
            end
            
            if drawer_array == []
              essence1 = nil
              essence2 = nil
              
              if @hinge_parameters[@a03_name.gsub(",","").gsub("|","").gsub(".","")]
                hinge_array = @hinge_parameters[@a03_name.gsub(",","").gsub("|","").gsub(".","")].split("&")
              end
              if hinge_array == []
                @hinge_parameters.each_pair{|name,array|
                  if @a03_name.gsub(",","").gsub("|","").gsub(".","").gsub(" ","") == name.gsub(",","").gsub("|","").gsub(".","").gsub(" ","")
                    hinge_array = array.split("&")
                    break
                  end
                }
              end
              hinge_array = param_array_from_name(@a03_name.gsub(",","").gsub("|","").gsub(".",""),@hinge_parameters) if hinge_array == []
              if hinge_array != []
                hinge_array.each { |param|
                  param_arr = param.split(";")
                  if param_arr[1] != "" && param_arr[2] != "" && param_arr[3] != ""
                    @hinge = true
                    essence1 = make_holes(param_arr,pt,pt_transformation,tr)
                  end
                }
              end
            end
            
            if drawer_array == [] && hinge_array == []
              essence1 = nil
              essence2 = nil
              
              accessories_array = param_array_from_name(@a03_name.gsub(",","").gsub("|","").gsub(".",""),@accessories_parameters)
              if accessories_array != []
                accessories_array.each { |param|
                  hole_param = param.split(";")
                  hole_param[3] = (lenz*25.4).round+hole_param[3][1..-1].to_f if hole_param[3][0] == "+"
                  hole_param[4] = (lenz*25.4).round+hole_param[4][1..-1].to_f if hole_param[4][0] == "+"
                  hole_param[5] = (lenz*25.4).round+hole_param[5][1..-1].to_f if hole_param[5][0] == "+"
                  if point_x_offset.to_f < 0 && hole_param[3][0] != "-"
                    hole_param[3] = "-"+hole_param[3]
                  end
                  if point_y_offset.to_f < 0 && hole_param[4][0] != "-"
                    hole_param[4] = "-"+hole_param[4]
                  end
                  if point_z_offset.to_f < 0 && hole_param[5][0] != "-"
                    hole_param[5] = "-"+hole_param[5]
                  end
                  essence1 = make_holes(hole_param,pt,pt_transformation,tr)
                }
              end
            end
            ent.definition.entities.grep(Sketchup::Group).each { |entity|
              hole_param = []
              if entity.name=="Hole" || entity.get_attribute("dynamic_attributes", "_name")=="Hole"
                if entity.get_attribute("dynamic_attributes", "diameter") && entity.get_attribute("dynamic_attributes", "depth")
                  hole_param << "Z"
                  hole_param << entity.get_attribute("dynamic_attributes", "diameter", "0").to_f*25.4
                  hole_param << entity.get_attribute("dynamic_attributes", "depth", "0").to_f*25.4
                  hole_param << "0"
                  hole_param << "0"
                  hole_param << "0"
                  hole_param << "1"
                  hole_param << "0"
                  hole_param << entity.get_attribute("dynamic_attributes", "fastener", "")
                  hole_param << entity.get_attribute("dynamic_attributes", "color", "").gsub(",",".")
                  pt_transformation = entity.transformation
                  pt = pt_transformation.origin
                  essence1 = make_holes(hole_param,pt,pt_transformation,tr*ent.transformation)
                end
              end
            }
            
            ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
              if entity.definition.name.include?("Groove") || entity.definition.get_attribute("dynamic_attributes", "_name")=="Groove"
                process_groove(ent,entity,tr,@essence_and_all_faces,@essence_and_transformation)
                elsif entity.definition.name.include?("Notch") || entity.definition.get_attribute("dynamic_attributes", "_name")=="Notch"
                point = entity.transformation.origin.transform(tr*ent.transformation)
                process_notch(ent,entity,point,tr,@essence_and_faces,@essence_and_transformation)
              end
            }
          end
          ent.make_unique if ent.definition.count_instances > 1
          tr*=ent.transformation
          ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_furniture(e,tr) }
        end
      end
    end
    def process_groove(ent,entity,tr,essence_and_faces,essence_and_transformation)
      essence_and_faces.each_pair { |essence,faces|
        if !essence.deleted? && essence.layer.visible?
          essence_lenx = get_cascading_attribute(essence, 'lenx').to_f
          face_tr = essence_and_transformation[essence]
          origin = ent.transformation.origin.transform(tr).transform(face_tr.inverse)
          groove_offset = get_cascading_attribute(ent, 'groove_point_x_offset').to_f
          point = entity.transformation.origin.transform(tr*ent.transformation).transform(face_tr.inverse)
          xaxis = entity.transformation.xaxis.transform(tr*ent.transformation).transform(face_tr.inverse)
          yaxis = entity.transformation.yaxis.transform(tr*ent.transformation).transform(face_tr.inverse)
          zaxis = entity.transformation.zaxis.transform(tr*ent.transformation).transform(face_tr.inverse)
          transform = Geom::Transformation.new(xaxis,yaxis,zaxis,point)
          faces.each { |face|
            if face.classify_point(point) == Sketchup::Face::PointInside
              essence.definition.entities.grep(Sketchup::ComponentInstance).each { |groove|
                if groove.definition.name.include?("Groove") || groove.definition.get_attribute("dynamic_attributes", "_name")=="Groove"
                  if !@pids.include?(groove.definition.get_attribute("dynamic_attributes", "groove_instance"))
                    groove.erase!
                    elsif groove.definition.get_attribute("dynamic_attributes", "groove_instance") == ent.persistent_id
                    groove.erase!
                  end
                end
              }
              groove_instance = essence.definition.entities.add_instance(entity.definition,transform)
              groove_instance.make_unique
              groove_instance.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if groove_instance.parent.is_a?(Sketchup::ComponentDefinition)
              groove_thick = get_cascading_attribute(entity, 'lenz').to_f
              groove_length = get_cascading_attribute(entity, 'leny').to_f
              groove_width = get_cascading_attribute(entity, 'lenx').to_f
              set_att(groove_instance,"lenz",groove_thick)
              set_att(groove_instance,"leny",groove_length)
              set_att(groove_instance,"lenx",groove_width)
              redraw_groove(entity,groove_instance)
              groove_origin = groove_instance.transformation.origin
              groove_instance.material = entity.material
              groove_instance.definition.behavior.is2d = true
              groove_instance.definition.behavior.snapto = SnapTo_Arbitrary
              groove_instance.definition.behavior.cuts_opening = true
              groove_instance.glued_to = face
              groove_name = get_cascading_attribute(ent, 'groove_name')
              
              points = []
              profil = nil
              groove_instance.definition.entities.grep(Sketchup::Face).each {|f|
                if (f.normal.y.abs).round(3) == 1
                  v_points = f.outer_loop.vertices.map{|v| [v.position.x,v.position.y,v.position.z] }
                  profil = v_points if !profil
                  points << v_points.map{|pt| pt.transform(groove_instance.transformation) }
                end
              }
              points.sort_by!{|pts|[pts[0].z,pts[0].y]}
              if zaxis.x.round(3) == -1     # сверху
                profil.map!{|pt|[pt[0] + entity.transformation.origin.x,-1*pt[2]]}
                elsif zaxis.x.round(3) == 1 # снизу
                profil.map!{|pt|[-1*pt[0] - entity.transformation.origin.x,-1*pt[2]]}
                else                        # торцы
                profil.map!{|pt|[pt[2],-1*pt[0] - entity.transformation.origin.x + (essence_lenx - origin.x)]}
              end
              profil.map!{|pt|[(pt[0]*25.4).round(2),(pt[1]*25.4).round(2)]}
              point1 = origin.offset(yaxis.reverse,groove_length/2)
              point2 = origin.offset(yaxis,groove_length/2)
              points << [[point1.x,point1.y,point1.z],[point2.x,point2.y,point2.z]]
              points_mm = points.map{|pts|pts.map{|pt|[(pt.x*25.4).round(2),(pt.y*25.4).round(2),(pt.z*25.4).round(2)]}} # для dxf
              yaxis.normalize!
              groove_xy_pos = [(points[-1][0].z*25.4).round(2),(points[-1][0].y*25.4).round(2),0,yaxis.z,yaxis.y,0]
              groove_instance.transformation.origin.x == 0 ? groove_z_pos = "2" : groove_z_pos = "1"
              groove_att = [(groove_offset.abs*25.4).round(1),[(groove_thick*25.4).round(1),(groove_width*25.4).round(1)],profil,groove_xy_pos,groove_z_pos,((groove_length+0.001)*25.4).round(1),groove_name,points_mm]
              set_att(groove_instance,"groove_param",groove_att)
              set_att(groove_instance,"groove_instance",ent.persistent_id)
              delete_attributes(groove_instance, ["x","y","z","lenx","leny","lenz","rotx","roty","rotz","_groove"])
            end
          }
        end
      }
    end
    def find_notch(ent,tr,notch_arr=[])
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |entity|
        if entity.definition.name.include?("Notch") || entity.definition.get_attribute("dynamic_attributes", "_name")=="Notch"
          if entity.definition.get_attribute("dynamic_attributes", "_lenx_formula")
            point = entity.transformation.origin.transform(tr*ent.transformation)
            notch_arr << [ent,entity,point,tr]
          end
        end
      }
      tr*=ent.transformation
      ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| find_notch(e,tr,notch_arr) }
      return notch_arr
    end
    def find_entities_by_ids(ids,entities=Sketchup.active_model.entities.grep(Sketchup::ComponentInstance),notch_arr=[])
      entities.each { |entity|
        notch_arr << entity if ids.include?(entity.persistent_id)
        find_entities_by_ids(ids,entity.definition.entities.grep(Sketchup::ComponentInstance),notch_arr)
      }
      return notch_arr
    end
    def delete_all_notches(entity,ids=nil,ids_to_modified=[])
      if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        delete_notch_edges(entity,ids)
      end
      if entity.definition.name.include?("Notch") || entity.definition.get_attribute("dynamic_attributes", "_name")=="Notch"
        if ids
          entity.erase! if ids.include?(entity.get_attribute("dynamic_attributes", "notch", 0))
          else
          if entity.get_attribute("dynamic_attributes", "notch") && !ids_to_modified.include?(entity.get_attribute("dynamic_attributes", "notch"))
            ids_to_modified << entity.get_attribute("dynamic_attributes", "notch")
          end
        end
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| delete_all_notches(ent,ids,ids_to_modified) }
      end
      return ids_to_modified
    end
    def delete_notch_edges(entity,ids=nil)
      if ids
        entity.definition.entities.grep(Sketchup::Face).each { |f| f.visible = true if ids.include?(f.get_attribute("dynamic_attributes", "id", 0))}
        else
        entity.definition.entities.grep(Sketchup::Face).each { |f| f.visible = true }
      end
      edges_to_delete = []
      entity.definition.entities.grep(Sketchup::Edge).each { |e|
        next if ids && !ids.include?(e.get_attribute("dynamic_attributes", "id", 0))
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
      end
      def modified_notch(notch_arr)
        reset_comp_with_essence(Sketchup.active_model.entities.grep(Sketchup::ComponentInstance))
        essence_and_faces,essence_and_transformation = all_essences()
        DCProgressBar::clear()
        notch_arr.each {|notch| process_notch(notch[0],notch[1],notch[2],notch[3],essence_and_faces,essence_and_transformation) }
        DCProgressBar::clear()
      end
      def process_notch(ent,entity,point,tr,essence_and_faces,essence_and_transformation,essences_with_notch=[])
        Redraw_Components.redraw(ent,false)
        new_comp = ent.definition.entities.add_instance(entity.definition,entity.transformation)
        new_comp.make_unique
        new_comp.definition.entities.grep(Sketchup::Group).each { |e| (e.hidden? || e.name=="Scaler") ? e.erase! : e.explode }
        hidden_elements = []
        end_points = []
        notch_tr = tr*ent.transformation*new_comp.transformation
        new_comp.definition.entities.each { |e|
          next unless e.is_a?(Sketchup::Edge) || e.is_a?(Sketchup::Face)
          if e.is_a?(Sketchup::Edge) && e.bounds.center.z.round(1) == 0
            end_points << e.start.position if !end_points.include?(e.start.position)
            end_points << e.end.position if !end_points.include?(e.end.position)
          end
          hidden_elements << e if e.hidden?
          e.hidden = false
        }
        
        end_points.map! { |pt| Geom::Point3d.new(pt.x,pt.y,point.transform(notch_tr.inverse).z) }
        end_points.map! { |pt| pt.transform(notch_tr) }
        notch_thick = get_cascading_attribute(entity, 'lenz').to_f
        notch_length = get_cascading_attribute(entity, 'leny').to_f
        notch_width = get_cascading_attribute(entity, 'lenx').to_f
        xaxis = entity.transformation.xaxis.transform(tr*ent.transformation)
        yaxis = entity.transformation.yaxis.transform(tr*ent.transformation)
        zaxis = entity.transformation.zaxis.transform(tr*ent.transformation)
        sibling_essences = []
        if ent.parent.is_a?(Sketchup::ComponentDefinition)
          ent.parent.entities.grep(Sketchup::ComponentInstance).each { |e|
            if e.definition.name.include?("Essence") || e.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
              sibling_essences << e
            end
          }
        end
        essence_and_faces.each_pair { |essence,faces|
          next if sibling_essences != [] && !sibling_essences.include?(essence)
          if faces.any? { |face| face.deleted? }
            hidden_elements.each { |e| e.hidden = true }
            new_comp.erase!
            reset_comp_with_essence(Sketchup.active_model.entities.grep(Sketchup::ComponentInstance))
            process_notch(ent,entity,point,tr,@essence_and_faces,@essence_and_transformation,essences_with_notch)
            return
          end
          lines_on_the_edge = []
          if !essence.deleted? && essence.layer.visible? && !essences_with_notch.include?(essence)
            essence.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |notch|
              if notch.definition.name.include?("Notch") || notch.definition.get_attribute("dynamic_attributes", "_name")=="Notch"
                notch.erase! if get_cascading_attribute(notch, 'notch') == ent.persistent_id
              end
            }
            delete_notch_edges(essence,[ent.persistent_id])
            return if ent.hidden?
            essence_thick = get_cascading_attribute(essence, 'lenx').to_f
            essence_length = get_cascading_attribute(essence, 'leny').to_f
            essence_width = get_cascading_attribute(essence, 'lenz').to_f
            face_tr = @essence_and_transformation[essence]
            faces.each { |face|
              next if face.normal.x.abs != 1 || face.normal != zaxis.transform(face_tr.inverse)
              next if !end_points.any?{|pt|face.classify_point(pt.transform(face_tr.inverse)) == Sketchup::Face::PointInside}
              essences_with_notch << essence
              new_points = end_points.map { |pt|
                pt = pt.transform(face_tr.inverse)
                pt.y = pt.y.clamp(0, essence_length)
                pt.z = pt.z.clamp(0, essence_width)
                pt.transform(face_tr).transform(notch_tr.inverse)
              }
              min_x = new_points.map(&:x).min
              max_x = new_points.map(&:x).max
              min_y = new_points.map(&:y).min
              max_y = new_points.map(&:y).max
              min_z = new_points.map(&:z).min
              point1 = Geom::Point3d.new((min_x + max_x) / 2, (min_y + max_y) / 2, min_z).transform(notch_tr)
              transform = Geom::Transformation.new(
                xaxis.transform(face_tr.inverse),
                yaxis.transform(face_tr.inverse),
                zaxis.transform(face_tr.inverse),
                point1.transform(face_tr.inverse)
              )
              new_lenx = (max_x - min_x).abs
              new_leny = (max_y - min_y).abs
              notch_instance1 = essence.definition.entities.add_instance(new_comp.definition,transform)
              notch_instance1.make_unique
              notch_instance1.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if notch_instance1.parent.is_a?(Sketchup::ComponentDefinition)
              set_att(notch_instance1,"lenx",new_lenx)
              set_att(notch_instance1,"leny",new_leny)
              set_att(notch_instance1,"lenz",(notch_thick >= essence_thick ? essence_thick : notch_thick))
              set_att(notch_instance1,"notch",ent.persistent_id)
              redraw_notch(notch_instance1)
              notch_origin = notch_instance1.transformation.origin
              notch_instance1.material = entity.material
              notch_instance1.definition.behavior.is2d = true
              notch_instance1.definition.behavior.snapto = SnapTo_Arbitrary
              notch_instance1.definition.behavior.cuts_opening = true
              notch_instance1.glued_to = face
              delete_attributes(notch_instance1, ["x","y","z","rotx","roty","rotz"])
              delete_attributes_formula(notch_instance1,["lenx","leny","lenz"])
              
              if notch_thick >= essence_thick
                point2 = Geom::Point3d.new(point1.transform(face_tr.inverse).x,point1.transform(face_tr.inverse).y,point1.transform(face_tr.inverse).z)
                point2.x == 0 ? point2.x = essence_thick : point2.x = 0
                transform = Geom::Transformation.new(xaxis.transform(face_tr.inverse),yaxis.transform(face_tr.inverse),zaxis.transform(face_tr.inverse),point2)
                notch_instance2 = essence.definition.entities.add_instance(new_comp.definition,transform)
                notch_instance2.make_unique
                notch_instance2.definition.entities.grep(Sketchup::Edge) {|e| e.erase! if e.line[1].z.abs.round == 1 || (e.start.position.z != 0 && e.end.position.z != 0) }
                notch_instance2.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if notch_instance2.parent.is_a?(Sketchup::ComponentDefinition)
                notch_instance2.definition.behavior.is2d = true
                notch_instance2.definition.behavior.snapto = SnapTo_Arbitrary
                notch_instance2.definition.behavior.cuts_opening = true
                other_face = essence_and_faces[essence].find { |f| f != face }
                notch_instance2.glued_to = other_face
                set_att(notch_instance2,"lenx",new_lenx)
                set_att(notch_instance2,"leny",new_leny)
                set_att(notch_instance2,"lenz",0)
                set_att(notch_instance2,"_second",true)
                set_att(notch_instance2,"notch",ent.persistent_id)
                redraw_notch(notch_instance2)
                delete_attributes(notch_instance2, ["x","y","z","rotx","roty","rotz"])
                delete_attributes_formula(notch_instance2,["lenx","leny","lenz"])
                notch_instance2.definition.entities.grep(Sketchup::Edge) {|e|
                  pt1 = e.start.position.transform(notch_instance2.transformation)
                  pt2 = e.end.position.transform(notch_instance2.transformation)
                  if (other_face.classify_point(pt1) == Sketchup::Face::PointOnEdge && other_face.classify_point(pt2) == Sketchup::Face::PointOnEdge) || (other_face.classify_point(pt1) == Sketchup::Face::PointOnEdge && other_face.classify_point(pt2) == Sketchup::Face::PointOnVertex) || (other_face.classify_point(pt1) == Sketchup::Face::PointOnVertex && other_face.classify_point(pt2) == Sketchup::Face::PointOnEdge) || (other_face.classify_point(pt1) == Sketchup::Face::PointOnVertex && other_face.classify_point(pt2) == Sketchup::Face::PointOnVertex)
                    lines_on_the_edge << [pt1,pt2]
                  end
                }
                notch_instance2.definition.entities.grep(Sketchup::Face) {|f| f.erase! }
                if lines_on_the_edge != []
                  common_points = []
                  lines_on_the_edge.each { |arr|
                    pt1 = arr[0]
                    pt2 = arr[1]
                    
                    edge1 = essence.definition.entities.add_line(pt1,pt2)
                    edge1.hidden = true
                    set_att(edge1,"edge",true)
                    set_att(edge1,"id",ent.persistent_id)
                    
                    if pt1.x == 0
                      pt3 = Geom::Point3d.new(essence_thick,pt1.y,pt1.z)
                      pt4 = Geom::Point3d.new(essence_thick,pt2.y,pt2.z)
                      else
                      pt3 = Geom::Point3d.new(0,pt1.y,pt1.z)
                      pt4 = Geom::Point3d.new(0,pt2.y,pt2.z)
                    end
                    
                    edge2 = essence.definition.entities.add_line(pt3,pt4)
                    edge2.hidden = true
                    set_att(edge2,"edge",true)
                    set_att(edge2,"id",ent.persistent_id)
                    
                    edge3 = essence.definition.entities.add_line(pt1,pt3)
                    edge3.hidden = true if common_points.include?([pt1,pt3])
                    set_att(edge3,"edge",true)
                    set_att(edge3,"id",ent.persistent_id)
                    common_points << [pt1,pt3]
                    if pt1.y == 0 && pt1.z == 0 || pt1.y == 0 && (pt1.z * 25.4 + 0.01).round(1) == (essence_width * 25.4 + 0.01).round(1) || (pt1.y * 25.4 + 0.01).round(1) == (essence_length * 25.4 + 0.01).round(1) && pt1.z == 0 || (pt1.y * 25.4 + 0.01).round(1) == (essence_length * 25.4 + 0.01).round(1) && (pt1.z * 25.4 + 0.01).round(1) == (essence_width * 25.4 + 0.01).round(1)
                      set_att(edge3,"essence",true)
                    end
                    
                    edge4 = essence.definition.entities.add_line(pt2,pt4)
                    edge4.hidden = true if common_points.include?([pt2,pt4])
                    set_att(edge4,"edge",true)
                    set_att(edge4,"id",ent.persistent_id)
                    common_points << [pt2,pt4]
                    if pt2.y == 0 && pt2.z == 0 || pt2.y == 0 && (pt2.z * 25.4 + 0.01).round(1) == (essence_width * 25.4 + 0.01).round(1) || (pt2.y * 25.4 + 0.01).round(1) == (essence_length * 25.4 + 0.01).round(1) && pt2.z == 0 || (pt2.y * 25.4 + 0.01).round(1) == (essence_length * 25.4 + 0.01).round(1) && (pt2.z * 25.4 + 0.01).round(1) == (essence_width * 25.4 + 0.01).round(1)
                      set_att(edge4,"essence",true)
                    end
                    
                    essence.definition.entities.grep(Sketchup::Face) {|f|
                      v_points = f.outer_loop.vertices.map{|v| v.position }
                      if v_points.include?(pt1) && v_points.include?(pt2) && v_points.include?(pt3) && v_points.include?(pt4)
                        f.hidden = true
                        set_att(f,"id",ent.persistent_id)
                      end
                    }
                    
                    notch_instance2.definition.entities.grep(Sketchup::Edge) {|e|
                      if pt1.transform(notch_instance2.transformation.inverse) == e.start.position && pt2.transform(notch_instance2.transformation.inverse) == e.end.position
                        e.hidden = true
                        elsif pt1.transform(notch_instance2.transformation.inverse) == e.end.position && pt2.transform(notch_instance2.transformation.inverse) == e.start.position
                        e.hidden = true
                      end
                    }
                    
                    notch_instance1.definition.entities.grep(Sketchup::Edge) {|e|
                      if pt3.transform(notch_instance1.transformation.inverse) == e.start.position && pt4.transform(notch_instance1.transformation.inverse) == e.end.position
                        e.hidden = true
                        elsif pt3.transform(notch_instance1.transformation.inverse) == e.end.position && pt4.transform(notch_instance1.transformation.inverse) == e.start.position
                        e.hidden = true
                        elsif pt1.transform(notch_instance1.transformation.inverse) == e.start.position && pt2.transform(notch_instance1.transformation.inverse) == e.end.position
                        e.hidden = true
                        elsif pt1.transform(notch_instance1.transformation.inverse) == e.end.position && pt2.transform(notch_instance1.transformation.inverse) == e.start.position
                        e.hidden = true
                        elsif pt1.transform(notch_instance1.transformation.inverse) == e.start.position && pt3.transform(notch_instance1.transformation.inverse) == e.end.position
                        e.hidden = true
                        elsif pt1.transform(notch_instance1.transformation.inverse) == e.end.position && pt3.transform(notch_instance1.transformation.inverse) == e.start.position
                        e.hidden = true
                        elsif pt2.transform(notch_instance1.transformation.inverse) == e.start.position && pt4.transform(notch_instance1.transformation.inverse) == e.end.position
                        e.hidden = true
                        elsif pt2.transform(notch_instance1.transformation.inverse) == e.end.position && pt4.transform(notch_instance1.transformation.inverse) == e.start.position
                        e.hidden = true
                      end
                    }
                    
                    notch_instance1.definition.entities.grep(Sketchup::Face) {|f|
                      v_points = f.outer_loop.vertices.map{|v| v.position }
                      if v_points.include?(pt1.transform(notch_instance1.transformation.inverse)) && v_points.include?(pt2.transform(notch_instance1.transformation.inverse)) && v_points.include?(pt3.transform(notch_instance1.transformation.inverse)) && v_points.include?(pt4.transform(notch_instance1.transformation.inverse))
                        f.hidden = true
                      end
                    }
                    
                    entity.definition.entities.grep(Sketchup::Edge) {|e|
                      if pt3.transform(face_tr).transform(notch_tr.inverse) == e.start.position && pt4.transform(face_tr).transform(notch_tr.inverse) == e.end.position
                        e.hidden = true
                        elsif pt3.transform(face_tr).transform(notch_tr.inverse) == e.end.position && pt4.transform(face_tr).transform(notch_tr.inverse) == e.start.position
                        e.hidden = true
                        elsif pt1.transform(face_tr).transform(notch_tr.inverse) == e.start.position && pt2.transform(face_tr).transform(notch_tr.inverse) == e.end.position
                        e.hidden = true
                        elsif pt1.transform(face_tr).transform(notch_tr.inverse) == e.end.position && pt2.transform(face_tr).transform(notch_tr.inverse) == e.start.position
                        e.hidden = true
                        elsif pt1.transform(face_tr).transform(notch_tr.inverse) == e.start.position && pt3.transform(face_tr).transform(notch_tr.inverse) == e.end.position
                        e.hidden = true
                        elsif pt1.transform(face_tr).transform(notch_tr.inverse) == e.end.position && pt3.transform(face_tr).transform(notch_tr.inverse) == e.start.position
                        e.hidden = true
                        elsif pt2.transform(face_tr).transform(notch_tr.inverse) == e.start.position && pt4.transform(face_tr).transform(notch_tr.inverse) == e.end.position
                        e.hidden = true
                        elsif pt2.transform(face_tr).transform(notch_tr.inverse) == e.end.position && pt4.transform(face_tr).transform(notch_tr.inverse) == e.start.position
                        e.hidden = true
                      end
                    }
                    entity.definition.entities.grep(Sketchup::Face) {|f|
                      v_points = f.outer_loop.vertices.map{|v| v.position }
                      if v_points.include?(pt1.transform(face_tr).transform(notch_tr.inverse)) && v_points.include?(pt2.transform(face_tr).transform(notch_tr.inverse)) && v_points.include?(pt3.transform(face_tr).transform(notch_tr.inverse)) && v_points.include?(pt4.transform(face_tr).transform(notch_tr.inverse))
                        f.hidden = true
                      end
                    }
                    entity.definition.entities.grep(Sketchup::Group) {|g|
                      pts = (0..7).map { |i| g.bounds.corner(i) }
                      if pts.include?(pt1.transform(face_tr).transform(notch_tr.inverse)) && pts.include?(pt2.transform(face_tr).transform(notch_tr.inverse)) && pts.include?(pt3.transform(face_tr).transform(notch_tr.inverse)) && pts.include?(pt4.transform(face_tr).transform(notch_tr.inverse))
                        g.hidden = true
                      end
                    }
                  }
                end
                if notch_thick > essence_thick
                  point3 = Geom::Point3d.new(point2.x,point2.y,point2.z)
                  process_notch(ent,entity,point3.transform(face_tr),tr,essence_and_faces.select{|x| x != essence},essence_and_transformation,essences_with_notch)
                end
                else
                notch_instance1.definition.entities.grep(Sketchup::Edge) {|e| e.find_faces }
                notch_instance1.definition.entities.grep(Sketchup::Face) {|f|
                  f.erase! if ((f.bounds.center.z.abs+0.001)*25.4).round(1) == 0
                }
              end
            }
          end
        }
        hidden_elements.each { |e| e.hidden = true }
        new_comp.erase!
      end
      def set_att(entity,att,value)
        entity.set_attribute('dynamic_attributes', att, value)
        if entity.is_a?(Sketchup::ComponentInstance)
          entity.definition.set_attribute('dynamic_attributes', att, value)
        end
      end
      def redraw_groove(parent,entity,parent_size=true)
        local_origin_transform = entity.local_transformation
        entity.transform! local_origin_transform.inverse
        new_x = entity.transformation.origin.x.to_f
        new_y = entity.transformation.origin.y.to_f
        new_z = entity.transformation.origin.z.to_f
        definition_origin = Geom::Point3d.new(0,0,0)
        
        unscaled_lenx, unscaled_leny, unscaled_lenz = entity.unscaled_size
        target_lenx = get_cascading_attribute((parent_size ? parent : entity), 'lenx').to_f
        target_leny = get_cascading_attribute((parent_size ? parent : entity), 'leny').to_f
        target_lenz = get_cascading_attribute((parent_size ? parent : entity), 'lenz').to_f
        
        scale_transform = Geom::Transformation.scaling definition_origin,
        1.0/entity.transformation.xscale,
        1.0/entity.transformation.yscale,
        1.0/entity.transformation.zscale
        entity.transformation = entity.transformation * scale_transform
        
        if target_lenx != unscaled_lenx || target_leny != unscaled_leny || target_lenz != unscaled_lenz
          fix_float(unscaled_lenx) == 0.0 ? dlenx = 1.0 : dlenx = (target_lenx/unscaled_lenx).abs
          fix_float(unscaled_leny) == 0.0 ? dleny = 1.0 : dleny = (target_leny/unscaled_leny).abs
          fix_float(unscaled_lenz) == 0.0 ? dlenz = 1.0 : dlenz = (target_lenz/unscaled_lenz).abs
          origin = entity.transformation.origin
          dlenx = 0.001 if dlenx == 0.0
          dleny = 0.001 if dleny == 0.0
          dlenz = 0.001 if dlenz == 0.0
          #new_scale = Geom::Transformation.scaling origin, dlenx, dleny, dlenz
          #entity.transformation = entity.transformation * new_scale
          
          subentity_transform = Geom::Transformation.scaling definition_origin, dlenx, dleny, dlenz
          if dlenx != 1.0 || dleny != 1.0 || dlenz != 1.0
            naked_entities = []
            subentities = entity.definition.entities
            subentities.each { |subentity|
              if subentity.is_a?(Sketchup::Face) || subentity.is_a?(Sketchup::Edge)
                naked_entities.push subentity
              end
            }
            if naked_entities.length > 0
              subentities.transform_entities subentity_transform, naked_entities
            end
          end
        end
        
        if entity.is_a?(Sketchup::ComponentInstance)
          entity.definition.invalidate_bounds
        end
        
        dx = new_x.to_f - entity.transformation.origin.x.to_f
        dy = new_y.to_f - entity.transformation.origin.y.to_f
        dz = new_z.to_f - entity.transformation.origin.z.to_f
        translation_vector = Geom::Vector3d.new dx, dy, dz
        translation = Geom::Transformation.translation translation_vector
        entity.transform! translation
        entity.transform! local_origin_transform
      end
      def redraw_notch(entity)
        local_origin_transform = entity.local_transformation
        entity.transform! local_origin_transform.inverse
        new_x = entity.transformation.origin.x.to_f
        new_y = entity.transformation.origin.y.to_f
        new_z = entity.transformation.origin.z.to_f
        definition_origin = Geom::Point3d.new(0,0,0)
        
        scale_transform = Geom::Transformation.scaling definition_origin,
        1.0/entity.transformation.xscale,
        1.0/entity.transformation.yscale,
        1.0/entity.transformation.zscale
        entity.transformation = entity.transformation * scale_transform
        
        start_lenx,start_leny,start_lenz = entity.unscaled_size
        target_lenx = get_cascading_attribute(entity,'lenx').to_f
        target_leny = get_cascading_attribute(entity,'leny').to_f
        target_lenz = get_cascading_attribute(entity,'lenz').to_f
        store_nominal_size(entity,target_lenx,target_leny,target_lenz)
        fix_float(start_lenx) == 0.0 ? dlenx = 1.0 : dlenx = target_lenx/start_lenx
        fix_float(start_leny) == 0.0 ? dleny = 1.0 : dleny = target_leny/start_leny
        fix_float(start_lenz) == 0.0 ? dlenz = 1.0 : dlenz = target_lenz/start_lenz
        dlenx = 0.001 if dlenx == 0.0
        dleny = 0.001 if dleny == 0.0
        dlenz = 0.001 if dlenz == 0.0
        subentity_transform = Geom::Transformation.scaling definition_origin, dlenx, dleny, dlenz
        if dlenx != 1.0 || dleny != 1.0 || dlenz != 1.0
          naked_entities = []
          subentities = entity.definition.entities
          subentities.each { |subentity|
            if subentity.is_a?(Sketchup::Face) || subentity.is_a?(Sketchup::Edge)
              naked_entities.push subentity
            end
          }
          if naked_entities.length > 0
            subentities.transform_entities subentity_transform, naked_entities
          end
        end
        if entity.is_a?(Sketchup::ComponentInstance)
          entity.definition.invalidate_bounds
        end
        dx = new_x.to_f - entity.transformation.origin.x.to_f
        dy = new_y.to_f - entity.transformation.origin.y.to_f
        dz = new_z.to_f - entity.transformation.origin.z.to_f
        translation_vector = Geom::Vector3d.new dx, dy, dz
        translation = Geom::Transformation.translation translation_vector
        entity.transform! translation
        entity.transform! local_origin_transform
      end
      def get_cascading_attribute(entity,name)
        name = name.downcase
        value = entity.get_attribute("dynamic_attributes", name)
        if !value && entity.is_a?(Sketchup::ComponentInstance)
          value = entity.definition.get_attribute("dynamic_attributes", name)
        end
        return value
      end
      def fix_float(f)
        return ((f.to_f*10000000.0).round/10000000.0)
      end
      def store_nominal_size(entity,target_lenx,target_leny,target_lenz)
        entity.definition.set_attribute "dynamic_attributes", '_lenx_nominal', target_lenx
        entity.definition.set_attribute "dynamic_attributes", '_leny_nominal', target_leny
        entity.definition.set_attribute "dynamic_attributes", '_lenz_nominal', target_lenz
      end
      def delete_attributes(entity,att_arr)
        get_instance_attribute_list(entity,att_arr).each { |name|
          entity.delete_attribute("dynamic_attributes", name)
          if entity.is_a?(Sketchup::ComponentInstance)
            entity.definition.delete_attribute("dynamic_attributes", name)
          end
        }
      end
      def delete_attributes_formula(entity,att_arr)
        att_arr.each { |name|
          entity.delete_attribute("dynamic_attributes", '_'+name+'_formula')
          if entity.is_a?(Sketchup::ComponentInstance)
            entity.definition.delete_attribute("dynamic_attributes", '_'+name+'_formula')
          end
        }
      end
      def get_instance_attribute_list(entity,att_arr)
        list = []
        if entity.is_a?(Sketchup::ComponentInstance)
          attribute_entity = entity.definition
          if attribute_entity.attribute_dictionaries
            if attribute_entity.attribute_dictionaries["dynamic_attributes"]
              dictionary = attribute_entity.attribute_dictionaries["dynamic_attributes"]
              dictionary.keys.each { |key|
                att_arr.each { |name|
                  if key.index(name) == 0 || key.index('_'+name) == 0 || key.index(@instance_cache_prefix+name) == 0 || key.index(@instance_cache_prefix+'_'+name) == 0
                    list.push key.downcase
                  end
                }
              }
            end
          end
        end
        return list
      end
      def param_array_from_name(a03_name,parameters,a03_name_exception="Tandembox",name_exception="Tandem")
        parameters.each_pair { |key,value|
          key = key.gsub("  "," ").gsub("|","").gsub(",","").gsub(".","")
          name_array = key.split(" ")
          include = 0
          name_array.each { |name|
            if a03_name.include?(name)
              if a03_name.include?(a03_name_exception) && name == name_exception
                else
                include += 1
              end
            end
          }
          if include == name_array.length && value
            return value.split("&")
          end
        }
        return []
      end#def
      def make_holes(param,pt,pt_transformation,ent_transformation,width=nil)
        essence = nil
        pts = nil
        @touch_hash[0] = []
        if param[0]
          @fastener_indent = 0
          fastener_param = {}
          @fastener_parameters["Фурнитура"] = fastener_param
          fastener_param["fastener_name"] = "Фурнитура"
          fastener_param["visible"] = "false"
          fastener_param["active"] = "true"
          fastener_param["fastener_C"] = "0"
          fastener_param["fastener_n0"] = "0"
          fastener_param["min_dist"] = "0.5"
          fastener_param["axis"] = param[0]
          fastener_param["fastener_d1"] = param[1].to_f.round.to_s
          fastener_param["fastener_d1_depth"] = param[2].to_f.round.to_s
          fastener_param["multiple"] = param[6]
          fastener_param["multiple_dist"] = param[7]
          fastener_param["list_name1"] = param[8]
          fastener_param["color1"] = param[9]
          @active_fastener = "Фурнитура"
          @fastener_param = @fastener_parameters[@active_fastener]
          xaxis = pt_transformation.xaxis
          yaxis = pt_transformation.yaxis
          zaxis = pt_transformation.zaxis
          if width
            point_x = -1*param[3].to_f
            else
            point_x = param[3].to_f
          end
          pt1 = pt+Geom::Vector3d.new(xaxis.x*(point_x)/25.4,xaxis.y*(point_x)/25.4,xaxis.z*(point_x)/25.4)+Geom::Vector3d.new(yaxis.x*(param[4].to_f)/25.4,yaxis.y*(param[4].to_f)/25.4,yaxis.z*(param[4].to_f)/25.4)+Geom::Vector3d.new(zaxis.x*(param[5].to_f)/25.4,zaxis.y*(param[5].to_f)/25.4,zaxis.z*(param[5].to_f)/25.4)
          pt1 += Geom::Vector3d.new(xaxis.x*width,0,0) if width
          pt1.transform!(ent_transformation)
          touch_face=nil
          face_normal=nil
          parallel_face_normal=nil
          touch_essence=nil
          new_comp_transformation=nil
          normal1=nil
          normal2=nil
          if param[0].include?("X") || param[0].include?("x")
            normal1 = yaxis.transform(ent_transformation)
            (param[0].include?("-") && width==nil) ? normal2 = xaxis.reverse.transform(ent_transformation) : normal2 = xaxis.transform(ent_transformation)
            elsif param[0].include?("Y") || param[0].include?("y")
            normal1 = xaxis.transform(ent_transformation)
            param[0].include?("-") ? normal2 = yaxis.reverse.transform(ent_transformation) : normal2 = yaxis.transform(ent_transformation)
            elsif param[0].include?("Z") || param[0].include?("z")
            normal1 = yaxis.transform(ent_transformation)
            param[0].include?("-") ? normal2 = zaxis.reverse.transform(ent_transformation) : normal2 = zaxis.transform(ent_transformation)
          end
          if normal1 && normal2
            @essence_and_faces.each_pair { |essence,faces|
              if !essence.deleted? && essence.layer.visible?
                touch_face,face_normal,touch_essence,new_comp_transformation,distance=ask_for_touch_component(essence,pt1,pt1,pt1,normal1,normal2)
                break if touch_essence
              end
            }
          end
          if touch_essence
            @touch_hash[0] << [touch_essence,face_normal,normal2.transform(ent_transformation.inverse),ent_transformation,normal1,touch_face,new_comp_transformation]
            #zaxis.reverse! if zaxis.transform(ent_transformation).z == -1 # правая петля
            
            lenx = touch_essence.definition.get_attribute("dynamic_attributes", "lenx")
            leny = touch_essence.definition.get_attribute("dynamic_attributes", "leny")
            lenz = touch_essence.definition.get_attribute("dynamic_attributes", "lenz")
            
            if @hinge && param[6] != "1"&& @dimension_base == "2side"
              pt_in_module = pt
              zaxis_in_module = zaxis
              if pt.x == 0 && pt.y == 0 && pt.z == 0
                pt_in_module = pt.transform(@comp.parent.instances[-1].transformation)
                zaxis_in_module = zaxis.transform(@comp.parent.instances[-1].transformation)
              end
              if zaxis_in_module.z.round(1) != 0 && pt_in_module.z > lenz/2 # верхняя петля в модуле
                zaxis.reverse!
                elsif zaxis_in_module.x.round(1) != 0 && pt_in_module.x > lenz/2 # правая петля в модуле
                zaxis.reverse!
                elsif zaxis_in_module.x.round(1) != 0 && pt_in_module.x > leny/2 # правая петля в фасад
                zaxis.reverse!
              end
            end
            pt1 = pt+Geom::Vector3d.new(xaxis.x*(point_x)/25.4,xaxis.y*(point_x)/25.4,xaxis.z*(point_x)/25.4)+Geom::Vector3d.new(yaxis.x*(param[4].to_f)/25.4,yaxis.y*(param[4].to_f)/25.4,yaxis.z*(param[4].to_f)/25.4)+Geom::Vector3d.new(zaxis.x*(param[5].to_f)/25.4,zaxis.y*(param[5].to_f)/25.4,zaxis.z*(param[5].to_f)/25.4)
            pt1 += Geom::Vector3d.new(xaxis.x*width,0,0) if width!=nil
            pt1.transform!(ent_transformation)
            @ipface_normal = zaxis.transform(ent_transformation)
            essence = draw_fastener(pt1,0,-1,0)
            @essences << essence if essence && !@essences.include?(essence)
          end
        end
        return essence
      end
      def ask_for_touch_component(essence,pow1,pow2,pow3,ipface_normal,parallel_face_normal)
        comp_transformation = @essence_and_transformation[essence]
        psc1=pow1.transform(comp_transformation.inverse)
        psc2=pow2.transform(comp_transformation.inverse)
        psc3=pow3.transform(comp_transformation.inverse)
        fc,distance=is_pt_touching_s(essence,psc1,psc2,psc3,ipface_normal,parallel_face_normal,comp_transformation)
        if fc
          return fc,fc.normal.transform(comp_transformation),essence,comp_transformation,distance
        end
        return nil,nil,nil,nil,nil
      end#def
      def is_pt_touching_s(essence,pt1,pt2,pt3,ipface_normal,parallel_face_normal,transformation)
        distance=0
        lenx = essence.definition.get_attribute("dynamic_attributes", "lenx", "0").to_f
        @essence_and_all_faces[essence].each{|f|
          next if @fastener_by_template && f.normal.x.abs != 1
          next if f.deleted?
          project_point2 = pt2.project_to_plane f.plane
          project_result2 = f.classify_point(project_point2)
          distance2=project_point2.distance pt2
          project_point3 = pt3.project_to_plane f.plane
          project_result3 = f.classify_point(project_point3)
          distance3=project_point3.distance pt3
          face_normal = f.normal.transform(transformation)
          if (!face_normal.parallel? ipface_normal) && (parallel_face_normal.reverse == face_normal)
            result1 = f.classify_point(pt1)
            result2 = f.classify_point(pt2)
            result3 = f.classify_point(pt3)
            if result3 == Sketchup::Face::PointOnEdge || result3 == Sketchup::Face::PointInside
              #p 999999999999999999
                #p pt1
              #p result1
              
              #p pt2
              #p result2
              
              #p pt3
              #p result3
              if (result1 == Sketchup::Face::PointInside) && (result2 == Sketchup::Face::PointInside)
                #p 111
                return f,distance
                elsif (result1 == Sketchup::Face::PointOnEdge) && (result2 == Sketchup::Face::PointInside)
                #p 222
                return f,distance
                elsif (result1 == Sketchup::Face::PointInside) && (result2 == Sketchup::Face::PointOnEdge)
                #p 333
                return f,distance
                elsif (result1 == Sketchup::Face::PointOnEdge) && (result2 == Sketchup::Face::PointOnEdge)
                #p 444
                return f,distance
                elsif (result1 == Sketchup::Face::PointOnEdge) && (result2 == Sketchup::Face::PointOnVertex)
                #p 555
                return f,distance
                elsif (result1 == Sketchup::Face::PointOnVertex) && (result2 == Sketchup::Face::PointOnEdge)
                #p 666
                return f,distance
                #elsif (result1 == Sketchup::Face::PointOnVertex) && (result2 == Sketchup::Face::PointInside)
                  #p 777
                #return f,distance
              end
              elsif distance3-0.01 <= @fastener_param["min_dist"].to_f/25.4 && distance2-0.01 <= @fastener_param["min_dist"].to_f/25.4
              if project_result3==Sketchup::Face::PointInside && project_result2==Sketchup::Face::PointOnEdge || project_result3==Sketchup::Face::PointOnEdge && project_result2==Sketchup::Face::PointInside || project_result3==Sketchup::Face::PointInside && project_result2==Sketchup::Face::PointInside
                #p 888
                return f,distance2
              end
            end
            #p 999
          end
        }
        return nil,distance
      end#def
      
      def onLButtonDown(flags, x, y, view)
        @mouse_down = Geom::Point3d.new(x, y, 0)
      end#def
      def dragging?
        @mouse_down && @mouse_down.distance(@mouse_position) > 10
      end
      def drag_pick_inside
        @mouse_down.x < @mouse_position.x
      end
      def drag_pick_type
        if drag_pick_inside
          Sketchup::PickHelper::PICK_INSIDE
          else
          Sketchup::PickHelper::PICK_CROSSING
        end
      end
      def mouse_rectangle
        [
          @mouse_position,
          Geom::Point3d.new(@mouse_position.x, @mouse_down.y, 0),
          @mouse_down,
          Geom::Point3d.new(@mouse_down.x, @mouse_position.y, 0)
        ]
      end
      def all_visible_entities(entity,visible_entities=[])
        if !entity.hidden? && entity.layer.visible?
          visible_entities << entity if !visible_entities.include?(entity)
          if entity.is_a?(Sketchup::ComponentInstance)
            entity.definition.entities.to_a.each{|e|all_visible_entities(e,visible_entities)}
            elsif entity.is_a?(Sketchup::Group)
            entity.entities.to_a.each{|e|all_visible_entities(e,visible_entities)}
          end
        end
        return visible_entities
      end
      def onLButtonUp(flags, x, y, view)
        ph = view.pick_helper
        
        if dragging?
          num_picked = ph.window_pick(@mouse_down, @mouse_position, drag_pick_type)
          if num_picked > 0
            picked = []
            context = @model.active_entities
            ph.count.times { |pick_path_index|
              path = ph.path_at(pick_path_index)
              found = path.find { |entity| context == entity.parent.entities }
              picked << found if found
            }
            picked.uniq!
            if picked != []
              if @control_press == true && @shift_press == true
                picked.each {|entity|
                  if @sel.include?(entity)
                    @sel.remove entity
                  end
                }
                elsif @shift_press == true
                if @sel.length > 0
                  picked.each {|entity|
                    if @sel.include?(entity)
                      @sel.remove entity
                      else
                      @sel.add entity
                    end
                  }
                  else
                  @sel.add picked
                end
                elsif @control_press == true
                @sel.add(picked)
                else
                @sel.clear
                @sel.add(picked)
              end
              else
              @sel.clear
            end
            else
            @sel.clear
          end
          
          @mouse_down = nil
          view.invalidate
          
          elsif @fastener_point != 0
          save_active_fastener(view,@fastener_point)
          
          elsif @draw_options
          read_draw_param
          prompts = ["#{SUF_STRINGS["Position of buttons"]}: "]
          list = ["#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Top"]}|#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Bottom"]}|#{SUF_STRINGS["Left"]} #{SUF_STRINGS["below the list"]}|#{SUF_STRINGS["Left"]} #{SUF_STRINGS["Bottom"]}|#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Top"]}|#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Bottom"]}"]
          input = UI.inputbox prompts, @draw_param, list, SUF_STRINGS["Placement parameters"]
          if input
            save_draw_options(view,input)
            @draw_param = input
          end
          
          elsif @delete_fastener
          ents = @ents.grep(Sketchup::ComponentInstance)
          @sel.to_a.each {|entity| @sel.remove entity if @model.active_entities != entity.parent.entities}
          @delete_fastener_array = []
          delete_dialog()
          if @delete_fastener_array != [] && !@delete_fastener_array.all?{|str|str==false}
            @model.start_operation "Delete fastener", true
            if @delete_fastener_array[0] || @delete_fastener_array[4] #все отверстия
              if @delete_fastener_array[4]
                ents = @sel.grep(Sketchup::ComponentInstance)
              end
              reset_comp_with_essence(ents)
              @essences = []
              @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"",true) }
              reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
              else
              if @delete_fastener_array[1] || @delete_fastener_array[5] #отверстия по шаблону
                if @delete_fastener_array[5]
                  ents = @sel.grep(Sketchup::ComponentInstance)
                end
                reset_comp_with_essence(ents)
                @essences = []
                @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"template",true) }
                essences_dimensions(@essences)
                reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
              end
              if @delete_fastener_array[2] || @delete_fastener_array[6] #отверстия фурнитуры
                if @delete_fastener_array[6]
                  ents = @sel.grep(Sketchup::ComponentInstance)
                end
                reset_comp_with_essence(ents)
                @essences = []
                @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"furniture",true) }
                essences_dimensions(@essences)
                reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
              end
              if @delete_fastener_array[2] || @delete_fastener_array[6] #отдельные отверстия
                if @delete_fastener_array[6]
                  ents = @sel.grep(Sketchup::ComponentInstance)
                end
                reset_comp_with_essence(ents)
                @essences = []
                @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"hole",true) }
                essences_dimensions(@essences)
                reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
              end
            end
            @model.commit_operation
          end
          
          elsif @visible_side
          @model.select_tool( Visible_Side )
          @visible_side = false
          
          elsif @without_fastener
          @model.select_tool( Without_Fastener )
          @without_fastener = false
          
          elsif @fastener_by_template
          @model.start_operation "Fastener by template", true
          @shift_press=true
          @control_press=true
          @fastener_pts = {}
          @a03_name = nil
          @process_by_template = true
          @change_shelf_fastener = {}
          ents = @ents.grep(Sketchup::ComponentInstance)
          @sel.to_a.each {|entity| @sel.remove entity if @model.active_entities != entity.parent.entities}
          commit = false
          if @sel.grep(Sketchup::ComponentInstance).length > 0
            prompts = ["#{SUF_STRINGS["Drill"]}: "]
            defaults = [SUF_STRINGS["Only selected"]]
            list = ["#{SUF_STRINGS["Only selected"]}|#{SUF_STRINGS["All panels"]}"]
            input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Parameters"]
            if input
              if input[0] == SUF_STRINGS["Only selected"]
                ents = @sel.grep(Sketchup::ComponentInstance)
              end
              else
              commit = true
            end
          end
          if !commit
            reset_comp_with_essence(ents)
            fastener_by_template(view)
            reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
          end
          @shift_press=false
          @control_press=false
          @a03_name = nil
          @rule1 = nil
          @rule2 = nil
          @active_fastener2 = nil
          @fastener_indent2 = 0
          @fastener_param2 = nil
          @draw_other_side = false
          @process_by_template = false
          @change_shelf_fastener = {}
          @touch_hash = {}
          @reverse_type_fastener1 = "0"
          @reverse_type_fastener2 = "0"
          @model.commit_operation
          
          elsif @fastener_furniture
          @model.start_operation "Accessories holes", true
          @process_accessories = true
          @change_shelf_fastener = {}
          current_active_fastener = @active_fastener
          current_fastener_indent = @fastener_indent
          ents = @ents.grep(Sketchup::ComponentInstance)
          @sel.to_a.each {|entity| @sel.remove entity if @model.active_entities != entity.parent.entities}
          commit = false
          if @sel.grep(Sketchup::ComponentInstance).length > 0
            prompts = ["#{SUF_STRINGS["Drill"]}: "]
            defaults = [SUF_STRINGS["Only selected"]]
            list = ["#{SUF_STRINGS["Only selected"]}|#{SUF_STRINGS["All panels"]}"]
            input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Parameters"]
            if input
              if input[0] == SUF_STRINGS["Only selected"]
                ents = @sel.grep(Sketchup::ComponentInstance)
              end
              else
              commit = true
            end
          end
          if !commit
            reset_comp_with_essence(ents)
            @essences = []
            @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"furniture") }
            reset_comp_with_essence(@ents.grep(Sketchup::ComponentInstance)) if @ents != ents
            @essences = []
            @comps = []
            @pids = []
            ents.each { |ent| all_pids(ent) }
            ents.each { |ent|
              trans = Geom::Transformation.new
              if !ent.definition.get_attribute("dynamic_attributes", "hinge_regulation") && ent.definition.get_attribute("dynamic_attributes", "_name", "").include?("Hinge")
                ent.set_attribute("dynamic_attributes", "hinge_regulation", 0)
                ent.definition.set_attribute("dynamic_attributes", "hinge_regulation", 0)
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_label", 'hinge_regulation')
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_access", 'TEXTBOX')
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_formlabel", 'Регулировка петли')
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_formulaunits", 'CENTIMETERS')
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_options", '&')
                ent.definition.set_attribute("dynamic_attributes", "_hinge_regulation_units", 'MILLIMETERS')
              end
              search_furniture(ent,trans)
            }
            essences_dimensions(@essences)
          end
          @fastener_indent = current_fastener_indent
          @active_fastener = current_active_fastener
          @fastener_param = @fastener_parameters[@active_fastener]
          @process_accessories = false
          @change_shelf_fastener = {}
          @touch_hash = {}
          @model.commit_operation
          
          elsif @fastener_hole
          Drill_Hole.import_essence_and_transformation(@essence_and_transformation)
          @model.select_tool( Drill_Hole )
          @fastener_hole = false
          
          elsif !@draw_background && @comp && @fastener_select == true
          @model.start_operation "Fastener", true
          @essences = []
          @change_shelf_fastener = {}
          @essences = fastener_operation(@essences)
          essences_dimensions(@essences)
          @change_shelf_fastener = {}
          @model.commit_operation
        end
        @mouse_down = nil
      end#def
      def all_pids(ent)
        @pids << ent.persistent_id if !@pids.include?(ent.persistent_id)
        ent.definition.entities.grep(Sketchup::ComponentInstance).each{ |e| all_pids(e) }
      end
      def delete_dialog
        html = "<style>"
        html += "body { font-family: Arial; color: #696969; font-size: 16px; }"
        html += "#name_table {  width: 100%; border-collapse: collapse; font-size: 12px; }  "        
        html += "#name_table th{ padding: 3px; }"
        html += "#name_table td { padding: 3px; border: 1px solid gray; }"
        html += "#name_table td:not(:first-child) { text-align: center; }"
        html += "</style>"
        html += "<script>"
        html += "function change_checkbox(elem){"
        
        html += "if(elem.id==\"delete_all_in_model\"){"
        html += "let all_model_checkbox = document.getElementsByClassName('in_model');"
        html += "for (let i = 0; i < all_model_checkbox.length; i++) {"
        html += "all_model_checkbox[i].checked = elem.checked;"
        html += "}"
        html += "document.getElementById('delete_all_in_selected').checked = false;"
        html += "let all_selected_checkbox = document.getElementsByClassName('in_selected');"
        html += "for (let i = 0; i < all_selected_checkbox.length; i++) {"
        html += "all_selected_checkbox[i].checked = false;"
        html += "}"
        
        html += "}else if(elem.id==\"delete_all_in_selected\"){"
        html += "let all_selected_checkbox = document.getElementsByClassName('in_selected');"
        html += "for (let i = 0; i < all_selected_checkbox.length; i++) {"
        html += "all_selected_checkbox[i].checked = elem.checked;"
        html += "}"
        html += "document.getElementById('delete_all_in_model').checked = false;"
        html += "let all_model_checkbox = document.getElementsByClassName('in_model');"
        html += "for (let i = 0; i < all_model_checkbox.length; i++) {"
        html += "all_model_checkbox[i].checked = false;"
        html += "}"
        
        html += "}else if(elem.classList.contains(\"in_model\")){"
        html += "if(elem.checked){"
        html += "let all_model_checkbox = document.getElementsByClassName('in_model');"
        html += "let checked_count = 0;"
        html += "for (let i = 0; i < all_model_checkbox.length; i++) {"
        html += "if(all_model_checkbox[i].checked){checked_count += 1;}"
        html += "}"
        html += "if(checked_count==all_model_checkbox.length){"
        html += "document.getElementById('delete_all_in_model').checked = true;"
        html += "document.getElementById('delete_all_in_selected').checked = false;"
        html += "}"
        html += "document.getElementById(elem.id.slice(0,elem.id.length-5)+'selected').checked = false;"
        html += "document.getElementById('delete_all_in_selected').checked = false;"
        html += "}else{"
        html += "document.getElementById('delete_all_in_model').checked = false;"
        html += "}"
        
        html += "}else if(elem.classList.contains(\"in_selected\")){"
        html += "if(elem.checked){"
        html += "let all_selected_checkbox = document.getElementsByClassName('in_selected');"
        html += "let checked_count = 0;"
        html += "for (let i = 0; i < all_selected_checkbox.length; i++) {"
        html += "if(all_selected_checkbox[i].checked){checked_count += 1;}"
        html += "}"
        html += "if(checked_count==all_selected_checkbox.length){"
        html += "document.getElementById('delete_all_in_selected').checked = true;"
        html += "document.getElementById('delete_all_in_model').checked = false;"
        html += "}"
        html += "document.getElementById(elem.id.slice(0,elem.id.length-8)+'model').checked = false;"
        html += "document.getElementById('delete_all_in_model').checked = false;"
        html += "}else{"
        html += "document.getElementById('delete_all_in_selected').checked = false;"
        html += "}"
        html += "}"
        
        html += "}"
        html += "</script>"
        @sel.grep(Sketchup::ComponentInstance).to_a.length == 0 ? disabled = 'disabled' : disabled = ''
        html += "<table id=\"name_table\" ><th></th><th>#{SUF_STRINGS["In model"]}</th><th>#{SUF_STRINGS["From selected"]}</th>"
        html += "<tr><td>#{SUF_STRINGS["Delete all holes"]}:</td><td><input id=\"delete_all_in_model\" onchange=\"change_checkbox(this)\" type=\"checkbox\"></td>"
        html += "<td><input id=\"delete_all_in_selected\" onchange=\"change_checkbox(this)\" #{disabled} type=\"checkbox\"></td></tr>"
        html += "<tr><td>#{SUF_STRINGS["Delete template holes"]}:</td><td><input id=\"delete_template_in_model\" onchange=\"change_checkbox(this)\" class=\"in_model\" type=\"checkbox\"></td>"
        html += "<td><input id=\"delete_template_in_selected\" onchange=\"change_checkbox(this)\" class=\"in_selected\" #{disabled} type=\"checkbox\"></td></tr>"
        html += "<tr><td>#{SUF_STRINGS["Delete hardware holes"]}:</td><td><input id=\"delete_accessories_in_model\" onchange=\"change_checkbox(this)\" class=\"in_model\" type=\"checkbox\"></td>"
        html += "<td><input id=\"delete_accessories_in_selected\" onchange=\"change_checkbox(this)\" class=\"in_selected\" #{disabled} type=\"checkbox\"></td></tr>"
        html += "<tr><td>#{SUF_STRINGS["Delete separate holes"]}:</td><td><input id=\"delete_holes_in_model\" onchange=\"change_checkbox(this)\" class=\"in_model\" type=\"checkbox\"></td>"
        html += "<td><input id=\"delete_holes_in_selected\" onchange=\"change_checkbox(this)\" class=\"in_selected\" #{disabled} type=\"checkbox\"></td></tr>"
        html += "</table></br>"
        str = "document.getElementById('delete_all_in_model').checked,document.getElementById('delete_template_in_model').checked,document.getElementById('delete_accessories_in_model').checked,document.getElementById('delete_holes_in_model').checked,document.getElementById('delete_all_in_selected').checked,document.getElementById('delete_template_in_selected').checked,document.getElementById('delete_accessories_in_selected').checked,document.getElementById('delete_holes_in_selected').checked"
        html += "<button onclick=\"sketchup.callback([#{str}])\">OK</button>"
        @dlg.close if @dlg && (@dlg.visible?)
        @dlg = UI::HtmlDialog.new({
          :dialog_title => ' ',
          :preferences_key => "delete_fastener",
          :scrollable => false,
          :resizable => false,
          :width => 500,
          :height => 300,
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
        @dlg.set_html(html)
        @dlg.add_action_callback("callback") { |_, v|
          @delete_fastener_array = v
          @dlg.close
        }
        OSX ? @dlg.show() : @dlg.show_modal()
      end
      def save_draw_options(view,input)
        temp_param = File.join(TEMP_PATH, "SUF", "draw_options.dat")
        param_file = File.new(temp_param,"w")
        param_file.puts input[0]
        param_file.close
        path_param = File.join(PATH, "parameters", "draw_options.dat")
        param_file = File.new(path_param,"w")
        param_file.puts input[0]
        param_file.close
        view.invalidate
      end#def
      def fastener_by_template(view)
        read_param
        current_fastener_position = @fastener_position
        if @template["type_fastener"][2] != "current"
          @fastener_position = @template["type_fastener"][2]
        end
        @essences = []
        @essence_and_comp.each_pair { |essence,comp| delete_fastener(comp,essence,"template") }
        @essence_and_comp.each_pair { |essence,comp|
          if !essence.definition.get_attribute("dynamic_attributes", "without_fastener")
            current_active_fastener = @active_fastener
            current_fastener_indent = @fastener_indent
            @constlines_pts = {}
            @comp = comp
            @essence = essence
            @a03_name = @comp.definition.get_attribute("dynamic_attributes", "a03_name")
            @a03_name = @comp.definition.get_attribute("dynamic_attributes", "l1_component_102_article") if !@a03_name
            panel_type = @comp.definition.get_attribute("dynamic_attributes", "name", "0")
            panel_type = "Vertical" if panel_type !~ /Vertical|Horizontal|Frontal/i
            point_x_offset = @comp.definition.get_attribute("dynamic_attributes", "point_x_offset")
            @point_y_offset = @comp.definition.get_attribute("dynamic_attributes", "point_y_offset")
            point_z_offset = @comp.definition.get_attribute("dynamic_attributes", "point_z_offset")
            @a01_gluing = @comp.definition.get_attribute("dynamic_attributes", "a01_gluing", "1").to_f
            @lenx = essence.definition.get_attribute("dynamic_attributes", "lenx", "0").to_f
            @leny = essence.definition.get_attribute("dynamic_attributes", "leny", "0").to_f
            @lenz = essence.definition.get_attribute("dynamic_attributes", "lenz", "0").to_f
            if @comp.definition.get_attribute("dynamic_attributes", "v0_cut")
              @comp.set_attribute("dynamic_attributes", "v0_cut", "2")
              @comp.definition.set_attribute("dynamic_attributes", "v0_cut", "2")
            end
            to_return = false
            if @template["horizontal_common"].count==4 || @template["horizontal_common"].count==6
              UI.messagebox("#{SUF_STRINGS["Reset template settings in Parameters"]}\n#{SUF_STRINGS["and restart the tool."]}")
              to_return = true
              return
              elsif @template["horizontal_common"].count < 10
              UI.messagebox("#{SUF_STRINGS["Resave template settings in Parameters"]}\n#{SUF_STRINGS["and restart the tool."]}")
              to_return = true
            end
            if to_return
              @canceled = true
              @model.commit_operation
              @model.select_tool(nil)
              return
            end
            name_template = []
            @rule1 = nil
            @rule2 = nil
            @a03_name_without_fastener = false
            @template.each_pair { |key,value|
              if @a03_name && @a03_name == value[0] && value[1].include?(panel_type.downcase)
                if !value[2].to_s.strip.empty? && !value[3].to_s.strip.empty? && !value[4].to_s.strip.empty?
                  name_template = value
                  @active_fastener = value[2]
                  @rule1 = value[3]
                  @fastener_indent = value[4].to_f
                  @reverse_type_fastener1 = value[5]
                  @fastener_param = @fastener_parameters[@active_fastener]
                end
                if !value[6].to_s.strip.empty? && !value[7].to_s.strip.empty? && !value[8].to_s.strip.empty?
                  name_template = value
                  @active_fastener2 = value[6]
                  @rule2 = value[7]
                  @fastener_indent2 = value[8].to_f
                  @reverse_type_fastener2 = value[9]
                  @fastener_param2 = @fastener_parameters[@active_fastener2]
                end
                if !@rule1 && !@rule2
                  @a03_name_without_fastener = true
                  break
                end
              end
            }
            if name_template == [] && !@a03_name_without_fastener
              common_template = @template[panel_type.downcase+"_common"]
              if !common_template[2].to_s.strip.empty? && !common_template[3].to_s.strip.empty? && !common_template[4].to_s.strip.empty?
                @active_fastener = common_template[2]
                @rule1 = common_template[3]
                @fastener_indent = common_template[4].to_f
                @reverse_type_fastener1 = common_template[5]
                @fastener_param = @fastener_parameters[@active_fastener]
              end
              if !common_template[6].to_s.strip.empty? && !common_template[7].to_s.strip.empty? && !common_template[8].to_s.strip.empty?
                @active_fastener2 = common_template[6]
                @rule2 = common_template[7]
                @fastener_indent2 = common_template[8].to_f
                @reverse_type_fastener2 = common_template[9]
                @fastener_param2 = @fastener_parameters[@active_fastener2]
              end
              if !@rule1 && !@rule2
                UI.messagebox("#{SUF_STRINGS["In Parameters under the Template tab"]}\n#{SUF_STRINGS["no rules specified for:"]}:\n\n#{common_template[0]}")
                @canceled = true
                @model.commit_operation
                @model.select_tool(nil)
                return
              end
            end
            if @rule1 || @rule2
              @ipface = nil
              @ipface2 = nil
              vertical_faces = {}
              horizontal_faces = {}
              frontal_faces = {}
              tr = @essence_and_transformation_of_module[essence][0]
              p_lenx = @essence_and_transformation_of_module[essence][1]
              p_leny = @essence_and_transformation_of_module[essence][2]
              p_lenz = @essence_and_transformation_of_module[essence][3]
              groove = nil
              essence.definition.entities.grep(Sketchup::ComponentInstance).each { |g|
                if g.definition.name.include?("grooveL") && !g.hidden?
                  groove = "L"
                  elsif g.definition.name.include?("grooveR") && !g.hidden?
                  groove = "R"
                end
              }
              essence.definition.entities.grep(Sketchup::Face).each { |f|
                if f.normal.x.abs == 1
                  if p_lenx && f.normal.transform(tr).x.abs == 1
                    if groove && @place_fastener.include?("groove")
                      if groove == "R"
                        f.bounds.center.x == 0 ? @ipface2 = f : @ipface = f
                        elsif groove == "L"
                        f.bounds.center.x == 0 ? @ipface = f : @ipface2 = f
                      end
                      else
                      vertical_faces[f] = f.bounds.center.transform(tr)
                    end
                    
                    elsif p_leny && f.normal.transform(tr).y.abs == 1
                    frontal_faces[f] = f.bounds.center.transform(tr)
                    
                    elsif f.normal.transform(tr).z.abs == 1
                    if groove && @place_fastener.include?("groove")
                      if groove == "R"
                        f.bounds.center.x == 0 ? @ipface2 = f : @ipface = f
                        elsif groove == "L"
                        f.bounds.center.x == 0 ? @ipface = f : @ipface2 = f
                      end
                      else
                      if p_lenz && f.bounds.center.transform(tr).z > p_lenz-2
                        horizontal_faces[f] = f.bounds.center.transform(tr)
                        else
                        f.normal.transform(tr).z == 1 ? @ipface2 = f : @ipface = f
                      end
                    end
                    else
                    f.bounds.center.x == 0 ? @ipface2 = f : @ipface = f
                  end
                end
              }
              
              if vertical_faces != {} && vertical_faces.count == 2
                @ipface = vertical_faces.sort_by {|f,pt| (pt.x-p_lenx/2).abs}[1][0]
                @ipface2 = vertical_faces.sort_by {|f,pt| (pt.x-p_lenx/2).abs}[0][0]
              end
              
              if frontal_faces != {} && frontal_faces.count == 2
                @ipface = frontal_faces.sort_by {|f,pt| (pt.y-p_leny/2).abs}[1][0]
                @ipface2 = frontal_faces.sort_by {|f,pt| (pt.y-p_leny/2).abs}[0][0]
              end
              
              if horizontal_faces != {} && horizontal_faces.count == 2
                @ipface = horizontal_faces.sort_by {|f,pt| (p_lenz-pt.z).abs}[0][0]
                @ipface2 = horizontal_faces.sort_by {|f,pt| (p_lenz-pt.z).abs}[1][0]
              end
              
              @shelf_fastener = false
              @shelf_fastener = true if @a03_name.include?("Полка съемная")
              if @ipface
                @ipface = @ipface2 if @ipface.get_attribute("dynamic_attributes", "visible_side")
                @touch_hash = {}
                @width_length = 10
                @height_length = 10
                if @a01_gluing > 1
                  @thick = @lenx/@a01_gluing
                  else
                  @thick = @lenx
                end
                search_elements
                touch_comp = false
                (0..1).each { |index| touch_comp ||= @rule1 && @touch_hash[index] && !@touch_hash[index].empty? }
                (2..3).each { |index| touch_comp ||= @rule2 && @touch_hash[index] && !@touch_hash[index].empty? }
                
                if !touch_comp && @a03_name && @a03_name.include?("Полка")
                  @template.each_pair { |key,value|
                    if value.include?("Полка съемная")
                      if @template[key][2].to_s.strip.empty? || @template[key][3].to_s.strip.empty? || @template[key][4].to_s.strip.empty?
                        UI.messagebox("#{SUF_STRINGS["In Parameters under the Template tab"]}\n#{SUF_STRINGS["no rules specified for:"]}:\n\n#{@template[key][0]}")
                        @canceled = true
                        @model.commit_operation
                        @model.select_tool(nil)
                        return
                        else
                        @active_fastener = @template[key][2]
                        @rule1 = @template[key][3]
                        @fastener_indent = @template[key][4].to_f
                        @reverse_type_fastener1 = @template[key][5]
                        @fastener_param = @fastener_parameters[@active_fastener]
                        @shelf_fastener = true
                        if !@template[key][6].to_s.strip.empty? && !@template[key][7].to_s.strip.empty? && !@template[key][8].to_s.strip.empty?
                          @active_fastener2 = @template[key][6]
                          @rule2 = @template[key][7]
                          @fastener_indent2 = @template[@rule2][8].to_f
                          @reverse_type_fastener1 = @template[@rule2][9]
                          @fastener_param2 = @fastener_parameters[@active_fastener2]
                        end
                      end
                      break
                    end
                  }
                  @width_length = 10
                  @height_length = 10
                  search_elements
                  touch_comp = false
                  for index in 0..1
                    if @rule1 && @touch_hash[index] && @touch_hash[index] != []
                      touch_comp = true
                    end
                  end
                  for index in 2..3
                    if @rule2 && @touch_hash[index] && @touch_hash[index] != []
                      touch_comp = true
                    end
                  end
                end
                if touch_comp
                  if @fastener_param && @fastener_param["fastener_dside1_depth"].to_f > @height_length*25.4
                    @active_fastener = @check_depth
                    @fastener_param = @fastener_parameters[@active_fastener]
                  end
                  if @fastener_param2 && @fastener_param2["fastener_dside1_depth"].to_f > @width_length*25.4
                    @active_fastener2 = @check_depth
                    @fastener_param2 = @fastener_parameters[@active_fastener2]
                  end
                  
                  #p "Панель: #{@a03_name}"
                  if @fastener_param
                    #p 1111111111111
                      #p @rule1
                      #p @active_fastener
                    #p @fastener_indent
                  end
                  if @fastener_param2
                    #p 2222222222222
                      #p @rule2
                      #p @active_fastener2
                    #p @fastener_indent2
                  end
                  costruction_lines_pts(@rule1,@rule2,true)
                  @fastener_pts = {}
                  if @constlines_pts != {}
                    @fastener_select = true
                    fastener_pts_collect(view,false)
                    @essences = fastener_operation(@essences)
                  end
                end
              end
            end
            @shelf_fastener = false
            @fastener_indent = current_fastener_indent
            @active_fastener = current_active_fastener
            @fastener_param = @fastener_parameters[@active_fastener]
          end
        }
        @fastener_position = current_fastener_position
        essences_dimensions(@essences)
      end#def
      def additional_fastener_count(len)
        count = 2
        @additional_fastener_hash.each_pair { |width,fastener_count|
          if len >= width/25.4
            count = fastener_count
          end
        }
        return count
      end
      def fastener_pts_collect(view,draw=true)
        @constlines_pts.each_pair {|edge_index,arr|                   # номер торца
          if !@fastener_pts[edge_index]
            @fastener_pts[edge_index] = []
            arr.each_with_index{|constlines_arr,j|                    # номер стыка
              fastener_pts = []
              constlines_arr.each_with_index { |constline_pts,index|  # номер направляющей
                if constline_pts[0] && constline_pts[1]
                  view.line_stipple = ""
                  if edge_index == 0 || edge_index == 1
                    if index == 0 || index == 2
                      if draw
                        view.draw_lines constline_pts
                        if @dimension_pts[constline_pts[0]]
                          point = view.screen_coords(@dimension_pts[constline_pts[0]][0])
                          draw_text(view,point, @dimension_pts[constline_pts[0]][1].to_s, @title_default_options)
                        end
                      end
                      fastener_pts[index] = constline_pts[0]
                      elsif index == 1
                      if @point_y_offset && additional_fastener_count(@lenz).odd? || !@point_y_offset && additional_fastener_count(@leny).odd?
                        if draw
                          view.draw_lines constline_pts
                        end
                        fastener_pts[index] = constline_pts[0]
                        else
                        if draw
                          view.line_stipple = "-"
                          view.draw_lines constline_pts
                        end
                      end
                      else
                      if draw
                        view.draw_lines constline_pts
                        if @dimension_pts[constline_pts[0]]
                          point = view.screen_coords(@dimension_pts[constline_pts[0]][0])
                          draw_text(view,point, @dimension_pts[constline_pts[0]][1].to_s, @title_default_options)
                        end
                      end
                      fastener_pts[index] = constline_pts[0]
                    end
                  end
                  if @rule2
                    if edge_index == 2 || edge_index == 3
                      if index == 0 || index == 2
                        if draw
                          view.draw_lines constline_pts
                        end
                        fastener_pts[index] = constline_pts[0]
                        elsif index == 1
                        if @point_y_offset && additional_fastener_count(@leny).odd? || !@point_y_offset && additional_fastener_count(@lenz).odd?
                          if draw
                            view.draw_lines constline_pts
                          end
                          fastener_pts[index] = constline_pts[0]
                          else
                          if draw
                            view.line_stipple = "-"
                            view.draw_lines constline_pts
                          end
                        end
                        else
                        if draw
                          view.draw_lines constline_pts
                        end
                        fastener_pts[index] = constline_pts[0]
                      end
                    end
                  end
                end
              }
              @fastener_pts[edge_index] << fastener_pts
            }
          end
        }
      end#def
      
      def fastener_operation(essences)
        if @fastener_pts != {}
          @fastener_pts.each_pair { |edge_index,fastener_pts|  # номер торца
            fastener_pts.each_with_index { |pts,index|         # номер стыка
              if pts != []
                pts.each_with_index { |pt,i|
                  if pt
                    essence = draw_fastener(pt,edge_index,index,i)
                    essences << essence if essence && !essences.include?(essence)
                    essences << @essence if @essence && !essences.include?(@essence)
                    if @touch_comp_fastener_array != []
                      @comp.set_attribute("dynamic_attributes", "v0_cut", "2")
                      @comp.definition.set_attribute("dynamic_attributes", "v0_cut", "2")
                    end
                  end
                }
              end
            }
          }
        end
        return essences
      end#def
      def save_active_fastener(view,fastener)
        fastener_parameters = Hash.new
        param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
        if param_temp_path && File.file?(File.join(param_temp_path,"fasteners.dat"))
          path_fastener = File.join(param_temp_path,"fasteners.dat")
          elsif File.file?(File.join(TEMP_PATH,"SUF","fasteners.dat"))
          path_fastener = File.join(TEMP_PATH,"SUF","fasteners.dat")
          else
          path_fastener = File.join(PATH,"parameters","fasteners.dat")
        end
        content = File.readlines(path_fastener)
        param_file = File.new(path_fastener,"w")
        content.each { |i|
          param_array = i.strip.split(",")
          fastener_param = Hash.new
          fastener_parameters[param_array[0].split("=>")[1]]=fastener_param
          param_array.each { |param| fastener_param[param.split("=>")[0]]=param.split("=>")[1] }
          if param_array[0].split("=>")[1] == fastener
            fastener_param["active"] = "true"
            else
            fastener_param["active"] = "false"
          end
          new_content = ""
          fastener_param.each { |key,value| new_content += key+"=>"+value.to_s+"," }
          param_file.puts new_content[0..-2]
        }
        param_file.close
        read_param
        fastener_parameters.each { |key,value|
          @active_fastener = key if value["active"] == "true"
        }
        @fastener_param = @fastener_parameters[@active_fastener]
        view.invalidate
      end#def
      def change_fastener_position(view)
        param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
        if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
          path_param = File.join(param_temp_path,"parameters.dat")
          elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
          path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
          else
          path_param = File.join(PATH,"parameters","parameters.dat")
        end
        content = File.readlines(path_param)
        next_fastener_position_index = 0
        fastener_position_array = @fastener_position_array.split("=")[4].strip[1..-1].split("&")
        fastener_position_array.each_with_index { |fastener_pos,i|
          if @fastener_position == fastener_pos.split("^")[0]
            next_fastener_position_index = i+1
            next_fastener_position_index = 0 if next_fastener_position_index == fastener_position_array.length
            @fastener_position_array = @fastener_position_array.split("=")[0]+"="+@fastener_position_array.split("=")[1]+"="+fastener_position_array[next_fastener_position_index].split("^")[0]+"="+@fastener_position_array.split("=")[3]+"="+@fastener_position_array.split("=")[4]
            @fastener_position = fastener_position_array[next_fastener_position_index].split("^")[0]
            param_file = File.new(path_param,"w")
            content[@fastener_position_index] = @fastener_position_array
            content.each { |i| param_file.puts i }
            param_file.close
            read_param
            view.invalidate
            draw(view)
            return
          end
        }
      end#def
      def search_fastener_index(dict,index)
        @index = index
        dict.each_key {|attr| search_index(attr,index) if attr.include?("z") && attr.include?("_name")}
        return @index
      end#def
      def search_index(attr,index)
        if attr.include?("z"+index.to_s+"_name")
          @index += 1
          search_index(attr,@index)
          else
          return @index
        end
      end#def
      def points_in_radius(start_point,radius,pt)
        if start_point[0]+radius > pt.z*25.4 && start_point[0]-radius < pt.z*25.4 && start_point[1]+radius > pt.y*25.4 && start_point[1]-radius < pt.y*25.4
          return true
        end
        return false
      end#def
      def delete_fastener_group(e)
        other_groups_pid = e.get_attribute("_suf", "other_groups").compact
        if other_groups_pid != []
          other_groups = @model.find_entity_by_persistent_id(other_groups_pid)
          other_groups.each { |group| group.erase! if group }
        end
        e.erase!
      end#def
      def delete_fastener_attribute(touch_comp,pt)
        for i in 1..7
          for name_index in 0..9
            touch_comp.definition.delete_attribute("dynamic_attributes", "z"+(pt.z*25.4).round.to_s+"_"+(pt.y*25.4).round.to_s+"_"+(pt.x*25.4).round.to_s+"_"+i.to_s+"_"+name_index.to_s+"_name")
            touch_comp.definition.delete_attribute("dynamic_attributes", "z"+(pt.z*25.4).round.to_s+"_"+(pt.y*25.4).round.to_s+"_"+(pt.x*25.4).round.to_s+"_"+i.to_s+"_"+name_index.to_s+"_quantity")
            touch_comp.definition.delete_attribute("dynamic_attributes", "z"+(pt.z*25.4).round.to_s+"_"+(pt.y*25.4).round.to_s+"_"+(pt.x*25.4).round.to_s+"_"+i.to_s+"_"+name_index.to_s+"_template")
            touch_comp.definition.delete_attribute("dynamic_attributes", "z"+(pt.z*25.4).round.to_s+"_"+(pt.y*25.4).round.to_s+"_"+(pt.x*25.4).round.to_s+"_"+i.to_s+"_"+name_index.to_s+"_furniture")
          end
        end
      end#def
      def draw_fastener(touch_pt,index,pts_index,line_index)
        # точка, торец, стык, коэф.
        stock_groups = []
        bolt_groups = []
        side_groups = []
        touch_arr = @touch_hash[index][pts_index]
        parallel_face_normal = touch_arr[2]
        touch_face = touch_arr[5]
        current_fastener_indent = @fastener_indent
        current_active_fastener = @active_fastener
        current_fastener_position = @fastener_position
        offset_fastener = 0
        pts_essence = nil
        single_fastener = false
        @essences_with_hole = []
        if pts_index == -1
          edge_length = 100
          else
          edge_length = touch_arr[4][0].distance touch_arr[4][1]
        end      
        if @rule2 && index>1
          rule = @rule2
          active_fastener = @active_fastener2
          @fastener_param = @fastener_param2
          fastener_indent = @fastener_indent2
          else
          rule = @rule1
          active_fastener = @active_fastener
          fastener_indent = @fastener_indent
        end
        if rule
          if rule == "template1"
            if (edge_length*25.4).round(1) < current_fastener_indent*2+32
              if @template["auto1"][2] == "template2"
                single_fastener = true if (edge_length*25.4).round(1) < fastener_indent*2+32
                fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
                elsif @template["auto1"][2] == "template3"
                single_fastener = true
                fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
                elsif @template["auto1"][2] == "template5"
                @fastener_position = "symmetrical"
                elsif @template["auto1"][2] == "template6"
                single_fastener = true
                else
                single_fastener = true
                fastener_indent = (edge_length*25.4).round(1)/2
              end
            end
            elsif rule == "template2"
            single_fastener = true if (edge_length*25.4).round(1) < fastener_indent*2+32
            fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
            elsif rule == "template3"
            single_fastener = true
            fastener_indent = (((edge_length*25.4).round(1)-32).floor).to_f/2
            elsif rule == "template4"
            single_fastener = true
            fastener_indent = (edge_length*25.4).round(1)/2
            elsif rule == "template5"
            @fastener_position = "symmetrical"
            elsif rule == "template6"
            single_fastener = true
          end
        end
        fastener_indent = fastener_indent/25.4
        if pts_index == -1
          @n_vector = touch_arr[4]
          else
          start_edge_point = touch_arr[4][0].transform(touch_arr[3].inverse)
          end_edge_point = touch_arr[4][1].transform(touch_arr[3].inverse)
          if @reverse_fastener
            start_distance = @reverse_pt.transform(touch_arr[3].inverse).distance start_edge_point
            end_distance = @reverse_pt.transform(touch_arr[3].inverse).distance end_edge_point
            else
            start_distance = touch_pt.transform(touch_arr[3].inverse).distance start_edge_point
            end_distance = touch_pt.transform(touch_arr[3].inverse).distance end_edge_point
          end
          
          if (start_distance*25.4).round(1) == (fastener_indent*25.4).round(1)
            if @reverse_fastener
              @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - start_edge_point
              else
              @n_vector = touch_pt.transform(touch_arr[3].inverse) - start_edge_point
            end
            elsif @fastener_position == "back" && (start_distance*25.4).round(1) == @second_indent || @fastener_position == "front" && (start_distance*25.4).round(1) == @second_indent
            fastener_indent = @second_indent/25.4
            if @reverse_fastener
              @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - start_edge_point
              else
              @n_vector = touch_pt.transform(touch_arr[3].inverse) - start_edge_point
            end
            elsif (end_distance*25.4).round(1) == (fastener_indent*25.4).round(1)
            if @reverse_fastener
              @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - end_edge_point
              else
              @n_vector = touch_pt.transform(touch_arr[3].inverse) - end_edge_point
            end
            elsif @fastener_position == "back" && (end_distance*25.4).round(1) == @second_indent || @fastener_position == "front" && (end_distance*25.4).round(1) == @second_indent
            fastener_indent = @second_indent/25.4
            if @reverse_fastener
              @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - end_edge_point
              else
              @n_vector = touch_pt.transform(touch_arr[3].inverse) - end_edge_point
            end
            else
            if @reverse_fastener
              if start_edge_point.y < end_edge_point.y
                @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - start_edge_point
                else
                @n_vector = @reverse_pt.transform(touch_arr[3].inverse) - end_edge_point
              end
              else
              if start_edge_point.y < end_edge_point.y
                @n_vector = touch_pt.transform(touch_arr[3].inverse) - start_edge_point
                else
                @n_vector = touch_pt.transform(touch_arr[3].inverse) - end_edge_point
              end
            end
          end
        end
        @n_vector.normalize! if @n_vector
        check1 = []
        essence = touch_arr[0]
        touch_comp = @essence_and_comp[essence]
        v0_cut = touch_comp.definition.get_attribute("dynamic_attributes", "v0_cut")
        if v0_cut
          touch_comp.set_attribute("dynamic_attributes", "v0_cut", "2")
          touch_comp.definition.set_attribute("dynamic_attributes", "v0_cut", "2")
        end
        touch_comp_transformation = @essence_and_transformation[essence]
        ppp = touch_pt.transform(touch_comp_transformation.inverse)
        pt = ppp.project_to_plane touch_face.plane
        transform_pt = pt
        @hole_color = "gray"
        pts_index == -1 ? radius = 6 : radius = 15
        thickness = essence.definition.get_attribute("dynamic_attributes", "lenx")
        
        back_fastener = false
        if @process_by_template && thickness && thickness.to_f < 0.4
          back_fastener = true
        end
        
        depth = 1
        delete_fastener_attribute(touch_comp,pt)
        touch_comp_fastener = true
        essence.definition.entities.grep(Sketchup::Group).each { |e|
          if !e.deleted?
            if e.name == "error_fastener"
              e.erase!
              elsif e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
              origin_point = e.transformation.origin
              points = []
              e.get_attribute("_suf", "facedrilling").each{|point|points << point[4] if point[4]} if e.get_attribute("_suf", "facedrilling")
              e.get_attribute("_suf", "backdrilling").each{|point|points << point[4] if point[4]} if e.get_attribute("_suf", "backdrilling")
              if points.any? { |start_point| points_in_radius(start_point,radius,pt) } # ищем отверстия в радиусе
                a03_name = @comp.definition.get_attribute("dynamic_attributes", "a03_name")
                if origin_point.x == pt.x # отверстия с этой же стороны панели
                  delete_fastener_group(e) # удаляем отверстия  в радиусе
                  delete_fastener_attribute(touch_comp,origin_point)
                  else # отверстия с другой стороны панели
                  if @process_by_template || @process_accessories
                    if @essence_and_module[essence]
                      @model.active_view.zoom @essence_and_module[essence]
                      elsif @essence_and_comp[essence]
                      @model.active_view.zoom @essence_and_comp[essence]
                    end
                  end
                  @draw_other_side = true
                  draw(@model.active_view) if @process_by_template
                  
                  if e.get_attribute("_suf", "facedrilling")
                    arr = e.get_attribute("_suf", "facedrilling")
                    elsif e.get_attribute("_suf", "backdrilling")
                    arr = e.get_attribute("_suf", "backdrilling")
                  end
                  if !@change_shelf_fastener[essence]
                    change_shelf_fastener = []
                    html = "<style>"
                    html += "body { font-family: Arial; color: #696969; font-size: 16px; }</style>"
                    html += "#{SUF_STRINGS["On the panel"]}: <b>#{touch_comp.definition.get_attribute("dynamic_attributes", "a03_name")}</b></br>"
                    html += "#{SUF_STRINGS["There are holes on the other side within radius"]} #{radius} #{SUF_STRINGS["mm"]}.</br></br>"
                    offset_fastener_value = (@offset_fastener_value ? @offset_fastener_value : @template["offset_fastener"][2])
                    shelf_fastener_value = (@shelf_fastener_value ? @shelf_fastener_value : @template["shelf_fastener"][2])
                    if @process_accessories
                      html += "#{SUF_STRINGS["Hardware"]}: <b>#{@a03_name}</b></br></br>"
                      html += "<input id=\"offset_fastener\" type=\"checkbox\" #{(@offset_fastener_check==true ? "checked" : "")}> #{SUF_STRINGS["Offset fitting by"]} "
                      html += "<input id=\"offset_value\" style=\"width: 200px; margin-left:11px;\" type=\"textbox\" value=\"#{offset_fastener_value}\"></br></br>"
                      else
                      html += "#{SUF_STRINGS["Current fitting"]}: <b>#{active_fastener}</b></br></br>"
                      html += "<input id=\"offset_fastener\" type=\"checkbox\" #{(@offset_fastener_check==true ? "checked" : "")}> #{SUF_STRINGS["Offset fitting by"]} "
                      html += "<input id=\"offset_value\" style=\"width: 200px; margin-left:11px;\" type=\"textbox\" value=\"#{offset_fastener_value}\"></br></br>"
                      html += "<input id=\"shelf_fastener\" type=\"checkbox\" #{(@shelf_fastener_check==true ? "checked" : "")}> #{SUF_STRINGS["Change fitting to"]} "
                      html += "<select id=\"fastener_list\" style=\"width: 200px; margin-left:10px;\" id=\"shelf_fastener\" type=\"text\">"
                      @fastener_list.each { |option|
                        html += "<option #{(option == shelf_fastener_value ? "selected" : "")} value=\"#{option}\">#{option}</option>"
                      }
                      html += "</select></br></br>"
                    end
                    if @process_accessories
                      str = "document.getElementById('offset_fastener').checked,document.getElementById('offset_value').value,false,false"
                      else
                      str = "document.getElementById('offset_fastener').checked,document.getElementById('offset_value').value,document.getElementById('shelf_fastener').checked,document.getElementById('fastener_list').value"
                    end
                    if origin_point.y == pt.y && origin_point.z == pt.z && arr[0][0] == @fastener_param["fastener_d1"] || @process_accessories && arr[0][0] == @fastener_param["fastener_d1"]
                      html += "<input id=\"change_depth\" type=\"checkbox\" #{((@process_accessories || @shelf_depth_check==true) ? "checked" : "")}> #{SUF_STRINGS["Change depth"]} "
                      html += "<select id=\"depth_value\" style=\"width: 200px; margin-left:30px;\" id=\"shelf_fastener_depth\" type=\"text\">"
                      html += "<option #{@shelf_depth_value == SUF_STRINGS["Make through-hole"] ? "selected" : ""} value=\"#{SUF_STRINGS["Make through-hole"]}\">#{SUF_STRINGS["Make through-hole"]}</option>)"
                      html += "<option #{@shelf_depth_value == SUF_STRINGS["Half panel thickness"] ? "selected" : ""} value=\"#{SUF_STRINGS["Half panel thickness"]}\">#{SUF_STRINGS["Half panel thickness"]}</option>)"
                      html += "</select></br></br>"
                      html += "<button onclick=\"sketchup.callback([#{str},document.getElementById('change_depth').checked,document.getElementById('depth_value').value])\">OK</button>"
                      else
                      html += "<button onclick=\"sketchup.callback([#{str}])\">OK</button>"
                    end
                    @dlg.close if @dlg && (@dlg.visible?)
                    @dlg = UI::HtmlDialog.new({
                      :dialog_title => ' ',
                      :preferences_key => "change_shelf_fastener",
                      :scrollable => false,
                      :resizable => false,
                      :width => 500,
                      :height => 300,
                      :style => UI::HtmlDialog::STYLE_DIALOG
                    })
                    @dlg.set_html(html)
                    @dlg.add_action_callback("callback") { |_, v|
                      change_shelf_fastener = v
                      @dlg.close
                    }
                    OSX ? @dlg.show() : @dlg.show_modal()
                    @change_shelf_fastener[essence] = change_shelf_fastener
                  end
                  
                  @draw_other_side = false
                  @offset_fastener_check = @change_shelf_fastener[essence][0]
                  if @change_shelf_fastener[essence][0]
                    offset_fastener = @change_shelf_fastener[essence][1].to_f
                    @offset_fastener_value = offset_fastener
                  end
                  
                  @shelf_fastener_check = @change_shelf_fastener[essence][2]
                  if @change_shelf_fastener[essence][2]
                    active_fastener = @change_shelf_fastener[essence][3]
                    @shelf_fastener_value = active_fastener
                    @fastener_param = @fastener_parameters[active_fastener]
                  end
                  
                  @shelf_depth_check = @change_shelf_fastener[essence][4]
                  if @change_shelf_fastener[essence][4]
                    @shelf_depth_value = @change_shelf_fastener[essence][5]
                    if @change_shelf_fastener[essence][5] == SUF_STRINGS["Make through-hole"]
                      if e.get_attribute("_suf", "facedrilling")
                        arr = e.get_attribute("_suf", "facedrilling")
                        depth = arr[0][2].to_f/25.4
                        arr.map!{|hole| [hole[0],hole[1],(thickness*25.4+0.01).round.to_s,(thickness*25.4+0.01).round.to_s,hole[4]]}
                        e.set_attribute("_suf", "facedrilling",arr)
                        dict = e.attribute_dictionary "dynamic_attributes"
                        if dict
                          dict.each_pair {|attr, v|
                            if attr.include?("quantity")
                              e.set_attribute("dynamic_attributes", attr, (v.to_f*2).to_s)
                            end
                          }
                        end
                        
                        elsif e.get_attribute("_suf", "backdrilling")
                        arr = e.get_attribute("_suf", "backdrilling")
                        depth = arr[0][2].to_f/25.4
                        arr.map!{|hole| [hole[0],hole[1],(thickness*25.4+0.01).round.to_s,(thickness*25.4+0.01).round.to_s,hole[4]]}
                        e.set_attribute("_suf", "backdrilling",arr)
                        dict = e.attribute_dictionary "dynamic_attributes"
                        if dict
                          dict.each_pair {|attr, v|
                            if attr.include?("quantity")
                              e.set_attribute("dynamic_attributes", attr, (v.to_f*2).to_s)
                            end
                          }
                        end
                      end
                      e.transform!(Geom::Transformation.scaling(origin_point,thickness/depth,1,1))
                      touch_comp_fastener = false
                      elsif @change_shelf_fastener[essence][5] == SUF_STRINGS["Half panel thickness"]
                      if e.get_attribute("_suf", "facedrilling")
                        arr = e.get_attribute("_suf", "facedrilling")
                        depth = arr[0][2].to_f/25.4
                        arr.map!{|hole| [hole[0],hole[1],(thickness/2*25.4+0.01).round.to_s,(thickness/2*25.4+0.01).round.to_s,hole[4]]}
                        e.set_attribute("_suf", "facedrilling",arr)
                        elsif e.get_attribute("_suf", "backdrilling")
                        arr = e.get_attribute("_suf", "backdrilling")
                        depth = arr[0][2].to_f/25.4
                        arr.map!{|hole| [hole[0],hole[1],(thickness/2*25.4+0.01).round.to_s,(thickness/2*25.4+0.01).round.to_s,hole[4]]}
                        e.set_attribute("_suf", "backdrilling",arr)
                      end
                      e.transform!(Geom::Transformation.scaling(origin_point,thickness/2/depth,1,1))
                      @fastener_param["fastener_d1_depth"] = ((thickness/2)*25.4+0.01).round.to_s
                    end
                  end
                end
              end
            end
          end
        }
        
        visible_side = essence.definition.get_attribute("dynamic_attributes", "visible_side")
        if visible_side && @process_by_template
          visible_face = nil
          essence.definition.entities.grep(Sketchup::Face).each { |f| 
            visible_face = f if f.get_attribute("dynamic_attributes", "visible_side")
          }
          if visible_face != touch_face
            through_hole = false
            for i in 1..7
              if @fastener_param["fastener_d"+i.to_s+"_depth"].to_f/25.4 >= thickness
                through_hole = true
              end
            end
            if through_hole
              active_fastener = @template["visible_side_fastener"][2]
              @fastener_param = @fastener_parameters[active_fastener]
            end
          end
        end
        if !back_fastener && touch_comp_fastener
          if touch_face.normal.x.abs == 1
            drill_to = 1
            else
            drill_to = 2
          end
          @fastener_param["fastener_n0"] ? n = @fastener_param["fastener_n0"].to_f : n = 0
          leny = essence.definition.get_attribute("dynamic_attributes", "leny")
          lenz = essence.definition.get_attribute("dynamic_attributes", "lenz")
          line_index==1 ? distance_from_begin = ((edge_length*25.4+0.01).round(1))/2 : distance_from_begin = n+fastener_indent*25.4
          for i in 1..7
            new_depth = 0
            stock_group = nil
            if @fastener_param["fastener_d"+i.to_s]
              if (edge_length*25.4+0.01).round(1)-distance_from_begin >= @min_indent
                if distance_from_begin >= @min_indent || pts_index == -1
                  check1 << i
                  touch_arr[0].definition.set_attribute("dynamic_attributes", "_fastener", true)
                  touch_arr[0].definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                  touch_arr[0].definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                  touch_comp.definition.set_attribute("dynamic_attributes", "_fastener", true)
                  touch_comp.definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                  touch_comp.definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                  
                  depth = -1*@fastener_param["fastener_d"+i.to_s+"_depth"].to_f/25.4
                  if !stock_group
                    fastener_array = []
                    stock_group = essence.definition.entities.add_group
                    stock_groups << stock_group
                    if @fastener_param["color"+i.to_s]
                      @hole_color = @fastener_param["color"+i.to_s].split(".").map(&:to_i)
                      stock_group.material = @hole_color
                      else
                      @hole_color = "gray"
                      stock_group.material = @hole_color
                    end
                    stock_group.layer = @fastener_layer
                    stock_group.move!([pt.x,pt.y+(@n_vector.y*offset_fastener/25.4),pt.z])
                    text = "x"+(depth.abs*25.4).round.to_s
                    if stock_group.transformation.origin.x != 0
                      touch_arr[0].definition.set_attribute("dynamic_attributes", "_fastener_position_front", true)
                      text += " "+SUF_STRINGS["front"] if @type_hole == "yes"
                      else
                      touch_arr[0].definition.set_attribute("dynamic_attributes", "_fastener_position_back", true)
                      text += " "+SUF_STRINGS["flip"] if @type_hole == "yes"
                    end
                    if drill_to==2
                      text = " "+SUF_STRINGS["flank"] if @type_hole == "yes"
                      else
                      if @fastener_param["fastener_d"+i.to_s+"_depth"].to_f/25.4 >= thickness
                        new_depth = (depth.abs*25.4).round - (thickness*25.4).round
                        depth = -1*thickness
                        text = " "+SUF_STRINGS["through"] if @type_hole == "yes"
                      end
                    end
                    @fastener_param["fastener_pd"+i.to_s] ? prefix = @fastener_param["fastener_pd"+i.to_s] : prefix = ""
                    stock_group.name = prefix+"ø"+@fastener_param["fastener_d"+i.to_s]+text
                    @touch_comp_fastener_array << 1
                  end
                  
                  if @fastener_param["list_name"+i.to_s] && @fastener_param["list_name"+i.to_s] != "" && @fastener_param["list_name"+i.to_s] != " "
                    list_name_arr = @fastener_param["list_name"+i.to_s].split(";")
                    list_name_arr.each_with_index {|name_arr,name_index|
                      name = name_arr.split("~")[0]
                      name_arr.include?("~") ? name_count = name_arr.split("~")[1].to_f : name_count = 1
                      stock_group.set_attribute("dynamic_attributes", "z"+"_"+i.to_s+"_"+name_index.to_s+"_name", name)
                      stock_group.set_attribute("dynamic_attributes", "z"+"_"+i.to_s+"_"+name_index.to_s+"_quantity", name_count.to_s)
                    }
                  end
                  
                  multiple = 0
                  edgedrilling = false
                  for multiple_index in 1..@fastener_param["multiple"].to_i
                    if pts_index == -1
                      n_vector = @n_vector
                      else
                      n_vector = @n_vector.transform(touch_arr[3])
                      n_vector.transform!(touch_comp_transformation.inverse)
                    end
                    n_vector.normalize!
                    if @fastener_param["fastener_C"] == "1/2"
                      fastener_с = @lenx/2
                      else
                      fastener_с = @fastener_param["fastener_C"].to_f/25.4
                    end
                    fastener_vector = @ipface_normal.reverse.transform(touch_comp_transformation.inverse)
                    point_d = Geom::Point3d.new(0, 0, 0)+Geom::Vector3d.new(fastener_vector.x*fastener_с,fastener_vector.y*fastener_с,fastener_vector.z*fastener_с)+Geom::Vector3d.new(n_vector.x*n/25.4,n_vector.y*n/25.4,n_vector.z*n/25.4)+Geom::Vector3d.new(fastener_vector.x*multiple,fastener_vector.y*multiple,fastener_vector.z*multiple)
                    edges = stock_group.definition.entities.add_circle  point_d, touch_face.normal, @fastener_param["fastener_d"+i.to_s].to_f/50.8
                    edges[0].find_faces
                    pts_essence = essence
                    multiple += @fastener_param["multiple_dist"].to_f/25.4 if multiple_index.odd?
                    multiple *= -1
                    point = point_d.transform(stock_group.transformation)
                    vec = touch_face.normal.reverse
                    edgedrilling = true if vec.x.abs != 1
                    points = [(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),vec.z,vec.y,vec.x]
                    fastener_array << [@fastener_param["fastener_d"+i.to_s],@fastener_param["fastener_d"+i.to_s],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,points] #export_points
                  end
                  stock_group.definition.entities.grep(Sketchup::Face).each { |face|
                    face.reverse! unless face.normal.samedirection?(touch_face.normal)
                    face.pushpull(depth)
                  }
                  if edgedrilling
                    stock_group.set_attribute("_suf", "edgedrilling", fastener_array)
                    else
                    if stock_group.transformation.origin.x == 0
                      stock_group.set_attribute("_suf", "backdrilling", fastener_array)
                      else
                      stock_group.set_attribute("_suf", "facedrilling", fastener_array)
                    end
                  end
                  stock_group.set_attribute("_suf", "_template", true) if @process_by_template
                  stock_group.set_attribute("_suf", "_furniture", true) if @fastener_furniture
                  if pts_index == -1 && new_depth != 0
                    @essences_with_hole << essence
                    transform_pt.x == 0 ? transform_pt.x = thickness : transform_pt.x = 0
                    pt = transform_pt.transform(touch_comp_transformation)
                    second_essence,tr = search_touch_essence(pt)
                    if second_essence
                      make_hole(second_essence,pt,tr,new_depth,@fastener_param["fastener_d"+i.to_s]) 
                    end
                  end
                end
              end
            end
            if @fastener_param["fastener_n"+i.to_s]
              n += @fastener_param["fastener_n"+i.to_s].to_f
              distance_from_begin += @fastener_param["fastener_n"+i.to_s].to_f
            end
          end
        end
        
        if pts_index != -1 && !back_fastener
          fastener_vector = parallel_face_normal.reverse
          radius = 15
          essence = @essence
          if @a01_gluing == 1
            essence.definition.entities.grep(Sketchup::Group).each { |e|
              if !e.deleted?
                if e.name == "error_fastener"
                  e.erase!
                  elsif e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling") || e.get_attribute("_suf", "edgedrilling")
                  start_point = e.transformation.origin
                  constlines_point = touch_pt.transform(touch_arr[3].inverse)
                  if start_point.z+radius/25.4 > constlines_point.z && start_point.z-radius/25.4 < constlines_point.z
                    if start_point.y+radius/25.4 > constlines_point.y && start_point.y-radius/25.4 < constlines_point.y
                      e.erase!
                    end
                  end
                end
              end
            }
          end
          @fastener_param["fastener_n0"] ? n = @fastener_param["fastener_n0"].to_f : n = 0
          thickness = essence.definition.get_attribute("dynamic_attributes", "lenx")
          leny = essence.definition.get_attribute("dynamic_attributes", "leny")
          lenz = essence.definition.get_attribute("dynamic_attributes", "lenz")
          line_index==1 ? distance_from_begin = ((edge_length*25.4+0.01).round(1))/2 : distance_from_begin = n+fastener_indent*25.4
          for i in 1..7
            bolt_group = nil
            if @fastener_param["fastener_D"+i.to_s] || @fastener_param["fastener_D"+i.to_s+"1"] || @fastener_param["fastener_D"+i.to_s+"2"]
              if distance_from_begin >= @min_indent && (edge_length*25.4+0.01).round(1)-distance_from_begin >= @min_indent
                essence.definition.set_attribute("dynamic_attributes", "_fastener", true)
                essence.definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                essence.definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                @comp.definition.set_attribute("dynamic_attributes", "_fastener", true)
                @comp.definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                @comp.definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                
                if !bolt_group
                  fastener_array = []
                  reverse_fastener = []
                  bolt_group = essence.definition.entities.add_group
                  bolt_groups << bolt_group
                  if @fastener_param["color"+i.to_s]
                    @hole_color = @fastener_param["color"+i.to_s].split(".").map(&:to_i)
                    bolt_group.material = @hole_color
                    else
                    @hole_color = "gray"
                    bolt_group.material = @hole_color
                  end
                  bolt_group.layer = @fastener_layer
                  pt = touch_pt.transform(touch_arr[3].inverse)
                  bolt_group.move!([pt.x,pt.y+(@n_vector.y*offset_fastener/25.4),pt.z])
                  text = "x"+@fastener_param["fastener_D"+i.to_s+"_depth"]
                  if bolt_group.transformation.origin.x != 0
                    essence.definition.set_attribute("dynamic_attributes", "_fastener_position_front", true)
                    text += " "+SUF_STRINGS["front"] if @type_hole == "yes"
                    else
                    essence.definition.set_attribute("dynamic_attributes", "_fastener_position_back", true)
                    text += " "+SUF_STRINGS["flip"] if @type_hole == "yes"
                  end
                  depth = @fastener_param["fastener_D"+i.to_s+"_depth"].to_f/25.4
                  if @fastener_param["fastener_D"+i.to_s+"_depth"].to_f/25.4 >= thickness
                    depth = thickness
                    text = " "+SUF_STRINGS["through"] if @type_hole == "yes"
                  end
                  @fastener_param["fastener_pD"+i.to_s] ? prefix = @fastener_param["fastener_pD"+i.to_s] : prefix = ""
                  bolt_group.name = prefix+"ø"+@fastener_param["fastener_D"+i.to_s]+text
                end
                
                if @fastener_param["list_name"+i.to_s] && @fastener_param["list_name"+i.to_s] != "" && @fastener_param["list_name"+i.to_s] != " " && !check1.include?(i)
                  list_name_arr = @fastener_param["list_name"+i.to_s].split(";")
                  list_name_arr.each {|name_arr|
                    name = name_arr.split("~")[0]
                    name_arr.include?("~") ? name_count = name_arr.split("~")[1].to_f : name_count = 1
                    bolt_group.set_attribute("dynamic_attributes", "z"+index.to_s+pts_index.to_s+line_index.to_s+i.to_s+"_name", name)
                    bolt_group.set_attribute("dynamic_attributes", "z"+index.to_s+pts_index.to_s+line_index.to_s+i.to_s+"_quantity", name_count.to_s)
                    check1 << i
                  }
                end
                
                all_faces = []
                fastener_L = @fastener_param["fastener_L"].to_f/25.4 - touch_arr[7]
                if @fastener_param["fastener_D"+i.to_s]
                  point_D = Geom::Point3d.new(0, 0, 0)+Geom::Vector3d.new(fastener_vector.x*fastener_L,fastener_vector.y*fastener_L,fastener_vector.z*fastener_L)+Geom::Vector3d.new(@n_vector.x*n/25.4,@n_vector.y*n/25.4,@n_vector.z*n/25.4)
                  edges = bolt_group.definition.entities.add_circle  point_D, @ipface_normal.transform(touch_arr[3].inverse), @fastener_param["fastener_D"+i.to_s].to_f/50.8
                  edges[0].find_faces
                  bolt_group.definition.entities.grep(Sketchup::Face).each { |face| face.pushpull(-1*depth, true) }
                  bolt_group.definition.entities.grep(Sketchup::Face).each { |face| all_faces << face }
                  point = point_D.transform(bolt_group.transformation)
                  fastener_array << [@fastener_param["fastener_D"+i.to_s],@fastener_param["fastener_D"+i.to_s],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,((point.x*25.4).round == 0 ? 1 : -1)]] #export_points
                end
                if @fastener_param["fastener_D"+i.to_s+"1"]
                  depth = @fastener_param["fastener_D"+i.to_s+"1_depth"].to_f/25.4
                  if depth < 0
                    if bolt_group.transformation.origin.x != 0
                      origin_point = Geom::Point3d.new(-1*thickness, 0, 0)
                      else
                      origin_point = Geom::Point3d.new(thickness, 0, 0)
                    end
                    else
                    origin_point = Geom::Point3d.new(0, 0, 0)
                  end
                  point11 = origin_point+Geom::Vector3d.new(fastener_vector.x*fastener_L,fastener_vector.y*fastener_L,fastener_vector.z*fastener_L)+Geom::Vector3d.new(@n_vector.x*n/25.4,@n_vector.y*n/25.4,@n_vector.z*n/25.4)+Geom::Vector3d.new(fastener_vector.x*@fastener_param["fastener_L1"].to_f/25.4,fastener_vector.y*@fastener_param["fastener_L1"].to_f/25.4,fastener_vector.z*@fastener_param["fastener_L1"].to_f/25.4)
                  edges = bolt_group.definition.entities.add_circle point11, @ipface_normal.transform(touch_arr[3].inverse), @fastener_param["fastener_D"+i.to_s+"1"].to_f/50.8
                  edges[0].find_faces
                  bolt_group.definition.entities.grep(Sketchup::Face).each { |face| face.pushpull(-1*depth, true) if !face.deleted? && !all_faces.include?(face) }
                  all_faces = []
                  bolt_group.definition.entities.grep(Sketchup::Face).each { |face| all_faces << face }
                  point = point11.transform(bolt_group.transformation)
                  if depth < 0
                    reverse_fastener << [@fastener_param["fastener_D"+i.to_s+"1"],@fastener_param["fastener_D"+i.to_s+"1"],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,((point.x*25.4).round == 0 ? 1 : -1)]] #export_points
                    else
                    fastener_array << [@fastener_param["fastener_D"+i.to_s+"1"],@fastener_param["fastener_D"+i.to_s+"1"],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,((point.x*25.4).round == 0 ? 1 : -1)]] #export_points
                  end
                end
                if @fastener_param["fastener_D"+i.to_s+"2"]
                  depth = @fastener_param["fastener_D"+i.to_s+"2_depth"].to_f/25.4
                  if depth < 0
                    if bolt_group.transformation.origin.x != 0
                      origin_point = Geom::Point3d.new(-1*thickness, 0, 0)
                      else
                      origin_point = Geom::Point3d.new(thickness, 0, 0)
                    end
                    else
                    origin_point = Geom::Point3d.new(0, 0, 0)
                  end
                  point12 = origin_point+Geom::Vector3d.new(fastener_vector.x*fastener_L,fastener_vector.y*fastener_L,fastener_vector.z*fastener_L)+Geom::Vector3d.new(@n_vector.x*n/25.4,@n_vector.y*n/25.4,@n_vector.z*n/25.4)+Geom::Vector3d.new(fastener_vector.x*@fastener_param["fastener_L1"].to_f/25.4,fastener_vector.y*@fastener_param["fastener_L1"].to_f/25.4,fastener_vector.z*@fastener_param["fastener_L1"].to_f/25.4)+Geom::Vector3d.new(fastener_vector.x*@fastener_param["fastener_L2"].to_f/25.4,fastener_vector.y*@fastener_param["fastener_L2"].to_f/25.4,fastener_vector.z*@fastener_param["fastener_L2"].to_f/25.4)
                  edges = bolt_group.definition.entities.add_circle  point12, @ipface_normal.transform(touch_arr[3].inverse), @fastener_param["fastener_D"+i.to_s+"2"].to_f/50.8
                  edges[0].find_faces
                  
                  bolt_group.definition.entities.grep(Sketchup::Face).each { |face| face.pushpull(-1*depth, true) if !face.deleted? && !all_faces.include?(face) }
                  point = point12.transform(bolt_group.transformation)
                  if depth < 0
                    reverse_fastener << [@fastener_param["fastener_D"+i.to_s+"2"],@fastener_param["fastener_D"+i.to_s+"2"],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,((point.x*25.4).round == 0 ? 1 : -1)]] #export_points
                    else
                    fastener_array << [@fastener_param["fastener_D"+i.to_s+"2"],@fastener_param["fastener_D"+i.to_s+"2"],(depth.abs*25.4).round.to_s,(depth.abs*25.4).round.to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),0,0,((point.x*25.4).round == 0 ? 1 : -1)]] #export_points
                  end
                end
                if bolt_group
                  if bolt_group.transformation.origin.x != 0
                    bolt_group.set_attribute("_suf", "facedrilling", fastener_array)
                    if reverse_fastener != []
                      bolt_group.set_attribute("_suf", "backdrilling", reverse_fastener)
                    end
                    else
                    bolt_group.set_attribute("_suf", "backdrilling", fastener_array)
                    if reverse_fastener != []
                      bolt_group.set_attribute("_suf", "facedrilling", reverse_fastener)
                    end
                  end
                end
                bolt_group.set_attribute("_suf", "_template", true) if @process_by_template
                bolt_group.set_attribute("_suf", "_furniture", true) if @fastener_furniture
              end
            end
            n += @fastener_param["fastener_n"+i.to_s].to_f if @fastener_param["fastener_n"+i.to_s]
            distance_from_begin += @fastener_param["fastener_n"+i.to_s].to_f if @fastener_param["fastener_n"+i.to_s]
          end
          
          @fastener_param["fastener_n0"] ? n = @fastener_param["fastener_n0"].to_f : n = 0
          line_index==1 ? distance_from_begin = ((edge_length*25.4+0.01).round(1))/2 : distance_from_begin = n+fastener_indent*25.4
          for i in 1..7
            side_group = nil
            if distance_from_begin >= @min_indent && @fastener_param["fastener_dside"+i.to_s] && (edge_length*25.4+0.01).round(1)-distance_from_begin >= @min_indent
              if thickness && thickness.to_f > @fastener_param["fastener_dside"+i.to_s].to_f/25.4
                essence.definition.set_attribute("dynamic_attributes", "_fastener", true)
                essence.definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                essence.definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                @comp.definition.set_attribute("dynamic_attributes", "_fastener", true)
                @comp.definition.set_attribute("dynamic_attributes", "_template", true) if @process_by_template
                @comp.definition.set_attribute("dynamic_attributes", "_furniture", true) if @fastener_furniture
                
                if !side_group
                  fastener_array = []
                  side_group = essence.definition.entities.add_group
                  side_groups << side_group
                  if @fastener_param["color"+i.to_s]
                    @hole_color = @fastener_param["color"+i.to_s].split(".").map(&:to_i)
                    side_group.material = @hole_color
                    else
                    @hole_color = "gray"
                    side_group.material = @hole_color
                  end
                  side_group.layer = @fastener_layer
                  pt = touch_pt.transform(touch_arr[3].inverse)
                  side_group.move!([pt.x,pt.y+(@n_vector.y*offset_fastener/25.4),pt.z])
                  @fastener_param["fastener_pdside"+i.to_s] ? prefix = @fastener_param["fastener_pdside"+i.to_s] : prefix = ""
                  side_group.name = prefix+"ø"+@fastener_param["fastener_dside"+i.to_s]+"x"+@fastener_param["fastener_dside"+i.to_s+"_depth"]+(@type_hole == "yes" ? " "+(SUF_STRINGS["flank"]) : "")
                end
                
                if @fastener_param["list_name"+i.to_s] && @fastener_param["list_name"+i.to_s] != "" && @fastener_param["list_name"+i.to_s] != " " && !check1.include?(i)
                  list_name_arr = @fastener_param["list_name"+i.to_s].split(";")
                  list_name_arr.each {|name_arr|
                    name = name_arr.split("~")[0]
                    name_arr.include?("~") ? name_count = name_arr.split("~")[1].to_f : name_count = 1
                    side_group.set_attribute("dynamic_attributes", "z"+index.to_s+pts_index.to_s+line_index.to_s+i.to_s+"_name", name)
                    side_group.set_attribute("dynamic_attributes", "z"+index.to_s+pts_index.to_s+line_index.to_s+i.to_s+"_quantity", name_count.to_s)
                    check1 << i
                  }
                end
                
                essence.definition.set_attribute("dynamic_attributes", "_fastener_position_edge", true)
                fastener_vector = @ipface_normal.reverse.transform(touch_arr[3].inverse)
                if @fastener_param["dside_C"] == "1/2"
                  dside_c = essence.definition.get_attribute("dynamic_attributes", "lenx")/2
                  else
                  dside_c = @fastener_param["dside_C"].to_f/25.4
                end
                point_dside = Geom::Point3d.new(0, 0, 0)+Geom::Vector3d.new(fastener_vector.x*dside_c,fastener_vector.y*dside_c,fastener_vector.z*dside_c)+Geom::Vector3d.new(@n_vector.x*n/25.4,@n_vector.y*n/25.4,@n_vector.z*n/25.4)
                edges = side_group.definition.entities.add_circle  point_dside, parallel_face_normal, @fastener_param["fastener_dside"+i.to_s].to_f/50.8
                edges[0].find_faces
                
                side_group.definition.entities.grep(Sketchup::Face).each { |face|
                  koef = -1
                  face.reverse! unless face.normal.samedirection?(parallel_face_normal)
                  face.pushpull(koef*@fastener_param["fastener_dside"+i.to_s+"_depth"].to_f/25.4)
                }
                
                point = point_dside.transform(side_group.transformation)
                fastener_array << [@fastener_param["fastener_dside"+i.to_s],@fastener_param["fastener_dside"+i.to_s],@fastener_param["fastener_dside"+i.to_s+"_depth"].to_s,@fastener_param["fastener_dside"+i.to_s+"_depth"].to_s,[(point.z*25.4).round(1),(point.y*25.4).round(1),(point.x*25.4).round(1),((point.z*25.4).round(1) == 0 ? 1 : ((point.z*25.4).round(1) == (lenz*25.4).round(1) ? -1 : 0)),((point.y*25.4).round(1) == 0 ? 1 : ((point.y*25.4).round(1) == (leny*25.4).round(1) ? -1 : 0)),0]] #export_points
                side_group.set_attribute("_suf", "edgedrilling", fastener_array)
                side_group.set_attribute("_suf", "_template", true) if @process_by_template
                side_group.set_attribute("_suf", "_furniture", true) if @fastener_furniture
              end
            end
            n += @fastener_param["fastener_n"+i.to_s].to_f if @fastener_param["fastener_n"+i.to_s]
            distance_from_begin += @fastener_param["fastener_n"+i.to_s].to_f if @fastener_param["fastener_n"+i.to_s]
          end
        end
        @fastener_indent = current_fastener_indent
        @active_fastener = current_active_fastener
        @fastener_position = current_fastener_position
        @fastener_param = @fastener_parameters[@active_fastener]
        stock_groups_pids = stock_groups.collect { |group| (group ? group.persistent_id : nil)}
        bolt_groups_pids = bolt_groups.collect { |group| (group ? group.persistent_id : nil)}
        side_groups_pids = side_groups.collect { |group| (group ? group.persistent_id : nil)}
        stock_groups.each { |stock_group|
          stock_group.set_attribute("_suf", "other_groups", stock_groups_pids.filter{|pid|pid != stock_group.persistent_id}.compact+bolt_groups_pids+side_groups_pids)
        }
        bolt_groups.each { |bolt_group|
          bolt_group.set_attribute("_suf", "other_groups", stock_groups_pids+bolt_groups_pids.filter{|pid|pid != bolt_group.persistent_id}.compact+side_groups_pids)
        }
        side_groups.each { |side_group|
          side_group.set_attribute("_suf", "other_groups", stock_groups_pids+bolt_groups_pids+side_groups_pids.filter{|pid|pid != side_group.persistent_id}.compact)
        }
        return pts_essence
      end#def
      def make_hole(essence,pt,tr,depth,diameter)
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
        essence.definition.set_attribute("dynamic_attributes", "_furniture", true)
        thickness = essence.definition.get_attribute("dynamic_attributes", "lenx")
        group = essence.definition.entities.add_group
        group.layer = @fastener_layer
        group.material = @hole_color
        group.move!(transform_pt)
        text = "x"+depth.round.to_s
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
        group.name = "ø"+diameter.to_s+text
        
        edges = group.definition.entities.add_circle  Geom::Point3d.new(0, 0, 0), @ipface.normal, diameter.to_f/50.8
        edges[0].find_faces
        group.definition.entities.grep(Sketchup::Face).each { |face|
          face.normal == @ipface.normal ? koef = -1 : koef = 1
          face.pushpull(koef*depth/25.4)
        }
        fastener_array = []
        fastener_array << [diameter.to_s,diameter.to_s,depth.round.to_s,depth.round.to_s]
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
        group.set_attribute("_suf", "_furniture", true)
        @essences_with_hole << essence
        if new_depth != 0
          transform_pt.x == 0 ? transform_pt.x = thickness : transform_pt.x = 0
          pt = transform_pt.transform(tr)
          second_essence,tr = search_touch_essence(pt)
          if second_essence
            make_hole(second_essence,pt,tr,new_depth,diameter) 
            if @fastener_dimension.include?("1") || @fastener_dimension.include?("2") || @fastener_dimension.include?("3")
              dimensions(second_essence)
            end
          end
        end
        if @fastener_dimension.include?("1") || @fastener_dimension.include?("2") || @fastener_dimension.include?("3")
          dimensions(essence)
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
      def essences_dimensions(essences)
        if @fastener_dimension.include?("1") || @fastener_dimension.include?("2") || @fastener_dimension.include?("3")
          essences.each {|essence| dimensions(essence) }
        end
      end#def
      def dimensions(essence)
        essence.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| ent.erase! if ent.definition.name.include?("dimension") }
        lenx = essence.definition.get_attribute("dynamic_attributes", "lenx")
        leny = essence.definition.get_attribute("dynamic_attributes", "leny")
        lenz = essence.definition.get_attribute("dynamic_attributes", "lenz")
        fasteners = search_fastener(essence)
        if @fastener_dimension.include?("1") || @fastener_dimension.include?("3")
          dimension_y(essence,lenx,leny,lenz,fasteners)
        end
        if @fastener_dimension.include?("1") || @fastener_dimension.include?("2")
          dimension_z(essence,lenx,leny,lenz,fasteners)
        end
      end#def
      def dimension_y(essence,lenx,leny,lenz,fasteners)
        pts_arr = []
        fasteners.each{|pts|pts_arr += pts}
        pts_x_arr = pts_arr.group_by { |pt| pt.x.round(2) }.values
        pts_x_arr.each{|points|
          pts_z_arr = points.group_by { |pt| pt.z.round(2) }.values
          pts_z_sort = []
          pts_z_arr.each { |pts_z| pts_z_sort << pts_z.sort_by { |pt| pt.y } }
          pts_z_sort.each { |pts|
            pts.each_index { |index|
              if pts[index].x == 0 || pts[index].x == lenx
                this_pt = pt_from_array(pts[index])
                this_pt.z > lenz-1 ? scale = -1 : scale = 1
                if index > 0
                  start_point = pt_from_array(pts[index-1])
                  else
                  start_point = Geom::Point3d.new(this_pt.x,0,this_pt.z)
                end
                t = Geom::Transformation.translation this_pt
                distance = this_pt.distance start_point
                if this_pt.z > 0.1 && this_pt.z < lenz-0.1
                  dim_comp_place = essence.definition.entities.add_instance @dim_y0, t
                  dim_comp_place.make_unique
                  dim_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if dim_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
                  scale_factors = [1, distance/dim_comp_place.bounds.height, scale]
                  dim_comp_place.transformation *= Geom::Transformation.scaling(*scale_factors)
                  dim_comp_place.layer = @dim_layer
                end
                if index == pts.length-1 && this_pt.y > leny/2 # размер от заднего торца
                  dim_comp_place = essence.definition.entities.add_instance @dim_y0, t
                  dim_comp_place.make_unique
                  dim_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if dim_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
                  distance = this_pt.distance Geom::Point3d.new(this_pt.x,leny,this_pt.z)
                  scale_factors = [1, -1*distance/dim_comp_place.bounds.height, scale]
                  dim_comp_place.transformation *= Geom::Transformation.scaling(*scale_factors)
                  dim_comp_place.layer = @dim_layer
                end
              end
            }
          }
        }
      end#def
      def dimension_z(essence,lenx,leny,lenz,fasteners)
        fasteners.each{|pts|
          pts.sort_by!{|pt|pt[2]}
          pts.reverse! if pts[0][2] > lenz/2
          pts.each_index{|index|
            if pts[index].x == 0 || pts[index].x == lenx
              this_pt = pt_from_array(pts[index])
              if @dimension_base == "2side" && this_pt.z > lenz/2
                index > 0 ? start_point = pt_from_array(pts[index-1]) : start_point = Geom::Point3d.new(this_pt.x,this_pt.y,lenz)
                dim_comp = @dim_z1
                scale = -1
                else
                index > 0 ? start_point = pt_from_array(pts[index-1]) : start_point = Geom::Point3d.new(this_pt.x,this_pt.y,0)
                dim_comp = @dim_z2
                scale = 1
              end
              t = Geom::Transformation.translation this_pt
              distance = this_pt.distance start_point
              if this_pt.y > 0.63 && this_pt.y < leny-0.63
                if distance*25.4 < 100 || index > 0
                  dim_comp_place = essence.definition.entities.add_instance @dim_z0, t
                  dim_comp_place.make_unique
                  dim_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if dim_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
                  scale_factors = [1, 1, scale*distance/dim_comp_place.bounds.depth]
                  dim_comp_place.transformation *= Geom::Transformation.scaling(*scale_factors)
                  else
                  dim_comp_place = essence.definition.entities.add_instance dim_comp, t
                  dim_comp_place.make_unique
                  dim_comp_place.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if dim_comp_place.parent.is_a?(Sketchup::ComponentDefinition)
                  precision = Sketchup::active_model.options['UnitsOptions']['LengthPrecision']
                  dim_comp_place.definition.entities.grep(Sketchup::DimensionLinear).each { |dim|
                    dim.text = (distance*25.4).round(precision).to_s
                  }
                end
                dim_comp_place.layer = @dim_layer
              end
            end
          }
        }
      end#def
      def pt_from_array(pt_array)
        Geom::Point3d.new(pt_array[0],pt_array[1],pt_array[2])
      end#def
      def search_fastener(essence)
        fasteners = []
        essence.definition.entities.grep(Sketchup::Group).each { |e|
          if e.get_attribute("_suf", "facedrilling") || e.get_attribute("_suf", "backdrilling")
            if e.get_attribute("_suf", "facedrilling")
              all_facedrilling = e.get_attribute("_suf", "facedrilling")
              drilling_arr = []
              all_facedrilling.each {|drilling|
                pt = drilling[4]
                if pt
                  drilling_arr << [pt[2]/25.4,pt[1]/25.4,pt[0]/25.4/1,pt[3],pt[4],pt[5]]
                  else
                  point = e.transformation.origin
                  points = [point.x,point.y,point.z,0,0,-1]
                  drilling_arr << points
                end
              }
              fasteners << drilling_arr
              elsif e.get_attribute("_suf", "backdrilling")
              all_backdrilling = e.get_attribute("_suf", "backdrilling")
              drilling_arr = []
              all_backdrilling.each {|drilling|
                pt = drilling[4]
                if pt
                  drilling_arr << [pt[2]/25.4,pt[1]/25.4,pt[0]/25.4/1,pt[3],pt[4],pt[5]]
                  else
                  point = e.transformation.origin
                  points = [point.x,point.y,point.z,0,0,1]
                  drilling_arr << points
                end
              }
              fasteners << drilling_arr
            end
          end			
        }
        return fasteners
      end#def
      def onLButtonDoubleClick(flags, x, y, view)
        if @selected_fasteners != []
          Sketchup.active_model.start_operation "Delete hole", true
          @selected_fasteners.each { |fastener|
            fastener.erase! if !fastener.deleted?
          }
          Sketchup.active_model.commit_operation
          elsif @essence && 1==2
          Sketchup.active_model.start_operation "Delete hole", true
          comp = @essence.parent.instances[0]
          comp = comp.parent.instances[0] if comp.definition.name.include?("Body")
          @essences = []
          delete_fastener(comp,@essence)
          Sketchup.active_model.commit_operation
        end
      end#def
      def delete_fastener(comp,essence=nil,delete_objects="",delete_dimensions=false)
        if !comp.deleted?
          if delete_objects != "hole"
            dict = comp.definition.attribute_dictionary "dynamic_attributes"
            if dict
              attributes_to_delete = []
              dict.each_pair {|attr, v|
                if attr.include?("z") && attr.include?("_name") && v || attr.include?("z") && attr.include?("_quantity") && v || attr.include?("z") && attr.include?("_template") && v || attr.include?("z") && attr.include?("_furniture") && v
                  if delete_objects == "template"
                    if attr.include?("z") && attr.include?("_name") && v && comp.definition.get_attribute("dynamic_attributes", attr.gsub("_name","_template")) || attr.include?("z") && attr.include?("_quantity") && v && comp.definition.get_attribute("dynamic_attributes", attr.gsub("_quantity","_template")) || attr.include?("z") && attr.include?("_template") && v
                      attributes_to_delete << attr
                    end
                    elsif delete_objects == "furniture"
                    if attr.include?("z") && attr.include?("_name") && v && comp.definition.get_attribute("dynamic_attributes", attr.gsub("_name","_furniture")) || attr.include?("z") && attr.include?("_quantity") && v && comp.definition.get_attribute("dynamic_attributes", attr.gsub("_quantity","_furniture")) || attr.include?("z") && attr.include?("_furniture") && v
                      attributes_to_delete << attr
                    end
                    else
                    attributes_to_delete << attr
                  end
                end
              }
              attributes_to_delete.each { |attr| comp.definition.delete_attribute("dynamic_attributes", attr) }
            end
          end
          holes = {}
          holes["other"] = []
          holes["template"] = []
          holes["furniture"] = []
          holes["hole"] = []
          essence.definition.entities.each { |ent|
            if ent.is_a?(Sketchup::ComponentInstance) && ent.definition.name.include?("dimension")
              ent.erase! if delete_dimensions
              elsif ent.is_a?(Sketchup::Group)
              if ent.get_attribute("_suf", "facedrilling") || ent.get_attribute("_suf", "backdrilling") || ent.get_attribute("_suf", "edgedrilling")
                if ent.get_attribute("_suf", "_template", false)
                  holes["template"] << ent
                  elsif ent.get_attribute("_suf", "_furniture", false)
                  holes["furniture"] << ent
                  elsif ent.get_attribute("_suf", "_hole", false)
                  holes["hole"] << ent
                  else
                  holes["other"] << ent
                end
              end
            end
          }
          key_to_delete = []
          if delete_objects == "template"
            comp.definition.delete_attribute("dynamic_attributes", "_template")
            essence.definition.delete_attribute("dynamic_attributes", "_template")
            @essences << essence if essence && !@essences.include?(essence)
            key_to_delete << "template"
            if holes["template"] != [] && holes["other"] == [] && holes["furniture"] == [] && holes["hole"] == []
              delete_attribute(comp)
              delete_attribute(essence)
            end
            elsif delete_objects == "furniture"
            comp.definition.delete_attribute("dynamic_attributes", "_furniture")
            essence.definition.delete_attribute("dynamic_attributes", "_furniture")
            @essences << essence if essence && !@essences.include?(essence)
            key_to_delete << "furniture"
            if holes["furniture"] != [] && holes["other"] == [] && holes["template"] == [] && holes["hole"] == []
              delete_attribute(comp)
              delete_attribute(essence)
            end
            elsif delete_objects == "hole"
            comp.definition.delete_attribute("dynamic_attributes", "_hole")
            essence.definition.delete_attribute("dynamic_attributes", "_hole")
            @essences << essence if essence && !@essences.include?(essence)
            key_to_delete << "hole"
            if holes["hole"] != [] && holes["other"] == [] && holes["template"] == [] && holes["furniture"] == []
              delete_attribute(comp)
              delete_attribute(essence)
            end
            else
            @essences << essence if essence && !@essences.include?(essence)
            key_to_delete = ["other","template","furniture","hole"]
            delete_attribute(comp)
            delete_attribute(essence)
            essence.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| ent.erase! if ent.definition.name.include?("dimension") }
          end
          holes.each_pair{|key,ent_arr|ent_arr.each{|ent|ent.erase!} if key_to_delete.include?(key)}
        end
      end#def
      def delete_attribute(entity)
        entity.definition.delete_attribute("dynamic_attributes", "_fastener")
        entity.definition.delete_attribute("dynamic_attributes", "_fastener_position_edge")
        entity.definition.delete_attribute("dynamic_attributes", "_fastener_position_back")
        entity.definition.delete_attribute("dynamic_attributes", "_fastener_position_front")
      end#def
      def onUserText(text, view)
        if text.to_f < 10
          UI.messagebox(SUF_STRINGS["Minimum distance 10 mm"])
          Sketchup::set_status_text(@fastener_indent, SB_VCB_VALUE)
          else
          @fastener_indent=text.to_f
          view.invalidate
          costruction_lines_pts
          draw(view)
        end
      end#def
      def onKeyDown(key, repeat, flags, view)
        if key==VK_SHIFT 
          @shift_press=true
          view.invalidate
          costruction_lines_pts
          draw(view)
          
          elsif key==VK_CONTROL || key==VK_COMMAND
          @control_press=true
          view.invalidate
          costruction_lines_pts
          draw(view)
          
          elsif key==VK_UP
          view.invalidate
          @reverse_fastener=false
          if @fastener_pts != {}
            @fastener_pts.each_pair { |edge_index,fastener_pts|  # номер торца
              fastener_pts.each_with_index { |pts,index|         # номер стыка
                if pts != []
                  pts.each_with_index { |pt,i|
                    if pt
                      @reverse_pt = pt
                      tr = @essence_and_transformation[@essence]
                      pt = pt.transform tr.inverse
                      pt = Geom::Point3d.new((pt.x==0 ? pt.x+@lenx : 0),pt.y,pt.z)
                      pts[i] = pt.transform tr
                      @ipface_normal = @ipface_normal.reverse
                      @reverse_fastener=true
                    end
                  }
                end
              }
            }
          end
          if @reverse_fastener
            @model.start_operation "Fastener", true
            essences = []
            essences = fastener_operation(essences)
            essences_dimensions(essences)
            @ipface_normal = @ipface_normal.reverse
            @reverse_fastener=false
            @reverse_pt = nil
            @model.commit_operation
          end
          
          elsif key==VK_DOWN
          @all_fastener_select = true
          view.invalidate
          draw(view)
          @model.start_operation "Fastener", true
          essences = []
          essences = fastener_operation(essences)
          essences_dimensions(essences)
          @model.commit_operation
          @all_fastener_select = false
          
          elsif key==VK_LEFT
          if @touch_hash
            for index in 0..3
              if @touch_hash[index] && @touch_hash[index] != []
                edge_index = nil
                if @fastener_pts != {}
                  @fastener_pts[index].each_with_index { |pts,index|
                    if pts != []
                      pts.each_with_index { |pt,i|
                        if pt
                          edge_index = index
                        end
                      }
                    end
                  }
                end
                next if !edge_index
                @touch_hash[index].each{|arr|
                  edge = arr[4]
                  edge_length = edge[0].distance edge[1]
                  fastener_count = additional_fastener_count(edge_length)
                  if fastener_count > 2
                    if @panel_fastener_count[@essence]
                      if @panel_fastener_count[@essence][index]
                        if @panel_fastener_count[@essence][index] > 2
                          @panel_fastener_count[@essence][index] = @panel_fastener_count[@essence][index] - 1
                        end
                        else
                        @panel_fastener_count[@essence][index] = fastener_count - 1
                      end
                      else
                      @panel_fastener_count[@essence] = {}
                      @panel_fastener_count[@essence][index] = fastener_count - 1
                    end
                    view.invalidate
                    costruction_lines_pts
                  end
                }
              end
            end
          end
          elsif key==VK_RIGHT
          if @touch_hash
            for index in 0..3
              if @touch_hash[index] && @touch_hash[index] != []
                edge_index = nil
                if @fastener_pts != {}
                  @fastener_pts[index].each_with_index { |pts,index|
                    if pts != []
                      pts.each_with_index { |pt,i|
                        if pt
                          edge_index = index
                        end
                      }
                    end
                  }
                end
                next if !edge_index
                @constlines_pts[index] = []
                @touch_hash[index].each{|arr|
                  edge = arr[4]
                  edge_length = edge[0].distance edge[1]
                  fastener_count = additional_fastener_count(edge_length)
                  if fastener_count > 2
                    if @panel_fastener_count[@essence]
                      if @panel_fastener_count[@essence][index]
                        if @panel_fastener_count[@essence][index] < 30
                          @panel_fastener_count[@essence][index] = @panel_fastener_count[@essence][index] + 1
                        end
                        else
                        @panel_fastener_count[@essence][index] = fastener_count + 1
                      end
                      else
                      @panel_fastener_count[@essence] = {}
                      @panel_fastener_count[@essence][index] = fastener_count + 1
                    end
                    view.invalidate
                    costruction_lines_pts
                  end
                }
              end
            end
          end
        end
      end#def
      def onKeyUp(key, repeat, flags, view)
        if key==VK_SHIFT
          UI.start_timer(0.1, false) {
            @shift_press=false
            view.invalidate
            costruction_lines_pts
            draw(view)
          }
          elsif key==VK_CONTROL || key==VK_COMMAND
          UI.start_timer(0.1, false) {
            @control_press=false
            view.invalidate
            costruction_lines_pts
            draw(view)
          }
          elsif key==9
          change_fastener_position(view)
        end
      end#def
      def onCancel(reason, view)
        if reason == 2
          @shift_press=false
          @control_press=false
          @reverse_fastener=false
          @reverse_pt = nil
          read_param
          @fastener_param = @fastener_parameters[@active_fastener]
          elsif reason == 0
          Sketchup.active_model.select_tool(nil)
        end
      end#def
      def onSetCursor
        UI.set_cursor(633)
      end#def
      def resume(view)
        view.invalidate
        costruction_lines_pts
        draw(view)
        if @indent32_1 == 0
          Sketchup::set_status_text("#{SUF_STRINGS["Fastener position from edge"]}", SB_VCB_LABEL)
          else
          Sketchup::set_status_text("#{SUF_STRINGS["Fastener position from edge"]} (#{SUF_STRINGS["system32"]} - #{@indent32_1},#{@indent32_1+16},#{@indent32_1+32},#{@indent32_1+48},#{@indent32_1+64})", SB_VCB_LABEL)
        end
        @fastener_indent = @fastener_indent.round if @fastener_indent.to_s[-1] == "0"
        Sketchup::set_status_text(@fastener_indent, SB_VCB_VALUE)
      end#def
      def reset(view=nil)
        view.lock_inference if view && view.inference_locked?
      end#def
      def enableVCB?
        return true
      end
  end#Class
end#Module
