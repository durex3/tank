extends Resource
class_name SparringRules

@export var spawn: Vector3 = Vector3(0, 0, 7)
@export var waypoints: PackedVector3Array = PackedVector3Array([Vector3(-2, 0, 7), Vector3(2, 0, 7)])
@export var speed_fraction: float = 0.3
@export var request_interval_ticks: int = 60
@export var rebuild_ticks: int = 180
@export var protection_ticks: int = 60

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if not spawn.is_finite() or spawn.y != 0.0 or waypoints.is_empty():
		errors.append("Sparring spawn/waypoints must be finite XZ points")
	for point: Vector3 in waypoints:
		if not point.is_finite() or point.y != 0.0:
			errors.append("Sparring waypoint must be on XZ")
	if not is_finite(speed_fraction) or speed_fraction <= 0.0 or speed_fraction > 1.0:
		errors.append("Invalid sparring speed fraction")
	if request_interval_ticks < 1 or rebuild_ticks < 1 or protection_ticks < 1:
		errors.append("Sparring tick settings must be positive")
	return errors
