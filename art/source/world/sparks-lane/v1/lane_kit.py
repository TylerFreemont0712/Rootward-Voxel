"""Shared helpers for the one-time authoring of the Haverlund lane (art T7c, props P1).

Imported by author_set.py, author_buildings.py and author_props.py. Each of those refuses an existing master; after
authoring, a model.blend is the editable authority and exports only through scripts/world-art.sh build <id>.
Blender +X is logical +x (east), +Y is logical +y (north), +Z is up. The set is authored in area coordinates;
buildings and props sit on their own origin at ground height.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import random
import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
LOFT = HERE.parents[1] / 'sparks-loft/v1'
REF = 'docs/concept/v0.7/art/4-opening/T7c-workshop-lane.wheels.png'
_spec = importlib.util.spec_from_file_location('loft_helpers', LOFT / 'author.py')
h = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(h)
M = h.M

PALETTE = {
    'limestone': 'e3d4b4', 'limestone_pale': 'eee4cc', 'limestone_warm': 'd8c39c', 'limestone_shade': 'c4b28e',
    'mortar': '9b8a70', 'soil': '6b5240', 'soil_dark': '4f3c2e', 'rock': '9d917c',
    'leaf': '5b8a45', 'leaf_light': '86ad5c', 'leaf_dark': '3f6a3c', 'cypress': '2f5a3d', 'cypress_light': '44724c',
    'terracotta': 'c8643f', 'terracotta_light': 'd97a4e', 'terracotta_dark': 'a9513a', 'brick': 'b0614a',
    'timber': '6b4a33', 'wood': 'a07950', 'wood_dark': '715038', 'wood_light': 'bd9567', 'ink': '503d30',
    'teal': '3f7b74', 'teal_dark': '315f5a', 'teal_light': '78a69b', 'shutter': '4c8a6c', 'shutter_dark': '3a6c55',
    'iron': '3b4043', 'iron_light': '5c6468', 'rail': '7c8487', 'brass': 'c29b59',
    'red': 'b5463a', 'red_dark': '8b3329', 'white': 'f2ead8', 'cream': 'e8dfca', 'linen': 'e5ddc8',
    'cloth_blue': '6f8fb3', 'cloth_rose': 'd99a8e', 'cloth_ochre': 'd8b465', 'stripe_cream': 'efe3c4',
    'window': '34535a', 'window_light': '5f8587', 'tunnel': '2a2420', 'water': '5e98a0',
    'flower_white': 'f6f0e2', 'flower_pink': 'e59aa8', 'flower_yellow': 'ebc55a', 'flower_red': 'cf4f43',
    'flower_violet': '9b84c4', 'flower_blue': '7f9ed6', 'paper': 'f4e8cc', 'pages': 'cbbc98', 'rubber': '34393a',
    'enamel_cream': 'ece2c8', 'enamel_teal': '3d7773', 'glass': 'a9c3c1', 'gold': 'd6b26a', 'ochre': 'c29a55',
    'ceramic': 'b6ad91', 'plum': '866875', 'blue': '687d8a', 'steel': '6d777d', 'steel_dark': '343e44',
    'chalk': 'f3efe4', 'cat': '7d8285', 'cat_light': 'c9cbc6', 'enamel_blue': '2f5f7a', 'milk': 'f7f5ee',
}


def start(asset, prefix='lane'):
    """A fresh scene with the lane palette and painted surfaces; returns the asset's root empty."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    M.clear()
    for name, colour in PALETTE.items():
        h.material(name, colour)
    h.material('cobbles', 'ffffff', str(HERE / 'lane-cobbles'))
    h.material('flags', 'ffffff', str(HERE / 'lane-flags'))
    # The project's lush grass (Kindle Hollow's ground picture), laid out by textures.py without repeats.
    h.material('grass', 'ffffff', str(HERE / 'lane-grass-lush'))
    h.material('plaster', 'ffffff', str(LOFT / 'cream-plaster'))
    h.material('salmon', 'ffffff', str(HERE / 'salmon-plaster'))
    h.material('ashlar', 'ffffff', str(HERE / 'lane-ashlar'))
    # The project's lush bark picture (assets/world/textures/lush), borrowed for the lane's trees.
    h.material('bark', 'ffffff', str(ROOT / 'assets/world/textures/lush/bark'))
    # Glass is one painted picture per pane; "window" in a material name keeps illustrated edges off it.
    h.material('window_pane', 'ffffff', str(HERE / 'lane-glass'))
    h.material('window_shop', 'ffffff', str(HERE / 'lane-glass-shop'), emission=.12)
    h.material('window_tram', 'ffffff', str(HERE / 'lane-glass-tram'))
    h.material('oak', 'ffffff', str(LOFT / 'honey-oak-v2'))
    h.material('brass', 'c29b59', metallic=.28)
    h.material('lamp_glass', 'ffe0a0', emission=.25)
    for name, mat in M.items():
        mat.name = prefix + '_' + name
    h.PARENT = bpy.data.objects.new(asset.replace('-', '_'), None)
    bpy.context.scene.collection.objects.link(h.PARENT)
    return h.PARENT


