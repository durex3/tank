extends ColorRect
class_name PauseOverlay
## Modal UI stays interactive while only the offline session is suspended.

signal resume_requested
signal exit_requested

var match_mode: bool = false
var _resume := Button.new()
var _reason := Label.new()
var _held_mouse: Dictionary = {}
var _held_touches: Dictionary = {}
var _blocked_touches: Dictionary = {}
var _blocked_mouse: Dictionary = {}
var _block_accept: bool = false

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	color = Color(0.02, 0.04, 0.06, 0.84)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 280)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	margin.add_child(column)
	var title := Label.new()
	title.text = "DUEL PAUSED" if match_mode else "TRAINING PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	_reason.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_reason)
	_resume.text = "Continue duel" if match_mode else "Continue training"
	_resume.custom_minimum_size.y = 56
	_resume.pressed.connect(func() -> void: resume_requested.emit())
	column.add_child(_resume)
	var exit := Button.new()
	exit.text = "Back"
	exit.custom_minimum_size.y = 56
	exit.pressed.connect(func() -> void: exit_requested.emit())
	column.add_child(exit)
	hide()

func show_paused(reason: StringName) -> void:
	_blocked_touches = _held_touches.duplicate()
	_blocked_mouse = _held_mouse.duplicate()
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
		if Input.is_mouse_button_pressed(button):
			_blocked_mouse[button] = true
	_block_accept = Input.is_action_pressed("ui_accept")
	_reason.text = "Focus lost. Continue when ready." if reason == &"focus_lost" else "Movement, shots and timers are frozen."
	show()
	_resume.grab_focus.call_deferred()

func dismiss() -> void:
	_resume.release_focus()
	hide()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var pointer := event as InputEventMouseButton
		if pointer.pressed:
			_held_mouse[pointer.button_index] = true
		else:
			_held_mouse.erase(pointer.button_index)
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and not touch.canceled:
			_held_touches[touch.index] = true
		else:
			_held_touches.erase(touch.index)
		if visible and _blocked_touches.has(touch.index):
			_blocked_touches.erase(touch.index)
			if not touch.pressed or touch.canceled:
				get_viewport().set_input_as_handled()
	elif visible and event is InputEventScreenDrag:
		if _blocked_touches.has((event as InputEventScreenDrag).index):
			get_viewport().set_input_as_handled()
	elif visible and event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if _blocked_mouse.has(mouse.button_index):
			_blocked_mouse.erase(mouse.button_index)
			if not mouse.pressed:
				get_viewport().set_input_as_handled()
	elif visible and _block_accept and event.is_action("ui_accept"):
		if event.is_action_released("ui_accept"):
			_block_accept = false
			get_viewport().set_input_as_handled()
		elif not event.is_echo():
			_block_accept = false
		else:
			get_viewport().set_input_as_handled()
