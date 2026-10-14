extends RefCounted
class_name ProjectileState

var projectile_id: int
var owner_id: int
var owner_life: int = 0
var team_id: int = 0
var request_id: int
var spawn_tick: int
var lifetime_ticks: int
var position: Vector3
var previous_position: Vector3
var direction: Vector3
var speed: float
var remaining_range: float
var damage: int
var active: bool = true

var radius: float = 0.0
var pierce_damage: PackedInt32Array = PackedInt32Array()
var hit_lives: Dictionary = {}
var excluded: Array[RID] = []
var ability_damage: bool = false

var storm_round: bool = false

var weapon_id: StringName = &"cannon"
var kind: StringName = &"normal"
var slow_multiplier: float = 1.0
var slow_ticks: int = 0
var curtain_id: int = 0
