extends Node3D
class_name CameraRig
## Presentation-only isometric follow. Session updates after committed movement.

var tuning: CameraTuning = preload("res://content/camera/fixed_arena.tres")
var camera := Camera3D.new()
var _focus: Vector3 = Vector3.ZERO

func _ready() -> void:
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = tuning.orthographic_size
	camera.position = tuning.offset
	camera.look_at(Vector3.ZERO)
	camera.current = true

func follow(target: Vector3, delta: float) -> void:
	var desired := Vector3(clampf(target.x, -tuning.focus_bounds.x, tuning.focus_bounds.x), 0, clampf(target.z, -tuning.focus_bounds.y, tuning.focus_bounds.y))
	var overflow := desired - _focus
	if overflow.length() > tuning.cut_distance:
		_focus = desired
	elif overflow.length() > tuning.deadzone_m:
		var destination := desired - overflow.normalized() * tuning.deadzone_m
		_focus = _focus.lerp(destination, 1.0 - exp(-tuning.follow_rate * maxf(delta, 0.0)))
	position = _focus

func horizontal_right() -> Vector3:
	return camera.global_basis.x

func horizontal_forward() -> Vector3:
	return -camera.global_basis.z

func ground_point(viewport_position: Vector2) -> Vector3:
	var origin := camera.project_ray_origin(viewport_position)
	var direction := camera.project_ray_normal(viewport_position)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	return hit as Vector3 if hit != null else Vector3.ZERO
