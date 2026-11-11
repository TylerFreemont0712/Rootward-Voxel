"""Shared kit for the modular seaside background houses (docs/concept/v0.72/background-houses.md).

Imported by author_houses.py. Each house is its own standalone model with a ground pivot at its footprint centre,
front toward Blender -Y, so a town can be dressed by placing finished houses instead of modelling one set.

Surfaces come from the seaside house texture pack (art/source/world/seaside-background-houses/v1/textures/, built
to assets/world/textures/seaside-houses/detail/ by scripts/art.sh). Every plaster, roof, ridge, stone, timber and
painted-board surface uses ONE material per family named `seaside_<family>`, so the game can swap a family's
painting per placed house (art/house_variants.gd). Optional dressing is grouped into objects named `detail_<name>`
and mutually exclusive alternatives into `alt_<group>_<option>`; everything else is static and joined by material.

Blender +X is east, +Y north, +Z up. One unit is one metre and one game cell. Authoring records refuse to overwrite an
existing master; after authoring, model.blend is the editable authority and exports only through
scripts/world-art.sh build <id>.
"""
from contextlib import contextmanager
from pathlib import Path
import hashlib
import json
import math
import random
import sys

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
DETAIL = ROOT / 'assets/world/textures/seaside-houses/detail'
LIBRARY = ROOT / 'art/source/world/seaside-background-houses/v1/textures/library.json'
GLASS = ROOT / 'art/source/world/sparks-lane/v1/lane-glass.png'
BRICK = ROOT / 'art/source/world/textures/v2-detail/native/red_brick.png'
PALETTE = HERE / 'house-palette.png'

# Surface slots. 'ridge' borrows the roof paintings so caps can match or contrast with the roof field.
FAMILIES = {'plaster': 'plaster', 'roof': 'roof', 'ridge': 'roof', 'stone': 'stone', 'timber': 'timber', 'shutter': 'shutter'}


def family_of(slot):
    """A surface slot's painting family. A joined building's second home paints its own slots, e.g. `plaster_2`."""
    return FAMILIES.get(slot.split('_2')[0]) if slot.endswith('_2') else FAMILIES.get(slot)


def repeat_of(mat):
    family = family_of(mat)
    return REPEAT['ridge' if mat.startswith('ridge') else family] if family else REPEAT.get(mat, 2.0)
# World size of one repeat of each painting, chosen so the painted courses, blocks and boards read at concept scale.
REPEAT = {'plaster': 2.0, 'roof': 1.75, 'ridge': 1.75, 'stone': 1.9, 'timber': 1.6, 'shutter': .8, 'brick': .75}

# Measured on the 512-pixel detail maps (all colours share the pattern): seven pan tiles across; one course is the
# band between two scalloped tile foots (rows 233 and 345 from the top, the foot dipping to ~350).
ROOF_COURSE_V = (1 - 350 / 512, 112 / 512)
ROOF_COLUMNS = 7
# Whole painted ashlar blocks (x0, x1, y0, y1 in pixels from the top-left), outline included.
STONE_BLOCKS = [(57, 206, 25, 105), (206, 357, 25, 105), (123, 293, 105, 187), (293, 463, 105, 187),
                (46, 227, 187, 266), (227, 405, 187, 266), (2, 160, 266, 345), (160, 322, 266, 345),
                (322, 510, 266, 345), (100, 262, 345, 427), (262, 423, 345, 427), (152, 312, 427, 504),
                (312, 472, 427, 504)]

FLAT = {
    'iron': '3a3f43', 'iron_light': '596267', 'sash': 'efe6d2', 'terracotta': 'c4643e', 'terracotta_dark': 'a24f35',
    'soil': '5c4433', 'leaf': '5b8a45', 'leaf_light': '86ad5c', 'leaf_dark': '3f6a3c', 'cypress': '2f5a3d',
    'cypress_light': '44724c', 'olive': '7d9356', 'flower_white': 'f6f0e2', 'flower_pink': 'e59aa8',
    'flower_red': 'cf4f43', 'flower_yellow': 'ebc55a', 'flower_orange': 'e88a3a', 'flower_violet': '9b84c4',
    'linen': 'eee6d3', 'cloth_blue': '7d9cbf', 'cloth_rose': 'dba198', 'cloth_ochre': 'd9b76b', 'rope': 'cdb48a',
    'wood_end': 'd9b484', 'bark': '6b4c34', 'wicker': 'c3994f', 'wicker_dark': '9c7537', 'brass': 'c29b59',
    'lead': '5f676b', 'water': '7fa7ad', 'grate': '2c3134',
    # Shopfront colours (appended so earlier cells keep their place; the palette stays five rows of eight).
    'enamel_red': 'b83b2f', 'enamel_red_dark': '8a2c24', 'gold_leaf': 'd9b35f', 'canvas': 'f1ead6', 'canvas_green': '4f8a6a',
    'ink': '2e2621',
}
# Plain colours are cells of one small painted palette, so every plain-coloured part of a house shares one material.
PALETTE_COLUMNS, CELL = 8, 16
SOFT = {'leaf', 'leaf_light', 'leaf_dark', 'cypress', 'cypress_light', 'olive', 'flower_white', 'flower_pink',
        'flower_red', 'flower_yellow', 'flower_orange', 'flower_violet'}
# Glass and light stay in their own objects: illustrated edges skip any mesh that carries them.
CLEAR = ('glass', 'window')

M = {}
LIB = {}


# --- materials -----------------------------------------------------------------------------------------------------
def _linear(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4


def _rgb(colour):
    return tuple(_linear(int(colour[i:i + 2], 16) / 255) for i in (0, 2, 4))


def material(name, colour='ffffff', image=None, roughness=.88, emission=0.0, metallic=0.0, interpolation='Linear'):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    c = _rgb(colour)
    mat.diffuse_color = (*c, 1)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*c, 1)
    bsdf.inputs['Roughness'].default_value = roughness
    bsdf.inputs['Metallic'].default_value = metallic
    if image:
        node = mat.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = bpy.data.images.load(str(image), check_existing=True)
        node.interpolation = interpolation
        mat.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
        if emission:
            mat.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Emission Color'])
    elif emission:
        bsdf.inputs['Emission Color'].default_value = (*c, 1)
    bsdf.inputs['Emission Strength'].default_value = emission
    M[name] = mat
    return mat


def begin(asset, palette):
    """A fresh scene with the house materials. `palette` maps each surface slot to its authored painting id."""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    M.clear()
    LIB.clear()
    for item in json.loads(LIBRARY.read_text())['materials']:
        LIB[item['id']] = item
    for slot, choice in palette.items():
        family = family_of(slot)
        if LIB[choice]['family'] != family:
            raise ValueError(f'{choice} is not a {family} painting')
        material('seaside_' + slot, 'ffffff', DETAIL / (choice + '.png'), LIB[choice]['roughness'])
    material('house_paint', 'ffffff', _palette_image(), .86, interpolation='Closest')
    material('house_brick', 'ffffff', BRICK, .92)
    material('house_window_pane', 'ffffff', GLASS, .35)
    material('house_lamp_glass', 'ffd9a0', emission=.45)
    root = bpy.data.objects.new(asset.replace('-', '_'), None)
    bpy.context.scene.collection.objects.link(root)
    return root


def _palette_image():
    """Writes the plain colours as 16-pixel cells of house-palette.png (rebuilt identically by every authoring run)."""
    rows = math.ceil(len(FLAT) / PALETTE_COLUMNS)
    width, height = PALETTE_COLUMNS * CELL, rows * CELL
    image = bpy.data.images.new('house-palette', width, height, alpha=False)
    pixels = [1.0] * (width * height * 4)
    for index, colour in enumerate(FLAT.values()):
        col, row = index % PALETTE_COLUMNS, index // PALETTE_COLUMNS
        rgb = [int(colour[k:k + 2], 16) / 255 for k in (0, 2, 4)]
        for y in range(CELL):
            line = height - 1 - (row * CELL + y)
            for x in range(CELL):
                o = (line * width + col * CELL + x) * 4
                pixels[o:o + 3] = rgb
    image.pixels = pixels
    image.filepath_raw = str(PALETTE)
    image.file_format = 'PNG'
    image.save()
    return PALETTE


