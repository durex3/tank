"""Original hard-surface study. +Y forward, Z up. No reference meshes copied."""
import bpy, bmesh, math, json, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT', str(Path.cwd()))).resolve()
assert (ROOT/'project.godot').is_file(), 'Run from the project root or set TANK_PROJECT_ROOT'
OUT=ROOT/'assets/derived/mechanical-sample-v1'
SRC=ROOT/'source_art/mechanical-sample-v1'
OUT.mkdir(parents=True,exist_ok=True);SRC.mkdir(parents=True,exist_ok=True)
s=bpy.data.scenes.new('Mechanical_105');bpy.context.window.scene=s
s.unit_settings.system='METRIC';s.render.engine='BLENDER_EEVEE'
s.render.resolution_x=1200;s.render.resolution_y=1000;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('105 studio');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.065,.055,.085,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
def mat(name,c,r=.65,m=0):
 a=bpy.data.materials.new('105 '+name);a.diffuse_color=(*c,1);a.use_nodes=True
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

hull=empty('scout_wheels')
loft('Lower monocoque',[(-.83,.43,.28,.61),(-.60,.52,.23,.68),(.59,.52,.23,.68),(.88,.40,.36,.56)],dark,hull,.0,.035)
loft('Main armored deck',[(-.82,.43,.57,.76),(-.57,.55,.56,.86),(.40,.55,.56,.86),(.84,.43,.50,.67)],white,hull,bevel=.035)
# Sloped nose panel and physically distinct rear closure.
loft('Front glacis',[(.39,.37,.73,.88),(.78,.35,.56,.70)],white,hull,bevel=.022)
box('Front bumper',(0,.855,.41),(.77,.12,.14),dark,hull,.035)
box('Front intake',(0,.868,.58),(.28,.035,.10),black,hull,.014)
for x in [-.095,-.048,0,.048,.095]:box('Intake louvre',(x,.89,.58),(.012,.012,.076),steel,hull,.003)
for side in [-1,1]:
 box('Headlight bezel',(side*.35,.80,.65),(.14,.07,.10),dark,hull,.025)
 box('Headlight lens',(side*.35,.841,.65),(.095,.014,.055),cyan,hull,.016)
 box('Rear light bezel',(side*.34,-.814,.66),(.15,.035,.085),dark,hull,.014)
 box('Tail lamp',(side*.34,-.837,.66),(.10,.014,.035),red,hull,.008)
 box('Rear bumper',(side*.29,-.85,.37),(.42,.10,.11),dark,hull,.025)
 for y in [-.20,-.10,0,.10,.20]:box('Side vertical vent',(side*.552,y,.69),(.014,.032,.12),black,hull,.009)
 for end in [-1,1]:
  cy=end*.55;cx=side*.63
  loft('Fender',[(cy-.39,.185,.62,.69),(cy-.25,.195,.77,.85),(cy+.25,.195,.77,.85),(cy+.39,.185,.62,.69)],white,hull,offset=cx,bevel=.025)
  handle('Tie down',side*.47,cy,.85,hull)
  wheel=empty('Wheel'+('Left' if side<0 else 'Right')+('Front' if end>0 else 'Rear'),hull,(cx,cy,.40))
  lathe('Tire',[(-.18,.25),(-.18,.33),(-.13,.385),(.13,.385),(.18,.33),(.18,.25)],rubber,wheel,axis='X')
  for i in range(24):
   a=i*math.tau/24
   for row in [-1,1]:
    o=box('Tread',(row*.077,.387*math.sin(a),.387*math.cos(a)),(.135,.082,.030),rubber,wheel,.008,rot=(-a,0,row*.13))
  face=side*.183
  cyl('Rim backing',(face,0,0),.278,.016,dark,wheel,'X')
  lathe('Yellow rim',[(-.012,.24),(-.012,.276),(.012,.276),(.012,.24)],gold,wheel,(face+side*.012,0,0),'X')
  cyl('Flat wheel cover',(face+side*.020,0,0),.237,.025,white,wheel,'X')
  box('Wheel slot',(face+side*.035,0,0),(.008,.12,.022),black,wheel,.008)
  for z in [-.16,.16]:cyl('Wheel screw',(face+side*.035,0,z),.013,.008,steel,wheel,'X',16)
cyl('Turret deck bearing',(0,-.06,.87),.39,.035,dark,hull)
for x in [-.27,.27]:
 box('Rear deck inset',(x,-.57,.846),(.24,.24,.015),dark,hull,.018)
 for y in [-.64,-.59,-.54]:box('Cooling fin',(x,y,.86),(.19,.014,.015),steel,hull,.003)
empty('TurretSocket',hull,(0,0,.76))

