extends SceneTree
## Real training page at desktop, statistics-open and touch sizes.

func _initialize() -> void:
	call_deferred("_run")

func _capture(path: String) -> void:
	for i: int in range(4): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/"+path+".png") == OK)

func _run() -> void:
	root.size = Vector2i(1280,720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await physics_frame
	await physics_frame
	screen.session.set_physics_process(false)
	if screen.session.phase == MovementSession.Phase.PAUSED: screen.session.resume()
	await _capture("training-redesign-desktop")
	(screen.training_hud._left.get_child(2) as Button).pressed.emit()
	assert(screen.training_hud.stats_panel.visible)
	await _capture("training-redesign-statistics")
	(screen.training_hud._left.get_child(2) as Button).pressed.emit()
	root.size = Vector2i(1000,700)
	screen._set_touch(true)
	await _capture("training-redesign-touch")
	screen.session.stop()
	screen.free()
	print("TRAINING REDESIGN CAPTURE: PASS")
	quit()
