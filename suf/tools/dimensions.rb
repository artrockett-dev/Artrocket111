module SU_Furniture
  class PanelDimensions
    def initialize()
      @shift_press = false
      @control_press = false
      @text_size = (OSX ? 20 : 13)
      @x_offset = (OSX ? 10 : 0)
      @y_offset = (OSX ? 10 : 0)
      @offset_value = 0.1
      @arrow_type = Sketchup::Dimension::ARROW_CLOSED
      @delete_frontal_dimensions = false
      @delete_module_dimensions = false
      @object_text = "Размеры панелей"
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
      @orange = Sketchup::Color.new(210, 130, 0, 150)
      @face_type = nil
      @essence = nil
      @module = nil
    end#def
		def read_param
      if File.file?( TEMP_PATH+"/SUF/dimensions.dat")
        path_param = TEMP_PATH+"/SUF/dimensions.dat"
        else
        path_param = PATH + "/parameters/dimensions.dat"
      end
      @content = File.readlines(path_param)
			case @content[0]
			  when 1 then @arrow_type = Sketchup::Dimension::ARROW_CLOSED
				when 2 then @arrow_type = Sketchup::Dimension::ARROW_OPEN
				when 3 then @arrow_type = Sketchup::Dimension::ARROW_NONE
				when 4 then @arrow_type = Sketchup::Dimension::ARROW_SLASH
				when 5 then @arrow_type = Sketchup::Dimension::ARROW_DOT
				else @arrow_type = Sketchup::Dimension::ARROW_CLOSED
      end
      @dim_position = @content[1].to_i
      @dim_rotation = @content[2].to_i
      @dim_vert_position = @content[3].to_i
      @dim_hor_position = @content[4].to_i
      @dimensions_object = @content[5].to_i
			@content[6].to_i == 1 ? @back_frontal_dimensions = true : @back_frontal_dimensions = false
    end#def
    def activate
      @shift_press = false
      @control_press = false
		  read_param
      case @dimensions_object
        when 1 then @object_text = "Размеры панелей"
        when 2 then @object_text = "Размеры ниш"
        when 3 then @object_text = "Размеры модулей"
        when 4 then @object_text = "Между компонентами"
      end
      @model=Sketchup.active_model
      @sel=@model.selection
      @sel.remove_observer $SUFSelectionObserver
      view = @model.active_view
      mat_names = []
      @model.materials.each{|i| mat_names << i.display_name}
      @back_check = image_rep(view,mat_names,"check.png")
      @points = []
      @add_face_edges = []
      @ip=Sketchup::InputPoint.new
      @all_frontal = false
			@model.options['UnitsOptions']['LengthPrecision'] = 0
			@dim_layer = @model.layers.add "7_Размеры"
			@frontal_dim_layer = @model.layers.add "7_Размеры_Фасадов"
      @module_dim_layer = @model.layers.add "0_Размеры"
			@dim_layer.visible = true
			@frontal_dim_layer.visible = true
      @module_dim_layer.visible = true
			@sel.clear
			@ip=Sketchup::InputPoint.new
			@screen_x=0
			@screen_y=0
			@model.start_operation "layers", true, false, true
			@model.layers.each { |l|
				l.visible = true if l.name.include?("Габаритная_рамка") || l.name.include?("Z_Face")
				l.visible = false if l.name.include?("Толщина_кромки") && l.visible? == true
      }
			@model.commit_operation
			if @dimensions_object == 2
				@model.start_operation('make_body_faces', true,false,true)
				@model.entities.grep(Sketchup::ComponentInstance).each { |e|
					if e.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module"
						body = e.definition.entities.grep(Sketchup::ComponentInstance).find { |ent| ent.definition.name.include?("Body")}
						if body
						  bounds = body.bounds
							make_body_faces(e,bounds,[0,1,3,2])
							make_body_faces(e,bounds,[0,2,6,4])
							make_body_faces(e,bounds,[7,6,4,5])
							make_body_faces(e,bounds,[7,5,1,3])
							make_body_faces(e,bounds,[7,6,2,3])
            end
          end
        }
				@model.commit_operation
      end
			self.reset(view)
    end#def
    def deactivate(view)
      @shift_press = false
			@control_press = false
      @model.start_operation "clear", true, false, true
      @add_face_edges.to_a.each {|e| e.erase! if !e.deleted?}
      @model.layers.each { |l|
        l.visible = false if l.name.include?("Габаритная_рамка")
      }
      @model.commit_operation
      @sel.clear
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
      end
      view.release_texture(@back_check)
      #view.model.select_tool nil
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
        new_mat.texture= PATH+"/icons/" + mat_name
        image_rep = new_mat.texture.image_rep
        return view.load_texture(image_rep)
      end
    end#def
    def draw(view)
      y = 25
      view.line_width=1
      view.drawing_color = "gray"
      @change_object = false
      if @screen_x > 15 && @screen_x < pix_pt(320)+@x_offset*3 && @screen_y > y-4 && @screen_y < y+20+@y_offset
        view.line_width=2
        view.drawing_color="black"
        @change_object = true
        view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
        draw_text(view,Geom::Point3d.new(25, y, 0), @object_text, @text_active_options)
        else
        view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
        draw_text(view,Geom::Point3d.new(25, y, 0), @object_text, @text_default_options)
      end
      y += 30+@y_offset
      draw_text(view,Geom::Point3d.new(25, y, 0), "Tab - Тип указателей", @text_default_options)
      if @dim_position==4
        text = "2 размера по центру"
        elsif @dim_position==3
        text = "Вертикальный и горизонтальный размеры"
        elsif @dim_position==2
        text = "Горизонтальный размер"
        else
        text = "Вертикальный размер"
      end
      y += 30+@y_offset
      draw_text(view,Geom::Point3d.new(25, y, 0), "Ctrl - "+text, @text_default_options)
      y += 30+@y_offset
      draw_text(view,Geom::Point3d.new(25, y, 0), "Shift - Поворот размеров (" + @dim_rotation.to_s + ")", @text_default_options)
      y += 30+@y_offset
      draw_text(view,Geom::Point3d.new(25, y, 0), "Стрелки - Положение указателей", @text_default_options)
      y += 30+@y_offset
      draw_text(view,Geom::Point3d.new(25, y, 0), "Двойной клик - Удалить размеры", @text_default_options)
      y += 30+@y_offset
      
      @back_frontal = false
      @all_frontal = false
      
      
      if @dimensions_object == 1
        uvs = [ [0, 0, 0], [1, 0, 0], [1, 1, 0], [0, 1, 0] ]
        if @back_frontal_dimensions
          view.draw2d(GL_QUADS, [ Geom::Point3d.new(21, y+15+@y_offset, 0), Geom::Point3d.new(35+@x_offset, y+15+@y_offset, 0), Geom::Point3d.new(35+@x_offset, y+1, 0), Geom::Point3d.new(21, y+1, 0) ], texture: @back_check, uvs: uvs)
        end
        view.line_width=1
        view.drawing_color = "gray"
        if @screen_x > 15 && @screen_x < 40 && @screen_y > y-4 && @screen_y < y+20+@y_offset
          view.line_width=2
          view.drawing_color="black"
          @back_frontal = true
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y, 0), Geom::Point3d.new(36+@x_offset*3, y, 0), Geom::Point3d.new(36+@x_offset*3, y+16+@y_offset, 0), Geom::Point3d.new(20, y+16+@y_offset, 0) ])
          else
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y, 0), Geom::Point3d.new(36+@x_offset*3, y, 0), Geom::Point3d.new(36+@x_offset*3, y+16+@y_offset, 0), Geom::Point3d.new(20, y+16+@y_offset, 0) ])
        end
        draw_text(view,Geom::Point3d.new(45, y, 0), "Размеры на обратной стороне фасадов", @text_default_options)
        if @delete_frontal_dimensions
          text = "Удалить размеры фасадов"
          else
          text = "Размеры на всех фасадах"
        end
        view.line_width=1
        view.drawing_color = "gray"
        y += 40+@y_offset
        if @screen_x > 15 && @screen_x < pix_pt(320)+@x_offset*3 && @screen_y > y-4 && @screen_y < y+20+@y_offset
          view.line_width=2
          view.drawing_color="black"
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), text, @text_active_options)
          @all_frontal = true
          else
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), text, @text_default_options)
        end
      end
      
      @delete_dimensions = false
      if @dimensions_object == 2
        view.line_width=1
        view.drawing_color = "gray"
        if @screen_x > 15 && @screen_x < pix_pt(320)+@x_offset*3 && @screen_y > y-4 && @screen_y < y+20+@y_offset
          view.line_width=2
          view.drawing_color="black"
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), "Удалить размеры ниш", @text_active_options)
          @delete_dimensions = true
          else
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), "Удалить размеры ниш", @text_default_options)
        end
      end
      
      @all_module = false
      if @dimensions_object == 3
        view.line_width=1
        view.drawing_color = "gray"
        if @delete_module_dimensions
          text = "Удалить размеры модулей"
          else
          text = "Размеры на всех модулях"
        end
        if @screen_x > 15 && @screen_x < pix_pt(320)+@x_offset*3 && @screen_y > y-4 && @screen_y < y+20+@y_offset
          view.line_width=2
          view.drawing_color="black"
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), text, @text_active_options)
          @all_module = true
          else
          view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(20, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y-4, 0), Geom::Point3d.new(pix_pt(320)+@x_offset*3, y+20+@y_offset, 0), Geom::Point3d.new(20, y+20+@y_offset, 0) ])
          draw_text(view,Geom::Point3d.new(25, y, 0), text, @text_default_options)
        end
      end
      
      if @dimensions_object == 2 && @points != []
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
      
      Sketchup::set_status_text "Смещение размерной линии ", SB_VCB_LABEL
      Sketchup::set_status_text (@offset_value==0.1 ? 0 : (@offset_value*25.4).round), SB_VCB_VALUE
      
    end#def
    def onMouseMove(flags, x, y, view)
      @screen_x = x
      @screen_y = y
      @ip.pick view,x,y
      @face_type = nil
      @essence = nil
      @module = nil
      if @dimensions_object == 1
        @sel.clear
        if (@ip.valid?)
          @ipface=nil if @sel.length==0
          Sketchup::set_status_text "Наведите на панель"
          if @ip.face
            comp = @ip.face.parent.instances[0]
            if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
              lenx = comp.definition.get_attribute("dynamic_attributes", "lenx", "0").to_f
              leny = comp.definition.get_attribute("dynamic_attributes", "leny", "0").to_f
              lenz = comp.definition.get_attribute("dynamic_attributes", "lenz", "0").to_f
              primary_face = true
              primary_face = false if @ip.face.edges.collect{ |edge| (edge.length*25.4+0.01).round(1) }.include?((lenx*25.4+0.01).round(1))
              if primary_face
                @ipface = @ip.face
                @sel.add @ipface
                @sel.add @ipface.edges
                @essence = comp
                all_comp=search_parent(@essence)
                if all_comp != []
                  all_comp.reverse.each { |parent_comp|
                    parent_comp.make_unique
                    parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
                  }
                end
                view.tooltip = (lenz*25.4).round.to_s+" x "+(leny*25.4).round.to_s
              end
            end
          end
        end
        elsif @dimensions_object == 2
        Sketchup::set_status_text "Наведите на нишу"
        @pt = @ip.position
        @points = []
        ph = view.pick_helper
        ph.do_pick(x, y)
        @picked_comp = ph.best_picked
        if @picked_comp && @picked_comp.is_a?(Sketchup::ComponentInstance)
          @body = nil
          @picked_comp.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| @body = ent if ent.definition.name.include?("Body")}
          if @body
					  bounds = @body.bounds
            body_max_x = bounds.max.x
            body_max_y = bounds.max.y
            body_max_z = bounds.max.z
            @transformation = @picked_comp.transformation
            @transformation *= @body.transformation
            @pt_in_comp = @pt.transform( @transformation.inverse )
            @pts_for_bounds = {}
            @pts_for_bounds["min_x"] = []
            @pts_for_bounds["min_z"] = []
            @pts_for_bounds["max_x"] = []
            @pts_for_bounds["max_z"] = []
            @pts_for_bounds["max_y"] = []
            #p @pt_in_comp
            @body.definition.entities.grep(Sketchup::ComponentInstance).each { |comp| essence_pts(comp,Geom::Transformation.new) }
            #p @pts_for_bounds
            if @pts_for_bounds["min_x"] == []
              @min_x = [(@pts_for_bounds["min_z"]==[] ? 0: @pts_for_bounds["min_z"].map{|pt|pt.x}.sort[0]),(@pts_for_bounds["max_z"]==[] ? 0 : @pts_for_bounds["max_z"].map{|pt|pt.x}.sort[0])].sort[-1]
              else
              @min_x = @pts_for_bounds["min_x"][0].x
            end
            if @pts_for_bounds["max_x"] == []
              @max_x = [(@pts_for_bounds["min_z"]==[] ? body_max_x : @pts_for_bounds["min_z"].map{|pt|pt.x}.sort[-1]),(@pts_for_bounds["max_z"]==[] ? body_max_x : @pts_for_bounds["max_z"].map{|pt|pt.x}.sort[-1])].sort[0]
              else
              @max_x = @pts_for_bounds["max_x"][0].x
            end
            if @pts_for_bounds["min_z"] == []
              @min_z = [(@pts_for_bounds["min_x"]==[] ? 0 : @pts_for_bounds["min_x"].map{|pt|pt.z}.sort[0]),(@pts_for_bounds["max_x"]==[] ? 0 : @pts_for_bounds["max_x"].map{|pt|pt.z}.sort[0])].sort[-1]
              else
              @min_z = @pts_for_bounds["min_z"][0].z
            end
            if @pts_for_bounds["max_z"] == []
              @max_z = [(@pts_for_bounds["min_x"]==[] ? body_max_z : @pts_for_bounds["min_x"].map{|pt|pt.z}.sort[-1]),(@pts_for_bounds["max_x"]==[] ? body_max_z : @pts_for_bounds["max_x"].map{|pt|pt.z}.sort[-1])].sort[0]
              else
              @max_z = @pts_for_bounds["max_z"][0].z
            end
            @min_y = [(@pts_for_bounds["min_x"]==[] ? 0 : @pts_for_bounds["min_x"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["max_x"]==[] ? 0 : @pts_for_bounds["max_x"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["min_z"]==[] ? 0 : @pts_for_bounds["min_z"].map{|pt|pt.y}.sort[0]),(@pts_for_bounds["max_z"]==[] ? 0 : @pts_for_bounds["max_z"].map{|pt|pt.y}.sort[0])].sort[-1]
            
            if @pts_for_bounds["max_y"] == []
              @max_y = [(@pts_for_bounds["min_x"]==[] ? body_max_y : @pts_for_bounds["min_x"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["max_x"]==[] ? body_max_y : @pts_for_bounds["max_x"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["min_z"]==[] ? body_max_y : @pts_for_bounds["min_z"].map{|pt|pt.y}.sort[-1]),(@pts_for_bounds["max_z"]==[] ? body_max_y : @pts_for_bounds["max_z"].map{|pt|pt.y}.sort[-1])].sort[0]
              else
              @max_y = @pts_for_bounds["max_y"][0].y
            end
            if @min_x<@max_x && @min_y<@max_y && @min_z<@max_z
              @points = [@min_x,@max_x,@min_y,@max_y,@min_z,@max_z]
              view.tooltip = ((@max_x-@min_x)*25.4).round.to_s+" x "+((@max_y-@min_y)*25.4).round.to_s+" x "+((@max_z-@min_z)*25.4).round.to_s
            end
          end
        end
        elsif @dimensions_object == 3
        Sketchup::set_status_text "Наведите на модуль"
        @pt = @ip.position
        @points = []
        ph = view.pick_helper
        ph.do_pick(x, y)
        @picked_comp = ph.best_picked
        if @picked_comp && @picked_comp.is_a?(Sketchup::ComponentInstance)
          if @picked_comp.definition.get_attribute("dynamic_attributes", "su_type") == "module"
            @module = @picked_comp
          end
        end
      end
      view.invalidate
    end#def
    def essence_pts(comp,transformation)
      if !comp.hidden?
        if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          all_comp=search_parent(comp)
          if all_comp != []
            all_comp.reverse.each { |parent_comp|
              parent_comp.make_unique if parent_comp.definition.count_instances > 1
              parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
            }
          end
          comp.make_unique if comp.definition.count_instances > 1
          comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
          transformation*=comp.transformation
          #transformation.invert!
          comp.definition.entities.grep(Sketchup::Face).each { |f|
            if f.get_attribute("dynamic_attributes", "face", "0").include?("primary")
              f_normal = f.normal.transform transformation
							bounds = f.bounds
              f_max = bounds.max.transform transformation
              f_center = bounds.center.transform transformation
              f_min = bounds.min.transform transformation
              #p "#{comp.definition.name}: #{f_normal}"
                #p @pt_in_comp
                #p f_min
                #p f_center
              #p f_max
              f_normal.normalize!
              #p f_normal.z
              if f_normal.x == 1 && f_center.x <= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z
                if @pts_for_bounds["min_x"] == []
                  @pts_for_bounds["min_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                  else
                  @pts_for_bounds["min_x"].each { |pts|
                    if f_center.x > pts.x
                      @pts_for_bounds["min_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                    end
                  }
                end
                elsif f_normal.x == -1 && f_center.x >= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z
                if @pts_for_bounds["max_x"] == []
                  @pts_for_bounds["max_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                  else
                  @pts_for_bounds["max_x"].each { |pts|
                    if f_center.x < pts.x
                      @pts_for_bounds["max_x"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                    end
                  }
                end
                elsif f_normal.z == 1 && f_center.z <= @pt_in_comp.z && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x
                if @pts_for_bounds["min_z"] == []
                  @pts_for_bounds["min_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                  else
                  @pts_for_bounds["min_z"].each { |pts|
                    if f_center.z > pts.z
                      @pts_for_bounds["min_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                    end
                  }
                end
                elsif f_normal.z == -1 && f_center.z >= @pt_in_comp.z && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x
                if @pts_for_bounds["max_z"] == []
                  @pts_for_bounds["max_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                  else
                  @pts_for_bounds["max_z"].each { |pts| 
                    if f_center.z < pts.z
                      @pts_for_bounds["max_z"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                    end
                  }
                end
                elsif f_normal.y == -1 && f_center.y >= @pt_in_comp.y && f_min.x <= @pt_in_comp.x && f_max.x >= @pt_in_comp.x && f_min.z <= @pt_in_comp.z && f_max.z >= @pt_in_comp.z
                if @pts_for_bounds["max_y"] == []
                  @pts_for_bounds["max_y"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                  else
                  @pts_for_bounds["max_y"].each { |pts|
                    if f_center.y < pts.y
                      @pts_for_bounds["max_y"] = f.outer_loop.vertices.collect {|v| v.position.transform transformation }
                    end
                  }
                end
              end
            end
          }
          else
          transformation*=comp.transformation
          comp.definition.entities.grep(Sketchup::ComponentInstance).each { |body| essence_pts(body,transformation) }
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
    def make_body_faces(e,bb,a)
      pts = [bb.corner(a[0]),bb.corner(a[1]),bb.corner(a[2]),bb.corner(a[3])]
      f = e.definition.entities.add_face(pts)
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
      @add_face_edges += f.edges
    end#def
    def onLButtonDown(flags, x, y, view)
      if @change_object
        @dimensions_object > 2 ? @dimensions_object = 1 : @dimensions_object += 1
        case @dimensions_object
          when 1 then @object_text = "Размеры панелей"
          when 2 then @object_text = "Размеры ниш"
          when 3 then @object_text = "Размеры модулей"
          when 4 then @object_text = "Между компонентами"
        end
        if @dimensions_object == 3 && @dim_position == 4
          @dim_position = 3
        end
        if @dimensions_object == 2
          @model.start_operation('make_body_faces', true,false,true)
          @model.entities.grep(Sketchup::ComponentInstance).each { |e|
            if e.definition.get_attribute("dynamic_attributes", "su_type", "0") == "module"
              body = nil
              e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| body = ent if ent.definition.name.include?("Body")}
              if body
							  bounds = body.bounds
                make_body_faces(e,bounds,[0,1,3,2])
                make_body_faces(e,bounds,[0,2,6,4])
                make_body_faces(e,bounds,[7,6,4,5])
                make_body_faces(e,bounds,[7,5,1,3])
                make_body_faces(e,bounds,[7,6,2,3])
              end
            end
          }
          @model.commit_operation
          else
          @model.start_operation('delete_body_faces', true,false,true)
          @add_face_edges.to_a.each {|e| e.erase! if !e.deleted?}
          @model.commit_operation
        end
        view.invalidate
        draw(view)
        save_param
        elsif @back_frontal
        @back_frontal_dimensions ? @back_frontal_dimensions = false : @back_frontal_dimensions = true
				save_param
        view.invalidate
        elsif @all_frontal
        @model.start_operation "Dimensions of all facades", true
        @essences = {}
        @model.entities.grep(Sketchup::ComponentInstance).each { |comp| search_essences(comp) }
        @essences.each_pair{|essence,faces|essence.definition.entities.grep(Sketchup::DimensionLinear).each {|dim| dim.erase! }}
        if !@delete_frontal_dimensions
          if @essences != {}
            @essences.each_pair{|essence,faces|
              faces.each{|face|
                if !@back_frontal_dimensions && face.bounds.center.x == 0
                  else
                  face_dimension(essence,face,@frontal_dim_layer)
                end
              }
            }
            @delete_frontal_dimensions = true
          end
          else
          @essences.each_pair{|essence,faces|
            essence.delete_attribute("dynamic_attributes", "dimensions")
            essence.definition.delete_attribute("dynamic_attributes", "dimensions")
            essence.definition.delete_attribute("dynamic_attributes", "_dimensions_label")
            essence.definition.delete_attribute("dynamic_attributes", "_dimensions_formula")
          }
          @delete_frontal_dimensions = false
        end
        @model.commit_operation
        view.invalidate
        draw(view)
        elsif @all_module
        @model.start_operation "Dimensions of all modules", true
        if !@delete_module_dimensions
          @model.entities.grep(Sketchup::ComponentInstance).each {|comp|
            if comp.definition.get_attribute("dynamic_attributes", "su_type") == "module"
              module_dimensions(@model, comp)
            end
          }
          @delete_module_dimensions = true
          else
          @model.entities.grep(Sketchup::DimensionLinear).each {|dim|
            if dim.get_attribute("su_dimension", "dim_left") || dim.get_attribute("su_dimension", "dim_right") || dim.get_attribute("su_dimension", "dim_bottom") || dim.get_attribute("su_dimension", "dim_top")
              dim.erase!
            end
          }
          @delete_module_dimensions = false
        end
        @model.commit_operation
        view.invalidate
        draw(view)
        elsif @delete_dimensions
        @model.start_operation "Delete dimensions", true
        @model.entities.grep(Sketchup::ComponentInstance).each { |comp|
          @body = nil
          comp.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| @body = ent if ent.definition.name.include?("Body")}
          @body.definition.entities.grep(Sketchup::DimensionLinear).each {|dim| dim.erase! } if @body
        }
        @model.commit_operation
        elsif @dimensions_object == 1 && @essence
        @double_click = false
        essence = @essence
        UI.start_timer(0.3, false) {
          if @double_click != true
            @model.start_operation "Panel dimensions", true
            essence.definition.entities.grep(Sketchup::DimensionLinear).each {|dim| dim.erase! }
            face_dimension(essence,@ipface,@dim_layer)
            @model.commit_operation
          end
        }
        elsif @dimensions_object == 2 && @points != []
        @double_click = false
        UI.start_timer(0.3, false) {
          if @double_click != true
            @model.start_operation "Niche dimensions", true
            niche_dimensions(@body,@points)
            @model.commit_operation
          end
        }
        elsif @dimensions_object == 3 && @module
        @double_click = false
        UI.start_timer(0.3, false) {
          if @double_click != true
            @model.start_operation "Module dimensions", true
            module_dimensions(@model,@module)
            @model.commit_operation
          end
        }
      end
    end#def
    def niche_dimensions(comp,points)
      p1 = Geom::Point3d.new(points[0], points[2], points[4]) #left bottom
      p2 = Geom::Point3d.new(points[0], points[2], points[5]) #left top
      p3 = Geom::Point3d.new(points[1], points[2], points[5]) #right top
      p4 = Geom::Point3d.new(points[1], points[2], points[4]) #right bottom
      comp.definition.entities.grep(Sketchup::DimensionLinear).each {|dim|
        if dim.start.include?(p1) && dim.end.include?(p2) || dim.start.include?(p4) && dim.end.include?(p3) || dim.start.include?(p1) && dim.end.include?(p4) || dim.start.include?(p2) && dim.end.include?(p3)
          dim.erase!
        end
      }
      if @dim_position==1 || @dim_position==3
        @dim_vert_position == 2 ? offset_value = (p1.distance(p4))/2 : offset_value = @offset_value
        dim = comp.definition.entities.add_dimension_linear (@dim_vert_position == 3 ? p4 : p1), (@dim_vert_position == 3 ? p3 : p2), (@dim_vert_position==3) ? [-1*offset_value,0,0] : [1*offset_value,0,0]
        dim.layer = @dim_layer
        dim.arrow_type = @arrow_type
      end
      if @dim_position==2 || @dim_position==3
        @dim_hor_position == 2 ? offset_value = (p1.distance(p2))/2 : offset_value = @offset_value
        dim = comp.definition.entities.add_dimension_linear (@dim_hor_position == 3 ? p2 : p1),(@dim_hor_position == 3 ? p3 : p4), (@dim_hor_position==3) ? [0, 0, -1*offset_value] : [0, 0, 1*offset_value]
        dim.layer = @dim_layer
        dim.arrow_type = @arrow_type
      end
      if @dim_position==4 || @dim_position==5
        pt1 = Geom::Point3d.new(p1.x+(p4.x-p1.x).abs/2-1,p1.y,p1.z+(p2.z-p1.z).abs/2)
        pt2 = Geom::Point3d.new(p1.x+(p4.x-p1.x).abs/2+1,p1.y,p1.z+(p2.z-p1.z).abs/2)
        dim = comp.definition.entities.add_dimension_linear pt1,pt2, [0, 0, 0.1]
        dim.layer = @dim_layer
        dim.text = ((p1.distance(p2))*25.4).round.to_s+"x"+((p1.distance(p4))*25.4).round.to_s
        dim.arrow_type = Sketchup::Dimension::ARROW_NONE
      end
    end#def
    def search_essences(comp)
      if !comp.hidden?
        if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          if comp.layer.name == "1_Фасад"
            lenx = comp.definition.get_attribute("dynamic_attributes", "lenx")
            if lenx && lenx.to_f > 0.4
              all_comp=search_parent(comp)
              if all_comp != []
                all_comp.reverse.each { |parent_comp|
                  parent_comp.make_unique if parent_comp.definition.count_instances > 1
                  parent_comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if parent_comp.parent.is_a?(Sketchup::ComponentDefinition)
                }
              end
              comp.make_unique if comp.definition.count_instances > 1
              comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
              @essences[comp] = []
              comp.definition.entities.grep(Sketchup::Face).each { |f|
                face = f.get_attribute("dynamic_attributes", "face", "0")
                @essences[comp] << f if face.include?("primary")
              }
            end
          end
          else
          comp.definition.entities.grep(Sketchup::ComponentInstance).each { |body| search_essences(body) }
        end
      end
    end#def
    def module_dimensions(model, comp)
      return unless comp.is_a?(Sketchup::ComponentInstance)
      entities = model.active_entities
      corner_hash = find_corner_points_with_paths(comp)
      if @dim_position==1 || @dim_position==3
        add_vert_dimension(entities,comp,corner_hash)
      end
      if @dim_position==2 || @dim_position==3
        add_hor_dimension(entities,comp,corner_hash)
      end
    end
    def find_edges_in_point_box(entity, recursive = false, path = [], transformation = Geom::Transformation.new, result = [])
      case entity
        when Sketchup::ComponentInstance
        combined_transformation = recursive ? transformation * entity.transformation : transformation
        new_path = path + [entity]
        if !recursive || entity.definition.name.include?("Body") || new_path.any? { |comp| comp.definition.name.include?("Point_box") }
          entity.definition.entities.each do |sub_entity|
            find_edges_in_point_box(sub_entity, true, new_path, combined_transformation, result)
          end
        end
        when Sketchup::Edge
        if path.any? { |comp| comp.definition.name.include?("Point_box") }
          transformed_points = entity.vertices.map { |v| v.position.transform(transformation) }
          result << { edge: entity, path: Sketchup::InstancePath.new(path), points: transformed_points }
        end
      end
      result
    end
    
    def find_corner_points_with_paths(entity)
      edges_with_paths = find_edges_in_point_box(entity)
      return [] if edges_with_paths.empty?
      points = edges_with_paths.flat_map { |e| e[:points].map { |pt| { point: pt, edge: e[:edge], path: e[:path] } } }
      min_x = points.map { |pt| pt[:point].x }.min
      max_x = points.map { |pt| pt[:point].x }.max
      min_y = points.map { |pt| pt[:point].y }.min
      max_y = points.map { |pt| pt[:point].y }.max
      min_z = points.map { |pt| pt[:point].z }.min
      max_z = points.map { |pt| pt[:point].z }.max
      corners_coords = [
        [min_x, max_y, min_z],
        [max_x, max_y, min_z],
        [min_x, max_y, max_z],
        [max_x, max_y, max_z]
      ]
      corner_hash = {}
      corners_coords.each_with_index do |(x, y, z), index|
        nearest = points.min_by { |pt| (pt[:point].x - x).abs + (pt[:point].y - y).abs + (pt[:point].z - z).abs }
        corner_hash[index] = {
          point: Geom::Point3d.new(x, y, z),
          edge: nearest[:edge],
          path: nearest[:path]
        }
      end
      corner_hash
    end
    
    def add_vert_dimension(entities,comp,corner_hash)
      return if @dim_vert_position != 1 && @dim_vert_position != 2
      case @dim_vert_position
        when 1 then index1 = 0; index2 = 2
        when 2 then index1 = 1; index2 = 3
      end
      dim_type = @dim_vert_position == 1 ? "dim_left" : "dim_right"
      existing_dim = entities.grep(Sketchup::DimensionLinear).find { |dim| dim.get_attribute("su_dimension", dim_type, "0") == comp.definition.name }
      existing_dim&.erase!
      tr = comp.transformation
      pt1 = corner_hash[index1][:point].transform(tr)
      pt2 = corner_hash[index2][:point].transform(tr)
      offset_vector = tr.xaxis.reverse
      rotation_angle = case @dim_rotation
        when 1 then 0
        when 2 then 90.degrees
        when 3 then 180.degrees
        when 4 then 270.degrees
        else 0
      end
      
      # Применяем вращение вокруг оси Z (или другой оси при необходимости)
      rotation = Geom::Transformation.rotation(pt1, tr.zaxis, rotation_angle)
      offset_vector = offset_vector.transform(rotation).to_a.map { |c| c * (@dim_vert_position == 2 ? -@offset_value : @offset_value) }
      dim = entities.add_dimension_linear(pt1, pt2, offset_vector)
      new_instance_path = Sketchup::InstancePath.new(corner_hash[index1][:path].to_a + [corner_hash[index1][:edge]])
      dim.start_attached_to = [new_instance_path, pt1]
      new_instance_path = Sketchup::InstancePath.new(corner_hash[index2][:path].to_a + [corner_hash[index2][:edge]])
      dim.end_attached_to = [new_instance_path, pt2]
      if @dim_vert_position == 1
        dim.set_attribute("su_dimension", "dim_left", comp.definition.name)
        else
        dim.set_attribute("su_dimension", "dim_right", comp.definition.name)
      end
      dim.arrow_type = @arrow_type
      dim.layer = @module_dim_layer
    end
    def add_hor_dimension(entities,comp,corner_hash)
      return if @dim_hor_position != 1 && @dim_hor_position != 2
      case @dim_hor_position
        when 1 then index1 = 0; index2 = 1
        when 2 then index1 = 2; index2 = 3
      end
      dim_type = @dim_hor_position == 1 ? "dim_bottom" : "dim_top"
      existing_dim = entities.grep(Sketchup::DimensionLinear).find { |dim| dim.get_attribute("su_dimension", dim_type, "0") == comp.definition.name }
      existing_dim&.erase!
      tr = comp.transformation
      pt1 = corner_hash[index1][:point].transform(tr)
      pt2 = corner_hash[index2][:point].transform(tr)
      offset_vector = tr.zaxis.reverse
      rotation_angle = case @dim_rotation
        when 1 then 0
        when 2 then 90.degrees
        when 3 then 180.degrees
        when 4 then 270.degrees
        else 0
      end
      rotation = Geom::Transformation.rotation(pt1, tr.xaxis, rotation_angle)
      offset_vector = offset_vector.transform(rotation).to_a.map { |c| c * (@dim_hor_position == 2 ? -@offset_value : @offset_value) }
      dim = entities.add_dimension_linear(pt1, pt2, offset_vector)
      new_instance_path = Sketchup::InstancePath.new(corner_hash[index1][:path].to_a + [corner_hash[index1][:edge]])
      dim.start_attached_to = [new_instance_path, pt1]
      new_instance_path = Sketchup::InstancePath.new(corner_hash[index2][:path].to_a + [corner_hash[index2][:edge]])
      dim.end_attached_to = [new_instance_path, pt2]
      if @dim_hor_position == 1
        dim.set_attribute("su_dimension", "dim_bottom", comp.definition.name)
        else
        dim.set_attribute("su_dimension", "dim_top", comp.definition.name)
      end
      dim.arrow_type = @arrow_type
      dim.layer = @module_dim_layer
    end
    def face_dimension(essence,ipface,dim_layer=nil)
      @dim_type = 1
      dim_layer=@dim_layer if !dim_layer
      dim_layer=@frontal_dim_layer if essence.layer.name == "1_Фасад"
      lenx = essence.get_attribute("dynamic_attributes", "lenx", "0")
      leny = essence.get_attribute("dynamic_attributes", "leny", "0")
      lenz = essence.get_attribute("dynamic_attributes", "lenz", "0")
      if essence.parent.instances[-1].definition.name.include?("Body")
        panel = essence.parent.instances[-1].parent.instances[-1]
        else
        panel = essence.parent.instances[-1]
      end
      napr_texture = "1"
      if panel.definition.get_attribute("dynamic_attributes", "a05_napr")
        napr_texture_att = "a05_napr"
        else
        napr_texture_att = "napr_texture"
      end
      if essence.layer.name != "1_Фасад"
        napr_texture = panel.definition.get_attribute("dynamic_attributes", napr_texture_att)
      end
      essence.definition.delete_attribute("dynamic_attributes", "_dimensions_formula")
      edge = nil
      if @dim_position==1 || @dim_position==3
        if @dim_vert_position == 3
          ipface.edges.each { |e| edge = e if (e.length*25.4).round == (lenz*25.4).round && e.start.position.y == leny }
          else
          ipface.edges.each { |e| edge = e if (e.length*25.4).round == (lenz*25.4).round && e.start.position.y == 0 }
        end
        if edge
          pt1 = Geom::Point3d.new(edge.start.position.x,edge.start.position.y,edge.start.position.z)
          pt2 = Geom::Point3d.new(edge.end.position.x,edge.end.position.y,edge.end.position.z)
          @dim_vert_position == 2 ? offset_value = leny/2 : offset_value = @offset_value
          dim = essence.definition.entities.add_dimension_linear [edge,pt1], [edge,pt2], (@dim_vert_position==3) ? [0, -1*offset_value, 0] : [0, 1*offset_value, 0]
          dim.layer = dim_layer
          dim.arrow_type = @arrow_type
        end
      end
      if @dim_position==2 || @dim_position==3
        edge = nil
        if @dim_hor_position == 3
          ipface.edges.each { |e| edge = e if (e.length*25.4).round == (leny*25.4).round && e.start.position.z == lenz && edge == nil }
          else
          ipface.edges.each { |e| edge = e if (e.length*25.4).round == (leny*25.4).round && e.start.position.z == 0 && edge == nil }
        end
        if edge
          pt1 = Geom::Point3d.new(edge.start.position.x,edge.start.position.y,edge.start.position.z)
          pt2 = Geom::Point3d.new(edge.end.position.x,edge.end.position.y,edge.end.position.z)
          @dim_hor_position == 2 ? offset_value = lenz/2 : offset_value = @offset_value
          dim = essence.definition.entities.add_dimension_linear [edge,pt1], [edge,pt2], (@dim_hor_position==3) ? [0, 0, -1*offset_value] : [0, 0, 1*offset_value]
          dim.layer = dim_layer
          dim.arrow_type = @arrow_type
        end
      end
      bounds = ipface.bounds
      if @dim_position==4
        if @dim_rotation==1
          pt1 = Geom::Point3d.new(bounds.center.x,leny/2-1,lenz/2)
          pt2 = Geom::Point3d.new(bounds.center.x,leny/2+1,lenz/2)
          dim = essence.definition.entities.add_dimension_linear pt1, pt2, [0, 0, 0.1]
          else
          pt1 = Geom::Point3d.new(bounds.center.x,leny/2,lenz/2-1)
          pt2 = Geom::Point3d.new(bounds.center.x,leny/2,lenz/2+1)
          dim = essence.definition.entities.add_dimension_linear pt1, pt2, [0, 0.1, 0]
        end
        if napr_texture == "1"
          dim.text = (lenz*25.4).round.to_s+"x"+(leny*25.4).round.to_s
          else
          dim.text = (leny*25.4).round.to_s+"x"+(lenz*25.4).round.to_s
        end
        dim.layer = dim_layer
        dim.arrow_type = Sketchup::Dimension::ARROW_NONE
        essence.set_attribute("dynamic_attributes", "dimensions",@dim_rotation.to_s)
        essence.definition.set_attribute("dynamic_attributes", "dimensions",@dim_rotation.to_s)
        essence.definition.set_attribute("dynamic_attributes", "_dimensions_label","dimensions")
        essence.definition.set_attribute("dynamic_attributes", "_dimensions_formula", "update_dimension("+@dim_rotation.to_s+")")
      end
    end#def
    def delete_niche_dimensions(comp,points)
      p1 = Geom::Point3d.new(points[0], points[2], points[4]) #left bottom
      p2 = Geom::Point3d.new(points[0], points[2], points[5]) #left top
      p3 = Geom::Point3d.new(points[1], points[2], points[5]) #right top
      p4 = Geom::Point3d.new(points[1], points[2], points[4]) #right bottom
      comp.definition.entities.grep(Sketchup::DimensionLinear).each {|dim|
        if dim.start.include?(p1) && dim.end.include?(p2) || dim.start.include?(p4) && dim.end.include?(p3) || dim.start.include?(p1) && dim.end.include?(p4) || dim.start.include?(p2) && dim.end.include?(p3)
          dim.erase!
        end
      }
    end
    def delete_module_dimensions(model,comp)
      model.entities.grep(Sketchup::DimensionLinear).each {|dim|
        if dim.get_attribute("su_dimension", "dim_left", "0") == comp.definition.name || dim.get_attribute("su_dimension", "dim_right", "0") == comp.definition.name || dim.get_attribute("su_dimension", "dim_bottom", "0") == comp.definition.name || dim.get_attribute("su_dimension", "dim_top", "0") == comp.definition.name
          dim.erase!
        end
      }
    end
    def onLButtonDoubleClick(flags, x, y, view)
      @double_click = true
      if @dimensions_object == 1 && @essence
        @model.start_operation "Delete dimensions", true
        @essence.definition.entities.grep(Sketchup::DimensionLinear).each {|dim| dim.erase! }
        @essence.delete_attribute("dynamic_attributes", "dimensions")
        @essence.definition.delete_attribute("dynamic_attributes", "dimensions")
        @essence.definition.delete_attribute("dynamic_attributes", "_dimensions_label")
        @essence.definition.delete_attribute("dynamic_attributes", "_dimensions_formula")
        @model.commit_operation
        elsif @dimensions_object == 2 && @points != []
        @model.start_operation "Delete dimensions", true
        delete_niche_dimensions(@body,@points)
        @model.commit_operation
        elsif @dimensions_object == 3 && @module
        @model.start_operation "Delete dimensions", true
        delete_module_dimensions(@model,@module)
        @model.commit_operation
      end 
    end#def
    def onKeyDown(key, repeat, flags, view)
      if key==VK_SHIFT 
        @shift_press=true
        elsif key==VK_CONTROL || key==VK_COMMAND
        @control_press=true
        else
        @shift_press = false
        @control_press = false
      end
      view.invalidate
      draw(view)
    end#def
    def make_dimensions
      if @essence && @ipface
        @model.start_operation "Panel dimensions", true
        @essence.definition.entities.grep(Sketchup::DimensionLinear).each {|dim| dim.erase! }
        face_dimension(@essence,@ipface)
        @model.commit_operation
      end
      if @points != []
        @model.start_operation "Niche dimensions", true
        niche_dimensions(@body,@points)
        @model.commit_operation
      end
      if @module
        @model.start_operation "Module dimensions", true
        module_dimensions(@model,@module)
        @model.commit_operation
      end
    end
    def onKeyUp(key, repeat, flags, view)
      if key!=VK_SHIFT
        @shift_press = false if @shift_press
      end
      if key!=VK_CONTROL && key!=VK_COMMAND
        @control_press = false if @control_press
      end
      if key==VK_CONTROL || key==VK_COMMAND
        return if !@control_press
        @dimensions_object > 2 ? max = 3 : max = 4
        @dim_position==max ? @dim_position=1 : @dim_position+=1
        view.invalidate
        draw(view)
        make_dimensions
        save_param
        elsif key==VK_SHIFT
        return if !@shift_press
        @dimensions_object > 2 ? max = 4 : max = 2
        @dim_rotation==max ? @dim_rotation=1 : @dim_rotation+=1
        view.invalidate
        draw(view)
        make_dimensions
        save_param
        elsif key==VK_LEFT
        dim_position = @dim_position
        if @dimensions_object == 3
          @dim_vert_position = 1
          @dim_position = 1
          else
          @dim_vert_position == 1 ? @dim_vert_position = 1 : @dim_vert_position -= 1
        end
        make_dimensions
        @dim_position = dim_position
        save_param
        elsif key==VK_RIGHT
        dim_position = @dim_position
        if @dimensions_object == 3
          @dim_vert_position = 2
          @dim_position = 1
          else
          @dim_vert_position > 2 ? @dim_vert_position = 1 : @dim_vert_position += 1
        end
        make_dimensions
        @dim_position = dim_position
        save_param
        elsif key==VK_UP
        dim_position = @dim_position
        if @dimensions_object == 3
          @dim_hor_position = 2
          @dim_position = 2
          else
          @dim_hor_position > 2 ? @dim_hor_position = 1 : @dim_hor_position += 1
        end
        make_dimensions
        @dim_position = dim_position
        save_param
        elsif key==VK_DOWN
        dim_position = @dim_position
        if @dimensions_object == 3
          @dim_hor_position = 1
          @dim_position = 2
          else
          @dim_hor_position == 1 ? @dim_hor_position = 3 : @dim_hor_position -= 1
        end
        make_dimensions
        @dim_position = dim_position
        save_param
        elsif ( key==9 || ((key==15 || key==48) && (RUBY_PLATFORM.include?('darwin'))))
        if @arrow_type == Sketchup::Dimension::ARROW_CLOSED
          @arrow_type = Sketchup::Dimension::ARROW_OPEN
          @content[0] = 2
          elsif @arrow_type == Sketchup::Dimension::ARROW_OPEN
          @arrow_type = Sketchup::Dimension::ARROW_NONE
          @content[0] = 3
          elsif @arrow_type == Sketchup::Dimension::ARROW_NONE
          @arrow_type = Sketchup::Dimension::ARROW_SLASH
          @content[0] = 4
          elsif @arrow_type == Sketchup::Dimension::ARROW_SLASH
          @arrow_type = Sketchup::Dimension::ARROW_DOT
          @content[0] = 5
          else
          @arrow_type = Sketchup::Dimension::ARROW_CLOSED
          @content[0] = 1
        end
        make_dimensions
        save_param
      end
    end#def
    def save_param
      @content[1] = @dim_position
      @content[2] = @dim_rotation
      @content[3] = @dim_vert_position
      @content[4] = @dim_hor_position
      @content[5] = @dimensions_object
      param_file = File.new(TEMP_PATH+"/SUF/dimensions.dat","w")
      @back_frontal_dimensions ? @content[6] = 1 : @content[6] = 0
      @content.each { |i| param_file.puts i }
      param_file.close
    end
    def onUserText(text, view)
      if text.to_f == 0
        @offset_value = 0.1
        else
        @offset_value=text.to_f/25.4
      end
      rescue ArgumentError
      view.tooltip = 'Invalid length'
    end#def
    def onCancel(reason, view)
      if reason == 2
        @model.commit_operation
      end
    end#def
    def resume(view)
      @shift_press = false if @shift_press
      view.invalidate
      draw(view)
    end#def
    def onSetCursor
      UI.set_cursor(633)
    end#def
    def reset(view=nil)
      view.lock_inference if view && view.inference_locked?
    end#def
    def enableVCB?
      return true
    end
  end#Class
end#Module
