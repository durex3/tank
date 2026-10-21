extends Node3D
class_name TrackRig
## Independent full wheels and moving tread cleats; no collision or simulation.

const STYLE: TrackRigStyle = preload("res://content/presentation/track_rig.tres")
@export var style: TrackRigStyle = STYLE
var _wheels: Array[Node3D] = []
var _belts: Array[MultiMeshInstance3D] = []
var _rubber: StandardMaterial3D
var _gold: StandardMaterial3D
var _face: StandardMaterial3D
var _cleat_poses: Array[Transform3D] = []
var belt_geometry: Array = []

func cleat_pose(side: int, index: int) -> Transform3D:
	return _cleat_poses[side * style.cleat_count + index]

func _ready() -> void:
	_rubber = _material(style.rubber, 0.0, 0.88)
	_gold = _material(style.gold, 0.55, 0.48)
	_face = _material(style.face, 0.08, 0.72)
	for side: int in [-1, 1]:
		_build_side(side)
	present_travel(Vector2.ZERO)

func perimeter() -> float:
	return 2.0 * (style.rear_z - style.front_z) + TAU * style.belt_radius

func present_turn(_turn: float, _distance: float) -> void:
	pass

func present_travel(travel: Vector2) -> void:
	_cleat_poses.clear()
	for i: int in range(_wheels.size()):
		# World-space axes: source legacy +X names correspond to the left side.
		var distance: float = travel.x if _wheels[i].position.x < 0.0 else travel.y
		_wheels[i].rotation.x = wrapf(distance / style.wheel_radius, -PI, PI)
	for side: int in range(_belts.size()):
		var distance: float = travel.x if side == 0 else travel.y
		var belt := _belts[side].multimesh
		for i: int in range(style.cleat_count):
			var pose := _path(float(i) * perimeter() / style.cleat_count + distance)
			pose.origin += pose.basis.y * (style.belt_thickness + style.cleat_height) * 0.5
			pose.origin.x = -style.axle_x if side == 0 else style.axle_x
			_cleat_poses.append(pose)
			belt.set_instance_transform(i, pose)

func _build_side(side: int) -> void:
	var base := MeshInstance3D.new()
	base.name = "BeltLeft" if side < 0 else "BeltRight"
	base.mesh = _belt_mesh()
	base.position.x = side * style.axle_x
	add_child(base)
	var cleat := BoxMesh.new()
	cleat.size = Vector3(style.belt_width + 0.012, style.cleat_height, perimeter() / style.cleat_count * 0.66)
	cleat.material = _rubber
	var belt := MultiMeshInstance3D.new()
	belt.name = "CleatsLeft" if side < 0 else "CleatsRight"
	belt.multimesh = MultiMesh.new()
	belt.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	belt.multimesh.mesh = cleat
	belt.multimesh.instance_count = style.cleat_count
	add_child(belt)
	_belts.append(belt)
	for i: int in range(style.wheel_count):
		var wheel := Node3D.new()
		wheel.name = ("WheelRight" if side < 0 else "WheelLeft") + str(i)
		wheel.position = Vector3(side * style.axle_x, style.axle_y, lerpf(style.front_z, style.rear_z, float(i) / maxi(1, style.wheel_count - 1)))
		add_child(wheel)
		_wheels.append(wheel)
		_disc(wheel, style.wheel_radius, 0.245, 0.0, _rubber)
		if style.sculpted_wheels:
			preload("res://presentation/sculpted_track_wheel.gd").build(wheel,side,style,_gold,_face,_rubber)
			continue
		_disc(wheel, style.rim_radius, 0.018, side * 0.132, _gold)
		_disc(wheel, style.face_radius, 0.012, side * 0.145, _face)
		var slot := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.006, 0.012, 0.145)
		box.material = _rubber
		slot.mesh = box
		slot.position.x = side * 0.153
		wheel.add_child(slot)
		for offset: float in [-0.115, 0.115]:
			var bolt := _disc(wheel, 0.012, 0.008, side * 0.154, _rubber)
			bolt.position.y = offset

func _disc(parent: Node3D, radius: float, depth: float, x: float, material: Material) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 32
	mesh.rings = 1
	mesh.material = material
	instance.mesh = mesh
	instance.rotation.z = PI * 0.5
	instance.position.x = x
	parent.add_child(instance)
	return instance

func _material(color: Color, metal: float, roughness: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = metal
	material.roughness = roughness
	return material

func _path(distance: float) -> Transform3D:
	var length: float = style.rear_z - style.front_z
	var arc: float = PI * style.belt_radius
	var s: float = fposmod(distance, perimeter())
	var point: Vector3
	var tangent: Vector3
	if s < length:
		point = Vector3(0, style.axle_y + style.belt_radius, style.rear_z - s)
		tangent = Vector3.FORWARD
	elif s < length + arc:
		var angle: float = PI * 0.5 + (s - length) / style.belt_radius
		point = Vector3(0, style.axle_y + sin(angle) * style.belt_radius, style.front_z + cos(angle) * style.belt_radius)
		tangent = Vector3(0, cos(angle), -sin(angle))
	elif s < length * 2 + arc:
		point = Vector3(0, style.axle_y - style.belt_radius, style.front_z + s - length - arc)
		tangent = Vector3.BACK
	else:
		var angle: float = -PI * 0.5 + (s - length * 2 - arc) / style.belt_radius
		point = Vector3(0, style.axle_y + sin(angle) * style.belt_radius, style.rear_z + cos(angle) * style.belt_radius)
		tangent = Vector3(0, cos(angle), -sin(angle))
	var normal := Vector3.RIGHT.cross(tangent).normalized()
	return Transform3D(Basis(Vector3.RIGHT, normal, -tangent), point)

func _belt_mesh() -> ArrayMesh:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_smooth_group(-1)
	surface.set_material(_rubber)
	for i: int in range(96):
		var a := _path(perimeter() * i / 96.0)
		var b := _path(perimeter() * (i + 1) / 96.0)
		for face: int in range(4):
			var corners: Array[Vector3] = []
			for pose: Transform3D in [a, b]:
				var outer := pose.basis.y * style.belt_thickness * 0.5
				var left := Vector3.LEFT * style.belt_width * 0.5
				var ring: Array[Vector3] = [pose.origin + left + outer, pose.origin - left + outer, pose.origin - left - outer, pose.origin + left - outer]
				corners.append(ring[face])
				corners.append(ring[(face + 1) % 4])
			# Godot front faces use clockwise winding viewed from outside.
			for index: int in [0, 2, 1, 1, 2, 3]:
				surface.add_vertex(corners[index])
	surface.generate_normals()
	belt_geometry = surface.commit_to_arrays()
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, belt_geometry)
	mesh.surface_set_material(0, _rubber)
	return mesh
