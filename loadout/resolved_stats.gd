extends RefCounted
class_name ResolvedStats
## Fresh per-resolution value; never shares mutable actor state.

var max_hp: int
var move_speed: float
var damage: int
var interval_ticks: int
var weight: int
var overload: int
var ability_id: StringName
var passive_id: StringName

func nominal_dps(pellet_count: int) -> float:
	return float(damage * pellet_count * BattleClock.TICKS_PER_SECOND) / interval_ticks
