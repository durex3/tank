extends ShotPattern
class_name SpreadShotPattern
## Total spread is symmetric and deterministic; no device-dependent RNG.

func offsets(weapon: WeaponDef) -> PackedFloat32Array:
	var result := PackedFloat32Array()
	if weapon.pellet_count < 2:
		return PackedFloat32Array([0.0])
	for index: int in range(weapon.pellet_count):
		result.append(deg_to_rad(weapon.spread_deg) * (float(index) / float(weapon.pellet_count - 1) - 0.5))
	return result
