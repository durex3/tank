extends RefCounted
class_name PlanarInput
## Camera basis is supplied as plain vectors, never as a scene dependency.

static func to_world(screen: Vector2, right: Vector3, forward: Vector3) -> Vector2:
	var r := Vector3(right.x, 0.0, right.z).normalized()
	var f := Vector3(forward.x, 0.0, forward.z).normalized()
	var world := r * screen.x - f * screen.y
	return Vector2(world.x, world.z).limit_length(1.0)

static func map_command(command: PlayerCommand, right: Vector3, forward: Vector3) -> PlayerCommand:
	var move := to_world(Vector2(command.move_x, command.move_z) / 127.0, right, forward)
	command.move_x = roundi(move.x * 127.0)
	command.move_z = roundi(move.y * 127.0)
	var yaw := float(command.aim_yaw) / 65536.0 * TAU
	var aim := to_world(Vector2(sin(yaw), -cos(yaw)), right, forward)
	command.aim_yaw = roundi(fposmod(atan2(aim.x, -aim.y), TAU) / TAU * 65536.0) % 65536
	return command
