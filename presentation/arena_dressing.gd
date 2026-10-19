extends Node3D
class_name ArenaDressing
## Cosmetic-only tiled training deck. All collision stays in the arena owner.

func _ready() -> void:
	_floor_tiles()
	_box(Vector3(0, -0.65, 0), Vector3(32.6, 0.8, 24.6), Color("344c63"))
	for x: float in [-6.0, 6.0]:
		for z: float in [-4.0, 4.0]:
			_cover_details(Vector3(x, 0, z))
	_boundary_planters()
	_launch_pad()
	_perimeter_rails()
	for x: int in range(-15, 16, 3):
		for z: float in [-12.0, 12.0]:
			_box(Vector3(x, 2.03, z), Vector3(0.18, 0.08, 0.4), Color("d4ab4b"))
	for z: int in range(-10, 11, 3):
		for x: float in [-16.0, 16.0]:
			_box(Vector3(x, 2.03, z), Vector3(0.4, 0.08, 0.18), Color("d4ab4b"))
	for point: Vector3 in [Vector3(-18, 0, -9), Vector3(18, 0, 7), Vector3(18, 0, -10), Vector3(-18, 0, 10)]:
		_tree(point)

func _floor_tiles() -> void:
	var style: TrainingViewStyle = preload("res://content/presentation/training_view.tres")
	var tiles := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.985, 0.04, 1.985)
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 0.9
	mesh.material = material
	batch.mesh = mesh
	batch.instance_count = 16 * 12
	var index: int = 0
	for x: int in range(16):
		for z: int in range(12):
			batch.set_instance_transform(index, Transform3D(Basis.IDENTITY, Vector3(-15 + x * 2, 0.015, -11 + z * 2)))
			batch.set_instance_color(index, style.tile_color_a if (x + z) % 2 == 0 else style.tile_color_b)
			index += 1
	tiles.multimesh = batch
	add_child(tiles)

func _cover_details(center: Vector3) -> void:
	_box(center + Vector3(0, 1.52, 0), Vector3(3.5, 0.04, 2.0), Color("c2a065"))
	for side: float in [-1.0, 1.0]:
		_box(center + Vector3(0, 0.6, side * 1.01), Vector3(3.1, 0.15, 0.025), Color("d6ad5e"))
		for index: int in range(5):
			_box(center + Vector3(-1.0 + index * 0.5, 1.13, side * 1.015), Vector3(0.28, 0.13, 0.025), Color("6f552f"))
	for side: float in [-1.0, 1.0]:
		for slat: int in range(6):
			_box(center + Vector3(-1.45+slat*0.58,0.75,side*1.015),Vector3(0.06,1.25,0.035),Color("c8a465"))
		_box(center + Vector3(side * 1.76, 0.8, 0), Vector3(0.025, 0.95, 0.09), Color("c8a465"))

func _tree(center: Vector3) -> void:
	_box(center + Vector3(0, -0.15, 0), Vector3(2.2, 0.3, 2.2), Color("5b725b"))
	_box(center + Vector3(0, 0.6, 0), Vector3(0.3, 1.2, 0.3), Color("75634c"))
	for index: int in range(3):
		var instance := MeshInstance3D.new()
		var canopy := SphereMesh.new()
		canopy.radius = 0.8 - index * 0.12
		canopy.height = canopy.radius * 1.8
		canopy.radial_segments = 8
		canopy.rings = 4
		canopy.material = _material(Color("5f916e") if index % 2 == 0 else Color("78a37a"))
		instance.mesh = canopy
		instance.position = center + Vector3(0, 1.2 + index * 0.5, 0)
		add_child(instance)

func _box(center: Vector3, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = _material(color)
	instance.mesh = mesh
	instance.position = center
	add_child(instance)

func _material(color: Color) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	return result

func _launch_pad() -> void:
	var mark := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 2.15
	mesh.outer_radius = 2.21
	mesh.rings = 64
	mesh.ring_segments = 6
	var material := _material(Color("566b70"))
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = material
	mark.mesh = mesh
	mark.position.y = 0.045
	mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mark)
	for x: float in [-2.45,2.45]:
		_box(Vector3(x,0.045,0),Vector3(0.12,0.015,0.8),Color("d2b36f"))

func _perimeter_rails() -> void:
	# Rails sit on existing solid parapets. No new gameplay obstacles.
	for x: int in range(-15,16,3):
		for z: float in [-12.0,12.0]:
			_box(Vector3(x,2.35,z),Vector3(0.08,0.7,0.08),Color("425761"))
	for z: int in range(-9,10,3):
		for x: float in [-16.0,16.0]:
			_box(Vector3(x,2.35,z),Vector3(0.08,0.7,0.08),Color("425761"))
	for height: float in [2.2,2.65]:
		for z: float in [-12.0,12.0]: _box(Vector3(0,height,z),Vector3(32,0.05,0.05),Color("768b8f"))
		for x: float in [-16.0,16.0]: _box(Vector3(x,height,0),Vector3(0.05,0.05,24),Color("768b8f"))

func _boundary_planters() -> void:
	# Vegetation stays on the collision-backed boundary, outside driving lanes.
	for center: Vector3 in [Vector3(-2,2.0,-12),Vector3(7,2.0,-12),Vector3(-9,2.0,12),Vector3(9,2.0,12),Vector3(16,2.0,-6),Vector3(-16,2.0,6)]:
		_box(center+Vector3(0,0.14,0),Vector3(1.7,0.28,0.52),Color("7d5c43"))
		for offset: float in [-0.5,0.0,0.5]:
			var bush := MeshInstance3D.new()
			var mesh := SphereMesh.new()
			mesh.radius = 0.35
			mesh.height = 0.55
			mesh.radial_segments = 10
			mesh.rings = 5
			mesh.material = _material(Color("638350"))
			bush.mesh = mesh
			bush.position = center+Vector3(offset,0.43,0)
			add_child(bush)
