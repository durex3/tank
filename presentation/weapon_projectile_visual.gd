extends RefCounted
class_name WeaponProjectileVisual
## Authored 3D silhouettes; local -Z is forward. No state mutation or collision.

static func create(weapon: StringName, team: int, style: WeaponVisualStyle) -> Node3D:
	var root := Node3D.new()
	root.name = "Projectile_"+String(weapon)
	var color: Color = style.friendly if team == 0 else style.enemy
	match weapon:
		&"autocannon":
			rod(root,style.needle_radius*1.35,style.needle_length,0,Color(Color("673e21"),0.45))
			rod(root,style.needle_radius*0.75,style.needle_length*1.05,0,Color("f0c777"))
			cone(root,style.needle_radius*1.6,style.needle_tail,style.needle_tail*0.7,Color(color,0.6))
		&"scatter":
			var pellet := MeshInstance3D.new()
			var gem := PrismMesh.new()
			gem.size = Vector3(style.pellet_radius*2,style.pellet_radius*1.5,style.pellet_radius*3)
			pellet.mesh = gem
			pellet.material_override = material(color)
			pellet.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(pellet)
			rod(root,style.pellet_radius*0.25,style.pellet_tail,style.pellet_tail*0.7,Color("fff4dc"))
		_:
			var core := MeshInstance3D.new()
			core.name = "ShellBody"
			var shell := CapsuleMesh.new()
			shell.radius = style.shell_radius
			shell.height = style.shell_length
			shell.radial_segments = 16
			shell.rings = 4
			core.mesh = shell
			core.rotation.x = PI/2
			core.material_override = material(Color("66503c"))
			core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			root.add_child(core)
			rod(root,style.shell_radius*1.06,0.055,0.11,style.steel)
			for angle: float in [0.0,PI/2]:
				var trail := MeshInstance3D.new()
				trail.name = "ShellTrail"+str(angle)
				var quad := QuadMesh.new()
				quad.size = Vector2(style.shell_radius*2.3,style.cannon_glow_tail)
				trail.mesh = quad
				var lateral := Vector3(cos(angle),sin(angle),0)
				trail.basis = Basis(lateral,Vector3.BACK,lateral.cross(Vector3.BACK))
				trail.position.z = style.shell_length*0.5+style.cannon_glow_tail*0.3
				var glow := ShaderMaterial.new()
				glow = (ToonFxMaterials.MATERIALS[&"warm"] as ShaderMaterial).duplicate()
				glow.set_shader_parameter("sheet",ToonFxMaterials.SHEETS[&"streak"])
				glow.set_shader_parameter("cell",0.0)
				glow.set_shader_parameter("billboard",false)
				trail.material_override = glow
				trail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				root.add_child(trail)
	return root

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	if color.a < 1.0: mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return mat

static func rod(root: Node3D, radius: float, length_m: float, z: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length_m
	_add(root,mesh,z,color)

static func cone(root: Node3D, radius: float, length_m: float, z: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = 0.0
	mesh.height = length_m
	_add(root,mesh,z,color)

static func _add(root: Node3D, mesh: CylinderMesh, z: float, color: Color) -> void:
	mesh.radial_segments = 8
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.rotation.x = -PI/2
	node.position.z = z
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(node)
