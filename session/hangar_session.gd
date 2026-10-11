extends RefCounted
class_name HangarSession
## Session-local preview draft; does not persist; app may create a new training session from these IDs.

const WEAPONS: Array[WeaponDef] = LoadoutCatalog.WEAPONS
const CHASSIS: Array[ChassisDef] = LoadoutCatalog.CHASSIS
var weapon_index: int = 0
var chassis_index: int = 0
var stats: ResolvedStats = LoadoutResolver.resolve(WEAPONS[0], CHASSIS[0])

func select(weapon: int, chassis: int) -> String:
	if weapon < 0 or weapon >= WEAPONS.size() or chassis < 0 or chassis >= CHASSIS.size():
		return "Selection index out of range"
	if not LoadoutResolver.can_save(WEAPONS[weapon], CHASSIS[chassis]):
		return "Invalid loadout"
	weapon_index = weapon
	chassis_index = chassis
	stats = LoadoutResolver.resolve(WEAPONS[weapon], CHASSIS[chassis])
	return ""