def paint_uv(name):
    """The centre of a plain colour's palette cell."""
    index = list(FLAT).index(name)
    rows = math.ceil(len(FLAT) / PALETTE_COLUMNS)
    return ((index % PALETTE_COLUMNS + .5) / PALETTE_COLUMNS, 1 - (index // PALETTE_COLUMNS + .5) / rows)


def _mat(name):
    """Any material a record added under its full name (`lamp_glass`), else a surface slot (`stone` →
    seaside_stone), else a house colour (`brick` → house_brick)."""
    for key in (name, 'seaside_' + name, 'house_' + name):
        if key in M:
            return M[key]
    raise KeyError(name)


# --- geometry accumulation -----------------------------------------------------------------------------------------
class Parts:
    """Every piece lands in a (group, material) bucket with its UVs already assigned. `with parts.into(group)` routes
    pieces into an optional detail or alternative; the default group is static."""

    def __init__(self, seed):
        self.rng = random.Random(seed)
        self.data = {}
        self.group = 'static'
        self.frame = Matrix.Identity(4)

    @contextmanager
    def turned(self, degrees):
        """Authors pieces in a frame turned `degrees` about the vertical, so kit parts made with a ridge along X can
        stand with their ridge along Y. -90 turns +X to -Y (the front): a gable end built at +X faces the street.
        Paintings are mapped before turning, so they follow the pieces."""
        previous, self.frame = self.frame, Matrix.Rotation(math.radians(degrees), 4, 'Z') @ self.frame
        try:
            yield
        finally:
            self.frame = previous

    @contextmanager
    def placed(self, at, degrees=0.0):
        """Authors pieces in a frame moved to `at` and turned `degrees` about the vertical (inside any current frame)."""
        previous = self.frame
        self.frame = self.frame @ Matrix.Translation(Vector(at)) @ Matrix.Rotation(math.radians(degrees), 4, 'Z')
        try:
            yield
        finally:
            self.frame = previous

    @contextmanager
    def into(self, group):
        previous, self.group = self.group, group
        try:
            yield
        finally:
            self.group = previous

    def bucket(self, mat):
        return self.data.setdefault((self.group, mat), {'v': [], 'f': [], 'uv': [], 'smooth': []})

    def add(self, mat, verts, faces, uvs, smooth=False):
        if mat in FLAT:
            cell = paint_uv(mat)
            uvs = [[cell] * len(face) for face in faces]
            mat = 'paint'
        bucket = self.bucket(mat)
        base = len(bucket['v'])
        bucket['v'].extend(tuple(self.frame @ Vector(v)) for v in verts)
        for face, loop_uvs in zip(faces, uvs):
            bucket['f'].append(tuple(base + i for i in face))
            bucket['uv'].append([tuple(uv) for uv in loop_uvs])
            bucket['smooth'].append(smooth)

    # -- mapping -----------------------------------------------------------------------------------------------
    def _rect(self, rect, du, dv, rng):
        """An aspect-preserving window of a painted rect (pixels) for a face du × dv metres, as UV corners."""
        x0, x1, y0, y1 = rect
        w, h = x1 - x0, y1 - y0
        want = (du / max(dv, 1e-4)) * h
        if want < w:
            start = x0 + rng.uniform(0, w - want)
            x0, x1 = start, start + want
        else:
            want_h = w * dv / max(du, 1e-4)
            if want_h < h:
                start = y0 + rng.uniform(0, h - want_h)
                y0, y1 = start, start + want_h
        return x0 / 512, 1 - y1 / 512, x1 / 512, 1 - y0 / 512

    def _uvs(self, bm, matrix, mat, uv, repeat, offset):
        """Per-face loop UVs for a temporary bmesh in local coordinates."""
        rep = repeat or repeat_of(mat)
        out = []
        rng = self.rng
        for face in bm.faces:
            n_local = face.normal
            local = [l.vert.co for l in face.loops]
            if uv == 'world':
                points = [matrix @ p for p in local]
                n = (matrix.to_3x3() @ n_local).normalized()
                axis = max(range(3), key=lambda i: abs(n[i]))
                a, b = [(1, 2), (0, 2), (0, 1)][axis]
                sign = -1 if (axis == 0 and n[0] < 0) or (axis == 1 and n[1] > 0) else 1
                out.append([(sign * p[a] / rep + offset[0], p[b] / rep + offset[1]) for p in points])
            elif uv == 'local':
                # Grain (the painting's vertical) follows the face's longer local edge.
                axis = max(range(3), key=lambda i: abs(n_local[i]))
                a, b = [(1, 2), (0, 2), (0, 1)][axis]
                span_a = max(p[a] for p in local) - min(p[a] for p in local)
                span_b = max(p[b] for p in local) - min(p[b] for p in local)
                if span_a > span_b:
                    a, b = b, a
                out.append([(p[a] / rep + offset[0], p[b] / rep + offset[1]) for p in local])
            elif isinstance(uv, tuple) and uv[0] == 'blocks':
                axis = max(range(3), key=lambda i: abs(n_local[i]))
                a, b = [(1, 2), (0, 2), (0, 1)][axis]
                lo_a, hi_a = min(p[a] for p in local), max(p[a] for p in local)
                lo_b, hi_b = min(p[b] for p in local), max(p[b] for p in local)
                u0, v0, u1, v1 = self._rect(rng.choice(STONE_BLOCKS), hi_a - lo_a, hi_b - lo_b, rng)
                out.append([(u0 + (u1 - u0) * (p[a] - lo_a) / max(hi_a - lo_a, 1e-5),
                             v0 + (v1 - v0) * (p[b] - lo_b) / max(hi_b - lo_b, 1e-5)) for p in local])
            elif isinstance(uv, tuple) and uv[0] == 'rect':
                axis = max(range(3), key=lambda i: abs(n_local[i]))
                a, b = [(1, 2), (0, 2), (0, 1)][axis]
                lo_a, hi_a = min(p[a] for p in local), max(p[a] for p in local)
                lo_b, hi_b = min(p[b] for p in local), max(p[b] for p in local)
                u0, v0, u1, v1 = uv[1]
                out.append([(u0 + (u1 - u0) * (p[a] - lo_a) / max(hi_a - lo_a, 1e-5),
                             v0 + (v1 - v0) * (p[b] - lo_b) / max(hi_b - lo_b, 1e-5)) for p in local])
            else:
                out.append([(p[0] * .5, p[1] * .5 + p[2] * .5) for p in local])
        return out

    def _take(self, bm, matrix, mat, uv='world', repeat=None, smooth=False, offset=None):
        if offset is None:
            offset = (self.rng.random(), self.rng.random()) if uv == 'local' else (0.0, 0.0)
        uvs = self._uvs(bm, matrix, mat, uv, repeat, offset)
        verts = [matrix @ v.co for v in bm.verts]
        index = {v: i for i, v in enumerate(bm.verts)}
        faces = [[index[l.vert] for l in f.loops] for f in bm.faces]
        self.add(mat, verts, faces, uvs, smooth or mat in SOFT)
        bm.free()

    # -- primitives --------------------------------------------------------------------------------------------
    def box(self, mat, at, size, rot=(0, 0, 0), bevel=.015, uv='world', repeat=None, segments=1, offset=None):
        bm = bmesh.new()
        bmesh.ops.create_cube(bm, size=1.0)
        bmesh.ops.scale(bm, vec=Vector(size), verts=bm.verts)
        # A soft arris only shows on pieces big enough to catch the light; bars, hinges and battens stay square.
        if bevel > 0 and min(size) >= .06:
            bmesh.ops.bevel(bm, geom=list(bm.edges), offset=min(bevel, min(size) * .45), segments=segments,
                            affect='EDGES', profile=.5)
        rotation = rot if isinstance(rot, Matrix) else Euler(rot).to_matrix()
        self._take(bm, Matrix.Translation(Vector(at)) @ rotation.to_4x4(), mat, uv, repeat, False, offset)

    def beam(self, mat, a, b, width, height, up=(0, 0, 1), bevel=.012, uv='local'):
        """A timber or stone member from a to b, `width` across and `height` along `up`."""
        a, b = Vector(a), Vector(b)
        axis = (b - a).normalized()
        upv = Vector(up)
        upv = (upv - axis * upv.dot(axis)).normalized()
        side = axis.cross(upv)
        rotation = Matrix((side, axis, upv)).transposed()
        self.box(mat, (a + b) / 2, (width, (b - a).length, height), rotation, bevel, uv)

    def cylinder(self, mat, a, b, radius, sides=8, radius_b=None, uv='local', caps=True, smooth=True):
        a, b = Vector(a), Vector(b)
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=caps, segments=sides, radius1=radius,
                              radius2=radius if radius_b is None else radius_b, depth=(b - a).length)
        rotation = (b - a).to_track_quat('Z', 'Y').to_matrix().to_4x4()
        self._take(bm, Matrix.Translation((a + b) / 2) @ rotation, mat, uv, None, smooth)

    def sphere(self, mat, at, radius, subdivisions=1, squash=(1, 1, 1)):
        if mat in SOFT and radius > .14:
            subdivisions = max(subdivisions, 2)
        elif radius < .06:
            subdivisions = 0
        bm = bmesh.new()
        bmesh.ops.create_icosphere(bm, subdivisions=subdivisions, radius=1.0)
        bmesh.ops.scale(bm, vec=Vector((radius * squash[0], radius * squash[1], radius * squash[2])), verts=bm.verts)
        self._take(bm, Matrix.Translation(Vector(at)), mat, 'flat', None, True)

    def prism(self, mat, polygon, z0, z1, uv='world'):
        """A convex polygon [(x, y), ...] counter-clockwise, extruded z0..z1."""
        bm = bmesh.new()
        lower = [bm.verts.new((x, y, z0)) for x, y in polygon]
        upper = [bm.verts.new((x, y, z1)) for x, y in polygon]
        bm.faces.new(list(reversed(lower)))
        bm.faces.new(upper)
        for i in range(len(polygon)):
            j = (i + 1) % len(polygon)
            bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
        bm.normal_update()
        self._take(bm, Matrix.Identity(4), mat, uv)

    def solid(self, mat, points, depth, normal, uv='world'):
        """A flat polygon (3D points, counter-clockwise seen from `normal`) thickened `depth` against its normal."""
        n = Vector(normal).normalized()
        bm = bmesh.new()
        front = [bm.verts.new(Vector(p)) for p in points]
        back = [bm.verts.new(Vector(p) - n * depth) for p in points]
        f = bm.faces.new(front)
        bm.faces.new(list(reversed(back)))
        for i in range(len(points)):
            j = (i + 1) % len(points)
            bm.faces.new((front[j], front[i], back[i], back[j]))
        bm.normal_update()
        if f.normal.dot(n) < 0:
            bmesh.ops.reverse_faces(bm, faces=list(bm.faces))
        self._take(bm, Matrix.Identity(4), mat, uv)

    def pane(self, mat, centre, width, height, facing, offset=0.0):
        """One flat pane showing a whole picture (UV 0..1), centred on `centre` and pushed `offset` along `facing`."""
        f = Vector((facing[0], facing[1], 0))
        across = Vector((-f.y, f.x, 0))
        c = Vector(centre) + f * offset
        w, h = width / 2, height / 2
        up = Vector((0, 0, h))
        verts = [c - across * w - up, c + across * w - up, c + across * w + up, c - across * w + up]
        self.add(mat, verts, [(0, 1, 2, 3)], [[(0, 0), (1, 0), (1, 1), (0, 1)]])

    def finish(self, root):
        """Static buckets become one object per material; each optional group becomes one multi-material object
        (glass split into `<group>_glass`)."""
        objects = {}
        for (group, mat), bucket in sorted(self.data.items()):
            if not bucket['f']:
                continue
            clear = any(word in mat for word in CLEAR)
            name = _mat(mat).name if group == 'static' else group + ('_glass' if clear else '')
            mesh = bpy.data.meshes.new(name)
            mesh.from_pydata(bucket['v'], [], bucket['f'])
            layer = mesh.uv_layers.new(name='UVMap')
            for poly, loop_uvs, smooth in zip(mesh.polygons, bucket['uv'], bucket['smooth']):
                poly.use_smooth = smooth
                for li, uv in zip(poly.loop_indices, loop_uvs):
                    layer.data[li].uv = uv
            mesh.validate(clean_customdata=False)
            mesh.update()
            obj = bpy.data.objects.new(name, mesh)
            obj.data.materials.append(_mat(mat))
            bpy.context.scene.collection.objects.link(obj)
            objects.setdefault(name, []).append(obj)
        for name, parts in objects.items():
            bpy.ops.object.select_all(action='DESELECT')
            for obj in parts:
                obj.select_set(True)
            bpy.context.view_layer.objects.active = parts[0]
            if len(parts) > 1:
                bpy.ops.object.join()
            obj = bpy.context.view_layer.objects.active
            obj.name = name
            obj.data.name = name
            obj.parent = root
        self.data = {}


# --- walls ---------------------------------------------------------------------------------------------------------
def _quad(verts, faces, points, outward):
    p = [Vector(q) for q in points]
    if (p[1] - p[0]).cross(p[2] - p[0]).dot(Vector(outward)) < 0:
        p = p[::-1]
    base = len(verts)
    verts.extend(p)
    faces.append((base, base + 1, base + 2, base + 3))


def wall(parts, mat, a, b, z0, z1, depth=.24, openings=(), uoff=None):
    """A wall slab whose outer face runs a→b (2D) facing to its right (walls run counter-clockwise seen from above),
    `depth` thick behind it. Openings (s0, s1, bottom, top) along the wall get lined reveals. Painted in world units,
    continuous round corners."""
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
    rep = repeat_of(mat)
    # Continuous painting round the house: the run along the outline from the wall's start.
    start = (a[0] + a[1]) if uoff is None else uoff
    uvs = []
    for face in faces:
        pts = [verts[i] for i in face]
        n = (pts[1] - pts[0]).cross(pts[2] - pts[0]).normalized()
        loop = []
        for p in pts:
            v = p - a3
            s, d, z = v.dot(along), -v.dot(out), p.z
            if abs(n.z) > .5:
                loop.append(((start + s) / rep, d / rep))
            elif abs(n.dot(along)) > .5:
                loop.append(((start + s + d) / rep, z / rep))
            else:
                loop.append(((start + s) / rep, z / rep))
        uvs.append(loop)
    parts.add(mat, verts, faces, uvs)


def gable(parts, mat, axis, at, s0, s1, z0, apex, outward, depth=.24):
    """A triangular gable end in the plane x = at (axis 'x') or y = at (axis 'y'), s0..s1 along it, eaves z0 to the
    apex z = apex over the middle; painted in world units like the walls below it."""
    mid = (s0 + s1) / 2
    if axis == 'x':
        pts = [(at, s0, z0), (at, s1, z0), (at, mid, apex)]
        normal = (outward, 0, 0)
    else:
        pts = [(s0, at, z0), (s1, at, z0), (mid, at, apex)]
        normal = (0, outward, 0)
    n = Vector(normal)
    if (Vector(pts[1]) - Vector(pts[0])).cross(Vector(pts[2]) - Vector(pts[0])).dot(n) < 0:
        pts = [pts[1], pts[0], pts[2]]
    parts.solid(mat, pts, depth, normal)


# --- stonework -----------------------------------------------------------------------------------------------------
def quoins(parts, corner, faces, z0, z1, course=.3, long=.5, short=.3, proud=.035, depth=.18):
    """Dressed corner stones from z0 to z1 alternating long and short along the two walls meeting at `corner`.
    `faces` are the outward 2D normals of the two walls, e.g. ((0, -1), (1, 0)) for the south-east corner."""
    (fx, fy), (gx, gy) = faces
    cx, cy = corner
    count = max(1, round((z1 - z0) / course))
    h = (z1 - z0) / count
    for k in range(count):
        z = z0 + h * (k + .5)
        a_len, b_len = (long, short) if k % 2 == 0 else (short, long)
        # Along the first wall the block runs away from the corner in the direction of the second wall's inward.
        ax, ay = -gx, -gy
        bx, by = -fx, -fy
        pa = (cx + ax * (a_len - proud) / 2 + fx * proud / 2, cy + ay * (a_len - proud) / 2 + fy * proud / 2, z)
        size_a = (abs(ax) * (a_len + proud) + abs(fx) * (depth + proud), abs(ay) * (a_len + proud) + abs(fy) * (depth + proud), h - .025)
        parts.box('stone', (pa[0] - fx * depth / 2, pa[1] - fy * depth / 2, z), size_a, bevel=.02, uv=('blocks', 0))
        pb = (cx + bx * b_len / 2 + gx * proud / 2, cy + by * b_len / 2 + gy * proud / 2, z)
        size_b = (abs(bx) * b_len + abs(gx) * (depth + proud), abs(by) * b_len + abs(gy) * (depth + proud), h - .025)
        parts.box('stone', (pb[0] - gx * depth / 2, pb[1] - gy * depth / 2, z), size_b, bevel=.02, uv=('blocks', 0))


def band(parts, mat, a, b, z, height, proud, facing, depth=.2, bevel=.015):
    """A string course, plinth or cornice along a wall face from a to b (2D), standing `proud` of it."""
    a, b = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    f = Vector((facing[0], facing[1], 0))
    mid = (a + b) / 2 + f * (proud - depth / 2)
    length = (b - a).length
    size = (length, depth, height) if abs(f.y) > .5 else (depth, length, height)
    parts.box(mat, (mid.x, mid.y, z + height / 2), size, bevel=bevel, uv='world')


def surround(parts, centre, width, height, facing, sill=True, lintel=True, jambs=True, keystone=False, depth=.16, proud=.04, arch=False):
    """Dressed stone jambs, lintel and sill round an opening whose outer wall face passes through `centre`."""
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector(centre)

    def put(off_across, z, w, h, d=depth, out=proud, bevel=.018):
        p = c + across * off_across + f * (out - d / 2)
        sx, sy = (w, d) if abs(f.y) > .5 else (d, w)
        parts.box('stone', (p.x, p.y, z), (sx, sy, h), bevel=bevel, uv=('blocks', 0))

    bottom, top = c.z - height / 2, c.z + height / 2
    jw = .16
    if jambs:
        stones = max(2, round(height / .32))
        sh = height / stones
        for side in (-1, 1):
            for k in range(stones):
                w = jw + (.06 if k % 2 == 0 else 0)
                put(side * (width / 2 + w / 2), bottom + sh * (k + .5), w, sh - .02)
    if lintel and not arch:
        put(0, top + .11, width + 2 * jw + .1, .22)
        if keystone:
            put(0, top + .13, .2, .28, out=proud + .025)
    if arch:
        r = width / 2 + .02
        stones = 9
        for k in range(stones):
            t0, t1 = math.pi * k / stones, math.pi * (k + 1) / stones
            tm = (t0 + t1) / 2
            ring = r + .11
            p = c + across * (-math.cos(tm) * ring) + f * (proud - depth / 2)
            z = top - r + math.sin(tm) * ring
            rot = Matrix.Rotation(-(tm - math.pi / 2) * (1 if abs(f.y) > .5 else -1), 3, 'Y' if abs(f.y) > .5 else 'X')
            size = (2 * ring * math.sin((t1 - t0) / 2) - .02, depth, .22) if abs(f.y) > .5 else (depth, 2 * ring * math.sin((t1 - t0) / 2) - .02, .22)
            parts.box('stone', (p.x, p.y, z), size, rot, .015, ('blocks', 0))
    if sill:
        put(0, bottom - .05, width + .3, .1, d=depth + .1, out=proud + .08)


def worn_patch(parts, centre, facing, rows=3, mat='brick'):
    """A ragged spot where the limewash has worn back to the brick beneath: a few staggered courses, widest in the
    middle, standing just proud of the plaster. `centre` is a point on the wall face; keep it clear of openings."""
    rng = parts.rng
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector(centre) + f * .012
    course = .085
    for r in range(rows):
        width = (.55 - abs(r - (rows - 1) / 2) * .16) * rng.uniform(.8, 1.15)
        p = c + across * rng.uniform(-.06, .06) + Vector((0, 0, (r - (rows - 1) / 2) * course))
        size = (width, .025, course) if abs(f.y) > .5 else (.025, width, course)
        parts.box(mat, tuple(p), size, bevel=0, uv='world')


# --- openings ------------------------------------------------------------------------------------------------------
def window(parts, centre, width, height, facing, *, recess=.12, shutters='open', shutter_group=None, box=True,
           box_group='detail_window_boxes', bars=(1, 2), stone=True, keystone=False, flowers=None, sill_pots=0,
           shutter_mat='shutter'):
    """A casement window in a wall opening whose outer face passes through `centre`. The painted pane (with its lace
    curtains) sits `recess` back with a cream sash and glazing bars on it; dressed stone surround; painted board
    shutters standing open against the wall (or 'closed', or None); a timber flower box on brackets.
    `shutter_group` puts the shutters in an alternative group (alt_shutters_open / alt_shutters_drawn)."""
    rng = parts.rng
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector(centre)

    def place(mat, off_across, off_out, z, w, d, h, bevel=.008, uv='local', rot=None):
        p = c + across * off_across + f * off_out
        sx, sy = (w, d) if abs(f.y) > .5 else (d, w)
        parts.box(mat, (p.x, p.y, z), (sx, sy, h), rot or (0, 0, 0), bevel, uv)

    parts.pane('window_pane', centre, width, height, facing, -recess)
    sash = -recess + .03
    for side in (-1, 1):
        place('sash', side * (width / 2 - .03), sash, c.z, .06, .05, height, uv='flat')
    for z in (c.z - height / 2 + .03, c.z + height / 2 - .03):
        place('sash', 0, sash, z, width, .05, .06, uv='flat')
    place('sash', 0, sash + .005, c.z, .045, .045, height - .05, uv='flat')
    for i in range(bars[1]):
        place('sash', 0, sash + .008, c.z - height / 2 + height * (i + 1) / (bars[1] + 1), width - .05, .035, .03, .004, 'flat')
    if bars[0] > 1:
        for side in (-1, 1):
            place('sash', side * width / 4, sash + .008, c.z, .03, .035, height - .05, .004, 'flat')
    if stone:
        surround(parts, centre, width, height, facing, keystone=keystone)
    else:
        place('timber', 0, .02, c.z + height / 2 + .07, width + .26, .08, .14, .01)
        place('timber', 0, .07, c.z - height / 2 - .04, width + .2, .16, .07, .01)

    def leaf(off, z, w, h, out, group):
        with parts.into(group or parts.group):
            place(shutter_mat, off, out, z, w, .045, h, .01)
            for k, zz in enumerate((z - h * .36, z + h * .36)):
                place(shutter_mat, off, out + .03, zz, w * .86, .025, .09, .006)
            # The diagonal brace between the two ledges.
            diag = math.atan2(h * .62, w * .7) * (1 if off >= 0 else -1)
            p = c + across * off + f * (out + .03)
            brace = math.hypot(w * .7, h * .62)
            if abs(f.y) > .5:
                parts.box(shutter_mat, (p.x, p.y, z), (brace, .025, .075), (0, diag, 0), .006, 'local')
            else:
                parts.box(shutter_mat, (p.x, p.y, z), (.025, brace, .075), (diag, 0, 0), .006, 'local')
            for zz in (z - h * .36, z + h * .36):
                hinge = c + across * (off - math.copysign(w * .25, off) if off else 0) + f * (out + .045)
                sx, sy = (w * .55, .012) if abs(f.y) > .5 else (.012, w * .55)
                parts.box('iron', (hinge.x, hinge.y, zz), (sx, sy, .03), bevel=.004, uv='flat')

    sw = width / 2 + .02
    group = shutter_group
    if shutters in ('open', 'both'):
        for side in (-1, 1):
            leaf(side * (width / 2 + .16 + sw / 2), c.z, sw, height + .04, .05, group if shutters == 'open' else 'alt_shutters_open')
    if shutters in ('closed', 'both'):
        for side in (-1, 1):
            leaf(side * sw / 2, c.z, sw - .01, height + .04, .025, group if shutters == 'closed' else 'alt_shutters_drawn')
        with parts.into(group if shutters == 'closed' else 'alt_shutters_drawn'):
            place('iron', 0, .07, c.z, .26, .02, .025, .004, 'flat')
    if box:
        with parts.into(box_group):
            bz = c.z - height / 2 - .2
            place('timber', 0, .2, bz, width + .14, .26, .2, .015)
            for side in (-1, 1):
                place('timber', side * (width / 2 - .05), .14, bz - .16, .05, .2, .05, .006)
            place('soil', 0, .2, bz + .095, width + .06, .2, .02, 0, 'flat')
            palette = flowers or ('flower_white', 'flower_pink', 'flower_red')
            for k in range(9):
                off = -width / 2 + (k + .5) * width / 9
                p = c + across * off + f * (.2 + rng.uniform(-.06, .06))
                parts.sphere(('leaf', 'leaf_light', 'leaf_dark')[k % 3], (p.x, p.y, bz + .12 + rng.uniform(0, .06)), rng.uniform(.07, .1), 1)
                if k % 2 == 0 or rng.random() < .4:
                    q = p + f * .07
                    parts.sphere(palette[rng.randrange(len(palette))], (q.x, q.y, bz + .2 + rng.uniform(0, .05)), .045, 1)
            for side in (-1, 1):
                if rng.random() < .7:
                    p = c + across * side * (width / 2 - .05) + f * .3
                    for j in range(4):
                        parts.sphere('leaf_dark' if j % 2 else 'leaf', (p.x, p.y, bz - .05 - j * .09), .06, 1, (1, 1, 1.3))
    for k in range(sill_pots):
        with parts.into('detail_planters'):
            off = (k - (sill_pots - 1) / 2) * width / max(sill_pots, 1) * .8
            p = c + across * off + f * .1
            pot(parts, (p.x, p.y, c.z - height / 2), .45, 'flowers')


def door(parts, centre_x, wall_y, width, height, facing, *, style='plank', leaf_mat='shutter', recess=.13,
         arch=False, step=True, hood=None, fanlight=False, canopy_mat='roof', canopy_lift=.55):
    """A door in a wall opening, wall face through (centre_x, wall_y) for a south/north wall or (wall_y, centre_x)
    for an east/west one. `style` 'plank' is ledged boards with strap hinges; 'panel' a framed and panelled leaf."""
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector((centre_x, wall_y, 0)) if abs(f.y) > .5 else Vector((wall_y, centre_x, 0))

    def place(mat, off, out, z, w, d, h, bevel=.008, uv='local'):
        p = c + across * off + f * out
        sx, sy = (w, d) if abs(f.y) > .5 else (d, w)
        parts.box(mat, (p.x, p.y, z), (sx, sy, h), (0, 0, 0), bevel, uv)

    leaf_h = height - (width / 2 if arch else 0) - (.42 if fanlight else 0)
    face = -recess + .05
    if style == 'plank':
        boards = max(4, round(width / .17))
        bw = width / boards
        for k in range(boards):
            place(leaf_mat, -width / 2 + bw * (k + .5), face, leaf_h / 2, bw - .008, .05, leaf_h - .01, .006)
        if arch:
            r = width / 2
            for k in range(boards):
                x = -width / 2 + bw * (k + .5)
                top = math.sqrt(max(r * r - x * x, 0)) * .96
                place(leaf_mat, x, face, leaf_h + top / 2, bw - .008, .05, top, .004)
        for z in (leaf_h * .2, leaf_h * .78):
            place('iron', -width * .12, face + .035, z, width * .76, .015, .05, .004, 'flat')
            for k in range(4):
                place('iron', -width / 2 + .1 + k * width * .22, face + .045, z, .025, .012, .025, .003, 'flat')
        place(leaf_mat, 0, face + .025, leaf_h * .5, width * .9, .025, .08, .006)
        ring = c + across * (width * .3) + f * (face + .06)
        parts.cylinder('iron', (ring.x, ring.y, leaf_h * .5 + .07), (ring.x + f.x * .02, ring.y + f.y * .02, leaf_h * .5 + .07), .035, 10, uv='flat')
        parts.cylinder('iron', (ring.x + f.x * .02, ring.y + f.y * .02, leaf_h * .5 - .02), (ring.x + f.x * .03, ring.y + f.y * .03, leaf_h * .5 + .08), .012, 6, uv='flat')
        place('iron', width * .3, face + .03, leaf_h * .5 - .14, .06, .012, .12, .004, 'flat')
    else:
        place(leaf_mat, 0, face, leaf_h / 2, width - .02, .055, leaf_h - .01, .01)
        for side in (-1, 1):
            place(leaf_mat, side * (width / 2 - .08), face + .03, leaf_h / 2, .13, .03, leaf_h - .04, .006)
        for z in (.12, leaf_h * .48, leaf_h - .08):
            place(leaf_mat, 0, face + .03, z, width - .1, .03, .13, .006)
        for z0, z1 in ((.2, leaf_h * .45), (leaf_h * .52, leaf_h - .16)):
            for side in (-1, 1):
                place(leaf_mat, side * width * .19, face + .035, (z0 + z1) / 2, width * .3, .02, z1 - z0 - .06, .02)
        knob = c + across * (width * .36) + f * (face + .06)
        parts.sphere('brass', (knob.x, knob.y, leaf_h * .48), .04, 1)
        place('brass', 0, face + .05, leaf_h * .62, .26, .01, .06, .004, 'flat')
    if fanlight:
        parts.pane('window_pane', (c + f * (-recess + .02)).to_tuple()[:2] + (leaf_h + .21,), width - .06, .36, facing)
        place('sash', 0, -recess + .06, leaf_h + .02, width, .05, .06, .004, 'flat')
        for k in range(3):
            place('sash', -width / 2 + width * (k + 1) / 4, -recess + .06, leaf_h + .21, .035, .04, .36, .004, 'flat')
    surround(parts, (c.x, c.y, height / 2), width, height, facing, sill=False, arch=arch, keystone=not arch and hood is None)
    if arch:
        # Stone fills the corners of the opening above the curved head.
        r = width / 2
        spring = height - r
        for side in (-1, 1):
            outline = [(side * r * math.cos(math.pi / 2 * k / 8), spring + r * math.sin(math.pi / 2 * k / 8)) for k in range(9)]
            outline.append((side * r, height))
            parts.solid('stone', [c + across * x + Vector((0, 0, z)) for x, z in outline], .2, (f.x, f.y, 0))
    if step:
        place('stone', 0, .2, .07, width + .5, .42, .14, .02, ('blocks', 0))
    if hood == 'cornice':
        place('stone', 0, .2, height + .36, width + .9, .42, .12, .02, 'world')
        place('stone', 0, .15, height + .27, width + .7, .3, .08, .015, 'world')
        for side in (-1, 1):
            for k, (dz, dd, hh) in enumerate(((.05, .26, .1), (-.07, .18, .14), (-.2, .1, .14))):
                place('stone', side * (width / 2 + .27), dd / 2 + .03, height + .2 + dz, .16, dd, hh, .015, ('blocks', 0))
    elif hood == 'canopy':
        canopy(parts, (c.x, c.y), width + .7, .75, height + canopy_lift, facing, mat=canopy_mat)


def canopy(parts, foot, width, reach, z, facing, pitch=25, mat='roof'):
    """A little tiled hood over a door on two timber brackets."""
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector((foot[0], foot[1], 0))
    rise = reach * math.tan(math.radians(pitch))
    eave = c + f * reach
    slope_courses(parts, (eave.x, eave.y, z), across, (-f * reach + Vector((0, 0, rise))).normalized(), math.hypot(reach, rise), width, width, mat=mat)
    eave_tiles(parts, (eave.x, eave.y, z), across, (-f * reach + Vector((0, 0, rise))).normalized(), width, mat)
    for side in (-1, 1):
        p = c + across * side * (width / 2 - .15)
        parts.beam('timber', (p.x + f.x * .05, p.y + f.y * .05, z - .55), (p.x + f.x * (reach - .1), p.y + f.y * (reach - .1), z - .02), .07, .08)
        parts.beam('timber', (p.x + f.x * .05, p.y + f.y * .05, z - .05), (p.x + f.x * (reach - .05), p.y + f.y * (reach - .05), z - .05), .08, .1)
    parts.beam('timber', (c + across * (-width / 2) + f * (reach - .05)).to_tuple()[:2] + (z - .06,), (c + across * (width / 2) + f * (reach - .05)).to_tuple()[:2] + (z - .06,), .08, .12)


# --- roofs ---------------------------------------------------------------------------------------------------------
def _slope_frame(along, up):
    u = Vector(along).normalized()
    v = Vector(up).normalized()
    if u.cross(v).z < 0:
        return -u, v, (-u).cross(v), True
    return u, v, u.cross(v), False


def slope_courses(parts, eave_mid, along, up, length, w0, w1, *, span=None, mat='roof', course=None, lift=.05):
    """Courses of painted pan tiles on one roof slope of any outline (rectangle, trapezoid for hips, triangle). The slope
    starts at its eave edge, centred on `eave_mid`, `w0` wide along `along`, and climbs `length` along the unit `up`
    to an edge `w1` wide; `span` = (a0, a1, b0, b1) gives both edges' ends instead. Each course is a thin slab whose
    foot lifts off the one below; its painting is the band between two tile foots, so painted tiles and steps agree."""
    a0, a1, b0, b1 = span or (-w0 / 2, w0 / 2, -w1 / 2, w1 / 2)
    u, v, n, flipped = _slope_frame(along, up)
    if flipped:
        a0, a1, b0, b1 = -a1, -a0, -b1, -b0
    pitch = course or REPEAT['roof'] * ROOF_COURSE_V[1]
    rows = max(1, math.ceil(length / pitch))
    v_foot, v_band = ROOF_COURSE_V
    e = Vector(eave_mid)
    rep = REPEAT['roof']
    for r in range(rows):
        s0 = r * pitch
        s1 = min(length, s0 + pitch + .06)
        lo0, hi0 = a0 + (b0 - a0) * s0 / length, a1 + (b1 - a1) * s0 / length
        lo1, hi1 = a0 + (b0 - a0) * s1 / length, a1 + (b1 - a1) * s1 / length
        if hi0 - lo0 < .02 and hi1 - lo1 < .02:
            continue
        foot = e + v * s0 + n * lift
        head = e + v * s1 + n * .012
        top = [foot + u * lo0, foot + u * hi0, head + u * hi1, head + u * lo1]
        bottom = [p - n * .035 for p in top]
        verts = top + bottom
        faces = [(0, 1, 2, 3), (7, 6, 5, 4), (4, 5, 1, 0), (5, 6, 2, 1), (7, 4, 0, 3), (6, 7, 3, 2)]
        ext = (s1 - s0) / pitch
        foot_v, head_v = v_foot, v_foot + v_band * ext

        def uu(x):
            return x / rep

        uvs = [[(uu(lo0), foot_v), (uu(hi0), foot_v), (uu(hi1), head_v), (uu(lo1), head_v)],
               [(uu(lo1), head_v), (uu(hi1), head_v), (uu(hi0), foot_v), (uu(lo0), foot_v)],
               [(uu(lo0), foot_v - .03), (uu(hi0), foot_v - .03), (uu(hi0), foot_v), (uu(lo0), foot_v)],
               [(.4, foot_v), (.4, foot_v), (.42, head_v), (.42, head_v)],
               [(.4, foot_v), (.4, foot_v), (.42, head_v), (.42, head_v)],
               [(uu(hi1), head_v), (uu(lo1), head_v), (uu(lo1), head_v), (uu(hi1), head_v)]]
        parts.add(mat, verts, faces, uvs)
    # The boarded deck beneath, so no daylight shows between courses.
    top = [e + u * a0, e + u * a1, e + v * length + u * b1, e + v * length + u * b0]
    if b1 - b0 < 1e-3:
        top = top[:3]
    parts.solid('timber', [p - n * .03 for p in top], .06, n, 'world')


def eave_tiles(parts, eave_mid, along, up, width, mat='roof', radius=.065):
    """The rounded mouths of the bottom course along an eave: the scalloped edge of a pan-tiled roof."""
    u, v, n, flipped = _slope_frame(along, up)
    rep = REPEAT['roof']
    # Painted tile centres lie midway between the measured joints (u = .172 + k / 7); the course painting runs
    # u = x / repeat from the eave's middle, so each mouth caps the painted tile beneath it.
    centre = .172
    k0 = math.floor((-width / 2) / rep * ROOF_COLUMNS) - 1
    for k in range(k0, k0 + int(width / rep * ROOF_COLUMNS) + 3):
        x = (centre + k / ROOF_COLUMNS) * rep
        if abs(x) > width / 2 - .1:
            continue
        x = -x if flipped else x
        p = Vector(eave_mid) + u * x + n * (.05 + radius * .2)
        u0 = (centre - .25 / ROOF_COLUMNS) % 1
        rect = ('rect', (u0, ROOF_COURSE_V[0] + .06, u0 + .5 / ROOF_COLUMNS, ROOF_COURSE_V[0] + .16))
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=radius, radius2=radius * .9, depth=.3)
        bmesh.ops.delete(bm, geom=[vv for vv in bm.verts if vv.co.y < -1e-4], context='VERTS')
        frame = Matrix((u, n, v)).transposed().to_4x4()
        parts._take(bm, Matrix.Translation(p + v * .1) @ frame, mat, rect, None, True)


