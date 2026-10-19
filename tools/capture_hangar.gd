extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	root.add_child(screen)
	for frame: int in range(30):
		await physics_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/hangar-cannon-light.png")
	screen.weapon_picker.select(2)
	screen.chassis_picker.select(2)
	screen.weapon_picker.item_selected.emit(2)
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	error = maxi(error, root.get_texture().get_image().save_png("res://artifacts/hangar-scatter-heavy.png"))
	screen.weapon_picker.select(1)
	screen.chassis_picker.select(1)
	screen.weapon_picker.item_selected.emit(1)
	for frame: int in range(5):
		await process_frame
	await RenderingServer.frame_post_draw
	error = maxi(error, root.get_texture().get_image().save_png("res://artifacts/hangar-autocannon-scout.png"))
	for viewport_size: Vector2i in [Vector2i(1024, 768), Vector2i(1600, 720)]:
		root.size = viewport_size
		for frame: int in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var path := "res://artifacts/hangar-%dx%d.png" % [viewport_size.x, viewport_size.y]
		error = maxi(error, root.get_texture().get_image().save_png(path))
	print("HANGAR CAPTURE: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
