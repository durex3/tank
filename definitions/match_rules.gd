extends Resource
class_name MatchRules
## Freeze a copy at match creation; changes only affect future matches.

@export var id: StringName = &"standard"
@export var duration_ticks: int = 14400
@export var target_score: int = 20
@export var respawn_ticks: int = 180
@export var protection_ticks: int = 90
@export var overtime_ticks: int = 1800
@export var team_size: int = 3
@export var friendly_fire: bool = false

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	if id == &"":
		errors.append("Match rule ID is empty")
	if duration_ticks <= 0 or target_score <= 0 or respawn_ticks <= 0 or protection_ticks <= 0 or overtime_ticks <= 0:
		errors.append("Match ticks and target score must be positive")
	if team_size < 1 or team_size > 3:
		errors.append("Supported team size is 1 to 3")
	if friendly_fire:
		errors.append("Friendly fire is unsupported")
	return errors
