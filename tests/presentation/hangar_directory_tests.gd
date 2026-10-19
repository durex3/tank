extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://directory_fixture.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(screen.equipment.store.path + suffix)
	root.add_child(screen)
	await process_frame
	# Both rich-text font slots must cover actual Chinese content, including bold.
	for slot: String in ["normal_font", "bold_font"]:
		var font: Font = screen.theme.get_font(slot, "RichTextLabel")
		for entry: PartEntry in PartCatalog.DATA.entries:
			for character: String in entry.ability_summary:
				var code: int = character.unicode_at(0)
				if code >= 0x4E00 and code <= 0x9FFF:
					check(font.has_char(code), slot + " covers " + character)
	check(screen.directory.cards.size() == 32, "complete stable card inventory")
	check(screen.directory.count.text == "炮塔 22 / 22", "turret tab count")
	check(screen.directory.cards[&"cannon"].upgrade_mark.visible, "eligible owned part has upgrade arrow")
	check(not screen.directory.cards[&"autocannon"].upgrade_mark.visible, "locked part has no upgrade arrow")
	for entry: PartEntry in PartCatalog.DATA.entries:
		var icon := HangarPartArtCatalog.texture(entry.id) as AtlasTexture
		check(icon != null and icon.region.has_area(), "every part has isolated illustration")
		check(icon.atlas.get_width() == int(icon.region.size.x) and icon.atlas.get_height() == int(icon.region.size.y), "icon upload contains only its own pixels")
		check(not entry.basic_summary.is_empty() and not entry.ability_summary.is_empty(), "every detail has stats and correct ability source")
	screen.directory.filter.select(1)
	screen.directory.refresh()
	check(screen.directory.count.text == "炮塔 1 / 22", "owned filter excludes ordinary locked parts")
	screen.directory.filter.select(0)
	screen.directory.search.text = "磁轨"
	screen.directory.refresh()
	check(screen.directory.count.text == "炮塔 1 / 22", "name search")
	var previous: Dictionary = screen.equipment.profile.snapshot()
	var preview_size: Vector2 = screen.art_stage.artwork.size
	screen.directory.cards[&"rail_sniper"].pressed.emit()
	check(screen.inspected_id == &"rail_sniper", "pending part can be inspected")
	check(screen.directory.cards[&"cannon"].equipped_mark.visible, "browsing retains applied checkmark")
	check(not screen.directory.cards[&"rail_sniper"].equipped_mark.visible, "browsed card is not marked equipped")
	check(screen.details_panel.title.text == PartCatalog.find(&"rail_sniper").display_name, "selected details stay synchronized")
	check(screen.apply_button.disabled and screen.train_button.disabled, "pending part cannot apply or trial")
	check(screen.equipment.profile.snapshot() == previous, "inspection cannot mutate player state")
	for frame: int in range(4): await process_frame
	check(screen.art_stage.artwork.size.is_equal_approx(preview_size), "pending selection keeps preview stage size")
	check(not screen.details_panel.passive.scroll_active and not screen.details_panel.ultimate.scroll_active, "skill cards do not have internal scrollbars")
	screen.directory.search.text = ""
	screen.directory.tabs.current_tab = 1
	await process_frame
	check(screen.directory.count.text == "底盘 10 / 10", "chassis tab count")
	screen.directory.cards[&"scout_wheels"].pressed.emit()
	check(screen.session.chassis_index == 1, "chassis card updates draft")
	check(screen.details_panel.rows[0].bar.value == 400, "chassis HP bar matches resolved value")
	check(screen.details_panel.rows[1].difference.text.contains("+1.2"), "speed comparison shows improvement")
	check(screen.apply_button.disabled, "ordinary locked chassis remains unequippable")
	screen.directory.tabs.current_tab = 0
	screen.directory.cards[&"autocannon"].pressed.emit()
	check(is_equal_approx(screen.details_panel.rows[1].bar.value, 150.0), "DPS uses rounded simulation ticks")
	await screen.details_panel._show_dialog()
	for frame: int in range(3): await process_frame
	check(screen.details_panel.dialog.size.y <= 650, "structured details window fits desktop height")
	screen.details_panel.dialog.hide()
	screen.free()
	await process_frame
	print("HANGAR DIRECTORY TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
