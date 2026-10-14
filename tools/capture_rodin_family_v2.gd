extends SceneTree
## Inspect new raw generations before any production mapping changes.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	for id: String in ["autocannon", "scatter", "bubble_cannon", "scout_wheels", "heavy_tracks"]:
		var path := "res://assets/imported/rodin-family-v2/%s.glb" % id
		if not ResourceLoader.exists(path): continue
		var viewport := SubViewport.new()
		viewport.size = Vector2i(640, 640)
		viewport.own_world_3d = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var part := (load(path) as PackedScene).instantiate() as Node3D
		viewport.add_child(part)
		var bounds := AABB()
		var first := true
		for node: Node in part.find_children("*", "MeshInstance3D", true, false):
			var mesh := node as MeshInstance3D
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		print(id, " BOUNDS ", bounds)
		var center := bounds.get_center()
		var size := maxf(bounds.size.x, maxf(bounds.size.y, bounds.size.z))
		var camera := Camera3D.new()
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		camera.size = size * 1.65
		camera.position = center + Vector3(3, 2.6, 4) * size
		viewport.add_child(camera)
		camera.look_at(center)
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-50, -25, 0)
		viewport.add_child(sun)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.background_mode = Environment.BG_COLOR
		environment.environment.background_color = Color("303642")
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color.WHITE
		environment.environment.ambient_light_energy = 0.4
		viewport.add_child(environment)
		for frame: int in range(5): await process_frame
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://artifacts/rodin-family-v2-%s.png" % id) == OK)
		viewport.free()
	print("RODIN FAMILY INSPECTION PASS")
	quit()
