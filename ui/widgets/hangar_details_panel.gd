extends PanelContainer
class_name HangarDetailsPanel
## Selected properties and two distinct ability cards; full text is in details.

signal training_requested
signal upgrade_requested

var dialog_body := VBoxContainer.new()
var modal_shade := ColorRect.new()
var dialog_upgrade: Button
var metadata := Label.new()
var summary := Label.new()
var trial := Button.new()
var costs_text: String = ""
var metadata_text: String = ""
var title := Label.new()
var comparison := Label.new()
var metrics := VBoxContainer.new()
var rows: Array[HangarStatRow] = []
var passive := RichTextLabel.new()
var ultimate := RichTextLabel.new()
var entry: PartEntry
var dialog := AcceptDialog.new()

func _ready() -> void:
	add_theme_stylebox_override("panel", HangarStyle.panel(Color("211d33"), Color("4b425b")))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 18)
	add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 300
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	metadata.add_theme_font_size_override("font_size", 12)
	metadata.add_theme_color_override("font_color", HangarStyle.ACCENT)
	left.add_child(metadata)
	title.add_theme_font_size_override("font_size", 27)
	left.add_child(title)
	summary.add_theme_font_size_override("font_size", 13)
	summary.add_theme_color_override("font_color", Color("bcb7ca"))
	left.add_child(summary)
	metrics.add_theme_constant_override("separation", 6)
	left.add_child(metrics)
	for index: int in range(5):
		var row := HangarStatRow.new()
		metrics.add_child(row)
		rows.append(row)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 290
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 9)
	body.add_child(right)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	right.add_child(actions)
	comparison.add_theme_font_size_override("font_size", 11)
	comparison.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(comparison)
	trial.text = "◎ 试炼场"
	trial.add_theme_font_size_override("font_size", 13)
	trial.pressed.connect(func() -> void: training_requested.emit())
	actions.add_child(trial)
	var button := Button.new()
	button.text = "? 详情"
	button.add_theme_font_size_override("font_size", 13)
	button.pressed.connect(_show_dialog)
	actions.add_child(button)
	_build_skill(right, passive, "底盘被动", false)
	_build_skill(right, ultimate, "炮塔大招", true)
	var overlay := CanvasLayer.new()
	overlay.layer = 40
	add_child(overlay)
	modal_shade.color = Color(0.03, 0.02, 0.07, 0.72)
	modal_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(modal_shade)
	modal_shade.hide()
	dialog.visibility_changed.connect(func() -> void: modal_shade.visible = dialog.visible)
	add_child(dialog)
	dialog.title = "部件详情"
	dialog.borderless = true
	dialog.add_theme_stylebox_override("panel", HangarStyle.panel(Color("211d33"), Color("4b425b"), 18))
	dialog.add_child(dialog_body)
	dialog_body.custom_minimum_size.x = 740
	dialog_body.add_theme_constant_override("separation", 12)
	dialog.get_ok_button().text = "关闭"
	dialog.get_ok_button().custom_minimum_size = Vector2(128, 48)
	dialog_upgrade = dialog.add_button("升级部件", true, "upgrade")
	dialog_upgrade.custom_minimum_size = Vector2(164, 48)
	var primary := HangarStyle.panel(HangarStyle.ACCENT, HangarStyle.ACCENT, 14)
	primary.set_content_margin_all(12)
	primary.set_content_margin(SIDE_LEFT, 32)
	primary.set_content_margin(SIDE_RIGHT, 32)
	dialog_upgrade.add_theme_stylebox_override("normal", primary)
	dialog_upgrade.add_theme_color_override("font_color", Color("092f38"))
	var secondary := HangarStyle.panel(Color("302b3e"), Color("574e66"), 14)
	secondary.set_content_margin(SIDE_LEFT, 32)
	secondary.set_content_margin(SIDE_RIGHT, 32)
	dialog.get_ok_button().add_theme_stylebox_override("normal", secondary)
	dialog.custom_action.connect(func(action: StringName) -> void:
		if action == &"upgrade":
			dialog.hide()
			upgrade_requested.emit())

