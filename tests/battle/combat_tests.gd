extends SceneTree

var failures: int = 0
var fired: int = 0
var deaths: int = 0
var events_seen: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_requests()
	_test_damage()
	await _test_physics()
	_test_desktop()
	await _test_screen_input()
	print("COMBAT TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_requests() -> void:
	var gate := WeaponController.new()
	var command := PlayerCommand.new()
	command.fire_request_id = 1
	command.client_tick = 1
	check(gate.poll(command, 1, 48).has("request_id"), "first request fires")
	check(gate.poll(command, 49, 48).is_empty(), "same request cannot fire twice")
	command.fire_request_id = 2
	command.client_tick = 48
	check(gate.poll(command, 48, 48).is_empty(), "early request waits")
	check(gate.poll(command, 49, 48).has("request_id"), "near cooldown request buffered")
	command.fire_request_id = 3
	command.client_tick = 50
	gate.poll(command, 50, 48)
	check(gate.poll(command, 57, 48).get("rejected") == &"cooldown_expired", "expired request rejected")
	check(gate.poll(command, 100, 48).is_empty(), "expired request never fires late")
	command.fire_request_id = 4
	command.client_tick = 101
	gate.next_fire_tick = 103
	gate.poll(command, 101, 48)
	gate.cancel_pending()
	check(gate.poll(command, 103, 48).is_empty(), "cancel removes buffered attack")

func _test_damage() -> void:
	var resolver := DamageResolver.new()
	var target := DamageableState.new()
	target.entity_id = 100
	target.hp = 150
	var first := _hit(target, 1, 120)
	var second := _hit(target, 2, 120)
	var hits: Array[HitEvent] = [second, first, first]
	var results := resolver.resolve_batch(hits)
	check(results.size() == 2, "duplicate hurtbox hit deduplicated")
	check(results[0].actual_damage == 120 and results[1].actual_damage == 30, "overkill clamps to actual HP")
	check(target.hp == 0 and results[1].died, "same-tick death exactly once")
	check(resolver.resolve_batch([_hit(target, 3, 120)]).is_empty(), "corpse takes no damage")
	target.hp = 350
	target.protected = true
	check(resolver.resolve_batch([_hit(target, 4, 120)]).is_empty(), "protection prevents damage")
	target.protected = false
	target.team_id = 0
	check(resolver.resolve_batch([_hit(target, 5, 120)]).is_empty(), "friendly fire prevented")
	target.team_id = 1
	var stale := _hit(target, 6, 120)
	target.life_index += 1
	check(resolver.resolve_batch([stale]).is_empty(), "old life hit rejected")

func _test_physics() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := load("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	world.add_child(actor)
	var weapon := load("res://content/weapons/cannon.tres") as WeaponDef
	var chassis := load("res://content/chassis/light_tracks.tres") as ChassisDef
	actor.configure(LoadoutResolver.resolve(weapon, chassis), chassis.acceleration)
	var target := TrainingTarget.new()
	target.state.entity_id = 100
	target.position = Vector3(0, 0, -5)
	world.add_child(target)
	var simulation := BattleSimulation.new()
	world.add_child(simulation)
	simulation.actor = actor
	simulation.targets.append(target)
	simulation.events.published.connect(_on_event)
	await physics_frame
	await physics_frame
	for shot_index: int in range(3):
		var command := PlayerCommand.new()
		command.sequence = shot_index + 1
		command.fire_request_id = shot_index + 1
		command.client_tick = simulation.tick + 1
		check(simulation.enqueue_command(command), "shot command accepted")
		for frame: int in range(48):
			simulation.step()
			await physics_frame
	check(fired == 3 and deaths == 1, "three physical hits destroy 350 HP target once")
	check(target.state.hp == 0, "physical target damage applied")
	var damage_total: int = 0
	for event: Dictionary in events_seen:
		if event.kind == &"damage_applied":
			damage_total += event.actual_damage
	check(damage_total == 350, "training total excludes overkill")
	for frame: int in range(180):
		simulation.step()
		await physics_frame
	check(target.state.hp == 350 and target.state.life_index == 1, "target rebuilds with new life")
	var space := actor.get_world_3d().direct_space_state
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0, 0.78, -2)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4, 2, 0.05)
	collision.shape = shape
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	var fast := weapon.duplicate() as WeaponDef
	fast.projectile_speed = 1200
	var projectiles := ProjectileSystem.new()
	projectiles.spawn(space, Vector3.ZERO, 0, fast, 1, 50, 1)
	projectiles.step(space, 2)
	check(projectiles.active.is_empty() and projectiles.hits.is_empty(), "high-speed sweep cannot tunnel through thin wall")
	check(projectiles.impacts.size() == 1, "wall impact exactly once")
	var blocked := ProjectileSystem.new()
	blocked.spawn(space, Vector3(0, 0, -1.1), 0, weapon, 1, 51, 1)
	check(blocked.active.is_empty(), "muzzle beyond wall cannot bypass obstruction")
	var inside := ProjectileSystem.new()
	inside.spawn(space, Vector3(0, 0, -2), 0, weapon, 1, 52, 1)
	check(inside.active.is_empty(), "shot origin overlap stops inside wall")
	var expiry := ProjectileSystem.new()
	expiry.spawn(space, Vector3(5, 0, 0), 0, weapon, 1, 53, 1)
	for frame: int in range(50):
		expiry.step(space, frame + 2)
	check(expiry.active.is_empty(), "range/lifetime reclaims missed shot")
	wall.queue_free()
	await physics_frame
	await physics_frame
	var friendly := TrainingTarget.new()
	friendly.state.team_id = 0
	friendly.state.entity_id = 200
	friendly.position = Vector3(0, 0, -2)
	world.add_child(friendly)
	await physics_frame
	await physics_frame
	var through_friendly := ProjectileSystem.new()
	through_friendly.spawn(space, Vector3.ZERO, 0, fast, 1, 54, 1)
	through_friendly.step(space, 2)
	check(through_friendly.hits.size() == 1 and through_friendly.hits[0].target.entity_id == 100, "friendly hurtbox ignored and enemy behind still hit")
	var ready := simulation.weapon_controller.next_fire_tick
	var epoch := simulation.replace_controller()
	var fresh := PlayerCommand.new()
	fresh.session_epoch = epoch
	fresh.sequence = 1
	fresh.client_tick = simulation.tick + 1
	check(simulation.enqueue_command(fresh), "new controller low sequence accepted in new epoch")
	check(simulation.weapon_controller.next_fire_tick == ready, "handoff preserves cooldown")
	world.free()

