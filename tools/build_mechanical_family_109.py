"""Original hard-surface study. +Y forward, Z up. No reference meshes copied."""
import bpy, bmesh, math, json, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT', str(Path.cwd()))).resolve()
assert (ROOT/'project.godot').is_file(), 'Run from the project root or set TANK_PROJECT_ROOT'
OUT=ROOT/'assets/derived/mechanical-family-v2'
SRC=ROOT/'source_art/mechanical-family-v2'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
s=bpy.data.scenes.new('Mechanical_Family_109');bpy.context.window.scene=s
s.unit_settings.system='METRIC';s.render.engine='BLENDER_EEVEE'
s.render.resolution_x=1200;s.render.resolution_y=1000;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('109 studio');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.055,.085,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
def mat(name,c,r=.65,m=0):
 a=bpy.data.materials.new('109 '+name);a.diffuse_color=(*c,1);a.use_nodes=True
 p=a.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=(*c,1);p.inputs['Roughness'].default_value=r;p.inputs['Metallic'].default_value=m
 return a
white=mat('porcelain',(.78,.80,.79),.48,.05)
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
  active(o);m=o.modifiers.new('Edge radii','BEVEL');m.width=bevel;m.segments=1 if material==rubber else 3
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
 vs=[]
 for y,w,b,t in sections:
  c=min(.06,(t-b)*.27,w*.23)
  vs.extend((x+offset,y,z) for x,z in [(-w+c,b),(w-c,b),(w,b+c),(w,t-c),(w-c,t),(-w+c,t),(-w,t-c),(-w,b+c)])
 fs=[tuple(reversed(range(8))),tuple(range((len(sections)-1)*8,len(sections)*8))]
 for j in range(len(sections)-1):
  for i in range(8):fs.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
 return mesh(name,vs,fs,material,parent,bevel)
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

# Shared language, purpose-built silhouettes. Shells are authored to the current template.
parts=[]
def bearing(part):
 cyl('Thin rotation bearing',(0,-.055,.035),.38,.07,dark,part)
def rear(part):
 box('Flush rear service panel',(0,-.534,.28),(.54,.024,.25),white,part,.018)
 for x in [-.16,0,.16]:box('Rear vent',(x,-.547,.29),(.105,.002,.045),black,part,.001)
def roof(part,x=0,y=-.18):
 box('Roof hatch',(x,y,.555),(.26,.26,.04),dark,part,.018)
 box('Hatch grip',(x,y,.582),(.11,.03,.024),steel,part,.008)
def bore(part,x,z,outer,inner,start,end,n=48):
 lathe('Bore lining',[(start,outer),(end,outer),(end,inner),(start,inner)],black,part,(x,0,z),'Y',n)
 cyl('Bore recess',(x,start,z),inner,.012,black,part,'Y',n)
def optic(part,x,y,z):
 box('Optic bezel',(x,y,z),(.13,.08,.07),dark,part,.012)
 box('Optic glass',(x,y+.044,z),(.09,.012,.035),cyan,part,.006)

p=empty('autocannon');parts.append(p);bearing(p)
loft('Body',[(-.52,.30,.09,.40),(-.32,.38,.08,.51),(.24,.36,.10,.47),(.48,.26,.15,.35)],dark,p,bevel=.025)
for side in [-1,1]:
 loft('Swept side armor',[(-.50,.11,.14,.39),(-.30,.170,.11,.51),(.20,.170,.12,.46),(.49,.09,.16,.31)],white,p,offset=side*.345,bevel=.022)
 for y in [-.30,-.20,-.10]:box('Cooling recess',(side*.516,y,.29),(.006,.05,.10),black,p,.002)
 cyl('Gun trunnion',(side*.39,.29,.29),.09,.06,steel,p,'X',32)
 pivot=empty('RecoilPivot' if side<0 else 'RecoilPivotRight',p)
 x=side*.245
 cyl('Receiver sleeve',(x,.40,.30),.115,.25,white,pivot,'Y')
 lathe('Long cooling shroud',[(.40,.085),(.96,.085),(.98,.075),(.98,.047),(.40,.047)],dark,pivot,(x,0,.30),'Y')
 for y in [.54,.67,.80]:cyl('Cooling collar',(x,y,.30),.095,.035,steel,pivot,'Y')
 lathe('Muzzle cap',[(.96,.085),(1.02,.105),(1.14,.105),(1.16,.090),(1.16,.052),(.96,.052)],gold,pivot,(x,0,.30),'Y',32)
 bore(pivot,x,.30,.051,.043,1.00,1.159,32)
 empty('VisualMuzzle' if side<0 else 'VisualMuzzleRight',pivot,(x,1.16,.30))
