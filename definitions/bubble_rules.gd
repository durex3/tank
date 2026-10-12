extends Resource
class_name BubbleRules
## Shared read-only geometry and timing for the bubble weapon family.

@export var charge_ticks: int = 21
@export var count: int = 5
@export var distance_m: float = 3.0
@export var spacing_m: float = 0.9
@export var radius_m: float = 0.45
@export var lifetime_ticks: int = 180
@export var damage: int = 35
@export var target_hit_limit: int = 2
@export var slow_multiplier: float = 0.85
@export var slow_ticks: int = 60
@export var arena_bounds: Rect2 = Rect2(-15.7,-11.7,31.4,23.4)

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if count != 5 or charge_ticks <= 0 or lifetime_ticks <= 0 or damage <= 0 or target_hit_limit != 2 or slow_ticks <= 0:
		errors.append("Invalid bubble count/timing/damage limits")
	for value: float in [distance_m,spacing_m,radius_m,slow_multiplier]:
		if not is_finite(value) or value <= 0.0: errors.append("Invalid bubble geometry/factor")
	if slow_multiplier < 0.6 or slow_multiplier > 1.0: errors.append("Bubble slow exceeds allowed range")
	if not arena_bounds.position.is_finite() or not arena_bounds.size.is_finite() or arena_bounds.size.x <= radius_m*2 or arena_bounds.size.y <= radius_m*2:
		errors.append("Invalid bubble arena bounds")
	return errors
