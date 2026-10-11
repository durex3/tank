extends SceneTree
## Desktop rendering evidence for authoritative projectile and confirmed hit.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	screen.session.set_physics_process(false)
	await physics_frame
	await physics_frame
	var command := PlayerCommand.new()
	command.sequence = 1
	command.client_tick = 1
	command.fire_request_id = 1
	screen.session.simulation.enqueue_command(command)
	for frame: int in range(22):
		screen.session.simulation.step()
		await physics_frame
		if frame == 8:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/combat-projectile.png")
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/combat-hit.png")
	print("COMBAT CAPTURE: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
