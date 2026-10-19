extends SceneTree
## Camera/input contract and visual-only environment integration.

var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var rig := CameraRig.new()
	root.add_child(rig)
	await process_frame
	for target: Vector3 in [Vector3.ZERO, Vector3(4, 0, -3), Vector3(-8, 0, 5)]:
		var screen := rig.camera.unproject_position(target)
		check(rig.ground_point(screen).is_equal_approx(target), "isometric screen/ground mapping round trip")
	var a := CameraRig.new()
	var b := CameraRig.new()
	for camera: CameraRig in [a, b]:
		camera.tuning = rig.tuning.duplicate() as CameraTuning
		camera.tuning.cut_distance = 100.0
		root.add_child(camera)
	for index: int in range(30):
		a.follow(Vector3(5, 0, 0), 1.0 / 30.0)
	for index: int in range(120):
		b.follow(Vector3(5, 0, 0), 1.0 / 120.0)
	check(a.position.distance_to(b.position) < 0.001, "follow independent of update frequency for fixed target")
	var before := rig.position
	rig.follow(Vector3(0.2, 0, 0.2), 1.0)
	check(rig.position == before, "deadzone rejects small motion")
	rig.follow(Vector3(100, 0, -100), 1.0)
	check(absf(rig.position.x) <= rig.tuning.focus_bounds.x and absf(rig.position.z) <= rig.tuning.focus_bounds.y, "focus bounded at arena edge")
	check(rig.ground_point(rig.camera.unproject_position(Vector3(12, 0, -9))).is_equal_approx(Vector3(12, 0, -9)), "projection remains correct after camera translation")
	for camera: CameraRig in [rig, a, b]:
		camera.free()
	var session := MovementSession.new()
	root.add_child(session)
	await physics_frame
	await physics_frame
	var dressing := session.find_children("*", "ArenaDressing", true, false)
	check(dressing.size() == 1, "session contains one dressing owner")
	if dressing.size() == 1:
		check(dressing[0].find_children("*", "CollisionObject3D", true, false).is_empty(), "dressing never adds combat collision")
	session.pause()
	before = session.rig.position
	session.actor.position = Vector3(9, 0, 0)
	for frame: int in range(4):
		await physics_frame
	check(session.rig.position == before, "paused session freezes camera follow")
	session.resume()
	await physics_frame
	await physics_frame
	check(session.rig.position.x > before.x, "resumed follow observes committed actor position")
	session.free()
	await process_frame
	check(root.get_child_count() == 0, "visual scene exit releases camera and dressing")
	await _check_scaled_view()
	print("BATTLE VISUAL TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _check_scaled_view() -> void:
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	check(screen.touch_overlay.get_index() > screen._container.get_index() and screen.touch_overlay.get_index() < screen.pause_overlay.get_index(), "touch sticks render above world and below modal overlays")
	screen._set_touch(true)
	check(screen.touch_overlay.visible, "touch mode shows its dedicated controls layer")
	screen._set_touch(false)
	check(not screen.training_hud.stats_panel.visible, "statistics start collapsed")
	(screen.training_hud._left.get_child(2) as Button).pressed.emit()
	check(screen.training_hud.stats_panel.visible, "statistics toolbar opens optional readout")
	(screen.training_hud._left.get_child(2) as Button).pressed.emit()
	for target: TrainingTarget in screen.session.simulation.targets:
		var views := target.find_children("*","TankView",true,false)
		check(views.size() == 1, "each dummy uses one assembled catalog tank")
		if views.size() == 1:
			check(views[0].find_children("*","CollisionObject3D",true,false).is_empty(), "dummy art adds no combat collision")
	screen.session.pause()
	for dimensions: Vector2 in [Vector2(1280,720), Vector2(1600,900), Vector2(1000,700)]:
		screen.size = dimensions
		screen._layout()
		await process_frame
		var viewport_point: Vector2 = screen.session.rig.camera.unproject_position(Vector3(2,0,-2))
		var displayed: Vector2 = screen._container.get_global_transform() * viewport_point
		var recovered: Vector2 = screen._container.get_global_transform().affine_inverse() * displayed
		check(screen.session.rig.ground_point(recovered).distance_to(Vector3(2,0,-2)) < 0.001, "supersampled view preserves aim at resized/letterboxed sizes")
		var visible_size: Vector2 = screen._container.size * screen._container.scale
		check(absf(visible_size.x / visible_size.y - 16.0/9.0) < 0.001, "world keeps 16:9 without distortion")
		check(Rect2(Vector2.ZERO,dimensions).encloses(screen.ability_hud.get_rect()), "skill card stays inside resized screen")
		check(not screen.ability_hud.get_rect().intersects(screen.ability_hud.passive_panel.get_rect()), "skill and passive cards do not overlap")
		screen._set_touch(true)
		await process_frame
		var skill_region := Rect2(screen._centers[2]-Vector2(80,80),Vector2(160,160))
		check(not screen.ability_hud.get_rect().intersects(skill_region), "skill card does not cover touch ability region")
		screen._set_touch(false)
	screen.session.stop()
	screen.free()
	await process_frame
