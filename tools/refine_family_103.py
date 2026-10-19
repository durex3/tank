"""Blender derivation from immutable Hyper3D inputs. Meters, +Y front, Z up."""
import bpy, bmesh, math, json, hashlib
from pathlib import Path
from mathutils import Vector, Matrix
ROOT=Path('E:/Godot_v4.7.2-stable_win64/game/tank')
OUT=ROOT/'assets/derived/family-refined-v2';OUT.mkdir(parents=True,exist_ok=True)
scene=bpy.data.scenes.new('Family_103_Refined');bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'

def activate(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def material(name,color,rough=.72):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 b=m.node_tree.nodes['Principled BSDF'];b.inputs['Base Color'].default_value=m.diffuse_color;b.inputs['Roughness'].default_value=rough
 return m
white=material('103 Porcelain',(.81,.83,.82));dark=material('103 Charcoal',(.026,.034,.042));gold=material('103 Warm Yellow',(.8,.49,.025),.5)
def empty(name,parent=None,loc=(0,0,0)):
 o=bpy.data.objects.new(name,None);scene.collection.objects.link(o);o.parent=parent;o.location=loc;return o
def box(name,loc,size,mat,parent,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size
 activate(o);bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(mat);o.parent=parent
 if bevel>0:
  mod=o.modifiers.new('Manufactured bevel','BEVEL');mod.width=bevel;mod.segments=2
  bpy.ops.object.modifier_apply(modifier=mod.name)
  mod=o.modifiers.new('Weighted corner normals','WEIGHTED_NORMAL');mod.keep_sharp=True;bpy.ops.object.modifier_apply(modifier=mod.name)
 return o
def cylinder(name,radius,depth,loc,parent,mat=dark,axis='Z',vertices=48):
 bpy.ops.mesh.primitive_cylinder_add(vertices=vertices,radius=radius,depth=depth,location=loc)
 o=bpy.context.object;o.name=name;o.parent=parent;o.data.materials.append(mat)
 if axis=='Y':o.rotation_euler.x=math.pi/2
 elif axis=='X':o.rotation_euler.y=math.pi/2
 for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
 return o
def read(name):
 before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/imported/family-refined-v2'/(name+'.glb')))
 o=next(o for o in set(scene.objects)-before if o.type=='MESH');activate(o)
 bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001);bm.to_mesh(o.data);bm.free()
 return o
def bbox(o):
 ps=[v.co for v in o.data.vertices];return Vector([min(p[i] for p in ps) for i in range(3)]),Vector([max(p[i] for p in ps) for i in range(3)])
def seal(o):
 bm=bmesh.new();bm.from_mesh(o.data);idx=len(o.data.materials);o.data.materials.append(dark)
 es=[e for e in bm.edges if e.is_boundary]
 if es:
  for f in bmesh.ops.holes_fill(bm,edges=es,sides=0)['faces']:f.material_index=idx
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.normal_update()
 for f in bm.faces:f.smooth=True
 for e in bm.edges:
  if len(e.link_faces)==2:e.smooth=e.calc_face_angle(0)<math.radians(45)
 bm.to_mesh(o.data);bm.free()
def section(o,name,predicate):
 n=o.copy();n.data=o.data.copy();n.name=name;scene.collection.objects.link(n)
 bm=bmesh.new();bm.from_mesh(n.data)
 bmesh.ops.delete(bm,geom=[f for f in bm.faces if not predicate(f.calc_center_median())],context='FACES')
 bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS');bm.to_mesh(n.data);bm.free();seal(n);return n
def boolean_remove(o,cutter):
 activate(o);m=o.modifiers.new('Mechanical clearance','BOOLEAN');m.operation='DIFFERENCE';m.solver='EXACT';m.object=cutter
 bpy.ops.object.modifier_apply(modifier=m.name);bpy.data.objects.remove(cutter,do_unlink=True)
def save(part,name):
 bpy.context.view_layer.update();ps=[];tris=0;qa={}
 for o in part.children_recursive:
  if o.type!='MESH':continue
  # Source split normals are in the pre-bake orientation. Recompute after vertex edits.
  o.data.normals_split_custom_set([(0.0,0.0,0.0)]*len(o.data.loops))
  o.data.update()
  o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles);ps.extend(o.matrix_world@v.co for v in o.data.vertices)
  bm=bmesh.new();bm.from_mesh(o.data);qa[o.name]={'boundary':sum(e.is_boundary for e in bm.edges),'nonmanifold':sum(not e.is_manifold for e in bm.edges)};bm.free()
 bpy.ops.object.select_all(action='DESELECT')
 for o in [part]+list(part.children_recursive):o.select_set(True)
 bpy.context.view_layer.objects.active=part
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
 return {'triangles':tris,'bounds':[[min(p[i] for p in ps),max(p[i] for p in ps)] for i in range(3)],'meshes':qa}

