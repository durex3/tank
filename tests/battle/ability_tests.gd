extends SceneTree

var failures: int = 0
var facts: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("ABILITY: "+message)

func _actor(parent: Node, id: int, position: Vector3 = Vector3.ZERO, chassis_id: String = "light_tracks") -> TankActor:
	var actor := load("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	actor.state.entity_id = id
	actor.position = position
	parent.add_child(actor)
	var weapon := load("res://content/weapons/cannon.tres") as WeaponDef
	var chassis := load("res://content/chassis/"+chassis_id+".tres") as ChassisDef
	actor.configure(LoadoutResolver.resolve(weapon,chassis),chassis.acceleration)
	return actor

func _command(simulation: BattleSimulation, request: int = 0, held: bool = false) -> PlayerCommand:
	var command := PlayerCommand.new()
	command.sequence = simulation.tick+1
	command.client_tick = simulation.tick+1
	command.session_epoch = simulation.session_epoch
	command.ability_request_id = request
	command.fire_held = held
	return command

func _run() -> void:
	var rules := BasicAbilityRules.new()
	check(rules.validate().is_empty(),"ability rules valid")
	rules.smoke_multiplier = NAN
	check(not rules.validate().is_empty(),"NaN ability tuning rejected")
	var invalid := PlayerCommand.new()
	invalid.aim_distance_cm = 149
	check(not invalid.is_valid(),"undersized aim distance rejected")
	invalid.aim_distance_cm = 1601
	check(not invalid.is_valid(),"oversized aim distance rejected")
	_test_guard()
	_test_passive()
	await _test_casts()
	await _test_smoke()
	await _test_escape_integration()
	await _test_storm_and_push()
	await _test_target_push()
	await _test_nine()
	await _test_ui()
	print("ABILITY TESTS: "+("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_guard() -> void:
	var target := DamageableState.new()
	target.hp = 500
	target.team_id = 1
	target.guard_reduction = 0.3
	var resolver := DamageResolver.new()
	for data: Array in [[Vector3.BACK,true,70],[Vector3.FORWARD,true,100],[Vector3.BACK,false,100],[Vector3(sin(deg_to_rad(60.0)),0,cos(deg_to_rad(60.0))),true,70]]:
		var hit := HitEvent.new()
		hit.target = target
		hit.target_life = target.life_index
		hit.projectile_id = 1
		hit.damage = 100
		hit.direction = data[0]
		hit.direct_projectile = data[1]
		var results := resolver.resolve_batch([hit])
		check(results.size() == 1 and results[0].actual_damage == data[2],"guard front/back/type/angle boundary")
	var tiny := HitEvent.new()
	tiny.target = target
	tiny.damage = 1
	tiny.direction = Vector3.BACK
	check(resolver.resolve_batch([tiny])[0].actual_damage == 1,"guard never rounds positive damage to zero")

func _test_passive() -> void:
	var actor := TankActor.new()
	actor.stats = ResolvedStats.new()
	actor.stats.move_speed = 6.0
	actor.chassis_id = &"light_tracks"
	var command := PlayerCommand.new()
	command.move_x = 127
	var rules := BasicAbilityRules.new()
	for i: int in range(90):
		actor.position = Vector3((i+1)*0.1,0,0)
		ChassisAbilities.after_move(actor,command,actor.position-Vector3(0.1,0,0),false,rules)
	check(actor.ability.cruise_active,"90 actual movement ticks activate cruise")
	for i: int in range(12): ChassisAbilities.after_move(actor,command,actor.position,false,rules)
	check(not actor.ability.cruise_active and actor.ability.charge_ticks == 0,"blocked movement clears boost")
	for i: int in range(100): ChassisAbilities.after_move(actor,command,actor.position-Vector3(0.1,0,0),true,rules)
	check(not actor.ability.cruise_active,"forced displacement cannot charge cruise")
	var gate := WeaponController.new()
	gate.next_fire_tick = 100
	actor.magazine.reload_until = 100
	actor.ability.cruise_active = true
	for tick: int in range(1,5): ChassisAbilities.reload_step(actor,gate,tick,rules)
	check(gate.next_fire_tick == 99 and actor.magazine.reload_until == 99,"four movement ticks grant exactly one reload tick")
	actor.ability.phase = &"cooling"
	for tick: int in range(5,13): ChassisAbilities.reload_step(actor,gate,tick,rules)
	check(gate.next_fire_tick == 99,"reload passive cannot accelerate skill cooling")
	actor.ability.phase = &"idle"
	actor.chassis_id = &"heavy_tracks"
	command.move_x = 0
	for i: int in range(36): ChassisAbilities.after_move(actor,command,actor.position,false,rules)
	check(actor.ability.guard_active,"stationary 36 ticks raises guard")
	command.move_x = 1
	ChassisAbilities.after_move(actor,command,actor.position,false,rules)
	check(actor.ability.guard_active,"mobile heavy keeps frontal guard")
	actor.hurtbox.free()
	actor.free()

func _test_casts() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := _actor(world,1)
	var system := AbilitySystem.new()
	system.register(actor,&"cannon",&"light_tracks")
	var projectiles := ProjectileSystem.new()
	var events := BattleEvents.new()
	var command := PlayerCommand.new()
	command.ability_request_id = 1
	system.before_move(actor,command,1,0,projectiles,events)
	check(actor.ability.energy == 0 and projectiles.reservations.size() == 1,"cast atomically spends energy/reserves projectile")
	actor.ability.energy = 100
	system.before_move(actor,command,2,0,projectiles,events)
	check(actor.ability.energy == 100,"repeated request never spends again")
	var gate := WeaponController.new()
	gate.next_fire_tick = 500
	check(system.attack(actor,gate,27,projectiles,events,[]),"charge blocks ordinary attacks")
	var targets: Array[TrainingTarget] = []
	for z: float in [-3.0,-5.0,-7.0]:
		var target := TrainingTarget.new()
		target.state.entity_id = 100+targets.size()
		target.position = Vector3(0,0,z)
		world.add_child(target)
		targets.append(target)
	await physics_frame
	await physics_frame
	system.attack(actor,gate,28,projectiles,events,targets)
	check(gate.next_fire_tick == 500 and projectiles.reservations.is_empty(),"firing never shortens existing ordinary cooldown")
	for tick: int in range(29,60): projectiles.step(actor.get_world_3d().direct_space_state,tick)
	var resolved := DamageResolver.new().resolve_batch(projectiles.hits)
	check(resolved.size() == 3,"breach hits three distinct targets")
	if resolved.size() == 3:
		check(resolved[0].ability_id == &"breach" and resolved[0].projectile_id == resolved[1].projectile_id,"piercing damage preserves ability and projectile identity per target")
		check(resolved[0].actual_damage == 240 and resolved[1].actual_damage == 144 and resolved[2].actual_damage == 86,"piercing falloff follows travel order")
	projectiles.hits.clear()
	# Budget rejection must not spend energy or set a phase.
	actor.ability.phase = &"idle"
	actor.ability.next_use_tick = 0
	actor.ability.energy = 100
	for i: int in range(ProjectileSystem.MAX_PROJECTILES): projectiles.active.append(ProjectileState.new())
	command.ability_request_id = 2
	system.before_move(actor,command,70,0,projectiles,events)
	check(actor.ability.energy == 100 and actor.ability.phase == &"idle","full budget rejects without spending")
	projectiles.active.clear()
	# Wall blocks the swept sphere before target one.
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0,0.8,-2)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4,2,0.2)
	shape.shape = box
	wall.add_child(shape)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	projectiles.spawn_breach(actor.get_world_3d().direct_space_state,actor.position,0,1,0,80,system.rules)
	for tick: int in range(81,110): projectiles.step(actor.get_world_3d().direct_space_state,tick)
	check(projectiles.hits.is_empty(),"breach cannot cross wall")
	wall.queue_free()
	await physics_frame
	await physics_frame
	# Shock sector excludes behind and walls and submits one hit each.
	targets[0].position = Vector3(0,0,-3)
	targets[1].position = Vector3(0,0,3)
	targets[2].position = Vector3(4,0,-1)
	for target: TrainingTarget in targets:
		target.state.hp = 350
		target.force_update_transform()
		target.hurtbox().force_update_transform()
	await physics_frame
	ShockwaveAttack.execute(actor,0,120,system.rules,[actor],targets,projectiles,events)
	resolved = DamageResolver.new().resolve_batch(projectiles.hits)
	check(resolved.size() == 1 and resolved[0].actual_damage == 150,"shock only hits forward unoccluded sector once")
	world.queue_free()
	await process_frame

func _test_smoke() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := _actor(world,1,Vector3.ZERO,"scout_wheels")
	var enemy := _actor(world,2,Vector3(0,0,0.6))
	enemy.health.team_id = 1
	var system := AbilitySystem.new()
	system.register(actor,&"cannon",&"scout_wheels")
	system.register(enemy,&"cannon",&"light_tracks")
	var projectiles := ProjectileSystem.new()
	var events := BattleEvents.new()
	await physics_frame
	var damage: Array[Dictionary] = [{"source_id":2,"target_id":1,"actual_damage":20,"died":false,"ability_damage":false}]
	system.after_damage(damage,1,projectiles,events)
	check(system.zones.size() == 1,"nonfatal enemy damage drops one smoke")
	system.after_damage(damage,2,projectiles,events)
	check(system.zones.size() == 1 and actor.ability.smoke_ready_tick == 601,"cooldown prevents repeated smoke")
	system.before_move(enemy,PlayerCommand.new(),2,0,projectiles,events)
	check(is_equal_approx(enemy.speed_multiplier,0.65),"enemy inside smoke slows")
	system.before_move(actor,PlayerCommand.new(),2,0,projectiles,events)
	check(is_equal_approx(actor.speed_multiplier,1.25),"owner gains escape speed without friendly smoke slow")
	enemy.position = Vector3(10,0,0)
	system.before_move(enemy,PlayerCommand.new(),3,0,projectiles,events)
	check(is_equal_approx(enemy.speed_multiplier,1),"leaving zone clears slow immediately")
	check(actor.ability.escape_until_tick == 92,"repeat damage cannot refresh escape boost")
	actor.ability.phase = &"breach"
	actor.ability.until_tick = 1000
	system.before_move(actor,PlayerCommand.new(),4,0,projectiles,events)
	check(is_equal_approx(actor.speed_multiplier,0.75),"escape combines with breach movement restriction instead of bypassing it")
	actor.ability.phase = &"idle"
	system.before_move(actor,PlayerCommand.new(),91,0,projectiles,events)
	check(is_equal_approx(actor.speed_multiplier,1.25),"escape boost includes its final active tick")
	system.before_move(actor,PlayerCommand.new(),92,0,projectiles,events)
	check(is_equal_approx(actor.speed_multiplier,1.0),"escape boost ends after exactly 90 movement ticks")
	actor.health.hp = 0
	system.after_damage(damage,3,projectiles,events)
	check(system.zones.is_empty() and actor.ability.energy == 0 and actor.ability.escape_until_tick == 0,"death removes smoke/energy/escape boost")
	system.training = false
	check(not system.refill(enemy),"formal battle rejects training refill")
	enemy.ability.energy = 0
	system.before_move(enemy,PlayerCommand.new(),4,0,projectiles,events)
	system.after_damage([{"source_id":2,"target_id":100,"actual_damage":1000,"ability_damage":false,"died":false}],4,projectiles,events)
	check(is_equal_approx(enemy.ability.energy,5),"per tick energy cap includes passive gain")
	enemy.ability.energy = 0
	system.before_move(enemy,PlayerCommand.new(),5,0,projectiles,events)
	system.after_damage([{"source_id":2,"target_id":100,"actual_damage":1000,"ability_damage":true,"died":false}],5,projectiles,events)
	check(is_equal_approx(enemy.ability.energy,0.05),"ability damage cannot recharge itself")
	world.queue_free()
	await process_frame

func _test_nine() -> void:
	for weapon: StringName in [&"cannon",&"autocannon",&"scatter"]:
		for chassis: StringName in [&"light_tracks",&"heavy_tracks",&"scout_wheels"]:
			var session := MovementSession.new()
			check(session.configure_loadout(weapon,chassis).is_empty(),"nine loadouts configure")
			root.add_child(session)
			session.set_physics_process(false)
			await physics_frame
			var sim: BattleSimulation = session.simulation
			var command := _command(sim,1)
			check(sim.enqueue_command(command),"ability command accepted")
			sim.step()
			check(session.actor.ability.energy == 0 and session.actor.ability.phase != &"idle","all nine combinations activate ability")
			var previous_tick: int = sim.tick
			var until: int = session.actor.ability.until_tick
			session.pause()
			sim.step()
			check(sim.tick == previous_tick and session.actor.ability.until_tick == until,"pause freezes ability timer")
			check(not session.refill_training_ability(),"paused refill rejected")
			session.resume()
			check(not sim.enqueue_command(command),"old controller epoch cannot replay ability")
			check(session.refill_training_ability(),"training refill succeeds")
			for i: int in range(300):
				command = _command(sim,0,weapon == &"autocannon")
				sim.enqueue_command(command)
				sim.step()
			check(session.actor.ability.phase == &"idle","ability and cooling finish on simulation ticks")
			check(session.actor.ability.energy == 100,"no duplicate spend after resume")
			check(sim.weapon_controller.next_fire_tick >= 0,"ordinary cooldown remains valid")
			session.stop()
			check(sim.projectiles.reservations.is_empty(),"stop releases reserved slots")
			session.queue_free()
			await process_frame

func _test_ui() -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await physics_frame
	await process_frame
	check(not screen.ability_hud.release.disabled,"training HUD ready initially")
	screen.ability_hud.release.pressed.emit()
	await physics_frame
	await physics_frame
	check(screen.session.actor.ability.energy == 0,"HUD requests skill through input/session")
	screen.queue_free()
	await process_frame

func _test_storm_and_push() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := _actor(world,1,Vector3.ZERO,"heavy_tracks")
	var weapon := load("res://content/weapons/autocannon.tres") as WeaponDef
	actor.stats = LoadoutResolver.resolve(weapon,load("res://content/chassis/heavy_tracks.tres") as ChassisDef)
	var system := AbilitySystem.new()
	system.register(actor,&"autocannon",&"heavy_tracks")
	var shots := ProjectileSystem.new()
	var events := BattleEvents.new()
	var gate := WeaponController.new()
	gate.next_fire_tick = 20
	var command := PlayerCommand.new()
	command.ability_request_id = 1
	command.fire_held = true
	system.before_move(actor,command,1,0,shots,events)
	WeaponAttack.execute(actor,weapon,gate,command,1,shots,events,system.interval(actor),true,system.damage_multiplier(actor))
	check(shots.active.is_empty() and gate.next_fire_tick == 20,"storm activation preserves ordinary cooldown")
	WeaponAttack.execute(actor,weapon,gate,command,20,shots,events,system.interval(actor),true,system.damage_multiplier(actor))
	check(shots.active.size() == 1 and gate.next_fire_tick == 23,"storm uses three tick intervals")
	check(shots.active[0].damage == 15 and shots.active[0].storm_round and weapon.damage == 25,"storm uses 60 percent damage with independent tracer identity and immutable base")
	WeaponAttack.execute(actor,weapon,gate,command,22,shots,events,system.interval(actor),true,system.damage_multiplier(actor))
	check(shots.active.size() == 1,"storm cannot fire before third tick")
	WeaponAttack.execute(actor,weapon,gate,command,23,shots,events,system.interval(actor),true,system.damage_multiplier(actor))
	check(shots.active.size() == 2 and gate.next_fire_tick == 26,"storm fires at exact third tick boundary")
	command.fire_held = false
	WeaponAttack.execute(actor,weapon,gate,command,25,shots,events,system.interval(actor),true,system.damage_multiplier(actor))
	check(shots.active.size() == 2,"releasing held fire stops storm shots")
	system.before_move(actor,command,181,0,shots,events)
	check(actor.ability.phase == &"cooling" and system.attack(actor,gate,181,shots,events,[]),"storm finishes into a blocked cooling window")
	system.before_move(actor,command,270,0,shots,events)
	check(actor.ability.phase == &"cooling" and system.attack(actor,gate,270,shots,events,[]),"red heat still blocks fire before 90 tick boundary")
	system.before_move(actor,command,271,0,shots,events)
	check(actor.ability.phase == &"idle","cooling ends at 90 simulation ticks")
	var victim := _actor(world,2,Vector3(0,0,-3),"heavy_tracks")
	victim.health.team_id = 1
	system.register(victim,&"cannon",&"heavy_tracks")
	var wall := StaticBody3D.new()
	wall.position = Vector3(0,0.8,-4)
	wall.collision_layer = 1
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3,2,0.2)
	collision.shape = box
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	ShockwaveAttack.execute(actor,0,220,system.rules,system.actors,[],shots,events)
	var results := DamageResolver.new().resolve_batch(shots.hits)
	check(results.size() == 1,"shock submits one enemy hit")
	system.after_damage(results,220,shots,events)
	var start: Vector3 = victim.position
	for tick: int in range(221,235):
		var before: Vector3 = victim.position
		var forced: bool = system.before_move(victim,PlayerCommand.new(),tick,0,shots,events)
		victim.step(PlayerCommand.new(),1.0/60)
		system.after_move(victim,PlayerCommand.new(),before,forced)
	check(victim.position.z < start.z-0.05 and victim.position.z >= -3.46,"shock moves survivor but cannot push through wall")
	check(victim.health.hp == victim.health.max_hp-150,"wall does not add squeeze damage")
	world.queue_free()
	await process_frame

