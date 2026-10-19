extends Control
class_name TrainingTouchOverlay
## Dedicated canvas layer above the world viewport, below pause/result overlays.

var state: TouchInputState
var centers: Array[Vector2] = []

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if state == null or centers.size() != 3: return
	var sticks: Array[Vector2] = [state.move_vector,state.aim_drag,state.ability_drag]
	for slot: int in range(3):
		var color := Color("55cfd5") if slot == 0 else Color("e9ba65")
		draw_circle(centers[slot],64,Color(0.06,0.10,0.14,0.55))
		draw_arc(centers[slot],64,0,TAU,48,color,2,true)
		draw_circle(centers[slot]+sticks[slot]*64,18,color)
