extends Control
class_name TrainingToolbarIcon
## Small vector glyphs, independent of platform font coverage.

var symbol: StringName = &"pause"

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var center := size * 0.5
	var ink := Color("eaf2f5")
	match symbol:
		&"back":
			draw_polyline(PackedVector2Array([center+Vector2(4,-9),center+Vector2(-5,0),center+Vector2(4,9)]),ink,3,true)
		&"pause":
			for x: float in [-6,3]: draw_style_box(HangarStyle.panel(ink,ink,2),Rect2(center+Vector2(x,-9),Vector2(4,18)))
		&"stats":
			for i: int in range(3): draw_rect(Rect2(center+Vector2(-10+i*8,8-(i+1)*6),Vector2(5,(i+1)*6)),ink)
		&"touch":
			draw_arc(center,10,0,TAU,24,ink,2,true)
			draw_circle(center,3,ink)
