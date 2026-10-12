extends RefCounted
class_name BubbleCurtain
## Frozen deployment plans and contact collection share the projectile budget.

var rules: BubbleRules = preload("res://content/rules/bubble.tres")
var _plans: Dictionary = {}
var _groups: Dictionary = {}

func prepare(actor: TankActor, yaw: float, projectiles: ProjectileSystem) -> String:
	assert(rules.validate().is_empty())
	var positions := PackedVector3Array()
	var origin: Vector3 = actor.position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT
	var forward := Vector3(sin(yaw),0,-cos(yaw))
	var right := Vector3(-forward.z,0,forward.x)
	for i: int in range(rules.count):
		positions.append(origin+forward*rules.distance_m+right*(i-(rules.count-1)*0.5)*rules.spacing_m)
	if not valid_plan(actor.get_world_3d().direct_space_state,origin,positions): return "泡泡幕部署受阻"
	if not projectiles.reserve(actor.state.entity_id,rules.count): return "弹丸预算不足"
	_plans[actor.state.entity_id] = {"origin":origin,"positions":positions,"life":actor.health.life_index}
	return ""

func valid_plan(space: PhysicsDirectSpaceState3D, origin: Vector3, positions: PackedVector3Array) -> bool:
	if positions.size() != rules.count: return false
	var sphere := SphereShape3D.new()
	sphere.radius = rules.radius_m
	var bounds: Rect2 = rules.arena_bounds.grow(-rules.radius_m)
	for p: Vector3 in positions:
		if not p.is_finite() or not bounds.has_point(Vector2(p.x,p.z)): return false
		var ray := PhysicsRayQueryParameters3D.create(origin,p,1)
		if not space.intersect_ray(ray).is_empty(): return false
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform.origin = p
		query.collision_mask = 1
		if not space.intersect_shape(query,1).is_empty(): return false
	return true

func deploy(actor: TankActor, tick: int, projectiles: ProjectileSystem, events: BattleEvents) -> bool:
	var id: int = actor.state.entity_id
	if not _plans.has(id): return false
	var plan: Dictionary = _plans[id]
	var valid: bool = actor.health.hp > 0 and actor.health.life_index == plan.life and int(projectiles.reservations.get(id,0)) == rules.count
	valid = valid and valid_plan(actor.get_world_3d().direct_space_state,plan.origin,plan.positions)
	projectiles.release_reservation(id)
	_plans.erase(id)
	if not valid:
		events.publish(&"ability_cancelled",tick,{"source_id":id,"reason":"部署场地失效"})
		return false
	var group_id: int = projectiles.allocate_id()
	_groups[group_id] = {"owner":actor,"life":actor.health.life_index,"until":tick+rules.lifetime_ticks,"hits":{}}
	for position: Vector3 in plan.positions:
		var shot := ProjectileState.new()
		shot.projectile_id = projectiles.allocate_id()
		shot.curtain_id = group_id
		shot.kind = &"bubble_barrier"
		shot.owner_id = id
		shot.owner_life = actor.health.life_index
		shot.team_id = actor.health.team_id
		shot.spawn_tick = tick
		shot.lifetime_ticks = rules.lifetime_ticks
		shot.position = position
		shot.previous_position = position
		shot.radius = rules.radius_m
		shot.damage = rules.damage
		shot.slow_multiplier = rules.slow_multiplier
		shot.slow_ticks = rules.slow_ticks
		shot.ability_damage = true
		projectiles.active.append(shot)
	events.publish(&"ability_fired",tick,{"source_id":id,"ability":&"bubble","position":plan.origin})
	return true

func step(tick: int, projectiles: ProjectileSystem, victims: Array[Damageable], space: PhysicsDirectSpaceState3D) -> void:
	prune(tick,projectiles)
	victims.sort_custom(func(a: Damageable,b: Damageable) -> bool: return a.state.entity_id < b.state.entity_id)
	for shot: ProjectileState in projectiles.active:
		if shot.kind != &"bubble_barrier": continue
		var group: Dictionary = _groups[shot.curtain_id]
		for victim: Damageable in victims:
			var state: DamageableState = victim.state
			if state.hp <= 0 or state.protected or state.team_id == shot.team_id: continue
			if int(group.hits.get(state.entity_id,0)) >= rules.target_hit_limit: continue
			var offset: Vector3 = victim.global_position-shot.position
			offset.y = 0.0
			if offset.length_squared() > pow(shot.radius+state.body_radius_m,2): continue
			var ray := PhysicsRayQueryParameters3D.create(shot.position,victim.global_position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT,1)
			if not space.intersect_ray(ray).is_empty(): continue
			var hit := HitEvent.new()
			hit.projectile_id = shot.projectile_id
			hit.source_id = shot.owner_id
			hit.source_life = shot.owner_life
			hit.team_id = shot.team_id
			hit.target = state
			hit.target_life = state.life_index
			hit.damage = shot.damage
			hit.position = shot.position
			hit.direction = offset.normalized()
			hit.direct_projectile = false
			hit.ability_damage = true
			hit.slow_multiplier = shot.slow_multiplier
			hit.slow_ticks = shot.slow_ticks
			hit.bubble_hits = int(group.hits.get(state.entity_id,0))+1
			projectiles.hits.append(hit)
			projectiles.impacts.append({"position":shot.position,"projectile_id":shot.projectile_id,"bubble":true})
			group.hits[state.entity_id] = int(group.hits.get(state.entity_id,0))+1
			shot.active = false
			break
	projectiles.active = projectiles.active.filter(func(shot: ProjectileState) -> bool: return shot.active)

func prune(tick: int, projectiles: ProjectileSystem) -> void:
	for id: int in _groups.keys():
		var group: Dictionary = _groups[id]
		var owner: TankActor = group.owner
		if not is_instance_valid(owner) or owner.health.hp <= 0 or owner.health.life_index != group.life or tick >= group.until:
			_groups.erase(id)
	projectiles.active = projectiles.active.filter(func(shot: ProjectileState) -> bool: return shot.kind != &"bubble_barrier" or _groups.has(shot.curtain_id))

func cancel(actor_id: int, projectiles: ProjectileSystem) -> void:
	_plans.erase(actor_id)
	projectiles.release_reservation(actor_id)

func plan_for(actor_id: int) -> PackedVector3Array:
	return _plans.get(actor_id,{}).get("positions",PackedVector3Array()).duplicate()

func clear(projectiles: ProjectileSystem) -> void:
	for id: int in _plans: projectiles.release_reservation(id)
	_plans.clear()
	_groups.clear()
	projectiles.active = projectiles.active.filter(func(shot: ProjectileState) -> bool: return shot.kind != &"bubble_barrier")
