extends Node3D
class_name ArenaDressing
## Cosmetic-only tiled training deck. All collision stays in the arena owner.

func _ready() -> void:
	_floor_tiles()
	_box(Vector3(0, -0.65, 0), Vector3(32.6, 0.8, 24.6), Color("344c63"))
	for x: float in [-6.0, 6.0]:
		for z: float in [-4.0, 4.0]:
			_cover_details(Vector3(x, 0, z))
	for x: int in range(-15, 16, 3):
		for z: float in [-12.0, 12.0]:
			_box(Vector3(x, 2.03, z), Vector3(0.18, 0.08, 0.4), Color("d4ab4b"))
	for z: int in range(-10, 11, 3):
		for x: float in [-16.0, 16.0]:
			_box(Vector3(x, 2.03, z), Vector3(0.4, 0.08, 0.18), Color("d4ab4b"))
	for point: Vector3 in [Vector3(-18, 0, -9), Vector3(18, 0, 7), Vector3(18, 0, -10), Vector3(-18, 0, 10)]:
		_tree(point)

func _floor_tiles() -> void:
	var tiles := MultiMeshInstance3D.new()
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.use_colors = true
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.97, 0.04, 1.97)
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
			batch.set_instance_color(index, Color("9caaa9") if (x + z) % 2 == 0 else Color("a9b5b1"))
			index += 1
	tiles.multimesh = batch
	add_child(tiles)

func _cover_details(center: Vector3) -> void:
	_box(center + Vector3(0, 1.52, 0), Vector3(3.5, 0.04, 2.0), Color("e3dfce"))
	for side: float in [-1.0, 1.0]:
		_box(center + Vector3(0, 0.6, side * 1.01), Vector3(3.1, 0.15, 0.025), Color("cda54c"))
		for index: int in range(5):
			_box(center + Vector3(-1.0 + index * 0.5, 1.13, side * 1.015), Vector3(0.28, 0.13, 0.025), Color("52656c"))
	for side: float in [-1.0, 1.0]:
		_box(center + Vector3(side * 1.76, 0.8, 0), Vector3(0.025, 0.95, 0.09), Color("b6b19d"))

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
