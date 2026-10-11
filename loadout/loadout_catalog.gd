extends RefCounted
class_name LoadoutCatalog
## Shared immutable content lookup. No scenes, device state or saved selection.

const WEAPONS: Array[WeaponDef] = [
	preload("res://content/weapons/cannon.tres"),
	preload("res://content/weapons/autocannon.tres"),
	preload("res://content/weapons/scatter.tres"),
]
const CHASSIS: Array[ChassisDef] = [
	preload("res://content/chassis/light_tracks.tres"),
	preload("res://content/chassis/scout_wheels.tres"),
	preload("res://content/chassis/heavy_tracks.tres"),
]

static func weapon(id: StringName) -> WeaponDef:
	for definition: WeaponDef in WEAPONS:
		if definition.id == id:
			return definition
	return null

static func chassis(id: StringName) -> ChassisDef:
	for definition: ChassisDef in CHASSIS:
		if definition.id == id:
			return definition
	return null
