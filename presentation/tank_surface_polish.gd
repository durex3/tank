extends RefCounted
class_name TankSurfacePolish
## Shared family finish: preserve source textures and authoritative assembly.

const STYLE: TankSurfaceStyle = preload("res://content/presentation/tank_surface.tres")
const SHADER: Shader = preload("res://presentation/shaders/clean_armor.gdshader")

static func apply(part: Node3D, part_id: StringName) -> void:
	if part_id not in [&"cannon", &"light_tracks", &"autocannon", &"scatter", &"bubble_cannon", &"scout_wheels", &"heavy_tracks"]:
		return
	var visual: Node = part.find_child("Visual", true, false)
	if visual == null:
		return
	for node: Node in part.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface: int in range(instance.mesh.get_surface_count()):
			var original := instance.get_active_material(surface) as StandardMaterial3D
			if original == null or original.albedo_texture == null:
				continue
			var finish := ShaderMaterial.new()
			finish.shader = SHADER
			finish.set_shader_parameter("albedo_map", original.albedo_texture)
			finish.set_shader_parameter("has_orm_map", original.roughness_texture != null)
			finish.set_shader_parameter("has_normal_map", original.normal_texture != null)
			if original.roughness_texture != null:
				finish.set_shader_parameter("orm_map", original.roughness_texture)
			if original.normal_texture != null:
				finish.set_shader_parameter("normal_map", original.normal_texture)
			finish.set_shader_parameter("cleanup_strength", STYLE.cleanup_strength)
			finish.set_shader_parameter("normal_strength", STYLE.normal_strength)
			finish.set_shader_parameter("speckle_cleanup", STYLE.speckle_cleanup)
			finish.set_shader_parameter("armor_color", STYLE.armor_color)
			instance.set_surface_override_material(surface, finish)

static func clear(part: Node) -> void:
	# Release overrides while the mesh still exists, before deferred renderer cleanup.
	for node: Node in part.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface: int in range(instance.get_surface_override_material_count()):
			if instance.get_surface_override_material(surface) is ShaderMaterial:
				instance.set_surface_override_material(surface, null)
