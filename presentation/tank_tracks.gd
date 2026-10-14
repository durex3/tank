extends RefCounted
class_name TankTracks
## Cosmetic motion from committed displacement; no Input, timers or velocity writes.

const STYLE: TankMotionStyle = preload("res://content/presentation/tank_motion.tres")
var _wheels: Array[Node3D] = []
var _materials: Array[ShaderMaterial] = []
var _sides: Array[float] = []
var _travel: Vector2 = Vector2.ZERO
var _position: Vector3
var _yaw: float = 0.0
var _tick: int = -1
var _has_sample: bool = false
var _rig: TrackRig

func bind(part: Node3D) -> void:
	_wheels.clear()
	_materials.clear()
	_sides.clear()
	_rig = part.find_child("TrackRig", true, false) as TrackRig
	for node: Node in part.find_children("Wheel*", "Node3D", true, false):
		_wheels.append(node as Node3D)
	for name: String in ["TrackLeft", "TrackRight"]:
		var mesh := part.find_child(name, true, false) as MeshInstance3D
		if mesh == null:
			continue
		var material := mesh.get_surface_override_material(0) as ShaderMaterial
		if material != null:
			material.set_shader_parameter("rolling_track", true)
			_materials.append(material)
			_sides.append(-1.0 if name == "TrackRight" else 1.0)
	reset()

func reset() -> void:
	_travel = Vector2.ZERO
	_has_sample = false
	for wheel: Node3D in _wheels:
		if is_instance_valid(wheel): wheel.rotation.x = 0.0
	for material: ShaderMaterial in _materials:
		material.set_shader_parameter("track_travel", 0.0)
	if is_instance_valid(_rig): _rig.present_travel(Vector2.ZERO)

func sample(position: Vector3, yaw: float, tick: int) -> void:
	if tick <= _tick:
		return
	_tick = tick
	if not _has_sample:
		_position = position
		_yaw = yaw
		_has_sample = true
		return
	var displacement := position - _position
	var turn := angle_difference(_yaw, yaw)
	var midpoint := _yaw + turn * 0.5
	_position = position
	_yaw = yaw
	if displacement.length() > STYLE.visual_teleport_limit_m:
		reset()
		return
	var distance := displacement.dot(Vector3(sin(midpoint), 0, -cos(midpoint)))
	var half_width: float = _rig.style.axle_x if is_instance_valid(_rig) else STYLE.track_half_width_m
	_travel += Vector2(distance + turn * half_width, distance - turn * half_width)
	if is_instance_valid(_rig):
		_rig.present_travel(_travel)
		return
	for wheel: Node3D in _wheels:
		var amount: float = _travel.x if str(wheel.name).begins_with("WheelRight") else _travel.y
		wheel.rotation.x = wrapf(-amount / STYLE.wheel_radius_m, -PI, PI)
	for i: int in range(_materials.size()):
		var amount: float = _travel.x if _sides[i] < 0 else _travel.y
		_materials[i].set_shader_parameter("track_travel", fposmod(amount / STYLE.track_source_scale, TAU / 90.0))
