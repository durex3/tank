extends "res://tools/normalize_part_sizes.gd"
const DEST: String = "res://presentation/parts/classic_toy_v1/"
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	for id: String in ["cannon","light_tracks"]:
		var turret: bool = id == "cannon"
		var part := Node3D.new()
		part.name = id
		part.set_meta("soft_workshop",true)
		part.set_meta("soft_workshop_style","res://content/presentation/classic_toy_v1.tres")
		root.add_child(part)
		var geometry := load("res://assets/derived/classic-toy-v1/%s.glb" % id).instantiate() as Node3D
		geometry.name = "Geometry"
		part.add_child(geometry)
		geometry.owner = part
		if turret: geometry.position.y = STYLE.turret_bounds.position.y
		else:
			var old := load("res://presentation/parts/mechanical_v2/light_tracks.tscn").instantiate() as Node3D
			root.add_child(old)
			var source := old.find_child("TrackRig",true,false) as TrackRig
			var rig := TrackRig.new()
			rig.name = "TrackRig"
			rig.style = source.style.duplicate() as TrackRigStyle
			rig.style.sculpted_wheels = true
			rig.position = source.position
			part.add_child(rig)
			rig.owner = part
			old.free()
		var marker := Marker3D.new()
		marker.name = "Muzzle" if turret else "TurretSocket"
		marker.position = Vector3(0,.02,-1.05) if turret else Vector3(0,.76,0)
		part.add_child(marker)
		marker.owner = part
		var target: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		var actual: AABB = _bounds(part)
		print(id," envelope ",actual," expected ",target)
		assert((actual.position-target.position).length()<.0002 and (actual.size-target.size).length()<.0002,"Sample must retain the unified envelope")
		var packed := PackedScene.new()
		assert(packed.pack(part)==OK)
		assert(ResourceSaver.save(packed,DEST+id+".tscn")==OK)
		part.free()
	print("SOFT WORKSHOP INTEGRATION: PASS")
	quit()
