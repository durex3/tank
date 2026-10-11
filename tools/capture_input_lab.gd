extends SceneTree
## Optional desktop visual check; run with a rendering backend, not --headless.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/input_lab.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://artifacts/input-lab.png")
	print("INPUT LAB CAPTURE: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
