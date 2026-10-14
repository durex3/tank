extends TrackRig
class_name ImportedWheelRig
## Complete imported rigid wheels, centered at their axles during packaging.

func _ready() -> void:
	for node: Node in get_parent().find_children("Wheel*", "Node3D", true, false):
		if node is Node3D and str(node.name).begins_with("Wheel"):
			_wheels.append(node as Node3D)
	present_travel(Vector2.ZERO)
