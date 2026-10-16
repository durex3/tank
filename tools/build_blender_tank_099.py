"""Author two modular, low-poly tank parts in a NEW Blender scene. Run via Blender MCP.

Blender +Y is vehicle front; glTF Y-up export maps it to Godot -Z.
Source scene and pre-existing user objects are preserved. Values are a candidate
template matching approved 098 envelopes, not a production configuration migration.
"""
import bpy
import bmesh
import json
import math
from pathlib import Path
from mathutils import Vector

ROOT = Path('E:/Godot_v4.7.2-stable_win64/game/tank')
OUT = ROOT / 'assets/derived/blender-family-v1'
SOURCE = ROOT / 'source_art/blender-family-v1'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
(ROOT / 'source_art/.gdignore').write_text('')
scene = bpy.data.scenes.new('Tank_099_Production')
bpy.context.window.scene = scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene.render.engine = 'BLENDER_EEVEE'
scene.render.resolution_x = 1200
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.film_transparent = False
scene.view_settings.view_transform = 'AgX'
scene.world = bpy.data.worlds.new('Tank099_PurpleStudio')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.026, 0.019, 0.043, 1)
scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.6

def mat(name, color, roughness, metallic=0):
    m = bpy.data.materials.new('099_' + name)
    m.diffuse_color = (*color, 1)
    m.use_nodes = True
    bsdf = m.node_tree.nodes.get('Principled BSDF')
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    return m

WHITE = mat('ivory_armor', (.72, .71, .66), .44, .12)
EDGE = mat('pale_metal', (.36, .40, .43), .39, .55)
DARK = mat('charcoal_mechanism', (.055, .066, .080), .46, .55)
RUBBER = mat('rubber', (.018, .022, .028), .82)
YELLOW = mat('signal_yellow', (.91, .54, .018), .4, .25)
BLACK = mat('recess', (.008, .011, .015), .75)

def empty(name, parent=None, loc=(0,0,0)):
    o = bpy.data.objects.new(name, None)
    scene.collection.objects.link(o)
    o.empty_display_size = .08
    o.parent = parent
    o.location = loc
    return o

def active(o):
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o

def finish(o, material, parent, bevel=0, segments=1, smooth=False):
    if material: o.data.materials.append(material)
    o.parent = parent
    if bevel:
        mod = o.modifiers.new('Manufactured edge bevel', 'BEVEL')
        mod.width = bevel
        mod.segments = segments
        active(o)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    for p in o.data.polygons: p.use_smooth = smooth
    return o

def mesh(name, vertices, faces, material, parent, bevel=0, smooth=False):
    m = bpy.data.meshes.new(name + '_mesh')
    m.from_pydata(vertices, [], faces)
    m.update()
    bm = bmesh.new()
    bm.from_mesh(m)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(m)
    bm.free()
    o = bpy.data.objects.new(name, m)
    scene.collection.objects.link(o)
    return finish(o, material, parent, bevel, 1, smooth)

def box(name, loc, size, material, parent, bevel=.015, rot=(0,0,0)):
    bpy.ops.mesh.primitive_cube_add(size=1, location=loc)
    o = bpy.context.object
    o.name = name
    o.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    o.rotation_euler = rot
    return finish(o, material, parent, bevel)

def cyl(name, loc, radius, depth, material, parent, axis='Z', vertices=24):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc)
    o = bpy.context.object
    o.name = name
    if axis == 'X': o.rotation_euler[1] = math.pi/2
    if axis == 'Y': o.rotation_euler[0] = math.pi/2
    finish(o, material, parent)
    for p in o.data.polygons: p.use_smooth = len(p.vertices)==4
    return o

def loft(name, sections, material, parent, bevel=.015):
    # Each section = y, half-width, bottom, top. Beveled octagonal cross section.
    verts = []
    for y,w,b,t in sections:
        c = min(.075, (t-b)*.25)
        verts.extend([(x,y,z) for x,z in [(-w+c,b),(w-c,b),(w,b+c),(w,t-c),(w-c,t),(-w+c,t),(-w,t-c),(-w,b+c)]])
    faces = [tuple(reversed(range(8))), tuple(range((len(sections)-1)*8,len(sections)*8))]
    for j in range(len(sections)-1):
        for i in range(8): faces.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i))
    return mesh(name,verts,faces,material,parent,bevel)

