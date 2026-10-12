extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://composition_capture_fixture.json"
	root.add_child(screen)
	for frame: int in range(12): await process_frame
	var gallery := Image.create(1665,1032,false,Image.FORMAT_RGBA8)
	var row: int = 0
	for chassis: StringName in [&"light_tracks", &"heavy_tracks", &"scout_wheels"]:
		var column: int = 0
		for weapon: StringName in [&"cannon", &"autocannon", &"scatter"]:
			screen.restore_selection(weapon,chassis)
			for frame: int in range(4): await process_frame
			await RenderingServer.frame_post_draw
			var image := root.get_texture().get_image()
			if row == 0 and column == 0:
				image.save_png("res://artifacts/hangar-composition.png")
			var region := image.get_region(Rect2i(screen.art_stage.artwork.get_global_rect()))
			region.resize(555,344,Image.INTERPOLATE_LANCZOS)
			gallery.blit_rect(region,Rect2i(Vector2i.ZERO,region.get_size()),Vector2i(column*555,row*344))
			column += 1
		row += 1
	gallery.save_png("res://artifacts/hangar-composition-gallery.png")
	print("COMPOSITION CAPTURE: PASS")
	quit()
