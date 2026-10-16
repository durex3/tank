"""Derived from 109 pressure body; replace the rejected exposed-rail nozzle only."""
import os, json
from pathlib import Path
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT',str(Path.cwd())))
source=(ROOT/'tools/build_mechanical_family_109.py').read_text()
prefix=source[:source.index("p=empty('autocannon')")]
prefix=prefix.replace('mechanical-family-v2','bubble-compact-v1').replace('Mechanical_Family_109','Bubble_Compact_110')
exec(compile(prefix,'109_helpers','exec'))
body=source[source.index("p=empty('bubble_cannon')"):source.index("pivot=empty('RecoilPivot',p)",source.index("p=empty('bubble_cannon')"))]
exec(compile(body,'109_pressure_body','exec'))
p.name='bubble_cannon_110'
pivot=empty('RecoilPivot',p)
# Continuous rounded pump casing; no exposed rods or floating ring.
lathe('Compact pump casing',[(.28,.15),(.40,.195),(.55,.205),(.69,.19),(.79,.20),(.88,.25),(.98,.28),(1.08,.28),(1.145,.25),(1.16,.22),(1.16,.175),(1.10,.16),(.92,.14),(.70,.105),(.28,.105)],white,pivot,(0,0,.30),'Y',64)
lathe('Cyan spray lip',[(1.125,.183),(1.155,.183),(1.16,.175),(1.16,.163),(1.125,.163)],cyan,pivot,(0,0,.30),'Y',64)
bore(pivot,0,.30,.159,.145,.87,1.13,64)
empty('VisualMuzzle',pivot,(0,1.16,.30))
import ast
for node in ast.parse(source).body:
 if isinstance(node,ast.FunctionDef) and node.name=='audit':exec(compile(ast.Module(body=[node],type_ignores=[]),'audit','exec'))
report=audit(p)
assert not report['nonmanifold_meshes'],report
(OUT/'report.json').write_text(json.dumps(report,indent=2))
# Reuse the established export batching implementation on copies of this one part.
finish_source=(ROOT/'tools/finish_mechanical_family_109.py').read_text()
scene=s;parts=[p];stats={}
export=finish_source[finish_source.index('for part in parts:'):finish_source.index('# Lay out authored')]
export=export.replace("(part.name+'.glb')","'bubble_cannon.glb'")
exec(compile(export,'110_material_batches','exec'))
(OUT/'batches.json').write_text(json.dumps(stats,indent=2))
(OUT/'provenance.json').write_text(json.dumps({'source':'109 original pressure body; 110 compact continuous nozzle replaces rejected open rails','generator':'tools/build_bubble_110.py','originals_preserved':True},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'bubble_compact.blend'))
result={'geometry':report,'batches':stats}
