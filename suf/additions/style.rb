require 'sketchup.rb'
module SU_Furniture
	def SU_Furniture.change_style(model)
		if model.styles.active_style.name == "HiddenColorLine"
			display_axes = model.rendering_options["DisplaySketchAxes"]
			last_style_name = model.get_attribute('pages_properties','last_style_name')
			if last_style_name
				style = model.styles.detect { |style| last_style_name == style.name }
				model.styles.selected_style = style if style
				else
				model.styles.selected_style = model.styles[0] if model.styles.count > 0
			end
			model.rendering_options["DisplaySketchAxes"] = display_axes
			else
			display_axes = model.rendering_options["DisplaySketchAxes"]
			model.set_attribute('pages_properties','last_style_name',model.styles.active_style.name)
			new_style = PATH + '/template/HiddenColorLine.style'
			model.styles.add_style(new_style, true)
			model.rendering_options["DisplaySketchAxes"] = display_axes
		end
	end
end
