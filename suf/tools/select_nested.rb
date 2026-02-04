module SU_Furniture
  class SelectNested
    def initialize
      @shift_press = false
      @control_press = false
      @offset_x = (OSX ? 8 : 0)
      @offset_y = (OSX ? 8 : 0)
      @size_x = (OSX ? 20 : 10)
      @line_black_text_options = {
        color: Sketchup::Color.new(0, 0, 0),
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft
      }
      @line_black_bold_text_options = {
        color: Sketchup::Color.new(0, 0, 0),
        font: 'Verdana',
        size: @text_size,
        align: TextAlignLeft,
        bold: true
      }
    end
    def activate
      @model = Sketchup.active_model
      @sel = @model.selection
      @activate = true
      @tab = false
      @select_draw_comp = nil
      @table_of_comp = []
      @comp_for_table = nil
      @shift_press = false
      @control_press = false
      @model.start_operation "layers", true, false, true
      @model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") || l.name.include?("Z_Edge") }
      @model.commit_operation
    end
    def deactivate(view)
      @activate = false
      @tab = false
      @shift_press = false
      @control_press = false
      view.invalidate
    end
    def resume(view)
      view.invalidate
    end
    def onSetCursor
      UI.set_cursor(633)
    end
    def draw_row(view,text,x,width,y,height,text_style)
      view.drawing_color = "black"
      @button_points = [
        Geom::Point3d.new(x, y+@offset_y, 0),
        Geom::Point3d.new(x+width, y+@offset_y, 0),
        Geom::Point3d.new(x+width, y+height+@offset_y, 0),
        Geom::Point3d.new(x, y+height+@offset_y, 0)
      ]
      view.draw2d(GL_LINE_LOOP, @button_points)
      view.drawing_color = "orange"
      @button_points = [
        Geom::Point3d.new(x+1, y+1+@offset_y, 0),
        Geom::Point3d.new(x-1+width, y+1+@offset_y, 0),
        Geom::Point3d.new(x-1+width, y-1+height+@offset_y, 0),
        Geom::Point3d.new(x+1, y-1+height+@offset_y, 0)
      ]
      view.draw2d(GL_QUADS, @button_points)
      view.drawing_color = "black"
      view.draw_text(Geom::Point3d.new(x+5, y+2, 0), text, text_style)
    end
    def draw(view)
      view.draw_text(Geom::Point3d.new(30, 25, 0), SUF_STRINGS["Press Tab to view components with attributes"], @line_black_text_options)
      view.draw_text(Geom::Point3d.new(30, 55, 0), SUF_STRINGS["Double-clicked to go inside to the component"], @line_black_text_options)
      if @tab && @table_of_comp != [] && !@table_of_comp.map{|comp|comp.deleted?}.include?(true)
        @comp_to_select = nil
        y = @y
        height = 20
        width = (@table_of_comp.max_by {|comp|comp.definition.name.length }).definition.name.length*@size_x
        @table_of_comp.each {|comp|
          if @screen_x > @x+10+@offset_x*10 && @screen_x < @x+width+@offset_x*10 && @screen_y > y && @screen_y < y+height
            if @select_draw_comp
              if @select_draw_comp != comp
                if @sel.include?(@select_draw_comp)
                  @sel.remove(@select_draw_comp)
                  @select_draw_comp = comp
                  @sel.add @select_draw_comp
                  else
                  @select_draw_comp = comp
                  @sel.add @select_draw_comp
                end
              end
              elsif @select_draw_comp != comp
              @select_draw_comp = comp
              @sel.add @select_draw_comp
            end
            @comp_to_select = comp
            draw_row(view,comp.definition.name,@x,width,y,height,@line_black_bold_text_options)
            else
            draw_row(view,comp.definition.name,@x,width,y,height,@line_black_text_options)
          end
          y+=height
        }
        if @screen_x < @x+10+@offset_x*10 || @screen_x > @x+width+@offset_x*10 || @screen_y < @y || @screen_y > @y+height*@table_of_comp.length
          @select_draw_comp = nil
          if !@control_press && !@shift_press && @sel.length != 0
            @sel.clear
          end
        end
      end
    end
    def onMouseMove(flags, x, y, view)
      @screen_x = x
      @screen_y = y
      ph = view.pick_helper
      ph.do_pick x,y
      pick_list = ph.path_at(0)
      @select_essence = false
      @comp_with_att = []
      @table_of_comp = [] if @table_of_comp.map{|comp|comp.deleted?}.include?(true)
      if (pick_list != nil)
        for i in 0..pick_list.length-1
          entity = pick_list[i]
          if entity.is_a?(Sketchup::ComponentInstance)
            make_unique_if_needed(entity)
            if entity.parent.is_a?(Sketchup::ComponentDefinition)
							if entity.definition.name.include?("Essence") || entity.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
								@select_essence = true
								if entity.parent.name.include?("Body")
									@new_entity = entity.parent.instances[0].parent.instances[0]
									else
									@new_entity = entity.parent.instances[0]
                end
								all_comp = [@new_entity] + search_parent(@new_entity)
								all_comp.reverse_each { |ent|
									dict = ent.definition.attribute_dictionary "dynamic_attributes"
									if dict
										att = false
										dict.each_pair {|attr, v|
											access = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_access", "NONE")
											formlabel = ent.definition.get_attribute("dynamic_attributes", "_" + attr + "_formlabel")
											att = true if access != "NONE" && formlabel
                    }
										@comp_with_att << ent if att == true
                  end
                } 
								if !@tab
									msg = @new_entity.definition.name
									a03_name = @new_entity.definition.get_attribute("dynamic_attributes","a03_name")
									msg += +"\n   Name: "+a03_name if a03_name
									su_type = @new_entity.definition.get_attribute("dynamic_attributes","su_type")
									if su_type
										case su_type
											when "frontal" then su_type = "Фасад"
											when "carcass" then su_type = "Каркас"
											when "back" then su_type = "Задняя_стенка"
                      when "glass" then su_type = "Стекло"
                      when "furniture" then su_type = "Фурнитура"
                    end
                    msg += +"\n   Type: "+su_type
                  end
                  msg += +"\n   Tag: "+entity.layer.name
                  Sketchup.active_model.active_view.tooltip = '   ' + msg
                end
              end
            end
          end
        end
      end
      Sketchup::set_status_text SUF_STRINGS["Click to select objects. Shift = Add/Subtract. Ctrl = Add."]
      view.invalidate
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
    def onLButtonDown(flags, x, y, view)
      if @tab && @comp_to_select != nil
        select_entity(@comp_to_select)
        @tab = false
        view.invalidate
        draw(view)
        elsif @select_essence
        select_entity(@new_entity)
        @tab = false
        elsif !@control_press && !@shift_press
        @sel.clear
        @tab = false
        if(Sketchup.version.to_i >= 20)
          Sketchup.active_model.active_path = nil
        end
      end
      onMouseMove(flags, x, y, view)
    end
    def select_entity(entity)
      if !@control_press && !@shift_press
        @sel.clear
        @sel.add entity
        elsif @shift_press == true
        if @sel.length > 1 && @sel.include?(entity)
          @sel.remove entity
          else
          @sel.add entity
        end
        elsif @control_press == true
        @sel.add entity
      end
    end
    def onLButtonDoubleClick(flags, x, y, view)
      @sel.clear
      if @select_essence
        if(Sketchup.version.to_i >= 20)
          instance = @new_entity
          parent = instance.parent
          if !parent.to_s.include?("Sketchup::Model")
            if !@model.active_path
              @model.start_operation "active_path", true, false, true
              arr_comp = []
              all_comp = search_parent(instance)
              all_comp.reverse.each { |comp|
                arr_comp += [comp]
                @model.selection.clear
                @model.selection.add comp
                @model.active_path = arr_comp
              }
              @model.selection.clear
              @model.selection.add @new_entity
              @model.commit_operation
            end
            else
            @model.selection.add @new_entity
          end
        end
      end
      onMouseMove(flags, x, y, view)
    end
    def onKeyDown(key, repeat, flags, view)
      if key==VK_SHIFT 
        @shift_press=true
        elsif key==VK_CONTROL || key==VK_COMMAND
        @control_press=true
        elsif ( key==9 || ((key==15 || key==48) && (RUBY_PLATFORM.include?('darwin'))))
        if @comp_with_att != []
          if @comp_with_att[-1] == @comp_for_table
            @tab ? @tab = false : @tab = true
            @x = @screen_x
            @y = @screen_y
            else
            @tab = true
            @x = @screen_x
            @y = @screen_y
            @table_of_comp = @comp_with_att
            @comp_for_table = @comp_with_att[-1]
          end
          view.invalidate
          Sketchup.active_model.active_view.tooltip = ''
          draw(view)
        end
      end
    end
    def onKeyUp(key, repeat, flags, view)
      if key==VK_DELETE
        @tab = false
        elsif key==VK_SHIFT
        @shift_press=false
        view.lock_inference if view.inference_locked?
        elsif key==VK_CONTROL || key==VK_COMMAND
        @control_press=false
        view.lock_inference if view.inference_locked?
      end
    end
  end # Class
end
