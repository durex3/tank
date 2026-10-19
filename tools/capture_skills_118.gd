extends SceneTree
## Production sessions: committed skill frames, never synthetic damage visuals.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	for pair: Array in [[&"cannon",&"heavy_tracks"]]:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		assert(screen.session.configure_loadout(pair[0],pair[1]).is_empty())
		root.add_child(screen)
		var session: MovementSession = screen.session
		session.set_physics_process(false)
		for i: int in range(5): await physics_frame
		var start: Vector3 = session.actor.position
		for tick: int in range(1,101):
			if session.phase == MovementSession.Phase.PAUSED: session.resume()
			var command := PlayerCommand.new()
			command.sequence = session.simulation.tick+1
			command.client_tick = command.sequence
			command.session_epoch = session.simulation.session_epoch
			command.ability_request_id = 1 if tick == 1 else 0
			command.aim_distance_cm = 500
			command.fire_request_id = 1 if tick == 70 else 0
			command.fire_held = pair[0] == &"autocannon"
			session.simulation.enqueue_command(command)
			session.simulation.step()
			await process_frame
			screen.pause_overlay.dismiss()
			RenderingServer.force_draw(false)
			if tick in [26,28,30,32,35,38,42,78]:
				assert(root.get_texture().get_image().save_png("res://artifacts/118-%s-%03d.png" % [pair[0],tick]) == OK)
		if pair[0] == &"scatter": assert(session.actor.position.distance_to(start) > 3.0,"Production floor must not terminate dash")
		session.stop()
		screen.free()
		await process_frame
	print("SKILL CAPTURE: PASS")
	quit()
