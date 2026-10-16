extends "res://tools/normalize_part_sizes.gd"
## Rebuild from immutable 105 and family_v3 sources, never from the output catalog.

const DEST := "res://presentation/parts/mechanical_v1/"
var failed: bool = false

const SAMPLE = preload("res://presentation/previews/mechanical_sample_mount.gd")

func _own(node: Node, part: Node) -> void:
	if node != part: node.owner = part
	if node is Node3D: node.scene_file_path = ""
	if node is TrackRig: return
	for child: Node in node.get_children(): _own(child, part)

func _save(part: Node3D, id: String, target: AABB) -> void:
	var actual := _bounds(part)
	if (actual.position-target.position).length()>=0.0002 or (actual.size-target.size).length()>=0.0002:
		failed = true
		push_error(id+" envelope "+str(actual))
		part.free()
		return
	_own(part,part)
	var packed := PackedScene.new()
	assert(packed.pack(part) == OK)
	assert(ResourceSaver.save(packed,DEST+id+".tscn") == OK)
	print(id," ",actual)
	part.free()

func _scout() -> Node3D:
	var part := SAMPLE._part(false)
	# Replace only the wheel meshes with the corrected Blender derivative.
	var corrected := load("res://assets/derived/mechanical-production-v1/scout_wheels.glb").instantiate() as Node3D
	for name: String in ["WheelLeftFront","WheelLeftRear","WheelRightFront","WheelRightRear"]:
		var wheel := part.get_node(name) as Node3D
		var source := corrected.find_child(name,true,false) as Node3D
		for child: Node in wheel.get_children(): child.free()
		for child: Node in source.get_children():
			child.owner = null
			child.reparent(wheel,false)
			if str(child.name).begins_with("Wheel"): child.name = "Detail_"+str(child.name)
	corrected.free()
	return part

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST)
	var cannon := SAMPLE._part(true)
	root.add_child(cannon)
	var turret_target := _bounds(cannon)
	_save(cannon,"cannon",turret_target)
	var scout := _scout()
	root.add_child(scout)
	var chassis_target := _bounds(scout)
	_save(scout,"scout_wheels",chassis_target)
	for id: String in ["autocannon","scatter","bubble_cannon"]:
		_turret(id,turret_target)
	for id: String in ["light_tracks","heavy_tracks"]:
		_tracks(id,chassis_target)
	if failed:
		quit(1)
		return
	var style := STYLE.duplicate() as PartSizeStyle
	style.turret_bounds = turret_target
	style.chassis_bounds = chassis_target
	assert(ResourceSaver.save(style,"res://content/presentation/part_size.tres") == OK)
	print("MECHANICAL PRODUCTION DERIVATION: PASS")
	quit()

func _turret(id: String, target: AABB) -> void:
	var part := load("res://presentation/parts/family_v3/%s.tscn" % id).instantiate() as Node3D
	root.add_child(part)
	var old := _bounds(part)
	var geometry := part.get_node("Geometry") as Node3D
	var factor := target.size.y/old.size.y
	geometry.scale *= factor
	geometry.position = geometry.position*factor + Vector3(0,target.position.y-old.position.y*factor,target.end.z-old.end.z*factor)
	# Preserve the original housing proportions; add real lateral cheek armor.
	var body := part.find_child("Body",true,false) as MeshInstance3D
	var box: AABB = body.global_transform * body.get_aabb()
	var gap := (target.size.x-box.size.x)*0.5
	for side: float in [-1.0,1.0]:
		var armor := MeshInstance3D.new()
		armor.name = "AdapterCheekLeft" if side<0 else "AdapterCheekRight"
		var mesh := BoxMesh.new()
		mesh.size = Vector3(gap+0.035,minf(0.24,box.size.y*0.6),minf(0.66,box.size.z*0.75))
		armor.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.78,0.80,0.79)
		material.roughness = 0.55
		armor.material_override = material
		armor.position = Vector3(side*(target.size.x-mesh.size.x)/2,box.get_center().y,box.get_center().z)
		part.add_child(armor)
	var current := _bounds(part)
	var extension := current.position.z-target.position.z
	for name: String in ["RecoilPivot","RecoilPivotRight"]:
		var pivot := part.find_child(name,true,false) as Node3D
		if pivot == null: continue
		for child: Node3D in pivot.get_children():
			if "Sleeve" in str(child.name):
				# Extend only the existing sleeve along its barrel axis; section stays round.
				var sleeve := child as MeshInstance3D
				var sleeve_box: AABB = sleeve.global_transform*sleeve.get_aabb()
				var rear := sleeve_box.end.z
				var stretch := (sleeve_box.size.z+extension)/sleeve_box.size.z
				var pose := sleeve.global_transform
				var axial := Transform3D(Basis.from_scale(Vector3(1,1,stretch)),Vector3(0,0,rear*(1-stretch)))
				sleeve.global_transform = axial*pose
			else:
				child.global_position.z -= extension
	_save(part,id,target)

func _tracks(id: String, target: AABB) -> void:
	var part := load("res://presentation/parts/family_v3/%s.tscn" % id).instantiate() as Node3D
	root.add_child(part)
	var old_rig := part.find_child("TrackRig",true,false) as TrackRig
	var style := old_rig.style.duplicate() as TrackRigStyle
	old_rig.free()
	var old := _bounds(part)
	var geometry := part.get_node("Geometry") as Node3D
	# Only static armor changes proportions. The wheel/belt rig stays a rigid sibling.
	geometry.scale *= Vector3(1,(target.end.y-0.22)/(old.end.y-0.22),1)
	geometry.position.y = target.end.y-old.end.y*geometry.scale.y
	style.axle_x = target.size.x/2.0-style.belt_width/2.0
	var rig: TrackRig
	for attempt: int in range(10):
		if rig != null: rig.free()
		rig = TrackRig.new()
		rig.name = "TrackRig"
		rig.style = style
		part.add_child(rig)
		var actual := _bounds(rig)
		rig.position.y = target.position.y-actual.position.y
		style.front_z += target.position.z-actual.position.z
		style.rear_z += target.end.z-actual.end.z
	_save(part,id,target)
