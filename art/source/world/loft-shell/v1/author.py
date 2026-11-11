"""One-time authoring record for the workshop loft's room shell. Refuses an existing editable master.

Run: blender --background --factory-startup --python-exit-code 1 --python art/source/world/loft-shell/v1/author.py
Afterwards model.blend is the authority: edit it in Blender, then scripts/world-art.sh retexture loft-shell
and scripts/world-art.sh build loft-shell. This script is not a second build pipeline.
"""
from pathlib import Path
import hashlib
import json
import math

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
OUTPUT = HERE / 'model.blend'
if OUTPUT.exists():
    raise RuntimeError('Open the existing loft shell master; authoring never overwrites it.')

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.context.preferences.filepaths.save_version = 0
scene = bpy.context.scene

# The room document is 12 by 10 cells (content/areas/workshop-loft.json). One metre is one cell.
# Blender +X is logical x and +Y is logical y (Godot -Z), so the shell sits at the area's origin
# with no rotation. The floor top is at height 0. Only the west and north walls exist: the camera
# looks in from the south-east, so the near sides stay cut away.
W, H = 12, 10
FRONT = 1 - 0.12           # interior.exit[1] - 0.12, the cut front edge of the floor
WEST, NORTH = -0.5, H - 0.5
HATCH = (2.4, 3.6, FRONT, 1.85)   # the stair opening around the exit cell [3, 1]
WALL_TOP = 2.95


def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4


def material(name, color, emission=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    rgb = tuple(linear(int(color[i:i + 2], 16) / 255) for i in (0, 2, 4))
    mat.diffuse_color = (*rgb, 1)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*rgb, 1)
    bsdf.inputs['Roughness'].default_value = .9
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*rgb, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return mat


# Names match pipeline/texture-catalog.json, so `retexture` bakes the painted pictures onto them.
mats = {
    'wood_light': material('wood_light', 'c08a52'),       # floorboards
    'oak_light': material('oak_light', 'a8743f'),         # alternate boards, sills
    'wood_dark': material('wood_dark', '5e3d26'),         # posts, beams, the cut floor edge
    'oak': material('oak', '8a5a3b'),                     # rails, window frames
    'limewash': material('limewash', 'efe4cf'),           # plaster between the timbers
    'timber_panels': material('timber_panels', '7a5233'), # plank wainscot
    'window_warm': material('window_warm', 'ffd99a', 1.2),
    'gold': material('gold', 'c99a3e'),                   # brass caps on the newel posts
}

root = bpy.data.objects.new('loft_shell', None)
scene.collection.objects.link(root)


def put(obj, mat):
    obj.data.materials.clear()
    obj.data.materials.append(mats[mat])
    obj.parent = root
    return obj


def box(name, lo, hi, mat, bevel=0.0):
    lo, hi = Vector(lo), Vector(hi)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(lo + hi) * .5)
    obj = bpy.context.object
    obj.name = name
    obj.scale = hi - lo
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel:
        mod = obj.modifiers.new('Soft arris', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return put(obj, mat)


def beam(name, a, b, width, mat, depth=None):
    a, b = Vector(a), Vector(b)
    bpy.ops.mesh.primitive_cube_add(size=1, location=(a + b) * .5)
    obj = bpy.context.object
    obj.name = name
    obj.scale = (width, depth or width, (b - a).length)
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.rotation_euler = (b - a).to_track_quat('Z', 'Y').to_euler()
    return put(obj, mat)


def polygon(name, points, thickness, axis, at, mat):
    """A flat plate from 2D points, extruded `thickness` along `axis` ('x' or 'y') at `at`."""
    verts, faces = [], []
    n = len(points)
    for offset in (0, thickness):
        for u, v in points:
            verts.append((at + offset, u, v) if axis == 'x' else (u, at + offset, v))
    faces.append(tuple(range(n)))
    faces.append(tuple(reversed(range(n, 2 * n))))
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.validate()
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    scene.collection.objects.link(obj)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode='OBJECT')
    return put(obj, mat)


