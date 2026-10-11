extends SceneTree
## Multi-projectile physics and session integration; no synthetic damage callbacks.

var failures: int = 0
var seen: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_gate_and_input()
	await _test_volley()
	await _test_spread_obstruction()
	await _test_continuous_simulation()
	await _test_live_inputs()
	await _test_budget_event()
	await _test_loadout_route()
	print("WEAPON VARIANTS TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_gate_and_input() -> void:
	var gate := WeaponController.new()
	var command := PlayerCommand.new()
	command.fire_held = true
	var count: int = 0
	for tick: int in range(1, 61):
		if gate.poll(command, tick, 10, true).has("request_id"):
			count += 1
	check(count == 6, "held fire respects 10-tick autocannon cadence")
	command.fire_held = false
	check(gate.poll(command, 61, 10, true).is_empty(), "release never adds a shot")
	var source := DesktopInputSource.new()
	source.continuous_fire = true
	var press := InputEventAction.new()
	press.action = "fire"
	press.pressed = true
	source.handle_event(press)
	check(source.sample(1).fire_held, "desktop held command active")
	source.set_enabled(false)
	source.set_enabled(true)
	check(not source.sample(2).fire_held, "resume requires fresh press")
	press.pressed = false
	source.handle_event(press)
	check(source.sample(3).fire_request_id == 0, "old release never fires autocannon")
	source.free()
	var scatter := LoadoutCatalog.weapon(&"scatter")
	var offsets := WeaponPatterns.create(&"scatter").offsets(scatter)
	check(offsets.size() == 5 and absf(offsets[2]) < 0.0001, "scatter has five pellets and center shot")
	check(is_equal_approx(offsets[0], -offsets[4]) and is_equal_approx(offsets[4], deg_to_rad(12.0)), "scatter spans symmetric 24 degree fan")

func _test_volley() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := TrainingTarget.new()
	target.position = Vector3(0, 0, -3)
	world.add_child(target)
	await physics_frame
	await physics_frame
	var space := target.get_world_3d().direct_space_state
	var weapon := LoadoutCatalog.weapon(&"scatter")
	var offsets := WeaponPatterns.create(weapon.id).offsets(weapon)
	var projectiles := ProjectileSystem.new()
	var shots := projectiles.spawn_volley(space, Vector3.ZERO, 0, offsets, weapon, 1, 1, 1)
	check(shots.size() == 5, "scatter atomically creates five unique projectiles")
	for shot: ProjectileState in shots:
		check(shot.position.is_equal_approx(Vector3(0, 0.78, -1.05)), "all pellets leave the same muzzle")
	for tick: int in range(2, 12):
		projectiles.step(space, tick)
	check(projectiles.hits.size() == 5, "nearby target receives five physical pellet hits")
	var resolver := DamageResolver.new()
	resolver.resolve_batch(projectiles.hits)
	check(target.state.hp == 190, "five pellets apply 160 total damage")
	projectiles = ProjectileSystem.new()
	for index: int in range(124):
		projectiles.spawn(space, Vector3(10, 0, 0), 0, weapon, 1, index, 1)
	check(projectiles.spawn_volley(space, Vector3.ZERO, 0, offsets, weapon, 1, 2, 1).is_empty(), "four free slots reject complete five-pellet volley")
	check(projectiles.active.size() == 124 and projectiles.hits.is_empty(), "budget rejection creates no partial shots or damage")
	projectiles.active.pop_back()
	check(projectiles.spawn_volley(space, Vector3.ZERO, 0, offsets, weapon, 1, 3, 1).size() == 5, "exactly five free slots accept volley")
	check(projectiles.active.size() == 128, "volley never exceeds global cap")
	world.free()

func _test_spread_obstruction() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := TrainingTarget.new()
	target.position = Vector3(0, 0, -3)
	target.state.hp = 100
	world.add_child(target)
	await physics_frame
	await physics_frame
	var weapon := LoadoutCatalog.weapon(&"scatter").duplicate() as WeaponDef
	weapon.projectile_speed = 1200.0
	var space := target.get_world_3d().direct_space_state
	var offsets := WeaponPatterns.create(weapon.id).offsets(weapon)
	var projectiles := ProjectileSystem.new()
	projectiles.spawn_volley(space, Vector3.ZERO, 0, offsets, weapon, 1, 1, 1)
	projectiles.step(space, 2)
	var resolver := DamageResolver.new()
	var results := resolver.resolve_batch(projectiles.hits)
	var total: int = 0
	var deaths: int = 0
	for result: Dictionary in results:
		total += result.actual_damage
		if result.died:
			deaths += 1
	check(total == 100 and deaths == 1, "same-tick scatter clamps overkill and emits one death")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0, 0.78, -0.5)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2, 2, 0.05)
	collision.shape = box
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	projectiles = ProjectileSystem.new()
	projectiles.spawn_volley(space, Vector3.ZERO, 0, offsets, weapon, 1, 2, 1)
	check(projectiles.active.is_empty() and projectiles.impacts.size() == 5 and projectiles.hits.is_empty(), "every pellet is blocked on shared center-to-muzzle path")
	world.free()
	await process_frame

