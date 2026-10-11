extends RefCounted
class_name EquipmentService
## Application transaction boundary. No UI or combat state.

var store := EquipmentStore.new()
var profile := EquipmentProfile.new()
var load_error: String = ""

func open() -> String:
	var loaded := store.load_profile()
	load_error = store.last_error
	if loaded != null:
		profile = loaded
	return load_error

func apply(weapon: StringName, chassis: StringName) -> String:
	if not load_error.is_empty():
		return load_error
	var error := profile.application_error(weapon, chassis)
	if not error.is_empty():
		return error
	var candidate := EquipmentProfile.decode(profile.snapshot())
	candidate.weapon_id = weapon
	candidate.chassis_id = chassis
	error = store.save_profile(candidate)
	if error.is_empty():
		profile = candidate
	return error

func upgrade_error(id: StringName, expected_level: int) -> String:
	if not load_error.is_empty():
		return load_error
	var data := PartGrowth.table(id)
	if data == null:
		return "part_not_ready"
	if not profile.owns(id):
		return "part_locked"
	var current: int = profile.level_of(id)
	if current != expected_level:
		return "stale_level"
	if current >= data.values.size():
		return "max_level"
	if profile.coins < data.costs[current - 1]:
		return "insufficient_coins"
	var candidate := EquipmentProfile.decode(profile.snapshot())
	candidate.levels[str(id)] = current + 1
	return candidate.application_error(candidate.weapon_id, candidate.chassis_id)

func upgrade(id: StringName, expected_level: int) -> String:
	var error := upgrade_error(id, expected_level)
	if not error.is_empty():
		return error
	var candidate := EquipmentProfile.decode(profile.snapshot())
	candidate.coins -= PartGrowth.table(id).costs[expected_level - 1]
	candidate.levels[str(id)] = expected_level + 1
	return _commit(candidate)

func unlock_error(id: StringName) -> String:
	if not load_error.is_empty():
		return load_error
	var data := PartGrowth.table(id)
	if data == null:
		return "part_not_ready"
	if profile.owns(id):
		return "already_owned"
	if data.unlock_cost <= 0:
		return "unlock_unavailable"
	return "insufficient_coins" if profile.coins < data.unlock_cost else ""

func unlock(id: StringName) -> String:
	var error := unlock_error(id)
	if not error.is_empty():
		return error
	var candidate := EquipmentProfile.decode(profile.snapshot())
	candidate.coins -= PartGrowth.table(id).unlock_cost
	candidate.levels[str(id)] = 1
	return _commit(candidate)

func _commit(candidate: EquipmentProfile) -> String:
	var error := store.save_profile(candidate)
	if error.is_empty():
		profile = candidate
	return error
