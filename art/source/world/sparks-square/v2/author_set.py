"""One-time authoring of the Guildhall Square set, in area coordinates (content/areas/haverlund-square.json, 36 by
32 cells, x -0.5..35.5, y -0.5..31.5), after docs/concept/v0.72/art/guildhall-square.png.

The square is a terrace on the hillside, joined to the town all round rather than cut out of it: the stepped street
climbs west toward Spindle Lane between a garden terrace and the shops; past the balustrades to the south and east
the lower town's roofs fall away toward the harbour; uphill to the west and behind the guild hall more houses fill
the view. The levels and stairs drawn here are the ones the area document declares (street at x 7..9 level 0, a
flight at x 6 up to level 1 at x 3..5, a flight at x 2 up to level 2 at x 0..1, the street y 16..20); the meshes
never decide traversal.

Run with Blender: blender -b --python author_set.py. Refuses an existing master.
"""
import math
import random
import sys
from pathlib import Path
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import square_kit as s  # noqa: E402

k, h = s.k, s.h
RECORD = 'author_set.py'
LOW = -5.5          # the lower town's street, below the south and east balustrades
NW = 3.4            # the garden terrace north of the street
BEACON = Vector((20, 11, 0))
PLASTERS = ('plaster', 'salmon', 'plaster', 'cream', 'plaster', 'salmon', 'ochre_wall', 'plaster')


# --- small pieces ---------------------------------------------------------------------------------------------------
def simple_window(b, centre, width, height, facing, shutters=True, flowers=False, rng=None):
    """A window for the houses round the square: a painted pane standing just proud of its wall, a plain frame,
    a sill, and shutters; cheap, because there are hundreds of them."""
    fx, fy = facing
    across = Vector((-fy, fx, 0))
    out = Vector((fx, fy, 0))
    c = Vector(centre)
    k.pane('Town window glass', 'window_pane', tuple(c), width, height, facing, .025)

    def place(mat, off_across, off_out, z, sa, so, sz):
        p = c + across * off_across + out * off_out
        sx, sy = (sa, so) if abs(fy) > .5 else (so, sa)
        b.box(mat, (p.x, p.y, z), (sx, sy, sz), 0)
    for side in (-1, 1):
        place('white', side * (width / 2 + .03), .04, c.z, .07, .05, height + .1)
    place('white', 0, .04, c.z + height / 2 + .04, width + .14, .05, .08)
    place('limestone_pale', 0, .07, c.z - height / 2 - .04, width + .22, .12, .07)
    place('white', 0, .045, c.z, .03, .03, height)
    if shutters:
        for side in (-1, 1):
            place('shutter', side * (width / 2 + .07 + width * .24), .05, c.z, width * .46, .04, height)
    if flowers and rng is not None:
        place('wood_dark', 0, .14, c.z - height / 2 - .15, width + .06, .18, .16)
        for i in range(5):
            off = -width / 2 + (i + .5) * width / 5
            p = c + across * off + out * .16
            b.sphere(('leaf', 'flower_red', 'leaf_light', 'flower_pink', 'leaf')[i], (p.x, p.y, c.z - height / 2 - .03), .07, 1)