func _test_continuous_simulation() -> void:
	var session := MovementSession.new()
	check(session.configure_loadout(&"autocannon", &"scout_wheels").is_empty(), "configure autocannon before start")
	root.add_child(session)
	session.set_physics_process(false)
	await physics_frame
	await physics_frame
	session.simulation.events.published.connect(func(event: Dictionary) -> void: seen.append(event))
	for index: int in range(60):
		var command := PlayerCommand.new()
		command.sequence = index + 1
		command.client_tick = session.simulation.tick + 1
		command.fire_held = true
		session.simulation.enqueue_command(command)
		session.simulation.step()
	check(_fired_count() == 6, "simulation publishes one fact per autocannon attack")
	check(session.actor.stats.max_hp == 400 and session.actor.stats.move_speed == 7.2, "training uses selected chassis stats")
	check(not session.configure_loadout(&"scatter", &"heavy_tracks").is_empty(), "live loadout replacement rejected")
	var before := _fired_count()
	session.pause()
	session.resume()
	for index: int in range(15):
		session.simulation.step()
	check(_fired_count() == before, "pause removes held command and preserves cooldown")
	var command := PlayerCommand.new()
	command.session_epoch = session.simulation.session_epoch
	command.sequence = 1
	command.client_tick = session.simulation.tick + 1
	command.fire_held = true
	session.simulation.enqueue_command(command)
	for index: int in range(30):
		session.simulation.step()
	check(_fired_count() == before + 1, "input timeout stops unattended continuous fire")
	session.free()
	await process_frame

func _test_live_inputs() -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	screen.session.configure_loadout(&"autocannon", &"scout_wheels")
	root.add_child(screen)
	await process_frame
	await physics_frame
	var session: MovementSession = screen.session
	session.simulation.events.published.connect(func(event: Dictionary) -> void: seen.append(event))
	var button := Button.new()
	button.position = Vector2(500, 440)
	button.size = Vector2(200, 60)
	screen.add_child(button)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = root.get_final_transform() * Vector2(650, 350)
	mouse.global_position = mouse.position
	mouse.pressed = true
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	var before := _fired_count()
	for index: int in range(25):
		await physics_frame
	check(_fired_count() >= before + 2, "real mouse hold fires through training input chain")
	mouse = mouse.duplicate() as InputEventMouseButton
	mouse.position = root.get_final_transform() * Vector2(600, 470)
	mouse.global_position = mouse.position
	mouse.pressed = false
	Input.parse_input_event(mouse)
	Input.flush_buffered_events()
	before = _fired_count()
	for index: int in range(20):
		await physics_frame
	check(_fired_count() == before, "GUI-consumed release still stops continuous fire")
	session.set_touch_mode(true)
	var left := Vector2(110, screen.size.y - 110)
	var right := Vector2(screen.size.x - 110, screen.size.y - 110)
	session.touch.state.press(0, left)
	session.touch.state.drag(0, left + Vector2(64, 0))
	session.touch.state.press(1, right)
	session.touch.state.drag(1, right + Vector2(64, 0))
	before = _fired_count()
	for index: int in range(25):
		await physics_frame
	check(_fired_count() >= before + 2 and session.actor.position.x > 0.1, "two captured contacts move and fire concurrently")
	session.touch.cancel_pending()
	before = _fired_count()
	for index: int in range(24):
		await physics_frame
	check(_fired_count() == before and session.actor.velocity.is_zero_approx(), "touch cancellation stops movement and held weapon")
	screen.free()
	await process_frame

