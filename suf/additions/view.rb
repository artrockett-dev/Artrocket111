module SU_Furniture
	module View
		def self.aspect_ratio(view = Sketchup.active_model.active_view)
			return view.camera.aspect_ratio unless view.camera.aspect_ratio.zero?
			vp_aspect_ratio(view)
		end
		def self.aspect_ratio_ratio(view = Sketchup.active_model.active_view)
			aspect_ratio(view) / vp_aspect_ratio(view)
		end
		def self.explicit_aspect_ratio?(view = Sketchup.active_model.active_view)
			view.camera.aspect_ratio != 0
		end
		def self.fov_h(view = Sketchup.active_model.active_view)
			return view.camera.fov unless view.camera.fov_is_height?
			frustum_ratio(view.camera.fov, aspect_ratio(view))
		end
		def self.fov_v(view = Sketchup.active_model.active_view)
			return view.camera.fov if view.camera.fov_is_height?
			frustum_ratio(view.camera.fov, 1 / aspect_ratio(view))
		end
		def self.full_fov_h(view = Sketchup.active_model.active_view)
			frustum_ratio(fov_h(view), [1 / aspect_ratio_ratio(view), 1].max)
		end
		def self.full_fov_v(view = Sketchup.active_model.active_view)
			frustum_ratio(fov_v(view), [aspect_ratio_ratio(view), 1].max)
		end
		def self.full_height(view = Sketchup.active_model.active_view)
			view.camera.height.to_l
		end
		def self.full_width(view = Sketchup.active_model.active_view)
			(full_height(view) * vp_aspect_ratio(view)).to_l
		end
		def self.height(view = Sketchup.active_model.active_view)
			(full_height(view) / [1, aspect_ratio_ratio(view)].max).to_l
		end
		def self.reset_aspect_ratio(view = Sketchup.active_model.active_view)
			set_aspect_ratio(0, view)
		end
		def self.set_aspect_ratio(aspect_ratio,
		view = Sketchup.active_model.active_view)
    fov = full_fov_v(view) if view.camera.perspective?
    view.camera.aspect_ratio = aspect_ratio
    set_full_fov_v(fov, view) if view.camera.perspective?
		end
		def self.set_fov_h(fov, view = Sketchup.active_model.active_view)
			view.camera.fov =
			if view.camera.fov_is_height?
				frustum_ratio(fov, 1 / aspect_ratio)
				else
				fov
			end
		end
		def self.set_fov_v(fov, view = Sketchup.active_model.active_view)
			view.camera.fov =
			if view.camera.fov_is_height?
				fov
				else
				frustum_ratio(fov, aspect_ratio)
			end
		end
		def self.set_full_fov_h(fov, view = Sketchup.active_model.active_view)
			set_fov_h(frustum_ratio(fov, [aspect_ratio_ratio(view), 1].min), view)
		end
		def self.set_full_fov_v(fov, view = Sketchup.active_model.active_view)
			set_fov_v(frustum_ratio(fov, [1 / aspect_ratio_ratio(view), 1].min), view)
		end
		def self.set_full_height(height, view = Sketchup.active_model.active_view)
			view.camera.height = height
		end
		def self.set_full_width(width, view = Sketchup.active_model.active_view)
			set_full_height(width / vp_aspect_ratio, view)
		end
		def self.set_height(height, view = Sketchup.active_model.active_view)
			set_full_height(height * [aspect_ratio_ratio(view), 1].max, view)
		end
		def self.set_width(width, view = Sketchup.active_model.active_view)
			set_full_width(width * [1 / aspect_ratio_ratio(view), 1].max, view)
		end
		def self.set_x(x, view = Sketchup.active_model.active_view)
			view.camera.perspective? ? set_fov_h(x, view) : set_width(x, view)
		end
		def self.set_y(y, view = Sketchup.active_model.active_view)
			view.camera.perspective? ? set_fov_v(y, view) : set_height(y, view)
		end
		def self.vp_aspect_ratio(view = Sketchup.active_model.active_view)
			view.vpwidth / view.vpheight.to_f
		end
		def self.width(view = Sketchup.active_model.active_view)
			(full_width(view) / [1, 1 / aspect_ratio_ratio(view)].max).to_l
		end
		def self.x(view = Sketchup.active_model.active_view)
			view.camera.perspective? ? fov_h(view) : width(view)
		end
		def self.y(view = Sketchup.active_model.active_view)
			view.camera.perspective? ? fov_v(view) : height(view)
		end
		def self.frustum_ratio(angle, ratio)
			Math.atan(Math.tan(angle.degrees / 2) * ratio).radians * 2
		end
		private_class_method :frustum_ratio
	end
	module Frustum
		def self.planes(view = Sketchup.active_model.active_view, full: false,
		padding: 0)
		raise ArgumentError, "Padding must be smaller than 50%" if padding >= 50
		if view.camera.perspective?
			perspective_planes(view, full, padding)
			else
			parallel_planes(view, full, padding)
		end
		end
		def self.perspective_planes(view, full, padding)
			cam = view.camera
			half_fov_h = (full ? View.full_fov_h(view) : View.fov_h(view)) / 2
			half_fov_v = (full ? View.full_fov_v(view) : View.fov_v(view)) / 2
			half_fov_h *= (1 - padding / 50.0)
			half_fov_v *= (1 - padding / 50.0)
			[
				[cam.eye, rotate_vector(cam.xaxis.reverse, cam.eye, cam.up, half_fov_h)],
				[cam.eye, rotate_vector(cam.xaxis, cam.eye, cam.up, -half_fov_h)],
				[cam.eye, rotate_vector(cam.up.reverse, cam.eye, cam.xaxis, -half_fov_v)],
				[cam.eye, rotate_vector(cam.up, cam.eye, cam.xaxis, half_fov_v)]
			]
		end
		private_class_method :perspective_planes
		def self.rotate_vector(vector, point, axis, angle)
			vector.transform(Geom::Transformation.rotation(point, axis, angle.degrees))
		end
		private_class_method :rotate_vector
		def self.parallel_planes(view, full, padding)
			cam = view.camera
			half_height = (full ? View.full_height(view) : View.height(view)) / 2
			half_width = (full ? View.full_width(view) : View.width(view)) / 2
			half_height /= (1 - padding / 50.0)
			half_width /= (1 - padding / 50.0)
			[
				[cam.eye.offset(cam.xaxis, -half_width), cam.xaxis.reverse],
				[cam.eye.offset(cam.xaxis, half_width), cam.xaxis],
				[cam.eye.offset(cam.up, -half_height), cam.up.reverse],
				[cam.eye.offset(cam.up, half_height), cam.up]
			]
		end
		private_class_method :parallel_planes
	end
	module Zoom
		def self.zoom_entities(entities, view = Sketchup.active_model.active_view,
		padding: 2.5, full: false)
		entities = [entities] unless entities.respond_to?(:each)
		zoom_points(points(entities), view, padding: padding, full: full)
		end
		def self.zoom_points(points, view = Sketchup.active_model.active_view,
		padding: 2.5, full: false)
		raise ArgumentError, "Padding must be smaller than 50%" if padding >= 50
		return if points.empty?
		if view.camera.perspective?
			zoom_perspective(points, view, padding, full)
			else
			zoom_parallel(points, view, padding, full)
		end
		end
		def self.zoom_parallel(points, view, padding, full)
			transformation = camera_space(view)
			extremes = extreme_planes(points, view, padding, full)
			extremes.map! { |pl| pl.map { |c| c.transform(transformation.inverse) } }
			height = (extremes[3][0].y - extremes[2][0].y) / (1 - padding / 50.0)
			width = (extremes[1][0].x - extremes[0][0].x) / (1 - padding / 50.0)
			eye = Geom::Point3d.new(
				(extremes[0][0].x + extremes[1][0].x) / 2,
				(extremes[2][0].y + extremes[3][0].y) / 2,
				0
			).transform(transformation)
			view.camera.set(eye, view.camera.direction, view.camera.up)
			set_zoom(view, width, height, full)
			width / height
		end
		private_class_method :zoom_parallel
		def self.set_zoom(view, width, height, full)
			aspect_ratio = full ? View.vp_aspect_ratio(view) : View.aspect_ratio(view)
			if aspect_ratio > width / height
				View.set_height(height, view)
				else
				View.set_width(width, view)
			end
		end
		private_class_method :set_zoom
		def self.zoom_perspective(points, view, padding, full)
			transformation = camera_space(view)
			extremes = extreme_planes(points, view, padding, full)
			extremes.map! { |pl| pl.map { |c| c.transform(transformation.inverse) } }
			line_y = Geom.intersect_plane_plane(extremes[0], extremes[1])
			line_x = Geom.intersect_plane_plane(extremes[2], extremes[3])
			eye = Geom::Point3d.new(
				line_y[0].x,
				line_x[0].y,
				[line_x[0].z, line_y[0].z].min
			).transform(transformation)
			view.camera.set(eye, view.camera.direction, view.camera.up)
			bb = Geom::BoundingBox.new
			bb.add(points.map { |pt| view.screen_coords(pt) })
			width = [(bb.max.x - view.center.x).abs, (bb.min.x - view.center.x).abs].max
			height =
			[(bb.max.y - view.center.y).abs, (bb.min.y - view.center.y).abs].max
			width / height
		end
		private_class_method :zoom_perspective
		def self.camera_space(view)
			Geom::Transformation.axes(view.camera.eye, view.camera.xaxis,
			view.camera.yaxis, view.camera.zaxis)
		end
		private_class_method :camera_space
		def self.points(entities, transformation = IDENTITY)
			entities.flat_map do |entity|
				case entity
					when Sketchup::Edge, Sketchup::Face
					entity.vertices.map { |v| v.position.transform(transformation) }
					when Sketchup::Group, Sketchup::ComponentInstance
					points(entity.definition.entities,
					transformation * entity.transformation)
				end
			end.compact
		end
		private_class_method :points
		def self.extreme_planes(points, view, padding, full)
			Frustum.planes(view, padding: padding, full: full).map do |plane|
				transformation = Geom::Transformation.new(*plane).inverse
				point = points.max_by { |pt| pt.transform(transformation).z }
				[point, plane[1]]
			end
		end
		private_class_method :extreme_planes
	end
end