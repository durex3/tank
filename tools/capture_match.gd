extends SceneTree
## Standard real bot match; overtime-only capture uses a two-second fixture.

var failed: bool = false

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var app := load("res://app/app_root.tscn").instantiate() as Node
	root.add_child(app)
	await process_frame
	var host := app.get_node("ScreenHost")
	host.get_child(0).movement_requested.emit()
	await process_frame
	(host.get_child(0).find_child("StartDuel", true, false) as Button).pressed.emit()
	await process_frame
	var screen := host.get_child(0)
	var session: MovementSession = screen.session
	session.set_physics_process(false)
	for frame: int in range(90):
		_step(session)
		await physics_frame
	await _save("duel-running.png")
	for frame: int in range(14500):
		if session.phase == MovementSession.Phase.FINISHED:
			break
		_step(session)
		if frame % 60 == 0:
			await physics_frame
	if session.phase != MovementSession.Phase.FINISHED:
		failed = true
		push_error("Actual match did not finish")
	else:
		console_result(session)
	await _save("duel-result.png")
	(screen.find_child("Rematch", true, false) as Button).pressed.emit()
	await process_frame
	session = host.get_child(0).session
	session.set_physics_process(false)
	await _save("duel-rematch.png")
	app.free()
	await process_frame
	await _capture_overtime()
	print("MATCH CAPTURE: " + ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)

func _capture_overtime() -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	var rules := preload("res://content/rules/offline_duel.tres").duplicate() as MatchRules
	rules.duration_ticks = 120
	screen.session.configure_match(rules)
	root.add_child(screen)
	var session: MovementSession = screen.session
	session.set_physics_process(false)
	for frame: int in range(120):
		_step(session)
		await physics_frame
	if session.simulation.match_runtime.phase != MatchRuntime.Phase.OVERTIME:
		failed = true
		push_error("Fixture failed to enter overtime")
	await _save("duel-overtime.png")
	screen.free()

func _step(session: MovementSession) -> void:
	session.sparring.sample_next_tick()
	session.simulation.step()

func console_result(session: MovementSession) -> void:
	var state := session.simulation.match_runtime.snapshot()
	print("ACTUAL DUEL RESULT: tick=%d scores=%s reason=%s" % [session.simulation.tick, state.scores, state.reason])

func _save(file: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png("res://artifacts/" + file) != OK:
		failed = true
		push_error("Capture failed: " + file)
