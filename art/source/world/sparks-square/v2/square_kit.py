"""Shared helpers for the one-time authoring of Guildhall Square (concept docs/concept/v0.72/art/guildhall-square.png).

Imported by author_landmarks.py, author_props.py and author_set.py. Each refuses an existing master; after
authoring, a model.blend is the editable authority and exports only through scripts/world-art.sh build <id>.
The square reuses the lane pack's palette, painted surfaces and primitives (lane_kit), so the street above and the
square below read as one town. Blender +X is logical +x (east), +Y logical +y (north), +Z up. The set is authored in
area coordinates; buildings and props sit on their own origin at ground height.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import sys
import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE.parents[1] / 'sparks-lane/v1'))
import lane_kit as k  # noqa: E402

h = k.h
REF = 'docs/concept/v0.72/art/guildhall-square.png'
ROOF_RED = ('terracotta', 'terracotta_light', 'terracotta_dark', 'terracotta')
ROOF_COPPER = ('copper', 'copper_light', 'copper_dark', 'copper')

EXTRA = {
    'copper': '5f9b8a', 'copper_light': '6ea795', 'copper_dark': '528b7c', 'banner': '2f6b67', 'banner_dark': '24524f',
    'enamel_red': 'c23f33', 'enamel_red_dark': '922d26', 'canvas': 'efe7d2', 'canvas_shade': 'd9cdb2',
    'orange': 'e3902f', 'apple': 'c4473b', 'pear': 'b9c35b', 'lemon': 'ecd05a', 'plum_fruit': '6e4a6a',
    'bread': 'cd8f4a', 'bread_dark': 'a76a34', 'pigeon': '8d9396', 'pigeon_dark': '666c70', 'slate': '58646b',
    'root': '98673f', 'root_light': 'be8e55', 'stone_dark': 'b3a17f',
}


def begin(asset):
    """A fresh scene with the lane palette, its painted surfaces and the square's own few colours."""
    parent = k.start(asset, 'square')
    for name, colour in EXTRA.items():
        h.material(name, colour)
    h.material('spark', 'ffc867', emission=1.8)
    h.material('spark_core', 'ffe9b0', emission=2.2)
    h.material('spark_face', 'eea13c', emission=.9)
    h.material('eye', 'fffcef', emission=2.4)
    h.material('gold', 'd8b45f', metallic=.35)
    # The beacon's bell: amber glass you can see the root through. "glass" keeps illustrated edges off it.
    glass = h.material('beacon_glass', 'ffb54d', emission=.55)
    glass.diffuse_color = (*glass.diffuse_color[:3], .42)
    glass.node_tree.nodes.get('Principled BSDF').inputs['Alpha'].default_value = .42
    if hasattr(glass, 'surface_render_method'):
        glass.surface_render_method = 'BLENDED'
    for name in list(EXTRA) + ['spark', 'spark_core', 'spark_face', 'eye', 'gold', 'beacon_glass']:
        k.M[name].name = 'square_' + name
    return parent


def save(asset, record, keep_separate=()):
    """Batches static pieces by material and saves the editable master with its authoring provenance."""
    groups = {}
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH':
            continue
        semantic = obj.name if any(obj.name.startswith(name) for name in keep_separate) else 'static'
        groups.setdefault((semantic, obj.data.materials[0].name), []).append(obj)
    for (semantic, mat), objects in groups.items():
        names = [o.name for o in objects]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:
            o.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        if len(objects) > 1:
            bpy.ops.object.join()
        o = bpy.context.object
        o.name = semantic if semantic != 'static' else mat
        o['authored_parts'] = names[:40]
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    scene['rootward_source'] = 'Editable authority after the Guildhall Square concept. Do not rerun the authoring record.'
    bpy.ops.file.pack_all()
    folder = ROOT / 'art/source/world' / asset / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    note = {'asset': asset, 'date': '2026-10-29', 'reference': REF,
            'authoring_record': 'art/source/world/sparks-square/v2/' + record,
            'authoring_record_sha256': hashlib.sha256((HERE / record).read_bytes()).hexdigest(),
            'kit_sha256': hashlib.sha256((HERE / 'square_kit.py').read_bytes()).hexdigest(),
            'shared_kit': 'art/source/world/sparks-lane/v1/lane_kit.py',
            'shared_kit_sha256': hashlib.sha256(Path(k.__file__).read_bytes()).hexdigest(),
            'note': 'New bespoke authored asset; model.blend is now authority. Build through scripts/world-art.sh.'}
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', asset, flush=True)


