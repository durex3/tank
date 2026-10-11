extends VBoxContainer
class_name HangarArtStage
## Static art is the default; explicit toggle exposes the existing assembly preview.

var preview: HangarPreview
var artwork := TextureRect.new()
var _model := SubViewportContainer.new()
var _caption := Label.new()
var _toggle := Button.new()
var _load := Label.new()
var _load_value := Label.new()
var _load_bar := ProgressBar.new()
var _status := Label.new()
var _show_model: bool = false
var _dragging: bool = false

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	custom_minimum_size.x = 360
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	add_child(header)
	_caption.text = "外观预览"
	_caption.add_theme_font_size_override("font_size", 13)
	_caption.add_theme_color_override("font_color", Color("aca2b7"))
	_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_caption)
	_toggle.name = "ArtModelToggle"
	_toggle.text = HangarCopy.text("hangar.show_model")
	_toggle.add_theme_font_size_override("font_size", 13)
	_toggle.pressed.connect(_toggle_view)
	header.add_child(_toggle)
	_build_display()
	var load_panel := PanelContainer.new()
	var load_style := HangarStyle.panel(Color("211d2c"), Color("51485b"), 18)
	load_style.set_content_margin_all(8)
	load_panel.add_theme_stylebox_override("panel", load_style)
	load_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	load_panel.custom_minimum_size.x = 300
	add_child(load_panel)
	var load_row := HBoxContainer.new()
	load_row.add_theme_constant_override("separation", 18)
	load_panel.add_child(load_row)
	load_row.add_child(_load)
	_load_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_load_bar.show_percentage = false
	_load_bar.custom_minimum_size = Vector2(130, 12)
	_load_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for state: String in ["background", "fill"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("13101c") if state == "background" else HangarStyle.ACCENT
		style.set_corner_radius_all(6)
		style.set_content_margin_all(0)
		_load_bar.add_theme_stylebox_override(state, style)
	load_row.add_child(_load_bar)
	_load_value.add_theme_font_size_override("font_size", 17)
	load_row.add_child(_load_value)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_status.add_theme_font_size_override("font_size", 16)
	_status.add_theme_color_override("font_color", HangarStyle.ACCENT)
	add_child(_status)
	_status.hide()

func _build_display() -> void:
	var display := Control.new()
	display.custom_minimum_size.y = 250
	display.clip_contents = true
	display.mouse_filter = Control.MOUSE_FILTER_STOP
	display.gui_input.connect(_preview_input)
	display.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(display)
	artwork.name = "SelectedLoadoutArt"
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var platform := Control.new()
	platform.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	platform.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(platform)
	platform.resized.connect(platform.queue_redraw)
	platform.draw.connect(func() -> void:
		var points := PackedVector2Array()
		var center := Vector2(platform.size.x * 0.5, platform.size.y * 0.88)
		for index: int in range(49):
			var angle: float = TAU * index / 48.0
			points.append(center + Vector2(cos(angle) * platform.size.x * 0.28, sin(angle) * 19))
		platform.draw_colored_polygon(points, Color("171426"))
		platform.draw_polyline(points, Color("615573"), 2, true)
		for index: int in range(12):
			var angle: float = TAU * index / 12.0
			platform.draw_circle(center + Vector2(cos(angle) * platform.size.x * 0.27, sin(angle) * 18), 2, Color("8b7a9f")))
	display.add_child(artwork)
	_model.name = "AssemblyPreview"
	_model.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_model.stretch = true
	_model.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(_model)
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 480)
	viewport.own_world_3d = true
	_model.add_child(viewport)
	viewport.add_child(preview)
	_model.hide()

func show_loadout(weapon: WeaponDef, chassis: ChassisDef, stats: ResolvedStats) -> String:
	var texture := HangarArtCatalog.texture(weapon.id, chassis.id)
	if texture == null:
		return "Missing hangar art: %s / %s" % [weapon.id, chassis.id]
	artwork.texture = texture
	_load.text = "载重"
	_load_value.text = "%d / %d" % [stats.weight, chassis.capacity]
	_load_bar.max_value = maxi(chassis.capacity, stats.weight)
	_load_bar.value = stats.weight
	var color: Color = Color("fa426d") if stats.overload > 0 else HangarStyle.ACCENT
	(_load_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = color
	_load_value.add_theme_color_override("font_color", color if stats.overload > 0 else Color.WHITE)
	_status.text = HangarCopy.text("hangar.ready") if stats.overload == 0 else HangarCopy.text("hangar.overload") % stats.overload
	return ""

func _toggle_view() -> void:
	_show_model = not _show_model
	_dragging = false
	_model.visible = _show_model
	artwork.visible = not _show_model
	_caption.text = "装配模型 · 拖动360°旋转" if _show_model else HangarCopy.text("hangar.art")
	_toggle.text = HangarCopy.text("hangar.show_art" if _show_model else "hangar.show_model")

func _preview_input(event: InputEvent) -> void:
	if not _show_model: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		preview.rotate_preview(event.relative.x * 0.012)
	elif event is InputEventScreenDrag:
		preview.rotate_preview(event.relative.x * 0.012)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false
