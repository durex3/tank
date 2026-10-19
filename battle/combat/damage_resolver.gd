extends RefCounted
class_name DamageResolver
## One sorted tick batch. Projectile removal guarantees no cross-tick replay.

func resolve_batch(hits: Array[HitEvent]) -> Array[Dictionary]:
	hits.sort_custom(_hit_before)
	var seen: Dictionary = {}
	var results: Array[Dictionary] = []
	for hit: HitEvent in hits:
		var target := hit.target
		if target == null or target.life_index != hit.target_life:
			continue
		var key := "%d:%d:%d" % [hit.projectile_id, target.entity_id, target.life_index]
		if seen.has(key) or target.hp <= 0 or target.protected or target.team_id == hit.team_id:
			continue
		seen[key] = true
		var damage: int = maxi(0,hit.damage)
		var reduced: bool = false
		if damage > 0 and target.guard_reduction > 0.0 and hit.direct_projectile and not hit.direction.is_zero_approx():
			var front := Vector3(sin(target.guard_yaw),0,-cos(target.guard_yaw))
			if front.dot(-hit.direction.normalized())+0.00001 >= cos(deg_to_rad(target.guard_half_angle)):
				damage = maxi(1,roundi(damage*(1.0-target.guard_reduction)))
				reduced = true
		var actual := mini(target.hp, damage)
		if actual == 0:
			continue
		target.hp -= actual
		results.append({"target_id": target.entity_id, "source_id": hit.source_id,
			"projectile_id":hit.projectile_id,"ability_id":hit.ability_id,"actual_damage": actual, "hp": target.hp, "max_hp": target.max_hp,
			"life_index": target.life_index, "died": target.hp == 0, "position": hit.position, "training": target.is_training, "source_life": hit.source_life, "ability_damage": hit.ability_damage, "guarded": reduced, "push": hit.push, "slow_multiplier":hit.slow_multiplier, "slow_ticks":hit.slow_ticks,"bubble_hits":hit.bubble_hits})
	return results

static func _hit_before(a: HitEvent, b: HitEvent) -> bool:
	if a.projectile_id != b.projectile_id: return a.projectile_id < b.projectile_id
	if a.travel_order != b.travel_order: return a.travel_order < b.travel_order
	var aid: int = a.target.entity_id if a.target != null else -1
	var bid: int = b.target.entity_id if b.target != null else -1
	return aid < bid
