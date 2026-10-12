extends RefCounted
class_name HangarStyle
## A shared theme for hangar widgets; no gameplay state.

const ACCENT := Color("21d7dd")
const INK := Color("101925")
const TEXT := Color("eff3f7")
const MUTED := Color("97a7ba")

static func panel(color: Color = Color("1a1c2d"), border: Color = Color("36374c"), radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(14)
	return style

static func create() -> Theme:
	var theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Hiragino Sans GB", "PingFang SC", "Heiti SC", "Noto Sans CJK SC"])
	theme.default_font = font
	# RichTextLabel bold uses its own font slot rather than default_font.
	var bold := SystemFont.new()
	bold.font_names = font.font_names
	bold.font_weight = 700
	theme.set_font("normal_font", "RichTextLabel", font)
	theme.set_font("bold_font", "RichTextLabel", bold)
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_stylebox("normal", "Button", panel())
	theme.set_stylebox("hover", "Button", panel(Color("253142"), ACCENT))
	theme.set_stylebox("pressed", "Button", panel(ACCENT, ACCENT))
	theme.set_stylebox("focus", "Button", panel(Color(0, 0, 0, 0), Color("eafaff")))
	theme.set_stylebox("panel", "PanelContainer", panel())
	theme.set_stylebox("background", "ProgressBar", panel(Color("10131e"), Color("10131e"), 5))
	theme.set_stylebox("fill", "ProgressBar", panel(ACCENT, ACCENT, 5))
	return theme

static func action_button(button: Button, background: Color, foreground: Color) -> void:
	button.custom_minimum_size.y = 48
	button.size_flags_vertical = Control.SIZE_SHRINK_END
	button.size_flags_stretch_ratio = 1.0
	button.add_theme_font_size_override("font_size", 18)
	for state: String in ["normal", "hover", "pressed"]:
		var style := panel(background.lightened(0.08) if state == "hover" else background, background, 12)
		style.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, foreground)