# Foliage, blossom and cloth read as soft clumps, as in the concept, rather than cut facets.
SOFT = {'leaf', 'leaf_light', 'leaf_dark', 'cypress', 'cypress_light', 'flower_white', 'flower_pink', 'flower_yellow',
        'flower_red', 'flower_violet', 'flower_blue', 'cat', 'cat_light'}


class Batch:
    """Many small bevelled boxes per material, built in bmesh and turned into one object per material."""

    def __init__(self, rng=None):
        self.parts = {}
        self.rng = rng or random.Random(7)

    def _bm(self, mat):
        if mat not in self.parts:
            self.parts[mat] = bmesh.new()
        return self.parts[mat]

    def box(self, mat, at, size, bevel=.025, rot=(0, 0, 0), segments=1):
        target = self._bm(mat)
        tmp = bmesh.new()
        bmesh.ops.create_cube(tmp, size=1.0)
        bmesh.ops.scale(tmp, vec=Vector(size), verts=tmp.verts)
        if bevel > 0:
            limit = min(size) * .45
            bmesh.ops.bevel(tmp, geom=list(tmp.edges), offset=min(bevel, limit), segments=segments, affect='EDGES', profile=.5)
        matrix = Matrix.Translation(Vector(at)) @ Euler(rot).to_matrix().to_4x4()
        bmesh.ops.transform(tmp, matrix=matrix, verts=tmp.verts)
        mesh = bpy.data.meshes.new('tmp')
        tmp.to_mesh(mesh)
        tmp.free()
        target.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)

    def sphere(self, mat, at, radius, subdivisions=1, squash=(1, 1, 1)):
        if mat in SOFT and radius > .15:
            subdivisions = max(subdivisions, 2)
        target = self._bm(mat)
        tmp = bmesh.new()
        bmesh.ops.create_icosphere(tmp, subdivisions=subdivisions, radius=1.0)
        bmesh.ops.scale(tmp, vec=Vector((radius * squash[0], radius * squash[1], radius * squash[2])), verts=tmp.verts)
        bmesh.ops.translate(tmp, vec=Vector(at), verts=tmp.verts)
        mesh = bpy.data.meshes.new('tmp')
        tmp.to_mesh(mesh)
        tmp.free()
        target.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)

    def cylinder(self, mat, a, b, radius, sides=8, radius_b=None):
        a, b = Vector(a), Vector(b)
        target = self._bm(mat)
        tmp = bmesh.new()
        bmesh.ops.create_cone(tmp, cap_ends=True, segments=sides, radius1=radius, radius2=radius if radius_b is None else radius_b, depth=(b - a).length)
        rot = (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
        bmesh.ops.transform(tmp, matrix=Matrix.Translation((a + b) / 2) @ rot, verts=tmp.verts)
        mesh = bpy.data.meshes.new('tmp')
        tmp.to_mesh(mesh)
        tmp.free()
        target.from_mesh(mesh)
        bpy.data.meshes.remove(mesh)

    def finish(self, smooth=()):
        for mat, bm in self.parts.items():
            # Cube-projected UVs in world units: painted surfaces tile, flat colours ignore them, and every
            # exported surface carries texture coordinates for the asset audit.
            layer = bm.loops.layers.uv.verify()
            for face in bm.faces:
                n = face.normal
                axis = max(range(3), key=lambda i: abs(n[i]))
                u, v = [(1, 2), (0, 2), (0, 1)][axis]
                for loop in face.loops:
                    loop[layer].uv = (loop.vert.co[u] / 2.0, loop.vert.co[v] / 2.0)
            mesh = bpy.data.meshes.new(mat)
            bm.to_mesh(mesh)
            bm.free()
            obj = bpy.data.objects.new(mat, mesh)
            bpy.context.scene.collection.objects.link(obj)
            h.put(obj, mat, mat in smooth or mat in SOFT)
        self.parts = {}


def quad_surface(name, mat, quads, span, height):
    """Flat top faces: quads are (x0, y0, x1, y1) rectangles at `height`, UVs in world units / span (seamless tiling)."""
    verts, faces, uvs = [], [], []
    for x0, y0, x1, y1 in quads:
        base = len(verts)
        for x, y in ((x0, y0), (x1, y0), (x1, y1), (x0, y1)):
            verts.append((x, y, height))
            uvs.append((x / span, y / span))
        faces.append((base, base + 1, base + 2, base + 3))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    layer = mesh.uv_layers.new(name='World tiling')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            layer.data[li].uv = uvs[mesh.loops[li].vertex_index]
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def plaster_wall(name, mat, a, b, z0, z1, depth=.18, span=3.0):
    """A plastered wall slab from a to b (2D points), its faces mapped to the plaster painting in world units."""
    a, b = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    along = (b - a).normalized()
    normal = Vector((along.y, -along.x, 0))
    corners = [a, b, b + normal * -depth, a + normal * -depth]
    verts = [(c.x, c.y, z0) for c in corners] + [(c.x, c.y, z1) for c in corners]
    faces = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7), (3, 2, 1, 0)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    layer = mesh.uv_layers.new(name='Plaster')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index].co
            run = (v - a).dot(along) if abs(poly.normal.z) < .5 else v.x
            layer.data[li].uv = (run / span, v.z / span if abs(poly.normal.z) < .5 else v.y / span)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def gable_plaster(name, mat, x, y0, y1, z0, z1, apex, outward=1, span=3.0, axis='x'):
    """A triangular gable end in the plane x = const (axis 'x'; y = const for axis 'y', with x and y swapped in the
    arguments), between y0 and y1, from the eaves z0 to the apex z1 at y = apex. A thin slab, so it has a back."""
    def at(u, z, d=0.0):
        return (x + d, u, z) if axis == 'x' else (u, x + d, z)
    inward = -.12 * outward
    verts = [at(y0, z0), at(y1, z0), at(apex, z1), at(y0, z0, inward), at(y1, z0, inward), at(apex, z1, inward)]
    front = (0, 1, 2) if (outward > 0) == (axis == 'x') else (2, 1, 0)
    back = tuple(i + 3 for i in reversed(front))
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], [front, back])
    mesh.update()
    layer = mesh.uv_layers.new(name='Plaster')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index].co
            layer.data[li].uv = ((v.y if axis == 'x' else v.x) / span, v.z / span)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def _quad(verts, faces, points, outward):
    """Appends a quad wound so its normal agrees with `outward`."""
    p = [Vector(q) for q in points]
    if (p[1] - p[0]).cross(p[2] - p[0]).dot(Vector(outward)) < 0:
        p = p[::-1]
    base = len(verts)
    verts.extend(tuple(q) for q in p)
    faces.append((base, base + 1, base + 2, base + 3))


