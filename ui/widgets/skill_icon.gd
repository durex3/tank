extends Control
## Resolution-independent symbols for chassis passives and turret ultimates.
var active: bool = false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
func _draw() -> void:
	var origin := (size - Vector2(40, 40)) * 0.5
	draw_set_transform(origin)
	if active:
		draw_colored_polygon(PackedVector2Array([Vector2(23,2), Vector2(7,24), Vector2(18,24), Vector2(14,38), Vector2(33,15), Vector2(22,15)]), HangarStyle.ACCENT)
	else:
		draw_style_box(HangarStyle.panel(Color("1c1828"), Color.TRANSPARENT, 8), Rect2(-3,-3,46,46))
		draw_rect(Rect2(6,18,6,18), Color.WHITE)
		draw_rect(Rect2(28,18,6,18), Color.WHITE)
		draw_rect(Rect2(13,20,14,11), Color.WHITE)
		draw_rect(Rect2(16,12,8,7), Color.WHITE)
		draw_rect(Rect2(19,3,3,12), Color.WHITE)
