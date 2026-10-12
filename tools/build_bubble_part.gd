extends SceneTree
## Original true 3D turret, matched to the existing bubble card silhouette.

var part := Node3D.new()
var ivory := StandardMaterial3D.new()
var dark := StandardMaterial3D.new()
var gold := StandardMaterial3D.new()
var glass := StandardMaterial3D.new()
var liquid := StandardMaterial3D.new()

func _initialize() -> void:
	ivory.albedo_color = Color("ede8d8")
	ivory.roughness = 0.42
	dark.albedo_color = Color("202a31")
	dark.metallic = 0.65
	gold.albedo_color = Color("c49b45")
	gold.metallic = 0.7
	glass.albedo_color = Color(0.52,0.9,0.95,0.28)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.1
	liquid.albedo_color = Color("1aafbd")
	liquid.metallic = 0.25
	part.name = "bubble_cannon"
	_cylinder("Turntable",Vector3(0,-0.04,0),0.57,0.16,dark)
	_cylinder("GoldBase",Vector3(0,-0.12,0),0.55,0.035,gold)
	_box("Armor",Vector3(0,0.14,-0.12),Vector3(0.9,0.48,0.8),ivory)
	_box("TopArmor",Vector3(0,0.42,-0.15),Vector3(0.67,0.10,0.55),ivory)
	var gun := _cylinder("ShortSprayer",Vector3(0,0.02,-0.70),0.235,0.70,dark)
	gun.rotation.x = PI/2
	var rim := _cylinder("GoldRim",Vector3(0,0.02,-1.025),0.255,0.05,gold)
	rim.rotation.x = PI/2
	var bore := _cylinder("Bore",Vector3(0,0.02,-1.054),0.195,0.008,dark)
	bore.rotation.x = PI/2
	_sphere("ReservoirLiquid",Vector3(0,0.23,0.40),0.35,liquid).scale.y = 0.72
	_sphere("ReservoirGlass",Vector3(0,0.34,0.40),0.43,glass)
	_cylinder("ReservoirFoot",Vector3(0,0.015,0.40),0.31,0.10,dark)
	_cylinder("ReservoirCap",Vector3(0,0.73,0.40),0.18,0.08,ivory)
	for side: int in [-1,1]:
		_box("SidePlate",Vector3(side*0.47,0.16,-0.13),Vector3(0.10,0.35,0.52),ivory)
		for i: int in range(3):
			_box("Vent",Vector3(side*0.53,0.18,-0.30+i*0.15),Vector3(0.03,0.14,0.055),dark)
		for i: int in range(8):
			var angle: float = PI*i/7
			_sphere("Hose",Vector3(side*(0.38+sin(angle)*0.19),-0.01,0.04+cos(angle)*0.40),0.065,dark)
	_box("Sensor",Vector3(0,0.51,-0.28),Vector3(0.22,0.16,0.19),dark)
	_sphere("SensorLens",Vector3(0,0.51,-0.38),0.055,liquid)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0,0.02,-1.05)
	part.add_child(muzzle)
	muzzle.owner = part
	var packed := PackedScene.new()
	assert(packed.pack(part) == OK)
	assert(ResourceSaver.save(packed,"res://presentation/parts/bubble_cannon.tscn") == OK)
	part.free()
	print("BUBBLE MODEL: PASS")
	quit()

func _node(name_value: String, mesh: Mesh, position_value: Vector3, material: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_value+str(part.get_child_count())
	node.position = position_value
	node.mesh = mesh
	node.material_override = material
	part.add_child(node)
	node.owner = part
	return node

func _box(name_value: String, p: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _node(name_value,mesh,p,material)

func _cylinder(name_value: String, p: Vector3, radius: float, height: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	return _node(name_value,mesh,p,material)

func _sphere(name_value: String, p: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius*2
	mesh.radial_segments = 24
	mesh.rings = 12
	return _node(name_value,mesh,p,material)
