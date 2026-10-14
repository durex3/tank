extends RefCounted
class_name PlayerCommand
## Input intent only. Damage and HP never enter this contract.

var session_epoch: int = 0
var sequence: int = 0
var client_tick: int = 0
var move_x: int = 0
var move_z: int = 0
var turn_preference: int = 0
var aim_yaw: int = 0
var fire_held: bool = false
var fire_request_id: int = 0
var ability_request_id: int = 0

func is_valid() -> bool:
	return (session_epoch >= 0 and sequence >= 0 and client_tick >= 0
		and absi(move_x) <= 127 and absi(move_z) <= 127
		and absi(turn_preference) <= 1
		and aim_yaw >= 0 and aim_yaw <= 65535
		and fire_request_id >= 0 and ability_request_id >= 0)