def lathe(name, profile, material, parent, loc=(0,0,0), axis='Z', n=24, closed=True):
    # Closed radial profile, for real rings, rubber tires and hollow barrels.
    verts=[]
    for along,r in profile:
        for i in range(n):
            a=2*math.pi*i/n
            u,v=r*math.cos(a),r*math.sin(a)
            xyz=(along,u,v) if axis=='X' else ((u,along,v) if axis=='Y' else (u,v,along))
            verts.append(tuple(xyz[j]+loc[j] for j in range(3)))
    faces=[]
    limit=len(profile) if closed else len(profile)-1
    for j in range(limit):
        k=(j+1)%len(profile)
        for i in range(n): faces.append((j*n+i,j*n+(i+1)%n,k*n+(i+1)%n,k*n+i))
    return mesh(name,verts,faces,material,parent,smooth=True)

def loop_handle(name, x,y,z,parent):
    # Closed hollow rectangular hoop, not a fake dark decal.
    box(name+'_L',(x-.045,y,z+.04),(.018,.026,.08),YELLOW,parent,.007)
    box(name+'_R',(x+.045,y,z+.04),(.018,.026,.08),YELLOW,parent,.007)
    box(name+'_Top',(x,y,z+.08),(.108,.026,.018),YELLOW,parent,.007)

turret=empty('CannonModule')
hull=empty('ScoutWheelsModule')

# MAIN CANNON: broad low armor, a real hollow gun, independent recoil group.
lathe('TurretBearing',[(0,.32),(.018,.38),(.10,.38),(.125,.34),(.125,.25),(0,.25)],DARK,turret,n=32)
lathe('BearingTrim',[(.045,.382),(.063,.382),(.063,.37),(.045,.37)],EDGE,turret,n=32)
cyl('BearingCore',(0,0,.090),.31,.17,DARK,turret,vertices=32)
loft('ArmorShell',[(-.687688,.39,.17,.64),(-.60,.49,.14,.71),(-.13,.5148,.16,.70),(.10,.44,.20,.59),(.18,.28,.25,.50)],WHITE,turret)
box('RearMechanism',(0,-.678,.39),(.62,.024,.32),DARK,turret,.008)
for side in (-1,1):
    for i in range(3):
        box('RearVent', (side*(.17+i*.085),-.690188,.44),(.035,.015,.14),BLACK,turret,.008)
    box('CheekServicePlate',(side*.503,-.12,.40),(.012,.15,.115),DARK,turret,.012)
    box('CheekLatch',(side*.5108,-.12,.40),(.008,.025,.07),EDGE,turret,.004)
    loop_handle('LiftLoop',side*.30,-.47,.793728,turret)
    box('LoopFoot',(side*.30,-.47,.750),(.13,.085,.10),WHITE,turret,.01)
cyl('Hatch',(0,-.13,.732),.19,.055,WHITE,turret,vertices=32)
box('HatchLatch',(0,.04,.771),(.07,.045,.025),DARK,turret,.005)
box('CoolingGrille',(0,-.48,.728),(.30,.22,.018),DARK,turret,.01)
for i in range(5): box('CoolingRib',(-.12+i*.06,-.48,.743),(.016,.20,.014),EDGE,turret,.003)
cyl('GunMantlet',(0,.08,.43),.16,.24,WHITE,turret,'Y',32)
cyl('MantletLip',(0,.21,.43),.135,.04,EDGE,turret,'Y',24)
recoil=empty('RecoilPivot',turret)
lathe('HollowBarrel',[(.12,.10),(.84,.10),(.84,.067),(.12,.067)],DARK,recoil,loc=(0,0,.43),axis='Y',n=24)
for y in (.48,.68):
    lathe('BarrelBand',[(y-.018,.108),(y+.018,.108),(y+.018,.10),(y-.018,.10)],EDGE,recoil,loc=(0,0,.43),axis='Y',n=24)
# Square muzzle with true bore and inside wall; closed rear recess prevents light leak.
verts=[]
for y,inner in [(.82,False),(1.047,False),(1.047,True),(.82,True)]:
    for i in range(16):
        a=2*math.pi*i/16
        if inner: x,z=.078*math.cos(a),.078*math.sin(a)
        else:
            x=.16*math.copysign(abs(math.cos(a))**.40,math.cos(a))
            z=.145*math.copysign(abs(math.sin(a))**.40,math.sin(a))
        verts.append((x,y,.43+z))
