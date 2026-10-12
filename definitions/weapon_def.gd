extends Resource
class_name WeaponDef
## Immutable content. Mutable cooldowns belong to per-actor state.

@export var id: StringName
@export var damage: int = 120
@export var fire_interval_s: float = 0.8
@export var range_m: float = 14.0
@export var projectile_speed: float = 24.0
@export var continuous_fire: bool = false
@export var pellet_count: int = 1
@export var spread_deg: float = 0.0
@export var weight: int = 2
@export var ability_id: StringName = &"pierce_shot"

@export var magazine_size: int = 0
@export var reload_s: float = 0.0
@export var projectile_radius: float = 0.0
@export var projectile_kind: StringName = &"normal"
@export var slow_multiplier: float = 1.0
@export var slow_ticks: int = 0

func nominal_dps() -> float:
	return float(damage * pellet_count) / fire_interval_s
