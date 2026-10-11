extends Button
class_name HangarPartCard
## Standalone part selector; preview, ownership and equipped markers are distinct.

var artwork := TextureRect.new()
var caption := Label.new()
var badge := Label.new()
var rarity := Label.new()
var equipped_mark := Label.new()
var upgrade_mark := Label.new()
var label_key: String = ""

func _ready() -> void:
	toggle_mode = true
	clip_contents = true
	custom_minimum_size = Vector2(126, 128)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 7)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 1)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(column)
	badge.add_theme_font_size_override("font_size", 11)
	badge.position = Vector2(8, 6)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artwork.custom_minimum_size.y = 70
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(artwork)
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 14)
	column.add_child(caption)
	rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity.add_theme_font_size_override("font_size", 12)
	column.add_child(rarity)
	add_theme_stylebox_override("normal", HangarStyle.panel(Color("1b1729"), Color("494052"), 16))
	var selected := HangarStyle.panel(Color("262137"), Color("d9fcff"), 16)
	selected.set_border_width_all(3)
	add_theme_stylebox_override("pressed", selected)
	add_theme_stylebox_override("hover", HangarStyle.panel(Color("2b253b"), Color("777083"), 16))
	equipped_mark.text = "✓"
	equipped_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	equipped_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	equipped_mark.add_theme_font_size_override("font_size", 23)
	equipped_mark.add_theme_color_override("font_color", Color("151423"))
	var circle := StyleBoxFlat.new()
	circle.bg_color = Color.WHITE
	circle.set_corner_radius_all(20)
	equipped_mark.add_theme_stylebox_override("normal", circle)
	equipped_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(equipped_mark)
	equipped_mark.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	equipped_mark.offset_left = -40
	equipped_mark.offset_top = -40
	equipped_mark.offset_right = -8
	equipped_mark.offset_bottom = -8
	equipped_mark.tooltip_text = "当前已装配"
	upgrade_mark.text = "↑"
	upgrade_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_mark.add_theme_font_size_override("font_size", 25)
	upgrade_mark.add_theme_color_override("font_color", Color("063d2a"))
	var upgrade_style := StyleBoxFlat.new()
	upgrade_style.bg_color = Color("33d989")
	upgrade_style.border_color = Color.WHITE
	upgrade_style.set_border_width_all(2)
	upgrade_style.set_corner_radius_all(8)
	upgrade_mark.add_theme_stylebox_override("normal", upgrade_style)
	upgrade_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(upgrade_mark)
	upgrade_mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	upgrade_mark.offset_left = -35
	upgrade_mark.offset_right = -5
	upgrade_mark.offset_top = 5
	upgrade_mark.offset_bottom = 35
	upgrade_mark.tooltip_text = "可升级"
	set_selected(false)

func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
	caption.text = HangarCopy.text(label_key)
	caption.add_theme_color_override("font_color", HangarStyle.TEXT)
