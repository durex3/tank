extends RefCounted
class_name DamageResolver
## One sorted tick batch. Projectile removal guarantees no cross-tick replay.

func resolve_batch(hits: Array[HitEvent]) -> Array[Dictionary]:
	hits.sort_custom(func(a: HitEvent, b: HitEvent) -> bool: return a.projectile_id < b.projectile_id)
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
		var actual := mini(target.hp, maxi(0, hit.damage))
		if actual == 0:
			continue
		target.hp -= actual
		results.append({"target_id": target.entity_id, "source_id": hit.source_id,
			"actual_damage": actual, "hp": target.hp, "max_hp": target.max_hp,
			"life_index": target.life_index, "died": target.hp == 0, "position": hit.position, "training": target.is_training})
	return results
