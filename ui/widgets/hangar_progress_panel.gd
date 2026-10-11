extends VBoxContainer
class_name HangarProgressPanel
## Displays service state; never computes growth or deducts money.

signal changed
signal operation_failed(reason: String)
var service: EquipmentService
var balance := Label.new()
var message := Label.new()
var rows: Array[Label] = []
var actions: Array[Button] = []
var ids: Array[StringName] = []

func _ready() -> void:
	custom_minimum_size.y = 72
	add_child(balance)
	for index: int in range(2):
		var row := HBoxContainer.new()
		add_child(row)
		var info := Label.new()
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 14)
		info.add_theme_color_override("font_color", Color("edcc7b"))
		row.add_child(info)
		rows.append(info)
		var action := Button.new()
		action.custom_minimum_size = Vector2(112, 48)
		row.add_child(action)
		actions.append(action)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(message)

func show_parts(weapon: StringName, chassis: StringName) -> void:
	ids = [weapon, chassis]
	balance.text = "金币 %d · 初始补给%d，无试炼收益" % [service.profile.coins, EquipmentProfile.RULES.starter_coins]
	for index: int in range(2):
		var id: StringName = ids[index]
		var data := PartGrowth.table(id)
		var level: int = service.profile.level_of(id)
		var owned: bool = service.profile.owns(id)
		var error: String = service.upgrade_error(id, level) if owned else service.unlock_error(id)
		var name_text: String = PartCatalog.find(id).display_name
		if owned and level < 10:
			rows[index].text = "%s Lv.%d→%d\n%s %d→%d · %s %d→%d" % [name_text, level, level + 1, "伤害" if index == 0 else "耐久", data.values[level - 1], data.values[level], "重量" if index == 0 else "承载", data.loads[level - 1], data.loads[level]]
			rows[index].text += _load_preview(index, level + 1)
			actions[index].text = "升级 · %d" % data.costs[level - 1]
		elif owned:
			rows[index].text = name_text + " · 已达Lv.10"
			actions[index].text = "已满级"
		else:
			rows[index].text = name_text + " · 未解锁（解锁不自动装备）"
			actions[index].text = "解锁 · %d" % data.unlock_cost
		actions[index].disabled = not error.is_empty()
		actions[index].tooltip_text = error
		for connection: Dictionary in actions[index].pressed.get_connections():
			actions[index].pressed.disconnect(connection.callable)
		actions[index].pressed.connect(_submit.bind(id, level, owned))

func _submit(id: StringName, level: int, owned: bool) -> void:
	var error: String = service.upgrade(id, level) if owned else service.unlock(id)
	message.text = "已保存" if error.is_empty() else "操作失败：" + error
	if error.is_empty():
		changed.emit()
	else:
		operation_failed.emit(error)

func _load_preview(changed_index: int, next_level: int) -> String:
	var wl: int = service.profile.level_of(ids[0])
	var cl: int = service.profile.level_of(ids[1])
	var before := PartGrowth.resolve(ids[0], ids[1], wl, cl)
	var after := PartGrowth.resolve(ids[0], ids[1], next_level if changed_index == 0 else wl, next_level if changed_index == 1 else cl)
	var c := PartGrowth.chassis(ids[1], next_level if changed_index == 1 else cl)
	return "\n升级后载重 %d/%d · 超重%d · 移速 %.1f→%.1f" % [after.weight, c.capacity, after.overload, before.move_speed, after.move_speed]
