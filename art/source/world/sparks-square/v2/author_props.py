"""One-time authoring of Guildhall Square's street furniture and its six rolling robots, after
docs/concept/v0.72/art/guildhall-square.png and docs/concept/v0.72/art/robots/lineup.png.

Run with Blender: blender -b --python author_props.py [-- asset ...]. Refuses any existing master; after creation
each model.blend is the authority. Origins are the ground centre; fronts face logical -y.
"""
import math
import random
import sys
from pathlib import Path
import bmesh
import bpy
from mathutils import Matrix, Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import square_kit as s  # noqa: E402

k, h = s.k, s.h
RECORD = 'author_props.py'


# --- street furniture ----------------------------------------------------------------------------------------------
def banner_lamp():
    """An iron lamppost on a stone foot: fluted base, a crown of scrolls under one hexagonal lantern, and a side
    arm with the town's teal banner. The banner is its own object hung from its top edge (cloth_banner) so the
    breeze can move it; the lantern glass is lamp_glass, which the game lights."""
    rng = random.Random(29201)
    b = k.Batch(rng)
    b.box('limestone_shade', (0, 0, .09), (.46, .46, .18), .02)
    b.box('limestone_pale', (0, 0, .24), (.38, .38, .12), .02)
    b.cylinder('iron', (0, 0, .3), (0, 0, .62), .13, 12, .09)
    for i in range(12):
        a = math.tau * i / 12
        b.cylinder('iron_light', (math.cos(a) * .1, math.sin(a) * .1, .34), (math.cos(a) * .07, math.sin(a) * .07, .6), .012, 4)
    b.cylinder('iron', (0, 0, .6), (0, 0, .75), .1, 12, .06)
    b.cylinder('iron', (0, 0, .75), (0, 0, 3.15), .052, 10, .042)
    for z in (1.05, 2.2, 2.86):
        b.cylinder('iron_light', (0, 0, z - .025), (0, 0, z + .025), .07, 10)
    for i in range(4):
        a = math.tau * i / 4 + math.pi / 4
        h.curve('Crown scroll', [(0, 0, 3.0), (math.cos(a) * .14, math.sin(a) * .14, 3.08), (math.cos(a) * .18, math.sin(a) * .18, 3.2), (math.cos(a) * .1, math.sin(a) * .1, 3.24)], .014, 'iron')
    b.cylinder('iron', (0, 0, 3.15), (0, 0, 3.22), .13, 6)
    h.cylinder('Lantern glass', (0, 0, 3.45), .12, .42, 'lamp_glass', 6)
    for i in range(6):
        a = math.tau * i / 6
        b.cylinder('iron', (math.cos(a) * .125, math.sin(a) * .125, 3.22), (math.cos(a) * .16, math.sin(a) * .16, 3.68), .012, 4)
    b.cylinder('iron', (0, 0, 3.66), (0, 0, 3.72), .19, 6)
    b.cylinder('iron', (0, 0, 3.72), (0, 0, 3.9), .19, 6, .05)
    b.sphere('iron', (0, 0, 3.95), .045, 1)
    # The banner arm and its scroll brace, on the lamp's +x side.
    b.cylinder('iron', (.04, 0, 2.78), (.62, 0, 2.78), .018, 6)
    h.curve('Arm brace', [(.04, 0, 2.5), (.2, 0, 2.55), (.4, 0, 2.7), (.55, 0, 2.77)], .012, 'iron')
    for x in (.08, .58):
        b.cylinder('iron', (x, 0, 2.78), (x, 0, 2.74), .02, 6)
    b.sphere('iron', (.64, 0, 2.78), .028, 1)
    b.finish()
    banner = bpy.data.objects.new('cloth_banner', bpy.data.meshes.new('cloth_banner'))
    bm = bmesh.new()
    w, top, length = .46, 0.0, 1.15
    verts = [(-w / 2, 0, -.04), (w / 2, 0, -.04), (w / 2, 0, -length), (0, 0, -length + .16), (-w / 2, 0, -length)]
    for side in (-.012, .012):
        for v in verts:
            bm.verts.new((v[0], side, v[2]))
    bm.verts.ensure_lookup_table()
    n = len(verts)
    bm.faces.new([bm.verts[i] for i in range(n)])
    bm.faces.new([bm.verts[n + i] for i in reversed(range(n))])
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new([bm.verts[j], bm.verts[i], bm.verts[n + i], bm.verts[n + j]])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    layer = bm.loops.layers.uv.verify()
    for f in bm.faces:
        for loop in f.loops:
            loop[layer].uv = (loop.vert.co.x + .5, -loop.vert.co.z)
    bm.to_mesh(banner.data)
    bm.free()
    banner.location = (.4, 0, 2.76)
    bpy.context.scene.collection.objects.link(banner)
    h.put(banner, 'banner')
    trim = k.Batch(rng)
    trim.box('gold', (0, 0, -.1), (w + .02, .03, .03), 0)
    for x in (-w / 2 + .03, w / 2 - .03):
        trim.box('gold', (x, 0, -.55), (.02, .03, .9), 0)
    for face in (-1, 1):
        s.emblem(trim, (0, face * .012, -.48), (0, face), .9)
    trim.finish()
    for obj in [o for o in bpy.context.scene.objects if o.type == 'MESH' and o.name.startswith('gold')]:
        obj.name = 'banner_emblem'
        obj.parent = banner
    for hook in (-.16, .16):
        h.torus('Banner ring', (.4 + hook, 0, 2.76), .025, .006, 'iron', (math.pi / 2, 0, 0))


