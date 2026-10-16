extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene := preload("res://presentation/previews/blender_family_preview.tscn").instantiate()
	root.add_child(scene)
	for index: int in range(4):
		scene.candidate.rotation.y = index * PI * 0.5
		for frame: int in range(8): await process_frame
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png("res://assets/derived/blender-family-v1/godot-%d.png" % index) == OK)
	var wheels: Array[Node] = scene.candidate.find_children("Wheel*", "Node3D", true, false)
	assert(wheels.size() == 4, "Four independent rolling pivots required")
	assert(scene.candidate.find_children("RecoilPivot*", "Node3D", true, false).size() == 1)
	for wheel: Node3D in wheels:
		assert(wheel.scale.is_equal_approx(Vector3.ONE))
		wheel.rotation.x = PI / 4.0
		assert(wheel.global_basis.x.length() > 0.999)
		assert(absf(wheel.global_basis.x.dot(wheel.global_basis.y)) < 0.00001)
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://assets/derived/blender-family-v1/godot-wheel-check.png") == OK)
	print("BLENDER FAMILY IMPORT AND PIVOTS PASS")
	quit()
