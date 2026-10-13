extends Resource
class_name HangarPreviewStyle
## Display-only quality budget, independent from battle rendering.

@export_range(1.0, 2.0, 0.1) var render_scale: float = 1.5
@export var max_render_edge: int = 2048
@export var msaa: Viewport.MSAA = Viewport.MSAA_4X
@export_range(2.5, 5.0, 0.1) var camera_size: float = 2.9
@export var key_energy: float = 1.25
@export var fill_energy: float = 0.35
@export var rim_energy: float = 0.55
@export var ambient_energy: float = 0.34
@export var background_color: Color = Color("252632")
@export var platform_color: Color = Color("383b48")
@export var camera_position: Vector3 = Vector3(-3, 2.7, -4)
@export var initial_yaw: float = -0.25
