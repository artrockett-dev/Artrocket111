module SU_Furniture
  class DrawSection
    def initialize()
      @pts = []
      @orange = Sketchup::Color.new(210, 130, 0, 150)
    end#def
    def import_pts(pts)
      @pts = pts
    end#def
    def activate
      @model=Sketchup.active_model
      view = @model.active_view
      @ents = @model.entities
      view.invalidate
    end#def
    def deactivate(view)
      view.invalidate
      @pts = []
    end#def
    def draw(view)
      view.drawing_color = @orange
      if @pts != []
        @pts.each{|pts| view.draw(GL_QUADS, pts)}
      end
    end#def
    def resume(view)
      view.invalidate
      draw(view)
    end#def
  end#Class
end#Module
