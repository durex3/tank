extends "res://tools/build_refined_parts.gd"
## Final display-only finish; earlier model versions and assembly markers stay intact.

func _output_directory() -> String:
	return "res://presentation/parts/card_finished"

func _metrics_path() -> String:
	return "res://artifacts/finished-model-metrics.json"

func _build_chassis(id: String) -> void:
	# Painted ceramic armor, satin mechanisms and muted brass read differently in the same light.
	(materials["armor"] as StandardMaterial3D).roughness = 0.43
	(materials["edge"] as StandardMaterial3D).albedo_color = Color("9b947f")
	(materials["edge"] as StandardMaterial3D).roughness = 0.64
	(materials["dark"] as StandardMaterial3D).metallic = 0.35
	(materials["dark"] as StandardMaterial3D).roughness = 0.40
	(materials["gold"] as StandardMaterial3D).albedo_color = Color("bd9341")
	(materials["gold"] as StandardMaterial3D).roughness = 0.36
	super._build_chassis(id)

func _part(root_node: Node3D, name_text: String, kind: String, size: Vector3, position: Vector3, material: String = "armor", rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node: MeshInstance3D = super._part(root_node,name_text,kind,size,position,material,rotation)
	if kind == "box" and material == "armor":
		# Broader edge highlights on armor only; tiny metal hardware keeps its precise silhouette.
		var bevel: float = minf(minf(size.x,size.y),size.z)*0.28
		var mesh: ArrayMesh = _rounded_box(size,bevel)
		mesh.surface_set_material(0,materials[material])
		node.mesh = mesh
	return node

func _refine_turret(turret: Node3D) -> void:
	super._refine_turret(turret)
	var rapid: bool = turret.name == "autocannon"
	for side: int in [-1,1]:
		var x: float = side*(0.33 if rapid else 0.37)
		# These details share the swept cheek's transform, avoiding floating fasteners.
		for j: int in range(3):
			var seam := _part(turret,"CheekVent%d_%d" % [side,j],"box",Vector3(0.012,0.024,0.095),Vector3(x+side*0.123,0.025+j*0.041,0.035),"dark")
			seam.position = seam.position.rotated(Vector3.UP,side*0.13)
			seam.rotation.y = side*0.13
		for z: float in [-0.18,0.13]:
			var p := Vector3(x+side*0.125,0.11,z).rotated(Vector3.UP,side*0.13)
			_bolt(turret,"SidePlateBolt%d_%s" % [side,z],p,Vector3(0,side*0.13,PI/2))
		_part(turret,"LiftFoot%d" % side,"box",Vector3(0.07,0.025,0.085),Vector3(side*0.205,0.329,0.15),"metal",Vector3(0.07,0,side*0.35))
		_part(turret,"LiftHandle%d" % side,"box",Vector3(0.024,0.045,0.085),Vector3(side*0.205,0.35,0.15),"dark")
	# A small stepped service hatch supplies depth without changing the main silhouette.
	_part(turret,"HatchGasket","box",Vector3(0.16,0.014,0.135),Vector3(0,0.353,0.075),"rubber",Vector3(0.09,0,0))
	_part(turret,"HatchPlate","box",Vector3(0.14,0.022,0.115),Vector3(0,0.365,0.075),"armor",Vector3(0.09,0,0))
	_part(turret,"HatchHinge","cylinder",Vector3(0.015,0.11,0),Vector3(0,0.371,0.135),"metal",Vector3(0,0,PI/2))

func _refine_hull(body: Node3D) -> void:
	super._refine_hull(body)
	for side: int in [-1,1]:
		for i: int in range(4):
			var fender := body.get_node("Fender%d_%d" % [side,i]) as MeshInstance3D
			var p: Vector3 = fender.position+Vector3(0,0.057,0.065)
			_bolt(body,"FenderRivet%d_%d" % [side,i],p)
			_part(body,"FenderHinge%d_%d" % [side,i],"box",Vector3(0.075,0.018,0.025),fender.position+Vector3(0,0.055,-0.09),"metal",fender.rotation)
		_part(body,"RearLampBed%d" % side,"box",Vector3(0.105,0.065,0.035),Vector3(side*0.26,0.46,0.79),"dark")
		_part(body,"RearLampTrim%d" % side,"box",Vector3(0.065,0.027,0.018),Vector3(side*0.26,0.46,0.813),"gold")
		_bolt(body,"NoseFastener%d" % side,Vector3(side*0.095,0.588,-0.63),Vector3(0.51,0,0))

func _wheel(body: Node3D, prefix: String, position: Vector3, radius: float, width: float, side: int, spokes: int) -> void:
	super._wheel(body,prefix,position,radius,width,side,spokes)
	# Dark load-bearing spokes and restrained brass rims keep wheels from reading as jewelry.
	for j: int in range(spokes):
		var spoke := body.get_node(prefix+"Spoke%d" % j) as MeshInstance3D
		spoke.mesh = _mesh("box",Vector3(0.03,radius*0.48,radius*0.16),"metal")
