"""Saved-master edit: the square's texture pass. Copies haverlund-square-ground v8 to v9 (v8 is untouched) and:

  * finishes Spindle Steps: the lane flight used to stop on a 2 m block above the terrace (its last tread at z 4.2,
    the terrace at z 2). Ten more 0.2 m steps now carry it down to the terrace floor (x 3.5-5.5, y 5.45-10.55), and
    the conduit follows the treads and risers instead of running straight down the block's face;
  * plants the upper town's gardens: the high ground behind the rear wall (z 4), the plateau west of the steps (z 6)
    and the parapet slab above the arrival lawn (z 3) were bare limestone flags with blocky grass patches. Their flag
    faces become lawn (world-scaled grass UVs, as the rest of the square's lawns), keeping the path off the head of
    the steps. Coping, walls and conduits are untouched.

Nothing walkable changes height. Run once with Blender (refuses to overwrite v9):
    blender -b --factory-startup --python ground_v9.py
"""
from pathlib import Path
import bpy, bmesh, hashlib, json, math
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
SRC = ROOT / 'art/source/world/haverlund-square-ground/v8/model.blend'
DST = ROOT / 'art/source/world/haverlund-square-ground/v9/model.blend'
if DST.exists():
    raise RuntimeError('v9 exists; edit the saved master instead.')
bpy.ops.wm.open_mainfile(filepath=str(SRC))
before = hashlib.sha256(SRC.read_bytes()).hexdigest()
scene = bpy.context.scene

# --- 1. the foot of Spindle Steps -------------------------------------------------------------------------------
Y0, Y1 = 5.45, 10.55
TOP, RISE, TREAD, COUNT = 4.0, 0.2, 0.2, 10      # tread k: x 3.5+0.2k .. 3.7+0.2k, top 4.0-0.2k
X0 = 3.5
bm = bmesh.new()
layer = bm.loops.layers.uv.new('UVMap')
for k in range(COUNT):
    x0 = X0 + TREAD * k; x1 = x0 + TREAD; top = TOP - RISE * k
    geom = bmesh.ops.create_cube(bm, size=1.0)['verts']
    bmesh.ops.scale(bm, vec=Vector((x1 - x0, Y1 - Y0, top - 2.0)), verts=geom)
    bmesh.ops.translate(bm, vec=Vector(((x0 + x1) / 2, (Y0 + Y1) / 2, (top + 2.0) / 2)), verts=geom)
# Drop faces nobody sees (the bottoms on the floor and the backs buried in the step behind) to keep it light.
doomed = [f for f in bm.faces if f.normal.z < -.9 or (f.normal.x < -.9 and f.calc_center_median().x > X0 + 1e-3)]
bmesh.ops.delete(bm, geom=doomed, context='FACES')
for f in bm.faces:
    n = f.normal
    axis = max(range(3), key=lambda i: abs(n[i]))
    a, b = [(1, 2), (0, 2), (0, 1)][axis]
    for loop in f.loops:
        loop[layer].uv = (loop.vert.co[a] / 1.9, loop.vert.co[b] / 1.9)
mesh = bpy.data.meshes.new('spindle_steps_foot'); bm.to_mesh(mesh); bm.free()
mesh.materials.append(bpy.data.materials['seaside_stone'])
steps = bpy.data.objects.new('spindle_steps_foot', mesh); scene.collection.objects.link(steps); steps['ground_chunk'] = True

# The conduit: tread and riser strips at y 8, the same channel as the flight above and the landing below.
HALF = .19
parts = {}


def face(mat, pts, uv):
    d = parts.setdefault(mat, [[], [], []]); n = len(d[0]); d[0].extend(pts); d[1].append(tuple(range(n, n + len(pts)))); d[2].append(uv)


