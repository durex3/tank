extends "res://tools/normalize_part_sizes.gd"
## Pack Blender-derived geometry with unchanged gameplay sockets and existing motion rigs.

const DEST: String = "res://presentation/parts/family_v3/"

func _own(node: Node, part: Node) -> void:
	if node != part: node.owner = part
	if node is Node3D: node.scene_file_path = ""
	if node is TrackRig: return
	for child: Node in node.get_children(): _own(child, part)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	for id: StringName in [&"cannon", &"autocannon", &"scatter", &"bubble_cannon", &"light_tracks", &"scout_wheels", &"heavy_tracks"]:
		var turret: bool = id in [&"cannon", &"autocannon", &"scatter", &"bubble_cannon"]
		var part := Node3D.new()
		part.name = str(id)
		root.add_child(part)
		if id == &"autocannon":
			part.free()
			part = load("res://presentation/parts/refined_v2/autocannon.tscn").instantiate() as Node3D
			root.add_child(part)
		else:
			var geometry := load("res://assets/derived/family-refined-v2/%s.glb" % id).instantiate() as Node3D
			geometry.name = "Geometry"
			part.add_child(geometry)
			for node: Node in geometry.find_children("*", "", true, false):
				for label: String in ["RecoilPivot", "VisualMuzzle", "Body", "Barrel"]:
					if str(node.name).begins_with(label): node.name = label
			if id == &"scout_wheels":
				for node: Node in geometry.find_children("Wheel*", "Node3D", true, false):
					(node as Node3D).reparent(part, true)
				var rig := ImportedWheelRig.new()
				rig.name = "TrackRig"
				rig.style = TrackRigStyle.new()
				rig.style.wheel_radius = 0.42
				rig.style.axle_x = 0.627
				part.add_child(rig)
			elif not turret:
				var previous := load("res://presentation/parts/refined_v2/%s.tscn" % id).instantiate() as Node3D
				root.add_child(previous)
				var old_rig := previous.find_child("TrackRig", true, false) as TrackRig
				var rig := TrackRig.new()
				rig.name = "TrackRig"
				rig.style = old_rig.style.duplicate() as TrackRigStyle
				rig.position = old_rig.position
				# Shared white disc / yellow ring / black slot design for both track classes.
				rig.style.face = Color(0.91, 0.925, 0.92)
				part.add_child(rig)
				previous.free()
			var marker := Marker3D.new()
			marker.name = "Muzzle" if turret else "TurretSocket"
			marker.position = Vector3(0,0.02,-1.05) if turret else Vector3(0,0.76,0)
			part.add_child(marker)
		var expected: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		var actual := _bounds(part)
		assert((actual.size-expected.size).length()<0.0002,str(id)+" size "+str(actual))
		assert((actual.position-expected.position).length()<0.0002,str(id)+" placement "+str(actual))
		_own(part, part)
		var packed := PackedScene.new()
		assert(packed.pack(part) == OK)
		assert(ResourceSaver.save(packed, DEST+str(id)+".tscn") == OK)
		print(id, " ", actual)
		part.free()
	print("FAMILY 103 DERIVATION PASS")
	quit()