def ridge_caps(parts, a, b, mat='ridge', radius=.1, piece=.4):
    """Half-round capping tiles from a to b, each slightly flared and overlapping the next."""
    a, b = Vector(a), Vector(b)
    length = (b - a).length
    count = max(1, round(length / piece))
    step = (b - a) / count
    tile = 1 / ROOF_COLUMNS
    for k in range(count):
        p0 = a + step * k
        p1 = a + step * (k + 1) + step.normalized() * .04
        col = (k * 3) % ROOF_COLUMNS
        bm = bmesh.new()
        bmesh.ops.create_cone(bm, cap_ends=True, segments=10, radius1=radius * 1.08, radius2=radius, depth=(p1 - p0).length)
        rotation = (p1 - p0).to_track_quat('Z', 'Y').to_matrix().to_4x4()
        rect = ('rect', ((col + .2) * tile, ROOF_COURSE_V[0] + .04, (col + .8) * tile, ROOF_COURSE_V[0] + ROOF_COURSE_V[1] - .02))
        parts._take(bm, Matrix.Translation((p0 + p1) / 2) @ rotation, mat, rect, None, True)


def gable_roof(parts, x0, x1, y0, y1, z, pitch, *, eave=.38, verge=.28, axis='x', bargeboards=True, gutters=True,
               caps=True, roof_mat='roof', cap_mat='ridge'):
    """A pan-tiled gable roof over the rectangle with its ridge along `axis`; returns (ridge height, eave height,
    eave offset). Includes scalloped eave mouths, ridge caps, verge tiles, bargeboards and iron gutters."""
    t = math.tan(math.radians(pitch))
    if axis == 'x':
        run = (y1 - y0) / 2 + eave
        rise = run * t
        z0 = z - eave * t
        w = x1 - x0 + 2 * verge
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        length = math.hypot(run, rise)
        for sign, ey in ((1, y0 - eave), (-1, y1 + eave)):
            up = Vector((0, sign * run, rise)).normalized()
            along = Vector((sign, 0, 0))
            slope_courses(parts, (cx, ey, z0), along, up, length, w, w, mat=roof_mat)
            eave_tiles(parts, (cx, ey, z0), along, up, w, roof_mat)
            if gutters:
                gutter(parts, (x0 - verge + .05, ey + sign * .02, z0 - .05), (x1 + verge - .05, ey + sign * .02, z0 - .05))
        ridge = z0 + rise
        if caps:
            ridge_caps(parts, (x0 - verge - .02, cy, ridge + .045), (x1 + verge + .02, cy, ridge + .045), cap_mat)
        for x, side in ((x0 - verge, -1), (x1 + verge, 1)):
            for sign, ey in ((1, y0 - eave), (-1, y1 + eave)):
                p0 = Vector((x, ey, z0 + .03))
                p1 = Vector((x, cy, ridge + .03))
                ridge_caps(parts, p0, p1, roof_mat, .07, .38)
                if bargeboards:
                    off = Vector((side * -.03, 0, -.13))
                    parts.beam('timber', p0 + off + Vector((0, -sign * .05, 0)), p1 + off, .05, .22, up=(0, 0, 1))
        if bargeboards:
            for wall_x, side in ((x0, -1), (x1, 1)):
                x = wall_x + side * (verge - .1) / 2
                for k in range(1, 4):
                    t_ = k / 4
                    for sign, ey in ((1, y0 - eave), (-1, y1 + eave)):
                        p = Vector((x, ey + (cy - ey) * t_, z0 + rise * t_ - .2))
                        parts.box('timber', p, (verge + .05, .1, .1), bevel=.01, uv='local')
        return ridge, z0, eave
    raise NotImplementedError('ridge along y: rotate the house instead')


