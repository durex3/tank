extends RefCounted
class_name BubbleCurtain
## Version-two bubble field: one reserved lob, then a bounded periodic ground hazard.
var rules: BubbleRules = preload("res://content/rules/bubble.tres")
var _plans: Dictionary = {}
var _groups: Dictionary = {}

func prepare(actor: TankActor, yaw: float, projectiles: ProjectileSystem, distance_m: float = 6.0) -> String:
	assert(rules.validate().is_empty())
	var forward := Vector3(sin(yaw),0,-cos(yaw))
	var origin: Vector3 = actor.position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT
	var landing: Vector3 = actor.position+forward*clampf(distance_m,1.5,rules.max_range)+Vector3.UP*0.2
	var positions := PackedVector3Array([landing])
	if not valid_plan(actor.get_world_3d().direct_space_state,origin,positions): return "泡泡区域落点受阻"
	if not projectiles.reserve(actor.state.entity_id,1): return "弹丸预算不足"
	_plans[actor.state.entity_id] = {"origin":origin,"positions":positions,"life":actor.health.life_index}
	return ""

func valid_plan(space: PhysicsDirectSpaceState3D, origin: Vector3, positions: PackedVector3Array) -> bool:
	if positions.size() != 1: return false
	var landing: Vector3 = positions[0]
	if not landing.is_finite() or not rules.arena_bounds.grow(-rules.field_radius).has_point(Vector2(landing.x,landing.z)): return false
	# Validate the real arc, not a straight ground ray. Tall walls still block it.
	var previous: Vector3 = origin
	for i: int in range(1,25):
		var u: float = i/24.0
		var point: Vector3 = origin.lerp(landing,u)+Vector3.UP*4*rules.arc_height*u*(1-u)
		var ray := PhysicsRayQueryParameters3D.create(previous,point,1)
		if not space.intersect_ray(ray).is_empty(): return false
		previous = point
	return true

func deploy(actor: TankActor, tick: int, projectiles: ProjectileSystem, events: BattleEvents) -> bool:
	var id: int = actor.state.entity_id
	if not _plans.has(id): return false
	var plan: Dictionary = _plans[id]
	var valid: bool = actor.health.hp > 0 and actor.health.life_index == plan.life and int(projectiles.reservations.get(id,0)) == 1
	var origin: Vector3 = actor.position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT
	valid = valid and valid_plan(actor.get_world_3d().direct_space_state,origin,plan.positions)
	projectiles.release_reservation(id)
	_plans.erase(id)
	if not valid:
		events.publish(&"ability_cancelled",tick,{"source_id":id,"reason":"部署场地失效"})
		return false
	var shot := ProjectileState.new()
	shot.projectile_id = projectiles.allocate_id()
	shot.curtain_id = shot.projectile_id
	shot.kind = &"bubble_lob"
	shot.weapon_id = &"bubble_cannon"
	shot.owner_id = id
	shot.owner_life = actor.health.life_index
	shot.team_id = actor.health.team_id
	shot.spawn_tick = tick
	shot.position = origin
	shot.previous_position = origin
	shot.arc_start = origin
	shot.arc_end = plan.positions[0]
	shot.arc_ticks = rules.flight_ticks
	shot.arc_height = rules.arc_height
	shot.radius = rules.radius_m
	shot.ability_damage = true
	_groups[shot.projectile_id] = {"owner":actor,"life":actor.health.life_index,"until":tick+rules.flight_ticks+rules.lifetime_ticks,"last_hits":{},"shot":shot}
	projectiles.active.append(shot)
	events.publish(&"ability_fired",tick,{"source_id":id,"ability":&"bubble","position":origin,"projectile_id":shot.projectile_id,"end":shot.arc_end})
	return true

