extends RefCounted
class_name WeaponPatterns

static func create(id: StringName) -> ShotPattern:
	match id:
		&"cannon", &"autocannon":
			return ShotPattern.new()
		&"scatter":
			return SpreadShotPattern.new()
	return null
