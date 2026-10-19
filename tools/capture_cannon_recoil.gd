extends SceneTree
## Real training fire, fixed-tick screenshots: no synthetic weapon callbacks.

func _initialize() -> void:
	call_deferred("_capture")

func _save(name: String) -> void:
	for frame: int in range(3): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/recoil-" + name + ".png") == OK)

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	var session: MovementSession = screen.session
	session.set_physics_process(false)
	for frame: int in range(8): await physics_frame
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	session.set_physics_process(false)
	await _save("training-rest")
	# Inspection close-up only. Gameplay camera tuning remains unchanged.
	session.rig.position = Vector3.ZERO
	session.rig.camera.size = 4.0
	var sim := session.simulation
	var neutral := PlayerCommand.new()
	neutral.session_epoch = sim.session_epoch
	neutral.sequence = 1
	neutral.client_tick = sim.tick + 1
	neutral.aim_yaw = 32768
	assert(sim.enqueue_command(neutral))
	sim.step()
	await _save("close-rest")
	var command := PlayerCommand.new()
	command.session_epoch = sim.session_epoch
	command.sequence = 2
	command.client_tick = sim.tick + 1
	command.fire_request_id = 1
	command.aim_yaw = 32768
	assert(sim.enqueue_command(command))
	sim.step()
	sim.step()
	await _save("close-peak")
	session.pause()
	var pivot := session._view.find_child("RecoilPivot", true, false) as Node3D
	var pose := pivot.position
	for frame: int in range(6): await physics_frame
	assert(pivot.position == pose)
	session.resume()
	session.set_physics_process(false)
	for frame: int in range(18): sim.step()
	await _save("close-returned")
	assert(pivot.position.is_zero_approx())
	screen.free()
	await process_frame
	print("CANNON RECOIL CAPTURE: PASS")
	quit()