func _test_desktop() -> void:
	var source := DesktopInputSource.new()
	var event := InputEventAction.new()
	event.action = "fire"
	event.pressed = true
	source.handle_event(event)
	event.pressed = false
	source.handle_event(event)
	check(source.sample(1).fire_request_id == 1, "desktop release fires once")
	check(source.sample(2).fire_request_id == 0, "desktop request consumed")
	event.pressed = true
	source.handle_event(event)
	source.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	source.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	event.pressed = false
	source.handle_event(event)
	check(source.sample(3).fire_request_id == 0, "focus cancellation never fires on stale release")
	source.free()

func _hit(target: DamageableState, projectile: int, amount: int) -> HitEvent:
	var hit := HitEvent.new()
	hit.target = target
	hit.target_life = target.life_index
	hit.projectile_id = projectile
	hit.damage = amount
	hit.source_id = 1
	hit.team_id = 0
	return hit

func _on_event(event: Dictionary) -> void:
	events_seen.append(event)
	if event.kind == &"weapon_fired":
		fired += 1
	if event.kind == &"entity_died":
		deaths += 1

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func _test_screen_input() -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	await physics_frame
	var count_before: int = fired
	screen.session.simulation.events.published.connect(_on_event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	mouse.position = Vector2(640, 360)
	mouse.global_position = mouse.position
	mouse.pressed = true
	Input.parse_input_event(mouse)
	await process_frame
	mouse = mouse.duplicate() as InputEventMouseButton
	mouse.pressed = false
	Input.parse_input_event(mouse)
	for frame: int in range(5):
		await physics_frame
	check(fired == count_before + 1, "real viewport mouse release reaches weapon through UI")
	screen.session.set_touch_mode(true)
	var right := Vector2(screen.size.x - 110, screen.size.y - 110)
	screen.session.touch.state.press(0, right)
	screen.session.touch.state.release(0, right)
	for frame: int in range(7):
		await physics_frame
	# A premature switch/release must retain existing cooldown and expire, not fire twice.
	check(fired == count_before + 1, "device switch cannot bypass cooldown")
	screen.session.stop()
	root.remove_child(screen)
	screen.free()
