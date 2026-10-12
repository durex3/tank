extends Node
class_name TankMotor
## Only the motor owns physical velocity. Called once per simulation tick.

var acceleration: float = 20.0
var _autonomous_velocity: Vector3 = Vector3.ZERO

func step(actor: CharacterBody3D, state: TankState, move: Vector2, speed: float, delta: float, forced: Vector3 = Vector3.ZERO) -> void:
	var direction := move.limit_length(1.0)
	var target := Vector3(direction.x, 0.0, direction.y) * speed
	_autonomous_velocity = _autonomous_velocity.move_toward(target, acceleration * delta)
	actor.velocity = _autonomous_velocity + forced
	actor.velocity.y = 0.0
	actor.move_and_slide()
	state.position = actor.position
	state.velocity = actor.velocity
	if forced.is_zero_approx():
		_autonomous_velocity = actor.velocity
	if state.velocity.length_squared() > 0.04:
		state.body_yaw = atan2(state.velocity.x, -state.velocity.z)

func halt(actor: CharacterBody3D, state: TankState) -> void:
	_autonomous_velocity = Vector3.ZERO
	actor.velocity = Vector3.ZERO
	state.velocity = Vector3.ZERO
