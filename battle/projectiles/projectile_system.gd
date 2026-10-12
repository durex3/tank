extends RefCounted
class_name ProjectileSystem
## Point-projectile segment sweep; visuals have no physics authority.

const MAX_PROJECTILES: int = 128
const SHOT_HEIGHT: float = 0.78
const MUZZLE_OFFSET: float = 1.05
var active: Array[ProjectileState] = []
var hits: Array[HitEvent] = []
var impacts: Array[Dictionary] = []
var _next_id: int = 0
var reservations: Dictionary = {}

func spawn(space: PhysicsDirectSpaceState3D, origin: Vector3, yaw: float, weapon: WeaponDef, owner_id: int, request_id: int, tick: int, muzzle_yaw: float = NAN, team_id: int = 0) -> ProjectileState:
	if used_slots() >= MAX_PROJECTILES:
		return null
	_next_id += 1
	var shot := ProjectileState.new()
	shot.projectile_id = _next_id
	shot.owner_id = owner_id
	shot.team_id = team_id
	shot.request_id = request_id
	shot.spawn_tick = tick
	shot.speed = weapon.projectile_speed
	shot.remaining_range = weapon.range_m
	if weapon.projectile_kind == &"bubble_round": shot.remaining_range = maxf(0.0,weapon.range_m-MUZZLE_OFFSET)
	shot.lifetime_ticks = BattleClock.seconds_to_ticks(weapon.range_m / weapon.projectile_speed) + 1
	shot.damage = weapon.damage
	shot.radius = weapon.projectile_radius
	shot.kind = weapon.projectile_kind
	shot.slow_multiplier = weapon.slow_multiplier
	shot.slow_ticks = weapon.slow_ticks
	shot.direction = Vector3(sin(yaw), 0, -cos(yaw))
	shot.position = origin + Vector3.UP * SHOT_HEIGHT
	shot.previous_position = shot.position
	# Sweep body center to authoritative muzzle, so a barrel cannot fire through a wall.
	var barrel_yaw := yaw if is_nan(muzzle_yaw) else muzzle_yaw
	var barrel_direction := Vector3(sin(barrel_yaw), 0, -cos(barrel_yaw))
	_sweep(space, shot, shot.position + barrel_direction * MUZZLE_OFFSET)
	if shot.active:
		active.append(shot)
	return shot

func spawn_volley(space: PhysicsDirectSpaceState3D, origin: Vector3, yaw: float, offsets: PackedFloat32Array, weapon: WeaponDef, owner_id: int, request_id: int, tick: int, team_id: int = 0) -> Array[ProjectileState]:
	var shots: Array[ProjectileState] = []
	if offsets.is_empty() or used_slots() + offsets.size() > MAX_PROJECTILES:
		return shots
	for offset: float in offsets:
		if not is_finite(offset):
			return shots
	for offset: float in offsets:
		shots.append(spawn(space, origin, yaw + offset, weapon, owner_id, request_id, tick, yaw, team_id))
	return shots

func step(space: PhysicsDirectSpaceState3D, tick: int) -> void:
	for shot: ProjectileState in active:
		if shot.kind == &"bubble_barrier": continue
		shot.previous_position = shot.position
		var distance := minf(shot.speed / BattleClock.TICKS_PER_SECOND, shot.remaining_range)
		_sweep(space, shot, shot.position + shot.direction * distance)
		shot.remaining_range -= distance
		if shot.remaining_range <= 0.0 or tick - shot.spawn_tick >= shot.lifetime_ticks:
			shot.active = false
	active = active.filter(func(shot: ProjectileState) -> bool: return shot.active)

