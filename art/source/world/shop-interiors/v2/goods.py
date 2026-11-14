"""Small goods shared by the shop interiors and their shop windows: bread and pastry, fruit and vegetables, cloth.
Each function draws one item into a `Parts` at a point; nothing here saves a file."""
import math
import random

from mathutils import Matrix, Vector

import interior_kit as s
from interior_kit import ball, box, lathe, rod, soft, torus, tube

R = random.Random(20261112)


# --- bread ----------------------------------------------------------------------------------------------------------
def boule(p, at, r=.12, colour='crust', score='crumb', turn=0.0, h=.6):
    """A round country loaf with a cross or a wheat-ear score."""
    x, y, z = at
    prof = [(0, 0), (r * .86, 0), (r, r * h * .3), (r * .92, r * h * .7), (r * .6, r * h * .98), (0, r * h * 1.08)]
    lathe(p, colour, prof, (x, y, z), 18, True, cap0=False)
    top = z + r * h * 1.02
    for a in (turn, turn + math.pi / 2):
        d = Vector((math.cos(a), math.sin(a), 0)) * r * .55
        tube(p, score + '/f', [(x - d.x, y - d.y, top - r * h * .2), (x, y, top + .004), (x + d.x, y + d.y, top - r * h * .2)],
             r * .07, 5)


def batard(p, at, length=.34, r=.08, colour='crust_light', score='crumb', angle=0.0, scores=3):
    """An oval loaf with diagonal slashes."""
    x, y, z = at
    rot = Matrix.Rotation(angle, 3, 'Z') @ Matrix.Rotation(math.pi / 2, 3, 'Y')
    prof = [(0, -length / 2), (r * .6, -length / 2 + r * .25), (r * .95, -length / 4), (r, 0), (r * .95, length / 4),
            (r * .6, length / 2 - r * .25), (0, length / 2)]
    lathe(p, colour, prof, (x, y, z + r * .78), 14, True, squash=(.78, 1), axis=rot)
    for i in range(scores):
        t = (i - (scores - 1) / 2) * length / (scores + 1)
        along = Vector((math.cos(angle), math.sin(angle), 0))
        side = Vector((-along.y, along.x, 0))
        c = Vector((x, y, z + r * 1.55)) + along * t
        a = c - along * r * .45 - side * r * .3
        b = c + along * r * .45 + side * r * .3
        tube(p, score + '/f', [tuple(a), tuple(c + Vector((0, 0, .006))), tuple(b)], r * .12, 4)


def baguette(p, a, b, r=.032, colour='crust_light', score='crumb'):
    a, b = Vector(a), Vector(b)
    along = (b - a)
    n = 9
    pts = [a + along * (i / n) for i in range(n + 1)]
    radii = [r * (.55 + .45 * math.sin(math.pi * min(1, max(0, i / n * 1.08 - .04)))) for i in range(n + 1)]
    s.tube(p, colour, [tuple(q) for q in pts], r, 8, radii=radii)
    up = Vector((0, 0, 1))
    side = along.normalized().cross(up).normalized() if abs(along.normalized().z) < .95 else Vector((1, 0, 0))
    for i in range(4):
        c = a + along * (.2 + .2 * i)
        top = c + up * r * .92 if abs(along.normalized().z) < .95 else c + side * r * .92
        d = along.normalized() * .05
        s.tube(p, score + '/f', [tuple(top - d - side * .01), tuple(top + d + side * .01)], r * .16, 4)


def tin_loaf(p, at, length=.28, w=.15, colour='crust', top='crust_dark', angle=0.0):
    x, y, z = at
    with p.placed((x, y, z), math.degrees(angle)):
        soft(p, colour, (0, 0, .055), (length, w, .11), .025)
        s.lathe(p, top, [(0, -length / 2 + .01), (w * .5, -length / 2 + .03), (w * .55, 0), (w * .5, length / 2 - .03),
                         (0, length / 2 - .01)], (0, 0, .1), 14, True, squash=(1, .5),
                axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))


def plait(p, at, length=.36, r=.03, colour='glaze', angle=0.0, seeds=True):
    """A three-strand plaited loaf, glazed, with sesame on top."""
    x, y, z = at
    with p.placed((x, y, z), math.degrees(angle)):
        for strand in range(3):
            pts, radii = [], []
            for i in range(17):
                t = i / 16
                u = -length / 2 + t * length
                ph = t * math.pi * 4 + strand * math.tau / 3
                taper = .55 + .45 * math.sin(math.pi * t)
                pts.append((u, math.sin(ph) * r * 1.1 * taper, r * 1.15 + math.cos(ph) * r * .55 * taper))
                radii.append(r * taper)
            s.tube(p, colour, pts, r, 7, radii=radii)
        if seeds:
            for i in range(10):
                u = -length * .35 + i * length * .07
                ball(p, 'sesame/f', (u, (i % 3 - 1) * r * .5, r * 2.1), .006)