# ------------------------------------------------------------------ floor
# A thick floor, as in the concept: the cut edge shows the loft's floor-and-ceiling sandwich.
box('Floor slab', (WEST - .12, FRONT - .04, -.62), (W - .5 + .1, NORTH + .1, -.03), 'wood_dark')
box('Cut floor edge', (WEST - .12, FRONT - .1, -.64), (W - .5 + .1, FRONT, .01), 'wood_dark')
x = WEST
board = 0
while x < W - .5 - .01:
    x1 = min(x + .5, W - .5)
    mat = 'wood_light' if board % 3 else 'oak_light'
    if x1 > HATCH[0] and x < HATCH[1]:
        box('Floorboard', (x + .012, HATCH[3], -.03), (x1 - .012, NORTH, .02), mat)
    else:
        box('Floorboard', (x + .012, FRONT, -.03), (x1 - .012, NORTH, .02), mat)
    x = x1
    board += 1
# Boards cut short around the stair opening still cover its sides.
box('Board beside hatch', (2.0, FRONT, -.03), (HATCH[0], HATCH[3], .02), 'wood_light')
box('Board beside hatch', (HATCH[1], FRONT, -.03), (4.0, HATCH[3], .02), 'oak_light')

# ------------------------------------------------------------------ the stair hatch
x0, x1, y0, y1 = HATCH
# The stairs descend inside the floor's thickness; a dark well below suggests the workshop.
box('Stairwell back', (x0, y1 - .06, -.6), (x1, y1, -.02), 'wood_dark')
for side, sx in (('west', x0), ('east', x1 - .06)):
    box('Stairwell side ' + side, (sx, y0, -.6), (sx + .06, y1, -.02), 'wood_dark')
box('Stairwell depth', (x0 + .06, y0, -.62), (x1 - .06, y1 - .06, -.58), 'wood_dark')
for step in range(3):
    top = -.14 - step * .15
    depth = (y1 - y0) / 3
    box('Stair tread', (x0 + .06, y1 - (step + 1) * depth, top - .06), (x1 - .06, y1 - step * depth, top), 'oak_light', .01)
# Newel posts stand exactly where HouseInstances.frame_posts puts the doorway's collision.
for nx in (2.25, 3.75):
    for ny in (1.0, y1 - .02):
        box('Newel post', (nx - .08, ny - .08, 0), (nx + .08, ny + .08, .98), 'oak', .015)
        box('Newel cap', (nx - .1, ny - .1, .98), (nx + .1, ny + .1, 1.04), 'gold', .01)
    box('Hand rail', (nx - .05, .96, .82), (nx + .05, y1 + .04, .92), 'oak', .01)
    for by in (1.25, 1.5):
        box('Baluster', (nx - .025, by - .025, 0), (nx + .025, by + .025, .82), 'oak')

# ------------------------------------------------------------------ west wall
WALL_X = WEST - .06
box('West plaster', (WALL_X - .2, FRONT, 0), (WALL_X, NORTH + .2, WALL_TOP), 'limewash')
box('West wainscot', (WALL_X, FRONT, 0), (WALL_X + .05, NORTH, .82), 'timber_panels')
box('West wainscot rail', (WALL_X, FRONT, .8), (WALL_X + .09, NORTH, .9), 'wood_dark', .01)
for py in (FRONT + .08, 3.4, 6.4, NORTH - .05):
    box('West post', (WALL_X - .02, py - .1, 0), (WALL_X + .14, py + .1, WALL_TOP + .1), 'wood_dark', .015)
box('West top plate', (WALL_X - .04, FRONT, WALL_TOP - .1), (WALL_X + .16, NORTH, WALL_TOP + .12), 'wood_dark', .015)
# Two broad braces, as in the concept: big diagonal timbers in the plaster.
beam('West brace', (WALL_X + .07, FRONT + .2, 1.0), (WALL_X + .07, 3.2, WALL_TOP - .1), .16, 'wood_dark', .12)
beam('West brace', (WALL_X + .07, 6.6, WALL_TOP - .1), (WALL_X + .07, 9.0, 1.0), .16, 'wood_dark', .12)
# The roof rises inward from the top plate: a purlin and three rafters, cut off for the camera.
box('Purlin', (.15, FRONT + .2, 3.72), (.4, NORTH, 3.95), 'wood_dark', .015)
for ry in (2.6, 5.5, 8.4):
    beam('Rafter', (WALL_X + .05, ry, WALL_TOP + .05), (.55, ry, 4.05), .2, 'wood_dark', .16)

