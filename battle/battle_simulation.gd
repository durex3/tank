extends Node
class_name BattleSimulation
## Local authoritative movement/combat slice. No device, view or camera dependencies.

signal snapshot_ready(state: TankState)
signal rival_snapshot_ready(state: TankState)

const INPUT_TIMEOUT_TICKS: int = 6
var match_runtime: MatchRuntime
var paused: bool = false
var tick: int = 0
var session_epoch: int = 0
var actor: TankActor
var rival: TankActor
var rival_weapon: WeaponDef = preload("res://content/weapons/cannon.tres")
var rival_controller := WeaponController.new()
var lives := TrainingLives.new()
var abilities := AbilitySystem.new()
var _rival_command := PlayerCommand.new()
var _rival_sequence: int = -1
var _rival_input_tick: int = -100
var training_rules: TrainingRules = preload("res://content/training/default.tres")
var weapon: WeaponDef = preload("res://content/weapons/cannon.tres")
var weapon_controller := WeaponController.new()
var projectiles := ProjectileSystem.new()
var damage_resolver := DamageResolver.new()
var events := BattleEvents.new()
var targets: Array[TrainingTarget] = []
var _last_cooldown_remaining: int = -1
var _command := PlayerCommand.new()
var _last_sequence: int = -1
var _last_input_tick: int = -100

func enqueue_command(command: PlayerCommand) -> bool:
	if paused or _match_finished() or (actor != null and actor.health.hp <= 0):
		return false
	if not command.is_valid() or command.session_epoch != session_epoch:
		return false
	if command.sequence <= _last_sequence or command.client_tick > tick + 1:
		return false
	if command.client_tick < tick - INPUT_TIMEOUT_TICKS:
		return false
	_command = PlayerCommand.new()
	for field: String in ["session_epoch", "sequence", "client_tick", "move_x", "move_z", "turn_preference", "aim_yaw", "aim_distance_cm", "fire_held", "fire_request_id", "ability_request_id"]:
		_command.set(field, command.get(field))
	_last_sequence = command.sequence
	_last_input_tick = tick
	return true

func step() -> void:
	if paused or _match_finished():
		return
	tick += 1
	if tick - _last_input_tick > INPUT_TIMEOUT_TICKS:
		clear_command()
	lives.step(tick, events)
	_step_targets()
	if rival != null:
		if tick - _rival_input_tick > INPUT_TIMEOUT_TICKS:
			_rival_command = PlayerCommand.new()
		_move_actor(rival,_rival_command,1)
	_move_actor(actor,_command,session_epoch)
	_step_combat()
	snapshot_ready.emit(actor.state)
	if rival != null:
		rival_snapshot_ready.emit(rival.state)

func clear_command() -> void:
	var neutral := PlayerCommand.new()
	neutral.aim_yaw = _command.aim_yaw
	neutral.aim_distance_cm = _command.aim_distance_cm
	_command = neutral
	weapon_controller.cancel_pending()

func _step_targets() -> void:
	for target: TrainingTarget in targets:
		if target.state.respawn_tick >= 0 and tick >= target.state.respawn_tick:
			target.state.hp = target.state.max_hp
			target.state.life_index += 1
			target.state.respawn_tick = -1
			target.reset_motion()
			events.publish(&"entity_respawned", tick, {"target_id": target.state.entity_id,
				"hp": target.state.hp, "max_hp": target.state.max_hp})
		target.step_motion(abilities.movement_multiplier(target.state,target.position,tick))

