extends SceneTree
## Actual rendered gallery of all twelve modular 3D assemblies, not illustration art.

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	root.size = Vector2i(1280, 960)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(grid)
	for chassis: StringName in TankPartCatalog.CHASSIS:
		for weapon: StringName in TankPartCatalog.WEAPONS:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.size_flags_vertical = Control.SIZE_EXPAND_FILL
			grid.add_child(column)
			var label := Label.new()
			label.text = "%s / %s" % [weapon, chassis]
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			column.add_child(label)
			var container := SubViewportContainer.new()
			container.stretch = true
			container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			container.size_flags_vertical = Control.SIZE_EXPAND_FILL
			column.add_child(container)
			var viewport := SubViewport.new()
			viewport.size = Vector2i(420, 280)
			viewport.msaa_3d = HangarPreview.STYLE.msaa
			viewport.scaling_3d_scale = HangarPreview.STYLE.render_scale
			viewport.own_world_3d = true
			container.add_child(viewport)
			var preview := HangarPreview.new()
			viewport.add_child(preview)
			preview.tank.configure_parts(weapon, chassis)
			if "--rear" in OS.get_cmdline_user_args():
				preview.rotate_preview(PI)
	for frame: int in range(30):
		await process_frame
	await RenderingServer.frame_post_draw
	var file_name: String = "tank-finish-gallery-rear.png" if "--rear" in OS.get_cmdline_user_args() else "tank-finish-gallery.png"
	var error := root.get_texture().get_image().save_png("res://artifacts/" + file_name)
	print("MODEL GALLERY: " + ("PASS" if error == OK else "FAIL"))
	quit(0 if error == OK else 1)