# ------------------------------------------------------------------ north wall and gable
WALL_Y = NORTH + .06
box('North plaster', (WEST - .2, WALL_Y, 0), (W - .5 + .1, WALL_Y + .2, WALL_TOP), 'limewash')
box('North wainscot', (WEST, WALL_Y - .05, 0), (W - .5, WALL_Y, .82), 'timber_panels')
box('North wainscot rail', (WEST, WALL_Y - .09, .8), (W - .5, WALL_Y, .9), 'wood_dark', .01)
for px in (WEST + .05, 3.6, 8.0, W - .55):
    box('North post', (px - .1, WALL_Y - .14, 0), (px + .1, WALL_Y + .02, WALL_TOP + .1), 'wood_dark', .015)
box('North top plate', (WEST - .04, WALL_Y - .16, WALL_TOP - .1), (W - .5, WALL_Y + .04, WALL_TOP + .12), 'wood_dark', .015)
# The gable over the bed holds the round porthole window, as in the concept.
GX, GPEAK = 5.6, 4.75
polygon('Gable plaster', [(1.4, WALL_TOP), (9.8, WALL_TOP), (GX, GPEAK)], .2, 'y', WALL_Y, 'limewash')
for a, b in (((1.2, WALL_TOP - .05), (GX, GPEAK + .1)), ((10.0, WALL_TOP - .05), (GX, GPEAK + .1))):
    beam('Gable rafter', (a[0], WALL_Y - .1, a[1]), (b[0], WALL_Y - .1, b[1]), .24, 'wood_dark', .18)
WIN_Z, WIN_R = 3.72, .56
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=WIN_R, depth=.06, location=(GX, WALL_Y - .04, WIN_Z), rotation=(math.pi / 2, 0, 0))
put(bpy.context.object, 'window_warm').name = 'Porthole glass'
bpy.ops.mesh.primitive_torus_add(major_radius=WIN_R + .07, minor_radius=.09, major_segments=28, minor_segments=6,
                                 location=(GX, WALL_Y - .1, WIN_Z), rotation=(math.pi / 2, 0, 0))
put(bpy.context.object, 'oak').name = 'Porthole frame'
box('Porthole mullion', (GX - .035, WALL_Y - .12, WIN_Z - WIN_R), (GX + .035, WALL_Y - .06, WIN_Z + WIN_R), 'oak')
box('Porthole transom', (GX - WIN_R, WALL_Y - .12, WIN_Z - .035), (GX + WIN_R, WALL_Y - .06, WIN_Z + .035), 'oak')
# The dormer's tall window to the east of the gable, with a deep sill for a flowerpot.
DX = 9.4
box('Dormer reveal', (DX - .92, WALL_Y - .2, .95), (DX + .92, WALL_Y, 2.62), 'oak', .015)
box('Dormer glass', (DX - .74, WALL_Y - .23, 1.08), (DX + .74, WALL_Y - .17, 2.5), 'window_warm')
box('Dormer mullion', (DX - .04, WALL_Y - .28, 1.08), (DX + .04, WALL_Y - .2, 2.5), 'oak')
box('Dormer transom', (DX - .74, WALL_Y - .28, 1.86), (DX + .74, WALL_Y - .2, 1.94), 'oak')
box('Dormer sill', (DX - 1.02, WALL_Y - .42, .9), (DX + 1.02, WALL_Y, 1.0), 'oak_light', .015)
box('Dormer head', (DX - 1.02, WALL_Y - .3, 2.58), (DX + 1.02, WALL_Y, 2.72), 'wood_dark', .015)
box('Corner post', (WALL_X - .16, WALL_Y - .16, 0), (WALL_X + .18, WALL_Y + .18, WALL_TOP + .14), 'wood_dark', .02)

# Plain cube-projected UVs; `retexture` replaces them with world-scale ones for the catalogued materials.
for obj in [o for o in scene.objects if o.type == 'MESH']:
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=1)
    bpy.ops.object.mode_set(mode='OBJECT')

scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['rootward_source'] = 'Editable loft shell authority. Authoring script refuses to overwrite it.'
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
(HERE / 'provenance.json').write_text(json.dumps({
    'asset': 'loft-shell', 'version': 'v1', 'date': '2026-10-27',
    'derived_from': None,
    'reference': 'docs/concept/v0.7/art/4-opening/T7a-workshop-loft.wheels.png',
    'authoring_record': 'author.py',
    'authoring_record_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'note': 'New room shell for the Sparks & Machines loft. model.blend is now authority.'
}, indent=2) + '\n')
print('Saved loft shell', OUTPUT)
