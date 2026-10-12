extends PanelContainer
class_name AbilityHud
## Committed ability readout and request controls. Passive has its own anchored card.

signal release_requested
signal refill_requested
var _energy := ProgressBar.new()
var _status := Label.new()
var _passive := Label.new()
var _amount := Label.new()
var release := Button.new()
var refill := Button.new()
var passive_panel := PanelContainer.new()
var training: bool = true

func _ready() -> void:
	var surface := HangarStyle.panel(Color(0.08,0.12,0.16,0.94),Color("52616a"),18)
	add_theme_stylebox_override("panel",surface)
	passive_panel.add_theme_stylebox_override("panel",surface)
	passive_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var passive_column := VBoxContainer.new()
	passive_panel.add_child(passive_column)
	var heading := Label.new()
	heading.text = BattleCopy.text(&"chassis_passive")
	heading.add_theme_font_size_override("font_size",12)
	heading.add_theme_color_override("font_color",HangarStyle.MUTED)
	passive_column.add_child(heading)
	_passive.add_theme_font_size_override("font_size",16)
	passive_column.add_child(_passive)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",8)
	add_child(column)
	_status.add_theme_font_size_override("font_size",18)
	column.add_child(_status)
	var meter_row := HBoxContainer.new()
	column.add_child(meter_row)
	_energy.show_percentage = false
	_energy.custom_minimum_size = Vector2(164,8)
	_energy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_energy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for pair: Array in [["background",Color("26343e")],["fill",Color("efb94e")]]:
		var style := HangarStyle.panel(pair[1],Color.TRANSPARENT,4)
		style.set_content_margin_all(0)
		_energy.add_theme_stylebox_override(pair[0],style)
	meter_row.add_child(_energy)
	_amount.add_theme_font_size_override("font_size",13)
	meter_row.add_child(_amount)
	release.text = BattleCopy.text(&"ability_release")
	release.focus_mode = Control.FOCUS_NONE
	HangarStyle.action_button(release,Color("efb94e"),HangarStyle.INK)
	release.pressed.connect(func() -> void: release_requested.emit())
	column.add_child(release)
	refill.text = BattleCopy.text(&"ability_refill")
	refill.focus_mode = Control.FOCUS_NONE
	refill.visible = training
	refill.add_theme_font_size_override("font_size",14)
	refill.custom_minimum_size.y = 36
	for state: String in ["normal","hover","pressed"]:
		var style := HangarStyle.panel(Color("26343e"),Color.TRANSPARENT,8)
		style.set_content_margin_all(4)
		refill.add_theme_stylebox_override(state,style)
	refill.pressed.connect(func() -> void: refill_requested.emit())
	column.add_child(refill)
	_status.text = BattleCopy.text(&"skill_preparing")

func on_event(event: Dictionary) -> void:
	if event.kind != &"ability_state" or event.source_id != 1: return
	var names: Dictionary = {&"cannon":"破阵重炮",&"autocannon":"火力风暴",&"scatter":"震荡清场"}
	var phases: Dictionary = {&"idle":"就绪" if event.ready else event.reason,&"breach":"蓄力中",&"shock":"准备中",&"storm":"火力强化",&"cooling":"散热中"}
	_status.text = "%s · %s" % [names.get(event.weapon,"未开放"),phases.get(event.phase,"")]
	_amount.text = "%d/%d" % [event.energy,event.energy_max]
	_energy.max_value = event.energy_max
	_energy.value = event.energy
	release.disabled = not event.ready
	refill.disabled = not event.alive
	match event.chassis:
		&"light_tracks": _passive.text = "巡航推进 · 推进中" if event.cruise else "巡航推进 · %d%%" % event.passive_progress
		&"heavy_tracks": _passive.text = "迎击装甲 · 防御中" if event.guard else "迎击装甲 · %d%%" % event.passive_progress
		&"scout_wheels": _passive.text = "脱险烟幕 · 就绪" if event.smoke_in == 0 else "脱险烟幕 · %.1f秒" % (event.smoke_in/60.0)

func set_touch_mode(value: bool) -> void:
	release.text = BattleCopy.text(&"ability_release_touch" if value else &"ability_release")
