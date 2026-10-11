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

func spawn(space: PhysicsDirectSpaceState3D, origin: Vector3, yaw: float, weapon: WeaponDef, owner_id: int, request_id: int, tick: int, muzzle_yaw: float = NAN, team_id: int = 0) -> ProjectileState:
	if active.size() >= MAX_PROJECTILES:
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
	shot.lifetime_ticks = BattleClock.seconds_to_ticks(weapon.range_m / weapon.projectile_speed) + 1
	shot.damage = weapon.damage
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
	if offsets.is_empty() or active.size() + offsets.size() > MAX_PROJECTILES:
		return shots
	for offset: float in offsets:
		if not is_finite(offset):
			return shots
	for offset: float in offsets:
		shots.append(spawn(space, origin, yaw + offset, weapon, owner_id, request_id, tick, yaw, team_id))
	return shots

func step(space: PhysicsDirectSpaceState3D, tick: int) -> void:
	for shot: ProjectileState in active:
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
	# Ignore friendly/corpse hurtboxes and continue to the next real obstruction.
	for iteration: int in range(128):
		var collision := space.intersect_ray(query)
		if collision.is_empty():
			shot.position = destination
			return
		var hurtbox := collision.collider as Damageable
		if hurtbox != null and (hurtbox.state.team_id == shot.team_id or hurtbox.state.hp <= 0):
			var excluded: Array[RID] = query.exclude
			excluded.append(hurtbox.get_rid())
			query.exclude = excluded
			continue
		shot.position = collision.position
		shot.active = false
		impacts.append({"position": shot.position, "projectile_id": shot.projectile_id})
		if hurtbox != null:
			var hit := HitEvent.new()
			hit.projectile_id = shot.projectile_id
			hit.source_id = shot.owner_id
			hit.team_id = shot.team_id
			hit.target = hurtbox.state
			hit.target_life = hurtbox.state.life_index
			hit.damage = shot.damage
			hit.position = shot.position
			hits.append(hit)
		return
	# Exhausted overlap budget: stop, never tunnel silently.
	shot.active = false
