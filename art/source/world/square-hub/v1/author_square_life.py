"""Guarded one-time authoring of the square's second set of street furniture, the pieces a working town centre uses
to make a big paved square comfortable and easy to read. Each is its own small model placed by the area document:

    town-festoon          a string of warm bulbs slung between two iron posts, 8 m apart, over the market aisle or a
                          café terrace. Origin on the ground midway between the posts; the string runs along X.
    town-signpost         a cast-iron fingerpost with four lettered arms. Its arms point the real ways from the foot
                          of Spindle Steps when placed at turn 0: Hill Street, Lantern Row, the Harbour Steps, back
                          to Spindle Lane.
    town-planter-bench    a long stone planter of low shrubs and flowers with a timber bench along its front, so a
                          seat in the open square still has something at its back. Front toward -Y.
    town-bollard-light    a short cast-iron bollard with a lit glass band, for low light along paths and edges.
    town-poster-column    a round advertising column papered with bills, a cornice and a zinc dome.
    town-coffee-cart      a coffee seller's cart: two wheels, a painted body, a brass urn, cups, a striped canopy and
                          a chalkboard. Front (the counter) toward -Y.
    town-bike-rack        four iron hoops on a stone kerb strip, 2.4 m long along X.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_square_life.py [-- ids]
    ... -- --draft .cache/square-hub/drafts [ids]

Bulbs and lit glass use the `festoon_glass` material (a warm emissive glass in its own mesh), not the game's
`lamp_glass`, so they are always lit and never counted as a lamp the robots tend.
"""
import math
import sys
from pathlib import Path

from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import author_street as street  # noqa: E402

kit = street.kit
RECORD = 'art/source/world/square-hub/v1/author_square_life.py'


def materials():
    street.grid_materials()
    kit.material('festoon_glass', 'ffd58a', roughness=.25, emission=2.4)


# --- festoon lights --------------------------------------------------------------------------------------------------
def iron_post(p, x, y, height, finial=True):
    p.cylinder('iron', (x, y, 0), (x, y, .06), .14, 12, uv='flat')
    p.cylinder('iron', (x, y, .06), (x, y, .5), .075, 10, .055, uv='flat')
    p.cylinder('iron', (x, y, .5), (x, y, height), .045, 10, .038, uv='flat')
    for z in (.5, height - .25):
        p.cylinder('iron', (x, y, z - .025), (x, y, z + .025), .07, 10, uv='flat')
    if finial:
        p.sphere('iron', (x, y, height + .06), .06, 1)
        p.cylinder('iron', (x, y, height + .1), (x, y, height + .2), .02, 6, 0, uv='flat')


def festoon(p):
    span, top, sag, bulbs = 4.0, 3.25, .5, 15
    for x in (-span, span):
        iron_post(p, x, 0, 3.45)
        inward = -1 if x > 0 else 1
        p.cylinder('iron', (x, 0, top), (x + inward * .28, 0, top), .016, 6, uv='flat')
    points = []
    for k in range(25):
        t = k / 24
        x = -span + .28 + (2 * span - .56) * t
        points.append(Vector((x, 0, top - sag * (1 - (2 * t - 1) ** 2))))
    for a, b in zip(points, points[1:]):
        p.cylinder('iron', tuple(a), tuple(b), .008, 4, uv='flat', smooth=False)
    for k in range(bulbs):
        t = (k + .5) / bulbs
        x = -span + .28 + (2 * span - .56) * t
        z = top - sag * (1 - (2 * t - 1) ** 2)
        p.cylinder('iron', (x, 0, z), (x, 0, z - .1), .006, 4, uv='flat', smooth=False)
        p.cylinder('lead', (x, 0, z - .1), (x, 0, z - .14), .022, 6, uv='flat')
        p.sphere('festoon_glass', (x, 0, z - .2), .07, 1, (1, 1, 1.25))


# --- the fingerpost --------------------------------------------------------------------------------------------------
ARMS = [('HILL STREET', 96, 2.62), ('LANTERN ROW', 33, 2.36), ('HARBOUR STEPS', -15, 2.1), ('SPINDLE LANE', 186, 1.84)]


