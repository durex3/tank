extends "res://tools/build_card_aligned_parts.gd"
## Offline second pass. Shares mesh packing with 035; produces new scenes, never old assets.

func _output_directory() -> String:
	return "res://presentation/parts/card_detailed"

func _face_steps(extent: float, bevel: float) -> Array[float]:
	# The flat face needs no middle subdivision; bevel silhouette and normals are unchanged.
	return [-extent, -extent+bevel, extent-bevel, extent]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(_output_directory())
	var palette: Dictionary = {"armor": Color("e8dfc9"), "edge": Color("b5ac98"), "dark": Color("24282e"), "rubber": Color("11171c"), "metal": Color("5f6870"), "gold": Color("d7aa45"), "green": Color("24bc78")}
	for key: String in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[key]
		material.roughness = 0.32 if key == "armor" else (0.27 if key == "gold" else 0.55)
		material.metallic = 0.82 if key == "gold" else (0.65 if key == "metal" else 0.0)
		if key == "rubber": material.roughness = 0.92
		if key == "green":
			material.emission_enabled = true
			material.emission = Color("1d9d62")
			material.emission_energy_multiplier = 0.65
		materials[key] = material
	for id: String in ["light_tracks", "heavy_tracks", "scout_wheels"]: _build_chassis(id)
	for id: String in ["cannon", "autocannon", "scatter"]: _build_turret(id)
	var report := FileAccess.open(_metrics_path(), FileAccess.WRITE)
	report.store_string(JSON.stringify(metrics, "\t"))
	print("DETAILED PARTS: PASS (six new native scenes)")
	quit()

func _metrics_path() -> String:
	return "res://artifacts/detailed-model-metrics.json"

func _tube(root_node: Node3D, name_text: String, radius: float, inner: float, length: float, position: Vector3, material: String, rotation: Vector3 = Vector3(PI/2, 0, 0)) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(32):
		var a: float = TAU * i / 32.0
		var b: float = TAU * (i + 1) / 32.0
		var na := Vector3(cos(a), 0, sin(a))
		var nb := Vector3(cos(b), 0, sin(b))
		var top := Vector3.UP * length * 0.5
		_quad(surface, na*radius-top, nb*radius-top, nb*radius+top, na*radius+top, na, nb, nb, na)
		_quad(surface, nb*inner-top, na*inner-top, na*inner+top, nb*inner+top, -nb, -na, -na, -nb)
		_quad(surface, na*inner+top, na*radius+top, nb*radius+top, nb*inner+top, Vector3.UP, Vector3.UP, Vector3.UP, Vector3.UP)
		_quad(surface, nb*inner-top, nb*radius-top, na*radius-top, na*inner-top, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN, Vector3.DOWN)
	# All sources must be indexed before material merging; mixed formats orphan vertices.
	surface.index()
	var mesh: ArrayMesh = surface.commit()
	mesh.surface_set_material(0, materials[material])
	var node := MeshInstance3D.new()
	node.name = name_text
	node.mesh = mesh
	node.position = position
	node.rotation = rotation
	root_node.add_child(node)
	node.owner = root_node

func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, na: Vector3, nb: Vector3, nc: Vector3, nd: Vector3) -> void:
	var points: Array[Vector3] = [a,b,c,a,c,d]
	var normals: Array[Vector3] = [na,nb,nc,na,nc,nd]
	# Godot front faces are clockwise; fix each quad relative to its authored outward normal.
	if (b-a).cross(c-a).dot(na+nb+nc) > 0.0:
		points = [a,c,b,a,d,c]
		normals = [na,nc,nb,na,nd,nc]
	for i: int in range(6):
		surface.set_normal(normals[i])
		surface.add_vertex(points[i])

