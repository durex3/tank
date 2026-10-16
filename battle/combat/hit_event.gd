extends RefCounted
class_name HitEvent

var projectile_id: int
var source_id: int
var team_id: int
var target: DamageableState
var target_life: int
var damage: int
var position: Vector3

var direction: Vector3 = Vector3.ZERO
var direct_projectile: bool = true
var ability_damage: bool = false
var push: Vector3 = Vector3.ZERO

var travel_order: int = 0

var source_life: int = 0

var slow_multiplier: float = 1.0
var slow_ticks: int = 0
var bubble_hits: int = 0

var ability_id: StringName = &""
