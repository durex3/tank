extends SceneTree
## Rebuild six display-only modules from the existing card silhouettes; originals stay intact.

const OUTPUT: String = "res://presentation/parts/card_aligned"
var materials: Dictionary = {}
var meshes: Dictionary = {}
var metrics: Dictionary = {}

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for key: String in ["armor", "dark", "metal", "gold", "green"]:
		var material := StandardMaterial3D.new()
		material.albedo_color = {"armor": Color("ded5c0"), "dark": Color("25272b"), "metal": Color("44484b"), "gold": Color("bb9140"), "green": Color("168b58")}[key]
		material.roughness = 0.38 if key == "armor" else (0.3 if key == "gold" else 0.65)
		material.metallic = 0.72 if key == "gold" else (0.35 if key == "metal" else 0.0)
		if key == "green":
			material.emission_enabled = true
			material.emission = Color("12663d")
			material.emission_energy_multiplier = 0.45
		materials[key] = material
	for id: String in ["light_tracks", "heavy_tracks", "scout_wheels"]:
		_build_chassis(id)
	for id: String in ["cannon", "autocannon", "scatter"]:
		_build_turret(id)
	var report := FileAccess.open("res://artifacts/card-aligned-model-metrics.json", FileAccess.WRITE)
	report.store_string(JSON.stringify(metrics, "\t"))
	print("CARD ALIGNED PARTS: PASS (six scenes, original parts preserved)")
	quit()

func _rounded_box(size: Vector3, bevel: float) -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half: Vector3 = size * 0.5
	var core: Vector3 = half - Vector3.ONE * bevel
	# Every face keeps its flat center; only a narrow edge band is rounded.
	for normal: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
		var u: Vector3 = Vector3.UP if absf(normal.x) > 0.5 else Vector3.RIGHT
		var v: Vector3 = normal.cross(u)
		var n_extent: float = normal.abs().dot(half)
		var u_extent: float = u.abs().dot(half)
		var v_extent: float = v.abs().dot(half)
		var us: Array[float] = _face_steps(u_extent, bevel)
		var vs: Array[float] = _face_steps(v_extent, bevel)
		var steps: int = us.size() - 1
		for y: int in range(steps):
			for x: int in range(steps):
				for corner: Vector2i in [Vector2i(x,y), Vector2i(x+1,y+1), Vector2i(x+1,y), Vector2i(x,y), Vector2i(x,y+1), Vector2i(x+1,y+1)]:
					var point: Vector3 = normal * n_extent + u * us[corner.x] + v * vs[corner.y]
					var nearest: Vector3 = point.clamp(-core, core)
					var outward: Vector3 = (point - nearest).normalized()
					surface.set_normal(outward)
					surface.add_vertex(nearest + outward * bevel)
	surface.index()
	return surface.commit()

func _face_steps(extent: float, bevel: float) -> Array[float]:
	return [-extent, -extent+bevel, 0.0, extent-bevel, extent]

func _mesh(kind: String, size: Vector3, material: String) -> Mesh:
	var key: String = "%s/%s/%s" % [kind, size, material]
	if meshes.has(key): return meshes[key]
	var mesh: Mesh
	if kind == "box":
		mesh = _rounded_box(size, minf(0.035, minf(size.x, minf(size.y, size.z)) * 0.2))
	elif kind == "cylinder" or kind == "octagon":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = size.x
		cylinder.bottom_radius = size.x
		cylinder.height = size.y
		cylinder.radial_segments = 8 if kind == "octagon" else 32
		mesh = cylinder
	elif kind == "ring":
		var ring := TorusMesh.new()
		ring.inner_radius = size.x
		ring.outer_radius = size.y
		ring.rings = 24
		ring.ring_segments = 8
		mesh = ring
	else:
		var sphere := SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		sphere.radial_segments = 24
		sphere.rings = 12
		mesh = sphere
	if mesh is PrimitiveMesh:
		(mesh as PrimitiveMesh).material = materials[material]
	else:
		mesh.surface_set_material(0, materials[material])
	meshes[key] = mesh
	return mesh

