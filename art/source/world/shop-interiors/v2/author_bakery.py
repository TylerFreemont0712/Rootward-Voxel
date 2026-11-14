"""Morning Loaf, second pass (2026-11-12): the room and its furniture, authored as editable masters.

    blender -b --factory-startup --python author_bakery.py -- [asset-id ...]

Refuses an existing master unless it is this record's own untouched output and `--redo` is given. After adoption,
edit each model.blend and rebuild with scripts/world-art.sh build <id>.

The bakery's colours are oxblood joinery, white glazed metro tile, warm limewash, terracotta floor, copper and brass.
"""
from pathlib import Path
import math
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import interior_kit as s  # noqa: E402
import goods as g  # noqa: E402
from interior_kit import arc, ball, box, facing, lathe, rod, sheet, soft, text, torus, tube  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

RECORD = __file__
JOIN = '#oxblood'


# ------------------------------------------------------------------------------------------------- the oven
def oven():
    """Ada Kettering's oven: a brick beehive on a brick base with a log store, an arched iron mouth (the fire is lamp
    glass, so the room binds it as `oven-fire`), a copper hood and stovepipe into the chimney breast, peels, a gauge."""
    root, p, path = s.begin('bakery-oven', 'v2')
    # Base: two piers and a back block round an arched log store, a slate plinth and a limestone hearth slab.
    box(p, '@brick', (0, .18, .5), (2.9, 1.54, 1.0), .02)
    for x in (-.98, .98):
        box(p, '@brick', (x, -.79, .5), (.94, .32, 1.0), .02)
    box(p, '@brick', (0, -.79, .86), (1.02, .32, .28), .01)
    for i in range(9):
        a = math.pi * (i + .5) / 9
        box(p, 'terracotta_dark', (math.cos(a) * .56, -.96, .62 + math.sin(a) * .16), (.11, .05, .09), .01,
            rot=(0, -(a - math.pi / 2), 0))
    box(p, 'soil/f', (0, -.62, .4), (.98, .02, .74), 0)
    for row in range(4):
        for col in range(7 - row % 2):
            x = -.4 + col * .135 + (row % 2) * .067
            z = .1 + row * .118
            rod(p, 'wood_mid', (x, -.62, z), (x, -.93, z), .056, 9)
            rod(p, 'wood_end/f', (x, -.93, z), (x, -.935, z), .05, 9)
    box(p, 'slate', (0, 0, .04), (3.0, 1.95, .08), .01)
    box(p, 'limestone', (0, -.02, .975), (3.02, 1.98, .07), .015)
    # The beehive dome, laid in brick courses.
    prof = [(1.28 * math.cos(t), .98 * math.sin(t)) for t in [i * math.pi / 2 / 10 for i in range(11)]]
    lathe(p, '@brick', prof, (0, .16, 1.0), 32, True, cap0=False, squash=(1, .74))
    # The portal: brick jambs and spandrels round an arched mouth, voussoirs and a limestone keystone.
    for x in (-.5, .5):
        box(p, '@brick', (x, -.84, 1.065), (.26, .44, .13), .01)
    for side in (-1, 1):
        pts = [(side * .63, -1.06, 1.12), (side * .36, -1.06, 1.12)]
        pts += [(side * .36 * math.cos(a), -1.06, 1.12 + .36 * math.sin(a)) for a in [i * math.pi / 2 / 8 for i in range(1, 9)]]
        pts += [(0, -1.06, 1.86), (side * .63, -1.06, 1.86)]
        if side < 0:
            pts.reverse()
        p.solid(s.surface('brick'), pts, .4, (0, -1, 0))
    for i in range(11):
        a = math.pi * i / 10
        mat = 'cream' if i == 5 else 'terracotta_dark'
        box(p, mat, (math.cos(a) * .43, -1.075, 1.12 + math.sin(a) * .43), (.12, .05, .14 if i == 5 else .1), .008,
            rot=(0, -(a - math.pi / 2), 0))
    tube(p, 'iron', arc((0, -1.07, 1.12), .36, 0, math.pi, 14, 'xz'), .022, 6)
    for x in (-.36, .36):
        rod(p, 'iron', (x, -1.07, 1.12), (x, -1.07, 1.02), .022, 6)
    box(p, 'limestone', (0, -1.06, 1.06), (.86, .3, .07), .01)
    # Inside the mouth: soot, glowing fire and embers (all lamp glass, one mesh), charred logs.
    box(p, 'ink', (0, -.8, 1.3), (.72, .02, .4), 0)
    fire = [(-.33, -.83, 1.12), (.33, -.83, 1.12), (.33, -.83, 1.2)] + \
           [(.33 * math.cos(a), -.83, 1.2 + .3 * math.sin(a)) for a in [i * math.pi / 10 for i in range(1, 10)]] + [(-.33, -.83, 1.2)]
    p.solid('shops_lamp_glass', fire, .02, (0, -1, 0))
    for i, (x, h) in enumerate([(-.2, .16), (-.05, .24), (.1, .2), (.22, .13)]):
        lathe(p, 'shops_lamp_glass', [(0, 0), (.07, .02), (.03, h * .7), (0, h)], (x, -.88, 1.12), 6, True, cap0=False,
              squash=(1, .5))
    for x0, x1 in ((-.25, .2), (-.18, .26)):
        rod(p, 'crust_deep', (x0, -.93, 1.16), (x1, -.96, 1.15), .035, 7)
    # The iron door, swung open on its hinge.
    with p.placed((.42, -1.1, 0), 158):
        door = [(-.72, 0, 1.13), (0, 0, 1.13), (0, 0, 1.45)] + \
               [(-.36 + .36 * math.cos(a), 0, 1.45 + .2 * math.sin(a)) for a in [i * math.pi / 10 for i in range(1, 10)]] + [(-.72, 0, 1.45)]
        p.solid('iron', door, .035, (0, -1, 0))
        for x, z in ((-.12, 1.2), (-.6, 1.2), (-.12, 1.48), (-.6, 1.48), (-.36, 1.6)):
            ball(p, 'iron_light/f', (x, -.012, z), .014)
        rod(p, 'brass', (-.55, -.02, 1.32), (-.55, -.1, 1.32), .012, 6)
        rod(p, 'brass', (-.55, -.1, 1.28), (-.55, -.1, 1.38), .016, 8)
        for z in (1.18, 1.52):
            box(p, 'iron_light', (-.04, -.02, z), (.1, .03, .05), .004)
    # The gauge: a brass-rimmed dial over the keystone.
    lathe(p, 'brass', [(0, 0), (.095, 0), (.095, .03), (0, .03)], (0, -1.08, 1.74), 20, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    lathe(p, 'cream/f', [(0, 0), (.078, 0), (0, .001)], (0, -1.112, 1.74), 20, False, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    for i in range(7):
        a = math.radians(210 - i * 40)
        rod(p, 'ink/f', (math.cos(a) * .055, -1.115, 1.74 + math.sin(a) * .055), (math.cos(a) * .07, -1.115, 1.74 + math.sin(a) * .07), .004, 3)
    rod(p, 'enamel_red/f', (0, -1.117, 1.74), (.045, -1.117, 1.765), .005, 3)
    # Copper hood, riveted, and a stovepipe that turns back into the chimney breast.
    hood = [((-.74, -1.18), (.74, -1.18), (.74, -.52), (-.74, -.52)), ((-.24, -.84), (.24, -.84), (.24, -.56), (-.24, -.56))]
    bottom, top = hood
    verts = [(x, y, 1.92) for x, y in bottom] + [(x, y, 2.42) for x, y in top]
    faces = [(0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7), (3, 2, 1, 0)]
    p.add('copper', verts, faces, [[(0, 0)] * 4] * 6)
    box(p, 'copper_dark', (0, -.85, 1.94), (1.52, .7, .06), .01)
    for i in range(13):
        ball(p, 'brass', (-.7 + i * .1167, -1.2, 1.95), .012)
    tube(p, 'iron', [(0, -.7, 2.4), (0, -.7, 2.78), (0, -.62, 2.92), (0, -.45, 3.0), (0, .2, 3.02), (0, .5, 3.02)], .14, 14)
    torus(p, 'brass', (0, -.7, 2.62), .145, .012, seg=20, n=5)
    # The chimney breast behind, to the ceiling.
    box(p, '@brick', (0, .72, 2.55), (1.1, .5, 3.1), .02)
    box(p, 'limestone', (0, .38, 1.98), (1.4, .16, .07), .01)
    for i, (x, kind) in enumerate([(-.45, 'jar'), (-.15, 'tin'), (.2, 'jar'), (.48, 'tin')]):
        if kind == 'jar':
            s.jar(p, (x, .38, 2.015), .16, .05, 'flour' if i == 0 else 'sesame', 'copper')
        else:
            s.tin(p, (x, .38, 2.015), .14, .045, 'enamel_white' if i == 1 else 'label_red', 'oxblood')
    # Peels stand against the right of the base; a log basket, ash bucket and brush at the left.
    for i, y in enumerate((-.62, -.3, .02)):
        w = .26 + i * .04
        rod(p, '@oak', (1.6, y, .02), (1.6, y, 1.12), .02, 8)
        box(p, '@oak', (1.6, y, 1.24), (.024, w, .26), .008)
        lathe(p, '@oak', [(0, -.012), (w / 2, -.012), (w / 2, .012), (0, .012)], (1.6, y, 1.37), 16, True,
              axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    rod(p, 'brass', (1.46, -.75, 1.06), (1.46, .15, 1.06), .012, 6)
    s.basket(p, (-1.72, -.3, 0), .26, .3, True)
    for i in range(7):
        a = i * 2.4
        rod(p, 'wood_mid', (-1.72 + math.cos(a) * .12, -.3 + math.sin(a) * .1, .2), (-1.72 + math.cos(a) * .1, -.3 + math.sin(a) * .06 - .1, .5),
            .045, 7)
    lathe(p, 'zinc', [(.12, 0), (.15, .26), (.16, .27), (.155, .28)], (-1.72, -.86, 0), 18, True, cap1=False)
    lathe(p, 'iron/f', [(0, .2), (.145, .2), (0, .201)], (-1.72, -.86, 0), 18, False)
    tube(p, 'iron', arc((-1.72, -.86, .26), .15, 0, math.pi, 8, 'xz'), .006, 4)
    rod(p, '@oak', (-1.3, -1.02, .1), (-1.28, -.97, .75), .015, 6)
    box(p, 'wicker_dark', (-1.3, -1.02, .07), (.16, .05, .12), .01)
    # Maker's plaque.
    box(p, 'brass', (0, -.957, .92), (.6, .012, .1), .004)
    text(p, 'brass_dark/f', 'KETTERING 1885', facing(0, -.964, .92), .05, 'cinzel')
    box(p, 'iron', (-.98, -.958, .45), (.34, .02, .3), .006)
    rod(p, 'brass', (-.88, -.97, .5), (-.88, -1.0, .5), .012, 6)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the room
def doormat(p, colour, inner, words, size):
    """A coir doormat inside the door: base, a coloured border and a lettered field, each layer 6 mm above the last."""
    box(p, 'kraft', (6, .32, .012), (1.15, .62, .024), .01)
    box(p, colour, (6, .32, .027), (1.0, .5, .006), 0)
    box(p, inner, (6, .32, .033), (.94, .44, .006), 0)
    text(p, colour, words, s.flat_text(6, .32, .0375), size, 'cinzel')


WEST_OPEN = [(3.0, 1.7, .95, 2.85)]
NORTH_OPEN = [(5.15, 1.3, 1.05, 2.85), (10.75, 1.0, 0.0, 2.35)]


def shell():
    """Terracotta floor; white metro tile to the dado with an oxblood glazed border; limewash above; a plate rail of
    blue-and-white china; café curtains; an oxblood back door to the bakehouse; a station clock; painted lettering."""
    root, p, path = s.begin('bakery-shell', 'v2')
    s.floor(p, 'floor_terracotta', 1.6)
    for wall, openings in ((s.NORTH, NORTH_OPEN), (s.WEST, WEST_OPEN)):
        s.strip(p, '@limewash', wall, 0, s.HEIGHT, 0, -.24, openings)
        s.strip(p, JOIN, wall, 0, .15, .03, 0, openings)
        s.strip(p, '@metro', wall, .15, 1.55, .014, 0, openings, bevel=0)
        s.strip(p, 'oxblood_glaze', wall, 1.55, 1.64, .026, 0, openings)
        s.strip(p, 'cream', wall, 1.64, 1.68, .02, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.58, 3.68, .05, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.68, 3.76, .08, 0, openings)
        s.strip(p, 'oxblood', wall, 3.76, 3.8, .09, 0, openings)
    # Windows: cream sashes, oak sills; café curtains in red gingham on the side window, geraniums on the rear.
    s.window(p, s.WEST, 3.0, 1.7, .95, 2.85, '#cream_paint', '@oak', (3, 3))
    s.window(p, s.NORTH, 5.15, 1.3, 1.05, 2.85, '#cream_paint', '@oak', (2, 3))
    for c, w, top, wall in ((3.0, 1.62, 1.95, s.WEST),):
        x, y, z = s.on_wall(wall, c, .07, top)
        rod(p, 'brass', (x, y - w / 2 - .05, z), (x, y + w / 2 + .05, z), .012, 8)
        for end in (-1, 1):
            ball(p, 'brass', (x, y + end * (w / 2 + .06), z), .022)
        sheet(p, '@gingham_red', lambda u, v: (x + .015 * math.sin(u * math.pi * 22), y - w / 2 + u * w, top - .04 - v * .9),
              44, 2, .006)
        sheet(p, '@gingham_red', lambda u, v: (x + .03 + .02 * math.sin(u * math.pi * 26), y - w / 2 - .04 + u * (w + .08),
                                               2.84 - v * .26 - .03 * math.sin(u * math.pi * 3) ** 8 * 0), 52, 2, .006)
    for i, xx in enumerate((4.75, 5.15, 5.55)):
        g.herbs_pot(p, (xx, 11.42, 1.05), .07, 'geranium' if i != 1 else 'leaf_mid')
    # The back door to the bakehouse, closed: oxblood panels in a cream architrave, a brass plate and knob.
    s.wall_box(p, 'cream_paint', s.NORTH, 10.75 - .555, .02, 1.2, .13, .06, 2.4)
    s.wall_box(p, 'cream_paint', s.NORTH, 10.75 + .555, .02, 1.2, .13, .06, 2.4)
    s.wall_box(p, 'cream_paint', s.NORTH, 10.75, .02, 2.42, 1.26, .06, .14)
    s.wall_box(p, JOIN, s.NORTH, 10.75, -.1, 1.175, 1.0, .06, 2.35)
    for z, h in ((.62, .8), (1.68, .9)):
        s.panel(p, JOIN, 10.75 - .22, 11.545, z, .38, h, .05, .025, 'gold_leaf')
        s.panel(p, JOIN, 10.75 + .22, 11.545, z, .38, h, .05, .025, 'gold_leaf')
    box(p, 'brass', (10.75, 11.538, 1.18), (.3, .01, .08), .002)
    text(p, 'brass_dark/f', 'PRIVATE', facing(10.75, 11.532, 1.18), .045, 'cinzel')
    lathe(p, 'brass', [(0, 0), (.02, 0), (.012, .03), (.035, .05), (0, .07)], (11.08, 11.57, 1.05), 12, True,
          axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    # Plate rail on the west wall, over the dresser and the flour, with blue-and-white plates standing in it.
    s.wall_box(p, '@oak', s.WEST, 6.7, .07, 2.5, 4.7, .14, .035)
    s.wall_box(p, '@oak', s.WEST, 6.7, .13, 2.55, 4.7, .02, .07)
    for i in range(8):
        yy = 4.7 + i * .57
        x, y, z = s.on_wall(s.WEST, yy, .06, 2.52)
        with p.placed((x, y, z), 90):
            s.plate(p, (0, 0, 0), .15 if i % 3 else .19, 'china', 'china_blue' if i % 2 else 'oxblood', tilt=.22)
    # A station clock by the café window, a framed harvest picture over the cabinet, lettering above the plates.
    cx, cy, cz = -.5, .95, 2.45
    lathe(p, 'oxblood', [(0, 0), (.3, 0), (.3, .07), (0, .07)], (cx, cy, cz), 32, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    lathe(p, 'cream/f', [(0, 0), (.25, 0), (0, .002)], (cx + .076, cy, cz), 32, False, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    torus(p, 'brass', (cx + .078, cy, cz), .265, .014, normal=(1, 0, 0), seg=32, n=6)
    for i in range(12):
        a = i * math.tau / 12
        L = .045 if i % 3 == 0 else .022
        box(p, 'ink/f', (cx + .082, cy + math.sin(a) * (.22 - L / 2), cz + math.cos(a) * (.22 - L / 2)), (.004, .012, L), 0, rot=(-a, 0, 0))
    for a, L, w, dx in ((.38, .1, .02, .086), (1.75, .15, .014, .09)):
        box(p, 'ink/f', (cx + dx, cy + math.sin(a) * L / 2, cz + math.cos(a) * L / 2), (.004, w, L), 0, rot=(-a, 0, 0))
    ball(p, 'brass', (cx + .094, cy, cz), .012)
    text(p, 'oxblood/f', 'MORNING LOAF', s.k.facing_text(cx + .082, cy, cz - .1, (1, 0)), .03, 'cinzel')
    x, y, z = s.on_wall(s.WEST, 10.0, .03, 3.05)
    box(p, 'gold', (x, y, z), (.05, .9, .66), .01)
    box(p, 'sky', (x + .03, y, z + .1), (.006, .78, .34), 0)
    box(p, 'butter', (x + .03, y, z - .17), (.006, .78, .2), 0)
    for i in range(9):
        box(p, 'crust_light/f', (x + .046, y - .34 + i * .085, z - .14), (.004, .03, .12), 0, rot=(.2 * (i % 2 - .5), 0, 0))
    box(p, 'leaf/f', (x + .039, y - .18, z - .03), (.006, .5, .1), 0, rot=(.12, 0, 0))
    ball(p, 'white/f', (x + .04, y + .24, z + .16), .05, (.2, 1, 1))
    s.wall_text(p, 'oxblood/f', 'CAKES  ·  PASTRIES  ·  TARTS', s.WEST, 6.7, .004, 3.25, .21)
    # Doormat inside the door, and the shop bell on its coiled spring above the door.
    doormat(p, 'oxblood/f', 'kraft', 'MORNING LOAF', .09)
    tube(p, 'iron', [(6.62, -.3, 3.0), (6.62, -.15, 3.0), (6.6, -.05, 2.98)] +
         [(6.6 + .04 * math.cos(t), -.05 + .004 * t, 2.95 - .012 * t) for t in [i * .6 for i in range(12)]], .006, 5)
    lathe(p, 'brass', [(0, 0), (.06, 0), (.05, .02), (.03, .08), (0, .1)], (6.6, -.0, 2.72), 14, True, cap0=False)
    ball(p, 'brass', (6.6, 0, 2.71), .015)
    s.front_door(p, 'bakery', 'oxblood', 'gold_leaf')
    s.beams(p)
    p.finish(root)
    s.hinge_doors('bakery')
    s.finish(root, s.Parts(1), path, RECORD, extras={'room': 'shop-bakery', 'door_colour': s.PALETTE['oxblood']})


# ------------------------------------------------------------------------------------------------- the bread wall
def _tilted_basket(p, x, y, z, w, d, h, tilt=.28, loaves='boule', colour='wicker', count=None):
    """A shallow oval basket tilted forward on a shelf, heaped with one kind of loaf."""
    m = Matrix.Translation((x, y, z)) @ Matrix.Rotation(tilt, 4, 'X')
    with p.framed(m):
        s.basket(p, (0, 0, 0), w / 2, h, False, colour, 'wicker_dark', oval=d / w, bands=False)
        if loaves == 'boule':
            for i in range(5):
                g.boule(p, ((i - 2) * w * .19, (.05 if i % 2 else -.05), h * .25), .11, 'crust' if i % 2 else 'crust_light', 'crumb', i * .7)
        elif loaves == 'batard':
            for i in range(4):
                g.batard(p, ((i - 1.5) * w * .23, 0, h * .2), .3, .072, 'crust_light' if i % 2 else 'crust', angle=math.pi / 2 + .15 * (i - 1.5))
        elif loaves == 'tin':
            for i in range(4):
                g.tin_loaf(p, ((i - 1.5) * w * .23, 0, h * .2), .26, .14, angle=math.pi / 2)
        elif loaves == 'plait':
            for i in range(3):
                g.plait(p, ((i - 1) * w * .3, 0, h * .2), .32, .032, angle=math.pi / 2)
        elif loaves == 'rolls':
            for i in range(count or 12):
                g.bun(p, (((i % 4) - 1.5) * w * .22, ((i // 4) - 1) * d * .27, h * .25), .055, 'glaze', 'seeds' if i % 2 else None)


def bread_wall():
    """Behind the counter: a cupboard base in oxblood, an oak bench, three bays of forward-tilted baskets of bread,
    tall baskets of baguettes at the ends, price tags on brass rails and a gilt header."""
    root, p, path = s.begin('bakery-bread-wall', 'v1')
    W, D = 3.7, .58
    y0 = -D / 2
    # Base cupboard with four panelled doors and a drawer row.
    box(p, JOIN, (0, .02, .43), (W, D - .04, .86), .01)
    box(p, 'oxblood_dark', (0, .0, .04), (W - .04, D - .06, .08), .005)
    for i in range(4):
        x = -W / 2 + W / 8 + i * W / 4
        s.panel(p, JOIN, x, y0 + .02, .45, W / 4 - .05, .6, .055, .025, 'gold_leaf', 'brass', (x + (.3 if i % 2 == 0 else -.3), .45))
        box(p, JOIN, (x, y0 + .03, .8), (W / 4 - .05, .03, .1), .005)
        rod(p, 'brass', (x - .08, y0 + .01, .8), (x + .08, y0 + .01, .8), .008, 6)
    box(p, '@oak', (0, 0, .885), (W + .06, D + .04, .05), .01)
    # Uprights, back boards and three tilted shelves per bay.
    box(p, 'cream_paint', (0, D / 2 - .03, 1.6), (W - .08, .03, 1.4), 0)
    for x in (-W / 2 + .04, -W / 6, W / 6, W / 2 - .04):
        box(p, '@oak', (x, 0, 1.6), (.07, D - .04, 1.42), .008)
    kinds = [['boule', 'batard', 'tin'], ['plait', 'rolls', 'boule'], ['tin', 'boule', 'batard']]
    for bay in range(3):
        cx = -W / 3 + bay * W / 3
        for row, z in enumerate((1.04, 1.5, 1.94)):
            box(p, '@oak', (cx, .02, z), (W / 3 - .08, D - .1, .035), .005, rot=(.12, 0, 0))
            rod(p, 'brass', (cx - W / 6 + .06, y0 + .05, z + .08), (cx + W / 6 - .06, y0 + .05, z + .08), .01, 6)
            _tilted_basket(p, cx, .0, z + .03, W / 3 - .2, .36, .13, .22, kinds[bay][row])
            box(p, 'card/f', (cx + .3, y0 + .04, z + .05), (.12, .006, .075), .002, rot=(.1, 0, 0))
            text(p, 'ink/f', ['4D', '6D', '3D', '9D', '2D', '5D', '7D', '4D', '6D'][bay * 3 + row],
                 facing(cx + .3, y0 + .034, z + .05), .04, 'alegreya')
    # Cornice and a gilt header.
    box(p, '@oak', (0, 0, 2.33), (W + .1, D + .06, .06), .01)
    box(p, JOIN, (0, y0 - .02, 2.22), (W, .04, .18), .006)
    text(p, 'gold_leaf/f', 'OUR DAILY BREAD', facing(0, y0 - .045, 2.22), .1, 'cinzel', spacing=1.1)
    # Tall baskets of baguettes standing on the bench at each end; a bread slicer and paper on the bench.
    for side in (-1, 1):
        x = side * (W / 2 - .28)
        lathe(p, 'wicker', [(.12, 0), (.15, .42), (.16, .45)], (x, -.05, .91), 18, True, cap1=False,
              ripple=lambda a, z: 1 + .04 * math.cos(a * 18))
        torus(p, 'wicker_dark', (x, -.05, 1.36), .16, .015, seg=20, n=5)
        for i in range(7):
            a = i * 2.4
            lean = Vector((math.cos(a) * .12, math.sin(a) * .08 - .02, 0))
            g.baguette(p, (x + math.cos(a) * .06, -.05 + math.sin(a) * .05, .95), (x + lean.x + math.cos(a) * .06, -.05 + lean.y, 1.75 + (i % 3) * .06), .03)
    # Slicer on the bench, centre: an iron frame with a wheel and a cut loaf.
    box(p, 'enamel_green', (0, .05, .95), (.42, .3, .08), .01)
    lathe(p, 'steel', [(0, -.01), (.16, -.01), (.16, .01), (0, .01)], (.1, .05, 1.15), 24, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    tube(p, 'enamel_green', [(.12, .18, .95), (.12, .18, 1.32), (.12, .05, 1.32)], .02, 6)
    rod(p, 'enamel_green', (.14, .05, 1.15), (.24, .05, 1.15), .03, 10)
    tube(p, 'iron', [(.24, .05, 1.15), (.24, -.08, 1.15), (.24, -.08, 1.05)], .01, 5)
    rod(p, 'wood_dark', (.24, -.08, 1.05), (.24, -.12, 1.05), .018, 8)
    g.tin_loaf(p, (-.1, .05, .99), .26, .13, angle=0)
    for i in range(4):
        box(p, 'crumb/f', (-.24 - i * .02, .05 - i * .002, 1.05), (.01, .12, .1), .002, rot=(0, -.15 * i, 0))
    for i in range(6):
        box(p, 'kraft', (-.65, .0, .92 + i * .008), (.28, .22, .006), 0, rot=(0, 0, .04 * i))
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the counter
def counter():
    """Oxblood panelled serving counter with a marble top, a curved-glass patisserie case on the left and, on the
    right, a brass till, the bell, paper bags and string, and a cake under a glass dome."""
    root, p, path = s.begin('bakery-counter', 'v2')
    W, D, H = 3.86, .96, .98
    box(p, JOIN, (0, .02, H / 2), (W - .04, D - .06, H - .06), .01)
    box(p, 'oxblood_dark', (0, 0, .045), (W, D + .01, .09), .008)
    for i in range(5):
        x = -W / 2 + W / 10 + i * W / 5
        s.panel(p, JOIN, x, -D / 2 + .01, .5, W / 5 - .06, .66, .06, .03, 'gold_leaf')
    for side in (-1, 1):
        x = side * (W / 2 - .01)
        with p.placed((x, 0, 0), 90 * side):
            s.panel(p, JOIN, 0, -.01, .5, D - .14, .66, .06, .03, 'gold_leaf')
    box(p, '@marble', (0, 0, H + .03), (W + .08, D + .06, .06), .015)
    # The patisserie case: brass frame, a curved glass front, a glass shelf and pastries on doilies.
    x0, x1 = -W / 2 + .06, -.08
    for x in (x0, x1):
        prof = [(x, -D / 2 + .06, H + .06), (x, -D / 2 + .06, H + .18)] + \
               [(x, -D / 2 + .06 + .3 * (1 - math.cos(a)), H + .18 + .32 * math.sin(a)) for a in [i * math.pi / 2 / 6 for i in range(1, 7)]] + \
               [(x, .3, H + .5), (x, .3, H + .06)]
        p.solid('shops_clear_glass', [(xx, y, z) for xx, y, z in prof], .01, (1, 0, 0))
        tube(p, 'brass', [(x, y, z) for _, y, z in prof[:-1]], .012, 6)
    sheet(p, 'shops_clear_glass', lambda u, v: (x0 + u * (x1 - x0), -D / 2 + .06 + .3 * (1 - math.cos(v * math.pi / 2)),
                                               H + .18 + .32 * math.sin(v * math.pi / 2)), 1, 8, .006, rims=False)
    p.pane('shops_clear_glass', ((x0 + x1) / 2, -D / 2 + .06, H + .12), x1 - x0, .12, (0, -1))
    box(p, 'shops_clear_glass', ((x0 + x1) / 2, .3, H + .28), (x1 - x0, .006, .44), 0)
    box(p, 'shops_clear_glass', ((x0 + x1) / 2, .02, H + .5), (x1 - x0, .56, .006), 0)
    box(p, 'brass', ((x0 + x1) / 2, .3, H + .5), (x1 - x0 + .02, .02, .02), .002)
    box(p, 'shops_clear_glass', ((x0 + x1) / 2, 0, H + .28), (x1 - x0 - .04, .5, .008), 0)
    for x in (x0 + .1, x1 - .1):
        rod(p, 'brass', (x, .2, H + .06), (x, .2, H + .28), .008, 6)
    lo, hi = H + .065, H + .29
    xs = [x0 + .2 + i * (x1 - x0 - .4) / 4 for i in range(5)]
    for i, x in enumerate(xs):
        g.doily(p, (x, -.12, lo), .1)
        if i == 0:
            for j in range(3):
                g.croissant(p, (x - .05 + j * .05, -.14 + (j % 2) * .06, lo + .003), .055, angle=.3 * j)
        elif i == 1:
            for j in range(4):
                box(p, 'eclair', (x, -.18 + j * .055, lo + .022), (.13, .04, .035), .012)
                box(p, 'chocolate', (x, -.18 + j * .055, lo + .042), (.12, .03, .01), .004)
        elif i == 2:
            g.tart(p, (x, -.12, lo + .002), .09, 'strawberry')
        elif i == 3:
            for j in range(4):
                g.cupcake(p, (x - .04 + (j % 2) * .08, -.16 + (j // 2) * .08, lo + .002), .03,
                          ['mac_pink', 'mac_pist', 'mac_lav', 'mac_lemon'][j], ['icing_pink', 'icing_mint', 'icing', 'icing_lemon'][j])
        else:
            g.tart(p, (x, -.12, lo + .002), .09, 'blueberry')
        g.doily(p, (x, .06, hi), .09)
        if i % 2 == 0:
            for j in range(6):
                g.macaron(p, (x - .05 + (j % 3) * .05, .02 + (j // 3) * .06, hi + .003), .02,
                          ['mac_pink', 'mac_pist', 'mac_lav', 'mac_lemon', 'mac_choc', 'mac_pink'][j])
        else:
            for j in range(3):
                g.bun(p, (x - .05 + j * .05, .06, hi + .003), .035, 'glaze', 'icing' if j != 1 else 'swirl')
    # Open end: brass till, bell, bags and string, a domed cake.
    tx = .55
    box(p, 'wood_dark', (tx, .1, H + .08), (.5, .42, .04), .006)
    verts = [(tx - .22, -.1, H + .1), (tx + .22, -.1, H + .1), (tx + .22, .3, H + .1), (tx - .22, .3, H + .1),
             (tx - .22, .02, H + .24), (tx + .22, .02, H + .24), (tx + .22, .3, H + .38), (tx - .22, .3, H + .38)]
    faces = [(0, 3, 2, 1), (0, 1, 5, 4), (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7), (4, 5, 6, 7)]
    p.add('brass', verts, faces, [[(0, 0)] * 4] * 6)
    for i in range(4):
        for j in range(5):
            x = tx - .16 + j * .08
            y = -.06 + i * .07
            z = H + .14 + i * .035
            rod(p, 'ink/f', (x, y, z), (x, y - .005, z + .03), .016, 8)
            rod(p, 'white/f', (x, y - .006, z + .03), (x, y - .007, z + .034), .015, 8)
    box(p, 'brass', (tx, .26, H + .5), (.4, .1, .22), .02)
    box(p, 'ink/f', (tx, .205, H + .52), (.3, .01, .1), .004)
    text(p, 'white/f', '0  4  6', facing(tx, .199, H + .52), .05, 'alegreya')
    for x in (tx - .2, tx + .2):
        tube(p, 'brass', [(x, .3, H + .38), (x, .32, H + .55), (x * .9 + tx * .1, .3, H + .62)], .012, 6)
    rod(p, 'brass', (tx + .28, .05, H + .2), (tx + .36, .05, H + .2), .012, 6)
    ball(p, 'enamel_red', (tx + .37, .05, H + .2), .025)
    lathe(p, 'brass', [(0, 0), (.05, 0), (.045, .02), (.012, .04), (0, .055)], (1.0, -.25, H + .06), 16, True)
    ball(p, 'brass', (1.0, -.25, H + .12), .01)
    for i in range(10):
        box(p, 'kraft', (1.32, .15, H + .065 + i * .007), (.3, .24, .006), 0, rot=(0, 0, .03 * (i % 3)))
    lathe(p, '@oak', [(0, 0), (.06, 0), (.05, .04), (.02, .05), (.02, .2), (0, .2)], (1.62, .1, H + .06), 12, True)
    lathe(p, 'string', [(0, 0), (.055, 0), (.03, .1), (0, .12)], (1.62, .1, H + .1), 12, True)
    tube(p, 'string', [(1.62, .1, H + .22), (1.6, .05, H + .5), (1.4, -.1, H + .2), (1.38, -.2, H + .065)], .003, 3)
    top = g.cake_stand(p, (-.0 + .02 + 1.0 - .7, .12, H + .06), .17, .1)
    g.cake(p, (.32, .12, top), .13, 1, 'chocolate_light', 'chocolate', 'raspberry', drip='chocolate')
    g.cloche(p, (.32, .12, top - .005), .16, .26)
    s.jar(p, (1.65, -.28, H + .06), .22, .07, 'crust_light', 'copper', 'paper')
    box(p, 'card/f', (1.0, -.43, H + .07), (.2, .005, .05), 0, rot=(.3, 0, 0))
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the cake table
def cake_table():
    """A round three-tier display table on a turned pedestal: a wedding cake on top, a macaron tower and a drip cake
    below, sponges, tarts, cupcakes, a pie and boxed orders round the bottom tier."""
    root, p, path = s.begin('bakery-cake-table', 'v1')
    lathe(p, '@oak', [(.42, 0), (.44, .03), (.36, .06), (.12, .1), (.08, .25), (.12, .3), (.07, .45), (.1, .62), (.14, .68),
                      (.14, .7)], (0, 0, 0), 24, True)
    tiers = [(.76, .72), (.52, 1.02), (.3, 1.3)]
    for i, (r, z) in enumerate(tiers):
        lathe(p, JOIN, [(r - .02, z - .1), (r, z - .09), (r, z - .02), (r - .02, z)], (0, 0, 0), 40, True, cap0=True, cap1=False)
        lathe(p, '@oak', [(0, z), (r + .02, z), (r + .03, z + .015), (r + .02, z + .035), (0, z + .035)], (0, 0, 0), 40, True,
              cap0=False)
        torus(p, 'gold_leaf', (0, 0, z - .055), r + .002, .006, seg=40, n=4)
        if i < 2:
            lathe(p, '@oak', [(.07, z + .03), (.06, z + .12), (.09, z + .2), (.06, tiers[i + 1][1] - .1)], (0, 0, 0), 14, True)
    z0, z1, z2 = (t[1] + .035 for t in tiers)
    # Bottom tier: eight pieces round the ring.
    ring = .56
    for i in range(8):
        a = i * math.tau / 8 + .2
        x, y = math.cos(a) * ring, math.sin(a) * ring
        g.doily(p, (x, y, z0), .13)
        kind = i % 8
        if kind == 0:
            top = g.cake(p, (x, y, z0 + .003), .12, 1, 'crumb', 'whip', 'strawberry')
        elif kind == 1:
            g.tart(p, (x, y, z0 + .003), .11, 'strawberry')
        elif kind == 2:
            top = g.cake_stand(p, (x, y, z0), .12, .06)
            for j in range(4):
                g.cupcake(p, (x + math.cos(j * 1.57) * .06, y + math.sin(j * 1.57) * .06, top), .028,
                          ['mac_pink', 'mac_pist', 'mac_lav', 'mac_lemon'][j], ['icing_pink', 'icing_mint', 'icing', 'icing_lemon'][j])
        elif kind == 3:
            lathe(p, 'crust_light', [(.1, 0), (.11, .04), (.105, .05), (0, .055)], (x, y, z0 + .003), 20, True,
                  ripple=lambda aa, zz: 1 + .05 * math.cos(aa * 16))
            for j in range(-2, 3):
                box(p, 'crust/f', (x + j * .035, y, z0 + .06), (.016, .19, .012), .004, rot=(0, 0, .785))
                box(p, 'crust/f', (x, y + j * .035, z0 + .061), (.19, .016, .012), .004, rot=(0, 0, .785))
        elif kind == 4:
            for j in range(3):
                box(p, ['pink_box', 'mint_box', 'card'][j], (x, y, z0 + .04 + j * .075), (.16 - j * .02, .16 - j * .02, .07), .008,
                    rot=(0, 0, .3 * j))
                box(p, 'ribbon_red/f', (x, y, z0 + .04 + j * .075), (.165 - j * .02, .015, .072), 0, rot=(0, 0, .3 * j))
                box(p, 'ribbon_red/f', (x, y, z0 + .04 + j * .075), (.015, .165 - j * .02, .072), 0, rot=(0, 0, .3 * j))
            for b in (-1, 1):
                ball(p, 'ribbon_red/f', (x + b * .015, y, z0 + .195), .02, (1.4, .6, .8))
        elif kind == 5:
            g.tart(p, (x, y, z0 + .003), .11, 'blueberry')
        elif kind == 6:
            for j in range(7):
                g.cookie(p, (x + math.cos(j) * .05 * (j > 0), y + math.sin(j) * .05 * (j > 0), z0 + .004 + (j == 0) * .013), .035)
        else:
            top = g.cake(p, (x, y, z0 + .003), .11, 1, 'crumb', 'icing_lemon', None)
            for j in range(6):
                rod(p, 'lemon/f', (x + math.cos(j) * .07, y + math.sin(j) * .07, top), (x + math.cos(j) * .07, y + math.sin(j) * .07, top + .006), .018, 8)
        box(p, 'card/f', (x * 1.24, y * 1.24, z0 + .025), (.07, .004, .04), 0, rot=(.4, 0, a + math.pi / 2))
    # Middle tier: a macaron tower and a chocolate drip cake, lemon loaf and a jar of meringues.
    for i, a in enumerate((.6, .6 + math.pi * 2 / 3, .6 + math.pi * 4 / 3)):
        x, y = math.cos(a) * .32, math.sin(a) * .32
        g.doily(p, (x, y, z1), .12)
        if i == 0:
            lathe(p, 'china', [(.06, 0), (.03, .02), (.025, .25), (0, .27)], (x, y, z1), 10, True, cap0=True)
            for row in range(7):
                rr = .085 - row * .011
                count = max(3, int(rr * 70))
                for j in range(count):
                    b = j * math.tau / count + row * .3
                    g.macaron(p, (x + math.cos(b) * rr, y + math.sin(b) * rr, z1 + .01 + row * .035), .018,
                              ['mac_pink', 'mac_pist', 'mac_lav', 'mac_lemon', 'mac_choc'][(j + row) % 5])
        elif i == 1:
            g.cake(p, (x, y, z1 + .003), .1, 2, 'chocolate_light', 'chocolate', 'raspberry', drip='chocolate')
        else:
            g.tin_loaf(p, (x, y, z1 + .003), .22, .1, 'crust_light', 'icing_lemon', a)
            for j in range(5):
                box(p, 'icing/f', (x + (j - 2) * .04 * math.cos(a), y + (j - 2) * .04 * math.sin(a), z1 + .125), (.012, .1, .006), 0,
                    rot=(0, 0, a))
    # Top: the wedding cake.
    g.doily(p, (0, 0, z2), .2)
    top = g.cake_stand(p, (0, 0, z2), .2, .06)
    top = g.cake(p, (0, 0, top), .16, 3, 'crumb', 'icing', None, roses='raspberry')
    for i in range(3):
        a = i * 2.1
        ball(p, 'icing_pink', (math.cos(a) * .03, math.sin(a) * .03, top + .025), .028)
    ball(p, 'leaf/f', (.04, -.03, top + .02), .015, (1.6, .8, .4))
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the bench
def bench():
    """The baker's bench: a thick butcher-block top dusted with flour, dough rounds, a sheet being rolled, cane
    proving baskets, a bowl under gingham, a brass scale, dredger and spoons, and a slatted shelf of tins."""
    root, p, path = s.begin('bakery-proving-table', 'v2')
    W, D, H = 2.6, 1.0, .9
    for x in (-W / 2 + .12, W / 2 - .12):
        for y in (-D / 2 + .12, D / 2 - .12):
            s.leg(p, '@oak', x, y, 0, H - .1, .05)
    box(p, '@oak', (0, 0, H - .14), (W - .16, D - .16, .12), .01)
    box(p, '@oak', (0, -D / 2 + .1, H - .14), (.5, .04, .1), .006)
    rod(p, 'brass', (0, -D / 2 + .07, H - .14), (0, -D / 2 + .05, H - .14), .018, 8)
    for i in range(9):
        box(p, '@oak', (-W / 2 + .2 + i * (W - .4) / 8, 0, H - .05), ((W - .4) / 8 - .006, D, .1), .006)
    for i in range(6):
        box(p, '@oak', (0, -D / 2 + .16 + i * .136, .2), (W - .26, .1, .03), .005)
    top = H + .05
    p.solid('flour/f', [(-1.0, -.35, top + .002), (-.2, -.42, top + .002), (.25, -.25, top + .002), (.2, .3, top + .002),
                        (-.6, .38, top + .002), (-1.1, .1, top + .002)], .002, (0, 0, 1))
    for i, (x, y) in enumerate(((-.85, -.15), (-.65, -.2), (-.75, .05), (-.55, .02), (-.95, .1))):
        lathe(p, 'dough', [(0, 0), (.07, 0), (.075, .025), (.05, .06), (0, .07)], (x, y, top), 14, True, cap0=False)
    sheet(p, 'dough', lambda u, v: (-.3 + u * .5, -.25 + v * .4, top + .012 + .006 * math.sin(u * 3)), 4, 4, .012)
    rod(p, '@oak', (-.05, -.32, top + .045), (-.05, .2, top + .045), .04, 12)
    for y0, y1 in ((-.46, -.32), (.2, .34)):
        rod(p, '@oak', (-.05, y0, top + .045), (-.05, y1, top + .045), .016, 8)
    box(p, 'steel', (.35, -.38, top + .045), (.14, .008, .09), .002, rot=(0, .2, .4))
    box(p, '@oak', (.32, -.36, top + .1), (.14, .03, .025), .004, rot=(0, .2, .4))
    for i, x in enumerate((.45, .72, .99)):
        y = .22 if i != 1 else .02
        lathe(p, 'cane', [(.06, 0), (.12, .01), (.14, .09), (.145, .1)], (x, y, top), 22, True, cap1=False,
              ripple=lambda a, z: 1 + .03 * math.cos(a * 22))
        for z in (.03, .06, .09):
            torus(p, 'wicker_dark/f', (x, y, top + z), .12 + z * .25, .004, seg=22, n=4)
        lathe(p, 'dough', [(.12, .07), (.1, .1), (.05, .125), (0, .13)], (x, y, top), 18, True, cap0=False)
    bx, by = 1.0, -.28
    lathe(p, 'china_blue', [(.08, 0), (.12, .02), (.2, .12), (.21, .14)], (bx, by, top), 24, True, cap1=False)
    lathe(p, 'china', [(.19, .13), (.08, .02), (0, .02)], (bx, by, top), 24, True, cap0=False, cap1=False)
    sheet(p, '@gingham_red', lambda u, v: (bx - .25 + u * .5, by - .25 + v * .5,
                                           top + .15 + .03 * (1 - ((u - .5) * 2) ** 2) * (1 - ((v - .5) * 2) ** 2) -
                                           .12 * max(0, abs(u - .5) * 2 - .8) * 5 - .12 * max(0, abs(v - .5) * 2 - .8) * 5),
          10, 10, .006)
    sx, sy = -.35, .3
    box(p, 'brass', (sx, sy, top + .02), (.3, .16, .04), .01)
    rod(p, 'brass', (sx, sy, top + .04), (sx, sy, top + .22), .012, 8)
    rod(p, 'brass', (sx - .16, sy, top + .22), (sx + .16, sy, top + .22), .008, 6)
    for x, z in ((sx - .16, top + .12), (sx + .16, top + .11)):
        lathe(p, 'brass', [(0, 0), (.07, 0), (.08, .02), (.075, .02)], (x, sy, z), 16, True, cap1=False)
        for dx in (-.05, .05):
            rod(p, 'brass', (x + dx, sy, z + .02), (x, sy, top + .22), .002, 3)
    for i, r in enumerate((.03, .025, .02, .015)):
        rod(p, 'brass', (sx - .02 + i * .045, sy - .1, top), (sx - .02 + i * .045, sy - .1, top + .02 + r), r, 10)
    ball(p, 'flour', (sx - .16, sy, top + .13), .05, (1, 1, .4))
    lathe(p, 'zinc', [(0, 0), (.04, 0), (.04, .12), (.02, .16), (0, .17)], (-.15, .38, top), 14, True, cap0=False)
    lathe(p, 'china', [(.05, 0), (.06, .14), (.065, .15)], (-1.05, .32, top), 14, True, cap1=False)
    for i in range(4):
        a = i * 1.6
        rod(p, '@oak', (-1.05 + math.cos(a) * .02, .32 + math.sin(a) * .02, top + .05),
            (-1.05 + math.cos(a) * .07, .32 + math.sin(a) * .05, top + .34), .009, 6)
        ball(p, '@oak', (-1.05 + math.cos(a) * .075, .32 + math.sin(a) * .052, top + .37), .025, (1, .5, 1.4))
    # Underneath: stacked cane baskets, loaf tins and a flour bin.
    for i in range(4):
        lathe(p, 'cane', [(.06, 0), (.12, .01), (.14, .085), (.145, .09)], (-.85, -.05, .215 + i * .05), 20, True, cap1=False,
              ripple=lambda a, z: 1 + .03 * math.cos(a * 20))
    for i in range(5):
        for j in range(2):
            box(p, 'steel', (-.2 + j * .3, -.1, .225 + i * .055), (.26, .14, .05), .006)
    lathe(p, 'zinc', [(.18, 0), (.2, .38), (.21, .4)], (.75, 0, .215), 20, True, cap1=False)
    lathe(p, 'zinc', [(0, .4), (.22, .4), (.22, .43), (.05, .45), (0, .47)], (.75, 0, .215), 20, True, cap0=False)
    box(p, 'paper/f', (.75, -.2, .45), (.16, .005, .1), 0)
    text(p, 'ink/f', 'RYE', facing(.75, -.206, .45), .05, 'alegreya')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the proving cabinet
def proving_cabinet():
    """A tall oak proving cabinet with glazed doors, the right one standing open: runners of trays with baguette
    dough resting in linen folds, rolls rising, a brass thermometer, baskets on top."""
    root, p, path = s.begin('bakery-proving-cabinet', 'v1')
    W, D, H = 1.2, .58, 2.05
    box(p, '@oak', (0, 0, .06), (W + .04, D + .02, .12), .01)
    box(p, '@oak', (-W / 2 + .03, 0, H / 2), (.06, D, H - .1), .008)
    box(p, '@oak', (W / 2 - .03, 0, H / 2), (.06, D, H - .1), .008)
    box(p, '@oak', (0, D / 2 - .02, H / 2), (W - .06, .04, H - .1), .006)
    box(p, 'cream_paint', (0, D / 2 - .045, H / 2 + .02), (W - .12, .01, H - .25), 0)
    box(p, '@oak', (0, 0, H - .06), (W, D, .06), .008)
    s.cornice(p, '@oak', 0, W, -D / 2, D, H - .03)
    for i in range(7):
        z = .25 + i * .24
        for x in (-W / 2 + .07, W / 2 - .07):
            box(p, '@oak', (x, 0, z), (.02, D - .1, .02), 0)
        box(p, 'steel', (0, -.02, z + .02), (W - .16, D - .14, .015), .003)
        if i % 2 == 0:
            for j in range(3):
                yy = -.14 + j * .14
                sheet(p, '@linen', lambda u, v, yy=yy: (-W / 2 + .1 + u * (W - .2), yy - .06 + v * .12, z + .03 + .03 * math.sin(v * math.pi)),
                      2, 4, .004)
                g.baguette(p, (-W / 2 + .14, yy, z + .03), (W / 2 - .14, yy, z + .03), .028, 'dough', 'dough')
        else:
            for j in range(10):
                lathe(p, 'dough', [(0, 0), (.045, 0), (.05, .02), (.03, .045), (0, .05)],
                      (-W / 2 + .16 + (j % 5) * (W - .3) / 4, -.12 + (j // 5) * .2, z + .035), 12, True, cap0=False)
    # Doors: the left closed, glazed in four lights; the right standing open.
    L = W / 2 - .04

    def leaf(p, handle):
        """One glazed door, hinge at local x 0, reaching to +x, its face toward -y."""
        box(p, '@oak', (.035, 0, 0), (.07, .04, H - .3), .006)
        box(p, '@oak', (L - .035, 0, 0), (.07, .04, H - .3), .006)
        for z in (-(H - .3) / 2 + .04, 0, (H - .3) / 2 - .04):
            box(p, '@oak', (L / 2, 0, z), (L - .1, .04, .07), .006)
        box(p, '@oak', (L / 2, 0, (H - .3) / 4), (.03, .03, (H - .3) / 2 - .1), 0)
        box(p, '@oak', (L / 2, 0, -(H - .3) / 4), (.03, .03, (H - .3) / 2 - .1), 0)
        p.pane('shops_clear_glass', (L / 2, 0, 0), L - .1, H - .4, (0, -1))
        rod(p, 'brass', (handle, -.03, -.05), (handle, -.03, .15), .01, 6)
    with p.placed((-W / 2 + .02, -D / 2 - .02, H / 2 + .05), 0):
        leaf(p, L - .09)
    with p.placed((W / 2 - .02, -D / 2 - .02, H / 2 + .05), -70):
        leaf(p, L - .09)
    lathe(p, 'brass', [(0, 0), (.06, 0), (.06, .015), (0, .015)], (-.3, -D / 2 - .04, 1.65), 16, True,
          axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    lathe(p, 'cream/f', [(0, 0), (.05, 0), (0, .001)], (-.3, -D / 2 - .056, 1.65), 16, False, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    rod(p, 'enamel_red/f', (-.3, -D / 2 - .058, 1.65), (-.28, -D / 2 - .058, 1.69), .004, 3)
    for i, x in enumerate((-.3, .25)):
        s.basket(p, (x, 0, H + .05), .2, .14, i == 0)
        if i == 1:
            for j in range(4):
                g.bun(p, (x - .07 + (j % 2) * .14, -.06 + (j // 2) * .12, H + .12), .05, 'crust_light')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the mixer
def mixer():
    """A floor-standing dough mixer in green enamel: a heavy base, a column, a domed head with a brass badge, a
    steel bowl on a cradle, a spiral hook in the dough, a hand wheel and a switch box."""
    root, p, path = s.begin('bakery-mixer', 'v1')
    box(p, 'enamel_green', (0, .15, .08), (.82, .9, .16), .04)
    box(p, 'iron', (0, .15, .01), (.86, .94, .02), .005)
    lathe(p, 'enamel_green', [(.2, 0), (.17, .1), (.15, 1.1), (.18, 1.15)], (0, .38, .16), 20, True, squash=(1, .8))
    box(p, 'enamel_green', (0, .2, 1.35), (.42, .62, .32), .1, seg=3)
    lathe(p, 'enamel_green', [(.2, 0), (.2, .05), (.12, .14), (0, .16)], (0, .2, 1.5), 20, True, cap0=False, squash=(1, 1.4))
    lathe(p, 'brass', [(0, 0), (.06, 0), (.06, .01), (0, .01)], (0, -.115, 1.36), 18, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    text(p, 'brass_dark/f', 'No 2', facing(0, -.127, 1.36), .035, 'cinzel')
    rod(p, 'steel', (0, .0, 1.19), (0, .0, .78), .025, 10)
    # The hook, a spiral of steel, and dough wound on it.
    pts = [(math.cos(t) * .07 * (1 - t / 14), math.sin(t) * .07 * (1 - t / 14), .78 - t * .025) for t in [i * .45 for i in range(22)]]
    tube(p, 'steel', pts, .014, 6)
    # Cradle and bowl.
    for x in (-.3, .3):
        tube(p, 'enamel_green', [(x * .6, .34, .9), (x, .2, .88), (x, -.02, .78), (x * .95, -.05, .65)], .03, 8)
    lathe(p, 'steel', [(.1, 0), (.22, .05), (.28, .3), (.29, .36), (.27, .36)], (0, -.0, .34), 28, True, cap1=False)
    lathe(p, 'dough', [(.26, 0), (.2, .06), (.08, .1), (0, .1)], (0, 0, .58), 20, True, cap0=True, ripple=lambda a, z: 1 + .06 * math.cos(a * 3 + z * 20))
    ball(p, 'dough', (.04, -.02, .7), .09, (1, 1, .7))
    rod(p, 'enamel_green', (0, 0, .16), (0, 0, .34), .07, 14)
    # Hand wheel and switch box.
    for i in range(6):
        a = i * math.tau / 6
        rod(p, 'iron', (.24, .3, 1.3), (.24, .3 + math.cos(a) * .17, 1.3 + math.sin(a) * .17), .01, 5)
    torus(p, 'iron', (.25, .3, 1.3), .18, .016, normal=(1, 0, 0), seg=24, n=6)
    rod(p, 'iron', (.2, .3, 1.3), (.27, .3, 1.3), .04, 10)
    rod(p, 'wood_dark', (.26, .3, 1.47), (.36, .3, 1.47), .018, 8)
    box(p, 'iron', (-.24, .55, .9), (.12, .14, .2), .02)
    rod(p, 'enamel_red', (-.31, .55, .95), (-.33, .55, .95), .025, 10)
    rod(p, 'ink', (-.31, .55, .87), (-.33, .55, .87), .02, 10)
    tube(p, 'ink', [(-.24, .62, .8), (-.2, .66, .5), (-.1, .7, .17)], .012, 5)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- flour sacks
def _sack(p, at, size=(.62, .42, .26), turn=0.0, mark='FLOUR', lean=0.0):
    x, y, z = at
    with p.placed((x, y, z), turn):
        with p.framed(Matrix.Rotation(lean, 4, 'Y')):
            s.soft(p, '@burlap', (0, 0, size[2] / 2), size, .1)
            for side in (-1, 1):
                ball(p, '@burlap', (side * size[0] / 2, 0, size[2] / 2), size[2] * .45, (.5, 1.1, 1))
                rod(p, 'string/f', (side * (size[0] / 2 + .01), -.06, size[2] / 2), (side * (size[0] / 2 + .01), .06, size[2] / 2),
                    .015, 6)
            text(p, 'label_red/f', mark, s.k.facing_text(0, -size[1] / 2 - .002, size[2] * .55, (0, -1)), .07, 'cinzel')
            text(p, 'label_blue/f', 'MILL No 3', s.k.facing_text(0, -size[1] / 2 - .002, size[2] * .3, (0, -1)), .035, 'alegreya')


def flour_sacks():
    """A pallet of stencilled flour sacks, one opened and rolled down with a brass scoop, a zinc bin and a sieve."""
    root, p, path = s.begin('bakery-flour-sacks', 'v2')
    for i in range(5):
        box(p, '@oak', (-.3, -.42 + i * .2, .03), (1.1, .14, .03), .004)
    for x in (-.8, -.3, .2):
        box(p, '@oak', (x, 0, .09), (.1, 1.0, .09), .006)
    for i in range(5):
        box(p, '@oak', (-.3, -.42 + i * .2, .15), (1.1, .14, .03), .004)
    _sack(p, (-.3, -.22, .165), (.9, .42, .24), 0, 'FLOUR')
    _sack(p, (-.3, .24, .165), (.9, .42, .24), 0, 'FLOUR')
    _sack(p, (-.3, -.02, .405), (.9, .44, .24), 180, 'RYE')
    _sack(p, (-.32, .0, .645), (.86, .42, .22), 6, 'FLOUR')
    # An opened sack standing beside, rolled down, with flour and a scoop.
    x, y = .55, -.15
    lathe(p, '@burlap', [(.2, 0), (.26, .1), (.27, .42), (.25, .55)], (x, y, 0), 18, True, cap1=False,
          ripple=lambda a, z: 1 + .05 * math.cos(a * 5 + z * 6))
    torus(p, '@burlap', (x, y, .56), .265, .04, seg=18, n=8)
    lathe(p, 'flour', [(0, .5), (.24, .5), (.18, .56), (0, .6)], (x, y, 0), 16, True, cap0=False)
    lathe(p, 'brass', [(0, 0), (.06, 0), (.065, .07)], (x + .05, y - .05, .55), 12, True, cap1=False, axis=Matrix.Rotation(.9, 3, 'X'))
    rod(p, 'brass', (x + .05, y - .1, .57), (x + .05, y - .22, .66), .015, 6)
    text(p, 'label_red/f', 'FLOUR', s.k.facing_text(x, y - .272, .3, (0, -1)), .065, 'cinzel')
    # Zinc bin on short legs, lid ajar; a drum sieve leaning on it.
    bx, by = .62, .32
    lathe(p, 'zinc', [(.2, .05), (.22, .6)], (bx, by, 0), 22, True, cap1=False)
    torus(p, 'zinc', (bx, by, .6), .22, .012, seg=22, n=5)
    for i in range(3):
        torus(p, 'zinc', (bx, by, .15 + i * .2), .215, .008, seg=22, n=4)
    with p.framed(Matrix.Translation((bx + .05, by + .02, .63)) @ Matrix.Rotation(-.18, 4, 'Y')):
        lathe(p, 'zinc', [(0, 0), (.23, 0), (.23, .02), (.05, .05), (0, .06)], (0, 0, 0), 22, True)
        ball(p, 'wood_dark', (0, 0, .08), .025)
    lathe(p, '@oak', [(.18, 0), (.18, .06)], (bx - .12, by - .26, .19), 20, False, axis=Matrix.Rotation(1.2, 3, 'X'),
          cap0=False, cap1=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the cooling rack
def cooling_rack():
    """A steel rack on castors with eight trays: croissants, pains au chocolat, cinnamon swirls, seeded rolls,
    cookies, pretzels, little tarts and éclairs."""
    root, p, path = s.begin('bakery-cooling-rack', 'v1')
    W, D, H = .76, .62, 1.75
    for x in (-W / 2, W / 2):
        for y in (-D / 2, D / 2):
            box(p, 'steel', (x, y, H / 2 + .08), (.03, .03, H - .04), .004)
            rod(p, 'steel', (x, y, .08), (x, y, .05), .012, 6)
            lathe(p, 'ink', [(0, -.02), (.035, -.02), (.035, .02), (0, .02)], (x, y, .04), 10, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    for z in (.1, H + .08):
        for y in (-D / 2, D / 2):
            box(p, 'steel', (0, y, z), (W, .03, .025), .003)
        for x in (-W / 2, W / 2):
            box(p, 'steel', (x, 0, z), (.03, D, .025), .003)
    kinds = ['croissant', 'pain', 'swirl', 'roll', 'cookie', 'pretzel', 'tart', 'eclair']
    for i, kind in enumerate(kinds):
        z = .26 + i * .2
        for x in (-W / 2 + .02, W / 2 - .02):
            box(p, 'steel', (x, 0, z - .012), (.015, D - .02, .012), 0)
        box(p, 'steel', (0, 0, z), (W - .05, D - .03, .012), .002)
        for x in (-W / 2 + .04, W / 2 - .04):
            box(p, 'steel', (x, 0, z + .015), (.012, D - .03, .02), 0)
        for j in range(6 if kind not in ('cookie',) else 12):
            cols = 3 if kind not in ('cookie',) else 4
            xx = -W / 2 + .15 + (j % cols) * (W - .3) / (cols - 1)
            yy = -D / 2 + .14 + (j // cols) * (D - .28) / max(1, (6 if kind != 'cookie' else 12) // cols - 1)
            zz = z + .006
            if kind == 'croissant':
                g.croissant(p, (xx, yy, zz), .055, angle=.4 * j)
            elif kind == 'pain':
                s.soft(p, 'glaze', (xx, yy, zz + .025), (.13, .08, .05), .02)
                for dx in (-.03, .03):
                    box(p, 'chocolate_dark/f', (xx + dx, yy - .04, zz + .025), (.012, .005, .02), 0)
            elif kind == 'swirl':
                pts = [(xx + math.cos(t) * .009 * t, yy + math.sin(t) * .009 * t, zz + .018) for t in [q * .5 for q in range(16)]]
                tube(p, 'glaze', pts, .018, 6)
            elif kind == 'roll':
                g.bun(p, (xx, yy, zz), .05, 'crust_light', 'seeds')
            elif kind == 'cookie':
                g.cookie(p, (xx, yy, zz), .04)
            elif kind == 'pretzel':
                g.pretzel(p, (xx, yy, zz), .06, angle=.3 * j)
            elif kind == 'tart':
                g.tart(p, (xx, yy, zz), .055, ['strawberry', 'blueberry', 'raspberry'][j % 3])
            else:
                box(p, 'eclair', (xx, yy, zz + .02), (.15, .045, .04), .014)
                box(p, 'chocolate', (xx, yy, zz + .043), (.14, .035, .01), .004)
    box(p, 'card/f', (0, -D / 2 - .016, H - .1), (.2, .006, .1), .002)
    text(p, 'ink/f', 'COOLING', facing(0, -D / 2 - .02, H - .1), .035, 'alegreya')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the café table
def _bentwood_chair(p, x, y, face):
    """A bentwood café chair at (x, y) whose sitter faces direction `face` (radians)."""
    with p.placed((x, y, 0), math.degrees(face) + 90):
        lathe(p, 'cane', [(0, 0), (.2, 0), (.205, .03), (0, .03)], (0, 0, .44), 20, True)
        torus(p, 'wood_dark', (0, 0, .455), .205, .018, seg=24, n=6)
        for a in (.6, 2.5, 3.8, 5.6):
            tube(p, 'wood_dark', [(math.cos(a) * .15, math.sin(a) * .15, .44), (math.cos(a) * .2, math.sin(a) * .2, .0)], .018, 6)
        torus(p, 'wood_dark', (0, 0, .2), .165, .011, seg=24, n=5)
        back = [(-.16, .14, .44), (-.18, .17, .72), (-.12, .2, .9), (0, .21, .95), (.12, .2, .9), (.18, .17, .72), (.16, .14, .44)]
        tube(p, 'wood_dark', [tuple(q) for q in bezier_chain(back)], .018, 6)
        inner = [(-.09, .15, .5), (-.11, .18, .7), (0, .19, .8), (.11, .18, .7), (.09, .15, .5)]
        tube(p, 'wood_dark', [tuple(q) for q in bezier_chain(inner)], .012, 5)


def bezier_chain(points, n=5):
    """A smooth curve through points (Catmull-Rom), for bentwood and wire."""
    pts = [Vector(q) for q in points]
    out = []
    for i in range(len(pts) - 1):
        p0 = pts[i - 1] if i > 0 else pts[i]
        p1, p2 = pts[i], pts[i + 1]
        p3 = pts[i + 2] if i + 2 < len(pts) else pts[i + 1]
        for j in range(n):
            t = j / n
            t2, t3 = t * t, t * t * t
            out.append(.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3))
    out.append(pts[-1])
    return out


def cafe_table():
    """A round marble bistro table on an iron tripod with two bentwood chairs: tea for two, a croissant, sugar and a
    little vase of flowers."""
    root, p, path = s.begin('bakery-cafe-table', 'v1')
    for i in range(3):
        a = i * math.tau / 3 + .5
        tube(p, 'iron', bezier_chain([(math.cos(a) * .3, math.sin(a) * .3, 0), (math.cos(a) * .2, math.sin(a) * .2, .08),
                                      (math.cos(a) * .06, math.sin(a) * .06, .25)]), .016, 6)
    lathe(p, 'iron', [(.06, .2), (.04, .3), (.035, .6), (.06, .66), (.12, .7), (.12, .71)], (0, 0, 0), 14, True)
    lathe(p, '@marble', [(0, .71), (.34, .71), (.35, .72), (.35, .74), (.34, .75), (0, .75)], (0, 0, 0), 32, True)
    z = .75
    s.cup(p, (-.15, -.06, z), .035, .06, angle=math.pi / 2)
    s.cup(p, (.16, .07, z), .035, .06, angle=-math.pi / 2)
    s.teapot(p, (.02, .17, z), .065, 'china_blue', angle=-.8)
    lathe(p, 'china', [(0, 0), (.08, 0), (.11, .012), (0, .006)], (.0, -.14, z), 18, True, cap0=False)
    g.croissant(p, (.0, -.14, z + .008), .06, angle=.4)
    lathe(p, 'china', [(.025, 0), (.04, .04), (.035, .05)], (-.18, .14, z), 12, True, cap1=False)
    for i in range(3):
        box(p, 'white/f', (-.18 + (i - 1) * .012, .14, z + .05), (.012, .012, .012), .002)
    lathe(p, 'glass_clear', [(.02, 0), (.03, .03), (.012, .1), (.015, .12)], (.2, -.15, z), 12, True, cap1=False)
    g.flower_bunch(p, (.2, -.15, z + .1), .1, 'flower_pink', 4, .02)
    _bentwood_chair(p, -.62, 0, 0)
    _bentwood_chair(p, .62, 0, math.pi)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the dresser
def dresser():
    """A bakery dresser: cupboards and drawers in oxblood with gilt lines, an oak top, and above it a rack of blue-and-
    white plates, cups on hooks, cake tins, copper jelly moulds and jars of sugar and sprinkles."""
    root, p, path = s.begin('bakery-dresser', 'v1')
    W, D = 2.06, .5
    box(p, JOIN, (0, .02, .45), (W, D - .04, .86), .01)
    box(p, 'oxblood_dark', (0, 0, .05), (W + .02, D + .03, .1), .006)
    for i in range(3):
        x = -W / 3 + i * W / 3
        s.panel(p, JOIN, x, -D / 2 + .02, .38, W / 3 - .06, .5, .05, .025, 'gold_leaf', 'brass', (x + (.2 if i != 1 else 0), .5 if i == 1 else .38))
        s.panel(p, JOIN, x, -D / 2 + .02, .76, W / 3 - .06, .16, .035, .02, None, 'brass')
    box(p, '@oak', (0, -.01, .9), (W + .08, D + .06, .05), .01)
    box(p, '@oak', (0, .2, 1.6), (W, .04, 1.36), .006)
    for x in (-W / 2 + .03, W / 2 - .03):
        box(p, '@oak', (x, .06, 1.6), (.06, .3, 1.36), .006)
    s.cornice(p, '@oak', 0, W, -.1, .32, 2.28)
    box(p, JOIN, (0, -.08, 2.18), (W - .06, .02, .14), .004)
    for i, z in enumerate((1.3, 1.72, 2.1)):
        box(p, '@oak', (0, .06, z - .02), (W - .06, .28, .025), .004)
        if i < 2:
            rod(p, '@oak', (-W / 2 + .06, -.04, z + .05), (W / 2 - .06, -.04, z + .05), .01, 6)
    # Plates on the middle shelf.
    for i in range(7):
        x = -W / 2 + .2 + i * (W - .4) / 6
        s.plate(p, (x, .1, 1.28), .12 if i % 2 else .14, 'china', 'china_blue' if i % 3 else 'oxblood', tilt=.2)
    # Cups on hooks under the top shelf.
    for i in range(8):
        x = -W / 2 + .15 + i * (W - .3) / 7
        rod(p, 'brass', (x, .0, 2.07), (x, -.02, 2.0), .004, 4)
        s.cup(p, (x, -.04, 1.92), .03, .05, 'china', 'china_blue', saucer=False, liquid=None, angle=-math.pi / 2)
    # Lower shelf: cake tins, copper moulds, jars.
    zz = 0.925
    for i in range(3):
        s.tin(p, (-.82, .02, zz + i * .13), .12, .13 - i * .015, ['enamel_white', 'label_red', 'enamel_blue'][i], 'oxblood')
    for i, x in enumerate((-.5, -.3, -.1)):
        lathe(p, 'copper', [(0, 0), (.08, 0), (.085, .03), (.07, .08), (.05, .11), (.02, .12), (0, .12)], (x, .02, zz), 16, True,
              ripple=lambda a, z: 1 + .1 * math.cos(a * 8), cap0=False)
    for i, (x, fill) in enumerate(((.12, 'icing_pink'), (.3, 'sesame'), (.48, 'flour'), (.66, 'mac_pist'))):
        s.jar(p, (x, .03, zz), .2, .06, fill, 'copper' if i % 2 else 'gold')
    for i in range(3):
        box(p, ['pink_box', 'mint_box', 'card'][i], (.88, .02, zz + .05 + i * .1), (.2, .2, .09), .008)
        box(p, 'ribbon_red/f', (.88, .02, zz + .05 + i * .1), (.205, .015, .092), 0)
    # Top shelf: jelly moulds and a tall jar of wooden spoons.
    for i in range(4):
        x = -.8 + i * .45
        lathe(p, 'copper', [(0, 0), (.07, 0), (.075, .05), (.05, .1), (.02, .13), (0, .13)], (x, .06, 2.11), 14, True,
              ripple=lambda a, z: 1 + .12 * math.cos(a * 6), cap0=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the pendant
def pendant():
    """A green enamel shop pendant: a ceiling rose, a long cord, a brass gallery and a wide shade, white inside, with a
    bulb (lamp glass) for the room to bind. The pivot is the suspension point at the top of the walls (4.1 m); the
    shade hangs 1.26 m below it."""
    root, p, path = s.begin('bakery-pendant', 'v1')
    lathe(p, 'cream_paint', [(0, 0), (.1, 0), (.09, -.03), (0, -.04)], (0, 0, 0), 18, True)
    rod(p, 'ink', (0, 0, -.04), (0, 0, -.97), .006, 5)
    with p.placed((0, 0, -.25)):
        lathe(p, 'brass', [(0, -.82), (.06, -.82), (.04, -.78), (.035, -.72), (0, -.72)], (0, 0, 0), 16, True)
        lathe(p, 'enamel_green', [(.33, -1.01), (.32, -1.0), (.26, -.96), (.12, -.86), (.06, -.82)], (0, 0, 0), 28, True,
              cap0=False, cap1=False)
        lathe(p, 'enamel_white', [(.055, -.835), (.11, -.875), (.25, -.97), (.315, -1.0)], (0, 0, 0), 28, True,
              cap0=False, cap1=False)
        torus(p, 'enamel_green', (0, 0, -1.005), .325, .008, seg=28, n=4)
        lathe(p, 'brass', [(0, -.83), (.065, -.83), (.07, -.8), (0, -.8)], (0, 0, 0), 16, True)
        lathe(p, 'shops_lamp_glass', [(0, -.97), (.05, -.95), (.06, -.9), (.035, -.85), (0, -.84)], (0, 0, 0), 14, True, cap0=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- pretzel stand
def pretzel_stand():
    """A turned oak pretzel tree by the door: pegs of salted pretzels round a pole, a tray of rolls at its waist,
    a gilt pretzel on top and a chalk price."""
    root, p, path = s.begin('bakery-pretzel-stand', 'v1')
    lathe(p, '@oak', [(.3, 0), (.32, .03), (.28, .06), (.1, .1), (.05, .14)], (0, 0, 0), 24, True)
    lathe(p, '@oak', [(.045, .12), (.04, .5), (.055, .55), (.04, .6), (.035, 1.6), (.05, 1.65), (.03, 1.7)], (0, 0, 0), 14, True)
    lathe(p, '@oak', [(0, .6), (.3, .6), (.32, .62), (.31, .66), (.28, .66), (.28, .63), (0, .63)], (0, 0, 0), 28, True)
    for i in range(9):
        a = i * math.tau / 9
        g.bun(p, (math.cos(a) * .2, math.sin(a) * .2, .63), .05, 'crust_light', 'seeds' if i % 2 else None)
    for level, z in enumerate((.95, 1.22, 1.48)):
        for i in range(4):
            a = i * math.pi / 2 + level * .4
            d = Vector((math.cos(a), math.sin(a), 0))
            rod(p, '@oak', (d.x * .03, d.y * .03, z), (d.x * .26, d.y * .26, z + .06), .012, 6)
            ball(p, '@oak', (d.x * .27, d.y * .27, z + .065), .018)
            with p.framed(Matrix.Translation((d.x * .2, d.y * .2, z - .05)) @ Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(math.pi / 2, 4, 'Y')):
                g.pretzel(p, (0, 0, -.01), .07, 'crust_dark', 0)
    with p.framed(Matrix.Translation((0, 0, 1.82)) @ Matrix.Rotation(math.pi / 2, 4, 'X')):
        g.pretzel(p, (0, 0, -.03), .12, 'gold_leaf', 0, salt=False)
    box(p, 'chalk', (0, -.32, .7), (.24, .015, .14), .004, rot=(-.3, 0, 0))
    text(p, 'chalk_line/f', 'PRETZELS 2D', s.k.facing_text(0, -.33, .7, (0, -1)) @ Matrix.Rotation(-.3, 4, 'X'), .028, 'alegreya')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- gift étagère
def gift_stand():
    """A three-tier oak and iron étagère of things to take home: jam jars with gingham caps, honey, biscuit tins,
    ribbon-tied bags of biscuits and boxed cakes."""
    root, p, path = s.begin('bakery-gift-stand', 'v1')
    W, D = 1.1, .44
    for x in (-W / 2, W / 2):
        for y in (-D / 2, D / 2):
            rod(p, 'iron', (x, y, 0), (x, y, 1.32), .014, 6)
            ball(p, 'brass', (x, y, 1.34), .022)
    for i, z in enumerate((.3, .72, 1.12)):
        inset = i * .0
        box(p, '@oak', (0, 0, z), (W + .04, D + .02, .035), .008)
        tube(p, 'iron', [(-W / 2, -D / 2, z + .1), (W / 2, -D / 2, z + .1)], .006, 4)
        for x in (-W / 2 + .2, 0, W / 2 - .2):
            tube(p, 'iron', [(x - .1, -D / 2, z + .02), (x, -D / 2, z + .1), (x + .1, -D / 2, z + .02)], .005, 4)
    z = .3175
    for i in range(6):
        x = -W / 2 + .1 + i * (W - .2) / 5
        for row, yy in enumerate((-.08, .1)):
            s.jar(p, (x, yy, z), .13, .045, ['jam', 'raspberry', 'blueberry', 'lemon', 'jam', 'mac_choc'][(i + row) % 6], 'gold')
            lathe(p, '@gingham_red' if (i + row) % 2 else '@gingham_blue', [(0, .125), (.065, .118), (.06, .135), (0, .14)],
                  (x, yy, z), 12, True, cap0=False, ripple=lambda a, zz: 1 + .1 * math.cos(a * 7))
    z = .7375
    for i in range(3):
        x = -W / 2 + .2 + i * .35
        s.tin(p, (x, .02, z), .14, .1, ['enamel_blue', 'oxblood', 'enamel_green'][i], 'gold')
        text(p, 'gold_leaf/f', 'BISCUITS', s.k.facing_text(x, .02 - .102, z + .07, (0, -1)), .022, 'cinzel')
    for i in range(4):
        x = -W / 2 + .14 + i * .27
        lathe(p, 'shops_clear_glass', [(.05, 0), (.07, .12), (.05, .2), (.02, .24), (.03, .27)], (x, -.15, z), 10, True, cap1=False)
        for j in range(5):
            g.cookie(p, (x + (j % 2 - .5) * .03, -.15, z + .01 + j * .028), .03 if j < 4 else .025)
        torus(p, 'ribbon_red/f', (x, -.15, z + .21), .025, .006, seg=10, n=4)
    z = 1.1375
    for i in range(3):
        x = -W / 2 + .2 + i * .35
        box(p, ['pink_box', 'mint_box', 'card'][i], (x, 0, z + .06), (.26, .26, .12), .01)
        box(p, 'ribbon_red/f', (x, 0, z + .06), (.272, .02, .13), 0)
        box(p, 'ribbon_red/f', (x, 0, z + .06), (.02, .272, .13), 0)
        for b in (-1, 1):
            ball(p, 'ribbon_red/f', (x + b * .02, 0, z + .13), .025, (1.4, .6, .7))
    box(p, 'card/f', (0, -D / 2 - .01, 1.2), (.3, .006, .12), .003)
    text(p, 'oxblood/f', 'TO TAKE HOME', s.k.facing_text(0, -D / 2 - .015, 1.2, (0, -1)), .034, 'cinzel')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- run
AUTHORS = {'bakery-shell': shell, 'bakery-oven': oven, 'bakery-bread-wall': bread_wall, 'bakery-counter': counter,
           'bakery-cake-table': cake_table, 'bakery-proving-table': bench, 'bakery-proving-cabinet': proving_cabinet,
           'bakery-mixer': mixer, 'bakery-flour-sacks': flour_sacks, 'bakery-cooling-rack': cooling_rack,
           'bakery-cafe-table': cafe_table, 'bakery-dresser': dresser, 'bakery-pendant': pendant,
           'bakery-pretzel-stand': pretzel_stand, 'bakery-gift-stand': gift_stand}

if __name__ == '__main__':
    s.run(AUTHORS, RECORD)