def house(b, rng, x0, y0, x1, y1, base, eave, faces=('S', 'E'), ridge='x', pitch=36, mat=None, door=None, chimney=True, cheap=True,
          floors=None, balcony=None):
    """One house round the square: plastered walls standing on `base`, painted windows on the faces the camera can
    see, a door, a tiled roof with its gable ends, and a chimney. Returns the ridge height."""
    mat = mat or PLASTERS[rng.randrange(len(PLASTERS))]
    b.box(mat, ((x0 + x1) / 2, (y0 + y1) / 2, (base + eave) / 2), (x1 - x0, y1 - y0, eave - base), 0)
    b.box('limestone_shade', ((x0 + x1) / 2, (y0 + y1) / 2, base + .2), (x1 - x0 + .08, y1 - y0 + .08, .4), 0)
    height = eave - base
    levels = floors or [base + 1.3 + i * 2.4 for i in range(max(1, int((height - .8) / 2.4)))]
    for face in faces:
        if face in ('S', 'N'):
            y = y0 if face == 'S' else y1
            span, start, facing = x1 - x0, x0, (0, -1 if face == 'S' else 1)
        else:
            x = x1 if face == 'E' else x0
            span, start, facing = y1 - y0, y0, (1 if face == 'E' else -1, 0)
        count = max(1, int(span / 1.6))
        for i, z in enumerate(levels):
            for j in range(count):
                u = start + span * (j + .5) / count
                if door and face == door[0] and i == 0 and j == door[1] % count:
                    continue
                at = (u, y, z) if face in ('S', 'N') else (x, u, z)
                simple_window(b, at, .72, 1.2 if z < eave - 2 else 1.0, facing, rng.random() < .75, i == 1 and rng.random() < .6, rng)
        if door and face == door[0]:
            j = door[1] % count
            u = start + span * (j + .5) / count
            out = Vector((facing[0], facing[1], 0)) * .04
            at = Vector((u, y, base + 1.05) if face in ('S', 'N') else (x, u, base + 1.05)) + out
            size = (.82, .06, 2.1) if face in ('S', 'N') else (.06, .82, 2.1)
            b.box(('teal_dark', 'shutter_dark', 'red_dark', 'plum', 'wood_dark')[rng.randrange(5)], tuple(at), size, 0)
            b.box('limestone_pale', tuple(at + out * 4 - Vector((0, 0, 1.0))), (size[0] + .3 if size[0] > .1 else .5, size[1] + .3 if size[1] > .1 else 1.1, .1), 0)
    if balcony:
        face, u, z = balcony
        if face == 'S':
            b.box('limestone_pale', (u, y0 - .3, z), (1.6, .6, .1), 0)
            for i in range(14):
                b.cylinder('iron', (u - .75 + i * .115, y0 - .58, z + .05), (u - .75 + i * .115, y0 - .58, z + .55), .01, 4)
            b.box('iron', (u, y0 - .58, z + .55), (1.6, .03, .03), 0)
            k.flower_clump(b, (u - .5, y0 - .35, z + .08), .2, rng, ('flower_red', 'flower_pink'), count=6)
        else:
            b.box('limestone_pale', (x1 + .3, u, z), (.6, 1.6, .1), 0)
            for i in range(14):
                b.cylinder('iron', (x1 + .58, u - .75 + i * .115, z + .05), (x1 + .58, u - .75 + i * .115, z + .55), .01, 4)
            b.box('iron', (x1 + .58, u, z + .55), (.03, 1.6, .03), 0)
            k.flower_clump(b, (x1 + .35, u - .5, z + .08), .2, rng, ('flower_red', 'flower_pink'), count=6)
    top = s.gable_roof(b, rng, x0, x1, y0, y1, eave, pitch, ridge, s.ROOF_RED, cheap)
    if ridge == 'x':
        s.gable_end(b, mat, 'x', x1 + .001, y0, y1, eave, top - .06, 1)
        s.gable_end(b, mat, 'x', x0 - .001, y0, y1, eave, top - .06, -1)
    else:
        s.gable_end(b, mat, 'y', y0 - .001, x0, x1, eave, top - .06, -1)
        s.gable_end(b, mat, 'y', y1 + .001, x0, x1, eave, top - .06, 1)
    if chimney:
        cx = x0 + (x1 - x0) * rng.uniform(.2, .8)
        cy = y0 + (y1 - y0) * rng.uniform(.25, .75)
        s.chimney(b, rng, cx, cy, eave + .3, top + .7, .5, ('brick', 'limestone')[rng.randrange(2)], 1 + rng.randrange(2))
    return top


def round_tree(b, rng, at, scale=1.0, blossom=False):
    x, y, z = at
    b.cylinder('bark', (x, y, z), (x + .05, y, z + 1.6 * scale), .16 * scale, 8, .11 * scale)
    for i in range(4):
        a = i * math.tau / 4 + rng.uniform(0, .6)
        b.cylinder('bark', (x, y, z + 1.3 * scale), (x + math.cos(a) * .6 * scale, y + math.sin(a) * .6 * scale, z + 2.1 * scale), .07 * scale, 6, .04 * scale)
    for i in range(13):
        a = rng.uniform(0, math.tau)
        r = rng.uniform(0, .9) * scale
        zz = z + rng.uniform(1.9, 3.0) * scale
        tone = ('leaf', 'leaf_light', 'leaf_dark', 'leaf')[i % 4] if zz < z + 2.6 * scale else ('leaf_light', 'leaf')[i % 2]
        b.sphere(tone, (x + math.cos(a) * r, y + math.sin(a) * r, zz), rng.uniform(.45, .62) * scale, 2)
    if blossom:
        for i in range(10):
            a = rng.uniform(0, math.tau)
            b.sphere('flower_pink', (x + math.cos(a) * .9 * scale, y + math.sin(a) * .9 * scale, z + rng.uniform(2.0, 3.0) * scale), .12, 1)