def croissant(p, at, size=.07, colour='glaze', angle=0.0):
    x, y, z = at
    pts, radii = [], []
    for i in range(11):
        t = i / 10
        a = math.pi * (.15 + .7 * t)
        pts.append((math.cos(a) * size * 1.3, -math.sin(a) * size * .7 + size * .4, size * .42))
        radii.append(size * (.18 + .38 * math.sin(math.pi * t)))
    with p.placed((x, y, z), math.degrees(angle)):
        s.tube(p, colour, pts, size * .4, 8, radii=radii)
        for i in range(2, 9, 2):
            t = i / 10
            a = math.pi * (.15 + .7 * t)
            c = Vector((math.cos(a) * size * 1.3, -math.sin(a) * size * .7 + size * .4, size * .42))
            rr = size * (.18 + .38 * math.sin(math.pi * t)) * 1.02
            s.torus(p, 'crust/f', tuple(c), rr, rr * .12, normal=(-math.sin(a), -math.cos(a) * .55, 0), seg=10, n=4)


def bun(p, at, r=.05, colour='glaze', topping=None):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .9, 0), (r, r * .35), (r * .7, r * .8), (0, r * .95)], (x, y, z), 12, True, cap0=False)
    if topping == 'seeds':
        for i in range(7):
            a = i * 2.4
            ball(p, 'sesame/f', (x + math.cos(a) * r * .4, y + math.sin(a) * r * .4, z + r * .9), .006)
    elif topping == 'icing':
        s.lathe(p, 'icing', [(0, r * .7), (r * .75, r * .62), (r * .5, r * .9), (0, r * 1.0)], (x, y, z), 12, True, cap0=False)
        ball(p, 'cherry/f', (x, y, z + r * 1.05), r * .22)
    elif topping == 'swirl':
        pts = [(x + math.cos(t) * r * .12 * t, y + math.sin(t) * r * .12 * t, z + r * .92 - t * .002) for t in [i * .5 for i in range(14)]]
        s.tube(p, 'chocolate_light/f', pts, r * .08, 4)


def cake(p, at, r=.16, tiers=1, sponge='crumb', icing='icing', fruit='strawberry', drip=None, roses=None):
    x, y, z = at
    zz = z
    for t in range(tiers):
        rr = r * (1 - t * .28)
        h = rr * .7
        s.lathe(p, icing, [(rr, 0), (rr, h), (rr * .97, h + .008), (0, h + .01)], (x, y, zz), 24, True, cap0=True)
        if drip:
            for i in range(12):
                a = i * math.tau / 12
                ln = h * (.25 + .2 * ((i * 7) % 3))
                s.rod(p, drip + '/f', (x + math.cos(a) * rr * 1.01, y + math.sin(a) * rr * 1.01, zz + h),
                      (x + math.cos(a) * rr * 1.01, y + math.sin(a) * rr * 1.01, zz + h - ln), .012, 5)
            s.lathe(p, drip, [(rr * 1.01, h - .01), (rr * 1.01, h + .006), (0, h + .014)], (x, y, zz), 24, True, cap0=False)
        torus(p, 'whip/f', (x, y, zz + .01), rr, .014, seg=24, n=5)
        if t == tiers - 1 or roses:
            for i in range(10 if t == tiers - 1 else 6):
                a = i * math.tau / (10 if t == tiers - 1 else 6)
                ball(p, 'whip/f', (x + math.cos(a) * rr * .82, y + math.sin(a) * rr * .82, zz + h + .02), .02)
                if fruit and (t == tiers - 1):
                    ball(p, fruit + '/f', (x + math.cos(a) * rr * .82, y + math.sin(a) * rr * .82, zz + h + .045), .018, (1, 1, 1.2))
        if roses and t < tiers - 1:
            for i in range(3):
                a = .4 + i * .5
                ball(p, roses + '/f', (x + math.cos(a) * rr, y - math.sin(a) * rr * .2 - rr * .9, zz + h * .7), .025)
        zz += h + .01
    return zz


