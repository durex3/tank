extends SceneTree

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var scene := preload("res://presentation/previews/hyper3d_refined_preview.tscn").instantiate()
	root.add_child(scene)
	for index: int in range(4):
		scene.candidate.rotation.y = index * PI * 0.5
		await _save("godot-%d" % index)
	var wheels: Array[Node] = scene.candidate.find_children("Wheel*", "Node3D", true, false)
	assert(wheels.size() == 4)
	assert(scene.candidate.find_children("RecoilLeft*", "Node3D", true, false).size() == 1)
	assert(scene.candidate.find_children("RecoilRight*", "Node3D", true, false).size() == 1)
	scene.candidate.rotation.y = 0
	for index: int in range(8):
		scene.set_review_pose(index * PI / 8.0)
		for wheel: Node3D in wheels:
			assert(wheel.scale.is_equal_approx(Vector3.ONE))
			assert(absf(wheel.global_basis.x.dot(wheel.global_basis.y)) < 0.00001)
		await _save("motion-%d" % index)
	scene.set_review_pose(0.25)
	assert(scene._left.position.z > 0.039 and is_zero_approx(scene._right.position.z))
	scene.set_review_pose(0.75)
	assert(scene._right.position.z > 0.039 and is_zero_approx(scene._left.position.z))
	scene.set_review_pose(0.0)
	assert(scene._left.position.is_zero_approx() and scene._right.position.is_zero_approx())
	print("HYPER3D REFINED IMPORT / FOUR WHEELS / INDEPENDENT RECOIL PASS")
	quit()

func _save(label: String) -> void:
	for frame: int in range(6): await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://assets/derived/hyper3d-refined-v1/%s.png" % label) == OK)
