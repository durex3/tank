"""Bake a half-turn into a new copy of C03; keep wheel transform axes canonical."""
import bpy, math, json
from pathlib import Path
from mathutils import Matrix, Vector

ROOT = Path('E:/Godot_v4.7.2-stable_win64/game/tank')
OUT = ROOT / 'assets/derived/hyper3d-refined-v2'
OUT.mkdir(parents=True, exist_ok=True)
scene = bpy.data.scenes.new('Hyper3D_102_Forward')
bpy.context.window.scene = scene
bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/derived/hyper3d-refined-v1/c03.glb'))
bpy.context.view_layer.update()
objects = list(scene.objects)
meshes = [o for o in objects if o.type == 'MESH']
points = [o.matrix_world @ v.co for o in meshes for v in o.data.vertices]
lo = Vector([min(p[i] for p in points) for i in range(3)])
hi = Vector([max(p[i] for p in points) for i in range(3)])
center = (lo+hi)/2
turn = Matrix.Translation(Vector((2*center.x,2*center.y,0))) @ Matrix.Rotation(math.pi,4,'Z')
world = {o: o.matrix_world.copy() for o in objects}
# Preserve parents but express every node with identity rotation/scale.
origins = {o: turn @ world[o].translation for o in objects}
for o in objects:
    if o.type == 'MESH':
        o.data = o.data.copy()
        for v in o.data.vertices:
            v.co = turn @ world[o] @ v.co - origins[o]
        o.data.update()
    o.matrix_parent_inverse = Matrix.Identity(4)
    o.matrix_basis = Matrix.Translation(origins[o] - origins[o.parent] if o.parent else origins[o])
    if o.name.startswith(('Wheel','Steer','Tire','Axle')):
        o.name = o.name.replace('Left','TEMP').replace('Right','Left').replace('TEMP','Right').replace('Front','TEMP').replace('Rear','Front').replace('TEMP','Rear')
bpy.context.view_layer.update()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'c03.glb'),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
saved = ROOT/'source_art/hyper3d-refined-v2'
saved.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(saved/'scout_forward.blend'))
result={'output':str(OUT/'c03.glb'),'mesh_count':len(meshes),'correction':'180 degree geometry bake, canonical wheel axes, original AABB center preserved'}
(OUT/'provenance.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
