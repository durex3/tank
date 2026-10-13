extends Control
## Workbench layout: directory/details left, preview/actions right.

signal training_requested(weapon_id: StringName, chassis_id: StringName)
signal back_requested

var equipment := EquipmentService.new()
var session := HangarSession.new()
var preview := HangarPreview.new()
var directory := HangarDirectory.new()
var details_panel := HangarDetailsPanel.new()
var progress_panel := HangarProgressPanel.new()
var art_stage := HangarArtStage.new()
var weapon_picker := OptionButton.new()
var chassis_picker := OptionButton.new()
var apply_button := Button.new()
var upgrade_button := Button.new()
var upgrade_fee := Label.new()
var upgrade_warning := Label.new()
var part_info := Button.new()
var equipped_label := Label.new()
var ownership_label := Label.new()
var train_button := Button.new()
var status_label := Label.new()
var coins_label := Label.new()
var inspected_id: StringName = &"cannon"

func _ready() -> void:
	equipment.open()
	theme = HangarStyle.create()
	_build_background()
	_build_selectors()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	_build_header(column)
	_build_body(column)
	weapon_picker.item_selected.connect(_on_selection)
	chassis_picker.item_selected.connect(_on_selection)
	restore_selection(equipment.profile.weapon_id, equipment.profile.chassis_id)
	directory.cards[inspected_id].grab_focus.call_deferred()

func _build_background() -> void:
	var background := TextureRect.new()
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("47343c"), Color("262136"), Color("344653")])
	gradient.offsets = PackedFloat32Array([0, 0.5, 1])
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_to = Vector2.ONE
	background.texture = texture
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

func _build_selectors() -> void:
	for definition: WeaponDef in HangarSession.WEAPONS:
		weapon_picker.add_item(HangarCopy.part_name(definition.id))
	for definition: ChassisDef in HangarSession.CHASSIS:
		chassis_picker.add_item(HangarCopy.part_name(definition.id))
	add_child(weapon_picker)
	add_child(chassis_picker)
	weapon_picker.hide()
	chassis_picker.hide()

