"""Finish the current authored family; export copies batched per material/motion owner."""
import bpy, json, os
from pathlib import Path
from mathutils import Matrix
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT',str(Path.cwd())))
OUT=ROOT/'assets/derived/mechanical-family-v2'
scene=bpy.data.scenes['Mechanical_Family_109'];bpy.context.window.scene=scene
parts=[scene.objects[n] for n in ['autocannon','scatter','bubble_cannon','light_tracks','heavy_tracks']]
# Thin recess objects reach the common width; armor is slightly inset, avoiding coplanar faces.
for obj in scene.objects:
 if obj.type=='MESH' and any(obj.name.startswith(n) for n in ['Swept side armor','Thick wedge cheek','Rounded shoulder armor']) and not obj.get('recess_clearance_109') and max(abs(v.co.x) for v in obj.data.vertices)>.516:
  center=.345 if sum(v.co.x for v in obj.data.vertices)>0 else -.345
  for v in obj.data.vertices:v.co.x=center+(v.co.x-center)*(.170/.174)
  obj['recess_clearance_109']=True
stats={}
for part in parts:
 export_scene=bpy.data.scenes.new('109_export_'+part.name)
 bpy.context.window.scene=export_scene
 mapping={}
 for original in [part]+list(part.children_recursive):
  clone=original.copy()
  if original.type=='MESH':clone.data=original.data.copy()
  export_scene.collection.objects.link(clone);mapping[original]=clone
 for original,clone in mapping.items():clone.parent=mapping.get(original.parent)
 mapping[part].location=(0,0,0)
 groups={}
 for clone in mapping.values():
  if clone.type=='MESH':groups.setdefault((clone.parent,clone.active_material),[]).append(clone)
 for (parent,material),group in groups.items():
  bpy.ops.object.select_all(action='DESELECT')
  for obj in group:obj.select_set(True)
  bpy.context.view_layer.objects.active=group[0]
  if len(group)>1:bpy.ops.object.join()
  group[0].name='Batch_'+material.name
 stats[part.name]={'render_meshes':len(groups),'construction_meshes':sum(o.type=='MESH' for o in part.children_recursive)}
 bpy.ops.object.select_all(action='SELECT')
 bpy.ops.export_scene.gltf(filepath=str(OUT/(part.name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
 # These are only this function's temporary export copies; keep all construction originals.
 for obj in list(export_scene.objects):bpy.data.objects.remove(obj,do_unlink=True)
 bpy.context.window.scene=scene;bpy.data.scenes.remove(export_scene)
# Lay out authored modules without overlap in the editable source.
for part,loc in zip(parts,[(-2.5,0,.885),(0,0,.885),(2.5,0,.885),(-1.4,-3,0),(1.4,-3,0)]):part.location=loc
(OUT/'batches.json').write_text(json.dumps(stats,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_art/mechanical-family-v2/mechanical_family.blend'))
result=stats
