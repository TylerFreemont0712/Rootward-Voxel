"""Saved-master edit: Spindle Walk's upper terrace. Copies haverlund-square-ground v7 to v8 (v7 is untouched) and:

  * repaves the terrace floor (z 2) as one scheme (the ragged lawn strips along the outer edge included): limestone flags everywhere, with a cobbled walk from the lane
    steps to the top of Spindle Steps (y 5.5-10.5) and a cobbled spine down the promenade (x 18.5-22.5). The
    outline of the walkable floor is kept exactly: every old floor face is re-cut, never re-drawn. The south park
    lawn is left alone. Faces are cut into 4 m sections so the light budget per mesh is unchanged;
  * runs the city conduit through: from the lane steps along the landing to the top of Spindle Steps, then up the
    spine, with feeds to the clockmaker and apothecary doors and the walk's lamps (same channel as city-power-grid
    v2: recessed bed, bronze rails, glass flagged `power_grid`, service plates at the joints);
  * removes the free-standing pit cheek left behind the clockmaker (x 9.5-13.5 at y 14.5) and closes the rear
    wall behind its plot (x 9.5, y 15.5-24.5), where the sky showed through;
  * closes the open void under the lane steps, the open slot north of them (x 3.5, z 3-4) and the open corner beside
    the upper stair flight.

Nothing the player walks on changes height. Run once with Blender (refuses to overwrite v8):
    blender -b --factory-startup --python terrace_ground.py
"""
from pathlib import Path
import bpy, bmesh, hashlib, json, math
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[5]
SRC = ROOT / 'art/source/world/haverlund-square-ground/v7/model.blend'
DST = ROOT / 'art/source/world/haverlund-square-ground/v8/model.blend'
if DST.exists():
    raise RuntimeError('v8 exists; edit the saved master instead.')
bpy.ops.wm.open_mainfile(filepath=str(SRC))
before = hashlib.sha256(SRC.read_bytes()).hexdigest()
scene = bpy.context.scene

# The terrace floor at z 2: the landing (A) and the promenade with the shop plots (B).
AREAS = [(3.5, -0.5, 21.5, 14.5), (9.5, 9.5, 27.1, 54.5)]
COBBLE_BANDS = [(3.5, 5.5, 20.5, 10.5), (18.5, 5.5, 22.5, 54.5)]
PAVING = ('ground_flags', 'ground_cobbles')
# The ragged lawn strips along the promenade's outer edge are paved too; the south park lawn (landing) stays.
EDGE_LAWN = (20.4, 14.4, 27.6, 51.6)


def inside_any(c, rects, pad=1e-5):
    return any(x0 - pad < c.x < x1 + pad and y0 - pad < c.y < y1 + pad for x0, y0, x1, y1 in rects)


def clip(poly, axis, value, keep_less):
    out = []
    for a, b in zip(poly, poly[1:] + poly[:1]):
        av = a[axis] - value; bv = b[axis] - value
        ina = av <= 1e-7 if keep_less else av >= -1e-7
        inb = bv <= 1e-7 if keep_less else bv >= -1e-7
        if ina:
            out.append(a)
        if ina != inb:
            out.append(a.lerp(b, av / (av - bv)))
    return out


def split_rect(poly, rect):
    """(inside piece or None, outside pieces) of a convex polygon against an axis rectangle."""
    x0, y0, x1, y1 = rect
    outside, inside = [], poly
    for axis, v, less in [(0, x0, False), (0, x1, True), (1, y0, False), (1, y1, True)]:
        rest = clip(inside, axis, v, not less)
        if len(rest) >= 3:
            outside.append(rest)
        inside = clip(inside, axis, v, less)
        if len(inside) < 3:
            return None, [poly]
    return inside, outside


def area(poly):
    return sum((poly[i] - poly[0]).cross(poly[i + 1] - poly[0]).length for i in range(1, len(poly) - 1)) / 2