func _panel(root_node: Node3D, name_text: String, profile: Array[Vector2], x0: float, x1: float, material: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var center := Vector2.ZERO
	for p: Vector2 in profile: center += p
	center /= profile.size()
	var bevel: float = minf(0.015, (x1-x0)*0.25)
	for i: int in range(profile.size()):
		var p: Vector2 = profile[i]
		var q: Vector2 = profile[(i+1) % profile.size()]
		var inset_p: Vector2 = p + (center-p).normalized()*bevel*1.5
		var inset_q: Vector2 = q + (center-q).normalized()*bevel*1.5
		var a := Vector3(x0+bevel,p.y,p.x)
		var b := Vector3(x1-bevel,p.y,p.x)
		var c := Vector3(x1-bevel,q.y,q.x)
		var d := Vector3(x0+bevel,q.y,q.x)
		var midpoint := (p+q)*0.5-center
		var outward := Vector3(0,midpoint.y,midpoint.x).normalized()
		var normal: Vector3 = (b-a).cross(c-a).normalized()
		if normal.dot(outward) < 0.0: normal = -normal
		_quad(surface,a,b,c,d,normal,normal,normal,normal)
		for side: int in [-1,1]:
			var x: float = x0 if side < 0 else x1
			var n := Vector3(float(side),0,0)
			var bevel_normal: Vector3 = (n+normal).normalized()
			_quad(surface,Vector3(x,inset_p.y,inset_p.x),Vector3(x-side*bevel,p.y,p.x),Vector3(x-side*bevel,q.y,q.x),Vector3(x,inset_q.y,inset_q.x),bevel_normal,bevel_normal,bevel_normal,bevel_normal)
			var points: Array[Vector3] = [Vector3(x,center.y,center.x),Vector3(x,inset_p.y,inset_p.x),Vector3(x,inset_q.y,inset_q.x)]
			if (points[1]-points[0]).cross(points[2]-points[0]).dot(n) > 0.0: points.reverse()
			for vertex: Vector3 in points:
				surface.set_normal(n)
				surface.add_vertex(vertex)
	surface.index()
	var mesh: ArrayMesh = surface.commit()
	mesh.surface_set_material(0,materials[material])
	var node := MeshInstance3D.new()
	node.name = name_text
	node.mesh = mesh
	root_node.add_child(node)
	node.owner = root_node

func _bolt(root_node: Node3D, name_text: String, position: Vector3, rotation: Vector3 = Vector3.ZERO) -> void:
	_part(root_node,name_text,"octagon",Vector3(0.018,0.012,0),position,"metal",rotation)

func _build_turret(id: String) -> void:
	var turret := Node3D.new()
	turret.name = id
	var rapid: bool = id == "autocannon"
	_part(turret,"Turntable","cylinder",Vector3(0.32,0.07,0),Vector3(0,-0.045,0),"dark")
	_part(turret,"BearingLip","ring",Vector3(0.30,0.325,0),Vector3(0,-0.05,0),"gold")
	_part(turret,"Mechanism","box",Vector3(0.62,0.36,0.64),Vector3(0,0.12,0.04),"dark")
	var cheek: Array[Vector2] = [Vector2(-0.36,-0.08),Vector2(-0.43,0.11),Vector2(-0.23,0.32),Vector2(0.23,0.34),Vector2(0.40,0.18),Vector2(0.36,-0.08)]
	var outer: Array[Vector2] = [Vector2(-0.20,-0.035),Vector2(-0.27,0.10),Vector2(-0.14,0.22),Vector2(0.15,0.22),Vector2(0.27,0.12),Vector2(0.22,-0.035)]
	for side: int in [-1,1]:
		var x0: float = side*0.24
		var x1: float = side*(0.39 if rapid else 0.43)
		_panel(turret,"Cheek%d" % side,cheek,minf(x0,x1),maxf(x0,x1),"armor")
		_panel(turret,"CheekInsert%d" % side,outer,minf(x1, x1+side*0.026),maxf(x1,x1+side*0.026),"edge")
		_panel(turret,"CheekOverlay%d" % side,outer,minf(x1+side*0.027,x1+side*0.045),maxf(x1+side*0.027,x1+side*0.045),"armor")
		_part(turret,"RearHousing%d" % side,"box",Vector3(0.15,0.27,0.25),Vector3(side*0.31,0.13,0.30),"dark")
		_part(turret,"RearInset%d" % side,"box",Vector3(0.018,0.11,0.13),Vector3(side*0.395,0.12,0.32),"metal")
		for z: float in [-0.13,0.14]: _bolt(turret,"CheekFastener%d_%s" % [side,z],Vector3(x1+side*0.05,0.10,z),Vector3(0,0,PI/2))
	_part(turret,"RoofCenter","box",Vector3(0.28,0.055,0.49),Vector3(0,0.335,0.025),"armor")
	_part(turret,"FrontBrow","box",Vector3(0.52,0.065,0.17),Vector3(0,0.245,-0.30),"armor",Vector3(-0.15,0,0))
	if id == "scatter": _part(turret,"CenterBridge","box",Vector3(0.075,0.24,0.10),Vector3(0,0.09,-0.35),"armor")
	_part(turret,"RearServicePanel","box",Vector3(0.34,0.20,0.025),Vector3(0,0.12,0.372),"metal")
	for j: int in range(4): _part(turret,"RearLouvre%d" % j,"box",Vector3(0.27,0.018,0.025),Vector3(0,0.06+j*0.035,0.395),"dark")
	for side: int in [-1,1]: _part(turret,"RearCatch%d" % side,"box",Vector3(0.045,0.08,0.035),Vector3(side*0.23,0.18,0.37),"armor")
	for side: int in [-1,1]:
		_part(turret,"RoofSeam%d" % side,"box",Vector3(0.016,0.016,0.46),Vector3(side*0.16,0.357,0.035),"dark")
		for j: int in range(3): _part(turret,"RearVent%d_%d" % [side,j],"box",Vector3(0.09,0.015,0.025),Vector3(side*0.22,0.346,0.17+j*0.045),"metal")
	_part(turret,"OpticHousing","box",Vector3(0.17,0.14,0.18),Vector3(0.08,0.43,-0.04),"dark")
	_tube(turret,"OpticBezel",0.056,0.041,0.04,Vector3(0.08,0.43,-0.145),"metal")
	_part(turret,"OpticLens","sphere",Vector3(0.077,0.077,0.024),Vector3(0.08,0.43,-0.171),"green")
	if id != "scatter":
		_part(turret,"AntennaBoot","cylinder",Vector3(0.035,0.065,0),Vector3(-0.16,0.40,0.23),"rubber")
		_part(turret,"Antenna","cylinder",Vector3(0.007,0.28,0),Vector3(-0.16,0.565,0.23),"metal")
		_part(turret,"AntennaTip","sphere",Vector3.ONE*0.016,Vector3(-0.16,0.708,0.23),"dark")
	var barrels: Array[float] = [0.0]
	if id != "cannon": barrels.assign([-0.17,0.17])
	for i: int in range(barrels.size()): _build_barrel(turret,i,barrels[i],id)
	if rapid: _ammo(turret)
	_save(turret,"Muzzle",Vector3(0,0.02,-1.05))

func _build_barrel(turret: Node3D, i: int, x: float, id: String) -> void:
	var rapid: bool = id == "autocannon"
	var radius: float = 0.17 if id == "cannon" else (0.14 if id == "scatter" else 0.055)
	var center := Vector3(x,0.02,-0.68)
	_tube(turret,"Barrel%d" % i,radius,radius*0.72,0.64,center,"metal" if rapid else "dark")
	_tube(turret,"MuzzleCuff%d" % i,radius*1.15,radius*0.73,0.13,Vector3(x,0.02,-0.985),"gold")
	_tube(turret,"BoreLiner%d" % i,radius*0.73,radius*0.67,0.28,Vector3(x,0.02,-0.88),"rubber")
	_part(turret,"BoreDepth%d" % i,"cylinder",Vector3(radius*0.68,0.015,0),Vector3(x,0.02,-0.735),"rubber",Vector3(PI/2,0,0))
	_tube(turret,"RootCollar%d" % i,radius*1.19,radius*0.99,0.07,Vector3(x,0.02,-0.39),"gold" if rapid else "metal")
	if not rapid:
		_tube(turret,"Sleeve%d" % i,radius*1.10,radius*0.98,0.18,Vector3(x,0.02,-0.52),"dark")
		_tube(turret,"SleeveSeam%d" % i,radius*1.115,radius*1.07,0.015,Vector3(x,0.02,-0.61),"metal")
	for angle: float in [0.0,PI/2,PI,PI*1.5]:
		var p := Vector3(x+cos(angle)*radius*0.94,0.02+sin(angle)*radius*0.94,-1.053)
		if not rapid: _bolt(turret,"MuzzleBolt%d_%s" % [i,angle],p,Vector3(PI/2,0,0))

func _ammo(turret: Node3D) -> void:
	for side: int in [-1,1]:
		_part(turret,"AmmoBox%d" % side,"box",Vector3(0.15,0.39,0.36),Vector3(side*0.47,0.12,0.0),"dark")
		_part(turret,"AmmoCover%d" % side,"box",Vector3(0.045,0.30,0.29),Vector3(side*0.555,0.12,0.03),"armor")
		for i: int in range(6):
			_part(turret,"Ammo%d_%d" % [side,i],"cylinder",Vector3(0.025,0.12,0),Vector3(side*0.47,-0.025+i*0.057,-0.22),"gold",Vector3(PI/2,0,0))
			_part(turret,"AmmoTip%d_%d" % [side,i],"sphere",Vector3(0.047,0.047,0.065),Vector3(side*0.47,-0.025+i*0.057,-0.288),"gold")

func _build_chassis(id: String) -> void:
	var body := Node3D.new()
	body.name = id
	var heavy: bool = id == "heavy_tracks"
	var wheels: bool = id == "scout_wheels"
	var side_x: float = 0.60 if heavy else 0.51
	_part(body,"LowerHull","box",Vector3(0.82,0.24,1.53),Vector3(0,0.33,0),"dark")
	_part(body,"Deck","box",Vector3(1.08 if heavy else 0.88,0.16,1.42),Vector3(0,0.59,0.05))
	_part(body,"NoseSlope","box",Vector3(0.78 if heavy else 0.63,0.12,0.60),Vector3(0,0.50,-0.66),"armor",Vector3(0.45,0,0))
	_part(body,"NoseInlay","box",Vector3(0.34,0.018,0.30),Vector3(0,0.58,-0.64),"edge",Vector3(0.45,0,0))
	_part(body,"NoseInnerPlate","box",Vector3(0.30,0.018,0.26),Vector3(0,0.594,-0.64),"armor",Vector3(0.45,0,0))
	_part(body,"FrontGrille","box",Vector3(0.27,0.19,0.04),Vector3(0,0.38,-0.93),"rubber")
	for i: int in range(5): _part(body,"FrontSlat%d" % i,"box",Vector3(0.23,0.014,0.018),Vector3(0,0.31+i*0.033,-0.958),"metal")
	_part(body,"RingSeat","cylinder",Vector3(0.35,0.055,0),Vector3(0,0.695,0),"dark")
	_part(body,"MountLip","ring",Vector3(0.30,0.35,0),Vector3(0,0.723,0),"gold")
	for side: int in [-1,1]:
		_deck_details(body,side,side_x,heavy)
		if wheels: _scout_wheels(body,side,side_x)
		else: _tracks(body,side,side_x,heavy)
	_part(body,"RearBumper","box",Vector3(0.64,0.08,0.08),Vector3(0,0.32,0.85),"metal")
	for j: int in range(7): _part(body,"EngineVent%d" % j,"box",Vector3(0.37,0.022,0.026),Vector3(0,0.68,0.39+j*0.044),"dark")
	for side: int in [-1,1]:
		_tube(body,"Exhaust%d" % side,0.047,0.033,0.16,Vector3(side*0.31,0.43,0.80),"metal")
	_save(body,"TurretSocket",Vector3(0,0.76,0))

func _deck_details(body: Node3D, side: int, side_x: float, heavy: bool) -> void:
	for i: int in range(4):
		var z: float = -0.57+i*0.38
		_part(body,"FenderUnder%d_%d" % [side,i],"box",Vector3(0.36 if heavy else 0.29,0.06,0.35),Vector3(side*side_x,0.535,z),"dark")
		_part(body,"Fender%d_%d" % [side,i],"box",Vector3(0.35 if heavy else 0.28,0.11,0.34),Vector3(side*side_x,0.605,z),"armor",Vector3(0,0,-side*0.21))
		_part(body,"DeckInset%d_%d" % [side,i],"box",Vector3(0.105,0.014,0.22),Vector3(side*0.31,0.681,z),"dark")
		_bolt(body,"DeckBolt%d_%d" % [side,i],Vector3(side*0.42,0.675,z+0.10))
		if heavy:
			var skirt: Array[Vector2] = [Vector2(z-0.15,0.58),Vector2(z+0.15,0.58),Vector2(z+0.12,0.39),Vector2(z-0.12,0.39)]
			_panel(body,"SkirtPanel%d_%d" % [side,i],skirt,minf(side*0.74,side*0.81),maxf(side*0.74,side*0.81),"armor")
			_bolt(body,"SkirtBolt%d_%d" % [side,i],Vector3(side*0.817,0.50,z),Vector3(0,0,PI/2))
	_part(body,"LampHousing%d" % side,"box",Vector3(0.16,0.085,0.045),Vector3(side*0.27,0.43,-0.90),"dark")
	_part(body,"LampRim%d" % side,"box",Vector3(0.125,0.052,0.018),Vector3(side*0.27,0.43,-0.928),"metal")
	_part(body,"Lamp%d" % side,"box",Vector3(0.10,0.032,0.016),Vector3(side*0.27,0.43,-0.941),"green")
	_part(body,"TowEye%d" % side,"ring",Vector3(0.018,0.033,0),Vector3(side*0.26,0.27,-0.94),"gold",Vector3(PI/2,0,0))

func _tracks(body: Node3D, side: int, x: float, heavy: bool) -> void:
	var width: float = 0.38 if heavy else 0.30
	var radius: float = 0.245
	var straight: float = 1.26
	var length: float = 2*straight+TAU*radius
	for j: int in range(44):
		var distance: float = j*length/44.0
		var y: float
		var z: float
		var angle: float
		if distance < straight:
			y=radius; z=-straight/2+distance; angle=0
		elif distance < straight+PI*radius:
			angle=(distance-straight)/radius; y=radius*cos(angle); z=straight/2+radius*sin(angle)
		elif distance < 2*straight+PI*radius:
			angle=PI; y=-radius; z=straight/2-(distance-straight-PI*radius)
		else:
			angle=PI+(distance-2*straight-PI*radius)/radius; y=radius*cos(angle); z=-straight/2+radius*sin(angle)
		var position := Vector3(side*x,0.285+y,z)
		_part(body,"Tread%d_%d" % [side,j],"box",Vector3(width,0.065,0.080),position,"rubber",Vector3(angle,0,0))
		_part(body,"TreadRib%d_%d" % [side,j],"box",Vector3(width*0.85,0.018,0.024),position+Vector3(0,cos(angle)*0.037,sin(angle)*0.037),"metal",Vector3(angle,0,0))
	for j: int in range(6):
		var end: bool = j == 0 or j == 5
		var z: float = [-0.64,-0.38,-0.126,0.126,0.38,0.64][j]
		var r: float = 0.176 if end else 0.116
		var y: float = 0.285 if end else 0.198
		_wheel(body,"Road%d_%d" % [side,j],Vector3(side*x,y,z),r,width,side,6)
	for j: int in range(3):
		_part(body,"ReturnRoller%d_%d" % [side,j],"cylinder",Vector3(0.046,width*0.70,0),Vector3(side*x,0.46,-0.27+j*0.27),"dark",Vector3(0,0,PI/2))

func _wheel(body: Node3D, prefix: String, position: Vector3, radius: float, width: float, side: int, spokes: int) -> void:
	_part(body,prefix+"Tyre","cylinder",Vector3(radius,width*0.79,0),position,"rubber",Vector3(0,0,PI/2))
	var face: Vector3 = position + Vector3(side*width*0.43,0,0)
	_part(body,prefix+"Inset","cylinder",Vector3(radius*0.77,0.018,0),face,"dark",Vector3(0,0,PI/2))
	_part(body,prefix+"Lip","ring",Vector3(radius*0.72,radius*0.86,0),face,"gold",Vector3(0,0,PI/2))
	for j: int in range(spokes):
		var angle: float = TAU*j/spokes
		_part(body,prefix+"Spoke%d" % j,"box",Vector3(0.018,radius*0.50,0.018),face+Vector3(side*0.012,cos(angle)*radius*0.42,sin(angle)*radius*0.42),"gold",Vector3(angle,0,0))
	_part(body,prefix+"Hub","cylinder",Vector3(radius*0.26,0.035,0),face+Vector3(side*0.018,0,0),"metal",Vector3(0,0,PI/2))
	_bolt(body,prefix+"CenterBolt",face+Vector3(side*0.04,0,0),Vector3(0,0,PI/2))

func _scout_wheels(body: Node3D, side: int, x: float) -> void:
	for end: int in [-1,1]:
		var z: float = end*0.58
		_part(body,"Axle%d_%d" % [side,end],"cylinder",Vector3(0.045,0.29,0),Vector3(side*x,0.30,z),"metal",Vector3(0,0,PI/2))
		_part(body,"SuspensionRod%d_%d" % [side,end],"cylinder",Vector3(0.026,0.32,0),Vector3(side*x,0.40,z),"metal",Vector3(0,0,side*0.30))
		for j: int in range(5): _part(body,"Spring%d_%d_%d" % [side,end,j],"ring",Vector3(0.028,0.046,0),Vector3(side*x,0.32+j*0.032,z),"gold")
		_wheel(body,"Scout%d_%d" % [side,end],Vector3(side*(x+0.12),0.30,z),0.29,0.27,side,8)
		for j: int in range(20):
			var angle: float = TAU*j/20.0
			for strip: int in [-1,1]:
				_part(body,"Grip%d_%d_%d_%d" % [side,end,j,strip],"box",Vector3(0.13,0.027,0.075),Vector3(side*(x+0.12)+strip*0.065,0.30+cos(angle)*0.29,z+sin(angle)*0.29),"rubber",Vector3(angle,0,strip*0.20))