def canopy_frame(b, w, d, z, posts='wood_dark'):
    for x in (-w / 2, w / 2):
        for y in (-d / 2, d / 2):
            b.box(posts, (x, y, z / 2), (.08, .08, z), .01)
    for y in (-d / 2, d / 2):
        b.box(posts, (0, y, z), (w + .1, .07, .07), .01)
    for x in (-w / 2, w / 2):
        b.box(posts, (x, 0, z), (.07, d + .1, .07), .01)


def cloth_roof(b, w, d, z, rise, mat='canvas', valance=True):
    """A canvas roof pitched front to back over a stall, sagging a little between its ridge and eaves, with a
    scalloped valance on the camera's two sides."""
    for side in (-1, 1):
        for i in range(6):
            t0, t1 = i / 6, (i + 1) / 6
            y0, y1 = side * (d / 2 + .12) * (1 - t0), side * (d / 2 + .12) * (1 - t1)
            sag = math.sin(math.pi * (t0 + t1) / 2) * .03
            z0, z1 = z + rise * t0 - sag, z + rise * t1 - sag
            mid = ((y0 + y1) / 2, (z0 + z1) / 2)
            length = math.hypot(y1 - y0, z1 - z0)
            b.box(mat if i % 2 == 0 else 'canvas_shade' if mat == 'canvas' else mat, (0, mid[0], mid[1]), (w + .24, length + .01, .03), .006, (math.atan2(z1 - z0, y1 - y0), 0, 0))
    if valance:
        for i in range(int((w + .24) / .2)):
            x = -(w + .24) / 2 + .1 + i * .2
            b.sphere(mat, (x, -d / 2 - .13, z - .08), .1, 1, (1, .22, .8))
        for i in range(int((d + .24) / .2)):
            y = -(d + .24) / 2 + .1 + i * .2
            b.sphere(mat, (w / 2 + .13, y, z + rise * (1 - abs(y) / (d / 2 + .12)) * 0 - .08), .1, 1, (.22, 1, .8))
    b.box('wood_dark', (0, 0, z + rise + .02), (w + .3, .05, .05), .01)


def bunch(b, rng, at, colours, radius=.14, count=7):
    x, y, z = at
    for i in range(count):
        a, r = rng.uniform(0, math.tau), rng.uniform(0, radius)
        b.cylinder('leaf_dark', (x, y, z - .18), (x + math.cos(a) * r * .6, y + math.sin(a) * r * .6, z), .008, 4)
        b.sphere(colours[rng.randrange(len(colours))], (x + math.cos(a) * r, y + math.sin(a) * r, z + rng.uniform(0, .06)), rng.uniform(.045, .07), 1)
    for i in range(4):
        a = rng.uniform(0, math.tau)
        b.sphere('leaf' if i % 2 else 'leaf_light', (x + math.cos(a) * radius * .8, y + math.sin(a) * radius * .8, z - .05), .05, 1, (1, 1, .6))