def hip_roof(parts, x0, x1, y0, y1, z, pitch, *, eave=.45, gutters=True, roof_mat='roof', cap_mat='ridge'):
    """A low hipped pan-tiled roof over the rectangle: four slopes, hip and ridge caps, scalloped eaves and gutters
    all round. Returns (ridge height, ridge ends, eave height)."""
    t = math.tan(math.radians(pitch))
    X0, X1, Y0, Y1 = x0 - eave, x1 + eave, y0 - eave, y1 + eave
    z0 = z - eave * t
    lx, ly = X1 - X0, Y1 - Y0
    run = min(lx, ly) / 2
    rise = run * t
    length = math.hypot(run, rise)
    cx, cy = (X0 + X1) / 2, (Y0 + Y1) / 2
    ridge = lx - 2 * run
    slopes = [((cx, Y0, z0), (1, 0, 0), (0, run, rise), lx, ridge), ((cx, Y1, z0), (-1, 0, 0), (0, -run, rise), lx, ridge),
              ((X1, cy, z0), (0, 1, 0), (-run, 0, rise), ly, 0), ((X0, cy, z0), (0, -1, 0), (run, 0, rise), ly, 0)]
    for mid, along, up, w0, w1 in slopes:
        upv = Vector(up).normalized()
        slope_courses(parts, mid, along, upv, length, w0, w1, mat=roof_mat)
        eave_tiles(parts, mid, along, upv, w0 - .3, roof_mat)
    top = z0 + rise
    ends = ((X0 + run, cy, top), (X1 - run, cy, top))
    ridge_caps(parts, (ends[0][0] - .05, cy, top + .05), (ends[1][0] + .05, cy, top + .05), cap_mat)
    for corner in ((X0, Y0), (X1, Y0), (X1, Y1), (X0, Y1)):
        apex = min(ends, key=lambda e: math.hypot(e[0] - corner[0], e[1] - corner[1]))
        ridge_caps(parts, (corner[0], corner[1], z0 + .07), (apex[0], apex[1], apex[2] + .05), cap_mat, .09, .38)
    if gutters:
        g = .04
        for a, b in (((X0 + .05, Y0 - g), (X1 - .05, Y0 - g)), ((X1 + g, Y0 + .05), (X1 + g, Y1 - .05)),
                     ((X1 - .05, Y1 + g), (X0 + .05, Y1 + g)), ((X0 - g, Y1 - .05), (X0 - g, Y0 + .05))):
            gutter(parts, (a[0], a[1], z0 - .05), (b[0], b[1], z0 - .05))
    return top, ends, z0


