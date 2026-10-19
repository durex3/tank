extends SceneTree
## Offline calibration: preserve original scenes and all authoritative markers.

const SOURCES: Array[Dictionary] = [{&"cannon": preload("res://presentation/parts/rodin_motion_v1/cannon.tscn"), &"autocannon": preload("res://presentation/parts/rodin_family_v2/autocannon.tscn"), &"scatter": preload("res://presentation/parts/rodin_family_v2/scatter.tscn"), &"bubble_cannon": preload("res://presentation/parts/rodin_family_v2/bubble_cannon.tscn")}, {&"light_tracks": preload("res://presentation/parts/track_rig_v1/light_tracks.tscn"), &"scout_wheels": preload("res://presentation/parts/rodin_family_v2/scout_wheels.tscn"), &"heavy_tracks": preload("res://presentation/parts/rodin_family_v2/heavy_tracks.tscn")} ]

const OUT: String = "res://presentation/parts/unified_size_v1/"
const STYLE: Resource = preload("res://content/presentation/part_size.tres")

func _initialize() -> void:
	call_deferred("_run")

func _bounds(part: Node3D) -> AABB:
	var result := AABB()
	var first: bool = true
	for node: Node in part.find_children("*", "GeometryInstance3D", true, false):
		var box: AABB
		if node is MeshInstance3D:
			box = (node as MeshInstance3D).get_aabb()
		elif node is MultiMeshInstance3D:
			box = (node as MultiMeshInstance3D).multimesh.get_aabb()
		else:
			continue
		box = part.global_transform.affine_inverse() * (node as Node3D).global_transform * box
		result = box if first else result.merge(box)
		first = false
	return result

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var report: Dictionary = {}
	for group: Dictionary in SOURCES:
		var turret: bool = group.has(&"cannon")
		var target: AABB = STYLE.turret_bounds if turret else STYLE.chassis_bounds
		for id: StringName in group:
			var source := group[id] as PackedScene
			# Always reference the pre-normalization source, even on rebuild.
			var source_path: String = source.resource_path
			var part := source.instantiate() as Node3D
			root.add_child(part)
			var original := _bounds(part)
			var factor := target.size / original.size
			var shift := target.position - original.position * factor
			var marker: String = "Muzzle" if turret else "TurretSocket"
			var socket: Vector3 = Vector3(0, 0.02, -1.05) if turret else Vector3(0, 0.76, 0)
			var text: String = "[gd_scene load_steps=2 format=3]\n\n[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1\"]\n\n[node name=\"%s\" type=\"Node3D\"]\n\n[node name=\"Geometry\" parent=\".\" instance=ExtResource(\"1\")]\nposition = %s\nscale = %s\n\n[node name=\"%s\" type=\"Marker3D\" parent=\".\"]\nposition = %s\n" % [source_path, id, var_to_str(shift), var_to_str(factor), marker, var_to_str(socket)]
			var file := FileAccess.open(OUT + str(id) + ".tscn", FileAccess.WRITE)
			file.store_string(text)
			report[str(id)] = {"source": source_path, "before": var_to_str(original), "target": var_to_str(target), "scale": var_to_str(factor), "offset": var_to_str(shift)}
			print(id, " BEFORE ", original, " TARGET ", target)
			part.free()
	var output := FileAccess.open(OUT + "calibration.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(report, "\t"))
	print("PART SIZE CALIBRATION: PASS")
	quit()