roof(p);rear(p);optic(p,0,.30,.49)

p=empty('scatter');parts.append(p);bearing(p)
loft('Body',[(-.52,.32,.09,.43),(-.30,.43,.08,.52),(.55,.44,.10,.49),(.76,.32,.16,.39)],dark,p,bevel=.028)
for side in [-1,1]:
 loft('Thick wedge cheek',[(-.50,.10,.14,.40),(-.27,.170,.10,.52),(.43,.170,.11,.49),(.77,.11,.16,.36)],white,p,offset=side*.345,bevel=.024)
 for y in [-.27,-.16]:box('Side exhaust',(side*.516,y,.27),(.006,.055,.10),black,p,.002)
 cyl('Recoil bearing',(side*.32,.57,.30),.12,.08,steel,p,'X',32)
roof(p,y=-.22);rear(p);optic(p,-.19,.38,.51)
pivot=empty('RecoilPivot',p)
cyl('Short receiver',(0,.69,.30),.235,.24,dark,pivot,'Y')
lathe('Heavy short muzzle',[(.70,.23),(.82,.27),(1.09,.27),(1.12,.25),(1.12,.16),(.70,.16)],white,pivot,(0,0,.30),'Y',12)
lathe('Yellow muzzle rim',[(1.12,.25),(1.16,.235),(1.16,.171),(1.12,.171)],gold,pivot,(0,0,.30),'Y',12)
bore(pivot,0,.30,.159,.148,.86,1.159)
empty('VisualMuzzle',pivot,(0,1.16,.30))

p=empty('bubble_cannon');parts.append(p);bearing(p)
# A squat circular pressure vessel and an exposed open spray ring: no wedge cheeks.
lathe('Rounded pressure vessel',[(.075,.27),(.10,.37),(.18,.47),(.29,.49),(.40,.45),(.49,.35),(.54,.21),(.54,.015),(.075,.015)],white,p,loc=(0,-.058,0),n=64)
lathe('Equator gasket',[(.265,.487),(.285,.49),(.305,.487),(.305,.477),(.265,.477)],dark,p,loc=(0,-.058,0),n=64)
cyl('Circular pressure lid',(0,-.058,.548),.205,.028,dark,p,n=64)
cyl('Pressure lid glass',(0,-.058,.568),.16,.012,cyan,p,n=64)
cyl('Pressure lid center',(0,-.058,.584),.062,.020,gold,p,n=48)
for side in [-1,1]:
 cyl('Side pressure bezel',(side*.483,-.058,.29),.117,.056,dark,p,'X')
 cyl('Side pressure window',(side*.515,-.058,.29),.087,.008,cyan,p,'X')
 cyl('Window center',(side*.514,-.058,.29),.035,.010,gold,p,'X')
# Rear edge is the round vessel itself at -.548; no rectangular backpack.
pivot=empty('RecoilPivot',p)
lathe('Pump throat',[(.28,.13),(.52,.16),(.64,.14),(.64,.095),(.28,.095)],steel,pivot,(0,0,.30),'Y')
bore(pivot,0,.30,.094,.08,.37,.64)
# Thin exposed rails leave a visible air gap between pressure body and spray ring.
for angle in [0,math.pi/2,math.pi,math.pi*1.5]:
 x=.21*math.cos(angle);z=.30+.21*math.sin(angle)
 box('Spray ring support',(x,.79,z),(.045,.50,.045),dark,pivot,.012)
lathe('Open circular spray ring',[(.99,.255),(1.035,.285),(1.125,.285),(1.16,.255),(1.16,.218),(.99,.218)],white,pivot,(0,0,.30),'Y',64)
lathe('Cyan nozzle channel',[(1.125,.282),(1.145,.268),(1.145,.257),(1.125,.271)],cyan,pivot,(0,0,.30),'Y',64)
lathe('Inner yellow spray lip',[(1.142,.222),(1.16,.222),(1.16,.206),(1.142,.206)],gold,pivot,(0,0,.30),'Y',64)
empty('VisualMuzzle',pivot,(0,1.16,.30))

