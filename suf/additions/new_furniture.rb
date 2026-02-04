module SU_Furniture
  class New_furniture
    def input_param(defaults = [SUF_STRINGS["New accessory"],"количество","1",SUF_STRINGS["Yes"]])
      model = Sketchup.active_model
      selection = model.selection
      if selection.empty?
        UI.messagebox("Nothing selected")
        else
        if selection.grep(Sketchup::ComponentInstance).length == 1
          defaults[0] = selection[0].definition.name
        end
        show_inputbox(model,selection,defaults)
      end
    end#def
    def show_inputbox(model,selection,defaults)
      prompts = ["#{SUF_STRINGS["name"]} ","#{SUF_STRINGS["Unit of measurement"]} ","#{SUF_STRINGS["Quantity (for pcs)"]} ","#{SUF_STRINGS["Change"]} Definition Name "]
      list = ["","Не учитывать|количество|пог.м по длине (X)|пог.м по ширине (Y)|пог.м по высоте (Z)|кв.м (X и Y)|кв.м (X и Z)|кв.м (Y и Z)|периметр (X и Y)|периметр (X и Z)|периметр (Y и Z)|куб.м","","#{SUF_STRINGS["Yes"]}|#{SUF_STRINGS["No"]}"]
      input = UI.inputbox prompts, defaults, list, " "
      return if !input
      if input[0].include?("|") || input[0].include?("/")
        UI.messagebox(SUF_STRINGS["Symbols | and / are not allowed"])
        show_inputbox(model,selection,input)
        else
        new_furniture(model,selection,input)
      end
    end#def
    def new_furniture(model,selection,input)
      furniture_layer = model.layers.add "9_Фурнитура"
      metal_layer = model.layers.add "4_Металл"
      model.start_operation "New furniture", true
      if selection.grep(Sketchup::ComponentInstance).length == 1
        entity = selection[0]
        entity.definition.name = Change_Attributes.my_uniq_defn_name(model,entity.definition.name.split("#")[0])
        shell = entity.definition.entities.grep(Sketchup::Group).find { |g| g.name == "shell"}
        if shell
          essence = wrap_in_component(model,entity)
          else
          essence = entity
        end
        else
        group = model.entities.add_group(selection.to_a)
        essence = group.to_component
      end
      new_component = wrap_in_component(model,essence)
      add_att_to_essence(essence, furniture_layer)
      shell = add_shell(new_component)
      set_new_att(new_component, input)
      DCProgressBar::clear()
      Redraw_Components.redraw(new_component)
      DCProgressBar::clear()
      model.commit_operation
      selection.clear
      selection.add(new_component)
    end#def
    def wrap_in_component(model,entity)
      group = model.entities.add_group(entity)
      group.to_component
    end#def
    def add_att_to_essence(essence,layer)
      bb = calculate_bounding_box(essence.definition.entities.to_a)
      essence.definition.name = "Essence"
      essence.layer = layer
      essence.set_attribute('dynamic_attributes', "_lengthunits", "CENTIMETERS")
      essence.definition.set_attribute('dynamic_attributes', "_lengthunits", "CENTIMETERS")
      set_att(essence,"x",0,"X",nil,nil,"CENTIMETERS",nil,'IF(parent!point_x_offset<0,-parent!LenX+parent!point_x_offset,IF(parent!point_x_offset=0,CHOOSE(parent!point_x,0,-parent!LenX/2,-parent!LenX),parent!point_x_offset))+parent!trim_x1',"&")
      set_att(essence,"y",0,"Y",nil,nil,"CENTIMETERS",nil,'IF(parent!point_y_offset<0,-parent!LenY+parent!point_y_offset,IF(parent!point_y_offset=0,CHOOSE(parent!point_y,0,-parent!LenY/2,-parent!LenY),parent!point_y_offset))+parent!trim_y1',"&")
      set_att(essence,"z",0,"Z",nil,nil,"CENTIMETERS",nil,'IF(parent!point_z_offset<0,-parent!LenZ+parent!point_z_offset,IF(parent!point_z_offset=0,CHOOSE(parent!point_z,0,-parent!LenZ/2,-parent!LenZ),parent!point_z_offset))+parent!trim_z1',"&")
      set_att(essence,"lenx",bb.width.to_f,"LenX",nil,nil,nil,nil,'parent!LenX-parent!trim_x1-parent!trim_x2',nil)
      set_att(essence,"leny",bb.height.to_f,"LenY",nil,nil,nil,nil,'parent!LenY-parent!trim_y1-parent!trim_y2',nil)
      set_att(essence,"lenz",bb.depth.to_f,"LenZ",nil,nil,nil,nil,'parent!LenZ-parent!trim_z1-parent!trim_z2',nil)
      set_att(essence,"su_type","Body")
    end#def
    def calculate_bounding_box(entities)
      bb = Geom::BoundingBox.new
      entities.each { |entity| bb.add(entity.bounds) if entity.respond_to?(:bounds) }
      bb
    end#def
    def add_shell(entity)
      shell_comp = Sketchup.active_model.definitions.load PATH + "/additions/shell.skp"
      t = Geom::Transformation.translation [0, 0, 0]
      shell_comp_place = entity.definition.entities.add_instance shell_comp, t
      shell_comp_place.explode
      shell = entity.definition.entities.grep(Sketchup::Group).find { |g| g.name == "shell"}
      set_att(shell,"x",0,"X",nil,nil,"CENTIMETERS",nil,'IF(parent!point_x_offset<0,-parent!LenX+parent!point_x_offset,IF(parent!point_x_offset=0,CHOOSE(parent!point_x,0,-parent!LenX/2,-parent!LenX),parent!point_x_offset))',"&")
      set_att(shell,"y",0,"Y",nil,nil,"CENTIMETERS",nil,'IF(parent!point_y_offset<0,-parent!LenY+parent!point_y_offset,IF(parent!point_y_offset=0,CHOOSE(parent!point_y,0,-parent!LenY/2,-parent!LenY),parent!point_y_offset))',"&")
      set_att(shell,"z",0,"Z",nil,nil,"CENTIMETERS",nil,'IF(parent!point_z_offset<0,-parent!LenZ+parent!point_z_offset,IF(parent!point_z_offset=0,CHOOSE(parent!point_z,0,-parent!LenZ/2,-parent!LenZ),parent!point_z_offset))',"&")
      set_att(shell,"lenx",1,"LenX",nil,nil,nil,nil,'parent!LenX',nil)
      set_att(shell,"leny",1,"LenY",nil,nil,nil,nil,'parent!LenY',nil)
      set_att(shell,"lenz",1,"LenZ",nil,nil,nil,nil,'parent!LenZ',nil)
      return shell
    end#def
    def set_new_att(entity,input)
      att,value,label,access,formlabel,formulaunits,units,formula,options = nil
      entity.set_attribute("dynamic_attributes", "_lengthunits", "CENTIMETERS")
      entity.definition.set_attribute("dynamic_attributes", "_lengthunits", "CENTIMETERS")
      set_att(entity,'description',"","Description",access,formlabel,formulaunits,units,'IF(Hidden," ",a03_name&","&Lenx*10&","&Leny*10&","&Lenz*10&","&Material&","&su_type)')
      set_att(entity,'itemcode',"","ItemCode",access,formlabel,formulaunits,units,'LOOKUP("itemcode","")')
      set_att(entity,'name',SUF_STRINGS["Element"],"Name")
      set_att(entity,'hidden',"0","Hidden")
      set_att(entity,'material',"","Material")
      set_att(entity,'suf_type',"furniture")
      name = input[0].gsub(",","|").gsub("=","~").gsub("+","плюс").gsub(")","]").gsub("(","[")
      entity.definition.name = name if input[3] == SUF_STRINGS["Yes"]
      set_att(entity,'a03_name',name,label,"TEXTBOX","Название","STRING")
      scale_grip = "120"
      lenx_formula = nil
      leny_formula = nil
      lenz_formula = nil
      case input[1]
        when "Не учитывать" then a08_su_unit = 1
        when "количество" then
        a08_su_unit = 2
        lenx_formula = Redraw_Components.get_live_value(entity, "lenx")
        leny_formula = Redraw_Components.get_live_value(entity, "leny")
        lenz_formula = Redraw_Components.get_live_value(entity, "lenz")
        when "пог.м по длине (X)" then
        scale_grip = "126"
        a08_su_unit = 3
        leny_formula = Redraw_Components.get_live_value(entity, "leny")
        lenz_formula = Redraw_Components.get_live_value(entity, "lenz")
        when "пог.м по ширине (Y)" then
        scale_grip = "125"
        a08_su_unit = 4
        lenx_formula = Redraw_Components.get_live_value(entity, "lenx")
        lenz_formula = Redraw_Components.get_live_value(entity, "lenz")
        when "пог.м по высоте (Z)" then
        scale_grip = "123"
        a08_su_unit = 5
        lenx_formula = Redraw_Components.get_live_value(entity, "lenx")
        leny_formula = Redraw_Components.get_live_value(entity, "leny")
        when "кв.м (X и Y)" then
        scale_grip = "124"
        a08_su_unit = 6
        lenz_formula = Redraw_Components.get_live_value(entity, "lenz")
        when "кв.м (X и Z)" then
        scale_grip = "122"
        a08_su_unit = 7
        leny_formula = Redraw_Components.get_live_value(entity, "leny")
        when "кв.м (Y и Z)" then
        scale_grip = "121"
        a08_su_unit = 8
        lenx_formula = Redraw_Components.get_live_value(entity, "lenx")
        when "периметр (X и Y)" then
        scale_grip = "124"
        a08_su_unit = 9
        lenz_formula = Redraw_Components.get_live_value(entity, "lenz")
        when "периметр (X и Z)" then
        scale_grip = "122"
        a08_su_unit = 10
        leny_formula = Redraw_Components.get_live_value(entity, "leny")
        when "периметр (Y и Z)" then
        scale_grip = "121"
        a08_su_unit = 11
        lenx_formula = Redraw_Components.get_live_value(entity, "lenx")
        when "куб.м" then a08_su_unit = 12
        else a08_su_unit = 1
      end
      set_att(entity,'scaletool',scale_grip,"ScaleTool")
      set_att(entity,'a08_su_unit',a08_su_unit.to_s,label,"LIST","Единица измерения","STRING","STRING",formula,'&%u041D%u0435%20%u0443%u0447%u0438%u0442%u044B%u0432%u0430%u0442%u044C=1&%u043A%u043E%u043B%u0438%u0447%u0435%u0441%u0442%u0432%u043E=2&%u043F%u043E%u0433.%u043C%20%u043F%u043E%20%u0434%u043B%u0438%u043D%u0435%20%20%28X%29%09=3&%u043F%u043E%u0433.%u043C%20%u043F%u043E%20%u0448%u0438%u0440%u0438%u043D%u0435%20%20%28Y%29=4&%u043F%u043E%u0433.%u043C%20%u043F%u043E%20%u0432%u044B%u0441%u043E%u0442%u0435%20%20%28Z%29=5&%u043A%u0432.%u043C%20%20%28X%20%u0438%20Y%29=6&%u043A%u0432.%u043C%20%28X%20%u0438%20Z%29=7&%u043A%u0432.%u043C%20%28Y%20%u0438%20Z%29=8&%u043F%u0435%u0440%u0438%u043C%u0435%u0442%u0440%20%28X%20%u0438%20Y%29%09=9&%u043F%u0435%u0440%u0438%u043C%u0435%u0442%u0440%20%28X%20%u0438%20Z%29=10&%u043F%u0435%u0440%u0438%u043C%u0435%u0442%u0440%20%28Y%20%u0438%20Z%29=11&%u043A%u0443%u0431.%u043C=12&')
      set_att(entity,'a09_su_quantity',"",'a09_su_quantity',"TEXTBOX","Количество","STRING","STRING",'CHOOSE(a08_su_unit,"0",'+input[2].to_s+',(LenX-trim_x1-trim_x2)/100,(LenY-trim_y1-trim_y2)/100,(LenZ-trim_z1-trim_z2)/100,(LenX-trim_x1-trim_x2)*(LenY-trim_y1-trim_y2)/10000,(LenX-trim_x1-trim_x2)*(LenZ-trim_z1-trim_z2)/10000,(LenY-trim_y1-trim_y2)*(LenZ-trim_z1-trim_z2)/10000,((LenX-trim_x1-trim_x2)+(LenY-trim_y1-trim_y2))/100,((LenX-trim_x1-trim_x2)+(LenZ-trim_z1-trim_z2))/100,((LenY-trim_y1-trim_y2)+(LenZ-trim_z1-trim_z2))/100,(LenX-trim_x1-trim_x2)*(LenY-trim_y1-trim_y2)*(LenZ-trim_z1-trim_z2)/1000000)')
      if !entity.definition.get_attribute("dynamic_attributes", "lenx")
        set_att(entity,'lenx',Redraw_Components.get_live_value(entity,"lenx"),"LenX","TEXTBOX","<font color=cc0000>Длина (X)</font>","CENTIMETERS","MILLIMETERS",(lenx_formula ? (lenx_formula*2.54).round(3).to_s : lenx_formula),nil)
      end
      if !entity.definition.get_attribute("dynamic_attributes", "leny")
        set_att(entity,'leny',Redraw_Components.get_live_value(entity,"leny"),"LenY","TEXTBOX","<font color=009900>Ширина (Y)</font>","CENTIMETERS","MILLIMETERS",(leny_formula ? (leny_formula*2.54).round(3).to_s : leny_formula),nil)
      end
      if !entity.definition.get_attribute("dynamic_attributes", "lenz")
        set_att(entity,'lenz',Redraw_Components.get_live_value(entity,"lenz"),"LenZ","TEXTBOX","<font color=0033ff>Высота (Z)</font>","CENTIMETERS","MILLIMETERS",(lenz_formula ? (lenz_formula*2.54).round(3).to_s : lenz_formula),nil)
      end
      set_att(entity,'a0_len',"0","a0_len",access,formlabel,formulaunits,units,'SETLABEL("lenx",CONCATENATE(╡┴║,"cc0000",├Длина┴,"(X)",┴╡┴║888888├┴,ROUND(z_min_length*10),│,ROUND(z_max_length*10),╞));SETLABEL("leny",CONCATENATE(╡┴║,"009900",├Ширина┴,"(Y)",┴╡┴║888888├┴,ROUND(z_min_width*10),│,ROUND(z_max_width*10),╞));SETLABEL("lenz",CONCATENATE(╡┴║,"0033ff",├Высота┴,"(Z)",┴╡┴║888888├┴,ROUND(z_min_height*10),│,ROUND(z_max_height*10),╞));')
      
      set_att(entity,"p1","&#9654;","p1","VIEW",'<font color=cc6600><b>Оси привязки<b></font>',"STRING","STRING")
      set_att(entity,"point_x","1","point_x","LIST","Точка по <font color=cc0000>оси X</font>","STRING","STRING",nil,'&Слева=1&По центру=2&Справа=3&')
      set_att(entity,"point_x_offset","0","point_x_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
      set_att(entity,"point_y","1","point_y","LIST","Точка по <font color=009900>оси Y</font>","STRING","STRING",nil,'&Спереди=1&По центру=2&Сзади=3&')
      set_att(entity,"point_y_offset","0","point_y_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
      set_att(entity,"point_z","1","point_z","LIST","Точка по <font color=0033ff>оси Z</font>","STRING","STRING",nil,'&Снизу=1&По центру=2&Сверху=3&')
      set_att(entity,"point_z_offset","0","point_z_offset","TEXTBOX","Смещение","CENTIMETERS","MILLIMETERS")
      
      set_att(entity,"s9","&#9654;","s9","VIEW",'<font color=cc6600><b>Компонент<b></font>',"STRING","STRING")
      set_att(entity,"s9_comp_axis","Показать/Скрыть","s9_comp_axis","VIEW","Оси компонентов","STRING","STRING",nil,nil)
      set_att(entity,"s9_comp_copy","+","s9_comp_copy","VIEW","Создать копию","STRING","STRING",nil,nil)
      set_att(entity,"s9_comp_name",entity.definition.name,"s9_comp_name","TEXTBOX","Название","STRING","STRING",nil,nil)
      set_att(entity,"s9_scale_grip","X:=>1,Y:=>1,Z:=>1",'s9_scale_grip',"CHECKBOX",'Ручки масштабирования',"STRING","STRING",'CHOOSE(a08_su_unit,"X:=>1,Y:=>1,Z:=>1","X:=>1,Y:=>1,Z:=>1","X:=>1,Y:=>0,Z:=>0","X:=>0,Y:=>1,Z:=>0","X:=>0,Y:=>0,Z:=>1","X:=>1,Y:=>1,Z:=>0","X:=>1,Y:=>0,Z:=>1","X:=>0,Y:=>1,Z:=>1","X:=>1,Y:=>1,Z:=>0","X:=>1,Y:=>0,Z:=>1","X:=>0,Y:=>1,Z:=>1","X:=>1,Y:=>1,Z:=>1")')
      
      set_att(entity,"t1","&#9654;","t1","VIEW",'<font color=cc6600><b>Отступы<b></font>',"STRING","STRING")
      set_att(entity,"trim_x1","0","trim_x1","TEXTBOX","Слева по <font color=cc0000>оси X</font>","CENTIMETERS","MILLIMETERS")
      set_att(entity,"trim_x2","0","trim_x2","TEXTBOX","Справа по <font color=cc0000>оси X</font>","CENTIMETERS","MILLIMETERS")
      set_att(entity,"trim_y1","0","trim_y1","TEXTBOX","Спереди по <font color=009900>оси Y</font>","CENTIMETERS","MILLIMETERS")
      set_att(entity,"trim_y2","0","trim_y2","TEXTBOX","Сзади по <font color=009900>оси Y</font>","CENTIMETERS","MILLIMETERS")
      set_att(entity,"trim_z1","0","trim_z1","TEXTBOX","Снизу по <font color=0033ff>оси Z</font>","CENTIMETERS","MILLIMETERS")
      set_att(entity,"trim_z2","0","trim_z2","TEXTBOX","Сверху по <font color=0033ff>оси Z</font>","CENTIMETERS","MILLIMETERS")
      
      set_att(entity,'su_info',"",label,access,formlabel,formulaunits,units,'IF(OR(Hidden,a08_su_unit=1)," ",ItemCode&"/"&a03_name&"/"&su_type&"/"&LenZ*10&"/"&LenY*10&"/"&LenX*10&"/"&Name&"/"&Material&"/"&1&"/"&su_quantity&"/"&su_unit&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0&"/"&0)')
      set_att(entity,'su_quantity',"",'su_quantity',nil,nil,nil,nil,'a09_su_quantity')
      set_att(entity,'su_type',"furniture")
      set_att(entity,'su_unit',"шт",label,access,formlabel,"STRING",units,'CHOOSE(a08_su_unit,"-","шт","м","м","м","кв.м","кв.м","кв.м","м","м","м","куб.м")')
      
      set_att(entity,'y0',"&#9654;",label,"VIEW",'<font color=cc6600><b>Фурнитура/Крепеж<b></font>','STRING','STRING',formula,'&')
      set_att(entity,'y0_name_manual',"0",label,"TEXTBOX","Ввод_Наименования","STRING",'STRING',formula,'&')
      set_att(entity,'y0_list',"1",label,access,formlabel,formulaunits,units,'SETLIST("y0_name_manual")')
      %w(y1 y2 y3 y4 y5).each {|a|
        y = "#{a}"
        set_att(entity,y+'_name',"1",label,"LIST",y[1]+"_Наименование",'STRING','STRING',formula,'&%u041D%u0435%u0442=1&')
        set_att(entity,y+'_quantity',"1",label,"TEXTBOX",y[1]+"_Количество (шт)","STRING",'STRING',formula,'&')
        set_att(entity,y+'_unit',"шт",label,"NONE",y[1]+"_Единица_измерения","STRING",'STRING',formula,'&%u0448%u0442=%u0448%u0442&%u043C=%u043C&')
      }
      set_att(entity,"z_max_length",10000/25.4,"z_max_length","NONE",nil,"CENTIMETERS","MILLIMETERS")
      set_att(entity,"z_max_width",10000/25.4,"z_max_width","NONE",nil,"CENTIMETERS","MILLIMETERS")
      set_att(entity,"z_max_height",10000/25.4,"z_max_height","NONE",nil,"CENTIMETERS","MILLIMETERS")
      set_att(entity,"z_min_length",1/25.4,"z_min_length","NONE",nil,"CENTIMETERS","MILLIMETERS")
      set_att(entity,"z_min_width",1/25.4,"z_min_width","NONE",nil,"CENTIMETERS","MILLIMETERS")
      set_att(entity,"z_min_height",1/25.4,"z_min_height","NONE",nil,"CENTIMETERS","MILLIMETERS")
    end#def
    def explode_hardware
      @model = Sketchup.active_model
      @model.start_operation('Explode furniture', true)
      @model.selection.grep(Sketchup::ComponentInstance).to_a.each { |entity|
        if entity.definition.get_attribute('dynamic_attributes', "suf_type","0") == "furniture"
          entity.definition.entities.each { |e|
            if e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("Point_box")
              e.erase!
              elsif e.is_a?(Sketchup::ComponentInstance) && e.definition.name.include?("Essence")
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
      if label
        e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label)
        else
        if att.downcase == "lenx" || att.downcase == "leny" || att.downcase == "lenz" || att.downcase == "x" || att.downcase == "y" || att.downcase == "z"
          else
          e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
        end
      end
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att && !e.definition.get_attribute('dynamic_attributes', "_"+att+"_label")
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
      if formula
        e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula)
        if att.downcase == "lenx" || att.downcase == "leny" || att.downcase == "lenz" || att.downcase == "x" || att.downcase == "y" || att.downcase == "z"
          e.set_attribute('dynamic_attributes', "_"+att+"_formula", formula)
        end
      end
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end#def
  end
end
