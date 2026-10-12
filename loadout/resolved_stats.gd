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
var magazine_size: int = 0
var reload_ticks: int = 0

func nominal_dps(pellet_count: int) -> float:
	if magazine_size > 0:
		return float(damage*pellet_count*magazine_size*BattleClock.TICKS_PER_SECOND)/((magazine_size-1)*interval_ticks+maxi(interval_ticks,reload_ticks))
	return float(damage * pellet_count * BattleClock.TICKS_PER_SECOND) / interval_ticks
