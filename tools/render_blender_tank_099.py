"""Render consistent true orthographic views from the authored meshes."""
import bpy, json, bmesh
from pathlib import Path
from mathutils import Vector

out = Path('E:/Godot_v4.7.2-stable_win64/game/tank/assets/derived/blender-family-v1')
scene = bpy.context.scene
assert scene.name.startswith('Tank_099_Production')
cam = scene.camera
turret = next(o for o in scene.objects if o.type == 'EMPTY' and o.name.startswith('CannonModule'))
hull = next(o for o in scene.objects if o.type == 'EMPTY' and o.name.startswith('ScoutWheelsModule'))
def visible(root, yes):
    for o in [root] + list(root.children_recursive): o.hide_render = not yes
def render(name, position, target, scale=2.6):
    cam.data.type = 'ORTHO'
    cam.data.ortho_scale = scale
    cam.location = position
    cam.rotation_euler = (Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(out / (name+'.png'))
    bpy.ops.render.render(write_still=True)
qa={}
for o in scene.objects:
    if o.type != 'MESH': continue
    bm=bmesh.new(); bm.from_mesh(o.data)
    qa[o.name]={'boundary_edges':sum(e.is_boundary for e in bm.edges),
                'nonmanifold_edges':sum(not e.is_manifold for e in bm.edges),
                'zero_area_faces':sum(f.calc_area()<1e-12 for f in bm.faces),
                'uv_layers':len(o.data.uv_layers), 'scale':list(o.scale)}
    bm.free()
(out/'mesh_qa.json').write_text(json.dumps(qa,indent=2),encoding='utf-8')
for part,name,height in [(turret,'cannon',.44),(hull,'scout_wheels',.50)]:
    turret.location.z=0
    visible(turret,part==turret); visible(hull,part==hull)
    render(name+'_hero',(3,4,2.7),(0,0,height))
    render(name+'_front',(0,5,height),(0,0,height))
    render(name+'_right',(5,0,height),(0,0,height))
    render(name+'_top',(0,0,5),(0,0,0))
    render(name+'_rear',(-3,-4,2.3),(0,0,height))
visible(turret,True); visible(hull,True)
turret.location.z=.88
render('assembly',(3,4,2.8),(0,0,.82),3.25)
bpy.ops.wm.save_as_mainfile(filepath=str(out.parents[2]/'source_art/blender-family-v1/tank_modules.blend'))
result={'rendered':11,'qa':qa}
