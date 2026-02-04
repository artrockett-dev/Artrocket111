module SU_Furniture
  def SU_Furniture.delete_hidden()
    @model = Sketchup.active_model
    selection = @model.selection.grep(Sketchup::ComponentInstance).to_a
    @hidden_objects = []
    selection.each { |e| search_hidden_objects(e) }
    if @hidden_objects != []
      @model.start_operation SUF_STRINGS["Delete hidden objects"], true
      @hidden_objects.each { |e| e.erase! if !e.deleted? }
      @model.commit_operation
    end
  end#def
  def SU_Furniture.search_hidden_objects(ent)
    @hidden_objects << ent if ent.hidden?
    ent.definition.entities.grep(Sketchup::ComponentInstance).each { |e| SU_Furniture.search_hidden_objects(e) }
  end#def
end
