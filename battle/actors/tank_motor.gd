extends Node
class_name TankMotor
## Only the motor owns physical velocity. Called once per simulation tick.

var acceleration: float = 20.0

func step(actor: CharacterBody3D, state: TankState, move: Vector2, speed: float, delta: float) -> void:
	var direction := move.limit_length(1.0)
	var target := Vector3(direction.x, 0.0, direction.y) * speed
	actor.velocity = actor.velocity.move_toward(target, acceleration * delta)
	actor.velocity.y = 0.0
	actor.move_and_slide()
	state.position = actor.position
	state.velocity = actor.velocity
	if state.velocity.length_squared() > 0.04:
		state.body_yaw = atan2(state.velocity.x, -state.velocity.z)

func halt(actor: CharacterBody3D, state: TankState) -> void:
	actor.velocity = Vector3.ZERO
	state.velocity = Vector3.ZERO
