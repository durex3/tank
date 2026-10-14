extends CharacterBody3D
class_name TankActor
## Physics adapter, independent from model, camera and device input.

var state := TankState.new()
var health := DamageableState.new()
var hurtbox := Damageable.new()
var ability := AbilityState.new()
var magazine := MagazineState.new()
var weapon_id: StringName
var chassis_id: StringName
var speed_multiplier: float = 1.0
var forced_velocity: Vector3 = Vector3.ZERO
var stats: ResolvedStats
@onready var motor: TankMotor = $Motor

func _ready() -> void:
	health.entity_id = state.entity_id
	health.team_id = 0
	hurtbox.name = "Hurtbox"
	hurtbox.state = health
	hurtbox.collision_layer = 4
	hurtbox.collision_mask = 0
	add_child(hurtbox)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.55
	shape.height = 1.4
	collision.shape = shape
	collision.position.y = 0.7
	hurtbox.add_child(collision)

func configure(resolved: ResolvedStats, acceleration: float) -> void:
	stats = resolved
	health.entity_id = state.entity_id
	health.max_hp = resolved.max_hp
	health.hp = resolved.max_hp
	motor.acceleration = acceleration

func step(command: PlayerCommand, delta: float) -> void:
	assert(stats != null, "Tank must be configured")
	if health.hp <= 0:
		halt()
		return
	state.aim_yaw = float(command.aim_yaw) / 65536.0 * TAU
	motor.step(self, state, Vector2(command.move_x, command.move_z) / 127.0, stats.move_speed * speed_multiplier, delta, forced_velocity,command.turn_preference)
	force_update_transform()
	hurtbox.force_update_transform()

func halt() -> void:
	motor.halt(self, state)
