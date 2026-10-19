extends SceneTree
## Capture actual stepped projectile volleys and matching selected visual loadouts.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var failed: bool = false
	for pair: Array in [[&"cannon", &"light_tracks"], [&"scatter", &"heavy_tracks"], [&"autocannon", &"scout_wheels"]]:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		screen.session.configure_loadout(pair[0], pair[1])
		root.add_child(screen)
		screen.session.set_physics_process(false)
		for frame: int in range(30):
			await physics_frame
		if screen.session.phase == MovementSession.Phase.PAUSED: screen.session.resume()
		var sim: BattleSimulation = screen.session.simulation
		for frame: int in range(8):
			var command := PlayerCommand.new()
			command.session_epoch = sim.session_epoch
			command.sequence = frame + 1
			command.client_tick = sim.tick + 1
			command.fire_request_id = 1 if frame == 0 else 0
			command.fire_held = true
			sim.enqueue_command(command)
			sim.step()
			await physics_frame
		screen.pause_overlay.dismiss()
		await process_frame
		screen.pause_overlay.dismiss()
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png("res://artifacts/readability-%s.png" % pair[0])
		failed = failed or error != OK
		screen.free()
		await process_frame
	print("WEAPON CAPTURE: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
