extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	screen.session.set_physics_process(false)
	await physics_frame
	for frame: int in range(60):
		screen.session.simulation.step()
		await physics_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/training-moving-target.png")
	screen.session.pause()
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/training-pause.png")
	print("TRAINING PAUSE CAPTURE: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