faces=[]
for ring in range(4):
    for i in range(16): faces.append((ring*16+i,ring*16+(i+1)%16,((ring+1)%4)*16+(i+1)%16,((ring+1)%4)*16+i))
muzzle=mesh('MuzzleBrake',verts,faces,WHITE,recoil)
muzzle.data.materials.append(BLACK)
for i,p in enumerate(muzzle.data.polygons):
    if i//16==2: p.material_index=1
cyl('BoreBack',(0,.35,.43),.068,.015,BLACK,recoil,'Y',24)
# Thin yellow squared rim on front, separated from white front face by physical depth.
rimverts=[]
for y,scale in [(1.048,1),(1.05,1),(1.05,.86),(1.048,.86)]:
    for i in range(16):
        a=2*math.pi*i/16
        rimverts.append((.16*scale*math.copysign(abs(math.cos(a))**.4,math.cos(a)),y,.43+.145*scale*math.copysign(abs(math.sin(a))**.4,math.sin(a))))
mesh('YellowMuzzleRim',rimverts,faces,YELLOW,recoil)
for side in (-1,1):
    for z in (.395,.465): box('MuzzleVent',(side*.161,.93,z),(.008,.12,.022),BLACK,recoil,.005)
empty('VisualMuzzle',recoil,(0,1.05,.43))

# SCOUT: four complete wheels with separate steering and rolling axes.
loft('ChassisArmor',[(-.82,.34,.43,.70),(-.58,.48,.33,.82),(.30,.49,.34,.84),(.83,.29,.39,.59)],WHITE,hull,.025)
loft('Undercarriage',[(-.70,.30,.20,.46),(.64,.30,.20,.46)],DARK,hull,.02)
box('FrontIntake',(0,.815,.48),(.23,.025,.09),DARK,hull,.015)
for side in (-1,1):
    for i in range(4): box('HullVent',(side*.49,-.25+i*.085,.62),(.012,.025,.13),BLACK,hull,.006)
    box('SuspensionRail',(side*.41,0,.31),(.08,1.18,.10),DARK,hull,.015)
    loop_handle('ChassisLift',side*.38,-.13,.903302,hull)
    box('ChassisLiftFoot',(side*.38,-.13,.86),(.13,.07,.10),WHITE,hull,.01)
lathe('MountingSocket',[(.82,.29),(.85,.35),(.90,.35),(.92,.31),(.92,.245),(.82,.245)],DARK,hull,n=32)
lathe('SocketRim',[(.89,.351),(.914,.321),(.914,.31),(.89,.34)],EDGE,hull,n=32)

R=.390346
for side,side_name in [(-1,'Left'),(1,'Right')]:
    for front,y in [(True,.57),(False,-.57)]:
        label=side_name+('Front' if front else 'Rear')
        steering=empty('Steer'+label,hull,(side*.640,y,R))
        wheel=empty('Wheel'+label,steering)
        lathe('Tire'+label,[(-.17,.29),(-.15,.34),(-.11,.365),(.11,.365),(.15,.34),(.17,.29),(.17,.215),(-.17,.215)],RUBBER,wheel,axis='X',n=24)
        for j in range(16):
            a=2*math.pi*j/16
            for row in (-1,1):
                # Outer tread radius is the exact template radius; flat blocks stay within circle.
                b=box('Tread',(row*.074,(R-.015)*math.sin(a),(R-.015)*math.cos(a)),(.14,.095,.030),RUBBER,wheel,0,(-a,0,0))
        for outer in (-1,1):
            x=outer*.176
            cyl('HubDisc',(x,0,0),.238,.013,WHITE,wheel,'X',24)
            lathe('HubYellowRing',[(x-.008,.254),(x+.008,.254),(x+.008,.235),(x-.008,.235)],YELLOW,wheel,axis='X',n=24)
        for z in (-.135,.135): cyl('HubFastener',(side*.179,0,z),.022,.012,DARK,wheel,'X',8)
        box('HubSlot',(side*.179,0,0),(.009,.20,.016),DARK,wheel,.004)
        # Axle exists inside real attachment, no disconnected floating wheel.
        cyl('Axle'+label,(side*.43,y,R),.065,.34,EDGE,hull,'X',12)
        # An enclosed curved shell over the tire, not a paper-thin plane.
        fv=[]
        for x in (side*.655-.17,side*.655+.17):
            for radius in (.445,.49):
                for j in range(9):
                    a=math.radians(45+90*j/8)
                    fv.append((x,y+radius*math.cos(a),R+radius*math.sin(a)))
        ff=[]
        for j in range(8):
            ff.extend([(j,j+1,9+j+1,9+j),(18+j,27+j,27+j+1,18+j+1),
                       (j,18+j,18+j+1,j+1),(9+j,9+j+1,27+j+1,27+j)])
        ff.extend([(0,9,27,18),(8,26,35,17)])
        mesh('Fender'+label,fv,ff,WHITE,hull)
        box('FenderMount',(side*.49,y,.73),(.16,.10,.10),DARK,hull,.015)

