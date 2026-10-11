extends Control
## Temporary M0 status screen; does not implement battle or loadout rules.

signal hangar_requested
signal movement_requested
signal input_lab_requested

func _ready() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48)
	add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 48)
	margin.add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(column)
	var title := Label.new()
	title.text = "TANK ARENA"
	title.add_theme_font_size_override("font_size", 52)
	column.add_child(title)
	var status := Label.new()
	status.text = "M0 / PROJECT FOUNDATION\nGodot 4.7.2 · 60 Hz · Compatibility\n\nArchitecture and content contracts initialized.\nCannon training is ready to drive and fire."
	status.add_theme_font_size_override("font_size", 22)
	column.add_child(status)
	var lab := Button.new()
	lab.text = "Open touch input lab"
	lab.custom_minimum_size.y = 56
	lab.pressed.connect(func() -> void: input_lab_requested.emit())
	column.add_child(lab)
	var movement := Button.new()
	movement.text = "Drive & fire · training"
	movement.custom_minimum_size.y = 56
	movement.pressed.connect(func() -> void: movement_requested.emit())
	column.add_child(movement)
	_add_hangar_button(column)
	var art := TextureRect.new()
	art.texture = preload("res://assets/tanks/cannon-hero-v1.png")
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.custom_minimum_size = Vector2(480, 400)
	art.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(art)

func _add_hangar_button(column: VBoxContainer) -> void:
	var hangar := Button.new()
	hangar.text = "Open modular hangar"
	hangar.custom_minimum_size.y = 56
	hangar.pressed.connect(func() -> void: hangar_requested.emit())
	column.add_child(hangar)