def balustrade(b, a, c, z, posts=1.3, flowers=None, rng=None):
    """Stone posts with caps and iron rails and bars between them, from a to c along x or y."""
    a, c = Vector((a[0], a[1], z)), Vector((c[0], c[1], z))
    along = (c - a).normalized()
    length = (c - a).length
    n = max(1, round(length / posts))
    for i in range(n + 1):
        p = a + along * length * i / n
        b.box('limestone', (p.x, p.y, z + .5), (.3, .3, 1.0), .03)
        b.box('limestone_pale', (p.x, p.y, z + 1.05), (.38, .38, .1), .02)
        b.sphere('limestone_pale', (p.x, p.y, z + 1.15), .08, 1)
        if flowers and i < n and i % 3 == 1:
            q = p + along * length / n / 2
            b.box('wood_dark', (q.x, q.y, z + 1.16), (.9 if abs(along.x) > .5 else .26, .26 if abs(along.x) > .5 else .9, .2), .02)
            k.flower_clump(b, (q.x, q.y, z + 1.28), .3, rng, flowers, count=8)
    for zz in (.25, .92):
        mid = (a + c) / 2
        b.box('iron', (mid.x, mid.y, z + zz), (length if abs(along.x) > .5 else .04, .04 if abs(along.x) > .5 else length, .04), 0)
    for i in range(int(length / .17)):
        p = a + along * (i + .5) * length / int(length / .17)
        b.cylinder('iron', (p.x, p.y, z + .25), (p.x, p.y, z + .92), .012, 4)


def conduit(b, points):
    """A brass power channel let into the paving: two brass strips either side of a dark slot, with studs."""
    for p, q in zip(points, points[1:]):
        p, q = Vector((p[0], p[1], 0)), Vector((q[0], q[1], 0))
        d = q - p
        length = d.length
        angle = math.atan2(d.y, d.x)
        side = Vector((-d.y, d.x, 0)).normalized()
        mid = (p + q) / 2
        for o in (-.09, .09):
            m = mid + side * o
            b.box('brass', (m.x, m.y, .016), (length + .1, .055, .032), .006, (0, 0, angle))
        b.box('ink', (mid.x, mid.y, .006), (length + .02, .1, .012), 0, (0, 0, angle))
        for i in range(int(length / .9)):
            m = p + d * ((i + .5) / int(length / .9))
            b.sphere('gold', (m.x, m.y, .03), .028, 1, (1, 1, .5))


def grate(b, at, angle=0.0, size=(.7, .45)):
    x, y = at
    b.box('iron', (x, y, .008), (size[0] + .08, size[1] + .08, .016), 0, (0, 0, angle))
    b.box('ink', (x, y, .012), (size[0], size[1], .012), 0, (0, 0, angle))
    for i in range(7):
        o = -size[0] / 2 + (i + .5) * size[0] / 7
        b.box('iron_light', (x + math.cos(angle) * o, y + math.sin(angle) * o, .02), (.03, size[1], .02), 0, (0, 0, angle))


def stair_flight(b, rng, x_top, y0, y1, z0, up_west=True):
    """Four limestone treads across the street from level z0 at x_top + 1 up to z0 + 1 at x_top, rising west."""
    for i in range(4):
        top = z0 + (i + 1) * .25
        xa = x_top + .5 - i * .25
        for j in range(int((y1 - y0) / .7)):
            yy = y0 + (j + .5) * (y1 - y0) / int((y1 - y0) / .7)
            b.box(('limestone_pale', 'limestone', 'limestone_warm')[(i + j) % 3], (xa - .125, yy, top - .06), (.27, (y1 - y0) / int((y1 - y0) / .7) - .02, .12), .02)
        b.box('limestone_shade', (xa - .125, (y0 + y1) / 2, (z0 + top) / 2 - .03), (.25, y1 - y0, top - z0 - .06), 0)


def pigeons(b, rng, at, count=4):
    x, y = at
    for i in range(count):
        px, py = x + rng.uniform(-.5, .5), y + rng.uniform(-.4, .4)
        a = rng.uniform(0, math.tau)
        b.sphere('pigeon', (px, py, .1), .09, 1, (1.3, .8, .8))
        b.sphere('pigeon_dark', (px + math.cos(a) * .1, py + math.sin(a) * .1, .17), .05, 1)
        b.sphere('pigeon_dark', (px - math.cos(a) * .1, py - math.sin(a) * .1, .1), .04, 1, (1.4, .6, .4))


