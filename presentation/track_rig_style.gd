extends Resource
class_name TrackRigStyle
## Dimensions in metres; visuals only, shared configuration is read-only.

@export var axle_x: float = 0.655
@export var axle_y: float = 0.335
@export var front_z: float = -0.75
@export var rear_z: float = 0.40
@export var belt_radius: float = 0.285
@export var belt_width: float = 0.34
@export var belt_thickness: float = 0.045
@export var wheel_radius: float = 0.225
@export var rim_radius: float = 0.205
@export var face_radius: float = 0.182
@export var cleat_count: int = 48
@export var cleat_height: float = 0.025
@export var wheel_count: int = 3
@export var rubber: Color = Color("202930")
@export var face: Color = Color("e8e9e3")
@export var gold: Color = Color("c9a137")

@export var sculpted_wheels: bool = false
