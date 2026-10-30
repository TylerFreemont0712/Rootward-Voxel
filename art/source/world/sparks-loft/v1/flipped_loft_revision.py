"""Deliberate edit of the adopted loft shell, preserving the previous master as model.pre-flip.blend.

The loft is the workshop's upper floor, seen from the yard side: its back-left wall is the street wall (three
windows, as on the lane) and its back-right wall the yard gable (the round window, centred, and two windows). The
room grows from 12 by 10 to 14 by 12 to match the workshop floor below, and the stair now comes up through a
railed opening in the middle of the floor instead of a hatch at the front edge.

Existing pieces are kept and moved where they still apply (walls, plates, wainscot, posts, braces, rafters,
purlin, gable, the round window and the tall window); the new windows are copies of the tall window's own parts.
Only the floorboards, the floor structure and the stair hatch are rebuilt, with the same materials.

Run: blender --background --python-exit-code 1 --python art/source/world/sparks-loft/v1/flipped_loft_revision.py
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import shutil
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SOURCE = ROOT / 'art/source/world/loft-shell/v1/model.blend'
BACKUP = SOURCE.with_name('model.pre-flip.blend')
NOTE = SOURCE.with_name('flip-revision.json')
if NOTE.exists() or BACKUP.exists():
    raise RuntimeError('This deliberate shell edit already ran; edit the saved master instead.')

W, H = 14, 12                                  # content/areas/workshop-loft.json
WEST, NORTH, EAST, FRONT = -.5, H - .5, W - .5, -.5
OPEN = (6.4, 7.6, 2.56, 5.86)                  # the stair opening: x0, x1, y0 (low end), y1 (top, where you step off)
TREAD = .33                                    # ten treads, as in the area's stairwell profile
STREET_WINDOWS = (1.0, 5.5, 9.1)               # centres along the street wall (y)
GABLE_WINDOWS = (4.0, 10.0)                    # centres along the yard gable (x); the tall window was at 9.4
OCULUS_X = 6.5
OLD_WINDOW_X, OLD_OCULUS_X = 9.4, 5.6

before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
shutil.copy2(SOURCE, BACKUP)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0
spec = importlib.util.spec_from_file_location('loft_author_helpers', HERE / 'author.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
h.PARENT = bpy.data.objects['loft_shell']
for role in ('oak', 'wood', 'wood_dark', 'wood_edge', 'plaster', 'wainscot', 'brass', 'window_view', 'panel_seam'):
    h.M[role] = bpy.data.materials['loft_' + role]
objects = {o.name: o for o in bpy.context.scene.objects if o.type == 'MESH'}


def remove(prefixes):
    for name, obj in list(objects.items()):
        if name.startswith(prefixes):
            bpy.data.objects.remove(obj, do_unlink=True)
            del objects[name]


def reshape(name, fn):
    """Moves each vertex of a kept piece through fn((x, y, z)) in world space."""
    obj = objects[name]
    world, inverse = obj.matrix_world.copy(), obj.matrix_world.inverted()
    for v in obj.data.vertices:
        v.co = inverse @ Vector(fn(world @ v.co))
    obj.data.update()


def along_street(p):
    """The street wall's run: its old front end (y .88) moves to the new front, its back end two cells back."""
    return p[0], p[1] + (FRONT - .88 if p[1] < 5 else 2.0), p[2]


def move(name, dx=0.0, dy=0.0):
    objects[name].matrix_world = Matrix.Translation((dx, dy, 0)) @ objects[name].matrix_world


def copy(name, transform, new_name, uv=None):
    src = objects[name]
    obj = src.copy()
    obj.data = src.data.copy()
    obj.name = new_name
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = transform @ src.matrix_world
    if uv and obj.data.uv_layers:
        layer = obj.data.uv_layers.active
        for loop in layer.data:
            loop.uv = (uv[0] + loop.uv[0] * (uv[1] - uv[0]), .08 + loop.uv[1] * .84)
    objects[new_name] = obj
    return obj


# --- The yard gable (back right) moves back two cells and widens to the new room; posts follow the windows.
for name in ('North plaster', 'North wainscot', 'North wainscot rail', 'North top plate'):
    reshape(name, lambda p: (p[0] + 2 if p[0] > 5 else p[0], p[1] + 2, p[2]))
move('Corner post', dy=2)
for name, x in (('North post', -.45), ('North post.001', 5.0), ('North post.002', 8.3), ('North post.003', 13.45)):
    old = (objects[name].matrix_world @ Vector(objects[name].bound_box[0])).x + .1
    move(name, dx=x - old, dy=2)
for name, x in (('North post chamfer highlight', 4.93), ('North post chamfer highlight.001', 8.23)):
    old = (objects[name].matrix_world @ Vector(objects[name].bound_box[0])).x
    move(name, dx=x - old, dy=2)
scale = 4.9 / 4.2                            # the gable's half-width grows with the room; its slope stays
for name in ('Gable plaster', 'Gable rafter', 'Gable rafter.001'):
    reshape(name, lambda p: (OCULUS_X + (p[0] - OLD_OCULUS_X) * scale, p[1] + 2, 2.95 + (p[2] - 2.95) * scale))