func _sweep(space: PhysicsDirectSpaceState3D, shot: ProjectileState, destination: Vector3) -> void:
	var query := PhysicsRayQueryParameters3D.create(shot.position, destination, 5)
	query.collide_with_areas = true
	query.hit_from_inside = true
	query.exclude = shot.excluded
	# Ignore friendly/corpse hurtboxes and continue to the next real obstruction.
	for iteration: int in range(128):
		var collision: Dictionary = _collision(space,query,shot.radius)
		if collision.is_empty():
			shot.position = destination
			return
		var hurtbox := collision.collider as Damageable
		if hurtbox != null and (hurtbox.state.team_id == shot.team_id or hurtbox.state.hp <= 0 or shot.hit_lives.has("%d:%d" % [hurtbox.state.entity_id,hurtbox.state.life_index])):
			var excluded: Array[RID] = query.exclude
			excluded.append(hurtbox.get_rid())
			query.exclude = excluded
			continue
		shot.position = collision.position
		shot.active = false
		impacts.append({"position": shot.position, "projectile_id": shot.projectile_id,"bubble":shot.kind == &"bubble_round"})
		if hurtbox != null:
			var hit := HitEvent.new()
			hit.projectile_id = shot.projectile_id
			hit.source_id = shot.owner_id
			hit.source_life = shot.owner_life
			hit.team_id = shot.team_id
			hit.target = hurtbox.state
			hit.target_life = hurtbox.state.life_index
			hit.damage = shot.damage
			hit.slow_multiplier = shot.slow_multiplier
			hit.slow_ticks = shot.slow_ticks
			hit.position = shot.position
			hit.direction = shot.direction
			hit.ability_damage = shot.ability_damage
			hit.travel_order = shot.hit_lives.size()
			hits.append(hit)
			if not shot.pierce_damage.is_empty():
				shot.hit_lives["%d:%d" % [hurtbox.state.entity_id,hurtbox.state.life_index]] = true
				shot.excluded.append(hurtbox.get_rid())
				if shot.hit_lives.size() < shot.pierce_damage.size():
					shot.damage = shot.pierce_damage[shot.hit_lives.size()]
					shot.active = true
					query.exclude = shot.excluded
					continue
		return
	# Exhausted overlap budget: stop, never tunnel silently.
	shot.active = false

func allocate_id() -> int:
	_next_id += 1
	return _next_id

func reserve(owner_id: int, count: int = 1) -> bool:
	if count <= 0 or reservations.has(owner_id) or used_slots()+count > MAX_PROJECTILES: return false
	reservations[owner_id] = count
	return true

func release_reservation(owner_id: int) -> void:
	reservations.erase(owner_id)

func spawn_breach(space: PhysicsDirectSpaceState3D, origin: Vector3, yaw: float, owner_id: int, team_id: int, tick: int, rules: BasicAbilityRules, owner_life: int = 0) -> ProjectileState:
	if used_slots() >= MAX_PROJECTILES: return null
	var shot := ProjectileState.new()
	shot.projectile_id = allocate_id()
	shot.owner_id = owner_id
	shot.owner_life = owner_life
	shot.team_id = team_id
	shot.spawn_tick = tick
	shot.speed = rules.breach_speed
	shot.remaining_range = maxf(0.0,rules.breach_range-MUZZLE_OFFSET)
	shot.lifetime_ticks = BattleClock.seconds_to_ticks(rules.breach_range/rules.breach_speed)+1
	shot.damage = rules.breach_damage[0]
	shot.pierce_damage = rules.breach_damage.duplicate()
	shot.ability_damage = true
	shot.radius = rules.breach_radius
	shot.direction = Vector3(sin(yaw),0,-cos(yaw))
	shot.position = origin+Vector3.UP*SHOT_HEIGHT
	shot.previous_position = shot.position
	_sweep(space,shot,shot.position+shot.direction*MUZZLE_OFFSET)
	if shot.active: active.append(shot)
	return shot

func _collision(space: PhysicsDirectSpaceState3D, ray: PhysicsRayQueryParameters3D, radius: float) -> Dictionary:
	if radius <= 0.0: return space.intersect_ray(ray)
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	query.shape = sphere
	query.transform.origin = ray.from
	query.motion = ray.to-ray.from
	query.collision_mask = ray.collision_mask
	query.collide_with_areas = true
	query.exclude = ray.exclude
	var initial: Dictionary = space.get_rest_info(query)
	if not initial.is_empty():
		return {"collider":instance_from_id(initial.collider_id),"position":initial.point}
	var fractions: PackedFloat32Array = space.cast_motion(query)
	if fractions.is_empty() or fractions[0] >= 1.0: return {}
	query.transform.origin += query.motion*minf(1.0,fractions[1]+0.0001)
	query.motion = Vector3.ZERO
	var rest: Dictionary = space.get_rest_info(query)
	if rest.is_empty(): return {}
	return {"collider":instance_from_id(rest.collider_id),"position":rest.point}

func used_slots() -> int:
	var count: int = active.size()
	for reserved: int in reservations.values(): count += reserved
	return count
