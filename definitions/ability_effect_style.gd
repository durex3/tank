extends Resource
class_name AbilityEffectStyle

@export var cruise_color: Color = Color("43e6ec")
@export var guard_color: Color = Color("74baff")
@export var smoke_color: Color = Color(0.46,0.72,0.68,0.24)
@export var breach_color: Color = Color("ac2337")
@export var storm_color: Color = Color("ffab51")
@export var shock_color: Color = Color("eeabff")
@export var ground_height: float = 0.07
@export var line_width: float = 0.06
@export var shock_visual_ticks: int = 18
@export var trail_length: float = 1.8
@export var smoke: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_smoke-1.png")
@export var muzzle: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_flash-0.png")
@export var impact: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_flash-1.png")
@export var shockwave: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_smoke-0.png")
@export var muzzle_ticks: int = 6
@export var impact_ticks: int = 10
@export var max_sprites: int = 48
@export var smoke_opacity: float = 0.40

@export var muzzle_width_m: float = 0.75
@export var impact_width_m: float = 0.95
@export var breach_muzzle_width_m: float = 1.3
@export var smoke_art_scale: float = 2.2
@export var smoke_height_m: float = 0.85
@export var guard_radius_m: float = 1.45
@export var guard_height_m: float = 1.0

@export var charge_core_m: float = 0.38
@export var charge_ray_m: float = 0.65
@export var guard_hit_ticks: int = 18
@export var guard_spark_width_m: float = 1.1
@export var guard_label_ticks: int = 30
@export var max_labels: int = 8
@export var storm_muzzle_width_m: float = 1.65
@export var storm_muzzle_ticks: int = 8
@export var smoke_layers: int = 3
@export var smoke_layer_spread_m: float = 0.55
@export var smoke_rise_m: float = 0.22
@export var smoke_fade_ticks: int = 24
@export var max_smoke_sprites: int = 48
@export var breach_core_width_m: float = 0.13
@export var breach_trail_m: float = 1.8

@export var art_camera_offset_m: float = 0.14
@export var storm_ring_radius_m: float = 1.2
@export var vent_height_m: float = 1.0
@export var vent_length_m: float = 0.4

@export var cooling_color: Color = Color("ff5533")
@export var storm_ring_height_m: float = 0.12
@export var storm_ring_width_m: float = 0.18
@export var storm_segments: int = 24
@export var storm_rail_offset_m: float = 0.38
@export var storm_rail_length_m: float = 1.25

@export var storm_core_width_m: float = 0.10
@export var storm_trail_m: float = 0.65

@export var heat_smoke_width_m: float = 0.8
@export var heat_smoke_rise_m: float = 0.75
@export var heat_smoke_opacity: float = 0.5

@export var escape_color: Color = Color("7ef5bf")
@export var escape_arrow_span_m: float = 0.9
@export var escape_arrow_spacing_m: float = 0.32

@export var bubble_color: Color = Color("56e5ed")
@export var bubble_enemy_color: Color = Color("ff9acd")
@export var bubble_opacity: float = 0.42
@export var bubble_plan_radius_m: float = 0.45
@export var bubble_pop_s: float = 0.22
@export var bubble_fade_ticks: int = 18
@export var bubble_outline_width_m: float = 0.035

@export var bubble_film: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_drop-2.png")
@export var bubble_splash: Texture2D = preload("res://assets/generated/vfx/toon-fx-v1/toon_drop-0.png")
@export var bubble_texture_fill: float = 0.86
@export var bubble_ground_opacity: float = 0.25
@export var bubble_enemy_tint: Color = Color(1,0.65,0.75,1)
@export var bubble_bob_m: float = 0.045
@export var bubble_bob_rate: float = 0.10
@export var bubble_wobble: float = 0.035
@export var bubble_start_scale: float = 0.78
@export var bubble_expand_ticks: int = 6
@export var bubble_trail_ratio: float = 0.7
@export var bubble_trail_distance_m: float = 0.30
@export var bubble_pop_ticks: int = 14
@export var bubble_pop_width_m: float = 1.35
@export var bubble_muzzle_ticks: int = 8
@export var bubble_muzzle_width_m: float = 0.5
@export var bubble_max_bursts: int = 24
