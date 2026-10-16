"""Derive mechanically separated meshes from immutable Hyper3D originals."""
import bpy, bmesh, math, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path('E:/Godot_v4.7.2-stable_win64/game/tank')
OUT=ROOT/'assets/derived/hyper3d-refined-v1'
SRC=ROOT/'source_art/hyper3d-refined-v1'
OUT.mkdir(parents=True,exist_ok=True); SRC.mkdir(parents=True,exist_ok=True)
scene=bpy.data.scenes.new('Hyper3D_100_Refined')
bpy.context.window.scene=scene
scene.unit_settings.system='METRIC'

def activate(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
    bpy.context.view_layer.objects.active=o

def empty(name,parent=None,loc=(0,0,0)):
    o=bpy.data.objects.new(name,None);scene.collection.objects.link(o)
    o.parent=parent;o.location=loc;return o

def read_source(key):
    before=set(scene.objects)
    bpy.ops.import_scene.gltf(filepath=str(ROOT/'assets/imported/modular-sample-v1'/(key+'_pbr.glb')))
    o=next(o for o in set(scene.objects)-before if o.type=='MESH')
    activate(o);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.000005)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=0.000001)
    bm.to_mesh(o.data);bm.free()
    return o

def section(source,name,predicate):
    o=source.copy();o.data=source.data.copy();o.name=name;scene.collection.objects.link(o)
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if not predicate(f.calc_center_median())],context='FACES')
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.to_mesh(o.data);bm.free();return o

dark=bpy.data.materials.new('100_RepairDark');dark.diffuse_color=(.035,.043,.052,1);dark.use_nodes=True
bs=dark.node_tree.nodes['Principled BSDF'];bs.inputs['Base Color'].default_value=dark.diffuse_color
bs.inputs['Roughness'].default_value=.65

def seal(o):
    idx=len(o.data.materials);o.data.materials.append(dark)
    bm=bmesh.new();bm.from_mesh(o.data)
    edges=[e for e in bm.edges if e.is_boundary]
    added=bmesh.ops.holes_fill(bm,edges=edges,sides=0)['faces'] if edges else []
    for f in added:f.material_index=idx
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    bm.to_mesh(o.data);bm.free()
    return len(added)

def cylinder(name,radius,depth,loc,axis,parent):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=radius,depth=depth,location=loc)
    o=bpy.context.object;o.name=name
    if axis=='X':o.rotation_euler.y=math.pi/2
    if axis=='Y':o.rotation_euler.x=math.pi/2
    o.data.materials.append(dark);o.parent=parent
    for p in o.data.polygons:p.use_smooth=len(p.vertices)==4
    return o

def transform_mesh(o,fn):
    for v in o.data.vertices:v.co=fn(v.co)
    o.data.update()

def origin_parent(o,parent,point):
    for v in o.data.vertices:v.co-=Vector(point)
    o.parent=parent;o.location=point

turret=empty('T02Refined');hull=empty('C03Refined')
source_t=read_source('t02')
# Insert a clean transverse cut inside the dark receiver, preserving UV interpolation.
bm=bmesh.new();bm.from_mesh(source_t.data)
bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=1e-7,
                      plane_co=(0,-.45,0),plane_no=(0,1,0))
bm.to_mesh(source_t.data);bm.free()
body=section(source_t,'T02Armor',lambda p:p.y>=-.450001)
left=section(source_t,'BarrelLeftMesh',lambda p:p.y<-.450001 and p.x>0)
right=section(source_t,'BarrelRightMesh',lambda p:p.y<-.450001 and p.x<=0)
caps={o.name:seal(o) for o in (body,left,right)}
ts=1.0296/1.1148518323898315
tf=lambda p:Vector((-(p.x-.0048419237)*ts,(-p.y+.28)*ts,(p.z+.4768456817)*ts))
for o in (body,left,right):transform_mesh(o,tf)
body.parent=turret
for o,label in [(left,'Left'),(right,'Right')]:
    coords=[v.co for v in o.data.vertices]
    cx=(min(v.x for v in coords)+max(v.x for v in coords))/2
    cz=(min(v.z for v in coords)+max(v.z for v in coords))/2
    pivot=empty('Recoil'+label,turret)
    o.parent=pivot
    cylinder('RecoilSleeve'+label,.115*ts,.15*ts,(cx,(.45+.28-.055)*ts,cz),'Y',pivot)
    empty('VisualMuzzle'+label,pivot,(cx,max(v.y for v in coords),cz))
# Remove only imported working copy. Source file is never edited.
bpy.data.objects.remove(source_t,do_unlink=True)

source_h=read_source('c03')
# Recover the complete disconnected rear tires. Front tires are fused to fenders;
# subtract their envelopes, then reuse rear tire geometry instead of ragged fragments.
bm=bmesh.new();bm.from_mesh(source_h.data);bm.verts.ensure_lookup_table();bm.faces.ensure_lookup_table()
remain=set(bm.verts);components=[]
while remain:
    todo=[remain.pop()];verts=set(todo)
    while todo:
        v=todo.pop()
        for e in v.link_edges:
            n=e.other_vert(v)
            if n in remain:remain.remove(n);verts.add(n);todo.append(n)
    components.append(verts)
rear={}
for verts in components:
    if len(verts)>100 and max(v.co.y for v in verts)<0:
        side=1 if sum(v.co.x for v in verts)>0 else -1
        rear[side]={f.index for v in verts for f in v.link_faces}
