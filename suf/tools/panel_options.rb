module SU_Furniture
  class ChangePoint
    def initialize(need_redraw=[])
      if(Sketchup.version.to_i >= 16)
        if(OSX)
          @default = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.pdf') unless defined? @default
          @active = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.pdf') unless defined? @active
          @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.pdf') unless defined? @noactions
          else
          @default = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.svg') unless defined? @default
          @active = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.svg') unless defined? @active
          @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.svg') unless defined? @noactions
        end
        else
        @default = File.join(PATH+"/html/cont/style", 'cursor_interact_tool.png') unless defined? @default
        @active = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_active.png') unless defined? @active
        @noactions = File.join(PATH+"/html/cont/style", 'cursor_interact_tool_noactions.png') unless defined? @noactions
      end
      @double_click = false
      @shift_press = false
      @control_press = false
      @hover_message = "Hover over a component to find its click behaviors."
      @cursor_default = UI.create_cursor(@default, 3, 2)
      @cursor_active = UI.create_cursor(@active, 9, 9)
      @cursor_noactions = UI.create_cursor(@noactions, 9, 9)
      @conv = DCConverter.new
      @current_edge = 0
      @current_edge_color = "gray"
      @line_1_text = "#{SUF_STRINGS["Edge thickness"]}:"
      @line_osb_text = "OSB"
      @line_0_0_text = "#{SUF_STRINGS["no edge"]}"
      @line_rec_text = "████"
      @line_2_text = "#{SUF_STRINGS["Replace attachment points"]}:"
      @line_tab_text = "#{SUF_STRINGS["By thickness"]} - TAB"
      @line_sep_text = "|"
      @line_x1_text = "#{SUF_STRINGS["along X axis"]}"
      @line_x2_text = " - #{SUF_STRINGS["Rightward"]}"
      @line_y1_text = "#{SUF_STRINGS["along Y axis"]}"
      @line_y2_text = " - #{SUF_STRINGS["Leftward"]}"
      @line_z1_text = "#{SUF_STRINGS["along Z axis"]}"
      @line_z2_text = " - #{SUF_STRINGS["Upward"]} #{SUF_STRINGS["or"]} #{SUF_STRINGS["Downward"]}"
      @is_animating = false
      @activate = false
      @need_redraw = need_redraw
      @panel_and_faces = {}
			@panel_and_essence = {}
			@panel_and_tr = {}
      @place_component = []
			@att_arr = ["edge_y1","edge_y2","edge_z1","edge_z2","description","su_info"]
			@EPSILON = 0.001
			@E_VE_POS = Geom::Vector3d.new(@EPSILON, @EPSILON, @EPSILON)
			@E_VE_NEG = Geom::Vector3d.new(-@EPSILON, -@EPSILON, -@EPSILON)
    end
    def set_color_and_text
      @color_face = Sketchup::Color.new(0, 0, 0, 20).freeze
      @orange = Sketchup::Color.new(210, 130, 0)
      @blue = Sketchup::Color.new(0, 0, 255)
      @green = Sketchup::Color.new(0, 200, 0)
      @green_blue = Sketchup::Color.new(0, 200, 200)
      @yellow = Sketchup::Color.new(240, 240, 0)
      @dark_yellow = Sketchup::Color.new(240, 150, 0)
      @red = Sketchup::Color.new(255, 0, 0)
      @dark_red = Sketchup::Color.new(128, 0, 0)
      
      @text_header_size = (OSX ? 20 : 10)
      @text_size = (OSX ? 18 : 9)
      @offset_x = (OSX ? 8 : 0)
      @offset_y = (OSX ? 8 : 0)
      @size_x = (OSX ? 20 : 0)
      @size_y = (OSX ? 18 : 0)
      
      @center_text_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      @center_black_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignCenter
      }
      @line_gray_text_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_black_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_black_bold_text_options = {
        color: "black",
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft,
        bold: true
      }
      @line_orange_text_options = {
        color: @orange,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_green_text_options = {
        color: @green,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_blue_text_options = {
        color: @blue,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_green_blue_text_options = {
        color: @green_blue,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_yellow_text_options = {
        color: @yellow,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_dark_yellow_text_options = {
        color: @dark_yellow,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_red_text_options = {
        color: @red,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_dark_red_text_options = {
        color: @dark_red,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @edge2 = Sketchup::Color.new(@edge_color_arr[1].split(",")[0].to_i, @edge_color_arr[1].split(",")[1].to_i, @edge_color_arr[1].split(",")[2].to_i,190)
      @edge3 = Sketchup::Color.new(@edge_color_arr[2].split(",")[0].to_i, @edge_color_arr[2].split(",")[1].to_i, @edge_color_arr[2].split(",")[2].to_i,190)
      @edge4 = Sketchup::Color.new(@edge_color_arr[3].split(",")[0].to_i, @edge_color_arr[3].split(",")[1].to_i, @edge_color_arr[3].split(",")[2].to_i,190)
      @edge5 = Sketchup::Color.new(@edge_color_arr[4].split(",")[0].to_i, @edge_color_arr[4].split(",")[1].to_i, @edge_color_arr[4].split(",")[2].to_i,190)
      @edge6 = Sketchup::Color.new(@edge_color_arr[5].split(",")[0].to_i, @edge_color_arr[5].split(",")[1].to_i, @edge_color_arr[5].split(",")[2].to_i,190)
      @edge7 = Sketchup::Color.new(@edge_color_arr[6].split(",")[0].to_i, @edge_color_arr[6].split(",")[1].to_i, @edge_color_arr[6].split(",")[2].to_i,190)
      @line_edge2_text_options = {
        color: @edge2,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_edge3_text_options = {
        color: @edge3,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_edge4_text_options = {
        color: @edge4,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_edge5_text_options = {
        color: @edge5,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_edge6_text_options = {
        color: @edge6,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_edge7_text_options = {
        color: @edge7,
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
    end#def
    def active
      @activate
    end#def
    def run
      activate
    end#def
    def place_component(inst)
      @place_component << inst if !@place_component.include?(inst)
    end#def
    def mat_from_name(mat_name)
      @model.materials.each{|mat| return mat if mat.display_name.include?(mat_name) }
    end#def
    def image_rep(view,mat_name)
      new_mat = mat_from_name(mat_name)
      image_rep = new_mat.texture.image_rep
      return view.load_texture(image_rep)
    end#def
    def activate
      @model = Sketchup.active_model
      @sel = @model.selection
      @sel.remove_observer $SUFSelectionObserver
      @model.entities.remove_observer $SUFEntitiesObserver
      @mouse_down = nil
      @screen_x=0
      @screen_y=0
			@ip=Sketchup::InputPoint.new
      @shift_press = false
      @control_press = false
      @is_animating = false
      $add_component = 0
      view = @model.active_view
      @sel_clear = false
      @sel_ents = @sel.grep(Sketchup::ComponentInstance).to_a
      #@@model.start_operation('Change_Point', true,false,true)
      @point_x_offset,@point_y_offset,@point_z_offset,@trim_x1,@trim_x2 = nil
      if @sel.length != 0 && @sel.grep(Sketchup::ComponentInstance)[0]
        entity = @sel.grep(Sketchup::ComponentInstance)[0]
        @ent_def = entity.definition
        @a03_name = @ent_def.get_attribute("dynamic_attributes", "a03_name")
        @point_x_offset = @ent_def.get_attribute("dynamic_attributes", "point_x_offset") #Vertical
        @point_y_offset = @ent_def.get_attribute("dynamic_attributes", "point_y_offset") #Frontal
        @point_z_offset = @ent_def.get_attribute("dynamic_attributes", "point_z_offset") #Gorizontal
        @trim_x1 = @ent_def.get_attribute("dynamic_attributes", "trim_x1") #Изделие
        @trim_x2 = @ent_def.get_attribute("dynamic_attributes", "trim_x2") #Изделие
        a0_shelves_count = @ent_def.get_attribute("dynamic_attributes", "a0_shelves_count")
        a0_panel_count = @ent_def.get_attribute("dynamic_attributes", "a0_panel_count")
        a0_drawer_count = @ent_def.get_attribute("dynamic_attributes", "a0_drawer_count")
        if @sel.length == 1 
          if @point_x_offset || @point_y_offset || @point_z_offset
            @edge_z2 = @ent_def.get_attribute("dynamic_attributes", "edge_z2", "0")
            @edge_z1 = @ent_def.get_attribute("dynamic_attributes", "edge_z1", "0")
            @edge_y1 = @ent_def.get_attribute("dynamic_attributes", "edge_y1", "0")
            @edge_y2 = @ent_def.get_attribute("dynamic_attributes", "edge_y2", "0")
          end
        end
        @sel.clear
        @sel_clear = true
      end
      @edge_width = []
      @edge_thickness = []
      @edge_color_arr = []
			@reverse_faces = {}
      @hide_face = "yes"
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				@path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				@path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				@path_param = File.join(PATH,"parameters","parameters.dat")
      end
      @content = File.readlines(@path_param)
      @content.each { |i|
        @hide_face = i.strip.split("=")[2] if i.strip.split("=")[1] == "hide_face"
        if i.strip.split("=")[1] && i.strip.split("=")[1].include?("edge_trim")
          @edge_width << i.strip.split("=")[0][4..-1] 
          @edge_thickness << i.strip.split("=")[0][4..-1].split(" ")[0]
          @edge_color_arr << i.strip.split("=")[4]
        end
      }
      set_color_and_text
			if !@model.materials.any?{|mat| mat.display_name == "DSP"}
			  material = @model.materials.add("DSP")
				material.texture = File.join(PATH,'additions','DSP.jpg')
      end
      @dsp = image_rep(view,"DSP")
      
      @model.start_operation "search", true, false, true
      @model.layers.add("Z_Face")
      @model.layers.remove("1_Фасад_текстура", true) if @model.layers["1_Фасад_текстура"]
			@model.layers.remove("3_Каркас_текстура", true) if @model.layers["3_Каркас_текстура"]
			@model.layers.remove("8_Толщина_кромки", true) if @model.layers["8_Толщина_кромки"]
      @sel.add @sel_ents if @sel_clear
      if !@activate
        @visible_layer = {}
        @model.layers.each { |l|
          l.visible = true if l.name.include?("Z_Edge")
					l.visible = true if l.name.include?("Z_Face")
          @visible_layer[l] = l.visible?
          l.visible = true if l.name.include?("Габаритная_рамка") || l.name.include?("Направляющие")
          l.visible = false if l.name.include?("Фасад_открывание")
        }
      end
      @model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") } if @hide_face == "yes"
      #@model.entities.grep(Sketchup::ComponentInstance).each { |entity| edge_material_formula(entity) }
      @sel.grep(Sketchup::ComponentInstance).each { |entity|
        b3_edge_default = entity.definition.get_attribute("dynamic_attributes", "b3_edge_default")
        edge_default = entity.definition.get_attribute("dynamic_attributes", "edge_default")
        if b3_edge_default
          entity.definition.set_attribute("dynamic_attributes", "_b3_edge_default_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
          elsif edge_default
          entity.definition.set_attribute("dynamic_attributes", "_edge_default_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
        end
      }
      @place_component = []
      reset_essence_and_faces
      comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
			find_reverse_faces
      @model.commit_operation
      
      @line_0_4_text = @edge_width[1]
      @line_4_4_text = @edge_width[2]
      @line_1_0_text = @edge_width[3]
      @line_1_1_text = @edge_width[4]
      @line_2_0_text = @edge_width[5]
      @line_2_2_text = @edge_width[6]
      @line_0_text = "#{SUF_STRINGS["Another panel: Double-click LMB"]} (#{SUF_STRINGS["Add"]}: Shift+"
      OSX ? @line_0_text += " #{SUF_STRINGS["or"]} Command+" : @line_0_text += " #{SUF_STRINGS["or"]} Ctrl+"
      @line_0_text += ") | #{SUF_STRINGS["Exit: Esc or select tool"]}"
      if @trim_x1 || @trim_x2
        @line_0_text += " | +/- #{SUF_STRINGS["Number of shelves"]}" if a0_shelves_count
        @line_0_text += " | +/- #{SUF_STRINGS["Number of panels"]}" if a0_panel_count
        @line_0_text += " | +/- #{SUF_STRINGS["Number of drawers"]}" if a0_drawer_count
      end
      if @point_x_offset || @point_y_offset || @point_z_offset
        @line_3_text = "#{SUF_STRINGS["Trim panel"]}:"
        elsif @trim_x1 || @trim_x2
        @line_3_text = "#{SUF_STRINGS["Edge offsets"]}:"
      end
      if @point_y_offset
        @len = "a0_leny"
        @width = @ent_def.get_attribute("dynamic_attributes", "a01_lenx", "0")*25.4
        @height = @ent_def.get_attribute("dynamic_attributes", "a01_lenz", "0")*25.4
        @line_3_panel_text = "#{SUF_STRINGS["Left"]} - SHIFT+#{SUF_STRINGS["Leftward"]} | #{SUF_STRINGS["Right"]} - SHIFT+#{SUF_STRINGS["Rightward"]} | #{SUF_STRINGS["Top"]} - SHIFT+#{SUF_STRINGS["Upward"]} | #{SUF_STRINGS["Bottom"]} - SHIFT+#{SUF_STRINGS["Downward"]}"
        elsif @point_x_offset
        @len = "a0_lenx"
        @width = @ent_def.get_attribute("dynamic_attributes", "a01_leny", "0")*25.4
        @height = @ent_def.get_attribute("dynamic_attributes", "a01_lenz", "0")*25.4
        @line_3_panel_text = "#{SUF_STRINGS["Front"]} - SHIFT+#{SUF_STRINGS["Leftward"]} | #{SUF_STRINGS["Back"]} - SHIFT+#{SUF_STRINGS["Rightward"]} | #{SUF_STRINGS["Top"]} - SHIFT+#{SUF_STRINGS["Upward"]} | #{SUF_STRINGS["Bottom"]} - SHIFT+#{SUF_STRINGS["Downward"]}"
        elsif @point_z_offset
        @len = "a0_lenz"
        @width = @ent_def.get_attribute("dynamic_attributes", "a01_leny", "0")*25.4
        @height = @ent_def.get_attribute("dynamic_attributes", "a01_lenx", "0")*25.4
        @line_3_panel_text = "#{SUF_STRINGS["Left"]} - SHIFT+#{SUF_STRINGS["Leftward"]} | #{SUF_STRINGS["Right"]} - SHIFT+#{SUF_STRINGS["Rightward"]} | #{SUF_STRINGS["Back"]} - SHIFT+#{SUF_STRINGS["Upward"]} | #{SUF_STRINGS["Front"]} - SHIFT+#{SUF_STRINGS["Downward"]}"
        elsif @trim_x1 || @trim_x2
        @len = "b1_p_thickness"
        @line_3_panel_text = "#{SUF_STRINGS["Left"]} - SHIFT+#{SUF_STRINGS["Leftward"]} | #{SUF_STRINGS["Right"]} - SHIFT+#{SUF_STRINGS["Rightward"]} | #{SUF_STRINGS["Top"]} - SHIFT+#{SUF_STRINGS["Upward"]} | #{SUF_STRINGS["Bottom"]} - SHIFT+#{SUF_STRINGS["Downward"]}"
      end
      if @point_x_offset || @point_y_offset || @point_z_offset
        Sketchup::set_status_text "#{SUF_STRINGS["Thickness offset"]} ", SB_VCB_LABEL
      end
      @activate = true
    end
    def reset_essence_and_faces
      @panel_and_faces = {}
			@panel_and_essence = {}
			@panel_and_tr = {}
    end
    def comp_with_essence(ents,edge_color_arr)
      if @place_component == []
        if @panel_and_faces == {}
          ents.each { |comp|
					  edge_material_formula(comp,edge_color_arr)
            search_comp_with_essence(comp,Geom::Transformation.new)
            comp.definition.set_attribute("dynamic_attributes", "_draw_edges", true)
          }
          else
          ents.each { |comp|
            if !comp.definition.get_attribute("dynamic_attributes", "_draw_edges")
						  edge_material_formula(comp,edge_color_arr)
              search_comp_with_essence(comp,Geom::Transformation.new)
            end
          }
        end
        else
        
        @place_component.each { |comp|
          if !comp.deleted?
            tr = Geom::Transformation.new
            all_comp=search_parent(comp)
            
            if all_comp != []
              all_comp.reverse.each { |parent_comp|
                parent_comp.make_unique
                parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
                tr *= parent_comp.transformation
              }
            end
            comp.make_unique if comp.definition.count_instances > 1
            comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
						edge_material_formula(comp,edge_color_arr)
            search_comp_with_essence(comp,tr)
          end
        }
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
		def all_edges(panel,edge_y1_texture)
		  edge_y1 = panel.definition.get_attribute("dynamic_attributes", "edge_y1")
			edge_y1_length = panel.definition.get_attribute("dynamic_attributes", "edge_y1_length")
			if edge_y1_length && !edge_y1_texture
				if edge_y1_length.to_f == 0
					edge_y1 = new_edge("0")
					else
					edge_y1 = new_edge(edge_y1)
        end
      end
			edge_y2 = panel.definition.get_attribute("dynamic_attributes", "edge_y2")
			edge_y2_length = panel.definition.get_attribute("dynamic_attributes", "edge_y2_length")
			if edge_y2_length && !edge_y1_texture
				if edge_y2_length.to_f == 0
					edge_y2 = new_edge("0")
					else
					edge_y2 = new_edge(edge_y2)
        end
      end
			edge_z1 = panel.definition.get_attribute("dynamic_attributes", "edge_z1")
			edge_z1_length = panel.definition.get_attribute("dynamic_attributes", "edge_z1_length")
			if edge_z1_length && !edge_y1_texture
				if edge_z1_length.to_f == 0
					edge_z1 = new_edge("0")
					else
					edge_z1 = new_edge(edge_z1)
        end
      end
			edge_z2 = panel.definition.get_attribute("dynamic_attributes", "edge_z2")
			edge_z2_length = panel.definition.get_attribute("dynamic_attributes", "edge_z2_length")
			if edge_z2_length && !edge_y1_texture
				if edge_z2_length.to_f == 0
					edge_z2 = new_edge("0")
					else
					edge_z2 = new_edge(edge_z2)
        end
      end
			return edge_y1,edge_y2,edge_z1,edge_z2
      end#def
		def all_faces(comp,panel,tr)
		  if panel.definition.get_attribute("dynamic_attributes", "a05_napr")
				napr_texture_att = "a05_napr"
				else
				napr_texture_att = "napr_texture"
      end
		  napr_texture = panel.definition.get_attribute("dynamic_attributes", napr_texture_att)
		  edge_y1_texture = panel.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
		  edge_y1,edge_y2,edge_z1,edge_z2 = all_edges(panel,edge_y1_texture)
			lenx = comp.definition.get_attribute("dynamic_attributes", "lenx", 0).to_f
			leny = comp.definition.get_attribute("dynamic_attributes", "leny", 0).to_f
			lenz = comp.definition.get_attribute("dynamic_attributes", "lenz", 0).to_f
			faces = {}
			tr *= comp.transformation
			comp.definition.entities.grep(Sketchup::Face).each { |f|
			  bounds = f.bounds
			  if f.normal.normalize.x.abs == 1
					f.layer = "Z_Face"
					f_center = bounds.center
					if !edge_y1_texture && napr_texture.to_s == "2"
						point1 = Geom::Point3d.new(f_center.x,f_center.y-bounds.height/4,f_center.z-bounds.depth/4)
						point3 = Geom::Point3d.new(f_center.x,f_center.y-bounds.height/4,f_center.z+bounds.depth/4)
						point2 = Geom::Point3d.new(f_center.x,f_center.y+bounds.height/4,f_center.z-bounds.depth/4)
						point4 = Geom::Point3d.new(f_center.x,f_center.y+bounds.height/4,f_center.z+bounds.depth/4)
						else
						point1 = Geom::Point3d.new(f_center.x,f_center.y-bounds.height/4,f_center.z-bounds.depth/4)
						point2 = Geom::Point3d.new(f_center.x,f_center.y-bounds.height/4,f_center.z+bounds.depth/4)
						point3 = Geom::Point3d.new(f_center.x,f_center.y+bounds.height/4,f_center.z-bounds.depth/4)
						point4 = Geom::Point3d.new(f_center.x,f_center.y+bounds.height/4,f_center.z+bounds.depth/4)
          end
					faces[f] = [napr_texture_att,napr_texture,[point1.transform(tr),point2.transform(tr),point3.transform(tr),point4.transform(tr)],tr,edge_y1_texture]
					else
					f.layer = "Z_Edge"
					f_normal = f.normal.normalize
					if f_normal.y == 1 && bounds.center.y == leny
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[f] = ["edge_y2",edge_y2,points_bb(bounds,tr),tr]
							else
							faces[f] = ["edge_z2",edge_z2,points_bb(bounds,tr),tr]
            end
						elsif f_normal.y == -1 && bounds.center.y == 0
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[f] = ["edge_y1",edge_y1,points_bb(bounds,tr),tr]
							else
							faces[f] = ["edge_z1",edge_z1,points_bb(bounds,tr),tr]
            end
						elsif f_normal.z == 1 && bounds.center.z == lenz
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[f] = ["edge_z2",edge_z2,points_bb(bounds,tr),tr]
							else
							faces[f] = ["edge_y1",edge_y1,points_bb(bounds,tr),tr]
            end
						elsif f_normal.z == -1 && bounds.center.z == 0
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[f] = ["edge_z1",edge_z1,points_bb(bounds,tr),tr]
							else
							faces[f] = ["edge_y2",edge_y2,points_bb(bounds,tr),tr]
            end
          end
        end
      }
			comp.definition.entities.grep(Sketchup::ComponentInstance).each { |f|
				if f.definition.name.include?("K_F")
					f.definition.entities.grep(Sketchup::Face).each { |face|
						if !edge_y1_texture && napr_texture.to_s == "2"
              faces[face] = ["edge_y1",edge_y1,points_bb(face.bounds,tr*f.transformation),tr]
              else
              faces[face] = ["edge_z1",edge_z1,points_bb(face.bounds,tr*f.transformation),tr]
            end
          }
					elsif f.definition.name.include?("K_RR")
					f.definition.entities.grep(Sketchup::Face).each { |face|
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[face] = ["edge_y2",edge_y2,points_bb(face.bounds,tr*f.transformation),tr]
							else
							faces[face] = ["edge_z2",edge_z2,points_bb(face.bounds,tr*f.transformation),tr]
            end
          }
					elsif f.definition.name.include?("K_U")
					f.definition.entities.grep(Sketchup::Face).each { |face|
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[face] = ["edge_z2",edge_z2,points_bb(face.bounds,tr*f.transformation),tr]
							else
							faces[face] = ["edge_y1",edge_y1,points_bb(face.bounds,tr*f.transformation),tr]
            end
          }
					elsif f.definition.name.include?("K_L")
					f.definition.entities.grep(Sketchup::Face).each { |face|
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[face] = ["edge_z1",edge_z1,points_bb(face.bounds,tr*f.transformation),tr]
							else
							faces[face] = ["edge_y2",edge_y2,points_bb(face.bounds,tr*f.transformation),tr]
            end
          }
					elsif f.definition.name.include?("K_R") && !f.definition.name.include?("K_RR")
					f.definition.entities.grep(Sketchup::Face).each { |face|
						if !edge_y1_texture && napr_texture.to_s == "2"
							faces[face] = ["edge_z2",edge_z2,points_bb(face.bounds,tr*f.transformation),tr]
							else
							faces[face] = ["edge_y1",edge_y1,points_bb(face.bounds,tr*f.transformation),tr]
            end
          }
        end
      }
			return faces
    end#def
		def search_comp_with_essence(comp,tr)
			if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
				napr_texture = comp.definition.get_attribute("dynamic_attributes", "napr_texture")
				napr_texture = comp.definition.get_attribute("dynamic_attributes", "texturemat") if !napr_texture
				if comp.parent.is_a?(Sketchup::ComponentDefinition) && napr_texture
					comp.make_unique if comp.definition.count_instances > 1
          comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
					if comp.parent.instances[-1].definition.name.include?("Body")
						panel = comp.parent.instances[-1].parent.instances[-1]
						else
						panel = comp.parent.instances[-1]
          end
					@panel_and_essence[panel] = comp
					@panel_and_tr[panel] = tr
					@panel_and_faces[panel] = all_faces(comp,panel,tr)
        end
				else
				if !comp.hidden?
					comp.make_unique if comp.definition.count_instances > 1
          comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
					comp.definition.entities.grep(Sketchup::ComponentInstance).each { |body| search_comp_with_essence(body,tr*comp.transformation) if !body.hidden?}
        end
      end
    end#def
		def points_bb(bb,tr)
			if bb.width!=0 && bb.height!=0
				points = [bb.corner(0).transform(tr),bb.corner(1).transform(tr),bb.corner(3).transform(tr),bb.corner(2).transform(tr)]
				elsif bb.depth!=0 && bb.height!=0
				points = [bb.corner(0).transform(tr),bb.corner(2).transform(tr),bb.corner(6).transform(tr),bb.corner(4).transform(tr)]
				else
				points = [bb.corner(0).transform(tr),bb.corner(1).transform(tr),bb.corner(5).transform(tr),bb.corner(4).transform(tr)]
      end
			return points
    end#def
		def edge_material_formula(unit,edge_color_arr)
			if unit.definition.name.include?("edge") && unit.definition.get_attribute("dynamic_attributes", "_material_formula") && unit.definition.get_attribute("dynamic_attributes", "_material_formula", "") != 'CHOOSE(edge,"DSP","'+edge_color_arr[1]+'","'+edge_color_arr[2]+'","'+edge_color_arr[3]+'","'+edge_color_arr[4]+'","'+edge_color_arr[5]+'","'+edge_color_arr[6]+'")'
				unit.definition.set_attribute("dynamic_attributes", "_material_formula", 'CHOOSE(edge,"DSP","'+edge_color_arr[1]+'","'+edge_color_arr[2]+'","'+edge_color_arr[3]+'","'+edge_color_arr[4]+'","'+edge_color_arr[5]+'","'+edge_color_arr[6]+'")')
				else
				unit.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| edge_material_formula(entity,edge_color_arr) }
      end
    end#def
		def deactivate(view)
			#p "deactivate options"
			@activate = false
			if @activate == false
				@model.start_operation "layers", true, false, true
				@visible_layer.each_pair { |l,v| l.visible = v if !l.deleted? } if @visible_layer
				@model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") || l.name.include?("Z_Edge") }
				@model.layers.each { |l| l.visible = false if l.name.include?("Габаритная_рамка") }
				@shift_press = false
				@control_press = false
				@model.commit_operation
				view.invalidate
      end
			view.release_texture(@dsp)
			#@model.commit_operation
			if SU_Furniture.observers_state == 1
				@sel.add_observer $SUFSelectionObserver
				@model.entities.add_observer $SUFEntitiesObserver
      end
    end
		def onCancel(reason, view)
			puts "Cancel reason: #{reason}"
			if reason == 2
				@model.abort_operation
				UI.start_timer(0.1, false) {
					@panel_and_faces = {}
					@panel_and_essence = {}
					@panel_and_tr = {}
					activate
					view.invalidate
					draw(view)
        }
      end
    end#def
		def resume(view)
			view.invalidate
    end
		def draw_active_edge_buttons(view,text,y1,y2)
			view.drawing_color = "black"
			view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(25, y1+@offset_y/2, 0), Geom::Point3d.new(75, y1+@offset_y/2, 0), Geom::Point3d.new(75, y2+@offset_y/2, 0), Geom::Point3d.new(25, y2+@offset_y/2, 0) ])
			view.draw_text(Geom::Point3d.new(85, y1+4, 0), text, @line_black_bold_text_options)
    end
		def draw_edge_buttons(view,edge_color,current_edge,text,y1,y2)
			view.drawing_color = "black"
			view.draw_text(Geom::Point3d.new(85, y1+1, 0), text, @line_gray_text_options)
			if @screen_x < 120 && @screen_x > 20 && @screen_y > y1-5 && @screen_y < y2+5+@offset_y
				@button_points = [
					Geom::Point3d.new(29, y1+@offset_y/2, 0),
					Geom::Point3d.new(71, y1+@offset_y/2, 0),
					Geom::Point3d.new(71, y2+@offset_y/2, 0),
					Geom::Point3d.new(29, y2+@offset_y/2, 0)
        ]
				view.draw2d(GL_LINE_LOOP, @button_points)
				@select_edge = current_edge
				@edge_color = edge_color
      end
    end
		def new_edge(edge)
			case edge.to_s.gsub("c","с")
				when "0" then edge = "1"
				when "0.4" then edge = "2"
				when "0.4 с подрезкой" then edge = "3"
				when "1" then edge = "4"
				when "1 с подрезкой" then edge = "5"
				when "2" then edge = "6"
				when "2 с подрезкой" then edge = "7"
      end
			return edge
    end
		def old_edge(edge)
			case edge.to_s
				when "7" then edge = "2 с подрезкой"
				when "6" then edge = "2"
				when "5" then edge = "1 с подрезкой"
				when "4" then edge = "1"
				when "3" then edge = "0.4 с подрезкой"
				when "2" then edge = "0.4"
				when "1" then edge = "0"
      end
			return edge
    end
		def color_of_edge(edge)
			case edge
				when "7" then color = @edge7
				when "6" then color = @edge6
				when "5" then color = @edge5
				when "4" then color = @edge4
				when "3" then color = @edge3
				when "2" then color = @edge2
				else color = "black"
      end
			color == "black" ? @line_width = 1 : @line_width = 3
			return color
    end
		def find_reverse_faces
			@face_drawed = {}
			@panel_and_faces.each_pair {|panel,face_hash|
				face_hash.each_pair {|face,edge_arr|
					if edge_arr[0].include?("edge")
						edge = edge_arr[1].to_s
						points = edge_arr[2]
						transformation = edge_arr[3]
						boundingbox = getBB(face.edges, transformation)
						if @face_drawed != {}
							@face_drawed.each_pair { |f,arr|
								tr = arr[0]
								comp = arr[1]
								bb = arr[2]
								if comp != panel && face != f
									result = boundingbox.intersect(bb)
									if !result.empty?
										if boundingbox.contains?(bb) && bb.contains?(boundingbox)
											@reverse_faces[face] = [points,transformation]
											@reverse_faces[f] = [points_bb(f.bounds,tr),tr]
											elsif !boundingbox.contains?(bb) && bb.contains?(boundingbox)
											new_points = subtract_faces(points_bb(f.bounds,tr),points)
											@reverse_faces[f] = [points_bb(f.bounds,tr),tr,new_points] # больше
											@reverse_faces[face] = [points,transformation]
											elsif boundingbox.contains?(bb) && !bb.contains?(boundingbox)
											new_points = subtract_faces(points,points_bb(f.bounds,tr))
											@reverse_faces[face] = [points,transformation,new_points] # больше
											@reverse_faces[f] = [points_bb(f.bounds,tr),tr]
                    end
                  end
                end
              }
            end
						@face_drawed[face] = [transformation,panel,boundingbox]
          end
        }
      }
    end
		def subtract_faces(points1,points2)
			new_points = []
			group = @model.entities.add_group
			face1 = group.entities.add_face(points1)
			face2 = group.entities.add_face(points2)
			group.entities.grep(Sketchup::Face).each {|f| f.erase! if f == face2 }
			group.entities.grep(Sketchup::Face).each {|f|
				new_points << points_bb(f.bounds,group.transformation)
      }
			group.erase!
			return new_points
    end
		def getBB(edges, tr)
			vs = edges.map{|e| e.vertices}
			return nil if vs.length == 0
			vs.flatten!.uniq!
			bb = Geom::BoundingBox.new
			vs.each { |v| bb.add(v.position.transform(tr)) }
			bb_min = bb.min.offset(@E_VE_NEG)
			bb_max = bb.max.offset(@E_VE_POS)
			bb2 = Geom::BoundingBox.new
			bb2.add(bb_min)
			bb2.add(bb_max)
			return bb2
    end
		def draw_edges(view)
			@panel_and_faces.each_pair {|comp,face_hash|
				if !comp.deleted? && comp.layer.visible?
					face_hash.each_pair {|face,edge_arr|
						if face.parent.instances[-1].layer.visible?
              if edge_arr[0].include?("edge")
                edge = edge_arr[1].to_s
                points = edge_arr[2]
                if !@reverse_faces[face]
                  draw_edge_quads(view,points,edge)
                end
                view.line_width = 2
                view.drawing_color = "gray"
                if @source_edge && @source_edge == points
                  view.line_width = 4
                  view.drawing_color = "black"
                end
                view.draw(GL_LINE_LOOP, points)
                
                elsif @hide_face == "no"
                view.drawing_color = "black"
                view.line_width = 2
                if @source_face && @source_face == face
                  view.line_width = 4
                end
                if edge_arr[1].to_s == "2"
                  points_array = [[edge_arr[2][0],edge_arr[2][2]],[edge_arr[2][1],edge_arr[2][3]]]
                  else
                  points_array = [[edge_arr[2][0],edge_arr[2][1]],[edge_arr[2][2],edge_arr[2][3]]]
                end
                points_array.each { |points|
                  view.draw(GL_LINES, points)
                }
              end
            end
          }
        end
      }
			if @reverse_faces != {}
				@reverse_faces.each_pair { |reverse_face,edge_arr|
					points = edge_arr[0]
          transformation = edge_arr[1]
          new_points = edge_arr[2]
          @panel_and_faces.each_pair {|comp,hash|
            if hash[reverse_face]
              edge = hash[reverse_face][1].to_s
              if reverse_face.normal.transform(transformation).angle_between(Sketchup.active_model.active_view.camera.direction)<90.degrees
                draw_edge_quads(view,points,edge)
                elsif new_points
                new_points.each { |points| draw_edge_quads(view,points,edge) }
              end
            end
          }
        }
      end
    end
		def draw_edge_quads(view,points,edge)
			if edge == "1"
				uvs = [ [1, 0.1, 0], [1, 0, 0.1], [0, 0.1, 0], [0, 0, 0.1] ]
				view.draw(GL_QUADS, points, texture: @dsp, uvs: uvs)
				else
				view.drawing_color = color_of_edge(edge)
				view.draw(GL_QUADS, points)
      end
    end
		def draw(view)
			draw_edges(view)
			view.drawing_color = "white"
			count = 7
			if @screen_x > 0 && @screen_x < 240 && @screen_y > 0 && @screen_y < 100+(30+@offset_y)*count
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(240, 0, 0), Geom::Point3d.new(240, 100+(30+@offset_y)*count, 0), Geom::Point3d.new(0, 100+(30+@offset_y)*count, 0) ])
      end
			view.line_width = 1
			view.drawing_color = "gray"
			@select_edge = 0
			@edge_color = "gray"
			y = 25
			hide_face_text = SUF_STRINGS["Yes"]
			hide_face_text = SUF_STRINGS["No"] if @hide_face == "no"
			view.draw_text(Geom::Point3d.new(30, y, 0), "#{SUF_STRINGS["Hide panel face"]}: ", @line_gray_text_options)
			if @screen_x > 20+@offset_x*10 && @screen_x < 220+@offset_x*10 && @screen_y > 20 && @screen_y < 40+@offset_y
				view.draw_text(Geom::Point3d.new(195+@offset_x*10, y, 0), hide_face_text, @line_black_bold_text_options)
				@hide_face_button = true
				else
				view.draw_text(Geom::Point3d.new(195+@offset_x*10, y, 0), hide_face_text, @line_gray_text_options)
				@hide_face_button = false
      end
			
			y += 30+@offset_y
			view.draw_text(Geom::Point3d.new(30, y, 0), @line_1_text, @line_gray_text_options)
			y += 30+@offset_y
			button_points = [
				Geom::Point3d.new(29, y-1+@offset_y/2, 0),
				Geom::Point3d.new(71, y-1+@offset_y/2, 0),
				Geom::Point3d.new(71, y+16+@offset_y/2, 0),
				Geom::Point3d.new(29, y+16+@offset_y/2, 0)
      ]
			uvs = [ [0.1, 0.1, 0], [0.1, 0, 0], [0, 0.5, 0], [0, 0, 0] ]
			view.draw2d(GL_QUADS, button_points, texture: @dsp, uvs: uvs)
			view.draw_text(Geom::Point3d.new(50, y, 0), @line_osb_text, @center_black_text_options)
			view.draw2d(GL_LINE_LOOP, button_points)
			view.draw_text(Geom::Point3d.new(85, y, 0), @line_0_0_text, @line_gray_text_options)
			view.line_width = 2
			
			y += 30+@offset_y
			view.drawing_color = @edge2
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 2
				draw_active_edge_buttons(view,@line_0_4_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge2,2,@line_0_4_text,y-1,y+16)
      end
			
			y += 30+@offset_y
			view.drawing_color = @edge3
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 3
				draw_active_edge_buttons(view,@line_4_4_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge3,3,@line_4_4_text,y-1,y+16)
      end
			
			y += 30+@offset_y
			view.drawing_color = @edge4
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 4
				draw_active_edge_buttons(view,@line_1_0_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge4,4,@line_1_0_text,y-1,y+16)
      end
			
			y += 30+@offset_y
			view.drawing_color = @edge5
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 5
				draw_active_edge_buttons(view,@line_1_1_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge5,5,@line_1_1_text,y-1,y+16)
      end
			
			y += 30+@offset_y
			view.drawing_color = @edge6
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 6
				draw_active_edge_buttons(view,@line_2_0_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge6,6,@line_2_0_text,y-1,y+16)
      end
			
			y += 30+@offset_y
			view.drawing_color = @edge7
			view.draw2d(GL_QUADS, [ Geom::Point3d.new(30, y+@offset_y/2, 0), Geom::Point3d.new(70, y+@offset_y/2, 0), Geom::Point3d.new(70, y+15+@offset_y/2, 0), Geom::Point3d.new(30, y+15+@offset_y/2, 0) ])
			if @current_edge == 7
				draw_active_edge_buttons(view,@line_2_2_text,y-4,y+19)
				else
				draw_edge_buttons(view,@edge7,7,@line_2_2_text,y-1,y+16)
      end
			
			@napr_texture = false
			#current_os = :MAC
      #@size_x = (current_os == :MAC ? 20 : 20)
			if @sel.length == 0
				view.draw_text(Geom::Point3d.new(view.vpwidth / 2, 30, 0), SUF_STRINGS["Double click or drag to select objects."], @center_text_options)
				elsif @sel[0].is_a?(Sketchup::ComponentInstance)
				@line_width = 2
				view.drawing_color = color_of_edge(@edge_z2.to_s)
				view.line_width = @line_width
				view.draw2d(GL_LINES, [ Geom::Point3d.new(30, view.vpheight - 30, 0), Geom::Point3d.new(150+@size_x*2, view.vpheight - 30, 0) ])
				view.drawing_color = color_of_edge(@edge_z1.to_s)
				view.line_width = @line_width
				view.draw2d(GL_LINES, [ Geom::Point3d.new(30, view.vpheight - 90 - @size_x*2, 0), Geom::Point3d.new(150+@size_x*2, view.vpheight - 90 - @size_x*2, 0) ])
				view.drawing_color = color_of_edge(@edge_y2.to_s)
				view.line_width = @line_width
				view.draw2d(GL_LINES, [ Geom::Point3d.new(30, view.vpheight - 30, 0), Geom::Point3d.new(30, view.vpheight - 90 - @size_x*2, 0) ])
				view.drawing_color = color_of_edge(@edge_y1.to_s)
				view.line_width = @line_width
				view.draw2d(GL_LINES, [ Geom::Point3d.new(150+@size_x*2, view.vpheight - 30, 0), Geom::Point3d.new(150+@size_x*2, view.vpheight - 90 - @size_x*2, 0) ])
				
				entity = @sel.grep(Sketchup::ComponentInstance)[0]
				napr_texture = entity.definition.get_attribute("dynamic_attributes", "napr_texture")
				
				view.drawing_color = "black"
				if napr_texture
					if @screen_x < 145+@size_x*2 && @screen_x > 25 && @screen_y > view.vpheight - 100-@size_x*2 && @screen_y < view.vpheight - 35
						view.line_width = 2
						napr_texture.to_s == "1" ? @napr_texture = "2" : @napr_texture = "1"
						else
						view.line_width = 1
          end
					if napr_texture == "2"
						view.draw2d(GL_LINES, [ Geom::Point3d.new(60, view.vpheight - 50 - @size_x/2, 0), Geom::Point3d.new(60, view.vpheight - 70 - @size_x*1.5, 0), Geom::Point3d.new(120+@size_x*2, view.vpheight - 50 - @size_x/2, 0), Geom::Point3d.new(120+@size_x*2, view.vpheight - 70 - @size_x*1.5, 0) ])
						else
						view.draw2d(GL_LINES, [ Geom::Point3d.new(60, view.vpheight - 50 - @size_x/2, 0), Geom::Point3d.new(120+@size_x*2, view.vpheight - 50 - @size_x/2, 0), Geom::Point3d.new(60, view.vpheight - 70 - @size_x*1.5, 0), Geom::Point3d.new(120+@size_x*2, view.vpheight - 70 - @size_x*1.5, 0) ])
          end
					if @width && @height
						view.draw_text(Geom::Point3d.new(30, view.vpheight - (OSX ? 170 : 112), 0), @a03_name, @line_gray_text_options)
						view.draw_text(Geom::Point3d.new(90+@size_x, view.vpheight - 27, 0), (napr_texture == "2" ? @width.round.to_s : @height.round.to_s)+" x "+(napr_texture == "2" ? @height.round.to_s : @width.round.to_s), @center_text_options)
          end
        end
				
				#delete_edge
				@delete_edge = false
				view.drawing_color = @color_face
				button_text_color = "black"
				if @screen_x < view.vpwidth / 2 + 205+@size_x*2 && @screen_x > view.vpwidth / 2 + 80 && @screen_y > 20 && @screen_y < 50+@offset_y
					button_text_color = "white"
					view.drawing_color = "gray"
					@delete_edge = true
        end
				button_text_options = {
					color: button_text_color,
					font: 'Verdana',
					size: @text_size,
					align: TextAlignCenter
        }
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(view.vpwidth / 2 + 210+@size_x*2+@offset_x*2, 30, 0), Geom::Point3d.new(view.vpwidth / 2 + 210+@size_x*2+@offset_x*2, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth / 2 + 90+@offset_x*2, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth / 2 + 90+@offset_x*2, 30, 0) ])
				view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + 150+@size_x+@offset_x*2, 35, 0), SUF_STRINGS["Remove edge"], button_text_options)
				
				#visible_edge
				@visible_edge = false
				view.drawing_color = @color_face
				button_text_color = "black"
				if @screen_x > view.vpwidth/2 - 70 - @size_x && @screen_x < view.vpwidth/2 + 55 + @size_x && @screen_y > 20 && @screen_y < 50+@offset_y
					button_text_color = "white"
					view.drawing_color = "gray"
					@visible_edge = true
        end
				button_text_options = {
					color: button_text_color,
					font: 'Verdana',
					size: @text_size,
					align: TextAlignCenter
        }
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(view.vpwidth/2-60-@size_x, 30, 0), Geom::Point3d.new(view.vpwidth/2-60-@size_x, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth/2+60+@size_x, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth/2+60+@size_x, 30, 0) ])
				@current_edge_color ? view.drawing_color = @current_edge_color : view.drawing_color = "gray"
				view.line_width = 2
				view.draw2d(GL_LINES, [ Geom::Point3d.new(view.vpwidth/2-60-@size_x, 29, 0), Geom::Point3d.new(view.vpwidth/2 + 60+@size_x, 29, 0), Geom::Point3d.new(view.vpwidth/2-60-@size_x, 56+@size_y, 0), Geom::Point3d.new(view.vpwidth/2 + 60+@size_x, 56+@size_y, 0) ])
				view.draw_text(Geom::Point3d.new(view.vpwidth/2, 35, 0), SUF_STRINGS["Visible edges"], button_text_options)
				
				#around_edge
				@around_edge = false
				view.drawing_color = @color_face
				button_text_color = "black"
				if @screen_x > view.vpwidth/2-220-@size_x*2 && @screen_x < view.vpwidth/2-95 && @screen_y > 20 && @screen_y < 50+@offset_y
					button_text_color = "white"
					view.drawing_color = "gray"
					@around_edge = true
        end
				button_text_options = {
					color: button_text_color,
					font: 'Verdana',
					size: @text_size,
					align: TextAlignCenter
        }
				view.draw2d(GL_QUADS, [ Geom::Point3d.new(view.vpwidth/2-210-@size_x*2-@offset_x*2, 30, 0), Geom::Point3d.new(view.vpwidth/2-210-@size_x*2-@offset_x*2, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth/2-90-@offset_x*2, 55+@size_y, 0), Geom::Point3d.new(view.vpwidth/2-90-@offset_x*2, 30, 0) ])
				@current_edge_color ? view.drawing_color = @current_edge_color : view.drawing_color = "gray"
				view.line_width = 2
				view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(view.vpwidth/2-211-@size_x*2-@offset_x*2, 29, 0), Geom::Point3d.new(view.vpwidth/2-211-@size_x*2-@offset_x*2, 56+@size_y, 0), Geom::Point3d.new(view.vpwidth/2-89-@offset_x*2, 56+@size_y, 0), Geom::Point3d.new(view.vpwidth/2-89-@offset_x*2, 29, 0) ])
				view.draw_text(Geom::Point3d.new(view.vpwidth/2-150-@size_x-@offset_x*2, 35, 0), SUF_STRINGS["Edge around"], button_text_options)
				
				view.drawing_color = "gray"
				
				unless @line_0_text.nil?
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2, view.vpheight - 95, 0), @line_0_text, @center_text_options)
        end
				unless @line_2_text.nil?
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 580 : 350), view.vpheight - 60, 0), @line_2_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 326 : 187), view.vpheight - 60, 0), @line_tab_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 136 : 70), view.vpheight - 60, 0), @line_sep_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 110 : 58), view.vpheight - 60, 0), @line_x1_text, @line_red_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 20 : 8), view.vpheight - 60, 0), @line_x2_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 88 : 56), view.vpheight - 60, 0), @line_sep_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 114 : 70), view.vpheight - 60, 0), @line_y1_text, @line_green_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 200 : 120), view.vpheight - 60, 0), @line_y2_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 296 : 178), view.vpheight - 60, 0), @line_sep_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 322  : 192), view.vpheight - 60, 0), @line_z1_text, @line_blue_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 + (OSX ? 410 : 242), view.vpheight - 60, 0), @line_z2_text, @line_gray_text_options)
        end
				unless @line_3_text.nil?
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 580 : 356), view.vpheight - 30, 0), @line_3_text, @line_gray_text_options)
					view.draw_text(Geom::Point3d.new(view.vpwidth / 2 - (OSX ? 366 : 226), view.vpheight - 30, 0), @line_3_panel_text, @line_gray_text_options)
        end
				if @point_x_offset || @point_y_offset || @point_z_offset
					Sketchup::set_status_text "#{SUF_STRINGS["Thickness offset"]} ", SB_VCB_LABEL
        end
      end
			if dragging?
				view.line_stipple = drag_pick_inside ? "" : "_"
				view.draw2d(GL_LINE_LOOP, mouse_rectangle)
      end
    end
		def onSetCursor()
			if @onclick_action.to_s != ''
				UI.set_cursor(@cursor_active)
				elsif @is_over_entity == true
				UI.set_cursor(@cursor_noactions)
				else
				UI.set_cursor(@cursor_default)
      end
    end
		def onMouseMove(flags, x, y, view)
			@mouse_position = Geom::Point3d.new(x, y, 0)
			view.invalidate
			stop_last_timer()
			if !dragging?
				@screen_x = x
				@screen_y = y
				@onclick_action = nil
				@onclick_entity = nil
				@source_entity = nil
				@source_face = nil
				@source_edge = nil
				@su_click = false
				ph = view.pick_helper
				ph.do_pick x,y
				pick_list = ph.path_at(0)
				@is_over_entity = false
				@new_entity = nil
				@ip.pick view,x,y
				@ip_face = @ip.face
				if ph.picked_face
					face = ph.picked_face
					if ph.count == 2
						faces = []
						essense = nil
						ph.count.times { |pick_path_index|
							f = ph.path_at(pick_path_index)[-1]
							if f.is_a?(Sketchup::Face)
								f_parent = nil
								if f.parent.name.include?("Essence") || f.parent.get_attribute("dynamic_attributes", "_name") == "Essence"
									f_parent = f.parent
									elsif f.parent.instances[-1].parent.name.include?("Essence") || f.parent.instances[-1].parent.get_attribute("dynamic_attributes", "_name") == "Essence"
									f_parent = f.parent.instances[-1].parent
                end
								if f_parent
									if !essense
										faces << f
										essense = f_parent
										elsif essense != f_parent
										faces << f
                  end
                end
              end
            }
						if faces.count == 2
							faces.each { |f|
								index = ph.count.times.find { |i| ph.leaf_at(i) == f }
								transformation = index ? ph.transformation_at(index) : IDENTITY
								face = f if f.normal.transform(transformation).angle_between(Sketchup.active_model.active_view.camera.direction)<90.degrees
              }
            end
          end
					index = ph.count.times.find { |i| ph.leaf_at(i) == face }
					transformation = index ? ph.transformation_at(index) : IDENTITY
					projected_point = @ip.position.transform(transformation.inverse).project_to_plane( face.plane )
					@ip = Sketchup::InputPoint.new(projected_point.transform(transformation))
					@ip_face = face
        end
				tooltip_msg = ''
				if @ip.valid?
					if @ip_face
						f_parent = nil
						if @ip_face.parent.name.include?("Essence") || @ip_face.parent.get_attribute("dynamic_attributes", "_name") == "Essence"
							f_parent = @ip_face.parent
							elsif @ip_face.parent.instances[-1].parent.name.include?("Essence") || @ip_face.parent.instances[-1].parent.get_attribute("dynamic_attributes", "_name") == "Essence"
							f_parent = @ip_face.parent.instances[-1].parent
            end
						if f_parent
							comp = f_parent.instances[-1]
							if comp.parent.instances[-1].definition.name.include?("Body")
								panel = comp.parent.instances[-1].parent.instances[-1]
								else
								panel = comp.parent.instances[-1]
              end
							if !panel.deleted? && panel.layer.visible? && @panel_and_faces[panel]
								face_hash = @panel_and_faces[panel]
								edge_arr = face_hash[@ip_face]
								if edge_arr
									if !edge_arr[0].include?("edge")
										boundingbox = Geom::BoundingBox.new
										edge_arr[2].each { |point| boundingbox.add(point) }
										if boundingbox.contains?(@ip.position)
											@su_click = true
											@source_entity = panel
											@onclick_action = edge_arr[0]
											@source_face = @ip_face
											msg = Redraw_Components.translate("Click to activate.")
											Sketchup::set_status_text msg
											tooltip_msg = '   '+panel.definition.get_attribute("dynamic_attributes","a03_name")+" \n   " + texture_hint(edge_arr[1])
                    end
										else
										boundingbox = Geom::BoundingBox.new
										boundingbox.add(edge_arr[2])
										if boundingbox.contains?(@ip.position)
											@su_click = true
											@source_entity = panel
											@onclick_action = edge_arr[0]
											@source_edge = edge_arr[2]
											msg = Redraw_Components.translate("Click to activate.")
											Sketchup::set_status_text msg
											tooltip_msg = '   '+panel.definition.get_attribute("dynamic_attributes","a03_name")+" \n   " + edge_hint(edge_arr[0])
                    end
                  end
                end
              end
            end
          end
        end
				if pick_list && !@su_click
					@new_entity = pick_list[0] if pick_list[0].is_a?(Sketchup::ComponentInstance)
					for i in 0..pick_list.length-1
						entity = pick_list[i]
						@is_over_entity = true
						if entity.is_a?(Sketchup::ComponentInstance)
							@onclick_action = Redraw_Components.get_attribute_value(entity,'onclick')
							if @onclick_action == nil
								@onclick_action = Redraw_Components.get_attribute_value(entity,'su_click')
								if @onclick_action != nil
									@su_click = true 
									@onclick_name = 'su_click'
									else
									@su_click = false
									@onclick_name = 'onclick'
                end
              end
							if (@onclick_action != nil) && @onclick_action.downcase.include?('set(') && !@onclick_action.downcase.include?('animate')
								@onclick_entity = entity
								msg = Redraw_Components.translate("Click to activate.")
								Sketchup::set_status_text msg
								tooltip_msg = '   ' + click_hint(entity)
								break
								else
								@onclick_action = nil
								msg = Redraw_Components.translate("No click behaviors.")
								Sketchup::set_status_text msg
								tooltip_msg = ''
              end
            end
          end
					else
					Sketchup::set_status_text Redraw_Components.translate(@hover_message)
        end
				Sketchup.active_model.active_view.tooltip = tooltip_msg
      end
			view.invalidate
    end
		def texture_hint(texture)
			if texture.to_s=='2'
				msg = SUF_STRINGS["Texture direction"]
				else
				msg = SUF_STRINGS["Texture direction"]
      end
			return msg
    end
		def edge_hint(att)
			msg = ''
			if att=='edge_z1'
				msg = SUF_STRINGS["Edge length 1"]
				elsif att=='edge_z2'
				msg = SUF_STRINGS["Edge length 2"]
				elsif att=='edge_y1'
				msg = SUF_STRINGS["Edge width 1"]
				elsif att=='edge_y2'
				msg = SUF_STRINGS["Edge width 2"]
      end
			return msg
    end#def
		def click_hint(entity)
			if entity.definition.name.include?("edge_front")
				msg = SUF_STRINGS["Edge length 1"]
				elsif entity.definition.name.include?("edge_rear")
				msg = SUF_STRINGS["Edge length 2"]
				elsif entity.definition.name.include?("edge_up")
				msg = SUF_STRINGS["Edge width 1"]
				elsif entity.definition.name.include?("edge_down")
				msg = SUF_STRINGS["Edge width 2"]
				elsif entity.definition.name.include?("Texture")
				msg = SUF_STRINGS["Texture direction"]
				elsif @onclick_action.include?("cut_type")
				msg = SUF_STRINGS["Panel cutout"]
				elsif entity.definition.name.include?("item_open")
				msg = SUF_STRINGS["Opening direction"]
				elsif entity.definition.name.include?("item_vitr")
				msg = SUF_STRINGS["Showcase/grilles"]
				elsif entity.definition.name.include?("item_1") || entity.definition.name.include?("item_2") || entity.definition.name.include?("item_3")
				msg = SUF_STRINGS["Handle position"]
				elsif entity.definition.name.include?("item_4")
				msg = SUF_STRINGS["Reduce the length of the handle"]
				elsif entity.definition.name.include?("item_5")
				msg = SUF_STRINGS["Turn the handle"]
				elsif entity.definition.name.include?("item_6")
				msg = SUF_STRINGS["Increase the length of the handle"]
				else
				if @onclick_action.include?("ANIMATECUSTOM")
					msg = SUF_STRINGS["Open"]
					else
					msg = entity.definition.get_attribute("dynamic_attributes", "_"+@onclick_name+"_formlabel", Redraw_Components.translate("Click to activate."))
        end
      end
			return msg
    end#def
		def onLButtonDoubleClick(flags, x, y, view)
			@double_click = true
			if @new_entity
				if !@control_press && !@shift_press
					@sel.clear
					@sel.add @new_entity
					elsif @shift_press == true
					if @sel.length > 1 && @sel.include?(@new_entity)
						@sel.remove @new_entity
						else
						@sel.add @new_entity
          end
					elsif @control_press == true
					@sel.add @new_entity
        end
				activate
				else
				@sel.clear
      end
			UI.start_timer(0.9, false) { @double_click = false }
    end
		def set_edge(entity,attribute,edge)
			entity.set_attribute("dynamic_attributes", attribute, edge)
			entity.definition.set_attribute("dynamic_attributes", attribute, edge)
			entity.definition.delete_attribute("dynamic_attributes", "_"+attribute+"_formula")
    end
		def delete_edge(entity)
			if entity.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
				set_edge(entity,"edge_y1", "1")
				set_edge(entity,"edge_y2", "1")
				set_edge(entity,"edge_z1", "1")
				set_edge(entity,"edge_z2", "1")
				@entities_for_redraw << entity
				elsif entity.definition.get_attribute("dynamic_attributes", "edge_y1")
				set_edge(entity,"edge_y1", "0")
				set_edge(entity,"edge_y2", "0")
				set_edge(entity,"edge_z1", "0")
				set_edge(entity,"edge_z2", "0")
				@entities_for_redraw << entity
				face_layer(entity)
				else
				entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| delete_edge(e) }
      end
    end#def
		def panel_thickness(entity)
			lenx = entity.definition.get_attribute("dynamic_attributes", "lenx", 0).to_f
			leny = entity.definition.get_attribute("dynamic_attributes", "leny", 0).to_f
			lenz = entity.definition.get_attribute("dynamic_attributes", "lenz", 0).to_f
			thickness = (([lenx,leny,lenz].sort[0]*25.4)+0.1).floor
    end
		def edge_around(entity)
      if panel_thickness(entity) > 7
        if entity.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
          set_edge(entity,"edge_y1", @current_edge)
          set_edge(entity,"edge_y2", @current_edge)
          set_edge(entity,"edge_z1", @current_edge)
          set_edge(entity,"edge_z2", @current_edge)
          su_info = entity.definition.get_attribute("dynamic_attributes", "_su_info_formula")
          if su_info && su_info.include?("su_quantity")
            su_info_new = su_info.split("su_quantity")[0]+'su_quantity'+'&"/"&su_unit&"/"&CHOOSE(edge_z1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_z2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z2_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y2_texture,a06_mat_panel,a07_mat_krom)&"/"&groove&"/"&groove_thick&"/"&groove_width&"/"&groove_xy_pos&"/"&groove_z_pos)'
            entity.definition.set_attribute("dynamic_attributes", "_su_info_formula", su_info_new)
            entity.definition.set_attribute("dynamic_attributes", "_edge_y1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
            entity.definition.set_attribute("dynamic_attributes", "_edge_y2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
            entity.definition.set_attribute("dynamic_attributes", "_edge_z1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
            entity.definition.set_attribute("dynamic_attributes", "_edge_z2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
          end
          @entities_for_redraw << entity
          face_layer(entity)
          elsif entity.definition.get_attribute("dynamic_attributes", "edge_y1")
          edge_value = old_edge(@current_edge)
          set_edge(entity,"edge_y1_length",(edge_value=="0" ? "0" : "1"))
          set_edge(entity,"edge_y2_length",(edge_value=="0" ? "0" : "1"))
          set_edge(entity,"edge_z1_length",(edge_value=="0" ? "0" : "1"))
          set_edge(entity,"edge_z2_length",(edge_value=="0" ? "0" : "1"))
          set_edge(entity,"edge_y1", edge_value)
          set_edge(entity,"edge_y2", edge_value)
          set_edge(entity,"edge_z1", edge_value)
          set_edge(entity,"edge_z2", edge_value)
        end
      end
      entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| edge_around(e) }
    end#def
		def ask_for_touch_component(pow1,pow2,pow3,pow4,instance)
			@touch_face=nil
			ents = Sketchup.active_model.active_entities.grep(Sketchup::ComponentInstance).to_a.select { |entity| entity.bounds.contains?(pow1) && entity.bounds.contains?(pow2) && entity.bounds.contains?(pow3) && entity.bounds.contains?(pow4) && !instance.definition.instances.index(entity) }
			ents.grep(Sketchup::ComponentInstance).each { |comp| search_touch_comp(comp,pow1,pow2,pow3,pow4,instance,comp.transformation) }
			return @touch_face
    end#def
		def search_touch_comp(comp,pow1,pow2,pow3,pow4,instance,tr)
			touch_face=nil
			if !comp.hidden?
				if @frontal_with_edge == "yes" && comp.definition.get_attribute("dynamic_attributes", "su_type", "0") == "frontal" && comp.definition.get_attribute("dynamic_attributes", "trim_z1").to_f > 0 && comp.definition.get_attribute("dynamic_attributes", "trim_z2").to_f > 0
					elsif @back_with_edge == "yes" && comp.definition.get_attribute("dynamic_attributes", "su_type", "0") == "back"
					else
					comp.definition.entities.grep(Sketchup::ComponentInstance).each { |essence|
						if essence.definition.name.include?("Essence") || essence.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
							essence.make_unique
              essence.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if essence.parent.is_a?(Sketchup::ComponentDefinition)
							tr*=essence.transformation
							psc1=pow1.transform(tr.inverse)
              psc2=pow2.transform(tr.inverse)
              psc3=pow3.transform(tr.inverse)
              psc4=pow4.transform(tr.inverse)
              fc=is_pt_touching_s(essence,psc1,psc2,psc3,psc4)
              if fc
                if !@frontal_with_edge && comp.definition.get_attribute("dynamic_attributes", "su_type", "0") == "frontal" && comp.definition.get_attribute("dynamic_attributes", "trim_z1").to_f > 0 && comp.definition.get_attribute("dynamic_attributes", "trim_z2").to_f > 0
                  input = UI.inputbox ["#{SUF_STRINGS["Edge needed behind the front"]}? ","#{SUF_STRINGS["Change front edges"]}? "], [SUF_STRINGS["Yes"],SUF_STRINGS["No"]], ["#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["No"]}","#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["No"]}"], SUF_STRINGS["Edging parameters"]
                  if input[0] == SUF_STRINGS["Yes"]
                    @frontal_with_edge = "yes"
                    else
                    @frontal_with_edge = "no"
                    touch_face=fc
                  end
                  @frontal_change_edge = true if input[1] == SUF_STRINGS["Yes"]
                  elsif comp.definition.get_attribute("dynamic_attributes", "su_type", "0") == "back" && !@back_with_edge
                  result = UI.messagebox("#{SUF_STRINGS["Edge needed on sides adjoining the back panel?"]}", MB_YESNO)
                  if result == IDYES
                    @back_with_edge = "yes"
                    else
                    @back_with_edge = "no"
                    touch_face=fc
                  end
                  else
                  touch_face=fc
                end
              end
            end
          }
					if touch_face
						@touch_face = touch_face
						else
						comp.make_unique if comp.definition.count_instances > 1
            comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
						comp.definition.entities.grep(Sketchup::ComponentInstance).each { |e| search_touch_comp(e,pow1,pow2,pow3,pow4,instance,tr*e.transformation) }
          end
        end
      end
    end#def
		def is_pt_touching_s(essence,pt1,pt2,pt3,pt4)
			fc=nil
			essence.definition.entities.grep(Sketchup::Face).each { |f|
				if f.classify_point(pt3) == Sketchup::Face::PointInside && f.classify_point(pt4) == Sketchup::Face::PointInside || f.classify_point(pt3) == Sketchup::Face::PointInside && f.classify_point(pt4) == Sketchup::Face::PointOnEdge || f.classify_point(pt4) == Sketchup::Face::PointInside && f.classify_point(pt3) == Sketchup::Face::PointOnEdge || f.classify_point(pt3) == Sketchup::Face::PointOnEdge && f.classify_point(pt4) == Sketchup::Face::PointOnEdge
					if f.classify_point(pt1) == Sketchup::Face::PointInside && f.classify_point(pt2) == Sketchup::Face::PointInside || f.classify_point(pt1) == Sketchup::Face::PointInside && f.classify_point(pt2) == Sketchup::Face::PointOnEdge || f.classify_point(pt2) == Sketchup::Face::PointInside && f.classify_point(pt1) == Sketchup::Face::PointOnEdge
						fc=f
          end
        end
      }
			return fc
    end#def
		def visible_edge(entity,tr)
			entity.make_unique
      entity.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if entity.parent.is_a?(Sketchup::ComponentDefinition)
			if entity.definition.get_attribute("dynamic_attributes", "edge_y1_texture") && panel_thickness(entity) > 9
				if !entity.hidden?
					if entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "frontal" && entity.definition.get_attribute("dynamic_attributes", "trim_z1").to_f > 0 && entity.definition.get_attribute("dynamic_attributes", "trim_z2").to_f > 0
						if !@frontal_with_edge
							input = UI.inputbox ["#{SUF_STRINGS["Edge needed behind the front"]}? ","#{SUF_STRINGS["Change front edges"]}? "], [SUF_STRINGS["Yes"],SUF_STRINGS["No"]], ["#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["No"]}","#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["No"]}"], SUF_STRINGS["Edging parameters"]
              if input[0] == SUF_STRINGS["Yes"]
								@frontal_with_edge = "yes"
								else
								@frontal_with_edge = "no"
              end
							@frontal_change_edge = true if input[1] == SUF_STRINGS["Yes"]
            end
						else
						set_edge(entity,"edge_y1", "1")
						set_edge(entity,"edge_y2", "1")
						set_edge(entity,"edge_z1", "1")
						set_edge(entity,"edge_z2", "1")
          end
					entity.definition.entities.grep(Sketchup::ComponentInstance).each { |essence|
						if essence.definition.name.include?("Essence") || essence.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
							change_edge(entity,essence,tr)
							elsif essence.definition.name.include?("Body")
							essence.definition.entities.grep(Sketchup::ComponentInstance).each { |ess| change_edge(entity,ess,tr) if ess.definition.name.include?("Essence") || ess.definition.get_attribute("dynamic_attributes", "_name") == "Essence"} if @frontal_change_edge == true
            end
          }
					@entities_for_redraw << entity
					face_layer(entity)
        end
				else
				entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| visible_edge(e,tr*e.transformation) }
      end
    end#def
		def change_edge(entity,essence,comp_transformation)
			@entities_for_redraw << essence
			essence.make_unique
      essence.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if essence.parent.is_a?(Sketchup::ComponentDefinition)
			comp_transformation *= essence.transformation
			lenx = essence.definition.get_attribute("dynamic_attributes", "lenx")
			essence.definition.entities.grep(Sketchup::Face).each { |face|
				face_type = face.get_attribute("dynamic_attributes", "face")
				if face_type == "up" || face_type == "down" || face_type == "front" || face_type == "rear"
					pow1 = nil
					pow2 = nil
					pow3 = nil
					pow4 = nil
					face.edges.each { |edge|
						if edge.length != lenx
							if !pow1
								pow1 = Geom::Point3d.new((edge.start.position.x+edge.end.position.x)/2.0, (edge.start.position.y+edge.end.position.y)/2.0, (edge.start.position.z+edge.end.position.z)/2.0)
								elsif !pow2
								pow2 = Geom::Point3d.new((edge.start.position.x+edge.end.position.x)/2.0, (edge.start.position.y+edge.end.position.y)/2.0, (edge.start.position.z+edge.end.position.z)/2.0)
              end
							else
							if !pow3
								pow3 = Geom::Point3d.new((edge.start.position.x+edge.end.position.x)/2.0, (edge.start.position.y+edge.end.position.y)/2.0, (edge.start.position.z+edge.end.position.z)/2.0)
								elsif !pow4
								pow4 = Geom::Point3d.new((edge.start.position.x+edge.end.position.x)/2.0, (edge.start.position.y+edge.end.position.y)/2.0, (edge.start.position.z+edge.end.position.z)/2.0)
              end
            end
          }
          next if !pow1 || !pow2 || !pow3 || !pow4
					pt1=pow1.transform(comp_transformation)
					pt2=pow2.transform(comp_transformation)
					pt3=pow3.transform(comp_transformation)
					pt4=pow4.transform(comp_transformation)
					#edges = Sketchup.active_model.active_entities.add_edges Geom::Point3d.new(0,0,0), pt1
						#edges = Sketchup.active_model.active_entities.add_edges Geom::Point3d.new(0,0,0), pt2
						#edges = Sketchup.active_model.active_entities.add_edges Geom::Point3d.new(0,0,0), pt3
          #edges = Sketchup.active_model.active_entities.add_edges Geom::Point3d.new(0,0,0), pt4
					touch_face = ask_for_touch_component(pt1,pt2,pt3,pt4,entity)
					#@sel.add touch_face if touch_face
					if @frontal_change_edge == false && entity.definition.get_attribute("dynamic_attributes", "su_type", "0") == "frontal" && entity.definition.get_attribute("dynamic_attributes", "trim_z1").to_f > 0 && entity.definition.get_attribute("dynamic_attributes", "trim_z1").to_f < 0.16 && entity.definition.get_attribute("dynamic_attributes", "trim_z2").to_f > 0 && entity.definition.get_attribute("dynamic_attributes", "trim_z2").to_f < 0.16
						
						else
						if !touch_face
							if face_type == "up"
								set_edge(entity,"edge_y1", @current_edge)
								elsif face_type == "down"
								set_edge(entity,"edge_y2", @current_edge)
								elsif face_type == "front"
								set_edge(entity,"edge_z1", @current_edge)
								elsif face_type == "rear"
								set_edge(entity,"edge_z2", @current_edge)
              end
							su_info = entity.definition.get_attribute("dynamic_attributes", "_su_info_formula")
							if su_info && su_info.include?("su_quantity")
								su_info_new = su_info.split("su_quantity")[0]+'su_quantity'+'&"/"&su_unit&"/"&CHOOSE(edge_z1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_z2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z2_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y2_texture,a06_mat_panel,a07_mat_krom)&"/"&groove&"/"&groove_thick&"/"&groove_width&"/"&groove_xy_pos&"/"&groove_z_pos)'
								entity.definition.set_attribute("dynamic_attributes", "_su_info_formula", su_info_new)
								entity.definition.set_attribute("dynamic_attributes", "_edge_y1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
								entity.definition.set_attribute("dynamic_attributes", "_edge_y2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
								entity.definition.set_attribute("dynamic_attributes", "_edge_z1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
								entity.definition.set_attribute("dynamic_attributes", "_edge_z2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
              end
            end
          end
        end
      }
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
				activate
				
				elsif @select_edge != 0
				@current_edge = @select_edge
				@current_edge_color = @edge_color
				view.invalidate
				draw(view)
				elsif @hide_face_button == true
				@hide_face == "yes" ? @hide_face = "no" : @hide_face = "yes"
				@content.each_with_index { |i,index|
					if i.strip.split("=")[1] == "hide_face"
						@content[index] = i.split("=")[0]+"="+i.split("=")[1]+"="+@hide_face+"="+i.split("=")[3]+"="+i.split("=")[4].strip
          end
        }
				param_file = File.new(@path_param,"w")
				@content.each{|i| param_file.puts i }
				param_file.close
				Sketchup.active_model.set_attribute('su_parameters', "hide_face", @hide_face)
				@model.start_operation "layers", true, false, true
				@model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") }
				@model.layers.each { |l| l.visible = false if l.name.include?("Z_Face") } if @hide_face == "yes"
				@model.commit_operation
				view.invalidate
				draw(view)
				
				elsif @napr_texture
				if @sel.length == 1 
					if @point_x_offset || @point_y_offset || @point_z_offset
						@model.start_operation "Napr texture", true
						entity = @sel.grep(Sketchup::ComponentInstance)[0]
						entity.set_attribute("dynamic_attributes", "a05_napr", @napr_texture)
						entity.definition.set_attribute("dynamic_attributes", "a05_napr", @napr_texture)
						DCProgressBar::clear()
						Redraw_Components.redraw(entity,true)
						DCProgressBar::clear()
						$dlg_att.execute_script("add_comp()") if $dlg_att
						$dlg_suf.execute_script("add_comp()") if $attobserver == 2
						$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
						view.invalidate
						activate
						@model.commit_operation
          end
        end
				
				elsif @delete_edge == true
				@model.start_operation "Delete edge", true
				@entities_for_redraw = []
				@sel.grep(Sketchup::ComponentInstance).each { |entity| delete_edge(entity) }
				DCProgressBar::clear()
				@entities_for_redraw.each {|entity|
					Redraw_Components.run_all_formulas(entity)
        }
				DCProgressBar::clear()
				$dlg_att.execute_script("add_comp()") if $dlg_att
				$dlg_suf.execute_script("add_comp()") if $attobserver == 2
				$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
				@panel_and_faces = {}
				@panel_and_essence = {}
				@panel_and_tr = {}
				activate
				view.invalidate
				@model.commit_operation
				@delete_edge = false
				
				elsif @around_edge == true
				if @current_edge == 0
					UI.messagebox(SUF_STRINGS["Select edge from list"])
					return
        end
				@model.start_operation "Edge around", true
				@entities_for_redraw = []
				@sel.grep(Sketchup::ComponentInstance).each { |entity| edge_around(entity) }
				DCProgressBar::clear()
				@entities_for_redraw.each {|entity|
					Redraw_Components.run_all_formulas(entity)
        }
				DCProgressBar::clear()
				$dlg_att.execute_script("add_comp()") if $dlg_att
				$dlg_suf.execute_script("add_comp()") if $attobserver == 2
				$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
				@panel_and_faces = {}
				@panel_and_essence = {}
				@panel_and_tr = {}
				activate
				view.invalidate
				onMouseMove(flags, x, y, view)
				@model.commit_operation
				@around_edge = false
				
				elsif @visible_edge == true
				if @current_edge == 0
					UI.messagebox(SUF_STRINGS["Select edge from list"])
					return
        end
				@model.start_operation "Visible edge", true
				@back_with_edge=nil
				@frontal_with_edge=nil
				@frontal_change_edge = false
				@entities_for_redraw = []
				@sel.grep(Sketchup::ComponentInstance).each { |entity| visible_edge(entity,entity.transformation) }
				DCProgressBar::clear()
				@entities_for_redraw.each {|entity|
					Redraw_Components.run_all_formulas(entity)
        }
				DCProgressBar::clear()
				$dlg_att.execute_script("add_comp()") if $dlg_att
				$dlg_suf.execute_script("add_comp()") if $attobserver == 2
				$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
				@panel_and_faces = {}
				@panel_and_essence = {}
				@panel_and_tr = {}
				activate
				view.invalidate
				onMouseMove(flags, x, y, view)
				@model.commit_operation
				@visible_edge = false
				
				elsif @source_entity && @su_click
				entity = @source_entity
				if @onclick_action.include?("edge")
					if @current_edge == 0
						UI.messagebox(SUF_STRINGS["Select edge from list"])
						else
						@model.start_operation "New edge", true
						edge_value = @current_edge
						if entity.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
							edge_value = "1" if edge_value == entity.definition.get_attribute("dynamic_attributes", @onclick_action)
							else
							edge_value = "1" if old_edge(edge_value) == entity.definition.get_attribute("dynamic_attributes", @onclick_action)
            end
						new_edge_value = {}
						@panel_and_faces[entity].each_pair {|face,edge_arr|
							if @onclick_action == edge_arr[0]
								edge_arr[1] = edge_value
              end
							new_edge_value[face] = edge_arr
            }
						@panel_and_faces[entity] = new_edge_value
						if !entity.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
							edge_value = old_edge(edge_value)
							set_edge(entity,@onclick_action+"_length",(edge_value=="0" ? "0" : "1"))
							else
							set_edge(entity,@onclick_action+"_length",(edge_value=="1" ? "0" : "1"))
            end
						set_edge(entity,@onclick_action,edge_value)
						DCProgressBar::clear()
						Redraw_Components.run_all_formulas(entity)
						DCProgressBar::clear()
						view.invalidate
						@model.commit_operation
          end
					else
					@model.start_operation "Texture orientation", true
					entity.definition.get_attribute("dynamic_attributes", @onclick_action, "1") == "2" ? napr_texture = "1" : napr_texture = "2"
					entity.definition.set_attribute("dynamic_attributes", @onclick_action, napr_texture)
					entity.set_attribute("dynamic_attributes", @onclick_action, napr_texture)
					DCProgressBar::clear()
					Redraw_Components.redraw(entity,true)
					DCProgressBar::clear()
					@panel_and_faces[entity] = all_faces(@panel_and_essence[entity],entity,@panel_and_tr[entity])
					view.invalidate
					@model.commit_operation
        end
				
				elsif @onclick_entity
				@onclick_action = @onclick_action.to_s
				if @onclick_action == ''
					@sel.clear
					return
        end
				entity = @onclick_entity
				if @onclick_action.downcase.include?('set(') && @is_animating == false
					@model.start_operation "Interact", true
					@is_animating = true
        end
				escaped_action = @onclick_action.gsub(/\"([^\"]+)?\"/) {|match|
					quoted_string = Redraw_Components.second_if_empty($1,'')
					'"' + Redraw_Components.escape(quoted_string,false) + '"'
        }
				commands = escaped_action.split(';');
				command_count = 0
				for command in commands
					if command.to_s == ''
						next
						elsif command.index(/\w/) == nil
						next
          end
					command_count = command_count + 1
					first_parens = command.index('(')
					last_parens = command.rindex(')')
					if first_parens == nil || last_parens == nil
						UI.messagebox(Redraw_Components.translate('ERROR: Unmatched parenthesis in ') + 
            command)
						return
          end
					function = command[0..first_parens-1].strip.downcase
					param_string = command[first_parens+1..last_parens-1]
					param_string = escape_commas_in_parens(param_string)
					params = param_string.split(',')
					for i in 0..params.length-1 
						params[i] = params[i].gsub(/\+/,'%2B')
						params[i] = Redraw_Components.unescape(params[i])
          end
					if function == 'set'
						reference_string = params.shift
						reference,error = Redraw_Components.parse_formula(reference_string,entity)
						if error.to_s.include? 'subformula-error' || reference == nil ||
							reference == ''
							UI.messagebox(Redraw_Components.translate('ERROR: Invalid entity to animate: ') +
              ' (' + reference_string + ')')
							return
            end
						if @conv.reserved_attribute_group[reference_string.downcase] == 'STRING'
							reference = reference_string.downcase
							elsif reference == nil || reference == '' ||
							reference.to_s =~ /^\d+\.*\d*$/
							reference = reference_string.downcase
            end
						if reference == nil || reference == ''
							return
            end
						value_list = params
						if value_list.length < 1
							return
            end
						value_list = parse_as_formulas(value_list, entity, reference)
						entity_array,attribute = parse_command_reference(reference)
						if entity_array == nil
							UI.messagebox(Redraw_Components.translate('ERROR: Invalid entity to animate: ') + ' (' + reference + ')')
							return
            end
						for entity in entity_array
							current_value = Redraw_Components.get_attribute_value(entity,attribute)
							last_list_index = Redraw_Components.get_attribute_value(entity, '_' + @onclick_name + '_state' + command_count.to_s)
							next_value, next_index = next_value_from(value_list, current_value, last_list_index)
							if @shift_press == true
								Redraw_Components.set_attribute(entity, '_' + @onclick_name + '_state' + command_count.to_s,  0)
								Redraw_Components.set_attribute(entity, attribute, value_list[0])
								elsif @current_edge != 0 && @onclick_action.include?("edge")
								if current_value == @current_edge
									index = 0
									value = 1
									else
									case @current_edge
										when 2 then index = 1
										when 3 then index = 1
										when 4 then index = 2
										when 5 then index = 2
										when 6 then index = 3
										when 7 then index = 4
                  end
									value = @current_edge
                end
								Redraw_Components.set_attribute(entity, '_' + @onclick_name + '_state' + command_count.to_s,  index)
								Redraw_Components.set_attribute(entity, attribute, value)
								su_info = Redraw_Components.get_attribute_value(entity,"_su_info_formula")
								if su_info && su_info.include?("su_quantity")
									su_info_new = su_info.split("su_quantity")[0]+'su_quantity'+'&"/"&su_unit&"/"&CHOOSE(edge_z1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_z2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_z2_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y1,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y1_texture,a06_mat_panel,a07_mat_krom)&"/"&CHOOSE(edge_y2,0,'+@edge_thickness[1]+','+@edge_thickness[2]+','+@edge_thickness[3]+','+@edge_thickness[4]+','+@edge_thickness[5]+','+@edge_thickness[6]+')&"/"&CHOOSE(edge_y2_texture,a06_mat_panel,a07_mat_krom)&"/"&groove&"/"&groove_thick&"/"&groove_width&"/"&groove_xy_pos&"/"&groove_z_pos)'
									entity.definition.set_attribute("dynamic_attributes", "_su_info_formula", su_info_new)
									entity.definition.set_attribute("dynamic_attributes", "_edge_y1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
									entity.definition.set_attribute("dynamic_attributes", "_edge_y2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
									entity.definition.set_attribute("dynamic_attributes", "_edge_z1_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
									entity.definition.set_attribute("dynamic_attributes", "_edge_z2_options", '&0=1&'+@edge_width[1]+'=2&'+@edge_width[2]+'=3&'+@edge_width[3]+'=4&'+@edge_width[4]+'=5&'+@edge_width[5]+'=6&'+@edge_width[6]+'=7&')
                end
								else
								Redraw_Components.set_attribute(entity, '_' + @onclick_name + '_state' + command_count.to_s,  next_index)
								Redraw_Components.set_attribute(entity, attribute, next_value)
              end
							Redraw_Components.update_last_sizes(entity)
							Redraw_Components.set_attribute_formula(entity, attribute, nil)
							Redraw_Components.clear_instance_cache(entity, false)
							@model.active_view.invalidate
							Redraw_Components.redraw_with_Progress_Bar([entity])
							face_layer(entity)
							onMouseMove(flags, x, y, view)
							if @sel.length == 1 
								if @point_x_offset || @point_y_offset || @point_z_offset
									@edge_z2 = @ent_def.get_attribute("dynamic_attributes", "edge_z2", "0")
									@edge_z1 = @ent_def.get_attribute("dynamic_attributes", "edge_z1", "0")
									@edge_y1 = @ent_def.get_attribute("dynamic_attributes", "edge_y1", "0")
									@edge_y2 = @ent_def.get_attribute("dynamic_attributes", "edge_y2", "0")
                end
              end
							draw(view)
            end
						$dlg_att.execute_script("add_comp()") if $dlg_att
						$dlg_suf.execute_script("add_comp()") if $attobserver == 2
						$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
          end
        end
				activate
				if @is_animating == true
					@is_animating = false
					@model.commit_operation
        end
				UI.set_cursor(@cursor_default)
      end
			@mouse_down = nil
    end
		def face_layer(unit)
			if unit.definition.name.include?("Essence") || unit.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
				unit.definition.entities.grep(Sketchup::Face).each { |f|
					face = f.get_attribute("dynamic_attributes", "face", "0")
					f.layer = "Z_Face" if face.include?("primary")
        }
      end
			unit.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| face_layer(entity) } 
    end#def
		def escape_commas_in_parens(formula)
			opening_parens_count = 0
			escaped_formula = ''
			for i in 0..(formula.length-1)
				char = formula[i..i]
				if opening_parens_count > 0 && char == ','
					escaped_formula = escaped_formula + '%2C'
					else
					escaped_formula = escaped_formula + char
        end
				if char == '('
					opening_parens_count = opening_parens_count + 1
					elsif char == ')'
					opening_parens_count = opening_parens_count - 1
        end
      end
			return escaped_formula
    end
		def parse_as_formulas(params, entity, attribute)
			for i in 0..params.length-1
				formula = params[i]
				params[i],error = Redraw_Components.parse_formula(formula, entity, attribute)
				if error.to_s.include? 'subformula-error'
					UI.messagebox(Redraw_Components.translate('ERROR: could not parse formula: ') +
          formula.to_s)
        end
      end
			return params
    end
		def parse_command_reference(reference)
			source_entity = @onclick_entity
			if reference.to_s.index('!')
				sheet_name = reference[0..reference.index('!')-1]
				attribute_name = reference[reference.index('!')+1..999]
				entity = find_entity_by_sheet_name(source_entity,sheet_name)
				return entity,attribute_name
				else
				attribute_name = reference
				entity = find_entity_by_attribute(source_entity,attribute_name)
				return entity,reference
      end
    end
		def find_entity_by_attribute(source_entity,attribute_name)
			if Redraw_Components.get_attribute_value(source_entity,attribute_name)
				return [source_entity]
      end
			if source_entity && source_entity.parent
				if !source_entity.parent.to_s.index('Sketchup::Model')
					if source_entity.parent.is_a?(Sketchup::ComponentDefinition)
						find_entity_by_attribute(source_entity.parent.instances[-1],attribute_name)
						else
						return nil
          end
        end
      end
    end
		def find_entity_by_sheet_name(source_entity,sheet_name)
			subentity_array = []
			sheet_name = sheet_name.downcase
			if Redraw_Components.name_of_entity_is(source_entity,sheet_name)
				return [source_entity]
      end
			if source_entity.parent
				if !source_entity.parent.to_s.index('Sketchup::Model')
					if source_entity.parent.is_a?(Sketchup::ComponentDefinition)
						parent_entity = source_entity.parent.instances[0]
						if sheet_name.downcase == "parent"
							return [parent_entity]
							elsif Redraw_Components.name_of_entity_is(parent_entity,sheet_name,'parent')
							return [parent_entity]
							else
							if parent_entity.parent.is_a?(Sketchup::ComponentDefinition)
								for subentity in parent_entity.parent.entities
									if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)
										if Redraw_Components.name_of_entity_is(subentity,sheet_name,'parent')
											return [subentity]
                    end
                  end
                end
              end
            end
          end
        end
				if source_entity.is_a?(Sketchup::ComponentInstance)
					for subentity in source_entity.definition.entities
						if subentity.is_a?(Sketchup::ComponentInstance) ||
							subentity.is_a?(Sketchup::Group)
							if Redraw_Components.name_of_entity_is(subentity,sheet_name,'children')
								subentity_array.push(subentity)
              end
            end
          end
        end
				for subentity in source_entity.parent.entities
					if subentity.is_a?(Sketchup::ComponentInstance) || subentity.is_a?(Sketchup::Group)
						if Redraw_Components.name_of_entity_is(subentity,sheet_name,'sibs')
							subentity_array.push(subentity)
            end
          end
        end
      end
			if subentity_array != nil
				return subentity_array
				else
				return nil
      end
    end
		def next_value_from(params, current_value, current_index=0)
			if current_value == nil || current_value == ''
				return params[0], 0
      end
			current_index = current_index.to_i
			found_index = nil
			last_matched_index = nil
			for i in 0..params.length-1
				value = params[i]
				if current_value.to_s == value.to_s
					if i < current_index
						last_matched_index = i
						else
						found_index = i
						break
          end
        end
      end
			if found_index == nil
				for i in 0..params.length-1
					value = params[i]
					if (current_value.to_f - value.to_f).abs < 0.001
						if i < current_index
							last_matched_index = i
							else
							found_index = i
							break
            end
          end
        end
      end
			if found_index == nil
				found_index = last_matched_index
      end
			if found_index==nil
				next_index = 0
				else
				next_index = found_index + 1
				if next_index == params.length
					next_index = 0
        end
      end
			next_value = params[next_index]
			return next_value, next_index
    end
		def stop_last_timer
			if @timer != nil
				UI.stop_timer @timer
				@timer = nil
      end
    end
		def onKeyDown(key, repeat, flags, view)
			if key==VK_SHIFT 
				@shift_press=true
				elsif key==VK_CONTROL || key==VK_COMMAND
				@control_press=true
				elsif key==VK_ALT
				@alt_press=true
      end
    end
		def onKeyUp(key, repeat, flags, view)
			#puts "onKeyDown: key = #{key}"
			if @ent_def && !@ent_def.deleted?
				@point_x = @ent_def.get_attribute("dynamic_attributes", "point_x").to_i
				@point_y = @ent_def.get_attribute("dynamic_attributes", "point_y").to_i
				@point_z = @ent_def.get_attribute("dynamic_attributes", "point_z").to_i
				if key==VK_SHIFT
					UI.start_timer(0.1, false) { @shift_press=false }
					view.lock_inference if view.inference_locked?
					elsif key==VK_CONTROL || key==VK_COMMAND
					@control_press=false
					view.lock_inference if view.inference_locked?
					elsif key==VK_ALT
					@alt_press=false
					view.lock_inference if view.inference_locked?
					elsif ( key==9 || ((key==15 || key==48) && (RUBY_PLATFORM.include?('darwin'))))
					if @point_y_offset
						change_point(@sel[0],"point_y",3)
						elsif @point_x_offset
						change_point(@sel[0],"point_x",3)
						elsif @point_z_offset
						change_point(@sel[0],"point_z",3)
          end
					elsif key==VK_LEFT && @control_press != true && @alt_press != true
					if @shift_press == true
						if @point_x_offset || @point_y_offset
							change_trim(@sel[0],"trim_z1",@len)
							elsif @point_z_offset
							change_trim(@sel[0],"trim_y2",@len)
							elsif @trim_x1 || @trim_x2
							change_trim(@sel[0],"trim_x1",@len)
            end
						else
						if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
							change_point(@sel[0],"point_y",3)
            end
          end
					elsif key==VK_RIGHT && @control_press != true && @alt_press != true
					if @shift_press == true
						if @point_x_offset || @point_y_offset
							change_trim(@sel[0],"trim_z2",@len)
							elsif @point_z_offset
							change_trim(@sel[0],"trim_y1",@len)
							elsif @trim_x1 || @trim_x2
							change_trim(@sel[0],"trim_x2",@len)
            end
						else
						if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
							change_point(@sel[0],"point_x",3)
            end
          end
					elsif key==VK_UP && @control_press != true && @alt_press != true
					if @shift_press == true
						if @point_x_offset || @point_y_offset
							change_trim(@sel[0],"trim_y1",@len)
							elsif @point_z_offset
							change_trim(@sel[0],"trim_z2",@len)
							elsif @trim_x1 || @trim_x2
							change_trim(@sel[0],"trim_z1",@len)
            end
						else
						if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
							change_point(@sel[0],"point_z",3)
            end
          end
					elsif key==VK_DOWN && @control_press != true && @alt_press != true
					if @shift_press == true
						if @point_x_offset || @point_y_offset
							change_trim(@sel[0],"trim_y2",@len)
							elsif @point_z_offset
							change_trim(@sel[0],"trim_z1",@len)
							elsif @trim_x1 || @trim_x2
							change_trim(@sel[0],"trim_z2",@len)
            end
						else
						if @point_x_offset || @point_y_offset || @point_z_offset || @trim_x1 || @trim_x2
							change_point(@sel[0],"point_z",3)
            end
          end
					elsif OSX && key==61 || !OSX && key==107 || !OSX && key==187
					if @trim_x1 || @trim_x2
						a0_shelves_count = @ent_def.get_attribute("dynamic_attributes", "a0_shelves_count")
						a0_panel_count = @ent_def.get_attribute("dynamic_attributes", "a0_panel_count")
						a0_drawer_count = @ent_def.get_attribute("dynamic_attributes", "a0_drawer_count")
						if a0_shelves_count
							a0_shelves_count = change_count(@sel[0],a0_shelves_count,"a0_shelves_count",12)
							elsif a0_panel_count
							a0_panel_count = change_count(@sel[0],a0_panel_count,"a0_panel_count",12)
							elsif a0_drawer_count
							a0_drawer_count = change_count(@sel[0],a0_drawer_count,"a0_drawer_count",5)
            end
          end
					elsif OSX && key==45 || !OSX && key==109 || !OSX && key==189
					if @trim_x1 || @trim_x2
						a0_shelves_count = @ent_def.get_attribute("dynamic_attributes", "a0_shelves_count")
						a0_panel_count = @ent_def.get_attribute("dynamic_attributes", "a0_panel_count")
						a0_drawer_count = @ent_def.get_attribute("dynamic_attributes", "a0_drawer_count")
						if a0_shelves_count
							a0_shelves_count = change_count(@sel[0],a0_shelves_count,"a0_shelves_count",1)
							elsif a0_panel_count
							a0_panel_count = change_count(@sel[0],a0_panel_count,"a0_panel_count",1)
							elsif a0_drawer_count
							a0_drawer_count = change_count(@sel[0],a0_drawer_count,"a0_drawer_count",1)
            end
          end
					elsif OSX && key==44 || OSX && key==63 || !OSX && key==191 && @shift_press == true
					@sel.clear
					if @new_entity
						@sel.add @new_entity
						activate
          end
					elsif key==27
					deactivate(view)
					@model.tools.pop_tool
        end
      end
    end
		def change_point(entity,point,max_value)
			point_value = entity.definition.get_attribute("dynamic_attributes", point).to_i
			@model.start_operation "change_point", true, false, true
			new_value= (point_value==max_value ? 1 : point_value+1)
			set_attribute_with_formula(entity, point, new_value)
			DCProgressBar::clear()
			Redraw_Components.redraw(entity,true)
			DCProgressBar::clear()
			$dlg_att.execute_script("add_comp()") if $dlg_att
			$dlg_suf.execute_script("add_comp()") if $attobserver == 2
			$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
			@model.commit_operation
			place_component(entity)
			comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
			@place_component = []
    end
		def change_trim(entity,trim,len)
			@model.start_operation "change_trim", true, false, true
			trim_value = entity.definition.get_attribute("dynamic_attributes", trim).to_f
			len_value = entity.definition.get_attribute("dynamic_attributes", len).to_f
			if trim_value.to_s == "0.0" 
				set_attribute_with_formula(entity, trim, len_value, len)
				else 
				set_attribute_with_formula(entity, trim, 0.0)
      end
			DCProgressBar::clear()
			Redraw_Components.redraw(entity,true)
			DCProgressBar::clear()
			$dlg_att.execute_script("add_comp()") if $dlg_att
			$dlg_suf.execute_script("add_comp()") if $attobserver == 2
			$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
			@model.commit_operation
			place_component(entity)
			comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
			@place_component = []
    end
		def change_count(entity,count,att,max_value)
			@model.start_operation "count", true, false, true
			if max_value == 1
				new_count= (count.to_i==1) ? 1 : (count.to_i-1)
				else
				new_count= (count.to_i==max_value) ? max_value : (count.to_i+1)
      end
			set_attribute_with_formula(entity,att,new_count)
			DCProgressBar::clear()
			Redraw_Components.redraw(entity,true)
			DCProgressBar::clear()
			$dlg_att.execute_script("add_comp()") if $dlg_att
			$dlg_suf.execute_script("add_comp()") if $attobserver == 2
			$dlg_suf.execute_script("check_listtablinks()") if $attobserver == 4
			count = new_count
			entity.definition.entities.grep(Sketchup::ComponentInstance).each { |entity| delete_if(entity) }
			@model.commit_operation
			reset_essence_and_faces
			@place_component = []
			comp_with_essence(@model.entities.grep(Sketchup::ComponentInstance),@edge_color_arr)
			return count
    end
		def delete_if(entity)
			if entity.definition.get_attribute("dynamic_attributes", "c2_erase", 0).to_f > 0
				entity.erase!
				else
				entity.definition.entities.grep(Sketchup::ComponentInstance).each { |e| delete_if(e) }
      end
    end#def
		def set_attribute_with_formula(entity,attribute,value,formula=nil)
			entity.set_attribute("dynamic_attributes", attribute, value)
			entity.definition.set_attribute("dynamic_attributes", attribute, value)
			entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_label", attribute.downcase)
			entity.definition.delete_attribute("dynamic_attributes", "_"+attribute+"_formula")
			entity.definition.set_attribute("dynamic_attributes", "_"+attribute+"_formula", formula) if formula != nil
    end
		def enableVCB?
			return true
    end
		def onUserText(text, view)
			@distance = text.to_f/25.4
			entity = @sel[0]
			if @point_y_offset
				@model.start_operation "Point offset", true
				entity.set_attribute("dynamic_attributes", "point_y_offset", @distance)
				entity.definition.set_attribute("dynamic_attributes", "point_y_offset", @distance)
				DCProgressBar::clear()
				Redraw_Components.redraw(entity,true)
				DCProgressBar::clear()
				@model.commit_operation
				elsif @point_x_offset
				@model.start_operation "point_offset", true
				entity.set_attribute("dynamic_attributes", "point_x_offset", @distance)
				entity.definition.set_attribute("dynamic_attributes", "point_x_offset", @distance)
				DCProgressBar::clear()
				Redraw_Components.redraw(entity,true)
				DCProgressBar::clear()
				@model.commit_operation
				elsif @point_z_offset
				@model.start_operation "point_offset", true
				entity.set_attribute("dynamic_attributes", "point_z_offset", @distance)
				entity.definition.set_attribute("dynamic_attributes", "point_x_offset", @distance)
				DCProgressBar::clear()
				Redraw_Components.redraw(entity,true)
				DCProgressBar::clear()
				@model.commit_operation
      end
			rescue ArgumentError
			view.tooltop = 'Invalid length'
    end
  end # Class
end
