extends RefCounted
## Cosmetic stepped wheel faces within the existing rigid wheel and axle envelope.
static func build(wheel: Node3D, side: int, style: TrackRigStyle, gold: Material, face: Material, rubber: Material) -> void:
	var rim: float = style.rim_radius
	var radius: float = style.face_radius
	_lathe(wheel,side,[Vector2(.125,.025),Vector2(.125,rim-.012),Vector2(.131,rim),Vector2(.140,rim),Vector2(.147,rim-.012),Vector2(.147,radius-.005),Vector2(.136,radius-.020),Vector2(.136,.025)],gold,"SteppedRim")
	_lathe(wheel,side,[Vector2(.136,.025),Vector2(.136,radius-.018),Vector2(.141,radius-.005),Vector2(.150,radius-.005),Vector2(.153,radius-.018),Vector2(.153,.075),Vector2(.142,.060),Vector2(.142,.025)],face,"RecessedFace")
	_lathe(wheel,side,[Vector2(.142,.025),Vector2(.142,.056),Vector2(.148,.064),Vector2(.156,.058),Vector2(.158,.030),Vector2(.158,.025)],rubber,"HubWell")
	_lathe(wheel,side,[Vector2(.150,.008),Vector2(.150,.026),Vector2(.155,.032),Vector2(.158,.026),Vector2(.158,.008)],face,"HubCap")

static func _lathe(parent: Node3D, side: int, profile: Array[Vector2], material: Material, label: String) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(material)
	var segments: int = 40
	for i: int in range(profile.size()):
		var a: Vector2 = profile[i]
		var b: Vector2 = profile[(i+1)%profile.size()]
		for j: int in range(segments):
			var first: float = TAU*j/segments
			var second: float = TAU*(j+1)/segments
			var points: Array[Vector3] = []
			var normals: Array[Vector3] = []
			for entry: Array in [[a,first],[a,second],[b,first],[b,second]]:
				var p: Vector2 = entry[0]
				var angle: float = entry[1]
				points.append(Vector3(side*p.x,p.y*cos(angle),p.y*sin(angle)))
				var delta: Vector2 = b-a
				normals.append(Vector3(-side*delta.y,delta.x*cos(angle),delta.x*sin(angle)).normalized())
			var indices := PackedInt32Array([0,2,1,1,2,3] if side > 0 else [0,1,2,1,3,2])
			for index: int in indices:
				surface.set_normal(normals[index])
				surface.add_vertex(points[index])
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = surface.commit()
	parent.add_child(instance)
