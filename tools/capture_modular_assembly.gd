extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene := preload("res://presentation/previews/modular_sample_preview.tscn").instantiate()
	root.add_child(scene)
	for index: int in range(4):
		scene.set_review_yaw(index * PI * 0.5)
		for frame: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://artifacts/modular-assembly-%d.png" % index) == OK)
	var toggle := InputEventKey.new()
	toggle.keycode = KEY_SPACE
	toggle.pressed = true
	scene._input(toggle)
	assert(scene.tank.visible and not scene.candidate.visible)
	scene._input(toggle)
	assert(not scene.tank.visible and scene.candidate.visible)
	var sizes: Dictionary = {}
	for part: Node3D in scene.candidate.get_children():
		var geometry := part.get_node("Geometry") as Node3D
		assert(is_equal_approx(geometry.scale.x, geometry.scale.y))
		assert(is_equal_approx(geometry.scale.x, geometry.scale.z))
		sizes["turret" if part.turret else "chassis"] = part.source_size * geometry.scale
	var turret_size: Vector3 = sizes["turret"]
	var chassis_size: Vector3 = sizes["chassis"]
	assert(turret_size.x / chassis_size.x <= 0.65, "Candidate turret must not dominate chassis width")
	assert(turret_size.y < chassis_size.y, "Candidate turret must be lower than chassis")
	assert(turret_size.z < chassis_size.z, "Candidate turret full length must fit chassis length")
	print("CANDIDATE SIZES turret=", turret_size, " chassis=", chassis_size)
	var screen := preload("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://modular_sample_capture_fixture.json"
	root.add_child(screen)
	for frame: int in range(12): await process_frame
	screen.restore_selection(&"autocannon", &"scout_wheels")
	for frame: int in range(5): await process_frame
	# Candidate injection exists only in this offline capture, never the gameplay catalog.
	for child: Node3D in screen.preview.tank.get_children(): child.hide()
	var candidate: Node3D = scene.candidate
	candidate.reparent(screen.preview.tank, false)
	candidate.rotation = Vector3.ZERO
	var label := Label.new()
	label.text = "新模型试装 · 尺寸/拆件待验收"
	label.position = Vector2(720, 430)
	label.add_theme_font_size_override("font_size", 18)
	screen.add_child(label)
	for child: Node in screen.preview.get_children():
		if child is Camera3D:
			child.size = 3.5
			child.look_at(Vector3(0, 0.9, 0))
	scene.free()
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://artifacts/modular-hangar.png") == OK)
	print("MODULAR ASSEMBLY CAPTURE PASS")
	quit()
