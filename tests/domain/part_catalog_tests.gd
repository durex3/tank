extends SceneTree

func _initialize() -> void:
	var errors: Array[String] = PartCatalog.validate()
	assert(errors.is_empty(), str(errors))
	assert(PartCatalog.entries_of(PartEntry.Kind.TURRET).size() == 22)
	assert(PartCatalog.entries_of(PartEntry.Kind.CHASSIS).size() == 10)
	assert(PartCatalog.find(&"unknown") == null)
	var starters: int = 0
	var implemented: int = 0
	for entry: PartEntry in PartCatalog.DATA.entries:
		starters += int(entry.starter)
		implemented += int(entry.basic_ready)
		assert(entry.ultimate_ready == (entry.id in [&"cannon",&"autocannon",&"scatter",&"bubble_cannon"]))
		assert(entry.passive_ready == (entry.id in [&"light_tracks",&"heavy_tracks",&"scout_wheels"]))
		assert(entry.ability_role() == (&"ultimate" if entry.kind == PartEntry.Kind.TURRET else &"passive"))
	assert(starters == 2 and implemented == 7)
	assert(PartCatalog.find(&"autocannon").rarity == PartEntry.Rarity.COMMON)
	assert(not PartCatalog.find(&"autocannon").starter)
	assert(PartCatalog.find(&"rocket_pod").rarity == PartEntry.Rarity.LEGENDARY)
	assert(not PartCatalog.find(&"rocket_pod").basic_ready)
	assert(PartCatalog.find(&"cannon").starter)
	assert(PartCatalog.find(&"light_tracks").starter)
	print("PART CATALOG TESTS: PASS")
	quit()