bm.free()
assert len(rear)==2
def indexed_copy(name,face_ids):
    o=source_h.copy();o.data=source_h.data.copy();o.name=name;scene.collection.objects.link(o)
    bm=bmesh.new();bm.from_mesh(o.data);bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in face_ids],context='FACES')
    bmesh.ops.delete(bm,geom=[v for v in bm.verts if not v.link_faces],context='VERTS')
    bm.to_mesh(o.data);bm.free();return o
hb=indexed_copy('C03Armor',set(range(len(source_h.data.polygons)))-rear[-1]-rear[1])
hb.data.materials.append(dark)
for side in (-1,1):
    cutter=cylinder('TemporaryWheelClearance',.435,.54,(side*.67,.522,-.099),'X',None)
    activate(hb);mod=hb.modifiers.new('Remove fused front tire','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
    bpy.ops.object.modifier_apply(modifier=mod.name)
    bpy.data.objects.remove(cutter,do_unlink=True)
hs=1.65/1.625929832458496
hf=lambda p:Vector(((p.x+.0000073314)*hs,p.y*hs,(p.z+.489688307)*hs))
transform_mesh(hb,hf);hb.parent=hull
caps[hb.name]=seal(hb)
wheel_metrics=[]
for side,end in [(-1,-1),(-1,1),(1,-1),(1,1)]:
    label=('Left' if side<0 else 'Right')+('Front' if end>0 else 'Rear')
    o=indexed_copy('Tire'+label,rear[side])
    caps[o.name]=seal(o)
    transform_mesh(o,hf)
    pts=[v.co for v in o.data.vertices]
    lo=Vector([min(p[i] for p in pts) for i in range(3)])
    hi=Vector([max(p[i] for p in pts) for i in range(3)])
    center=(lo+hi)/2
    # Repair source tire ellipticity in mesh space; object transforms stay rigid.
    target_center=Vector((center.x,end*(1.9206918/2-.42),.42))
    for v in o.data.vertices:
        v.co.y=(v.co.y-center.y)*(.84/(hi.y-lo.y))+target_center.y
        v.co.z=(v.co.z-center.z)*(.84/(hi.z-lo.z))+target_center.z
    center=target_center
    pivot=empty('Steer'+label,hull,center)
    roll=empty('Wheel'+label,pivot)
    origin_parent(o,roll,center);o.location=(0,0,0)
    wheel_metrics.append({'name':label,'center':list(center),'source_diameter_y':hi.y-lo.y,'source_diameter_z':hi.z-lo.z,'corrected_diameter':.84})
    cylinder('Axle'+label,.07,.28,(side*.41*hs,center.y,center.z),'X',hull)
bpy.data.objects.remove(source_h,do_unlink=True)

scene.render.engine='BLENDER_EEVEE'
scene.render.resolution_x=1200;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.world=bpy.data.worlds.new('100_RefinedWorld');scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.035,.025,.055,1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
camd=bpy.data.cameras.new('100_RefinedCamera');cam=bpy.data.objects.new('100_RefinedCamera',camd)
scene.collection.objects.link(cam);scene.camera=cam;camd.type='ORTHO';camd.ortho_scale=3.5
def aim(o,target):o.rotation_euler=(Vector(target)-o.location).to_track_quat('-Z','Y').to_euler()
cam.location=(3,4,2.8);aim(cam,(0,0,.85))
for name,loc,power in [('Key',(2,4,6),500),('Fill',(-4,2,3),300),('Rim',(1,-4,4),350)]:
    d=bpy.data.lights.new('100_'+name,'AREA');d.energy=power;d.size=4
    o=bpy.data.objects.new(d.name,d);scene.collection.objects.link(o);o.location=loc;aim(o,(0,0,.7))

def stats(root):
    tris=0;points=[];qa={}
    bpy.context.view_layer.update()
    for o in root.children_recursive:
        if o.type!='MESH':continue
        o.data.calc_loop_triangles();tris+=len(o.data.loop_triangles)
        points.extend(o.matrix_world@v.co for v in o.data.vertices)
        bm=bmesh.new();bm.from_mesh(o.data)
        qa[o.name]={'boundary':sum(e.is_boundary for e in bm.edges),'nonmanifold':sum(not e.is_manifold for e in bm.edges)};bm.free()
    return {'triangles':tris,'size':[max(v[i] for v in points)-min(v[i] for v in points) for i in (0,2,1)],'qa':qa}

report={'turret':stats(turret),'chassis':stats(hull),'wheel_metrics':wheel_metrics,'caps':caps,
        'status':'mesh_checked_engine_review_separate','source_hashes':{k:hashlib.sha256((ROOT/'assets/imported/modular-sample-v1'/(k+'_pbr.glb')).read_bytes()).hexdigest() for k in ('t02','c03')}}
for key,target in [('turret',(1.0296,.882728,1.747688)),('chassis',(1.65,.992302,1.920692))]:
    assert all(abs(a-b)<.001 for a,b in zip(report[key]['size'],target)), report[key]['size']
    assert all(v['boundary']==0 and v['nonmanifold']==0 for v in report[key]['qa'].values())
for r,name in [(turret,'t02'),(hull,'c03')]:
    bpy.ops.object.select_all(action='DESELECT')
    for o in [r]+list(r.children_recursive):o.select_set(True)
    bpy.context.view_layer.objects.active=r
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,use_active_scene=True,export_animations=False)
turret.location.z=.88
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SRC/'hyper3d_refined.blend'))
scene.render.filepath=str(OUT/'assembly.png');bpy.ops.render.render(write_still=True)
(OUT/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
result=report
