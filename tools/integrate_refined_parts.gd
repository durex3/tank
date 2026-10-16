extends "res://tools/normalize_part_sizes.gd"
## Offline derivation: authoritative roots stay fixed, circular components stay rigid.

const DEST: String = "res://presentation/parts/refined_v2/"
const LEGACY_TURRETS: Dictionary = {
	&"cannon": "res://presentation/parts/proportion_v1/cannon.tscn",
	&"scatter": "res://presentation/parts/proportion_v1/scatter.tscn",
	&"bubble_cannon": "res://presentation/parts/proportion_v1/bubble_cannon.tscn",
}

func _own(node: Node, part: Node) -> void:
	if node != part: node.owner = part
	if node is Node3D: node.scene_file_path = ""
	if node is TrackRig: return
	for child: Node in node.get_children(): _own(child, part)

func _save(part: Node3D, id: StringName) -> void:
	_own(part, part)
	var packed := PackedScene.new()
	assert(packed.pack(part) == OK)
	assert(ResourceSaver.save(packed, DEST + str(id) + ".tscn") == OK)
	print(id, " ", _bounds(part))
	part.free()

func _marker(part: Node3D, turret: bool) -> void:
	var marker := Marker3D.new()
	marker.name = "Muzzle" if turret else "TurretSocket"
	marker.position = Vector3(0, 0.02, -1.05) if turret else Vector3(0, 0.76, 0)
	part.add_child(marker)

func _new_part(id: StringName) -> Node3D:
	var part := Node3D.new()
	part.name = str(id)
	root.add_child(part)
	return part

func _metal() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("30383d")
	material.roughness = 0.65
	return material

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	var turret := _new_part(&"autocannon")
	var model := load("res://assets/derived/hyper3d-refined-v1/t02.glb").instantiate() as Node3D
	turret.add_child(model)
	model.name = "Geometry"
	model.position.y = 0.12
	for node: Node in model.find_children("*", "", true, false):
		var label := str(node.name)
		if label.begins_with("RecoilLeft"): node.name = "RecoilPivot"
		elif label.begins_with("RecoilRight"): node.name = "RecoilPivotRight"
		elif label.begins_with("VisualMuzzleLeft"): node.name = "VisualMuzzle"
		elif label.begins_with("VisualMuzzleRight"): node.name = "VisualMuzzleRight"
		elif label.begins_with("T02Armor"): node.name = "Body"
	_marker(turret, true)
	var turret_target := _bounds(turret)
	_save(turret, &"autocannon")
	var hull := _new_part(&"scout_wheels")
	model = load("res://assets/derived/hyper3d-refined-v2/c03.glb").instantiate() as Node3D
	hull.add_child(model)
	model.name = "Geometry"
	# Existing ImportedWheelRig expects axle centers on the rolling node itself.
	for node: Node in model.find_children("Wheel*", "Node3D", true, false):
		(node as Node3D).reparent(hull, true)
	var imported := ImportedWheelRig.new()
	imported.name = "TrackRig"
	imported.style = TrackRigStyle.new()
	imported.style.wheel_radius = 0.42
	imported.style.axle_x = 0.627
	hull.add_child(imported)
	_marker(hull, false)
	var chassis_target := _bounds(hull)
	_save(hull, &"scout_wheels")
	var style := STYLE.duplicate() as PartSizeStyle
	style.turret_bounds = turret_target
	style.chassis_bounds = chassis_target
	assert(ResourceSaver.save(style, "res://content/presentation/part_size.tres") == OK)
	for id: StringName in LEGACY_TURRETS:
		var part := _new_part(id)
		var geometry := load(LEGACY_TURRETS[id]).instantiate() as Node3D
		part.add_child(geometry)
		geometry.name = "Geometry"
		var old := _bounds(part)
		var factor: float = turret_target.size.x / old.size.x
		geometry.scale = Vector3.ONE * factor
		geometry.position = Vector3(turret_target.position.x-old.position.x*factor,
			turret_target.end.y-old.end.y*factor, turret_target.end.z-old.end.z*factor)
		var current := _bounds(part)
		var extension: float = current.position.z - turret_target.position.z
		var pivot := part.find_child("RecoilPivot", true, false) as Node3D
		var move_local: Vector3 = pivot.global_basis.inverse() * Vector3(0,0,-extension)
		for child: Node3D in pivot.get_children(): child.position += move_local
		var collar := MeshInstance3D.new()
		collar.name = "TemplateMountCollar"
		var cylinder := CylinderMesh.new()
		cylinder.radial_segments = 8
		cylinder.top_radius = 0.46
		cylinder.bottom_radius = 0.34
		cylinder.height = current.position.y - turret_target.position.y + 0.025
		collar.mesh = cylinder
		var armor := StandardMaterial3D.new()
		armor.albedo_color = Color("dadbd3")
		armor.roughness = 0.65
		collar.material_override = armor
		collar.position = Vector3(0,turret_target.position.y+cylinder.height/2.0,0)
		part.add_child(collar)
		_marker(part,true)
		assert((_bounds(part).size-turret_target.size).length()<0.0002, str(id))
		_save(part,id)
	for id: StringName in [&"light_tracks", &"heavy_tracks"]:
		var part := _new_part(id)
		var geometry := load("res://presentation/parts/proportion_v1/%s.tscn" % id).instantiate() as Node3D
		part.add_child(geometry)
		geometry.name = "Geometry"
		var old := _bounds(part)
		var old_rig := part.find_child("TrackRig",true,false) as TrackRig
		var rig_style := old_rig.style.duplicate() as TrackRigStyle
		old_rig.free()
		geometry.scale = chassis_target.size/old.size
		geometry.position = chassis_target.position-old.position*geometry.scale
		var rig := TrackRig.new()
		rig.name = "TrackRig"
		rig_style.axle_x = chassis_target.size.x/2.0-rig_style.belt_width/2.0
		var allowance: float = rig_style.belt_radius+rig_style.belt_thickness/2.0+rig_style.cleat_height
		rig_style.front_z = chassis_target.position.z+allowance
		rig_style.rear_z = chassis_target.end.z-allowance
		rig.style = rig_style
		part.add_child(rig)
		# Correct sampled arc/cleat extents until the rest-pose envelope converges.
		for attempt: int in range(8):
			var actual := _bounds(rig)
			rig_style.front_z += chassis_target.position.z-actual.position.z
			rig_style.rear_z += chassis_target.end.z-actual.end.z
			rig.free()
			rig = TrackRig.new()
			rig.name = "TrackRig"
			rig.style = rig_style
			part.add_child(rig)
		rig.position.x = chassis_target.get_center().x
		_marker(part,false)
		assert((_bounds(part).size-chassis_target.size).length()<0.0002,str(id)+str(_bounds(part)))
		_save(part,id)
	print("REFINED PRODUCTION DERIVATION PASS")
	quit()