def signpost(p):
    p.box('stone', (0, 0, .06), (.5, .5, .12), bevel=.02, uv=('blocks', 0))
    p.cylinder('canvas_green', (0, 0, .12), (0, 0, .55), .12, 12, .08, uv='flat')
    for k in range(8):
        a = math.tau * k / 8
        p.box('canvas_green', (math.cos(a) * .085, math.sin(a) * .085, .34), (.03, .03, .4), (0, 0, a), 0, 'flat')
    p.cylinder('canvas_green', (0, 0, .55), (0, 0, 2.95), .055, 10, .045, uv='flat')
    for z in (.58, 2.9):
        p.cylinder('canvas_green', (0, 0, z - .03), (0, 0, z + .03), .08, 10, uv='flat')
    p.sphere('brass', (0, 0, 3.02), .07, 1)
    for words, angle, z in ARMS:
        d = Vector((math.cos(math.radians(angle)), math.sin(math.radians(angle)), 0))
        n = Vector((-d.y, d.x, 0))
        length = .2 + .085 * len(words)
        mid = d * (.07 + length / 2)
        rot = (0, 0, math.radians(angle))
        p.box('canvas', tuple(mid + Vector((0, 0, z))), (length, .04, .19), rot, .008, 'flat')
        p.box('canvas_green', tuple(mid + Vector((0, 0, z + .105))), (length, .05, .025), rot, 0, 'flat')
        p.box('canvas_green', tuple(mid + Vector((0, 0, z - .105))), (length, .05, .025), rot, 0, 'flat')
        tip = d * (.07 + length) + Vector((0, 0, z))
        p.add('canvas', [tuple(tip + n * .021 + Vector((0, 0, -.095))), tuple(tip + d * .14 + n * .021 + Vector((0, 0, 0))),
                         tuple(tip + n * .021 + Vector((0, 0, .095)))], [(0, 1, 2)], [[(0, 0)] * 3])
        p.add('canvas', [tuple(tip - n * .021 + Vector((0, 0, -.095))), tuple(tip - n * .021 + Vector((0, 0, .095))),
                         tuple(tip + d * .14 - n * .021 + Vector((0, 0, 0)))], [(0, 1, 2)], [[(0, 0)] * 3])
        p.add('canvas', [tuple(tip + n * .021 + Vector((0, 0, .095))), tuple(tip + d * .14 + n * .021),
                         tuple(tip + d * .14 - n * .021), tuple(tip - n * .021 + Vector((0, 0, .095)))], [(0, 1, 2, 3)], [[(0, 0)] * 4])
        p.add('canvas', [tuple(tip + n * .021 + Vector((0, 0, -.095))), tuple(tip - n * .021 + Vector((0, 0, -.095))),
                         tuple(tip + d * .14 - n * .021), tuple(tip + d * .14 + n * .021)], [(0, 1, 2, 3)], [[(0, 0)] * 4])
        # Lettering on both faces.
        for face in (n, -n):
            at = mid + d * .02 + face * .022 + Vector((0, 0, z))
            kit.text(p, 'ink', words, kit.facing_text(at.x, at.y, at.z, (face.x, face.y)), .1)


# --- planter bench ---------------------------------------------------------------------------------------------------
def planter_bench(p):
    length, depth, height = 3.4, .9, .7
    p.box('stone', (0, 0, height / 2), (length, depth, height), bevel=.03, segments=2, uv=('blocks', 0))
    p.box('stone', (0, 0, height + .04), (length + .1, depth + .1, .08), bevel=.02, uv=('blocks', 0))
    p.box('soil', (0, 0, height + .07), (length - .2, depth - .2, .04), bevel=0, uv='flat')
    rng = p.rng
    for k in range(9):
        x = -length / 2 + .35 + k * (length - .7) / 8
        r = rng.uniform(.26, .34)
        p.sphere(('leaf', 'leaf_dark', 'leaf_light')[k % 3], (x, rng.uniform(-.08, .08), height + .1 + r * .8), r, 2, (1, 1, .9))
    for k in range(12):
        x = rng.uniform(-length / 2 + .25, length / 2 - .25)
        y = rng.choice((-.3, .3)) + rng.uniform(-.05, .05)
        p.sphere(('flower_white', 'flower_pink', 'flower_yellow', 'flower_violet')[k % 4], (x, y, height + .32 + rng.uniform(0, .25)), .05, 1)
    for k in range(3):
        x = -1.1 + k * 1.1
        p.sphere('cypress', (x, 0, height + .7), .2, 2, (1, 1, 2.6))
    # The bench along the front: iron brackets off the planter, timber slats, the planter's face as its back with a rail.
    face = -depth / 2
    for x in (-1.35, 0, 1.35):
        p.box('iron', (x, face - .22, .2), (.05, .05, .4), bevel=0, uv='flat')
        p.box('iron', (x, face - .2, .4), (.05, .44, .04), bevel=0, uv='flat')
    for k in range(4):
        p.box('timber', (0, face - .4 + k * .1, .44), (length - .1, .085, .04), bevel=.008, uv='local')
    for k in range(2):
        p.box('timber', (0, face - .03, .58 + k * .12), (length - .1, .04, .085), bevel=.008, uv='local')