report={}
# Source barrel/housing intersections inspected in orthographic renders.
for name,cut in [('cannon',-.20),('scatter',-.60),('bubble_cannon',-.79)]:
 src=read(name);lo,hi=bbox(src);part=empty(name)
 bm=bmesh.new();bm.from_mesh(src.data);bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,plane_co=(0,cut,0),plane_no=(0,1,0));bm.to_mesh(src.data);bm.free()
 body=section(src,'Body',lambda p:p.y>=cut-1e-6);barrel=section(src,'Barrel',lambda p:p.y<cut-1e-6)
 scale=1.0296/(hi.x-lo.x)
 # The main gun keeps the shell aspect ratio, shortening only its sliding barrel.
 length=(hi.y-lo.y)*scale
 extension=1.7476878-length
 rear=-.6102236
 top=1.0027276
 for obj in (body,barrel):
  for v in obj.data.vertices:
   p=v.co.copy();v.co=Vector((-(p.x-(lo.x+hi.x)/2)*scale, rear+(hi.y-p.y)*scale,top+(p.z-hi.z)*scale))
 body.parent=part
 pivot=empty('RecoilPivot',part);barrel.parent=pivot
 joint=rear+(hi.y-cut)*scale
 blo,bhi=bbox(barrel);axis_x=(blo.x+bhi.x)/2;axis_z=(blo.z+bhi.z)/2
 if extension<0:
  # Compress only axial barrel length; circular cross-sections remain unchanged.
  factor=(bhi.y-joint+extension)/(bhi.y-joint)
  for v in barrel.data.vertices:v.co.y=joint+(v.co.y-joint)*factor
 else:
  for v in barrel.data.vertices:v.co.y+=extension
  radius=min(bhi.x-blo.x,bhi.z-blo.z)*.39
  cylinder('RecoilSleeve',radius,extension+.13,(axis_x,joint+extension/2-.025,axis_z),pivot,dark,'Y')
 empty('VisualMuzzle',pivot,(axis_x,1.1374642,axis_z))
 lowest=min(v.co.z for v in body.data.vertices)
 if lowest>.12:
  height=lowest-.12+.035
  cylinder('ArmoredMount',.43,height,(0,0,.12+height/2),part,white,vertices=12)
  cylinder('MountBearing',.40,.045,(0,0,.1425),part,dark)
 bpy.data.objects.remove(src,do_unlink=True)
 report[name]=save(part,name)

for name,inner_x,cut_z in [('light_tracks',.455,.17),('heavy_tracks',.40,.155)]:
 src=read(name);part=empty(name);src.name='Body';src.parent=part
 # Remove generated belt/wheel mass; the shipped rigid TrackRig rebuilds round wheels.
 for side in (-1,1):
  cut=box('temporary belt removal',(side*(inner_x+1),0,cut_z-1),(2,4,2),dark,None,0)
  boolean_remove(src,cut)
 if name=='light_tracks':
  # Delete the user's rejected rear backpack, retain a flush rear closure.
  cut=box('temporary backpack removal',(0,1.25,.20),(.60,1.0,1.4),dark,None,0)
  boolean_remove(src,cut)
 lo,hi=bbox(src);scale=1.58/(hi.x-lo.x)
 for v in src.data.vertices:
  p=v.co.copy();v.co=Vector((-(p.x-(lo.x+hi.x)/2)*scale, -(p.y-(lo.y+hi.y)/2)*min(scale,1.80/(hi.y-lo.y)),.9923022+(p.z-hi.z)*scale))
 seal(src)
 if name=='light_tracks':
  box('FlushRearArmor',(0,-.76,.68),(.50,.10,.27),white,part,.035)
  for x in [-.14,0,.14]:box('RearVent',(x,-.816,.68),(.075,.016,.11),dark,part,.008)
 # Dark closed undercarriage prevents seeing through between road wheels.
 box('ClosedUndercarriage',(0,0,.42),(1.10,1.40,.30),dark,part,.04)
 report[name]=save(part,name)

# Higher-quality regenerated scout armor. Reuse already round complete Hyper3D tires.
src=read('scout_wheels');part=empty('scout_wheels');src.name='Body';src.parent=part
for side in (-1,1):
 for end in (-1,1):
  cut=cylinder('temporary tire clearance',.433,.65,(side*.68,end*.52,-.09),None,dark,'X',64)
  boolean_remove(src,cut)
for v in src.data.vertices:
 p=v.co.copy();v.co=Vector((-p.x,-p.y,.4912951+p.z))
cut=box('temporary mirrored rear face removal',(0,-1.10,.38),(.96,1.0,.92),dark,None,0)
boolean_remove(src,cut)
seal(src)
box('DistinctRearArmor',(0,-.75,.60),(.92,.34,.48),white,part,.045)
box('RearInsetGrille',(0,-.924,.59),(.43,.018,.15),dark,part,.012)
red=material('103 Tail Lamp',(.45,.035,.018),.55)
for side in (-1,1):
 box('RearTailLamp',(side*.335,-.926,.66),(.09,.016,.045),red,part,.009)
box('RearBumper',(0,-.88,.33),(.82,.12,.10),dark,part,.025)
# Only use complete separated tires from the immutable 100 export.
before=set(scene.objects);bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/derived/hyper3d-refined-v1/c03.glb'))
old=list(set(scene.objects)-before);bpy.context.view_layer.update()
for obj in old:
 if obj.type!='MESH' or not obj.name.startswith('Tire'):continue
 matrix=obj.matrix_world.copy();ps=[matrix@v.co for v in obj.data.vertices]
 lo=Vector([min(v[i] for v in ps) for i in range(3)]);hi=Vector([max(v[i] for v in ps) for i in range(3)]);center=(lo+hi)/2
 side='Left' if center.x<0 else 'Right';end='Front' if center.y>0 else 'Rear'
 pivot=empty('Wheel'+side+end,part,center)
 mesh=obj.data.copy()
 for v,p in zip(mesh.vertices,ps):v.co=p-center
 n=bpy.data.objects.new('Tire'+side+end,mesh);scene.collection.objects.link(n);n.parent=pivot
 bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000005);bm.to_mesh(mesh);bm.free()
for obj in old:bpy.data.objects.remove(obj,do_unlink=True)
report['scout_wheels']=save(part,'scout_wheels')
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
srcdir=ROOT/'source_art/family-refined-v2';srcdir.mkdir(parents=True,exist_ok=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(srcdir/'family_refined.blend'))
result=report
