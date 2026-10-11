extends Resource
class_name TouchInputTuning
## Shared read-only logical-pixel tuning. Never mutated by a touch session.

@export_range(16.0, 160.0) var radius: float = 64.0
@export_range(0.0, 0.9) var deadzone: float = 0.15
@export_range(1.5, 4.0) var cancel_distance_radii: float = 2.0
