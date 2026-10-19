extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	for chassis: StringName in [&"light_tracks",&"heavy_tracks",&"scout_wheels"]:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		assert(screen.session.configure_loadout(&"cannon",chassis).is_empty())
		root.add_child(screen)
		var session: MovementSession = screen.session
		session.set_physics_process(false)
		for i: int in range(5): await physics_frame
		for tick: int in range(1,61):
			if session.phase == MovementSession.Phase.PAUSED: session.resume()
			var command := PlayerCommand.new()
			command.sequence = session.simulation.tick+1
			command.client_tick = command.sequence
			command.session_epoch = session.simulation.session_epoch
			if chassis == &"light_tracks":
				command.move_z = -127
				command.fire_request_id = 1 if tick == 8 else 0
			if tick == 10 and chassis != &"light_tracks":
				session.simulation.projectiles.spawn(session.actor.get_world_3d().direct_space_state,session.actor.position+Vector3.FORWARD*4,PI,LoadoutCatalog.weapon(&"cannon"),999,1,session.simulation.tick,NAN,1)
			session.simulation.enqueue_command(command)
			session.simulation.step()
			await process_frame
			screen.pause_overlay.dismiss()
			RenderingServer.force_draw(false)
			if tick in [18,20,25,33]:
				assert(root.get_texture().get_image().save_png("res://artifacts/123-%s-passive-%02d.png" % [chassis,tick]) == OK)
		session.stop()
		screen.free()
		await process_frame
	print("CHASSIS CAPTURE: PASS")
	quit()
