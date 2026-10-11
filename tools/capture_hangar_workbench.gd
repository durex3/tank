extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://workbench_capture_fixture.json"
	root.add_child(screen)
	for frame: int in range(12):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/workbench-turrets.png")
	screen.directory.cards[&"burst_cannon"].pressed.emit()
	(screen.directory.grid.get_parent() as ScrollContainer).scroll_vertical = 400
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/workbench-scrolled.png")
	screen.directory.tabs.current_tab = 1
	(screen.directory.grid.get_parent() as ScrollContainer).scroll_vertical = 0
	screen.directory.cards[&"scout_wheels"].pressed.emit()
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/workbench-chassis.png")
	screen.directory.tabs.current_tab = 0
	screen.directory.cards[&"cannon"].pressed.emit()
	screen.details_panel._show_dialog()
	for frame: int in range(8):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/workbench-details.png")
	print("DIALOG ", screen.details_panel.dialog.size, " BODY ", screen.details_panel.dialog_body.size, " MIN ", screen.details_panel.dialog_body.get_combined_minimum_size())
	screen.details_panel.dialog.hide()
	screen.equipment.profile.coins = 5
	screen.restore_selection(screen.equipment.profile.weapon_id, screen.equipment.profile.chassis_id)
	for frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/workbench-insufficient-coins.png")
	print("WORKBENCH CAPTURE: PASS")
	quit()
