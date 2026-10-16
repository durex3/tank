extends Node
class_name TankMotor
## Only the motor owns physical velocity. Called once per simulation tick.

var acceleration: float = 20.0
var steering: TankSteeringRules = preload("res://content/rules/tank_steering.tres")
var _autonomous_velocity: Vector3 = Vector3.ZERO
var _turn_sign: float = 1.0

func step(actor: CharacterBody3D, state: TankState, move: Vector2, speed: float, delta: float, forced: Vector3 = Vector3.ZERO, turn_preference: int = 0, exclusive: bool = false) -> void:
	if exclusive:
		_autonomous_velocity = Vector3.ZERO
		_turn(state,forced,delta,turn_preference)
		actor.velocity = forced
		actor.move_and_slide()
		state.position = actor.position
		state.velocity = actor.velocity
		return
	var direction := move.limit_length(1.0)
	var target := Vector3(direction.x, 0.0, direction.y) * speed
	_turn(state,target,delta,turn_preference)
	if not target.is_zero_approx():
		var desired_heading: float = atan2(target.x,-target.z)
		var alignment: float = maxf(0.0,cos(angle_difference(state.body_yaw,desired_heading)))
		target *= lerpf(steering.minimum_turn_speed_ratio,1.0,pow(alignment,steering.alignment_power))
	var braking: bool = _autonomous_velocity.length() > target.length() or _autonomous_velocity.dot(target) < 0.0
	var response: float = maxf(acceleration,steering.turn_braking_acceleration) if braking else acceleration
	_autonomous_velocity = _autonomous_velocity.move_toward(target, response * delta)
	actor.velocity = _autonomous_velocity + forced
	actor.velocity.y = 0.0
	actor.move_and_slide()
	state.position = actor.position
	state.velocity = actor.velocity
	if forced.is_zero_approx():
		_autonomous_velocity = actor.velocity

func _turn(state: TankState, target: Vector3, delta: float, turn_preference: int) -> void:
	if target.length_squared() > 0.04:
		var heading: float = atan2(target.x,-target.z)
		var difference: float = angle_difference(state.body_yaw,heading)
		if absf(absf(difference)-PI) <= steering.opposite_epsilon_radians:
			difference = PI*(float(turn_preference) if turn_preference != 0 else _turn_sign)
		if absf(difference) > steering.opposite_epsilon_radians: _turn_sign = signf(difference)
		var amount: float = steering.turn_rate_radians*delta
		state.body_yaw = wrapf(state.body_yaw+clampf(difference,-amount,amount),-PI,PI)

func halt(actor: CharacterBody3D, state: TankState) -> void:
	_autonomous_velocity = Vector3.ZERO
	_turn_sign = 1.0
	actor.velocity = Vector3.ZERO
	state.velocity = Vector3.ZERO
