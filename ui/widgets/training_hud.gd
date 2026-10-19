extends Control
class_name TrainingHud
## Compact anchored training chrome; statistics remain an optional readout.

signal back_requested
signal pause_requested
signal touch_requested(value: bool)
signal sparring_requested

var combat_status := Label.new()
var health_status := Label.new()
var cooldown := ProgressBar.new()
var sparring := Button.new()
var stats_panel := PanelContainer.new()
var _left := HBoxContainer.new()
var _right := HBoxContainer.new()
var _title := PanelContainer.new()
var _hint := Label.new()
var weapon_id: StringName
var continuous: bool
var touch_mode: bool
var match_mode: bool

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left.add_theme_constant_override("separation",10)
	add_child(_left)
	_icon(&"back",BattleCopy.text(&"back"),func() -> void: back_requested.emit())
	_icon(&"pause",BattleCopy.text(&"pause"),func() -> void: pause_requested.emit())
	_icon(&"stats",BattleCopy.text(&"statistics"),func() -> void: stats_panel.visible = not stats_panel.visible)
	var touch_button := _icon(&"touch",BattleCopy.text(&"touch"),func() -> void: touch_requested.emit(not touch_mode))
	touch_button.toggle_mode = true
	touch_button.button_pressed = touch_mode
	add_child(_title)
	_title.add_theme_stylebox_override("panel",HangarStyle.panel(Color(0.08,0.12,0.16,0.86),Color("52616a"),16))
	var heading := Label.new()
	heading.text = BattleCopy.text(&"match_title" if match_mode else &"training_title")
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_child(heading)
	_right.add_theme_constant_override("separation",10)
	add_child(_right)
	sparring.name = "StartSparring"
	sparring.text = BattleCopy.text(&"sparring")
	sparring.focus_mode = Control.FOCUS_NONE
	sparring.visible = not match_mode
	sparring.custom_minimum_size = Vector2(130,48)
	sparring.pressed.connect(func() -> void: sparring_requested.emit())
	_right.add_child(sparring)
	_build_stats()
	_hint.text = "%s  ·  %s  ·  %s" % [HangarCopy.part_name(weapon_id),BattleCopy.text(&"controls"),BattleCopy.text(&"hold" if continuous else &"release")]
	_hint.add_theme_font_size_override("font_size",14)
	_hint.add_theme_color_override("font_color",Color("e4eef2"))
	_hint.add_theme_color_override("font_shadow_color",Color("15232e"))
	_hint.add_theme_constant_override("shadow_offset_x",1)
	_hint.add_theme_constant_override("shadow_offset_y",2)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hint)
	set_touch_mode(touch_mode)
	resized.connect(_layout)
	_layout()

func _icon(symbol: StringName, caption: String, action: Callable) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(48,48)
	button.tooltip_text = caption
	button.accessibility_name = caption
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	_left.add_child(button)
	var glyph := TrainingToolbarIcon.new()
	glyph.symbol = symbol
	button.add_child(glyph)
	return button

func _build_stats() -> void:
	stats_panel.name = "TrainingStatistics"
	stats_panel.add_theme_stylebox_override("panel",HangarStyle.panel(Color(0.08,0.12,0.16,0.94),Color("52616a"),16))
	add_child(stats_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	stats_panel.add_child(column)
	var heading := Label.new()
	heading.text = BattleCopy.text(&"statistics")
	column.add_child(heading)
	for label: Label in [combat_status,health_status]:
		label.custom_minimum_size.x = 330
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(label)
	cooldown.custom_minimum_size = Vector2(330,8)
	cooldown.show_percentage = false
	for pair: Array in [["background",Color("26343e")],["fill",HangarStyle.ACCENT]]:
		var style := HangarStyle.panel(pair[1],Color.TRANSPARENT,4)
		style.set_content_margin_all(0)
		cooldown.add_theme_stylebox_override(pair[0],style)
	column.add_child(cooldown)
	stats_panel.hide()

func set_touch_mode(value: bool) -> void:
	touch_mode = value
	_hint.visible = not value
	(_left.get_child(3) as Button).button_pressed = value

func _layout() -> void:
	_left.position = Vector2(20,20)
	_right.position = Vector2(size.x-164,20)
	_title.position = Vector2(size.x*0.5-145,20)
	_title.size = Vector2(290,48)
	stats_panel.position = Vector2(20,82)
	_hint.position = Vector2(size.x*0.5-280,size.y-30)
	_hint.size = Vector2(560,24)
