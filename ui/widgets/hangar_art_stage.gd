extends VBoxContainer
class_name HangarArtStage
## Appearance directly presents real models; unmodeled designs use static fallback.

const PREVIEW_STYLE: HangarPreviewStyle = preload("res://content/presentation/hangar_preview.tres")

var preview: HangarPreview
var artwork := TextureRect.new()
var _model := TextureRect.new()
var _viewport := SubViewport.new()
var _caption := Label.new()
var _load := Label.new()
var _load_value := Label.new()
var _load_bar := ProgressBar.new()
var _status := Label.new()
var _show_model: bool = true
var _dragging: bool = false
var _touch_index: int = -1

func _ready() -> void:
	add_theme_constant_override("separation", 10)
	custom_minimum_size.x = 360
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	var header := HBoxContainer.new()
	add_child(header)
	_caption.text = "外观预览 · 拖动360°旋转"
	_caption.add_theme_font_size_override("font_size", 13)
	_caption.add_theme_color_override("font_color", Color("aca2b7"))
	_caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_caption)
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
	display.add_child(artwork)
	_model.name = "AssemblyPreview"
	_model.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_model.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_model.stretch_mode = TextureRect.STRETCH_SCALE
	_model.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_model.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display.add_child(_model)
	var viewport := _viewport
	viewport.size = Vector2i(640, 480)
	# Keep the small embedded preview smooth without post-process blur.
	viewport.msaa_3d = PREVIEW_STYLE.msaa
	viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	viewport.scaling_3d_scale = 1.0
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	viewport.own_world_3d = true
	_model.add_child(viewport)
	viewport.add_child(preview)
	_model.texture = viewport.get_texture()
	_model.resized.connect(_resize_preview)
	_resize_preview()
	artwork.hide()

func _resize_preview() -> void:
	# Explicit pixel dimensions also supersample with Compatibility rendering.
	var pixels := _model.size * PREVIEW_STYLE.render_scale
	var limit := float(PREVIEW_STYLE.max_render_edge)
	if pixels.x > limit or pixels.y > limit:
		pixels *= limit / maxf(pixels.x, pixels.y)
	_viewport.size = Vector2i(maxi(2, roundi(pixels.x)), maxi(2, roundi(pixels.y)))

func show_loadout(weapon: WeaponDef, chassis: ChassisDef, stats: ResolvedStats) -> String:
	var texture := HangarArtCatalog.texture(weapon.id, chassis.id)
	if texture == null:
		return "Missing hangar art: %s / %s" % [weapon.id, chassis.id]
	artwork.texture = texture
	_dragging = false
	_touch_index = -1
	_show_model = TankPartCatalog.WEAPONS.has(weapon.id) and TankPartCatalog.CHASSIS.has(chassis.id)
	_model.visible = _show_model
	artwork.visible = not _show_model
	_caption.text = "外观预览 · 拖动360°旋转" if _show_model else "外观设计 · 静态图，模型待制作"
	_load.text = "载重"
	_load_value.text = "%d / %d" % [stats.weight, chassis.capacity]
	_load_bar.max_value = maxi(chassis.capacity, stats.weight)
	_load_bar.value = stats.weight
	var color: Color = Color("fa426d") if stats.overload > 0 else HangarStyle.ACCENT
	(_load_bar.get_theme_stylebox("fill") as StyleBoxFlat).bg_color = color
	_load_value.add_theme_color_override("font_color", color if stats.overload > 0 else Color.WHITE)
	_status.text = HangarCopy.text("hangar.ready") if stats.overload == 0 else ("超重 %d · 无法装配" % stats.overload if not LoadoutResolver.can_save(weapon, chassis) else "超重 %d · 移速降低 %d%%" % [stats.overload, roundi(LoadoutResolver.RULES.speed_penalty_per_overload * stats.overload * 100)])
	return ""

func show_design(id: StringName) -> void:
	_dragging = false
	_touch_index = -1
	_show_model = false
	_model.hide()
	artwork.texture = HangarPartArtCatalog.display_texture(id)
	artwork.show()
	_caption.text = "外观设计 · 静态图，模型待制作"

func _preview_input(event: InputEvent) -> void:
	if not _show_model: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		preview.rotate_preview(event.relative.x * 0.012)
	elif event is InputEventScreenTouch:
		_touch_index = event.index if event.pressed else -1
	elif event is InputEventScreenDrag and event.index == _touch_index:
		preview.rotate_preview(event.relative.x * 0.012)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_dragging = false

	if event is InputEventScreenTouch and not event.pressed and event.index == _touch_index:
		_touch_index = -1