# --- 1. collect and remove the old terrace floor ---------------------------------------------------------------
floor_polys = []
removed_faces = 0
for obj in list(scene.objects):
    if obj.type != 'MESH' or not obj.data.materials:
        continue
    names = [m.name if m else '' for m in obj.data.materials]
    if not any(n in PAVING or n == 'ground_grass' for n in names):
        continue
    mw = obj.matrix_world
    bm = bmesh.new(); bm.from_mesh(obj.data); bm.faces.ensure_lookup_table()
    doomed = []
    for f in bm.faces:
        pts = [mw @ v.co for v in f.verts]
        c = sum(pts, Vector()) / len(pts)
        mat = names[f.material_index]
        if mat not in PAVING and not (mat == 'ground_grass' and inside_any(c, [EDGE_LAWN])):
            continue
        n = (mw.to_3x3() @ f.normal).normalized()
        if n.z > .99 and abs(c.z - 2.0) < .02 and inside_any(c, AREAS):
            # Keep the face's polygon in world space, flattened exactly onto the floor.
            floor_polys.append([Vector((p.x, p.y, 2.0)) for p in pts])
            doomed.append(f)
    if doomed:
        removed_faces += len(doomed)
        bmesh.ops.delete(bm, geom=doomed, context='FACES')
        if not bm.faces:
            bm.free(); bpy.data.objects.remove(obj, do_unlink=True); continue
        bm.to_mesh(obj.data); obj.data.update()
    bm.free()


# --- 2. re-cut the same outline into the new scheme, leaving channel mouths open -------------------------------
# Conduit routes in area coordinates. Each ends at a doorway, a lamp, a junction or the existing lane-step channel.
ROUTES = [
    ('spindle-landing', [(21.55, 8.0), (3.53, 8.0)]),
    ('spindle-spine', [(20.5, 8.0), (20.5, 53.6)]),
    ('clockmaker-feed', [(20.5, 21.0), (16.25, 21.0)]),
    ('apothecary-feed', [(20.5, 30.0), (16.25, 30.0)]),
    ('walk-lamp-18', [(20.5, 18.0), (25.55, 18.0)]),
    ('walk-lamp-30', [(20.5, 30.0), (25.55, 30.0)]),
    ('walk-lamp-42', [(20.5, 42.0), (25.55, 42.0)]),
    ('walk-lamp-52', [(20.5, 52.5), (25.55, 52.5)]),
]
JOINTS = [(20.5, 8.0), (20.5, 18.0), (20.5, 21.0), (20.5, 30.0), (20.5, 42.0), (20.5, 52.5)]
HALF = .19
channels = []
for _, pts in ROUTES:
    for a, b in zip(pts, pts[1:]):
        channels.append((min(a[0], b[0]) - (HALF if a[0] == b[0] else 0), min(a[1], b[1]) - (HALF if a[1] == b[1] else 0),
                         max(a[0], b[0]) + (HALF if a[0] == b[0] else 0), max(a[1], b[1]) + (HALF if a[1] == b[1] else 0)))
pieces = {'ground_flags': [], 'ground_cobbles': []}
for poly in floor_polys:
    todo = [poly]
    for rect in channels:
        nxt = []
        for q in todo:
            _, outside = split_rect(q, rect)
            nxt.extend(outside)
        todo = nxt
    for q in todo:
        rest = [q]
        for band in COBBLE_BANDS:
            nxt = []
            for r in rest:
                inside, outside = split_rect(r, band)
                if inside is not None and area(inside) > 1e-6:
                    pieces['ground_cobbles'].append(inside)
                nxt.extend(outside)
            rest = nxt
        pieces['ground_flags'].extend(r for r in rest if area(r) > 1e-6)

