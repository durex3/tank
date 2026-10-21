"""Original hard-surface study. +Y forward, Z up. No reference meshes copied."""
import bpy, bmesh, math, json, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT', str(Path.cwd()))).resolve()
assert (ROOT/'project.godot').is_file(), 'Run from the project root or set TANK_PROJECT_ROOT'
OUT=ROOT/'assets/derived/soft-workshop-v2'
SRC=ROOT/'source_art/soft-workshop-v2'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
bpy.context.preferences.filepaths.save_version=0
s=bpy.data.scenes.new('Soft_Workshop_134');bpy.context.window.scene=s
s.unit_settings.system='METRIC';s.render.engine='BLENDER_EEVEE'
s.render.resolution_x=1200;s.render.resolution_y=1000;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('134 studio');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.055,.085,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
def mat(name,c,r=.65,m=0):
 a=bpy.data.materials.new('134 '+name);a.diffuse_color=(*c,1);a.use_nodes=True
 p=a.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=r;p.inputs['Metallic'].default_value=m
 return a
white=mat('ivory armor',(.65,.66,.62),.60,.02)
dark=mat('mechanism',(.035,.047,.059),.55,.15)
rubber=mat('rubber',(.013,.019,.025),.83)
black=mat('recess',(.006,.009,.012),.8)
gold=mat('yellow',(.95,.62,.025),.43,.12)
steel=mat('steel',(.21,.26,.29),.42,.4)
cyan=mat('headlight',(.05,.75,.85),.3)
red=mat('tail light',(.62,.025,.013),.4)
def empty(name,parent=None,loc=(0,0,0)):
 o=bpy.data.objects.new(name,None);s.collection.objects.link(o);o.parent=parent;o.location=loc;return o
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def finish(o,material,parent,bevel=0,smooth=False):
 o.data.materials.append(material);o.parent=parent
 if bevel:
  active(o);m=o.modifiers.new('Edge radii','BEVEL');m.width=bevel;m.segments=2 if material==rubber else 5
  bpy.ops.object.modifier_apply(modifier=m.name)
 for p in o.data.polygons:p.use_smooth=smooth or bool(bevel)
 if bevel:
  m=o.modifiers.new('Weighted planar normals','WEIGHTED_NORMAL');m.keep_sharp=True;m.weight=40
  bpy.ops.object.modifier_apply(modifier=m.name)
 return o
def mesh(name,vs,fs,material,parent,bevel=0,smooth=False):
 d=bpy.data.meshes.new(name);d.from_pydata(vs,[],fs);d.update()
 bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
 o=bpy.data.objects.new(name,d);s.collection.objects.link(o);return finish(o,material,parent,bevel,smooth)
def box(name,loc,size,material,parent,bevel=.018,rot=(0,0,0)):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
 active(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.rotation_euler=rot
 return finish(o,material,parent,bevel)
def cyl(name,loc,r,depth,material,parent,axis='Z',n=48):
 bpy.ops.mesh.primitive_cylinder_add(vertices=n,radius=r,depth=depth,location=loc)
 o=bpy.context.object;o.name=name
 if axis=='X':o.rotation_euler.y=math.pi/2
 if axis=='Y':o.rotation_euler.x=math.pi/2
 finish(o,material,parent)
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 return o
def loft(name,sections,material,parent,offset=0,bevel=.022):
 vs=[];stride=16
 for y,w,b,t in sections:
  c=min(.09,(t-b)*.34,w*.28)
  for cx,cz,start in [(w-c,b+c,-90),(w-c,t-c,0),(-w+c,t-c,90),(-w+c,b+c,180)]:
   for step in range(4):
    angle=math.radians(start+step*30)
    vs.append((cx+math.cos(angle)*c+offset,y,cz+math.sin(angle)*c))
 fs=[tuple(reversed(range(stride))),tuple(range((len(sections)-1)*stride,len(sections)*stride))]
 for j in range(len(sections)-1):
  for i in range(stride):fs.append((j*stride+i,j*stride+(i+1)%stride,(j+1)*stride+(i+1)%stride,(j+1)*stride+i))
 return mesh(name,vs,fs,material,parent,min(bevel,.028))
def lathe(name,profile,material,parent,loc=(0,0,0),axis='Z',n=48):
 vs=[]
 for a,r in profile:
  for i in range(n):
   u,v=r*math.cos(i*math.tau/n),r*math.sin(i*math.tau/n)
   p=(a,u,v) if axis=='X' else ((u,a,v) if axis=='Y' else (u,v,a))
   vs.append(tuple(p[j]+loc[j] for j in range(3)))
 fs=[]
 for j in range(len(profile)):
  for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,((j+1)%len(profile))*n+(i+1)%n,((j+1)%len(profile))*n+i))
 return mesh(name,vs,fs,material,parent,smooth=True)
