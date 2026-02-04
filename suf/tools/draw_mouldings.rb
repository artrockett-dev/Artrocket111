module SU_Furniture
  class DrawMouldings
    def initialize()
      @text_header_size = (OSX ? 16 : 10)
      @text_size = (OSX ? 14 : 8)
    end
    def activate
      @model=Sketchup.active_model
      @edit_transform=axes_edit_transform
      @ip0=Sketchup::InputPoint.new
      @ip1=Sketchup::InputPoint.new
      @ip2=Sketchup::InputPoint.new
      @ip3=Sketchup::InputPoint.new
      @ip=Sketchup::InputPoint.new
      @pts=[]
      @pts_rad=[]
      @screen_x=0
      @screen_y=0
      @length_mouldings = 0
      @intersections = 0
      @radius_elements = []
      @face=nil
      @faces=[]
      @profil_face = nil
      @connected = nil
      @edges=[]
      @element=[]
      @ents = @model.entities
      self.reset(@model.active_view)
    end
    def deactivate(view)
      #view.model.select_tool nil
    end
    def setstatus(view=nil)
      text = ""
      if @state==0
        text+=SUF_STRINGS["Select First point"]
        elsif @state==1
        text+= SUF_STRINGS["Select Second point"]
        elsif @state==2
        text+= SUF_STRINGS["Select Next point"]
      end
      Sketchup.status_text=text
      view.invalidate if view
    end
    def draw(view)
      view.line_width=2
      if @screen_x < view.vpwidth / 2 + 50 && @screen_x > view.vpwidth / 2 - 50 && @screen_y > view.vpheight - 32 && @screen_y < view.vpheight - 10
        view.drawing_color = "green"
        @text_options = {
          color: "green",
          font: 'Verdana',
          size: @text_header_size,
          align: TextAlignCenter
        }
        else
        view.drawing_color = "gray"
        @text_options = {
          color: "gray",
          font: 'Verdana',
          size: @text_header_size,
          align: TextAlignCenter
        }
      end
      view.draw_text(Geom::Point3d.new(view.vpwidth / 2, view.vpheight - 30, 0), "Выход: Esc или выбор инструмента", @text_options)
      points = [
        Geom::Point3d.new(view.vpwidth / 2 - 50, view.vpheight - 32, 0),
        Geom::Point3d.new(view.vpwidth / 2 + 50, view.vpheight - 32, 0),
        Geom::Point3d.new(view.vpwidth / 2 + 50, view.vpheight - 10, 0),
        Geom::Point3d.new(view.vpwidth / 2 - 50, view.vpheight - 10, 0),
        Geom::Point3d.new(view.vpwidth / 2 - 50, view.vpheight - 32, 0)
      ]
      #view.draw2d(GL_LINE_STRIP, points)
      model=view.model
      view.line_width=2
      view.drawing_color="black"
      if @ip && @ip.valid?
        if @ip.display?
          @ip.draw(view)
          elsif @face
          view.draw_points @ip.position, 7, 1, "red"
        end
      end
      if @new_comp
        if @state==1
          if @ip1.valid?
            @ip1.draw(view)
            view.set_color_from_line @ip1.position,@ip.position
            self.draw_geometry(@ip1.position, @ip.position, view)
          end
          elsif @state==2
          if @ip2.valid?
            @ip2.draw(view)
            view.set_color_from_line @ip2.position,@ip.position
            self.draw_geometry(@ip2.position, @ip.position, view)
          end
        end
      end
      self.setstatus
    end
    def draw_geometry(pt1, pt2, view)
      view.line_width=3
      view.draw_line(pt1, pt2)
      vec = pt2 - pt1
      if vec.length>0
        points=@outer_loop.collect {|pt| pt}
        object_origin=pt1
        object_zaxis=vec.reverse
        trans=Geom::Transformation.new(object_origin,object_zaxis)
        points=points.collect {|pt| pt.transform(trans)}
        end_points=points.collect {|pt| pt.offset(vec)}
        view.line_width=1
        view.draw(GL_LINE_LOOP, points)
        view.draw(GL_LINE_LOOP, end_points)
        points.each_index {|i| view.draw(GL_LINES,[points[i],end_points[i]])}
      end
    end
    def onMouseMove(flags, x, y, view)
      @face=nil
      @screen_x = x
      @screen_y = y
      if @state==0
        @ip.pick view,x,y
        view.invalidate if @ip.valid?
        elsif @state==1
        @ip.pick view,x,y,@ip1
        view.invalidate if @ip.valid?
        length = @ip1.position.distance(@ip.position)
        Sketchup::set_status_text length.to_s, SB_VCB_VALUE
        rotate_comp(@ip.position,@ip1.position) if @new_comp
        elsif @state==2
        @ip.pick view,x,y,@ip2
        view.invalidate if @ip.valid?
        length = @ip2.position.distance(@ip.position)
        Sketchup::set_status_text length.to_s, SB_VCB_VALUE
      end
    end
    def comp_name(name)
      @comp_name = name
    end
    def load_comp(moulding_name)
      @outer_loop=[]
      folder_comp = PATH_COMP+"/Профили"
      @new_comp = nil
      if File.file? (folder_comp + "/" + moulding_name + ".skp")
        if Sketchup.version_number >= 2110000000
          @new_comp = @model.definitions.load(folder_comp + "/" + moulding_name + ".skp", allow_newer: true)
          else
          @new_comp = @model.definitions.load folder_comp + "/" + moulding_name + ".skp"
        end
        t1 = Geom::Transformation.translation @ip0.position
        @new_comp_place = @model.entities.add_instance @new_comp, t1
        @new_comp_place2 = @model.entities.add_instance @new_comp, t1
        @comp_length = @new_comp_place.bounds.height*25.4
        @new_objects = @new_comp_place2.explode
        @new_objects.grep(Sketchup::Face).each { |face| @profil_face = face.reverse! }
        normal=@profil_face.normal
        trans=Geom::Transformation.new(@ip0.position, normal)
        trans.invert!
        @profil_face.loops.each {|loop|
          verts=loop.vertices
          @outer_loop=verts.collect {|v| v.position.transform(trans)}
        }
        @new_objects.each { |object| object.erase! if object.is_a?(Sketchup::Edge) }
      end
      p @outer_loop
    end
    def rotate_comp(p2,p1)
      if p2!=p1
        @comp_vector = p2 - p1
      @new_comp_place.move!(Geom::Transformation.translation(ORIGIN))
      @new_comp_place.transform!(
        Geom::Transformation.new(p1, @comp_vector.normalize!)
      )
    end
    end
    def onLButtonDown(flags, x, y, view)
      if @state==0
        if @ip.valid?
          @element.clear
          @ip1.copy! @ip
          @p1=@ip1.position
          @ip0.copy! @ip
          @state=1
          view.lock_inference if  view.inference_locked?
          self.load_comp(@comp_name)
        end
        elsif @state==1 && @ip.valid? && (@ip1.position!=@ip.position)
        if @screen_x < view.vpwidth / 2 + 50 && @screen_x > view.vpwidth / 2 - 50 && @screen_y > view.vpheight - 32 && @screen_y < view.vpheight - 10
          self.reset(view)
          elsif @new_comp
          @ip2.copy! @ip
          @p2=@ip2.position
          @state=2
          view.lock_inference if  view.inference_locked?
          @pts << @ip1.position
          @pts << @ip2.position
          @length_mouldings += @ip1.position.distance(@ip2.position)*25.4
          self.process_follow_me(@comp_name, view)
          @ip1.copy! @ip2
        end
        elsif @state==2 && @ip.valid? && (@ip2.position!=@ip.position)
        if @screen_x < view.vpwidth / 2 + 50 && @screen_x > view.vpwidth / 2 - 50 && @screen_y > view.vpheight - 32 && @screen_y < view.vpheight - 10
          self.reset(view)
          else
          @ip3.copy! @ip
          @p3=@ip3.position
          view.lock_inference if  view.inference_locked?
          @pts << @ip3.position
          @length_mouldings += @ip2.position.distance(@ip3.position)*25.4
          @intersections += 1
          @unit.erase!
          self.process_follow_me(@comp_name, view)
          @ip2.copy! @ip3
        end
      end
      view.invalidate
      self.setstatus(view)
    end
    def process_follow_me(comp_name, view)
      @model.start_operation "Make moulding",true
      if @new_comp_place.deleted?
        t1 = Geom::Transformation.translation @ip0.position
        @new_comp_place = @model.entities.add_instance @new_comp, t1
        rotate_comp(@ip1.position,@ip0.position)
        new_objects = @new_comp_place.explode
        new_objects.grep(Sketchup::Face).each { |face| @profil_face = face.reverse! }
        else
        new_objects = @new_comp_place.explode
        new_objects.grep(Sketchup::Face).each { |face| @profil_face = face.reverse! }
      end
      
      group = @ents.add_group @profil_face.all_connected
      pts = @pts.collect {|v| v.transform(group.transformation.inverse)}
      edges = group.entities.add_curve(pts)
      edges[0].explode_curve
      @profil_face.followme(edges)
      
      @unit=group.to_component
      
      @unit.definition.name=comp_name.to_s
      @unit.set_attribute("dynamic_attributes", "_lengthunits", "CENTIMETERS")
      @length_mouldings += @intersections*@comp_length*2
      
      #set_att(g,att,value,label,access,formlabel,formulaunits,units,formula,options)
      att,value,label,access,formlabel,formulaunits,units,formula,options = nil
      set_att(@unit,'itemcode',"","ItemCode",access,formlabel,formulaunits,units,'LOOKUP("itemcode","")',options)
      set_att(@unit,'name',comp_name,"Name",access,formlabel,formulaunits,units,formula,options)
      set_att(@unit,'hidden',"0","Hidden",access,formlabel,formulaunits,units,formula,options)
      set_att(@unit,'a03_name',comp_name,label,access,formlabel,formulaunits,units,formula,options)
      set_att(@unit,'a08_su_unit',3,label,access,formlabel,formulaunits,units,formula,options)
      set_att(@unit,'su_info',"",label,access,formlabel,formulaunits,units,'IF(OR(Hidden,a08_su_unit=1)," ",ItemCode&"/"&a03_name&"/"&su_type&"/"&LenZ*10&"/"&LenY*10&"/"&LenX*10&"/"&Name&"/"&Material&"/"&1&"/"&su_quantity&"/"&su_unit&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0)',options)
      set_att(@unit,'su_unit',"м",label,access,formlabel,"STRING",units,formula,options)
      set_att(@unit,'su_quantity',@length_mouldings/1000,label,access,formlabel,formulaunits,units,formula,options)
      set_att(@unit,'su_type',"furniture",label,access,formlabel,formulaunits,units,formula,options)
      if @radius_elements != []
        @radius_elements.each_with_index{|element,index|
          set_att(@unit,'y'+(index+1).to_s+'_name',"Радиусный элемент "+element[0].to_s,label,access,formlabel,formulaunits,units,formula,options)
          set_att(@unit,'y'+(index+1).to_s+'_quantity',element[1],label,access,formlabel,formulaunits,units,formula,options)
          set_att(@unit,'y'+(index+1).to_s+'_unit',"шт",label,access,formlabel,formulaunits,units,formula,options)
        }
      end
      Redraw_Components.redraw_entities_with_Progress_Bar([@unit])
      @model.commit_operation
    end
    def set_att(e,att,value,label=nil,access=nil,formlabel=nil,formulaunits=nil,units=nil,formula=nil,options=nil)
			e.set_attribute('dynamic_attributes', att, value) if value
			e.definition.set_attribute('dynamic_attributes', att, value) if value
			label ? e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label) : e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula) if formula
			e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end#def
    def parse_length(input)
      (return 0) if !input
      begin
        value=input.to_s.to_l
        rescue ArgumentError
        value=input.to_s.to_f
      end
      return value
    end
    def onReturn(view)
      #view.model.select_tool nil
    end
    def onKeyDown(key, repeat, flags, view)
      if key==CONSTRAIN_MODIFIER_KEY
        @shift_press=true
        if view.inference_locked?
          view.lock_inference
          elsif (@state==0 && @ip.valid? )
          view.lock_inference @ip
          elsif (@state==1 && @ip.valid?)
          view.lock_inference @ip,@ip1
          elsif @state==2 && @ip3.valid?
          @ip_shift= @ip3
          view.lock_inference @ip3,@ip2
        end
        elsif key==VK_UP
        view.lock_inference if view.inference_locked?
        if @ip.valid? && @state>0
          pt= ((@state==1) ? @p1 : @p2)
          p1=pt + @edit_transform.zaxis
          ip1 = Sketchup::InputPoint.new(p1)
          ip = Sketchup::InputPoint.new(pt)
          view.lock_inference ip1,ip
        end
        elsif key==VK_LEFT
        view.lock_inference if view.inference_locked?
        if @ip.valid? && @state>0
          pt=  ((@state==1) ? @p1 : @p2)
          p1=pt + @edit_transform.yaxis
          ip1 = Sketchup::InputPoint.new(p1)
          ip = Sketchup::InputPoint.new(pt)
          view.lock_inference ip1,ip
        end
        elsif key==VK_RIGHT
        view.lock_inference if view.inference_locked?
        if @ip.valid? && @state>0
          pt= ((@state==1) ? @p1 : @p2)
          p1=pt + @edit_transform.xaxis
          ip1 = Sketchup::InputPoint.new(p1)
          ip = Sketchup::InputPoint.new(pt)
          view.lock_inference ip1,ip
        end
      end
      self.setstatus(view)
    end
    def onKeyUp(key, repeat, flags, view)
      if (key==CONSTRAIN_MODIFIER_KEY)
        @shift_press=false
        view.lock_inference if view.inference_locked?
        elsif key==27
        view.model.select_tool nil
        self.deactivate(view)
      end
      self.setstatus(view)
    end
    def cut_rad_nar(point,radius)
      @pts_rad = []
      @rad_vector.normalize!
      if @rad_vector.x != 0
        vector = Geom::Vector3d.new(0, 0, -1*@rad_vector.x).normalize!
        else
        vector = Geom::Vector3d.new(0, 0, -1*@rad_vector.y).normalize!
      end
      vector1 = vector.cross(@rad_vector)
      vector1.x=-(vector1.x.abs)*radius
      vector1.y=(vector1.y.abs)*radius
      @rad_vector.x=(@rad_vector.x)*radius
      @rad_vector.y=(@rad_vector.y)*radius
      edges = @model.active_entities.add_arc(point+vector1, @rad_vector, vector, radius, 0, 90.degrees, 36)
      edges_array = edges.to_a.reverse
      for i in 0..edges_array.length-1
        @pts_rad << edges_array[i].end.position
        @pts_rad << edges_array[i].start.position
      end
      @pts += @pts_rad
      edges.each { |edge| edge.erase! }
      @new_point = Sketchup::InputPoint.new(point+vector1+@rad_vector)
    end
    def cut_rad_vn(point,radius)
      @pts_rad = []
      @rad_vector.normalize!
      if @rad_vector.x != 0
        vector = Geom::Vector3d.new(0, 0, -1*@rad_vector.x).normalize!
        else
        vector = Geom::Vector3d.new(0, 0, -1*@rad_vector.y).normalize!
      end
      vector1 = vector.cross(@rad_vector)
      vector1.x=-(vector1.x.abs)*radius
      vector1.y=(vector1.y.abs)*radius
      @rad_vector.x=(@rad_vector.x)*radius
      @rad_vector.y=(@rad_vector.y)*radius
      edges = @model.active_entities.add_arc(point+@rad_vector, @rad_vector.reverse, vector, radius, 0, 90.degrees, 36)
      for i in 0..edges.length-1
        @pts_rad << edges[i].start.position
        @pts_rad << edges[i].end.position
      end
      @pts += @pts_rad
      edges.each { |edge| edge.erase! }
      @new_point = Sketchup::InputPoint.new(point+vector1+@rad_vector)
    end
    def onUserText(text, view)
      if @state==1
        if @ip.position!=@p1
          @comp_vector = @ip.position - @ip1.position
          if text.include?("+")
            @rad_vector = @ip.position - @ip1.position
            radius=text[1..-1].to_f
            @count = 1
            @radius_elements.each {|element|
              if element.include?(@comp_name+" R"+radius.round.to_s)
                @count += element[1]
                @radius_elements.delete(element)
              end
            }
            @radius_elements.push([@comp_name+" R"+radius.round.to_s,@count])
            cut_rad_nar(@ip1.position,radius/25.4)
            self.process_follow_me(@comp_name, view)
            @ip1.copy! @new_point
            elsif text.include?("-")
            @rad_vector = @ip.position - @ip1.position
            radius=text[1..-1].to_f
            @count = 1
            @radius_elements.each {|element|
              if element.include?(@comp_name+" R"+radius.round.to_s)
                @count += element[1]
                @radius_elements.delete(element)
              end
            }
            @radius_elements.push([@comp_name+" R"+radius.round.to_s,@count])
            cut_rad_vn(@ip1.position,radius/25.4)
            self.process_follow_me(@comp_name, view)
            @ip1.copy! @new_point
            else
            vec=@ip.position - @p1
            vec.length=self.parse_length(text)
            if vec.length>0
              @p2=@p1 + vec
              ip = Sketchup::InputPoint.new(@p2)
              @ip2.copy! ip
              view.lock_inference if  view.inference_locked?
              @pts << @p1
              @pts << @p2
              self.process_follow_me(@comp_name, view)
              @length_mouldings += @p1.distance(@p2)*25.4
              @ip1.copy! @ip2
              @state=2
            end
          end
        end
        elsif @state==2
        if @ip.position!=@ip2.position
          if text.include?("+")
            @rad_vector = @ip.position - @ip2.position
            radius=text[1..-1].to_f
            @count = 1
            @radius_elements.each {|element|
              if element.include?(@comp_name+" R"+radius.round.to_s)
                @count += element[1]
                @radius_elements.delete(element)
              end
            }
            @radius_elements.push([@comp_name+" R"+radius.round.to_s,@count])
            cut_rad_nar(@ip2.position,radius/25.4)
            @unit.erase!
            self.process_follow_me(@comp_name, view)
            @ip2.copy! @new_point
            elsif text.include?("-")
            @rad_vector = @ip.position - @ip2.position
            radius=text[1..-1].to_f
            @count = 1
            @radius_elements.each {|element|
              if element.include?(@comp_name+" R"+radius.round.to_s)
                @count += element[1]
                @radius_elements.delete(element)
              end
            }
            @radius_elements.push([@comp_name+" R"+radius.round.to_s,@count])
            cut_rad_vn(@ip2.position,radius/25.4)
            @unit.erase!
            self.process_follow_me(@comp_name, view)
            @ip2.copy! @new_point
            else
            vec=@ip.position - @ip2.position
            vec.length=self.parse_length(text)
            if vec.length>0
              @p3=@ip2.position + vec
              ip = Sketchup::InputPoint.new(@p3)
              @ip3.copy! ip
              view.lock_inference if  view.inference_locked?
              @pts << @p3
              @unit.erase!
              self.process_follow_me(@comp_name, view)
              @length_mouldings += @ip2.position.distance(@p3)*25.4
              @intersections += 1
              @ip2.copy! @ip3
            end
          end
        end
      end
      self.setstatus(view)
    end
    def get_vertices(face)
      return nil if not( face && (face.is_a? Sketchup::Face))
      ver=[]
      vertices=[]
      vertices =face.vertices*3
      (0..face.vertices.length-1).each { |i|
        j=face.vertices.length+i
        p1=vertices[j-1].position.clone
        p2=vertices[j].position.clone
        p3=vertices[j+1].position.clone
        v1=p1.vector_to p2
        v2=p2.vector_to p3
        ver.push vertices[j] if not( v1.samedirection? v2)
      }
      return ver
    end
    def center_face(face)
      vertices=get_vertices(face)
      return nil if !vertices
      numver=vertices.length
      cp=Geom::Point3d.new
      vertices.each{|v|
        cp.x=cp.x+v.position.x
        cp.y=cp.y+v.position.y
        cp.z=cp.z+v.position.z
      }
      cp.x=cp.x/ numver
      cp.y=cp.y/ numver
      cp.z=cp.z/ numver
      return cp
    end
    def onCancel(reason, view)
      self.reset(view)
    end
    def reset(view=nil)
      @state=0
      @face=nil
      @ip0.clear
      @ip1.clear
      @ip2.clear
      @ip3.clear
      @ip.clear
      @pts=[]
      @pts_rad=[]
      @screen_x=0
      @screen_y=0
      @length_mouldings = 0
      @intersections = 0
      @radius_elements = []
      @face=nil
      @faces=[]
      @profil_face = nil
      @connected = nil
      @edges=[]
      @element=[]
      view.lock_inference if view && view.inference_locked?
      self.setstatus(view)
    end
    def resume(view)
      self.setstatus(view)
    end
    def onSetCursor
      UI.set_cursor(633)
    end#def
    def axes_edit_transform
      model=Sketchup.active_model
      ents=model.active_entities
      begin
        model.start_operation "Panel Tools",true,false,true
        g=ents.add_group(ents.add_group)
        t=Geom::Transformation.new(g.transformation.xaxis,g.transformation.yaxis,g.transformation.zaxis,g.transformation.origin)
        g.erase! if g && g.valid? && !g.deleted?
        model.commit_operation
        rescue
        t=model.edit_transform
      end
      return t
    end
  end
end