def selected(all_assets):
    """The assets named after `--` on the Blender command line (all of them when none are named), each refused if
    its editable master already exists."""
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    chosen = [a for a in all_assets if not argv or a in argv]
    for asset in chosen:
        if (ROOT / 'art/source/world' / asset / 'v1/model.blend').exists():
            raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + asset)
    return chosen


# --- geometry ------------------------------------------------------------------------------------------------------
def add_mesh(b, mat, verts, faces):
    """Custom geometry into a batch's bmesh for `mat`, so it shares the batch's UVs and joining."""
    mesh = bpy.data.meshes.new('tmp')
    mesh.from_pydata([tuple(v) for v in verts], [], faces)
    mesh.update()
    b._bm(mat).from_mesh(mesh)
    bpy.data.meshes.remove(mesh)


def prism(b, mat, polygon, z0, z1):
    """A convex polygon [(x, y), ...] (counter-clockwise) extruded from z0 to z1."""
    n = len(polygon)
    verts = [(x, y, z0) for x, y in polygon] + [(x, y, z1) for x, y in polygon]
    faces = [tuple(range(n - 1, -1, -1)), tuple(range(n, 2 * n))]
    for i in range(n):
        j = (i + 1) % n
        faces.append((i, j, n + j, n + i))
    add_mesh(b, mat, verts, faces)


def octagon_points(apothem, centre=(0, 0)):
    """An octagon whose faces look along the four axes and the four diagonals (so one faces the camera)."""
    radius = apothem / math.cos(math.pi / 8)
    return [(centre[0] + radius * math.cos(math.pi / 8 + i * math.pi / 4), centre[1] + radius * math.sin(math.pi / 8 + i * math.pi / 4)) for i in range(8)]


def octagon(b, mat, z0, z1, apothem, centre=(0, 0)):
    prism(b, mat, octagon_points(apothem, centre), z0, z1)


def face_frame(angle, apothem, centre=(0, 0)):
    """The centre of an octagon face facing `angle` (radians) and its outward and along unit vectors."""
    out = Vector((math.cos(angle), math.sin(angle), 0))
    along = Vector((-out.y, out.x, 0))
    return Vector((centre[0], centre[1], 0)) + out * apothem, out, along


def basis_rotation(u, v, n):
    return Matrix((u, v, n)).transposed().to_euler()


def slope_tiles(b, rng, eave_mid, along, up, w0, w1, length, tones=ROOF_RED, row=.27, width=.31, lift=.07, thick=.05, bevel=.018, span=None):
    """Rows of overlapping tiles on one roof slope of any shape: the slope starts at its eave edge (centred on
    `eave_mid`, `w0` wide along `along`) and climbs `length` along `up` to an edge `w1` wide, so hips are
    trapezoids or triangles. `span` = (a0, a1, b0, b1) gives the eave and top edges' ends along `along` instead,
    for a slope cut square at one end. The outside of the slope is along x up."""
    u, v = Vector(along).normalized(), Vector(up).normalized()
    n = u.cross(v)
    a0, a1, b0, b1 = span or (-w0 / 2, w0 / 2, -w1 / 2, w1 / 2)
    rows = max(2, int(length / row) + 1)
    row_length = length / rows
    vt = v * math.cos(lift) + n * math.sin(lift)
    rot = basis_rotation(u, vt, n * math.cos(lift) - v * math.sin(lift))
    for r in range(rows):
        t = (r + .5) / rows
        lo, hi = a0 + (b0 - a0) * t, a1 + (b1 - a1) * t
        w = hi - lo
        if w < width * .45:
            continue
        count = max(1, int(w / width))
        step = w / count
        shift = step * .5 if r % 2 else 0
        for c in range(count + (1 if r % 2 else 0)):
            s = lo + step * (c + .5) - shift
            if s < lo + step * .2 or s > hi - step * .2:
                continue
            p = Vector(eave_mid) + v * (length * t) + n * .045 + u * s
            b.box(tones[rng.randrange(len(tones))], tuple(p), (step * .94, row_length * 1.22, thick), bevel, rot, 1)


def slope_deck(b, mat, eave_mid, along, up, w0, w1, length, thick=.08, span=None):
    """The solid deck under a slope, the same trapezoid as its tiles."""
    u, v = Vector(along).normalized(), Vector(up).normalized()
    n = u.cross(v)
    e = Vector(eave_mid)
    a0, a1, b0, b1 = span or (-w0 / 2, w0 / 2, -w1 / 2, w1 / 2)
    top = [e + u * a0, e + u * a1, e + v * length + u * b1, e + v * length + u * b0]
    if b1 - b0 < 1e-3:
        top = top[:3]
    bottom = [p - n * thick for p in top]
    m = len(top)
    faces = [tuple(range(m)), tuple(range(2 * m - 1, m - 1, -1))]
    for i in range(m):
        j = (i + 1) % m
        faces.append((j, i, m + i, m + j))
    add_mesh(b, mat, top + bottom, faces)


