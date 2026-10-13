extends Node3D
class_name TankView
## Reusable visual assembly. Chassis and turret never own authoritative state.

var weapon_id: StringName = &"cannon"
var chassis_id: StringName = &"light_tracks"
var entity_id: int = 0
var _recoil := TankRecoil.new()
var _hull := Node3D.new()
var _turret := Node3D.new()
var _muzzle: Marker3D

func _ready() -> void:
	_hull.name = "HullMount"
	_turret.name = "TurretMount"
	add_child(_hull)
	add_child(_turret)
	var error := configure_parts(weapon_id, chassis_id)
	if not error.is_empty():
		push_error(error)

func configure_parts(next_weapon: StringName, next_chassis: StringName) -> String:
	if not TankPartCatalog.WEAPONS.has(next_weapon) or not TankPartCatalog.CHASSIS.has(next_chassis):
		return "Unknown visual part ID"
	var hull: Node3D
	var turret: Node3D
	var error: String = ""
	if next_chassis != chassis_id or _hull.get_child_count() == 0:
		hull = (TankPartCatalog.CHASSIS[next_chassis] as PackedScene).instantiate() as Node3D
		error = TankPartCatalog.validate_part(hull, &"TurretSocket", Vector3(0, 0.76, 0))
	if next_weapon != weapon_id or _turret.get_child_count() == 0:
		turret = (TankPartCatalog.WEAPONS[next_weapon] as PackedScene).instantiate() as Node3D
	if error.is_empty() and turret != null:
		error = TankPartCatalog.validate_part(turret, &"Muzzle", Vector3(0, 0.02, -1.05))
	if not error.is_empty():
		if hull != null: hull.free()
		if turret != null: turret.free()
		return error
	if hull != null:
		TankSurfacePolish.apply(hull, next_chassis)
		_replace_child(_hull, hull)
		_turret.position = (hull.get_node("TurretSocket") as Marker3D).position
	if turret != null:
		_recoil.reset()
		TankSurfacePolish.apply(turret, next_weapon)
		_replace_child(_turret, turret)
		_muzzle = turret.get_node("Muzzle") as Marker3D
		_recoil.bind(turret)
	weapon_id = next_weapon
	chassis_id = next_chassis
	return ""

func present(state: TankState) -> void:
	# Mounts are siblings: body yaw must not accumulate into aim yaw.
	_hull.rotation.y = -state.body_yaw
	_turret.rotation.y = -state.aim_yaw

func muzzle_transform() -> Transform3D:
	return _muzzle.global_transform

func advance_visual_tick(tick: int) -> void:
	_recoil.advance(tick)

func reset_visual_motion() -> void:
	_recoil.reset()

func on_event(event: Dictionary) -> void:
	if event.kind == &"match_finished":
		_recoil.reset()
	elif event.kind in [&"entity_died", &"entity_respawned"] and event.get("target_id", -1) == entity_id:
		_recoil.reset()
	elif event.get("source_id", -1) == entity_id and weapon_id == &"cannon":
		if event.kind == &"weapon_fired" and event.get("weapon", &"") == &"cannon":
			_recoil.fire(event.tick)
		elif event.kind == &"ability_fired" and event.get("ability", &"") == &"breach":
			_recoil.fire(event.tick, true)

func _replace_child(mount: Node3D, part: Node) -> void:
	for old: Node in mount.get_children():
		TankSurfacePolish.clear(old)
		mount.remove_child(old)
		old.queue_free()
	mount.add_child(part)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		TankSurfacePolish.clear(self)