def handle(name,x,y,z,parent):
 for side in [-1,1]:box(name+' foot',(x+side*.035,y,z+.027),(.016,.022,.055),gold,parent,.007)
 box(name+' grip',(x,y,z+.05),(.08,.022,.018),gold,parent,.008)

# Original simplified continuous armor, authored directly to the existing metre template.
turret=empty('cannon')
cyl('Low bearing',(0,-.05,.035),.37,.07,dark,turret)
loft('Dark lower cradle',[(-.54,.31,.08,.23),(-.30,.48,.07,.27),(.22,.44,.08,.25),(.46,.27,.13,.24)],dark,turret,bevel=.018)
loft('Continuous rounded armor',[(-.548,.32,.20,.40),(-.34,.49,.18,.54),(.10,.519,.19,.52),(.34,.40,.19,.46),(.48,.29,.20,.37)],white,turret,bevel=.025)
# One quiet roof panel instead of several overlapping strips and lifting handles.
box('Roof service inset',(0,-.20,.547),(.33,.31,.045),dark,turret,.025)
box('Single roof lid',(0,-.20,.571),(.29,.27,.046),white,turret,.025)
for side in [-1,1]:
 box('Side mechanical inset',(side*.480,-.16,.31),(.018,.25,.085),dark,turret,.012)
 box('Broad side vent',(side*.491,-.16,.31),(.010,.18,.022),black,turret,.006)
 cyl('Trunnion',(side*.28,.24,.275),.105,.055,steel,turret,'X',32)
box('Recessed optic',(0,.20,.50),(.15,.085,.06),dark,turret,.018)
box('Optic glass',(0,.245,.50),(.095,.012,.024),cyan,turret,.006)
pivot=empty('RecoilPivot',turret)
cyl('Integrated mantlet',(0,.39,.275),.19,.24,white,pivot,'Y',48)
lathe('Barrel',[(.42,.105),(.94,.105),(.96,.09),(.96,.063),(.42,.063)],dark,pivot,(0,0,.275),'Y',48)
cyl('Single barrel collar',(0,.77,.275),.115,.05,steel,pivot,'Y',48)
lathe('Rounded muzzle shroud',[(.91,.105),(.96,.155),(1.12,.155),(1.16,.135),(1.16,.083),(.91,.083)],white,pivot,(0,0,.275),'Y',48)
lathe('Recessed yellow muzzle lip',[(1.11,.154),(1.14,.154),(1.16,.135),(1.16,.084),(1.11,.084)],gold,pivot,(0,0,.275),'Y',48)
lathe('Deep bore',[(.97,.082),(1.159,.082),(1.159,.068),(.97,.068)],black,pivot,(0,0,.275),'Y',48)
cyl('Bore end',(0,.98,.275),.067,.01,black,pivot,'Y',32)
empty('VisualMuzzle',pivot,(0,1.16,.275))

hull=empty('light_tracks')
loft('Lower dark chassis',[(-.84,.40,.25,.57),(-.60,.52,.22,.65),(.53,.52,.22,.65),(.88,.40,.32,.54)],dark,hull,bevel=.04)
loft('Continuous upper deck',[(-.88,.44,.54,.73),(-.59,.57,.52,.84),(.35,.57,.52,.84),(.89,.43,.43,.65)],white,hull,bevel=.045)
loft('Broad sloped nose',[(.32,.40,.72,.86),(.86,.37,.48,.66)],white,hull,bevel=.035)
for side in [-1,1]:
 loft('Rounded track cover',[(-.89,.12,.52,.63),(-.66,.16,.68,.79),(.57,.16,.68,.79),(.89,.12,.51,.61)],white,hull,offset=side*.685,bevel=.04)
 box('Headlamp pocket',(side*.34,.82,.65),(.17,.07,.11),dark,hull,.022)
 box('Small green lamp',(side*.34,.860,.65),(.075,.012,.045),cyan,hull,.012)
 box('Rear lamp',(side*.33,-.875,.65),(.10,.012,.04),red,hull,.01)
 box('Recessed rear radiator',(side*.27,-.60,.837),(.26,.25,.018),dark,hull,.022)
 for y in [-.65,-.55]:box('Broad radiator louvre',(side*.27,y,.85),(.18,.020,.012),steel,hull,.004)
