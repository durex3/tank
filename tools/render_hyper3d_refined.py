"""Orthographic documentation for the active 100 Blender scene."""
import bpy
from pathlib import Path
from mathutils import Vector

scene=bpy.context.scene
assert scene.name.startswith('Hyper3D_100_Refined')
out=Path('E:/Godot_v4.7.2-stable_win64/game/tank/assets/derived/hyper3d-refined-v1')
turret=next(o for o in scene.objects if o.type=='EMPTY' and o.name.startswith('T02Refined'))
hull=next(o for o in scene.objects if o.type=='EMPTY' and o.name.startswith('C03Refined'))
cam=scene.camera
def show(root,visible):
    for o in [root]+list(root.children_recursive):o.hide_render=not visible
def render(name,position,target,scale):
    cam.location=position;cam.data.type='ORTHO';cam.data.ortho_scale=scale
    cam.rotation_euler=(Vector(target)-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
turret.location.z=0
for obj,name,height in [(turret,'t02',.44),(hull,'c03',.50)]:
    show(turret,obj==turret);show(hull,obj==hull)
    render(name+'_hero',(3,4,2.8),(0,0,height),2.7)
    render(name+'_front',(0,5,height),(0,0,height),2.7)
    render(name+'_right',(5,0,height),(0,0,height),2.7)
    render(name+'_top',(0,0,5),(0,0,0),2.7)
    render(name+'_rear',(-3,-4,2.7),(0,0,height),2.7)
show(turret,True);show(hull,True);turret.location.z=.88
render('assembly',(3,4,2.8),(0,0,.85),3.5)
bpy.ops.wm.save_as_mainfile(filepath='E:/Godot_v4.7.2-stable_win64/game/tank/source_art/hyper3d-refined-v1/hyper3d_refined.blend')
result={'rendered':11}
