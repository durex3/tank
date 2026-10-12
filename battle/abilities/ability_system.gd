extends RefCounted
class_name AbilitySystem
## Six-ability orchestration. Projectile/damage authority remains in the existing systems.

var rules: BasicAbilityRules = preload("res://content/rules/basic_abilities.tres")
var training: bool = true
var actors: Array[TankActor] = []
var zones: Array[Dictionary] = []
var _pushes: Dictionary = {}

func register(actor: TankActor, weapon_id: StringName, chassis_id: StringName) -> void:
	if actors.has(actor): return
	assert(rules.validate().is_empty(),"Invalid ability tuning")
	actor.weapon_id = weapon_id
	actor.chassis_id = chassis_id
	actor.ability.reset_life(actor.health.life_index)
	actor.ability.energy = rules.energy_max if training else 0.0
	actors.append(actor)

func before_move(actor: TankActor, command: PlayerCommand, tick: int, epoch: int, projectiles: ProjectileSystem, events: BattleEvents) -> bool:
	if not actors.has(actor): return false
	var state: AbilityState = actor.ability
	state.gained_this_tick = 0.0
	if state.life != actor.health.life_index:
		_release(actor,projectiles)
		state.reset_life(actor.health.life_index)
	if state.epoch != epoch:
		state.epoch = epoch
		state.last_request = 0
	if actor.health.hp <= 0:
		return false
	if not training and not actor.health.protected: _gain(state,rules.energy_per_tick)
	if state.phase == &"storm" and tick >= state.until_tick:
		state.phase = &"cooling"
		state.until_tick = tick+rules.storm_cooldown
	elif state.phase == &"cooling" and tick >= state.until_tick:
		state.phase = &"idle"
	if command.ability_request_id > state.last_request:
		state.last_request = command.ability_request_id
		var reason := _activate(actor,command,tick,projectiles)
		events.publish(&"ability_rejected" if not reason.is_empty() else &"ability_started",tick,{"source_id":actor.state.entity_id,"reason":reason,"phase":state.phase})
	actor.speed_multiplier = (rules.cruise_multiplier if state.cruise_active else 1.0)
	if state.phase == &"breach": actor.speed_multiplier *= rules.breach_speed_multiplier
	zones = zones.filter(func(zone: Dictionary) -> bool: return tick < zone.until_tick and _owner_alive(zone.owner_id))
	for zone: Dictionary in zones:
		if zone.team_id != actor.health.team_id and actor.position.distance_to(zone.position) <= rules.smoke_radius:
			actor.speed_multiplier *= rules.smoke_multiplier
			break
	var forced: bool = _pushes.has(actor.state.entity_id)
	actor.forced_velocity = Vector3.ZERO
	if forced:
		var push: Dictionary = _pushes[actor.state.entity_id]
		if tick >= push.until_tick:
			_pushes.erase(actor.state.entity_id)
			forced = false
		else:
			actor.forced_velocity = push.velocity
	return forced

func _activate(actor: TankActor, command: PlayerCommand, tick: int, projectiles: ProjectileSystem) -> String:
	var state: AbilityState = actor.ability
	if actor.health.protected: return "出生保护中"
	if state.phase != &"idle": return "技能进行中"
	if tick < state.next_use_tick: return "技能间隔未结束"
	if state.energy < rules.energy_max: return "能量不足"
	if actor.weapon_id not in [&"cannon",&"autocannon",&"scatter"]: return "能力未就绪"
	if actor.weapon_id == &"cannon":
		if not projectiles.reserve(actor.state.entity_id): return "弹丸预算不足"
		state.reserved = true
		state.phase = &"breach"
		state.until_tick = tick+rules.breach_charge
	elif actor.weapon_id == &"autocannon":
		state.phase = &"storm"
		state.until_tick = tick+rules.storm_ticks
	else:
		state.phase = &"shock"
		state.until_tick = tick+rules.shock_charge
		state.locked_yaw = float(command.aim_yaw)/65536.0*TAU
	state.energy = 0.0
	state.next_use_tick = tick+rules.minimum_interval
	return ""

func after_move(actor: TankActor, command: PlayerCommand, before: Vector3, forced: bool) -> void:
	if actors.has(actor) and actor.health.hp > 0:
		ChassisAbilities.after_move(actor,command,before,forced,rules)

func attack(actor: TankActor, gate: WeaponController, tick: int, projectiles: ProjectileSystem, events: BattleEvents, targets: Array[TrainingTarget]) -> bool:
	if not actors.has(actor): return false
	var state: AbilityState = actor.ability
	if state.phase == &"cooling":
		gate.cancel_pending()
		return true
	if state.phase not in [&"breach",&"shock"]: return false
	gate.cancel_pending()
	if tick < state.until_tick: return true
	if state.phase == &"breach":
		_release(actor,projectiles)
		var shot := projectiles.spawn_breach(actor.get_world_3d().direct_space_state,actor.position,actor.state.aim_yaw,actor.state.entity_id,actor.health.team_id,tick,rules,actor.health.life_index)
		if shot != null:
			events.publish(&"ability_fired",tick,{"source_id":actor.state.entity_id,"ability":&"breach","position":shot.position,"yaw":actor.state.aim_yaw})
	else:
		ShockwaveAttack.execute(actor,state.locked_yaw,tick,rules,actors,targets,projectiles,events)
	state.phase = &"idle"
	gate.next_fire_tick = maxi(gate.next_fire_tick,tick+actor.stats.interval_ticks)
	return true

func interval(actor: TankActor) -> int:
	return rules.storm_interval if actors.has(actor) and actor.ability.phase == &"storm" else actor.stats.interval_ticks

