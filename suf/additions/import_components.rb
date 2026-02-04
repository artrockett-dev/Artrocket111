module SU_Furniture
  def SU_Furniture.import_components()
    @model = Sketchup.active_model
    df = @model.definitions
    ent = @model.entities
    path = UI.select_directory(
      title: SUF_STRINGS["Select a folder"],
      directory: Dir.pwd,
      select_multiple: false
    )
    if path
      cwd = Dir.chdir(path)
      @model.start_operation('Import components', true)
      dir_arr = Dir.new(path).entries
      dir_arr.map! { |d| d = d.encode("utf-8") }
      skps = dir_arr.reject { |s| s unless s =~ /\.skp/ }
      return if skps.count == 0
      x = 0
      y = 0
      skps.each { |skp|
        if Sketchup.version_number >= 2110000000
          new_comp = df.load(File.join(path,skp), allow_newer: true)
          else
          new_comp = df.load File.join(path,skp)
        end
        t = Geom::Transformation.translation [x, y, 0]
        new_comp_place = ent.add_instance new_comp, t
        lenx = new_comp_place.bounds.width
        x += lenx+100/25.4
        if x > 5000/25.4
          x = 0
          y += 1000/25.4
        end
      }
      @model.commit_operation
    end
  end#def
end