def tart(p, at, r=.1, filling='strawberry', crust='crust_light'):
    x, y, z = at
    s.lathe(p, crust, [(r * .9, 0), (r, .03), (r * 1.02, .035), (r * .9, .035), (r * .9, .02), (0, .02)], (x, y, z), 20, True,
            cap0=True, cap1=False, ripple=lambda a, zz: 1 + .04 * math.cos(a * 18))
    s.lathe(p, 'whip', [(r * .88, .02), (r * .86, .03), (0, .03)], (x, y, z), 20, True, cap0=False)
    count = 9 if r > .08 else 5
    for i in range(count):
        a = i * math.tau / count
        ball(p, filling + '/f', (x + math.cos(a) * r * .55, y + math.sin(a) * r * .55, z + .04), r * .17, (1, 1, .8))
    ball(p, filling + '/f', (x, y, z + .045), r * .2)


def macaron(p, at, r=.022, colour='mac_pink'):
    x, y, z = at
    s.lathe(p, colour + '/f', [(0, 0), (r * .95, 0), (r, r * .25), (0, r * .4)], (x, y, z), 10, True, cap0=False)
    s.rod(p, 'whip/f', (x, y, z + r * .38), (x, y, z + r * .55), r * .85, 10)
    s.lathe(p, colour + '/f', [(0, r * .55), (r, r * .65), (r * .95, r * .85), (0, r * 1.0)], (x, y, z), 10, True, cap0=False)


def cupcake(p, at, r=.04, case='mac_pink', icing='icing_pink', top='cherry'):
    x, y, z = at
    s.lathe(p, case, [(r * .75, 0), (r, r * 1.0)], (x, y, z), 12, True, cap0=True, cap1=False,
            ripple=lambda a, zz: 1 + .06 * math.cos(a * 12))
    s.lathe(p, 'crumb/f', [(r, r), (r * 1.05, r * 1.15), (0, r * 1.2)], (x, y, z), 12, True, cap0=False)
    pts = []
    for i in range(22):
        t = i / 21
        a = t * math.tau * 2.4
        rr = r * (.95 - .8 * t)
        pts.append((x + math.cos(a) * rr, y + math.sin(a) * rr, z + r * 1.2 + t * r * .9))
    s.tube(p, icing, pts, r * .28, 6)
    if top:
        ball(p, top + '/f', (x, y, z + r * 2.2), r * .22)


def cookie(p, at, r=.035, colour='crust_light', chips='chocolate'):
    x, y, z = at
    s.rod(p, colour + '/f', (x, y, z), (x, y, z + .012), r, 10)
    for i in range(4):
        a = i * 1.7
        ball(p, chips + '/f', (x + math.cos(a) * r * .5, y + math.sin(a) * r * .5, z + .013), .006)


def pretzel(p, at, size=.09, colour='crust_dark', angle=0.0, salt=True):
    x, y, z = at
    pts = []
    for i in range(41):
        t = i / 40 * math.tau
        # A pretzel knot: a cardioid lobe pair crossing in the middle
        px = math.sin(t) * (1 + .25 * math.cos(t)) * size
        py = (math.cos(t) * .8 - .35 * math.cos(2 * t)) * size
        pz = .015 * math.sin(2 * t)
        pts.append((px, py, pz))
    with p.placed((x, y, z + size * .2), math.degrees(angle)):
        s.tube(p, colour, pts, size * .16, 8, closed=True)
        if salt:
            for i in range(0, 40, 5):
                ball(p, 'white/f', (pts[i][0], pts[i][1], pts[i][2] + size * .15), .005)


def doily(p, at, r=.12):
    """A paper doily lying 4 mm above the surface at `at` (clear of its plane)."""
    x, y, z = at
    z += .004
    s.lathe(p, 'white/f', [(0, 0), (r, 0), (r, .002), (0, .002)], (x, y, z), 24, False,
            ripple=lambda a, zz: 1 + .07 * math.cos(a * 16))


def cake_stand(p, at, r=.18, h=.16, plate='china', stem='china'):
    """A footed cake stand; returns the plate height."""
    x, y, z = at
    s.lathe(p, stem, [(r * .55, 0), (r * .5, .012), (r * .14, .04), (r * .1, h * .6), (r * .16, h - .01), (r * .16, h)],
            (x, y, z), 18, True)
    s.lathe(p, plate, [(r * .2, h), (r, h + .005), (r * 1.02, h + .02), (r * .96, h + .02), (0, h + .012)], (x, y, z), 24, True,
            cap0=True, cap1=False)
    return z + h + .012


