extends AnimatableBody3D
class_name TrainingTarget
## Physical training entity. Rendering is attached by the session.

var state := DamageableState.new()
var motion_origin: Vector3 = Vector3.ZERO
var motion_extent: float = 0.0
var motion_speed: float = 0.0
var _motion_tick: int = 0
var _hurtbox := Damageable.new()

func _ready() -> void:
	motion_origin = position
	sync_to_physics = false
	collision_layer = 2
	collision_mask = 2
	var shape := CylinderShape3D.new()
	shape.radius = 0.65
	shape.height = 1.4
	var body_shape := CollisionShape3D.new()
	body_shape.shape = shape
	body_shape.position.y = 0.7
	add_child(body_shape)
	_hurtbox.state = state
	_hurtbox.collision_layer = 4
	_hurtbox.collision_mask = 0
	add_child(_hurtbox)
	var hit_shape := CollisionShape3D.new()
	hit_shape.shape = shape
	hit_shape.position.y = 0.7
	_hurtbox.add_child(hit_shape)

func configure_motion(extent: float, speed: float) -> void:
	assert(is_finite(extent) and extent >= 0.0 and is_finite(speed) and speed >= 0.0)
	motion_origin = position
	motion_extent = extent
	motion_speed = speed
	reset_motion()

func step_motion() -> void:
	if state.hp <= 0 or motion_extent <= 0.0 or motion_speed <= 0.0:
		return
	_motion_tick += 1
	var distance := float(_motion_tick) * motion_speed / BattleClock.TICKS_PER_SECOND
	var offset := motion_extent - absf(fposmod(distance + motion_extent, motion_extent * 4.0) - motion_extent * 2.0)
	position = motion_origin + Vector3.RIGHT * offset
	_sync_collision()

func reset_motion() -> void:
	_motion_tick = 0
	position = motion_origin
	_sync_collision()

func _sync_collision() -> void:
	# Flush both body and child Area transforms before this tick's projectile query.
	force_update_transform()
	_hurtbox.force_update_transform()
