extends RefCounted
class_name ShockwaveAttack
## One sector submission, with wall occlusion and post-damage displacement.

static func execute(source: TankActor, yaw: float, tick: int, rules: BasicAbilityRules, actors: Array[TankActor], targets: Array[TrainingTarget], projectiles: ProjectileSystem, events: BattleEvents) -> void:
	var victims: Array[Damageable] = []
	for actor: TankActor in actors: victims.append(actor.hurtbox)
	for target: TrainingTarget in targets: victims.append(target.hurtbox())
	var id: int = projectiles.allocate_id()
	var forward := Vector3(sin(yaw),0,-cos(yaw))
	var space := source.get_world_3d().direct_space_state
	for victim: Damageable in victims:
		if victim.state.team_id == source.health.team_id or victim.state.hp <= 0: continue
		var difference: Vector3 = victim.global_position-source.global_position
		difference.y = 0.0
		if difference.length() > rules.shock_range+0.00001: continue
		var direction: Vector3 = difference.normalized() if difference.length_squared() > 0.000001 else forward
		if direction.dot(forward)+0.00001 < cos(deg_to_rad(rules.shock_half_angle)): continue
		var ray := PhysicsRayQueryParameters3D.create(source.global_position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT,victim.global_position+Vector3.UP*ProjectileSystem.SHOT_HEIGHT,1)
		if not space.intersect_ray(ray).is_empty(): continue
		var hit := HitEvent.new()
		hit.projectile_id = id
		hit.source_id = source.state.entity_id
		hit.source_life = source.health.life_index
		hit.team_id = source.health.team_id
		hit.target = victim.state
		hit.target_life = victim.state.life_index
		hit.damage = rules.shock_damage
		hit.position = victim.global_position
		hit.direction = direction
		hit.ability_damage = true
		hit.direct_projectile = false
		hit.push = direction*rules.shock_push
		projectiles.hits.append(hit)
	events.publish(&"ability_fired",tick,{"source_id":source.state.entity_id,"ability":&"shock","position":source.position,"yaw":yaw,"range":rules.shock_range,"half_angle":rules.shock_half_angle})
