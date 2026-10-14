extends Node3D
class_name TankView
## Reusable visual assembly. Chassis and turret never own authoritative state.

var weapon_id: StringName = &"cannon"
var chassis_id: StringName = &"light_tracks"
var entity_id: int = 0
var _recoil := TankRecoil.new()
var _right_recoil := TankRecoil.new()
var _active_barrel: int = 0
var _next_barrel: int = 0
var _last_visual_fire: int = -1
var _tracks := TankTracks.new()
var _present_position: Vector3
var _present_yaw: float = 0.0
var _hull := Node3D.new()
var _turret := Node3D.new()
var _muzzle: Marker3D

func _ready() -> void:
	_hull.name = "HullMount"
	_turret.name = "TurretMount"
	add_child(_hull)
	add_child(_turret)
	_add_contact_shadow()
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
		_tracks.bind(hull)
		_turret.position = (hull.get_node("TurretSocket") as Marker3D).position
	if turret != null:
		_recoil.reset()
		TankSurfacePolish.apply(turret, next_weapon)
		_replace_child(_turret, turret)
		_muzzle = turret.get_node("Muzzle") as Marker3D
		_recoil.bind(turret, next_weapon)
		_right_recoil.bind(turret,next_weapon,"RecoilPivotRight")
		_active_barrel = 0
		_next_barrel = 0
	weapon_id = next_weapon
	chassis_id = next_chassis
	return ""

func present(state: TankState) -> void:
	_present_position = state.position
	_present_yaw = state.body_yaw
	# Mounts are siblings: body yaw must not accumulate into aim yaw.
	_hull.rotation.y = -state.body_yaw
	_turret.rotation.y = -state.aim_yaw

func muzzle_transform() -> Transform3D:
	return _muzzle.global_transform

func active_barrel_index() -> int:
	return _active_barrel

func visual_muzzle_position() -> Vector3:
	var marker_name: String = "VisualMuzzleRight" if weapon_id == &"autocannon" and _active_barrel == 1 else "VisualMuzzle"
	var marker := _turret.find_child(marker_name, true, false) as Node3D
	return marker.global_position if marker != null else _muzzle.global_position

func advance_visual_tick(tick: int) -> void:
	_recoil.advance(tick)
	_right_recoil.advance(tick)
	_tracks.sample(_present_position, _present_yaw, tick)

func reset_visual_motion() -> void:
	_recoil.reset()
	_right_recoil.reset()
	_active_barrel = 0
	_next_barrel = 0
	_tracks.reset()

func on_event(event: Dictionary) -> void:
	if event.kind == &"match_finished":
		reset_visual_motion()
	elif event.kind in [&"entity_died", &"entity_respawned"] and event.get("target_id", -1) == entity_id:
		reset_visual_motion()
	elif event.get("source_id", -1) == entity_id:
		if event.kind == &"weapon_fired" and event.get("weapon", &"") == weapon_id:
			if event.tick <= _last_visual_fire: return
			_last_visual_fire = event.tick
			_active_barrel = _next_barrel if weapon_id == &"autocannon" else 0
			_next_barrel = 1-_active_barrel
			if _active_barrel == 1: _right_recoil.fire(event.tick)
			else: _recoil.fire(event.tick)
		elif weapon_id == &"cannon" and event.kind == &"ability_fired" and event.get("ability", &"") == &"breach":
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

func _add_contact_shadow() -> void:
	var shadow := MeshInstance3D.new()
	shadow.name = "ContactShadow"
	var plane := PlaneMesh.new()
	plane.size = TankSurfacePolish.STYLE.contact_shadow_size
	shadow.mesh = plane
	shadow.position.y = 0.025
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = preload("res://presentation/shaders/contact_shadow.gdshader")
	material.set_shader_parameter("opacity", TankSurfacePolish.STYLE.contact_shadow_opacity)
	shadow.material_override = material
	add_child(shadow)