def roof_slope(b, rng, eave_mid, along, up, w0, w1, length, tones=ROOF_RED, cheap=False, deck='terracotta_dark', span=None):
    slope_deck(b, deck, eave_mid, along, up, w0, w1, length, span=span)
    if cheap:
        slope_tiles(b, rng, eave_mid, along, up, w0, w1, length, tones, row=.42, width=.5, bevel=0, thick=.06, span=span)
    else:
        slope_tiles(b, rng, eave_mid, along, up, w0, w1, length, tones, span=span)


def half_disc_pane(name, mat, centre, radius, facing, sides=16):
    """The upper half of a round pane (a fanlight), its picture mapped across the half disc."""
    fx, fy = facing
    across = Vector((-fy, fx, 0))
    c = Vector(centre)
    points, uvs = [c], [(.5, 0)]
    for i in range(sides + 1):
        t = math.pi * i / sides
        points.append(c + across * math.cos(t) * radius + Vector((0, 0, math.sin(t) * radius)))
        uvs.append((.5 + .5 * math.cos(t), math.sin(t)))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(p) for p in points], [], [(0, 1 + i, 2 + i) for i in range(sides)])
    mesh.update()
    for poly in mesh.polygons:
        if poly.normal.dot(Vector((fx, fy, 0))) < 0:
            poly.flip()
    mesh.update()
    layer = mesh.uv_layers.new(name='Whole pane')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            layer.data[li].uv = uvs[mesh.loops[li].vertex_index]
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def dome(name, at, rx, rz, mat, segments=32, rings=16):
    """The upper half of an ellipsoid, open at its foot, smooth, with UVs wrapped round it."""
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=segments, v_segments=rings, radius=1.0)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -1e-4], context='VERTS')
    bmesh.ops.scale(bm, vec=(rx, rx, rz), verts=bm.verts)
    layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        for loop in f.loops:
            co = loop.vert.co
            loop[layer].uv = (math.atan2(co.y, co.x) / math.tau + .5, co.z / max(rz, 1e-3))
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = at
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat, True)


def hip_roof(b, rng, x0, x1, y0, y1, z, pitch, tones=ROOF_RED, cheap=False, deck='terracotta_dark', cap='terracotta_dark'):
    """A hipped roof over the rectangle: four slopes meeting at a ridge along the longer side. Returns the ridge
    height."""
    lx, ly = x1 - x0, y1 - y0
    run = min(lx, ly) / 2
    rise = run * math.tan(math.radians(pitch))
    length = math.hypot(run, rise)
    cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
    if lx >= ly:
        ridge = lx - 2 * run
        slopes = [((cx, y0, z), (1, 0, 0), (0, run, rise), lx, ridge), ((cx, y1, z), (-1, 0, 0), (0, -run, rise), lx, ridge),
                  ((x1, cy, z), (0, 1, 0), (-run, 0, rise), ly, 0), ((x0, cy, z), (0, -1, 0), (run, 0, rise), ly, 0)]
        ends = [((x0 + run, cy, z + rise), (x1 - run, cy, z + rise))]
    else:
        ridge = ly - 2 * run
        slopes = [((x1, cy, z), (0, 1, 0), (-run, 0, rise), ly, ridge), ((x0, cy, z), (0, -1, 0), (run, 0, rise), ly, ridge),
                  ((cx, y0, z), (1, 0, 0), (0, run, rise), lx, 0), ((cx, y1, z), (-1, 0, 0), (0, -run, rise), lx, 0)]
        ends = [((cx, y0 + run, z + rise), (cx, y1 - run, z + rise))]
    for mid, along, up, w0, w1 in slopes:
        roof_slope(b, rng, mid, along, up, w0, w1, length, tones, cheap, deck)
    a, c = ends[0]
    if (Vector(a) - Vector(c)).length > .05:
        b.cylinder(cap, a, c, .08, 8)
    for corner in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
        apex = min((a, c), key=lambda e: math.hypot(e[0] - corner[0], e[1] - corner[1]))
        b.cylinder(cap, (corner[0], corner[1], z + .02), (apex[0], apex[1], apex[2] + .02), .06, 6)
    return z + rise


