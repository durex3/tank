extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://model_capture_fixture.json"
	root.add_child(screen)
	for frame: int in range(12): await process_frame
	screen.directory.cards[&"scatter"].pressed.emit()
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var suffix: String = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	root.get_texture().get_image().save_png("res://artifacts/model-preview-%s.png" % suffix)
	print("MODEL PREVIEW ", screen.art_stage._model.size)
	if suffix == "after":
		for weapon: StringName in [&"cannon", &"autocannon", &"scatter"]:
			for chassis: StringName in [&"light_tracks", &"scout_wheels", &"heavy_tracks"]:
				screen.restore_selection(weapon, chassis)
				for frame: int in range(4): await process_frame
				await RenderingServer.frame_post_draw
				var area := Rect2i(screen.art_stage._model.get_global_rect())
				root.get_texture().get_image().get_region(area).save_png("res://artifacts/model-%s-%s.png" % [weapon, chassis])
		screen.preview.rotate_preview(PI * 0.75)
		for frame: int in range(4): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/model-preview-rotated.png")
		root.size = Vector2i(1600, 900)
		for frame: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/model-preview-large.png")
	quit()
