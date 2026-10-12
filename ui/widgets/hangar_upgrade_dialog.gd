extends ConfirmationDialog
class_name HangarUpgradeDialog
## Presentation only: compares explicit growth data and resolved loadout values.

const GREEN := Color("43e6a0")
const RED := Color("ff8092")
var heading := Label.new()
var levels := Label.new()
var icon := TextureRect.new()
var comparison := GridContainer.new()
var fee := Label.new()
var wallet := Label.new()
var _body := VBoxContainer.new()

func _ready() -> void:
	title = "升级部件"
	borderless = true
	add_theme_stylebox_override("panel", HangarStyle.panel(Color("201e31"), Color("64577d"), 20))
	_body.custom_minimum_size.x = 620
	_body.add_theme_constant_override("separation", 16)
	add_child(_body)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	_body.add_child(header)
	icon.custom_minimum_size = Vector2(96, 80)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	var identity := VBoxContainer.new()
	identity.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(identity)
	heading.add_theme_font_size_override("font_size", 26)
	identity.add_child(heading)
	levels.add_theme_font_size_override("font_size", 20)
	levels.add_theme_color_override("font_color", GREEN)
	identity.add_child(levels)
	var table := PanelContainer.new()
	table.add_theme_stylebox_override("panel", HangarStyle.panel(Color("29263e"), Color("39364f"), 12))
	_body.add_child(table)
	comparison.columns = 4
	comparison.add_theme_constant_override("h_separation", 18)
	comparison.add_theme_constant_override("v_separation", 14)
	table.add_child(comparison)
	var note := Label.new()
	note.text = "大招 / 被动本级不变 · 超重1降速%d%%，超重%d起禁止装配" % [roundi(LoadoutResolver.RULES.speed_penalty_per_overload * 100), LoadoutResolver.RULES.maximum_overload + 1]
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", HangarStyle.MUTED)
	_body.add_child(note)
	var cost := HBoxContainer.new()
	_body.add_child(cost)
	fee.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fee.add_theme_font_size_override("font_size", 22)
	fee.add_theme_color_override("font_color", Color("ffda79"))
	cost.add_child(fee)
	wallet.add_theme_font_size_override("font_size", 16)
	wallet.add_theme_color_override("font_color", HangarStyle.MUTED)
	cost.add_child(wallet)
	get_ok_button().text = "确认升级"
	get_cancel_button().text = "暂不升级"
	for button: Button in [get_ok_button(), get_cancel_button()]:
		button.custom_minimum_size = Vector2(220, 50)
		button.add_theme_font_size_override("font_size", 18)
	get_ok_button().add_theme_stylebox_override("normal", HangarStyle.panel(GREEN, GREEN, 12))
	# Focus/hover use separate font colors; the dialog initially focuses OK.
	for state: String in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		get_ok_button().add_theme_color_override(state, Color("102d25"))
	get_ok_button().add_theme_stylebox_override("hover", HangarStyle.panel(Color("67efb4"), Color("67efb4"), 12))
	get_ok_button().add_theme_stylebox_override("pressed", HangarStyle.panel(Color("2cc88b"), Color("2cc88b"), 12))

func show_upgrade(id: StringName, level: int, ids: Array[StringName], profile: EquipmentProfile) -> void:
	var entry := PartCatalog.find(id)
	var data := PartGrowth.table(id)
	heading.text = entry.display_name + " · 升级"
	levels.text = "Lv.%d    →    Lv.%d" % [level, level + 1]
	icon.texture = HangarPartArtCatalog.texture(id)
	for child: Node in comparison.get_children():
		comparison.remove_child(child)
		child.queue_free()
	for text: String in ["属性", "当前", "升级后", "变化"]:
		_cell(text, HangarStyle.MUTED, 14)
	var turret: bool = entry.kind == 0
	_row("伤害" if turret else "耐久", data.values[level - 1], data.values[level], true)
	_row("重量" if turret else "承载", data.loads[level - 1], data.loads[level], not turret)
	var wl: int = profile.level_of(ids[0])
	var cl: int = profile.level_of(ids[1])
	var before := PartGrowth.resolve(ids[0], ids[1], wl, cl)
	var after := PartGrowth.resolve(ids[0], ids[1], level + 1 if turret else wl, level + 1 if not turret else cl)
	_row("组合移速", before.move_speed, after.move_speed, true, true)
	_row("组合超重", before.overload, after.overload, false)
	fee.text = "升级费用   %d 金币" % data.costs[level - 1]
	wallet.text = "持有 %d 金币" % profile.coins
	popup_centered(Vector2i(680, 480))

func _row(label: String, before: float, after: float, higher_is_better: bool, decimal: bool = false) -> void:
	var changed: bool = not is_equal_approx(before, after)
	var color: Color = (GREEN if (after > before) == higher_is_better else RED) if changed else HangarStyle.MUTED
	_cell(label, HangarStyle.TEXT)
	_cell("%.1f" % before if decimal else str(int(before)), HangarStyle.MUTED)
	_cell("%.1f" % after if decimal else str(int(after)), color if changed else HangarStyle.TEXT)
	_cell(("%+.1f" % (after - before) if decimal else "%+d" % int(after - before)) if changed else "不变", color, 16)

func _cell(text: String, color: Color, font_size: int = 20) -> void:
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.x = 110
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if comparison.get_child_count() % 4 == 0 else HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	comparison.add_child(label)