SCALE = {'ground_flags': 3.0, 'ground_cobbles': 2.0}
CHUNK = 4.0
made = 0
for mat, polys in pieces.items():
    buckets = {}
    for q in polys:
        c = sum(q, Vector()) / len(q)
        key = (math.floor(c.x / CHUNK), math.floor(c.y / CHUNK))
        # Cut each piece on the 4 m grid so every section stays local for the lights.
        xs = [math.floor(min(v.x for v in q) / CHUNK) * CHUNK + CHUNK * i for i in range(1, 30)]
        parts = [q]
        for axis in (0, 1):
            lo = min(v[axis] for v in q); hi = max(v[axis] for v in q)
            g = math.floor(lo / CHUNK) * CHUNK + CHUNK
            while g < hi - 1e-6:
                nxt = []
                for r in parts:
                    a = clip(r, axis, g, True); b = clip(r, axis, g, False)
                    nxt.extend(s for s in (a, b) if len(s) >= 3 and area(s) > 1e-7)
                parts = nxt
                g += CHUNK
        for r in parts:
            cc = sum(r, Vector()) / len(r)
            buckets.setdefault((math.floor(cc.x / CHUNK), math.floor(cc.y / CHUNK)), []).append(r)
    for (cx, cy), polys2 in buckets.items():
        verts, faces, uvs = [], [], []
        for r in polys2:
            n0 = len(verts); verts.extend(r); faces.append(tuple(range(n0, n0 + len(r))))
            uvs.append([(v.x / SCALE[mat], v.y / SCALE[mat]) for v in r])
        name = f'{mat}_terrace_{cx}_{cy}'
        mesh = bpy.data.meshes.new(name); mesh.from_pydata([tuple(v) for v in verts], [], faces); mesh.update()
        mesh.materials.append(bpy.data.materials[mat])
        layer = mesh.uv_layers.new(name='UVMap')
        for poly, cs in zip(mesh.polygons, uvs):
            for li, uv in zip(poly.loop_indices, cs):
                layer.data[li].uv = uv
        obj = bpy.data.objects.new(name, mesh); scene.collection.objects.link(obj); obj['ground_chunk'] = True
        made += 1


# --- 3. walls: the stray pit cheek out, the rear wall behind the clockmaker in --------------------------------
def delete_faces(pred):
    count = 0
    for obj in list(scene.objects):
        if obj.type != 'MESH':
            continue
        mw = obj.matrix_world
        bm = bmesh.new(); bm.from_mesh(obj.data)
        doomed = []
        for f in bm.faces:
            pts = [mw @ v.co for v in f.verts]
            c = sum(pts, Vector()) / len(pts)
            n = (mw.to_3x3() @ f.normal).normalized()
            if pred(obj, c, n, pts):
                doomed.append(f)
        if doomed:
            count += len(doomed)
            bmesh.ops.delete(bm, geom=doomed, context='FACES')
            bm.to_mesh(obj.data); obj.data.update()
        bm.free()
    return count


stray = delete_faces(lambda o, c, n, pts: o.name.startswith('spindle_seaside_stone') and abs(c.y - 14.5) < .03
                     and c.x > 9.52 and abs(n.y + 1) < .05 and 1.95 < c.z < 4.05)
# Copy one 3 m run of the dressed rear wall (its painted block UVs included) three times to fill y 15.5-24.5.
src = bpy.data.objects['frontage_seaside_stone_-2_6']
mw = src.matrix_world
run = []
for poly in src.data.polygons:
    pts = [mw @ src.data.vertices[i].co for i in poly.vertices]
    n = (mw.to_3x3() @ poly.normal).normalized()
    if n.x > .99 and all(abs(p.x - 9.5) < .01 and 24.5 - 1e-4 <= p.y <= 27.5 + 1e-4 for p in pts):
        uv = [tuple(src.data.uv_layers.active.data[li].uv) for li in poly.loop_indices]
        run.append((pts, uv, src.data.materials[poly.material_index].name))
wall_faces = 0
for shift in (-3.0, -6.0, -9.0):
    verts, faces, uvs, mats = [], [], [], []
    for pts, uv, mat in run:
        n0 = len(verts); verts.extend(Vector((p.x, p.y + shift, p.z)) for p in pts); faces.append(tuple(range(n0, n0 + len(pts))))
        uvs.append(uv); mats.append(mat)
    name = f'terrace_rear_wall_{int(-shift)}'
    mesh = bpy.data.meshes.new(name); mesh.from_pydata([tuple(v) for v in verts], [], faces); mesh.update()
    for m in dict.fromkeys(mats):
        mesh.materials.append(bpy.data.materials[m])
    order = list(dict.fromkeys(mats))
    layer = mesh.uv_layers.new(name='UVMap')
    for poly, cs, m in zip(mesh.polygons, uvs, mats):
        poly.material_index = order.index(m)
        for li, uv in zip(poly.loop_indices, cs):
            layer.data[li].uv = uv
    obj = bpy.data.objects.new(name, mesh); scene.collection.objects.link(obj); obj['ground_chunk'] = True
    wall_faces += len(faces)


