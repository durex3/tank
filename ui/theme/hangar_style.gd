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
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC"])
	theme.default_font = font
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
