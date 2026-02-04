module SU_Furniture
  class ThrowToFace
    def initialize
      @text_header_size = (OSX ? 16 : 10)
      @text_default_options = {
        color: "gray",
        font: 'Verdana',
        size: @text_header_size,
        align: TextAlignLeft,
        bold: false
      }
    end
    def activate
      @model = Sketchup.active_model
      @sel = @model.selection
      @sel.remove_observer $SUFSelectionObserver
      @shift_press = false
      @control_press = false
      @drawn = false
      @ip = Sketchup::InputPoint.new
      self.reset(nil)
    end
    def deactivate(view)
      view.invalidate if @drawn
      if SU_Furniture.observers_state == 1
        @sel.add_observer $SUFSelectionObserver
      end
    end
    def onCancel(flag, view)
      self.reset(view)
    end
    def onSetCursor
      UI.set_cursor(633)
    end
    def reset(view)
      @ip.clear
      @message = "Select Face to move"
      @pts = []
      Sketchup.set_status_text( @message )
      if( view )
        view.tooltip = nil
        view.invalidate if @drawn
      end
      @drawn = false
    end
    def draw(view)
      Sketchup.set_status_text( @message )
      if @pts != []
        view.line_width = 4
        view.drawing_color="red"
        @pts.push @pts[0] if @pts[0] != @pts[-1]
        view.draw_polyline(@pts)
      end
      view.draw_text(Geom::Point3d.new(30, 25, 0), "Double click - select component", @text_default_options)
      @drawn = true
    end
    def onMouseMove(flags, x, y, view)
      @ip.pick( view, x, y )
      ph = view.pick_helper
      ph.do_pick x,y
      pick_list = ph.path_at(0)
      @new_entity = nil
      
      if (pick_list != nil)
        @new_entity = pick_list[0] if pick_list[0].is_a?(Sketchup::ComponentInstance)
      end
      
      if @ip.face and @ip.face.visible?
        tr = @ip.transformation
        @pts = @ip.face.vertices.map{|vt| vt.position.transform( tr ) }
        view.invalidate# if @drawn
        else
        @pts = []
      end
    end
    def onLButtonDoubleClick(flags, x, y, view)
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
        @pts = []
        activate
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
      if key==VK_SHIFT
        UI.start_timer(0.1, false) { @shift_press=false }
        view.lock_inference if view.inference_locked?
        elsif key==VK_CONTROL || key==VK_COMMAND
        @control_press=false
        view.lock_inference if view.inference_locked?
        elsif key==VK_ALT
        @alt_press=false
        view.lock_inference if view.inference_locked?
      end
    end
    def onLButtonDown(flags, x, y, view)
      UI.start_timer(0.3, false) {
        @ip.pick( view, x, y )
        if @ip.face && @pts != []
          tr = @ip.transformation
          plane = [ @ip.face.vertices[0].position.transform( tr ) , @ip.face.normal.transform( tr ) ]
          start_throwing_plane( plane , tr )
          self.reset(view)
        end
      }
    end
    def start_throwing_plane( plane , tr )
      vec = plane[1]
      model = Sketchup.active_model
      ents = model.active_entities
      tvecs = []
      tents = []
      Sketchup.active_model.start_operation "Throw to Plane", true
      @sel.each{|sel|
        pts = []
        pts = get_all_vt_pts( sel )
        pts2 = pts.uniq.compact
        dist = model.bounds.diagonal
        tvec = Geom::Vector3d.new(0,0,0)
        pts2.each{|pt3|
          ray = [ pt3 , vec ]
          ipt = Geom.intersect_line_plane(ray, plane)
          if ipt
            if pt3.distance( ipt ) < dist
              dist = pt3.distance( ipt )
              tvec = pt3.vector_to( ipt )
            end
          end
        }
        if tvec.valid?
          tents.push sel
          tvecs.push tvec
        end
      }
      if tents != []
        ents.transform_by_vectors tents, tvecs
      end

      Sketchup.active_model.commit_operation
    end
    def get_all_vt_pts( e , gtr = Geom::Transformation.new )
      if e.is_a? Sketchup::Group
        tr = e.transformation
        pts = []
        e.entities.each{|e2|
          pts.push get_all_vt_pts( e2 , gtr * tr )
        }
        return pts.flatten
        elsif e.is_a? Sketchup::ComponentInstance 
        tr = e.transformation
        pts = []
        e.definition.entities.each{|e2|
          pts.push get_all_vt_pts( e2 , gtr * tr )
        }
        return pts.flatten
        elsif e.visible? and ( e.is_a? Sketchup::Face or e.is_a? Sketchup::Edge )
        return e.vertices.map{|vt| vt.position.transform( gtr ) }
      end
    end
  end # Class Throw_to
end # Module
