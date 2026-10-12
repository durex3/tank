extends "res://tools/build_detailed_parts.gd"
## Card-matched second version: revolved armor, true hollow nozzle and continuous tubing.

var turret := Node3D.new()

func _initialize() -> void:
	var palette: Dictionary = {"armor":Color("e8dfcc"),"edge":Color("aba28f"),"dark":Color("252c31"),"rubber":Color("11171b"),"metal":Color("66737a"),"gold":Color("ba9248"),"green":Color("49d58c")}
	for key: String in palette:
		var material := StandardMaterial3D.new()
		material.albedo_color = palette[key]
		material.roughness = 0.43 if key == "armor" else 0.35
		material.metallic = 0.65 if key in ["metal","gold"] else 0.12
		materials[key] = material
	turret.name = "bubble_cannon"
	_part(turret,"Turntable","cylinder",Vector3(0.51,0.12,0),Vector3(0,-0.055,0),"dark")
	_tube(turret,"BaseBrassSeam",0.515,0.49,0.018,Vector3(0,-0.11,0),"gold",Vector3.ZERO)
	_part(turret,"LowerCradle","box",Vector3(0.66,0.15,0.72),Vector3(0,-0.025,0.03),"dark")
	# The broad round front is the identity of the existing bubble card.
	_lathe("ArmorGasket",[Vector2(0.23,-0.49),Vector2(0.34,-0.49),Vector2(0.425,-0.34),Vector2(0.425,-0.04),Vector2(0.40,0.12),Vector2(0.23,0.12)],"dark",24)
	_lathe("IvoryCircularArmor",[Vector2(0.25,-0.51),Vector2(0.355,-0.51),Vector2(0.435,-0.40),Vector2(0.445,-0.18),Vector2(0.41,-0.01),Vector2(0.30,0.075),Vector2(0.25,0.075)],"armor",16)
	_tube(turret,"NozzleRootGasket",0.245,0.182,0.12,Vector3(0,0.02,-0.51),"rubber")
	_tube(turret,"IvorySprayerSleeve",0.225,0.175,0.29,Vector3(0,0.02,-0.69),"armor")
	_tube(turret,"DarkTipCollar",0.215,0.171,0.15,Vector3(0,0.02,-0.905),"dark")
	_tube(turret,"HollowBrassMuzzle",0.225,0.17,0.08,Vector3(0,0.02,-1.01),"gold")
	_tube(turret,"InnerBore",0.173,0.15,0.43,Vector3(0,0.02,-0.80),"rubber")
	for side: int in [-1,1]:
		for z: float in [-0.34,-0.04]:
			_part(turret,"ArmorFastener%d_%s" % [side,z],"cylinder",Vector3(0.024,0.018,0),Vector3(side*0.435,0.12,z),"metal",Vector3(0,0,PI/2))
		_part(turret,"SideSeam%d" % side,"box",Vector3(0.012,0.13,0.035),Vector3(side*0.445,0.08,-0.19),"dark")
	_reservoir()
	_optic(Vector3(0,0.48,-0.25),"Front")
	_optic(Vector3(0,0.91,0.37),"Rear")
	for side: int in [-1,1]:
		_hose(side)
		_part(turret,"HoseCoupling%d" % side,"cylinder",Vector3(0.075,0.12,0),Vector3(side*0.31,0.10,0.46),"gold",Vector3(0,0,PI/2))
	_merge_opaque()
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0,0.02,-1.05)
	turret.add_child(muzzle)
	muzzle.owner = turret
	DirAccess.make_dir_recursive_absolute("res://presentation/parts/bubble_refined")
	var packed := PackedScene.new()
	assert(packed.pack(turret) == OK)
	assert(ResourceSaver.save(packed,"res://presentation/parts/bubble_refined/bubble_cannon.tscn") == OK)
	turret.free()
	print("BUBBLE REFINED MODEL: PASS")
	quit()

func _lathe(label: String, profile: Array[Vector2], mat: String, segments: int) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(segments):
		var a: float = TAU*i/segments
		var b: float = TAU*(i+1)/segments
		if mat == "armor" and i%4 == 3: b -= 0.025
		for j: int in range(profile.size()):
			var p: Vector2 = profile[j]
			var q: Vector2 = profile[(j+1)%profile.size()]
			var n := Vector2(q.y-p.y,p.x-q.x).normalized()
			var na := Vector3(cos(a)*n.x,sin(a)*n.x,n.y)
			var nb := Vector3(cos(b)*n.x,sin(b)*n.x,n.y)
			_quad(surface,_lathe_point(p,a),_lathe_point(p,b),_lathe_point(q,b),_lathe_point(q,a),na,nb,nb,na)
	surface.index()
	var mesh: ArrayMesh = surface.commit()
	mesh.surface_set_material(0,materials[mat])
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	turret.add_child(node)
	node.owner = turret

func _lathe_point(p: Vector2, angle: float) -> Vector3:
	return Vector3(cos(angle)*p.x,maxf(-0.09,sin(angle)*p.x*0.92+0.09),p.y)