# --- the set ---------------------------------------------------------------------------------------------------------
def square_set():
    rng = random.Random(29301)
    b = k.Batch(rng)
    k.h.material('ochre_wall', 'dcc08c')
    k.M['ochre_wall'].name = 'square_ochre_wall'
    # The square's floor: cobbles, flagged pavements before the shops, the hall and the post office.
    k.quad_surface('Square cobbles', 'cobbles', [(-.5, -.5, 35.5, 15.5), (4.4, 15.5, 35.5, 20.5), (6.5, 20.5, 35.5, 31.5)], 2, 0)
    k.quad_surface('Square pavements', 'flags', [(5.5, 1.5, 7.4, 15.5), (12.6, 22.5, 28.4, 24.7), (28.2, 22.6, 35.5, 24.7)], 3, .008)
    # The open working side to the east: grass coming up between the setts and in a few soft patches.
    k.quad_surface('Apron grass', 'grass', [(27.4, 1.2, 30.2, 3.6), (33.2, 8.0, 35.4, 11.4), (32.6, 16.2, 35.4, 19.8), (26.8, 17.6, 28.6, 19.2)], 8, .012)
    for _ in range(70):
        x, y = rng.uniform(26.5, 35.3), rng.uniform(.3, 21)
        k.flower_clump(b, (x, y, .01), .12, rng, ('flower_white', 'flower_yellow', 'leaf_light'), count=3)
    # The beacon stands on an octagon of pale setts with a brass band, inside the plain cobbles.
    for ring, apothem in enumerate((3.48, 3.78, 4.08, 4.36)):
        side = 2 * apothem * math.tan(math.pi / 8)
        for f in range(8):
            angle = f * math.pi / 4
            centre, out, along = s.face_frame(angle, apothem, (BEACON.x, BEACON.y))
            count = max(3, round(side / .38))
            for i in range(count):
                p = centre + along * (-side / 2 + side * (i + .5) / count)
                b.box(('limestone_pale', 'limestone', 'limestone_warm')[(i + ring + f) % 3], (p.x, p.y, .022), (.24, side / count - .03, .045), .018, (0, 0, angle))
    for f in range(8):
        angle = f * math.pi / 4
        centre, out, along = s.face_frame(angle, 4.56, (BEACON.x, BEACON.y))
        side = 2 * 4.56 * math.tan(math.pi / 8)
        b.box('brass', (centre.x, centre.y, .02), (.06, side + .02, .04), .006, (0, 0, angle))
    # Brass channels leave the beacon for the hall, the street, the post office, the market and the yard.
    conduit(b, [(20, 6.4), (20, 1.0)])
    conduit(b, [(23.25, 7.75), (26.0, 5.0), (29.0, 5.0)])
    conduit(b, [(15.4, 11), (10.6, 11), (10.6, 18), (7.4, 18)])
    conduit(b, [(20, 15.6), (20, 22.4)])
    conduit(b, [(23.25, 14.25), (26.8, 17.8), (26.8, 21.6), (30.5, 21.6), (30.5, 23.2)])
    conduit(b, [(24.6, 11), (29.4, 11)])
    for at, angle in (((20, .75), 0), ((29.3, 5), 0), ((7.3, 18), math.pi / 2), ((20, 22.6), 0), ((30.5, 23.4), 0), ((23.7, 7.3), math.pi / 4)):
        grate(b, at, angle)
    grate(b, (13.5, 17.5), 0, (.5, .5))
    grate(b, (27.5, 9.5), 0, (.5, .5))
    for at in ((16.3, 6.2), (25.4, 15.5), (18.0, 16.6)):
        pigeons(b, rng, at)
    for i in range(5):
        b.box('paper', (11.4 + i * .13, 5.2, .015), (.09, .2, .01), .004, (0, 0, .2 * i))
    # The stepped street: level 0 at x 7..9, a flight at x 6, level 1 at x 3..5, a flight at x 2, level 2 at x 0..1,
    # on rows y 21..25, so the houses in front of it never hide it from the camera.
    y0, y1 = 20.5, 25.5
    yc = (y0 + y1) / 2
    b.box('ashlar', (4.0, yc, .5), (3.0, 5.0, 1.0), 0)
    b.box('ashlar', (.5, yc, 1.0), (2.0, 5.0, 2.0), 0)
    for i in range(4):
        b.box('limestone', (6.0 + .125 - i * .25 + .125, y0 - .1, (i + 1) * .125), (.26, .2, (i + 1) * .25), .02)
    k.quad_surface('Street level one', 'cobbles', [(2.5, y0, 5.5, y1)], 2, 1.0)
    k.quad_surface('Street level two', 'cobbles', [(-.5, y0, 1.5, y1)], 2, 2.0)
    stair_flight(b, rng, 6, y0, y1, 0)
    stair_flight(b, rng, 2, y0, y1, 1)
    for x, z in ((5.6, 1.0), (1.6, 2.0)):
        b.box('limestone_pale', (x, yc, z - .03), (.2, 5.0, .06), .01)
    # An iron railing along the street's raised south edge, over the shops' back garden.
    for (xa, xb, z) in ((2.6, 5.45, 1.0), (-.45, 1.45, 2.0)):
        for i in range(int((xb - xa) / .16) + 1):
            x = xa + i * (xb - xa) / int((xb - xa) / .16)
            b.cylinder('iron', (x, y0 + .08, z), (x, y0 + .08, z + .85), .011, 4)
        b.box('iron', ((xa + xb) / 2, y0 + .08, z + .85), (xb - xa, .04, .04), 0)
        b.box('limestone_pale', ((xa + xb) / 2, y0 + .08, z + .03), (xb - xa + .1, .2, .06), .01)
    # The shops' back garden, behind a low wall: a fruit tree, beds, a shed, a water butt and washing.
    b.box('limestone', (4.62, 18.0, .45), (.3, 5.0, .9), .02)
    b.box('limestone_pale', (4.62, 18.0, .93), (.38, 5.06, .08), .02)
    k.quad_surface('Back garden', 'grass', [(-.5, 15.5, 4.47, 20.5)], 8, .01)
    round_tree(b, rng, (1.4, 17.4, 0), .95, True)
    for yy in (16.2, 19.2):
        b.box('soil', (2.9, yy, .08), (2.4, .8, .16), .02)
        for i in range(6):
            b.sphere(('leaf', 'leaf_light')[i % 2], (1.9 + i * .4, yy + rng.uniform(-.2, .2), .25), .14, 1)
    b.box('wood', (.6, 19.6, .75), (1.3, 1.1, 1.5), .02)
    s.gable_roof(b, rng, -.05, 1.25, 19.05, 20.15, 1.5, 30, 'x', s.ROOF_RED, True, .12)
    b.box('wood_dark', (1.26, 19.6, .7), (.04, .5, 1.1), .01)
    b.cylinder('wood_dark', (3.9, 20.0, 0), (3.9, 20.0, .8), .3, 12, .28)
    b.cylinder('water', (3.9, 20.0, .8), (3.9, 20.0, .81), .26, 12)
    for x in (.2, 3.6):
        b.box('wood_dark', (x, 16.0, .9), (.06, .06, 1.8), .01)
    k.catenary('Garden washing line', (.2, 16.0, 1.75), (3.6, 16.0, 1.75), .12, .007, 'rail')
    for i, mat in enumerate(('linen', 'cloth_blue', 'linen', 'cloth_ochre')):
        b.box(mat, (.7 + i * .78, 16.0, 1.42), (.5, .02, .55), .01)
    # The street keeps climbing west out of the square toward Spindle Lane, then turns uphill out of view.
    b.box('ashlar', (-4.0, yc, 1.0 + LOW / 2), (7.0, 5.0, 2.0 - LOW), 0)
    k.quad_surface('Street beyond', 'cobbles', [(-6.5, y0, -.5, y1)], 2, 2.0)
    stair_flight(b, rng, -7, y0, y1, 2)
    b.box('limestone_shade', (-9.0, yc + .5, (LOW + 3.0) / 2), (3.0, 6.0, 3.0 - LOW), 0)
    k.quad_surface('Street landing beyond', 'cobbles', [(-10.5, y0, -7.5, y1 + 1)], 2, 3.0)
    for i in range(4):
        top = 3.0 + (i + 1) * .25
        b.box(('limestone_pale', 'limestone')[i % 2], (-9.0, y1 + 1 + i * .25 + .125, top - .06), (3.0, .27, .12), .02)
    b.box('limestone_shade', (-9.0, y1 + 4.5, 2.0), (3.0, 6.0, 4.0), 0)
    k.quad_surface('Street uphill', 'cobbles', [(-10.5, y1 + 2, -7.5, y1 + 7.5)], 2, 4.0)
    for x in (-3.0, -8.2):
        b.box('iron', (x, y0 + .3, 2.0 + 1.6 + (x < -7)), (.08, .08, 3.2), 0)
        h.cylinder('Street lamp glass', (x, y0 + .3, 2.0 + 3.35 + (x < -7)), .1, .3, 'lamp_glass', 6)
        b.cylinder('iron', (x, y0 + .3, 2.0 + 3.5 + (x < -7)), (x, y0 + .3, 2.0 + 3.65 + (x < -7)), .15, 6, .03)
    # The garden terrace north of the street: a retaining wall with a railing, a lawn, paths, trees and houses.
    T = y1
    k.wall('Terrace retaining wall', 'ashlar', (-7.5, T), (12.5, T), LOW, NW, .4)
    k.wall('Terrace east wall', 'ashlar', (12.5, T), (12.5, 37.0), 0, NW, .4)
    b.box('limestone_pale', (2.5, T + .2, NW + .06), (20.2, .5, .12), .02)
    b.box('limestone_pale', (12.7, (T + 37) / 2, NW + .06), (.5, 37 - T, .12), .02)
    balustrade(b, (-7.4, T + .25), (12.4, T + .25), NW + .1, 1.4)
    balustrade(b, (12.75, T + .2), (12.75, 31.5), NW + .1, 1.4)
    b.box('limestone_shade', (1.0, (T + 37) / 2, NW / 2), (23.0, 37 - T, NW), 0)
    k.quad_surface('Terrace lawn', 'grass', [(-7.5, T + .5, 12.5, T + 3.9)], 8, NW + .01)
    k.quad_surface('Terrace path', 'flags', [(-7.5, T + 1.8, 12.5, T + 2.6)], 3, NW + .02)
    for x in (-5.5, -.5, 4.5, 9.5):
        round_tree(b, rng, (x, T + 1.2, NW), 1.05, x == 4.5)
    for x in range(-7, 12, 2):
        k.flower_clump(b, (x + .5, T + 3.6, NW), .35, rng, ('flower_pink', 'flower_white', 'flower_violet', 'flower_yellow'), count=8)
    # Ivy hangs over the retaining wall; a gate and steps up to the terrace from the square stay shut.
    for x in (-3.0, 3.6, 9.2):
        s.ivy(b, rng, [(x, T - .05, NW + .1), (x + .3, T - .05, NW - 1.0), (x - .2, T - .05, NW - 1.9)], .25, (0, -1), 10, .12)
    # Steps climb the face of the retaining wall from the square to a shut gate on the terrace.
    for i in range(10):
        top = (i + 1) * NW / 10
        b.box(('limestone_pale', 'limestone')[i % 2], (12.25 - i * .35, T - .28, top / 2), (.36, .56, top), .02)
    for i in range(9):
        b.cylinder('iron', (12.4 - i * .4, T - .54, (i + 1) * NW / 10 + .05), (12.4 - i * .4, T - .54, (i + 1) * NW / 10 + .95), .015, 4)
    h.curve('Step handrail', [(12.4, T - .54, NW / 10 + .95), (10.6, T - .54, NW * .55 + .95), (8.9, T - .54, NW + .95)], .022, 'iron')
    for i in range(7):
        b.cylinder('iron', (8.75, T - .55 + i * .09, NW), (8.75, T - .55 + i * .09, NW + 1.0), .012, 4)
    b.box('iron', (8.75, T - .28, NW + 1.0), (.05, .6, .05), 0)
    # Houses on the terrace face the square over their gardens.
    for (x0, x1, eave, mat, door) in ((-7.4, -2.6, NW + 6.0, 'salmon', ('S', 1)), (-2.6, 2.6, NW + 6.6, 'plaster', ('S', 2)), (2.6, 7.4, NW + 5.6, 'ochre_wall', ('S', 0)),
                                      (7.4, 12.3, NW + 6.2, 'plaster', ('S', 1))):
        house(b, rng, x0, T + 4.1, x1, T + 10.5, NW, eave, ('S', 'E'), 'y' if x1 - x0 < 5 else 'x', 38, mat, door, True, False, balcony=('S', (x0 + x1) / 2, NW + 3.4))
    # The lower town: a retaining wall drops from the south and east balustrades to a street below, lined with
    # houses whose roofs come up to the square's edge, and another row beyond.
    k.wall('South retaining wall', 'ashlar', (-.5, -.5), (35.8, -.5), LOW - .1, 0, .4)
    k.wall('Uphill retaining wall', 'ashlar', (-18.5, -.5), (-.5, -.5), LOW - .1, 1.0, .4)
    k.wall('East retaining wall', 'ashlar', (35.8, -.5), (35.8, 40.0), LOW - .1, 0, .4)
    b.box('limestone_pale', (9.6, -.42, .07), (51.2, .38, .14), .02)
    b.box('limestone_pale', (35.62, 12.0, .07), (.38, 25.0, .14), .02)
    balustrade(b, (-.4, -.4), (35.4, -.4), .14, 1.3, ('flower_pink', 'flower_red', 'flower_white', 'flower_yellow'), rng)
    b.box('limestone', (35.62, 11.0, .35), (.32, 22.6, .5), .02)
    b.box('limestone_pale', (35.62, 11.0, .63), (.42, 22.7, .08), .02)
    for i in range(int(22.6 / 1.6) + 1):
        y = -.3 + i * 1.6
        b.box('iron', (35.62, y, 1.0), (.05, .05, .75), 0)
        b.sphere('iron', (35.62, y, 1.4), .04, 1)
    for zz in (.85, 1.3):
        b.box('iron', (35.62, 11.0, zz), (.03, 22.6, .03), 0)
    for i in range(int(22.6 / .2)):
        b.cylinder('iron', (35.62, -.3 + i * .2, .67), (35.62, -.3 + i * .2, 1.3), .01, 4)
    for y in (2.0, 7.5, 13.0, 18.5):
        k.flower_clump(b, (35.15, y, .02), .35, rng, ('leaf', 'leaf_dark', 'flower_white'), count=9)
    b.box('limestone', (35.62, -.42, .7), (.6, .6, 1.4), .03)
    b.box('limestone_pale', (35.62, -.42, 1.45), (.75, .75, .12), .02)
    s.topiary(b, rng, (35.62, -.42, 1.5), .9, .24, .44)
    for x in range(-14, 36, 6):
        s.ivy(b, rng, [(x, -.95, -.2), (x + .4, -.95, -1.6), (x - .2, -.95, -2.8)], .3, (0, -1), 8, .1)
    k.quad_surface('Lower street south', 'cobbles', [(-30.0, -9.2, 44.2, -.5)], 2, LOW)
    k.quad_surface('Lower street east', 'cobbles', [(35.8, -.5, 44.2, 50.0)], 2, LOW)
    k.quad_surface('Lower town below', 'cobbles', [(-30.0, -40.0, 62.0, -9.2), (44.2, -9.2, 62.0, 50.0)], 2, LOW - 2.5)
    k.wall('Lower terrace wall south', 'ashlar', (-30.0, -9.2), (44.2, -9.2), LOW - 2.6, LOW, .3)
    k.wall('Lower terrace wall east', 'ashlar', (44.2, -9.2), (44.2, 50.0), LOW - 2.6, LOW, .3)
    x = -16.0
    while x < 35.6:
        w = rng.choice((4.4, 5.0, 5.6))
        x1 = min(x + w, 36.2)
        house(b, rng, x, -6.6, x1, -.95, LOW, LOW + rng.uniform(4.3, 4.9), ('S', 'E'), 'x', 32, None, ('S', 1), True, True, [LOW + 1.2, LOW + 3.3])
        x = x1
    y = -6.6
    while y < 40.0:
        w = rng.choice((4.4, 5.0, 5.6))
        y1 = y + w
        house(b, rng, 36.25, y, 41.9, y1, LOW, LOW + rng.uniform(4.3, 4.9) if y > -.5 else LOW + 4.0, ('S', 'E'), 'y', 32, None, ('E', 1), True, True, [LOW + 1.2, LOW + 3.3])
        y = y1
    x = -20.0
    while x < 41.0:
        w = rng.choice((4.6, 5.4, 6.0))
        house(b, rng, x, -16.5, x + w - .3, -9.6, LOW - 2.5, LOW - 2.5 + rng.uniform(4.2, 4.8), ('S', 'E', 'N'), 'x', 34, None, ('N', 1), True, True, [LOW - 1.3, LOW + .8])
        if rng.random() < .5:
            round_tree(b, rng, (x + w - .1, -8.6, LOW), .9)
        x += w
    y = -17.0
    while y < 44.0:
        w = rng.choice((4.6, 5.4, 6.0))
        house(b, rng, 44.6, y, 50.8, y + w - .3, LOW - 2.5, LOW - 2.5 + rng.uniform(4.2, 4.8), ('S', 'E', 'W'), 'y', 34, None, ('W', 1), True, True, [LOW - 1.3, LOW + .8])
        if rng.random() < .4:
            round_tree(b, rng, (43.8, y + w - .1, LOW), .85)
        y += w
    for x in range(-12, 40, 7):
        b.box('iron', (x, -7.0, LOW + 1.6), (.08, .08, 3.2), 0)
        h.cylinder('Lower lamp glass', (x, -7.0, LOW + 3.35), .1, .3, 'lamp_glass', 6)
        b.cylinder('iron', (x, -7.0, LOW + 3.5), (x, -7.0, LOW + 3.65), .15, 6, .03)
    for y in range(2, 40, 7):
        b.box('iron', (42.4, y, LOW + 1.6), (.08, .08, 3.2), 0)
        h.cylinder('Lower lamp glass', (42.4, y, LOW + 3.35), .1, .3, 'lamp_glass', 6)
        b.cylinder('iron', (42.4, y, LOW + 3.5), (42.4, y, LOW + 3.65), .15, 6, .03)
    # Uphill to the west the land rises behind the shops: taller houses climb above their roofs.
    b.box('limestone_shade', (-9.5, 10.0, (LOW + 1.0) / 2), (18.0, 21.0, 1.0 - LOW), 0)
    k.quad_surface('Uphill gardens', 'grass', [(-18.5, -.5, -.5, 20.5)], 8, 1.0)
    for (y0_, y1_, eave) in ((-.5, 5.0, 9.0), (5.0, 10.2, 9.6), (10.2, 15.4, 8.8), (15.4, 20.4, 8.4)):
        house(b, rng, -6.6, y0_, -.6, y1_, 1.0, eave, ('S', 'E'), 'y', 38, None, None, True, True)
    for (y0_, y1_, eave) in ((-.5, 5.6, 10.4), (5.6, 11.0, 10.8), (11.0, 15.4, 10.0), (15.4, 20.4, 10.6)):
        house(b, rng, -13.6, y0_, -7.4, y1_, 1.0, eave, ('S', 'E'), 'y', 38, None, None, True, True)
    for at in ((-7.0, 3.0), (-7.1, 9.0), (-14.6, 6.0), (-15.0, 13.0), (-7.0, 17.8)):
        round_tree(b, rng, (at[0], at[1], 1.0), 1.1)
    b.box('limestone_shade', (-14.5, 29.0, (LOW + 4.0) / 2), (8.0, 17.0, 4.0 - LOW), 0)
    for (y0_, y1_) in ((20.6, 26.0), (26.0, 31.4), (31.4, 36.6)):
        house(b, rng, -18.0, y0_, -11.0, y1_, 4.0, 11.5, ('S', 'E'), 'y', 38, None, ('E', 1), True, True)
    for (x0, x1) in ((-10.4, -.6), (-.6, 6.0)):
        house(b, rng, x0, 36.4, x1, 41.8, NW, NW + 5.6, ('S', 'E'), 'x', 36, None, None, True, True)
    b.box('limestone_shade', (-2.0, 39.5, NW / 2 - 1), (17.0, 5.6, NW + 2), 0)
    round_tree(b, rng, (-12.5, 19.0, 4.0), 1.0)
    # Behind the guild hall and the post office the town drops toward the harbour.
    k.quad_surface('Town behind', 'cobbles', [(12.5, 31.5, 62.0, 60.0)], 2, -1.5)
    b.box('limestone_shade', (21.0, 31.6, -.8), (30.0, .4, 1.6), 0)
    x = 13.0
    while x < 46.0:
        w = rng.choice((4.6, 5.2, 6.0))
        house(b, rng, x, 33.0, x + w - .2, 38.6, -1.5, -1.5 + rng.uniform(5.6, 6.6), ('S', 'E'), 'x', 36, None, ('S', 1), True, True)
        x += w
    x = 13.0
    while x < 46.0:
        w = rng.choice((5.0, 5.8))
        house(b, rng, x, 40.4, x + w - .2, 46.0, -3.0, -3.0 + rng.uniform(5.4, 6.2), ('S', 'E'), 'x', 36, None, None, True, True)
        x += w
    for at in ((14.0, 39.5), (27.5, 39.6), (33.0, 32.2), (20.0, 32.4)):
        round_tree(b, rng, (at[0], at[1], -1.5), 1.2)
    # A planted corner where the shops end above the south balustrade.
    b.box('limestone', (2.5, .45, .2), (5.8, .9, .4), .02)
    b.box('soil', (2.5, .45, .41), (5.5, .7, .04), 0)
    for x in range(0, 6):
        k.flower_clump(b, (x, .45, .42), .32, rng, ('flower_violet', 'flower_white', 'flower_pink', 'flower_yellow'), count=9)
    b.finish()


for asset in s.selected(['guildhall-square-set']):
    s.begin(asset)
    square_set()
    s.save(asset, RECORD)
