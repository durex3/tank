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
