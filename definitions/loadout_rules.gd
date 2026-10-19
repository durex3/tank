extends Resource
class_name LoadoutRules
## Shared weight policy. Definitions are read-only at runtime.

@export var maximum_overload: int = 1
@export var speed_penalty_per_overload: float = 0.2
@export var minimum_speed_ratio: float = 0.6
