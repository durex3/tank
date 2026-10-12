extends RefCounted
class_name ChassisAbilities
## Passive state transitions use actual autonomous displacement, never presentation motion.

static func after_move(actor: TankActor, command: PlayerCommand, before: Vector3, forced: bool, rules: BasicAbilityRules) -> void:
	var state: AbilityState = actor.ability
	var moving: bool = command.move_x != 0 or command.move_z != 0
	var displacement: float = actor.position.distance_to(before)
	var autonomous_speed: float = displacement * BattleClock.TICKS_PER_SECOND
	if actor.chassis_id == &"light_tracks":
		var valid: bool = moving and not forced and autonomous_speed + 0.0001 >= actor.stats.move_speed * rules.cruise_threshold
		if valid:
			state.release_ticks = 0
			state.charge_ticks = mini(rules.cruise_charge,state.charge_ticks+1)
			state.cruise_active = state.charge_ticks >= rules.cruise_charge
		else:
			state.release_ticks += 1
			if state.release_ticks >= rules.cruise_release:
				state.cruise_active = false
				state.charge_ticks = 0
	if actor.chassis_id == &"heavy_tracks":
		if moving or forced or autonomous_speed > 0.1:
			state.charge_ticks = 0
			state.guard_active = false
		else:
			state.charge_ticks = mini(rules.guard_charge,state.charge_ticks+1)
			state.guard_active = state.charge_ticks >= rules.guard_charge
	actor.health.guard_reduction = rules.guard_reduction if state.guard_active else 0.0
	actor.health.guard_yaw = actor.state.body_yaw
	actor.health.guard_half_angle = rules.guard_half_angle
