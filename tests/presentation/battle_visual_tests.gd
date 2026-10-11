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
	print("BATTLE VISUAL TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
