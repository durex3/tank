extends SceneTree
## Actual session fire, turn-rate behavior, physical muzzle isolation and round-wheel poses.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _command(session: MovementSession, request: int = 0, move: Vector2 = Vector2.ZERO) -> void:
	if session.phase == MovementSession.Phase.PAUSED: session.resume()
	var command := PlayerCommand.new()
	command.sequence = session.simulation.tick+1
	command.client_tick = command.sequence
	command.session_epoch = session.simulation.session_epoch
	command.fire_held = request > 0
	command.fire_request_id = request
	command.move_x = roundi(move.x*127)
	command.move_z = roundi(move.y*127)
	session.simulation.enqueue_command(command)
	session.simulation.step()

func _run() -> void:
	await _test_opposite_turn_paths()
	var session := MovementSession.new()
	check(session.configure_loadout(&"autocannon",&"scout_wheels").is_empty(),"new combination valid")
	root.add_child(session)
	session.set_physics_process(false)
	await physics_frame
	await physics_frame
	var view: TankView = session._view
	var facts: Array[Dictionary] = []
	session.simulation.events.published.connect(func(event: Dictionary) -> void:
		if event.kind == &"weapon_fired": facts.append(event))
	var authority: Transform3D = view._muzzle.transform
	_command(session,1)
	session.combat_view._process(0)
	check(view.active_barrel_index() == 0,"first successful shot uses first barrel")
	var first_muzzle: Vector3 = view.visual_muzzle_position()
	var first: ProjectileState = session.simulation.projectiles.active[0]
	var first_visual: Node3D = session.combat_view._visuals[first.projectile_id]
	check(first_visual.position.distance_to(first_muzzle+first.direction*(first.speed/60.0)) < 0.0002,"first visual step starts at the selected physical barrel tip")
	check(is_equal_approx(first.position.y,facts[0].position.y),"visual bridge preserves authoritative shot height")
	_command(session,2)
	check(view.active_barrel_index() == 0,"cooldown rejection does not toggle barrel")
	while session.simulation.tick < 10: _command(session)
	_command(session,3)
	session.combat_view._process(0)
	check(facts.size() == 2 and view.active_barrel_index() == 1,"next accepted shot alternates barrel")
	check(absf(view.visual_muzzle_position().x-first_muzzle.x) > 0.2,"alternating muzzle is spatially separated")
	var second: ProjectileState = session.simulation.projectiles.active[-1]
	check(second.position.x == 0.0,"alternation never shifts authority sideways")
	check(view._muzzle.transform.is_equal_approx(authority) and view._muzzle.position.is_equal_approx(Vector3(0,0.02,-1.05)),"both recoil branches leave authoritative socket fixed")
	view.on_event(facts[-1])
	check(view.active_barrel_index() == 1,"duplicate fact cannot toggle barrel again")
	var left := view.find_child("RecoilPivot",true,false) as Node3D
	var right := view.find_child("RecoilPivotRight",true,false) as Node3D
	check(right != null and left.get_node_or_null("Barrel2") == null,"second gun has an independent recoil owner")
	var old_heading: float = session.actor.state.body_yaw
	_command(session,0,Vector2.DOWN)
	var turn: float = absf(angle_difference(old_heading,session.actor.state.body_yaw))
	check(turn > 0 and turn <= session.actor.motor.steering.turn_rate_radians/60.0+0.0001,"reverse movement turns gradually instead of flipping instantly")
	check(is_zero_approx(session.actor.state.aim_yaw),"chassis steering does not change turret aim")
	var mount: Vector3 = view._turret.position
	for i: int in range(40): _command(session,0,Vector2.DOWN)
	check(view._turret.position == mount,"turning does not slide turret mounting point")
	check(session.start_sparring().is_empty(),"real rival subscribes through the session")
	var rival_view: TankView = session.sparring._view
	check(rival_view.configure_parts(&"autocannon",&"light_tracks").is_empty(),"rival feedback fixture has dual guns")
	for id: int in [900,901]:
		var origin: Vector3 = session.sparring.rival.position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT+Vector3.FORWARD*ProjectileSystem.MUZZLE_OFFSET
		session.simulation.events.publish(&"weapon_fired",id,{"source_id":2,"weapon":&"autocannon","position":origin,"projectile_id":id,"projectile_ids":[id],"direction":Vector3.FORWARD})
		var launch: Dictionary = session.combat_view._launches[id]
		check((launch.offset as Vector3).is_equal_approx(rival_view.visual_muzzle_position()-origin),"rival bridge samples current selected barrel despite later view subscription")
	check(rival_view.active_barrel_index() == 1,"rival successful facts alternate exactly once")
	var before: float = session.actor.state.body_yaw
	session.pause(&"test")
	await physics_frame
	check(session.actor.state.body_yaw == before,"pause freezes steering animation and authority")
	session.stop()
	session.free()
	await process_frame
	_test_wheels()
	await process_frame
	check(root.get_child_count() == 0,"session disposal releases all new moving parts")
	print("FIREARM HANDLING TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_opposite_turn_paths() -> void:
	var rig := CameraRig.new()
	root.add_child(rig)
	var actor := load("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	root.add_child(actor)
	var chassis := LoadoutCatalog.chassis(&"light_tracks")
	actor.configure(LoadoutResolver.resolve(LoadoutCatalog.weapon(&"cannon"),chassis),chassis.acceleration)
	var source := DesktopInputSource.new()
	root.add_child(source)
	source.aim_direction = Vector2.DOWN
	for item: Array in [["move_right",Vector2.LEFT,1],["move_left",Vector2.RIGHT,-1]]:
		actor.motor.halt(actor,actor.state)
		actor.position = Vector3.ZERO
		var old_world: Vector2 = PlanarInput.to_world(item[1],rig.horizontal_right(),rig.horizontal_forward())
		actor.state.body_yaw = atan2(old_world.x,-old_world.y)
		var old: float = actor.state.body_yaw
		Input.action_press(item[0])
		var command: PlayerCommand = source.sample(1)
		Input.action_release(item[0])
		check(command.turn_preference == item[2],"screen A/D provide opposite turn preferences")
		var world: Vector2 = PlanarInput.to_world(Vector2(command.move_x,command.move_z)/127.0,rig.horizontal_right(),rig.horizontal_forward())
		command.move_x = roundi(world.x*127)
		command.move_z = roundi(world.y*127)
		actor.step(command,1.0/60)
		check(angle_difference(old,actor.state.body_yaw)*item[2] > 0,"180-degree reversal follows the requested A/D arc")
		var front := Vector3(sin(actor.state.body_yaw),0,-cos(actor.state.body_yaw))
		var projected: Vector2 = rig.camera.unproject_position(actor.position+front)-rig.camera.unproject_position(actor.position)
		check(projected.y < 0,"left-to-D and right-to-A both start through the upper screen arc")
		check(actor.state.velocity.dot(Vector3(world.x,0,world.y)) > 0,"WASD movement remains in the selected screen direction")
		check(is_equal_approx(actor.state.aim_yaw,PI),"movement and hull turn do not remap injected mouse aim")
	var invalid := PlayerCommand.new()
	invalid.turn_preference = 2
	check(not invalid.is_valid(),"out-of-range turn preference is rejected")
	source.free()
	actor.free()
	rig.free()
	await process_frame

func _bounds(wheel: Node3D) -> AABB:
	var result: AABB
	var first: bool = true
	for mesh: MeshInstance3D in wheel.find_children("*","MeshInstance3D",true,false):
		var box: AABB = wheel.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

func _test_wheels() -> void:
	var part := (TankPartCatalog.CHASSIS[&"scout_wheels"] as PackedScene).instantiate() as Node3D
	root.add_child(part)
	for wheel: Node3D in part.find_children("Wheel*","Node3D",true,false):
		var box: AABB = _bounds(wheel)
		check(absf(box.size.y-box.size.z) < 0.0002,"real wheel geometry has equal rolling diameters")
		check(absf(box.get_center().y)+absf(box.get_center().z) < 0.0002,"wheel geometry is centered on its axle")
	var rig := part.find_child("TrackRig",true,false) as ImportedWheelRig
	rig.present_turn(0.05,0.1)
	rig.present_travel(Vector2(0.2,0.2))
	for wheel: Node3D in rig._wheels:
		check(absf(wheel.rotation.x) > 0.1,"whole wheel rolls with actual displacement")
		check(absf(wheel.rotation.y) > 0.1 if wheel.position.z < 0 else is_zero_approx(wheel.rotation.y),"only front wheels steer")
	rig.present_turn(0,0)
	for wheel: Node3D in rig._wheels: check(is_zero_approx(wheel.rotation.y),"stop/reset returns front steering to neutral")
	part.free()
