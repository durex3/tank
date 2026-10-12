extends Node3D
## Stable 32 x 24 meter collision layout, with separate cosmetic dressing.

func _ready() -> void:
	_box(Vector3(0, -0.15, 0), Vector3(32, 0.3, 24), Color("687c85"))
	_box(Vector3(-16, 1, 0), Vector3(0.6, 2, 24), Color("737f80"))
	_box(Vector3(16, 1, 0), Vector3(0.6, 2, 24), Color("737f80"))
	_box(Vector3(0, 1, -12), Vector3(32, 2, 0.6), Color("737f80"))
	_box(Vector3(0, 1, 12), Vector3(32, 2, 0.6), Color("737f80"))
	for x: float in [-6.0, 6.0]:
		for z: float in [-4.0, 4.0]:
			_box(Vector3(x, 0.75, z), Vector3(3.5, 1.5, 2.0), Color("947443"))
	add_child(ArenaDressing.new())

func _box(center: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = center
	add_child(body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	_add_mesh(body, size, color)

func _add_mesh(parent: Node3D, size: Vector3, color: Color) -> void:
	var instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	mesh.material = material
	instance.mesh = mesh
	parent.add_child(instance)
