"""Blender assembly review using authored modules and exact Godot track snapshots."""
import bpy, os
from pathlib import Path
from mathutils import Vector
ROOT=Path(os.environ.get('TANK_PROJECT_ROOT',str(Path.cwd())))
source=bpy.data.scenes['Mechanical_Family_109']
s=bpy.data.scenes.new('Family_109_Assembly_Review');bpy.context.window.scene=s
s.render.engine='BLENDER_EEVEE';s.render.resolution_x=1600;s.render.resolution_y=900;s.render.resolution_percentage=100
s.render.image_settings.file_format='PNG';s.view_settings.view_transform='AgX'
s.world=bpy.data.worlds.new('109 review world');s.world.use_nodes=True
s.world.node_tree.nodes['Background'].inputs[0].default_value=(.08,.09,.12,1)
s.world.node_tree.nodes['Background'].inputs[1].default_value=.45
def copy_part(name,loc):
 original=source.objects[name];mapping={}
 for obj in [original]+list(original.children_recursive):
  clone=obj.copy();s.collection.objects.link(clone);mapping[obj]=clone
 for obj,clone in mapping.items():clone.parent=mapping.get(obj.parent)
 mapping[original].location=loc
 return mapping[original]
for x,weapon,chassis in [(-2.4,'autocannon','light_tracks'),(0,'scatter','heavy_tracks'),(2.4,'bubble_cannon','light_tracks')]:
 copy_part(weapon,(x,0,.885));copy_part(chassis,(x,0,0))
 before=set(s.objects)
 bpy.ops.import_scene.gltf(filepath=str(ROOT/'source_art/mechanical-family-v2'/(chassis+'_runtime_tracks.glb')))
 added=set(s.objects)-before
 for obj in added:
  if obj.parent not in added:obj.location.x+=x
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-.005));plane=bpy.context.object
m=bpy.data.materials.new('109 floor');m.diffuse_color=(.11,.13,.17,1);plane.data.materials.append(m)
def aim(obj):obj.rotation_euler=(Vector((0,0,.7))-obj.location).to_track_quat('-Z','Y').to_euler()
for loc,power,size in [((-4,4,7),1700,7),((5,2,5),1100,6),((0,-5,6),1600,5)]:
 d=bpy.data.lights.new('109 softbox','AREA');d.energy=power;d.shape='DISK';d.size=size
 obj=bpy.data.objects.new('109 softbox',d);s.collection.objects.link(obj);obj.location=loc;aim(obj)
d=bpy.data.cameras.new('109 camera');camera=bpy.data.objects.new('109 camera',d);s.collection.objects.link(camera);s.camera=camera;d.type='ORTHO';d.ortho_scale=9.2
for label,loc in [('front',(-4,8,5)),('rear',(4,-8,5)),('side',(-8,1,4))]:
 camera.location=loc;aim(camera)
 s.render.filepath=str(ROOT/'assets/derived/mechanical-family-v2'/('blender-'+label+'.png'))
 bpy.ops.render.render(write_still=True)
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'source_art/mechanical-family-v2/mechanical_family_review.blend'))
result={'renders':['front','rear','side'],'scene':s.name}