def cloche(p, at, r=.17, h=.22):
    x, y, z = at
    s.lathe(p, 'shops_clear_glass', [(r, 0), (r, h * .55), (r * .82, h * .85), (r * .4, h), (0, h * 1.02)], (x, y, z), 20, True,
            cap0=False)
    ball(p, 'brass', (x, y, z + h * 1.08), .025)


# --- fruit and vegetables -------------------------------------------------------------------------------------------
def apple(p, at, r=.045, colour='apple', leaf=True):
    x, y, z = at
    s.lathe(p, colour, [(0, r * .15), (r * .7, 0), (r, r * .55), (r * .9, r * 1.35), (r * .45, r * 1.62), (0, r * 1.45)],
            (x, y, z), 9, True, cap0=False)
    rod(p, 'wood_dark/f', (x, y, z + r * 1.4), (x + .006, y, z + r * 1.85), .004, 4)
    if leaf:
        s.lathe(p, 'leaf/f', [(0, 0), (r * .25, r * .3), (0, r * .75)], (x + .01, y, z + r * 1.7), 6, True,
                squash=(1, .25), axis=Matrix.Rotation(1.2, 3, 'Y'))


def orange(p, at, r=.05, colour='orange'):
    x, y, z = at
    ball(p, colour, (x, y, z + r * .95), r, (1, 1, .94))
    ball(p, 'leaf_dark/f', (x, y, z + r * 1.86), r * .15, (1, 1, .4))


def lemon(p, at, r=.04, colour='lemon', angle=0.0):
    x, y, z = at
    rot = Matrix.Rotation(angle, 3, 'Z') @ Matrix.Rotation(math.pi / 2, 3, 'Y')
    s.lathe(p, colour, [(0, -r * 1.5), (r * .3, -r * 1.25), (r * .9, -r * .55), (r, 0), (r * .9, r * .55), (r * .3, r * 1.25),
                        (0, r * 1.5)], (x, y, z + r * .9), 9, True, axis=rot)


def pear(p, at, r=.045, colour='pear'):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .8, r * .1), (r, r * .7), (r * .75, r * 1.25), (r * .45, r * 1.7), (r * .3, r * 2.0),
                        (0, r * 2.1)], (x, y, z), 9, True, cap0=False)
    rod(p, 'wood_dark/f', (x, y, z + r * 2.05), (x + .008, y, z + r * 2.45), .004, 4)


def plum(p, at, r=.03, colour='plum'):
    x, y, z = at
    ball(p, colour, (x, y, z + r), r, (1, .92, 1.05))


def grapes(p, at, size=.09, colour='grape', angle=0.0):
    x, y, z = at
    rr = size * .16
    with p.placed((x, y, z), math.degrees(angle)):
        for row in range(5):
            count = 5 - row
            for i in range(count):
                ball(p, colour + ('/f' if size < .08 else ''), ((i - (count - 1) / 2) * rr * 1.8 + R.uniform(-.004, .004),
                                                               -row * rr * 1.5, rr * (1.6 if row % 2 else 1) + R.uniform(0, .006)), rr)
        rod(p, 'stem/f', (0, rr * 1.5, rr * 1.2), (0, rr * 2.6, rr * 1.8), .005, 4)


def banana_bunch(p, at, size=.17, colour='banana', angle=0.0):
    x, y, z = at
    with p.placed((x, y, z), math.degrees(angle)):
        for i in range(5):
            off = (i - 2) * size * .14
            pts = [(off + math.sin(t) * size * .1, -math.cos(t) * size * .4 + size * .4, size * .12 + math.sin(t) * size * .45)
                   for t in [j * math.pi / 2 / 8 for j in range(9)]]
            radii = [size * (.06 + .04 * math.sin(math.pi * j / 8)) for j in range(9)]
            s.tube(p, colour, pts, size * .08, 7, radii=radii)
        rod(p, 'stem/f', (0, size * .42, size * .1), (0, size * .5, size * .1), size * .08, 6)


def carrot_bunch(p, at, count=5, length=.17, angle=0.0):
    x, y, z = at
    with p.placed((x, y, z), math.degrees(angle)):
        for i in range(count):
            off = (i - (count - 1) / 2) * .03
            rod(p, 'carrot', (off, -length / 2, .025), (off * .4, length / 2, .03), .024, 8, rb=.006)
            for j in range(3):
                s.tube(p, 'leaf_light/f', [(off * .4, length / 2 + .005, .03),
                                           (off * .4 + (j - 1) * .02, length / 2 + .07, .05 + j * .01),
                                           (off * .4 + (j - 1) * .04, length / 2 + .14, .04)], .007, 4)
        torus(p, 'string/f', (0, length * .38, .03), .05, .004, normal=(0, 1, 0), seg=12, n=4)


