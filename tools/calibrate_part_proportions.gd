extends "res://tools/normalize_part_sizes.gd"
## Derive editable scenes without stretching circular running gear.

func _own(node: Node, part: Node) -> void:
	if node != part:
		node.owner = part
	if node is Node3D:
		(node as Node3D).scene_file_path = ""
	if node is TrackRig:
		return
	for child: Node in node.get_children():
		_own(child, part)

func _run() -> void:
	var output_dir: String = "res://presentation/parts/proportion_v1/"
	DirAccess.make_dir_recursive_absolute(output_dir)
	for group: Dictionary in SOURCES:
		var turret: bool = group.has(&"cannon")
		var target: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		for id: StringName in group:
			var part := Node3D.new()
			part.name = str(id)
			root.add_child(part)
			var geometry := (group[id] as PackedScene).instantiate() as Node3D
			part.add_child(geometry)
			geometry.name = "Geometry"
			var original := _bounds(part)
			var factor := target.size / original.size
			var shift := target.position - original.position * factor
			if id == &"cannon":
				factor.y = factor.x
				shift.y = target.end.y - original.end.y * factor.y
			geometry.scale = factor
			geometry.position = shift
			if id == &"cannon":
				var bottom: float = original.position.y * factor.y + shift.y
				var collar := MeshInstance3D.new()
				collar.name = "MountCollar"
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = 0.37
				cylinder.bottom_radius = 0.40
				cylinder.height = bottom - target.position.y + 0.025
				collar.mesh = cylinder
				collar.position.y = target.position.y + cylinder.height / 2.0
				var material := StandardMaterial3D.new()
				material.albedo_color = Color("303b40")
				material.roughness = 0.85
				collar.material_override = material
				part.add_child(collar)
			elif id == &"heavy_tracks":
				var rig := geometry.get_node("TrackRig") as Node3D
				geometry.remove_child(rig)
				part.add_child(rig)
				rig.transform = Transform3D.IDENTITY
				# Same metre-based axle and round wheels as the first chassis.
				# Rebuild procedural geometry using the shared light rig dimensions.
				rig.free()
				var replacement := Node3D.new()
				replacement.name = "TrackRig"
				replacement.set_script(load("res://presentation/track_rig.gd"))
				var style := load("res://content/presentation/track_rig.tres").duplicate() as Resource
				style.wheel_count = 4
				style.cleat_count = 56
				replacement.set("style", style)
				part.add_child(replacement)
			elif id == &"scout_wheels":
				for node: Node in geometry.find_children("Wheel*", "Node3D", true, false):
					var wheel := node as Node3D
					var old_center := wheel.global_position
					var old_basis := wheel.global_basis
					wheel.reparent(part, true)
					wheel.global_basis = old_basis.orthonormalized()
					var box := _bounds(wheel)
					var half := box.size / 2.0
					var center := Vector3(signf(old_center.x) * (target.end.x - half.x), half.y, target.position.z + half.z if old_center.z < target.get_center().z else target.end.z - half.z)
					wheel.global_position = center - box.get_center()
				var imported_rig := geometry.get_node("TrackRig") as Node3D
				imported_rig.reparent(part, false)
			var marker := Marker3D.new()
			marker.name = "Muzzle" if turret else "TurretSocket"
			marker.position = Vector3(0, 0.02, -1.05) if turret else Vector3(0, 0.76, 0)
			part.add_child(marker)
			_own(part, part)
			var packed := PackedScene.new()
			assert(packed.pack(part) == OK)
			assert(ResourceSaver.save(packed, output_dir + str(id) + ".tscn") == OK)
			print(id, " ", _bounds(part))
			part.free()
	quit()
