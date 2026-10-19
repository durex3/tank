extends SceneTree
## Public behavior boundaries for magazine, committed slows and atomic fields.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_growth_and_slows()
	await _test_physics()
	await _test_session()
	print("BUBBLE TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_growth_and_slows() -> void:
	var w := LoadoutCatalog.weapon(&"bubble_cannon")
	check(w.damage == 55 and w.magazine_size == 4 and w.projectile_radius == 0.25,"baseline content")
	check(PartGrowth.table(w.id).unlock_cost == 120,"unlock cost")
	check(PartGrowth.weapon(w.id,6).weight == 1 and PartGrowth.weapon(w.id,7).weight == 2,"level seven weight boundary")
	check(PartGrowth.weapon(w.id,10).damage == 70 and w.damage == 55,"growth does not mutate content")
	for chassis: ChassisDef in LoadoutCatalog.CHASSIS:
		for level: int in [1,10]:
			var resolved := PartGrowth.resolve(w.id,chassis.id,level,1)
			check(resolved != null and resolved.damage == PartGrowth.weapon(w.id,level).damage,"all chassis resolve exact selected growth")
	var stats := PartGrowth.resolve(w.id,&"light_tracks",1,1)
	check(is_equal_approx(stats.nominal_dps(1),220.0*60/201),"sustained DPS includes reload once")
	var mag := MagazineState.new()
	mag.step(w,0,1)
	for tick: int in [1,40,79,118]: mag.consume(tick)
	check(mag.rounds == 0 and mag.reload_until == 202,"last round starts exactly 84 tick reload")
	mag.step(w,0,201)
	check(mag.rounds == 0,"reload boundary stays empty")
	mag.step(w,0,202)
	check(mag.rounds == 4,"reload restores at boundary")
	mag.consume(202)
	mag.step(w,0,203)
	check(mag.rounds == 3,"same life keeps ammo")
	mag.step(w,1,204)
	check(mag.rounds == 4,"new life resets ammo")
	var slow := SlowEffects.new()
	var state := DamageableState.new()
	state.entity_id = 7
	state.hp = 100
	var states: Array[DamageableState] = [state]
	var results: Array[Dictionary] = [{"source_id":1,"target_id":7,"life_index":0,"slow_ticks":60,"slow_multiplier":0.85}]
	slow.commit(results,states,10)
	check(slow.multiplier(state,10) == 1.0 and slow.multiplier(state,11) == 0.85,"slow starts next tick")
	check(slow.multiplier(state,70) == 0.85 and slow.multiplier(state,71) == 1.0,"slow lasts exactly 60 ticks")
	slow.commit(results,states,30)
	results[0].source_id = 2
	results[0].slow_multiplier = 0.7
	slow.commit(results,states,40)
	check(slow.multiplier(state,41) == 0.7,"different slows choose strongest without multiplying")
	state.hp = 0
	slow.commit([],states,41)
	state.hp = 100
	check(slow.multiplier(state,42) == 1.0,"death removes committed slow")
	var service := EquipmentService.new()
	service.store.path = "user://bubble_unlock_test.json"
	for suffix: String in ["", ".bak", ".tmp"]: DirAccess.remove_absolute(service.store.path+suffix)
	check(service.open().is_empty(),"open isolated test profile")
	service.profile.coins = 119
	check(service.unlock(w.id) == "insufficient_coins" and not service.profile.owns(w.id),"insufficient unlock is atomic")
	service.profile.coins = 120
	check(service.unlock(w.id).is_empty() and service.profile.coins == 0,"unlock deducts exact cost")
	check(service.profile.weapon_id == &"cannon","unlock does not equip")
	service.profile.coins = 20
	service.store.path = "user://missing_bubble_directory/save.json"
	check(not service.upgrade(w.id,1).is_empty() and service.profile.level_of(w.id) == 1 and service.profile.coins == 20,"save failure keeps growth and coins")
	for suffix: String in ["", ".bak", ".tmp"]: DirAccess.remove_absolute("user://bubble_unlock_test.json"+suffix)

func _test_physics() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var target := TrainingTarget.new()
	target.position = Vector3(0,0,-3)
	world.add_child(target)
	await physics_frame
	await physics_frame
	var space := target.get_world_3d().direct_space_state
	var w := LoadoutCatalog.weapon(&"bubble_cannon")
	var p := ProjectileSystem.new()
	var shot := p.spawn(space,Vector3.ZERO,0,w,1,1,1,NAN,0,3.0)
	check(is_equal_approx(shot.remaining_range,7.95),"range accounts for barrel offset")
	p.step(space,2)
	check(shot.position.y > ProjectileSystem.SHOT_HEIGHT and shot.position.z < -1.05,"bubble ascends along real ballistic path")
	for tick: int in range(3,30): p.step(space,tick)
	check(p.hits.size() == 1 and p.active.is_empty(),"ordinary bubble hits once then pops")
	var results := DamageResolver.new().resolve_batch(p.hits)
	check(results.size() == 1 and results[0].actual_damage == 55 and results[0].slow_ticks == 60,"ordinary hit commits damage and slow metadata")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0,0.78,-0.5)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(5,6,0.1)
	collision.shape = shape
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	p = ProjectileSystem.new()
	p.spawn(space,Vector3.ZERO,0,w,1,1,1,NAN,0,3.0)
	check(p.active.is_empty() and p.hits.is_empty() and p.impacts.size() == 1,"wall blocks bubble before muzzle")
	var curtain := BubbleCurtain.new()
	var positions := PackedVector3Array([Vector3(0,0.2,-3)])
	check(not curtain.valid_plan(space,Vector3(0,0.78,0),positions),"high wall blocks lob arc")
	positions[0] = Vector3(100,0.2,0)
	check(not curtain.valid_plan(space,Vector3.ZERO,positions),"map bounds reject field")
	world.free()
	await process_frame