turret=empty('cannon')
cyl('Thin rotation bearing',(0,-.06,.035),.38,.07,dark,turret)
loft('Central housing',[(-.52,.32,.08,.37),(-.35,.39,.08,.49),(.23,.37,.08,.46),(.43,.26,.12,.31)],dark,turret,bevel=.032)
for side in [-1,1]:
 loft('Cheek armor',[(-.50,.13,.13,.36),(-.31,.17,.12,.51),(.18,.17,.11,.44),(.49,.10,.13,.27)],white,turret,offset=side*.345,bevel=.025)
 # Sloped roof strips and rear cooling vents with intentional quiet areas.
 box('Rear shoulder pad',(side*.33,-.28,.506),(.22,.23,.026),white,turret,.018)
 for y in [-.36,-.28,-.20]:box('Side cooling slot',(side*.513,y,.29),(.012,.045,.095),black,turret,.008)
 handle('Turret lifting eye',side*.30,-.33,.535,turret)
 cyl('Trunnion',(side*.24,.23,.27),.10,.045,steel,turret,'X',32)
loft('Roof spine',[(-.36,.16,.39,.52),(.12,.19,.35,.50),(.30,.13,.26,.37)],white,turret,bevel=.025)
box('Roof hatch',(0,-.18,.534),(.25,.26,.028),dark,turret,.032)
box('Hatch handle',(0,-.19,.562),(.10,.027,.028),steel,turret,.008)
box('Optic housing',(0,.09,.50),(.16,.11,.09),dark,turret,.016)
box('Optic lens',(0,.15,.51),(.10,.015,.035),cyan,turret,.006)
box('Rear service panel',(0,-.526,.25),(.34,.028,.18),white,turret,.025)
for x in [-.10,0,.10]:box('Rear horizontal vent',(x,-.543,.26),(.065,.010,.025),black,turret,.006)
pivot=empty('RecoilPivot',turret)
cyl('Barrel collar',(0,.38,.275),.14,.22,white,pivot,'Y')
lathe('Barrel',[(.40,.105),(.91,.105),(.94,.09),(.94,.065),(.40,.065)],dark,pivot,loc=(0,0,.275),axis='Y')
for y in [.49,.78]:cyl('Barrel band',(0,y,.275),.113,.032,steel,pivot,'Y')
lathe('Muzzle armor',[(.91,.10),(.95,.145),(1.13,.145),(1.15,.13),(1.15,.079),(.91,.079)],white,pivot,loc=(0,0,.275),axis='Y',n=8)
lathe('Yellow muzzle lip',[(1.12,.145),(1.16,.145),(1.16,.081),(1.12,.081)],gold,pivot,loc=(0,0,.275),axis='Y',n=8)
lathe('Dark bore lining',[(.995,.078),(1.155,.078),(1.155,.069),(.995,.069)],black,pivot,loc=(0,0,.275),axis='Y',n=32)
cyl('Dark bore end',(0,1.00,.275),.067,.01,black,pivot,'Y')
empty('VisualMuzzle',pivot,(0,1.16,.275));empty('Muzzle',turret,(0,1.05,.02))

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
for part in [turret,hull]:
 report[part.name]=audit(part)
 bpy.ops.object.select_all(action='DESELECT')
 for o in [part]+list(part.children_recursive):o.select_set(True)
 bpy.context.view_layer.objects.active=part
 bpy.ops.export_scene.gltf(filepath=str(OUT/(part.name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
report['status']='Standalone proportion study, not production size contract acceptance'
report['source']='Original Blender geometry; MiniTanks models inspected read-only, no mesh or texture copied'
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
# Compose only for preview. Exported turret remains in its independent local coordinates.
turret.location=(0,0,.885)
ground=mat('studio floor',(.045,.04,.065),.85)
box('Studio floor',(0,0,-.055),(200,200,.1),ground,None,0)
def aim(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
for loc,power,size in [((-3,4,6),550,4),((4,2,3),350,4),((1,-4,5),650,3)]:
 d=bpy.data.lights.new('Softbox','AREA');d.energy=power;d.shape='DISK';d.size=size
 o=bpy.data.objects.new('Softbox',d);s.collection.objects.link(o);o.location=loc;aim(o,(0,0,.6))
d=bpy.data.cameras.new('Inspection camera');camera=bpy.data.objects.new('Inspection camera',d);s.collection.objects.link(camera);s.camera=camera;d.type='ORTHO';d.ortho_scale=3.3
for name,loc in [('front',(-3,4,2.8)),('rear',(3,-4,2.6)),('side',(-4,0,1.4))]:
 camera.location=loc;aim(camera,(0,.05,.70));s.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'mechanical_sample.blend'))
result=report