func _build_header(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	parent.add_child(row)
	var back := Button.new()
	back.icon = preload("res://assets/derived/ui/back.svg")
	back.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back.tooltip_text = "返回 · Esc"
	back.custom_minimum_size = Vector2(44, 44)
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	back.add_theme_font_size_override("font_size", 28)
	var back_style := HangarStyle.panel(Color("201c2b"), Color("514858"), 22)
	back_style.set_content_margin_all(4)
	back.add_theme_stylebox_override("normal", back_style)
	for state: String in ["hover", "pressed"]:
		var style := HangarStyle.panel(Color("302b3e"), Color("7d718d"), 22)
		style.set_content_margin_all(4)
		back.add_theme_stylebox_override(state, style)
	back.pressed.connect(func() -> void: back_requested.emit())
	row.add_child(back)
	var heading := VBoxContainer.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	heading.add_theme_constant_override("separation", 0)
	row.add_child(heading)
	var title := Label.new()
	title.text = "整备车间"
	title.add_theme_font_size_override("font_size", 27)
	heading.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "自由组合 · 打造你的战车"
	subtitle.add_theme_font_size_override("font_size", 11)
	subtitle.add_theme_color_override("font_color", Color("a79eae"))
	heading.add_child(subtitle)
	coins_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coins_label.add_theme_font_size_override("font_size", 20)
	row.add_child(coins_label)
	equipped_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	equipped_label.add_theme_font_size_override("font_size", 13)
	equipped_label.add_theme_color_override("font_color", Color("a9b6c4"))
	row.add_child(equipped_label)

func _build_body(parent: VBoxContainer) -> void:
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(body)
	var left := VBoxContainer.new()
	left.custom_minimum_size.x = 650
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_stretch_ratio = 1.2
	body.add_child(left)
	directory.service = equipment
	directory.size_flags_vertical = Control.SIZE_EXPAND_FILL
	directory.part_selected.connect(_inspect_part)
	left.add_child(directory)
	directory.tabs.tab_changed.connect(func(index: int) -> void: _inspect_part(HangarSession.WEAPONS[session.weapon_index].id if index == 0 else HangarSession.CHASSIS[session.chassis_index].id))
	details_panel.custom_minimum_size.y = 240
	details_panel.training_requested.connect(_train)
	details_panel.upgrade_requested.connect(_upgrade_part)
	left.add_child(details_panel)
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 380
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	art_stage.preview = preview
	right.add_child(art_stage)
	var actions_panel := PanelContainer.new()
	actions_panel.add_theme_stylebox_override("panel", HangarStyle.panel(Color("211d2e"), Color("4a4057"), 16))
	right.add_child(actions_panel)
	var action_column := VBoxContainer.new()
	actions_panel.add_child(action_column)
	ownership_label.custom_minimum_size.y = 24
	ownership_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ownership_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	ownership_label.add_theme_font_size_override("font_size", 14)
	action_column.add_child(ownership_label)
	progress_panel.service = equipment
	progress_panel.changed.connect(_refresh)
	progress_panel.operation_failed.connect(func(reason: String) -> void: status_label.text = "操作失败：" + HangarCopy.error(reason))
	action_column.add_child(progress_panel)
	progress_panel.hide()
	upgrade_warning.custom_minimum_size.y = 28
	upgrade_warning.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	upgrade_warning.add_theme_font_size_override("font_size", 13)
	upgrade_warning.add_theme_color_override("font_color", Color("f5ce58"))
	var warning_style := HangarStyle.panel(Color("49402b"), Color.TRANSPARENT, 14)
	warning_style.set_content_margin_all(5)
	upgrade_warning.add_theme_stylebox_override("normal", warning_style)
	action_column.add_child(upgrade_warning)
	progress_panel.balance.hide()
	progress_panel.message.hide()
	_build_actions(action_column)
	status_label.add_theme_font_size_override("font_size", 12)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(status_label)

func _build_actions(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	upgrade_fee.custom_minimum_size.y = 22
	upgrade_fee.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_fee.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	upgrade_fee.add_theme_font_size_override("font_size", 13)
	upgrade_fee.add_theme_color_override("font_color", Color("ffe075"))
	parent.add_child(upgrade_fee)
	row.custom_minimum_size.y = 48
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var undo := Button.new()
	undo.text = "撤销改装"
	undo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	undo.custom_minimum_size.y = 48
	undo.size_flags_vertical = Control.SIZE_SHRINK_END
	undo.pressed.connect(func() -> void: restore_selection(equipment.profile.weapon_id, equipment.profile.chassis_id))
	row.add_child(undo)
	upgrade_button.text = "升级"
	upgrade_button.pressed.connect(_upgrade_part)
	upgrade_button.add_theme_stylebox_override("normal", HangarStyle.panel(Color("33d989"), Color("33d989"), 14))
	upgrade_button.add_theme_color_override("font_color", Color("092f28"))
	upgrade_button.add_theme_stylebox_override("disabled", HangarStyle.panel(Color("2c2838"), Color("4d455b"), 14))
	upgrade_button.add_theme_color_override("font_disabled_color", Color("8b839b"))
	upgrade_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(upgrade_button)
	part_info.text = "ⓘ"
	part_info.custom_minimum_size = Vector2(54, 54)
	part_info.size_flags_vertical = Control.SIZE_SHRINK_END
	part_info.pressed.connect(details_panel._show_dialog)
	row.add_child(part_info)
	apply_button.add_theme_stylebox_override("normal", HangarStyle.panel(Color("14c8dc"), Color("14c8dc"), 14))
	apply_button.add_theme_color_override("font_color", Color("092f38"))
	apply_button.add_theme_stylebox_override("disabled", HangarStyle.panel(Color("2c2838"), Color("4d455b"), 14))
	apply_button.add_theme_color_override("font_disabled_color", Color("8b839b"))
	apply_button.name = "ApplyLoadout"
	apply_button.custom_minimum_size.y = 48
	apply_button.size_flags_vertical = Control.SIZE_SHRINK_END
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(_apply_loadout)
	row.add_child(apply_button)
	HangarStyle.action_button(undo, Color("302b3e"), Color("e8e4f1"))
	HangarStyle.action_button(upgrade_button, Color("33d989"), Color("092f28"))
	HangarStyle.action_button(apply_button, Color("14c8dc"), Color("092f38"))
	train_button.name = "TrainLoadout"
	train_button.text = "试炼场"
	train_button.pressed.connect(_train)
	row.add_child(train_button)
	train_button.hide()

func _inspect_part(id: StringName) -> void:
	inspected_id = id
	var entry := PartCatalog.find(id)
	if entry.basic_ready:
		if entry.kind == PartEntry.Kind.TURRET:
			for i: int in range(HangarSession.WEAPONS.size()):
				if HangarSession.WEAPONS[i].id == id: weapon_picker.select(i)
		else:
			for i: int in range(HangarSession.CHASSIS.size()):
				if HangarSession.CHASSIS[i].id == id: chassis_picker.select(i)
		session.select(weapon_picker.selected, chassis_picker.selected)
	_refresh()

func _on_selection(_index: int) -> void:
	session.select(weapon_picker.selected, chassis_picker.selected)
	inspected_id = HangarSession.WEAPONS[session.weapon_index].id if directory.tabs.current_tab == 0 else HangarSession.CHASSIS[session.chassis_index].id
	_refresh()

func _refresh() -> void:
	var weapon := PartGrowth.weapon(HangarSession.WEAPONS[session.weapon_index].id, equipment.profile.level_of(HangarSession.WEAPONS[session.weapon_index].id))
	var chassis := PartGrowth.chassis(HangarSession.CHASSIS[session.chassis_index].id, equipment.profile.level_of(HangarSession.CHASSIS[session.chassis_index].id))
	session.stats = LoadoutResolver.resolve(weapon, chassis)
	preview.tank.configure_parts(weapon.id, chassis.id)
	art_stage.show_loadout(weapon, chassis, session.stats)
	directory.selected_id = inspected_id
	directory.weapon_id = weapon.id
	directory.chassis_id = chassis.id
	directory.refresh()
	details_panel.show_part(inspected_id, equipment.profile, weapon, chassis)
	progress_panel.show_parts(weapon.id, chassis.id)
	var kind: int = PartCatalog.find(inspected_id).kind
	for i: int in range(2):
		progress_panel.actions[i].get_parent().visible = i == kind
		progress_panel.actions[i].hide()
	upgrade_button.text = progress_panel.actions[kind].text
	upgrade_button.disabled = progress_panel.actions[kind].disabled
	upgrade_button.tooltip_text = HangarCopy.error(progress_panel.actions[kind].tooltip_text)
	details_panel.dialog_upgrade.text = upgrade_button.text
	details_panel.dialog_upgrade.disabled = upgrade_button.disabled or not PartCatalog.find(inspected_id).basic_ready
	details_panel.costs_text = "持有金币 %d · %s" % [equipment.profile.coins, upgrade_button.text]
	coins_label.text = "金币  %d" % equipment.profile.coins
	equipped_label.text = "当前装备\n" + PartCatalog.find(equipment.profile.weapon_id).display_name + " / " + PartCatalog.find(equipment.profile.chassis_id).display_name
	var pending: bool = not PartCatalog.find(inspected_id).basic_ready
	var owned: bool = equipment.profile.owns(inspected_id)
	ownership_label.text = "承载符合 · 可装配" if owned and not pending and session.stats.overload == 0 else (PartCatalog.find(inspected_id).display_name + " · 尚未拥有" if not owned else "当前组合超重")
	ownership_label.add_theme_color_override("font_color", Color("bdc2d0") if owned else Color("fa607c"))
	progress_panel.visible = false
	if pending:
		progress_panel.rows[kind].text = "设计预览 · 尚未开放装配"
		upgrade_button.text = "待开发"
	if pending:
		upgrade_button.disabled = true
		art_stage._status.text = "设计预览 · 当前部件暂不可装配"
		art_stage.show_design(inspected_id)
	var error := equipment.profile.application_error(weapon.id, chassis.id)
	var applied: bool = weapon.id == equipment.profile.weapon_id and chassis.id == equipment.profile.chassis_id
	apply_button.disabled = pending or applied or not error.is_empty() or not equipment.load_error.is_empty()
	apply_button.text = "待开发" if pending else ("已应用" if applied else ("尚未拥有" if error == "part_locked" else "应用改装"))
	train_button.disabled = pending or not LoadoutResolver.can_save(weapon, chassis)
	status_label.text = "设计预览 · 模型待制作，不可旋转" if pending else "试炼无收益 · 六能力已接入，训练场可补满能量"
	if not equipment.load_error.is_empty(): status_label.text = "存档异常，已阻止覆盖"
	_refresh_dock(kind, pending, owned, weapon, chassis)

func restore_selection(weapon_id: StringName, chassis_id: StringName) -> void:
	for i: int in range(HangarSession.WEAPONS.size()):
		if HangarSession.WEAPONS[i].id == weapon_id: weapon_picker.select(i)
	for i: int in range(HangarSession.CHASSIS.size()):
		if HangarSession.CHASSIS[i].id == chassis_id: chassis_picker.select(i)
	_on_selection(0)

func _apply_loadout() -> void:
	if not PartCatalog.find(inspected_id).basic_ready: return
	var error := equipment.apply(HangarSession.WEAPONS[session.weapon_index].id, HangarSession.CHASSIS[session.chassis_index].id)
	_refresh()
	if not error.is_empty(): status_label.text = "应用失败：" + HangarCopy.error(error)

func _train() -> void:
	if not PartCatalog.find(inspected_id).basic_ready: return
	training_requested.emit(HangarSession.WEAPONS[session.weapon_index].id, HangarSession.CHASSIS[session.chassis_index].id)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		back_requested.emit()
		get_viewport().set_input_as_handled()

func _upgrade_part() -> void:
	if upgrade_button.disabled: return
	var kind: int = PartCatalog.find(inspected_id).kind
	progress_panel.actions[kind].pressed.emit()

func _refresh_dock(kind: int, pending: bool, owned: bool, weapon: WeaponDef, chassis: ChassisDef) -> void:
	var show_upgrade: bool = HangarActionState.configure(self, kind, pending, owned)
	var reason: String = progress_panel.actions[kind].tooltip_text
	if show_upgrade and not reason.is_empty():
		ownership_label.text += " · " + HangarCopy.error(reason)
		ownership_label.add_theme_color_override("font_color", Color("fa607c"))
	if not pending and session.stats.overload > 0:
		var blocked: bool = not LoadoutResolver.can_save(weapon, chassis)
		ownership_label.text += " · 超重%d · %s" % [session.stats.overload, "无法装配" if blocked else "移速降低 %d%%" % roundi(LoadoutResolver.RULES.speed_penalty_per_overload * session.stats.overload * 100)]
		ownership_label.add_theme_color_override("font_color", Color("fa607c"))
		if blocked: apply_button.text = "无法装配"
	upgrade_button.custom_minimum_size.y = 48
	upgrade_button.tooltip_text = HangarCopy.error(reason) + "\n" + progress_panel.rows[kind].text
	upgrade_warning.text = ""
	if show_upgrade and owned:
		var level: int = equipment.profile.level_of(inspected_id)
		var after := PartGrowth.resolve(weapon.id, chassis.id, level + 1 if kind == 0 else equipment.profile.level_of(weapon.id), level + 1 if kind == 1 else equipment.profile.level_of(chassis.id))
		upgrade_warning.text = "升级后超重 %d：移速 %.1f → %.1f" % [after.overload, session.stats.move_speed, after.move_speed] if after.overload > session.stats.overload or after.move_speed < session.stats.move_speed else ""
	upgrade_warning.modulate.a = 1.0 if not upgrade_warning.text.is_empty() else 0.0
	if pending: ownership_label.text = "设计预览 · 暂不可装配"