for name in ('Porthole frame', 'Porthole harbour view', 'Porthole mullion', 'Porthole transom'):
    move(name, dx=OCULUS_X - OLD_OCULUS_X, dy=2)
WINDOW_PARTS = ('Dormer glass', 'Dormer head', 'Dormer mullion', 'Dormer reveal', 'Dormer sill', 'Dormer transom')
for name in WINDOW_PARTS:
    move(name, dx=GABLE_WINDOWS[1] - OLD_WINDOW_X, dy=2)
# A second gable window, a copy of the tall window's own parts, with its own part of the painted view.
centre_now = Vector((GABLE_WINDOWS[1], NORTH, 0))
for name in WINDOW_PARTS:
    copy(name, Matrix.Translation((GABLE_WINDOWS[0] - GABLE_WINDOWS[1], 0, 0)), 'Gable window ' + name.split()[1],
         (.05, .55) if name == 'Dormer glass' else None)

# --- The street wall (back left) runs the full twelve cells, with three windows turned from the same parts.
for name in ('West plaster', 'West wainscot', 'West wainscot rail', 'West top plate'):
    reshape(name, along_street)
for name, y in (('West post', -.4), ('West post.001', 3.2), ('West post.002', 7.6), ('West post.003', 11.45)):
    old = (objects[name].matrix_world @ Vector(objects[name].bound_box[0])).y + .1
    move(name, dy=y - old)
for name, (a0, a1, b0, b1) in (('West brace', (1.04, 3.24, 6.48, 7.5)), ('West brace.001', (6.56, 9.04, 10.08, 11.35))):
    reshape(name, lambda p, a0=a0, a1=a1, b0=b0, b1=b1: (p[0], b0 + (p[1] - a0) * (b1 - b0) / (a1 - a0), p[2]))
for name, y in (('Rafter', 3.2), ('Rafter.001', 7.6), ('Rafter.002', 11.0)):
    old = (objects[name].matrix_world @ Vector(objects[name].bound_box[0])).y + .1
    move(name, dy=y - old)
copy('Rafter', Matrix.Translation((0, -.2 - 3.2, 0)), 'Rafter.front')
reshape('Purlin', along_street)
turn = Matrix.Rotation(math.pi / 2, 4, 'Z')
for i, y in enumerate(STREET_WINDOWS):
    place = Matrix.Translation((WEST - .06, y, 0)) @ turn @ Matrix.Translation((-centre_now.x, -(NORTH + .06), 0))
    for name in WINDOW_PARTS:
        copy(name, place, 'Street window %d %s' % (i, name.split()[1]), ((.0, .5), (.25, .75), (.5, 1.0))[i] if name == 'Dormer glass' else None)

# --- Floor: the structure and honey boards around a mid-room stair opening.
remove(('Floor structure', 'Staggered honey floorboard', 'Stair tread', 'Stairwell', 'Newel', 'Hand rail', 'Baluster', 'Wainscot board seams'))
x0, x1, y0, y1 = OPEN
for name, lo, hi in (('Floor structure front', (WEST - .12, FRONT - .12, -.62), (EAST + .1, y0, -.03)),
                     ('Floor structure rear', (WEST - .12, y1, -.62), (EAST + .1, NORTH + .1, -.03)),
                     ('Floor structure west', (WEST - .12, y0, -.62), (x0, y1, -.03)),
                     ('Floor structure east', (x1, y0, -.62), (EAST + .1, y1, -.03))):
    h.box(name, tuple((a + b) / 2 for a, b in zip(lo, hi)), tuple(b - a for a, b in zip(lo, hi)), 'wood_dark', .012)
boards = []
for col in range(int((EAST - WEST) / .5)):
    bx0 = WEST + col * .5
    bx1 = bx0 + .5
    offset = (col % 3) * .93
    cuts = [FRONT] + [v for v in (1.6 + offset, 4.6 + offset, 7.6 + offset, 10.6 + offset) if FRONT < v < NORTH] + [NORTH]
    for ya, yb in zip(cuts, cuts[1:]):
        patches = []
        if bx1 > x0 and bx0 < x1 and yb > y0 and ya < y1:
            if bx0 < x0: patches.append((bx0, x0, ya, yb))
            if bx1 > x1: patches.append((x1, bx1, ya, yb))
            mid = (max(bx0, x0), min(bx1, x1))
            if ya < y0: patches.append((mid[0], mid[1], ya, y0))
            if yb > y1: patches.append((mid[0], mid[1], y1, yb))
        else:
            patches.append((bx0, bx1, ya, yb))
        for xa, xb, ya2, yb2 in patches:
            if xb - xa > .03 and yb2 - ya2 > .03:
                boards.append(h.box('Staggered honey floorboard', ((xa + xb) / 2, (ya2 + yb2) / 2, -.005), (xb - xa - .014, yb2 - ya2 - .014, .05), 'oak', .008, 1))
