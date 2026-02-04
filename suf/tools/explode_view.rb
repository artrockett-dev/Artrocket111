module SU_Furniture
  class ExplodeView
    def initialize()
      @text_header_size = (OSX ? 16 : 10)
      @text_indent = (OSX ? 15 : 9)
      @text_size = (OSX ? 14 : 8)
      @coef = (OSX ? 4 : 0)
      @points = {}
    end
    def activate
      @model=Sketchup.active_model
      @model.start_operation "Explode View", true
      view = @model.active_view
      @ents = @model.entities.to_a
      @screen_x=0
      @screen_y=0
      @state=0
      @object_array = false
      @center_selec = nil
      @dist_x=view.vpwidth-290 if !@dist_x
      @dist_y=view.vpwidth-290 if !@dist_y
      @dist_z=view.vpwidth-290 if !@dist_z
      @exit_button=false
      @ip=Sketchup::InputPoint.new
      @reset_border_points = [
        Geom::Point3d.new(view.vpwidth-300, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-200, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-200, view.vpheight-40, 0),
        Geom::Point3d.new(view.vpwidth-300, view.vpheight-40, 0)
      ]
      @reset_button_points = [
        Geom::Point3d.new(view.vpwidth-300, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-200, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-200, view.vpheight-40, 0),
        Geom::Point3d.new(view.vpwidth-300, view.vpheight-40, 0)
      ]
      @exit_border_points = [
        Geom::Point3d.new(view.vpwidth-150, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-50, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-50, view.vpheight-40, 0),
        Geom::Point3d.new(view.vpwidth-150, view.vpheight-40, 0)
      ]
      @exit_button_points = [
        Geom::Point3d.new(view.vpwidth-150, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-50, view.vpheight-62, 0),
        Geom::Point3d.new(view.vpwidth-50, view.vpheight-40, 0),
        Geom::Point3d.new(view.vpwidth-150, view.vpheight-40, 0)
      ]
      self.reset(view)
    end
    def deactivate(view)
      @model.commit_operation
    end
    def draw(view)
      @x_button=false
      @y_button=false
      @z_button=false
      @exit_button=false
      @reset_button=false
      @exit_text_color = "gray"
      @reset_text_color = "gray"
      view.drawing_color = "gray"
      @x_color = "gray"
      @y_color = "gray"
      @z_color = "gray"
      view.line_width=2
      if @screen_x < view.vpwidth-200 && @screen_x > view.vpwidth-300 && @screen_y > view.vpheight-62 && @screen_y < view.vpheight-40
        @reset_text_color = "white"
        view.draw2d(GL_QUADS, @reset_button_points)
        @reset_button=true
        elsif @screen_x < view.vpwidth-50 && @screen_x > view.vpwidth-150 && @screen_y > view.vpheight-62 && @screen_y < view.vpheight-40
        @exit_text_color = "white"
        view.draw2d(GL_QUADS, @exit_button_points)
        @exit_button=true
        elsif @screen_x > @dist_x-5 && @screen_x < @dist_x+5 && @screen_y > view.vpheight-190 && @screen_y < view.vpheight-170
        @x_color = "red"
        @x_button=true
        elsif @screen_x > @dist_y-5 && @screen_x < @dist_y+5 && @screen_y > view.vpheight-150 && @screen_y < view.vpheight-130
        @y_color = Sketchup::Color.new(0, 200, 0)
        @y_button=true
        elsif @screen_x > @dist_z-5 && @screen_x < @dist_z+5 && @screen_y > view.vpheight-110 && @screen_y < view.vpheight-90
        @z_color = "blue"
        @z_button=true
      end
      view.line_width=1
      
      view.drawing_color = @x_color
      @text_options = {
        color: @x_color,
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      view.draw_text(Geom::Point3d.new(view.vpwidth-315, view.vpheight-180-@text_indent, 0), "X", @text_options) #x
      view.draw2d(GL_LINES, [Geom::Point3d.new(view.vpwidth-300, view.vpheight-180, 0),
      Geom::Point3d.new(view.vpwidth-50, view.vpheight-180, 0)])
      @x_points = [
        Geom::Point3d.new(@dist_x-5, view.vpheight-190, 0),
        Geom::Point3d.new(@dist_x+5, view.vpheight-190, 0),
        Geom::Point3d.new(@dist_x+5, view.vpheight-170, 0),
        Geom::Point3d.new(@dist_x-5, view.vpheight-170, 0)
      ]
      view.draw2d(GL_QUADS, @x_points)
      
      view.drawing_color = @y_color
      @text_options = {
        color: @y_color,
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      view.draw_text(Geom::Point3d.new(view.vpwidth-315, view.vpheight-140-@text_indent, 0), "Y", @text_options) #y
      view.draw2d(GL_LINES, [Geom::Point3d.new(view.vpwidth-300, view.vpheight-140, 0),
      Geom::Point3d.new(view.vpwidth-50, view.vpheight-140, 0)])
      @y_points = [
        Geom::Point3d.new(@dist_y-5, view.vpheight-150, 0),
        Geom::Point3d.new(@dist_y+5, view.vpheight-150, 0),
        Geom::Point3d.new(@dist_y+5, view.vpheight-130, 0),
        Geom::Point3d.new(@dist_y-5, view.vpheight-130, 0)
      ]
      view.draw2d(GL_QUADS, @y_points)
      
      view.drawing_color = @z_color
      @text_options = {
        color: @z_color,
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      view.draw_text(Geom::Point3d.new(view.vpwidth-315, view.vpheight-100-@text_indent, 0), "Z", @text_options) #z
      view.draw2d(GL_LINES, [Geom::Point3d.new(view.vpwidth-300, view.vpheight-100, 0),
      Geom::Point3d.new(view.vpwidth-50, view.vpheight-100, 0)])
      @z_points = [
        Geom::Point3d.new(@dist_z-5, view.vpheight-110, 0),
        Geom::Point3d.new(@dist_z+5, view.vpheight-110, 0),
        Geom::Point3d.new(@dist_z+5, view.vpheight-90, 0),
        Geom::Point3d.new(@dist_z-5, view.vpheight-90, 0)
      ]
      view.draw2d(GL_QUADS, @z_points)
      
      view.drawing_color = "gray"
      @reset_text_options = {
        color: @reset_text_color,
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      @exit_text_options = {
        color: @exit_text_color,
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignCenter
      }
      view.draw_text(Geom::Point3d.new(view.vpwidth-250, view.vpheight-60-@coef, 0), SUF_STRINGS["Reset"], @reset_text_options)
      view.draw2d(GL_LINE_LOOP, @reset_border_points)
      view.draw_text(Geom::Point3d.new(view.vpwidth-100, view.vpheight-60-@coef, 0), SUF_STRINGS["Exit"], @exit_text_options)
      view.draw2d(GL_LINE_LOOP, @exit_border_points)
      
    end
    def onMouseMove(flags, x, y, view)
      @screen_x = x
      @screen_y = y
      @ip.pick view,x,y
      if @x_edit
        if @screen_x < view.vpwidth-290
          @dist_x = view.vpwidth-290
          elsif @screen_x > view.vpwidth-60
          @dist_x = view.vpwidth-60
          else
          @dist_x = @screen_x
        end
        explode_view(view.vpwidth-290-@dist_x, view.vpwidth-290-@dist_y, view.vpwidth-290-@dist_z)
        elsif @y_edit
        if @screen_x < view.vpwidth-290
          @dist_y = view.vpwidth-290
          elsif @screen_x > view.vpwidth-60
          @dist_y = view.vpwidth-60
          else
          @dist_y = @screen_x
        end
        explode_view(view.vpwidth-290-@dist_x, view.vpwidth-290-@dist_y, view.vpwidth-290-@dist_z)
        elsif @z_edit
        if @screen_x < view.vpwidth-290
          @dist_z = view.vpwidth-290
          elsif @screen_x > view.vpwidth-60
          @dist_z = view.vpwidth-60
          else
          @dist_z = @screen_x
        end
        explode_view(view.vpwidth-290-@dist_x, view.vpwidth-290-@dist_y, view.vpwidth-290-@dist_z)
      end
      view.invalidate if @ip.valid?
    end
    def onLButtonDown(flags, x, y, view)
      if @exit_button==true
        view.model.select_tool nil
        elsif @reset_button==true
        @dist_x=view.vpwidth-290
        @dist_y=view.vpwidth-290
        @dist_z=view.vpwidth-290
        explode_view(0, 0, 0)
        view.invalidate
        elsif @x_button==true
        @x_edit=true
        elsif @y_button==true
        @y_edit=true
        elsif @z_button==true
        @z_edit=true
      end
    end
    def onLButtonUp(flags, x, y, view)
      @x_edit=false
      @y_edit=false
      @z_edit=false
    end
    def explode_view(dist_x, dist_y, dist_z)
      selection = @model.selection
      if selection.empty?
        UI.messagebox SUF_STRINGS["Select Components or Groups"]
        else
        if @object_array == false
          group = @model.active_entities.add_group(selection)
          @center_selec = group.bounds.center
          selection = group.explode
        end
        
        cent_selec_x = @center_selec[0].to_f   # determination
        cent_selec_y = @center_selec[1].to_f   # center
        cent_selec_z = @center_selec[2].to_f   # of selection
        
        selection.grep(Sketchup::ComponentInstance).each { |e|
          name = e.definition.name
          if @points[name]
            center_object = @points[name]
            vector = center_object-e.bounds.center
            if vector.length != 0
              t = Geom::Transformation.new vector
              e.transform! t
            end
            else
            e.make_unique
            e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
            center_object = e.bounds.center
            @points.store(name,center_object)
          end
          
          center_object_x = center_object[0].to_f  # Determination
          center_object_y = center_object[1].to_f  # center
          center_object_z = center_object[2].to_f  # of object
          
          if center_object_x != cent_selec_x
            t = Geom::Transformation.new Geom::Vector3d.new(dist_x.abs*(center_object_x-cent_selec_x)/100,0,0)
            e.transform! (t)
          end
          if center_object_y != cent_selec_y
            t = Geom::Transformation.new Geom::Vector3d.new(0,dist_y.abs*(center_object_y-cent_selec_y)/100,0)
            e.transform! (t)
          end
          if center_object_z > cent_selec_z
            t = Geom::Transformation.new Geom::Vector3d.new(0,0,dist_z.abs*(center_object_z-cent_selec_z)/100)
            e.transform! (t)
          end
          
          @model.selection.add e
        }
        @object_array = true
      end
    end
    def onReturn(view)
      #view.model.select_tool nil
    end
    def onKeyUp(key, repeat, flags, view)
      if key==27
        self.deactivate(view)
      end
    end
    def onCancel(reason, view)
      #view.model.select_tool nil
    end
    def reset(view=nil)
      view.lock_inference if view && view.inference_locked?
    end
  end
end