def flower_stall():
    """A timber flower stall under a cream canvas roof: stepped shelves of buckets and crates of cut flowers,
    pots on the ground, a watering can and a little chalked board. Front toward -y."""
    rng = random.Random(29202)
    b = k.Batch(rng)
    W, D, Z = 2.4, 1.3, 1.95
    canopy_frame(b, W, D, Z)
    cloth_roof(b, W, D, Z, .42)
    palettes = [('flower_pink', 'flower_white'), ('flower_red', 'flower_yellow'), ('flower_violet', 'flower_white'), ('flower_yellow', 'flower_red'),
                ('flower_blue', 'flower_white'), ('flower_pink', 'flower_red')]
    for row, (y, z) in enumerate(((-.38, .42), (0, .7), (.38, .98))):
        b.box('wood', (0, y, z - .06), (W - .1, .36, .05), .01)
        for x in (-W / 2 + .1, W / 2 - .1):
            b.box('wood_dark', (x, y, z / 2), (.05, .3, z), .005)
        for i in range(5):
            x = -W / 2 + .3 + i * (W - .6) / 4
            if (i + row) % 2:
                b.cylinder('steel', (x, y, z - .04), (x, y, z + .2), .11, 10, .13)
                bunch(b, rng, (x, y, z + .4), palettes[(i + row) % 6], .14, 9)
            else:
                b.box('wood_light', (x, y, z + .06), (.36, .28, .18), .012)
                for j in range(6):
                    b.sphere(palettes[(i + row + 2) % 6][j % 2], (x + rng.uniform(-.13, .13), y + rng.uniform(-.09, .09), z + .2), .06, 1)
    for x, y, scale in ((-1.35, -.5, 1.0), (1.4, -.45, .85), (1.45, .25, 1.1), (-1.4, .3, .8)):
        h.pot((x, y, 0), scale, False, True)
    b.cylinder('steel', (.9, -.85, 0), (.9, -.85, .28), .13, 12, .15)
    bunch(b, rng, (.9, -.85, .52), ('flower_white', 'flower_yellow'), .16, 10)
    b.cylinder('teal', (-.75, -.9, .02), (-.75, -.9, .26), .1, 12)
    b.cylinder('teal', (-.75, -.9, .2), (-.98, -.9, .36), .025, 6)
    h.torus('Can handle', (-.75, -.9, .3), .08, .012, 'teal', (math.pi / 2, 0, 0))
    b.box('ink', (W / 2 + .1, -.62, .42), (.04, .4, .55), .01, (0, .14, 0))
    b.box('chalk', (W / 2 + .125, -.62, .5), (.005, .28, .02), 0)
    b.box('chalk', (W / 2 + .125, -.62, .4), (.005, .2, .02), 0)
    b.finish()


def fruit_stall():
    """A produce barrow-stall under a striped canvas roof: tilted crates of oranges, apples, pears and lemons,
    baskets, a hanging scale, sacks of potatoes and a price board. Front toward -y."""
    rng = random.Random(29203)
    b = k.Batch(rng)
    W, D, Z = 2.2, 1.2, 1.9
    canopy_frame(b, W, D, Z)
    cloth_roof(b, W, D, Z, .38, 'stripe_cream')
    for i in range(7):
        x = -W / 2 + (i + .5) * W / 7
        if i % 2:
            b.box('red', (x, -D / 4 - .05, Z + .2), (W / 7, D / 2 + .25, .035), .004, (math.atan2(.38, D / 2 + .12), 0, 0))
    b.box('wood', (0, -.1, .7), (W - .1, .8, .06), .01)
    b.box('wood_dark', (0, -.1, .35), (W - .2, .7, .7), .015)
    for x in (-.9, .9):
        b.box('wood_dark', (x, -.52, .35), (.06, .04, .62), .005)
    fruit = ('orange', 'apple', 'pear', 'lemon', 'plum_fruit')
    for i in range(5):
        x = -W / 2 + .25 + i * (W - .5) / 4
        b.box('wood_light', (x, -.25, .82), (.38, .36, .18), .012, (-.25, 0, 0))
        for j in range(9):
            b.sphere(fruit[i], (x + rng.uniform(-.14, .14), -.27 + rng.uniform(-.11, .11), .94 + rng.uniform(-.03, .04)), .065 if fruit[i] != 'plum_fruit' else .05, 1)
    for i, x in enumerate((-.7, .1, .75)):
        b.cylinder('ochre', (x, .2, .73), (x, .2, .9), .15, 12, .18)
        for j in range(6):
            b.sphere(('apple', 'pear', 'orange')[i], (x + rng.uniform(-.1, .1), .2 + rng.uniform(-.1, .1), .95), .06, 1)
    b.cylinder('brass', (.6, -.45, Z - .02), (.6, -.45, Z - .35), .008, 4)
    h.cylinder('Scale dial', (.6, -.45, Z - .45), .1, .04, 'enamel_cream', 20).rotation_euler = (math.pi / 2, 0, 0)
    h.torus('Scale rim', (.6, -.47, Z - .45), .1, .015, 'brass', (math.pi / 2, 0, 0))
    b.cylinder('brass', (.6, -.45, Z - .55), (.6, -.45, Z - .7), .008, 4)
    b.cylinder('brass', (.6, -.45, Z - .72), (.6, -.45, Z - .76), .14, 16, .1)
    for x, y in ((-1.4, -.4), (-1.45, .1), (1.38, .2)):
        b.sphere('linen', (x, y, .25), .22, 1, (1, .9, 1.2))
        b.sphere('wood_light', (x, y, .5), .1, 1, (1, 1, .5))
    b.box('ink', (-.3, -.62, 1.1), (.4, .03, .3), .01)
    b.box('chalk', (-.3, -.64, 1.14), (.28, .005, .02), 0)
    b.box('chalk', (-.3, -.64, 1.06), (.2, .005, .02), 0)
    b.finish()


