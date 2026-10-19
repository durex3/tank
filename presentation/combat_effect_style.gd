extends Resource
class_name CombatEffectStyle
## Read-only visual tuning. No collision or combat values.

@export var muzzle: Texture2D
@export var impact: Texture2D
@export var explosion: Texture2D
@export var muzzle_width_m: float = 1.25
@export var impact_width_m: float = 1.65
@export var explosion_width_m: float = 3.2
@export var muzzle_duration_s: float = 0.14
@export var impact_duration_s: float = 0.22
@export var explosion_duration_s: float = 0.48
@export var max_active: int = 32
@export var camera_offset_m: float = 0.9
