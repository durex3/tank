extends Button
class_name HangarPartCard
## Standalone part selector; preview, ownership and equipped markers are distinct.

var artwork := TextureRect.new()
var caption := Label.new()
var badge := Label.new()
var rarity := Label.new()
var equipped_mark := HangarCardMark.new()
var upgrade_mark := HangarCardMark.new()
var label_key: String = ""

func _ready() -> void:
	toggle_mode = true
	clip_contents = true
	custom_minimum_size = Vector2(126, 158)
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
	badge.position = Vector2(10, 8)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(badge)
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.size_flags_vertical = Control.SIZE_EXPAND_FILL
	artwork.custom_minimum_size.y = 80
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var status_space := Control.new()
	status_space.custom_minimum_size.y = 22
	status_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(status_space)
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
	_add_mark(equipped_mark, false)
	_add_mark(upgrade_mark, true)
	set_selected(false)

func set_selected(selected: bool) -> void:
	set_pressed_no_signal(selected)
	caption.text = HangarCopy.text(label_key)
	caption.add_theme_color_override("font_color", HangarStyle.TEXT)

func _add_mark(mark: HangarCardMark, is_upgrade: bool) -> void:
	mark.upgrade = is_upgrade
	add_child(mark)
	mark.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT if is_upgrade else Control.PRESET_BOTTOM_RIGHT)
	mark.offset_left = -30 if is_upgrade else -34
	mark.offset_right = -10
	mark.offset_top = 8 if is_upgrade else -34
	mark.offset_bottom = 28 if is_upgrade else -10
	mark.tooltip_text = "可升级" if is_upgrade else "当前已装配"
