# encoding: UTF-8

Sketchup::require("suf/tools/pick")
module SU_Furniture
  class ChangeMaterials
	  def initialize
		  @material_path = {}
      @back_material_input = SUF_STRINGS["White"]
    end
    def list
      folder_list=[]
      content=[]
			begin_time = Time.new
      @material_path = {}
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
      if param_temp_path && File.file?(File.join(param_temp_path,"material.dat"))
        path_param = File.join(param_temp_path,"material.dat")
        elsif File.file?(File.join(TEMP_PATH,"SUF","material.dat"))
        path_param = File.join(TEMP_PATH,"SUF","material.dat")
        elsif File.file?(File.join(PATH_MAT,"material.dat"))
        path_param = File.join(PATH_MAT,"material.dat")
        else
        path_param = File.join(PATH,"parameters","material.dat")
      end
      content = File.readlines(path_param, chomp: true).reject { |c| c.empty? }
      content.map! {|i| i.force_encoding("UTF-8") if i.respond_to?(:force_encoding) }
      folder_list << 'var material_content = {'
      folder_list << '"sections": [' + content.map { |folder| '{"name": "' + folder.split("=")[0].gsub('"','') + '", "alias": "' + folder.split("=")[1].gsub('"','') + '"}' }.join(", ") + '],'
      folder_list << '"vendors": {'
      content.each_with_index{|folder,index|
				index==content.length-1 ? last = " " : last = ","
        name_vendor = []
        name_vendor=folder.split("=")
        name_vendor[2] == nil ? name_vendor[2] = '""' : name_vendor[2] = name_vendor[2].chomp
        folder_list << '"' + name_vendor[0].gsub('"','') + '":["' + name_vendor[2].gsub('"','').split(",").join('","') + '"]' + last
        @material_path[name_vendor[0].gsub('"','')] = name_vendor[2].gsub('"','').split(",")
      } 
      folder_list << '},'
      folder_list << '"standard": {'
      content.each_with_index{|folder,index|
				index==content.length-1 ? last = " " : last = ","
        name_vendor = []
        name_vendor=folder.split("=")
        name_vendor[4] == nil ? name_vendor[4] = '""' : name_vendor[4] = name_vendor[4].chomp
        folder_list << '"' + name_vendor[0].gsub('"','') + '":["' + name_vendor[3].gsub('"','').split(",").join('","') + '","' + name_vendor[4].gsub('"','').split(",").join('","') + '"]' + last
      } 
      folder_list << '},'
      folder_list << '"full_path_materials": "'  + PATH_MAT + '",'
      folder_list << '"materials": {'
      all_folder = Dir.glob(File.join(PATH_MAT, "*")).select {|f| File.directory? f}.uniq.sort_by{ |word| word.to_s.downcase.gsub("ё","е") }
			all_image_files_count = 0
      all_folder.each_with_index{|folder,index|
				last = ","
        last = " " if index != 0 && index==all_folder.length-1
        shot_folder = File.basename(folder)
				all_folder_vendor = Dir.glob(File.join(folder,"*")).select { |f| File.directory? f }
				all_image_files = Dir.glob( File.join(folder,"*.{jpg,jpeg,png,bmp}") ).map {|d| File.basename(d, "*.*")}.sort_by{ |word| word.to_s.downcase.gsub("ё","е") }
				all_image_files_count+=all_image_files.length
        if all_folder_vendor.length == 0
          folder_list << '"'+"#{shot_folder}"+'":' + '['+'"'+"#{all_image_files.join('","')}"+'"]' + last
          else
          folder_vendor = all_folder_vendor.map{|f|f.split(/[\/]/)[-1]}
          folder_list << '"'+"#{shot_folder}"+'":' + '['+'"'+"#{folder_vendor.join('","')}"+'","'+"#{all_image_files.join('","')}"+'"],'
          all_folder_vendor.each_with_index{|path,i|
            vendor_last = ","
            vendor_last = " " if i != 0 && i==all_folder_vendor.length-1 && last == " "
            all_image_files = Dir.glob(File.join(path,"*.{jpg,jpeg,png,bmp}")).map {|d| File.basename(d, "*.*")}.sort_by{ |word| word.to_s.downcase.gsub("ё","е") }
						all_image_files_count+=all_image_files.length
            folder_list << '"'+"#{shot_folder+"^"+path.split(/[\/]/)[-1]}"+'":' + '['+'"'+"#{all_image_files.join('","')}"+'"]' + vendor_last
          }
        end
      }
      folder_list << "}" 
      folder_list << "}"
      File.open(File.join(PATH, "/html/cont/material_list.js"), 'w') { |file|
        folder_list.each { |line| file.puts line }
      }
			p "#{all_image_files_count} files processed in #{Time.new - begin_time} sec"
      return true
    end#def
    def read_param(type_mat,edge_mat=nil)
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
      end
      content = File.readlines(path_param)
      @edge_array, @edge_type_mat_array, @sheet_trim = [], [], 10
      File.open(path_param, "w") { |path|
        content.each { |line|
          parts = line.split("=")
          if edge_mat && parts[1] == "edge_mat"
            path.puts "#{parts[0]}=#{parts[1]}=#{edge_mat}=#{parts[3]}=#{parts[4]}"
            else
            path.puts line
          end
          line_arr = line.strip
          @edge_array << line_arr if line_arr.include?("edge_trim")
          @edge_type_mat_array << line_arr if line_arr.include?("edge_vendor")
          @edge_mat = parts[2] if line_arr.include?("edge_mat") && !edge_mat
          @sheet_trim = parts[2].to_i if line_arr.include?("sheet_trim")
        }
      }
      @max_width_of_count = @max_length = @max_width = nil
      @edge_carcass = @edge_frontal = @edge_gluing = "1"
      @edge_type_mat_array.each { |edge_type_mat|
        path_mat = edge_type_mat.split("=")[0]
        if type_mat.downcase.include?("worktop")
          if type_mat == path_mat
            @max_width_of_count = edge_type_mat.split("=")[2].to_f / 1000
            @max_length = edge_type_mat.split("=")[2].to_i
            break
          end
          else
          if type_mat[0..path_mat.length-1] == path_mat || path_mat == type_mat[-path_mat.length..-1]
            params = edge_type_mat.split("=")[2].split(/x|х/)
            @max_length, @max_width = params.map(&:to_i)
            @edge_carcass, @edge_frontal, @edge_gluing = edge_type_mat.split("=")[3..5]
            break
          end
        end
      }
      @edge_list, @edge_hash, @trim_frontal = [], {}, "0"
      @edge_array.each { |edge_array|
        parts = edge_array.split("=")
        @edge_list << parts[0][4..-1] if parts[0][4..-1] != "0"
        @edge_hash[parts[0][4..-1]] = parts[0][1]
        if @trim_frontal == "0" && @edge_frontal == parts[0][1]
          @trim_frontal = parts[2].to_f*2
        end
      }
      if !@max_width_of_count
        if File.file?(File.join(PATH_MAT,type_mat[0],"_size.dat"))
          @max_width_of_count = File.read(File.join(PATH_MAT,type_mat[0],"_size.dat")).strip.to_f / 1000
        end
      end
    end#def
    def load_material(change_for_type,type_mat,frontal_section,frontal_vendor)
      path_mat = UI.openpanel(SUF_STRINGS["Select texture file"], "c:/", "Image Files|*.jpg;*.jpeg;*.png;||")
      if path_mat
        FileUtils.cp  path_mat, PATH_MAT+"/"+type_mat
        list
        vend = [change_for_type,type_mat,frontal_section,frontal_vendor]
        command = "materials_activate(#{vend.inspect})"
        $dlg_suf.execute_script(command)
        path_price = File.join(PATH_PRICE + "/", "*")
        full_path_price = Dir.glob(path_price).find_all { |l| File.extname(l)[/(xml)/i] }
        all_folder_price = full_path_price.find_all { |i| i.split(/[\/]/) }
        all_folder_price = all_folder_price.map { |f| f=File.basename(f,File.extname(f)) }
        all_folder_price.each { |f| all_folder_price.delete(f) if f == "Фреза_текстура"}
        price_list = ""
        all_folder_price.each{|j| price_list = price_list + j.to_s + "|" }
        price_list = price_list[0...price_list.length-1]
        prefix = ""
        if change_for_type == "Edge"
          prefix = "#{SUF_STRINGS["Edge"]} 0,4х19"
          elsif change_for_type == "Worktop"
          prefix = "#{SUF_STRINGS["worktop"]} 3050*600*38"
          elsif type_mat.include?("LDSP")
          prefix = "#{SUF_STRINGS["Chipboard"]} 16#{SUF_STRINGS["mm"]}"
          elsif type_mat.include?("LMDF")
          prefix = "#{SUF_STRINGS["MDF"]} 16#{SUF_STRINGS["mm"]}"
        end
        prompts = ["#{SUF_STRINGS["Price list"]} ","#{SUF_STRINGS["Name prefix"]} ","#{SUF_STRINGS["The supplier"]} ","#{SUF_STRINGS["Article number"]} ","#{SUF_STRINGS["Unit"]}","#{SUF_STRINGS["Price"]} ","#{SUF_STRINGS["Currency"]} ","#{SUF_STRINGS["Ratio"]} ","#{SUF_STRINGS["Work"]} ","#{SUF_STRINGS["Category"]} "]
        defaults = ["",prefix,"","","#{SUF_STRINGS["m"]}2","400","RUB","2","0","1"]
        list = [price_list,"","","","#{SUF_STRINGS["m"]}2|#{SUF_STRINGS["m"]}|#{SUF_STRINGS["pc"]}","","RUB|AUD|GBP|MDL|BYN|BGN|USD|EUR|KZT|CAD|KGS|CNY|TJS|UZS|UAH","","",""]
        input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Add to price list"]
        if input
          if File.file?( PATH_PRICE + "/" + input[0] + ".xml" )
            param_file = File.new(PATH_PRICE + "/" + input[0] + ".xml","r")
            content = param_file.readlines
            param_file.close
            digit_capacity = content[4][11].gsub("<Digit_capacity>","").gsub("</Digit_capacity>","")
            digit_capacity.length == 1 ? digit_capacity = digit_capacity.to_i : digit_capacity = digit_capacity.to_f
            name_mat = File.basename(path_mat,File.extname(path_mat))
            path_name = type_mat.gsub("_LDSP","").gsub("_LMDF","").gsub("_MDF","").gsub("_COLOR","").gsub("_PLASTIC","").gsub("_SHPON","").gsub("_Worktop","").gsub("_WorkTop","").gsub("_Stone","")
            content.insert(3, "\t\t<Material>\n", "\t\t\t<Provider>"+input[2]+"</Provider>\n", "\t\t\t<Name>"+input[1]+" "+name_mat+", "+path_name+"</Name>\n", "\t\t\t<Article>"+input[3]+"</Article>\n", "\t\t\t<Unit_Measure>"+input[4]+"</Unit_Measure>\n", "\t\t\t<Cost>"+input[5]+"</Cost>\n", "\t\t\t<Currency>"+input[6]+"</Currency>\n", "\t\t\t<Coef>"+input[7]+"</Coef>\n", "\t\t\t<Price>"+((input[5].to_f*input[7].to_f).round(digit_capacity)).to_s+"</Price>\n", "\t\t\t<Work>"+input[8]+"</Work>\n", "\t\t\t<Category>"+input[9]+"</Category>\n", "\t\t\t<Digit_capacity>"+digit_capacity.to_s+"</Digit_capacity>\n", "\t\t</Material>\n")
            xml_file = PATH_PRICE + "/" + input[0] + ".xml"
            new_file = File.open xml_file, "w"
            content.each {|i| new_file.write i }
            new_file.close
          end
        end
      end
    end#def
    def replace_mat(change_for_type,new_mat_name,type_mat,patina_name=SUF_STRINGS["No"],patina_arr=SUF_STRINGS["No"],edge_mat="true")
      @edge_mat = edge_mat
      @random_texture = true
      if new_mat_name.index("_",-5)
        new_mat_name = new_mat_name[0..new_mat_name.index("_",-5)-1]
      end
      @model = Sketchup.active_model
      if !@model.materials.any?{|mat| mat.name == "Wood OSB"}
        material = @model.materials.add("Wood OSB")
        material.texture = File.join(PATH,'additions','DSP.jpg')
      end
      sel = @model.selection
      if sel.count == 0
        UI.messagebox(SUF_STRINGS["No Components Selected"])
        return nil
        elsif type_mat
        if OCL
          if defined? Ladb::OpenCutList::AppObserver
            Ladb::OpenCutList::AppObserver.instance.remove_model_observers(@model)
          end
        end
        read_param(type_mat,edge_mat)
        @model.start_operation('Change materials', true)
        p type_mat
        if type_mat[0..1] == SUF_STRINGS["G_"] || type_mat[0..1] == SUF_STRINGS["M_"]
          type_mat_new = type_mat[2..-1]
          folder_mat = PATH_MAT+"/" + type_mat_new + "/" + new_mat_name
          new_mat_name = type_mat[0..1]+new_mat_name
          else
          folder_mat = PATH_MAT+"/" + type_mat + "/" + new_mat_name
        end
        @edge_r = ""
        if new_mat_name.include?(" R-")
          ind = new_mat_name.rindex(" R-")
          @edge_r = new_mat_name[ind..ind+3].strip
          new_mat_name = new_mat_name.gsub(" R-6","").gsub(" R-3","").gsub(" R-2","")
        end
        new_mat_name = File.basename(new_mat_name,".*").gsub("(","[").gsub(")","]")
        new_mat_name += " " if new_mat_name[-1] == "]"
        mat_names = []
        @model.materials.each{|m| mat_names << m.display_name.downcase}
        if !mat_names.include?(new_mat_name.downcase)
          new_mat= @model.materials.add new_mat_name
          new_mat.texture= folder_mat
          if new_mat.texture
            mat_width= new_mat.texture.image_width
            mat_height= new_mat.texture.image_height
            new_mat.texture.size= [mat_width.to_f.mm, mat_height.to_f.mm]
          end
        end
        if change_for_type == "Frontal"
          input = [@back_material_input]
          if type_mat && type_mat.include?("LDSP") || type_mat && type_mat.include?("LMDF")
            sel.grep(Sketchup::ComponentInstance).each { |e| frontal_edge_trim(e, @edge_frontal, @trim_frontal) } if @edge_mat == "true"
            elsif type_mat && type_mat.include?("COLOR") || type_mat && type_mat.include?("MDF") || type_mat && type_mat.include?("PLASTIC") || type_mat && type_mat.include?("SHPON")
            input = UI.inputbox ["#{SUF_STRINGS["Back side of fronts"]} "], [@back_material_input], ["#{SUF_STRINGS["Same as front color"]}|#{SUF_STRINGS["White"]}|#{SUF_STRINGS["White + Stripe in front color"]}"], SUF_STRINGS["Front material"]
            @back_material_input = input[0] if input
            return if !input
            sel.grep(Sketchup::ComponentInstance).each { |e| frontal_edge_trim(e, @edge_frontal, 0) } if @edge_mat == "true"
            else
            sel.grep(Sketchup::ComponentInstance).each { |e| frontal_edge_trim(e, @edge_frontal, 0) } if @edge_mat == "true"
          end
        end
        input_edge = nil
        if change_for_type == "Edge"
          if File.file?(File.join(TEMP_PATH,"SUF","edge_material.dat"))
            path_param = File.join(TEMP_PATH,"SUF","edge_material.dat")
            elsif File.file?(File.join(PATH,"parameters","edge_material.dat"))
            path_param = File.join(PATH,"parameters","edge_material.dat")
          end
          param_file = File.new(path_param,"r")
          defaults_edge = param_file.readlines.map{|str|str.strip}
          param_file.close
          
          prompts_edge = ["#{SUF_STRINGS["Paint edge"]} ","#{SUF_STRINGS["Change thickness"]} ","#{SUF_STRINGS["Add glue to name"]} "]
          glue_arr = ["PUR","EVA","LASER"]
          list_edge = ["#{SUF_STRINGS["Fronts"]}|#{SUF_STRINGS["By panel face"]}|#{SUF_STRINGS["Everywhere applicable"]}","#{SUF_STRINGS["No"]}|"+@edge_list.join("|"),"#{SUF_STRINGS["No"]}|"+glue_arr.join("|")]
          input_edge = UI.inputbox prompts_edge, defaults_edge, list_edge, SUF_STRINGS["Edge on parts"]
          if input_edge
            path_param = File.join(TEMP_PATH,"SUF","edge_material.dat")
            File.open(path_param, "w") { |param_file| input_edge.each { |value| param_file.puts value } }
          end
        end
        if change_for_type == "Glass"
          @random_texture = false
          if new_mat_name.include?("Гравировка") || new_mat_name.include?("гравировка") || new_mat_name.include?("Фотопечать") || new_mat_name.include?("фотопечать")
            prompts = [SUF_STRINGS["By width"],SUF_STRINGS["By height"]]
            defaults = ["1","1"]
            list = ["1|2|3|4|5|6|7|8|9","1|2|3|4|5|6|7|8|9"]
            input_glass = UI.inputbox prompts, defaults, list, SUF_STRINGS["Copy texture"]
          end
        end
        DCProgressBar::clear()
        begin_time = Time.new
        sel.grep(Sketchup::ComponentInstance).each { |e|
          case change_for_type
            when "Frontal" then change_Frontal_material(e,new_mat_name,type_mat,input,patina_name,patina_arr)
            when "Carcass" then change_Carcass_material(e,new_mat_name,@edge_carcass,@edge_gluing,type_mat)
            when "Edge" then change_Edge_material(e,new_mat_name,input_edge,defaults_edge) if input_edge
            when "Back" then change_Back_material(e,new_mat_name,true,type_mat)
            when "Drawer" then change_Drawer_material(e,new_mat_name,type_mat)
            when "Handle" then change_Handle_material(e,new_mat_name)
            when "Worktop" then change_Worktop_material(e,new_mat_name,type_mat)
            when "Plinth" then change_Plinth_material(e,new_mat_name)
            when "Glass" then change_Glass_material(e,new_mat_name,input_glass)
            when "Metal" then change_Metal_material(e,new_mat_name)
            else change_All_material(e,new_mat_name)
          end
        }
        if new_mat_name.include?("Зеркало")
          @glass_width = 1
          @glass_height = 1
          @model.entities.grep(Sketchup::ComponentInstance).each { |e| search_glass(e) }
          mat = @model.materials.detect{|i| i.display_name.include?("Зеркало")}
          mat.texture.size = [@glass_width.round+10,@glass_height.round+10] if mat
        end
        @model.materials.purge_unused
        @model.commit_operation
        end_time = Time.new
        p "change_material in #{end_time - begin_time} seconds"
        DCProgressBar::clear()
        #UI.refresh_inspectors
      end
      @max_width_of_count = @max_length = @max_width = nil
    end#def
    def search_glass(e)
      if e.material && e.material.display_name.include?("Зеркало")
        a01_lenx = e.definition.get_attribute("dynamic_attributes", "a01_lenx", "0")
        a01_lenz = e.definition.get_attribute("dynamic_attributes", "a01_lenz", "0")
        @glass_width = a01_lenx.to_f if @glass_width < a01_lenx.to_f
        @glass_height = a01_lenz.to_f if @glass_height < a01_lenz.to_f
      end
      e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| search_glass(ent) }
    end#def
    def search(new_mat_name,change_for_type=nil)
      type_mat = nil
      new_mat_name = new_mat_name.encode("utf-8")
      new_mat_name = new_mat_name[2..-1] if new_mat_name[0..1] == SUF_STRINGS["G_"] || new_mat_name[0..1] == SUF_STRINGS["M_"]
      @file_name = nil
      vend = nil
      if new_mat_name.index("_",-5)
        my_str = new_mat_name[0..new_mat_name.index("_",-5)-1]
        else
        my_str = new_mat_name
      end
      my_str_strip = my_str.strip
      mat_dir = Dir.new(PATH_MAT+"")
      dir_arr = mat_dir.entries
      dir_arr.map! {|dir| dir.encode("utf-8")}
      if change_for_type
        if @material_path[change_for_type]
          filtered_arr = []
          @material_path[change_for_type].each { |filter| filtered_arr += dir_arr.select { |d| d.downcase.include?(filter.downcase) } }
          dir_arr = filtered_arr
        end
      end
      dir_arr.each { |d|
        d = d.encode("utf-8")
        ext_arr = [".jpg",".jpeg",".png"]
        ext_arr.each { |ext|
          if File.file? PATH_MAT+"/" + d + "/" + my_str_strip + ext
            @file_name = PATH_MAT+"/" + d + "/" + my_str_strip + ext
            type_mat = d
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str_strip.gsub("(","[").gsub(")","]") + ext
            @file_name = PATH_MAT+"/" + d + "/" + my_str_strip.gsub("(","[").gsub(")","]") + ext
            type_mat = d
            elsif File.file? PATH_MAT+"/" + d + "/" + my_str_strip.gsub("[","(").gsub("]",")") + ext
            @file_name = PATH_MAT+"/" + d + "/" + my_str_strip.gsub("[","(").gsub("]",")") + ext
            type_mat = d
          end
        }
      }
      if @file_name != nil
        file_name_arr = @file_name.split(/[\/]/)
        length_name = file_name_arr.length
        vend = file_name_arr[length_name-2..length_name-1]
        else
        vend = [0, my_str]
      end
      command = "onVend(#{vend.inspect})"
      $dlg_suf.execute_script(command)
      return type_mat
    end
    def frontal_edge_trim(e, edge, edge_trim)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      aaa_info = e.definition.get_attribute("dynamic_attributes", "aaa_info")
      itemcode = e.definition.get_attribute("dynamic_attributes", "itemcode")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      if itemcode && itemcode[0] != "E" && itemcode[0] != "C"
        if type.include?("frontal") || type.include?("carcass") && type.include?("Фасад") || type.include?("body") && e.definition.name.include?("HF")
          e.definition.delete_attribute("dynamic_attributes", "_material_formula")
          set_att(e,"edge_trim",0)
          attributes = ["edge_y1", "edge_y2", "edge_z1", "edge_z2"]
          attributes.each { |attr| set_att(e,attr,edge) }
          elsif l1_component_101_name.include?("ЛДСП") && l1_component_102_article.include?("Фасад")
          e.definition.delete_attribute("dynamic_attributes", "_material_formula")
          e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| egde_easy_kitchen(ent,edge_trim) }
          elsif aaa_info && type.include?("Фасад") || aaa_info && type.include?("МДФ")
          e.definition.delete_attribute("dynamic_attributes", "_material_formula")
          edge_type_mappings = { "1" => "0", "2" => "0.4", "3" => "0.4 00", "4" => "1", "5" => "1 000", "6" => "2", "7" => "2 000" }
          edge_type = edge_type_mappings[edge.to_s] || 1
          attributes = ["y1_krom_speredi", "y2_krom_szadi", "y3_krom_sverhu", "y4_krom_snizu"]
          attributes.each { |attr| set_att(e,attr,edge_type) }
          if type.include?("body") && e.definition.name.include?("HF")
            e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| frontal_edge_trim(ent, edge, edge_trim) }
          end
          else
          e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| frontal_edge_trim(ent, edge, edge_trim) }
        end
        elsif type.include?("Body") || type.include?("body")
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| frontal_edge_trim(ent, edge, edge_trim) }
      end
    end#def
    def egde_easy_kitchen(e,edge_trim)
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      if l1_component_101_name.include?("ЛДСП") && l1_component_102_article.include?("Фасад")
        set_att(e,"edge_trim",edge_trim)
        else
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| egde_easy_kitchen(ent,edge_trim) }
      end
    end#def
    def change_krom(e,new_mat_name,edge,edge_gluing=nil)
      edge = "1" if !edge
      a01_gluing = e.definition.get_attribute("dynamic_attributes", "a01_gluing")
      lenx = e.definition.get_attribute("dynamic_attributes", "lenx", 0).to_f
      leny = e.definition.get_attribute("dynamic_attributes", "leny", 0).to_f
      lenz = e.definition.get_attribute("dynamic_attributes", "lenz", 0).to_f
      thickness = (([lenx,leny,lenz].sort[0]*25.4)+0.1).floor
      if a01_gluing && a01_gluing.to_f > 1 && edge_gluing
        edge = edge_gluing
        elsif thickness == 32 || thickness == 36
        edge = edge_gluing
      end
      edge_y1_texture = e.definition.get_attribute("dynamic_attributes", "edge_y1_texture")
      if edge_y1_texture
        edge_type = edge
        else
        case edge.to_s
          when "1" then edge_type = "0"
          when "2" then edge_type = "0.4"
          when "3" then edge_type = "0.4 с подрезкой"
          when "4" then edge_type = "1"
          when "5" then edge_type = "1 с подрезкой"
          when "6" then edge_type = "2"
          when "7" then edge_type = "2 с подрезкой"
        end
      end
      set_att(e,"a00_mat_krom",new_mat_name)
      
      y3_mat = e.definition.get_attribute("dynamic_attributes", "y3_mat")
      set_att(e,"y3_mat",1) if y3_mat
      
      if e.definition.get_attribute("dynamic_attributes", "_lenz_formula", "0").include?("r1_bottom")
        e.definition.set_attribute("dynamic_attributes", "_lenz_formula", 'LOOKUP("r1_bottom")')
      end
      
      edge_y1 = e.definition.get_attribute("dynamic_attributes", "edge_y1")
      edge_y1_length = e.definition.get_attribute("dynamic_attributes", "edge_y1_length")
      edge_y2 = e.definition.get_attribute("dynamic_attributes", "edge_y2")
      edge_y2_length = e.definition.get_attribute("dynamic_attributes", "edge_y2_length")
      edge_z1 = e.definition.get_attribute("dynamic_attributes", "edge_z1")
      edge_z1_length = e.definition.get_attribute("dynamic_attributes", "edge_z1_length")
      edge_z2 = e.definition.get_attribute("dynamic_attributes", "edge_z2")
      edge_z2_length = e.definition.get_attribute("dynamic_attributes", "edge_z2_length")
      if edge_y1_length && edge_y2_length && edge_z1_length && edge_z2_length
        if edge_y1.to_s == "1" && edge_y1_length.to_s == "1"
          elsif edge_y1_length.to_s != "0" && edge_y1_length.to_s != "0.0"
          _edge_y1_formula = e.definition.get_attribute("dynamic_attributes", "_edge_y1_formula")
          if _edge_y1_formula && _edge_y1_formula.include?("LOOKUP")
            e.definition.set_attribute("dynamic_attributes", "_edge_y1_formula", 'LOOKUP("edge_default","'+edge_type+'")')
            else
            set_att(e,"edge_y1",edge_type)
          end
        end
        if edge_y2.to_s == "1" && edge_y2_length.to_s == "1"
          elsif edge_y2_length.to_s != "0" && edge_y2_length.to_s != "0.0"
          _edge_y2_formula = e.definition.get_attribute("dynamic_attributes", "_edge_y2_formula")
          if _edge_y2_formula && _edge_y2_formula.include?("LOOKUP")
            e.definition.set_attribute("dynamic_attributes", "_edge_y2_formula", 'LOOKUP("edge_default","'+edge_type+'")')
            else
            set_att(e,"edge_y2",edge_type)
          end
        end
        if edge_z1.to_s == "1" && edge_z1_length.to_s == "1"
          elsif edge_z1_length.to_s != "0" && edge_z1_length.to_s != "0.0"
          _edge_z1_formula = e.definition.get_attribute("dynamic_attributes", "_edge_z1_formula")
          if _edge_z1_formula && _edge_z1_formula.include?("LOOKUP")
            e.definition.set_attribute("dynamic_attributes", "_edge_z1_formula", 'LOOKUP("edge_default","'+edge_type+'")')
            else
            set_att(e,"edge_z1",edge_type)
          end
        end
        if edge_z2.to_s == "1" && edge_z2_length.to_s == "1"
          elsif edge_z2_length.to_s != "0" && edge_z2_length.to_s != "0.0"
          _edge_z2_formula = e.definition.get_attribute("dynamic_attributes", "_edge_z2_formula")
          if _edge_z2_formula && _edge_z2_formula.include?("LOOKUP")
            e.definition.set_attribute("dynamic_attributes", "_edge_z2_formula", 'LOOKUP("edge_default","'+edge_type+'")')
            else
            set_att(e,"edge_z2",edge_type)
          end
        end
      end
    end
    def set_type_mat(e,type_mat)
      if e.definition.get_attribute("dynamic_attributes", "_material_formula")
        set_att(e,"type_material",type_mat)
      end
      e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| set_type_mat(ent,type_mat) }
    end
    def change_mat(e, new_mat_name, back_mat_name, pref_thick=true, type_mat="")
      DCProgressBar.advance(true)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      e.make_unique
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      lenx = e.definition.get_attribute("dynamic_attributes", "lenx", 0).to_f
      leny = e.definition.get_attribute("dynamic_attributes", "leny", 0).to_f
      lenz = e.definition.get_attribute("dynamic_attributes", "lenz", 0).to_f
      thickness = ([lenx,leny,lenz].sort[0]*25.4).round(1)
      @model = Sketchup.active_model
      if !new_mat_name.include?("_"+thickness.to_s) && pref_thick==true
        a01_gluing = e.definition.get_attribute("dynamic_attributes", "a01_gluing")
        if a01_gluing && a01_gluing.to_f > 1
          mat_name = new_mat_name+"_"+(thickness/a01_gluing.to_f).round(1).to_s
          elsif thickness == 32 || thickness == 36
          mat_name = new_mat_name+"_"+(thickness/2).to_s
          else
          mat_name = new_mat_name+"_"+thickness.to_s
        end
        else
        mat_name = new_mat_name
      end
      add_material(new_mat_name,mat_name) if pref_thick==true
      e.material = mat_name
      set_att(e,"material",mat_name)
      
      if back_mat_name == "White" || pref_thick==false && back_mat_name == "White"
        back_material_input = "1"
        back_name = back_mat_name
        elsif back_mat_name == "White_and_stripe"
        back_material_input = "3"
        back_name = back_mat_name
        else
        back_material_input = "2"
        back_name = mat_name
      end
      set_att(e,"back_material_input",back_material_input,"back_material_input","LIST","Материал задней стороны","FLOAT","STRING",nil,'&%u0411%u0435%u043B%u0430%u044F=1&%u0412%20%u0446%u0432%u0435%u0442%20%u043B%u0438%u0446%u0435%u0432%u043E%u0439=2&%u0411%u0435%u043B%u0430%u044F%20+%20%u041F%u043E%u043B%u043E%u0441%u0430%20%u0432%20%u0446%u0432%u0435%u0442%20%u043B%u0438%u0446%u0435%u0432%u043E%u0439=3&')
      
      e.definition.delete_attribute("dynamic_attributes", "_back_material_formula")
      set_att(e,"back_material",back_name,"back_material","NONE","Материал задней стороны","STRING","STRING",'CHOOSE(back_material_input,"White",Material,"White_and_stripe")','&')
      
      if !e.definition.get_attribute("dynamic_attributes", "back_side")
        if e.definition.get_attribute("dynamic_attributes", "point_x_offset")
          set_att(e,"back_side","1","back_side","LIST","Задняя сторона","FLOAT","STRING",nil,'&%u0421%u043B%u0435%u0432%u0430=1&%u0421%u043F%u0440%u0430%u0432%u0430=2&')
          elsif e.definition.get_attribute("dynamic_attributes", "point_y_offset")
          set_att(e,"back_side","1","back_side","LIST","Задняя сторона","FLOAT","STRING",nil,'&%u0421%u0437%u0430%u0434%u0438=1&%u0421%u043F%u0435%u0440%u0435%u0434%u0438=2&')
          elsif e.definition.get_attribute("dynamic_attributes", "point_z_offset")
          set_att(e,"back_side","1","back_side","LIST","Задняя сторона","FLOAT","STRING",nil,'&%u0421%u0432%u0435%u0440%u0445%u0443=1&%u0421%u043D%u0438%u0437%u0443=2&')
          else
          set_att(e,"back_side","2","back_side","LIST","Задняя сторона","FLOAT","STRING",nil,'&%u0421%u0432%u0435%u0440%u0445%u0443=1&%u0421%u043D%u0438%u0437%u0443=2&')
        end
      end
      e.definition.get_attribute("dynamic_attributes", "back_stripe_width") ? back_stripe_width = nil : back_stripe_width = 100/25.4
      set_att(e,"back_stripe_width",back_stripe_width,"back_stripe_width","TEXTBOX","Ширина полосы","CENTIMETERS","MILLIMETERS",nil,'&')
      set_att(e,"back_side_opt","0","back_side_opt",nil,nil,nil,nil,'SETACCESS("back_stripe_width",CHOOSE(back_material_input,0,0,2))',nil)
      
      type_mat="" if !type_mat
      if type_mat != ""
        set_att(e,"type_material",type_mat)
        e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent| set_type_mat(ent,type_mat) }
      end
      z_size_mat = e.definition.get_attribute("dynamic_attributes", "z_size_mat", "2")
      z_max_length = e.definition.get_attribute("dynamic_attributes", "z_max_length")
      if z_size_mat=="2" && z_max_length
        if @max_length || @max_width
          if type_mat.downcase.include?("worktop")
            trim = 0
            else
            trim = @sheet_trim*2
          end
          set_att(e,"z_max_length",(@max_length-trim)/10) if @max_length
          set_att(e,"z_max_width",(@max_width-trim)/10) if @max_width
        end
      end
      if !e.definition.get_attribute("dynamic_attributes", "edge_color")
        set_att(e,"a00_mat_krom",mat_name)
      end
      
      Redraw_Components.run_all_formulas(e)
      groove = e.definition.get_attribute("dynamic_attributes", "groove", "0")
      redraw_essence(e,mat_name,groove)
      Redraw_Components.run_all_formulas(e)
    end
    def redraw_essence(e,mat_name=nil,groove=nil,delete_grooves=false)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      e.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
        if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
          ent.make_unique if ent.definition.count_instances > 1
          ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
          ent.material = mat_name if mat_name
          edge_label = ent.definition.get_attribute("dynamic_attributes", "edge_label")
          if edge_label
            ent.definition.set_attribute("dynamic_attributes", "_edge_label_formula", 'EDGEMAT(IF(AND(LOOKUP("edge_y1")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_y1_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_y2")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_y2_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_z1")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_z1_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))),IF(AND(LOOKUP("edge_z2")=1,LOOKUP("su_type")="carcass"),"DSP",CHOOSE(LOOKUP("edge_z2_texture"),LOOKUP("material"),LOOKUP("a07_mat_krom"))))')
          end
          if ent.definition.get_attribute("dynamic_attributes", "_back_material_formula", "0") == 'CHOOSE(back_material_input,"White",Material)'
            ent.definition.set_attribute("dynamic_attributes", "_back_material_formula", 'CHOOSE(LOOKUP("back_material_input",1),"White",Material,"White_and_stripe")')
          end
          if ent.definition.get_attribute("dynamic_attributes", "_texturemat_formula", "1") == '1'
            ent.definition.set_attribute("dynamic_attributes", "_edge_label_formula", 'EDGEMAT(0,0,0,0)')
            else
            ent.definition.set_attribute("dynamic_attributes", "_texturemat_formula", 'TEXTUREMAT(LOOKUP("napr_texture"),Material,LOOKUP("back_material"),1,LOOKUP("back_side",1),LOOKUP("back_stripe_width",1))')
          end
          ent.definition.entities.grep(Sketchup::Face) { |f|
            f.material = nil
            if f.bounds.center.x==0 && (f.normal.x+0.01).round(1).abs == 1 && f.area>0.1 
              f.set_attribute("dynamic_attributes", "face", "primary_back") 
            end
          }
          att_arr = ['material','back_material','a00_mat_krom','edge_label','front_mat']
          att_arr += ['texturemat'] if @random_texture
          Redraw_Components.run_all_formulas(ent)
          essence_entities(ent,mat_name,groove,delete_grooves)
          elsif ent.layer.name.include?("Фасад_открывание")
          Redraw_Components.redraw(ent,false)
          elsif ent.definition.name.include?("Body")
          ent.make_unique if ent.definition.count_instances > 1
          ent.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if ent.parent.is_a?(Sketchup::ComponentDefinition)
          redraw_essence(ent,mat_name,groove,groove=="0")
        end
      }
    end#def
    def essence_entities(essence,mat_name,groove,delete_grooves)
      essence.definition.entities.grep(Sketchup::ComponentInstance).each { |ent|
        if ent.definition.name.include?("groove")
          ent.erase! if delete_grooves
          elsif Redraw_Components.get_attribute_formula(ent,'material')
          Redraw_Components.run_all_formulas(ent)
          new_mat_name = ent.definition.get_attribute("dynamic_attributes", "material", mat_name)
          if new_mat_name.length > 3
            if @model.materials.any? {|mat| mat.display_name.include?(new_mat_name) }
              ent.material = new_mat_name
              else
              ent.material = mat_name
            end
          end
        end
      }
    end#def
    def add_material(new_mat_name,mat_name)
      mat_names = []
      @model = Sketchup.active_model
      @model.materials.each{|m| mat_names << m.display_name}
      if !mat_names.include?(mat_name)
        info_mat = @model.materials.detect { |m| m.display_name.include?(new_mat_name) }
        if info_mat
          new_mat = @model.materials.add(mat_name)
          if info_mat.texture
            new_mat.texture = info_mat.texture.image_rep
            mat_width= info_mat.texture.image_width
            mat_height= info_mat.texture.image_height
            new_mat.texture.size= [mat_width.to_f.mm, mat_height.to_f.mm]
            else
            new_mat.color = info_mat.color
          end
        end
      end
    end#def
    def change_Frontal_material(e,new_mat_name,type_mat,input=[SUF_STRINGS["White"]],patina_name=SUF_STRINGS["No"],patina_arr=[])
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      aaa_info = e.definition.get_attribute("dynamic_attributes", "aaa_info")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      l1_component_100_module = e.definition.get_attribute("dynamic_attributes", "l1_component_100_module", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
      if l1_component_101_name.include?("ЛДСП") && l1_component_102_article.include?("Фасад") || type.include?("Доступна функция горячей замены") && l1_component_102_article.include?("Фасад") #EasyKitchen
        e.definition.delete_attribute("dynamic_attributes", "_material_formula")
        change_mat(e, new_mat_name, new_mat_name, false, type_mat)
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif aaa_info && type.include?("Фасад") #SDCF
        e.definition.delete_attribute("dynamic_attributes", "_material_formula")
        change_mat(e, new_mat_name, new_mat_name, false, type_mat)
        elsif !item_code.include?("Cs") && type.include?("Фасад") || !item_code.include?("Cs") && type.include?("МДФ") || !item_code.include?("Cs") && type.include?("frontal")
        e.definition.delete_attribute("dynamic_attributes", "_material_formula")
        return if type.to_s.downcase =~ /рамка|integro|макмарт/i
        if type_mat && type_mat.include?("LDSP") || type_mat && type_mat.include?("LMDF")
          if type.include?("Радиус")
            UI.messagebox("Радиусный фасад невозможно сделать из ЛДСП!")
            elsif type.include?("Модерн") || type.include?("frontal")
            change_mat(e, new_mat_name, new_mat_name, true, type_mat)
          end
          else
          if input && input[0] == SUF_STRINGS["White"]
            change_mat(e, new_mat_name, "White", true, type_mat)
            elsif input && input[0] == SUF_STRINGS["White + Stripe in front color"]
            change_mat(e, new_mat_name, "White_and_stripe", true, type_mat)
            else
            change_mat(e, new_mat_name, new_mat_name, true, type_mat)
          end
          patina_options = "&"
          if patina_name == SUF_STRINGS["No"]
            set_att(e,"ad_material","0","ad_material","NONE","Патина","STRING","STRING",nil,patina_options)
            else
            options = patina_arr.split(",")
            options.each { |option| patina_options += option+"="+option+"&" }
            e.definition.set_attribute("dynamic_attributes", "_ad_material_options", patina_options)
            set_att(e,"ad_material",patina_name,"ad_material","NONE","Патина","STRING","STRING",nil,patina_options)
          end
        end
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || type.include?("frontal") && item_code.include?("Cs1")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        b1_f_thickness = e.definition.get_attribute("dynamic_attributes", "b1_f_thickness")
        if b1_f_thickness
          mat_name = new_mat_name+"_"+(b1_f_thickness.to_f*25.4).round(1).to_s 
          else
          mat_name = new_mat_name
        end
        set_att(e,"b1_f_material",mat_name)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Frontal_material(ent, new_mat_name, type_mat, input,patina_name,patina_arr) }
        elsif !g1_module_100_name.include?("0") || !l1_component_100_module.include?("0") || l1_component_101_name.include?("ящик") || component_101_name.include?("ящик")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Frontal_material(ent, new_mat_name, type_mat, input,patina_name,patina_arr) }
      end
    end#def
    
    def change_Carcass_material(e,new_mat_name,edge=nil,edge_gluing=nil,type_mat="")
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      name = e.definition.get_attribute("dynamic_attributes", "_name", "0")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_100_module = e.definition.get_attribute("dynamic_attributes", "l1_component_100_module", "0")
      component_100_module = e.definition.get_attribute("dynamic_attributes", "component_100_module", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      l1_component_302_shelves_quantity = e.definition.get_attribute("dynamic_attributes", "l1_component_302_shelves_quantity")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
      if type.include?("carcass") || type.include?("ЛДСП") && !type.include?("frontal") && !type.include?("glass") && !type.include?("Фасад") && !type.include?("ЗС") && !type.include?("ХДФ")
        change_krom(e,new_mat_name,edge,edge_gluing) if edge && @edge_mat=="true"
        change_mat(e,new_mat_name,new_mat_name,true,type_mat)
        elsif l1_component_101_name.include?("ЛДСП") && !l1_component_102_article.include?("Фасад") || name.include?("module_drawer") || l1_component_101_name.include?("1") && !l1_component_302_shelves_quantity
        change_krom(e,new_mat_name,edge,edge_gluing) if edge && @edge_mat=="true"
        change_mat(e,new_mat_name,new_mat_name,false,type_mat)
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || type.include?("frontal")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        if edge && @edge_mat=="true"
          edge_default_formula = e.definition.get_attribute("dynamic_attributes", "_edge_default_formula")
          if edge_default_formula && edge_default_formula.include?("LOOKUP")
            e.definition.set_attribute("dynamic_attributes", "_edge_default_formula", 'LOOKUP("edge_default","'+edge+'")')
          end
          
          edge_default = e.definition.get_attribute("dynamic_attributes", "b3_edge_default")
          if edge_default
            set_att(e,"b3_edge_default",edge)
            set_att(e,"edge_default",edge)
            else
            edge_default = e.definition.get_attribute("dynamic_attributes", "edge_default")
            set_att(e,"edge_default",edge) if edge_default
          end
        end
        z_max_height = e.definition.get_attribute("dynamic_attributes", "z_max_height")
        if e.definition.name == "Секция с панелями" || e.definition.name == "Секция с полками" || e.definition.name == "Тумба" || e.definition.name == "Корпус шкафа"
          if @max_length
            if z_max_height != @max_length/10-@sheet_trim/10*2
              set_att(e,"z_max_height",@max_length/10-@sheet_trim/10*2)
              set_att(e,"z_max_panel_width",@max_length/10-@sheet_trim/10*2)
              Redraw_Components.redraw_entities_with_Progress_Bar([e])
            end
          end
        end
        b1_p_thickness = e.definition.get_attribute("dynamic_attributes", "b1_p_thickness")
        if b1_p_thickness 
          mat_name = new_mat_name+"_"+(b1_p_thickness.to_f*25.4).round(1).to_s
          set_att(e,"b1_p_material",mat_name)
        end
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Carcass_material(ent,new_mat_name,edge,edge_gluing,type_mat) }
        elsif !g1_module_100_name.include?("0") || !l1_component_100_module.include?("0") || l1_component_101_name.include?("ящик") || component_101_name.include?("ящик")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Carcass_material(ent,new_mat_name,edge,edge_gluing,type_mat) }
      end 
    end#def
    
    def change_Edge_material(e, new_mat_name, input, defaults)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      e.make_unique
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      input = defaults if !input
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      y1_mat, y2_mat, y3_mat, y4_mat = get_attributes(e.definition, %w[y1_mat y2_mat y3_mat y4_mat], nil)
      edge_z1, edge_z2, edge_y1, edge_y2 = get_attributes(e.definition, %w[edge_z1 edge_z2 edge_y1 edge_y2], "1")
      edge_z1_length, edge_z2_length, edge_y1_length, edge_y2_length = get_attributes(e.definition, %w[edge_z1_length edge_z2_length edge_y1_length edge_y2_length], "0")
      edge_z1_texture = e.definition.get_attribute("dynamic_attributes", "edge_z1_texture")
      a0_lenx, a0_leny, a0_lenz = get_attributes(e.definition, %w[lenx leny lenz], 0).map(&:to_f)
      dep = [a0_lenx, a0_leny, a0_lenz].min
      redraw = false
      texture_attributes = {}
      mat_attributes = {}
      if type.include?("carcass") && !type.include?("Фасад") || type.include?("ЛДСП") && !type.include?("Фасад") && !type.include?("МДФ") && !type.include?("ЗС")
        
        
        if input[0] == SUF_STRINGS["By panel face"]
          if dep == a0_lenx || dep == a0_lenz
            redraw = true
            mat_attributes = {"y3_mat"=>2} if y3_mat
            texture_attributes = {"edge_y1_texture"=>1, "edge_y2_texture"=>1, "edge_z1_texture"=>2, "edge_z2_texture"=>1} if edge_z1_texture
            if input[1] != SUF_STRINGS["No"]
              edge_z1_texture ? edge_z1 = @edge_hash[input[1]] : edge_z1 = input[1].gsub(" мм","")
              set_att(e,"edge_z1",edge_z1)
            end
          end
          
          
          elsif input[0] == SUF_STRINGS["Everywhere applicable"]
          redraw = true
          texture_attributes = {"edge_y1_texture"=>2, "edge_y2_texture"=>2, "edge_z1_texture"=>2, "edge_z2_texture"=>2} if edge_z1_texture
          mat_attributes = {"y3_mat"=>2} if y3_mat
          if input[1] != SUF_STRINGS["No"]
            edge_value = edge_z1_texture ? @edge_hash[input[1]] : input[1].gsub(" мм", "")
            { "edge_z1" => [edge_z1, edge_z1_length],"edge_z2" => [edge_z2, edge_z2_length],"edge_y1" => [edge_y1, edge_y1_length],"edge_y2" => [edge_y2, edge_y2_length]
              }.each { |key, (edge_flag, edge_len)|
              if (edge_z1_texture && edge_flag != "1") || (edge_len != "0" && edge_flag != "0")
                set_att(e, key, edge_value)
              end
            }
          end
        end
        
        elsif type.include?("frontal") || type.include?("Фасад") || type.include?("МДФ")
        if input[0] == SUF_STRINGS["Fronts"]
          redraw = true
          texture_attributes = {"edge_y1_texture"=>2, "edge_y2_texture"=>2, "edge_z1_texture"=>2, "edge_z2_texture"=>2} if edge_z1_texture
          mat_attributes = {"y1_mat"=>2,"y2_mat"=>2,"y3_mat"=>2,"y4_mat"=>2} if y1_mat
        end
      end
      
      if redraw
        set_att(e,"a00_mat_krom",new_mat_name)
        texture_attributes.each { |attr,value| set_att(e,attr,value) }
        mat_attributes.each { |attr,value| set_att(e,attr,value) }
        if input[2] && input[2] == SUF_STRINGS["No"]
          del_att(e,"edge_glue")
          else
          set_att(e,"edge_glue",input[2])
        end
        Redraw_Components.run_all_formulas(e)
        redraw_essence(e)
        Redraw_Components.run_all_formulas(e)
      end
      e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Edge_material(ent, new_mat_name, input, defaults) }
      end#def
    
    def change_Back_material(e, new_mat_name, pref_thick=true,type_mat="")
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      item_code = e.definition.get_attribute("dynamic_attributes", "itemcode", "0")
      c7_naves = e.definition.get_attribute("dynamic_attributes", "c7_naves")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_100_module = e.definition.get_attribute("dynamic_attributes", "l1_component_100_module", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      if type.include?("ЗС") && !type.include?("Ящик") && !type.include?("carcass") || type.include?("ХДФ") && !type.include?("glass") && !type.include?("carcass") || type.include?("back") || l1_component_101_name.include?("ХДФ") || l1_component_101_name.include?("3")
        change_mat(e,new_mat_name,new_mat_name,pref_thick,type_mat)
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        b1_b_thickness = e.definition.get_attribute("dynamic_attributes", "b1_b_thickness")
        b1_b_thickness && pref_thick==true ? mat_name = new_mat_name+"_"+(b1_b_thickness.to_f*25.4).round(1).to_s : mat_name = new_mat_name
        set_att(e,"b1_b_material",mat_name)
        if 1==2 # навесы верхних модулей
          if item_code[0] == "V" || item_code[0] == "A"
            if new_mat_name.include?("Белый")
              e.set_attribute("dynamic_attributes", "c7_naves", 2) if c7_naves
              e.definition.set_attribute("dynamic_attributes", "c7_naves", 2) if c7_naves
              else
              e.set_attribute("dynamic_attributes", "c7_naves", 3) if c7_naves
              e.definition.set_attribute("dynamic_attributes", "c7_naves", 3) if c7_naves
            end
            Redraw_Components.redraw_entities_with_Progress_Bar([e])
          end
        end
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Back_material(ent, new_mat_name, pref_thick,type_mat) }
        elsif !g1_module_100_name.include?("0") || !l1_component_100_module.include?("0") || l1_component_101_name.include?("ящик") || component_101_name.include?("ящик")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Back_material(ent, new_mat_name, pref_thick,type_mat) }
      end
    end#def
    
    def change_Drawer_material(e, new_mat_name, pref_thick=true,type_mat="")
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      name = e.definition.get_attribute("dynamic_attributes", "_name", "0")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_100_module = e.definition.get_attribute("dynamic_attributes", "l1_component_100_module", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      if type.include?("Ящ") && type.include?("carcass") || type.include?("Ящ") && type.include?("ЛДСП") || name.include?("module_drawer") || l1_component_101_name.include?("1") && l1_component_102_article.include?("ящ")
        change_mat(e,new_mat_name,new_mat_name,pref_thick,type_mat)
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Тело") || type.include?("Каркас") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || !g1_module_100_name.include?("0") || l1_component_101_name.include?("ящ") || component_101_name.include?("ящ") || !l1_component_100_module.include?("0")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Drawer_material(ent, new_mat_name, pref_thick,type_mat) }
      end
    end#def
    
    def change_Handle_material(e, new_mat_name)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0") 
      if type.include?("Руч") || type.include?("Handle") || type.include?("handle")
        change_mat(e, new_mat_name, new_mat_name)
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || type.include?("Фасад") || type.include?("МДФ") || type.include?("frontal") || l1_component_101_name.include?("ЛДСП") && l1_component_102_article.include?("Фасад")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Handle_material(ent, new_mat_name) }
      end 
    end#def
    
    def color_list(color)
      case color
        when "1004" then @color = "светло-бежевый "+color
        when "1007" then @color = "кирпичный "+color
        when "145" then @color = "зеленый "+color
        when "153" then @color = "светло-серый "+color
        when "1905" then @color = "черный "+color
        when "284" then @color = "темно-серый "+color
        when "301" then @color = "белый "+color
        when "500" then @color = "светло-коричневый "+color
        when "594" then @color = "бежевый "+color
        when "709" then @color = "темно-коричневый "+color
        when "820" then @color = "металлик "+color
        else @color = "белый 301"
      end
      @color
    end#def
    def plinth_color(s)
      mat_name = s.downcase.split(" [")[0]
      content = File.readlines(File.join(PATH_PRICE,"Плинтус_цоколь.xml"))
      materials = Report_lists.xml_value(content.join("").strip,"<Materials>","</Materials>")
      material_array = Report_lists.xml_array(materials,"<Material>","</Material>")
      material_array.each{|cont|
        name = Report_lists.xml_value(cont,"<Name>","</Name>")
        if name.downcase.include?(mat_name) && name.include?("(ф-ра")
          return name.split("(ф-ра ")[1].split(")")[0]
        end
      }
      return ""
    end#def
    
    def change_Worktop_material(e, new_mat_name,type_mat="")
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      a03_name = e.definition.get_attribute("dynamic_attributes", "a03_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      t2_tabletops = e.definition.get_attribute("dynamic_attributes", "t2_tabletops", "0")
      if type.include?("worktop") || type.include?("Столеш") && !a03_name.include?("Плинтус") || l1_component_102_article.include?("Столешница") || type.include?("fartuk") || type.include?("Фартук") || l1_component_102_article.include?("Скинали") || l1_component_102_article.include?("Бортик")
        if @edge_r != ""
          set_att(e,"edge_r",@edge_r)
        end
        back_material = "White"
        edge_color = e.definition.get_attribute("dynamic_attributes", "edge_color")
        back_material_input = e.definition.get_attribute("dynamic_attributes", "back_material_input")
        if edge_color
          if back_material_input == "2"
            back_material = new_mat_name
            elsif back_material_input == "3"
            back_material = "White_and_stripe"
          end
        end
        change_mat(e, new_mat_name, back_material, false, type_mat)
        z_size_mat = e.definition.get_attribute("dynamic_attributes", "z_size_mat", "2")
        if z_size_mat=="2"
          if @max_width_of_count && @max_width_of_count != "0" && @max_width_of_count != 0
            set_att(e,"max_width_of_count",@max_width_of_count)
            if !e.definition.get_attribute("dynamic_attributes", "z_max_length")
              e.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", (@max_width_of_count.to_f*100).to_s)
              if type.include?("гол") || type.include?("глов") || e.definition.name.include?("гол") || e.definition.name.include?("глов")
                if type.include?("worktop")
                  e.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", 'CHOOSE(a1_stik,'+(@max_width_of_count.to_f*100).to_s+',CHOOSE(a2_soed,'+(@max_width_of_count.to_f*100).to_s+','+(@max_width_of_count.to_f*100-7).to_s+')+a4_width_r_real)')
                  e.definition.set_attribute("dynamic_attributes", "_x_max_y_formula", 'CHOOSE(a1_stik,CHOOSE(a2_soed,'+(@max_width_of_count.to_f*100).to_s+','+(@max_width_of_count.to_f*100-7).to_s+')+a3_width_l_real,'+(@max_width_of_count.to_f*100).to_s+')')
                  elsif type.include?("fartuk")
                  e.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", (@max_width_of_count.to_f*100).to_s)
                  e.definition.set_attribute("dynamic_attributes", "_x_max_y_formula", (@max_width_of_count.to_f*100).to_s)
                  set_att(e,"scaletool","120")
                end
                elsif type.include?("fartuk")
                set_att(e,"scaletool","122")
                else
                e.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", (@max_width_of_count.to_f*100).to_s)
              end
            end
          end
          if type.include?("fartuk")
            e.definition.set_attribute("dynamic_attributes", "_x_max_z_formula", "120")
          end
        end
        e.definition.entities.grep(Sketchup::ComponentInstance).to_a.each { |ent|
          type = ent.definition.get_attribute("dynamic_attributes", "description", "0")
          a03_name = ent.definition.get_attribute("dynamic_attributes", "a03_name", "0")
          if type.include?("worktop") || type.include?("Столеш") && !a03_name.include?("Плинтус") || type.include?("fartuk") || type.include?("Фартук")
            change_mat(ent, new_mat_name, back_material, false, type_mat)
            if @max_width_of_count && @max_width_of_count != "0" && @max_width_of_count != 0
              set_att(e,"max_width_of_count",@max_width_of_count)
              if !ent.definition.get_attribute("dynamic_attributes", "z_max_length")
                ent.definition.set_attribute("dynamic_attributes", "_x_max_x_formula", (@max_width_of_count.to_f*100).to_s)
              end
              if type.include?("fartuk") && ent.definition.get_attribute("dynamic_attributes", "_x_max_z_formula")
                ent.definition.set_attribute("dynamic_attributes", "_x_max_z_formula", "120")
              end
            end
          end
        }
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif type.include?("skirting") || a03_name.include?("Плинтус")
        color = color_list(plinth_color(new_mat_name.strip))
        change_mat(e, new_mat_name, back_material, false, type_mat)
        set_att(e,"mat_furniture",color)
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
        elsif t2_tabletops != "0"
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Worktop_material(ent, new_mat_name,type_mat) }
      end
    end#def
    
    def change_Plinth_material(e, new_mat_name)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      if type.include?("plinth") || type.include?("Цоколь")
        change_mat(e, new_mat_name, new_mat_name, true)
        Redraw_Components.redraw_entities_with_Progress_Bar(e.definition.entities.grep(Sketchup::ComponentInstance))
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Plinth_material(ent, new_mat_name) }
      end
    end#def
    
    def change_Metal_material(e, new_mat_name)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      name = e.definition.get_attribute("dynamic_attributes", "name", "0")
      if type.include?("metal") || name.include?("Метал") || su_type.include?("metal")
        change_mat(e, new_mat_name, new_mat_name, true)
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || su_type.downcase.include?("furniture")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Metal_material(ent, new_mat_name) }
        Redraw_Components.redraw_entities_with_Progress_Bar([e])
      end
    end#def
    
    def change_Glass_material(e, new_mat_name, input_glass=false)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      name = e.definition.get_attribute("dynamic_attributes", "name", "0")
      component_101_name = e.definition.get_attribute("dynamic_attributes", "component_101_name", "0")
      l1_component_100_module = e.definition.get_attribute("dynamic_attributes", "l1_component_100_module", "0")
      component_100_module = e.definition.get_attribute("dynamic_attributes", "component_100_module", "0")
      l1_component_101_name = e.definition.get_attribute("dynamic_attributes", "l1_component_101_name", "0")
      l1_component_102_article = e.definition.get_attribute("dynamic_attributes", "l1_component_102_article", "0")
      g1_module_100_name = e.definition.get_attribute("dynamic_attributes", "g1_module_100_name", "0")
      if su_type.include?("glass") || type.include?("glass") || name.include?("Стекло") && type.include?("fartuk") || l1_component_101_name.include?("Стекло") || l1_component_101_name.include?("4")
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent|
          if ent.definition.name.include?("Essence") || ent.definition.get_attribute("dynamic_attributes", "_name") == "Essence"
            if ent.definition.get_attribute("dynamic_attributes", "_texturemat_formula", "0") == 'TEXTUREMAT(parent!napr_texture,parent!material,parent!back_material)'
              ent.definition.set_attribute("dynamic_attributes", "_texturemat_formula", 'TEXTUREMAT(parent!napr_texture,parent!material,parent!back_material,0,1,1)')
            end
          end
        }
        if input_glass
          a01_lenx = e.definition.get_attribute("dynamic_attributes", "a01_lenx", "0")
          a01_lenz = e.definition.get_attribute("dynamic_attributes", "a01_lenz", "0")
          mat = @model.materials.detect{|i| i.display_name == new_mat_name}
          if mat && mat.texture
            if input_glass
              mat.texture.size = [a01_lenx.to_f/input_glass[0].to_f, a01_lenz.to_f/input_glass[1].to_f]
            end
          end
        end
        change_mat(e, new_mat_name, new_mat_name, false)
        elsif type.include?(SUF_STRINGS["Product"]) || type.include?("Изделие") || type.include?("Каркас") || type.include?("Тело") || type.downcase.include?("body") || su_type.downcase.include?("body") || su_type.downcase.include?("section") || type.include?("Фасад") || type.include?("МДФ") || type.include?("frontal")
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        b1_p_thickness = e.definition.get_attribute("dynamic_attributes", "b1_p_thickness")
        if b1_p_thickness && name.include?("купе")
          set_att(e,"b1_p_material","ЛДСП_Базовая")
        end
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Glass_material(ent, new_mat_name, input_glass) }
        elsif l1_component_100_module != "0" || component_100_module != "0"
        e.make_unique
        e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
        e.definition.entities.grep(Sketchup::ComponentInstance) { |ent| change_Glass_material(ent, new_mat_name, input_glass) }
      end
    end#def
    
    def change_All_material(e, new_mat_name)
      e.definition.set_attribute("dynamic_attributes", '_hideinbrowser', true) if e.parent.is_a?(Sketchup::ComponentDefinition)
      type = e.definition.get_attribute("dynamic_attributes", "description", "0")
      su_type = e.definition.get_attribute("dynamic_attributes", "su_type", "0")
      if type != "0" && !type.include?(SUF_STRINGS["Product"]) && !type.include?("Тело") && !type.include?("Фасад") && !type.include?("ЛДСП") && !type.downcase.include?("body")
        change_mat(e, new_mat_name, new_mat_name, false)
      end
    end#def
    
    def get_attributes(definition, keys, default)
      keys.map { |key| definition.get_attribute("dynamic_attributes", key, default) }
    end
    
    def set_att(e,att,value,label=nil,access=nil,formlabel=nil,formulaunits=nil,units=nil,formula=nil,options=nil)
      e.set_attribute('dynamic_attributes', att, value) if value
      e.definition.set_attribute('dynamic_attributes', att, value) if value
      label ? e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", label) : e.definition.set_attribute('dynamic_attributes', "_"+att+"_label", att) if att
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_access", access) if access
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formlabel", formlabel) if formlabel
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_formulaunits", formulaunits) if formulaunits
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_units", units) if units
      if formula
        e.definition.set_attribute('dynamic_attributes', "_"+att+"_formula", formula)
        else
        e.definition.delete_attribute("dynamic_attributes", "_"+att+"_formula")
      end
      e.definition.set_attribute('dynamic_attributes', "_"+att+"_options", options) if options
    end#def
    
    def del_att(e,att)
      e.delete_attribute("dynamic_attributes", att)
      e.definition.delete_attribute("dynamic_attributes", att)
    end
    
  end # class ChangeMaterials
  
end # module SU_Furniture
