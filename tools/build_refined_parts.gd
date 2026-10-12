extends "res://tools/build_detailed_parts.gd"
## Third pass: tapered hull/turret silhouettes and inset wheels, using the established packer.

func _output_directory() -> String:
	return "res://presentation/parts/card_refined"

func _metrics_path() -> String:
	return "res://artifacts/refined-model-metrics.json"

func _save(node: Node3D, socket_name: String, position: Vector3) -> void:
	if socket_name == "Muzzle": _refine_turret(node)
	else: _refine_hull(node)
	super._save(node, socket_name, position)

func _remove_matching(node: Node3D, prefixes: Array[String]) -> void:
	for child: Node in node.get_children():
		for prefix: String in prefixes:
			if str(child.name).begins_with(prefix):
				node.remove_child(child)
				child.free()
				break

func _shell(node: Node3D, name_text: String, sections: Array[Vector4], bottom: float, material: String) -> void:
	# Each section is (z, roof height, lower half-width, roof half-width).
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var loops: Array[PackedVector3Array] = []
	for s: Vector4 in sections:
		var bevel: float = 0.025
		loops.append(PackedVector3Array([
			Vector3(-s.z+bevel,bottom,s.x),Vector3(s.z-bevel,bottom,s.x),
			Vector3(s.z,bottom+bevel,s.x),Vector3(s.z,s.y-0.075,s.x),
			Vector3(s.w,s.y,s.x),Vector3(-s.w,s.y,s.x),
			Vector3(-s.z,s.y-0.075,s.x),Vector3(-s.z,bottom+bevel,s.x)]))
	for k: int in range(loops.size()-1):
		for j: int in range(8):
			var next: int = (j+1)%8
			var a: Vector3 = loops[k][j]
			var b: Vector3 = loops[k][next]
			var c: Vector3 = loops[k+1][next]
			var d: Vector3 = loops[k+1][j]
			var normal: Vector3 = (b-a).cross(d-a).normalized()
			var center: Vector3 = (a+b+c+d)*0.25
			var outward := Vector3(center.x,center.y-(bottom+sections[k].y)*0.5,0)
			if normal.dot(outward) < 0.0: normal = -normal
			_quad(surface,a,b,c,d,normal,normal,normal,normal)
	for end: int in [0,loops.size()-1]:
		var center := Vector3.ZERO
		for p: Vector3 in loops[end]: center += p
		center /= 8.0
		var normal := Vector3(0,0,-1 if end == 0 else 1)
		for j: int in range(8):
			var a: Vector3 = loops[end][j]
			var b: Vector3 = loops[end][(j+1)%8]
			var triangle: Array[Vector3] = [center,a,b]
			if (a-center).cross(b-center).dot(normal) > 0.0: triangle.reverse()
			for point: Vector3 in triangle:
				surface.set_normal(normal)
				surface.add_vertex(point)
	surface.index()
	var mesh: ArrayMesh = surface.commit()
	mesh.surface_set_material(0,materials[material])
	var instance := MeshInstance3D.new()
	instance.name = name_text
	instance.mesh = mesh
	node.add_child(instance)
	instance.owner = node

func _refine_turret(turret: Node3D) -> void:
	var rapid: bool = turret.name == "autocannon"
	var scatter: bool = turret.name == "scatter"
	_remove_matching(turret,["Mechanism","Cheek","RoofCenter","RoofSeam","FrontBrow","RearVent"])
	var width: float = 0.31 if rapid else 0.37
	_shell(turret,"TaperedMechanism",[
		Vector4(-0.40,0.17,width*0.76,width*0.64),Vector4(-0.18,0.30,width,width*0.70),
		Vector4(0.19,0.31,width,width*0.72),Vector4(0.39,0.17,width*0.76,width*0.65)],-0.09,"dark")
	var armor: Array[Vector2] = [Vector2(-0.36,-0.07),Vector2(-0.43,0.07),Vector2(-0.28,0.26),Vector2(-0.10,0.33),Vector2(0.21,0.31),Vector2(0.32,0.16),Vector2(0.25,-0.07)]
	var insert: Array[Vector2] = [Vector2(-0.19,-0.04),Vector2(-0.27,0.08),Vector2(-0.15,0.19),Vector2(0.08,0.18),Vector2(0.18,0.07),Vector2(0.12,-0.04)]
	for side: int in [-1,1]:
		var x: float = side*(0.33 if rapid else 0.37)
		_panel(turret,"SweptCheek%d" % side,armor,minf(x,x+side*0.09),maxf(x,x+side*0.09),"armor")
		(turret.get_node("SweptCheek%d" % side) as Node3D).rotation.y = side*0.13
		_panel(turret,"InsetBorder%d" % side,insert,minf(x+side*0.08,x+side*0.105),maxf(x+side*0.08,x+side*0.105),"edge")
		_panel(turret,"InsetArmor%d" % side,insert,minf(x+side*0.105,x+side*0.12),maxf(x+side*0.105,x+side*0.12),"armor")
		(turret.get_node("InsetBorder%d" % side) as Node3D).rotation.y = side*0.13
		(turret.get_node("InsetArmor%d" % side) as Node3D).rotation.y = side*0.13
		_part(turret,"RoofShoulder%d" % side,"box",Vector3(0.16,0.045,0.37),Vector3(side*0.22,0.30,-0.035),"armor",Vector3(0.07,0,side*0.35))
		_part(turret,"RoofGap%d" % side,"box",Vector3(0.012,0.015,0.29),Vector3(side*0.125,0.334,-0.04),"rubber",Vector3(0.07,0,0))
	_part(turret,"SlopedRoof","box",Vector3(0.23,0.045,0.40),Vector3(0,0.325,-0.04),"armor",Vector3(0.09,0,0))
	_part(turret,"SlopedBrow","box",Vector3(0.46,0.065,0.17),Vector3(0,0.22,-0.315),"armor",Vector3(-0.48,0,0))
	if scatter:
		# Bring the housing forward, retaining the authoritative muzzle but shortening exposed tubes.
		for side: int in [-1,1]:
			_part(turret,"ScatterFrontCheek%d" % side,"box",Vector3(0.13,0.28,0.20),Vector3(side*0.33,0.06,-0.40),"armor",Vector3(0,side*0.15,side*0.12))
		_part(turret,"ScatterBridge","box",Vector3(0.075,0.20,0.13),Vector3(0,0.04,-0.46),"armor")
	else:
		var optic := turret.get_node("OpticHousing") as Node3D
		optic.scale = Vector3(0.9,0.85,0.9)

