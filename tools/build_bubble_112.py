"""Low armored bubble turret, following the user-approved silhouette."""
import os, json
from pathlib import Path
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT',str(Path.cwd())))
source=(ROOT/'tools/build_mechanical_family_109.py').read_text()
prefix=source[:source.index("p=empty('autocannon')")]
prefix=prefix.replace('mechanical-family-v2','bubble-armored-v1').replace('Mechanical_Family_109','Bubble_Armored_112')
exec(compile(prefix,'109_helpers','exec'))
p=empty('bubble_cannon_112');parts.append(p);bearing(p)
# Broad low rear housing, narrowing to an integrated front pump; no round vessel.
loft('Low pressure housing',[(-.52,.34,.09,.36),(-.30,.46,.075,.45),(.28,.45,.075,.46),(.70,.32,.10,.44),(.98,.26,.12,.42)],dark,p,bevel=.035)
for side in [-1,1]:
 loft('Continuous shoulder armor',[(-.50,.11,.14,.35),(-.28,.17,.10,.46),(.25,.16,.10,.47),(.68,.10,.13,.43),(.99,.055,.15,.40)],white,p,offset=side*.345,bevel=.035)
 box('Pressure indicator surround',(side*.508,-.10,.29),(.014,.32,.10),dark,p,.012)
 box('Pressure indicator strip',(side*.516,-.10,.29),(.006,.24,.035),cyan,p,.006)
 for y in [.16,.24]:box('Side pump vent',(side*.493,y,.25),(.012,.035,.065),black,p,.004)
# Low raised maintenance hatch, rather than a high pedestal under the whole turret.
loft('Top service hatch',[(-.34,.20,.44,.50),(-.20,.23,.45,.54),(.11,.23,.45,.54),(.25,.18,.44,.49)],white,p,bevel=.022)
box('Top pressure readout',(0,-.02,.555),(.22,.16,.03),dark,p,.012)
box('Top cyan readout',(0,-.015,.573),(.16,.10,.006),cyan,p,.003)
box('Service release handle',(0,-.23,.582),(.13,.035,.024),gold,p,.008)
rear(p)
pivot=empty('RecoilPivot',p)
# The short circular outlet is recessed into the armored nose, not on a long neck.
lathe('Integrated nozzle surround',[(.78,.215),(.96,.25),(1.08,.25),(1.16,.225),(1.16,.17),(1.10,.16),(.78,.16)],white,pivot,(0,0,.285),'Y',64)
lathe('Recessed cyan outlet',[(1.115,.169),(1.15,.169),(1.15,.145),(1.115,.145)],cyan,pivot,(0,0,.285),'Y',64)
bore(pivot,0,.285,.144,.13,.91,1.14,64)
empty('VisualMuzzle',pivot,(0,1.16,.285))
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
(OUT/'provenance.json').write_text(json.dumps({'source':'112 user-selected low armored housing with inset circular outlet; original procedural Blender geometry','generator':'tools/build_bubble_112.py','originals_preserved':True},indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'bubble_armored.blend'))
result={'geometry':report,'batches':stats}