def tree_planter():
    """A shade tree in a square limestone planter with a timber seat round two sides: a flared bark trunk,
    boughs that fork, a full rounded crown lit lighter on top, and flowers at its foot."""
    rng = random.Random(29204)
    b = k.Batch(rng)
    S = 1.25
    for x0, y0, x1, y1 in ((-S, -S, S, -S + .22), (-S, S - .22, S, S), (-S, -S, -S + .22, S), (S - .22, -S, S, S)):
        b.box('limestone', ((x0 + x1) / 2, (y0 + y1) / 2, .26), (x1 - x0, y1 - y0, .52), .025)
        b.box('limestone_pale', ((x0 + x1) / 2, (y0 + y1) / 2, .55), (x1 - x0 + .06, y1 - y0 + .06, .08), .02)
    b.box('soil', (0, 0, .47), (2 * S - .4, 2 * S - .4, .06), 0)
    for side in ((0, -1), (1, 0)):
        fx, fy = side
        for i in range(5):
            along = -S + .2 + i * (2 * S - .4) / 4
            px, py = (along, -S - .22) if fy else (S + .22, along)
            b.box('wood' if i % 2 else 'wood_light', (px, py, .46), (.48 if fy else .36, .36 if fy else .48, .05), .01)
        for along in (-S + .3, S - .3):
            px, py = (along, -S - .2) if fy else (S + .2, along)
            b.box('iron', (px, py, .22), (.06, .06, .44), .01)
    for i in range(10):
        a = math.tau * i / 10
        b.cylinder('bark', (math.cos(a) * .3, math.sin(a) * .3, .5), (math.cos(a) * .08, math.sin(a) * .08, 1.0), .07, 6, .03)
    b.cylinder('bark', (0, 0, .48), (.04, .02, 2.0), .2, 10, .15)
    b.cylinder('bark', (.04, .02, 2.0), (-.05, .05, 2.9), .15, 10, .1)
    rng2 = random.Random(7)
    tips = []
    for i in range(6):
        a = i * math.tau / 6 + .4
        base = Vector((0, 0, 1.9 + (i % 3) * .3))
        mid = base + Vector((math.cos(a) * .7, math.sin(a) * .7, .5))
        tip = mid + Vector((math.cos(a + .3) * .7, math.sin(a + .3) * .7, .55))
        b.cylinder('bark', tuple(base), tuple(mid), .09, 8, .07)
        b.cylinder('bark', tuple(mid), tuple(tip), .07, 6, .04)
        tips.append(tip)
    for tip in tips:
        for j in range(9):
            p = tip + Vector((rng2.uniform(-.7, .7), rng2.uniform(-.7, .7), rng2.uniform(-.3, .55)))
            b.sphere(('leaf', 'leaf_light', 'leaf', 'leaf_dark')[j % 4] if p.z < 3.6 else ('leaf_light', 'leaf', 'leaf_light')[j % 3], tuple(p), rng2.uniform(.45, .62), 2)
    for j in range(16):
        a = rng2.uniform(0, math.tau)
        r = rng2.uniform(0, 1.3)
        b.sphere('leaf_light', (math.cos(a) * r, math.sin(a) * r, 3.9 + rng2.uniform(0, .5)), rng2.uniform(.42, .6), 2)
    for i in range(14):
        a = math.tau * i / 14
        k.flower_clump(b, (math.cos(a) * .75, math.sin(a) * .75, .5), .14, rng, ('flower_white', 'flower_pink', 'flower_yellow', 'flower_violet'), count=4)
    b.finish()


