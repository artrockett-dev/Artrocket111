module SU_Furniture
  class TrimPanel
    def initialize()
      @text_size = (OSX ? 20 : 13)
      @text_indent = (OSX ? 15 : 9)
      @y_offset = (OSX ? 10 : 0)
      @shift_press=false
			@shift_key_down=false
      @control_press=false
			@control_key_down=false
      @trim_value = 0
			@last_tool_name = ''
		end#def
    def activate
      @model=Sketchup.active_model
      @sel=@model.selection
      @sel.remove_observer $SUFSelectionObserver
      read_param
      @comp = nil
      @cancel = false
      @hide_face_button = false
      @ent=@model.entities
      Sketchup.active_model.layers.add("Z_Face")
	    @ent.grep(Sketchup::ComponentInstance).to_a.each { |ent| face_layer(ent) }
      @sel.clear
      view = @model.active_view
      @ents = @model.entities
      @ip=Sketchup::InputPoint.new
      @screen_x=0
      @screen_y=0
      @line_black_text_options = {
        color: "gray",
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
      @model.start_operation "layers", true, false, true
      @model.layers.each { |l|
        if l.name.include?("Z_Face")
          @hide_face == "yes" ? l.visible = false : l.visible = true
				end
        l.visible = false if l.name.include?("Толщина_кромки") && l.visible? == true
			}
      @model.commit_operation
      self.reset(view)
      Sketchup::set_status_text("Новый Отступ ", SB_VCB_LABEL)
      Sketchup::set_status_text(@trim_value.to_s+" mm", SB_VCB_VALUE)
		end#def
    def read_param
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
			}
		end#def
    def face_layer(unit)
      if unit.definition.name.include?("Essence") || unit.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
        unit.definition.entities.grep(Sketchup::Face).each { |f|
          face = f.get_attribute("dynamic_attributes", "face", "0")
          f.layer = "Z_Face" if face.include?("primary")
				}
			end
      unit.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| face_layer(ent) } 
		end#def
    def deactivate(view)
      @model.layers.each { |l| l.visible = true if l.name.include?("Z_Face") }
      @sel.clear
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
			end
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
    def draw(view)
      hide_face_text = "Tab - Скрывать пласть панелей"
      hide_face_text = "Tab - Не скрывать пласть панелей" if @hide_face == "no"
      if @screen_x > 15 && @screen_x < 290 && @screen_y > 10 && @screen_y < 40
        draw_text(view,Geom::Point3d.new(25, 25, 0), hide_face_text, @line_black_bold_text_options)
        @hide_face_button = true
        else
        draw_text(view,Geom::Point3d.new(25, 25, 0), hide_face_text, @line_black_text_options)
        @hide_face_button = false
			end
      draw_text(view,Geom::Point3d.new(25, 55+@y_offset, 0), "Shift - "+(@shift_press==true ? "Увеличить" : "Изменить")+" отступ на новое значение", @line_black_text_options)
      draw_text(view,Geom::Point3d.new(25, 85+@y_offset*2, 0), (OSX ? "Cmd" : "Ctrl")+" - Отступ "+(@control_press==true ? "Секции" : "Панели"), @line_black_text_options)
      Sketchup::set_status_text(@trim_value.to_s+" mm", SB_VCB_VALUE)
		end#def
    def onMouseMove(flags, x, y, view)
      @screen_x = x
      @screen_y = y
      @ip.pick view,x,y
      @face_type = nil
      @sel.clear
      Sketchup::set_status_text "Наведите на торец панели"
      if (@ip.valid?)
        @ipface=nil if @sel.length==0
        if @ip.face
          @face_type = @ip.face.get_attribute("dynamic_attributes", "face")
          if @face_type && @face_type != "primary"
            @model.start_operation "make_unique", true, false, true
            @ip.face.parent.instances.each { |instance| make_unique_if_needed(instance) }
            @model.commit_operation
            if @control_press==false
              @sel.add @ip.face
              @sel.add @ip.face.edges
              @comp = nil
              @ip.face.parent.instances.each {|essence|
                if essence.parent.instances != []
                  if essence.parent.instances[0].definition.name.include?("Body")
                    @comp = essence.parent.instances[0].parent.instances[0]
                    else
                    @comp = essence.parent.instances[0]
									end
								end
							}
              trim = 0
              if @comp
                if @face_type.include?("front")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_z1", "0")
                  elsif @face_type.include?("rear")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_z2", "0")
                  elsif @face_type.include?("up")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_y1", "0")
                  elsif @face_type.include?("down")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_y2", "0")
								end
                trim=(trim.to_f*25.4).round(1)
                trim=trim.round if trim.to_s[-1] == "0"
                Sketchup.active_model.active_view.tooltip = '   Текущий Отступ ' + trim.to_s + ' мм'
                Sketchup::set_status_text "Текущий Отступ "+(@control_press==true ? "секции " : "панели ")+(trim.to_f).round.to_s+" mm | Нажмите для "+(@shift_press==true ? "увеличения" : "изменения")+" отступа на "+(@trim_value).round.to_s+" mm"
							end
              else
              trim = 0
              @section_comp = []
              search_section(@ip.face.parent.instances[0])
              if @section_comp != []
                @comp = @section_comp[-1]
                @sel.add @comp
                if @face_type.include?("front")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_y1", "0")
                  elsif @face_type.include?("rear")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_y2", "0")
                  elsif @face_type.include?("up")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_x2", "0")
                  elsif @face_type.include?("down")
                  trim = @comp.definition.get_attribute("dynamic_attributes", "trim_x1", "0")
								end
                Sketchup.active_model.active_view.tooltip = '   Отступ ' + (trim.to_f*25.4).round.to_s + ' мм'
                Sketchup::set_status_text "Текущий Отступ "+(@control_press==true ? "секции " : "панели ")+(trim.to_f*25.4).round.to_s+" mm | Нажмите для "+(@shift_press==true ? "увеличения" : "изменения")+" отступа на "+(@trim_value).round.to_s+" mm"
							end
						end
					end
				end
        view.invalidate
			end
		end#def
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
    def search_section(entity)
      if entity.parent.is_a?(Sketchup::ComponentDefinition)
        if entity.parent.instances[0]
          if entity.parent.instances[0].definition.name.include?("Секция")
            @section_comp << entity.parent.instances[0]
            return 
					end
          search_section(entity.parent.instances[0])
				end
			end
		end#def
    def onLButtonDown(flags, x, y, view)
      if @hide_face_button == true
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
        @model.layers.each { |l|
          if l.name.include?("Z_Face")
            @hide_face == "yes" ? l.visible = false : l.visible = true
					end
				}
        @model.commit_operation
        view.invalidate
        draw(view)
        elsif @face_type && @face_type != "primary" && @comp
        @model.start_operation "Trim", true
        if @control_press==false
          trim_z1_text = "trim_z1"
          trim_z2_text = "trim_z2"
          trim_y1_text = "trim_y1"
          trim_y2_text = "trim_y2"
          else
          trim_z1_text = "trim_y1"
          trim_z2_text = "trim_y2"
          trim_y1_text = "trim_x2"
          trim_y2_text = "trim_x1"
				end
        if @face_type.include?("front")
          @comp.definition.delete_attribute("dynamic_attributes", "_"+trim_z1_text+"_formula")
          trim_z1 = @comp.definition.get_attribute("dynamic_attributes", trim_z1_text, 0)
          if @shift_press==true
            @comp.definition.set_attribute("dynamic_attributes", trim_z1_text, trim_z1.to_f+@trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_z1_text, trim_z1.to_f+@trim_value/25.4)
            else
            @comp.definition.set_attribute("dynamic_attributes", trim_z1_text, @trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_z1_text, @trim_value/25.4)
					end
          elsif @face_type.include?("rear")
          @comp.definition.delete_attribute("dynamic_attributes", "_"+trim_z2_text+"_formula")
          trim_z2 = @comp.definition.get_attribute("dynamic_attributes", trim_z2_text, 0)
          if @shift_press==true
            @comp.definition.set_attribute("dynamic_attributes", trim_z2_text, trim_z2.to_f+@trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_z2_text, trim_z2.to_f+@trim_value/25.4)
            else
            @comp.definition.set_attribute("dynamic_attributes", trim_z2_text, @trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_z2_text, @trim_value/25.4)
					end
          elsif @face_type.include?("up")
          @comp.definition.delete_attribute("dynamic_attributes", "_"+trim_y1_text+"_formula")
          trim_y1 = @comp.definition.get_attribute("dynamic_attributes", trim_y1_text, 0)
          if @shift_press==true
            @comp.definition.set_attribute("dynamic_attributes", trim_y1_text, trim_y1.to_f+@trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_y1_text, trim_y1.to_f+@trim_value/25.4)
            else
            @comp.definition.set_attribute("dynamic_attributes", trim_y1_text, @trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_y1_text, @trim_value/25.4)
					end
          elsif @face_type.include?("down")
          @comp.definition.delete_attribute("dynamic_attributes", "_"+trim_y2_text+"_formula")
          trim_y2 = @comp.definition.get_attribute("dynamic_attributes", trim_y2_text, 0)
          if @shift_press==true
            @comp.definition.set_attribute("dynamic_attributes", trim_y2_text, trim_y2.to_f+@trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_y2_text, trim_y2.to_f+@trim_value/25.4)
            else
            @comp.definition.set_attribute("dynamic_attributes", trim_y2_text, @trim_value/25.4)
            @comp.set_attribute("dynamic_attributes", trim_y2_text, @trim_value/25.4)
					end
				end
        Redraw_Components.redraw_entities_with_Progress_Bar([@comp])
        @model.commit_operation
        @model.start_operation "faces", true, false, true
        face_layer(@comp)
        @model.commit_operation
			end
		end#def
    def enableVCB?
      return true
		end
    def onUserText(text, view)
      text = text.gsub(",",".")
      text=text.to_f.round(1)
      text=text.round if text.to_s[-1] == "0"
      @trim_value=text
      view.invalidate
      draw(view)
      rescue ArgumentError
      view.tooltip = 'Invalid length'
		end#def
    def onKeyDown(key, repeat, flags, view)
			if key==VK_SHIFT
				@shift_key_down=true
				elsif key==VK_CONTROL || key==VK_COMMAND
				@control_key_down=true
			end
		end#def
    def onKeyUp(key, repeat, flags, view)
			@shift_key_down=false
			@control_key_down=false
			if @last_tool_name == "CameraOrbitTool"
			  @last_tool_name = $SUFToolsObserver.last_tool_name
			  return
			end
      if key==VK_SHIFT
        @shift_press==false ? @shift_press=true : @shift_press=false
        view.invalidate
        draw(view)
        onMouseMove(flags, @screen_x, @screen_y, view)
        elsif key==VK_CONTROL || key==VK_COMMAND
        if !@cancel
          @control_press==false ? @control_press=true : @control_press=false
          view.invalidate
          draw(view)
          onMouseMove(flags, @screen_x, @screen_y, view)
				end
        @cancel = false
        elsif ( key==9 || ((key==15 || key==48) && (RUBY_PLATFORM.include?('darwin'))))
        @hide_face == "yes" ? @hide_face = "no" : @hide_face = "yes"
        @model.start_operation "layers", true, false, true
        @model.layers.each { |l|
          if l.name.include?("Z_Face")
            @hide_face == "yes" ? l.visible = false : l.visible = true
					end
				}
				view.invalidate
				@model.commit_operation
			end
		end#def
    def onCancel(reason, view)
      if reason == 2
        @cancel = true
        @model.commit_operation
			end
		end#def
    def resume(view)
			if @shift_key_down || @control_key_down
			  @last_tool_name = $SUFToolsObserver.last_tool_name
			end
      Sketchup::set_status_text("Новый Отступ ", SB_VCB_LABEL)
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
