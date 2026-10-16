extends "res://tools/normalize_part_sizes.gd"
## Fixed authored meshes + existing validated motion; no gameplay or size migration.
const DEST := "res://presentation/parts/bubble_compact_v1/"
var failed: bool = false

func _own(node: Node, part: Node) -> void:
	if node != part: node.owner = part
	if node is Node3D: node.scene_file_path = ""
	if node is TrackRig: return
	for child: Node in node.get_children(): _own(child,part)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	for id: String in ["bubble_cannon"]:
		var turret := id in ["autocannon","scatter","bubble_cannon"]
		var part := Node3D.new()
		part.name = id
		root.add_child(part)
		var geometry := load("res://assets/derived/bubble-compact-v1/%s.glb" % id).instantiate() as Node3D
		geometry.name = "Geometry"
		part.add_child(geometry)
		for node: Node in geometry.find_children("*","",true,false):
			# Blender's datablock suffixes must not change the motion contract.
			for label: String in ["RecoilPivotRight","RecoilPivot","VisualMuzzleRight","VisualMuzzle"]:
				if str(node.name) == label or str(node.name).begins_with(label+"_") or str(node.name).begins_with(label+"."):
					node.name = label
		if turret:
			geometry.position.y = STYLE.turret_bounds.position.y
		else:
			var previous := load("res://presentation/parts/mechanical_v1/%s.tscn" % id).instantiate() as Node3D
			root.add_child(previous)
			var old_rig := previous.find_child("TrackRig",true,false) as TrackRig
			var rig := TrackRig.new()
			rig.name = "TrackRig"
			rig.style = old_rig.style.duplicate() as TrackRigStyle
			rig.position = old_rig.position
			part.add_child(rig)
			previous.free()
		var marker := Marker3D.new()
		marker.name = "Muzzle" if turret else "TurretSocket"
		marker.position = Vector3(0,.02,-1.05) if turret else Vector3(0,.76,0)
		part.add_child(marker)
		var target: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		var actual := _bounds(part)
		if (actual.position-target.position).length()>.0002 or (actual.size-target.size).length()>.0002:
			push_error(id+" envelope "+str(actual))
			failed = true
		else:
			_own(part,part)
			var packed := PackedScene.new()
			assert(packed.pack(part)==OK)
			assert(ResourceSaver.save(packed,DEST+id+".tscn")==OK)
			print(id," ",actual)
		part.free()
	print("MECHANICAL FAMILY DERIVATION: "+("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