def timber_store():
    """Building stock waiting on the open side of the square: sawn planks stacked on bearers, long beams, crates,
    a barrel, a coil of rope, a tarpaulin pegged half over one stack, sawhorses with a plank and a toolbox."""
    rng = random.Random(29205)
    b = k.Batch(rng)
    for stack, (cx, cy, layers) in enumerate(((-.9, .25, 6), (.75, .35, 4))):
        for x in (-.7, 0, .7):
            b.box('wood_dark', (cx + x, cy, .06), (.12, .9, .12), .01)
        for layer in range(layers):
            z = .14 + layer * .09
            for i in range(5):
                y = cy - .32 + i * .16
                b.box(('wood_light', 'wood', 'wood_light')[(layer + i) % 3], (cx + rng.uniform(-.04, .04), y, z), (1.65, .14, .08), .01)
        if stack == 0:
            top = .14 + layers * .09
            for i in range(4):
                t = i / 4
                b.box('teal_dark' if i % 2 else 'teal', (cx - .3 + t * .5, cy, top + .02 - i * .01), (.5, 1.0, .02), .008, (0, 0, .03 * i))
            b.box('teal', (cx - .42, cy - .5, top - .12), (.9, .03, .3), .008, (-.5, 0, 0))
            for x in (cx - .9, cx - .2):
                b.cylinder('rope' if 'rope' in k.M else 'ochre', (x, cy - .52, top - .4), (x, cy - .6, 0), .008, 4)
    for i, (y, z) in enumerate(((-.55, .1), (-.72, .1), (-.63, .25))):
        b.box('wood_dark', (-.3 + i * .05, y, z), (2.6, .15, .15), .015, (0, 0, .04 * (i - 1)))
    for x, y, size in ((1.1, -.45, .45), (1.5, -.35, .38), (1.28, -.4, .32)):
        z = size / 2 if size != .32 else .45 + .16
        b.box('wood', (x, y, z), (size, size, size), .015)
        for dz in (-size / 3, size / 3):
            b.box('wood_dark', (x, y - size / 2 - .005, z + dz), (size + .01, .02, .04), 0)
    b.cylinder('wood_dark', (1.75, .55, 0), (1.75, .55, .62), .26, 14, .24)
    for z in (.12, .5):
        h.torus('Barrel hoop', (1.75, .55, z), .262, .018, 'iron')
    h.torus('Rope coil', (-.1, -1.1, .05), .22, .05, 'ochre')
    h.torus('Rope coil', (-.1, -1.1, .14), .2, .05, 'ochre')
    for x in (-1.4, -.2):
        for leg in (-1, 1):
            for side in (-1, 1):
                b.box('wood_dark', (x + leg * .12, -1.25 + side * .18, .28), (.05, .05, .58), .005, (side * .25, leg * .15, 0))
        b.box('wood_dark', (x, -1.25, .56), (.32, .08, .08), .01)
    b.box('wood_light', (-.8, -1.25, .64), (1.8, .26, .05), .01, (0, 0, .03))
    b.box('red', (.55, -1.15, .12), (.5, .24, .22), .015)
    b.box('red_dark', (.55, -1.15, .26), (.5, .24, .05), .01)
    b.box('iron', (.55, -1.15, .32), (.3, .03, .03), .005)
    b.box('steel', (.65, -1.22, .3), (.25, .03, .02), .003, (0, 0, .4))
    b.finish()


# --- robots ---------------------------------------------------------------------------------------------------------
def wheelbase(b, wheels, plate=(.5, .42), z=.12, mat='teal_dark'):
    b.box(mat, (0, 0, z), (plate[0], plate[1], .07), .02)
    for name, at, radius, width in wheels:
        s.wheel(name, at, radius, width)
        b.cylinder('iron', (at[0] - math.copysign(width * .6, at[0]), at[1], at[2]), (at[0] - math.copysign(width * 1.4, at[0]) if abs(at[0]) > .05 else at[0], at[1], at[2]), .02, 6)


def four_wheels(x, y, r, w=.07):
    return [('wheel_' + n, (sx * x, sy * y, r), r, w) for n, sx, sy in (('fl', -1, -1), ('fr', 1, -1), ('bl', -1, 1), ('br', 1, 1))]


def mitten_arm(b, shoulder, elbow, hand, mat='teal', joint='brass', mitten=None):
    b.sphere(joint, shoulder, .05, 1)
    b.cylinder(mat, shoulder, elbow, .035, 8)
    b.sphere(joint, elbow, .04, 1)
    b.cylinder(mat, elbow, hand, .032, 8)
    b.sphere(mitten or mat, hand, .065, 1, (1, .8, 1))


