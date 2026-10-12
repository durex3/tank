extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://bubble_model_capture_fixture.json"
	root.add_child(screen)
	for i: int in range(8): await process_frame
	if not screen.art_stage._show_model: screen.art_stage._toggle_view()
	Input.warp_mouse(Vector2(10,10))
	for chassis: StringName in [&"light_tracks",&"scout_wheels",&"heavy_tracks"]:
		screen.restore_selection(&"bubble_cannon",chassis)
		for i: int in range(6): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/bubble-model-"+str(chassis)+".png") == OK)
	screen.preview.rotate_preview(PI)
	for i: int in range(6): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/bubble-model-rear.png") == OK)
	screen.queue_free()
	await process_frame
	print("BUBBLE MODEL CAPTURE: PASS")
	quit()
