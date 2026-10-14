extends SceneTree
## Visual envelopes are equal across styles; mounting and authority remain unchanged.

const STYLE: Resource = preload("res://content/presentation/part_size.tres")

func _initialize() -> void:
	call_deferred("_run")

func _bounds(part: Node3D) -> AABB:
	var result := AABB()
	var first: bool = true
	for node: Node in part.find_children("*", "GeometryInstance3D", true, false):
		var box: AABB
		if node is MeshInstance3D:
			box = (node as MeshInstance3D).get_aabb()
		elif node is MultiMeshInstance3D:
			box = (node as MultiMeshInstance3D).multimesh.get_aabb()
		else:
			continue
		box = part.global_transform.affine_inverse() * (node as Node3D).global_transform * box
		result = box if first else result.merge(box)
		first = false
	return result


func _run() -> void:
	for group: Dictionary in [TankPartCatalog.WEAPONS, TankPartCatalog.CHASSIS]:
		var turret: bool = group.has(&"cannon")
		var target: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		for id: StringName in group:
			var part := (group[id] as PackedScene).instantiate() as Node3D
			root.add_child(part)
			var actual := _bounds(part)
			assert((actual.size - target.size).length() < 0.0002, str(id) + " common size")
			assert((actual.position - target.position).length() < 0.0002, str(id) + " common placement")
			var marker: StringName = &"Muzzle" if turret else &"TurretSocket"
			var socket := Vector3(0, 0.02, -1.05) if turret else Vector3(0, 0.76, 0)
			assert(TankPartCatalog.validate_part(part, marker, socket).is_empty())
			# Rotation must remain rigid through a full revolution, not only at rest.
			for wheel_node: Node in part.find_children("Wheel*", "Node3D", true, false):
				var wheel := wheel_node as Node3D
				for angle: float in [0.0, PI / 4.0, PI / 2.0, PI]:
					wheel.rotation.x = angle
					var basis: Basis = wheel.global_basis
					assert(absf(basis.y.length() - basis.z.length()) < 0.0002, str(id) + " round wheel scale")
					assert(absf(basis.y.dot(basis.z)) < 0.0002, str(id) + " rigid wheel axes")
			part.free()
	print("PART SIZE TESTS: PASS")
	quit()
