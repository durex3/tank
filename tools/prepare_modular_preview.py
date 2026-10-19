"""Measure original GLBs and build isolated, uniformly scaled preview wrappers."""
import hashlib
import json
import struct
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'presentation/parts/modular_sample_v1'
OUT.mkdir(parents=True, exist_ok=True)
records = {}
for name in ('t02', 'c03'):
    path = ROOT / f'assets/imported/modular-sample-v1/{name}_pbr.glb'
    data = path.read_bytes()
    assert data[:4] == b'glTF'
    doc = json.loads(data[20:20 + struct.unpack_from('<I', data, 12)[0]])
    prim = doc['meshes'][0]['primitives'][0]
    accessor = doc['accessors'][prim['attributes']['POSITION']]
    records[name] = dict(source=str(path.relative_to(ROOT)), sha256=hashlib.sha256(data).hexdigest(),
                         meshes=len(doc['meshes']), triangles=doc['accessors'][prim['indices']]['count']//3,
                         minimum=accessor['min'], maximum=accessor['max'],
                         size=[b-a for a,b in zip(accessor['min'],accessor['max'])])

# World sizes are intentionally derived at runtime from the existing single size resource.
# The preview resource then applies a uniform turret correction; full-envelope compliance is pending.
for name, socket, position in [('t02','Muzzle','0, 0.02, -1.05'),('c03','TurretSocket','0, 0.76, 0')]:
    (OUT / f'{name}.tscn').write_text(f'''[gd_scene load_steps=3 format=3]

[ext_resource type="PackedScene" path="res://assets/imported/modular-sample-v1/{name}_pbr.glb" id="1"]
[ext_resource type="Script" path="res://presentation/previews/modular_candidate_part.gd" id="2"]

[node name="{name.upper()}Candidate" type="Node3D"]
script = ExtResource("2")
turret = {'true' if name == 't02' else 'false'}
source_minimum = Vector3({', '.join(str(x) for x in records[name]['minimum'])})
source_size = Vector3({', '.join(str(x) for x in records[name]['size'])})

[node name="Geometry" parent="." instance=ExtResource("1")]

[node name="{socket}" type="Marker3D" parent="."]
position = Vector3({position})
''', encoding='utf-8')
report = dict(parts=records, status='inspection_candidate_not_production',
              scale_policy='uniform width-fit from part_size.tres, then candidate-only multiplier/seating from modular_sample_preview.tres; full-envelope NOT compliant yet',
              limitations=['single mesh per part', 'no independent recoil/wheel animation', 'rear geometry needs review'])
(ROOT/'assets/imported/modular-sample-v1/inspection.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report, indent=2))
