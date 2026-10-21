"""Experimental derivation of user-provided Hyper3D output. Never overwrite inputs.
Reference shape is third-party MiniTanks art, not an original production asset.
Run from the project root with Blender 5.2.2.
"""
import bpy, bmesh, math, json, hashlib
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path.cwd(); assert (ROOT/'project.godot').exists()
INPUT=Path('/Users/liugelong/Downloads/487d6b33-e68a-4f2b-ae8f-654fd32c2452/base_basic_pbr.glb')
OUT=ROOT/'assets/derived/hyper3d-cannon-study-v1';OUT.mkdir(parents=True,exist_ok=True)
SRC=ROOT/'source_art/hyper3d-cannon-study-v1';SRC.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version=0
scene=bpy.context.scene;scene.name='136 Hyper3D reference-derived candidate'
def active(o):
 bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def material(name,col,rough=.6,metal=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True
 p=m.node_tree.nodes['Principled BSDF'];p.inputs['Base Color'].default_value=m.diffuse_color;p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
 return m
white=material('Ivory armor',(.75,.77,.73),.55,.02)
dark=material('Charcoal structure',(.035,.045,.055),.58,.12)
black=material('Bore interior',(.008,.011,.014),.85)
gold=material('Golden muzzle lip',(.94,.57,.025),.48,.08)
materials=[white,dark,black,gold]
bpy.ops.import_scene.gltf(filepath=str(INPUT));source=next(o for o in scene.objects if o.type=='MESH');active(source)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
# Keep a source-proportioned color study. Do not retain generated normal maps or baked lighting.
native=source.copy();native.data=source.data.copy();scene.collection.objects.link(native);native.name='Native proportion recolor'
native.data.materials.clear()
for m in materials:native.data.materials.append(m)
for f in native.data.polygons:
 c=f.center
 # Polygon centers require an explicit update following imported transforms.
 f.material_index=0
native.data.update()
for f in native.data.polygons:
 c=sum((native.data.vertices[i].co for i in f.vertices),Vector())/len(f.vertices)
 f.material_index=3 if c.y<-.84 else (1 if c.y<-.38 or c.z<.12 else 0)
 f.use_smooth=True
# Make candidate from a separate mesh. Cuts are inside the receiver / lower ring / hatch region.
body=source.copy();body.data=source.data.copy();scene.collection.objects.link(body);body.name='Armor shell'
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00002)
for co,no in [((0,-.405,0),(0,1,0)),((0,0,.13),(0,0,1)),((0,0,.95),(0,0,-1))]:
 bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-6,plane_co=co,plane_no=no,clear_inner=True)
# Local low-strength relaxation on imported triangulated surfaces; cut borders remain fixed.
verts=[v for v in bm.verts if not v.is_boundary]
for _ in range(3):bmesh.ops.smooth_vert(bm,verts=verts,factor=.18,use_axis_x=True,use_axis_y=True,use_axis_z=True)
bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
coords=[v.co.copy() for v in body.data.vertices];mn=[min(p[i] for p in coords) for i in range(3)];mx=[max(p[i] for p in coords) for i in range(3)]
# Only the armor shell is reshaped. Circular hatch / swivel / cannon are independently built rigid parts.
for v in body.data.vertices:
 p=v.co.copy();v.co=Vector(((p.x-mn[0])/(mx[0]-mn[0])*1.038-.519,.548-(p.y-mn[1])/(mx[1]-mn[1])*1.096,.07+(p.z-mn[2])/(mx[2]-mn[2])*.42))
body.data.materials.clear();body.data.materials.append(white)
for f in body.data.polygons:f.material_index=0;f.use_smooth=len(f.vertices)==3
body.data.update()
bm=bmesh.new();bm.from_mesh(body.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
def empty(name,parent=None,loc=(0,0,0)):
 o=bpy.data.objects.new(name,None);scene.collection.objects.link(o);o.parent=parent;o.location=loc;return o
root=empty('cannon');body.parent=root
pivot=empty('RecoilPivot',root)
def cyl(name,r,depth,loc,mat,parent,axis='Z',bevel=.006):
 bpy.ops.mesh.primitive_cylinder_add(vertices=64,radius=r,depth=depth,location=loc)
 o=bpy.context.object;o.name=name
 if axis=='Y':o.rotation_euler.x=math.pi/2
 o.data.materials.append(mat)
 active(o);bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
 if bevel:
  mod=o.modifiers.new('Small edge radius','BEVEL');mod.width=bevel;mod.segments=3
  bpy.ops.object.modifier_apply(modifier=mod.name)
 for f in o.data.polygons:f.use_smooth=len(f.vertices)==4
 o.parent=parent;return o
cyl('Low swivel ring',.38,.07,(0,0,.035),dark,root)
cyl('Flush roof hatch',.25,.104,(0,-.15,.542),white,root,bevel=.012)
cyl('Hatch seam',.265,.018,(0,-.15,.495),dark,root,bevel=.004)
# Locally rebuild the front receiver plane, removing generated collar lumps.
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-6,plane_co=(0,.35,0),plane_no=(0,-1,0),clear_inner=True)
bmesh.ops.holes_fill(bm,edges=[e for e in bm.edges if e.is_boundary],sides=0)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(body.data);bm.free()
cyl('Fixed receiver',.222,.18,(0,.42,.29),dark,root,'Y',.012)
# Revolved annular barrel profile, including true bore walls and a dark back. All circles stay circular.
profile=[(.50,.169),(.55,.177),(.59,.177),(.62,.157),(.97,.157),(1.015,.18),(1.135,.18),(1.16,.163),(1.16,.117),(1.13,.113),(.64,.113),(.62,0)]
vertices=[];faces=[];face_mats=[];N=64
for y,r in profile:
 for i in range(N):
  a=i*math.tau/N;vertices.append((r*math.cos(a),y,.29+r*math.sin(a)))
