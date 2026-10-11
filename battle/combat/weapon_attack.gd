extends RefCounted
class_name WeaponAttack
## Shared attack execution for every controller; emits facts only after spawning.

static func execute(actor: TankActor, weapon: WeaponDef, gate: WeaponController, command: PlayerCommand, tick: int, projectiles: ProjectileSystem, events: BattleEvents) -> void:
	if actor.health.hp <= 0 or actor.health.protected:
		gate.cancel_pending()
		return
	var fire := gate.poll(command, tick, actor.stats.interval_ticks, weapon.continuous_fire)
	if fire.has("rejected"):
		events.publish(&"fire_rejected", tick, {"source_id": actor.state.entity_id, "reason": fire.rejected})
	if not fire.has("request_id"):
		return
	var pattern := WeaponPatterns.create(weapon.id)
	if pattern == null:
		events.publish(&"fire_rejected", tick, {"source_id": actor.state.entity_id, "reason": &"unknown_weapon"})
		return
	var muzzle := actor.position + Vector3.UP * ProjectileSystem.SHOT_HEIGHT
	muzzle += Vector3(sin(actor.state.aim_yaw), 0, -cos(actor.state.aim_yaw)) * ProjectileSystem.MUZZLE_OFFSET
	var space := actor.get_world_3d().direct_space_state
	var shots := projectiles.spawn_volley(space, actor.position, actor.state.aim_yaw, pattern.offsets(weapon), weapon, actor.state.entity_id, fire.request_id, tick, actor.health.team_id)
	if shots.is_empty():
		events.publish(&"fire_rejected", tick, {"source_id": actor.state.entity_id, "reason": &"projectile_budget"})
		return
	events.publish(&"weapon_fired", tick, {"source_id": actor.state.entity_id,
		"position": muzzle, "projectile_id": shots[0].projectile_id,
		"pellet_count": shots.size(), "next_fire_tick": gate.next_fire_tick})
