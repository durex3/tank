extends RefCounted
class_name ContentValidator

static func validate(weapons: Array[WeaponDef], chassis_defs: Array[ChassisDef], abilities: Array[AbilityDef] = []) -> PackedStringArray:
	var errors := PackedStringArray()
	var ids: Dictionary = {}
	var ability_ids: Dictionary = {}
	for ability: AbilityDef in abilities:
		_check_id(ability.id, ids, errors)
		ability_ids[ability.id] = true
		if ability.cost < 0 or ability.damage < 0 or not is_finite(ability.duration_s) or ability.duration_s < 0.0:
			errors.append("Invalid ability: " + str(ability.id))
	for weapon: WeaponDef in weapons:
		_check_id(weapon.id, ids, errors)
		if not ability_ids.has(weapon.ability_id):
			errors.append("Unknown ability: " + str(weapon.ability_id))
		if not is_finite(weapon.spread_deg) or weapon.spread_deg < 0.0 or weapon.spread_deg > 360.0:
			errors.append("Invalid spread: " + str(weapon.id))
		if weapon.damage < 0 or weapon.weight < 0:
			errors.append("Weapon damage/weight must be nonnegative: " + str(weapon.id))
		if not is_finite(weapon.fire_interval_s) or weapon.fire_interval_s <= 0.0:
			errors.append("Invalid fire interval: " + str(weapon.id))
		if not is_finite(weapon.range_m) or weapon.range_m <= 0.0:
			errors.append("Invalid range: " + str(weapon.id))
		if not is_finite(weapon.projectile_speed) or weapon.projectile_speed <= 0.0:
			errors.append("Invalid projectile speed: " + str(weapon.id))
		if weapon.magazine_size < 0 or not is_finite(weapon.reload_s) or weapon.reload_s < 0.0 or (weapon.magazine_size > 0) != (weapon.reload_s > 0.0):
			errors.append("Invalid magazine: " + str(weapon.id))
		if not is_finite(weapon.projectile_radius) or weapon.projectile_radius < 0.0 or not is_finite(weapon.slow_multiplier) or weapon.slow_multiplier < 0.6 or weapon.slow_multiplier > 1.0 or weapon.slow_ticks < 0 or (weapon.slow_multiplier < 1.0) != (weapon.slow_ticks > 0):
			errors.append("Invalid projectile/slow: " + str(weapon.id))
		if weapon.pellet_count < 1 or weapon.pellet_count > 128:
			errors.append("Invalid pellet budget: " + str(weapon.id))
	for chassis: ChassisDef in chassis_defs:
		_check_id(chassis.id, ids, errors)
		if not is_finite(chassis.acceleration) or chassis.acceleration <= 0.0:
			errors.append("Invalid acceleration: " + str(chassis.id))
		if chassis.max_hp <= 0 or chassis.capacity < 0:
			errors.append("Invalid chassis hp/capacity: " + str(chassis.id))
		if not is_finite(chassis.move_speed) or chassis.move_speed <= 0.0:
			errors.append("Invalid move speed: " + str(chassis.id))
	return errors

static func _check_id(id: StringName, ids: Dictionary, errors: PackedStringArray) -> void:
	if id == &"" or ids.has(id):
		errors.append("Empty or duplicate content ID: " + str(id))
	ids[id] = true
