extends RefCounted
class_name DashCharge
## Swept collision plans a bounded displacement; TankMotor remains the movement owner.

static func velocity(actor: TankActor, tick: int, rules: BasicAbilityRules, shots: ProjectileSystem, events: BattleEvents) -> Vector3:
	var state: AbilityState = actor.ability
	var direction := Vector3(sin(state.locked_yaw),0,-cos(state.locked_yaw))
	var distance: float = minf(state.dash_remaining,rules.dash_speed/60.0)
	var query := PhysicsShapeQueryParameters3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = actor.health.body_radius_m
	query.shape = sphere
	query.transform.origin = actor.position+Vector3.UP*0.7
	query.motion = direction*distance
	query.collision_mask = 5
	query.collide_with_areas = true
	query.exclude = [actor.hurtbox.get_rid()]
	var space := actor.get_world_3d().direct_space_state
	var contact: Dictionary = space.get_rest_info(query)
	var fraction: float = 0.0 if not contact.is_empty() else 1.0
	if contact.is_empty():
		var fractions := space.cast_motion(query)
		fraction = fractions[0]
		if fraction < 1.0:
			query.transform.origin += query.motion*minf(1.0,fractions[1]+0.0001)
			query.motion = Vector3.ZERO
			contact = space.get_rest_info(query)
	state.dash_remaining = maxf(0.0,state.dash_remaining-distance*fraction)
	if fraction < 1.0:
		state.dash_remaining = 0.0
		if not contact.is_empty():
			var victim := instance_from_id(contact.collider_id) as Damageable
			if victim != null and victim.state.hp > 0 and victim.state.team_id != actor.health.team_id:
				var hit := HitEvent.new()
				hit.projectile_id = shots.allocate_id()
				hit.source_id = actor.state.entity_id
				hit.source_life = actor.health.life_index
				hit.team_id = actor.health.team_id
				hit.target = victim.state
				hit.target_life = victim.state.life_index
				hit.damage = rules.dash_damage
				hit.direction = direction
				hit.position = contact.point
				hit.direct_projectile = false
				hit.ability_damage = true
				shots.hits.append(hit)
			events.publish(&"dash_contact",tick,{"source_id":actor.state.entity_id,"position":contact.point})
	return direction*distance*fraction*60.0
