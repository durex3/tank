extends RefCounted
class_name TrainingBotInput
## Patrol/engage intents only. World queries and combat execution are injected.

enum Mode { INACTIVE, PATROL, ENGAGE }

var tuning: SparringRules = preload("res://content/training/sparring.tres")
var mode: Mode = Mode.INACTIVE
var _waypoint: int = 0
var _sequence: int = 0
var _request: int = 0
var _next_request: int = 0

func sample(tick: int, origin: Vector3, target: Vector3, alive: bool, target_alive: bool, visible_target: bool, range_m: float) -> PlayerCommand:
	_sequence += 1
	var command := PlayerCommand.new()
	command.sequence = _sequence
	command.client_tick = tick
	if not alive or not origin.is_finite() or not target.is_finite() or not is_finite(range_m) or range_m <= 0.0:
		mode = Mode.INACTIVE
		return command
	var delta := target - origin
	var engaging := target_alive and visible_target and delta.length() <= range_m
	mode = Mode.ENGAGE if engaging else Mode.PATROL
	var destination := tuning.waypoints[_waypoint]
	if origin.distance_to(destination) < 0.3:
		_waypoint = (_waypoint + 1) % tuning.waypoints.size()
		destination = tuning.waypoints[_waypoint]
	var move := Vector2(destination.x - origin.x, destination.z - origin.z).normalized() * tuning.speed_fraction
	command.move_x = roundi(move.x * 127.0)
	command.move_z = roundi(move.y * 127.0)
	command.aim_distance_cm = clampi(roundi(delta.length()*100),150,1600)
	command.aim_yaw = roundi(fposmod(atan2(delta.x, -delta.z), TAU) / TAU * 65536.0) % 65536
	if engaging and tick >= _next_request:
		_request += 1
		command.fire_request_id = _request
		_next_request = tick + tuning.request_interval_ticks
	return command

func reset(tick: int) -> void:
	mode = Mode.INACTIVE
	_next_request = tick + tuning.request_interval_ticks
