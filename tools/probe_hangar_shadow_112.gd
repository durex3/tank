extends SceneTree
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(800,700)
	var studio := HangarPreview.new()
	root.add_child(studio)
	studio.tank.configure_parts(&"bubble_cannon", &"scout_wheels")
	studio.tank.rotation.y = 1.1
	var key: DirectionalLight3D
	for child: Node in studio.get_children():
		if child is DirectionalLight3D and child.shadow_enabled: key = child
	for preset: int in range(3):
		if preset >= 0:
			get_root().get_camera_3d().far = 12.0
			key.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
			key.directional_shadow_max_distance = 10.0
			key.shadow_normal_bias = [.4, .7, 1.0][preset]
			key.shadow_bias = [.1, .2, .3][preset]
		if preset >= 0:
			key.light_energy = .65
			for child: Node in studio.get_children():
				if child is DirectionalLight3D and not child.shadow_enabled: child.light_energy *= 1.35
		for frame: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/112-shadow-%d.png" % preset)
	quit()
