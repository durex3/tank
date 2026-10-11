extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for data: PartGrowthDef in PartGrowth.TABLES:
		assert(data.values.size() == 10 and data.loads.size() == 10 and data.costs.size() == 9)
		for i: int in range(10):
			assert(data.values[i] > 0 and data.loads[i] > 0)
			if i > 0:
				assert(data.values[i] >= data.values[i - 1] and data.loads[i] >= data.loads[i - 1])
	assert(PartGrowth.weapon(&"cannon", 2).damage == 124)
	assert(LoadoutCatalog.weapon(&"cannon").damage == 120)
	assert(PartGrowth.chassis(&"light_tracks", 2).max_hp == 515)
	assert(PartGrowth.weapon(&"cannon", 0) == null)
	assert(PartGrowth.chassis(&"light_tracks", 11) == null)
	var old: Dictionary = {"version": 1, "levels": {"cannon": 1, "light_tracks": 1}, "weapon": "cannon", "chassis": "light_tracks"}
	var migrated := EquipmentProfile.decode(old)
	assert(migrated != null and migrated.coins == 300 and migrated.snapshot().version == 2)
	var service := EquipmentService.new()
	service.store.path = "user://growth_test.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(service.store.path + suffix)
	assert(service.open().is_empty())
	assert(service.upgrade(&"autocannon", 1) == "part_locked")
	assert(service.unlock(&"rocket_pod") == "part_not_ready")
	assert(service.upgrade(&"cannon", 1).is_empty())
	assert(service.profile.level_of(&"cannon") == 2 and service.profile.coins == 280)
	assert(service.upgrade(&"cannon", 1) == "stale_level")
	assert(service.profile.coins == 280)
	assert(service.unlock(&"autocannon").is_empty())
	assert(service.profile.coins == 200 and service.profile.owns(&"autocannon"))
	assert(service.unlock(&"autocannon") == "already_owned")
	assert(service.profile.weapon_id == &"cannon")
	assert(service.store.load_profile().coins == 200)
	var session := MovementSession.new()
	assert(session.configure_loadout(&"cannon", &"light_tracks", 2, 2).is_empty())
	root.add_child(session)
	await physics_frame
	assert(session.actor.health.max_hp == 515 and session.simulation.weapon.damage == 124)
	assert(not session.configure_loadout(&"cannon", &"light_tracks", 3, 3).is_empty())
	session.stop()
	session.queue_free()
	await process_frame
	service.profile.coins = 0
	assert(service.upgrade(&"cannon", 2) == "insufficient_coins")
	service.profile.coins = 10000
	service.profile.levels["cannon"] = 10
	assert(service.upgrade(&"cannon", 10) == "max_level")
	service.profile.levels["cannon"] = 2
	service.store.path = "user://missing_growth_directory/save.json"
	assert(not service.upgrade(&"cannon", 2).is_empty())
	assert(service.profile.level_of(&"cannon") == 2 and service.profile.coins == 10000)
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://growth_test.json" + suffix)
	print("EQUIPMENT GROWTH TESTS: PASS")
	quit()