def cabbage(p, at, r=.09, colour='cabbage', dark='cabbage_dark'):
    x, y, z = at
    ball(p, colour, (x, y, z + r * .9), r * .85, (1, 1, .9))
    for i in range(5):
        a = i * math.tau / 5
        s.sheet(p, dark, lambda u, v, a=a: (x + math.cos(a + (u - .5) * 1.1) * r * (.6 + .45 * v),
                                             y + math.sin(a + (u - .5) * 1.1) * r * (.6 + .45 * v),
                                             z + r * (.15 + 1.0 * math.sin(math.pi * .5 * (1 - v)) * .9)), 4, 3, .006)


def cauliflower(p, at, r=.08):
    x, y, z = at
    for i in range(5):
        a = i * math.tau / 5
        s.sheet(p, 'leaf', lambda u, v, a=a: (x + math.cos(a + (u - .5) * 1.0) * r * (.5 + .7 * v),
                                              y + math.sin(a + (u - .5) * 1.0) * r * (.5 + .7 * v),
                                              z + r * (.1 + .9 * (1 - v))), 3, 3, .006)
    for i in range(9):
        a = i * 2.4
        rr = r * .45 * math.sqrt(i / 9)
        ball(p, 'cream', (x + math.cos(a) * rr, y + math.sin(a) * rr, z + r * .95 - rr * .4), r * .33)


def potato(p, at, r=.04, colour='potato'):
    x, y, z = at
    ball(p, colour, (x, y, z + r * .7), r, (1.25 + R.uniform(-.1, .1), .95, .75))


def onion(p, at, r=.04, colour='onion'):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .7, r * .12), (r, r * .8), (r * .7, r * 1.45), (r * .15, r * 1.85), (0, r * 2.05)],
            (x, y, z), 9, True, cap0=False)


def tomato(p, at, r=.035, colour='tomato'):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .8, r * .1), (r, r * .8), (r * .75, r * 1.45), (0, r * 1.5)], (x, y, z), 9, True,
            cap0=False, ripple=lambda a, zz: 1 + .05 * math.cos(a * 5))
    for i in range(5):
        a = i * math.tau / 5
        rod(p, 'leaf/f', (x, y, z + r * 1.5), (x + math.cos(a) * r * .45, y + math.sin(a) * r * .45, z + r * 1.42), .005, 3)


def pumpkin(p, at, r=.12, colour='pumpkin'):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .8, r * .05), (r, r * .55), (r * .85, r * 1.0), (r * .2, r * 1.15), (0, r * 1.1)],
            (x, y, z), 24, True, cap0=False, ripple=lambda a, zz: 1 + .07 * math.cos(a * 8))
    rod(p, 'stem/f', (x, y, z + r * 1.05), (x + .01, y, z + r * 1.35), .018, 6, rb=.012)


def pepper(p, at, r=.035, colour='pepper'):
    x, y, z = at
    s.lathe(p, colour, [(0, 0), (r * .7, r * .2), (r, r * .9), (r * .95, r * 1.5), (r * .3, r * 1.75), (0, r * 1.7)],
            (x, y, z), 9, True, cap0=False, ripple=lambda a, zz: 1 + .1 * math.cos(a * 3))
    rod(p, 'stem/f', (x, y, z + r * 1.7), (x, y, z + r * 2.2), .006, 4)


def aubergine(p, at, r=.035, angle=0.0):
    x, y, z = at
    rot = Matrix.Rotation(angle, 3, 'Z') @ Matrix.Rotation(math.pi / 2, 3, 'Y')
    s.lathe(p, 'aubergine', [(0, -r * 2.5), (r * .8, -r * 2), (r * 1.1, -r * .6), (r * .8, r * 1.2), (r * .5, r * 2.2), (0, r * 2.4)],
            (x, y, z + r), 12, True, axis=rot)


def leek_bundle(p, at, count=4, length=.4, angle=0.0):
    x, y, z = at
    with p.placed((x, y, z), math.degrees(angle)):
        for i in range(count):
            off = (i - (count - 1) / 2) * .045
            rod(p, 'white', (-length / 2, off, .025), (0, off, .025), .02, 8)
            rod(p, 'leaf_light', (0, off, .025), (length * .25, off, .028), .021, 8)
            for j in range(3):
                s.sheet(p, 'leaf_dark', lambda u, v, j=j, off=off: (length * .25 + u * length * .3, off + (v - .5) * .05 + (j - 1) * .012 * u,
                                                                   .03 + j * .008 * u), 3, 1, .004)


