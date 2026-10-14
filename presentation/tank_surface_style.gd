extends Resource
class_name TankSurfaceStyle
## Read-only sample finish. Applied to per-instance materials, never imported assets.

@export_range(0.0, 1.0) var cleanup_strength: float = 0.45
@export_range(0.0, 1.0) var normal_strength: float = 0.45
@export var armor_color: Color = Color("ebe8d9")

@export_range(0.0, 1.0) var speckle_cleanup: float = 0.75
@export var contact_shadow_size: Vector2 = Vector2(1.85, 2.15)
@export_range(0.0, 1.0) var contact_shadow_opacity: float = 0.30
@export var team_ring_width: float = 0.025
@export var team_ring_opacity: float = 0.60
