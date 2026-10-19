extends Node3D
## Preview-only uniform scaling. Not approved for the production part catalog.

const SIZE: PartSizeStyle = preload("res://content/presentation/part_size.tres")
const REVIEW: Resource = preload("res://content/presentation/modular_sample_preview.tres")

@export var turret: bool = false
@export var source_minimum: Vector3
@export var source_size: Vector3
@export var collar_source_z: float = 0.28

func _ready() -> void:
	var geometry := get_node("Geometry") as Node3D
	var width: float = SIZE.turret_bounds.size.x if turret else SIZE.chassis_bounds.size.x
	var factor: float = width / source_size.x
	if turret:
		factor *= REVIEW.turret_uniform_scale
	geometry.scale = Vector3.ONE * factor
	geometry.position.y = -source_minimum.y * factor
	geometry.position.x = -(source_minimum.x + source_size.x * 0.5) * factor
	if turret:
		geometry.rotation.y = PI
		# Collar location estimated from raw inspection; keep root and authoritative marker fixed.
		geometry.position.z = -collar_source_z * factor
		geometry.position.y += REVIEW.turret_seating_offset