def robot_pip():
    """Pip, the postal robot: a red pillar box on four wheels with a domed cap, a letter in its slot, a pigeonhole
    panel of envelopes, little red arms and a canvas satchel."""
    rng = random.Random(29211)
    b = k.Batch(rng)
    wheelbase(b, four_wheels(.24, .16, .1), (.5, .42))
    b.cylinder('teal_light', (0, 0, .16), (0, 0, .28), .3, 20)
    b.cylinder('enamel_red', (0, 0, .28), (0, 0, 1.0), .28, 24)
    for z in (.3, .98):
        h.torus('Pip band', (0, 0, z), .285, .02, 'enamel_red_dark')
    s.dome('Pip cap', (0, 0, 1.0), .31, .16, 'enamel_red', 24, 8)
    h.torus('Pip cap rim', (0, 0, 1.0), .31, .025, 'enamel_red_dark')
    b.cylinder('brass', (0, 0, 1.14), (0, 0, 1.2), .03, 8)
    b.sphere('brass', (0, 0, 1.24), .05, 1)
    b.box('ink', (0, -.265, .87), (.26, .04, .045), .005)
    b.box('paper', (0, -.29, .9), (.2, .02, .1), .004, (.25, 0, .08))
    s.spark_face(b, (0, -.275, .64), .13, (0, -1))
    b.box('enamel_red_dark', (0, -.27, .42), (.28, .03, .2), .01)
    for i, (x, z) in enumerate(((-.07, .46), (.07, .46), (-.07, .38), (.07, .38))):
        b.box('linen' if i % 3 else 'paper', (x, -.29, z), (.11, .015, .07), .004)
        b.box('leaf' if i == 2 else 'ochre', (x, -.297, z), (.05, .005, .03), 0)
    for side in (-1, 1):
        mitten_arm(b, (side * .3, 0, .7), (side * .42, -.05, .58), (side * .4, -.18, .5), 'enamel_red', 'white', 'enamel_red')
    b.box('canvas', (.38, .02, .44), (.1, .3, .26), .03)
    b.box('canvas_shade', (.43, .02, .52), (.03, .31, .1), .01)
    b.cylinder('leather_dark' if 'leather_dark' in k.M else 'wood_dark', (.38, .02, .56), (.33, -.02, .74), .012, 4)
    b.finish()


def robot_trowel():
    """Trowel, the gardener: a cream watering-can body with teal bands on four wheels, a brass handle and a rose on
    its spout, a pot of seedlings riding on its back."""
    rng = random.Random(29212)
    b = k.Batch(rng)
    wheelbase(b, four_wheels(.22, .15, .1), (.46, .38))
    b.sphere('cream', (0, 0, .46), .3, 2, (1.05, 1, .95))
    for z, r in ((.33, .27), (.56, .27)):
        h.torus('Trowel band', (0, 0, z), r, .03, 'teal')
    s.dome('Trowel cap', (0, 0, .68), .2, .1, 'teal', 20, 8)
    h.curve('Trowel handle', [(-.14, .04, .72), (-.08, .05, .9), (.08, .05, .9), (.14, .04, .72)], .022, 'brass')
    b.cylinder('cream', (-.25, 0, .42), (-.52, -.04, .68), .06, 10, .035)
    b.cylinder('teal', (-.52, -.04, .68), (-.58, -.05, .74), .05, 10, .09)
    h.cylinder('Spout rose', (-.6, -.05, .76), .095, .02, 'brass', 16).rotation_euler = (0, math.radians(-50), 0)
    for i in range(6):
        a = math.tau * i / 6
        b.sphere('ink', (-.6 + math.cos(a) * .05 * .64, -.05 + math.sin(a) * .05, .76 + math.cos(a) * .05 * .77), .012, 1)
    s.spark_face(b, (0, -.29, .48), .13, (0, -1))
    mitten_arm(b, (.28, -.05, .48), (.36, -.12, .38), (.33, -.22, .33))
    h.pot((.06, .2, .7), .75, False, True)
    for i in range(5):
        a = i * math.tau / 5
        b.sphere('leaf_light', (.06 + math.cos(a) * .12, .2 + math.sin(a) * .1, .98), .06, 1)
    b.finish()


