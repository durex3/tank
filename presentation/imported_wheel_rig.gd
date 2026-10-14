extends TrackRig
class_name ImportedWheelRig
## Complete imported rigid wheels, centered at their axles during packaging.

const MOTION: TankMotionStyle = preload("res://content/presentation/tank_motion.tres")

func present_turn(turn: float, distance: float) -> void:
	var steer: float = clampf(-turn/maxf(absf(distance),MOTION.wheel_steer_distance_floor_m),-MOTION.wheel_steer_max_radians,MOTION.wheel_steer_max_radians)
	for wheel: Node3D in _wheels:
		wheel.rotation.y = steer if wheel.position.z < 0.0 else 0.0

func _ready() -> void:
	for node: Node in get_parent().find_children("Wheel*", "Node3D", true, false):
		if node is Node3D and str(node.name).begins_with("Wheel"):
			_wheels.append(node as Node3D)
	present_travel(Vector2.ZERO)