func _test_session() -> void:
	var session := MovementSession.new()
	check(session.configure_loadout(&"bubble_cannon",&"light_tracks").is_empty(),"bubble loadout ready")
	root.add_child(session)
	session.set_physics_process(false)
	await physics_frame
	await physics_frame
	var sim := session.simulation
	var actor := session.actor
	actor.position = Vector3(0,0,5)
	actor.force_update_transform()
	await physics_frame
	var events: Array[Dictionary] = []
	sim.events.published.connect(func(event: Dictionary) -> void: events.append(event))
	for tick: int in range(1,119):
		var command := PlayerCommand.new()
		if tick in [1,40,79,118]: command.fire_request_id = tick
		_step(sim,command)
	check(actor.magazine.rounds == 0 and actor.magazine.reload_until == 202,"simulation consumes four shots")
	var epoch := sim.replace_controller()
	check(actor.magazine.rounds == 0 and sim.weapon_controller.next_fire_tick == 202,"controller switch cannot refill or shorten reload")
	sim.set_paused(true)
	sim.step()
	check(sim.tick == 118 and actor.magazine.rounds == 0,"pause freezes reload")
	sim.set_paused(false)
	var curtain := sim.abilities.curtain
	var p := ProjectileSystem.new()
	for i: int in range(128): p.active.append(ProjectileState.new())
	check(curtain.prepare(actor,0,p) == "弹丸预算不足" and p.reservations.is_empty(),"full budget rejects field atomically")
	p.active.clear()
	check(curtain.prepare(actor,0,p).is_empty() and p.used_slots() == 1,"reserve single lob")
	var plan := curtain.plan_for(actor.state.entity_id)
	check(plan.size() == 1,"one frozen landing point")
	actor.position.x = 2
	check(curtain.deploy(actor,120,p,sim.events),"deploy reserved lob")
	check(p.active.size() == 1 and p.reservations.is_empty() and p.active[0].arc_end == plan[0],"moving caster keeps frozen landing")
	var target: TrainingTarget = sim.targets[0]
	target.position = Vector3(plan[0].x,0,plan[0].z)
	target.configure_motion(0,0)
	target.force_update_transform()
	await physics_frame
	var victims: Array[Damageable] = [target.hurtbox()]
	var space := actor.get_world_3d().direct_space_state
	curtain.step(138,p,victims,space)
	check(p.hits.is_empty() and p.active[0].position.y > 2,"airborne lob has no ground damage")
	target.state.protected = true
	curtain.step(156,p,victims,space)
	check(p.hits.is_empty() and p.active[0].kind == &"bubble_field","protected victim ignores landed field damage")
	target.state.protected = false
	curtain.step(157,p,victims,space)
	check(p.hits.size() == 1,"ground field first pulse")
	DamageResolver.new().resolve_batch(p.hits)
	check(target.state.hp == target.state.max_hp-20,"field pulse deals twenty damage")
	p.hits.clear()
	curtain.step(186,p,victims,space)
	check(p.hits.is_empty(),"no pulse before thirty ticks")
	curtain.step(187,p,victims,space)
	check(p.hits.size() == 1,"pulse repeats on exact boundary")
	check(curtain.multiplier(target.position,1,187) == 0.65,"enemy inside field slowed")
	check(curtain.multiplier(target.position,0,187) == 1.0,"friendly unaffected")
	check(curtain.multiplier(target.position+Vector3.RIGHT*3,1,187) == 1.0,"leaving field immediately clears field slow")
	curtain.prune(395,p)
	check(p.active.size() == 1,"field lives through final active tick")
	curtain.prune(396,p)
	check(p.active.is_empty(),"field expires after exactly four seconds")
	actor.position = Vector3(0,0,5)
	check(curtain.prepare(actor,0,p).is_empty(),"prepare before dynamic obstruction")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = curtain.plan_for(actor.state.entity_id)[0]
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3.ONE
	collision.shape = box
	wall.add_child(collision)
	session.add_child(wall)
	await physics_frame
	await physics_frame
	check(not curtain.deploy(actor,301,p,sim.events) and p.used_slots() == 0,"dynamic obstruction cancels whole reserved field")
	wall.free()
	await physics_frame
	var command := PlayerCommand.new()
	command.ability_request_id = 1
	command.session_epoch = epoch
	_step(sim,command)
	check(actor.ability.phase == &"bubble" and sim.projectiles.reservations.get(actor.state.entity_id,0) == 1,"activation begins reserved preparation")
	var start := sim.tick
	for i: int in range(20): _step(sim,PlayerCommand.new())
	check(actor.ability.phase == &"bubble","preparation does not finish early")
	_step(sim,PlayerCommand.new())
	check(sim.tick == start+21 and actor.ability.phase == &"idle" and sim.projectiles.reservations.is_empty(),"preparation completes at 21 tick")
	actor.health.hp = 0
	sim.abilities.after_damage([],sim.tick,sim.projectiles,sim.events)
	check(sim.projectiles.active.filter(func(s: ProjectileState) -> bool: return s.kind in [&"bubble_field",&"bubble_lob"]).is_empty(),"owner death clears curtain")
	session.stop()
	session.free()
	await process_frame

func _step(sim: BattleSimulation, command: PlayerCommand) -> void:
	command.session_epoch = sim.session_epoch
	command.client_tick = sim.tick+1
	command.sequence = sim.tick+1
	check(sim.enqueue_command(command),"fresh command accepted")
	sim.step()

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
