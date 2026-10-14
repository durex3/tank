extends RefCounted
class_name WeaponProjectileVisual
## Authored 3D silhouettes; local -Z is forward. No state mutation or collision.

static func create(weapon: StringName, team: int, style: WeaponVisualStyle) -> Node3D:
	var root := Node3D.new()
	root.name = "Projectile_"+String(weapon)
	var color: Color = style.friendly if team == 0 else style.enemy
	match weapon:
		&"autocannon":
			rod(root,style.needle_radius,style.needle_length,0,Color("fff5d9"))
			cone(root,style.needle_radius*1.6,style.needle_tail,style.needle_tail*0.5,color)
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
			rod(root,style.cannon_radius,style.cannon_length,0,color)
			rod(root,style.cannon_radius*1.12,style.cannon_length*0.18,style.cannon_length*0.2,style.steel)
			cone(root,style.cannon_radius,style.cannon_length*0.35,-style.cannon_length*0.65,Color("fff4d2"))
			cone(root,style.cannon_radius*0.75,style.cannon_tail,style.cannon_tail*0.7,color)
	return root

static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
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
