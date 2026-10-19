extends RefCounted
class_name EquipmentProfile
## Player state only. Static definitions remain untouched.

const RULES: ProgressionRules = preload("res://content/growth/rules.tres")

var coins: int = RULES.starter_coins
var levels: Dictionary = {"cannon": 1, "light_tracks": 1}
var weapon_id: StringName = &"cannon"
var chassis_id: StringName = &"light_tracks"

func owns(id: StringName) -> bool:
	return levels.has(str(id))

func snapshot() -> Dictionary:
	return {"version": 2, "coins": coins, "levels": levels.duplicate(true), "weapon": str(weapon_id), "chassis": str(chassis_id)}

static func decode(data: Variant) -> EquipmentProfile:
	if not data is Dictionary or (data.get("version") != 1 and data.get("version") != 2) or not data.get("levels") is Dictionary:
		return null
	var result := EquipmentProfile.new()
	if data.version == 2:
		var balance: Variant = data.get("coins")
		if not (balance is int or balance is float) or not is_finite(float(balance)) or float(balance) != floor(float(balance)) or balance < 0 or balance > 1000000000:
			return null
		result.coins = int(balance)
	result.levels.clear()
	for id: Variant in data.levels:
		var value: Variant = data.levels[id]
		if not id is String or PartCatalog.find(StringName(id)) == null:
			return null
		if not (value is int or value is float) or not is_finite(float(value)) or float(value) != floor(float(value)) or value < 1 or value > 10:
			return null
		result.levels[id] = int(value)
	if not data.get("weapon") is String or not data.get("chassis") is String:
		return null
	result.weapon_id = StringName(data.weapon)
	result.chassis_id = StringName(data.chassis)
	if not result.application_error(result.weapon_id, result.chassis_id).is_empty():
		return null
	return result

func application_error(weapon: StringName, chassis: StringName) -> String:
	var weapon_def := PartGrowth.weapon(weapon, level_of(weapon))
	var chassis_def := PartGrowth.chassis(chassis, level_of(chassis))
	if weapon_def == null or chassis_def == null:
		return "part_not_ready"
	if not owns(weapon) or not owns(chassis):
		return "part_locked"
	if not LoadoutResolver.can_save(weapon_def, chassis_def):
		return "invalid_loadout"
	return ""

func level_of(id: StringName) -> int:
	return int(levels.get(str(id), 1))
