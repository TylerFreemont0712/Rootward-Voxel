"""Guarded one-time authoring of the Rootwell, the town's central power beacon, after the approved v0.72 paintings
docs/concept/v0.72/art/rootwell/front-threequarter.png and rear-threequarter.png.

    blender --background --factory-startup --python art/source/world/rootwell/v1/author_rootwell.py
    ... -- --draft .cache/rootwell/drafts         (a review draft outside art/source)

Refuses an existing master. After authoring, art/source/world/rootwell-beacon/v1/model.blend is the editable
authority; export only with scripts/world-art.sh build rootwell-beacon.

Built with the seaside house kit (painted limestone blocks, tiles, timber, painted boards, plain colours) plus its own
verdigris, brass, amber glass and root materials. Ground pivot at the centre; the octagon has a face toward each
compass point and diagonal, and the public face (the pressure gauge) looks south-east, toward the game camera:
    face k looks along 45k degrees (0 east, 2 north, 4 west, 6 south, 7 south-east)
    SE (7) gauge · S (6) notice board and bench · E (0) maintenance door · NW (3) service panel and risers
Parts that story may move later stay separate with their pivots: gauge_needle, maintenance_door and valve_wheel_*;
the living root (root_glow), its light (root_heart) and the bell glass are their own objects too.
"""
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import house_kit as kit  # noqa: E402