func _build_skill(parent: VBoxContainer, content: RichTextLabel, heading: String, active: bool) -> void:
	var panel := PanelContainer.new()
	var style := HangarStyle.panel(Color("2c273c"), Color("12bbcf") if active else Color("3d374e"), 14)
	style.set_content_margin_all(7)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)
	var icon := Control.new()
	icon.set_script(preload("res://ui/widgets/skill_icon.gd"))
	icon.active = active
	icon.custom_minimum_size = Vector2(36, 40)
	row.add_child(icon)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var tag := Label.new()
	tag.text = heading + " · 待实现"
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.add_theme_font_size_override("font_size", 10)
	tag.add_theme_color_override("font_color", Color("64dce4"))
	column.add_child(tag)
	content.set_meta("status_label",tag)
	content.set_meta("heading",heading)
	content.custom_minimum_size.y = 0
	content.fit_content = true
	content.scroll_active = false
	content.bbcode_enabled = true
	content.add_theme_font_size_override("normal_font_size", 12)
	content.add_theme_font_size_override("bold_font_size", 14)
	column.add_child(content)

func show_part(id: StringName, profile: EquipmentProfile, weapon: WeaponDef, chassis: ChassisDef) -> void:
	entry = PartCatalog.find(id)
	title.text = entry.display_name
	var state: String = "Lv.%d" % profile.level_of(id) if profile.owns(id) else "未解锁"
	var entries := PartCatalog.entries_of(entry.kind)
	metadata_text = "%s%02d · %s · %s" % ["T" if entry.kind == 0 else "H", entries.find(entry) + 1, entry.rarity_name(), state]
	metadata.text = metadata_text
	summary.text = "普通攻击 · " + ("连续射击" if id == &"autocannon" else "散射弹道" if id == &"scatter" else "直射弹道") if entry.kind == 0 else "机动底盘 · " + entry.display_name
	comparison.text = ""
	trial.disabled = not entry.basic_ready
	metrics.visible = entry.basic_ready
	if not entry.basic_ready:
		comparison.text = "待开发"
		summary.text = "设计预览 · 暂不可装配"
		_set_skill(passive, entry.ability_summary if entry.kind == 1 else PartCatalog.find(chassis.id).ability_summary,entry.passive_ready if entry.kind == 1 else PartCatalog.find(chassis.id).passive_ready)
		_set_skill(ultimate, entry.ability_summary if entry.kind == 0 else PartCatalog.find(weapon.id).ability_summary,entry.ultimate_ready if entry.kind == 0 else PartCatalog.find(weapon.id).ultimate_ready)
		return
	var current_w := PartGrowth.weapon(profile.weapon_id, profile.level_of(profile.weapon_id))
	var current_c := PartGrowth.chassis(profile.chassis_id, profile.level_of(profile.chassis_id))
	var stats := LoadoutResolver.resolve(weapon, chassis)
	var current := LoadoutResolver.resolve(current_w, current_c)
	comparison.text = "对比 " + (PartCatalog.find(profile.weapon_id).display_name if entry.kind == 0 else PartCatalog.find(profile.chassis_id).display_name)
	if entry.kind == 0:
		rows[0].show_stat("⚔ 伤害", stats.damage, current.damage, 300)
		rows[1].show_stat("ϟ 秒伤", stats.nominal_dps(weapon.pellet_count), current.nominal_dps(current_w.pellet_count), 300, 1)
		rows[2].show_stat("◎ 射程", weapon.range_m, current_w.range_m, 22, 1)
		rows[3].show_stat("◷ 间隔", float(stats.interval_ticks) / 60.0, float(current.interval_ticks) / 60.0, 2, 2, true)
		rows[4].show_stat("⚓ 重量", stats.weight, current.weight, 4, 0, true)
	else:
		rows[0].show_stat("▣ 耐久", stats.max_hp, current.max_hp, 1000)
		rows[1].show_stat("ϟ 移速", stats.move_speed, current.move_speed, 10, 1)
		rows[2].show_stat("▤ 承载", chassis.capacity, current_c.capacity, 5)
		rows[3].show_stat("⚓ 载重", stats.weight, current.weight, chassis.capacity)
		rows[4].show_stat("！ 超重", stats.overload, current.overload, 3, 0, true)
	_set_skill(passive, PartCatalog.find(chassis.id).ability_summary,PartCatalog.find(chassis.id).passive_ready)
	_set_skill(ultimate, PartCatalog.find(weapon.id).ability_summary,PartCatalog.find(weapon.id).ultimate_ready)