func _reservoir() -> void:
	var center := Vector3(0,0.43,0.37)
	var glass := ShaderMaterial.new()
	glass.shader = load("res://presentation/shaders/reservoir_glass.gdshader")
	var shell := _sphere_node("ClearReservoir",0.405,center,glass)
	shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var fluid := ShaderMaterial.new()
	fluid.shader = load("res://presentation/shaders/reservoir_liquid.gdshader")
	_sphere_node("HalfFilledLiquid",0.385,center,fluid)
	var surface := CylinderMesh.new()
	surface.top_radius = 0.379
	surface.bottom_radius = 0.379
	surface.height = 0.006
	surface.radial_segments = 48
	var water := StandardMaterial3D.new()
	water.albedo_color = Color("237c8b")
	water.roughness = 0.15
	water.metallic = 0.25
	_mesh_node("LiquidSurface",surface,center+Vector3.UP*0.065,water)
	var reflection := StandardMaterial3D.new()
	reflection.albedo_color = Color(0.88,0.98,1,0.72)
	reflection.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	reflection.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_sphere_node("GlassReflection",0.10,center+Vector3(-0.19,0.17,-0.29),reflection).scale = Vector3(0.34,1.1,0.12)
	_sphere_node("GlassReflectionSmall",0.035,center+Vector3(-0.23,0.02,-0.32),reflection).scale = Vector3(0.5,1,0.15)
	_part(turret,"TankFoot","cylinder",Vector3(0.27,0.09,0),Vector3(0,0.055,0.37),"dark")
	_tube(turret,"TankEquatorTrim",0.408,0.395,0.022,center,"metal",Vector3(PI/2,0,0))
	_part(turret,"CapGasket","cylinder",Vector3(0.19,0.035,0),Vector3(0,0.818,0.37),"dark")
	_part(turret,"IvoryTankCap","box",Vector3(0.39,0.065,0.30),Vector3(0,0.85,0.37),"armor")
	for side: int in [-1,1]:
		for z: float in [0.27,0.46]:
			_part(turret,"CapBolt%d_%s" % [side,z],"cylinder",Vector3(0.015,0.012,0),Vector3(side*0.145,0.89,z),"metal")
	for i: int in range(7):
		var position_value := center+Vector3(sin(i*2.4)*0.18,-0.25+i*0.038,cos(i*1.6)*0.13)
		_sphere_node("LiquidBubble%d" % i,0.018+0.005*(i%3),position_value,glass)

func _optic(p: Vector3, label: String) -> void:
	_part(turret,label+"OpticFoot","box",Vector3(0.24,0.08,0.20),p-Vector3.UP*0.055,"armor")
	_part(turret,label+"OpticHousing","box",Vector3(0.18,0.14,0.18),p,"dark")
	_part(turret,label+"OpticRim","cylinder",Vector3(0.062,0.025,0),p+Vector3.FORWARD*0.10,"metal",Vector3(PI/2,0,0))
	var lens := materials["green"] as StandardMaterial3D
	lens.emission_enabled = true
	lens.emission = Color("28a867")
	lens.emission_energy_multiplier = 0.45
	_sphere_node(label+"Lens",0.046,p+Vector3.FORWARD*0.12,lens).scale.z = 0.36

func _hose(side: int) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count: int = 48
	for i: int in range(count):
		var t0: float = PI*i/count
		var t1: float = PI*(i+1)/count
		for j: int in range(10):
			var a: float = TAU*j/10
			var b: float = TAU*(j+1)/10
			var c0 := Vector3(side*(0.30+sin(t0)*0.32),0.05,0.18+cos(t0)*0.30)
			var c1 := Vector3(side*(0.30+sin(t1)*0.32),0.05,0.18+cos(t1)*0.30)
			var tangent: Vector3 = (c1-c0).normalized()
			var right: Vector3 = tangent.cross(Vector3.UP).normalized()
			var na: Vector3 = right*cos(a)+Vector3.UP*sin(a)
			var nb: Vector3 = right*cos(b)+Vector3.UP*sin(b)
			var r0: float = 0.043+0.006*cos(t0*48)
			var r1: float = 0.043+0.006*cos(t1*48)
			_quad(surface,c0+na*r0,c0+nb*r0,c1+nb*r1,c1+na*r1,na,nb,nb,na)
	surface.index()
	_mesh_node("RibbedHose%d" % side,surface.commit(),Vector3.ZERO,materials["rubber"])

func _sphere_node(label: String, radius: float, p: Vector3, material: Material) -> MeshInstance3D:
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius*2
	sphere.radial_segments = 48
	sphere.rings = 24
	return _mesh_node(label,sphere,p,material)

func _mesh_node(label: String, mesh: Mesh, p: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = label
	node.mesh = mesh
	node.position = p
	node.material_override = material
	turret.add_child(node)
	node.owner = turret
	return node

func _merge_opaque() -> void:
	var groups: Dictionary = {}
	for child: Node in turret.get_children():
		if not child is MeshInstance3D: continue
		var node := child as MeshInstance3D
		var material: Material = node.material_override if node.material_override != null else node.mesh.surface_get_material(0)
		if not material is StandardMaterial3D or (material as StandardMaterial3D).transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
		if not groups.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[material] = surface
		(groups[material] as SurfaceTool).append_from(node.mesh,0,node.transform)
		turret.remove_child(node)
		node.free()
	for material: Material in groups:
		_mesh_node("OpaqueSurface%d" % turret.get_child_count(),(groups[material] as SurfaceTool).commit(),Vector3.ZERO,material)
