extends RefCounted
class_name AbilityState
## One independent state per entity/life; no Resource is used as runtime storage.

var energy: float = 0.0
var next_use_tick: int = 0
var last_request: int = 0
var epoch: int = -1
var life: int = -1
var phase: StringName = &"idle"
var until_tick: int = 0
var locked_yaw: float = 0.0
var charge_ticks: int = 0
var release_ticks: int = 0
var cruise_active: bool = false
var guard_active: bool = false
var smoke_ready_tick: int = 0
var reserved: bool = false
var gained_this_tick: float = 0.0

func reset_life(index: int) -> void:
	life = index
	energy = 0.0
	next_use_tick = 0
	phase = &"idle"
	until_tick = 0
	charge_ticks = 0
	release_ticks = 0
	cruise_active = false
	guard_active = false
	smoke_ready_tick = 0
	reserved = false
