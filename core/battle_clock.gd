extends RefCounted
class_name BattleClock
## Battle time is integer ticks; wall time never drives rule decisions.

const TICKS_PER_SECOND: int = 60

static func seconds_to_ticks(seconds: float) -> int:
	assert(is_finite(seconds) and seconds >= 0.0, "Invalid duration")
	return maxi(1, ceili(seconds * TICKS_PER_SECOND))
