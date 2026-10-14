extends RefCounted
class_name TankRecoil
## Only the separated barrel moves. Session supplies committed ticks, never wall time.

const STYLE: TankMotionStyle = preload("res://content/presentation/tank_motion.tres")
var _pivot: Node3D
var _rest: Vector3
var _axis: Vector3
var _fired_at: int = -1
var _last_fire: int = -1
var _tick: int = -1
var _distance: float = 0.0
var _weapon: StringName = &"cannon"

func bind(part: Node3D, weapon: StringName = &"cannon") -> void:
	reset()
	_weapon = weapon
	_pivot = part.find_child("RecoilPivot", true, false) as Node3D
	if _pivot == null:
		return
	_rest = _pivot.position
	var to_part := part.global_transform.affine_inverse() * (_pivot.get_parent() as Node3D).global_transform
	_axis = to_part.basis.inverse() * Vector3.BACK

func fire(tick: int, powerful: bool = false) -> void:
	if not is_instance_valid(_pivot) or tick < _tick or tick <= _last_fire:
		return
	_last_fire = tick
	_fired_at = tick
	_distance = STYLE.breach_recoil_m if powerful else STYLE.cannon_recoil_m
	if not powerful:
		match _weapon:
			&"autocannon": _distance = STYLE.autocannon_recoil_m
			&"scatter": _distance = STYLE.scatter_recoil_m
			&"bubble_cannon": _distance = STYLE.bubble_recoil_m
	advance(tick)

func advance(tick: int) -> void:
	if tick < _tick:
		return
	_tick = tick
	if not is_instance_valid(_pivot) or _fired_at < 0:
		return
	var age: int = tick - _fired_at
	var amount: float
	if age < STYLE.kick_ticks:
		amount = float(age + 1) / maxi(1, STYLE.kick_ticks)
	else:
		var progress := clampf(float(age - STYLE.kick_ticks + 1) / maxi(1, STYLE.return_ticks), 0.0, 1.0)
		amount = (1.0 - progress) * (1.0 - progress)
	_pivot.position = _rest + _axis * (_distance * amount)
	if amount <= 0.0:
		_fired_at = -1

func reset() -> void:
	if is_instance_valid(_pivot):
		_pivot.position = _rest
	_fired_at = -1
