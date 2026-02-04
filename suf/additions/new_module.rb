module SU_Furniture
  class New_module
    def activate
      is_visible=$dlg_module.visible? if $dlg_module
      $dlg_module.close if $dlg_module && (is_visible==true)
      $dlg_module = UI::HtmlDialog.new({
        :dialog_title => "Make_module_"+PLUGIN_VERSION,
        :preferences_key => "module",
        :scrollable => true,
        :resizable => true,
        :width => 500,
        :height => 580,
        :left => 100,
        :top => 200,
        :min_width => 400,
        :min_height => 340,
        :max_width =>800,
        :max_height => 1000,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      html_path = PATH + "/html/New_module.html"
      $dlg_module.set_file(html_path)	
      $dlg_module.show()
      $dlg_module.add_action_callback("get_data") { |web_dialog,action_name|
        if action_name.to_s.include?("read_param")
          read_param
          elsif action_name.to_s.include?("save_changes")
          param = action_name[13..-1]
          save_changes(param)
          make_module(param)
        end
      }
    end#def
    def read_param
      param = []
      temp_hash = {}
      path_param = File.join(TEMP_PATH,"SUF","module.dat")
      if File.exist?(path_param)
        content = File.readlines(path_param).map(&:strip)
        content.each{|i| temp_hash[i.split("=")[1]] = i.split("=")[2] if i.split("=")[1]}
      end
      content = File.readlines(File.join(PATH,"parameters","module.dat")).map(&:strip)
      content.each{|i|
        cont = i.strip.split("=")
        cont[2] = temp_hash[cont[1]] if cont[1] && temp_hash[cont[1]]
        param << cont.join("=")
      }
      command = "parameters(#{param.inspect})"
      $dlg_module.execute_script(command)
    end#def
    def save_changes(param)
      param = param.split("|")
      path_param = File.join(TEMP_PATH,"SUF","module.dat")
      File.open(path_param, "w") { |param_file| param.each { |i| param_file.puts i } }
    end#def
    def make_module(param)
      att,value,label,access,formlabel,formulaunits,units,formula,options = nil
      param = param.split("|")
      param.each { |i|
        @comp_name = i.split("=")[2] if i.split("=")[1] == "comp_name"
        @item_code = i.split("=")[2] if i.split("=")[1] == "item_code"
        @code_pos = i.split("=")[2] if i.split("=")[1] == "code_pos"
        @panel_thickness = i.split("=")[2].to_f if i.split("=")[1] == "panel_thickness"
        @frontal_thickness = i.split("=")[2].to_f if i.split("=")[1] == "frontal_thickness"
        @back_thickness = i.split("=")[2].to_f if i.split("=")[1] == "back_thickness"
        
        @point_x = i.split("=")[2] if i.split("=")[1] == "point_x"
        @point_y = i.split("=")[2] if i.split("=")[1] == "point_y"
        @point_z = i.split("=")[2] if i.split("=")[1] == "point_z"
        
        @x_max_x = i.split("=")[2].to_f if i.split("=")[1] == "x_max_x"
        @x_max_y = i.split("=")[2].to_f if i.split("=")[1] == "x_max_y"
        @x_max_z = i.split("=")[2].to_f if i.split("=")[1] == "x_max_z"
        @x_min_x = i.split("=")[2].to_f if i.split("=")[1] == "x_min_x"
        @x_min_y = i.split("=")[2].to_f if i.split("=")[1] == "x_min_y"
        @x_min_z = i.split("=")[2].to_f if i.split("=")[1] == "x_min_z"
      }
      @model = Sketchup.active_model
      ents = @model.active_entities
      sel = @model.selection
      @model.start_operation('Make module', true)
      sel.grep(Sketchup::ComponentInstance).each{|ent|
        if ent.definition.get_attribute('dynamic_attributes', "description","0") == "Изделие"
          if @code_pos == "1"
            set_att(ent,"itemcode",nil,"ItemCode","NONE",nil,nil,nil,'LOOKUP("itemcode",a04_itemcode)',nil)
            elsif @code_pos == "2"
            set_att(ent,"itemcode",nil,"ItemCode","NONE",nil,nil,nil,'CONCATENATE(LOOKUP("itemcode"),".",a04_itemcode)',nil)
            elsif @code_pos == "3"
            set_att(ent,"itemcode",nil,"ItemCode","NONE",nil,nil,nil,'CONCATENATE(LOOKUP("itemcode"),"-",a04_itemcode)',nil)
          end
        end
      }
      
      body=ents.add_group(sel.grep(Sketchup::ComponentInstance))
      body=body.to_component
      body.definition.name = "Body"
      body.set_attribute('dynamic_attributes', "_lengthunits", "CENTIMETERS")
      set_att(body,"description","body","Description",access,formlabel,formulaunits,units,formula,options)
      set_att(body,"su_type","Body",label,access,formlabel,formulaunits,units,formula,options)
      set_att(body,"x","","X",access,formlabel,"CENTIMETERS",units,'CHOOSE(parent!point_x,0,-parent!LenX/2,-parent!LenX)+parent!trim_x1',"&")
      set_att(body,"y","","Y",access,formlabel,"CENTIMETERS",units,'CHOOSE(parent!point_y,0,-parent!LenY/2,-parent!LenY)+parent!trim_y1',"&")
      set_att(body,"z","","Z",access,formlabel,"CENTIMETERS",units,'CHOOSE(parent!point_z,0,-parent!LenZ/2,-parent!LenZ)+parent!trim_z2',"&")
      set_att(body,"lenx","","LenX",access,formlabel,"CENTIMETERS",units,'parent!a01_lenx',"&")
      set_att(body,"leny","","LenY",access,formlabel,"CENTIMETERS",units,'parent!a01_leny',"&")
      set_att(body,"lenz","","LenZ",access,formlabel,"CENTIMETERS",units,'parent!a01_lenz',"&")
      bounds = body.definition.bounds
      min_x = bounds.min.x.to_f
      min_y = bounds.min.y.to_f
      min_z = bounds.min.z.to_f
      max_x = bounds.max.x.to_f
      max_y = bounds.max.y.to_f
      max_z = bounds.max.z.to_f
      unit=ents.add_group(body)
      unit=unit.to_component
      unit.definition.name = @comp_name
      sel.add(unit.definition.instances)
      
      #set_att(unit,att,value,label,access,formlabel,formulaunits,units,formula,options)
      unit.set_attribute('dynamic_attributes', "_lengthunits", "CENTIMETERS")
      set_att(unit,"name","","Name",access,formlabel,formulaunits,units,'a03_name&" "&ABS(ROUND(a01_lenx*10,0))&_&ABS(ROUND(a01_leny*10,0))&_&ABS(ROUND(a01_lenz*10,0))',options)
      set_att(unit,"itemcode",@item_code,"ItemCode","NONE",formlabel,formulaunits,units,'a04_itemcode',options)
      set_att(unit,"description","Изделие","Description",access,formlabel,formulaunits,units,formula,options)
      set_att(unit,"lenx",max_x,"LenX","NONE",formlabel,"CENTIMETERS","MILLIMETERS",'IF(CURRENT("LenX")*2.54=a00_lenx,SETLEN("a00_lenx",IF(CURRENT("LenX")*2.54<x_min_x,x_min_x,IF(CURRENT("LenX")*2.54>x_max_x,x_max_x,ROUND(CURRENT("LenX")*2.54,1)))),a00_lenx)',"&")
      set_att(unit,"leny",max_y,"LenY","NONE",formlabel,"CENTIMETERS","MILLIMETERS",'IF(a00_leny<x_min_y,x_min_y,IF(a00_leny>x_max_y,x_max_y,a00_leny))',"&")
      set_att(unit,"lenz",max_z,"LenZ","NONE",formlabel,"CENTIMETERS","MILLIMETERS",'IF(CURRENT("LenZ")*2.54=a00_lenz,SETLEN("a00_lenz",IF(CURRENT("LenZ")*2.54<x_min_z,x_min_z,IF(CURRENT("LenZ")*2.54>x_max_z,x_max_z,ROUND(CURRENT("LenZ")*2.54,1)))),a00_lenz)',"&")
      set_att(unit,"hidden","0","Hidden",access,formlabel,formulaunits,units,formula,options)
      set_att(unit,"scaletool","122","ScaleTool",access,"ScaleTool",formulaunits,"STRING",formula,options)
      
      set_att(unit,"a0","&#9660;",label,"VIEW","<font color=cc6600><b>Габариты модуля<b></font>","STRING",units,formula,options)
      set_att(unit,"a00_lenx",max_x,label,"TEXTBOX","<font color=cc0000>Ширина <font color=888888> 100-1810</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a00_leny",max_y,label,"TEXTBOX","<font color=009900>Глубина <font color=888888> 100-1810</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a00_lenz",max_z,label,"TEXTBOX","<font color=0033ff>Высота <font color=888888> 100-1810</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a01_lenx","",label,"VIEW","<font color=cc0000><b>Ширина<b></font><font color=888888> (реальная)</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a01_leny","",label,"VIEW","<font color=009900><b>Глубина<b></font><font color=888888> (реальная)</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a01_lenz","",label,"VIEW","<font color=0033ff><b>Высота<b></font><font color=888888> (реальная)</font>","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"a0_len","",label,"NONE",formlabel,"CENTIMETERS","MILLIMETERS",'SETLEN("a01_lenx",IF(a00_lenx<x_min_x,x_min_x,IF(a00_lenx>x_max_x,x_max_x,a00_lenx-trim_x1-trim_x2)))*SETLEN("a01_leny",IF(a00_leny<x_min_y,x_min_y,IF(a00_leny>x_max_y,x_max_y,a00_leny-trim_y1-trim_y2)))*SETLEN("a01_lenz",IF(a00_lenz<x_min_z,x_min_z,IF(a00_lenz>x_max_z,x_max_z,a00_lenz-trim_z1-trim_z2)));SETLABEL("a00_lenx",CONCATENATE(╡┴║,"cc0000",├Ширина┴╡┴║888888├┴,ROUND(x_min_x*10),│,ROUND(x_max_x*10),╞));SETLABEL("a00_leny",CONCATENATE(╡┴║,"009900",├Глубина┴╡┴║888888├┴,ROUND(x_min_y*10),│,ROUND(x_max_y*10),╞));SETLABEL("a00_lenz",CONCATENATE(╡┴║,"0033ff",├Высота┴╡┴║888888├┴,ROUND(x_min_z*10),│,ROUND(x_max_z*10),╞))',options)
      set_att(unit,"a0_lenx","",label,"NONE",formlabel,"CENTIMETERS","MILLIMETERS",'SETLEN("LenX",IF(a00_lenx<x_min_x,x_min_x,IF(a00_lenx>x_max_x,x_max_x,a00_lenx)),IF(LenX=a00_lenx,0,))',"&")
      set_att(unit,"a0_leny","",label,"NONE",formlabel,"CENTIMETERS","MILLIMETERS",'SETLEN("LenY",IF(a00_leny<x_min_y,x_min_y,IF(a00_leny>x_max_y,x_max_y,a00_leny)),IF(LenY=a00_leny,0,))',"&")
      set_att(unit,"a0_lenz","",label,"NONE",formlabel,"CENTIMETERS","MILLIMETERS",'SETLEN("LenZ",IF(a00_lenz<x_min_z,x_min_z,IF(a00_lenz>x_max_z,x_max_z,a00_lenz)),IF(LenZ=a00_lenz,0,))',"&")
      
      set_att(unit,"a02","&#9660;",label,"VIEW","<font color=cc6600><b>Параметры модуля<b></font>","STRING",units,formula,options)
      set_att(unit,"a03_name",@comp_name,label,"TEXTBOX","Название","STRING","STRING",formula,options)
      set_att(unit,"a04_itemcode",@item_code,label,"TEXTBOX","Код изделия","STRING","STRING",formula,options)
      set_att(unit,"b1_f_thickness",@frontal_thickness/25.4,label,"TEXTBOX","Толщина фасадов","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"b1_f_material","Фасад_Базовая",label,access,formlabel,"STRING","STRING",formula,options)
      set_att(unit,"b1_p_thickness",@panel_thickness/25.4,label,"TEXTBOX","Толщина панелей","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"b1_p_material","ЛДСП_Базовая",label,access,formlabel,"STRING","STRING",formula,options)
      set_att(unit,"b1_b_thickness",@back_thickness/25.4,label,"TEXTBOX","Толщина ЗС/дна","CENTIMETERS","MILLIMETERS",'LOOKUP("b1_b_thickness",c5_back_thick)',options)
      
      set_att(unit,"c5","&#9654;",label,"VIEW","<font color=cc6600><b>Параметры задней стенки<b></font>","STRING",units,formula,options)
      set_att(unit,"c5_back","2",label,"LIST","Тип задней стенки","FLOAT","STRING",formula,'&%u041D%u0435%u0442=1&%u041D%u0430%u043A%u043B%u0430%u0434%u043D%u0430%u044F=2&%u0412%20%u043F%u0430%u0437=4&%u0412%20%u0447%u0435%u0442%u0432%u0435%u0440%u0442%u044C=5&')
      set_att(unit,"c5_back_dist",16/25.4,label,"TEXTBOX","Расстояние до паза (от 10 до 40)","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"c5_back_dist_r",16/25.4,label,"VIEW","Расстояние до паза (реальное)","CENTIMETERS","MILLIMETERS",'IF(c5_back_dist<1,1,IF(c5_back_dist>4,4,c5_back_dist))',options)
      set_att(unit,"c5_back_thick",@back_thickness/25.4,label,"TEXTBOX","Толщина ЗС (ширина паза)","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"c5_back_width",8/25.4,label,"TEXTBOX","Глубина паза","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"c6_back_indent",1/25.4,label,"TEXTBOX","Отступ ЗС от паза","CENTIMETERS","MILLIMETERS",formula,options)
      set_att(unit,"c9_back_opt",0,label,access,formlabel,"STRING","STRING",'SETACCESS("c5_back_dist",CHOOSE(c5_back,0,0,0,2,0));SETACCESS("c5_back_dist_r",CHOOSE(c5_back,0,0,0,1,0));SETACCESS("c5_back_width",CHOOSE(c5_back,0,0,0,2,0));SETLABEL("c6_back_indent",CHOOSE(c5_back,"Отступ по краям","Отступ по краям","Отступ по краям","Отступ ЗС от паза","Отступ ЗС от паза"))',options)
      
      set_att(unit,"p1","&#9654;",label,"VIEW","<font color=cc6600><b>Оси привязки<b></font>","STRING",units,formula,options)
      set_att(unit,"point_x",@point_x,label,"LIST","Точка по ширине","FLOAT","STRING",formula,'&%u0421%u043B%u0435%u0432%u0430=1&%u041F%u043E%20%u0446%u0435%u043D%u0442%u0440%u0443=2&%u0421%u043F%u0440%u0430%u0432%u0430=3&')
      set_att(unit,"point_y",@point_y,label,"LIST","Точка по глубине","FLOAT","STRING",formula,'&%u0421%u043F%u0435%u0440%u0435%u0434%u0438=1&%u041F%u043E%20%u0446%u0435%u043D%u0442%u0440%u0443=2&%u0421%u0437%u0430%u0434%u0438=3&')
      set_att(unit,"point_z",@point_z,label,"LIST","Точка по высоте","FLOAT","STRING",formula,'&%u0421%u043D%u0438%u0437%u0443=1&%u041F%u043E%20%u0446%u0435%u043D%u0442%u0440%u0443=2&%u0421%u0432%u0435%u0440%u0445%u0443=3&')
      
      set_att(unit,"t1","&#9654;",label,"VIEW","<font color=cc6600><b>Отступы<b></font>","STRING",units,formula,options)
      set_att(unit,"trim_x1","0",label,"TEXTBOX","Отступ слева","CENTIMETERS","MILLIMETERS",formula,"&")
      set_att(unit,"trim_x2","0",label,"TEXTBOX","Отступ справа","CENTIMETERS","MILLIMETERS",formula,"&")
      set_att(unit,"trim_y1","0",label,"TEXTBOX","Отступ спереди","CENTIMETERS","MILLIMETERS",formula,"&")
      set_att(unit,"trim_y2","0",label,"TEXTBOX","Отступ сзади","CENTIMETERS","MILLIMETERS",formula,"&")
      set_att(unit,"trim_z1","0",label,"TEXTBOX","Отступ сверху","CENTIMETERS","MILLIMETERS",formula,"&")
      set_att(unit,"trim_z2","0",label,"TEXTBOX","Отступ снизу","CENTIMETERS","MILLIMETERS",formula,"&")
      
      set_att(unit,"x_max_x","200",label,access,formlabel,"STRING",units,'z_max_width+trim_x1+trim_x2',options)
      set_att(unit,"x_max_y","200",label,access,formlabel,"STRING",units,'z_max_depth+trim_y1+trim_y2',options)
      set_att(unit,"x_max_z","200",label,access,formlabel,"STRING",units,'z_max_height+trim_z1+trim_z2',options)
      set_att(unit,"x_min_x","200",label,access,formlabel,"STRING",units,'z_min_width',options)
      set_att(unit,"x_min_y","200",label,access,formlabel,"STRING",units,'z_min_depth',options)
      set_att(unit,"x_min_z","200",label,access,formlabel,"STRING",units,'z_min_height',options)
      
      set_att(unit,"z_max_width",@x_max_x/10,label,access,formlabel,"STRING",units,formula,options)
      set_att(unit,"z_max_depth",@x_max_y/10,label,access,formlabel,"STRING",units,formula,options)
      set_att(unit,"z_max_height",@x_max_z/10,label,access,formlabel,"STRING",units,formula,options)
      set_att(unit,"z_min_width",@x_min_x/10,label,access,formlabel,"STRING",units,formula,options)
      set_att(unit,"z_min_depth",@x_min_y/10,label,access,formlabel,"STRING",units,formula,options)
      set_att(unit,"z_min_height",@x_min_z/10,label,access,formlabel,"STRING",units,formula,options)
      
      set_att(unit,'y0',"&#9654;",label,"VIEW",'<font color=cc6600><b>Фурнитура/Крепеж<b></font>','STRING','STRING',formula,'&')
      set_att(unit,'y0_name_manual',"0",label,"TEXTBOX","Ввод_Наименования","STRING",'STRING',formula,'&')
      set_att(unit,'y0_list',"1",label,access,formlabel,formulaunits,units,'SETLIST("y0_name_manual")',options)
      %w(y1 y2 y3 y4 y5).each {|a|
        y = "#{a}"
        set_att(unit,y+'_name',"1",label,"LIST",y[1]+"_Наименование",'STRING','STRING',formula,'&%u041D%u0435%u0442=1&')
        set_att(unit,y+'_quantity',"1",label,"TEXTBOX",y[1]+"_Количество (шт)","STRING",'STRING',formula,'&')
        set_att(unit,y+'_unit',"шт",label,"NONE",y[1]+"_Еденица_измерения","STRING",'STRING',formula,'&%u0448%u0442=%u0448%u0442&%u043C=%u043C&')
      }
      
      set_att(unit,"su_type","module",label,access,formlabel,formulaunits,units,formula,options)
      
      shell_comp = @model.definitions.load PATH + "/additions/shell.skp"
      t = Geom::Transformation.translation [0, 0, 0]
      shell_comp_place = unit.definition.entities.add_instance shell_comp, t
      shell_comp_place.explode
      point_box_comp = @model.definitions.load PATH + "/additions/point_box.skp"
      t = Geom::Transformation.translation [0, 0, 0]
      point_box_comp_place = unit.definition.entities.add_instance point_box_comp, t
      point_box_comp_place.explode
      
      DCProgressBar::clear()
      Redraw_Components.redraw(unit)
      Redraw_Components.run_all_formulas(unit)
      Redraw_Components.redraw(unit)
      DCProgressBar::clear()
      @model.commit_operation
      $dlg_module.close
    end#def
    def explode_module
      @model = Sketchup.active_model
      ents = @model.active_entities
      sel = @model.selection
      @model.start_operation('Explode module', true)
      nested_components = []
      sel.grep(Sketchup::ComponentInstance).to_a.each { |entity|
        if entity.definition.get_attribute('dynamic_attributes', "description","0") == "Изделие"
          entity.definition.entities.each { |e|
            if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("Point_box")
              e.erase!
              elsif e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("Body")
              e.explode
            end
          }
          entity.explode
        end
      }
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
  end #end Class 
  
end
