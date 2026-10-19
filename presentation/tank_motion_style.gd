extends Resource
class_name TankMotionStyle
## Cosmetic distances in metres and durations in committed simulation ticks.

@export var cannon_recoil_m: float = 0.12
@export var breach_recoil_m: float = 0.18
@export var autocannon_recoil_m: float = 0.045
@export var scatter_recoil_m: float = 0.10
@export var bubble_recoil_m: float = 0.035
@export var kick_ticks: int = 2
@export var return_ticks: int = 13
@export var wheel_radius_m: float = 0.21
@export var track_half_width_m: float = 0.62
@export var track_source_scale: float = 1.35
@export var visual_teleport_limit_m: float = 2.0
@export var wheel_steer_max_radians: float = 0.42
@export var wheel_steer_distance_floor_m: float = 0.08
