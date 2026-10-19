extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/derived/family-cards-v3")
	for id: StringName in [&"cannon", &"autocannon", &"scatter", &"bubble_cannon", &"light_tracks", &"scout_wheels", &"heavy_tracks"]:
		var viewport := SubViewport.new()
		viewport.size = Vector2i(512,512)
		viewport.transparent_bg = true
		viewport.own_world_3d = true
		viewport.msaa_3d = Viewport.MSAA_4X
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var studio := HangarPreview.new()
		viewport.add_child(studio)
		studio.tank.hide()
		for child: Node in studio.get_children():
			if child is MeshInstance3D: child.hide()
		var packed: PackedScene = TankPartCatalog.WEAPONS[id] if TankPartCatalog.WEAPONS.has(id) else TankPartCatalog.CHASSIS[id]
		var part := packed.instantiate() as Node3D
		studio.add_child(part)
		TankSurfacePolish.apply(part, id)
		var camera := viewport.get_camera_3d()
		camera.size = 2.6
		camera.position = Vector3(-3,2.2,-4)
		camera.look_at(Vector3(0,0.50,-0.15))
		for frame: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		assert(viewport.get_texture().get_image().save_png("res://assets/derived/family-cards-v3/%s.png" % id) == OK)
		viewport.free()
	print("REFINED MODEL CARDS PASS")
	quit()
