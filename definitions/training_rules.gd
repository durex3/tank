extends Resource
class_name TrainingRules

@export var target_hp: PackedInt32Array = PackedInt32Array([350, 670, 1445])
@export var target_positions: PackedVector3Array = PackedVector3Array([Vector3(-7, 0, -8), Vector3(0, 0, -8), Vector3(7, 0, -8)])
@export var rebuild_ticks: int = 180

@export var target_motion_extents: PackedFloat32Array = PackedFloat32Array([0.0, 2.5, 0.0])
@export var target_motion_speeds: PackedFloat32Array = PackedFloat32Array([0.0, 2.0, 0.0])

func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	var count := target_hp.size()
	if count == 0 or target_positions.size() != count or target_motion_extents.size() != count or target_motion_speeds.size() != count:
		errors.append("Training target arrays must be nonempty and have equal lengths")
		return errors
	if rebuild_ticks < 1:
		errors.append("Training rebuild_ticks must be positive")
	for index: int in range(count):
		if target_hp[index] <= 0:
			errors.append("Training HP must be positive: " + str(index))
		if not target_positions[index].is_finite() or target_positions[index].y != 0.0:
			errors.append("Training positions must be finite and on XZ: " + str(index))
		var extent := target_motion_extents[index]
		var speed := target_motion_speeds[index]
		if not is_finite(extent) or not is_finite(speed) or extent < 0.0 or speed < 0.0:
			errors.append("Training motion must be finite and nonnegative: " + str(index))
		elif (extent == 0.0) != (speed == 0.0):
			errors.append("Stationary targets need both motion values zero: " + str(index))
	return errors
