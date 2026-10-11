extends RefCounted
class_name TrainingLives
## Shared rebuild mechanics. Session injects training or frozen match timing.

var tuning: SparringRules = preload("res://content/training/sparring.tres")
var actors: Array[TankActor] = []
var _spawns: Dictionary = {}
var _protected_until: Dictionary = {}

func track(actor: TankActor, spawn: Vector3) -> void:
	if actors.has(actor):
		return
	actors.append(actor)
	_spawns[actor.state.entity_id] = spawn

func died(id: int, tick: int) -> void:
	for actor: TankActor in actors:
		if actor.state.entity_id == id:
			actor.health.respawn_tick = tick + tuning.rebuild_ticks
			actor.halt()
			actor.collision_layer = 0
			actor.collision_mask = 0

func step(tick: int, events: BattleEvents) -> void:
	for actor: TankActor in actors:
		var id := actor.state.entity_id
		if actor.health.protected and tick >= int(_protected_until.get(id, 0)):
			actor.health.protected = false
			events.publish(&"protection_changed", tick, {"target_id": id, "protected": false})
		if actor.health.hp <= 0 and actor.health.respawn_tick >= 0 and tick >= actor.health.respawn_tick:
			_rebuild(actor, tick, events)

func _rebuild(actor: TankActor, tick: int, events: BattleEvents) -> void:
	var spawn: Vector3 = _spawns[actor.state.entity_id]
	var point := safe_spawn(actor.get_world_3d().direct_space_state, spawn, [actor.get_rid()])
	if not point.is_finite():
		return
	actor.halt()
	actor.position = point
	actor.collision_layer = 2
	actor.collision_mask = 3
	actor.state.position = point
	actor.force_update_transform()
	actor.hurtbox.force_update_transform()
	actor.health.hp = actor.health.max_hp
	actor.health.life_index += 1
	actor.health.respawn_tick = -1
	actor.health.protected = true
	_protected_until[actor.state.entity_id] = tick + tuning.protection_ticks
	events.publish(&"entity_respawned", tick, {"target_id": actor.state.entity_id,
		"hp": actor.health.hp, "max_hp": actor.health.max_hp, "position": point,
		"life_index": actor.health.life_index, "protected": true})

static func safe_spawn(space: PhysicsDirectSpaceState3D, origin: Vector3, excluded: Array[RID] = []) -> Vector3:
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.6
	shape.height = 0.8
	query.shape = shape
	query.collision_mask = 3
	query.exclude = excluded
	for offset: Vector3 in [Vector3.ZERO, Vector3.RIGHT * 2.0, Vector3.LEFT * 2.0]:
		query.transform = Transform3D(Basis.IDENTITY, origin + offset + Vector3.UP * 0.42)
		if space.intersect_shape(query, 1).is_empty():
			return origin + offset
	return Vector3(INF, INF, INF)
