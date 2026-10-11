extends Resource
class_name PartEntry
## Read-only catalogue metadata; ownership and levels belong to profile.

enum Kind { TURRET, CHASSIS }
enum Rarity { COMMON, UNCOMMON, EPIC, LEGENDARY }

@export var id: StringName
@export var display_name: String
@export var kind: Kind = Kind.TURRET
@export var rarity: Rarity = Rarity.COMMON
@export var unlock_rule_id: StringName
@export_multiline var basic_summary: String
@export_multiline var ability_summary: String
@export_multiline var role_summary: String
@export var starter: bool = false
@export var basic_ready: bool = false
@export var ultimate_ready: bool = false
@export var passive_ready: bool = false

func ability_role() -> StringName:
	return &"ultimate" if kind == Kind.TURRET else &"passive"

func rarity_name() -> String:
	return ["普通", "罕见", "史诗", "传奇"][rarity]