func _test_target_push() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := _actor(world,1)
	var weapon := load("res://content/weapons/scatter.tres") as WeaponDef
	var chassis := load("res://content/chassis/light_tracks.tres") as ChassisDef
	actor.configure(LoadoutResolver.resolve(weapon,chassis),chassis.acceleration)
	var target := TrainingTarget.new()
	target.state.entity_id = 100
	target.position = Vector3(0,0,-3)
	world.add_child(target)
	var sim := BattleSimulation.new()
	world.add_child(sim)
	sim.actor = actor
	sim.weapon = weapon
	sim.targets.append(target)
	sim.abilities.register(actor,&"scatter",&"light_tracks")
	await physics_frame
	await physics_frame
	var initial: Vector3 = target.position
	check(sim.enqueue_command(_command(sim,1)),"training shock request accepted")
	for i: int in range(40): sim.step()
	check(target.state.hp == target.state.max_hp-80,"dash contact damages target exactly once")
	check(target.position.is_equal_approx(initial),"dash does not push training target")
	check(actor.position.z < -1.0 and actor.position.z > -3.0,"dash stops at enemy body")
	check(actor.ability.phase == &"idle","contact terminates dash")
	var stopped: Vector3 = actor.position
	sim.set_paused(true)
	for i: int in range(12): sim.step()
	check(actor.position.is_equal_approx(stopped),"pause freezes dash movement")
	sim.set_paused(false)
	target.reset_motion()
	target.configure_motion(2.0,1.0)
	target.commit_push(Vector3.FORWARD*1.2,12)
	for i: int in range(12): target.step_motion()
	target.step_motion()
	check(is_equal_approx(target.position.z,initial.z-1.2),"patrol resumes relative to displaced path")
	target.reset_motion()
	check(target.position.is_equal_approx(initial),"rebuild/reset clears displaced path")
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = Vector3(0,0.7,-4.0)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(4,2,0.1)
	collision.shape = box
	wall.add_child(collision)
	world.add_child(wall)
	await physics_frame
	await physics_frame
	target.commit_push(Vector3.FORWARD*1.2,12)
	for i: int in range(12): target.step_motion()
	check(target.position.z > -3.4 and target.position.z < -3.1,"training knockback stops at wall with body radius")
	check(target.state.hp == target.state.max_hp-80,"wall contact adds no squeeze damage")
	target.reset_motion()
	target.state.hp = 0
	target.commit_push(Vector3.FORWARD*1.2,12)
	target.step_motion()
	check(target.position.is_equal_approx(initial),"dead training target cannot be pushed")
	world.free()

