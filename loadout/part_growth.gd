extends RefCounted
class_name PartGrowth

const TABLES: Array[PartGrowthDef] = [
	preload("res://content/growth/cannon.tres"),
	preload("res://content/growth/autocannon.tres"),
	preload("res://content/growth/scatter.tres"),
	preload("res://content/growth/light_tracks.tres"),
	preload("res://content/growth/scout_wheels.tres"),
	preload("res://content/growth/heavy_tracks.tres"),
]

static func table(id: StringName) -> PartGrowthDef:
	for data: PartGrowthDef in TABLES:
		if data.id == id:
			return data
	return null

static func weapon(id: StringName, level: int) -> WeaponDef:
	var base := LoadoutCatalog.weapon(id)
	var data := table(id)
	if base == null or data == null or level < 1 or level > data.values.size():
		return null
	var result := base.duplicate(true) as WeaponDef
	result.damage = data.values[level - 1]
	result.weight = data.loads[level - 1]
	return result

static func chassis(id: StringName, level: int) -> ChassisDef:
	var base := LoadoutCatalog.chassis(id)
	var data := table(id)
	if base == null or data == null or level < 1 or level > data.values.size():
		return null
	var result := base.duplicate(true) as ChassisDef
	result.max_hp = data.values[level - 1]
	result.capacity = data.loads[level - 1]
	return result

static func resolve(weapon_id: StringName, chassis_id: StringName, weapon_level: int, chassis_level: int) -> ResolvedStats:
	var w := weapon(weapon_id, weapon_level)
	var c := chassis(chassis_id, chassis_level)
	if w == null or c == null:
		return null
	return LoadoutResolver.resolve(w, c)