def descendants(root): return [root]+list(root.children_recursive)

def join_static(parent, name):
    meshes=[o for o in parent.children if o.type=='MESH']
    if not meshes: return
    bpy.ops.object.select_all(action='DESELECT')
    for o in meshes: o.select_set(True)
    bpy.context.view_layer.objects.active=meshes[0]
    bpy.ops.object.join()
    obj=bpy.context.object
    obj.name=name
    # Preserve exact world transform while placing origin at the mechanical parent.
    scene.cursor.location=parent.matrix_world.translation
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    return obj

bpy.context.view_layer.update()
for r in (turret,hull):
    for p in reversed(descendants(r)):
        if p.type=='EMPTY': join_static(p,'Barrel' if p==recoil else ('TireAssembly' if p.name.startswith('Wheel') else p.name+'_Body'))

for obj in scene.objects:
    if obj.type=='MESH':
        bm=bmesh.new()
        bm.from_mesh(obj.data)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.000001)
        bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=0.000001)
        bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
        bm.to_mesh(obj.data)
        bm.free()
        active(obj)
        bpy.ops.object.mode_set(mode='EDIT')
        bpy.ops.mesh.select_all(action='SELECT')
        bpy.ops.uv.smart_project(angle_limit=math.radians(66), island_margin=.025)
        bpy.ops.object.mode_set(mode='OBJECT')

def stats(root):
    pts=[]
    count=0
    for o in descendants(root):
        if o.type!='MESH': continue
        o.data.calc_loop_triangles()
        count+=len(o.data.loop_triangles)
        pts.extend(o.matrix_world@v.co for v in o.data.vertices)
    lo=[min(p[i] for p in pts) for i in range(3)]
    hi=[max(p[i] for p in pts) for i in range(3)]
    return dict(triangles=count,blender_min=lo,blender_max=hi,
                godot_size=[hi[0]-lo[0],hi[2]-lo[2],hi[1]-lo[1]],
                objects=[o.name for o in descendants(root)])

bpy.context.view_layer.update()
report={'cannon':stats(turret),'scout_wheels':stats(hull),'blender':bpy.app.version_string,
        'source':'user screenshot and generated isolated references; authored meshes, no Hyper3D reuse',
        'materials':'six shared procedural PBR colors; no invented image normal maps',
        'status':'candidate_pending_visual_and_godot_review'}
report['triangle_budget_note']='User explicitly allowed more than 6000 tris on 2026-10-15; retain mechanical details.'
for r,name in [(turret,'cannon'),(hull,'scout_wheels')]:
    bpy.ops.object.select_all(action='DESELECT')
    for o in descendants(r): o.select_set(True)
    bpy.context.view_layer.objects.active=r
    bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True,
                              use_active_scene=True,export_yup=True,export_apply=True,export_animations=False,export_extras=True)

# Scene presentation: separate asset files retain local origin, assembled source uses seating offset.
turret.location.z=.88
bpy.context.view_layer.update()
cam_data=bpy.data.cameras.new('099_Ortho')
cam=bpy.data.objects.new('099_Ortho',cam_data)
scene.collection.objects.link(cam)
scene.camera=cam
cam.data.type='ORTHO'
cam.data.ortho_scale=3.25

def aim(obj, point): obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()
cam.location=(3,4,2.8)
aim(cam,(0,0,.82))
for name,loc,power,size in [('Key',(2,4,6),450,5),('Fill',(-4,2,3),250,4),('Rim',(1,-4,4),350,3)]:
    d=bpy.data.lights.new('099_'+name,'AREA')
    d.energy=power
    d.shape='DISK'
    d.size=size
    o=bpy.data.objects.new('099_'+name,d)
    scene.collection.objects.link(o)
    o.location=loc
    aim(o,(0,0,.7))
scene.render.filepath=str(OUT/'assembly.png')
(OUT/'report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'tank_modules.blend'))
result=report
