extends SceneTree
## Candidate-only inspection. Does not change the active catalog or player profile.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	screen.equipment.store.path = "user://model_capture_fixture.json"
	root.add_child(screen)
	for frame: int in range(12): await process_frame
	screen.restore_selection(&"cannon", &"light_tracks")
	var candidate := preload("res://presentation/parts/tripo_v2/cannon.tscn").instantiate() as Node3D
	assert(TankPartCatalog.validate_part(candidate, &"Muzzle", Vector3(0, 0.02, -1.05)).is_empty())
	TankSurfacePolish.apply(candidate, &"cannon")
	screen.preview.tank._replace_child(screen.preview.tank._turret, candidate)
	screen.preview.tank._muzzle = candidate.get_node("Muzzle") as Marker3D
	for frame: int in range(8): await process_frame
	await RenderingServer.frame_post_draw
	var area := Rect2i(screen.art_stage._model.get_global_rect())
	var error := root.get_texture().get_image().get_region(area).save_png("res://artifacts/smart-cannon-candidate.png")
	print("SMART CANNON CANDIDATE: ", "PASS" if error == OK else "FAIL")
	quit(0 if error == OK else 1)