def stone_box(name, x0, y0, z0, x1, y1, z1, rep=1.9):
    """A plain dressed-stone block (seaside_stone, world-painted) that closes a void behind existing faces."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=Vector((x1 - x0, y1 - y0, z1 - z0)), verts=bm.verts)
    bmesh.ops.translate(bm, vec=Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)), verts=bm.verts)
    layer = bm.loops.layers.uv.new('UVMap')
    for f in bm.faces:
        n = f.normal
        axis = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][axis]
        for loop in f.loops:
            loop[layer].uv = (loop.vert.co[a] / rep, loop.vert.co[b] / rep)
    mesh = bpy.data.meshes.new(name); bm.to_mesh(mesh); bm.free()
    mesh.materials.append(bpy.data.materials['seaside_stone'])
    obj = bpy.data.objects.new(name, mesh); scene.collection.objects.link(obj); obj['ground_chunk'] = True


# The lane steps stood on nothing between the landing wall (top z 3) and their first nosing (z 3.96).
stone_box('terrace_lane_step_base', .3, 5.45, 2.0, 3.48, 10.55, 3.95)
# North of the steps the landing wall (x 3.5) stopped at z 3 under lane paving at z 4: an open slot to the sky.
stone_box('terrace_lane_corner', 2.6, 10.55, 2.0, 3.48, 14.48, 3.99)
# The corner pier where the landing's north wall meets the lower flight was open on its outer faces.
stone_box('terrace_stair_corner', 26.52, 9.51, 0.0, 27.53, 10.49, 1.99)


# --- 4. conduits: the city-power-grid v2 channel, surveyed on the new floor ------------------------------------
for name, col, metal in [('grid_bed', (.075, .09, .085), .45), ('grid_bronze', (.33, .24, .12), .68),
                         ('grid_glass', (.42, .24, .065), .18)]:
    if name not in bpy.data.materials:
        raise RuntimeError('Missing conduit material ' + name)
ground = [o for o in scene.objects if o.type == 'MESH' and o.name.startswith(('ground_', 'seaside_stone', 'spindle_', 'terrace_'))]
verts, faces = [], []
for o in ground:
    n0 = len(verts); verts.extend(o.matrix_world @ v.co for v in o.data.vertices)
    faces.extend(tuple(n0 + i for i in f.vertices) for f in o.data.polygons)
bvh = BVHTree.FromPolygons(verts, faces)
parts = {}


def face(mat, pts, uv=None):
    d = parts.setdefault(mat, [[], [], []]); n = len(d[0]); d[0].extend(pts); d[1].append(tuple(range(n, n + len(pts))))
    d[2].append(uv or [(0, 0)] * len(pts))


def quad(mat, a, b, side, ua=0, ub=1):
    face(mat, [a - side, b - side, b + side, a + side], [(ua, 0), (ub, 0), (ub, 1), (ua, 1)])


def strip(a, b, distance, normal):
    d = b - a; length = d.length
    side = Vector((-d.y, d.x, 0)).normalized() if abs(d.x) + abs(d.y) > 1e-5 else Vector((0, 1, 0))
    a = a + normal * .006; b = b + normal * .006
    quad('grid_bed', a - normal * .018, b - normal * .018, side * HALF, distance, distance + length)
    for off in (-.142, .142):
        quad('grid_bronze', a + side * off, b + side * off, side * .018, distance, distance + length)
    count = max(1, math.ceil(length / .55))
    for i in range(count):
        t0 = (i + .025) / count; t1 = (i + .975) / count
        quad('grid_glass', a.lerp(b, t0) - normal * .004, b.lerp(a, 1 - t1) - normal * .004, side * .082,
             distance + length * t0, distance + length * t1)


audit = []
for name, pts in ROUTES:
    a = Vector((*pts[0], 2.0)); b = Vector((*pts[1], 2.0))
    for q in (a, b):
        # The channel mouths themselves are open, so look for floor in the diagonal corners beside each end.
        probes = [Vector((q.x + dx, q.y + dy, 2.5)) for dx in (-.3, .3) for dy in (-.3, .3)]
        hits = [bvh.ray_cast(pr, Vector((0, 0, -1)), 1.0)[0] for pr in probes]
        if not any(h is not None and abs(h.z - 2.0) < .01 for h in hits):
            raise RuntimeError(f'Route {name} leaves the terrace floor at {tuple(q)}')
    strip(a, b, 0, Vector((0, 0, 1)))
    audit.append({'route': name, 'start': pts[0], 'end': pts[1], 'length': round((b - a).length, 3)})
# The landing channel climbs the face of the new step base to meet the existing lane-step channel (x 3.44, z 3.96).
strip(Vector((3.505, 8.0, 2.0)), Vector((3.505, 8.0, 3.96)), 0, Vector((1, 0, 0)))
audit.append({'route': 'lane-step-riser', 'start': [3.505, 8.0, 2.0], 'end': [3.505, 8.0, 3.96], 'length': 1.96})
for x, y in JOINTS:
    z = 2.009
    face('grid_bronze', [(x - .27, y - .27, z), (x + .27, y - .27, z), (x + .27, y + .27, z), (x - .27, y + .27, z)])
    face('grid_bed', [(x - .23, y - .23, z + .001), (x + .23, y - .23, z + .001), (x + .23, y + .23, z + .001), (x - .23, y + .23, z + .001)])
    for d in ((1, 0), (0, 1)):
        a = Vector((x - d[0] * .21, y - d[1] * .21, z + .002)); b = Vector((x + d[0] * .21, y + d[1] * .21, z + .002))
        quad('grid_glass', a, b, Vector((-d[1] * .06, d[0] * .06, 0)), 0, .42)
    for dx in (-.21, .21):
        for dy in (-.21, .21):
            face('grid_bronze', [(x + dx + math.cos(i * math.pi / 3) * .018, y + dy + math.sin(i * math.pi / 3) * .018, z + .003) for i in range(6)])
for key, (vs, fs, uvs) in parts.items():
    name = key + '_terrace'
    mesh = bpy.data.meshes.new(name); mesh.from_pydata([tuple(v) for v in vs], [], fs); mesh.update()
    layer = mesh.uv_layers.new(name='GridUV')
    for poly, coords in zip(mesh.polygons, uvs):
        for li, co in zip(poly.loop_indices, coords):
            layer.data[li].uv = co
    mesh.materials.append(bpy.data.materials[key])
    obj = bpy.data.objects.new(name, mesh); scene.collection.objects.link(obj)
    obj['grid_inlay'] = True; obj['ground_chunk'] = True
    if key == 'grid_glass':
        obj['power_grid'] = True

scene['spindle_terrace_revision'] = 1
bpy.context.preferences.filepaths.save_version = 0
DST.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(DST))
record = {'previous': 'v7', 'previous_sha256': before, 'record': str(Path(__file__).relative_to(ROOT)),
          'removed_floor_faces': removed_faces, 'new_floor_sections': made,
          'floor_pieces': {k: len(v) for k, v in pieces.items()}, 'stray_wall_faces_removed': stray,
          'rear_wall_faces_added': wall_faces, 'conduit_routes': audit, 'joints': JOINTS,
          'areas': AREAS, 'cobble_bands': COBBLE_BANDS}
(DST.parent / 'terrace.json').write_text(json.dumps(record, indent=2) + '\n')
print('TERRACE GROUND SAVED', json.dumps({k: record[k] for k in ('removed_floor_faces', 'new_floor_sections', 'stray_wall_faces_removed', 'rear_wall_faces_added')}))
