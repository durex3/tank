extends RefCounted
## Development-only visual swap for the approved 105 prototype. No catalog mutation.

static func install(view: TankView) -> void:
	var hull := _part(false)
	var turret := _part(true)
	assert(TankPartCatalog.validate_part(hull, &"TurretSocket", Vector3(0,0.76,0)).is_empty())
	assert(TankPartCatalog.validate_part(turret, &"Muzzle", Vector3(0,0.02,-1.05)).is_empty())
	view._replace_child(view._hull,hull)
	view._replace_child(view._turret,turret)
	view._turret.position = Vector3(0,0.76,0)
	view._muzzle = turret.get_node("Muzzle") as Marker3D
	view._tracks.bind(hull)
	view._recoil.bind(turret,&"cannon")
	view._right_recoil.bind(turret,&"cannon","RecoilPivotRight")
	view.reset_visual_motion()

static func _part(turret: bool) -> Node3D:
	var part := Node3D.new()
	part.name = "MechanicalCannon" if turret else "MechanicalScout"
	var id := "cannon" if turret else "scout_wheels"
	var geometry := load("res://assets/derived/mechanical-sample-v1/%s.glb" % id).instantiate() as Node3D
	geometry.name = "Geometry"
	part.add_child(geometry)
	if turret:
		# The standalone design rests at 0.885 m; authority socket stays at 0.76 m.
		geometry.position.y = 0.125
	else:
		# Wheel cover/slot nodes are not motion pivots; existing rig discovers Wheel*.
		for node: Node in geometry.find_children("Wheel*", "", true, false):
			if node is MeshInstance3D: node.name = "Detail_" + str(node.name)
		for name: String in ["WheelLeftFront","WheelLeftRear","WheelRightFront","WheelRightRear"]:
			var wheel := geometry.find_child(name,true,false) as Node3D
			assert(wheel != null)
			var pose := wheel.transform
			var ancestor := wheel.get_parent() as Node3D
			while ancestor != part:
				pose = ancestor.transform * pose
				ancestor = ancestor.get_parent() as Node3D
			wheel.owner = null
			for child: Node in wheel.find_children("*", "", true, false): child.owner = null
			wheel.reparent(part,false)
			wheel.transform = pose
		var rig := ImportedWheelRig.new()
		rig.name = "TrackRig"
		rig.style = TrackRigStyle.new()
		rig.style.wheel_radius = 0.402
		rig.style.axle_x = 0.63
		part.add_child(rig)
	var marker := Marker3D.new()
	marker.name = "Muzzle" if turret else "TurretSocket"
	marker.position = Vector3(0,0.02,-1.05) if turret else Vector3(0,0.76,0)
	part.add_child(marker)
	return part
