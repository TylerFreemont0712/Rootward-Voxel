"""Render an editable world-asset .blend from the game's camera angle. Review aid only: it opens the source,
adds a temporary ground, camera and sun to the in-memory scene and renders; it never saves the .blend.

    blender --background --factory-startup --python tools/blender_preview.py -- <model.blend> <out.png> [yaw_degrees] [ortho_scale] [look_height]

The camera matches the game's: orthographic, 45 degrees round, about 31 degrees up. `yaw_degrees` turns the model
(90 is how an 'E'-facing building is placed). Blender is Z-up, so Godot's +Z (the cabin's front) is Blender -Y.
"""
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

args = sys.argv[sys.argv.index('--') + 1:]
source, output = Path(args[0]), Path(args[1])
yaw = float(args[2]) if len(args) > 2 else 0.0
scale = float(args[3]) if len(args) > 3 else 7.0
look = float(args[4]) if len(args) > 4 else 1.6

bpy.ops.wm.open_mainfile(filepath=str(source))
scene = bpy.context.scene
for obj in [o for o in scene.objects if o.parent is None]:
    obj.rotation_euler[2] += math.radians(yaw)  # Godot +Z -> +X is Blender -Y -> +X: a quarter turn counter-clockwise about Z

ground_mesh = bpy.data.meshes.new('preview_ground')
ground_mesh.from_pydata([(-6, -6, 0), (6, -6, 0), (6, 6, 0), (-6, 6, 0)], [], [(0, 1, 2, 3)])
ground = bpy.data.objects.new('preview_ground', ground_mesh)
material = bpy.data.materials.new('preview_grass')
material.diffuse_color = (0.39, 0.55, 0.25, 1.0)
material.use_nodes = True
bsdf = next(node for node in material.node_tree.nodes if node.type == 'BSDF_PRINCIPLED')
bsdf.inputs['Base Color'].default_value = (0.12, 0.26, 0.07, 1.0)
bsdf.inputs['Roughness'].default_value = 1.0
ground_mesh.materials.append(material)
scene.collection.objects.link(ground)
ground.location.z = -0.001

camera_data = bpy.data.cameras.new('preview_camera')
camera_data.type = 'ORTHO'
camera_data.ortho_scale = scale
camera = bpy.data.objects.new('preview_camera', camera_data)
scene.collection.objects.link(camera)
target = Vector((0.0, 0.0, look))
camera.location = target + Vector((21.0, -21.0, 17.8))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.clip_end = 200.0
scene.camera = camera

sun_data = bpy.data.lights.new('preview_sun', 'SUN')
sun_data.energy = 3.2
sun_data.angle = math.radians(2.0)
sun = bpy.data.objects.new('preview_sun', sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (math.radians(48), 0.0, math.radians(-55))

world = scene.world or bpy.data.worlds.new('preview_world')
scene.world = world
world.use_nodes = True  # deprecated in Blender 6; revisit when the pinned Blender moves
background = next(node for node in world.node_tree.nodes if node.type == 'BACKGROUND')
background.inputs['Color'].default_value = (0.35, 0.43, 0.55, 1.0)
background.inputs['Strength'].default_value = 0.9

scene.render.resolution_x = 1000
scene.render.resolution_y = 900
scene.render.film_transparent = False
scene.render.filepath = str(output)
scene.render.image_settings.file_format = 'PNG'
for engine in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT', 'BLENDER_WORKBENCH'):
    try:
        scene.render.engine = engine
        break
    except TypeError:
        continue
output.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.render.render(write_still=True)
print('Preview rendered with', scene.render.engine, '->', output)