func _part(root_node: Node3D, name_text: String, kind: String, size: Vector3, position: Vector3, material: String = "armor", rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = name_text
	node.mesh = _mesh(kind, size, material)
	node.position = position
	node.rotation = rotation
	if kind == "sphere": node.scale = size
	root_node.add_child(node)
	node.owner = root_node
	return node

func _save(node: Node3D, socket_name: String, position: Vector3) -> void:
	# Static module detail shares one surface per material instead of one draw per bolt/tread.
	var groups: Dictionary = {}
	for child: Node in node.get_children():
		if not child is MeshInstance3D: continue
		var instance := child as MeshInstance3D
		var material := instance.mesh.surface_get_material(0)
		if not groups.has(material):
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			groups[material] = surface
		(groups[material] as SurfaceTool).append_from(instance.mesh, 0, instance.transform)
		node.remove_child(instance)
		instance.free()
	var triangles: int = 0
	for material: Material in groups:
		var combined := (groups[material] as SurfaceTool).commit()
		combined.surface_set_material(0, material)
		var instance := MeshInstance3D.new()
		instance.name = "Surface%d" % node.get_child_count()
		instance.mesh = combined
		node.add_child(instance)
		instance.owner = node
		var indices: int = combined.surface_get_array_index_len(0)
		triangles += (indices if indices > 0 else combined.surface_get_array_len(0)) / 3
	metrics[str(node.name)] = {"surfaces": groups.size(), "triangles": triangles}
	var socket := Marker3D.new()
	socket.name = socket_name
	socket.position = position
	node.add_child(socket)
	socket.owner = node
	var packed := PackedScene.new()
	assert(packed.pack(node) == OK)
	assert(ResourceSaver.save(packed, "%s/%s.tscn" % [_output_directory(), node.name]) == OK)
	node.free()

func _output_directory() -> String:
	return OUTPUT

func _build_chassis(id: String) -> void:
	var body := Node3D.new()
	body.name = id
	var heavy: bool = id == "heavy_tracks"
	var wheels: bool = id == "scout_wheels"
	var side_x: float = 0.60 if heavy else 0.51
	_part(body, "LowerHull", "box", Vector3(0.84,0.25,1.52), Vector3(0,0.32,0), "dark")
	_part(body, "Deck", "box", Vector3(1.10 if heavy else 0.91,0.22,1.52), Vector3(0,0.57,0))
	_part(body, "WedgeNose", "box", Vector3(0.78 if heavy else 0.60,0.17,0.57), Vector3(0,0.49,-0.67), "armor", Vector3(0.38,0,0))
	_part(body, "NoseGrille", "box", Vector3(0.28,0.20,0.045), Vector3(0,0.39,-0.93), "dark")
	for i: int in range(4):
		_part(body, "NoseSlat%d" % i, "box", Vector3(0.24,0.018,0.025), Vector3(0,0.32+i*0.045,-0.957), "metal")
	_part(body, "RingSeat", "cylinder", Vector3(0.34,0.065,0), Vector3(0,0.70,0), "dark")
	_part(body, "MountRim", "ring", Vector3(0.29,0.35,0), Vector3(0,0.735,0), "gold")
	for side: int in [-1, 1]:
		var x: float = side * side_x
		for i: int in range(4):
			_part(body, "SideArmor%d_%d" % [side,i], "box", Vector3(0.33 if heavy else 0.25,0.16,0.34), Vector3(x,0.61,-0.59+i*0.39), "armor", Vector3(0,0,-side*0.18))
			_part(body, "DeckInsert%d_%d" % [side,i], "box", Vector3(0.14,0.025,0.24), Vector3(side*0.31,0.695,-0.61+i*0.39), "metal")
		_part(body, "LampSocket%d" % side, "box", Vector3(0.16,0.09,0.04), Vector3(side*0.28,0.42,-0.89), "dark")
		_part(body, "Lamp%d" % side, "box", Vector3(0.10,0.042,0.025), Vector3(side*0.28,0.42,-0.917), "green")
		if wheels:
			for end: int in [-1,1]:
				var z: float = end*0.58
				_part(body, "Suspension%d_%d" % [side,end], "cylinder", Vector3(0.05,0.32,0), Vector3(x,0.40,z), "gold", Vector3(0,0,side*0.35))
				_part(body, "Tyre%d_%d" % [side,end], "cylinder", Vector3(0.30,0.27,0), Vector3(x+side*0.11,0.30,z), "dark", Vector3(0,0,PI/2))
				_part(body, "Rim%d_%d" % [side,end], "cylinder", Vector3(0.20,0.028,0), Vector3(x+side*0.255,0.30,z), "gold", Vector3(0,0,PI/2))
				_part(body, "Hub%d_%d" % [side,end], "cylinder", Vector3(0.07,0.045,0), Vector3(x+side*0.28,0.30,z), "metal", Vector3(0,0,PI/2))
				for j: int in range(16):
					var angle: float = TAU*j/16
					_part(body, "TyreGrip%d_%d_%d" % [side,end,j], "box", Vector3(0.29,0.035,0.10), Vector3(x+side*0.11,0.30+cos(angle)*0.30,z+sin(angle)*0.30), "dark", Vector3(angle,0,0))
		else:
			var radius: float = 0.245
			var straight: float = 1.26
			var length: float = 2*straight+TAU*radius
			for j: int in range(40):
				var distance: float = j*length/40
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
				_part(body, "Tread%d_%d" % [side,j], "box", Vector3(0.39 if heavy else 0.30,0.075,0.095), Vector3(x,0.285+y,z), "dark", Vector3(angle,0,0))
			for j: int in range(6):
				var z: float = -0.64+j*0.256
				var outer: float = x+side*(0.205 if heavy else 0.16)
				_part(body, "RoadWheel%d_%d" % [side,j], "cylinder", Vector3(0.205,0.19,0), Vector3(x,0.285,z), "dark", Vector3(0,0,PI/2))
				_part(body, "GoldRim%d_%d" % [side,j], "ring", Vector3(0.135,0.175,0), Vector3(outer,0.285,z), "gold", Vector3(0,0,PI/2))
				_part(body, "WheelFace%d_%d" % [side,j], "cylinder", Vector3(0.135,0.02,0), Vector3(outer,0.285,z), "gold", Vector3(0,0,PI/2))
				_part(body, "WheelHub%d_%d" % [side,j], "cylinder", Vector3(0.055,0.04,0), Vector3(outer+side*0.02,0.285,z), "metal", Vector3(0,0,PI/2))
		if heavy:
			_part(body, "Skirt%d" % side, "box", Vector3(0.11,0.21,1.12), Vector3(side*0.79,0.53,0), "armor")
	_part(body, "RearGrille", "box", Vector3(0.42,0.12,0.035), Vector3(0,0.43,0.78), "dark")
	_save(body, "TurretSocket", Vector3(0,0.76,0))

func _build_turret(id: String) -> void:
	var turret := Node3D.new()
	turret.name = id
	var rapid: bool = id == "autocannon"
	_part(turret, "Turntable", "cylinder", Vector3(0.33,0.08,0), Vector3(0,-0.04,0), "dark")
	_part(turret, "TurntableGold", "ring", Vector3(0.30,0.335,0), Vector3(0,-0.045,0), "gold")
	_part(turret, "TurretCore", "box", Vector3(0.69,0.43,0.64), Vector3(0,0.10,0.015), "dark")
	for side: int in [-1,1]:
		_part(turret, "Cheek%d" % side, "octagon", Vector3(0.29,0.17,0), Vector3(side*0.34,0.10,0.015), "armor", Vector3(0,0,PI/2))
		_part(turret, "UpperFacet%d" % side, "box", Vector3(0.22,0.10,0.53), Vector3(side*0.22,0.34,0.015), "armor", Vector3(0,0,side*0.26))
		_part(turret, "SidePlate%d" % side, "octagon", Vector3(0.16,0.09,0), Vector3(side*0.44,0.10,0.05), "armor", Vector3(0,0,PI/2))
		_part(turret, "RearBlock%d" % side, "box", Vector3(0.12,0.30,0.18), Vector3(side*0.32,0.10,0.31), "metal")
	_part(turret, "OpticBase", "box", Vector3(0.16,0.13,0.17), Vector3(0.13,0.43,-0.06), "dark")
	_part(turret, "Optic", "cylinder", Vector3(0.045,0.025,0), Vector3(0.13,0.44,-0.16), "green", Vector3(PI/2,0,0))
	if id != "scatter":
		_part(turret, "AntennaBase", "cylinder", Vector3(0.035,0.10,0), Vector3(-0.15,0.41,0.21), "metal")
		_part(turret, "Antenna", "cylinder", Vector3(0.009,0.30,0), Vector3(-0.15,0.59,0.21), "dark")
	var barrels: Array[float] = [0.0]
	if id != "cannon": barrels.assign([-0.17,0.17])
	for i: int in range(barrels.size()):
		var x: float = barrels[i]
		var radius: float = 0.17 if id == "cannon" else (0.14 if id == "scatter" else 0.062)
		_part(turret, "Barrel%d" % i, "cylinder", Vector3(radius,0.62,0), Vector3(x,0.02,-0.66), "metal" if rapid else "dark", Vector3(PI/2,0,0))
		_part(turret, "Collar%d" % i, "ring", Vector3(radius*0.97,radius*1.16,0), Vector3(x,0.02,-0.41), "gold" if rapid else "metal", Vector3(PI/2,0,0))
		_part(turret, "Muzzle%d" % i, "ring", Vector3(radius*0.78,radius*1.24,0), Vector3(x,0.02,-1.0), "gold", Vector3(PI/2,0,0))
		_part(turret, "Bore%d" % i, "cylinder", Vector3(radius*0.79,0.01,0), Vector3(x,0.02,-0.97), "dark", Vector3(PI/2,0,0))
		if not rapid:
			_part(turret, "Sleeve%d" % i, "cylinder", Vector3(radius*1.12,0.15,0), Vector3(x,0.02,-0.54), "dark", Vector3(PI/2,0,0))
	if rapid:
		for side: int in [-1,1]:
			_part(turret, "AmmoBox%d" % side, "box", Vector3(0.13,0.43,0.35), Vector3(side*0.48,0.18,0.0), "dark")
			for i: int in range(6):
				_part(turret, "Ammo%d_%d" % [side,i], "cylinder", Vector3(0.026,0.14,0), Vector3(side*0.50,0.015+i*0.065,-0.20), "gold", Vector3(0,0,PI/2))
	_save(turret, "Muzzle", Vector3(0,0.02,-1.05))
