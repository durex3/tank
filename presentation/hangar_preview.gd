extends Node3D
class_name HangarPreview
## Isolated non-combat display world; a preview never creates a simulation.

const STYLE: HangarPreviewStyle = preload("res://content/presentation/hangar_preview.tres")

var tank := TankView.new()

func _ready() -> void:
	add_child(tank)
	tank.rotation.y = STYLE.initial_yaw
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = STYLE.camera_size
	camera.position = STYLE.camera_position
	camera.look_at(Vector3(0, 0.45, 0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = STYLE.key_energy
	light.light_color = Color("fff1dd")
	light.shadow_enabled = true
	light.shadow_normal_bias = STYLE.shadow_normal_bias
	light.directional_shadow_max_distance = 12.0
	add_child(light)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 70, 0)
	fill.light_energy = STYLE.fill_energy
	fill.light_color = Color("c5d6ef")
	add_child(fill)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-35, 150, 0)
	rim.light_energy = STYLE.rim_energy
	rim.light_color = Color("e2eafa")
	add_child(rim)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = STYLE.background_color
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("d4d8df")
	environment.environment.ambient_light_energy = STYLE.ambient_energy
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("64748a")
	sky_material.sky_horizon_color = Color("c0c7cc")
	sky_material.ground_horizon_color = Color("a49b89")
	sky_material.ground_bottom_color = Color("292d36")
	sky.sky_material = sky_material
	environment.environment.sky = sky
	environment.environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	add_child(environment)
	var floor_mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.25
	cylinder.bottom_radius = 1.3
	cylinder.height = 0.12
	var material := StandardMaterial3D.new()
	material.albedo_color = STYLE.platform_color
	material.roughness = 0.8
	cylinder.material = material
	floor_mesh.mesh = cylinder
	floor_mesh.position.y = -0.06
	add_child(floor_mesh)

func rotate_preview(radians: float) -> void:
	tank.rotation.y = wrapf(tank.rotation.y + radians, -PI, PI)