ASSET = 'rootwell-beacon'
REFERENCES = ['docs/concept/v0.72/art/rootwell/front-threequarter.png', 'docs/concept/v0.72/art/rootwell/rear-threequarter.png']
PALETTE = {'stone': 'seaside_stone_limestone', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
           'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}
COPPER = ROOT / 'art/source/world/textures/v2-detail/native/copper_patina.png'
VERDIGRIS = HERE / 'verdigris.png'
LIGHT = HERE / 'light-gradient.png'
TAN = math.tan(math.pi / 8)

# Heights (metres). Steps and terrace, the drum, its cornice, the chamber, the crown.
STEP1, STEP2, TERRACE = .16, .32, .48
A_STEP1, A_STEP2, A_TERRACE, A_DRUM = 3.75, 3.4, 3.05, 2.0
DRUM_TOP, CORNICE, TOP = 2.55, 2.66, 2.8
CHAMBER, GLASS_TOP, ENTABLATURE, DOME = 3.32, 6.55, 6.62, 6.95
COLUMN_R = 1.7


# --- materials -----------------------------------------------------------------------------------------------------
def _srgb(hex_colour):
    return np.array([int(hex_colour[i:i + 2], 16) / 255 for i in (0, 2, 4)])


def verdigris():
    """The crown's weathered copper: the library's copper-patina painting recoloured to the concept's teal, its mottle
    kept. Written once per authoring run (deterministic) as verdigris.png at 512 pixels."""
    image = bpy.data.images.load(str(COPPER))
    image.scale(512, 512)
    px = np.array(image.pixels[:], dtype=np.float32).reshape(512, 512, 4)
    r, g, b = px[..., 0], px[..., 1], px[..., 2]
    patina = np.clip((g - r) * 1.6 + .5, 0, 1)
    lum = r * .3 + g * .59 + b * .11
    t = np.clip(.3 + patina * .4 + (lum - lum.mean()) * .9, 0, 1)
    dark, light = _srgb('2f6762'), _srgb('62a191')
    out = np.ones_like(px)
    out[..., :3] = dark * (1 - t)[..., None] + light * t[..., None]
    result = bpy.data.images.new('verdigris', 512, 512, alpha=False)
    result.pixels = out.ravel().tolist()
    result.filepath_raw = str(VERDIGRIS)
    result.file_format = 'PNG'
    result.save()
    bpy.data.images.remove(image)
    return VERDIGRIS


def light_gradient():
    """The chamber's light from bottom to top: amber at the throat, nearly white a third of the way up behind the trunk,
    warm gold under the crown. 8 x 128, written once per authoring run."""
    stops = [(0, 'ffae45'), (.18, 'ffd986'), (.38, 'fff6d6'), (.6, 'ffe7a6'), (.85, 'ffc663'), (1, 'f59f3d')]
    pixels = []
    for row in range(128):
        v = row / 127
        for (a, ca), (b, cb) in zip(stops, stops[1:]):
            if a <= v <= b:
                t = (v - a) / (b - a)
                colour = _srgb(ca) * (1 - t) + _srgb(cb) * t
                break
        pixels.extend(list(colour) + [1.0] for _ in range(8))
    image = bpy.data.images.new('light-gradient', 8, 128, alpha=False)
    image.pixels = [c for px in pixels for c in px]
    image.filepath_raw = str(LIGHT)
    image.file_format = 'PNG'
    image.save()
    return LIGHT


def materials():
    kit.material('rootwell_verdigris', 'ffffff', verdigris(), .62, metallic=.25)
    kit.material('rootwell_brass', 'c99d55', roughness=.36, metallic=.55)
    kit.material('rootwell_enamel', 'f3ead4', roughness=.5)
    kit.material('rootwell_ink', '2e2621', roughness=.6)
    kit.material('rootwell_red', 'c23a2e', roughness=.5)
    kit.material('rootwell_root', 'b06a2c', roughness=.72)
    # Single-sided on purpose: from outside only the shell's far half faces the camera.
    kit.material('rootwell_light', 'ffffff', light_gradient(), .6, emission=1.6).use_backface_culling = True
    kit.material('lamp_glass', 'f2a23c', roughness=.85, emission=.4)
    glass = kit.material('rootwell_bell_glass', 'ffb447', roughness=.08, emission=.95)
    bsdf = next(n for n in glass.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Alpha'].default_value = .3
    glass.diffuse_color = (*glass.diffuse_color[:3], .3)
    if hasattr(glass, 'surface_render_method'):
        glass.surface_render_method = 'BLENDED'
    glass.use_backface_culling = False


# --- octagon frames ------------------------------------------------------------------------------------------------
def vertex(k, a):
    """The corner between face k and face k+1 of an octagon with apothem a."""
    th = math.radians(45 * k + 22.5)
    r = a / math.cos(math.pi / 8)
    return Vector((math.cos(th) * r, math.sin(th) * r, 0))


def octagon(a):
    return [tuple(vertex(k, a))[:2] for k in range(-1, 7)]


def face_turn(k):
    """Degrees that turn a face-local frame (x along the face to the viewer's right, y inward, z up; the wall's outer
    face at y = -apothem) onto face k."""
    return 45 * k + 90


# --- primitives ----------------------------------------------------------------------------------------------------
def block(p, polygon, z0, z1, bevel=.02, mat='stone', uv=('blocks', 0)):
    """One dressed stone: a convex plan polygon (counter-clockwise) extruded and softly bevelled, a painted block on
    each face."""
    bm = bmesh.new()
    lower = [bm.verts.new((x, y, z0)) for x, y in polygon]
    upper = [bm.verts.new((x, y, z1)) for x, y in polygon]
    bm.faces.new(list(reversed(lower)))
    bm.faces.new(upper)
    for i in range(len(polygon)):
        j = (i + 1) % len(polygon)
        bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
    bm.normal_update()
    if bevel:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=1, affect='EDGES', profile=.5)
    p._take(bm, Matrix.Identity(4), mat, uv)


def ring(p, a_out, depth, z0, z1, mean=.68, openings=(), joint=.014, bevel=.02, stagger=0.0):
    """A course of mitred blocks round the octagon from apothem a_out inward by `depth`, z0..z1. `openings` are
    (face, c0, c1, bottom, top) along the face from its middle; blocks butt against them and leave them open."""
    rng = p.rng
    a_in = a_out - depth
    h_out, h_in = a_out * TAN, a_in * TAN
    for k in range(8):
        holes = [(c0, c1) for f, c0, c1, lo, hi in openings if f % 8 == k and lo < z1 - 1e-4 and hi > z0 + 1e-4]
        cuts = [-h_out]
        c = -h_out + mean * (rng.uniform(.45, .95) if stagger == 0 else stagger)
        while c < h_out - .3 * mean:
            cuts.append(c)
            c += mean * rng.uniform(.75, 1.25)
        cuts.append(h_out)
        for c0, c1 in holes:
            cuts = [x for x in cuts if not c0 - .12 < x < c1 + .12] + [c0, c1]
        cuts = sorted(set(round(x, 5) for x in cuts))
        with p.turned(face_turn(k)):
            for u0, u1 in zip(cuts, cuts[1:]):
                if any(c0 - 1e-4 <= u0 and u1 <= c1 + 1e-4 for c0, c1 in holes):
                    continue
                f0 = (u0 + h_out) / (2 * h_out)
                f1 = (u1 + h_out) / (2 * h_out)
                g0, g1 = joint / (2 * h_out), joint / (2 * h_out)
                f0, f1 = f0 + (g0 if u0 > -h_out + 1e-4 else 0), f1 - (g1 if u1 < h_out - 1e-4 else 0)
                outer = [(-h_out + 2 * h_out * f, -a_out) for f in (f0, f1)]
                inner = [(-h_in + 2 * h_in * f, -a_in) for f in (f1, f0)]
                block(p, outer + inner, z0, z1 - joint * .6, bevel)


def lathe(p, mat, profile, segs=48, smooth=True, u_tiles=1.0, v_rep=1.0, start=0.0, centre=(0, 0)):
    """A surface of revolution through (radius, z) points, bottom to top, its faces outward. UVs run once round
    (u_tiles times) and along the profile's length."""
    verts, faces, uvs = [], [], []
    run = [0.0]
    for (r0, z0), (r1, z1) in zip(profile, profile[1:]):
        run.append(run[-1] + math.hypot(r1 - r0, z1 - z0))
    for r, z in profile:
        for j in range(segs):
            a = start + math.tau * j / segs
            verts.append((centre[0] + r * math.cos(a), centre[1] + r * math.sin(a), z))
    for i in range(len(profile) - 1):
        for j in range(segs):
            jn = (j + 1) % segs
            faces.append((i * segs + j, i * segs + jn, (i + 1) * segs + jn, (i + 1) * segs + j))
            u0, u1 = j / segs * u_tiles, (j + 1) / segs * u_tiles
            v0, v1 = run[i] / v_rep, run[i + 1] / v_rep
            uvs.append([(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    p.add(mat, verts, faces, uvs, smooth)


def annulus(p, mat, r_in, r_out, z0, z1, segs=48, smooth=False, u_tiles=1.0):
    """A closed flat ring, like a washer, from z0 to z1."""
    for profile in ([(r_in, z1), (r_in, z0)], [(r_in, z0), (r_out, z0)], [(r_out, z0), (r_out, z1)], [(r_out, z1), (r_in, z1)]):
        lathe(p, mat, profile, segs, smooth, u_tiles)


def sweep(p, mat, points, radii, sides=8, caps=(True, True), smooth=True, v_rep=.6):
    """A tube along a polyline, its radius following `radii`, with parallel-transported rings (no twisting)."""
    pts = [Vector(q) for q in points]
    if isinstance(radii, (int, float)):
        radii = [radii] * len(pts)
    tangents = []
    for i in range(len(pts)):
        a, b = pts[max(i - 1, 0)], pts[min(i + 1, len(pts) - 1)]
        tangents.append((b - a).normalized())
    n = tangents[0].orthogonal().normalized()
    rings, run = [], [0.0]
    for i, (q, t, r) in enumerate(zip(pts, tangents, radii)):
        n = (n - t * n.dot(t)).normalized()
        b = t.cross(n)
        rings.append([q + (n * math.cos(math.tau * s / sides) + b * math.sin(math.tau * s / sides)) * r for s in range(sides)])
        if i:
            run.append(run[-1] + (pts[i] - pts[i - 1]).length)
    verts = [v for ring_ in rings for v in ring_]
    faces, uvs = [], []
    for i in range(len(rings) - 1):
        for s in range(sides):
            sn = (s + 1) % sides
            faces.append((i * sides + s, i * sides + sn, (i + 1) * sides + sn, (i + 1) * sides + s))
            uvs.append([(s / sides, run[i] / v_rep), ((s + 1) / sides, run[i] / v_rep), ((s + 1) / sides, run[i + 1] / v_rep), (s / sides, run[i + 1] / v_rep)])
    for end, keep in ((0, caps[0]), (len(rings) - 1, caps[1])):
        if keep:
            centre = len(verts)
            verts.append(pts[end])
            for s in range(sides):
                sn = (s + 1) % sides
                face = (centre, end * sides + sn, end * sides + s) if end == 0 else (centre, end * sides + s, end * sides + sn)
                faces.append(face)
                uvs.append([(.5, .5)] * 3)
    p.add(mat, verts, faces, uvs, smooth)


def torus(p, mat, centre, radius, minor, axis=(0, 0, 1), segs=40, sides=8):
    """A ring of tube round `axis` through `centre`."""
    axis = Vector(axis).normalized()
    u = axis.orthogonal().normalized()
    w = axis.cross(u)
    c = Vector(centre)
    pts = [c + (u * math.cos(math.tau * i / segs) + w * math.sin(math.tau * i / segs)) * radius for i in range(segs + 1)]
    sweep(p, mat, pts, minor, sides, (False, False))


def wheel(p, centre, axis, radius, spokes=5):
    """A handwheel: rim, spokes and hub, all brass."""
    axis = Vector(axis).normalized()
    u = axis.orthogonal().normalized()
    w = axis.cross(u)
    c = Vector(centre)
    torus(p, 'rootwell_brass', c, radius, radius * .13, axis, 28, 8)
    for i in range(spokes):
        a = math.tau * i / spokes
        p.cylinder('rootwell_brass', c, c + (u * math.cos(a) + w * math.sin(a)) * radius, radius * .07, 6, uv='flat')
    p.cylinder('rootwell_brass', c - axis * radius * .12, c + axis * radius * .18, radius * .2, 10, uv='flat')
    for i in range(spokes):
        a = math.tau * (i + .5) / spokes
        p.sphere('rootwell_brass', c + (u * math.cos(a) + w * math.sin(a)) * radius, radius * .16, 0)


def rivets(p, points, radius=.022):
    for q in points:
        p.sphere('rootwell_brass', q, radius, 0, (1, 1, 1))


def text(p, mat, words, matrix, size, align='CENTER'):
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
    p.add(mat, verts, faces, [[(0, 0)] * len(f) for f in faces])
    bpy.data.objects.remove(obj)
    bpy.data.curves.remove(curve)
    bpy.data.meshes.remove(mesh)


def wall_text(x, y, z):
    """Lettering standing on a face-local wall: reads along +x, up +z, facing -y."""
    return Matrix.Translation((x, y, z)) @ Matrix(((1, 0, 0, 0), (0, 0, -1, 0), (0, 1, 0, 0), (0, 0, 0, 1)))


# --- planting ------------------------------------------------------------------------------------------------------
BLOOM = ('flower_white', 'flower_white', 'flower_orange', 'flower_red')


def bloom(p, at, radius, count=10, colours=BLOOM, height=.12):
    """A clump of leaves starred with daisies and orange flowers."""
    rng = p.rng
    x, y, z = at
    for i in range(count):
        a, d = rng.uniform(0, math.tau), radius * math.sqrt(rng.random())
        p.sphere(('leaf', 'leaf_dark', 'leaf_light')[i % 3], (x + math.cos(a) * d, y + math.sin(a) * d, z + rng.uniform(0, height)), rng.uniform(.07, .11), 1, (1, 1, .8))
    for i in range(count):
        a, d = rng.uniform(0, math.tau), radius * math.sqrt(rng.random())
        colour = colours[rng.randrange(len(colours))]
        q = (x + math.cos(a) * d, y + math.sin(a) * d, z + height + rng.uniform(.02, .07))
        p.sphere(colour, q, .045, 1, (1, 1, .6))
        if colour == 'flower_white':
            p.sphere('flower_yellow', (q[0], q[1], q[2] + .022), .018, 0)


def trail(p, top, facing, length, spread=.22, bloom_chance=.3):
    """Ivy hanging from a ledge down a wall that faces `facing`, starred with a few flowers."""
    rng = p.rng
    f = Vector((facing[0], facing[1], 0)).normalized()
    across = Vector((-f.y, f.x, 0))
    for strand in range(3):
        q = Vector(top) + across * rng.uniform(-spread, spread) + f * .06
        for i in range(int(length / .09)):
            q = q + Vector((0, 0, -.09)) + across * rng.uniform(-.04, .04)
            depth = 1 - i * .09 / length
            if rng.random() < .85:
                p.sphere(('leaf', 'leaf_dark', 'leaf_light', 'leaf')[rng.randrange(4)], q + across * rng.uniform(-.05, .05) + f * rng.uniform(0, .04), rng.uniform(.05, .085) * (.6 + .4 * depth), 1, (1, 1, .8))
            if rng.random() < bloom_chance * depth:
                p.sphere(('flower_white', 'flower_orange')[rng.randrange(2)], q + f * .06, .035, 0)
        length *= rng.uniform(.6, .9)


def conifer(p, at, height=1.2, radius=.32):
    """A clipped evergreen cone."""
    x, y, z = at
    layers = max(5, int(height / .16))
    for i in range(layers):
        t = i / (layers - 1)
        r = radius * (1 - t * .85)
        zz = z + .1 + t * height
        for j in range(5):
            a = j * math.tau / 5 + i
            p.sphere('cypress' if (i + j) % 3 else 'cypress_light', (x + math.cos(a) * r * .5, y + math.sin(a) * r * .5, zz), r * .62 + .03, 1)


def stone_planter(p, at, size=(.75, .6), height=.5, turn=0.0, tree=True):
    x, y, z = at
    w, d = size
    rot = Matrix.Rotation(turn, 3, 'Z')
    corners = [rot @ Vector((sx * w / 2, sy * d / 2, 0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    block(p, [(x + c.x, y + c.y) for c in corners], z, z + height, .025)
    lip = [rot @ Vector((sx * (w / 2 + .04), sy * (d / 2 + .04), 0)) for sx, sy in ((-1, -1), (1, -1), (1, 1), (-1, 1))]
    block(p, [(x + c.x, y + c.y) for c in lip], z + height - .07, z + height, .015)
    p.box('soil', (x, y, z + height + .005), (w - .1, d - .1, .02), (0, 0, turn), 0, 'flat')
    bloom(p, (x, y, z + height), min(w, d) * .45, 14)
    if tree:
        conifer(p, (x, y, z + height), .75, .22)


def wood_planter(p, at, size=(.62, .42), height=.34, turn=0.0, tree=0.0):
    x, y, z = at
    w, d = size
    p.box('timber', (x, y, z + height / 2), (w, d, height), (0, 0, turn), .015, 'local')
    rot = Matrix.Rotation(turn, 3, 'Z')
    for k in (-1, 1):
        q = rot @ Vector((0, 0, 0))
        p.box('timber', (x, y, z + height / 2 + k * height * .32), (w + .025, d + .025, .045), (0, 0, turn), .006, 'local')
    for sx in (-1, 1):
        q = rot @ Vector((sx * (w / 2 - .02), 0, 0))
        p.box('timber', (x + q.x, y + q.y, z + height / 2), (.05, d + .03, height + .02), (0, 0, turn), .006, 'local')
    p.box('soil', (x, y, z + height + .004), (w - .06, d - .06, .02), (0, 0, turn), 0, 'flat')
    bloom(p, (x, y, z + height), min(w, d) * .5, 12)
    if tree:
        conifer(p, (x, y, z + height), tree, .16 + tree * .11)


# --- the stepped base, terrace and drum ------------------------------------------------------------------------------
GAUGE = (7, -.78, .78, .8, 2.26)
DOOR = (0, -.47, .47, TERRACE, 2.12)
VENT = (3, -.52, .52, 1.38, 1.97)


def base(p):
    rng = p.rng
    p.prism('stone', octagon(A_STEP2), 0, STEP1 - .01)
    p.prism('stone', octagon(A_TERRACE), 0, STEP2 - .01)
    p.prism('stone', octagon(1.74), TERRACE - .02, DRUM_TOP)
    ring(p, A_STEP1, A_STEP1 - A_STEP2 + .01, 0, STEP1, .72)
    ring(p, A_STEP2, A_STEP2 - A_TERRACE + .01, STEP1, STEP2, .72)
    ring(p, A_TERRACE, .53, STEP2, TERRACE, .64)
    ring(p, A_TERRACE - .52, .55, STEP2, TERRACE, .58)
    # The drum: a proud plinth course, six courses of dressed limestone, a moulded lip and the top paving.
    ring(p, A_DRUM + .07, .34, TERRACE, .8, .7, [DOOR])
    course = (DRUM_TOP - .8) / 6
    for i in range(6):
        z0 = .8 + i * course
        ring(p, A_DRUM, .28, z0, z0 + course, .62, [GAUGE, DOOR, VENT])
    ring(p, A_DRUM + .12, .44, DRUM_TOP, CORNICE, .9)
    ring(p, A_DRUM + .22, 1.05, CORNICE, TOP, .75)
    p.prism('stone', octagon(A_DRUM + .22 - 1.0), CORNICE, TOP - .01)
    # Grass in a few joints on the steps and terrace.
    for _ in range(12):
        k = rng.randrange(8)
        a, z = rng.choice(((A_STEP2 + .01, STEP1), (A_TERRACE + .01, STEP2)))
        c = rng.choice((-1, 1)) * rng.uniform(a * TAN * .75, a * TAN * .95)
        with p.turned(face_turn(k)):
            for j in range(4):
                p.sphere(('leaf_light', 'leaf')[j % 2], (c + rng.uniform(-.05, .05), -a - rng.uniform(.0, .04), z + .005), .025, 0, (1.3, 1.3, .7))


# --- the public face: the pressure gauge ---------------------------------------------------------------------------
NEEDLE_VALUE = 1.3      # "just past the first mark"
SCRATCH_VALUE = 6.4     # "a line in the brass where it used to rest"
DIAL_Z, DIAL_R = 1.48, .5


def dial_angle(value):
    """0 sits lower left and 10 lower right, sweeping clockwise through the top (270 degrees)."""
    return math.radians(225 - 27 * value)


def gauge(p):
    a = A_DRUM
    face = -a
    with p.turned(face_turn(7)):
        # The teal riveted panel in its recess, framed in brass.
        p.box('rootwell_verdigris', (0, face + .12, 1.53), (1.52, .04, 1.46), bevel=.008, uv='local')
        for x0, x1, z0, z1 in ((-.78, .78, .8, .86), (-.78, .78, 2.2, 2.26), (-.78, -.72, .8, 2.26), (.72, .78, .8, 2.26)):
            p.box('rootwell_brass', ((x0 + x1) / 2, face + .08, (z0 + z1) / 2), (x1 - x0, .05, z1 - z0), bevel=.006, uv='flat')
        rivets(p, [(x, face + .095, z) for x in (-.66, -.33, .33, .66) for z in (.92, 2.14)] +
               [(x, face + .095, z) for x in (-.66, .66) for z in (1.22, 1.53, 1.84)])
        # Bezel, enamel face, ticks, numerals, the red low band, the word PRESSURE.
        torus(p, 'rootwell_brass', (0, face + .04, DIAL_Z), DIAL_R + .03, .055, (0, 1, 0), 48, 10)
        p.cylinder('rootwell_brass', (0, face + .1, DIAL_Z), (0, face + .02, DIAL_Z), DIAL_R + .04, 48, uv='flat', smooth=False)
        p.cylinder('rootwell_enamel', (0, face + .025, DIAL_Z), (0, face + .012, DIAL_Z), DIAL_R, 48, uv='flat', smooth=False)
        dial = face + .009
        for i in range(21):
            value = i / 2
            ang = dial_angle(value)
            major = i % 2 == 0
            r0, r1 = DIAL_R - (.1 if major else .065), DIAL_R - .025
            mid = (r0 + r1) / 2
            p.box('rootwell_ink', (math.cos(ang) * mid, dial, DIAL_Z + math.sin(ang) * mid), (r1 - r0, .004, .022 if major else .012),
                  (0, -ang, 0), 0, 'flat')
        for value in (0, 2, 4, 6, 8, 10):
            ang = dial_angle(value)
            r = DIAL_R - .19
            text(p, 'rootwell_ink', str(value), wall_text(math.cos(ang) * r, dial - .001, DIAL_Z + math.sin(ang) * r), .1)
        band = []
        for i in range(13):
            ang = dial_angle(i / 12)
            band.append(ang)
        verts, faces = [], []
        for i, ang in enumerate(band):
            for r in (DIAL_R - .1, DIAL_R - .04):
                verts.append((math.cos(ang) * r, dial - .0005, DIAL_Z + math.sin(ang) * r))
        for i in range(len(band) - 1):
            faces.append((2 * i, 2 * i + 2, 2 * i + 3, 2 * i + 1))
        p.add('rootwell_red', verts, faces, [[(0, 0)] * 4 for _ in faces])
        text(p, 'rootwell_ink', 'PRESSURE', wall_text(0, dial - .001, DIAL_Z - .2), .055)
        # The scratch on the bezel where the needle used to rest.
        ang = dial_angle(SCRATCH_VALUE)
        for dr, lift in ((0, 0), (.012, .006)):
            r = DIAL_R + .03 + dr
            p.box('sash', (math.cos(ang) * r, face - .02, DIAL_Z + math.sin(ang) * r + lift), (.09, .006, .008), (0, -ang, 0), 0, 'flat')
        # The plaque above, ROOTWELL.
        p.box('rootwell_brass', (0, face + .07, 2.14), (.66, .04, .12), bevel=.012, uv='flat')
        text(p, 'rootwell_ink', 'ROOTWELL', wall_text(0, face + .048, 2.138), .08)
        # Under the dial: a stem into a manifold bar, and three pipes that run down the steps to the ground.
        p.cylinder('rootwell_brass', (0, face + .04, DIAL_Z - DIAL_R - .03), (0, face + .04, .92), .05, 10, uv='flat')
        p.cylinder('rootwell_brass', (-.34, face + .04, .92), (.34, face + .04, .92), .07, 12, uv='flat')
        for x in (-.34, .34):
            p.cylinder('rootwell_brass', (x - .04, face + .04, .92), (x + .04, face + .04, .92), .1, 12, uv='flat')
        for x, r, mat in ((-.17, .05, 'iron'), (0, .075, 'rootwell_brass'), (.17, .05, 'iron')):
            path = [(x, face + .04, .92), (x, face - .08, .88), (x, face - .15, .76), (x, face - .15, TERRACE + r + .08), (x, face - .26, TERRACE + r),
                    (x, -A_TERRACE - .04, TERRACE + r), (x, -A_TERRACE - .1, STEP2 + r + .02), (x, -A_TERRACE - .18, STEP2 + r),
                    (x, -A_STEP2 - .04, STEP2 + r), (x, -A_STEP2 - .1, STEP1 + r + .02), (x, -A_STEP2 - .18, STEP1 + r),
                    (x, -A_STEP1 - .04, STEP1 + r), (x, -A_STEP1 - .14, r + .03), (x, -A_STEP1 - .26, r)]
            sweep(p, mat, path, r, 10, (False, True))
            for yy, zz in ((-A_TERRACE + .3, TERRACE + r), (-A_STEP2 + .15, STEP2 + r), (-A_STEP1 + .15, STEP1 + r)):
                p.cylinder('rootwell_brass', (x, yy - .03, zz), (x, yy + .03, zz), r + .02, 10, uv='flat')
        for y, z in ((-A_TERRACE + .3, TERRACE), (-A_STEP2 + .15, STEP2), (-A_STEP1 + .15, STEP1)):
            p.box('rootwell_brass', (0, y, z + .015), (.5, .07, .03), bevel=.005, uv='flat')
        # The needle on its own pivot (gauge_needle): built pointing at NEEDLE_VALUE in the dial's own frame.
        with p.into('gauge_needle'):
            ang = dial_angle(NEEDLE_VALUE)
            d = Vector((math.cos(ang), 0, math.sin(ang)))
            side = Vector((-d.z, 0, d.x))
            centre = Vector((0, face - .005, DIAL_Z))
            tip = centre + d * (DIAL_R - .05)
            tail = centre - d * .1
            outline = (tail + side * .02, centre + side * .022, tip, centre - side * .022, tail - side * .02)
            p.add('rootwell_ink', [tuple(v) for v in outline], [(4, 3, 2, 1, 0)], [[(0, 0)] * 5])
            p.add('rootwell_ink', [tuple(v + Vector((0, .002, 0))) for v in outline], [(0, 1, 2, 3, 4)], [[(0, 0)] * 5])
            p.cylinder('rootwell_brass', centre + Vector((0, .01, 0)), centre - Vector((0, .03, 0)), .04, 14, uv='flat')
            p.sphere('rootwell_brass', centre - Vector((0, .03, 0)), .03, 1)


# --- notice board and bench (south), maintenance door (east), service face (north-west) -----------------------------
def notices(p):
    face = -A_DRUM
    with p.turned(face_turn(6)):
        x0, x1, z0, z1 = -.66, .66, 1.02, 1.9
        p.box('timber', (0, face - .04, (z0 + z1) / 2), (x1 - x0, .05, z1 - z0), bevel=.01, uv='local')
        for (a, b), horizontal in ((((x0, z0), (x1, z0)), True), (((x0, z1), (x1, z1)), True), (((x0, z0), (x0, z1)), False), (((x1, z0), (x1, z1)), False)):
            p.box('timber', ((a[0] + b[0]) / 2, face - .085, (a[1] + b[1]) / 2), ((b[0] - a[0]) + .08 if horizontal else .08, .06, .08 if horizontal else (b[1] - a[1]) + .08), bevel=.01, uv='local')
        p.box('timber', (0, face - .12, z0 - .06), (x1 - x0 + .2, .12, .06), bevel=.01, uv='local')
        sheets = ((-.42, 1.47, .34, .6, -.03), (0, 1.5, .34, .56, .02), (.42, 1.44, .34, .62, -.015))
        for x, z, w, h, tilt in sheets:
            p.box('rootwell_enamel', (x, face - .07, z), (w, .006, h), (0, tilt, 0), 0, 'flat')
            p.sphere('rootwell_red', (x, face - .078, z + h / 2 - .04), .018, 0)
        y = face - .0745
        # A tide table, a meeting on Thursday, and a lost tortoise called Admiral.
        text(p, 'rootwell_ink', 'TIDES', wall_text(-.42, y, 1.71), .055)
        for i in range(6):
            p.box('rootwell_ink', (-.46, y, 1.62 - i * .065), (.12, .003, .012), (0, -.03, 0), 0, 'flat')
            p.box('rootwell_ink', (-.33, y, 1.62 - i * .066), (.08, .003, .012), (0, -.03, 0), 0, 'flat')
        text(p, 'rootwell_ink', 'GUILD', wall_text(0, y, 1.71), .055)
        text(p, 'rootwell_ink', 'MEETING', wall_text(0, y, 1.64), .045)
        text(p, 'rootwell_red', 'THURSDAY', wall_text(0, y, 1.56), .04)
        for i in range(4):
            p.box('rootwell_ink', (0, y, 1.46 - i * .055), (.22 - (i % 2) * .06, .003, .01), (0, .02, 0), 0, 'flat')
        text(p, 'rootwell_ink', 'LOST', wall_text(.42, y, 1.69), .06)
        text(p, 'rootwell_ink', 'ADMIRAL', wall_text(.42, y, 1.23), .04)
        dome = [(.42 + math.cos(a) * .1, y, 1.40 + math.sin(a) * .07) for a in [math.pi * i / 10 for i in range(11)]]
        p.add('leaf_dark', dome, [tuple(range(11))], [[(0, 0)] * 11])
        for lx in (.35, .49):
            p.box('rootwell_ink', (lx, y + .001, 1.385), (.022, .002, .04), (0, 0, 0), 0, 'flat')
        p.sphere('leaf_dark', (.545, y + .004, 1.415), .022, 0, (1, .2, 1))
        # The hood: pan tiles on two brackets.
        kit.canopy(p, (0, face - .07), 1.6, .45, 2.2, (0, -1), 30)
        # The bench, its brass ends scrolled.
        bench(p, (0, face - .62, TERRACE), 1.3)


def bench(p, at, length):
    x, y, z = at
    for k in range(3):
        p.box('timber', (x, y - .16 + k * .13, z + .42), (length, .11, .04), bevel=.008, uv='local')
    for k in range(2):
        p.box('timber', (x, y + .2, z + .58 + k * .14), (length, .035, .1), (math.radians(-12), 0, 0), .008, 'local')
    for side in (-1, 1):
        sx = x + side * (length / 2 - .06)
        leg = [(sx, y - .24, z), (sx, y - .2, z + .2), (sx, y - .22, z + .4), (sx, y - .25, z + .62), (sx, y - .17, z + .66),
               (sx, y - .05, z + .6), (sx, y + .1, z + .42)]
        sweep(p, 'rootwell_brass', leg, .022, 8, (True, True))
        back = [(sx, y + .26, z), (sx, y + .22, z + .22), (sx, y + .2, z + .42), (sx, y + .24, z + .62), (sx, y + .27, z + .82), (sx, y + .23, z + .88)]
        sweep(p, 'rootwell_brass', back, .022, 8, (True, True))
        p.sphere('rootwell_brass', (sx, y - .19, z + .66), .035, 1)


def door(p):
    face = -A_DRUM
    with p.turned(face_turn(0)):
        w, top = .86, 2.08
        # Timber lining, a stone lintel, a threshold and the tiled hood.
        for x in (-w / 2 - .04, w / 2 + .04):
            p.box('timber', (x, face + .06, (TERRACE + top) / 2), (.08, .18, top - TERRACE), bevel=.01, uv='local')
        p.box('timber', (0, face + .06, top), (w + .16, .18, .08), bevel=.01, uv='local')
        block(p, [(-w / 2 - .22, face - .03), (w / 2 + .22, face - .03), (w / 2 + .22, face + .28), (-w / 2 - .22, face + .28)], top + .04, top + .24, .02)
        block(p, [(-w / 2 - .05, face - .14), (w / 2 + .05, face - .14), (w / 2 + .05, face + .1), (-w / 2 - .05, face + .1)], TERRACE - .02, TERRACE + .05, .015)
        kit.canopy(p, (0, face - .03), w + .7, .5, top + .2, (0, -1), 24)
        # Chalked on the step: BACK AT 4.
        text(p, 'sash', 'BACK AT 4', Matrix.Translation((0, face - .5, TERRACE + .004)), .12)
        # The door on its hinge line (maintenance_door), painted boards, brass straps, a ring and a polished keyhole.
        with p.into('maintenance_door'):
            boards = 5
            bw = w / boards
            y = face + .1
            for i in range(boards):
                p.box('shutter', (-w / 2 + bw * (i + .5), y, (TERRACE + .02 + top - .04) / 2), (bw - .008, .05, top - .04 - TERRACE - .02), bevel=.006, uv='local')
            for z in (TERRACE + .3, top - .32):
                p.box('rootwell_brass', (-w * .1, y - .035, z), (w * .82, .015, .07), bevel=.004, uv='flat')
                p.sphere('rootwell_brass', (w * .31, y - .04, z), .035, 1, (1, .5, 1))
                for i in range(4):
                    p.sphere('rootwell_brass', (-w / 2 + .08 + i * w * .22, y - .045, z), .014, 0)
                p.cylinder('rootwell_brass', (-w / 2 - .02, y - .03, z - .07), (-w / 2 - .02, y - .03, z + .07), .025, 8, uv='flat')
            p.box('rootwell_brass', (w * .3, y - .03, 1.22), (.08, .012, .2), bevel=.004, uv='flat')
            p.sphere('rootwell_ink', (w * .3, y - .038, 1.19), .012, 0)
            torus(p, 'rootwell_brass', (w * .3, y - .06, 1.32), .045, .009, (0, 1, 0), 16, 6)


def service(p):
    face = -A_DRUM
    with p.turned(face_turn(3)):
        # The louvred vent plate in its recess.
        p.box('rootwell_verdigris', (0, face + .12, 1.675), (1.02, .04, .6), bevel=.008, uv='local')
        for x0, x1, z0, z1 in ((-.52, .52, 1.38, 1.43), (-.52, .52, 1.92, 1.97), (-.52, -.47, 1.38, 1.97), (.47, .52, 1.38, 1.97)):
            p.box('rootwell_brass', ((x0 + x1) / 2, face + .08, (z0 + z1) / 2), (x1 - x0, .05, z1 - z0), bevel=.005, uv='flat')
        for i in range(5):
            p.box('rootwell_verdigris', (0, face + .07, 1.48 + i * .095), (.86, .1, .028), (math.radians(35), 0, 0), .004, 'local')
        rivets(p, [(x, face + .055, z) for x in (-.495, .495) for z in (1.47, 1.675, 1.88)])
        # Copper risers either side, each with a valve wheel; a relief valve on the right; two capped stubs.
        for side in (-1, 1):
            x = side * .74
            p.cylinder('rootwell_brass', (x, face - .1, TERRACE), (x, face - .1, CORNICE + .04), .065, 12, uv='flat')
            p.cylinder('rootwell_brass', (x, face - .1, CORNICE + .04), (x, face + .2, CORNICE + .04), .065, 12, uv='flat')
            for z in (TERRACE + .04, .95, 1.75, 2.35):
                p.cylinder('rootwell_brass', (x, face - .1, z - .03), (x, face - .1, z + .03), .085, 12, uv='flat')
                p.box('rootwell_brass', (x, face - .04, z), (.05, .12, .04), bevel=.004, uv='flat')
            p.cylinder('rootwell_brass', (x, face - .1, 1.15), (x, face - .22, 1.15), .055, 10, uv='flat')
            p.cylinder('rootwell_brass', (x, face - .2, 1.15), (x, face - .28, 1.15), .08, 12, uv='flat')
            with p.into('valve_wheel_service_' + ('w' if side < 0 else 'n')):
                wheel(p, (x, face - .33, 1.15), (0, -1, 0), .16)
        p.cylinder('rootwell_brass', (.74, face - .16, 2.0), (.95, face - .16, 2.0), .03, 8, uv='flat')
        p.cylinder('rootwell_brass', (.95, face - .16, 2.0), (.95, face - .16, 2.12), .05, 10, uv='flat')
        p.box('rootwell_brass', (1.0, face - .16, 2.16), (.14, .025, .025), bevel=.003, uv='flat')
        for x in (-.2, .2):
            p.cylinder('rootwell_brass', (x, face - .12, TERRACE), (x, face - .12, .82), .055, 12, uv='flat')
            p.cylinder('rootwell_brass', (x, face - .12, .78), (x, face - .12, .86), .075, 12, uv='flat')
            p.sphere('rootwell_brass', (x, face - .12, .88), .05, 1, (1, 1, .6))


# --- planting round the base ---------------------------------------------------------------------------------------
def planting(p):
    rng = p.rng
    r_ter = (A_TERRACE + A_DRUM) / 2 / math.cos(math.pi / 8)
    for k in (6, 7):            # the corners either side of the gauge: stone planters with clipped trees
        q = vertex(k, (A_TERRACE + A_DRUM + .1) / 2)
        stone_planter(p, (q.x, q.y, TERRACE), (.66, .56), .48, math.radians(45 * k + 22.5))
    for k in (2, 3):            # either side of the service face: timber planters with trees
        q = vertex(k, (A_TERRACE + A_DRUM + .1) / 2)
        wood_planter(p, (q.x, q.y, TERRACE), (.6, .46), .4, math.radians(45 * k + 22.5 + 90), .9)
    for k in (0, 1, 4, 5):      # the other corners: timber boxes, tall evergreens at the two sides seen past the crown
        q = vertex(k, (A_TERRACE + A_DRUM + .1) / 2)
        wood_planter(p, (q.x, q.y, TERRACE), (.62, .44), .34, math.radians(45 * k + 22.5 + 90), 1.7 if k in (1, 4) else 0.0)
    # Flowers in soil pockets at every corner of the drum top; ivy hangs over the lip at the corners seen front and back.
    for k in range(8):
        q = vertex(k, A_DRUM + .12)
        p.cylinder('soil', (q.x, q.y, TOP), (q.x, q.y, TOP + .02), .2, 10, uv='flat', smooth=False)
        bloom(p, (q.x, q.y, TOP), .2, 12)
        if k in (6, 7, 2, 3):
            for j in (k, k + 1):
                th = math.radians(45 * j)
                n = Vector((math.cos(th), math.sin(th), 0))
                corner = vertex(k, A_DRUM)
                start = corner.lerp(n * A_DRUM, .22) + n * .04
                lip = vertex(k, A_DRUM + .2).lerp(n * (A_DRUM + .2), .2)
                for i in range(5):
                    p.sphere(('leaf', 'leaf_dark', 'leaf_light')[i % 3], lip.lerp(start, i / 4) + Vector((0, 0, TOP - (TOP - DRUM_TOP) * i / 4 + .03)), .075, 1, (1, 1, .8))
                trail(p, (start.x, start.y, DRUM_TOP), (n.x, n.y), rng.uniform(.9, 1.5), .16)


# --- the chamber, its glass and the living root ---------------------------------------------------------------------
def bell_radius(z):
    t = (z - CHAMBER) / (GLASS_TOP - CHAMBER)
    return 1.08 + .22 * math.sin(math.pi * min(max(t, 0), 1)) ** .7


def chamber(p):
    # The teal riveted base band with brass rings, sitting on the drum's top paving.
    lathe(p, 'rootwell_verdigris', [(1.3, TOP), (1.3, CHAMBER)], 48, u_tiles=4)
    for z, minor in ((TOP + .03, .045), (CHAMBER - .01, .05), (3.06, .03)):
        torus(p, 'rootwell_brass', (0, 0, z), 1.31, minor, segs=56)
    rivets(p, [(math.cos(a) * 1.32, math.sin(a) * 1.32, z) for a in [math.tau * i / 32 for i in range(32)] for z in (2.93, 3.19)], .02)
    annulus(p, 'rootwell_brass', 0, 1.29, CHAMBER - .02, CHAMBER + .01, 48)
    p.cylinder('grate', (0, 0, CHAMBER + .005), (0, 0, CHAMBER + .02), .5, 24, uv='flat', smooth=False)
    torus(p, 'rootwell_brass', (0, 0, CHAMBER + .03), .5, .035)
    # Pipes from the collar to four valve stands on the drum top (east, north, west, south).
    for k in (0, 2, 4, 6):
        th = math.radians(45 * k)
        d = Vector((math.cos(th), math.sin(th), 0))
        z = 2.98
        p.cylinder('rootwell_brass', d * 1.28 + Vector((0, 0, z)), d * 1.38 + Vector((0, 0, z)), .1, 12, uv='flat')
        sweep(p, 'rootwell_brass', [d * 1.35 + Vector((0, 0, z)), d * 1.62 + Vector((0, 0, z)), d * 1.72 + Vector((0, 0, z - .03)), d * 1.8 + Vector((0, 0, z - .03))], .06, 12, (False, False))
        v = d * 1.9
        p.box('stone', (v.x, v.y, TOP + .05), (.3, .3, .1), (0, 0, th), .015, ('blocks', 0))
        p.cylinder('rootwell_brass', (v.x, v.y, TOP + .1), (v.x, v.y, 3.12), .1, 14, uv='flat')
        for zz in (TOP + .14, 3.1):
            p.cylinder('rootwell_brass', (v.x, v.y, zz - .025), (v.x, v.y, zz + .025), .13, 14, uv='flat')
        p.cylinder('rootwell_brass', (v.x, v.y, 3.12), (v.x, v.y, 3.24), .065, 12, uv='flat')
        p.cylinder('rootwell_brass', (v.x, v.y, 3.24), (v.x, v.y, 3.36), .02, 6, uv='flat')
        with p.into('valve_wheel_' + {0: 'e', 2: 'n', 4: 'w', 6: 's'}[k]):
            wheel(p, (v.x, v.y, 3.37), (0, 0, 1), .18)
    # The bell: bowed amber glass with brass retainers and glazing ribs.
    zs = [CHAMBER + (GLASS_TOP - CHAMBER) * i / 20 for i in range(21)]
    lathe(p, 'rootwell_bell_glass', [(bell_radius(z), z) for z in zs], 56)
    for z in (CHAMBER + .02, GLASS_TOP):
        torus(p, 'rootwell_brass', (0, 0, z), bell_radius(z) + .02, .045, segs=56)
    torus(p, 'rootwell_brass', (0, 0, (CHAMBER + GLASS_TOP) / 2), bell_radius((CHAMBER + GLASS_TOP) / 2) + .015, .02, segs=56)
    for i in range(8):
        a = math.radians(45 * i)
        rib = [(math.cos(a) * (bell_radius(z) + .015), math.sin(a) * (bell_radius(z) + .015), z) for z in zs]
        sweep(p, 'rootwell_brass', rib, .022, 6, (False, False))
    lathe(p, 'rootwell_brass', [(bell_radius(GLASS_TOP), GLASS_TOP), (1.46, ENTABLATURE + .01)], 48)
    annulus(p, 'rootwell_brass', 0, 1.46, ENTABLATURE, ENTABLATURE + .02, 48)
    root(p)


def root(p):
    """The living root: a twisted trunk out of the well throat, roots spread over the chamber floor, and branches that
    fork to fine twigs filling the bell (root). Behind it, from any side, the chamber's light: a shell just inside the
    glass that faces inward, so only its far half draws and the root stands against it as in the paintings
    (root_light). The root is lit, not emissive, so it keeps its drawn outline."""
    rng = random.Random(4417)
    branches = []

    def inside(q, margin=.12):
        r = math.hypot(q.x, q.y)
        limit = bell_radius(min(max(q.z, CHAMBER), GLASS_TOP)) - margin
        if r > limit:
            q.x, q.y = q.x * limit / r, q.y * limit / r
        q.z = min(q.z, GLASS_TOP - .12)
        return q

    def grow(start, direction, length, radius, depth):
        pts, rads = [Vector(start)], [radius]
        d = Vector(direction).normalized()
        steps = 5
        for i in range(steps):
            d = (d + Vector((rng.uniform(-.3, .3), rng.uniform(-.3, .3), rng.uniform(-.05, .25)))).normalized()
            pts.append(inside(pts[-1] + d * length / steps))
            rads.append(radius * (1 - .6 * (i + 1) / steps))
        branches.append((pts, rads))
        if depth:
            for j in range(rng.choice((2, 2, 3)) if depth > 1 else 2):
                at = rng.randint(2, steps)
                spin = rng.uniform(0, math.tau)
                out = Vector((math.cos(spin), math.sin(spin), 0))
                child = (d * .55 + out * .6 + Vector((0, 0, .35))).normalized()
                grow(pts[at], child, length * rng.uniform(.6, .78), rads[at] * .78, depth - 1)

    # The trunk: three strands twisting round each other.
    base, top = CHAMBER + .04, 4.45
    for s in range(4):
        strand = []
        for i in range(13):
            t = i / 12
            a = s * math.tau / 4 + t * math.tau * .8
            r = .1 + .09 * (1 - t) ** 2
            strand.append((math.cos(a) * r, math.sin(a) * r, base + (top - base) * t))
        branches.append(([Vector(q) for q in strand], [.16 - .06 * i / 12 for i in range(13)]))
    # Main boughs from the top of the trunk.
    for i in range(5):
        a = math.tau * i / 5 + rng.uniform(-.3, .3)
        out = Vector((math.cos(a), math.sin(a), 0))
        grow(Vector((0, 0, top - .1)) + out * .05, out * .85 + Vector((0, 0, .6)), 1.2, .1, 4)
    # Roots over the floor and into the throat.
    for i in range(10):
        a = math.tau * i / 10 + rng.uniform(-.2, .2)
        out = Vector((math.cos(a), math.sin(a), 0))
        reach = rng.uniform(.75, 1.05)
        pts = [out * .1 + Vector((0, 0, base + .18)), out * .3 + Vector((0, 0, base + .06)), out * .55 + Vector((0, 0, base + .03)),
               out * reach + Vector((-out.y, out.x, 0)) * rng.uniform(-.15, .15) + Vector((0, 0, base + .02)), out * (reach + .05) + Vector((0, 0, base - .03))]
        branches.append((pts, [.08, .065, .05, .035, .02]))
    with p.into('root'):
        for pts, rads in branches:
            sweep(p, 'rootwell_root', pts, rads, 7, (False, True), v_rep=.4)
    with p.into('root_light'):
        zs = [CHAMBER + .03 + (GLASS_TOP - CHAMBER - .06) * i / 20 for i in range(21)]
        shell = [(bell_radius(z) - .07, z) for z in reversed(zs)]
        lathe(p, 'rootwell_light', shell, 48, v_rep=-(GLASS_TOP - CHAMBER))


# --- columns, lanterns and the crown ---------------------------------------------------------------------------------
LANTERN_COLUMNS = (0, 4)   # the columns at 22.5 and 202.5 degrees: one lantern each side, seen from front and back


def columns(p):
    for k in range(8):
        th = math.radians(45 * k + 22.5)
        d = Vector((math.cos(th), math.sin(th), 0))
        c = d * COLUMN_R
        p.box('stone', (c.x, c.y, TOP + .14), (.42, .42, .28), (0, 0, th), .02, ('blocks', 0))
        z0 = TOP + .28
        p.cylinder('rootwell_brass', (c.x, c.y, z0), (c.x, c.y, z0 + .08), .2, 16, uv='flat')
        torus(p, 'rootwell_brass', (c.x, c.y, z0 + .1), .155, .035, segs=20, sides=6)
        lathe(p, 'rootwell_verdigris', [(.125, z0 + .1), (.125, ENTABLATURE - .1)], 14, u_tiles=.5, v_rep=1.2, centre=(c.x, c.y))
        for z, r, h in ((3.42, .16, .1), (4.85, .17, .18), (6.05, .155, .08)):
            p.cylinder('rootwell_brass', (c.x, c.y, z - h / 2), (c.x, c.y, z + h / 2), r, 16, uv='flat')
            torus(p, 'rootwell_brass', (c.x, c.y, z + h / 2), r - .01, .018, segs=20, sides=6)
            torus(p, 'rootwell_brass', (c.x, c.y, z - h / 2), r - .01, .018, segs=20, sides=6)
        p.cylinder('rootwell_brass', (c.x, c.y, ENTABLATURE - .12), (c.x, c.y, ENTABLATURE), .2, 16, uv='flat')
        if k in LANTERN_COLUMNS:
            lantern(p, c, d)
    for z in (3.55, 6.32):
        torus(p, 'rootwell_brass', (0, 0, z), COLUMN_R, .032, segs=64, sides=6)


def lantern(p, column, out, s=1.25):
    z = 5.25
    arm0 = column + out * .13
    arm1 = column + out * .55
    sweep(p, 'rootwell_brass', [arm0 + Vector((0, 0, z + .62)), arm1 + Vector((0, 0, z + .62)), arm1 + Vector((0, 0, z + .5))], .032, 8, (True, False))
    curl = [arm0 + Vector((0, 0, z + .15)), arm0 + out * .14 + Vector((0, 0, z + .38)), arm0 + out * .3 + Vector((0, 0, z + .58))]
    sweep(p, 'rootwell_brass', curl, .02, 6)
    p.cylinder('rootwell_brass', column + out * .12 + Vector((0, 0, z + .56)), column + out * .12 + Vector((0, 0, z + .68)), .06, 10, uv='flat')
    c = arm1 + Vector((0, 0, z))
    up = Vector((0, 0, s))
    p.cylinder('rootwell_brass', c + up * .45, c + up * .3, .015 * s, 6, uv='flat')
    p.cylinder('rootwell_verdigris', c + up * .17, c + up * .3, .2 * s, 6, .04 * s, uv='flat', smooth=False)
    torus(p, 'rootwell_brass', c + up * .17, .19 * s, .02 * s, segs=6, sides=6)
    p.sphere('rootwell_brass', c + up * .33, .04 * s, 1)
    p.cylinder('lamp_glass', c - up * .14, c + up * .16, .13 * s, 6, uv='flat', smooth=False)
    for i in range(6):
        a = math.tau * (i + .5) / 6
        q = c + Vector((math.cos(a), math.sin(a), 0)) * .135 * s
        p.cylinder('rootwell_brass', q - up * .15, q + up * .17, .015 * s, 5, uv='flat')
    p.cylinder('rootwell_brass', c - up * .2, c - up * .14, .16 * s, 6, .12 * s, uv='flat', smooth=False)
    p.sphere('rootwell_brass', c - up * .25, .035 * s, 1)


def crown(p):
    # The entablature: brass lips round a teal riveted band, balls over each column and smaller ones between.
    annulus(p, 'rootwell_brass', 1.42, 1.93, ENTABLATURE, ENTABLATURE + .08, 64)
    annulus(p, 'rootwell_verdigris', 1.42, 1.88, ENTABLATURE + .08, DOME - .09, 64, u_tiles=8)
    annulus(p, 'rootwell_brass', 1.42, 1.96, DOME - .09, DOME, 64)
    rivets(p, [(math.cos(a) * 1.885, math.sin(a) * 1.885, (ENTABLATURE + DOME) / 2) for a in [math.tau * (i + .5) / 40 for i in range(40)]], .022)
    for k in range(8):
        th = math.radians(45 * k + 22.5)
        c = Vector((math.cos(th), math.sin(th), 0)) * COLUMN_R
        p.cylinder('rootwell_brass', (c.x, c.y, DOME), (c.x, c.y, DOME + .07), .07, 12, uv='flat')
        p.sphere('rootwell_brass', (c.x, c.y, DOME + .2), .15, 2)
        th2 = math.radians(45 * k)
        q = Vector((math.cos(th2), math.sin(th2), 0)) * 1.86
        p.cylinder('rootwell_brass', (q.x, q.y, DOME), (q.x, q.y, DOME + .08), .025, 8, uv='flat')
        p.sphere('rootwell_brass', (q.x, q.y, DOME + .12), .06, 1)
    # The ribbed copper dome.
    rx, rz = 1.8, 1.35
    profile = []
    for i in range(17):
        a = math.pi / 2 * i / 16
        r = rx * math.cos(a)
        if r < .48:
            break
        profile.append((r, DOME + rz * math.sin(a)))
    lathe(p, 'rootwell_verdigris', profile, 64, u_tiles=6, v_rep=1.2)
    top_r, top_z = profile[-1]
    torus(p, 'rootwell_brass', (0, 0, DOME + .02), rx + .01, .04, segs=64)
    for i in range(16):
        a = math.tau * i / 16
        rib = [(math.cos(a) * (r + .004), math.sin(a) * (r + .004), z) for r, z in profile]
        sweep(p, 'rootwell_brass', rib, .024, 6, (False, False))
        rivets(p, [(math.cos(a) * (r + .025), math.sin(a) * (r + .025), z) for r, z in profile[1:-1:3]], .02)
    # The cupola: a teal drum with studs, a flared cap, two finials, struts down to the dome.
    torus(p, 'rootwell_brass', (0, 0, top_z), top_r + .02, .05, segs=32)
    lathe(p, 'rootwell_verdigris', [(.42, top_z), (.42, top_z + .36)], 32, u_tiles=1)
    annulus(p, 'rootwell_brass', 0, .42, top_z - .05, top_z, 32)
    for z in (top_z + .06, top_z + .34):
        torus(p, 'rootwell_brass', (0, 0, z), .43, .025, segs=32)
    rivets(p, [(math.cos(a) * .43, math.sin(a) * .43, top_z + .2) for a in [math.tau * i / 12 for i in range(12)]], .025)
    annulus(p, 'rootwell_brass', 0, .54, top_z + .36, top_z + .42, 32)
    lathe(p, 'rootwell_verdigris', [(.52, top_z + .42), (.4, top_z + .55), (.24, top_z + .68), (.12, top_z + .78)], 32, u_tiles=1)
    torus(p, 'rootwell_brass', (0, 0, top_z + .43), .53, .025, segs=32)
    p.cylinder('rootwell_brass', (0, 0, top_z + .76), (0, 0, top_z + .86), .1, 16, uv='flat')
    p.sphere('rootwell_brass', (0, 0, top_z + .98), .14, 2)
    p.cylinder('rootwell_brass', (0, 0, top_z + 1.1), (0, 0, top_z + 1.16), .05, 10, uv='flat')
    p.sphere('rootwell_brass', (0, 0, top_z + 1.21), .06, 1)


# --- assembling and saving ----------------------------------------------------------------------------------------
def pivot(name, point, turn=0.0):
    """Moves an object's origin to `point` and turns its axes by `turn` degrees about Z, keeping the geometry where
    it is, so code can later swing, spin or rotate the part about its own axis."""
    obj = bpy.data.objects[name]
    frame = Matrix.Translation(point) @ Matrix.Rotation(math.radians(turn), 4, 'Z')
    obj.data.transform(frame.inverted())
    obj.matrix_world = frame
    obj['pivot'] = 'origin on the axis; see the rootwell README'


def assemble():
    root_obj = kit.begin(ASSET, PALETTE)
    materials()
    p = kit.Parts(2911)
    base(p)
    gauge(p)
    notices(p)
    door(p)
    service(p)
    planting(p)
    chamber(p)
    columns(p)
    crown(p)
    p.finish(root_obj)
    # The gauge needle turns about the dial's axis: its local frame is the gauge face's (x right, y into the wall).
    th7 = math.radians(face_turn(7))
    dial = Matrix.Rotation(th7, 4, 'Z') @ Vector((0, -A_DRUM - .005, DIAL_Z))
    pivot('gauge_needle', dial, face_turn(7))
    th0 = math.radians(face_turn(0))
    hinge = Matrix.Rotation(th0, 4, 'Z') @ Vector((-.43, -A_DRUM + .1, TERRACE))
    pivot('maintenance_door', hinge, face_turn(0))
    for k, key in ((0, 'e'), (2, 'n'), (4, 'w'), (6, 's')):
        th = math.radians(45 * k)
        pivot('valve_wheel_' + key, Vector((math.cos(th) * 1.9, math.sin(th) * 1.9, 3.37)), 45 * k)
    th3 = math.radians(face_turn(3))
    for side, key in ((-1, 'w'), (1, 'n')):
        pivot('valve_wheel_service_' + key, Matrix.Rotation(th3, 4, 'Z') @ Vector((side * .74, -A_DRUM - .33, 1.15)), face_turn(3))


def save(out=None):
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    bpy.ops.file.pack_all()
    if out:
        path = Path(out) / ASSET / 'model.blend'
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(path))
        print('DRAFT', ASSET, path, flush=True)
        return
    scene['rootwell_source'] = 'Editable authority after the v0.72 Rootwell paintings. Do not rerun the authoring record.'
    folder = ROOT / 'art/source/world' / ASSET / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()  # noqa: E731
    note = {'asset': ASSET, 'date': '2026-10-29',
            'references': {ref: digest(ROOT / ref) for ref in REFERENCES},
            'authoring_record': 'art/source/world/rootwell/v1/author_rootwell.py', 'authoring_record_sha256': digest(__file__),
            'kit': 'art/source/world/seaside-houses/v1/house_kit.py', 'kit_sha256': digest(kit.__file__),
            'verdigris': {'path': 'art/source/world/rootwell/v1/verdigris.png', 'sha256': digest(VERDIGRIS),
                          'derived_from': 'art/source/world/textures/v2-detail/native/copper_patina.png', 'derived_from_sha256': digest(COPPER)},
            'palette': PALETTE,
            'note': 'New bespoke authored asset; model.blend is now authority. Build through scripts/world-art.sh.'}
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', ASSET, flush=True)


if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    draft = argv[argv.index('--draft') + 1] if '--draft' in argv else None
    if not draft and (ROOT / 'art/source/world' / ASSET / 'v1/model.blend').exists():
        raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + ASSET)
    assemble()
    save(draft)
