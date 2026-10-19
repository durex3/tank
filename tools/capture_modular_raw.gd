extends SceneTree
## Raw generated mesh inspection; no gameplay catalog edits.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(800, 800)
	for id: String in ["t02", "c03"]:
		var stage := HangarPreview.new()
		root.add_child(stage)
		stage.tank.hide()
		var mesh := (load("res://assets/imported/modular-sample-v1/%s_pbr.glb" % id) as PackedScene).instantiate() as Node3D
		stage.add_child(mesh)
		mesh.position.y = 0.5
		for index: int in range(4):
			mesh.rotation.y = index * PI / 2.0
			for frame: int in range(5): await process_frame
			await RenderingServer.frame_post_draw
			assert(root.get_texture().get_image().save_png("res://artifacts/modular-raw-%s-%d.png" % [id, index]) == OK)
		stage.free()
	print("MODULAR RAW CAPTURE PASS")
	quit()