# --- bollard light ---------------------------------------------------------------------------------------------------
def bollard_light(p):
    p.cylinder('canvas_green', (0, 0, 0), (0, 0, .08), .14, 12, uv='flat')
    p.cylinder('canvas_green', (0, 0, .08), (0, 0, .66), .09, 12, .08, uv='flat')
    p.cylinder('canvas_green', (0, 0, .64), (0, 0, .7), .11, 12, uv='flat')
    p.cylinder('festoon_glass', (0, 0, .7), (0, 0, .86), .085, 12, uv='flat')
    for k in range(4):
        a = math.tau * k / 4 + math.pi / 4
        p.box('canvas_green', (math.cos(a) * .088, math.sin(a) * .088, .78), (.022, .022, .16), (0, 0, a), 0, 'flat')
    p.cylinder('canvas_green', (0, 0, .86), (0, 0, .92), .12, 12, .1, uv='flat')
    p.sphere('canvas_green', (0, 0, .95), .07, 1, (1, 1, .7))


# --- poster column ---------------------------------------------------------------------------------------------------
BILLS = [('canvas', 'enamel_red', 'BAND TONIGHT'), ('linen', 'cloth_blue', 'TIDE FAIR'), ('cloth_ochre', 'ink', 'LECTURE'),
         ('canvas', 'canvas_green', 'GARDEN SHOW'), ('cloth_rose', 'ink', 'DANCE'), ('linen', 'enamel_red', 'CIRCUS')]


def bill(p, mat, radius, angle, width, z0, z1, steps=4):
    """A bill pasted round a column: a strip of quads following the curve, centred on `angle`, `width` wide."""
    half = width / 2 / radius
    pts = [angle - half + 2 * half * i / steps for i in range(steps + 1)]
    for a0, a1 in zip(pts, pts[1:]):
        q0, q1 = (math.cos(a0) * radius, math.sin(a0) * radius), (math.cos(a1) * radius, math.sin(a1) * radius)
        p.add(mat, [(q0[0], q0[1], z0), (q1[0], q1[1], z0), (q1[0], q1[1], z1), (q0[0], q0[1], z1)], [(0, 1, 2, 3)], [[(0, 0)] * 4])


