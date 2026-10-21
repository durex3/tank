extends SceneTree
## Production sessions: committed skill frames, never synthetic damage visuals.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	for pair: Array in [[&"cannon",&"heavy_tracks"],[&"autocannon",&"scout_wheels"]]:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		assert(screen.session.configure_loadout(pair[0],pair[1]).is_empty())
		root.add_child(screen)
		var session: MovementSession = screen.session
		session.set_physics_process(false)
		for i: int in range(5): await physics_frame
		var start: Vector3 = session.actor.position
		if pair[0] in [&"cannon",&"autocannon"]:
			var target: TrainingTarget = session.simulation.targets[0]
			target.position = start+Vector3.FORWARD*5
			target.configure_motion(0,0)
			target.force_update_transform()
			target.hurtbox().force_update_transform()
			for i: int in range(2): await physics_frame
		for tick: int in range(1,231):
			if session.phase == MovementSession.Phase.PAUSED: session.resume()
			var command := PlayerCommand.new()
			command.sequence = session.simulation.tick+1
			command.client_tick = command.sequence
			command.session_epoch = session.simulation.session_epoch
			command.ability_request_id = 1 if tick == 1 and pair.size() == 2 else 0
			command.aim_distance_cm = 500
			command.fire_request_id = 1 if tick == 70 else 0
			command.fire_held = pair[0] == &"autocannon"
			session.simulation.enqueue_command(command)
			session.simulation.step()
			await process_frame
			screen.pause_overlay.dismiss()
			RenderingServer.force_draw(false)
			if tick in [10,15,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,38,40,42,48,52,56,57,58,60,62,63,64,65,68,70,72,74,76,78,80,84,90,120,180,220]:
				assert(root.get_texture().get_image().save_png("res://artifacts/132-%s-%03d.png" % [pair[2] if pair.size() > 2 else pair[0],tick]) == OK)
		if pair[0] == &"scatter" and pair.size() == 2: assert(session.actor.position.distance_to(start) > 3.0,"Production floor must not terminate dash")
		session.stop()
		screen.free()
		await process_frame
	print("SKILL CAPTURE: PASS")
	quit()
