extends Resource
class_name WeaponVisualStyle
## Presentation-only sizes, durations and overload limits; never collision radii.

@export var cannon_radius: float = 0.15
@export var cannon_length: float = 0.58
@export var cannon_tail: float = 0.65
@export var needle_radius: float = 0.045
@export var needle_length: float = 0.44
@export var needle_tail: float = 0.34
@export var pellet_radius: float = 0.105
@export var pellet_tail: float = 0.34
@export var friendly: Color = Color("ffe2a0")
@export var enemy: Color = Color("ff7770")
@export var steel: Color = Color("554b3f")
@export var cannon_impact: Texture2D = preload("res://assets/generated/vfx/weapon-identity-v1/impact.png")
@export var impact_width: float = 1.3
@export var impact_ticks: int = 12
@export var max_bursts: int = 32
@export var max_signatures: int = 24
@export var signature_ticks: int = 24
@export var signature_width: float = 0.09
@export var breach_ring_radius: float = 0.55
@export var breach_release_radius: float = 1.4
@export var shock_height: float = 0.60
@export var storm_jet_length: float = 1.0
@export var bubble_marker_height: float = 0.45
@export var cannon_muzzle_width: float = 1.05
@export var needle_muzzle_width: float = 0.55
@export var scatter_muzzle_width: float = 1.0
@export var needle_impact_width: float = 0.65
@export var scatter_impact_width: float = 0.7
@export var needle_flash_shape: Vector3 = Vector3(0.45,1.3,1)
@export var scatter_flash_shape: Vector3 = Vector3(1.3,0.65,1)
@export var launch_blend_ticks: int = 8

@export var lightning_halo_width: float = 0.48
@export var lightning_body_width: float = 0.14
@export var lightning_core_width: float = 0.025
@export var lightning_jitter: float = 0.17
@export var lightning_step: float = 0.25
@export var cannon_glow_radius: float = 0.12
@export var cannon_glow_tail: float = 0.32

@export var energy_beam_width: float = 2.0

@export var energy_arc_radius: float = 0.32
@export var energy_arc_width: float = 0.035
@export var energy_arc_step: float = 0.14
@export var energy_arc_turns_per_m: float = 0.45

@export var energy_release_ticks: int = 14
@export var energy_peak_ticks: int = 2

@export var storm_trace_length: float = 0.9
@export var shell_radius: float = 0.12
@export var shell_length: float = 0.46
