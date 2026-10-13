extends SceneTree
## Test observable assembly contracts, not implementation geometry details.

var failures: int = 0
var back_count: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	await _test_assembly()
	_test_mesh_integrity()
	_test_finish_isolation()
	_test_rejected_content()
	await _test_hangar()
	await _test_navigation()
	print("TANK PARTS TESTS: " + ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)

func _test_mesh_integrity() -> void:
	# A mixed indexed/unindexed merge previously saved invisible barrels and armor.
	var scenes: Array = TankPartCatalog.WEAPONS.values() + TankPartCatalog.CHASSIS.values()
	for scene: PackedScene in scenes:
		var part: Node = scene.instantiate()
		for node: Node in part.find_children("*", "MeshInstance3D", true, false):
			var mesh: Mesh = (node as MeshInstance3D).mesh
			for surface: int in range(mesh.get_surface_count()):
				var arrays: Array = mesh.surface_get_arrays(surface)
				if arrays[Mesh.ARRAY_INDEX] == null: continue
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var referenced: Dictionary = {}
				for index: int in indices: referenced[index] = true
				var vertex_count: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
				check(referenced.size() >= vertex_count * 0.98, "packed visual mesh retains its geometry in draw indices")
		part.free()

func _test_assembly() -> void:
	var view := TankView.new()
	root.add_child(view)
	var hull: Node = view.get_node("HullMount").get_child(0)
	view.configure_parts(&"autocannon", &"light_tracks")
	check(view.get_node("HullMount").get_child(0) == hull, "turret change preserves the exact chassis instance")
	var turret: Node = view.get_node("TurretMount").get_child(0)
	view.configure_parts(&"autocannon", &"heavy_tracks")
	check(view.get_node("TurretMount").get_child(0) == turret, "chassis change preserves the exact turret instance")
	var state := TankState.new()
	for weapon: StringName in TankPartCatalog.WEAPONS:
		for chassis: StringName in TankPartCatalog.CHASSIS:
			check(view.configure_parts(weapon, chassis).is_empty(), "all nine pairs assemble")
			state.body_yaw = 0.0
			state.aim_yaw = 0.0
			view.present(state)
			check(view.muzzle_transform().origin.is_equal_approx(Vector3(0, 0.78, -1.05)), "zero aim matches authoritative muzzle")
			state.body_yaw = 1.2
			state.aim_yaw = 0.6
			view.present(state)
			var expected := Vector3(sin(0.6) * 1.05, 0.78, -cos(0.6) * 1.05)
			check(view.muzzle_transform().origin.is_equal_approx(expected), "body yaw does not accumulate into turret yaw")
			check(view.muzzle_transform().basis.z.is_equal_approx(Vector3(-sin(0.6), 0, cos(0.6))), "muzzle points along aim")
			await process_frame
	var previous := view.muzzle_transform()
	check(not view.configure_parts(&"missing", &"heavy_tracks").is_empty(), "unknown part rejected explicitly")
	check(view.muzzle_transform().is_equal_approx(previous), "rejected selection preserves assembly")
	for frame: int in range(30):
		view.configure_parts(&"cannon", &"light_tracks")
	await process_frame
	for mount: Node in view.get_children():
		check(mount.get_child_count() == 1, "repeated replacement retains exactly one part per mount")
	view.free()
	await process_frame
	check(root.get_child_count() == 0, "assembly disposal releases mounts")

func _test_rejected_content() -> void:
	var part := Node3D.new()
	check(not TankPartCatalog.validate_part(part, &"Muzzle", Vector3.ZERO).is_empty(), "missing socket rejected")
	var socket := Marker3D.new()
	socket.name = "Muzzle"
	part.add_child(socket)
	socket.rotation.y = 1.0
	check(not TankPartCatalog.validate_part(part, &"Muzzle", Vector3.ZERO).is_empty(), "rotated socket rejected")
	socket.rotation = Vector3.ZERO
	var collision := Area3D.new()
	part.add_child(collision)
	check(not TankPartCatalog.validate_part(part, &"Muzzle", Vector3.ZERO).is_empty(), "visual collision rejected")
	part.free()

func _test_hangar() -> void:
	var screen := load("res://ui/screens/hangar_screen.tscn").instantiate() as Control
	root.add_child(screen)
	await process_frame
	for weapon: int in range(3):
		for chassis: int in range(3):
			screen.weapon_picker.select(weapon)
			screen.chassis_picker.select(chassis)
			screen.weapon_picker.item_selected.emit(weapon)
			check(screen.preview.tank.weapon_id == HangarSession.WEAPONS[weapon].id, "picker updates turret")
			check(screen.preview.tank.chassis_id == HangarSession.CHASSIS[chassis].id, "picker updates chassis")
			var resolved := LoadoutResolver.resolve(HangarSession.WEAPONS[weapon], HangarSession.CHASSIS[chassis])
			check(screen.session.stats.max_hp == resolved.max_hp and screen.session.stats.move_speed == resolved.move_speed, "preview reads resolved stats")
			await process_frame
	var before: ResolvedStats = screen.session.stats
	check(not screen.session.select(-1, 0).is_empty() and screen.session.stats == before, "invalid index retains draft")
	check(HangarSession.WEAPONS[0].damage == 120 and HangarSession.CHASSIS[0].max_hp == 500, "preview never mutates shared definitions")
	screen.back_requested.connect(func() -> void: back_count += 1)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	screen._unhandled_input(escape)
	check(back_count == 1, "Escape requests back navigation")
	screen.free()
	await process_frame
	check(root.get_child_count() == 0, "hangar disposal releases preview world")

func _test_navigation() -> void:
	var app := load("res://app/app_root.tscn") as PackedScene
	if app == null:
		check(false, "main scene available")
		return
	var instance := app.instantiate()
	root.add_child(instance)
	await process_frame
	var host := instance.get_node("ScreenHost")
	host.get_child(0).hangar_requested.emit()
	await process_frame
	check(host.get_child_count() == 1 and host.get_child(0).get("preview") != null, "home routes to a single hangar")
	host.get_child(0).back_requested.emit()
	await process_frame
	check(host.get_child_count() == 1 and host.get_child(0).has_signal("hangar_requested"), "back restores a single home")
	instance.free()
	await process_frame

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _test_finish_isolation() -> void:
	var first := TankView.new()
	var second := TankView.new()
	root.add_child(first)
	root.add_child(second)
	var a: MeshInstance3D = first.get_node("TurretMount").find_children("*", "MeshInstance3D", true, false)[0]
	var b: MeshInstance3D = second.get_node("TurretMount").find_children("*", "MeshInstance3D", true, false)[0]
	var finish := a.get_surface_override_material(0) as ShaderMaterial
	check(finish != null, "sample paint treatment applied")
	check(finish != b.get_surface_override_material(0), "paint overrides isolated between tank instances")
	check(a.mesh.surface_get_material(0) is StandardMaterial3D, "original imported material remains unchanged")
	var texture: Texture2D = (a.mesh.surface_get_material(0) as StandardMaterial3D).albedo_texture
	check(finish.get_shader_parameter("albedo_map") == texture, "sample retains original texture source")
	finish.set_shader_parameter("cleanup_strength", 0.0)
	check(is_equal_approx(float((b.get_surface_override_material(0) as ShaderMaterial).get_shader_parameter("cleanup_strength")), TankSurfacePolish.STYLE.cleanup_strength), "one instance cannot alter another finish")
	first.free()
	second.free()
