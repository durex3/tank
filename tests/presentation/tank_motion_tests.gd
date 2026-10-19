extends SceneTree
## Committed fire -> independent barrel; pause/lifecycle never alter combat muzzle.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_independent_barrel()
	_test_tracks()
	_test_family_motion()
	await _test_session()
	print("TANK MOTION TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _pivot(view: TankView) -> Node3D:
	return view.find_child("RecoilPivot", true, false) as Node3D

func _housing_poses(view: TankView) -> Dictionary:
	var result: Dictionary = {}
	for node: MeshInstance3D in view._turret.find_children("*", "MeshInstance3D", true, false):
		var ancestor: Node = node.get_parent()
		var moving := false
		while ancestor != view._turret:
			if ancestor.name in [&"RecoilPivot", &"RecoilPivotRight"]: moving = true
			ancestor = ancestor.get_parent()
		if not moving: result[node] = node.global_transform
	return result

func _housing_unchanged(poses: Dictionary) -> bool:
	for node: Node3D in poses:
		if not node.global_transform.is_equal_approx(poses[node]): return false
	return true

func _test_tracks() -> void:
	var view := TankView.new()
	root.add_child(view)
	var other := TankView.new()
	root.add_child(other)
	var left := view.find_child("WheelRight0", true, false) as Node3D
	var right := view.find_child("WheelLeft0", true, false) as Node3D
	check(left != null and right != null, "authored rig has six independent complete circular wheels")
	if left == null or right == null:
		view.free()
		other.free()
		return
	var state := TankState.new()
	view.present(state)
	view.advance_visual_tick(0)
	var rig := view.find_child("TrackRig", true, false) as TrackRig
	var rest_belt := rig.cleat_pose(0, 0)
	var arrays := rig.belt_geometry
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var bottom_faces: int = 0
	for i: int in range(vertices.size()):
		if vertices[i].y < TrackRig.STYLE.axle_y - TrackRig.STYLE.belt_radius and absf(normals[i].y) > 0.9:
			bottom_faces += 1
			check(normals[i].y < 0.0, "bottom belt outer surface faces downward")
	check(bottom_faces > 0, "closed belt contains outward-facing lower surface")
	check(TrackRig.STYLE.belt_width * 0.5 > 0.158, "belt side extends beyond wheel face to remain visible")
	check(TrackRig.STYLE.axle_y - TrackRig.STYLE.belt_radius - TrackRig.STYLE.belt_thickness * 0.5 - TrackRig.STYLE.cleat_height >= -0.00001, "lower belt and cleats remain above ground")
	state.position.z = -0.05
	view.present(state)
	view.advance_visual_tick(1)
	check(left.rotation.x > 0 and is_equal_approx(left.rotation.x, right.rotation.x), "forward displacement rotates both sides equally")
	var forward := left.rotation.x
	var belt_pose := rig.cleat_pose(0, 0)
	check(not belt_pose.is_equal_approx(rest_belt), "forward travel moves tread geometry along the loop")
	state.velocity = Vector3.FORWARD * 10
	view.present(state)
	view.advance_visual_tick(2)
	check(left.rotation.x == forward, "blocked motion and stationary ticks never spin wheels")
	check(rig.cleat_pose(0, 0).is_equal_approx(belt_pose), "stationary ticks freeze tread geometry")
	state.position.z = 0.0
	view.present(state)
	view.advance_visual_tick(3)
	check(is_zero_approx(left.rotation.x), "reverse displacement reverses wheel rotation")
	check(rig.cleat_pose(0, 0).is_equal_approx(rest_belt), "equal reverse travel returns tread geometry to rest")
	state.body_yaw = 0.08
	view.present(state)
	view.advance_visual_tick(4)
	check(left.rotation.x > 0 and right.rotation.x < 0, "right pivot turn drives left forward and right backward")
	var turning := left.rotation.x
	state.position.z = -0.1
	view.present(state)
	view.advance_visual_tick(4)
	check(left.rotation.x == turning, "duplicate committed tick cannot advance tracks")
	check(is_zero_approx((other.find_child("WheelRight0", true, false) as Node3D).rotation.x), "track motion is instance independent")
	view.on_event({"kind": &"entity_died", "target_id": view.entity_id})
	check(is_zero_approx(left.rotation.x), "death resets wheel pose and displacement baseline")
	view.advance_visual_tick(5)
	state.position = Vector3(100, 0, 0)
	view.present(state)
	view.advance_visual_tick(6)
	check(is_zero_approx(left.rotation.x), "teleport never becomes a huge wheel roll")
	check(view.configure_parts(&"cannon", &"heavy_tracks").is_empty(), "unsupported chassis safely clears track animation")
	view.advance_visual_tick(7)
	view.free()
	other.free()

func _fire(view: TankView, tick: int, source: int = 1) -> void:
	view.on_event({"kind": &"weapon_fired", "weapon": &"cannon", "source_id": source, "tick": tick})

func _test_family_motion() -> void:
	for weapon: StringName in [&"autocannon", &"scatter", &"bubble_cannon"]:
		var view := TankView.new()
		view.weapon_id = weapon
		view.entity_id = 10
		root.add_child(view)
		var pivot := _pivot(view)
		var housing := _housing_poses(view)
		check(pivot != null and not housing.is_empty(), "new turret has separate rigid housing and nozzle: " + str(weapon))
		var authority := view.muzzle_transform()
		var cosmetic := view.visual_muzzle_position()
		view.on_event({"kind": &"weapon_fired", "weapon": &"cannon", "source_id": 10, "tick": 1})
		check(pivot.position.is_zero_approx(), "mismatched weapon cannot animate new turret")
		view.on_event({"kind": &"weapon_fired", "weapon": weapon, "source_id": 10, "tick": 2})
		view.advance_visual_tick(3)
		check(not pivot.position.is_zero_approx() and _housing_unchanged(housing), "committed matching shot retracts only nozzle")
		check(view.visual_muzzle_position().z > cosmetic.z, "new turret cosmetic muzzle follows nozzle")
		check(view.muzzle_transform().is_equal_approx(authority), "new turret animation preserves combat muzzle")
		view.on_event({"kind": &"entity_respawned", "target_id": 10})
		check(pivot.position.is_zero_approx(), "new turret respawn clears old-life pose")
		view.free()
	for chassis: StringName in [&"scout_wheels", &"heavy_tracks"]:
		var view := TankView.new()
		view.chassis_id = chassis
		root.add_child(view)
		var rig := view.find_child("TrackRig", true, false) as TrackRig
		var wheels := view.find_children("Wheel*", "Node3D", true, false)
		check(rig != null and wheels.size() == (4 if chassis == &"scout_wheels" else 8), "new chassis has complete independent wheel count")
		var state := TankState.new()
		view.present(state)
		view.advance_visual_tick(0)
		state.position.z = -0.08
		view.present(state)
		view.advance_visual_tick(1)
		for wheel: Node3D in wheels:
			check(wheel.rotation.x > 0.0, "every complete new chassis wheel follows forward displacement")
		var before: float = (wheels[0] as Node3D).rotation.x
		view.advance_visual_tick(1)
		check((wheels[0] as Node3D).rotation.x == before, "new chassis duplicate tick remains stationary")
		view.on_event({"kind": &"match_finished"})
		for wheel: Node3D in wheels:
			check(is_zero_approx(wheel.rotation.x), "new chassis lifecycle resets all wheel axes")
		view.free()

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
	var housing := _housing_poses(first)
	check(not housing.is_empty(), "turret contains static housing meshes")
	var before := barrel.global_position
	var muzzle := first.muzzle_transform()
	var visual_muzzle := first.visual_muzzle_position()
	check(visual_muzzle.distance_to(muzzle.origin) > 0.1, "Rodin cosmetic muzzle is separate from authoritative marker")
	first.on_event({"kind": &"fire_rejected", "source_id": 1, "tick": 1})
	_fire(first, 1, 2)
	check(pivot.position.is_zero_approx(), "rejected and other-entity fire have no effect")
	_fire(first, 2)
	first.advance_visual_tick(3)
	check(barrel.global_position.distance_to(before + Vector3.BACK * TankRecoil.STYLE.cannon_recoil_m) < 0.0001, "barrel retracts by world-space cosmetic distance")
	check(_housing_unchanged(housing), "housing remains fixed during barrel recoil")
	check(first.muzzle_transform().is_equal_approx(muzzle), "authoritative muzzle never follows visual barrel")
	check(first.visual_muzzle_position().distance_to(visual_muzzle + Vector3.BACK * TankRecoil.STYLE.cannon_recoil_m) < 0.0001, "cosmetic muzzle follows separated barrel recoil")
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
	var fired_facts: Array[Dictionary] = []
	sim.events.published.connect(func(event: Dictionary) -> void:
		if event.kind == &"weapon_fired": fired_facts.append(event.duplicate()))
	var command := PlayerCommand.new()
	command.session_epoch = sim.session_epoch
	command.sequence = 1
	command.client_tick = sim.tick + 1
	command.fire_request_id = 1
	check(sim.enqueue_command(command), "session accepts valid fire request")
	sim.step()
	check(fired_facts.size() == 1 and fired_facts[0].position.is_equal_approx(session._view.muzzle_transform().origin), "cosmetic effect routing never mutates committed shot position")
	var pivot := _pivot(session._view)
	check(not pivot.position.is_zero_approx(), "real committed weapon event drives recoil")
	var move := PlayerCommand.new()
	move.session_epoch = sim.session_epoch
	move.sequence = 2
	move.client_tick = sim.tick + 1
	move.move_z = -127
	check(sim.enqueue_command(move), "real session movement accepted")
	for frame: int in range(3): sim.step()
	var wheel := session._view.find_child("WheelRight0", true, false) as Node3D
	check(not is_zero_approx(wheel.rotation.x), "actual committed movement drives wheels")
	var paused_wheel := wheel.rotation.x
	var paused_pose := pivot.position
	var paused_tick := sim.tick
	session.pause()
	for frame: int in range(4):
		sim.step()
		await physics_frame
	check(sim.tick == paused_tick and pivot.position == paused_pose, "paused simulation freezes independent barrel")
	check(wheel.rotation.x == paused_wheel, "pause freezes wheel rotation in real session")
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