def poster_column(p):
    r = .5
    p.cylinder('stone', (0, 0, 0), (0, 0, .25), r + .14, 18, r + .1, uv=('blocks', 0))
    p.cylinder('canvas_green', (0, 0, .25), (0, 0, .32), r + .05, 18, uv='flat')
    p.cylinder('canvas_green', (0, 0, .32), (0, 0, 2.4), r, 18, uv='flat')
    rng = p.rng
    for k, (paper, ink, words) in enumerate(BILLS):
        a = math.tau * k / len(BILLS) + .2
        out = Vector((math.cos(a), math.sin(a), 0))
        rot = (0, 0, a + math.pi / 2)
        z = rng.uniform(1.4, 1.6)
        bill(p, paper, r + .008, a, .5, z - .4, z + .4)
        c = out * (r + .012)
        p.box(ink, tuple(c + Vector((0, 0, z + .26))), (.26, .006, .09), rot, 0, 'flat')
        for j in range(3):
            p.box('ink', tuple(c + Vector((0, 0, z - .12 - j * .07))), (.24 - j * .05, .006, .022), rot, 0, 'flat')
        at = c + out * .006 + Vector((0, 0, z + .07))
        kit.text(p, ink, words, kit.facing_text(at.x, at.y, at.z, (out.x, out.y)), .055 if len(words) < 10 else .045)
        # A second row of older bills lower down, overlapping the joins.
        b = a + math.pi / len(BILLS)
        bill(p, ('cloth_ochre', 'canvas', 'cloth_blue', 'flower_yellow', 'linen', 'cloth_rose')[k], r + .004, b, .56,
             rng.uniform(.4, .5), rng.uniform(.98, 1.08))
        lower = Vector((math.cos(b), math.sin(b), 0)) * (r + .01)
        p.box('ink', tuple(lower + Vector((0, 0, .85))), (.22, .006, .06), (0, 0, b + math.pi / 2), 0, 'flat')
    p.cylinder('canvas_green', (0, 0, 2.4), (0, 0, 2.5), r + .08, 18, uv='flat')
    p.cylinder('canvas_green', (0, 0, 2.5), (0, 0, 2.58), r + .14, 18, uv='flat')
    profile = [(r + .1, 2.58), (r * .85, 2.78), (r * .5, 2.92), (.08, 2.98)]
    verts, faces = [], []
    segs = 18
    for rr, z in profile:
        for s in range(segs):
            a = math.tau * s / segs
            verts.append((math.cos(a) * rr, math.sin(a) * rr, z))
    for i in range(len(profile) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            faces.append((i * segs + s, i * segs + sn, (i + 1) * segs + sn, (i + 1) * segs + s))
    p.add('lead', verts, faces, [[(0, 0)] * 4 for _ in faces], True)
    p.cylinder('brass', (0, 0, 2.98), (0, 0, 3.12), .025, 8, uv='flat')
    p.sphere('brass', (0, 0, 3.17), .06, 1)


# --- coffee cart -----------------------------------------------------------------------------------------------------
def wheel(p, x, y, r):
    p.cylinder('timber', (x, y - .03, r), (x, y + .03, r), r, 18, uv='local', smooth=False)
    p.cylinder('iron', (x, y - .035, r), (x, y + .035, r), r + .02, 18, uv='flat', smooth=False)
    p.cylinder('wood_end', (x, y - .04, r), (x, y + .04, r), r - .05, 18, uv='flat', smooth=False)
    for k in range(8):
        a = math.tau * k / 8
        p.cylinder('timber', (x, y - .05, r), (x + math.cos(a) * (r - .05), y - .05, r + math.sin(a) * (r - .05)), .015, 5, uv='local')
    p.sphere('brass', (x, y - .06, r), .04, 1)


def coffee_cart(p):
    W, D = 1.5, .8
    wheel(p, -.42, D / 2 + .08, .4)
    wheel(p, -.42, -D / 2 - .08, .4)
    p.cylinder('iron', (-.42, -D / 2 - .1, .4), (-.42, D / 2 + .1, .4), .025, 6, uv='flat')
    for x in (W / 2 - .12,):
        for y in (-D / 2 + .1, D / 2 - .1):
            p.cylinder('iron', (x, y, 0), (x, y, .45), .025, 6, uv='flat')
    # The body: a painted box with panels, a timber counter, a lettered fascia.
    p.box('shutter', (0, 0, .82), (W, D, .76), bevel=.02, uv='local')
    for x in (-W / 4, W / 4):
        p.box('shutter', (x, -D / 2 - .012, .82), (W / 2 - .16, .02, .56), bevel=.008, uv='local')
        p.box('gold_leaf', (x, -D / 2 - .024, .82), (W / 2 - .22, .006, .5), bevel=0, uv='flat')
        p.box('shutter', (x, -D / 2 - .03, .82), (W / 2 - .26, .006, .46), bevel=0, uv='local')
    p.box('timber', (0, -.04, 1.23), (W + .1, D + .16, .06), bevel=.012, uv='local')
    p.box('canvas', (.33, -D / 2 - .035, 1.0), (.62, .01, .18), bevel=0, uv='flat')
    kit.text(p, 'ink', 'COFFEE', kit.facing_text(.33, -D / 2 - .042, 1.0, (0, -1)), .11)
    # Handles at the back for pushing.
    for y in (-D / 2 + .08, D / 2 - .08):
        p.cylinder('iron', (W / 2, y, 1.0), (W / 2 + .45, y, 1.05), .02, 6, uv='flat')
    p.cylinder('timber', (W / 2 + .45, -D / 2 + .05, 1.05), (W / 2 + .45, D / 2 - .05, 1.05), .03, 8, uv='local')
    # On the counter: a brass urn with a tap, cups and saucers, a sugar bowl, a tin of biscuits.
    p.cylinder('brass', (-.35, .1, 1.26), (-.35, .1, 1.62), .17, 14, .15, uv='flat')
    p.cylinder('brass', (-.35, .1, 1.62), (-.35, .1, 1.7), .1, 14, .04, uv='flat')
    p.sphere('ink', (-.35, .1, 1.73), .03, 1)
    p.cylinder('brass', (-.35, -.06, 1.34), (-.35, -.14, 1.32), .015, 6, uv='flat')
    for k in range(5):
        x, y = .05 + (k % 3) * .14, -.18 + (k // 3) * .14
        p.cylinder('canvas', (x, y, 1.26), (x, y, 1.27), .06, 10, uv='flat')
        p.cylinder('canvas', (x, y, 1.27), (x, y, 1.34), .035, 10, .042, uv='flat')
    p.cylinder('cloth_blue', (.5, .15, 1.26), (.5, .15, 1.33), .06, 10, uv='flat')
    p.box('enamel_red', (.48, -.2, 1.31), (.18, .12, .1), bevel=.008, uv='flat')
    # The canopy: four posts and a striped roof.
    for x in (-W / 2 + .05, W / 2 - .05):
        for y in (-D / 2 + .05, D / 2 - .05):
            p.cylinder('iron', (x, y, 1.26), (x, y, 2.15), .018, 6, uv='flat')
    stripes = 7
    for k in range(stripes):
        x0 = -W / 2 - .15 + (W + .3) * k / stripes
        x1 = -W / 2 - .15 + (W + .3) * (k + 1) / stripes
        mat = ('enamel_red', 'canvas')[k % 2]
        for sign in (-1, 1):
            verts = [(x0, 0, 2.32), (x1, 0, 2.32), (x1, sign * (D / 2 + .25), 2.1), (x0, sign * (D / 2 + .25), 2.1)]
            p.add(mat, verts + verts[::-1], [(0, 1, 2, 3), (4, 5, 6, 7)], [[(0, 0)] * 4, [(0, 0)] * 4])
            for j in range(2):
                cx = x0 + (x1 - x0) * (j + .5) / 2
                p.sphere(mat, (cx, sign * (D / 2 + .25), 2.06), .05, 0, (1, .4, 1))
    # A chalkboard on an A-frame by the front corner.
    for sign in (-1, 1):
        p.box('timber', (.95, -D / 2 - .45 + sign * .12, .38), (.5, .03, .76), (sign * .16, 0, 0), .006, 'local')
        p.box('ink', (.95, -D / 2 - .45 + sign * .136, .4), (.42, .006, .6), (sign * .16, 0, 0), 0, 'flat')
    kit.text(p, 'canvas', 'COFFEE 2d', kit.facing_text(.95, -D / 2 - .6, .52, (0, -1)), .06)


# --- bike rack -------------------------------------------------------------------------------------------------------
def bike_rack(p):
    p.box('stone', (0, 0, .03), (2.4, .45, .06), bevel=.012, uv=('blocks', 0))
    for k in range(4):
        x = -.9 + k * .6
        for y in (-.2, .2):
            p.cylinder('canvas_green', (x, y, .06), (x, y, .61), .022, 6, uv='flat')
        arc = [Vector((x, -.2 * math.cos(math.pi * i / 10), .61 + .2 * math.sin(math.pi * i / 10))) for i in range(11)]
        for a, b in zip(arc, arc[1:]):
            p.cylinder('canvas_green', tuple(a), tuple(b), .022, 6, uv='flat')


PIECES = {
    'town-festoon': (festoon, 'Festoon lights between two posts'),
    'town-signpost': (signpost, 'Cast-iron fingerpost'),
    'town-planter-bench': (planter_bench, 'Planter with a bench along its front'),
    'town-bollard-light': (bollard_light, 'Lit bollard'),
    'town-poster-column': (poster_column, 'Advertising column'),
    'town-coffee-cart': (coffee_cart, 'Coffee cart'),
    'town-bike-rack': (bike_rack, 'Bicycle rack'),
}

if __name__ == '__main__':
    chosen, out = kit.selected(list(PIECES))
    for index, asset in enumerate(chosen):
        make, label = PIECES[asset]
        street.FLAGS.clear()
        root = kit.begin(asset, street.PALETTE)
        materials()
        parts = kit.Parts(4400 + index)
        make(parts)
        street.finish(parts, root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, RECORD, street.PALETTE, {'reference': 'docs/concept/v0.72/art/guildhall-square.png'})