def lean_to(parts, x0, x1, wall_y, reach, z_top, z_low, facing, *, posts=True, verge_left=True, verge_right=True, mat='roof'):
    """A mono-pitch tiled roof against a wall at `wall_y`, falling `reach` outward along `facing` (0, ±1) from z_top to
    z_low, with a lead flashing, a fascia, eave mouths, a gutter and corner posts with braces."""
    f = Vector((0, facing, 0))
    cx = (x0 + x1) / 2
    width = x1 - x0
    run = reach
    rise = z_top - z_low
    eave = Vector((cx, wall_y + facing * reach, z_low))
    up = Vector((0, -facing * run, rise)).normalized()
    along = Vector((facing, 0, 0))
    slope_courses(parts, eave, along, up, math.hypot(run, rise) + .05, width, width, mat=mat)
    eave_tiles(parts, eave, along, up, width, mat)
    parts.box('lead', (cx, wall_y + facing * .06, z_top + .05), (width + .1, .14, .05), bevel=.01, uv='flat')
    parts.beam('timber', (x0 - .05, wall_y + facing * (reach - .04), z_low - .08), (x1 + .05, wall_y + facing * (reach - .04), z_low - .08), .08, .16)
    gutter(parts, (x0, wall_y + facing * (reach + .02), z_low - .06), (x1, wall_y + facing * (reach + .02), z_low - .06))
    for x, keep in ((x0 - .03, verge_left), (x1 + .03, verge_right)):
        if keep:
            ridge_caps(parts, (x, wall_y + facing * reach, z_low + .03), (x, wall_y + facing * .05, z_top + .03), mat, .065, .36)
    if posts:
        for x in (x0 + .08, x1 - .08):
            py = wall_y + facing * (reach - .12)
            parts.beam('timber', (x, py, 0), (x, py, z_low - .14), .14, .14, up=(0, 1, 0))
            parts.box('stone', (x, py, .06), (.24, .24, .12), bevel=.015, uv=('blocks', 0))
            parts.beam('timber', (x, py, z_low - .7), (x, wall_y + facing * .1, z_low - .14 + (z_top - z_low) * .1), .1, .1, up=(1, 0, 0))
            parts.beam('timber', (x, py, z_low - .14), (x, wall_y + facing * .06, z_low - .14 + (z_top - z_low) * .02), .12, .14, up=(1, 0, 0))


