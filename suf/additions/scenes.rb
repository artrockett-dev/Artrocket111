require 'sketchup.rb'
module SU_Furniture
  class KitchenScenes
    def initialize
		  @delete_defaults = ["Удалить все сцены"]
      @add_defaults = [SUF_STRINGS["to the end"]]
    end#def
    def scenes(views=false,direction=false,current_scene=false,zoom_extents=true)
      model=Sketchup.active_model
      model.selection.remove_observer $SUFSelectionObserver
      model.entities.remove_observer $SUFEntitiesObserver
      visible_entities = []
      hidden_entities = []
      selection_layer = nil
      model.entities.each { |entity| entity.hidden = false }
      new_style = PATH + '/template/HiddenLine.style'
			make_views = views
      if views==false
        model.pages.to_a.each { |this_page| model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'M_' }
        elsif views != true && views != "new" && views.count != 1
        model.pages.to_a.each { |this_page| model.pages.erase(this_page) }
      end
      existing_pages=[]
      model.pages.each{|page| existing_pages<<page.name.to_s }
      @visible_layer = []
      carcass_layer = ["Z_Walls","3_Каркас","3_Каркас_ящика","9_Фурнитура","4_Задняя_стенка","5_Ножки","7_Размеры","0_Размеры","Z_Edge","Z_Face","1_LDSP","0_Nogki"]
      worktop = false
      wallpanel = false
      model.entities.grep(Sketchup::ComponentInstance).each { |ent|
        item_code = ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")
        if item_code[0] == "S"
          dimensions(ent)
          worktop = true
        end
        if item_code[0] == "F"
          dimensions(ent)
          wallpanel = true
        end
      }
      model.layers.add("0_Размеры")
      model.entities.grep(Sketchup::Dimension).each { |d| d.layer = "0_Размеры" }
      model.layers.each { |l| @visible_layer.push l if l.visible? }
      model.layers.each { |l| l.visible = false if l.name == "8_Направляющие" }
      scene_index = nil
      if current_scene
        selected_page = model.pages.selected_page
        return if !selected_page
        hidden_entities = selected_page.hidden_entities
        views[0] = selected_page.name + ' ' + views[0]
        model.pages.each_with_index { |page,index| scene_index = index+1 if page == selected_page}
      end
      if views==true || views=="new"
        prompts = [SUF_STRINGS["title "]] + (views=="new" && model.pages.count > 0 ? [SUF_STRINGS["position "]] : [] )
        defaults = [SUF_STRINGS["New Scene"]] + (views=="new" && model.pages.count > 0 ? @add_defaults : [] )
        list = [""] + (views=="new" && model.pages.count > 0 ? [SUF_STRINGS["to the end"]+"|"+SUF_STRINGS["after the current"]] : [] )
        input = UI.inputbox prompts, defaults, list, SUF_STRINGS["New Scene"]
        if input && input != ""
          if views==true
            selection_layer = model.layers.add(input[0])
            model.layers.each { |l| l.visible = false if !l.name[0][/^\d+$|Z/] }
            model.pages.each { |page| page.set_visibility( selection_layer, false ) if !['Общий_вид','Корпуса','Вид_Сверху','Столешница'].include?(page.name) }
            hidden_entities = model.active_entities.to_a - model.selection.to_a
            model.selection.each {|sel| sel.layer = input[0] }
          end
          if input[1]
            @add_defaults = [input[1]]
            if input[1] == SUF_STRINGS["after the current"]
              selected_page = model.pages.selected_page
              model.pages.each_with_index { |page,index| scene_index = index+1 if page == selected_page}
            end
          end
          views = [input[0]]
          else
          return
        end
        elsif views==false
        views = ['Общий_вид','Корпуса','Вид_Сверху']
        #views += ['Фартук'] if wallpanel
        views += ['Столешница'] if worktop
      end
      p views
      views.each{|view|
        
        if existing_pages.include?(view)
          if model.options['PageOptions']['ShowTransition']==true
            model.options['PageOptions']['ShowTransition']=false
            optionchanged=1
          end
          this_page = model.pages[view]
          this_page.delay_time = 0.1
          this_page.transition_time=0.1
          model.pages.selected_page=this_page
          model.active_view.zoom_extents if zoom_extents
          model.pages.add view,PAGE_USE_ALL,existing_pages.index(view)
          model.pages.erase(this_page)
          
          if optionchanged==1
            model.options['PageOptions']['ShowTransition']=true
          end
					
          else
					
          if view=='Общий_вид'
					  if direction==false
							direction1=Geom::Vector3d.new -0.666667, 0.666667, -0.333333
							model.active_view.camera.set( ORIGIN, direction1, direction1.axes.y)
            end
            model.active_view.camera.perspective = true
            info = model.shadow_info
            info["DisplayShadows"] = false
            elsif view.include?('Корпуса')
            model.styles.add_style(new_style, true)
            model.layers.each { |l| l.visible = false if !carcass_layer.include?(l.name) && l.name[0][/^\d+$/] }
            elsif view=='Вид_Сверху'
            model.active_view.camera.set( ORIGIN, Z_AXIS.reverse, Z_AXIS.reverse.axes.y)
            model.active_view.camera.perspective = false
						model.active_view.zoom_extents
            elsif view=='Вид_Спереди'
            model.active_view.camera.set( ORIGIN, Y_AXIS, Y_AXIS.axes.y)
            model.active_view.camera.perspective = false
						model.active_view.zoom_extents
            elsif view=='Вид_сзади'
            model.active_view.camera.set( ORIGIN, Y_AXIS.reverse, Y_AXIS.reverse.axes.y)
            model.active_view.camera.perspective = false
						model.active_view.zoom_extents
            elsif view=='Вид_Слева'
            model.active_view.camera.set( ORIGIN, X_AXIS, X_AXIS.axes.y)
            model.active_view.camera.perspective = false
						model.active_view.zoom_extents
            elsif view=='Вид_Справа'
            model.active_view.camera.set( ORIGIN, X_AXIS.reverse, X_AXIS.reverse.axes.y)
            model.active_view.camera.perspective = false
						model.active_view.zoom_extents
            elsif view=='Фартук'
            model.layers.each { |l| !l.name.include?("Фартук") && !l.name.include?("Z_Top_dimension") ? l.visible = false : l.visible = true }
						model.active_view.zoom_extents
            elsif view=='Столешница'
            model.layers.each { |l| !l.name.include?("Столешница") && !l.name.include?("Z_Top_dimension") ? l.visible = false : l.visible = true }
            model.active_view.camera.set( ORIGIN, Z_AXIS.reverse, Z_AXIS.reverse.axes.y)
            model.entities.each { |ent|
              if ent.is_a?(Sketchup::ComponentInstance) && ent.definition.get_attribute("dynamic_attributes", "itemcode", "0")[0] == "S"
                else
                visible_entities << ent
                ent.hidden = true
              end
            }
						model.active_view.camera.perspective = false
						model.active_view.zoom_extents
          end
          #add page
          hidden_entities.each { |entity| entity.hidden = true }
          if make_views==true
            model.active_view.zoom model.selection
            elsif !current_scene && zoom_extents
            model.active_view.zoom_extents
          end
          page = model.pages.add(view,PAGE_USE_ALL,(scene_index ? scene_index : model.pages.size))
          if selection_layer
            page.set_visibility( selection_layer, true )
          end
        end
				
      }
      model.pages.each{|page| 
        page.delay_time = 0.1
        page.transition_time=0.1
      }
      visible_entities.each { |entity| entity.hidden = false }
      if direction==false
        direction1=Geom::Vector3d.new -0.666667, 0.666667, -0.333333
        model.active_view.camera.set( ORIGIN, direction1, direction1.axes.y)
        model.active_view.camera.perspective = true
        model.entities.each { |ent| ent.hidden = false if !ent.is_a?(Sketchup::ComponentInstance) && !ent.is_a?(Sketchup::Group) }
        else
        if current_scene
          model.pages.selected_page=model.pages[scene_index]
          else
          model.pages.selected_page=model.pages[0]
        end
      end
      if SU_Furniture.observers_state == 1
        model.selection.add_observer $SUFSelectionObserver
        model.entities.add_observer $SUFEntitiesObserver
      end
    end#def
		def delete_scenes
      @model = Sketchup.active_model
      if @model.pages.count > 0
        input = UI.inputbox ["Удалить "], @delete_defaults, ["Удалить все сцены|Удалить все сцены, кроме первой|Удалить сцены модулей|Удалить сцены с чертежами|Удалить текущую сцену|Удалить текущую со слоем"], "Параметры удаления"
        if input
          @model.selection.remove_observer $SUFSelectionObserver
          @model.entities.remove_observer $SUFEntitiesObserver
          @delete_defaults = input
          if input[0] == "Удалить все сцены"
            @model.pages.selected_page=@model.pages[0]
            @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) }
            @model.entities.each { |entity| entity.hidden = false }
            @model.entities.grep(Sketchup::Text).each { |entity| entity.erase! if entity.layer.name == "Z_text" }
            elsif input[0] == "Удалить сцены модулей"
            @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'M_' }
            @model.entities.grep(Sketchup::Text).each { |entity| entity.erase! if entity.layer.name == "Z_text" }
            elsif input[0] == "Удалить сцены с чертежами"
            @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'P_' }
            elsif input[0].include?("Удалить текущую")
            selected_page = @model.pages.selected_page
            page_name = selected_page.name
            @model.pages.erase(selected_page)
            if input[0].include?("слоем") && @model.layers[page_name]
              @model.layers.remove(page_name)
            end
            else
            @model.pages.selected_page=@model.pages[0]
            @model.pages.to_a.each_with_index { |this_page, index| @model.pages.erase(this_page) if index!=0 }
            @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'M_' }
            @model.pages.to_a.each { |this_page| @model.pages.erase(this_page) if this_page.name.to_s[0..1] == 'P_' }
            @model.entities.grep(Sketchup::Text).each { |entity| entity.erase! if entity.layer.name == "Z_text" }
          end
          if @model.pages.count > 0
            @model.pages.selected_page=@model.pages[0]
            else
            @model.entities.each { |entity| entity.hidden = false }
          end
          @model.active_view.zoom_extents
          if SU_Furniture.observers_state == 1
            @model.selection.add_observer $SUFSelectionObserver
            @model.entities.add_observer $SUFEntitiesObserver
          end
        end
      end
    end#def
		def update_camera
		  pages_array = ['Общий_вид','Корпуса']
			@model = Sketchup.active_model
      @model.selection.remove_observer $SUFSelectionObserver
      @model.entities.remove_observer $SUFEntitiesObserver
      if @model.pages.count > 0
			  @model.pages.to_a.each { |this_page| this_page.update(PAGE_USE_CAMERA) if pages_array.include?(this_page.name) }
      end
      if SU_Furniture.observers_state == 1
        @model.selection.add_observer $SUFSelectionObserver
        @model.entities.add_observer $SUFEntitiesObserver
      end
    end#def
    def dimensions(entity)
      if !entity.hidden? && entity.definition.name.include?("Essence") && entity.layer.name.include?("Столешница") || entity.layer.name.include?("Фартук")
        essence_leny = entity.definition.get_attribute("dynamic_attributes", "leny", "1")
        entity.definition.entities.grep(Sketchup::ComponentInstance).each{ |ent|
          lenz = ent.definition.get_attribute("dynamic_attributes", "lenz", "0")
          if !ent.hidden?
            if ent.definition.name.include?("K_RR") || ent.definition.name.include?("K_R") || ent.definition.name.include?("K_L")
              entities = ent.definition.entities
              entities.grep(Sketchup::Dimension).each{ |ent| ent.erase!}
							bounds = ent.definition.bounds
              mix = bounds.min.x.to_f
              miz = bounds.min.z.to_f
              mx = bounds.max.x.to_f
              mz = bounds.max.z.to_f
              dim_layer = Sketchup.active_model.layers.add "Z_Top_dimension"
              if ent.definition.name.include?("K_RR")
                dim = entities.add_dimension_linear([mix, 0, miz], [mix, 0, mz], [0, 1, 0])
                dim.layer = dim_layer
                elsif ent.definition.name.include?("K_L")
                dim = entities.add_dimension_linear([mix, 0, miz], [mix, 0, mz], [0, 1, 0])
                dim.layer = dim_layer
                elsif ent.definition.name.include?("K_R")
                dim = entities.add_dimension_linear([mix, 0, miz], [mix, 0, mz], [0, -1, 0])
                dim.layer = dim_layer
              end
            end
          end
        }
        else
        entity.definition.entities.grep(Sketchup::ComponentInstance).each{ |e| dimensions(e) }
      end
    end#def
  end
end
