module SU_Furniture
  class Activate
		def Activate_plugin()
      @model = Sketchup.active_model
      sel = @model.selection
      ent = @model.entities
      $attobserver = 0
      $change_att = false
      $change_param = false
      
      sel.remove_observer $SUFSelectionObserver
      $SUFSelectionObserver = SUFSelectionObserver.new
      sel.add_observer $SUFSelectionObserver
      
      ent.remove_observer $SUFEntitiesObserver
      $SUFEntitiesObserver = SUFEntitiesObserver.new
      ent.add_observer $SUFEntitiesObserver
      
      @model.layers.remove_observer $SUFLayersObserver
      $SUFLayersObserver = SUFLayersObserver.new
      @model.layers.add_observer $SUFLayersObserver
      language_file
    end#def
    def language_file
      folder_list = []
      folder_list << 'function translate(str){'
      folder_list << '  if (translate_hash[str]) { return translate_hash[str]; }'
      folder_list << '  else { return str; }'
      folder_list << '}'
      folder_list << 'var translate_hash = {'
      content = SUF_STRINGS.strings.to_a
      content.each_with_index{|arr,i|
        folder_list << '"'+arr[0]+'":"'+arr[1]+'"'+(i==content.size-1 ? "" : ",")
      }
      folder_list << '}' 
      translate_js = PATH + "/html/cont/SUF_translate.js"
      file = File.new(translate_js,"w")
      folder_list.each{|i| file.puts i}
      file.close
    end
  end #class  
end # module SUFurniture

file_loaded(__FILE__)