# Track hulls are authored in Blender; the existing Godot TrackRig supplies complete
# round wheels and circulating cleats at runtime, independent of these fixed shells.
for name,heavy in [('light_tracks',False),('heavy_tracks',True)]:
 p=empty(name);parts.append(p)
 loft('Closed lower hull',[(-.83,.40,.25,.59),(-.59,.53,.22,.65),(.55,.53,.22,.65),(.86,.40,.32,.55)],dark,p,bevel=.03)
 loft('Body',[(-.86,.43,.53,.72),(-.61,.56,.51,.84),(.40,.56,.51,.84),(.87,.43,.42,.67)],white,p,bevel=.035)
 loft('Front glacis',[(.35,.39,.71,.87),(.83,.36,.48,.69)],white,p,bevel=.025)
 cyl('Deck bearing',(0,-.055,.87),.39,.035,dark,p)
 for side in [-1,1]:
  x=side*.685
  loft('Track guard',[(-.88,.13,.53,.63),(-.68,.16,.68,.79),(.57,.16,.68,.79),(.88,.13,.51,.61)],white,p,offset=x,bevel=.025)
  if heavy:
   for y in [-.52,0,.52]:
    loft('Segmented side skirt',[(y-.21,.07,.40,.67),(y+.21,.07,.40,.67)],white,p,offset=side*.77,bevel=.02)
    box('Skirt seam',(side*.842,y,.53),(.008,.045,.14),dark,p,.003)
   box('Front reinforced bumper',(side*.28,.875,.41),(.45,.12,.15),dark,p,.025)
  else:
   box('Side suspension rail',(side*.54,0,.48),(.055,1.28,.09),steel,p,.015)
  for y in [-.52,.47]:handle('Tie down',side*.45,y,.85,p)
  box('Headlight bezel',(side*.34,.812,.66),(.14,.07,.10),dark,p,.015)
  box('Headlight lens',(side*.34,.853,.66),(.095,.012,.05),cyan,p,.012)
  box('Tail bezel',(side*.33,-.851,.64),(.14,.026,.075),dark,p,.012)
  box('Tail light',(side*.33,-.868,.64),(.095,.012,.035),red,p,.008)
  box('Rear cooling well',(side*.27,-.58,.836),(.25,.25,.02),dark,p,.015)
  for y in [-.66,-.60,-.54]:box('Cooling fin',(side*.27,y,.855),(.20,.016,.018),steel,p,.004)
 box('Flush rear plate',(0,-.86,.54),(.56,.04,.23),white,p,.018)
 for x in [-.17,0,.17]:box('Rear vent',(x,-.883,.56),(.105,.012,.08),black,p,.005)

# Retain editable separated construction in .blend, merge static material batches only
# for exports. Object/part transforms are identity; motion empties remain separate.
def audit(part):
 bpy.context.view_layer.update();points=[];tris=0;bad=[]
 for o in part.children_recursive:
  if o.type!='MESH':continue
  o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
  points.extend(o.matrix_world@v.co for v in o.data.vertices)
  bm=bmesh.new();bm.from_mesh(o.data)
  if any(not e.is_manifold for e in bm.edges):bad.append(o.name)
  bm.free()
 return {'triangles':tris,'bounds':[[min(p[i] for p in points),max(p[i] for p in points)] for i in range(3)],'nonmanifold_meshes':bad}
report={}
for part in parts:
 report[part.name]=audit(part)
 assert not report[part.name]['nonmanifold_meshes'],report[part.name]
 bpy.ops.object.select_all(action='DESELECT')
 for obj in [part]+list(part.children_recursive):obj.select_set(True)
 bpy.context.view_layer.objects.active=part
 bpy.ops.export_scene.gltf(filepath=str(OUT/(part.name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
(OUT/'provenance.json').write_text(json.dumps({'source':'Original Blender modeling based on approved 105 style and project handbook','tool':'tools/build_mechanical_family_109.py','external_meshes_copied':False,'runtime_tracks':'Existing validated Godot TrackRig; Blender exports authored fixed chassis shells'},indent=2),encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'mechanical_family.blend'))
result=report