def lean_to_shed(parts, x0, x1, wall_y, reach, z_top, z_low, facing, *, wall_mat='plaster', roof_mat='roof',
                 door_x=None, window_x=None, shutter_mat='shutter'):
    """A small enclosed lean-to (pantry, wash house) against a wall at `wall_y`, reaching `reach` outward along `facing`
    (±1 on y): walls on three sides with sloping side tops, an optional plank door and small window in its outer wall,
    a stone plinth and its own tiled mono-pitch roof."""
    fy = facing
    yo = wall_y + fy * reach
    if fy > 0:
        sides = [((x1, wall_y), (x1, yo), (1, 0)), ((x1, yo), (x0, yo), (0, 1)), ((x0, yo), (x0, wall_y), (-1, 0))]
    else:
        sides = [((x0, wall_y), (x0, yo), (-1, 0)), ((x0, yo), (x1, yo), (0, -1)), ((x1, yo), (x1, wall_y), (1, 0))]
    for a, b, out in sides:
        openings = []
        if out[1] != 0:
            start = a[0]
            for cx, w, lo, hi in ((door_x, .82, 0, 2.0), (window_x, .55, 1.05, 1.7)):
                if cx is not None:
                    s = abs(cx - start)
                    openings.append((s - w / 2, s + w / 2, lo, min(hi, z_low - .12)))
        wall(parts, wall_mat, a, b, 0, z_low, .16, openings)
        band(parts, 'stone', a, b, 0, .3, .04, out)
    for x, out in ((x0, -1), (x1, 1)):
        pts = [(x, wall_y, z_low), (x, yo, z_low), (x, wall_y, z_top)]
        parts.solid(wall_mat, pts if (out > 0) == (fy > 0) else list(reversed(pts)), .16, (out, 0, 0))
    if door_x is not None:
        door(parts, door_x, yo, .82, 2.0, (0, fy), style='plank', leaf_mat=shutter_mat, recess=.1)
    if window_x is not None:
        window(parts, (window_x, yo, (1.05 + min(1.7, z_low - .12)) / 2), .55, min(1.7, z_low - .12) - 1.05, (0, fy),
               shutters=None, box=False, bars=(1, 1), recess=.08)
    lean_to(parts, x0 - .06, x1 + .06, wall_y, reach + .14, z_top, z_low - .04, fy, posts=False, mat=roof_mat)


def bench(parts, at, facing, length=1.3):
    """A slatted timber bench with a back, standing against a wall that faces `facing`."""
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector(at)

    def place(off, out, z, w, d, h):
        p = c + across * off + f * out
        size = (w, d, h) if abs(f.y) > .5 else (d, w, h)
        parts.box('timber', (p.x, p.y, z), size, bevel=.008, uv='local')
    for k in range(3):
        place(0, .05 + k * .13, .45, length, .11, .04)
    for k in range(3):
        place(0, -.12, .62 + k * .13, length, .04, .09)
    for side in (-1, 1):
        place(side * (length / 2 - .08), .12, .22, .07, .38, .44)
        place(side * (length / 2 - .08), -.13, .5, .07, .06, 1.0)


def dormer(parts, x, roof_eave_y, roof_eave_z, pitch, facing, *, in_from_eave, ridge_run, width=1.3, height=1.15,
           window_w=.62, window_h=.78, shutters='open', box=True, flowers=None, d_pitch=42, wall_mat='plaster',
           shutter_mat='shutter', roof_mat='roof', cap_mat='ridge'):
    """A gabled dormer standing on a roof slope that falls toward `facing` (±1 along y): plastered cheeks, a timber
    front frame, its own window, a little pan-tiled gable roof and lead flashing where it meets the slope."""
    t = math.tan(math.radians(pitch))
    fy = facing
    yd = roof_eave_y - fy * in_from_eave
    zb = roof_eave_z + in_from_eave * t
    zt = zb + height
    hw = width / 2
    d_rise = (hw + .15) * math.tan(math.radians(d_pitch))
    zr = zt + d_rise - .15 * math.tan(math.radians(d_pitch))
    back = (zr + .25 - roof_eave_z) / t
    if back > ridge_run - .1:
        raise ValueError('dormer would reach past the ridge; lower it or move it toward the eave')
    yb = roof_eave_y - fy * back
    # Front wall with its window opening, plaster or boards.
    front_y = yd
    a, b = ((x - hw, front_y), (x + hw, front_y)) if fy < 0 else ((x + hw, front_y), (x - hw, front_y))
    wall(parts, wall_mat, a, b, zb - .2, zt, .14, [(hw - window_w / 2, hw + window_w / 2, zb + (height - window_h) * .45, zb + (height - window_h) * .45 + window_h)])
    gable(parts, wall_mat, 'y', front_y, x - hw, x + hw, zt, zr - .05, fy, .14)
    for side in (-1, 1):
        sx = x + side * hw
        pts = [(sx, front_y, zb - .2), (sx, front_y, zt), (sx, yb, zt), (sx, yb, zt - .3)]
        normal = (side, 0, 0)
        if side < 0:
            pts = list(reversed(pts))
        parts.solid(wall_mat, pts, .12, normal)
    # Timber frame round the front.
    for side in (-1, 1):
        parts.box('timber', (x + side * (hw - .04), front_y + fy * .02, (zb + zt) / 2 - .1), (.1, .1, height + .2), bevel=.01, uv='local')
    parts.box('timber', (x, front_y + fy * .03, zt - .02), (width + .1, .12, .12), bevel=.01, uv='local')
    wc = (x, front_y, zb + (height - window_h) * .45 + window_h / 2)
    window(parts, wc, window_w, window_h, (0, fy), recess=.08, shutters=shutters, box=box, stone=False, bars=(1, 1),
           flowers=flowers, shutter_mat=shutter_mat)
    # Its roof: two slopes running back into the main roof.
    run = hw + .15
    for side in (-1, 1):
        eave_mid = Vector((x + side * run, (front_y + fy * .18 + yb) / 2, zt - .15 * math.tan(math.radians(d_pitch))))
        up = Vector((-side * run, 0, d_rise)).normalized()
        along = Vector((0, -side, 0))
        length = abs(front_y + fy * .18 - yb)
        slope_courses(parts, eave_mid, along, up, math.hypot(run, d_rise), length, length, mat=roof_mat)
    ridge_caps(parts, (x, front_y + fy * .22, zr + .03), (x, yb, zr + .03), cap_mat, .08, .34)
    for side in (-1, 1):
        p0 = Vector((x + side * (run + .02), front_y + fy * .2, zt - .15 * math.tan(math.radians(d_pitch)) + .02))
        p1 = Vector((x, front_y + fy * .2, zr + .02))
        ridge_caps(parts, p0, p1, roof_mat, .06, .3)
        parts.beam('timber', p0 + Vector((0, -fy * .03, -.1)), p1 + Vector((0, -fy * .03, -.1)), .05, .16, up=(0, 0, 1))
    # Lead flashing dressed over the tiles at the dormer's foot.
    lead_y = front_y + fy * .14
    lead_z = roof_eave_z + (in_from_eave - .14) * t + .07
    parts.box('lead', (x, lead_y, lead_z), (width + .02, .22, .025), (-fy * math.radians(pitch), 0, 0), 0, 'flat')
    return yb


