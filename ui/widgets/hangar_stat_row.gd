extends HBoxContainer
class_name HangarStatRow
## Bars visualize provided values only; no equipment formulas live here.

var icon := Label.new()
var label := Label.new()
var bar := ProgressBar.new()
var value := Label.new()
var difference := Label.new()

func _ready() -> void:
	add_theme_constant_override("separation", 6)
	icon.custom_minimum_size.x = 20
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	icon.add_theme_color_override("font_color", HangarStyle.ACCENT)
	add_child(icon)
	label.custom_minimum_size.x = 32
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color("9bbbc7"))
	add_child(label)
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(90, 12)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background := HangarStyle.panel(Color("100e19"), Color("464052"), 6)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		background.set_content_margin(side, 0)
	bar.add_theme_stylebox_override("background", background)
	add_child(bar)
	var ticks := Control.new()
	ticks.set_script(preload("res://ui/widgets/stat_ticks.gd"))
	ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bar.add_child(ticks)
	value.custom_minimum_size.x = 46
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 15)
	add_child(value)
	difference.custom_minimum_size.x = 48
	difference.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	difference.add_theme_font_size_override("font_size", 12)
	add_child(difference)

func show_stat(caption: String, amount: float, previous: float, scale_max: float, decimals: int = 0, lower_better: bool = false) -> void:
	var parts := caption.split(" ", true, 1)
	icon.text = parts[0]
	label.text = parts[1] if parts.size() > 1 else caption
	bar.max_value = scale_max
	bar.value = amount
	var delta: float = amount - previous
	var color: Color = Color("18c9db") if is_zero_approx(delta) else (Color("3cdb8b") if (delta < 0 if lower_better else delta > 0) else Color("fa607c"))
	var fill := HangarStyle.panel(color, color, 6)
	for side: int in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		fill.set_content_margin(side, 0)
	bar.add_theme_stylebox_override("fill", fill)
	value.add_theme_color_override("font_color", Color("f0eef5"))
	difference.add_theme_color_override("font_color", color)
	var number_format: String = "%." + str(decimals) + "f"
	var delta_format: String = "%+." + str(decimals) + "f"
	value.text = number_format % amount
	difference.text = "—" if is_zero_approx(delta) else delta_format % delta
	difference.tooltip_text = "相对已装配部件的差值；不加到当前数值上"
