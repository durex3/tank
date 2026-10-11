extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for action: String in ["move_left", "move_right", "move_up", "move_down"]:
		var keys: Dictionary = {"move_left": KEY_LEFT, "move_right": KEY_RIGHT, "move_up": KEY_UP, "move_down": KEY_DOWN}
		var event := InputEventKey.new()
		event.physical_keycode = keys[action]
		check(InputMap.action_has_event(action, event), "arrow binding: " + action)
	var arena := Node3D.new()
	arena.set_script(load("res://session/graybox_arena.gd"))
	root.add_child(arena)
	var actor := load("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	root.add_child(actor)
	var chassis := load("res://content/chassis/light_tracks.tres") as ChassisDef
	actor.configure(LoadoutResolver.resolve(load("res://content/weapons/cannon.tres"), chassis), chassis.acceleration)
	var simulation := BattleSimulation.new()
	root.add_child(simulation)
	simulation.actor = actor
	await physics_frame
	await physics_frame
	var command := PlayerCommand.new()
	command.move_x = 127
	for index: int in range(240):
		command = PlayerCommand.new()
		command.sequence = index + 1
		command.client_tick = simulation.tick + 1
		command.move_x = 127
		check(simulation.enqueue_command(command), "valid movement accepted")
		simulation.step()
		check(actor.velocity.length() <= 6.001, "speed capped")
		check(absf(actor.position.y) < 0.001, "XZ ground plane maintained")
		await physics_frame
	check(actor.position.x > 14.8 and actor.position.x < 15.2, "boundary stops tank without crossing wall")
	check(not simulation.enqueue_command(command), "duplicate sequence rejected")
	command = PlayerCommand.new()
	command.sequence = 999
	command.session_epoch = 1
	check(not simulation.enqueue_command(command), "old/wrong epoch rejected")
	command.session_epoch = 0
	command.client_tick = simulation.tick + 10
	check(not simulation.enqueue_command(command), "future command rejected")
	for index: int in range(30):
		simulation.step()
		await physics_frame
	check(actor.velocity.length() < 0.001, "input timeout stops movement")
	actor.position = Vector3(6, 0, 0)
	actor.velocity = Vector3.ZERO
	for index: int in range(90):
		command = PlayerCommand.new()
		command.sequence = 1000 + index
		command.client_tick = simulation.tick + 1
		command.move_z = 127
		command.aim_yaw = 16384
		simulation.enqueue_command(command)
		simulation.step()
		if index == 0:
			check(actor.velocity.length() > 0 and actor.velocity.length() < 1, "acceleration ramps up")
		await physics_frame
	check(actor.position.z > 2.3 and actor.position.z < 2.5, "internal cover blocks movement")
	check(is_equal_approx(actor.state.aim_yaw, PI * 0.5), "turret aim remains independent of +Z hull travel")
	var mapped := PlanarInput.to_world(Vector2(1, 0), Vector3(0, 0, 1), Vector3(1, 0, 0))
	check(mapped.is_equal_approx(Vector2(0, 1)), "camera rotation maps right to +Z")
	check(is_equal_approx(PlanarInput.to_world(Vector2(1, -1).normalized(), Vector3.RIGHT, Vector3.FORWARD).length(), 1.0), "camera mapping preserves diagonal speed")
	actor.free()
	simulation.free()
	arena.free()
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	await physics_frame
	check(screen.session.actor != null, "full movement screen initializes")
	screen.session.set_touch_mode(true)
	var origin := Vector2(110, screen.size.y - 110)
	screen.session.touch.state.press(0, origin)
	screen.session.touch.state.drag(0, origin + Vector2(64, 0))
	for index: int in range(12):
		await physics_frame
	check(screen.session.actor.position.x > 0.1, "touch command drives actual actor")
	screen.session.touch.cancel_pending()
	for index: int in range(24):
		await physics_frame
	check(screen.session.actor.velocity.length() < 0.001, "touch cancellation stops actual actor")
	screen.session.stop()
	check(not screen.session.enabled, "exit stops session")
	root.remove_child(screen)
	screen.free()
	print("MOVEMENT TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
