extends SceneTree
## Real dual-gun firing followed by right turn and reverse, held turret aim.

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	assert(screen.session.configure_loadout(&"autocannon",&"scout_wheels").is_empty())
	root.add_child(screen)
	var session: MovementSession = screen.session
	session.set_physics_process(false)
	for i: int in range(12): await physics_frame
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	for tick: int in range(1,81):
		var command := PlayerCommand.new()
		command.sequence = session.simulation.tick+1
		command.client_tick = command.sequence
		command.session_epoch = session.simulation.session_epoch
		command.fire_held = tick in [1,11,21]
		command.move_x = 127 if tick >= 25 and tick <= 40 else 0
		command.move_z = 127 if tick > 40 and tick < 65 else 0
		session.simulation.enqueue_command(command)
		session.simulation.step()
		# Every movement tick is actually rendered; snapshots sample the continuous sequence.
		for i: int in range(2): await process_frame
		screen.pause_overlay.dismiss()
		await RenderingServer.frame_post_draw
		if tick in [1,2,10,11,12,20,21,25,30,40,50,60,70,80]:
			assert(root.get_texture().get_image().save_png("res://artifacts/handling-%02d.png" % tick) == OK)
	session.stop()
	screen.free()
	await process_frame
	print("HANDLING CAPTURE: PASS")
	quit()
