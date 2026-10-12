extends SceneTree

var failures: int = 0

func _initialize() -> void:
	var training := load("res://content/training/default.tres") as TrainingRules
	check(training.validate().is_empty(), "training content valid")
	var bad_training := training.duplicate() as TrainingRules
	bad_training.target_motion_speeds = PackedFloat32Array()
	check(not bad_training.validate().is_empty(), "training array mismatch rejected")
	bad_training = training.duplicate() as TrainingRules
	bad_training.target_positions = PackedVector3Array([Vector3(NAN, 0, 0), Vector3.ZERO, Vector3.ZERO])
	check(not bad_training.validate().is_empty(), "training NaN origin rejected")
	var weapons: Array[WeaponDef] = []
	var chassis_defs: Array[ChassisDef] = []
	var abilities: Array[AbilityDef] = []
	for id: String in ["pierce_shot", "overdrive", "ram"]:
		abilities.append(load("res://content/abilities/" + id + ".tres") as AbilityDef)
	for id: String in ["cannon", "autocannon", "scatter"]:
		weapons.append(load("res://content/weapons/" + id + ".tres") as WeaponDef)
	for id: String in ["light_tracks", "scout_wheels", "heavy_tracks"]:
		chassis_defs.append(load("res://content/chassis/" + id + ".tres") as ChassisDef)
	check(ContentValidator.validate(weapons, chassis_defs, abilities).is_empty(), "content is valid")
	for weapon: WeaponDef in weapons:
		for chassis: ChassisDef in chassis_defs:
			check(LoadoutResolver.can_save(weapon, chassis), "nine baseline combinations save")
	var resolved := LoadoutResolver.resolve(weapons[0], chassis_defs[0])
	check(resolved.interval_ticks == 48 and resolved.max_hp == 500, "cannon tick/hp")
	check(is_equal_approx(weapons[0].nominal_dps(), 150.0), "nominal DPS")
	check(BattleClock.seconds_to_ticks(0.001) == 1, "minimum cooldown")
	check(BattleClock.seconds_to_ticks(0.16) == 10, "fractional tick rounds up")
	var overloaded := weapons[0].duplicate() as WeaponDef
	overloaded.weight = 3
	check(LoadoutResolver.can_save(overloaded, chassis_defs[0]), "overload one accepted")
	check(is_equal_approx(LoadoutResolver.resolve(overloaded, chassis_defs[0]).move_speed, 4.8), "overload one reduces speed twenty percent")
	overloaded.weight = 4
	check(not LoadoutResolver.can_save(overloaded, chassis_defs[0]), "overload two rejected")
	overloaded.weight = 20
	check(not LoadoutResolver.can_save(overloaded, chassis_defs[0]), "extreme overload rejected")
	check(is_equal_approx(LoadoutResolver.resolve(overloaded, chassis_defs[0]).move_speed, 3.6), "invalid draft preview retains speed floor")
	resolved.max_hp = 1
	check(LoadoutResolver.resolve(weapons[0], chassis_defs[0]).max_hp == 500, "state independence")
	weapons.append(weapons[0])
	check(not ContentValidator.validate(weapons, chassis_defs, abilities).is_empty(), "duplicate IDs rejected")
	weapons.pop_back()
	var bad := weapons[0].duplicate() as WeaponDef
	bad.fire_interval_s = NAN
	weapons.append(bad)
	check(not ContentValidator.validate(weapons, chassis_defs, abilities).is_empty(), "NaN interval rejected")
	weapons.pop_back()
	bad = weapons[0].duplicate() as WeaponDef
	bad.ability_id = &"missing"
	weapons.append(bad)
	check(not ContentValidator.validate(weapons, chassis_defs, abilities).is_empty(), "missing ability rejected")
	var command := PlayerCommand.new()
	check(command.is_valid(), "neutral command")
	command.move_x = 128
	check(not command.is_valid(), "input range rejected")
	print("DOMAIN TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
