module SU_Furniture
  class SaveCopy
    def initialize
      @save_timer = false
      @auto_save = "no"
      @save_time = 5
      read_param
		end#def
    def read_param
      param_temp_path = Sketchup.read_default("SUF", "PARAM_TEMP_PATH")
			if param_temp_path && File.file?(File.join(param_temp_path,"parameters.dat"))
				path_param = File.join(param_temp_path,"parameters.dat")
				elsif File.file?(File.join(TEMP_PATH,"SUF","parameters.dat"))
				path_param = File.join(TEMP_PATH,"SUF","parameters.dat")
				else
				path_param = File.join(PATH,"parameters","parameters.dat")
			end
      param_file = File.new(path_param,"r")
      content = param_file.readlines
      param_file.close
      content.each { |i| 
        @auto_save = i.strip.split("=")[2] if i.strip.split("=")[1] == "auto_save"
        @save_time = i.strip.split("=")[2] if i.strip.split("=")[1] == "save_time"
			}
		end#def
    def save()
      @model = Sketchup.active_model
      if @auto_save == "yes"
        if !@model.title || @model.title == ""
          input = UI.messagebox("#{SUF_STRINGS["Save project"]}?",MB_YESNO)
          if input == IDYES
            filename = UI.savepanel("#{SUF_STRINGS["Save project"]}", Dir.pwd, "*.skp")
            if filename
              filename += '.skp' if filename[-4..-1] != '.skp'
              @model.save(filename)
              @model.save_copy(filename.gsub('.skp',"")+'_copy.skp')
						end
					end
          elsif @model.title.include?('_copy')
          UI.messagebox("#{SUF_STRINGS["Save a copy of the project"]}")
          filename = UI.savepanel("#{SUF_STRINGS["Save project"]}", File.dirname(@model.path), @model.title.gsub('_copy',"")+".skp")
          if filename
            filename += '.skp' if filename[-4..-1] != '.skp'
            @model.save(filename)
            @model.save_copy(filename.gsub('.skp',"")+'_copy.skp')
					end
          elsif !@save_timer
          @save_timer = true
          status = @model.save_copy(File.join(File.dirname(@model.path),@model.title+'_copy.skp'))
          UI.start_timer(@save_time.to_f*60, false) { @save_timer = false }
				end
			end
		end#def
	end
end # module