func _test_budget_event() -> void:
	var session := MovementSession.new()
	session.configure_loadout(&"scatter", &"heavy_tracks")
	root.add_child(session)
	session.set_physics_process(false)
	await physics_frame
	await physics_frame
	var sim := session.simulation
	sim.events.published.connect(func(event: Dictionary) -> void: seen.append(event))
	var space := session.actor.get_world_3d().direct_space_state
	for index: int in range(124):
		sim.projectiles.spawn(space, Vector3(10, 0, 0), 0, sim.weapon, 1, index, 1)
	var command := PlayerCommand.new()
	command.sequence = 1
	command.client_tick = 1
	command.fire_request_id = 1
	sim.enqueue_command(command)
	var before := _fired_count()
	sim.step()
	check(_fired_count() == before, "budget rejection publishes no muzzle fact")
	check(sim.weapon_controller.next_fire_tick == 61, "rejected volley still consumes cooldown")
	var rejected: bool = false
	for event: Dictionary in seen:
		if event.kind == &"fire_rejected" and event.reason == &"projectile_budget":
			rejected = true
	check(rejected, "budget rejection gives explicit event reason")
	session.free()
	await process_frame

func _test_loadout_route() -> void:
	var app := load("res://app/app_root.tscn").instantiate() as Node
	root.add_child(app)
	await process_frame
	var host := app.get_node("ScreenHost")
	host.get_child(0).hangar_requested.emit()
	await process_frame
	for weapon: int in range(3):
		for chassis: int in range(3):
			var hangar := host.get_child(0)
			hangar.weapon_picker.select(weapon)
			hangar.chassis_picker.select(chassis)
			hangar.weapon_picker.item_selected.emit(weapon)
			var train := hangar.find_child("TrainLoadout", true, false) as Button
			train.pressed.emit()
			await process_frame
			var session: MovementSession = host.get_child(0).session
			check(session.weapon.id == LoadoutCatalog.WEAPONS[weapon].id and session.chassis.id == LoadoutCatalog.CHASSIS[chassis].id, "hangar routes selected IDs into training")
			check(session.touch.state.continuous_fire == session.weapon.continuous_fire and session.desktop.continuous_fire == session.weapon.continuous_fire, "both input sources match weapon mode")
			var view: TankView
			for child: Node in session.actor.get_children():
				if child is TankView:
					view = child as TankView
			check(view != null and view.weapon_id == session.weapon.id and view.chassis_id == session.chassis.id, "training visuals match actual loadout")
			host.get_child(0).back_requested.emit()
			await process_frame
			check(host.get_child_count() == 1 and host.get_child(0).session.weapon_index == weapon and host.get_child(0).session.chassis_index == chassis, "back restores selected loadout without duplicate screens")
	app.free()
	await process_frame
	check(root.get_child_count() == 0, "navigation disposes old simulations")

func _fired_count() -> int:
	var result: int = 0
	for event: Dictionary in seen:
		if event.kind == &"weapon_fired":
			result += 1
	return result

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
