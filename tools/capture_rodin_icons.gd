extends SceneTree
## Render authored standalone 3D parts, never crop whole-tank illustrations.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	for group: Dictionary in [{&"cannon": TankPartCatalog.WEAPONS[&"cannon"], &"light_tracks": TankPartCatalog.CHASSIS[&"light_tracks"]}]:
		for id: StringName in group:
			var viewport := SubViewport.new()
			viewport.size = Vector2i(512, 512)
			viewport.transparent_bg = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			viewport.own_world_3d = true
			root.add_child(viewport)
			var part := (group[id] as PackedScene).instantiate() as Node3D
			viewport.add_child(part)
			var camera := Camera3D.new()
			camera.projection = Camera3D.PROJECTION_ORTHOGONAL
			camera.size = 3.3
			camera.position = Vector3(3, 2.6, -4)
			viewport.add_child(camera)
			camera.look_at(Vector3(0, 0.3, -0.2))
			var sun := DirectionalLight3D.new()
			sun.rotation_degrees = Vector3(-50, -25, 0)
			sun.light_energy = 0.9
			viewport.add_child(sun)
			var environment := WorldEnvironment.new()
			environment.environment = Environment.new()
			environment.environment.background_mode = Environment.BG_COLOR
			environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			environment.environment.ambient_light_color = Color.WHITE
			environment.environment.ambient_light_energy = 0.4
			viewport.add_child(environment)
			for frame: int in range(5):
				await process_frame
			await RenderingServer.frame_post_draw
			var error := viewport.get_texture().get_image().save_png("res://assets/derived/rodin-v1/%s.png" % id)
			if error != OK:
				quit(1)
				return
			viewport.queue_free()
			await process_frame
	print("PART ICON CAPTURE: PASS")
	quit()