def chimney(parts, x, y, z0, z1, *, width=.72, depth=.6, style='brick', pots=2, collar=None):
    """A chimney stack from z0 (inside the roof) to z1: painted brick or dressed stone, a stone collar where it leaves
    the roof, a projecting two-step stone cap and terracotta pots."""
    mat = 'brick' if style == 'brick' else 'stone'
    parts.box(mat, (x, y, (z0 + z1) / 2), (width, depth, z1 - z0), bevel=.015, uv='world')
    if collar is not None:
        parts.box('stone', (x, y, collar + .12), (width + .06, depth + .06, .24), bevel=.015, uv=('blocks', 0))
    parts.box('stone', (x, y, z1 + .05), (width + .16, depth + .16, .1), bevel=.02, uv=('blocks', 0))
    parts.box('stone', (x, y, z1 + .13), (width + .04, depth + .04, .07), bevel=.012, uv=('blocks', 0))
    for i in range(pots):
        px = x + (i - (pots - 1) / 2) * width * .45
        parts.cylinder('terracotta', (px, y, z1 + .16), (px, y, z1 + .52), .1, 10, .08, uv='flat')
        parts.cylinder('terracotta_dark', (px, y, z1 + .49), (px, y, z1 + .57), .1, 10, uv='flat')
        parts.cylinder('grate', (px, y, z1 + .565), (px, y, z1 + .575), .07, 10, uv='flat')