def robot_wick():
    """Wick, the lamplighter: a slim cream body on a broad three-wheeled base, a lantern-shaped head under a teal
    hat, holding a brass lighting pole with its own little lantern."""
    rng = random.Random(29213)
    b = k.Batch(rng)
    for name, at, r, w in (('wheel_l', (-.22, 0, .14), .14, .07), ('wheel_r', (.22, 0, .14), .14, .07), ('wheel_c', (0, .2, .06), .06, .04)):
        s.wheel(name, at, r, w)
    b.box('teal_dark', (0, .02, .16), (.36, .34, .08), .02)
    b.cylinder('iron', (-.27, 0, .14), (.27, 0, .14), .02, 6)
    b.cylinder('teal', (0, 0, .2), (0, 0, .32), .2, 16, .16)
    b.cylinder('cream', (0, 0, .32), (0, 0, 1.0), .13, 16, .12)
    for z in (.45, .78, .98):
        h.torus('Wick band', (0, 0, z), .13, .018, 'brass')
    b.box('brass', (0, -.125, .62), (.1, .02, .08), .005)
    b.cylinder('brass', (0, 0, 1.0), (0, 0, 1.06), .05, 10)
    b.cylinder('cream', (0, 0, 1.06), (0, 0, 1.32), .15, 16)
    s.spark_face(b, (0, -.15, 1.19), .095, (0, -1))
    b.cylinder('teal', (0, 0, 1.32), (0, 0, 1.36), .2, 16)
    b.cylinder('teal', (0, 0, 1.36), (0, 0, 1.52), .19, 16, .03)
    b.sphere('brass', (0, 0, 1.55), .035, 1)
    mitten_arm(b, (.14, 0, .85), (.24, -.04, .72), (.27, -.06, .9), 'brass', 'teal', 'teal')
    mitten_arm(b, (-.14, 0, .85), (-.2, -.06, .7), (-.18, -.12, .58), 'brass', 'teal', 'teal')
    b.cylinder('brass', (.27, -.06, .35), (.27, -.06, 1.85), .015, 6)
    b.cylinder('brass', (.27, -.06, 1.85), (.42, -.06, 1.92), .012, 6)
    b.cylinder('iron', (.42, -.06, 1.92), (.42, -.06, 1.84), .008, 4)
    b.cylinder('iron', (.42, -.06, 1.83), (.42, -.06, 1.86), .05, 6, .02)
    h.cylinder('Pole lantern glass', (.42, -.06, 1.76), .04, .12, 'lamp_glass', 6)
    b.cylinder('iron', (.42, -.06, 1.69), (.42, -.06, 1.7), .045, 6)
    b.finish()


def robot_heron():
    """Heron, the porter crane: a cream dome on a striped collar and four wheels, a winch drum, a teal jib with
    pulleys, a cable, a brass hook and a crate in the air."""
    rng = random.Random(29214)
    b = k.Batch(rng)
    wheelbase(b, four_wheels(.25, .2, .1), (.56, .48))
    for i in range(16):
        a = math.tau * i / 16
        b.box('teal' if i % 2 else 'cream', (math.cos(a) * .27, math.sin(a) * .27, .26), (.11, .06, .12), .01, (0, 0, a + math.pi / 2))
    b.cylinder('cream', (0, 0, .2), (0, 0, .32), .26, 16)
    s.dome('Heron body', (0, 0, .32), .29, .36, 'cream', 24, 10)
    s.dome('Heron cap', (0, 0, .58), .17, .1, 'teal', 16, 6)
    s.spark_face(b, (0, -.24, .48), .11, (0, -1))
    b.cylinder('brass', (-.3, 0, .45), (-.36, 0, .45), .1, 16)
    h.torus('Winch rim', (-.37, 0, .45), .1, .015, 'brass', (0, math.pi / 2, 0))
    b.sphere('teal', (0, .02, .7), .07, 1)
    jib_a, jib_b = Vector((0, .05, .7)), Vector((0, -.5, 1.35))
    b.cylinder('teal', tuple(jib_a), tuple(jib_b), .045, 8)
    b.cylinder('teal_dark', tuple(jib_a + Vector((0, .02, -.05))), tuple(jib_b + Vector((0, .02, -.08))), .02, 6)
    for p in (jib_a, jib_b):
        h.cylinder('Jib pulley', tuple(p), .07, .04, 'brass', 16).rotation_euler = (0, math.pi / 2, 0)
    b.cylinder('ink', (-.36, 0, .55), tuple(jib_a + Vector((0, 0, .07))), .006, 4)
    b.cylinder('ink', tuple(jib_a + Vector((0, 0, .07))), tuple(jib_b + Vector((0, 0, .07))), .006, 4)
    b.cylinder('ink', tuple(jib_b + Vector((0, -.07, 0))), (0, -.57, .95), .006, 4)
    h.torus('Crane hook eye', (0, -.57, .93), .025, .008, 'brass', (0, math.pi / 2, 0))
    h.curve('Crane hook', [(0, -.57, .91), (0, -.57, .85), (0, -.53, .82), (0, -.51, .86)], .012, 'brass')
    b.cylinder('ink', (0, -.53, .83), (-.08, -.53, .72), .005, 4)
    b.cylinder('ink', (0, -.53, .83), (.08, -.53, .72), .005, 4)
    b.box('wood', (0, -.53, .62), (.22, .2, .2), .012)
    b.box('wood_dark', (0, -.635, .62), (.23, .01, .04), 0)
    b.finish()