bpy.ops.object.select_all(action='DESELECT')
for b in boards:
    b.select_set(True)
bpy.context.view_layer.objects.active = boards[0]
bpy.ops.object.join()
bpy.context.object.name = 'Staggered honey floorboards'

# --- The stair opening: dark sides, a trimmer at the low end, treads stepping down toward the front, and a
# railing on three sides with brass-capped newels. You step off at the north end, which stays open.
for name, lo, hi in (('Stairwell side west', (x0, y0, -1.66), (x0 + .06, y1, -.02)),
                     ('Stairwell side east', (x1 - .06, y0, -1.66), (x1, y1, -.02)),
                     ('Stairwell back', (x0, y1 - .06, -.62), (x1, y1, -.02)),
                     ('Stairwell trimmer', (x0, y0, -.62), (x1, y0 + .06, -.02)),
                     ('Stairwell depth', (x0 + .06, y0, -1.7), (x1 - .06, y1, -1.64))):
    h.box(name, tuple((a + b) / 2 for a, b in zip(lo, hi)), tuple(b - a for a, b in zip(lo, hi)), 'wood_dark', 0)
depth = TREAD
for k in range(10):
    top = -.14 - .15 * k
    ya, yb = y1 - (k + 1) * depth, y1 - k * depth
    if ya < y0: break
    h.box('Stair tread', ((x0 + x1) / 2, (ya + yb) / 2, top - .03), (x1 - x0 - .12, yb - ya + .01, .06), 'oak', .012, 1)
    h.box('Stair riser', ((x0 + x1) / 2, ya + .015, top - .11), (x1 - x0 - .14, .03, .16), 'wood_dark', 0)
rail_x = (x0 - .08, x1 + .08)
rail_y0 = y0 - .08
for x in rail_x:
    for y in (rail_y0, y1):
        h.box('Newel post', (x, y, .49), (.16, .16, .98), 'wood', .02)
        h.box('Newel cap', (x, y, 1.01), (.2, .2, .06), 'brass', .015)
    h.box('Hand rail', (x, (rail_y0 + y1) / 2, .87), (.1, y1 - rail_y0, .1), 'wood', .02)
    n = int((y1 - rail_y0) / .3)
    for i in range(1, n):
        h.box('Baluster', (x, rail_y0 + i * (y1 - rail_y0) / n, .41), (.05, .05, .82), 'wood', 0)
h.box('Hand rail', ((x0 + x1) / 2, rail_y0, .87), (rail_x[1] - rail_x[0], .1, .1), 'wood', .02)
for i in range(1, 4):
    h.box('Baluster', (rail_x[0] + i * (rail_x[1] - rail_x[0]) / 4, rail_y0, .41), (.05, .05, .82), 'wood', 0)

# --- Wainscot seams along both walls, then the painted plaster and wainscot mapping for every reshaped piece.
seams = []
y = FRONT + .1
while y < NORTH - .05:
    seams.append(h.box('West wainscot seam', (-.495, y, .42), (.008, .007, .72), 'panel_seam', 0))
    y += .255
x = WEST + .1
while x < EAST - .05:
    seams.append(h.box('North wainscot seam', (x, NORTH - .007, .42), (.007, .008, .72), 'panel_seam', 0))
    x += .265
bpy.ops.object.select_all(action='DESELECT')
for s in seams:
    s.select_set(True)
bpy.context.view_layer.objects.active = seams[0]
bpy.ops.object.join()
bpy.context.object.name = 'Wainscot board seams'
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH' or not obj.data.materials:
        continue
    kind = obj.data.materials[0].name
    if kind not in ('loft_plaster', 'loft_wainscot'):
        continue
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name='Painted surface')
    for p in obj.data.polygons:
        axis = 0 if abs(p.normal.x) > .7 else 1
        for li in p.loop_indices:
            v = obj.matrix_world @ obj.data.vertices[obj.data.loops[li].vertex_index].co
            horizontal = v.y if axis == 0 else v.x
            uv.data[li].uv = (horizontal / 4, v.z / 4) if kind == 'loft_plaster' else (v.z / 1.8, horizontal / 1.3)

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
NOTE.write_text(json.dumps({
    'date': '2026-10-28', 'source_before_sha256': before, 'preserved_source': BACKUP.name,
    'edit_record': 'art/source/world/sparks-loft/v1/flipped_loft_revision.py',
    'size': [W, H], 'stair_opening': list(OPEN), 'street_windows_y': list(STREET_WINDOWS), 'gable_windows_x': list(GABLE_WINDOWS),
    'note': 'Deliberate source edit after the Spindle Lane review: the loft seen from the yard side, 14 by 12 over the workshop floor, three street windows and two gable windows to match the lane, and the stair opening in the middle of the floor. Walls, posts, plates, wainscot, braces, rafters, purlin, gable and windows are the adopted pieces, moved; new windows copy the tall window; floorboards, floor structure and the stair opening are rebuilt in the same materials.',
}, indent=2) + '\n')
print('Flipped and enlarged the adopted loft shell; previous master preserved at', BACKUP)
