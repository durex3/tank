extends Resource
class_name TankSteeringRules
## Authoritative heading rate; displacement still follows the existing top-down controls.

@export var turn_rate_radians: float = 4.8
@export var opposite_epsilon_radians: float = 0.001
@export var minimum_turn_speed_ratio: float = 0.15
@export var alignment_power: float = 2.0
@export var turn_braking_acceleration: float = 40.0