def mushroom_heap(p, at, w=.3, d=.2):
    x, y, z = at
    for i in range(14):
        xx = x + R.uniform(-w / 2, w / 2) * .85
        yy = y + R.uniform(-d / 2, d / 2) * .85
        zz = z + R.uniform(0, .03)
        s.lathe(p, 'mushroom', [(0, .015), (.028, .012), (.032, .03), (0, .045)], (xx, yy, zz), 10, True, cap0=False)


def herbs_pot(p, at, r=.06, colour='herb'):
    x, y, z = at
    s.lathe(p, 'terracotta', [(r * .7, 0), (r, r * 1.3), (r * 1.1, r * 1.35), (r * 1.1, r * 1.55), (r * .95, r * 1.55)],
            (x, y, z), 14, True, cap1=False)
    rod(p, 'soil/f', (x, y, z + r * 1.3), (x, y, z + r * 1.4), r * .95, 12)
    for i in range(9):
        a = i * 2.4
        h = r * (1.6 + (i % 3) * .5)
        tip = (x + math.cos(a) * r * .9, y + math.sin(a) * r * .9, z + r * 1.4 + h)
        s.tube(p, 'stem/f', [(x + math.cos(a) * r * .2, y + math.sin(a) * r * .2, z + r * 1.4), tip], .004, 3)
        ball(p, colour + '/f', tip, r * .32, (1, 1, .6))


def flower_bunch(p, at, h=.45, colour='flower_pink', count=7, spread=.09):
    x, y, z = at
    for i in range(count):
        a = i * 2.4
        rr = spread * math.sqrt((i + .5) / count)
        tip = (x + math.cos(a) * rr * 1.6, y + math.sin(a) * rr * 1.6, z + h * (.85 + .15 * ((i * 5) % 3) / 2))
        s.tube(p, 'stem/f', [(x + math.cos(a) * rr * .3, y + math.sin(a) * rr * .3, z), tip], .005, 3)
        for j in range(5):
            b = j * math.tau / 5
            ball(p, colour + '/f', (tip[0] + math.cos(b) * .018, tip[1] + math.sin(b) * .018, tip[2]), .016, (1, 1, .6))
        ball(p, 'flower_yellow/f', (tip[0], tip[1], tip[2] + .008), .009)
        if i % 2 == 0:
            s.lathe(p, 'leaf/f', [(0, 0), (.012, .03), (0, .07)], (tip[0], tip[1], tip[2] - h * .45), 5, True, squash=(1, .3),
                    axis=Matrix.Rotation(.9, 3, 'X'))


def heap(p, kind, at, w, d, layers=2, r=None):
    """A heaped crate-top of one kind of fruit or veg."""
    x, y, z = at
    maker = {'apple': (apple, .042), 'apple_green': (apple, .042), 'apple_gold': (apple, .04), 'orange': (orange, .045),
             'lemon': (lemon, .034), 'pear': (pear, .036), 'plum': (plum, .03), 'potato': (potato, .038),
             'onion': (onion, .036), 'onion_red': (onion, .034), 'tomato': (tomato, .032), 'pepper': (pepper, .032),
             'pepper_gold': (pepper, .032), 'lime': (orange, .032)}[kind]
    make, size = maker
    size = r or size
    cols = max(1, int(w / (size * 2.1)))
    rows = max(1, int(d / (size * 2.1)))
    colour = {'apple_green': 'apple_green', 'apple_gold': 'apple_gold', 'onion_red': 'onion_red', 'pepper_gold': 'pepper_gold',
              'lime': 'lime'}.get(kind)
    for layer in range(layers):
        c2, r2 = cols - layer, rows - layer
        for i in range(c2):
            for j in range(r2):
                xx = x - (c2 - 1) * size * 1.05 + i * size * 2.1 + R.uniform(-.004, .004)
                yy = y - (r2 - 1) * size * 1.05 + j * size * 2.1 + R.uniform(-.004, .004)
                zz = z + layer * size * 1.45
                kw = {}
                if colour:
                    kw['colour'] = colour
                if make in (apple,):
                    kw['leaf'] = (i + j + layer) % 4 == 0
                if make is lemon:
                    kw['angle'] = R.uniform(0, math.pi)
                make(p, (xx, yy, zz), size, **kw)
