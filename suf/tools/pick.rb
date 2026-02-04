
module SU_Furniture
  def self.activate_tool()
    my_tool = PickMat.new
    Sketchup.active_model.tools.push_tool(my_tool)
  end
  
  class PickMat
    def initialize
      @cursor = nil
      cursor_path = PATH_ICONS + "/pipette.png"
      if cursor_path
        @cursor = UI.create_cursor( cursor_path, 1, 21 )
      end
    end	
    def activate
      @drawn = false
      @ip = Sketchup::InputPoint.new
      self.reset(nil)
    end
    
    def resume(view)
    end
    
    def deactivate(view)
      view.invalidate
    end
    
    def onCancel(flag, view)
      self.reset(view)
    end
    
    def reset(view)
      @ip.clear
      @message = "Select Face"
      @pts = []
      Sketchup.set_status_text( @message )
      if( view )
        view.tooltip = nil
        view.invalidate if @drawn
      end
      @drawn = false
    end
    
    def onMouseMove(flags, x, y, view)
      $flag = nil
      ph = view.pick_helper
      ph.do_pick(x, y)
      picked = (ph.picked_face.nil?) ? (ph.picked_edge.nil?) ? ph.best_picked : ph.picked_edge : ph.picked_face
      index = 0
      for i in 1..ph.count
        if ph.element_at(i) == picked
          index = i
          break
        end
      end
      path = ph.path_at(index)
      t = ph.transformation_at(index)
      
      if path.nil?
        $picked = nil
        else
        $picked = nil
        # Get picked face global normal
        n = ( picked.is_a?(Sketchup::Face) ) ? picked.normal.transform(t).normalize : nil
        # Travel down the path to work out the visible material
        path.each { |e|
          next unless e.respond_to?(:material)
          if e.is_a?(Sketchup::Face)
            c = Sketchup.active_model.active_view.camera.direction
            m = (c % n > 0) ? e.back_material : e.material
            next if m.nil?
            $picked = m.name
            else
            next if e.material.nil?
            $picked = e.material.name
          end
        }
        
      end
      @pos = [x,y,0]
      view.invalidate
      draw(view)
      
    end
    def draw(view)
      pos = @pos
      if pos != nil
        pos[0] += 20
        pos[1] -= 20
        p_name = $picked
        if p_name == nil
          str = "Default"
          else
          str = "#{p_name}"
        end
        view.draw_text(pos, str)
      end
      @drawn = true
    end
    def onLButtonDown(flags, x, y, view)
      @ip.pick( view, x, y )
      if @ip.face
        tr = @ip.transformation
        plane = [ @ip.face.vertices[0].position.transform( tr ) , @ip.face.normal.transform( tr ) ]
        $flag = $picked
        command = "pick_mat(#{$flag.inspect})"
        $dlg_suf.execute_script(command)
        deactivate(view)
        Sketchup.active_model.tools.pop_tool
      end
    end
    def onSetCursor
      UI.set_cursor(@cursor)
    end
  end # Class

end
