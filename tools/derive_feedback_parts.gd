extends "res://tools/normalize_part_sizes.gd"
## Derive from immutable 081 parts, retain dimensions and authoritative sockets.

func _own(node: Node, owner_root: Node) -> void:
	if node != owner_root: node.owner = owner_root
	if node is Node3D: (node as Node3D).scene_file_path = ""
	for child: Node in node.get_children(): _own(child,owner_root)

func _save(part: Node3D, id: String) -> void:
	_own(part,part)
	var scene := PackedScene.new()
	assert(scene.pack(part) == OK)
	assert(ResourceSaver.save(scene,"res://presentation/parts/feedback_v1/"+id+".tscn") == OK)
	print(id," ",_bounds(part))
	part.free()

func _run() -> void:
	DirAccess.make_dir_recursive_absolute("res://presentation/parts/feedback_v1")
	var turret := load("res://presentation/parts/proportion_v1/autocannon.tscn").instantiate() as Node3D
	root.add_child(turret)
	var left := turret.find_child("RecoilPivot",true,false) as Node3D
	var right := Node3D.new()
	right.name = "RecoilPivotRight"
	left.get_parent().add_child(right)
	var second := left.get_node("Barrel2") as Node3D
	second.reparent(right,true)
	for pair: Array in [[left,left.get_node("Barrel0"),"VisualMuzzle"],[right,second,"VisualMuzzleRight"]]:
		var pivot: Node3D = pair[0]
		var barrel: MeshInstance3D = pair[1]
		var box: AABB = turret.global_transform.affine_inverse()*barrel.global_transform*barrel.get_aabb()
		var marker := pivot.find_child(pair[2],true,false) as Node3D
		if marker == null:
			marker = Marker3D.new()
			marker.name = pair[2]
			pivot.add_child(marker)
		var tip := Vector3(box.get_center().x,box.get_center().y,box.position.z)
		marker.position = pivot.to_local(turret.to_global(tip))
	_save(turret,"autocannon")
	var scout := load("res://presentation/parts/proportion_v1/scout_wheels.tscn").instantiate() as Node3D
	root.add_child(scout)
	var radius: float = 0.31
	for wheel: Node3D in scout.find_children("Wheel*","Node3D",true,false):
		var box: AABB = _bounds(wheel)
		var scale_yz := Vector3(1,radius*2/box.size.y,radius*2/box.size.z)
		for node: MeshInstance3D in wheel.find_children("*","MeshInstance3D",true,false):
			var source: Mesh = node.mesh
			var adjusted := ArrayMesh.new()
			var to_wheel: Transform3D = wheel.global_transform.affine_inverse()*node.global_transform
			var remap := to_wheel.affine_inverse()*Transform3D(Basis.from_scale(scale_yz),-box.get_center()*scale_yz)*to_wheel
			for surface: int in range(source.get_surface_count()):
				var arrays: Array = source.surface_get_arrays(surface)
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
				for i: int in range(vertices.size()): vertices[i] = remap*vertices[i]
				for i: int in range(normals.size()): normals[i] = (remap.basis.inverse().transposed()*normals[i]).normalized()
				arrays[Mesh.ARRAY_VERTEX] = vertices
				arrays[Mesh.ARRAY_NORMAL] = normals
				var tangents: PackedFloat32Array = arrays[Mesh.ARRAY_TANGENT]
				for i: int in range(0,tangents.size(),4):
					var tangent := (remap.basis*Vector3(tangents[i],tangents[i+1],tangents[i+2])).normalized()
					tangents[i] = tangent.x
					tangents[i+1] = tangent.y
					tangents[i+2] = tangent.z
				arrays[Mesh.ARRAY_TANGENT] = tangents
				adjusted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
				adjusted.surface_set_material(surface,source.surface_get_material(surface))
			node.mesh = adjusted
		wheel.position.y = radius
		wheel.position.z = STYLE.chassis_bounds.position.z+radius if wheel.position.z < STYLE.chassis_bounds.get_center().z else STYLE.chassis_bounds.end.z-radius
	var wheel_rig := scout.find_child("TrackRig",true,false) as TrackRig
	wheel_rig.style = wheel_rig.style.duplicate() as TrackRigStyle
	wheel_rig.style.wheel_radius = radius
	_save(scout,"scout_wheels")
	print("FEEDBACK PART DERIVATION: PASS")
	quit()
