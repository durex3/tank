extends Node3D
class_name TankView
## Reusable visual assembly. Chassis and turret never own authoritative state.

var weapon_id: StringName = &"cannon"
var chassis_id: StringName = &"light_tracks"
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
	var hull := (TankPartCatalog.CHASSIS[next_chassis] as PackedScene).instantiate()
	var turret := (TankPartCatalog.WEAPONS[next_weapon] as PackedScene).instantiate()
	var error := TankPartCatalog.validate_part(hull, &"TurretSocket", Vector3(0, 0.76, 0))
	if error.is_empty():
		error = TankPartCatalog.validate_part(turret, &"Muzzle", Vector3(0, 0.02, -1.05))
	if not error.is_empty():
		hull.free()
		turret.free()
		return error
	_replace_child(_hull, hull)
	_replace_child(_turret, turret)
	_turret.position = (hull.get_node("TurretSocket") as Marker3D).position
	_muzzle = turret.get_node("Muzzle") as Marker3D
	weapon_id = next_weapon
	chassis_id = next_chassis
	return ""

func present(state: TankState) -> void:
	# Mounts are siblings: body yaw must not accumulate into aim yaw.
	_hull.rotation.y = -state.body_yaw
	_turret.rotation.y = -state.aim_yaw

func muzzle_transform() -> Transform3D:
	return _muzzle.global_transform

func _replace_child(mount: Node3D, part: Node) -> void:
	for old: Node in mount.get_children():
		mount.remove_child(old)
		old.queue_free()
	mount.add_child(part)
