extends SceneTree
## Real training session with development-only candidate visuals.



func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.title = "坦克训练场 · Blender 正式主炮与四轮底盘"
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	assert(screen.session.configure_loadout(&"cannon",&"light_tracks").is_empty())
	root.add_child(screen)
	screen.back_requested.connect(quit)
	var session: MovementSession = screen.session
	
	session.set_physics_process(false)
	for i: int in range(12): await physics_frame
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	var view := session._view
	var before: Transform3D = view._muzzle.transform
	var wheel := view._hull.find_child("Wheel*",true,false) as Node3D
	var initial := wheel.transform
	var saw_recoil := false
	var saw_wheel_motion := false
	for tick: int in range(1,81):
		if session.phase == MovementSession.Phase.PAUSED: session.resume()
		var command := PlayerCommand.new()
		command.sequence = session.simulation.tick+1
		command.client_tick = command.sequence
		command.session_epoch = session.simulation.session_epoch
		command.fire_held = tick == 1
		command.fire_request_id = 1 if tick == 1 else 0
		command.move_x = 127 if tick >= 20 and tick <= 50 else 0
		session.simulation.enqueue_command(command)
		session.simulation.step()
		for i: int in range(2): await process_frame
		saw_recoil = saw_recoil or (view._turret.find_child("RecoilPivot",true,false) as Node3D).position.length()>0.001
		saw_wheel_motion = saw_wheel_motion or not wheel.transform.is_equal_approx(initial)
		screen.pause_overlay.dismiss()
		await RenderingServer.frame_post_draw
		if tick in [1,3,30,60,80]:
			root.get_texture().get_image().save_png("res://artifacts/133-training-%02d.png" % tick)
	assert(saw_recoil,"Committed shot must animate the cannon")
	assert(saw_wheel_motion,"Travel must animate a complete wheel")
	assert(view._muzzle.transform.is_equal_approx(before),"Authority muzzle must not recoil")
	session.stop()
	screen.free()
	await process_frame
	print("MECHANICAL TRAINING: PASS movement, recoil, immutable muzzle")
	quit()
