require 'fileutils'
module SU_Furniture
  class Parameter
	  def initialize
		  @content = []
			@content_temp = []
			@param = []
    end#def
    def activate
      $dlg_param = UI::HtmlDialog.new({
        :dialog_title => "Parameters_"+PLUGIN_VERSION,
        :preferences_key => "parameter",
        :scrollable => true,
        :resizable => true,
        :width => 1180,
        :height => 600,
        :left => 100,
        :top => 100,
        :min_width => 1130,
        :min_height => 510,
        :max_width =>1240,
        :max_height => 1100,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      html_path = PATH + "/html/Parameters.html"
      $dlg_param.set_file(html_path)	
      $dlg_param.show()
      @saved = false
      @new_temp = nil
      $dlg_param.add_action_callback("get_data") { |web_dialog,action_name|
        if action_name.to_s.include?("read_param")
          read_param
          if @saved == false
            command = "save_changes(false)"
            #$dlg_param.execute_script(command)
            @saved = true
          end
          elsif action_name.to_s.include?("change_path")
          change_path(action_name[11..-1])
          elsif action_name.to_s.include?("change_file")
          change_file(action_name[11..-1])
					elsif action_name.to_s.include?("edit_additional_fastener")
          edit_additional_fastener(action_name[14..-1])
          elsif action_name.to_s.include?("save_changes")
          save_changes("parameters",action_name[13..-1].split("|"))
          elsif action_name.to_s.include?("export_parameters")
          export_param
          elsif action_name.to_s.include?("import_parameters")
          import_param
          elsif action_name.to_s.include?("reset_parameters")
          reset_param
          elsif action_name.to_s.include?("export_library")
          export_library
					elsif action_name.to_s.include?("new_profile")
          new_profile
					elsif action_name.to_s.include?("change_profile")
          change_profile(action_name.split("=>")[1])
          elsif action_name.to_s.include?("edit_list_name")
          param = action_name.split("|")
          edit_list_name(param[1],param[2],param[3])
          elsif action_name.to_s.include?("save_fasteners")
          param = action_name.split("&")
          save_changes("fasteners",param[1..-1])
          elsif action_name.to_s.include?("save_template")
          param = action_name[13..-1].split("/n")
          save_changes("template",param)
          elsif action_name.to_s.include?("save_hinge")
          param = action_name[10..-1].split("/n")
          save_changes("hinge",param)
          elsif action_name.to_s.include?("save_drawer")
          param = action_name[11..-1].split("/n")
          save_changes("drawer",param)
          elsif action_name.to_s.include?("save_accessories")
          param = action_name[16..-1].split("/n")
          save_changes("accessories",param)
          elsif action_name.to_s.include?("save_groove")
          param = action_name[11..-1].split("/n")
          save_changes("groove",param)
          elsif action_name.to_s.include?("save_lists")
          param = action_name[10..-1].split("/n")
          save_changes("lists",param)
          elsif action_name.to_s.include?("save_texts")
          param = action_name[10..-1].split("/n")
          save_changes("texts",param)
          elsif action_name.to_s.include?("save_worktop")
          param = action_name[12..-1].split("/n")
          save_changes("worktop",param)
          elsif action_name.to_s.include?("save_fartuk")
          param = action_name[11..-1].split("/n")
          save_changes("fartuk",param)
          elsif action_name.to_s.include?("save_frontal")
          param = action_name[12..-1].split("/n")
          save_changes("frontal",param)
          elsif action_name.to_s.include?("save_freza")
          param = action_name[10..-1].split("/n")
          save_changes("freza",param)
          elsif action_name.to_s.include?("save_component")
          param = action_name[14..-1].split("/n")
          save_changes("component",param)
          elsif action_name.to_s.include?("save_material")
          param = action_name[13..-1].split("/n")
          save_changes("material",param)
        end
      }
    end#def
    def export_library
			export_path = UI.select_directory(
        title: SUF_STRINGS["Select folder to save settings"],
        directory: Dir.pwd,
        select_multiple: false
      )
			return unless export_path
      cwd = Dir.chdir(export_path)
      copy_lib(export_path,false)
    end#def
		def export_param
			export_path = UI.select_directory(
        title: SUF_STRINGS["Select folder to save settings"],
        directory: Dir.pwd,
        select_multiple: false
      )
			return unless export_path
      cwd = Dir.chdir(export_path)
      valid_extensions = [".dat", ".png", ".jpg", ".jpeg"]
      all_files = Dir.entries(File.join(TEMP_PATH, "SUF")).select { |l| valid_extensions.any? { |ext| l.end_with?(ext) } }
      all_files.each { |file_name|
        src_path = File.join(TEMP_PATH, "SUF", file_name)
        dest_path = File.join(export_path, file_name)
        FileUtils.cp(src_path, dest_path)
      }
      Dir.entries(File.join(TEMP_PATH,"SUF")).each{|path|
        path = path.encode("utf-8")
        src_path = File.join(TEMP_PATH, "SUF", path)
        dest_path = File.join(export_path, path)
        FileUtils.cp_r("#{src_path}/.", dest_path) if File.directory?(src_path) && !path.include?(".")
      }
    end#def
		def import_param
      import_path = UI.select_directory(
        title: SUF_STRINGS["Select folder with settings"],
        directory: Dir.pwd,
        select_multiple: false
      )
      if import_path
				cwd = Dir.chdir(import_path)
        param_dialog("import",import_path)
      end
    end#def
    def copy_files(param_array,array,import_path)
      Dir.entries(import_path).each{|path|
        path = path.encode("utf-8")
        
        if File.file?(path)
          FileUtils.cp path,File.join(TEMP_PATH,"SUF")
          
          elsif !path.include?('.') && File.directory?(File.join(import_path,path))
          if !Dir.exist?(File.join(TEMP_PATH,"SUF",path))
            Dir.mkdir(File.join(TEMP_PATH,"SUF",path))
          end
          if path.include?("Name_database")
            FileUtils.cp_r( File.join(path,"."), File.join(TEMP_PATH,"SUF",path))
            else
            Dir.entries(File.join(import_path,path)).each { |f|
              f = f.encode("utf-8")
              file_name = File.join(import_path,path,f)
              if File.file?(file_name)
                if array.any?{|name|param_array[name]==File.basename(f,".dat")}
                  FileUtils.cp file_name,File.join(TEMP_PATH,"SUF",path)
                end
              end
            }
          end
        end
      }
    end#def
    def reset_param
      param_dialog("reset",File.join(TEMP_PATH, "SUF"))
    end#def
    def find_all_dat_files(temp_path,all_dat_files=[])
      Dir.entries(temp_path).each { |path|
        all_dat_files << File.join(temp_path,path) if path.include?(".dat")
        path = path.encode("utf-8")
        if !path.include?('.') && File.directory?(File.join(temp_path,path))
          find_all_dat_files(File.join(temp_path,path),all_dat_files)
        end
      }
      all_dat_files
    end
    def param_dialog(action,path)
      param_array = {
        SUF_STRINGS["General"] => "parameters",
        SUF_STRINGS["Drilling"] => "fasteners",
        SUF_STRINGS["Template"] => "template",
        SUF_STRINGS["Hinges"] => "hinge",
        SUF_STRINGS["Slides"] => "drawer",
        SUF_STRINGS["Fittings"] => "accessories",
        SUF_STRINGS["Grooves"] => "groove",
        SUF_STRINGS["Lists"] => "lists",
        SUF_STRINGS["Text"] => "texts",
        SUF_STRINGS["Countertops"] => "worktop",
        SUF_STRINGS["Backsplashes"] => "fartuk",
        SUF_STRINGS["Fronts"] => "frontal"
      }
      
      all_dat_files = find_all_dat_files(path)
      if all_dat_files.empty?
        UI.messagebox(SUF_STRINGS["No settings files in the folder"])
        else
        prompts = []
        param_array.each_key { |param| prompts << param }
        
        html_content = <<-HTML
          <html>
          <head>
          <style>
          body { font-family: Arial; color: #696969; font-size: 18px; }
          </style>
          <script type="text/javascript">
          function getCheckboxValues() {
          var values = [];
          var checkboxes = document.getElementsByName('param');
          for (var i = 0; i < checkboxes.length; i++) {
          if (checkboxes[i].checked) {
          values.push(checkboxes[i].value);
          }
          }
          return values;
          }
          function submit() {
          var values = getCheckboxValues();
          sketchup.callback(values)
          }
          </script>
          </head>
          <body>
          <form>
        HTML
        
        param_array.each_key.with_index do |param, index|
          html_content += "<input type='checkbox' name='param' checked=\"true\" value='#{param}'> #{param}<br>"
        end
        
        html_content += <<-HTML
          </form>
          <button onclick="submit()">#{SUF_STRINGS["Confirm"]}</button>
          </body>
          </html>
        HTML
        
        dialog = UI::HtmlDialog.new(
          {
            :dialog_title => SUF_STRINGS["Select parameters"],
            :preferences_key => "reset_param",
            :scrollable => false,
            :resizable => false,
            :width => 250,
            :height => 350
          }
        )
        dialog.set_html(html_content)
        dialog.show
        dialog.add_action_callback("callback") { |_, v|
          if action=="reset"
            delete_files(all_dat_files,param_array,v)
            elsif action=="import"
            copy_files(param_array,v,path)
          end
          read_param
          dialog.close
        }
      end
    end
    def delete_files(all_dat_files,param_array,array)
      all_dat_files.each { |file|
        file_name = File.basename(file,".dat")
        if param_array.values.include?(file_name) && !array.any?{|name|file_name==param_array[name]}
          elsif File.file?(file)
          File.unlink(file)
        end
      }
    end
		def new_profile
			input = UI.inputbox ["#{SUF_STRINGS["Profile name"]}: "], [""], [""], " "
			if input
				if File.directory?(File.join(TEMP_PATH,"SUF",input[0]))
				  UI.messagebox(SUF_STRINGS["A profile with this name already exists!"])
					else
					Dir.entries(File.join(TEMP_PATH,"SUF")).each{|f|
						f = f.encode("utf-8")
						if !f.include?('.') && File.directory?(File.join(TEMP_PATH,"SUF",f))
              if File.file?(File.join(TEMP_PATH,"SUF",f,"parameters.dat"))
                path_param = File.join(TEMP_PATH,"SUF",f,"parameters.dat")
                param_file = File.new(path_param,"r")
                content = param_file.readlines
                param_file.close
                param_file = File.new(path_param,"w")
                content.each{|i|
                  if i.split("=")[1] == "param_profile"
                    cont = i.split("=")
                    param_file.puts cont[0]+"="+cont[1]+"="+input[0]+"="+cont[3]+"="+cont[4].strip+"&"+input[0]+"^"+input[0]
                    else
                    param_file.puts i
                  end
                }
                param_file.close
              end
            end
          }
          command = "add_new_profile(#{input[0].inspect})"
          $dlg_param.execute_script(command)
        end
      end
    end#def
		def change_profile(input)
		  Sketchup.write_default("SUF", "PARAM_TEMP_PATH", File.join(TEMP_PATH,"SUF",input))
			Dir.entries(File.join(TEMP_PATH,"SUF")).each{|f|
				f = f.encode("utf-8")
				if !f.include?('.') && File.directory?(File.join(TEMP_PATH,"SUF",f))
          if File.file?(File.join(TEMP_PATH,"SUF",f,"parameters.dat"))
            path_param = File.join(TEMP_PATH,"SUF",f,"parameters.dat")
            param_file = File.new(path_param,"r")
            content = param_file.readlines
            param_file.close
            param_file = File.new(path_param,"w")
            content.each{|i|
              if i.split("=")[1] == "param_profile"
                cont = i.split("=")
                param_file.puts cont[0]+"="+cont[1]+"="+input+"="+cont[3]+"="+cont[4].strip
                else
                param_file.puts i
              end
            }
            param_file.close
          end
        end
      }
			read_param
    end#def
    def edit_list_name(id,list,from)
      @edit_dlg.close if @edit_dlg && (@edit_dlg.visible?)
      list = list.split(";")
      name_list = []
      list.each { |i| name_list << i.strip }
      head = <<-HEAD
				<html><head>
				<meta charset="utf-8">
				<title>Edit</title>
				<style>
				body { font-family: Arial; color: #696969; font-size: 14px; padding-bottom: 45px;}
				#name_table {  width: 100%; border-collapse: collapse; font-size: 12px; }          
					#name_table th{ padding: 3px; text-align:left; }
					#name_table th:nth-child(2){ text-align:right; }
					#name_table td { padding: 3px; border: 1px solid gray; }
        #name_table td:nth-child(2){ text-align:right; }
        .edit_name { width: 100%; height: 17px; }
				.edit_count { width: 23px; height: 17px; text-align:right; }
				#footer { position : fixed; bottom: 0; left: 0; width: 100%; height: 38px; line-height: 20px; text-align: center; border-top: 1px solid gray; background-color: #e2ded7; padding: 3px; }
				.save { position: fixed; bottom: 8px; left: 50%; margin-left: -50px; width:100px; height:30px; background-color: #e08120; cursor:pointer; border: 1px solid transparent; color: #000000;}
				.save:hover { background-color: #c46500; }
				</style>
				</head>
				<body>
      HEAD
			if from=="hinge"
        hidden = "none";
        style1="width: 100%; height: 38px; display: flex; flex-direction: column; justify-content: space-between;"
        style2="width: 35px; height: 38px; display:none;"
        else
        hidden = "";
        style1="width: 100%; height: 24px;"
        style2="width: 35px; height: 24px;"
      end
			body = ''
			body << %(
			<table id="name_table" ><th style="width: 100%; height: 24px;">#{SUF_STRINGS["Name"]}</th><th style="width: 35px; height: 24px; display:#{hidden} ">#{SUF_STRINGS["count"]}</th>)
			name_list.each_with_index {|name_value,index|
				name = name_value.split("~")[0]
        if name.include?("<#>")
          name_arr = name.split("<#>")
          name = name_arr[0]
          tags = "#"+name_arr[1..-1].join(" #")
          p tags
          name = "<div>#{name}</div><div>#{tags}</div>"
        end
				count = name_value.split("~")[1]
				body << %(<tr>
				<td style="#{style1}" id="name#{index}" >#{name}</td>
				<td style="#{style2}" id="count#{index}" >#{count}</td>
				</tr>)
      }
			for index in name_list.count..19
				body << %(<tr>
				<td style="#{style1}" id="name#{index}" ></td>
				<td style="#{style2}" id="count#{index}" ></td>
				</tr>)
      end
			body << %(</table>
			<div id="footer">
			<button class="save" onclick="save();">#{SUF_STRINGS["Save"]}</button>
			</div>
			)
			tail = <<-TAIL
				<script>
				var tds = document.querySelectorAll('td');
				for (var i = 0; i < tds.length; i++) {
				tds[i].addEventListener('click', function func() {
				var input = document.createElement('input');
				input.value = this.innerHTML;
				let cls = this.id.startsWith('name') ? 'edit_name' : 'edit_count';
        input.classList.add(cls);
				this.innerHTML = '';
				this.appendChild(input);
        input.focus();
        var td = this;
        input.addEventListener('blur', function() {
        td.innerHTML = this.value;
        td.addEventListener('click', func);
        });
        this.removeEventListener('click', func);
        });
        }
        function save() {
        let name_list = '';
        var trs = document.querySelectorAll('tr');
        for (var i = 1; i < trs.length; i++) {
        if (trs[i].cells[0].innerHTML != '') {
        let count = 1;
        if (trs[i].cells[1].innerHTML != '') { count = trs[i].cells[1].innerHTML; }
        name_list += trs[i].cells[0].innerHTML + '~' + count + ';';
        }
        }
        sketchup.edit('save'+name_list);
        }
        </script>
        </body></html>
      TAIL
			html = head + body + tail
			@edit_dlg = UI::HtmlDialog.new({
				:dialog_title => SUF_STRINGS["Edit_list"],
				:preferences_key => "edit_list",
				:scrollable => true,
				:resizable => true,
				:width => 600,
				:height => 600,
				:left => 100,
				:top => 200,
				:min_width => 600,
				:min_height => 400,
				:max_width =>100,
				:max_height => 1000,
				:style => UI::HtmlDialog::STYLE_DIALOG
      })
			@edit_dlg.add_action_callback('edit') { |web_dialog,action_name|
				if action_name.include?("save")
					if action_name[4..-1].include?("|") || action_name[4..-1].include?("/")
						UI.messagebox(SUF_STRINGS["Symbols | and / are not allowed"])
						else
						param = [id,action_name[4..-1],from]
						command = "save_name_list(#{param.inspect})"
						$dlg_param.execute_script(command)
						@edit_dlg.close
          end
        end
      }
			@edit_dlg.set_html(html)
			@edit_dlg && (@edit_dlg.visible?) ? @edit_dlg.bring_to_front : @edit_dlg.show
    end#def
    def change_path(param)
      if param.include?("work_path")
        path_lib = UI.select_directory(
          title: SUF_STRINGS["Select a Folder for screenshots and export to LayOut"],
          directory: Dir.pwd,
          select_multiple: false
        )
        if path_lib
          cwd = Dir.chdir(path_lib)
          read_param(param.split("=>")[0]+"=>"+path_lib)
        end
        elsif param.split("=>")[0] == "lib_path"
        path_lib = UI.select_directory(
          title: SUF_STRINGS["Select folder with SUF library (Cancel — Use default folder)"],
          directory: param.split("=>")[2],
          select_multiple: false
        )
        if path_lib
          read_param(param.split("=>")[0]+"=>"+path_lib)
          result = UI.messagebox("#{SUF_STRINGS["Move library to new folder"]}? \n\n#{SUF_STRINGS["Yes – Entire library will be moved to the selected folder."]}. \n\n#{SUF_STRINGS["No – The selected folder will be used"]}.", MB_YESNO)
          copy_lib(path_lib) if result == IDYES
          else
          read_param(param.split("=>")[0]+"=>#{SUF_STRINGS["Default"]}")
          result = UI.messagebox("#{SUF_STRINGS["Move library to default folder"]}? \n\n#{SUF_STRINGS["Yes – The entire library will be moved to the folder"]}. \n\n#{SUF_STRINGS["No – The default folder will be used"]}.", MB_YESNO)
          copy_lib(File.dirname(PATH_ROOT)) if result == IDYES
        end
        elsif param.split("=>")[0] == "temp_path"
        temp_path = UI.select_directory(
          title: SUF_STRINGS["Select folder with SUF settings (Cancel — Use default folder)"],
          directory: param.split("=>")[2],
          select_multiple: false
        )
        if temp_path
          @new_temp = temp_path
          Sketchup.write_default("SUF", "TEMP_PATH", temp_path)
          read_param(param.split("=>")[0]+"=>"+temp_path)
          $dlg_param.execute_script("save_changes(false)")
          UI.messagebox(SUF_STRINGS["Restart"] + " SketchUp")
          else
          @new_temp = nil
          Sketchup.write_default("SUF", "TEMP_PATH", nil)
          read_param(param.split("=>")[0]+"=>#{SUF_STRINGS["Default"]}")
          $dlg_param.execute_script("save_changes(false)")
          UI.messagebox(SUF_STRINGS["Restart"] + " SketchUp")
        end
      end
    end#def
    def copy_lib(path_lib,delete_src=true)
      if delete_src
        Sketchup.status_text = SUF_STRINGS["Moving library files…"]
        else
        Sketchup.status_text = SUF_STRINGS["Copying library files…"]
      end
      if !File.directory?( path_lib+"/Components/SUF" )
        FileUtils.mkdir_p path_lib+"/Components/SUF"
      end
      if !File.directory?( path_lib+"/Materials/SUF" )
        FileUtils.mkdir_p path_lib+"/Materials/SUF"
      end
      if !File.directory?( path_lib+"/Materials/price" )
        FileUtils.mkdir_p path_lib+"/Materials/price"
      end
      FileUtils.cp_r( PATH_COMP+"/.", path_lib+"/Components/SUF")
      FileUtils.rm_rf(Dir.glob(PATH_COMP+"/*")) if delete_src
      FileUtils.cp_r( PATH_MAT+"/.", path_lib+"/Materials/SUF")
      FileUtils.rm_rf(Dir.glob(PATH_MAT+"/*")) if delete_src
      FileUtils.cp_r( PATH_PRICE+"/.", path_lib+"/Materials/price")
      FileUtils.rm_rf(Dir.glob(PATH_PRICE+"/*")) if delete_src
      Sketchup.status_text = SUF_STRINGS["Success"]
      if delete_src
        $dlg_param.execute_script("save_changes(true)")
        UI.messagebox(SUF_STRINGS["Restart"] + " SketchUp")
        else
        UI.messagebox("#{SUF_STRINGS["The library has been copied to the folder"]}:\n\n#{path_lib}")
      end
    end#def
    def change_file(param)
      path_lib = UI.openpanel(SUF_STRINGS["Select logo file (Cancel — Use default)"], "c:/", "Image Files|*.jpg;*.jpeg;*.png;||")
      if path_lib
        FileUtils.cp_r( path_lib, File.join(TEMP_PATH,"SUF"))
        read_param(param.split("=>")[0]+"=>"+File.join(TEMP_PATH,"SUF",File.basename(path_lib)))
        else
        FileUtils.rm_rf(Dir.glob(TEMP_PATH+"/SUF/*.{jpg,jpeg,png}"))
        read_param(param.split("=>")[0]+"=>#{SUF_STRINGS["Default"]}")
      end
    end#def
    def edit_additional_fastener(param)
      additional_fastener_array = param.split("=>")[2].split(";")
      html = "<style>"
      html += "body { font-family: Arial; color: #696969; font-size: 16px; }"
      html += "#additional_fastener_table { width: 100%; margin-bottom: 20px; }"
      html += "#additional_fastener_table th { text-align:left; }"
      html += "#additional_fastener_table td { height: 18px; }"
      html += "</style>"
      html += "<script>"
      html += "function save() {"
      html += "let fastener_list = '';"
      html += "var trs = document.querySelectorAll('tr');"
      html += "for (var i = 1; i < trs.length; i++) {"
      html += "if ((trs[i].cells[0].childNodes[0].value != '')&&(trs[i].cells[2].childNodes[0].value != '')) {"
      html += "fastener_list += trs[i].cells[0].childNodes[0].value + '-' + trs[i].cells[2].childNodes[0].value + ';';"
      html += "}}"
      html += "sketchup.callback(fastener_list);"
      html += "}"
      html += "</script>"
      html += "<table id='additional_fastener_table'>"
      html += "<tr><th>#{SUF_STRINGS["Length"]}</th><th></th><th>#{SUF_STRINGS["count"]}</th></tr>"
      for i in 0..9
        if additional_fastener_array[i] && additional_fastener_array[i] != ""
          fastener = additional_fastener_array[i]
          html += "<tr><td><input style=\"width: 100px;\" value="+fastener.split("-")[0].to_s+"></input></td><td></td><td><input style=\"width: 50px;\" value="+fastener.split("-")[1].to_s+"></input></td></tr>"
          else
          html += "<tr><td><input style=\"width: 100px;\"></input></td><td></td><td><input style=\"width: 50px;\"></input></td></tr>"
        end
      end
      html += "</table>"
      html += "<button onclick=\"save()\">OK</button>"
      @dlg.close if @dlg && (@dlg.visible?)
      @dlg = UI::HtmlDialog.new({
        :dialog_title => ' ',
        :preferences_key => "fastener_count",
        :scrollable => false,
        :resizable => false,
        :width => 220,
        :height => 370,
        :left => 100,
        :top => 100,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })
      @dlg.set_html(html)
      @dlg.add_action_callback("callback") { |_, v|
        $dlg_param.execute_script("save_additional_fastener('"+v[0..-2]+"')")
        @dlg.close
      }
      OSX ? @dlg.show() : @dlg.show_modal()
    end#def
    def read_param(path_lib=nil)
      @param = []
      @content_temp = []
      if Sketchup.read_default("SUF", "PARAM_TEMP_PATH") && File.file?(File.join(Sketchup.read_default("SUF", "PARAM_TEMP_PATH"),"parameters.dat"))
        temp_path_file = File.new(File.join(Sketchup.read_default("SUF", "PARAM_TEMP_PATH"),"parameters.dat"), "r")
        @content_temp = temp_path_file.readlines
        temp_path_file.close
      end
      if @content_temp == [] && File.file?(File.join(TEMP_PATH,"SUF","Default","parameters.dat"))
        temp_path_file = File.new(File.join(TEMP_PATH,"SUF","Default","parameters.dat"), "r")
        @content_temp = temp_path_file.readlines
        temp_path_file.close
      end
      if @content_temp == [] && File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
        temp_path_file = File.new(File.join(TEMP_PATH,"SUF","parameters.dat"), "r")
        @content_temp = temp_path_file.readlines
        temp_path_file.close
      end
      path_param = PATH + "/parameters/parameters.dat"
      param_file = File.new(path_param,"r")
      @content = param_file.readlines
      param_file.close
      @profiles_path = "&Default^Default"
      Dir.entries(File.join(TEMP_PATH,"SUF")).each{|f|
        f = f.encode("utf-8")
        if !f.include?('.') && File.directory?(File.join(TEMP_PATH,"SUF",f)) && !f.include?("Default") && !f.include?("Name_database")
          @profiles_path += "&#{f}^#{f}"
        end
      }
      if @content_temp != []
        path_array = []
        @content.each_with_index { |cont,index| path_array << index if cont.split("=")[1] == "edge_vendor_header" } # строка начала папок
        @content_temp.each { |cont_temp|
          if cont_temp.split("=")[1] == "edge_vendor"
            path_array << cont_temp if !path_array.include?(cont_temp)
          end
        }
        if path_array.length > 1
          @content.delete_if {|cont| cont.split("=")[1] == "edge_vendor" }
        end
        @content.each_with_index { |cont,index|
          if cont.split("=")[1] != "menu_row"
            @content_temp.each { |cont_temp|
              if cont_temp.split("=")[1].include?("edge_trim") && cont.split("=")[1] == cont_temp.split("=")[1]
                @content[index] = cont_temp.split("=")[0]+"="+cont_temp.split("=")[1]+"="+cont_temp.split("=")[2]+"="+cont_temp.split("=")[3]+"="+cont.split("=")[4]+(cont_temp.split("=")[5] ? ("="+cont_temp.split("=")[5]) : (cont.split("=")[5] ? ("="+cont.split("=")[5]) : ""))
                elsif cont_temp.split("=")[1].include?("edge_header")
                
                elsif cont_temp.split("=")[1].include?("param_profile") && cont.split("=")[1] == cont_temp.split("=")[1]
                @content[index] = cont_temp.split("=")[0]+"="+cont_temp.split("=")[1]+"="+cont_temp.split("=")[2]+"="+cont_temp.split("=")[3]+"=&New^New"+@profiles_path
                elsif cont_temp.split("=")[1] != "edge_vendor" && cont.split("=")[1] == cont_temp.split("=")[1]
                if cont_temp.split("=")[3] == "SELECT"
                  @content[index] = cont_temp.split("=")[0]+"="+cont_temp.split("=")[1]+"="+cont_temp.split("=")[2]+"="+cont_temp.split("=")[3]+"="+cont.split("=")[4]
                  else
                  @content[index] = cont_temp
                end
              end
            }
          end
          if path_lib && path_lib.split("=>")[0] == cont.split("=")[1]
            @content[index] = cont.split("=")[0]+"="+cont.split("=")[1]+"="+path_lib.split("=>")[1]+"="+cont.split("=")[3]
          end
        }
        if path_array.length > 1
          if path_array[0].to_s.length < 4
            for i in 1..path_array.length-1
              @content.insert(i+path_array[0],path_array[i]) if !@content.include?(path_array[i])
            end
          end
        end
      end
      @content.delete_if { |i| !i }
      path_lang = File.join(PATH, "Resources")
      full_path_lang = Dir.entries(path_lang).find_all{|l|!l.include?(".") }
      lang_arr = "&"
      full_path_lang.each { |d|
        @strings = Hash.new { |hash, key| key }
        lang_file = File.join(path_lang, d, "suf.strings")
        parce_lang_file(lang_file, d)
        lang_arr += @strings["Language path"]
        lang_arr += "^"
        lang_arr << @strings["Language name"]
        lang_arr += "&"
      }
      @content.each_index { |index|
        if @content[index].split("=")[1] == "language"
          @content[index] = "Language=language="+@content[index].split("=")[2]+"=SELECT="+lang_arr[0..-2]
        end
      }
      # все папки лдсп
      full_path_ldsp = Dir.glob(File.join(PATH_MAT, "*")).find_all{|l|l.include?("LDSP") || l.include?("LMDF") }
      all_folder_ldsp = full_path_ldsp.map { |i| i.split(/[\/]/)[-1].gsub("_LDSP","").gsub("_LMDF","") }
      # удалить строки, если нет таких папок
      @content.delete_if { |i| i.split("=")[1] == "edge_vendor" && !all_folder_ldsp.include?(i.split("=")[0]) && i.split("=")[0] != "HDF" && i.split("=")[0] != "COLOR" && i.split("=")[0] != "MDF" && i.split("=")[0] != "PLASTIC" }
      content_folder_ldsp = []
      default_param = nil
      # значения по умолчанию для новых папок
      @content.each { |i|
        if i.split("=")[1] == "edge_vendor"
					content_folder_ldsp << i.split("=")[0]
					if !default_param
						default_param = i.split("=")[1]+"="+i.split("=")[2]+"="+i.split("=")[3]+"="+i.split("=")[4]+"="+i.split("=")[5].strip
          end
        end
      }
      
      worktop_hash = {}
      full_path_worktop = Dir.glob(File.join(PATH_MAT, "*")).find_all{|l|l.downcase.include?("worktop") }
      full_path_worktop.each { |worktop|
        @content_temp.each { |cont_temp|
          if cont_temp.split("=")[1] == "edge_vendor" && File.basename(worktop) == cont_temp.split("=")[0]
            worktop_hash[File.basename(worktop)] = cont_temp.split("=")[2]
          end
        }
        next if worktop_hash[File.basename(worktop)]
        size_file = Dir.entries(worktop).find{|l|File.basename(l).include?("_size.dat") }
        if size_file
          size = File.readlines(File.join(worktop,size_file))[0].strip
          else
          size = "3000"
        end
        worktop_hash[File.basename(worktop)] = size
      }
      # записываем в параметры
      save_all_folder = false
      last_index = 0
      @content.each { |i|
        if i.split("=")[1] == "edge_vendor"
          if !save_all_folder
            for folder_ldsp in all_folder_ldsp
              if !content_folder_ldsp.include?(folder_ldsp)
                !default_param ? @param << folder_ldsp+"=edge_vendor=2750x1830=2=6=6" : @param << folder_ldsp+"="+default_param
                last_index = @param.count
              end
            end
          end
          if all_folder_ldsp.include?(i.split("=")[0]) || i.split("=")[0] == "HDF" || i.split("=")[0] == "COLOR" || i.split("=")[0] == "MDF" || i.split("=")[0] == "PLASTIC"
            @param << i.strip
            last_index = @param.count
          end
          save_all_folder = true
          else
          @param << i.strip
        end
      }      
      worktop_hash.each_with_index { |(worktop,size),i|
        @param.insert(i+last_index,worktop+"=edge_vendor="+size+"=1=1=1")
      }
      read_furniture("fasteners")
      read_furniture("template")
      read_furniture("hinge")
      read_furniture("drawer")
      read_furniture("accessories")
      read_furniture("groove")
      read_furniture("lists")
      read_furniture("texts")
      read_furniture("worktop")
      read_furniture("fartuk")
      read_furniture("frontal")
      read_furniture("freza")
      read_furniture("component")
      read_furniture("material")
      
      @param << "plugin_version#{PLUGIN_VERSION}"
      command = "parameters(#{@param.inspect})"
      $dlg_param.execute_script(command)
    end#def
    def parce_lang_file(strings_file, lang)
      
      @language_folder = File.expand_path(File.dirname(strings_file))
      
      File.open(strings_file, 'r:BOM|UTF-8') { |lang_file|
        entry_string = ''
        in_comment_block = false
        lang_file.each_line { |line|
          
          if !line.lstrip.start_with?('//')
            
            if line.include?('/*')
              in_comment_block = true
            end
            if in_comment_block
              if line.include?('*/')
                in_comment_block = false
              end
              else
              entry_string += line
            end
          end
          
          if entry_string.include?(';')
            pattern = /^\s*"(.+)"="(.+)"\s*;\s*(?:\/\/.*)*$/
            result = pattern.match(entry_string)
            if result && result.size == 3
              key = result[1]
              value = result[2]
              @strings[key] = value
            end
            entry_string.clear
          end
        } 
      }
      return true
    end#def
    def read_furniture(file_name)
      content_temp = []
			param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,file_name+".dat"))
				path = File.join(param_temp_path,file_name+".dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF",file_name+".dat"))
				path = File.join(TEMP_PATH,"SUF",file_name+".dat")
				else
				path = File.join(PATH,"parameters",file_name+".dat")
      end
			file = File.new(path,"r")
			content_temp = file.readlines
			file.close
      path = PATH + "/parameters/"+file_name+".dat"
      file = File.new(path,"r")
      content = file.readlines
      file.close
      all_param = []
      if content_temp == []
        all_param = content
        else
        content_temp.each { |cont_temp|
				  if file_name=="template"
            if cont_temp.split("=")[1]=="third_fastener" || cont_temp.split("=")[1].include?("template") || cont_temp.split("=")[1].include?("auto1") || cont_temp.split("=")[1].include?("check_depth")
              content.each { |cont|
                if cont.split("=")[1]==cont_temp.split("=")[1]
                  param = cont.split("=")[0]+"="+cont_temp.split("=")[1]+"="+cont_temp.split("=")[2]+"="+cont_temp.split("=")[3]
                  param += "="+cont_temp.split("=")[4] if cont_temp.split("=")[4]
                  all_param << param
                end
              }
              elsif cont_temp.split("=")[1]=="horizontal_header" || cont_temp.split("=")[1].include?("vertical_header") || cont_temp.split("=")[1].include?("frontal_header")
              content.each { |cont|
                if cont.split("=")[1]==cont_temp.split("=")[1]
                  all_param << cont
                end
              }
              elsif !cont_temp.split("=")[1].include?("header") && cont_temp.split("=").length < 9 && (cont_temp.split("=")[1].include?("horizontal") || cont_temp.split("=")[1].include?("vertical") || cont_temp.split("=")[1].include?("frontal"))
              param = cont_temp.split("=")[0]+"="+cont_temp.split("=")[1]+"="+cont_temp.split("=")[2]+"="+cont_temp.split("=")[3]+"="+cont_temp.split("=")[4]+"=0="+cont_temp.split("=")[5]+"="+cont_temp.split("=")[6]+"="+cont_temp.split("=")[7]+"=0"
              all_param << param
              else
              all_param << cont_temp
            end
						else
						all_param << cont_temp
          end
        }
        new_param = {}
        content.each_with_index { |cont,index|
          if file_name=="hinge" || file_name=="template" && cont.split("=")[1].include?("template") || file_name=="template" && cont.split("=")[1]=="place_fastener" || file_name=="template" && cont.split("=")[1]=="check_depth"
            str = cont.split("=")[0]+"="+cont.split("=")[1]
            new_param[index] = cont if !content_temp.any? { |cont_temp| cont_temp.include?(str) }
          end
        }
        new_param.each_pair{|index,cont| all_param.insert(index,cont)} if new_param != {}
      end
      all_param.map! { |i| i = i.strip.gsub("{","").gsub("}","") }
      command = file_name+"_parameters(#{all_param.inspect})"
      $dlg_param.execute_script(command)
    end#def
    def save_changes(file_name,param)
		  @model = Sketchup.active_model
		  @model.start_operation "Save parameters", true
      if @new_temp
        temp_path = @new_temp
        else
        temp_path = TEMP_PATH
      end
			if file_name == "parameters"
        attrdicts = @model.attribute_dictionaries
        attrdicts.delete 'su_parameters'
        dict = @model.attribute_dictionary('su_parameters', true)
        param.each {|i|
					if i.split("=")[1] == "param_profile"
						Sketchup.write_default("SUF", "PARAM_TEMP_PATH", File.join(temp_path,"SUF",i.split("=")[2]))
          end
					@model.set_attribute('su_parameters', i.split("=")[1], i)
        }
      end
			profile_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH").split("/")[-1]
      if !File.directory?(File.join(temp_path,"SUF"))
        Dir.mkdir(File.join(temp_path,"SUF"))
      end
			if !File.directory?(File.join(temp_path,"SUF",profile_path))
        Dir.mkdir(File.join(temp_path,"SUF",profile_path))
      end
      path_param = File.join(temp_path,"SUF",profile_path,file_name+".dat")
      param_file = File.new(path_param,"w")
      param.each{|i| param_file.puts i }
      param_file.close
      if OSX
        path_param = PATH+"/parameters/"+file_name+".dat"
        param_file = File.new(path_param,"w")
        param.each{|i| param_file.puts i }
        param_file.close
      end
			@model.commit_operation
    end#def
  end #end Class 
end