func _test_escape_integration() -> void:
	var world := Node3D.new()
	root.add_child(world)
	var actor := _actor(world,1,Vector3.ZERO,"scout_wheels")
	var sim := BattleSimulation.new()
	world.add_child(sim)
	var hud := AbilityHud.new()
	world.add_child(hud)
	world.add_child(hud.passive_panel)
	sim.events.published.connect(hud.on_event)
	sim.actor = actor
	sim.abilities.register(actor,&"cannon",&"scout_wheels")
	var target := TrainingTarget.new()
	target.position = Vector3(20,0,20)
	target.state.entity_id = 100
	world.add_child(target)
	sim.targets.append(target)
	await physics_frame
	await physics_frame
	var hit := HitEvent.new()
	hit.projectile_id = 1000
	hit.source_id = 2
	hit.team_id = 1
	hit.target = actor.health
	hit.target_life = actor.health.life_index
	hit.damage = 20
	sim.projectiles.hits.append(hit)
	sim.step()
	check(actor.health.hp == actor.health.max_hp-20 and sim.abilities.zones.size() == 1,"real batch damage triggers one escape smoke")
	check(is_equal_approx(actor.speed_multiplier,1.0),"escape starts next tick, never changes already committed movement")
	check(hud._passive.text.contains("+25%") and hud._passive.text.contains("1.5秒"),"committed escape HUD displays literal percent and remaining duration")
	for i: int in range(60):
		var command := _command(sim)
		command.move_x = 127
		sim.enqueue_command(command)
		sim.step()
	check(is_equal_approx(actor.state.velocity.x,actor.stats.move_speed*1.25),"escape raises actual autonomous top speed by 25 percent")
	check(actor.position.x > actor.stats.move_speed*0.95,"escape produces actual extra travel, not only a HUD multiplier")
	var until: int = actor.ability.escape_until_tick
	var frozen_position: Vector3 = actor.position
	sim.set_paused(true)
	for i: int in range(120): sim.step()
	check(actor.ability.escape_until_tick == until and actor.position == frozen_position and sim.tick == 61,"pause freezes escape timer and displacement")
	sim.set_paused(false)
	target.position = sim.abilities.zones[0].position
	target.configure_motion(20,1)
	var before: Vector3 = target.position
	for i: int in range(30): sim.step()
	check(is_equal_approx(target.position.x-before.x,0.325),"simulation patrol target travels 65 percent distance inside smoke")
	var speed_before: float = actor.speed_multiplier
	check(is_equal_approx(speed_before,1.25),"escape lasts through final movement tick")
	sim.step()
	check(is_equal_approx(actor.speed_multiplier,1.0),"escape multiplier clears on first tick after window")
	var zone: Dictionary = sim.abilities.zones[0].duplicate()
	sim.abilities.zones.append(zone)
	check(is_equal_approx(sim.abilities.smoke_multiplier_at(target.position,1,sim.tick),0.65),"overlapping smoke does not multiply slowdown")
	check(is_equal_approx(sim.abilities.smoke_multiplier_at(target.position,0,sim.tick),1.0),"allied patrol is unaffected by smoke")
	check(is_equal_approx(sim.abilities.smoke_multiplier_at(Vector3(30,0,30),1,sim.tick),1.0),"leaving smoke restores patrol speed")
	check(is_equal_approx(sim.abilities.smoke_multiplier_at(target.position,1,152),1.0),"expired smoke cannot slow before actor cleanup")
	actor.ability.reset_life(actor.health.life_index+1)
	check(actor.ability.escape_until_tick == 0,"new life has no stale escape acceleration")
	world.free()