def gable_roof(b, rng, x0, x1, y0, y1, z, pitch, axis='x', tones=ROOF_RED, cheap=False, overhang=.25, deck='terracotta_dark'):
    """A plain gabled roof with its ridge along `axis`, overhanging the walls. Returns the ridge height."""
    if axis == 'x':
        run = (y1 - y0) / 2 + overhang
        rise = run * math.tan(math.radians(pitch))
        length = math.hypot(run, rise)
        w = x1 - x0 + overhang * 2
        cx = (x0 + x1) / 2
        z0 = z - overhang * math.tan(math.radians(pitch))
        roof_slope(b, rng, (cx, y0 - overhang, z0), (1, 0, 0), (0, run, rise), w, w, length, tones, cheap, deck)
        roof_slope(b, rng, (cx, y1 + overhang, z0), (-1, 0, 0), (0, -run, rise), w, w, length, tones, cheap, deck)
        b.cylinder('terracotta_dark', (x0 - overhang, (y0 + y1) / 2, z0 + rise + .04), (x1 + overhang, (y0 + y1) / 2, z0 + rise + .04), .08, 8)
    else:
        run = (x1 - x0) / 2 + overhang
        rise = run * math.tan(math.radians(pitch))
        length = math.hypot(run, rise)
        w = y1 - y0 + overhang * 2
        cy = (y0 + y1) / 2
        z0 = z - overhang * math.tan(math.radians(pitch))
        roof_slope(b, rng, (x1 + overhang, cy, z0), (0, 1, 0), (-run, 0, rise), w, w, length, tones, cheap, deck)
        roof_slope(b, rng, (x0 - overhang, cy, z0), (0, -1, 0), (run, 0, rise), w, w, length, tones, cheap, deck)
        b.cylinder('terracotta_dark', ((x0 + x1) / 2, y0 - overhang, z0 + rise + .04), ((x0 + x1) / 2, y1 + overhang, z0 + rise + .04), .08, 8)
    return z0 + rise


def gable_end(b, mat, axis, at, s0, s1, z0, apex_z, outward):
    """A solid triangular gable end in the plane x = at (axis 'x') or y = at (axis 'y'), s0..s1 along the wall."""
    mid = (s0 + s1) / 2
    d = -.14 * outward
    if axis == 'x':
        pts = [(at, s0, z0), (at, s1, z0), (at, mid, apex_z), (at + d, s0, z0), (at + d, s1, z0), (at + d, mid, apex_z)]
    else:
        pts = [(s0, at, z0), (s1, at, z0), (mid, at, apex_z), (s0, at + d, z0), (s1, at + d, z0), (mid, at + d, apex_z)]
    add_mesh(b, mat, pts, [(0, 1, 2), (5, 4, 3), (0, 3, 4, 1), (1, 4, 5, 2), (2, 5, 3, 0)])


def chimney(b, rng, x, y, z0, z1, size=.6, mat='brick', pots=1):
    b.box(mat, (x, y, (z0 + z1) / 2), (size, size * .85, z1 - z0), .02)
    b.box('limestone_pale', (x, y, z1 + .05), (size + .12, size * .85 + .12, .1), .02)
    for i in range(pots):
        px = x + (i - (pots - 1) / 2) * size * .42
        b.cylinder('terracotta', (px, y, z1 + .1), (px, y, z1 + .42), .085, 10, .07)


def ivy(b, rng, points, spread=.16, face=None, density=12, flowers=0):
    """Leaf clumps up a polyline on a wall; `face` pushes them off the wall along a 2D outward vector."""
    out = Vector((face[0], face[1], 0)) if face else Vector((0, 0, 0))
    for a, c in zip(points, points[1:]):
        a, c = Vector(a), Vector(c)
        count = max(2, int((c - a).length * density))
        for i in range(count):
            p = a.lerp(c, i / count) + out * rng.uniform(.03, .08)
            p += Vector((rng.uniform(-spread, spread), rng.uniform(-spread, spread), rng.uniform(-spread, spread))) * (Vector((1, 1, 1)) - Vector((abs(out.x), abs(out.y), 0)))
            b.sphere(('leaf', 'leaf_dark', 'leaf_light', 'leaf')[rng.randrange(4)], tuple(p), rng.uniform(.06, .11), 1, (1, 1, .85))
            if flowers and rng.random() < flowers:
                b.sphere(('flower_pink', 'flower_white')[rng.randrange(2)], tuple(p + out * .05), .04, 1)