for j in range(len(profile)-1):
 for i in range(N):
  faces.append((j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i))
  face_mats.append(2 if j>=8 else (3 if j>=4 else 1))
mesh=bpy.data.meshes.new('Clean rigid barrel with bore');mesh.from_pydata(vertices,[],faces);mesh.update()
barrel=bpy.data.objects.new('Barrel',mesh);scene.collection.objects.link(barrel);barrel.parent=pivot
for m in materials:mesh.materials.append(m)
for f,idx in zip(mesh.polygons,face_mats):f.material_index=idx;f.use_smooth=True
bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free()
empty('VisualMuzzle',pivot,(0,1.16,.29))
bpy.data.objects.remove(source,do_unlink=True)
# Generated imported maps are deliberately unused; do not pack 2K source maps into the derivative.
for mesh in list(bpy.data.meshes):
 if mesh.users==0:bpy.data.meshes.remove(mesh)
for m in list(bpy.data.materials):
 if m.users==0:bpy.data.materials.remove(m)
for image in list(bpy.data.images):
 if image.users==0:bpy.data.images.remove(image)
def export(part,path):
 active(part)
 for child in part.children_recursive:child.select_set(True)
 bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_animations=False,export_vertex_color='ACTIVE',export_all_vertex_colors=True)
# Native study rotates +Y forward to match the candidate; its source proportions remain unchanged.
for v in native.data.vertices:v.co.x=-v.co.x;v.co.y=-v.co.y
native_root=empty('native');native.parent=native_root
export(native_root,OUT/'cannon_native.glb')
# Bake only local geometric occlusion on the repaired candidate into vertex colors.
bpy.context.view_layer.update();objects=[o for o in root.children_recursive if o.type=='MESH']
vv=[];ff=[]
for o in objects:
 base=len(vv);vv.extend(o.matrix_world@v.co for v in o.data.vertices);ff.extend(tuple(base+i for i in f.vertices) for f in o.data.polygons)
tree=BVHTree.FromPolygons(vv,ff)
for o in objects:
 attr=o.data.color_attributes.new(name='LocalAO',type='FLOAT_COLOR',domain='CORNER');o.data.color_attributes.active_color=attr;cache={}
 for loop in o.data.loops:
  k=loop.vertex_index
  if k not in cache:
   v=o.data.vertices[k];p=o.matrix_world@v.co;n=(o.matrix_world.to_3x3()@v.normal).normalized();up=Vector((0,0,1)) if abs(n.z)<.95 else Vector((0,1,0));t=n.cross(up).normalized();b=n.cross(t);blocked=0
   for i in range(16):
    z=(i+.5)/16;r=math.sqrt(1-z*z);a=i*2.399963;direction=(n*z+t*r*math.cos(a)+b*r*math.sin(a)).normalized()
    if tree.ray_cast(p+n*.004,direction,.30)[0] is not None:blocked+=1
   cache[k]=1-.4*blocked/16
  c=cache[k];attr.data[loop.index].color=(c,c,c,1)
export(root,OUT/'cannon.glb')
native_root.hide_viewport=True;native_root.hide_render=True
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'cannon_study.blend'))
report={'status':'experimental candidate; not production mapped','source':str(INPUT),'source_sha256':hashlib.sha256(INPUT.read_bytes()).hexdigest(),'generation_id':'487d6b33-e68a-4f2b-ae8f-654fd32c2452','reference':'Third-party MiniTanks turret icon, user-authorized shape reference. Not original artwork. No production rights claim.','tool':'tools/refine_hyper3d_cannon_136.py','operations':['Native-proportion flat-color study','Armor-only structural height adaptation; circular mechanical parts rebuilt rigidly','Low strength local relaxation; receiver/roof/base cuts sealed','Original recolor maps and normal maps replaced with independent materials','Independent rigid barrel with genuine bore and RecoilPivot/VisualMuzzle','16-direction geometric local AO'],'authority':'No gameplay or catalog mapping changes; original Downloads files untouched'}
(OUT/'provenance.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
print('136 DERIVATION EXPORT PASS')
