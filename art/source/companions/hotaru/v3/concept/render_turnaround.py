"""Render Hotaru's concept turnaround from the robot's editable Blender source. Never saves the source.

Run: blender --background --factory-startup --python art/source/companions/hotaru/v3/concept/render_turnaround.py
Writes renders/<mode>-<angle>.png (transparent) and renders/portrait-base.png for the painted portrait.
"""
from pathlib import Path
import math

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[6]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / 'art/source/world/hotaru-robot/v1/model.blend'
OUT = HERE / 'renders'
OUT.mkdir(exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene = bpy.context.scene
for engine in ('BLENDER_EEVEE', 'BLENDER_EEVEE_NEXT', 'CYCLES'):
    try:
        scene.render.engine = engine
        break
    except TypeError:
        continue
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 768
scene.view_settings.view_transform = 'Standard'
scene.world = bpy.data.worlds.new('Soft studio')
scene.world.color = (.55, .55, .58)

def light(name, kind, energy, rotation, color, size=1.0):
    data = bpy.data.lights.new(name, kind)
    data.energy = energy
    data.color = color
    if kind == 'SUN':
        data.angle = math.radians(size)
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.rotation_euler = [math.radians(a) for a in rotation]
    return obj

light('Warm key', 'SUN', 3.2, (52, 0, -38), (1.0, .93, .82), 12)
light('Cool fill', 'SUN', 1.1, (65, 0, 140), (.78, .85, 1.0), 30)
light('Rim', 'SUN', 1.6, (110, 0, 175), (1.0, .95, .9), 8)

camera_data = bpy.data.cameras.new('Turnaround')
camera_data.type = 'ORTHO'
camera = bpy.data.objects.new('Turnaround', camera_data)
scene.collection.objects.link(camera)
scene.camera = camera
legs = bpy.data.objects['legs']
leg_parts = [o for o in bpy.data.objects if o.parent == legs]
centre = Vector((0, 0, .19))

def shoot(name, azimuth, elevation, scale, target=centre):
    angle, tilt = math.radians(azimuth), math.radians(elevation)
    direction = Vector((math.sin(angle) * math.cos(tilt), -math.cos(angle) * math.cos(tilt), math.sin(tilt)))
    camera.location = target + direction * 3
    camera.rotation_euler = (-direction).to_track_quat('-Z', 'Y').to_euler()
    camera_data.ortho_scale = scale
    scene.render.filepath = str(OUT / (name + '.png'))
    bpy.ops.render.render(write_still=True)

views = {'front': 0, 'front-34': 40, 'side': 90, 'back-34': 140, 'back': 180}
for mode in ('following', 'working'):
    for part in leg_parts:
        part.hide_render = mode == 'following'
    for label, azimuth in views.items():
        shoot(f'{mode}-{label}', azimuth, 12, .46)
for part in leg_parts:
    part.hide_render = True
# The dialogue portrait is painted over a tall three-quarter render with an empty
# spark window. Eyes are drawn afterwards from the projected positions saved here,
# so all six expressions share one painting.
import json
from bpy_extras.object_utils import world_to_camera_view
scene.render.resolution_x, scene.render.resolution_y = 896, 1152
eyes = [o for o in bpy.data.objects if o.name.startswith('Spark eye')]
for eye in eyes:
    eye.hide_render = True
shoot('portrait-base', 22, 12, .44, Vector((0, 0, .19)))
def pixel(point):
    p = world_to_camera_view(scene, camera, point)
    return [round(p.x * 896, 1), round((1 - p.y) * 1152, 1)]
window = bpy.data.objects['Spark window']
centres = sorted((eye.matrix_world.translation for eye in eyes), key=lambda v: v.x)
rim = window.matrix_world.translation
(OUT / 'portrait-base.json').write_text(json.dumps({
    'size': [896, 1152],
    'eyes': [pixel(c) for c in centres],
    'eye_height_px': round(pixel(centres[0] + Vector((0, 0, .0115)))[1] - pixel(centres[0] - Vector((0, 0, .0115)))[1], 1) * -1,
    'window_centre': pixel(rim),
    'window_radius_px': round(abs(pixel(rim + Vector((.04, 0, 0)))[0] - pixel(rim)[0]), 1),
}, indent=2) + '\n')
print('Rendered turnaround into', OUT)
