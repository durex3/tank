extends Resource
class_name PartCardRenderStyle
## Offline card photography only; never rescales production geometry.

@export var camera_position: Vector3 = Vector3(-3.8,3.2,-4.5)
@export var camera_target: Vector3 = Vector3(0,0.30,-0.15)
@export var camera_size: float = 3.0
@export var key_rotation: Vector3 = Vector3(-35,55,0)
@export var key_energy: float = 0.78
@export var ambient_energy: float = 0.12
@export var fill_rotation: Vector3 = Vector3(-20,-110,0)
@export var fill_energy: float = 0.12
@export var rim_rotation: Vector3 = Vector3(-25,145,0)
@export var rim_energy: float = 0.22
@export var lower_value: float = 0.62
@export var upper_value: float = 0.94
@export var side_value: float = 0.76
@export var render_pixels: int = 1024
@export var output_pixels: int = 512
