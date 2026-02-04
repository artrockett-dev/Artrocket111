module SU_Furniture
  class WithoutFastener
    def initialize()
      @y_offset = (OSX ? 10 : 0)
      @text_default_options = {
        color: "gray",
        font: 'Verdana',
        size: (OSX ? 20 : 13),
        align: TextAlignLeft,
        bold: false
      }
      @button_text_options = {
        color: "black",
        font: 'Verdana',
        size: (OSX ? 20 : 13),
        align: TextAlignRight
      }
    end#def
    def activate
      @model=Sketchup.active_model
      @sel=@model.selection
      @sel.remove_observer $SUFSelectionObserver
      read_draw_param
      @sel.clear
      view = @model.active_view
      @ents = @model.entities
      @ip=Sketchup::InputPoint.new
      @screen_x=0
      @screen_y=0
      self.reset(view)
    end#def
    def read_draw_param
      @draw_param = []
      if File.file?( TEMP_PATH+"/SUF/draw_options.dat")
        path = TEMP_PATH+"/SUF/draw_options.dat"
        else
        path = PATH + "/parameters/draw_options.dat"
      end
      content = File.readlines(path)
      content.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
      content.each { |i| @draw_param << i }
    end#def
    def deactivate(view)
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
      end
			@sel.clear
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
      view.line_width=2
      view.drawing_color = "gray"
      button_width = pix_pt(110)
      case @draw_param[0]
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth-25;x1=x-button_width;x2=x+5;y=25;@button_text_options[:align] = TextAlignRight
				when "#{SUF_STRINGS["Right"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth-25;x1=x-button_width;x2=x+5;y=view.vpheight-50;@button_text_options[:align] = TextAlignRight
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["below the list"]}" then x=30;x1=x-5;x2=x+button_width;y+=30;@button_text_options[:align] = TextAlignLeft
				when "#{SUF_STRINGS["Left"]} #{SUF_STRINGS["Bottom"]}" then x=30;x1=x-5;x2=x+button_width;y=view.vpheight-50;@button_text_options[:align] = TextAlignLeft
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Top"]}" then x=view.vpwidth/2;x1=x-button_width/2;x2=x+button_width/2;y=60;@button_text_options[:align] = TextAlignCenter
				when "#{SUF_STRINGS["Centered"]} #{SUF_STRINGS["Bottom"]}" then x=view.vpwidth/2;x1=x-button_width/2;x2=x+button_width/2;y=view.vpheight-50;@button_text_options[:align] = TextAlignCenter
				else x=view.vpwidth-25;x1=x-button_width;x2=x+5;y=80;@button_text_options[:align] = TextAlignRight
			end
      
      @exit = false
      if @screen_x > x1 && @screen_x < x2 && @screen_y > y-4 && @screen_y < y+20+@y_offset
        view.drawing_color = "black"
        @exit = true
      end
      @button_text_options[:bold] = @exit
      draw_text(view,Geom::Point3d.new(x, y, 0), SUF_STRINGS["Exit"], @button_text_options )
      view.draw2d(GL_LINE_LOOP, [ Geom::Point3d.new(x1, y-4, 0), Geom::Point3d.new(x2, y-4, 0), Geom::Point3d.new(x2, y+20+@y_offset, 0), Geom::Point3d.new(x1, y+20+@y_offset, 0) ])
    end#def
    def onMouseMove(flags, x, y, view)
      @screen_x = x
      @screen_y = y
      @ip.pick view,x,y
      @face_type = nil
      @essence = nil
      @sel.clear
      Sketchup::set_status_text SUF_STRINGS["Hover over the panel"]
      if (@ip.valid?)
        @ipface=nil if @sel.length==0
        if @ip.face && @ip.face.parent.is_a?(Sketchup::ComponentDefinition)
          comp = @ip.face.parent.instances[0]
          if comp.definition.name.include?("Essence") || comp.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
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
            comp.make_unique if comp.definition.count_instances > 1
            comp.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if comp.parent.is_a?(Sketchup::ComponentDefinition)
          end
        end
        view.invalidate
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
      if @exit
        @model.select_tool( Fasteners_Panel )
        elsif @essence
        @model.start_operation "Without fastener", true
        f_c = @ipface.bounds.center
        @essence.definition.entities.grep(Sketchup::Group).each {|group| group.erase! if group.name == "without_fastener" || group.name == "visible_side" || group.name == "error_fastener" || group.layer.name.include?("fastener") }
        if @essence.definition.get_attribute("dynamic_attributes", "without_fastener")
          @essence.definition.delete_attribute("dynamic_attributes", "without_fastener")
					@essence.definition.entities.grep(Sketchup::Face).each{|f| f.delete_attribute("dynamic_attributes", "without_fastener")}
          else
          @essence.definition.delete_attribute("dynamic_attributes", "visible_side")
          @ipface.delete_attribute("dynamic_attributes", "visible_side")
          @ipface.delete_attribute("dynamic_attributes", "without_fastener")
          @ipface.set_attribute("dynamic_attributes", "without_fastener",f_c.x)
					if @ipface.bounds.max.y < 2.4 || @ipface.bounds.max.z < 2.4
            height = [@ipface.bounds.max.y,@ipface.bounds.max.z].min-0.1
            else
            height = 4
          end
          add_text(@essence,f_c,"w",height)
          @essence.definition.set_attribute("dynamic_attributes", "without_fastener", f_c.x)
        end
        @model.commit_operation
      end
    end#def
		def add_text(essence,f_c,text,height)
		  group=essence.definition.entities.add_group
			group.layer = @model.layers.add "Z_fastener_text"
			group.entities.add_3d_text(text, TextAlignCenter, "Arial", false, false, height, 0.0, 0.0, false, 0.0)
			bounds = group.bounds
			proportion = bounds.width/bounds.height
			group.set_attribute('dynamic_attributes', "_lengthunits", "CENTIMETERS")
			set_att(group,"lenx",height,"LenX",'LenY*' + proportion.to_s)
			set_att(group,"leny",height,"LenY",height.to_s)
			group.move!([f_c.x-group.bounds.max.x/2,f_c.y-group.bounds.max.y/2,f_c.z])
			#group.transform! Geom::Transformation.rotation(@ipface.bounds.center, Geom::Vector3d.new(1, 0, 0), 90.degrees)
			group.transform! Geom::Transformation.rotation(f_c, Geom::Vector3d.new(0, 1, 0), 90.degrees)
			group.transform! Geom::Transformation.rotation(f_c, Geom::Vector3d.new(1, 0, 0), 180.degrees)
			group.name = "without_fastener"
			group.material = "black"
			group.entities.each { |face| face.reverse! if face.is_a?(Sketchup::Face) }
			DCProgressBar::clear()
			Redraw_Components.redraw(group,false)
			DCProgressBar::clear()
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
		def set_att(e,att,value,label=nil,formula=nil)
      e.set_attribute('dynamic_attributes', att, value) if att
      e.set_attribute('dynamic_attributes', "_"+att+"_label", label) if label
      e.set_attribute('dynamic_attributes', "_"+att+"_formula", formula) if formula
    end#def
  end#Class
end#Module
