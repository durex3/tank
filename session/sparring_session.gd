extends Node3D
class_name SparringSession
## Application adapter: world observations -> bot intents -> shared simulation.

var simulation: BattleSimulation
var spawn_point: Vector3 = Vector3(0, 0, 7)
var player: TankActor
var rival: TankActor
var brain := TrainingBotInput.new()
var rules: SparringRules = preload("res://content/training/sparring.tres")
var _view := TankView.new()

func _ready() -> void:
	brain.tuning = rules
	rival = preload("res://battle/actors/tank_actor.tscn").instantiate() as TankActor
	rival.state.entity_id = 2
	rival.position = spawn_point
	add_child(rival)
	var chassis := preload("res://content/chassis/light_tracks.tres") as ChassisDef
	rival.configure(LoadoutResolver.resolve(simulation.rival_weapon, chassis), chassis.acceleration)
	rival.health.team_id = 1
	rival.add_child(_view)
	var health := TankHealthView.new()
	health.entity_id = 2
	health.friendly = false
	health.visual = _view
	rival.add_child(health)
	health.show_health(rival.health.hp, rival.health.max_hp)
	simulation.events.published.connect(health.on_event)
	simulation.rival = rival
	simulation.rival_snapshot_ready.connect(_view.present)
	simulation.lives.tuning = rules
	simulation.lives.track(player, Vector3.ZERO)
	simulation.lives.track(rival, rules.spawn)
	reset_intent()

func sample_next_tick() -> void:
	var visible_target := has_line_of_sight()
	if not visible_target or player.health.hp <= 0 or player.health.protected:
		simulation.rival_controller.cancel_pending()
	var command := brain.sample(simulation.tick + 1, rival.position, player.position,
		rival.health.hp > 0 and not rival.health.protected,
		player.health.hp > 0 and not player.health.protected, visible_target, simulation.rival_weapon.range_m)
	simulation.enqueue_rival_command(command)

func has_line_of_sight() -> bool:
	var height := Vector3.UP * ProjectileSystem.SHOT_HEIGHT
	var query := PhysicsRayQueryParameters3D.create(rival.global_position + height, player.global_position + height, 1)
	return rival.get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func reset_intent() -> void:
	brain.reset(simulation.tick)
	simulation.rival_controller.cancel_pending()
