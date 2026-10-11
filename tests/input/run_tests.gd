extends SceneTree

var failures: int = 0
var state := TouchInputState.new()

func _initialize() -> void:
	var regions: Array[Rect2] = [Rect2(0, 0, 160, 160), Rect2(300, 0, 160, 160), Rect2(600, 0, 160, 160)]
	state.configure(regions)
	check(not state.press(9, Vector2(200, 200)), "outside ignored")
	check(state.press(0, Vector2(80, 80)), "move captured")
	check(not state.press(1, Vector2(80, 80)), "second finger cannot steal")
	check(not state.press(0, Vector2(380, 80)), "duplicate down cannot steal")
	state.drag(0, Vector2(144, 144))
	check(is_equal_approx(state.move_vector.length(), 1.0), "diagonal normalized")
	state.drag(0, Vector2(380, 80))
	check(state.is_captured(TouchInputState.Slot.MOVE), "crossing retains ownership")
	check(state.press(1, Vector2(380, 80)), "aim simultaneous with movement")
	check(state.press(2, Vector2(680, 80)), "third skill finger captured")
	state.release(2, Vector2(680, 80))
	check(state.sample(1).ability_request_id == 1, "skill emits once")
	check(state.sample(2).ability_request_id == 0, "skill not repeated")
	state.drag(1, Vector2(444, 80))
	var aim := state.aim_vector
	state.drag(1, Vector2(380, 80))
	check(state.aim_vector == aim, "deadzone retains aim")
	state.release(1, Vector2(380, 80))
	check(state.sample(3).fire_request_id == 1, "tap fires last direction")
	check(state.sample(4).fire_request_id == 0, "release consumed once")
	state.press(1, Vector2(380, 80))
	state.release(1, Vector2(380, 80), true)
	check(state.sample(5).fire_request_id == 0, "OS cancel never fires")
	state.press(1, Vector2(380, 80))
	state.release(1, Vector2(380, -60))
	check(state.sample(6).fire_request_id == 0, "cancel zone never fires")
	state.press(1, Vector2(380, 80))
	state.release(1, Vector2(380, 80))
	state.cancel_pending()
	var neutral := state.sample(7)
	check(neutral.move_x == 0 and neutral.fire_request_id == 0, "cancel clears queued release and movement")
	check(not state.release(0, Vector2(80, 80)), "stale release ignored")
	state.continuous_fire = true
	state.press(1, Vector2(444, 80))
	check(state.sample(8).fire_held, "held outside deadzone")
	state.drag(1, Vector2(380, 80))
	check(not state.sample(9).fire_held, "held stops in deadzone")
	state.release(1, Vector2(444, 80))
	check(state.sample(10).fire_request_id == 0, "held release has no single shot")
	state.set_enabled(false)
	check(not state.press(1, Vector2(444, 80)), "modal disables capture")
	state.set_enabled(true)
	check(not state.press(1, Vector2(NAN, 0)), "NaN ignored")
	check(is_equal_approx(state.apply_deadzone(Vector2(0.575, 0)).x, 0.5), "radial deadzone remap")
	_test_adapter(regions)
	call_deferred("_test_screen")

func _test_adapter(regions: Array[Rect2]) -> void:
	var source := TouchInputSource.new()
	source.state.configure(regions)
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	check(not source.handle_event(mouse), "mouse ignored to avoid duplicated touch")
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.pressed = true
	touch.position = Vector2(380, 80)
	check(source.handle_event(touch), "device touch accepted")
	touch.canceled = true
	check(source.handle_event(touch), "pressed canceled event prioritizes cancellation")
	check(source.sample(11).fire_request_id == 0, "canceled device touch never fires")
	touch.canceled = false
	source.handle_event(touch)
	source.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not source.state.is_captured(TouchInputState.Slot.AIM), "focus loss releases ownership")
	source.handle_event(touch)
	source.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not source.state.is_captured(TouchInputState.Slot.AIM), "background releases ownership")
	source.viewport_to_logical = Transform2D(0.0, Vector2(0.5, 0.5), 0.0, Vector2.ZERO)
	touch.position = Vector2(760, 160)
	check(source.handle_event(touch), "scaled viewport maps to logical aim region")
	source.cancel_pending()
	check(source.sample(12).is_valid(), "command stays valid after cancellation")
	source.free()

func _test_screen() -> void:
	var screen := load("res://ui/screens/input_lab.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	check(screen.get_child_count() > 0, "lab screen initializes")
	root.remove_child(screen)
	screen.free()
	print("INPUT TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)