func _step_combat() -> void:
	ChassisAbilities.reload_step(actor,weapon_controller,tick,abilities.rules)
	if rival != null: ChassisAbilities.reload_step(rival,rival_controller,tick,abilities.rules)
	actor.magazine.step(weapon,actor.health.life_index,tick)
	if rival != null: rival.magazine.step(rival_weapon,rival.health.life_index,tick)
	if not abilities.attack(actor,weapon_controller,tick,projectiles,events,targets):
		WeaponAttack.execute(actor, weapon, weapon_controller, _command, tick, projectiles, events,abilities.interval(actor),actor.ability.phase == &"storm",abilities.damage_multiplier(actor))
	if rival != null:
		if not abilities.attack(rival,rival_controller,tick,projectiles,events,targets):
			WeaponAttack.execute(rival, rival_weapon, rival_controller, _rival_command, tick, projectiles, events,abilities.interval(rival),rival.ability.phase == &"storm",abilities.damage_multiplier(rival))
	var space := actor.get_world_3d().direct_space_state
	abilities.collect_fields(tick,projectiles,targets,space)
	projectiles.step(space, tick)
	var results := damage_resolver.resolve_batch(projectiles.hits)
	projectiles.hits.clear()
	for impact: Dictionary in projectiles.impacts:
		events.publish(&"projectile_hit", tick, impact)
	projectiles.impacts.clear()
	for result: Dictionary in results:
		events.publish(&"damage_applied", tick, result)
		if result.died:
			lives.died(result.target_id, tick)
			if result.target_id == actor.state.entity_id:
				clear_command()
			if rival != null and result.target_id == rival.state.entity_id:
				_rival_command = PlayerCommand.new()
				rival_controller.cancel_pending()
			events.publish(&"entity_died", tick, result)
			for target: TrainingTarget in targets:
				if target.state.entity_id == result.target_id:
					target.state.respawn_tick = tick + training_rules.rebuild_ticks
	_commit_target_pushes(results)
	abilities.commit_slows(results,targets,tick)
	abilities.after_damage(results,tick,projectiles,events)
	actor.magazine.publish(actor.state.entity_id,tick,events)
	if rival != null: rival.magazine.publish(rival.state.entity_id,tick,events)
	if match_runtime != null:
		match_runtime.commit_tick(tick, results, events)
	var remaining := maxi(0, weapon_controller.next_fire_tick - tick)
	if remaining != _last_cooldown_remaining:
		_last_cooldown_remaining = remaining
		events.publish(&"cooldown_changed", tick, {"remaining_ticks": remaining, "interval_ticks": abilities.interval(actor)})

func replace_controller() -> int:
	session_epoch += 1
	_last_sequence = -1
	_last_input_tick = -100
	clear_command()
	var ready_tick := weapon_controller.next_fire_tick
	weapon_controller = WeaponController.new()
	weapon_controller.next_fire_tick = ready_tick
	return session_epoch

func set_paused(value: bool) -> void:
	paused = value
	clear_command()
	_rival_command = PlayerCommand.new()
	rival_controller.cancel_pending()
	if rival != null:
		rival.halt()
	if actor != null:
		actor.halt()

func enqueue_rival_command(command: PlayerCommand) -> bool:
	if paused or _match_finished() or rival == null or rival.health.hp <= 0:
		return false
	if not command.is_valid() or command.sequence <= _rival_sequence or command.client_tick != tick + 1:
		return false
	_rival_command = PlayerCommand.new()
	for field: String in ["sequence", "client_tick", "move_x", "move_z", "turn_preference", "aim_yaw", "aim_distance_cm", "fire_held", "fire_request_id", "ability_request_id"]:
		_rival_command.set(field, command.get(field))
	_rival_sequence = command.sequence
	_rival_input_tick = tick
	return true

func _match_finished() -> bool:
	return match_runtime != null and match_runtime.phase == MatchRuntime.Phase.FINISHED

func _move_actor(tank: TankActor, command: PlayerCommand, epoch: int) -> void:
	var before: Vector3 = tank.position
	var forced: bool = abilities.before_move(tank,command,tick,epoch,projectiles,events)
	tank.step(command,1.0/BattleClock.TICKS_PER_SECOND)
	abilities.after_move(tank,command,before,forced)

func _commit_target_pushes(results: Array[Dictionary]) -> void:
	# Batch health is final here: a target killed later in this tick must not move.
	for target: TrainingTarget in targets:
		if target.state.hp <= 0: continue
		var displacement := Vector3.ZERO
		for result: Dictionary in results:
			if result.target_id == target.state.entity_id and result.life_index == target.state.life_index:
				displacement += result.get("push",Vector3.ZERO) as Vector3
		target.commit_push(displacement.limit_length(abilities.rules.shock_push),abilities.rules.push_ticks)