func _refine_hull(body: Node3D) -> void:
	var heavy: bool = body.name == "heavy_tracks"
	var wheels: bool = body.name == "scout_wheels"
	_remove_matching(body,["Deck","NoseSlope","NoseInlay","NoseInnerPlate"])
	var w: float = 0.51 if heavy else (0.39 if wheels else 0.43)
	_shell(body,"TaperedHull",[
		Vector4(-0.94,0.43,0.245,0.20),Vector4(-0.56,0.65,w*0.89,w*0.70),
		Vector4(0.45,0.67,w,w*0.87),Vector4(0.79,0.56,w*0.80,w*0.66)],0.36,"armor")
	_part(body,"NoseSeamBed","box",Vector3(0.30,0.025,0.37),Vector3(0,0.555,-0.69),"dark",Vector3(0.51,0,0))
	_part(body,"NoseCenterPlate","box",Vector3(0.275,0.025,0.33),Vector3(0,0.578,-0.69),"armor",Vector3(0.51,0,0))
	for side: int in [-1,1]:
		for i: int in range(4):
			var fender := body.get_node("Fender%d_%d" % [side,i]) as Node3D
			fender.rotation.x = 0.20 if i == 0 else (-0.14 if i == 3 else 0.0)
			fender.scale.z = 0.92
			if wheels: fender.scale.x = 0.72
		for name_text: String in ["LampHousing","LampRim","Lamp","TowEye"]:
			var detail := body.get_node(name_text+str(side)) as Node3D
			detail.position.x *= 0.82
		_part(body,"ShoulderSeam%d" % side,"box",Vector3(0.016,0.018,0.65),Vector3(side*w*0.77,0.665,-0.04),"dark")

func _tracks(body: Node3D, side: int, x: float, heavy: bool) -> void:
	super._tracks(body,side,x,heavy)
	_remove_matching(body,["Road%d_" % side])
	var width: float = 0.38 if heavy else 0.30
	for j: int in range(6):
		var end: bool = j == 0 or j == 5
		var z: float = [-0.65,-0.37,-0.123,0.123,0.37,0.65][j]
		_wheel(body,"Road%d_%d" % [side,j],Vector3(side*x,0.285 if end else 0.215,z),0.165 if end else 0.123,width,side,6)

func _wheel(body: Node3D, prefix: String, position: Vector3, radius: float, width: float, side: int, spokes: int) -> void:
	var scout: bool = prefix.begins_with("Scout")
	var tyre_width: float = width*(0.93 if scout else 0.80)
	_tube(body,prefix+"Tyre",radius,radius*0.69,tyre_width,position,"rubber",Vector3(0,0,PI/2))
	var face: Vector3 = position + Vector3(side*tyre_width*0.48,0,0)
	_part(body,prefix+"Sidewall","ring",Vector3(radius*0.78,radius*0.98,0),face,"rubber",Vector3(0,0,PI/2))
	_part(body,prefix+"GoldDish","cylinder",Vector3(radius*0.75,0.028,0),face-Vector3(side*0.02,0,0),"gold",Vector3(0,0,PI/2))
	_part(body,prefix+"Inset","cylinder",Vector3(radius*0.61,0.018,0),face,"dark",Vector3(0,0,PI/2))
	_tube(body,prefix+"Lip",radius*0.81,radius*0.73,0.024,face+Vector3(side*0.008,0,0),"gold",Vector3(0,0,PI/2))
	for j: int in range(spokes):
		var angle: float = TAU*j/spokes
		_part(body,prefix+"Spoke%d" % j,"box",Vector3(0.028,radius*0.48,radius*0.12),face+Vector3(side*0.013,cos(angle)*radius*0.40,sin(angle)*radius*0.40),"gold",Vector3(angle,0,0))
	_part(body,prefix+"Hub","cylinder",Vector3(radius*0.27,0.043,0),face+Vector3(side*0.016,0,0),"metal",Vector3(0,0,PI/2))
	_bolt(body,prefix+"Bolt",face+Vector3(side*0.043,0,0),Vector3(0,0,PI/2))
