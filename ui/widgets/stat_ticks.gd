extends Control
## Decorative ticks; input and stat values belong to parent controls.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	for index: int in range(1, 10):
		var x: float = size.x * float(index) / 10.0
		draw_line(Vector2(x, 2), Vector2(x, size.y - 2), Color(0.04, 0.12, 0.17, 0.5), 1)