func _set_skill(target: RichTextLabel, summary: String, ready: bool = false) -> void:
	target.set_meta("ready",ready)
	(target.get_meta("status_label") as Label).text = str(target.get_meta("heading"))+(" · 训练可用" if ready else " · 待实现")
	target.tooltip_text = summary
	var parts := summary.split("：", true, 1)
	var name_text: String = parts[0]
	var description: String = parts[1] if parts.size() > 1 else summary
	description = description.split("；")[0]
	if description.length() > 30:
		description = description.left(29) + "…"
	target.text = "[b]" + name_text + "[/b]\n" + description

func _show_dialog() -> void:
	for child: Node in dialog_body.get_children():
		dialog_body.remove_child(child)
		child.queue_free()
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	dialog_body.add_child(header)
	var icon := TextureRect.new()
	icon.texture = load("res://assets/derived/ui/turret.svg" if entry.kind == 0 else "res://assets/derived/ui/chassis.svg")
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.modulate = HangarStyle.ACCENT
	header.add_child(icon)
	var identity := VBoxContainer.new()
	header.add_child(identity)
	for item: Array in [[metadata_text, 13, HangarStyle.ACCENT], [entry.display_name, 32, Color.WHITE], [summary.text, 15, Color("c5bfd3")]]:
		var label := Label.new()
		label.text = str(item[0])
		label.add_theme_font_size_override("font_size", item[1])
		label.add_theme_color_override("font_color", item[2])
		identity.add_child(label)
	var separator := HSeparator.new()
	dialog_body.add_child(separator)
	var table := GridContainer.new()
	table.columns = 4
	table.add_theme_constant_override("h_separation", 24)
	table.add_theme_constant_override("v_separation", 14)
	dialog_body.add_child(table)
	if metrics.visible:
		for row: HangarStatRow in rows:
			for text: String in [row.label.text, row.value.text + ("  (" + row.difference.text + ")" if row.difference.text != "—" else "")]:
				var cell := Label.new()
				cell.text = text
				cell.add_theme_font_size_override("font_size", 17)
				cell.add_theme_color_override("font_color", HangarStyle.ACCENT if text == row.label.text else Color.WHITE)
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				table.add_child(cell)
	for item: Array in [["底盘被动 · 待实现", passive.tooltip_text], ["炮塔大招 · 待实现", ultimate.tooltip_text]]:
		var content := RichTextLabel.new()
		_build_skill(dialog_body, content, "底盘被动" if item[0] == "底盘被动 · 待实现" else "炮塔大招", item[0] != "底盘被动 · 待实现")
		content.custom_minimum_size = Vector2(650, 64)
		content.add_theme_font_size_override("normal_font_size", 14)
		content.add_theme_font_size_override("bold_font_size", 18)
		var source: RichTextLabel = passive if item[0] == "底盘被动 · 待实现" else ultimate
		(content.get_meta("status_label") as Label).text = str(content.get_meta("heading"))+(" · 训练可用" if source.get_meta("ready",false) else " · 待实现")
		var parts := str(item[1]).split("：", true, 1)
		content.text = "[b]" + parts[0] + "[/b]\n" + (parts[1] if parts.size() > 1 else "")
	var resources := Label.new()
	resources.text = costs_text
	resources.add_theme_color_override("font_color", Color("edcc7b"))
	dialog_body.add_child(resources)
	dialog_body.size = Vector2(772, 540)
	await get_tree().process_frame
	await get_tree().process_frame
	dialog.reset_size()
	dialog.popup_centered(Vector2i(800, 650))
