extends SceneTree
## Pure adjudication + actual shared projectiles + fresh UI routing over ten games.

var failures: int = 0
var seen: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var cases := preload("res://tests/domain/match_cases.gd").new()
	for error: String in cases.run():
		check(false, error)
	await _test_combat_end(false)
	await _test_combat_end(true)
	await _test_pause_and_protection()
	await _test_routes()
	print("MATCH TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_combat_end(mutual: bool) -> void:
	seen.clear()
	var session := _session(1)
	var sim := session.simulation
	sim.events.published.connect(func(event: Dictionary) -> void: seen.append(event))
	sim.weapon = sim.weapon.duplicate() as WeaponDef
	sim.weapon.projectile_speed = 1200
	sim.rival_weapon = sim.weapon
	sim.rival.health.hp = 120
	if mutual:
		sim.actor.health.hp = 120
	await physics_frame
	await physics_frame
	check(sim.enqueue_command(_command(sim, 32768)), "live match player command accepted")
	if mutual:
		check(sim.enqueue_rival_command(_command(sim, 0)), "live match opponent command accepted")
	sim.step()
	var state := sim.match_runtime.snapshot()
	check(state.scores == ([1, 1] if mutual else [1, 0]), "actual swept attacks score entire tick batch")
	check(state.stats[1].kills == 1 and state.stats[1].damage == 120, "overkill clamped actual damage and kill stats")
	if mutual:
		check(state.phase == MatchRuntime.Phase.OVERTIME and session.enabled, "physical mutual kill enters overtime without freezing")
	else:
		check(session.phase == MovementSession.Phase.FINISHED and _count(&"match_finished") == 1, "winning hit ends session once")
		var tick := sim.tick
		session.resume()
		sim.set_paused(false)
		sim.step()
		check(sim.tick == tick and not sim.enqueue_command(_command(sim, 0)), "finished simulation cannot resume or accept input")
		check(not session.can_control and session.desktop.sample(2).fire_request_id == 0 and session.touch.sample(2).fire_request_id == 0, "finish clears both devices")
	session.free()
	await process_frame

func _test_pause_and_protection() -> void:
	var session := _session(20)
	var sim := session.simulation
	await physics_frame
	await physics_frame
	var deadline: int = sim.match_runtime.snapshot().remaining_seconds
	session.pause()
	for frame: int in range(5):
		sim.step()
		await physics_frame
	check(sim.tick == 0 and sim.match_runtime.snapshot().remaining_seconds == deadline, "pause freezes match timer")
	session.resume()
	check(sim.lives.tuning.protection_ticks == 90 and sim.lives.tuning.rebuild_ticks == 180, "match lifecycle uses frozen match rules")
	check(sim.targets.is_empty() and not sim.actor.health.is_training and not sim.rival.health.is_training, "timed match excludes training targets")
	check(not session.configure_match(MatchRules.new()).is_empty(), "live match rules cannot change")
	session.free()
	await process_frame

func _test_routes() -> void:
	var app := load("res://app/app_root.tscn").instantiate() as Node
	root.add_child(app)
	await process_frame
	var host := app.get_node("ScreenHost")
	host.get_child(0).hangar_requested.emit()
	await process_frame
	var hangar := host.get_child(0)
	hangar.weapon_picker.select(2)
	hangar.chassis_picker.select(2)
	hangar.weapon_picker.item_selected.emit(2)
	(hangar.find_child("TrainLoadout", true, false) as Button).pressed.emit()
	await process_frame
	var screen := host.get_child(0)
	screen.session.set_touch_mode(true)
	(screen.find_child("StartDuel", true, false) as Button).pressed.emit()
	await process_frame
	var ids: Dictionary = {}
	for game: int in range(10):
		screen = host.get_child(0)
		var session: MovementSession = screen.session
		session.set_physics_process(false)
		var sim := session.simulation
		var state := sim.match_runtime.snapshot()
		check(not ids.has(state.match_id), "rematch uses new match ID")
		ids[state.match_id] = true
		check(session.weapon.id == &"scatter" and session.chassis.id == &"heavy_tracks" and session.use_touch, "rematch retains loadout and device mode")
		check(state.scores == [0, 0] and sim.actor.health.hp == 700 and sim.projectiles.active.is_empty(), "new match clears score HP and projectiles")
		# Advance authoritative rules to time tie then overtime draw; combat tested separately above.
		sim.match_runtime.commit_tick(14400, [], sim.events)
		sim.match_runtime.commit_tick(16200, [], sim.events)
		check(session.phase == MovementSession.Phase.FINISHED and screen.find_child("MatchResult", true, false).visible, "real event shows result overlay")
		(screen.find_child("Rematch", true, false) as Button).pressed.emit()
		await process_frame
		check(host.get_child_count() == 1 and not is_instance_valid(session), "rematch frees old session and subscriptions")
	screen = host.get_child(0)
	var session: MovementSession = screen.session
	session.simulation.match_runtime.commit_tick(14400, [], session.simulation.events)
	session.simulation.match_runtime.commit_tick(16200, [], session.simulation.events)
	(screen.find_child("ExitMatch", true, false) as Button).pressed.emit()
	await process_frame
	check(host.get_child(0).session.weapon_index == 2 and host.get_child(0).session.chassis_index == 2, "result back restores originating hangar")
	app.free()
	await process_frame
	check(root.get_child_count() == 0, "all match navigation nodes disposed")

func _session(target: int) -> MovementSession:
	var session := MovementSession.new()
	var rules := preload("res://content/rules/offline_duel.tres").duplicate() as MatchRules
	rules.target_score = target
	check(session.configure_match(rules).is_empty(), "configure new duel")
	root.add_child(session)
	session.set_physics_process(false)
	return session

func _command(sim: BattleSimulation, yaw: int) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.sequence = 1
	command.client_tick = sim.tick + 1
	command.session_epoch = sim.session_epoch
	command.aim_yaw = yaw
	command.fire_request_id = 1
	return command

func _count(kind: StringName) -> int:
	var count: int = 0
	for event: Dictionary in seen:
		if event.kind == kind:
			count += 1
	return count

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
