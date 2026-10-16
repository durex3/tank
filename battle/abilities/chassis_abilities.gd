extends RefCounted
class_name ChassisAbilities
## Movement reload and directional armor. Forced travel never earns reload progress.

static func after_move(actor: TankActor, command: PlayerCommand, before: Vector3, forced: bool, rules: BasicAbilityRules) -> void:
	var state: AbilityState = actor.ability
	var moving: bool = command.move_x != 0 or command.move_z != 0
	var speed: float = actor.position.distance_to(before)*BattleClock.TICKS_PER_SECOND
	state.cruise_active = actor.chassis_id == &"light_tracks" and moving and not forced and speed >= rules.reload_min_speed and state.phase == &"idle"
	if not state.cruise_active: state.reload_credit = 0.0
	state.guard_active = actor.chassis_id == &"heavy_tracks"
	actor.health.guard_reduction = rules.guard_reduction if state.guard_active else 0.0
	actor.health.guard_yaw = actor.state.body_yaw
	actor.health.guard_half_angle = rules.guard_half_angle

static func reload_step(actor: TankActor, gate: WeaponController, tick: int, rules: BasicAbilityRules) -> void:
	var state: AbilityState = actor.ability
	if not state.cruise_active or actor.health.hp <= 0 or state.phase != &"idle": return
	if gate.next_fire_tick <= tick and actor.magazine.reload_until <= tick:
		state.reload_credit = 0.0
		return
	state.reload_credit += rules.reload_bonus
	var extra: int = floori(state.reload_credit)
	state.reload_credit -= extra
	if extra == 0: return
	gate.next_fire_tick = maxi(tick,gate.next_fire_tick-extra)
	if actor.magazine.reload_until > tick:
		actor.magazine.reload_until = maxi(tick,actor.magazine.reload_until-extra)
