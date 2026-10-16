extends SceneTree
## Production catalog, twelve combinations and the actual hangar screen.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1260, 690)
	var previews: Array[HangarPreview] = []
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 0)
	grid.add_theme_constant_override("v_separation", 0)
	root.add_child(grid)
	for weapon: StringName in TankPartCatalog.WEAPONS:
		for chassis: StringName in TankPartCatalog.CHASSIS:
			var container := SubViewportContainer.new()
			container.custom_minimum_size = Vector2(315, 230)
			grid.add_child(container)
			var viewport := SubViewport.new()
			viewport.size = Vector2i(315,230)
			viewport.own_world_3d = true
			viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			container.add_child(viewport)
			var preview := HangarPreview.new()
			viewport.add_child(preview)
			previews.append(preview)
			for lamp: Node in preview.get_children():
				if lamp is Light3D: assert(not lamp.shadow_enabled)
			assert(preview.tank.configure_parts(weapon,chassis).is_empty())
			var camera := viewport.get_camera_3d()
			camera.size = 3.5
			camera.look_at(Vector3(0,0.9,0))
			var label := Label.new()
			label.text = "%s + %s" % [weapon,chassis]
			container.add_child(label)
	for frame: int in range(12): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-twelve-combinations.png") == OK)
	for preview: HangarPreview in previews: preview.rotate_preview(PI)
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-twelve-rear.png") == OK)
	grid.free()
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://mechanical_113_fixture.json"
	root.add_child(screen)
	for frame: int in range(12): await process_frame
	screen.restore_selection(&"bubble_cannon",&"scout_wheels")
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-hangar.png") == OK)
	screen.preview.rotate_preview(PI)
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-hangar-rear.png") == OK)
	root.size = Vector2i(960,640)
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-hangar-small.png") == OK)
	(screen.directory.grid.get_parent() as ScrollContainer).scroll_vertical = 400
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/113-hangar-scrolled.png") == OK)
	print("REFINED PRODUCTION TWELVE COMBINATIONS AND HANGAR PASS")
	quit()