func after_damage(results: Array[Dictionary], tick: int, projectiles: ProjectileSystem, events: BattleEvents) -> void:
	var damaged: Dictionary = {}
	for result: Dictionary in results:
		for actor: TankActor in actors:
			if actor.state.entity_id == result.source_id and actor.health.hp > 0 and not actor.health.protected and result.get("source_life",actor.health.life_index) == actor.health.life_index and not training and not result.get("ability_damage",false):
				_gain(actor.ability,float(result.actual_damage)/rules.damage_per_energy)
			if actor.state.entity_id == result.target_id: damaged[actor.state.entity_id] = actor
	for actor: TankActor in actors:
		if actor.health.hp <= 0:
			_release(actor,projectiles)
			actor.ability.reset_life(actor.health.life_index)
			actor.health.guard_reduction = 0.0
			_pushes.erase(actor.state.entity_id)
		elif damaged.has(actor.state.entity_id) and actor.chassis_id == &"scout_wheels" and tick >= actor.ability.smoke_ready_tick:
			_smoke(actor,tick)
	for result: Dictionary in results:
		if not result.get("died",false) and result.has("push") and not (result.push as Vector3).is_zero_approx():
			for actor: TankActor in actors:
				if actor.state.entity_id == result.target_id and actor.health.hp > 0:
					var id: int = actor.state.entity_id
					var displacement: Vector3 = result.push
					if _pushes.has(id) and int(_pushes[id].get("start_tick",-1)) == tick+1:
						displacement += _pushes[id].displacement
					displacement = displacement.limit_length(rules.shock_push)
					_pushes[id] = {"displacement":displacement,"velocity":displacement*BattleClock.TICKS_PER_SECOND/rules.push_ticks,"start_tick":tick+1,"until_tick":tick+1+rules.push_ticks}
	zones = zones.filter(func(zone: Dictionary) -> bool: return _owner_alive(zone.owner_id))
	for actor: TankActor in actors: _snapshot(actor,tick,events)
	events.publish(&"ability_zones",tick,{"zones":zones.duplicate(true),"radius":rules.smoke_radius})

func _smoke(actor: TankActor, tick: int) -> void:
	zones = zones.filter(func(zone: Dictionary) -> bool: return zone.owner_id != actor.state.entity_id)
	if zones.size() >= rules.max_smoke_zones: return
	var desired: Vector3 = actor.position-Vector3(sin(actor.state.body_yaw),0,-cos(actor.state.body_yaw))*rules.smoke_offset
	var space := actor.get_world_3d().direct_space_state
	var ray := PhysicsRayQueryParameters3D.create(actor.position+Vector3.UP*0.2,desired+Vector3.UP*0.2,1)
	if not space.intersect_ray(ray).is_empty(): desired = actor.position
	zones.append({"owner_id":actor.state.entity_id,"team_id":actor.health.team_id,"position":desired,"until_tick":tick+1+rules.smoke_ticks})
	actor.ability.smoke_ready_tick = tick+rules.smoke_cooldown

func refill(actor: TankActor) -> bool:
	if not training or not actors.has(actor) or actor.health.hp <= 0: return false
	actor.ability.energy = rules.energy_max
	return true

func clear(projectiles: ProjectileSystem) -> void:
	zones.clear()
	_pushes.clear()
	for actor: TankActor in actors:
		_release(actor,projectiles)
		actor.ability.reset_life(actor.health.life_index)
		actor.health.guard_reduction = 0.0

func _release(actor: TankActor, projectiles: ProjectileSystem) -> void:
	if actor.ability.reserved:
		projectiles.release_reservation(actor.state.entity_id)
		actor.ability.reserved = false

func _gain(state: AbilityState, amount: float) -> void:
	var gain: float = minf(amount,maxf(0.0,rules.energy_tick_cap-state.gained_this_tick))
	state.energy = minf(rules.energy_max,state.energy+gain)
	state.gained_this_tick += gain

func _owner_alive(id: int) -> bool:
	for actor: TankActor in actors:
		if actor.state.entity_id == id: return actor.health.hp > 0
	return false

func _snapshot(actor: TankActor, tick: int, events: BattleEvents) -> void:
	var state: AbilityState = actor.ability
	var ready: bool = actor.health.hp > 0 and not actor.health.protected and state.phase == &"idle" and state.energy >= rules.energy_max and tick >= state.next_use_tick
	var reason: String = "出生保护" if actor.health.protected else ("等待重建" if actor.health.hp <= 0 else ("能量不足" if state.energy < rules.energy_max else "间隔 %.1f秒" % (maxi(0,state.next_use_tick-tick)/60.0)))
	var progress: int = roundi(100.0*state.charge_ticks/(rules.cruise_charge if actor.chassis_id == &"light_tracks" else rules.guard_charge))
	events.publish(&"ability_state",tick,{"ready":ready,"reason":reason,"passive_progress":progress,"source_id":actor.state.entity_id,"position":actor.position,"yaw":actor.state.aim_yaw,"body_yaw":actor.state.body_yaw,"energy":state.energy,"energy_max":rules.energy_max,"phase":state.phase,"remaining":maxi(0,state.until_tick-tick),"ready_in":maxi(0,state.next_use_tick-tick),"cruise":state.cruise_active,"guard":state.guard_active,"charge":state.charge_ticks,"chassis":actor.chassis_id,"weapon":actor.weapon_id,"locked_yaw":state.locked_yaw,"alive":actor.health.hp>0,"smoke_in":maxi(0,state.smoke_ready_tick-tick)})
