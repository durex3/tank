import bpy
from pathlib import Path
from mathutils import Vector
s=bpy.context.scene
assert s.name.startswith('Family_103_Inspection')
out=Path('E:/Godot_v4.7.2-stable_win64/game/tank/artifacts/103')
out.mkdir(parents=True,exist_ok=True)
s.render.engine='BLENDER_EEVEE'
s.render.resolution_x=640;s.render.resolution_y=540;s.render.resolution_percentage=100
s.world=bpy.data.worlds.new('103 Inspection World');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.10,.085,.12,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.5
def aim(o,p):o.rotation_euler=(Vector(p)-o.location).to_track_quat('-Z','Y').to_euler()
for loc,power in [((2,-3,5),450),((-3,-1,3),300),((1,4,4),350)]:
 d=bpy.data.lights.new('103 inspection light','AREA');d.energy=power;d.size=4
 o=bpy.data.objects.new(d.name,d);s.collection.objects.link(o);o.location=loc;aim(o,(0,0,0))
d=bpy.data.cameras.new('103 inspection camera');o=bpy.data.objects.new(d.name,d);s.collection.objects.link(o);s.camera=o;d.type='ORTHO';d.ortho_scale=2.8
meshes=[o for o in s.objects if o.type=='MESH']
for obj in meshes:
 for m in meshes:m.hide_render=m!=obj
 for suffix,pos in [('minus',(3,-4,2.8)),('plus',(-3,4,2.8))]:
  s.camera.location=pos;aim(s.camera,(0,0,0));s.render.filepath=str(out/(obj.name+'_'+suffix+'.png'));bpy.ops.render.render(write_still=True)
result={'renders':len(meshes)*2}
