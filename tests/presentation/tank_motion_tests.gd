extends SceneTree
## Committed fire -> independent barrel; pause/lifecycle never alter combat muzzle.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_independent_barrel()
	await _test_session()
	print("TANK MOTION TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _pivot(view: TankView) -> Node3D:
	return view.find_child("RecoilPivot", true, false) as Node3D

func _fire(view: TankView, tick: int, source: int = 1) -> void:
	view.on_event({"kind": &"weapon_fired", "weapon": &"cannon", "source_id": source, "tick": tick})

func _test_independent_barrel() -> void:
	var first := TankView.new()
	first.entity_id = 1
	var second := TankView.new()
	second.entity_id = 2
	root.add_child(first)
	root.add_child(second)
	var pivot := _pivot(first)
	check(pivot != null, "original cannon has separated barrel")
	if pivot == null:
		first.free()
		second.free()
		return
	var barrel := pivot.get_child(0) as MeshInstance3D
	var body := first.find_child("Body", true, false) as MeshInstance3D
	var body_before := body.transform
	var before := barrel.global_position
	var muzzle := first.muzzle_transform()
	first.on_event({"kind": &"fire_rejected", "source_id": 1, "tick": 1})
	_fire(first, 1, 2)
	check(pivot.position.is_zero_approx(), "rejected and other-entity fire have no effect")
	_fire(first, 2)
	first.advance_visual_tick(3)
	check(barrel.global_position.distance_to(before + Vector3.BACK * TankRecoil.STYLE.cannon_recoil_m) < 0.0001, "barrel retracts by world-space cosmetic distance")
	check(body.transform == body_before, "housing remains fixed during barrel recoil")
	check(first.muzzle_transform().is_equal_approx(muzzle), "authoritative muzzle never follows visual barrel")
	check(_pivot(second).position.is_zero_approx(), "entity animation state is independent")
	first.advance_visual_tick(7)
	var recovery := pivot.position
	_fire(first, 2)
	first.advance_visual_tick(6)
	check(pivot.position == recovery, "duplicate fire and old tick cannot restart or rewind recoil")
	first.advance_visual_tick(30)
	check(pivot.position.is_zero_approx(), "barrel returns exactly to its initial pose")
	first.on_event({"kind": &"ability_fired", "source_id": 1, "ability": &"breach", "tick": 31})
	first.advance_visual_tick(32)
	check(is_equal_approx(barrel.global_position.distance_to(before), TankRecoil.STYLE.breach_recoil_m), "committed breach has its own recoil amplitude")
	first.on_event({"kind": &"entity_died", "target_id": 1})
	check(pivot.position.is_zero_approx(), "death clears recoil")
	_fire(first, 33)
	first.on_event({"kind": &"entity_respawned", "target_id": 1})
	check(pivot.position.is_zero_approx(), "respawn clears old-life pose")
	_fire(first, 34)
	first.on_event({"kind": &"match_finished"})
	check(pivot.position.is_zero_approx(), "match end clears motion")
	_fire(first, 35)
	check(first.configure_parts(&"autocannon", &"light_tracks").is_empty(), "switching away safely releases separated barrel")
	first.advance_visual_tick(36)
	check(first.configure_parts(&"cannon", &"light_tracks").is_empty(), "switching back restores original cannon")
	check(_pivot(first).position.is_zero_approx(), "replacement starts at rest")
	first.free()
	second.free()

func _test_session() -> void:
	var session := MovementSession.new()
	root.add_child(session)
	session.set_physics_process(false)
	await physics_frame
	await physics_frame
	if session.phase == MovementSession.Phase.PAUSED:
		session.resume()
	var sim := session.simulation
	var command := PlayerCommand.new()
	command.session_epoch = sim.session_epoch
	command.sequence = 1
	command.client_tick = sim.tick + 1
	command.fire_request_id = 1
	check(sim.enqueue_command(command), "session accepts valid fire request")
	sim.step()
	var pivot := _pivot(session._view)
	check(not pivot.position.is_zero_approx(), "real committed weapon event drives recoil")
	var paused_pose := pivot.position
	var paused_tick := sim.tick
	session.pause()
	for frame: int in range(4):
		sim.step()
		await physics_frame
	check(sim.tick == paused_tick and pivot.position == paused_pose, "paused simulation freezes independent barrel")
	session.resume()
	for frame: int in range(20):
		sim.step()
	check(pivot.position.is_zero_approx(), "resume completes recovery without wall-time jump")
	check(session.start_sparring().is_empty(), "rival session starts")
	var rival := session.sparring
	check(rival._view.entity_id == rival.rival.state.entity_id, "rival recoil identity is injected by session")
	var next := PlayerCommand.new()
	next.sequence = 1
	next.client_tick = sim.tick + 1
	next.fire_request_id = 1
	check(sim.enqueue_rival_command(next), "rival fire command accepted")
	sim.step()
	check(not _pivot(rival._view).position.is_zero_approx(), "rival committed shot drives its own barrel")
	check(pivot.position.is_zero_approx(), "rival shot leaves player barrel at rest")
	session.stop()
	check(_pivot(rival._view).position.is_zero_approx(), "session exit clears rival recoil")
	session.free()
	await process_frame
	check(root.get_child_count() == 0, "session disposal releases all recoil owners")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
