extends Control
class_name HangarCardMark
## Vector status marks keep their shape and alignment across system fonts.

var upgrade: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var center := size * 0.5
	var radius: float = size.x * 0.5 - 1.0
	if upgrade:
		var green := Color("57e5aa")
		draw_circle(center, radius, Color("17352e"))
		draw_arc(center, radius, 0, TAU, 48, Color("378369"), 1.0, true)
		draw_line(center + Vector2(0, 5), center + Vector2(0, -5), green, 1.8, true)
		draw_polyline(PackedVector2Array([center + Vector2(-4, -1), center + Vector2(0, -5), center + Vector2(4, -1)]), green, 1.8, true)
	else:
		draw_circle(center, radius, Color("f4f5f8"))
		draw_polyline(PackedVector2Array([center + Vector2(-4.5, 0), center + Vector2(-1.5, 3), center + Vector2(4.5, -3.5)]), Color("242333"), 1.8, true)