def wall(name, mat, a, b, z0, z1, depth=.2, openings=(), span=3.0):
    """A wall slab from a to b (2D points) whose outer face lies on the line a→b, facing to its right (walls run
    counter-clockwise seen from above), `depth` thick behind it. `openings` are (s0, s1, bottom, top) with s along
    the wall from a: the slab is faced around each one and lined with reveals, so glass set inside an opening
    never shares a plane with the wall. UVs map the painted surface in world units."""
    a3, b3 = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    along = (b3 - a3).normalized()
    length = (b3 - a3).length
    out = Vector((along.y, -along.x, 0))
    up = Vector((0, 0, 1))

    def point(s, z, d=0.0):
        return a3 + along * s + up * z - out * d

    cuts = sorted({0.0, length, *[o[0] for o in openings], *[o[1] for o in openings]})
    verts, faces = [], []
    for sa, sb in zip(cuts, cuts[1:]):
        solid = [(z0, z1)]
        for s0, s1, bottom, top in openings:
            if s0 <= sa + 1e-6 and s1 >= sb - 1e-6:
                solid = [piece for lo, hi in solid for piece in ((lo, min(hi, bottom)), (max(lo, top), hi)) if piece[1] - piece[0] > 1e-6]
        for lo, hi in solid:
            _quad(verts, faces, [point(sa, lo), point(sb, lo), point(sb, hi), point(sa, hi)], out)
            _quad(verts, faces, [point(sa, lo, depth), point(sb, lo, depth), point(sb, hi, depth), point(sa, hi, depth)], -out)
    for s0, s1, bottom, top in openings:
        _quad(verts, faces, [point(s0, bottom), point(s0, top), point(s0, top, depth), point(s0, bottom, depth)], along)
        _quad(verts, faces, [point(s1, bottom), point(s1, top), point(s1, top, depth), point(s1, bottom, depth)], -along)
        _quad(verts, faces, [point(s0, top), point(s1, top), point(s1, top, depth), point(s0, top, depth)], -up)
        if bottom > z0 + 1e-6:
            _quad(verts, faces, [point(s0, bottom), point(s1, bottom), point(s1, bottom, depth), point(s0, bottom, depth)], up)
    _quad(verts, faces, [point(0, z1), point(length, z1), point(length, z1, depth), point(0, z1, depth)], up)
    _quad(verts, faces, [point(0, z0), point(0, z1), point(0, z1, depth), point(0, z0, depth)], -along)
    _quad(verts, faces, [point(length, z0), point(length, z1), point(length, z1, depth), point(length, z0, depth)], along)
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(verts, [], faces)
    mesh.update()
    layer = mesh.uv_layers.new(name='Painted surface')
    for poly in mesh.polygons:
        n = poly.normal
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index].co - a3
            s, d, z = v.dot(along), -v.dot(out), v.z
            if abs(n.z) > .5:
                layer.data[li].uv = (s / span, d / span)
            elif abs(n.dot(along)) > .5:
                layer.data[li].uv = (d / span, z / span)
            else:
                layer.data[li].uv = (s / span, z / span)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def pane(name, mat, centre, width, height, facing, offset=0.0):
    """A flat pane carrying one whole picture (UV 0..1), centred on `centre` and pushed `offset` along `facing`."""
    fx, fy = facing
    across = Vector((-fy, fx, 0))
    c = Vector(centre) + Vector((fx, fy, 0)) * offset
    w, hh = width / 2, height / 2
    points = [c - across * w - Vector((0, 0, hh)), c + across * w - Vector((0, 0, hh)), c + across * w + Vector((0, 0, hh)), c - across * w + Vector((0, 0, hh))]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(p) for p in points], [], [(0, 1, 2, 3)])
    mesh.update()
    layer = mesh.uv_layers.new(name='Whole pane')
    for poly in mesh.polygons:
        for li, uv in zip(poly.loop_indices, ((0, 0), (1, 0), (1, 1), (0, 1))):
            layer.data[li].uv = uv
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def disc_pane(name, mat, centre, radius, facing, offset=0.0, sides=20):
    """A round pane (an oculus) with its picture mapped across the disc."""
    fx, fy = facing
    across = Vector((-fy, fx, 0))
    c = Vector(centre) + Vector((fx, fy, 0)) * offset
    points = [c]
    uvs = [(.5, .5)]
    for i in range(sides):
        t = math.tau * i / sides
        points.append(c + across * math.cos(t) * radius + Vector((0, 0, math.sin(t) * radius)))
        uvs.append((.5 + .5 * math.cos(t), .5 + .5 * math.sin(t)))
    faces = [(0, 1 + i, 1 + (i + 1) % sides) for i in range(sides)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata([tuple(p) for p in points], [], faces)
    mesh.update()
    layer = mesh.uv_layers.new(name='Whole pane')
    for poly in mesh.polygons:
        if poly.normal.dot(Vector((fx, fy, 0))) < 0:
            poly.flip()
    mesh.update()
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            layer.data[li].uv = uvs[mesh.loops[li].vertex_index]
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return h.put(obj, mat)


def lettering(name, words, at, height, mat, rotation=(math.pi / 2, 0, 0)):
    """Raised lettering from Blender's built-in face, converted to mesh so nothing depends on fonts at runtime."""
    bpy.ops.object.text_add(location=at, rotation=rotation)
    obj = bpy.context.object
    obj.name = name
    obj.data.body = words
    obj.data.size = height
    obj.data.align_x = 'CENTER'
    obj.data.align_y = 'CENTER'
    obj.data.extrude = .004
    bpy.ops.object.convert(target='MESH')
    obj = bpy.context.object
    obj.data.uv_layers.new(name='UVMap')
    return h.put(obj, mat)


def catenary(name, a, b, sag, radius=.012, mat='iron'):
    a, b = Vector(a), Vector(b)
    points = []
    for k in range(9):
        t = k / 8
        p = a.lerp(b, t)
        p.z -= sag * 4 * t * (1 - t)
        points.append(tuple(p))
    return h.curve(name, points, radius, mat)


def tiled_roof(batch, x0, x1, eave, ridge, z_eave, z_ridge, rng, row=.27, width=.31, tones=('terracotta', 'terracotta_light', 'terracotta_dark', 'terracotta'), axis='x', cap=True):
    """Overlapping rounded clay tiles on one slope, ridge along X. eave/ridge are the slope's Y at its foot and top.
    axis='y' lays the same slope with its ridge along Y: x0/x1 then run along Y and eave/ridge are X positions."""
    def put(mat, at, size, angle, bevel=.018):
        if axis == 'x':
            batch.box(mat, at, size, bevel, (angle, 0, 0), 1)
        else:
            batch.box(mat, (at[1], at[0], at[2]), (size[1], size[0], size[2]), bevel, (0, -angle, 0), 1)

    run = ridge - eave
    rise = z_ridge - z_eave
    length = math.hypot(run, rise)
    pitch = math.atan2(rise, abs(run))
    direction = 1 if run > 0 else -1
    rows = max(2, int(length / row) + 1)
    for r in range(rows):
        t = (r + .5) / rows
        y = eave + run * t
        z = z_eave + rise * t + .045
        count = max(1, int((x1 - x0) / width))
        step = (x1 - x0) / count
        shift = step * .5 if r % 2 else 0
        for c in range(count + (1 if r % 2 else 0)):
            x = x0 + step * (c + .5) - shift
            if x < x0 + step * .2 or x > x1 - step * .2:
                continue
            tone = tones[rng.randrange(len(tones))]
            lift = .07
            put(tone, (x, y, z), (step * .94, length / rows * 1.22, .05), direction * (pitch + lift))
    if not cap:
        return
    # Half-round ridge capping.
    count = max(1, int((x1 - x0) / .36))
    for c in range(count):
        x = x0 + (x1 - x0) * (c + .5) / count
        a, b = (x - (x1 - x0) / count * .48, ridge, z_ridge + .06), (x + (x1 - x0) / count * .48, ridge, z_ridge + .06)
        if axis == 'y':
            a, b = (a[1], a[0], a[2]), (b[1], b[0], b[2])
        batch.cylinder('terracotta_dark' if c % 3 == 0 else 'terracotta', a, b, .085, 8)


def roof_deck(batch, x0, x1, eave, ridge, z_eave, z_ridge, mat='terracotta_dark', axis='x'):
    """The boarded deck under one slope (same arguments as tiled_roof), so no gap shows between tiles."""
    run = ridge - eave
    rise = z_ridge - z_eave
    length = math.hypot(run, rise)
    pitch = math.atan2(rise, abs(run)) * (1 if run > 0 else -1)
    mid = ((x0 + x1) / 2, (eave + ridge) / 2, (z_eave + z_ridge) / 2 - .03)
    if axis == 'x':
        batch.box(mat, mid, (x1 - x0, length, .08), 0, (pitch, 0, 0))
    else:
        batch.box(mat, (mid[1], mid[0], mid[2]), (length, x1 - x0, .08), 0, (0, -pitch, 0))


def window(batch, centre, width, height, facing, shutters=True, box=True, frame='white', sill='limestone', flowers=('flower_pink', 'flower_white', 'flower_red'), glass='window_pane', recess=.09, bars=(1, 1), name='Window glass', shutter_mats=('shutter', 'shutter_dark')):
    """A window in a wall opening whose outer face passes through `centre`; `facing` is the outward unit vector
    along X or Y (2D tuple). The glass is one painted pane set `recess` behind the face, with its sash and glazing
    bars on it (`bars` = upright and cross bar counts); the casing, sill, shutters and box stand on the face. A
    negative recess stands the whole window proud of a wall that has no opening for it."""
    cx, cy, cz = centre
    fx, fy = facing
    across = Vector((-fy, fx, 0))
    out = Vector((fx, fy, 0))
    c = Vector(centre)

    def place(mat, offset_across, offset_out, z, size_across, size_out, size_z, bevel=.012):
        p = c + across * offset_across + out * offset_out
        sx, sy = (size_across, size_out) if abs(fy) > .5 else (size_out, size_across)
        batch.box(mat, (p.x, p.y, z), (sx, sy, size_z), bevel)

    pane(name, glass, centre, width, height, facing, -recess)
    sash = -recess + .025
    for side in (-1, 1):
        place(frame, side * (width / 2 - .025), sash, cz, .05, .045, height)
    for z in (cz - height / 2 + .025, cz + height / 2 - .025):
        place(frame, 0, sash, z, width, .045, .05)
    for i in range(bars[0]):
        place(frame, -width / 2 + width * (i + 1) / (bars[0] + 1), sash + .005, cz, .035, .04, height - .04, .006)
    for i in range(bars[1]):
        place(frame, 0, sash + .005, cz - height / 2 + height * (i + 1) / (bars[1] + 1) + height * .06, width - .04, .04, .035, .006)
    for side in (-1, 1):
        place(frame, side * (width / 2 + .04), .02, cz + .02, .08, .06, height + .12)
    place(frame, 0, .025, cz + height / 2 + .05, width + .2, .07, .1)
    place(sill, 0, .07, cz - height / 2 - .05, width + .26, .16, .07)
    if shutters:
        for side in (-1, 1):
            place(shutter_mats[0], side * (width / 2 + .09 + width * .25), .04, cz, width * .5, .045, height + .02, .01)
            for k in range(4):
                place(shutter_mats[1], side * (width / 2 + .09 + width * .25), .065, cz - height * .36 + k * height * .24, width * .42, .01, .025, 0)
    if box:
        place('wood_dark', 0, .14, cz - height / 2 - .2, width + .1, .24, .2, .02)
        rng = batch.rng
        for k in range(7):
            off = -width / 2 + (k + .5) * width / 7
            p = c + across * off + out * (.16 + rng.uniform(-.04, .04))
            batch.sphere('leaf' if k % 2 else 'leaf_light', (p.x, p.y, cz - height / 2 - .06 + rng.uniform(0, .05)), .085, 1)
            if k % 2 == 0:
                q = p + out * .06
                batch.sphere(flowers[rng.randrange(len(flowers))], (q.x, q.y, cz - height / 2 + .02), .045, 1)


def flower_clump(batch, at, radius=.25, rng=None, petals=('flower_white', 'flower_yellow', 'flower_pink'), leaves=('leaf', 'leaf_light', 'leaf_dark'), count=6):
    rng = rng or batch.rng
    x, y, z = at
    for k in range(count):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, radius)
        batch.sphere(leaves[k % len(leaves)], (x + math.cos(a) * d, y + math.sin(a) * d, z + rng.uniform(.02, .1)), rng.uniform(.07, .12), 1, (1, 1, .8))
    for k in range(count // 2 + 1):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(0, radius * .9)
        batch.sphere(petals[rng.randrange(len(petals))], (x + math.cos(a) * d, y + math.sin(a) * d, z + rng.uniform(.12, .2)), .04, 1)


def stone_courses(batch, rng, along, a, b, z0, z1, face, depth=.26, course=.33, block=(.45, .8), tones=('limestone', 'limestone_pale', 'limestone_warm', 'limestone_shade', 'limestone'), bevel=.035, skip=None):
    """A face of stone blocks. along='x' runs from x=a to b at y=face; along='y' runs y a..b at x=face. Blocks
    stand just proud of the face (outward = -y for along x, +x for along y unless depth is negative)."""
    courses = max(1, round((z1 - z0) / course))
    ch = (z1 - z0) / courses
    for k in range(courses):
        z = z0 + ch * (k + .5)
        start = a
        first = True
        while start < b - .02:
            w = min(rng.uniform(*block) * (.55 if first and k % 2 else 1), b - start)
            first = False
            if b - (start + w) < .18:
                w = b - start
            mid = start + w / 2
            if skip is None or not skip(mid, z):
                tone = tones[rng.randrange(len(tones))]
                inset = rng.uniform(-.015, .015)
                if along == 'x':
                    batch.box(tone, (mid, face + depth / 2 + inset, z), (w - .03, depth, ch - .03), bevel)
                else:
                    batch.box(tone, (face - depth / 2 + inset, mid, z), (depth, w - .03, ch - .03), bevel)
            start += w


def save(asset, record, extras=None, keep_separate=()):
    """Batches static pieces by material and saves the editable master. Names in keep_separate stay separate."""
    groups = {}
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH':
            continue
        semantic = obj.name if any(obj.name.startswith(k) for k in keep_separate) else 'static'
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
    scene['rootward_source'] = 'Editable authority after T7c/P1. Do not rerun the authoring record.'
    bpy.ops.file.pack_all()
    folder = ROOT / 'art/source/world' / asset / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    note = {'asset': asset, 'date': '2026-10-28', 'reference': REF,
            'authoring_record': 'art/source/world/sparks-lane/v1/' + record,
            'authoring_record_sha256': hashlib.sha256((HERE / record).read_bytes()).hexdigest(),
            'kit_sha256': hashlib.sha256((HERE / 'lane_kit.py').read_bytes()).hexdigest(),
            'textures': 'art/source/world/sparks-lane/v1/textures.py',
            'note': 'New bespoke authored asset; model.blend is now authority. Build through scripts/world-art.sh.'}
    if extras:
        note.update(extras)
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', asset, flush=True)


def guard(assets):
    for asset in assets:
        if (ROOT / 'art/source/world' / asset / 'v1/model.blend').exists():
            raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + asset)
