module SU_Furniture
  class SUPrice
    def initialize
      @currency = nil
    end
    def price()
      @param_list = []
      all_folder_price = Dir.glob(File.join(PATH_PRICE, "*.xml"))
      .map { |f| File.basename(f, ".xml") }
      .reject { |f| f == "Фреза_текстура" }
      if $dlg_price && ($dlg_price.visible?)
        $dlg_price.bring_to_front
        else
        $dlg_price = UI::HtmlDialog.new({
          :dialog_title => SUF_STRINGS["Price List Editor"]+"_"+PLUGIN_VERSION,
          :preferences_key => "suf_price",
          :scrollable => true,
          :resizable => true,
          :width => 700,
          :height => 500,
          :left => 100,
          :top => 200,
          :min_width => 700,
          :min_height => 500,
          :max_width =>1900,
          :max_height => 1600,
          :style => UI::HtmlDialog::STYLE_DIALOG
        })
        html_path = PATH + "/html/SU_Price.html"
        $dlg_price.set_file(html_path)
        $dlg_price.show()
      end
      @export_path = nil
      $dlg_price.add_action_callback("get_price_data") { |web_dialog,action_name|
        
        if action_name.include?("price_activate")
          price_activate()
          
          elsif action_name.include?("save_currency")
          @currency, @currency_name = action_name.split('=>')[1..2]
          currency_name ||= "р"
          File.write("#{PATH_PRICE}/currency.dat", "#{@currency}=1=#{@currency_name}\nEUR=1\nUSD=1\n")
          
          elsif action_name.include?("export_price")
          @export_path = UI.select_directory(
            title: SUF_STRINGS["Select a folder to save the price lists"],
            directory: Dir.pwd,
            select_multiple: false
          )
          cwd = Dir.chdir(@export_path) if @export_path
          elsif action_name.include?("export_xml")
          if @export_path
            file_name, xml = action_name.split('=>')[1..2]
            File.write(File.join(@export_path, "#{file_name}.xml"), xml)
          end
          
          elsif action_name.include?("import_price")
          import_path = UI.select_directory(
            title: SUF_STRINGS["Select a folder with price lists"],
            directory: Dir.pwd,
            select_multiple: false
          )
          if import_path
            cwd = Dir.chdir(import_path)
            FileUtils.cp_r(File.join(import_path, "."), PATH_PRICE)
            price_activate()
          end
          
          elsif action_name.include?("add_path")
          price_name = action_name.split('=>')[1]
          path_mat = UI.select_directory(
            title: SUF_STRINGS["Select the location of the materials folder"],
            directory: PATH_MAT,
            select_multiple: false
          )
          if path_mat
            folder_name = path_mat.split("/").last.gsub("_LDSP","").gsub("_LMDF","").gsub("_Worktop","")
            prefix = ""
            if folder_name.include?("LMDF")
              prefix = SUF_STRINGS["MDF"]+" 16"+SUF_STRINGS["mm"]
              elsif folder_name.include?("LDSP")
              prefix = SUF_STRINGS["chipboard"]+" 16"+SUF_STRINGS["mm"]
            end
            prompts = [SUF_STRINGS["Name prefix"],SUF_STRINGS["Name suffix"],SUF_STRINGS["The supplier"],SUF_STRINGS["Article number"],SUF_STRINGS["Unit"],SUF_STRINGS["Price"],SUF_STRINGS["Currency"],SUF_STRINGS["Ratio"],SUF_STRINGS["Work"],SUF_STRINGS["Category"],SUF_STRINGS["Code"],SUF_STRINGS["Weight"],SUF_STRINGS["Link"]]
            defaults = [prefix,folder_name,"-------","-------",SUF_STRINGS["sq.m."],"400","RUB","2","0","1","","",""]
            list = ["","","","",SUF_STRINGS["sq.m."]+"|"+SUF_STRINGS["m"]+"|"+SUF_STRINGS["pc"],"","RUB|AUD|GBP|MDL|BYN|BGN|USD|EUR|KZT|CAD|KGS|CNY|TJS|UZS|UAH","","","","","",""]
            input = UI.inputbox prompts, defaults, list, SUF_STRINGS["Import Parameters"]
            if input
              price_array = [price_name] + input
              p price_array
              all_folder = Dir.glob(File.join(path_mat, "*.{jpg,jpeg,png,bmp}"))
              .map { |f| File.basename(f, File.extname(f)) }
              price_array += all_folder
              $dlg_price.execute_script("add_materials_row(#{price_array.inspect})")
            end
          end
          
          elsif action_name.include?("delete_xml")
          file_name = action_name.split('=>')[1]
          File.delete(File.join(PATH_PRICE, "#{file_name}.xml")) if File.file?(File.join(PATH_PRICE, "#{file_name}.xml"))
          
          elsif action_name[0..7]=="save_xml"
          file_name, xml = action_name.split('=>')[1..2]
          File.write(File.join(PATH_PRICE, "#{file_name}.xml"), xml)
          
          elsif action_name.include?("cat_delete")
          file_name = action_name.split('=>')[1]
          input = UI.messagebox("#{SUF_EXP_STR["Delete"]} #{file_name}?",MB_YESNO)
          if input == IDYES
            File.delete(File.join(PATH_PRICE, "#{file_name}.xml")) if File.file?(File.join(PATH_PRICE, "#{file_name}.xml"))
          end
          UI.start_timer(0.5, false) { 
            price_activate()
          }
          
          elsif action_name[0..9]=="cat_hidden"
          hidden_categories = action_name[12..-1].split(',')
          File.write("#{PATH_PRICE}/param_list.txt", hidden_categories.join("\n"))
          
          elsif action_name.include?("new_category")
          UI.start_timer(0.5, false) { 
            price_activate()
          }
        end
        }
      end#def
      def price_activate()
        @param_list = []
        path_param_list = File.join(PATH_PRICE, "param_list.txt")
        File.write(path_param_list, "") unless File.file?(path_param_list)
        @param_list = File.readlines(path_param_list).map(&:strip)
        path_currency_rate = File.join(PATH_PRICE, "currency.dat")
        unless File.file?(path_currency_rate)
          File.write(path_currency_rate, "RUB=1=руб\nEUR=1\nUSD=1\n")
        end
        @currency = File.readlines(path_currency_rate).first.strip
        @price_hash = {}
        price_hash()
        vend = [@price_hash.to_json,@param_list,@currency]
        $dlg_price.execute_script("price(#{vend.inspect})")
      end
      def price_hash()
        path_price = File.join(PATH_PRICE, "*")
        @all_folder_price = Dir.glob(path_price).select { |file| File.extname(file).casecmp?(".xml") }
        @all_folder_price.map! { |file| File.basename(file, File.extname(file)) }
        @all_folder_price.reject! { |name| name == "Фреза_текстура" }
        @all_folder_price.each{|folder_price|
        content = File.read(File.join(PATH_PRICE, "#{folder_price}.xml"))
        materials = Report_lists.xml_value(content.strip,"<Materials>","</Materials>")
        next if materials.strip.empty?
        material_array = Report_lists.xml_array(materials.strip,"<Material>","</Material>")
        price_array = []
        material_array.each{|cont|
          price_array << [Report_lists.xml_value(cont,"<Provider>","</Provider>"),Report_lists.xml_value(cont,"<Article>","</Article>"),Report_lists.xml_value(cont,"<Name>","</Name>"),Report_lists.xml_value(cont,"<Unit_Measure>","</Unit_Measure>"),Report_lists.xml_value(cont,"<Cost>","</Cost>"),Report_lists.xml_value(cont,"<Currency>","</Currency>"),Report_lists.xml_value(cont,"<Coef>","</Coef>"),Report_lists.xml_value(cont,"<Price>","</Price>"),Report_lists.xml_value(cont,"<Work>","</Work>"),Report_lists.xml_value(cont,"<Category>","</Category>"),Report_lists.xml_value(cont,"<Code>","</Code>"),Report_lists.xml_value(cont,"<Weight>","</Weight>"),Report_lists.xml_value(cont,"<Link>","</Link>"),Report_lists.xml_value(cont,"<Digit_capacity>","</Digit_capacity>"),Report_lists.xml_value(cont,"<Value>","</Value>")]
        }
        @price_hash[folder_price] = price_array
      }
    end
  end #end Class 
end
