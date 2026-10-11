extends SceneTree

func _initialize() -> void:
	var store := EquipmentStore.new()
	store.path = "user://equipment_test.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path + suffix)
	var service := EquipmentService.new()
	service.store = store
	assert(service.open().is_empty())
	assert(service.profile.owns(&"cannon"))
	assert(not service.profile.owns(&"autocannon"))
	assert(service.apply(&"autocannon", &"light_tracks") == "part_locked")
	assert(service.apply(&"rocket_pod", &"light_tracks") == "part_not_ready")
	assert(not FileAccess.file_exists(store.path))
	assert(service.apply(&"cannon", &"light_tracks").is_empty())
	# Fixture unlock is not a production reward path.
	service.profile.levels["autocannon"] = 1
	assert(service.apply(&"autocannon", &"light_tracks").is_empty())
	assert(store.load_profile().weapon_id == &"autocannon")
	var bad: Dictionary = service.profile.snapshot()
	bad.version = 99
	assert(EquipmentProfile.decode(bad) == null)
	bad = service.profile.snapshot()
	bad.levels["cannon"] = 1.5
	assert(EquipmentProfile.decode(bad) == null)
	var file := FileAccess.open(store.path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	assert(store.load_profile().weapon_id == &"cannon")
	assert(store.recovered)
	assert(service.apply(&"autocannon", &"light_tracks").is_empty())
	assert(store.load_profile().weapon_id == &"autocannon")
	var failing := EquipmentStore.new()
	failing.path = "user://missing_directory/equipment.json"
	service.store = failing
	assert(not service.apply(&"cannon", &"light_tracks").is_empty())
	assert(service.profile.weapon_id == &"autocannon")
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(store.path + suffix)
	print("EQUIPMENT PROFILE TESTS: PASS")
	quit()
