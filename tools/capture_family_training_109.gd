extends SceneTree
## Real sessions using the production catalog, successful fire and committed movement.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	root.size = Vector2i(1280,720)
	for pair: Array in [[&"autocannon",&"light_tracks"],[&"scatter",&"heavy_tracks"],[&"bubble_cannon",&"heavy_tracks"]]:
		await _capture(pair[0],pair[1])
	print("MECHANICAL FAMILY TRAINING: PASS")
	quit()
func _capture(weapon: StringName, chassis: StringName) -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	assert(screen.session.configure_loadout(weapon,chassis).is_empty())
	root.add_child(screen)
	var session: MovementSession = screen.session
	session.set_physics_process(false)
	for i: int in range(8): await physics_frame
	var view := session._view
	var pivot := view._turret.find_child("RecoilPivot",true,false) as Node3D
	var rig := view._hull.find_child("TrackRig",true,false) as TrackRig
	var wheel := rig._wheels[0]
	var rest := pivot.position
	var wheel_rest := wheel.transform
	var authority := view._muzzle.transform
	var saw_recoil := false
	var saw_wheel := false
	for tick: int in range(1,81):
		if session.phase == MovementSession.Phase.PAUSED: session.resume()
		var command := PlayerCommand.new()
		command.sequence = session.simulation.tick+1
		command.client_tick = command.sequence
		command.session_epoch = session.simulation.session_epoch
		command.fire_request_id = 1 if tick == 1 else 0
		command.fire_held = tick <= 16
		command.move_x = 127 if tick >= 20 and tick <= 60 else 0
		session.simulation.enqueue_command(command)
		session.simulation.step()
		saw_recoil = saw_recoil or not pivot.position.is_equal_approx(rest)
		saw_wheel = saw_wheel or not wheel.transform.is_equal_approx(wheel_rest)
		for i: int in range(2): await process_frame
		screen.pause_overlay.dismiss()
		await RenderingServer.frame_post_draw
		if tick in [1,3,10,30,60,80]:
			assert(root.get_texture().get_image().save_png("res://artifacts/109-%s-training-%02d.png" % [weapon,tick])==OK)
	assert(saw_recoil,"Successful fire animates "+str(weapon))
	assert(saw_wheel,"Committed travel animates "+str(chassis))
	assert(view._muzzle.transform.is_equal_approx(authority))
	session.pause(&"capture_test")
	var paused_tick: int = session.simulation.tick
	var paused_wheel := wheel.transform
	for i: int in range(3): await physics_frame
	assert(session.simulation.tick==paused_tick and wheel.transform.is_equal_approx(paused_wheel))
	view.reset_visual_motion()
	assert(pivot.position.is_equal_approx(rest))
	session.stop()
	screen.free()
	await process_frame
