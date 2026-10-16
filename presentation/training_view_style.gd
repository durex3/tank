extends Resource
class_name TrainingViewStyle
## Presentation-only clarity settings; no collision or skill range changes.

@export var render_size: Vector2i = Vector2i(1920, 1080)
@export var msaa: Viewport.MSAA = Viewport.MSAA_4X
@export var key_energy: float = 0.48
@export var ambient_energy: float = 0.28
@export var ambient_color: Color = Color("c2ccd8")
@export var background_color: Color = Color("8caabd")

@export var target_chassis: Array[StringName] = [&"light_tracks",&"scout_wheels",&"heavy_tracks"]
@export var target_captions: PackedStringArray = PackedStringArray(["轻型训练靶","中型训练靶","重型训练靶"])

@export var key_rotation: Vector3 = Vector3(-48, -32, 0)
@export var key_color: Color = Color("fff3df")
@export var shadow_distance: float = 24.0
@export_range(0.0, 4.0) var shadow_normal_bias: float = 0.0
@export var tile_color_a: Color = Color("b6b1a5")
@export var tile_color_b: Color = Color("b9b4a8")
@export_range(0.0, 4.0) var shadow_blur: float = 2.0

@export var fill_energy: float = 0.18
@export var fill_color: Color = Color("c6d8ed")
@export var fill_rotation: Vector3 = Vector3(-25, 115, 0)