def emblem(b, centre, facing, size=1.0, mat='gold'):
    """The town's sprout mark: a stem rising from a root fork between two leaves, standing just off a surface."""
    out = Vector((facing[0], facing[1], 0))
    across = Vector((-out.y, out.x, 0))
    up = Vector((0, 0, 1))
    c = Vector(centre) + out * .02
    s = size

    def piece(at, w, hgt, tilt=0.0):
        rot = basis_rotation(across * math.cos(tilt) + up * math.sin(tilt), -out, up * math.cos(tilt) - across * math.sin(tilt))
        b.box(mat, tuple(at), (w, .02, hgt), .004, rot)
    piece(c + Vector((0, 0, .02 * s)), .045 * s, .42 * s)
    for side in (-1, 1):
        piece(c + across * side * .085 * s + Vector((0, 0, .1 * s)), .05 * s, .22 * s, -side * .75)
        piece(c + across * side * .07 * s + Vector((0, 0, -.2 * s)), .035 * s, .14 * s, side * .55)
    piece(c + Vector((0, 0, .26 * s)), .07 * s, .07 * s)


def topiary(b, rng, at, height=1.1, radius=.32, box=.5):
    """A clipped evergreen cone in a square timber planter."""
    x, y, z = at
    b.box('wood_dark', (x, y, z + .2), (box, box, .4), .02)
    for sx in (-1, 1):
        b.box('wood', (x + sx * box / 2, y, z + .21), (.04, box + .04, .42), .01)
        b.box('wood', (x, y + sx * box / 2, z + .21), (box + .04, .04, .42), .01)
    b.box('soil', (x, y, z + .41), (box - .06, box - .06, .03), 0)
    layers = 7
    for i in range(layers):
        t = i / (layers - 1)
        r = radius * (1 - t * .85)
        zz = z + .48 + t * height
        for j in range(5):
            a = j * math.tau / 5 + i
            b.sphere('cypress' if (i + j) % 3 else 'cypress_light', (x + math.cos(a) * r * .55, y + math.sin(a) * r * .55, zz), r * .62, 1)
    b.sphere('gold', (x, y, z + .5 + height + .12), .04, 1)


# --- robots ---------------------------------------------------------------------------------------------------------
def wheel(name, at, radius, width, tyre='rubber', hub='brass'):
    """A wheel on its own objects, origin on the axle (Blender X), so the street presenter can roll it."""
    parts = []
    for part, mat, r, w in ((name, tyre, radius, width), (name + '_hub', hub, radius * .58, width * 1.12)):
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=20, radius1=r, radius2=r, depth=w)
        bmesh.ops.rotate(bm, verts=bm.verts, cent=(0, 0, 0), matrix=Matrix.Rotation(math.pi / 2, 4, 'Y'))
        if part == name:
            # A tread band, so a turning wheel reads as turning.
            for i in range(16):
                a = i * math.tau / 16
                t = bmesh.new()
                bmesh.ops.create_cube(t, size=1.0)
                bmesh.ops.scale(t, vec=Vector((w * .7, r * .12, .012)), verts=t.verts)
                bmesh.ops.transform(t, matrix=Matrix.Rotation(a, 4, 'X') @ Matrix.Translation((0, 0, r + .002)), verts=t.verts)
                tmp = bpy.data.meshes.new('tmp')
                t.to_mesh(tmp)
                t.free()
                bm.from_mesh(tmp)
                bpy.data.meshes.remove(tmp)
        layer = bm.loops.layers.uv.verify()
        for f in bm.faces:
            for loop in f.loops:
                loop[layer].uv = (loop.vert.co.y + .5, loop.vert.co.z + .5)
        mesh = bpy.data.meshes.new(part)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new(part, mesh)
        obj.location = at
        bpy.context.scene.collection.objects.link(obj)
        h.put(obj, mat, True)
        parts.append(obj)
    return parts


def spark_face(b, centre, radius, facing=(0, -1), rim='brass', eyes=True):
    """The amber spark window every Haverlund robot looks out of, with two pale eyes when it is awake."""
    out = Vector((facing[0], facing[1], 0))
    c = Vector(centre)
    rot = (math.pi / 2, 0, math.atan2(out.y, out.x) + math.pi / 2)
    disc = h.cylinder('Spark window', tuple(c + out * .01), radius, .04, 'spark_face', 28)
    disc.rotation_euler = rot
    ring = h.torus('Spark window rim', tuple(c + out * .025), radius + .012, .028, rim, rot)
    if eyes:
        across = Vector((-out.y, out.x, 0))
        squash = (.45, .8, 1.4) if abs(out.x) > .5 else (.8, .45, 1.4)
        for side in (-1, 1):
            b.sphere('eye', tuple(c + out * .045 + across * side * radius * .3 + Vector((0, 0, radius * .06))), radius * .24, 2, squash)
    return disc, ring
