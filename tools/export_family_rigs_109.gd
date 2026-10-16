extends SceneTree
## Snapshot the exact runtime TrackRig for editable Blender inspection scenes.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	for id: String in ["light_tracks","heavy_tracks"]:
		var source := load("res://presentation/parts/mechanical_v2/%s.tscn" % id).instantiate() as Node3D
		root.add_child(source)
		var rig := source.find_child("TrackRig",true,false) as TrackRig
		var snapshot := Node3D.new()
		snapshot.name = id+"_runtime_tracks"
		root.add_child(snapshot)
		for node: Node in rig.find_children("*","GeometryInstance3D",true,false):
			if node is MeshInstance3D:
				var mesh := MeshInstance3D.new()
				mesh.name = node.get_parent().name+"_"+str(snapshot.get_child_count())
				mesh.mesh = node.mesh
				snapshot.add_child(mesh)
				mesh.transform = node.global_transform
			elif node is MultiMeshInstance3D:
				for i: int in range(node.multimesh.instance_count):
					var mesh := MeshInstance3D.new()
					mesh.name = "Cleat_"+str(snapshot.get_child_count())
					mesh.mesh = node.multimesh.mesh
					snapshot.add_child(mesh)
					mesh.transform = node.global_transform*node.multimesh.get_instance_transform(i)
		var doc := GLTFDocument.new()
		var state := GLTFState.new()
		assert(doc.append_from_scene(snapshot,state)==OK)
		assert(doc.write_to_filesystem(state,"res://source_art/mechanical-family-v2/%s_runtime_tracks.glb" % id)==OK)
		source.free()
		snapshot.free()
	print("FAMILY RIG SNAPSHOTS: PASS")
	quit()
