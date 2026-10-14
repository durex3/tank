extends SceneTree
## InputMap -> DesktopInputSource -> camera mapping -> real simulation, mouse aim independent.

func _initialize() -> void:
	call_deferred("_run")

func _step(session: MovementSession) -> void:
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	session.desktop._focused = true
	session.mouse_viewport_position = session.rig.camera.unproject_position(session.actor.position+Vector3.FORWARD*8)
	session._physics_process(1.0/60)

func _run() -> void:
	root.size = Vector2i(1280,720)
	for pair: Array in [["move_left","move_right","left-to-D"],["move_right","move_left","right-to-A"]]:
		var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
		root.add_child(screen)
		var session: MovementSession = screen.session
		session.set_physics_process(false)
		for i: int in range(12): await physics_frame
		if session.phase == MovementSession.Phase.PAUSED: session.resume()
		session.use_touch = false
		session.desktop.set_enabled(true)
		Input.action_press(pair[0])
		for i: int in range(50): _step(session)
		Input.action_release(pair[0])
		Input.action_press(pair[1])
		for tick: int in range(1,41):
			_step(session)
			for i: int in range(2): await process_frame
			screen.pause_overlay.dismiss()
			await RenderingServer.frame_post_draw
			if tick in [1,5,10,20,30,40]:
				var front := Vector3(sin(session.actor.state.body_yaw),0,-cos(session.actor.state.body_yaw))
				var projected: Vector2 = session.rig.camera.unproject_position(session.actor.position+front)-session.rig.camera.unproject_position(session.actor.position)
				print(pair[2]," tick=",tick," screen_front=",projected," aim=",session.actor.state.aim_yaw)
				assert(root.get_texture().get_image().save_png("res://artifacts/turn-%s-%02d.png" % [pair[2],tick]) == OK)
		Input.action_release(pair[1])
		session.stop()
		screen.free()
		await process_frame
	print("TURN PATH CAPTURE: PASS")
	quit()
