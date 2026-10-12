extends Resource
class_name HangarCompositionStyle
## Image-space assembly anchors, never authoritative tank sockets.

@export var canvas_size: int = 1024
@export var chassis_width: int = 880
@export var turret_width: int = 420
@export var chassis_bottom: int = 950
@export var turret_base_cuts: Dictionary = {&"cannon": 0.93, &"autocannon": 0.86, &"scatter": 0.82}
@export var turret_base_feather: float = 0.015
@export var contact_shadow_radius: Vector2 = Vector2(112, 26)
@export var contact_shadow_offset: Vector2 = Vector2(0, 7)
@export var contact_shadow_opacity: float = 0.40
@export var chassis_mounts: Dictionary = {
	&"light_tracks": Vector2(0.53, 0.30),
	&"heavy_tracks": Vector2(0.49, 0.30),
	&"scout_wheels": Vector2(0.49, 0.33),
}
@export var turret_mounts: Dictionary = {
	&"cannon": Vector2(0.57, 0.89),
	&"autocannon": Vector2(0.62, 0.83),
	&"scatter": Vector2(0.56, 0.79),
}
