extends SceneTree
## Individual 3D parts photographed with directional key, restrained fill and rim.

const STYLE: PartCardRenderStyle = preload("res://content/presentation/part_cards_v3.tres")

func _initialize() -> void:
	call_deferred("_run")

func _light(viewport: SubViewport, rotation_value: Vector3, energy: float, color: Color, shadows: bool = false) -> void:
	var light := DirectionalLight3D.new()
	light.rotation_degrees = rotation_value
	light.light_energy = energy
	light.light_color = color
	light.shadow_enabled = shadows
	light.shadow_blur = 1.5
	viewport.add_child(light)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/derived/volume-cards-v3")
	for group: Dictionary in [TankPartCatalog.WEAPONS,TankPartCatalog.CHASSIS]:
		for id: StringName in group:
			var viewport := SubViewport.new()
			viewport.size = Vector2i.ONE*STYLE.render_pixels
			viewport.transparent_bg = true
			viewport.own_world_3d = true
			viewport.msaa_3d = Viewport.MSAA_4X
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			root.add_child(viewport)
			var part := (group[id] as PackedScene).instantiate() as Node3D
			viewport.add_child(part)
			TankSurfacePolish.apply(part,id)
			for instance: MeshInstance3D in part.find_children("*","MeshInstance3D",true,false):
				for surface: int in range(instance.mesh.get_surface_count()):
					var material := instance.get_surface_override_material(surface) as ShaderMaterial
					if material == null: continue
					material.shader = preload("res://presentation/shaders/card_volume.gdshader")
					material.set_shader_parameter("lower_value",STYLE.lower_value)
					material.set_shader_parameter("upper_value",STYLE.upper_value)
					material.set_shader_parameter("side_value",STYLE.side_value)
			var camera := Camera3D.new()
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = STYLE.camera_size
			camera.position = STYLE.camera_position
			viewport.add_child(camera)
			camera.look_at(STYLE.camera_target)
			_light(viewport,STYLE.key_rotation,STYLE.key_energy,Color("fff2d9"),true)
			_light(viewport,STYLE.fill_rotation,STYLE.fill_energy,Color("c9e1ff"))
			_light(viewport,STYLE.rim_rotation,STYLE.rim_energy,Color("e5efff"))
			var environment := WorldEnvironment.new()
			environment.environment = Environment.new()
			environment.environment.background_mode = Environment.BG_COLOR
			environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.environment.ambient_light_color = Color("dce7f2")
			environment.environment.ambient_light_energy = STYLE.ambient_energy
			viewport.add_child(environment)
			for i: int in range(8): await process_frame
			await RenderingServer.frame_post_draw
			var picture: Image = viewport.get_texture().get_image()
			picture.resize(STYLE.output_pixels,STYLE.output_pixels,Image.INTERPOLATE_LANCZOS)
			assert(picture.save_png("res://assets/derived/volume-cards-v3/%s.png" % id) == OK)
			TankSurfacePolish.clear(part)
			viewport.free()
			await process_frame
	print("VOLUME CARD CAPTURE: PASS")
	quit()
