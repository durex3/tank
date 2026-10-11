extends SceneTree
## Actual bot shots and player lifecycle, not injected damage events.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	screen.session.set_physics_process(false)
	for frame: int in range(30):
		await physics_frame
	var start := screen.find_child("StartSparring", true, false) as Button
	start.pressed.emit()
	var session: MovementSession = screen.session
	if session.sparring == null:
		push_error("Sparring failed to start")
		quit(1)
		return
	for frame: int in range(90):
		session.sparring.sample_next_tick()
		session.simulation.step()
		await physics_frame
	var failed := await _save("sparring-damage.png") != OK
	for frame: int in range(360):
		if session.actor.health.hp == 0:
			break
		session.sparring.sample_next_tick()
		session.simulation.step()
		await physics_frame
	failed = failed or await _save("sparring-player-down.png") != OK
	for frame: int in range(200):
		if session.actor.health.hp > 0:
			break
		session.sparring.sample_next_tick()
		session.simulation.step()
		await physics_frame
	failed = failed or await _save("sparring-rebuild.png") != OK
	print("SPARRING CAPTURE: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _save(file: String) -> Error:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image().save_png("res://artifacts/" + file)
