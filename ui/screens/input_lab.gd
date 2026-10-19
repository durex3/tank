extends Control
## Diagnostic screen: reads commands without applying combat state.

signal back_requested

var _source := TouchInputSource.new()
var _status := Label.new()
var _tick: int = 0
var _shots: int = 0
var _skills: int = 0
var _centers: Array[Vector2] = []

func _ready() -> void:
	add_child(_source)
	_source.state_changed.connect(queue_redraw)
	var column := VBoxContainer.new()
	column.position = Vector2(32, 24)
	add_child(column)
	_status.add_theme_font_size_override("font_size", 22)
	column.add_child(_status)
	var hint := Label.new()
	hint.text = "TOUCH INPUT LAB\nLeft: move | Right: release to fire | Upper right: skill\nDrag above a ring by 128 px to cancel.\nDesktop: mouse simulates one finger. Android supports multi-touch."
	column.add_child(hint)
	var mode := CheckButton.new()
	mode.text = "Hold to fire (autocannon)"
	mode.toggled.connect(_source.set_continuous_fire)
	column.add_child(mode)
	var clear := Button.new()
	clear.text = "Cancel all inputs"
	clear.pressed.connect(_source.cancel_pending)
	column.add_child(clear)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(_on_back)
	column.add_child(back)
	resized.connect(_layout_controls)
	_layout_controls()

func _physics_process(_delta: float) -> void:
	_tick += 1
	var command := _source.sample(_tick)
	if command.fire_request_id > 0:
		_shots += 1
	if command.ability_request_id > 0:
		_skills += 1
	_status.text = "MOVE %d, %d | YAW %d | HELD %s\nRELEASES %d | SKILLS %d | TICK %d" % [
		command.move_x, command.move_z, command.aim_yaw, command.fire_held,
		_shots, _skills, _tick]

func _draw() -> void:
	if _centers.size() != 3:
		return
	var sticks: Array[Vector2] = [_source.state.move_vector, _source.state.aim_drag, _source.state.ability_drag]
	var labels: Array[String] = ["MOVE", "AIM / FIRE", "ABILITY"]
	for slot: int in range(3):
		var color := Color("55cfd5") if slot == 0 else Color("e9ba65")
		if _source.state.is_canceled(slot):
			color = Color("ef6f70")
		draw_circle(_centers[slot], 64, Color(color, 0.12))
		draw_arc(_centers[slot], 64, 0, TAU, 64, color, 3, true)
		draw_circle(_centers[slot] + sticks[slot] * 64, 22, color)
		draw_string(ThemeDB.fallback_font, _centers[slot] + Vector2(-46, 96), labels[slot], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, color)
		if slot > 0:
			draw_string(ThemeDB.fallback_font, _centers[slot] + Vector2(-220, -140), "CANCEL ↑", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, color)

func _layout_controls() -> void:
	_centers = [Vector2(150, size.y - 150), Vector2(size.x - 150, size.y - 150), Vector2(size.x - 150, size.y - 350)]
	var regions: Array[Rect2] = []
	for center: Vector2 in _centers:
		regions.append(Rect2(center - Vector2(80, 80), Vector2(160, 160)))
	_source.state.configure(regions)
	_source.viewport_to_logical = get_global_transform_with_canvas().affine_inverse()
	queue_redraw()

func _on_back() -> void:
	_source.set_enabled(false)
	back_requested.emit()