def robot_tender():
    """Tender, the maintenance helper: a low wide cream body with a teal top, a brass handle and a sprig of clover,
    folding mitten arms and four wheels."""
    rng = random.Random(29215)
    b = k.Batch(rng)
    wheelbase(b, four_wheels(.24, .17, .09), (.5, .42))
    b.sphere('cream', (0, 0, .38), .34, 2, (1.05, .95, .78))
    h.torus('Tender band', (0, 0, .25), .3, .035, 'teal')
    s.dome('Tender top', (0, .02, .52), .24, .1, 'teal', 20, 8)
    h.curve('Tender handle', [(-.1, .05, .58), (-.06, .05, .68), (.06, .05, .68), (.1, .05, .58)], .02, 'brass')
    s.spark_face(b, (0, -.31, .4), .14, (0, -1))
    for side in (-1, 1):
        mitten_arm(b, (side * .33, -.05, .32), (side * .42, -.15, .26), (side * .36, -.27, .22))
    for i in range(7):
        a = rng.uniform(0, math.tau)
        b.sphere('leaf' if i % 2 else 'leaf_light', (.12 + math.cos(a) * .08, .12 + math.sin(a) * .06, .62 + rng.uniform(0, .04)), .05, 1)
    for i in range(2):
        b.sphere('flower_white', (.1 + i * .06, .1, .67), .025, 1)
    b.finish()


def robot_tally():
    """Tally, the trading assistant: a cream capsule under a teal cap on two big wheels and a caster, brass ear
    discs, a till drawer, and a brass tray of coins and a receipt held out in front."""
    rng = random.Random(29216)
    b = k.Batch(rng)
    for name, at, r, w in (('wheel_l', (-.28, 0, .16), .16, .08), ('wheel_r', (.28, 0, .16), .16, .08), ('wheel_c', (0, .18, .06), .06, .04)):
        s.wheel(name, at, r, w)
    b.cylinder('iron', (-.3, 0, .16), (.3, 0, .16), .02, 6)
    b.cylinder('cream', (0, 0, .2), (0, 0, .8), .25, 20)
    s.dome('Tally cap', (0, 0, .8), .26, .14, 'teal', 20, 8)
    h.torus('Tally cap rim', (0, 0, .8), .26, .02, 'brass')
    b.sphere('brass', (0, 0, .97), .05, 1)
    s.spark_face(b, (0, -.25, .63), .14, (0, -1))
    for side in (-1, 1):
        h.cylinder('Tally ear', (side * .26, 0, .63), .08, .04, 'brass', 16).rotation_euler = (0, math.pi / 2, 0)
    b.box('teal', (0, -.235, .33), (.26, .04, .12), .01)
    b.sphere('brass', (0, -.26, .33), .02, 1)
    for side in (-1, 1):
        mitten_arm(b, (side * .25, -.03, .5), (side * .26, -.18, .44), (side * .16, -.3, .45))
    b.box('brass', (0, -.36, .44), (.42, .2, .02), .005)
    for side in (-1, 1):
        b.box('brass', (side * .2, -.36, .47), (.02, .2, .05), .003)
    for i in range(5):
        b.cylinder('gold', (-.12 + i * .05, -.36, .455), (-.12 + i * .05, -.36, .47 + (i % 2) * .015), .025, 10)
    b.box('paper', (.12, -.36, .46), (.08, .12, .005), 0, (0, 0, .3))
    b.finish()


ASSETS = {'square-banner-lamp': banner_lamp, 'square-flower-stall': flower_stall, 'square-fruit-stall': fruit_stall,
          'square-tree-planter': tree_planter, 'square-timber-store': timber_store,
          'robot-pip': robot_pip, 'robot-trowel': robot_trowel, 'robot-wick': robot_wick, 'robot-heron': robot_heron,
          'robot-tender': robot_tender, 'robot-tally': robot_tally}
for asset in s.selected(list(ASSETS)):
    s.begin(asset)
    ASSETS[asset]()
    s.save(asset, RECORD, keep_separate=('cloth', 'banner_emblem', 'wheel'))
