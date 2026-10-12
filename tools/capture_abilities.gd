extends SceneTree
## Actual simulation-driven training captures, including art textures, not staged effect screenshots.

func _initialize() -> void:
	call_deferred("_run")

func _step(screen: Control, count: int, request: int = 0, move: Vector2 = Vector2.ZERO, held: bool = false) -> void:
	var session: MovementSession = screen.session
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	for i: int in range(count):
		var command := PlayerCommand.new()
		command.session_epoch = session.simulation.session_epoch
		command.sequence = session.simulation.tick+1
		command.client_tick = command.sequence
		command.ability_request_id = request if i == 0 else 0
		command.move_x = roundi(move.x*127)
		command.move_z = roundi(move.y*127)
		command.fire_held = held
		session.simulation.enqueue_command(command)
		session.simulation.step()
		session.rig.follow(session.actor.position,1.0/60)

func _run() -> void:
	root.size = Vector2i(1280,720)
	var cases: Array[Array] = [["cruise","cannon","light_tracks"],["guard","cannon","heavy_tracks"],["guard-hit","cannon","heavy_tracks"],["smoke","cannon","scout_wheels"],["breach","cannon","light_tracks"],["breach-flight","cannon","light_tracks"],["storm","autocannon","light_tracks"],["cooling","autocannon","light_tracks"],["shock","scatter","heavy_tracks"]]
	for item: Array in cases:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		assert(screen.session.configure_loadout(StringName(item[1]),StringName(item[2])).is_empty())
		root.add_child(screen)
		screen.session.set_physics_process(false)
		for i: int in range(8): await process_frame
		await physics_frame
		match item[0]:
			"cruise": _step(screen,110,0,Vector2.RIGHT)
			"guard": _step(screen,40)
			"guard-hit":
				_step(screen,40)
				assert(screen.session.start_sparring().is_empty())
				var rival: TankActor = screen.session.sparring.rival
				rival.position = Vector3(0,0,-3)
				rival.force_update_transform()
				rival.hurtbox.force_update_transform()
				await physics_frame
				screen.session.simulation.projectiles.spawn(screen.session.actor.get_world_3d().direct_space_state,rival.position,PI,screen.session.simulation.rival_weapon,2,1,screen.session.simulation.tick,NAN,1)
				_step(screen,7)
				assert(not screen.session.ability_effects._art._messages.is_empty())
			"smoke":
				assert(screen.session.start_sparring().is_empty())
				var rival: TankActor = screen.session.sparring.rival
				rival.position = Vector3(0,0,-3)
				rival.force_update_transform()
				rival.hurtbox.force_update_transform()
				await physics_frame
				screen.session.simulation.projectiles.spawn(screen.session.actor.get_world_3d().direct_space_state,rival.position,PI,screen.session.simulation.rival_weapon,2,1,0,NAN,1)
				_step(screen,10)
			"breach": _step(screen,20,1)
			"breach-flight": _step(screen,30,1)
			"storm": _step(screen,16,1,Vector2.ZERO,true)
			"cooling": _step(screen,185,1)
			"shock":
				assert(screen.session.start_sparring().is_empty())
				var rival: TankActor = screen.session.sparring.rival
				rival.position = Vector3(0,0,-3)
				rival.force_update_transform()
				rival.hurtbox.force_update_transform()
				await physics_frame
				_step(screen,21,1)
		for i: int in range(3): await process_frame
		if screen.session.phase == MovementSession.Phase.PAUSED:
			screen.session.resume()
			await process_frame
		if item[0] == "storm": assert(screen.session.actor.ability.phase == &"storm")
		if item[0] == "breach": assert(screen.session.actor.ability.phase == &"breach")
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/ability-"+item[0]+".png") == OK)
		print("CAPTURE ",item[0]," hp=",screen.session.actor.health.hp," phase=",screen.session.actor.ability.phase)
		screen.session.stop()
		screen.queue_free()
		await process_frame
	print("ABILITY CAPTURE: PASS")
	quit()