def strip(a, b, normal, distance):
    d = b - a; length = d.length
    side = Vector((0, 1, 0))
    a = a + normal * .006; b = b + normal * .006
    def quad(mat, p, q, s, u0, u1):
        face(mat, [p - s, q - s, q + s, p + s], [(u0, 0), (u1, 0), (u1, 1), (u0, 1)])
    quad('grid_bed', a - normal * .018, b - normal * .018, side * HALF, distance, distance + length)
    for off in (-.142, .142):
        quad('grid_bronze', a + side * off, b + side * off, side * .018, distance, distance + length)
    quad('grid_glass', a.lerp(b, .025) - normal * .004, a.lerp(b, .975) - normal * .004, side * .082,
         distance + length * .025, distance + length * .975)
    return distance + length


dist = 0.0
for k in range(COUNT):
    x0 = X0 + TREAD * k; x1 = x0 + TREAD; top = TOP - RISE * k
    dist = strip(Vector((x0, 8.0, top)), Vector((x1, 8.0, top)), Vector((0, 0, 1)), dist)
    low = top - RISE
    dist = strip(Vector((x1, 8.0, top)), Vector((x1, 8.0, low)), Vector((1, 0, 0)), dist)
for key, (vs, fs, uvs) in parts.items():
    m = bpy.data.meshes.new(key + '_steps_foot'); m.from_pydata([tuple(v) for v in vs], [], fs); m.update()
    uvl = m.uv_layers.new(name='GridUV')
    for poly, coords in zip(m.polygons, uvs):
        for li, co in zip(poly.loop_indices, coords):
            uvl.data[li].uv = co
    m.materials.append(bpy.data.materials[key])
    o = bpy.data.objects.new(key + '_steps_foot', m); scene.collection.objects.link(o)
    o['grid_inlay'] = True; o['ground_chunk'] = True
    if key == 'grid_glass':
        o['power_grid'] = True


# --- 2. the upper gardens ---------------------------------------------------------------------------------------
def garden(c):
    if abs(c.z - 4.0) < .06:
        return (c.x < 9.0 and c.y > 15.0) or (c.x < 15.0 and c.y > 55.0)
    if abs(c.z - 6.0) < .06:
        return c.x < 0.5 and not (4.5 < c.y < 11.5)       # keep the path off the head of the steps
    if abs(c.z - 3.0) < .06:
        return c.y < -0.8 and c.x < 14.5
    return False


grass = bpy.data.materials['ground_grass']
regrassed = 0
for obj in list(scene.objects):
    if obj.type != 'MESH' or not obj.data.uv_layers:
        continue
    names = [s.material.name if s.material else '' for s in obj.material_slots]
    if 'ground_flags' not in names:
        continue
    mw = obj.matrix_world
    hits = []
    for p in obj.data.polygons:
        if names[p.material_index] != 'ground_flags':
            continue
        n = (mw.to_3x3() @ p.normal).normalized()
        if n.z < .99:
            continue
        if garden(mw @ p.center):
            hits.append(p)
    if not hits:
        continue
    if 'ground_grass' not in names:
        obj.data.materials.append(grass); names.append('ground_grass')
    gi = names.index('ground_grass')
    uv = obj.data.uv_layers.active.data
    for p in hits:
        p.material_index = gi
        for li in p.loop_indices:
            w = mw @ obj.data.vertices[obj.data.loops[li].vertex_index].co
            uv[li].uv = (w.x / 8.0, w.y / 8.0)
        regrassed += 1

scene['square_texture_pass'] = 1
bpy.context.preferences.filepaths.save_version = 0
DST.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(DST))
record = {'previous': 'v8', 'previous_sha256': before, 'record': str(Path(__file__).relative_to(ROOT)),
          'steps': {'x': [X0, X0 + TREAD * COUNT], 'y': [Y0, Y1], 'top': TOP, 'rise': RISE, 'count': COUNT},
          'conduit_length': round(dist, 3), 'regrassed_faces': regrassed}
(DST.parent / 'texture-pass.json').write_text(json.dumps(record, indent=2) + '\n')
print('SQUARE GROUND V9 SAVED', json.dumps(record))
