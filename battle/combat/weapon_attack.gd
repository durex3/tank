extends RefCounted
class_name WeaponAttack
## Shared attack execution for every controller; emits facts only after spawning.

static func execute(actor: TankActor, weapon: WeaponDef, gate: WeaponController, command: PlayerCommand, tick: int, projectiles: ProjectileSystem, events: BattleEvents, interval: int = 0, ability_damage: bool = false, damage_multiplier: float = 1.0) -> void:
	actor.magazine.step(weapon,actor.health.life_index,tick)
	gate.next_fire_tick = maxi(gate.next_fire_tick,actor.magazine.reload_until)
	if actor.health.hp <= 0 or actor.health.protected:
		gate.cancel_pending()
		return
	var fire := gate.poll(command, tick, actor.stats.interval_ticks if interval <= 0 else interval, weapon.continuous_fire)
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
	# Copy before spawn so muzzle-overlap hits use the same scaled damage as flight hits.
	var attack_weapon: WeaponDef = weapon
	if damage_multiplier != 1.0:
		attack_weapon = weapon.duplicate() as WeaponDef
		attack_weapon.damage = maxi(1,roundi(weapon.damage*damage_multiplier))
	var shots := projectiles.spawn_volley(space, actor.position, actor.state.aim_yaw, pattern.offsets(weapon), attack_weapon, actor.state.entity_id, fire.request_id, tick, actor.health.team_id)
	for shot: ProjectileState in shots:
		shot.storm_round = ability_damage and weapon.id == &"autocannon"
		shot.ability_damage = ability_damage
		shot.owner_life = actor.health.life_index
	for impact: Dictionary in projectiles.impacts:
		if impact.projectile_id in shots.map(func(shot: ProjectileState) -> int: return shot.projectile_id):
			impact.ability_damage = ability_damage
			impact.storm = ability_damage and weapon.id == &"autocannon"
	for hit: HitEvent in projectiles.hits:
		if hit.source_id == actor.state.entity_id and hit.projectile_id in shots.map(func(shot: ProjectileState) -> int: return shot.projectile_id):
			hit.ability_damage = ability_damage
			hit.source_life = actor.health.life_index
	if shots.is_empty():
		events.publish(&"fire_rejected", tick, {"source_id": actor.state.entity_id, "reason": &"projectile_budget"})
		return
	actor.magazine.consume(tick)
	gate.next_fire_tick = maxi(gate.next_fire_tick,actor.magazine.reload_until)
	events.publish(&"weapon_fired", tick, {"source_id": actor.state.entity_id,
		"position": muzzle, "weapon":weapon.id, "direction":Vector3(sin(actor.state.aim_yaw),0,-cos(actor.state.aim_yaw)), "projectile_id": shots[0].projectile_id, "projectile_ids":shots.map(func(shot: ProjectileState) -> int: return shot.projectile_id),
		"interval_ticks": actor.stats.interval_ticks if interval <= 0 else interval, "pellet_count": shots.size(), "next_fire_tick": gate.next_fire_tick})
