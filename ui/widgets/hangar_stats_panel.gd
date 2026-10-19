extends PanelContainer
class_name HangarStatsPanel
## Values are supplied by the shared loadout resolver through HangarSession.

var _title := Label.new()
var _values: Array[Label] = []

func _ready() -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)
	_title.add_theme_font_size_override("font_size", 22)
	column.add_child(_title)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	column.add_child(grid)
	for key: String in ["hp", "speed", "damage", "pellets", "cooldown", "weight"]:
		var item := VBoxContainer.new()
		item.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(item)
		var name_label := Label.new()
		name_label.text = HangarCopy.text("hangar." + key)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", HangarStyle.MUTED)
		item.add_child(name_label)
		var value := Label.new()
		value.add_theme_font_size_override("font_size", 21)
		item.add_child(value)
		_values.append(value)

func show_loadout(weapon: WeaponDef, chassis: ChassisDef, stats: ResolvedStats) -> void:
	_title.text = HangarCopy.part_name(weapon.id) + "  /  " + HangarCopy.part_name(chassis.id)
	var values: Array[String] = [str(stats.max_hp), "%.1f 米/秒" % stats.move_speed,
		str(stats.damage), str(weapon.pellet_count), "%.2f 秒" % (float(stats.interval_ticks) / BattleClock.TICKS_PER_SECOND), str(stats.weight)]
	for index: int in range(_values.size()):
		_values[index].text = values[index]
