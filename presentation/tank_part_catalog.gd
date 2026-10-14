extends RefCounted
class_name TankPartCatalog
## Visual mapping lives outside immutable gameplay definitions.

const WEAPONS: Dictionary = {
	&"cannon": preload("res://presentation/parts/proportion_v1/cannon.tscn"),
	&"autocannon": preload("res://presentation/parts/proportion_v1/autocannon.tscn"),
	&"scatter": preload("res://presentation/parts/proportion_v1/scatter.tscn"),
	&"bubble_cannon": preload("res://presentation/parts/proportion_v1/bubble_cannon.tscn"),
}
const CHASSIS: Dictionary = {
	&"light_tracks": preload("res://presentation/parts/proportion_v1/light_tracks.tscn"),
	&"scout_wheels": preload("res://presentation/parts/proportion_v1/scout_wheels.tscn"),
	&"heavy_tracks": preload("res://presentation/parts/proportion_v1/heavy_tracks.tscn"),
}

static func validate_part(part: Node, socket_name: StringName, expected: Vector3) -> String:
	if part is CollisionObject3D:
		return "Visual part root cannot own combat collision"
	if not part is Node3D:
		return "Part root must be Node3D"
	var socket := part.get_node_or_null(NodePath(socket_name)) as Marker3D
	if socket == null:
		return "Missing Marker3D: " + socket_name
	if not socket.basis.is_equal_approx(Basis.IDENTITY):
		return "Socket basis must be identity: " + socket_name
	if not socket.position.is_equal_approx(expected):
		return "Socket position does not match combat contract: " + socket_name
	if not (part as Node3D).transform.is_equal_approx(Transform3D.IDENTITY):
		return "Part root transform must be identity"
	for child: Node in part.find_children("*", "", true, false):
		if child is CollisionObject3D or child is CollisionShape3D:
			return "Visual parts cannot own combat collision"
	return ""
