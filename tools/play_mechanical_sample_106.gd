extends SceneTree
## Real training session with development-only candidate visuals.

const SAMPLE = preload("res://presentation/previews/mechanical_sample_mount.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280,720)
	root.title = "坦克训练场 · Blender 主炮与四轮底盘样板"
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	assert(screen.session.configure_loadout(&"cannon",&"scout_wheels").is_empty())
	root.add_child(screen)
	screen.back_requested.connect(quit)
	var session: MovementSession = screen.session
	SAMPLE.install(session._view)
	# Legacy arena shadow maps show stripes in Compatibility. Keep sample lighting clean.
	for node: Node in session.find_children("*", "DirectionalLight3D",true,false):
		(node as DirectionalLight3D).shadow_enabled = false
		(node as DirectionalLight3D).light_energy *= 1.25
	if "--capture" not in OS.get_cmdline_user_args(): return
	session.set_physics_process(false)
	for i: int in range(12): await physics_frame
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	var view := session._view
	var before: Transform3D = view._muzzle.transform
	var wheel := view._hull.find_child("WheelLeftFront",true,false) as Node3D
	var initial := wheel.transform
	var saw_recoil := false
	for tick: int in range(1,81):
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
		screen.pause_overlay.dismiss()
		await RenderingServer.frame_post_draw
		if tick in [1,3,30,60,80]:
			root.get_texture().get_image().save_png("res://artifacts/106-training-%02d.png" % tick)
	assert(saw_recoil,"Committed shot must animate the cannon")
	assert(not wheel.transform.is_equal_approx(initial),"Travel must animate a complete wheel")
	assert(view._muzzle.transform.is_equal_approx(before),"Authority muzzle must not recoil")
	session.stop()
	screen.free()
	await process_frame
	print("MECHANICAL TRAINING: PASS movement, recoil, immutable muzzle")
	quit()
