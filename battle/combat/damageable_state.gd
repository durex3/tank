extends RefCounted
class_name DamageableState

var entity_id: int = 0
var life_index: int = 0
var team_id: int = 1
var max_hp: int = 350
var hp: int = 350
var protected: bool = false
var is_training: bool = true
var respawn_tick: int = -1

var guard_reduction: float = 0.0
var guard_yaw: float = 0.0
var guard_half_angle: float = 60.0
