extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://hangar_growth_fixture.json"
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(screen.equipment.store.path + suffix)
	root.add_child(screen)
	for i: int in range(10):
		await process_frame
	for i: int in range(5):
		await process_frame
	assert(screen.equipment.profile.coins == 300)
	assert(screen.progress_panel.actions[0].text == "升级 · 20")
	assert(screen.upgrade_button.text == "升级" and screen.upgrade_fee.text == "金币 20")
	screen.upgrade_button.pressed.emit()
	assert(screen.progress_panel.upgrade_dialog.visible)
	assert(screen.equipment.profile.coins == 300)
	assert(screen.equipment.profile.level_of(&"cannon") == 1)
	assert(screen.progress_panel.upgrade_dialog.comparison.get_child(5).text == "120")
	assert(screen.progress_panel.upgrade_dialog.comparison.get_child(6).text == "124")
	assert(screen.progress_panel.upgrade_dialog.comparison.get_child(7).text == "+4")
	screen.progress_panel.upgrade_dialog.hide()
	assert(screen.equipment.profile.coins == 300)
	screen.upgrade_button.pressed.emit()
	screen.progress_panel.upgrade_dialog.hide()
	screen.progress_panel.upgrade_dialog.confirmed.emit()
	assert(screen.equipment.profile.coins == 280)
	assert(screen.equipment.profile.level_of(&"cannon") == 2)
	assert(screen.session.stats.damage == 124)
	assert(screen.equipment.store.load_profile().level_of(&"cannon") == 2)
	for i: int in range(5):
		await process_frame
	if not DisplayServer.get_name() == "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/hangar-growth.png")
	screen.equipment.profile.levels["cannon"] = 6
	screen._refresh()
	assert(screen.upgrade_warning.text.contains("6.0 → 4.8"))
	screen.equipment.profile.levels["cannon"] = 7
	screen._refresh()
	assert(screen.upgrade_warning.text.is_empty())
	screen.equipment.profile.levels["cannon"] = 2
	screen.equipment.profile.coins = 0
	screen._refresh()
	assert(screen.upgrade_button.text == "升级" and screen.upgrade_button.disabled)
	screen._inspect_part(&"autocannon")
	assert(screen.apply_button.text == "尚未拥有" and screen.apply_button.disabled)
	assert(screen.upgrade_button.text == "未解锁" and screen.upgrade_button.disabled)
	screen.equipment.profile.coins = 300
	screen._refresh()
	assert(screen.upgrade_button.text == "解锁" and not screen.upgrade_button.disabled)
	screen.upgrade_button.pressed.emit()
	assert(screen.equipment.profile.owns(&"autocannon"))
	assert(screen.upgrade_button.text == "升级" and not screen.upgrade_button.disabled)
	screen._inspect_part(&"rail_sniper")
	assert(screen.upgrade_button.text == "未解锁" and screen.upgrade_button.disabled)
	for suffix: String in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(screen.equipment.store.path + suffix)
	screen.queue_free()
	await process_frame
	print("HANGAR GROWTH TESTS: PASS")
	quit()
