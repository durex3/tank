extends SceneTree
## Real cards -> session -> art/stats, with transparent assets and layout checks.

var failures: int = 0
var requested: Array[StringName] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	check(HangarCopy.text("hangar.title") == "整备车间", "keyed Chinese fallback available")
	for weapon: int in range(3):
		for chassis: int in range(3):
			screen.directory.tabs.current_tab = 0
			(screen.find_child("WeaponCard" + str(weapon), true, false) as Button).pressed.emit()
			screen.directory.tabs.current_tab = 1
			(screen.find_child("ChassisCard" + str(chassis), true, false) as Button).pressed.emit()
			await process_frame
			check(screen.session.weapon_index == weapon and screen.session.chassis_index == chassis, "real cards update validated selection")
			var id: StringName = HangarSession.WEAPONS[weapon].id
			var chassis_id: StringName = HangarSession.CHASSIS[chassis].id
			var texture: Texture2D = screen.art_stage.artwork.texture
			check(texture == HangarArtCatalog.texture(id, chassis_id), "selected illustration matches both stable IDs")
			check(texture.get_width() == 1024 and texture.get_height() == 1024, "all combinations share a fixed presentation canvas")
			var picture := texture.get_image()
			check(picture.get_width() >= 512 and picture.get_height() >= 512 and picture.detect_alpha() != Image.ALPHA_NONE, "hero art has usable dimensions and alpha")
			check(picture.get_pixel(0, 0).a < 0.01 and picture.get_pixel(picture.get_width() - 1, picture.get_height() - 1).a < 0.01, "hero corners are transparent")
			for index: int in range(3):
				check((screen.find_child("WeaponCard" + str(index), true, false) as Button).button_pressed == (index == weapon), "exactly one turret selected")
				check((screen.find_child("ChassisCard" + str(index), true, false) as Button).button_pressed == (index == chassis), "exactly one chassis selected")
	check(screen.find_child("ArtModelToggle", true, false) == null, "appearance requires no model toggle")
	for chassis: StringName in [&"light_tracks", &"heavy_tracks", &"scout_wheels"]:
		var base := HangarArtCatalog.texture(&"cannon", chassis).get_image().get_region(Rect2i(0, 800, 1024, 224)).get_data()
		for weapon: StringName in [&"autocannon", &"scatter"]:
			var changed := HangarArtCatalog.texture(weapon, chassis).get_image().get_region(Rect2i(0, 800, 1024, 224)).get_data()
			check(changed == base, "turret switching preserves visible lower chassis pixels exactly")
	check(not screen.art_stage.artwork.visible and screen.art_stage._model.visible, "appearance directly shows real model")
	var before_rotation: float = screen.preview.tank.rotation.y
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	screen.art_stage._preview_input(press)
	var drag := InputEventMouseMotion.new()
	drag.relative = Vector2(40, 0)
	screen.art_stage._preview_input(drag)
	check(not is_equal_approx(before_rotation, screen.preview.tank.rotation.y), "drag rotates actual model")
	screen.preview.rotate_preview(TAU * 4)
	check(absf(screen.preview.tank.rotation.y) <= PI, "rotation wraps through multiple full turns")
	press.pressed = false
	screen.art_stage._input(press)
	check(not screen.art_stage._dragging, "release outside preview clears drag")
	press.pressed = true
	screen.art_stage._preview_input(press)
	screen.restore_selection(&"cannon", &"light_tracks")
	check(not screen.art_stage._dragging, "selection change clears rotation drag")
	screen._inspect_part(&"cutting_laser")
	check(screen.art_stage.artwork.visible and not screen.art_stage._model.visible, "unmodeled part shows static design instead of previous model")
	var fallback_yaw: float = screen.preview.tank.rotation.y
	screen.art_stage._preview_input(press)
	screen.art_stage._preview_input(drag)
	check(is_equal_approx(fallback_yaw, screen.preview.tank.rotation.y), "static design cannot rotate")
	screen.restore_selection(&"scatter", &"heavy_tracks")
	var touch := InputEventScreenTouch.new()
	touch.index = 2
	touch.pressed = true
	screen.art_stage._preview_input(touch)
	touch.pressed = false
	screen.art_stage._input(touch)
	check(screen.art_stage._touch_index == -1, "touch release outside clears rotation")
	screen.training_requested.connect(func(weapon: StringName, chassis: StringName) -> void: requested = [weapon, chassis])
	(screen.find_child("TrainLoadout", true, false) as Button).pressed.emit()
	check(requested == [&"scatter", &"heavy_tracks"], "training request preserves art selection IDs")
	await _test_layout(screen)
	screen.free()
	await process_frame
	check(root.get_child_count() == 0, "art screen disposal releases preview and widgets")
	print("HANGAR ART TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_layout(screen: Control) -> void:
	screen.directory.tabs.current_tab = 0
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 720), Vector2i(1024, 768)]:
		root.size = dimensions
		for frame: int in range(3):
			await process_frame
		var pixels: Vector2i = screen.art_stage._viewport.size
		var expected: Vector2 = screen.art_stage._model.size * HangarArtStage.PREVIEW_STYLE.render_scale
		if maxf(expected.x, expected.y) > HangarArtStage.PREVIEW_STYLE.max_render_edge:
			expected *= float(HangarArtStage.PREVIEW_STYLE.max_render_edge) / maxf(expected.x, expected.y)
		check(absf(pixels.x - expected.x) <= 1 and absf(pixels.y - expected.y) <= 1, "preview uses explicit supersampled pixels at each window size")
		var bounds := screen.get_global_rect()
		var train := screen.find_child("TrainLoadout", true, false) as Button
		check(bounds.encloses(train.get_global_rect()), "training entry stays inside viewport across aspect ratios")
		var first := screen.find_child("WeaponCard0", true, false) as Button
		var last := screen.find_child("WeaponCard2", true, false) as Button
		check(bounds.encloses(first.get_global_rect()) and bounds.encloses(last.get_global_rect()), "cards stay inside tested viewport")
		check(not first.get_global_rect().intersects(last.get_global_rect()), "card hit regions do not overlap")
		check(screen.art_stage._model.size.x > 250 and screen.art_stage._model.size.y > 250, "hero remains a readable large presentation")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