def text(parts, mat, words, matrix, size, align='CENTER'):
    """Lettering as flat geometry from Blender's built-in face (nothing depends on fonts at runtime). `matrix` places
    the text's plane: its x reads along, y is up, z faces the reader."""
    curve = bpy.data.curves.new('lettering', 'FONT')
    curve.body = words
    curve.size = size
    curve.align_x = align
    curve.align_y = 'CENTER'
    obj = bpy.data.objects.new('lettering', curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    verts = [matrix @ v.co for v in mesh.vertices]
    faces = [tuple(poly.vertices) for poly in mesh.polygons]
    parts.add(mat, verts, faces, [[(0, 0)] * len(f) for f in faces])
    bpy.data.objects.remove(obj)
    bpy.data.curves.remove(curve)
    bpy.data.meshes.remove(mesh)


def facing_text(x, y, z, facing):
    """A lettering matrix on a wall whose outward face is `facing` (0, -1) south, (1, 0) east, ..., read left to right."""
    f = Vector((facing[0], facing[1], 0)).normalized()
    across = Vector((-f.y, f.x, 0))
    return Matrix(((across.x, 0, f.x, x), (across.y, 0, f.y, y), (0, 1, 0, z), (0, 0, 0, 1)))


def awning(parts, centre, width, reach, z_top, drop, facing, colours=('canvas_green', 'canvas'), stripe=.32):
    """A striped canvas awning off a wall facing `facing`: stripes run down the slope, a scalloped valance across the
    front edge, two iron arms and a roller box at the wall."""
    f = Vector((facing[0], facing[1], 0)).normalized()
    across = Vector((-f.y, f.x, 0))
    c = Vector((centre[0], centre[1], 0))       # heights below come from z_top
    length = math.hypot(reach, drop)
    pitch = math.atan2(drop, reach)
    count = max(2, round(width / stripe))
    w = width / count
    for k in range(count):
        mid = c + across * (-width / 2 + w * (k + .5)) + f * reach / 2 + Vector((0, 0, z_top - drop / 2))
        rot = Matrix((across, f * math.cos(pitch) - Vector((0, 0, math.sin(pitch))), across.cross(f * math.cos(pitch) - Vector((0, 0, math.sin(pitch)))))).transposed()
        parts.box(colours[k % 2], tuple(mid), (w + .002, length, .025), rot, 0, 'flat')
        edge = c + across * (-width / 2 + w * (k + .5)) + f * (reach + .01) + Vector((0, 0, z_top - drop - .12))
        parts.box(colours[k % 2], tuple(edge), (w + .002 if abs(f.y) > .5 else .02, .02 if abs(f.y) > .5 else w + .002, .24), (0, 0, 0), 0, 'flat')
        parts.sphere(colours[k % 2], tuple(edge - Vector((0, 0, .13))), w * .5, 1, (1, .2, .45) if abs(f.y) > .5 else (.2, 1, .45))
    roller = c + Vector((0, 0, z_top + .06)) + f * .08
    parts.cylinder('iron', roller - across * (width / 2 + .05), roller + across * (width / 2 + .05), .07, 8, uv='flat')
    for side in (-1, 1):
        a = c + across * side * (width / 2 - .05) + Vector((0, 0, z_top - drop - .45))
        b = c + across * side * (width / 2 - .05) + f * reach + Vector((0, 0, z_top - drop))
        parts.cylinder('iron', a, b, .018, 6, uv='flat')


# --- metalwork -----------------------------------------------------------------------------------------------------
def gutter(parts, a, b, radius=.065):
    a, b = Vector(a), Vector(b)
    parts.cylinder('iron', a, b, radius, 8, uv='flat', smooth=True)
    direction = (b - a).normalized()
    count = max(1, int((b - a).length / .9))
    for k in range(count + 1):
        p = a + (b - a) * (k / count)
        parts.box('iron', p - Vector((0, 0, .02)), (.03 if abs(direction.x) < .5 else .03, .03, .1), bevel=.005, uv='flat')


def downpipe(parts, top, bottom_z, wall_out, swan=.25):
    """A downpipe from a gutter outlet at `top` that steps back to the wall (`wall_out` = 2D offset to the wall), then
    runs down with collars to a shoe and a drain grate."""
    top = Vector(top)
    wall = top + Vector((wall_out[0], wall_out[1], -swan))
    parts.cylinder('iron', top, top - Vector((0, 0, .1)), .05, 8, uv='flat')
    parts.cylinder('iron', top - Vector((0, 0, .08)), wall, .045, 8, uv='flat')
    foot = Vector((wall.x, wall.y, bottom_z + .22))
    parts.cylinder('iron', wall, foot, .045, 8, uv='flat')
    z = wall.z - .5
    while z > bottom_z + .5:
        parts.cylinder('iron_light', (wall.x, wall.y, z), (wall.x, wall.y, z + .06), .055, 8, uv='flat')
        z -= 1.25
    out = Vector((-wall_out[0], -wall_out[1], 0))
    if out.length > 0:
        out.normalize()
    shoe = foot + out * .14 + Vector((0, 0, -.15))
    parts.cylinder('iron', foot, shoe, .045, 8, uv='flat')
    g = shoe + out * .1
    parts.box('grate', (g.x, g.y, .015), (.3, .3, .03), bevel=.004, uv='flat')
    for k in range(4):
        off = (k - 1.5) * .06
        p = (g.x + off, g.y, .032) if abs(out.y) > .5 else (g.x, g.y + off, .032)
        parts.box('iron_light', p, (.025, .26, .01) if abs(out.y) > .5 else (.26, .025, .01), bevel=0, uv='flat')


def lantern(parts, at, facing, scale=1.0):
    """A wall lantern on a scrolled iron bracket; its glass is `house_lamp_glass`."""
    f = Vector((facing[0], facing[1], 0))
    p = Vector(at)
    s = scale
    parts.box('iron', p + f * .02, (.12 * s if abs(f.y) > .5 else .04, .04 if abs(f.y) > .5 else .12 * s, .22 * s), bevel=.01, uv='flat')
    arm = p + f * .28 * s + Vector((0, 0, .12 * s))
    parts.cylinder('iron', p + f * .03 + Vector((0, 0, .1 * s)), arm, .018 * s, 6, uv='flat')
    parts.cylinder('iron', p + f * .03 - Vector((0, 0, .06 * s)), arm - f * .06 * s, .014 * s, 6, uv='flat')
    body = arm - Vector((0, 0, .26 * s))
    parts.cylinder('iron', arm, arm - Vector((0, 0, .06 * s)), .015 * s, 6, uv='flat')
    parts.box('lamp_glass', body, (.17 * s, .17 * s, .26 * s), bevel=0, uv='flat')
    for dx in (-1, 1):
        for dy in (-1, 1):
            parts.box('iron', body + Vector((dx * .09 * s, dy * .09 * s, 0)), (.025 * s, .025 * s, .3 * s), bevel=.004, uv='flat')
    parts.cylinder('iron', body + Vector((0, 0, .15 * s)), body + Vector((0, 0, .27 * s)), .14 * s, 4, .03 * s, uv='flat', smooth=False)
    parts.box('iron', body - Vector((0, 0, .15 * s)), (.21 * s, .21 * s, .04 * s), bevel=.006, uv='flat')
    parts.sphere('iron', body - Vector((0, 0, .2 * s)), .025 * s, 1)


# --- dressing ------------------------------------------------------------------------------------------------------
def pot(parts, at, scale=1.0, plant='flowers', flowers=None):
    """A terracotta pot with a flowering plant, a clipped cone, a bay tree or trailing ivy."""
    rng = parts.rng
    x, y, z = at
    r, h = .2 * scale, .3 * scale
    parts.cylinder('terracotta', (x, y, z), (x, y, z + h), r * .72, 12, r, uv='flat')
    parts.cylinder('terracotta_dark', (x, y, z + h - .03 * scale), (x, y, z + h + .02 * scale), r * 1.08, 12, uv='flat')
    parts.cylinder('soil', (x, y, z + h), (x, y, z + h + .025 * scale), r * .95, 10, uv='flat')
    top = z + h + .02 * scale
    palette = flowers or ('flower_white', 'flower_pink', 'flower_red', 'flower_orange')
    if plant == 'cone':
        layers = 8
        for i in range(layers):
            t = i / (layers - 1)
            rr = r * 1.25 * (1 - t * .8)
            zz = top + .08 * scale + t * 1.0 * scale
            for j in range(5):
                a = j * math.tau / 5 + i
                parts.sphere('cypress' if (i + j) % 3 else 'cypress_light', (x + math.cos(a) * rr * .5, y + math.sin(a) * rr * .5, zz), rr * .62, 1)
    elif plant == 'tree':
        parts.cylinder('bark', (x, y, top), (x, y, top + .75 * scale), .025 * scale, 6, uv='flat')
        for j in range(9):
            a = rng.uniform(0, math.tau)
            d = rng.uniform(0, .2 * scale)
            parts.sphere(('olive', 'leaf', 'leaf_light')[j % 3], (x + math.cos(a) * d, y + math.sin(a) * d, top + (.8 + rng.uniform(-.1, .2)) * scale), rng.uniform(.12, .17) * scale, 1)
    else:
        for j in range(8):
            a = rng.uniform(0, math.tau)
            d = rng.uniform(0, r * .8)
            parts.sphere(('leaf', 'leaf_light', 'leaf_dark')[j % 3], (x + math.cos(a) * d, y + math.sin(a) * d, top + rng.uniform(.04, .16) * scale), rng.uniform(.07, .11) * scale, 1)
        for j in range(6):
            a = rng.uniform(0, math.tau)
            d = rng.uniform(0, r * .8)
            parts.sphere(palette[rng.randrange(len(palette))], (x + math.cos(a) * d, y + math.sin(a) * d, top + rng.uniform(.14, .24) * scale), .045 * scale, 1)


def barrel(parts, at, radius=.3, height=.75):
    x, y, z = at
    staves = 12
    for k in range(staves):
        a = k * math.tau / staves
        p = Vector((x + math.cos(a) * radius * .93, y + math.sin(a) * radius * .93, z + height / 2))
        parts.box('timber', p, (.06, radius * 2 * math.pi / staves, height), (0, 0, a), .008, 'local')
    for zz in (.12, height / 2, height - .12):
        parts.cylinder('iron', (x, y, z + zz - .025), (x, y, z + zz + .025), radius * 1.0, 14, uv='flat')
    parts.cylinder('timber', (x, y, z + height - .06), (x, y, z + height - .03), radius * .9, 12, uv='local')


def climber(parts, foot, height, facing, *, spread=.35, flowers=('flower_white', 'flower_pink'), bloom=.3, density=14):
    """A climbing rose or jasmine up a wall: a wandering stem with leaf clumps and a scatter of blossom."""
    rng = parts.rng
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    p = Vector(foot)
    points = [p.copy()]
    for k in range(int(height / .35)):
        p = p + Vector((0, 0, .35)) + across * rng.uniform(-.12, .12)
        points.append(p.copy())
    for a, b in zip(points, points[1:]):
        parts.cylinder('bark', a + f * .04, b + f * .04, .018, 5, uv='flat')
        count = max(2, int((b - a).length * density))
        for i in range(count):
            q = a.lerp(b, i / count) + f * rng.uniform(.04, .1) + across * rng.uniform(-spread, spread)
            parts.sphere(('leaf', 'leaf_dark', 'leaf_light', 'leaf')[rng.randrange(4)], q, rng.uniform(.06, .1), 1, (1, 1, .85))
            if rng.random() < bloom:
                parts.sphere(flowers[rng.randrange(len(flowers))], q + f * .05, .035, 1)


def laundry(parts, a, b, items, sag=.12):
    """A line between two points with pegged washing."""
    a, b = Vector(a), Vector(b)
    pts = []
    for k in range(11):
        t = k / 10
        p = a.lerp(b, t)
        p.z -= sag * 4 * t * (1 - t)
        pts.append(p)
    for p, q in zip(pts, pts[1:]):
        parts.cylinder('rope', p, q, .008, 4, uv='flat')
    direction = (b - a).normalized()
    n = len(items)
    for k, (mat, w, h) in enumerate(items):
        t = (k + .7) / (n + .4)
        p = a.lerp(b, t)
        p.z -= sag * 4 * t * (1 - t)
        rot = (0, 0, math.atan2(direction.y, direction.x))
        parts.box(mat, (p.x, p.y, p.z - h / 2), (w, .02, h), rot, .006, 'flat')
        parts.box('linen', (p.x, p.y, p.z - h + .02), (w * .98, .025, .03), rot, .004, 'flat')
        for s in (-1, 1):
            q = p + direction * s * w * .4
            parts.box('wood_end', (q.x, q.y, p.z), (.02, .03, .06), rot, .003, 'flat')


def log_store(parts, x0, x1, y_wall, depth, height, facing):
    """A small open log shelter against a wall: posts, a boarded pent roof and split logs stacked on a sleeper."""
    rng = parts.rng
    fy = facing
    yo = y_wall + fy * depth
    for x in (x0 + .05, x1 - .05):
        parts.beam('timber', (x, yo - fy * .05, 0), (x, yo - fy * .05, height), .09, .09, up=(0, 1, 0))
    parts.box('timber', ((x0 + x1) / 2, (y_wall + yo) / 2, height + .05), (x1 - x0 + .2, depth + .25, .06), (fy * math.radians(-12), 0, 0), .008, 'local')
    for k in range(int((x1 - x0) / .16)):
        x = x0 + .1 + k * .16
        parts.box('timber', (x, (y_wall + yo) / 2, height + .09), (.12, depth + .25, .02), (fy * math.radians(-12), 0, 0), .004, 'local')
    parts.box('timber', ((x0 + x1) / 2, (y_wall + yo) / 2, .05), (x1 - x0 - .1, depth - .1, .1), bevel=.01, uv='local')
    r = .075
    rows = int((height - .25) / (2 * r))
    for row in range(rows):
        n = int((x1 - x0 - .2) / (2 * r))
        for k in range(n):
            x = x0 + .1 + r + k * 2 * r + (r if row % 2 else 0) * .5 + rng.uniform(-.01, .01)
            if x > x1 - .1 - r:
                continue
            z = .1 + r + row * r * 1.75
            a = Vector((x, y_wall + fy * .08, z))
            b = Vector((x, yo - fy * .02, z))
            parts.cylinder('bark', a, b, r * rng.uniform(.82, 1.0), 7, uv='flat', caps=False)
            parts.cylinder('wood_end', b - Vector((0, fy * .005, 0)), b + Vector((0, fy * .012, 0)), r * .82, 7, uv='flat')


def basket(parts, at, radius=.22, height=.24, linen=True):
    x, y, z = at
    parts.cylinder('wicker', (x, y, z), (x, y, z + height), radius * .85, 12, radius, uv='flat')
    parts.cylinder('wicker_dark', (x, y, z + height - .02), (x, y, z + height + .02), radius * 1.05, 12, uv='flat')
    for k in range(4):
        zz = z + height * (k + .5) / 4
        parts.cylinder('wicker_dark', (x, y, zz - .005), (x, y, zz + .005), radius * (.88 + .03 * k), 12, uv='flat')
    if linen:
        for k in range(3):
            parts.sphere(('linen', 'cloth_blue', 'linen')[k], (x + (k - 1) * .08, y, z + height + .03), .1, 1, (1, .8, .45))


def crate(parts, at, size=(.5, .4, .32), rot=0.0):
    x, y, z = at
    w, d, h = size
    parts.box('timber', (x, y, z + h / 2), (w, d, h), (0, 0, rot), .012, 'local')
    for k in (-1, 1):
        parts.box('timber', (x, y, z + h / 2 + k * h * .3), (w + .02, d + .02, .05), (0, 0, rot), .006, 'local')


# --- saving --------------------------------------------------------------------------------------------------------
def save(asset, record, palette, extras):
    """Writes the editable master and its provenance. Refuses to overwrite an existing one."""
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    scene['rootward_source'] = 'Editable authority after the v0.72 background-house concept. Do not rerun the authoring record.'
    bpy.ops.file.pack_all()
    folder = ROOT / 'art/source/world' / asset / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    note = {'asset': asset, 'date': '2026-10-29', 'reference': extras['reference'],
            'authoring_record': record if '/' in record else 'art/source/world/seaside-houses/v1/' + record,
            'authoring_record_sha256': hashlib.sha256((ROOT / record if '/' in record else HERE / record).read_bytes()).hexdigest(),
            'kit': 'art/source/world/seaside-houses/v1/house_kit.py',
            'kit_sha256': hashlib.sha256((HERE / 'house_kit.py').read_bytes()).hexdigest(),
            'texture_library': 'art/source/world/seaside-background-houses/v1/textures/library.json',
            'authored_palette': palette,
            'note': 'New bespoke authored asset; model.blend is now authority. Build through scripts/world-art.sh.'}
    note.update({k: v for k, v in extras.items() if k != 'reference'})
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', asset, flush=True)


def draft(asset, out_dir):
    """Saves an unadopted draft elsewhere (for review before adoption); never touches art/source."""
    path = Path(out_dir) / asset / 'model.blend'
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    print('DRAFT', asset, path, flush=True)


def selected(all_assets):
    """(asset ids, draft directory or None) from the arguments after `--`: `--draft DIR` writes review drafts;
    otherwise each chosen master is refused if it already exists."""
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    out = None
    if '--draft' in argv:
        i = argv.index('--draft')
        out = argv[i + 1]
        argv = argv[:i] + argv[i + 2:]
    chosen = [a for a in all_assets if not argv or a in argv]
    if out is None:
        for asset in chosen:
            if (ROOT / 'art/source/world' / asset / 'v1/model.blend').exists():
                raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + asset)
    return chosen, out