box('Front grille well',(0,.875,.59),(.29,.025,.11),black,hull,.018)
for x in [-.08,0,.08]:box('Three readable grille bars',(x,.893,.59),(.017,.012,.07),steel,hull,.004)
box('Inset front bumper',(0,.87,.40),(.76,.09,.12),dark,hull,.032)
cyl('Flush deck bearing',(0,-.055,.885),.38,.048,dark,hull)

shell=bpy.data.objects['Continuous rounded armor']
maximum=max(abs(v.co.x) for v in shell.data.vertices)
for v in shell.data.vertices:v.co.x*=.519/maximum

# Real shallow side recesses: details must not be buried behind the continuous outer shell.
for side in [-1,1]:
 cutter=box('Temporary side pocket',(side*.522,-.16,.31),(.10,.27,.10),black,None,.014)
 active(shell);modifier=shell.modifiers.new('Inset side pocket','BOOLEAN');modifier.operation='DIFFERENCE';modifier.object=cutter
 bpy.ops.object.modifier_apply(modifier=modifier.name)
 bpy.data.objects.remove(cutter,do_unlink=True)
active(shell);normal=shell.modifiers.new('Final planar normals','WEIGHTED_NORMAL');normal.keep_sharp=True
bpy.ops.object.modifier_apply(modifier=normal.name)

# Bake original local occlusion into vertex colors, independent from scene lighting.
from mathutils.bvhtree import BVHTree
from mathutils import Vector
parts=[turret,hull]
for part in parts:
 bpy.context.view_layer.update()
 objects=[o for o in part.children_recursive if o.type=='MESH']
 vertices=[];faces=[]
 for o in objects:
  base=len(vertices);vertices.extend(o.matrix_world@v.co for v in o.data.vertices)
  faces.extend(tuple(base+i for i in face.vertices) for face in o.data.polygons)
 tree=BVHTree.FromPolygons(vertices,faces)
 for o in objects:
  colors=o.data.color_attributes.new(name='SoftAO',type='FLOAT_COLOR',domain='CORNER')
  o.data.color_attributes.active_color=colors
  cached={}
  for loop in o.data.loops:
   key=loop.vertex_index
   if key not in cached:
    v=o.data.vertices[key];p=o.matrix_world@v.co;n=(o.matrix_world.to_3x3()@v.normal).normalized()
    up=Vector((0,0,1)) if abs(n.z)<.95 else Vector((0,1,0));t=n.cross(up).normalized();b=n.cross(t)
    blocked=0
    for i in range(24):
     z=(i+.5)/24;r=math.sqrt(1-z*z);angle=i*2.399963
     direction=(n*z+t*(r*math.cos(angle))+b*(r*math.sin(angle))).normalized()
     hit=tree.ray_cast(p+n*.008,direction,.45)
     if hit[0] is not None:blocked+=1
    cached[key]=1-.45*blocked/24
   value=cached[key];colors.data[loop.index].color=(value,value,value,1)
# Save editable source before material batching; no prior source is overwritten.
turret.location=(0,0,.885)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'soft_workshop.blend'))
turret.location=(0,0,0)
report={}
for part in parts:
 groups={}
 for o in list(part.children_recursive):
  if o.type=='MESH':groups.setdefault((o.parent,o.active_material),[]).append(o)
 for (parent,material),group in groups.items():
  active(group[0])
  for o in group:o.select_set(True)
  if len(group)>1:bpy.ops.object.join()
  group[0].name='Soft_'+material.name
 active(part)
 for o in part.children_recursive:o.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(OUT/(part.name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False,export_vertex_color='ACTIVE',export_all_vertex_colors=True)
 report[part.name]={'construction_material_batches':len(groups),'source':'Original Blender geometry and baked local AO','track_system':'Existing TrackRig, not recreated in Blender' if part==hull else 'Existing recoil/visual muzzle contract'}
(OUT/'provenance.json').write_text(json.dumps({'tool':'tools/build_soft_workshop_134.py','reference':'MiniTanks resources inspected read-only for shape and shading principles; no mesh, shader, or texture copied','parts':report},indent=2))
