extends RefCounted
## Original sample materials; only explicitly tagged candidates use this finish.
const SHADER = preload("res://presentation/shaders/soft_workshop.gdshader")
const STYLE = preload("res://content/presentation/soft_workshop.tres")

static func apply(part: Node3D) -> void:
	var tuning: Resource = load(part.get_meta("soft_workshop_style","res://content/presentation/soft_workshop.tres"))
	for node: Node in part.find_children("*","GeometryInstance3D",true,false):
		var mesh: Mesh
		if node is MeshInstance3D: mesh = node.mesh
		elif node is MultiMeshInstance3D: mesh = node.multimesh.mesh
		else: continue
		for surface: int in range(mesh.get_surface_count()):
			var source: StandardMaterial3D = (node.get_active_material(surface) if node is MeshInstance3D else node.material_override if node.material_override != null else mesh.surface_get_material(surface)) as StandardMaterial3D
			if source == null: continue
			var material := ShaderMaterial.new()
			material.shader = SHADER
			material.set_shader_parameter("base_color",source.albedo_color)
			material.set_shader_parameter("roughness_value",source.roughness)
			for key: StringName in [&"ambient_strength",&"wrap_amount",&"occlusion_strength",&"top_bottom_strength",&"highlight_strength",&"key_strength",&"exposure_shoulder"]:
				material.set_shader_parameter(key,tuning.get(key))
			if node is MeshInstance3D: node.set_surface_override_material(surface,material)
			else:
				node.set_meta("soft_workshop_source_material",source)
				node.material_override = material

static func clear(part: Node3D) -> void:
	for node: Node in part.find_children("*","MultiMeshInstance3D",true,false):
		if node.has_meta("soft_workshop_source_material"):
			node.material_override = node.get_meta("soft_workshop_source_material")
			node.remove_meta("soft_workshop_source_material")
