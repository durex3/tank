extends RefCounted
class_name LoadoutResolver

static func resolve(weapon: WeaponDef, chassis: ChassisDef) -> ResolvedStats:
	assert(weapon != null and chassis != null, "Missing loadout definition")
	var result := ResolvedStats.new()
	result.max_hp = chassis.max_hp
	result.weight = weapon.weight
	result.overload = maxi(0, weapon.weight - chassis.capacity)
	result.move_speed = chassis.move_speed * maxf(0.6, 1.0 - 0.15 * result.overload)
	result.damage = weapon.damage
	result.interval_ticks = BattleClock.seconds_to_ticks(weapon.fire_interval_s)
	result.ability_id = weapon.ability_id
	result.passive_id = chassis.passive_id
	return result

static func can_save(weapon: WeaponDef, chassis: ChassisDef) -> bool:
	return weapon != null and chassis != null and weapon.weight - chassis.capacity <= 2
