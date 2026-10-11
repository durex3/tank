extends Node3D
class_name HangarPreview
## Isolated non-combat display world; a preview never creates a simulation.

var tank := TankView.new()

func _ready() -> void:
	add_child(tank)
	tank.rotation.y = 0.45
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.6
	camera.position = Vector3(3, 3, -4)
	camera.look_at(Vector3(0, 0.45, 0))
	camera.current = true
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.5
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("172832")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b8d6db")
	environment.environment.ambient_light_energy = 0.7
	add_child(environment)
	var floor_mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 1.25
	cylinder.bottom_radius = 1.3
	cylinder.height = 0.12
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("34515b")
	cylinder.material = material
	floor_mesh.mesh = cylinder
	floor_mesh.position.y = -0.06
	add_child(floor_mesh)

func rotate_preview(radians: float) -> void:
	tank.rotation.y = wrapf(tank.rotation.y + radians, -PI, PI)
