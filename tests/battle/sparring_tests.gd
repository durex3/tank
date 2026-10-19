extends SceneTree
## Real physics: blocked sight, hostile hits, rebuild leases, and mutual kill.

var failures: int = 0
var seen: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_intents()
	await _test_sparring()
	await _test_mutual_kill()
	await _test_safe_respawn()
	print("SPARRING TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_intents() -> void:
	var brain := TrainingBotInput.new()
	brain.reset(0)
	var hidden := brain.sample(60, Vector3(0, 0, 7), Vector3.ZERO, true, true, false, 14)
	check(hidden.fire_request_id == 0 and brain.mode == TrainingBotInput.Mode.PATROL, "occluded target yields patrol only")
	check(brain.sample(61, Vector3(0, 0, 7), Vector3.ZERO, true, true, true, 14).fire_request_id > 0, "visible in-range target yields attack")
	check(brain.sample(121, Vector3(0, 0, 7), Vector3.ZERO, true, false, true, 14).fire_request_id == 0, "dead target never attacked")
	check(brain.sample(122, Vector3(0, 0, 7), Vector3.ZERO, true, true, true, 2).fire_request_id == 0, "out-of-range target never attacked")
	var dead := brain.sample(123, Vector3.ZERO, Vector3.ONE, false, true, true, 14)
	check(dead.move_x == 0 and dead.move_z == 0 and dead.fire_request_id == 0, "dead bot has neutral intent")
	var invalid := brain.sample(124, Vector3(NAN, 0, 0), Vector3.ZERO, true, true, true, 14)
	check(invalid.move_x == 0 and invalid.fire_request_id == 0, "nonfinite observations produce neutral intent")
	var rules := SparringRules.new()
	check(rules.validate().is_empty(), "default sparring rules valid")
	rules.protection_ticks = 0
	check(not rules.validate().is_empty(), "invalid lifecycle rules rejected")

func _test_sparring() -> void:
	var session := MovementSession.new()
	root.add_child(session)
	session.set_physics_process(false)
	check(session.sparring == null, "normal training has no hostile bot")
	check(session.start_sparring().is_empty(), "explicit sparring starts")
	check(not session.start_sparring().is_empty(), "duplicate start rejected")
	var sim := session.simulation
	sim.events.published.connect(_remember)
	var wall := _wall(Vector3(0, 0.8, 3), Vector3(8, 2, 0.1))
	session.add_child(wall)
	await physics_frame
	await physics_frame
	for frame: int in range(120):
		session.sparring.sample_next_tick()
		sim.step()
		await physics_frame
	check(session.actor.health.hp == 500 and _count(&"weapon_fired", 2) == 0, "real occluder prevents bot firing")
	check(absf(session.sparring.rival.position.x) > 0.1, "bot patrol moves through actual motor")
	wall.queue_free()
	await physics_frame
	await physics_frame
	for frame: int in range(90):
		session.sparring.sample_next_tick()
		sim.step()
		await physics_frame
	check(session.actor.health.hp < 500 and session.actor.health.hp > 0, "hostile swept projectiles damage actual player")
	check(session.sparring.rival.health.hp == 500, "bot ignores its own hurtbox")
	var attempts: int = 0
	while session.actor.health.hp > 0 and attempts < 360:
		session.sparring.sample_next_tick()
		sim.step()
		await physics_frame
		attempts += 1
	check(session.actor.health.hp == 0 and _count(&"entity_died", 1) == 1, "bot destroys player once")
	check(not session.can_control and session.actor.collision_layer == 0, "death disables controls and corpse body")
	var stale_epoch := sim.session_epoch
	var command := PlayerCommand.new()
	command.session_epoch = stale_epoch
	command.sequence = 999
	command.client_tick = sim.tick + 1
	command.move_x = 127
	command.fire_request_id = 99
	check(not sim.enqueue_command(command), "dead player command rejected")
	var old_position := session.actor.position
	session.actor.step(command, 1.0 / 60)
	check(session.actor.position == old_position and session.actor.velocity.is_zero_approx(), "dead actor cannot move directly")
	var paused_tick := sim.tick
	var rival_position := session.sparring.rival.position
	session.pause()
	for frame: int in range(10):
		sim.step()
		await physics_frame
	check(sim.tick == paused_tick and session.sparring.rival.position == rival_position, "pause freezes opponent and rebuild timer")
	session.resume()
	attempts = 0
	while session.actor.health.hp == 0 and attempts < 200:
		session.sparring.sample_next_tick()
		sim.step()
		await physics_frame
		attempts += 1
	check(session.actor.health.hp == 500 and session.actor.health.life_index == 1, "player rebuilds into fresh life")
	check(session.actor.health.protected and session.can_control, "rebuild grants shield and fresh controls")
	command.client_tick = sim.tick + 1
	check(not sim.enqueue_command(command), "old life controller lease rejected after rebuild")
	var ready_count := _count(&"weapon_fired", 1)
	command = PlayerCommand.new()
	command.session_epoch = sim.session_epoch
	command.sequence = 1
	command.client_tick = sim.tick + 1
	command.fire_request_id = 1
	sim.enqueue_command(command)
	var fast := sim.rival_weapon.duplicate() as WeaponDef
	fast.projectile_speed = 1200
	sim.projectiles.spawn(session.actor.get_world_3d().direct_space_state, Vector3(0, 0, 3), 0, fast, 2, 999, sim.tick, NAN, 1)
	sim.step()
	check(session.actor.health.hp == 500 and _count(&"weapon_fired", 1) == ready_count, "shield blocks damage and outgoing attacks")
	for frame: int in range(60):
		session.sparring.sample_next_tick()
		sim.step()
		await physics_frame
	check(not session.actor.health.protected, "shield expires on simulation ticks")
	session.stop()
	var before := sim.tick
	sim.step()
	check(sim.tick == before, "exit freezes both controllers")
	session.free()
	await process_frame
	check(root.get_child_count() == 0, "sparring exit releases opponent and player")

func _test_mutual_kill() -> void:
	seen.clear()
	var player := _actor(1, Vector3.ZERO, 0)
	var rival := _actor(2, Vector3(0, 0, -3), 1)
	var sim := BattleSimulation.new()
	root.add_child(sim)
	sim.actor = player
	sim.rival = rival
	sim.weapon = sim.weapon.duplicate() as WeaponDef
	sim.weapon.projectile_speed = 1200
	sim.rival_weapon = sim.weapon
	sim.lives.track(player, Vector3.ZERO)
	sim.lives.track(rival, Vector3(0, 0, -3))
	player.health.hp = 120
	rival.health.hp = 120
	sim.events.published.connect(_remember)
	await physics_frame
	await physics_frame
	var command := PlayerCommand.new()
	command.sequence = 1
	command.client_tick = 1
	command.fire_request_id = 1
	sim.enqueue_command(command)
	command = PlayerCommand.new()
	command.sequence = 1
	command.client_tick = 1
	command.fire_request_id = 1
	command.aim_yaw = 32768
	sim.enqueue_rival_command(command)
	sim.step()
	check(player.health.hp == 0 and rival.health.hp == 0, "both attacks resolve before same-tick mutual death")
	check(_count(&"entity_died", 1) == 1 and _count(&"entity_died", 2) == 1, "mutual kill emits one death per entity")
	check(rival.health.respawn_tick == 181, "rival uses same rebuild policy")
	sim.free()
	player.free()
	rival.free()
	await process_frame

func _test_safe_respawn() -> void:
	var player := _actor(1, Vector3.ZERO, 0)
	var lives := TrainingLives.new()
	lives.track(player, Vector3.ZERO)
	player.health.hp = 0
	lives.died(1, 0)
	var wall := _wall(Vector3(0, 0.8, 0), Vector3(8, 2, 2))
	root.add_child(wall)
	await physics_frame
	await physics_frame
	lives.step(180, BattleEvents.new())
	check(player.health.hp == 0 and player.health.life_index == 0, "occupied rebuild candidates defer without overlap")
	wall.queue_free()
	await physics_frame
	await physics_frame
	lives.step(181, BattleEvents.new())
	check(player.health.hp == 500 and player.health.life_index == 1, "clear safe point permits rebuild")
	player.free()
	await process_frame

func _actor(id: int, point: Vector3, team: int) -> TankActor:
	var actor := load("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	actor.state.entity_id = id
	actor.position = point
	root.add_child(actor)
	actor.configure(LoadoutResolver.resolve(LoadoutCatalog.WEAPONS[0], LoadoutCatalog.CHASSIS[0]), 20)
	actor.health.team_id = team
	return actor

func _wall(point: Vector3, size: Vector3) -> StaticBody3D:
	var wall := StaticBody3D.new()
	wall.position = point
	wall.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	wall.add_child(collision)
	return wall

func _remember(event: Dictionary) -> void:
	seen.append(event)

func _count(kind: StringName, id: int) -> int:
	var count: int = 0
	for event: Dictionary in seen:
		if event.kind == kind and event.get("source_id" if kind == &"weapon_fired" else "target_id", -1) == id:
			count += 1
	return count

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
