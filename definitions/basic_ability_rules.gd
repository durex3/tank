extends Resource
class_name BasicAbilityRules
## Shared immutable tuning; all time values are simulation ticks.

@export var energy_max: float = 100.0
@export var energy_per_tick: float = 0.05
@export var damage_per_energy: float = 10.0
@export var energy_tick_cap: float = 5.0
@export var minimum_interval: int = 480
@export var reload_bonus: float = 0.25
@export var reload_min_speed: float = 0.6
@export var dash_distance: float = 4.5
@export var dash_speed: float = 12.0
@export var dash_damage: int = 80
@export var cruise_charge: int = 90
@export var cruise_release: int = 12
@export var cruise_threshold: float = 0.5
@export var cruise_multiplier: float = 1.25
@export var guard_charge: int = 36
@export var guard_half_angle: float = 60.0
@export var guard_reduction: float = 0.30
@export var escape_ticks: int = 90
@export var escape_multiplier: float = 1.25
@export var smoke_radius: float = 1.6
@export var smoke_ticks: int = 150
@export var smoke_cooldown: int = 600
@export var smoke_multiplier: float = 0.65
@export var smoke_offset: float = 0.6
@export var max_smoke_zones: int = 16
@export var breach_charge: int = 27
@export var breach_speed_multiplier: float = 0.6
@export var breach_damage: PackedInt32Array = PackedInt32Array([240,144,86])
@export var breach_speed: float = 40.0
@export var breach_range: float = 16.0
@export var breach_radius: float = 0.10
@export var storm_damage_multiplier: float = 0.6
@export var storm_ticks: int = 180
@export var storm_interval: int = 3
@export var storm_cooldown: int = 90
@export var shock_charge: int = 15
@export var shock_half_angle: float = 35.0
@export var shock_range: float = 4.5
@export var shock_damage: int = 150
@export var shock_push: float = 1.2
@export var push_ticks: int = 12

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for field: Dictionary in get_property_list():
		if (int(field.usage)&PROPERTY_USAGE_SCRIPT_VARIABLE) == 0: continue
		if field.type in [TYPE_FLOAT,TYPE_INT]:
			var value: float = float(get(field.name))
			if not is_finite(value) or value <= 0.0: errors.append("Invalid ability tuning: "+str(field.name))
	if guard_half_angle >= 90.0 or shock_half_angle >= 90.0: errors.append("Ability cone must face forward")
	if reload_bonus > 1.0 or storm_damage_multiplier > 1.0 or guard_reduction >= 1.0 or smoke_multiplier > 1.0 or breach_speed_multiplier > 1.0 or cruise_threshold > 1.0: errors.append("Invalid ability factor")
	if breach_damage.size() != 3: errors.append("Breach requires three explicit damage steps")
	for value: int in breach_damage:
		if value <= 0: errors.append("Invalid breach damage")
	return errors