func step(tick: int, projectiles: ProjectileSystem, victims: Array[Damageable], space: PhysicsDirectSpaceState3D) -> void:
	prune(tick,projectiles)
	victims.sort_custom(func(a: Damageable,b: Damageable) -> bool: return a.state.entity_id < b.state.entity_id)
	for group: Dictionary in _groups.values():
		var shot: ProjectileState = group.shot
		if shot.kind == &"bubble_lob":
			var u: float = clampf(float(tick-shot.spawn_tick)/shot.arc_ticks,0,1)
			var next: Vector3 = shot.arc_start.lerp(shot.arc_end,u)+Vector3.UP*4*shot.arc_height*u*(1-u)
			var ray := PhysicsRayQueryParameters3D.create(shot.position,next,1)
			if not shot.position.is_equal_approx(next) and not space.intersect_ray(ray).is_empty():
				shot.active = false
				continue
			shot.previous_position = shot.position
			shot.position = next
			if u < 1.0: continue
			shot.kind = &"bubble_field"
			shot.radius = rules.field_radius
			shot.spawn_tick = tick
			shot.lifetime_ticks = rules.lifetime_ticks
			group.until = tick+rules.lifetime_ticks
			projectiles.impacts.append({"position":shot.position,"projectile_id":shot.projectile_id,"bubble":true,"field":true})
		for victim: Damageable in victims:
			var state: DamageableState = victim.state
			if not contains(shot,victim.global_position,state.team_id,space) or state.hp <= 0 or state.protected: continue
			var key := "%d:%d" % [state.entity_id,state.life_index]
			if tick < int(group.last_hits.get(key,-rules.pulse_ticks))+rules.pulse_ticks: continue
			group.last_hits[key] = tick
			var hit := HitEvent.new()
			hit.projectile_id = projectiles.allocate_id()
			hit.source_id = shot.owner_id
			hit.source_life = shot.owner_life
			hit.team_id = shot.team_id
			hit.target = state
			hit.target_life = state.life_index
			hit.damage = rules.damage
			hit.position = victim.global_position
			hit.direct_projectile = false
			hit.ability_damage = true
			projectiles.hits.append(hit)

func contains(shot: ProjectileState, position: Vector3, team: int, space: PhysicsDirectSpaceState3D) -> bool:
	if shot.kind != &"bubble_field" or shot.team_id == team: return false
	var offset: Vector3 = position-shot.position
	offset.y = 0.0
	if offset.length_squared() > rules.field_radius*rules.field_radius: return false
	var point := Vector3(position.x,ProjectileSystem.SHOT_HEIGHT,position.z)
	var center := Vector3(shot.position.x,ProjectileSystem.SHOT_HEIGHT,shot.position.z)
	if point.is_equal_approx(center): return true
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(center,point,1)).is_empty()

func multiplier(position: Vector3, team: int, tick: int) -> float:
	for group: Dictionary in _groups.values():
		var owner: TankActor = group.owner
		if not is_instance_valid(owner) or owner.health.hp <= 0 or owner.health.life_index != group.life or tick >= group.until: continue
		if contains(group.shot,position,team,owner.get_world_3d().direct_space_state): return rules.slow_multiplier
	return 1.0

func prune(tick: int, projectiles: ProjectileSystem) -> void:
	for id: int in _groups.keys():
		var group: Dictionary = _groups[id]
		var owner: TankActor = group.owner
		if not is_instance_valid(owner) or owner.health.hp <= 0 or owner.health.life_index != group.life or tick >= group.until or not group.shot.active: _groups.erase(id)
	projectiles.active = projectiles.active.filter(func(shot: ProjectileState) -> bool: return shot.kind not in [&"bubble_field",&"bubble_lob"] or _groups.has(shot.curtain_id))

func cancel(actor_id: int, projectiles: ProjectileSystem) -> void:
	_plans.erase(actor_id)
	projectiles.release_reservation(actor_id)

func plan_for(actor_id: int) -> PackedVector3Array:
	return _plans.get(actor_id,{}).get("positions",PackedVector3Array()).duplicate()

func clear(projectiles: ProjectileSystem) -> void:
	for id: int in _plans: projectiles.release_reservation(id)
	_plans.clear()
	_groups.clear()
	projectiles.active = projectiles.active.filter(func(shot: ProjectileState) -> bool: return shot.kind not in [&"bubble_field",&"bubble_lob"])
