extends Resource
class_name PartGrowthDef
## Explicit level tables. Cost index is the current level minus one.

@export var id: StringName
@export var values: PackedInt32Array
@export var loads: PackedInt32Array
@export var costs: PackedInt32Array
@export var unlock_cost: int = 0
