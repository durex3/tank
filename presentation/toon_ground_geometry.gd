extends RefCounted
class_name ToonGroundGeometry
## Coplanar stencil geometry. Never extrudes a ground marking vertically.

static func material() -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	result.vertex_color_use_as_albedo = true
	result.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	result.cull_mode = BaseMaterial3D.CULL_DISABLED
	return result

static func triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)

static func ribbon(mesh: ImmediateMesh, a: Vector3, b: Vector3, width: float, color: Color) -> void:
	var side: Vector3 = (b-a).cross(Vector3.UP).normalized()*width*0.5
	triangle(mesh,a-side,a+side,b+side,color)
	triangle(mesh,a-side,b+side,b-side,color)

static func arc(mesh: ImmediateMesh, center: Vector3, radius: float, yaw: float, half: float, width: float, color: Color, segments: int = 20) -> void:
	for i: int in range(segments):
		var a: float = yaw-half+half*2.0*i/segments
		var b: float = yaw-half+half*2.0*(i+0.78)/segments
		var inner: float = maxf(0.01,radius-width)
		var va := Vector3(sin(a),0,-cos(a))
		var vb := Vector3(sin(b),0,-cos(b))
		triangle(mesh,center+va*inner,center+va*radius,center+vb*radius,color)
		triangle(mesh,center+va*inner,center+vb*radius,center+vb*inner,color)

static func chevron(mesh: ImmediateMesh, p: Vector3, front: Vector3, size: float, color: Color) -> void:
	var right := Vector3(-front.z,0,front.x)
	ribbon(mesh,p-front*size+right*size,p,size*0.40,color)
	ribbon(mesh,p-front*size-right*size,p,size*0.40,color)
