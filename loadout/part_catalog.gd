extends RefCounted
class_name PartCatalog
## Complete design inventory, independent of currently playable LoadoutCatalog.

const DATA: Resource = preload("res://content/parts/catalog.tres")

static func find(id: StringName) -> PartEntry:
	for entry: PartEntry in DATA.entries:
		if entry.id == id:
			return entry
	return null

static func entries_of(kind: PartEntry.Kind) -> Array[PartEntry]:
	var result: Array[PartEntry] = []
	for entry: PartEntry in DATA.entries:
		if entry.kind == kind:
			result.append(entry)
	return result

static func validate() -> Array[String]:
	var errors: Array[String] = []
	var seen: Dictionary = {}
	for entry: PartEntry in DATA.entries:
		if entry.id == &"" or seen.has(entry.id):
			errors.append("Missing or duplicate part ID: %s" % entry.id)
		seen[entry.id] = true
		if entry.display_name.is_empty() or entry.unlock_rule_id == &"":
			errors.append("Missing metadata: %s" % entry.id)
		if entry.rarity < 0 or entry.rarity > PartEntry.Rarity.LEGENDARY:
			errors.append("Invalid rarity: %s" % entry.id)
		if entry.basic_ready:
			var exists: bool = LoadoutCatalog.weapon(entry.id) != null if entry.kind == PartEntry.Kind.TURRET else LoadoutCatalog.chassis(entry.id) != null
			if not exists:
				errors.append("Ready part has no gameplay definition: %s" % entry.id)
		if entry.starter and not entry.basic_ready:
			errors.append("Starter must be implemented: %s" % entry.id)
	return errors
