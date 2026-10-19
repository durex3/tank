"""Correct 105 tread frame order in an isolated derivative; original GLB/blend stay read-only."""
import bpy, math, json
from pathlib import Path
from mathutils import Matrix
root = Path.cwd()
output = root / 'assets/derived/mechanical-production-v1'
output.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/derived/mechanical-sample-v1/scout_wheels.glb'))
count = 0
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH' and obj.name.startswith('Tread'):
        angle = math.atan2(obj.location.y, obj.location.z)
        row = 1 if obj.location.x > 0 else -1
        obj.rotation_mode = 'XYZ'
        obj.rotation_euler = (Matrix.Rotation(-angle, 4, 'X') @ Matrix.Rotation(row*.13, 4, 'Z')).to_euler()
        count += 1
assert count == 192, count
bpy.ops.export_scene.gltf(filepath=str(output/'scout_wheels.glb'), export_format='GLB', export_animations=False)
(output/'provenance.json').write_text(json.dumps({'source':'assets/derived/mechanical-sample-v1/scout_wheels.glb','tool':'tools/prepare_mechanical_108.py','change':'192 tread blocks: apply chevron tilt before radial wheel rotation; preserve round tire and all axle centers','original_modified':False},indent=2))
