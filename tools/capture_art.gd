extends SceneTree
## Real Compatibility render of committed combat facts with production texture bindings.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 720)
	var screen := load("res://ui/screens/movement_screen.tscn").instantiate() as Control
	root.add_child(screen)
	screen.session.set_physics_process(false)
	for frame: int in range(30):
		await physics_frame
	var view: CombatView = screen.session.combat_view
	view.on_event({"kind": &"weapon_fired", "position": Vector3(0, 0.78, -1.05)})
	view.on_event({"kind": &"projectile_hit", "position": Vector3(0, 0.78, -8)})
	view.on_event({"kind": &"entity_died", "position": Vector3(-7, 0.78, -8)})
	# Freeze the first frame for reproducible visual inspection, not gameplay evidence.
	view.set_paused(true)
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png("res://artifacts/combat-art-preview.png")
	print("ART CAPTURE: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
