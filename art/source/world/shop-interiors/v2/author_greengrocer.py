"""The Pantry, second pass (2026-11-12): Teo Vasko's provisions shop, the room and its furniture as editable masters.

    blender -b --factory-startup --python author_greengrocer.py -- [asset-id ...]

Refuses an existing master unless it is this record's own untouched output and `--redo` is given. After adoption,
edit each model.blend and rebuild with scripts/world-art.sh build <id>.

The Pantry's colours are bottle-green painted boards, sage sprig paper, limestone flags, oak, zinc and wicker; it is
a market hall in one room: a barrow, a produce island, barrels, bins, a cheese case and buckets of flowers.
"""
from pathlib import Path
import math
import random
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent))
import interior_kit as s  # noqa: E402
import goods as g  # noqa: E402
from interior_kit import arc, ball, box, facing, lathe, rod, sheet, soft, text, torus, tube  # noqa: E402
from mathutils import Matrix, Vector  # noqa: E402

RECORD = __file__
JOIN = '#bottle'
R = random.Random(1201)
WEST_OPEN = [(4.2, 1.6, .95, 2.8)]
NORTH_OPEN = [(5.2, 1.2, 1.1, 2.8), (10.9, .9, 0.0, 2.3)]

# The painted green boards come from the timber-panel painting, tinted.
s.SURFACES['green_boards'] = (lambda: s._reduced('green-boards-256', s.NATIVE / 'timber_panels.png', 256, '6f9f80'), .7, 1.2)


def label(p, words, x, y, z, w=.16, h=.08, size=.035, face=(0, -1), chalk=True):
    """A slate price tag (or a paper one) facing `face`."""
    fx, fy = face
    if fx == 0:
        box(p, 'chalk' if chalk else 'card', (x, y, z), (w, .012, h), .003)
        text(p, ('chalk_line' if chalk else 'ink') + '/f', words, s.k.facing_text(x, y + fy * .008, z, face), size, 'alegreya')
    else:
        box(p, 'chalk' if chalk else 'card', (x, y, z), (.012, w, h), .003)
        text(p, ('chalk_line' if chalk else 'ink') + '/f', words, s.k.facing_text(x + fx * .008, y, z, face), size, 'alegreya')


# ------------------------------------------------------------------------------------------------- the room
def doormat(p, colour, inner, words, size):
    """A coir doormat inside the door: base, a coloured border and a lettered field, each layer 6 mm above the last."""
    box(p, 'kraft', (6, .32, .012), (1.15, .62, .024), .01)
    box(p, colour, (6, .32, .027), (1.0, .5, .006), 0)
    box(p, inner, (6, .32, .033), (.94, .44, .006), 0)
    text(p, colour, words, s.flat_text(6, .32, .0375), size, 'cinzel')


def shell():
    """Limestone flags; bottle-green painted boards to the dado with a cream cap; sage sprig paper above; a wall rail
    of onion and garlic strings and drying herbs; a ledged store door; a big painted sign; a slate menu of the day."""
    root, p, path = s.begin('greengrocer-shell', 'v2')
    s.floor(p, 'floor_flags', 3.0)
    for wall, openings in ((s.NORTH, NORTH_OPEN), (s.WEST, WEST_OPEN)):
        s.strip(p, '@sage_paper', wall, 0, s.HEIGHT, 0, -.24, openings)
        s.strip(p, 'bottle_dark', wall, 0, .16, .035, 0, openings)
        s.strip(p, '@green_boards', wall, .16, 1.42, .018, 0, openings, bevel=0)
        s.strip(p, 'cream_paint', wall, 1.42, 1.5, .045, 0, openings)
        s.strip(p, 'bottle', wall, 1.5, 1.53, .03, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.55, 3.66, .05, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.66, 3.74, .085, 0, openings)
        s.strip(p, 'bottle', wall, 3.74, 3.78, .095, 0, openings)
    # The boards are grooved: thin dark lines every 12 cm.
    for wall, openings in ((s.NORTH, NORTH_OPEN), (s.WEST, WEST_OPEN)):
        a, b = wall['span']
        n = int((b - a) / .12)
        for i in range(1, n):
            u = a + i * .12
            if any(abs(u - c) < w / 2 + .02 and o0 < 1.42 for c, w, o0, o1 in openings):
                continue
            s.wall_box(p, 'bottle_dark/f', wall, u, .02, .79, .008, .004, 1.26, 0)
    s.window(p, s.WEST, 4.2, 1.6, .95, 2.8, '#cream_paint', '@oak', (3, 3))
    s.window(p, s.NORTH, 5.2, 1.2, 1.1, 2.8, '#cream_paint', '@oak', (2, 3))
    # Herbs drying in the rear window on a string, and pots on both sills.
    x0, x1 = 4.7, 5.7
    tube(p, 'string', [(x0, 11.38, 2.5), ((x0 + x1) / 2, 11.38, 2.44), (x1, 11.38, 2.5)], .004, 3)
    for i in range(6):
        x = x0 + .1 + i * .16
        z = 2.48 - .06 * math.sin(math.pi * (i + .5) / 6)
        for j in range(5):
            a = j * 1.2
            tube(p, ['herb', 'lavender', 'leaf_mid'][i % 3] + '/f', [(x, 11.38, z), (x + math.cos(a) * .03, 11.38 + math.sin(a) * .02, z - .25)], .012, 4)
        torus(p, 'string/f', (x, 11.38, z - .03), .02, .004, seg=8, n=3)
    for i, x in enumerate((4.85, 5.2, 5.55)):
        g.herbs_pot(p, (x, 11.42, 1.1), .06, ['herb', 'leaf_mid', 'herb'][i])
    for i, yy in enumerate((3.65, 4.2, 4.75)):
        g.herbs_pot(p, (-.42, yy, .95), .065, ['leaf_mid', 'herb', 'lavender'][i])
    # The store door: ledged and braced boards in bottle green, a thumb latch, a cream architrave, a STORE plate.
    c = 10.9
    for dx in (-.505, .505):
        s.wall_box(p, 'cream_paint', s.NORTH, c + dx, .02, 1.17, .13, .06, 2.34)
    s.wall_box(p, 'cream_paint', s.NORTH, c, .02, 2.37, 1.14, .06, .12)
    for i in range(6):
        s.wall_box(p, JOIN, s.NORTH, c - .375 + i * .15, -.1, 1.15, .145, .05, 2.3, .004)
    for z in (.35, 1.15, 1.95):
        s.wall_box(p, JOIN, s.NORTH, c, -.06, z, .86, .035, .12, .005)
    for z0, z1 in ((.35, 1.15), (1.15, 1.95)):
        dz, dx = z1 - z0, .7
        ang = math.atan2(dz, dx)
        box(p, s.joinery('paint_bottle', s.PALETTE['bottle']), (c, 11.545, (z0 + z1) / 2), (math.hypot(dx, dz), .03, .1), .004,
            rot=(0, -ang, 0))
    rod(p, 'iron', (c + .3, 11.52, 1.1), (c + .3, 11.49, 1.1), .02, 8)
    tube(p, 'iron', [(c + .18, 11.5, 1.12), (c + .34, 11.5, 1.12)], .008, 4)
    box(p, 'brass', (c, 11.52, 1.62), (.28, .01, .08), .002)
    text(p, 'brass_dark/f', 'STORE', facing(c, 11.514, 1.62), .045, 'cinzel')
    # A wall rail of onion and garlic strings and a basket over the sacks on the west wall.
    x, _, _ = s.on_wall(s.WEST, 0, .1, 0)
    rod(p, '@oak', (x - .04, 7.9, 2.3), (x - .04, 11.1, 2.3), .03, 8)
    for i in range(7):
        y = 8.1 + i * .45
        rod(p, 'iron', (x - .06, y, 2.3), (x + .02, y, 2.28), .008, 4)
        kind = ['onion', 'garlic', 'onion_red', 'garlic', 'onion', 'chilli', 'garlic'][i]
        for j in range(9 if kind != 'chilli' else 12):
            zz = 2.22 - j * .075
            side = .035 if j % 2 else -.035
            if kind == 'chilli':
                rod(p, 'pepper/f', (x + .02, y + side * .6, zz), (x + .04, y + side * 1.2, zz - .09), .012, 6, rb=.003)
            else:
                g.onion(p, (x + .04, y + side, zz - .04), .038 if kind != 'garlic' else .032, kind if kind != 'garlic' else 'garlic')
        rod(p, 'string/f', (x + .03, y, 2.28), (x + .03, y, 2.22 - (9 if kind != 'chilli' else 12) * .075), .006, 4)
    # A painted sign board high on the north wall, and a slate of the day's specials on the west wall.
    s.wall_box(p, JOIN, s.NORTH, 2.0, .03, 3.12, 3.2, .05, .52, .02)
    s.wall_box(p, 'gold_leaf', s.NORTH, 2.0, .06, 3.12, 3.06, .01, .4, .002)
    s.wall_box(p, JOIN, s.NORTH, 2.0, .07, 3.12, 3.0, .012, .34, .002)
    s.wall_text(p, 'cream/f', 'T. VASKO  ·  PROVISIONS', s.NORTH, 2.0, .08, 3.15, .16)
    s.wall_text(p, 'gold_leaf/f', 'FRUIT  ·  GREENGROCERY  ·  DAIRY  ·  DRY GOODS', s.NORTH, 2.0, .08, 2.99, .055)
    xw, yw, zw = s.on_wall(s.WEST, 1.6, .03, 2.45)
    box(p, '@oak', (xw, yw, zw), (.05, 1.0, .8), .01)
    box(p, 'chalk', (xw + .028, yw, zw), (.008, .88, .68), 0)
    for j, line in enumerate(['TODAY', 'PEARS  3P', 'CHERRIES  6P', 'NEW POTATOES', 'EGGS  1D EACH']):
        text(p, ('chalk_line' if j else 'gold_leaf') + '/f', line, s.k.facing_text(xw + .034, yw, zw + .24 - j * .12, (1, 0)),
             .065 if j == 0 else .05, 'alegreya')
    # Doormat and a hanging brass shop bell.
    doormat(p, 'bottle/f', 'kraft', 'THE PANTRY', .1)
    tube(p, 'iron', [(6.62, -.3, 3.0), (6.62, -.15, 3.0), (6.6, -.05, 2.98), (6.6, 0, 2.82)], .006, 5)
    lathe(p, 'brass', [(0, 0), (.06, 0), (.05, .02), (.03, .08), (0, .1)], (6.6, -.0, 2.72), 14, True, cap0=False)
    s.front_door(p, 'pantry', 'bottle', 'cream')
    s.beams(p)
    p.finish(root)
    s.hinge_doors('pantry')
    s.finish(root, s.Parts(1), path, RECORD, extras={'room': 'shop-greengrocer', 'door_colour': s.PALETTE['bottle']})


# ------------------------------------------------------------------------------------------------- produce island
def produce_stand():
    """A double-sided island of tilted crates and baskets: apples three ways, oranges, lemons, pears, plums, grapes,
    bananas, tomatoes, peppers, cabbages and carrots, each with a slate price; a gilt sign on a riser."""
    root, p, path = s.begin('greengrocer-produce-stand', 'v2')
    W, D = 2.9, 1.4
    for x in (-W / 2 + .05, 0, W / 2 - .05):
        for y in (-D / 2 + .05, D / 2 - .05):
            box(p, '@oak', (x, y, .35), (.08, .08, .7), .008)
    box(p, '@oak', (0, 0, .12), (W - .1, D - .1, .04), .006)
    for i in range(5):
        box(p, '@oak', (-W / 2 + .3 + i * (W - .6) / 4, 0, .16), (.25, D - .2, .1), .01)
    for side in (-1, 1):
        for x in (-W / 2 + .05, W / 2 - .05):
            p.solid(s.surface('oak'), [(x, side * .02, .7), (x, side * (D / 2), .52), (x, side * (D / 2), .58), (x, side * .02, 1.06)],
                    .05, (1, 0, 0))
    goods = {-1: ['apple', 'orange', 'lemon', 'apple_green', 'pear'], 1: ['plum', 'tomato', 'apple_gold', 'pepper', 'lime']}
    for side in (-1, 1):
        tilt = -side * .3
        for i, kind in enumerate(goods[side]):
            x = -W / 2 + .32 + i * (W - .64) / 4
            m = Matrix.Translation((x, side * .36, .74)) @ Matrix.Rotation(tilt, 4, 'X')
            with p.framed(m):
                s.crate(p, (0, 0, -.08), .52, .5, .16, '@oak', 'wood_dark', 2)
                g.heap(p, kind, (0, 0, .02), .44, .42, 2)
            label(p, kind.replace('_', ' ').replace('apple green', 'BRAMLEY').replace('apple gold', 'GOLDEN').upper()[:9],
                  x, side * .62, .64, .2, .08, .03, (0, side))
    # The ridge: a riser with grapes, bananas and a basket of cabbages and carrots, and a gilt sign.
    box(p, '@oak', (0, 0, 1.08), (W - .1, .26, .06), .008)
    for i, x in enumerate((-1.1, -.55, 0, .55, 1.1)):
        if i in (0, 4):
            s.basket(p, (x, 0, 1.11), .17, .12, False)
            for j in range(3):
                g.cabbage(p, (x + (j - 1) * .09, (j % 2) * .04, 1.13), .075)
        elif i == 2:
            g.banana_bunch(p, (x - .1, -.02, 1.11), .2, angle=.4)
            g.banana_bunch(p, (x + .12, .03, 1.11), .18, angle=-.5)
        else:
            s.basket(p, (x, 0, 1.11), .16, .1, False)
            g.grapes(p, (x - .04, 0, 1.15), .12, 'grape' if i == 1 else 'grape_dark', .3)
            g.grapes(p, (x + .06, .03, 1.15), .1, 'grape' if i == 1 else 'grape_dark', -.5)
    for x in (-W / 2 + .1, W / 2 - .1):
        rod(p, '@oak', (x, 0, 1.08), (x, 0, 1.75), .03, 8)
    box(p, JOIN, (0, 0, 1.65), (W - .1, .05, .26), .01)
    for side in (-1, 1):
        box(p, 'gold_leaf', (0, side * .032, 1.65), (W - .2, .004, .2), 0)
        box(p, JOIN, (0, side * .04, 1.65), (W - .26, .004, .16), 0)
        text(p, 'cream/f', 'FRESH FROM THE HILLS', s.k.facing_text(0, side * .046, 1.65, (0, side)), .1, 'cinzel')
    # Carrot bunches and a basket of paper bags at the ends.
    for side in (-1, 1):
        g.carrot_bunch(p, (side * (W / 2 + .02), -.2, .72), 5, .17, math.pi / 2)
        g.carrot_bunch(p, (side * (W / 2 + .02), .15, .72), 5, .17, math.pi / 2)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the counter
def counter():
    """The provisions counter: bottle-green panels and a marble top; a cheese case at the left with wheels, wedges,
    a dome and a wire; at the right a brass beam scale, a red coffee mill, the till, paper bags and string."""
    root, p, path = s.begin('greengrocer-counter', 'v2')
    W, D, H = 3.8, .95, .96
    box(p, JOIN, (0, .02, H / 2), (W - .04, D - .06, H - .06), .01)
    box(p, 'bottle_dark', (0, 0, .045), (W, D + .01, .09), .008)
    for i in range(5):
        x = -W / 2 + W / 10 + i * W / 5
        s.panel(p, JOIN, x, -D / 2 + .01, .5, W / 5 - .06, .66, .06, .03, 'cream')
    for side in (-1, 1):
        with p.placed((side * (W / 2 - .01), 0, 0), 90 * side):
            s.panel(p, JOIN, 0, -.01, .5, D - .14, .66, .06, .03, 'cream')
    box(p, '@marble_green', (0, 0, H + .03), (W + .08, D + .06, .06), .015)
    # Cheese case: a slanted glass front on brass, cheeses on a slate.
    x0, x1 = -W / 2 + .08, -.15
    box(p, 'slate', ((x0 + x1) / 2, .0, H + .075), (x1 - x0, .7, .03), .004)
    for x in (x0, x1):
        p.solid('shops_clear_glass', [(x, -.38, H + .06), (x, .3, H + .06), (x, .3, H + .46), (x, .05, H + .46)], .008, (1, 0, 0))
        tube(p, 'brass', [(x, -.38, H + .06), (x, .05, H + .46), (x, .3, H + .46)], .01, 6)
    sheet(p, 'shops_clear_glass', lambda u, v: (x0 + u * (x1 - x0), -.38 + v * .43, H + .06 + v * .4), 1, 1, .006, rims=False)
    box(p, 'shops_clear_glass', ((x0 + x1) / 2, .175, H + .46), (x1 - x0, .25, .006), 0)
    zc = H + .09
    cheeses = [(-1.6, -.1, .14, .1, 'cheese'), (-1.25, .1, .12, .12, 'cheese'), (-.9, -.12, .13, .08, 'milk'), (-.55, .08, .11, .1, 'wax')]
    for x, y, r, h, kind in cheeses:
        if kind == 'wax':
            lathe(p, 'wax', [(0, 0), (r, 0), (r * 1.02, h * .5), (r, h), (0, h)], (x, y, zc), 20, True)
        elif kind == 'milk':
            lathe(p, 'cream', [(0, 0), (r, 0), (r, h), (0, h)], (x, y, zc), 20, True)
            box(p, 'rind/f', (x, y, zc + h + .002), (r * 1.3, r * 1.3, .002), 0, rot=(0, 0, .785))
        else:
            # A wheel, and a wedge cut from it lying in front to show the paste.
            lathe(p, 'rind', [(0, 0), (r, 0), (r * 1.04, h * .5), (r, h), (0, h)], (x, y, zc), 24, True)
            p.solid('cheese', [(x - .07, y - r - .03, zc), (x + .07, y - r - .03, zc), (x, y - r + .05, zc)], h * .9, (0, 0, -1))
        box(p, 'card/f', (x, y - r - .03, zc + .03), (.07, .004, .035), 0, rot=(.4, 0, 0))
    for i in range(3):
        a = .4 + i * .9
        p.solid('cheese', [(-1.0 + i * .14, .18, zc), (-.92 + i * .14, .18, zc), (-.96 + i * .14, .3, zc)], .06, (0, 0, -1))
    lathe(p, 'shops_clear_glass', [(.11, 0), (.11, .1), (.06, .16), (0, .17)], (-.35, -.12, zc), 18, True, cap0=False)
    lathe(p, 'cheese', [(0, 0), (.08, 0), (.08, .06), (0, .06)], (-.35, -.12, zc), 18, True)
    rod(p, 'steel', (-1.75, -.3, H + .1), (-1.45, -.3, H + .1), .004, 4)
    for x in (-1.75, -1.45):
        rod(p, '@oak', (x, -.3, H + .1), (x, -.3, H + .16), .012, 6)
    # Beam scale with weights and a pear in the pan.
    sx = .25
    box(p, 'brass', (sx, .05, H + .08), (.42, .26, .04), .01)
    rod(p, 'brass', (sx, .05, H + .1), (sx, .05, H + .55), .022, 10)
    ball(p, 'brass', (sx, .05, H + .57), .03)
    rod(p, 'brass', (sx - .3, .05, H + .52), (sx + .3, .05, H + .52), .012, 8)
    for x, z in ((sx - .3, H + .26), (sx + .3, H + .28)):
        lathe(p, 'brass', [(0, 0), (.1, 0), (.12, .025), (.115, .03)], (x, .05, z), 18, True, cap1=False)
        for dx in (-.08, .08):
            rod(p, 'brass', (x + dx, .05, z + .03), (x, .05, H + .52), .002, 3)
    g.pear(p, (sx - .3, .05, H + .27), .04)
    for i, r in enumerate((.035, .03, .025, .02)):
        rod(p, 'brass', (sx + .3 - .02 + i * .0, .05, H + .29 + i * .03), (sx + .3, .05, H + .32 + i * .03), r, 12)
    # The coffee mill: red enamel with two spoked wheels and a brass hopper.
    mx = .9
    box(p, 'enamel_red', (mx, .12, H + .2), (.22, .2, .28), .03)
    lathe(p, 'brass', [(.03, 0), (.09, .12), (.1, .14)], (mx, .12, H + .34), 14, True, cap1=False)
    for side in (-1, 1):
        x = mx + side * .14
        torus(p, 'enamel_red', (x, .12, H + .3), .17, .015, normal=(1, 0, 0), seg=24, n=6)
        for i in range(6):
            a = i * math.tau / 6
            rod(p, 'enamel_red', (x, .12, H + .3), (x, .12 + math.cos(a) * .16, H + .3 + math.sin(a) * .16), .008, 4)
        rod(p, 'gold', (x - side * .02, .12, H + .3), (x + side * .03, .12, H + .3), .03, 10)
    rod(p, 'wood_dark', (mx + .17, .12 + .1, H + .44), (mx + .25, .12 + .1, H + .44), .018, 8)
    box(p, 'zinc', (mx, -.03, H + .12), (.12, .06, .08), .01)
    text(p, 'gold_leaf/f', 'COFFEE', s.k.facing_text(mx, .015, H + .26, (0, -1)), .035, 'cinzel')
    # Till, paper bags, string, ledger and bell.
    tx = 1.45
    box(p, '@oak', (tx, .15, H + .17), (.42, .34, .22), .02)
    box(p, '@oak', (tx, .2, H + .34), (.42, .2, .12), .015)
    box(p, 'brass', (tx, -.02, H + .2), (.3, .01, .08), .003)
    for i in range(3):
        rod(p, 'ink/f', (tx - .1 + i * .1, .0, H + .3), (tx - .1 + i * .1, -.01, H + .33), .015, 8)
    for i in range(12):
        box(p, 'kraft', (1.6, -.24, H + .065 + i * .006), (.26, .2, .005), 0, rot=(0, 0, .04 * (i % 3)))
    lathe(p, '@oak', [(0, 0), (.06, 0), (.05, .04), (.02, .05), (.02, .2), (0, .2)], (1.2, -.3, H + .06), 12, True)
    lathe(p, 'string', [(0, 0), (.055, 0), (.03, .1), (0, .12)], (1.2, -.3, H + .1), 12, True)
    box(p, 'wood_dark', (.55, -.18, H + .075), (.3, .22, .03), .006)
    box(p, 'paper', (.55, -.18, H + .095), (.28, .2, .01), 0)
    for i in range(5):
        box(p, 'ink/f', (.5 + (i % 2) * .08, -.24 + i * .03, H + .101), (.08, .004, .002), 0)
    lathe(p, 'brass', [(0, 0), (.05, 0), (.045, .02), (.012, .04), (0, .055)], (.05, -.32, H + .06), 16, True)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the jar dresser
def jar_shelves():
    """A tall green dresser of preserves, honey with dippers, oil bottles, tea and spice tins, labelled and turned to
    the front, with a library ladder on a brass rail and drawers of loose tea below."""
    root, p, path = s.begin('greengrocer-jar-shelves', 'v2')
    W, D, H = 3.6, .5, 2.35
    box(p, JOIN, (0, .02, .42), (W, D - .04, .84), .01)
    for i in range(6):
        x = -W / 2 + W / 12 + i * W / 6
        s.panel(p, JOIN, x, -D / 2 + .02, .62, W / 6 - .04, .3, .04, .02, None, 'brass')
        s.panel(p, JOIN, x, -D / 2 + .02, .27, W / 6 - .04, .34, .04, .02, None, 'brass')
        box(p, 'card/f', (x, -D / 2 + .005, .72), (.12, .004, .05), 0)
        text(p, 'ink/f', ['ASSAM', 'CEYLON', 'DARJEEL', 'CLOVES', 'NUTMEG', 'CINNAM'][i], facing(x, -D / 2 + .002, .72), .022, 'alegreya')
    box(p, '@oak', (0, 0, .86), (W + .06, D + .04, .05), .01)
    box(p, '@green_boards', (0, D / 2 - .03, 1.6), (W - .06, .03, 1.45), 0)
    for x in (-W / 2 + .04, -W / 6 * 1.0 - .0, W / 6, W / 2 - .04):
        box(p, '@oak', (x, 0, 1.6), (.07, D - .06, 1.46), .008)
    s.cornice(p, '@oak', 0, W, -D / 2, D, H - .02)
    rows = (1.0, 1.38, 1.76, 2.12)
    for r, z in enumerate(rows):
        box(p, '@oak', (0, .0, z - .02), (W - .08, D - .1, .03), .005)
        for i in range(12):
            x = -W / 2 + .17 + i * (W - .34) / 11
            kind = (i + r * 2) % 6
            y = -.04
            if kind == 0:
                s.jar(p, (x, y, z), .2, .065, ['jam', 'raspberry', 'blueberry', 'lemon'][(i + r) % 4], 'gold')
            elif kind == 1:
                s.jar(p, (x, y, z), .17, .07, 'honey', 'gold')
                rod(p, '@oak', (x + .02, y, z + .15), (x + .05, y, z + .25), .008, 5)
            elif kind == 2:
                s.bottle(p, (x, y, z), .3, .045, ['glass_green', 'glass_amber', 'oil'][(i + r) % 3])
            elif kind == 3:
                s.tin(p, (x, y, z), .16, .06, ['tea', 'label_red', 'label_blue', 'enamel_green'][(i + r) % 4], 'gold')
            elif kind == 4:
                s.jar(p, (x, y, z), .22, .06, ['onion', 'pepper', 'leaf', 'crumb'][(i + r) % 4], 'steel')
            else:
                for j in range(3):
                    s.tin(p, (x, y + .02 - j * .0, z + j * .065), .06, .06 - j * .006, ['label_red', 'gold', 'label_blue'][j], 'steel')
    rod(p, 'brass', (-W / 2, -D / 2 - .1, 2.15), (W / 2, -D / 2 - .1, 2.15), .016, 8)
    for x in (-W / 2 + .1, W / 2 - .1):
        rod(p, 'brass', (x, -D / 2 - .1, 2.15), (x, -D / 2 + .05, 2.15), .012, 6)
    # The library ladder hung on the rail, leaning out at the foot.
    lx = .7
    for dx in (-.2, .2):
        rod(p, '@oak', (lx + dx, -D / 2 - .1, 2.17), (lx + dx, -D / 2 - .62, 0), .025, 8)
    for i in range(7):
        t = (i + 1) / 8
        y = -D / 2 - .1 - .52 * t
        z = 2.17 * (1 - t)
        rod(p, '@oak', (lx - .2, y, z), (lx + .2, y, z), .018, 6)
    for dx in (-.2, .2):
        tube(p, 'brass', [(lx + dx, -D / 2 - .1, 2.17), (lx + dx, -D / 2 - .1, 2.2), (lx + dx, -D / 2 - .14, 2.2)], .01, 5)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- dry goods bins
def bin_wall():
    """A general store's bin wall: sloped glass-fronted hoppers of rice, lentils, beans, oats, sugar and coffee
    beans below brass-labelled drawers, with tins and boxes on the shelves above and a scoop on a hook."""
    root, p, path = s.begin('greengrocer-bin-wall', 'v1')
    W, D, H = 3.6, .6, 2.5
    box(p, '@oak', (0, .02, .69), (W, D - .04, 1.38), .01)
    box(p, 'bottle_dark', (0, -.02, .05), (W + .02, D, .1), .006)
    box(p, '@green_boards', (0, D / 2 - .03, 1.94), (W - .06, .03, 1.12), 0)
    for x in (-W / 2 + .03, -W / 6, W / 6, W / 2 - .03):
        box(p, '@oak', (x, 0, 1.94), (.06, D - .06, 1.12), .006)
    fills = ['white', 'onion', 'egg_brown', 'cream', 'flour', 'coffee']
    names = ['RICE', 'LENTILS', 'BEANS', 'OATS', 'SUGAR', 'COFFEE']
    for i in range(6):
        x = -W / 2 + W / 12 + i * W / 6
        w = W / 6 - .05
        # Hopper: a sloped front with a glass window showing the goods.
        p.solid(s.surface('oak'), [(x - w / 2, -D / 2, .12), (x + w / 2, -D / 2, .12), (x + w / 2, -D / 2 - .12, .78),
                                   (x - w / 2, -D / 2 - .12, .78)], .03, (0, -1, .2))
        sheet(p, fills[i], lambda u, v, x=x, w=w: (x - w / 2 + .05 + u * (w - .1), -D / 2 - .03 - v * .07, .25 + v * .4), 1, 1, .004, rims=False)
        sheet(p, 'shops_clear_glass', lambda u, v, x=x, w=w: (x - w / 2 + .05 + u * (w - .1), -D / 2 - .05 - v * .08, .22 + v * .45), 1, 1, .004, rims=False)
        for z in (.22, .68):
            box(p, '@oak', (x, -D / 2 - .02 - (z - .12) / .66 * .12, z), (w - .04, .04, .04), .004)
        box(p, 'brass', (x, -D / 2 - .14, .82), (.2, .01, .07), .002)
        text(p, 'brass_dark/f', names[i], facing(x, -D / 2 - .146, .82), .035, 'cinzel')
        # Two drawers above each hopper.
        for z in (1.0, 1.24):
            s.panel(p, '@oak', x, -D / 2 - .0, z, w, .2, .03, .02, None, 'brass')
            box(p, 'card/f', (x, -D / 2 - .025, z + .05), (.08, .004, .03), 0)
    box(p, '@oak', (0, -.02, 1.38), (W + .06, D + .04, .04), .006)
    for r, z in enumerate((1.45, 1.85, 2.22)):
        box(p, '@oak', (0, .0, z), (W - .06, D - .1, .03), .004)
        for i in range(10):
            x = -W / 2 + .2 + i * (W - .4) / 9
            kind = (i + r) % 4
            if kind == 0:
                for j in range(2):
                    box(p, ['label_red', 'label_blue', 'butter', 'label_green'][(i + j) % 4], (x, -.05, z + .1 + j * .17), (.18, .12, .16), .008)
                    box(p, 'cream/f', (x, -.116, z + .1 + j * .17), (.12, .004, .07), 0)
            elif kind == 1:
                s.tin(p, (x, -.05, z + .015), .24, .07, ['enamel_green', 'oxblood', 'label_blue'][(i + r) % 3], 'gold')
            elif kind == 2:
                s.jar(p, (x, -.05, z + .015), .26, .075, ['flour', 'sesame', 'onion', 'coffee'][(i + r) % 4], 'steel')
            else:
                for j in range(4):
                    rod(p, 'kraft', (x - .06 + j * .04, -.05, z + .015), (x - .06 + j * .04, -.05, z + .2), .02, 6)
                    rod(p, 'string/f', (x - .06 + j * .04, -.05, z + .17), (x - .06 + j * .04, -.05, z + .18), .021, 6)
    s.cornice(p, '@oak', 0, W, -D / 2, D, H)
    box(p, JOIN, (0, -D / 2 - .01, H - .06), (W - .1, .02, .1), .004)
    text(p, 'gold_leaf/f', 'DRY GOODS  ·  BY WEIGHT', facing(0, -D / 2 - .025, H - .06), .065, 'cinzel')
    for i, x in enumerate((-1.2, .6)):
        rod(p, 'brass', (x, -D / 2 - .14, .95), (x, -D / 2 - .2, .92), .006, 4)
        lathe(p, 'zinc', [(0, 0), (.06, 0), (.065, .1)], (x, -D / 2 - .26, .78), 12, True, cap1=False, axis=Matrix.Rotation(.3, 3, 'X'))
        rod(p, '@oak', (x, -D / 2 - .22, .89), (x, -D / 2 - .19, .95), .012, 6)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- sacks of grain
def sack_row():
    """Open sacks of potatoes, onions, split peas, oats and dried beans rolled down at the neck, each with a scoop
    and a slate, and a low crate of new potatoes in front."""
    root, p, path = s.begin('greengrocer-sack-row', 'v2')
    goods_ = [('potato', 'POTATOES'), ('onion', 'ONIONS'), ('mac_pist', 'SPLIT PEAS'), ('flour', 'OATS'), ('egg_brown', 'BEANS')]
    for i, (kind, name) in enumerate(goods_):
        x = -1.08 + i * .54
        lathe(p, '@burlap', [(.2, 0), (.25, .08), (.26, .4), (.24, .55)], (x, 0, 0), 18, True, cap1=False,
              ripple=lambda a, z: 1 + .05 * math.cos(a * 5 + z * 7 + i))
        torus(p, '@burlap', (x, 0, .56), .25, .045, seg=18, n=8)
        if kind in ('potato', 'onion'):
            for j in range(9):
                a = j * 2.4
                rr = .14 * math.sqrt((j + .5) / 9)
                (g.potato if kind == 'potato' else g.onion)(p, (x + math.cos(a) * rr, math.sin(a) * rr, .5 + (j % 3) * .02), .045)
        else:
            lathe(p, kind, [(0, .52), (.22, .52), (.14, .58), (0, .61)], (x, 0, 0), 16, True, cap0=False)
            for j in range(10):
                a = j * 2.4
                ball(p, kind + '/f', (x + math.cos(a) * .1 * (j / 10), math.sin(a) * .1 * (j / 10), .6), .02)
        if i % 2 == 0:
            lathe(p, 'zinc', [(0, 0), (.05, 0), (.055, .06)], (x + .06, -.05, .58), 12, True, cap1=False, axis=Matrix.Rotation(.8, 3, 'X'))
            rod(p, '@oak', (x + .06, -.1, .6), (x + .06, -.2, .7), .012, 6)
        rod(p, 'iron', (x, -.28, .2), (x, -.28, .5), .006, 4)
        label(p, name, x, -.29, .48, .22, .08, .028)
    s.crate(p, (0, -.52, 0), .8, .34, .18, '@oak', 'wood_dark', 2)
    g.heap(p, 'potato', (0, -.52, .14), .7, .26, 2, .03)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- barrels
def barrels():
    """Three coopered barrels: red apples, russet potatoes and red onions, lids leaning, a scoop and a stoneware jar
    of pickles on an upended half-barrel."""
    root, p, path = s.begin('greengrocer-barrels', 'v1')
    for i, (x, kind) in enumerate(((-.8, 'apple'), (0, 'potato'), (.8, 'onion_red'))):
        prof = [(.28, 0), (.32, .2), (.34, .4), (.32, .6), (.29, .74)]
        lathe(p, '@oak_dark', prof, (x, 0, 0), 24, True, cap1=False)
        for k in range(16):
            a = k * math.tau / 16
            tube(p, 'wood_dark/f', [(x + math.cos(a) * r * 1.003, math.sin(a) * r * 1.003, z) for r, z in prof], .004, 3, caps=False)
        for z, r in ((.12, .31), (.3, .335), (.5, .335), (.68, .3)):
            torus(p, 'iron', (x, 0, z), r + .008, .012, seg=24, n=5)
        lathe(p, 'wood_dark', [(0, .6), (.28, .6), (.28, .62), (0, .62)], (x, 0, 0), 24, True)
        heap_kind = kind
        for j in range(12):
            a = j * 2.4
            rr = .2 * math.sqrt((j + .5) / 12)
            zz = .64 + (.06 if j < 4 else 0)
            if kind == 'apple':
                g.apple(p, (x + math.cos(a) * rr, math.sin(a) * rr, zz), .045, 'apple' if j % 3 else 'apple_dark', j % 4 == 0)
            elif kind == 'potato':
                g.potato(p, (x + math.cos(a) * rr, math.sin(a) * rr, zz), .045, 'potato')
            else:
                g.onion(p, (x + math.cos(a) * rr, math.sin(a) * rr, zz), .042, 'onion_red')
        label(p, {'apple': 'COX 4P', 'potato': 'RUSSETS', 'onion_red': 'RED ONION'}[kind], x, -.34, .42, .22, .08, .03)
    with p.framed(Matrix.Translation((.8, .36, 0)) @ Matrix.Rotation(-.25, 4, 'X')):
        lathe(p, '@oak_dark', [(0, 0), (.3, 0), (.3, .03), (0, .03)], (0, 0, .3), 24, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    lathe(p, 'zinc', [(0, 0), (.07, 0), (.075, .08)], (-.62, -.12, .74), 12, True, cap1=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the dairy cupboard
def dairy():
    """A cool cupboard with louvred sides and slate shelves: eggs in trays and baskets, butter pats on paper, bottles
    of milk with foil caps, cream jugs and a blue-and-white cheese dome; two milk churns stand in front."""
    root, p, path = s.begin('greengrocer-dairy', 'v1')
    W, D, H = 1.6, .55, 2.0
    for x in (-W / 2 + .03, W / 2 - .03):
        box(p, '@oak', (x, 0, H / 2), (.06, D, H), .008)
        for i in range(12):
            box(p, 'wood_dark/f', (x + (.032 if x > 0 else -.032), 0, .3 + i * .12), (.004, D - .1, .02), 0, rot=(.5, 0, 0))
    box(p, '@oak', (0, D / 2 - .02, H / 2), (W, .04, H), .006)
    box(p, 'enamel_white', (0, D / 2 - .045, H / 2 + .1), (W - .1, .01, H - .3), 0)
    box(p, '@oak', (0, 0, .08), (W, D, .16), .01)
    s.cornice(p, '@oak', 0, W, -D / 2, D, H)
    box(p, JOIN, (0, -D / 2 - .01, H - .07), (W - .06, .02, .12), .004)
    text(p, 'cream/f', 'DAIRY', facing(0, -D / 2 - .024, H - .07), .08, 'cinzel')
    for r, z in enumerate((.45, .85, 1.25, 1.6)):
        box(p, 'slate', (0, 0, z), (W - .1, D - .06, .03), .004)
        if r == 0:
            for i in range(3):
                x = -.5 + i * .5
                box(p, 'card', (x, -.02, z + .03), (.36, .26, .03), .004)
                for j in range(12):
                    g.plum(p, (x - .13 + (j % 4) * .087, -.1 + (j // 4) * .08, z + .035), .028, 'egg' if (i + j) % 3 else 'egg_brown')
        elif r == 1:
            for i in range(6):
                x = -.6 + i * .24
                lathe(p, 'milk', [(0, 0), (.04, 0), (.042, .15), (.025, .2), (.022, .22)], (x, -.05, z + .015), 12, True)
                lathe(p, 'gold' if i % 2 else 'silver', [(0, .22), (.024, .22), (.024, .235), (0, .24)], (x, -.05, z + .015), 12, True)
        elif r == 2:
            for i in range(4):
                x = -.55 + i * .36
                box(p, 'paper', (x, -.05, z + .02), (.22, .14, .01), 0)
                s.soft(p, 'cheese' if i % 2 else 'butter', (x, -.05, z + .055), (.16, .1, .06), .015)
        else:
            for i, x in enumerate((-.5, -.1)):
                lathe(p, 'china_blue', [(.05, 0), (.06, .1), (.05, .14), (.055, .16)], (x, -.05, z + .015), 14, True, cap1=False)
                tube(p, 'china_blue', [(x + .055, -.05, z + .14), (x + .1, -.05, z + .12), (x + .1, -.05, z + .05), (x + .055, -.05, z + .04)], .008, 4)
            lathe(p, 'china', [(0, 0), (.15, 0), (.16, .015), (0, .015)], (.42, -.04, z + .015), 20, True)
            lathe(p, 'china_blue', [(.14, .015), (.14, .1), (.09, .16), (0, .18)], (.42, -.04, z + .015), 20, True, cap0=False)
            ball(p, 'china', (.42, -.04, z + .21), .025)
    for x in (-.45, .45):
        lathe(p, 'zinc', [(.17, 0), (.19, .05), (.19, .4), (.16, .46), (.1, .52), (.1, .6), (.12, .62)], (x, -D / 2 - .25, 0), 22, True,
              cap1=False)
        lathe(p, 'zinc', [(0, .6), (.13, .6), (.13, .66), (.06, .68), (0, .7)], (x, -D / 2 - .25, 0), 22, True, cap0=False)
        for side in (-1, 1):
            tube(p, 'zinc', [(x + side * .18, -D / 2 - .25, .38), (x + side * .23, -D / 2 - .25, .4), (x + side * .23, -D / 2 - .25, .46),
                             (x + side * .17, -D / 2 - .25, .47)], .012, 5)
        torus(p, 'brass', (x, -D / 2 - .25, .3), .195, .01, seg=22, n=4)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the barrow
def barrow():
    """Teo's market barrow, brought in from the street: two spoked wheels, shafts, a sign board painted with his
    name, and a load of crates — strawberries in punnets, cherries, peaches, a crate of leeks and a basket of figs."""
    root, p, path = s.begin('greengrocer-barrow', 'v1')
    W, D = 1.9, 1.0
    for side in (-1, 1):
        y = side * (D / 2 + .1)
        torus(p, 'oxblood', (.1, y, .42), .4, .028, normal=(0, 1, 0), seg=28, n=6)
        torus(p, 'iron', (.1, y, .42), .42, .012, normal=(0, 1, 0), seg=28, n=5)
        for i in range(12):
            a = i * math.tau / 12
            rod(p, 'oxblood', (.1, y, .42), (.1 + math.cos(a) * .4, y, .42 + math.sin(a) * .4), .012, 5)
        rod(p, 'gold', (.1, y - side * .04, .42), (.1, y + side * .04, .42), .05, 10)
    rod(p, 'iron', (.1, -D / 2 - .14, .42), (.1, D / 2 + .14, .42), .02, 8)
    box(p, '@oak', (0, 0, .68), (W, D, .06), .01)
    for side in (-1, 1):
        box(p, JOIN, (0, side * (D / 2 - .02), .8), (W, .04, .2), .006)
        tube(p, '@oak', [(-W / 2 + .1, side * (D / 2 - .1), .66), (-W / 2 - .5, side * (D / 2 - .15), .62), (-W / 2 - 1.0, side * (D / 2 - .2), .55)],
             .03, 8)
    for x in (-W / 2 + .02, W / 2 - .02):
        box(p, JOIN, (x, 0, .8), (.04, D, .2), .006)
    box(p, 'gold_leaf', (0, -D / 2 - .006, .8), (W - .2, .004, .16), 0)
    box(p, JOIN, (0, -D / 2 - .014, .8), (W - .26, .004, .12), 0)
    text(p, 'cream/f', 'T. VASKO  ·  FRUIT & VEG', s.k.facing_text(0, -D / 2 - .02, .8, (0, -1)), .065, 'cinzel')
    for x in (W / 2 - .25,):
        rod(p, 'iron', (x, 0, .68), (x, 0, .1), .02, 6)
        rod(p, 'iron', (x, -D / 2 + .1, .1), (x, D / 2 - .1, .1), .02, 6)
    # The load.
    z = .71
    s.crate(p, (-.48, -.22, z), .6, .42, .18, '@oak', 'wood_dark', 2)
    for i in range(6):
        px, py = -.48 - .2 + (i % 3) * .2, -.22 - .09 + (i // 3) * .18
        box(p, 'card', (px, py, z + .12), (.17, .15, .08), .006)
        for j in range(6):
            ball(p, 'strawberry/f', (px - .05 + (j % 3) * .05, py - .035 + (j // 3) * .07, z + .17), .025, (1, 1, 1.2))
    s.crate(p, (.18, -.22, z), .6, .42, .18, '@oak', 'wood_dark', 2)
    for j in range(40):
        a = j * 2.4
        rr = .17 * math.sqrt((j + .5) / 40)
        ball(p, 'cherry', (.18 + math.cos(a) * rr * 1.4, -.22 + math.sin(a) * rr, z + .16 + (j % 3) * .01), .02)
    s.crate(p, (-.48, .22, z), .6, .42, .18, '@oak', 'wood_dark', 2)
    g.heap(p, 'orange', (-.48, .22, z + .12), .5, .34, 2, .045)
    g.leek_bundle(p, (.18, .22, z + .02), 5, .5, 0)
    s.basket(p, (.68, 0, z), .2, .14, True)
    for j in range(9):
        a = j * 2.4
        rr = .12 * math.sqrt((j + .5) / 9)
        g.plum(p, (.68 + math.cos(a) * rr, math.sin(a) * rr, z + .1), .035, 'plum')
    label(p, 'PUNNET 3D', -.48, -.45, z + .25, .22, .08, .03)
    label(p, 'CHERRIES', .18, -.45, z + .25, .22, .08, .03)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- flower stand
def flower_stand():
    """A three-step stand of zinc buckets by the door: tulips, sunflowers, sweet peas, cornflowers, white daisies and
    lavender, a watering can and a roll of brown paper for wrapping."""
    root, p, path = s.begin('greengrocer-flower-stand', 'v1')
    W = 1.3
    for i, (z, y) in enumerate(((.0, -.25), (.3, 0), (.6, .25))):
        box(p, '@oak', (0, y, z + .14), (W, .3, .03), .006)
        for x in (-W / 2 + .03, W / 2 - .03):
            box(p, '@oak', (x, y, (z + .14) / 2), (.05, .28, z + .14), .006)
    colours = [['flower_red', 'flower_yellow', 'flower_white', 'flower_pink'], ['flower_blue', 'lavender', 'flower_pink', 'flower_yellow'],
               ['flower_white', 'flower_red', 'flower_violet', 'flower_yellow']]
    for i, (z, y) in enumerate(((.0, -.25), (.3, 0), (.6, .25))):
        for j in range(4):
            x = -W / 2 + .18 + j * (W - .36) / 3
            lathe(p, 'zinc', [(.08, 0), (.11, .26), (.115, .27)], (x, y, z + .155), 16, True, cap1=False)
            torus(p, 'zinc', (x, y, z + .425), .115, .008, seg=16, n=4)
            col = colours[i][j]
            if col == 'flower_yellow' and i == 1:
                for k in range(3):
                    a = k * 2.1
                    tip = (x + math.cos(a) * .06, y + math.sin(a) * .05, z + .155 + .75)
                    tube(p, 'stem/f', [(x, y, z + .3), tip], .007, 4)
                    lathe(p, 'flower_yellow', [(0, 0), (.08, .01), (0, .02)], tip, 12, True, ripple=lambda a, zz: 1 + .25 * math.cos(a * 12),
                          axis=Matrix.Rotation(-.6, 3, 'X'))
                    ball(p, 'chocolate_dark', (tip[0], tip[1] - .01, tip[2] + .01), .035, (1, .5, 1))
            else:
                g.flower_bunch(p, (x, y, z + .3), .38 + (j % 2) * .06, col, 8, .07)
            label(p, ['1D', '2D', '1D', '3D'][(i + j) % 4], x, y - .13, z + .3, .1, .06, .026, chalk=False)
    lathe(p, 'enamel_green', [(.08, 0), (.1, .02), (.1, .2), (.06, .24)], (W / 2 + .15, -.2, 0), 16, True)
    tube(p, 'enamel_green', [(W / 2 + .23, -.2, .1), (W / 2 + .4, -.2, .3), (W / 2 + .45, -.2, .34)], .015, 6)
    tube(p, 'enamel_green', [(W / 2 + .05, -.2, .24), (W / 2 + .15, -.2, .32), (W / 2 + .25, -.2, .24)], .01, 5)
    rod(p, 'kraft', (-W / 2 - .15, -.25, .05), (-W / 2 - .15, .25, .05), .05, 12)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- squash pallet
def squash_pallet():
    """A low pallet bedded with straw under pumpkins, squashes and marrows, with a basket of mushrooms and a crate of
    beetroot with their leaves."""
    root, p, path = s.begin('greengrocer-squash-pallet', 'v1')
    for i in range(5):
        box(p, '@oak', (0, -.4 + i * .2, .1), (1.4, .14, .03), .004)
    for x in (-.6, 0, .6):
        box(p, '@oak', (x, 0, .05), (.1, .96, .08), .006)
    for i in range(60):
        x, y = R.uniform(-.65, .65), R.uniform(-.45, .45)
        rod(p, 'butter/f', (x, y, .12), (x + R.uniform(-.1, .1), y + R.uniform(-.1, .1), .13), .005, 3)
    g.pumpkin(p, (-.35, .1, .12), .2)
    g.pumpkin(p, (.05, .2, .12), .15, 'pumpkin')
    g.pumpkin(p, (-.1, -.2, .12), .13, 'squash')
    for i, (x, y, a) in enumerate(((.35, -.15, .3), (.45, .1, -.4))):
        rot = Matrix.Rotation(a, 3, 'Z') @ Matrix.Rotation(math.pi / 2, 3, 'Y')
        lathe(p, 'squash', [(0, -.18), (.05, -.16), (.065, -.05), (.06, .1), (.045, .17), (0, .19)], (x, y, .18), 14, True, axis=rot)
    s.basket(p, (.55, -.32, .12), .16, .1, True)
    g.mushroom_heap(p, (.55, -.32, .17), .22, .2)
    s.crate(p, (-.4, -.35, .12), .5, .3, .14, '@oak', 'wood_dark', 2)
    for j in range(8):
        x = -.6 + (j % 4) * .13
        y = -.42 + (j // 4) * .13
        ball(p, 'beet', (x, y, .28), .045)
        for k in range(2):
            s.lathe(p, 'leaf_dark/f', [(0, 0), (.03, .06), (0, .14)], (x, y, .32), 6, True, squash=(1, .3),
                    axis=Matrix.Rotation(.4 + k * .5, 3, 'X') @ Matrix.Rotation(k * 1.5, 3, 'Z'))
    label(p, 'PUMPKINS', -.35, -.5, .2, .2, .08, .03)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- crate stack
def crate_stack():
    """Crates from the market, stacked by the store door, and a sack truck with two more on it."""
    root, p, path = s.begin('greengrocer-crate-stack', 'v1')
    for i, (x, y, z, kind) in enumerate(((-.2, 0, 0, 'apple'), (-.2, 0, .3, 'orange'), (-.2, 0, .6, None), (.3, .05, 0, 'potato'))):
        s.crate(p, (x, y, z), .56, .4, .28, '@oak', 'wood_dark', 2, None)
        text(p, 'label_red/f', 'HILL FARM', s.k.facing_text(x, y - .215, z + .16, (0, -1)), .05, 'cinzel')
        if kind:
            g.heap(p, kind, (x, y, z + .2), .48, .32, 1)
    # Sack truck.
    tx = .45
    for side in (-1, 1):
        tube(p, 'iron', [(tx + side * .18, -.42, .1), (tx + side * .18, -.32, .8), (tx + side * .16, -.25, 1.1), (tx + side * .1, -.2, 1.2)], .016, 6)
        lathe(p, 'ink', [(0, -.03), (.09, -.03), (.09, .03), (0, .03)], (tx + side * .22, -.4, .09), 14, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    rod(p, 'iron', (tx - .22, -.4, .09), (tx + .22, -.4, .09), .012, 6)
    box(p, 'iron', (tx, -.5, .03), (.36, .14, .02), .004)
    for i in range(2):
        s.crate(p, (tx, -.42 + .02 * i, .05 + i * .26), .4, .3, .24, '@oak', 'wood_dark', 2)
        g.heap(p, 'onion', (tx, -.42 + .02 * i, .25 + i * .26), .32, .22, 1)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the pendant
def pendant():
    """A bottle-green glass dome on a brass gallery, The Pantry's own lamp. The pivot is the suspension point at the
    top of the walls; the dome hangs 1.2 m below it. The bulb is lamp glass for the room to bind."""
    root, p, path = s.begin('greengrocer-pendant', 'v1')
    lathe(p, 'cream_paint', [(0, 0), (.1, 0), (.09, -.03), (0, -.04)], (0, 0, 0), 18, True)
    tube(p, 'brass', [(0, 0, -.04), (0, 0, -.82)], .008, 5)
    for i in range(10):
        torus(p, 'brass', (0, 0, -.1 - i * .07), .012, .004, normal=(1, 0, 0) if i % 2 else (0, 1, 0), seg=8, n=3)
    lathe(p, 'brass', [(0, -.92), (.05, -.92), (.06, -.88), (.03, -.84), (0, -.82)], (0, 0, 0), 16, True)
    prof = [(.3, -1.2), (.31, -1.19), (.28, -1.1), (.2, -1.0), (.1, -.94), (.05, -.92)]
    lathe(p, 'glass_bottle', prof, (0, 0, 0), 28, True, cap0=False, cap1=False)
    lathe(p, 'enamel_white', [(.045, -.93), (.095, -.955), (.19, -1.015), (.27, -1.11), (.295, -1.19)], (0, 0, 0), 28, True,
          cap0=False, cap1=False)
    torus(p, 'brass', (0, 0, -1.2), .305, .01, seg=28, n=4)
    lathe(p, 'shops_lamp_glass', [(0, -1.12), (.05, -1.1), (.06, -1.04), (.035, -.98), (0, -.97)], (0, 0, 0), 14, True, cap0=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- basket table
def basket_table():
    """A low trestle table in the middle of the floor: baskets of eggs, brown mushrooms, tomatoes on the vine,
    punnets of cherries and a bowl of lemons, each with a paper price; a gingham cloth over the top."""
    root, p, path = s.begin('greengrocer-basket-table', 'v1')
    W, D, H = 1.7, .9, .62
    for x in (-W / 2 + .15, W / 2 - .15):
        for side in (-1, 1):
            rod(p, '@oak', (x, side * .32, 0), (x, side * .05, H - .05), .028, 8)
        rod(p, '@oak', (x, -.25, .22), (x, .25, .22), .02, 6)
    rod(p, '@oak', (-W / 2 + .15, 0, .22), (W / 2 - .15, 0, .22), .022, 6)
    box(p, '@oak', (0, 0, H - .02), (W, D, .05), .01)
    sheet(p, '@gingham_green', lambda u, v: (-W / 2 - .02 + u * (W + .04), -D / 2 - .02 + v * (D + .04),
                                             H + .014 - .18 * max(0, abs(v - .5) * 2 - .92) * 12), 6, 12, .004)
    z = H + .01
    s.basket(p, (-.55, -.15, z), .18, .1, True)
    for j in range(12):
        a = j * 2.4
        rr = .12 * math.sqrt((j + .5) / 12)
        g.plum(p, (-.55 + math.cos(a) * rr, -.15 + math.sin(a) * rr, z + .06 + (j < 4) * .03), .03, 'egg' if j % 3 else 'egg_brown')
    s.basket(p, (-.1, .18, z), .2, .1, False)
    g.mushroom_heap(p, (-.1, .18, z + .07), .3, .3)
    for i in range(3):
        x = .3 + i * .17
        box(p, 'card', (x, -.2, z + .04), (.15, .15, .07), .006)
        for j in range(8):
            ball(p, 'cherry/f', (x - .04 + (j % 3) * .04, -.24 + (j // 3) * .04, z + .085), .02)
    lathe(p, 'china_blue', [(.05, 0), (.14, .06), (.16, .09)], (.5, .2, z), 18, True, cap1=False)
    for j in range(7):
        a = j * 2.4
        g.lemon(p, (.5 + math.cos(a) * .07 * (j > 0), .2 + math.sin(a) * .06 * (j > 0), z + .04 + (j == 0) * .03), .035, angle=a)
    tube(p, 'stem', [(-.62, .25, z + .06), (-.5, .25, z + .1), (-.38, .27, z + .06)], .006, 4)
    for j in range(5):
        g.tomato(p, (-.6 + j * .055, .25 + (j % 2) * .03, z + .04), .03)
    for x, words in ((-.55, 'EGGS 1D'), (-.1, 'MUSHROOMS'), (.47, 'CHERRIES'), (.5, 'LEMONS')):
        box(p, 'card/f', (x, -D / 2 - .01, H - .03), (.16, .004, .06), 0)
        text(p, 'ink/f', words, s.k.facing_text(x, -D / 2 - .013, H - .03, (0, -1)), .026, 'alegreya')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- platform scale
def platform_scale():
    """A cast-iron platform scale on little wheels, its brass beam and sliding poise on a column, with a sack of
    potatoes being weighed and a tin of weights on the base."""
    root, p, path = s.begin('greengrocer-platform-scale', 'v1')
    box(p, 'enamel_red', (0, 0, .1), (.7, .55, .12), .02)
    box(p, 'iron', (0, 0, .175), (.66, .5, .03), .004)
    for i in range(6):
        box(p, 'iron_light/f', (-.28 + i * .112, 0, .193), (.012, .46, .006), 0)
    for x in (-.3, .3):
        lathe(p, 'iron', [(0, -.02), (.05, -.02), (.05, .02), (0, .02)], (x, -.28, .05), 12, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    lathe(p, 'enamel_red', [(.07, 0), (.05, .1), (.04, .9), (.06, .95), (.03, 1.0)], (0, .3, .16), 14, True)
    box(p, 'gold', (0, .245, .65), (.12, .01, .18), .004)
    text(p, 'enamel_red/f', 'AVERY', s.k.facing_text(0, .239, .7, (0, -1)), .03, 'cinzel')
    box(p, 'brass', (.18, .3, 1.12), (.62, .03, .035), .004)
    for i in range(13):
        box(p, 'ink/f', (-.08 + i * .045, .284, 1.12), (.004, .004, .02), 0)
    box(p, 'brass', (.25, .3, 1.12), (.05, .06, .06), .01)
    rod(p, 'brass', (.49, .3, 1.12), (.49, .3, 1.0), .006, 4)
    lathe(p, 'brass', [(0, 0), (.03, 0), (.025, .04), (0, .05)], (.49, .3, .95), 10, True)
    lathe(p, '@burlap', [(.15, 0), (.19, .06), (.2, .3), (.17, .42)], (-.05, -.05, .19), 16, True, cap1=False,
          ripple=lambda a, z: 1 + .05 * math.cos(a * 5))
    torus(p, '@burlap', (-.05, -.05, .61), .17, .035, seg=16, n=6)
    for j in range(7):
        a = j * 2.4
        g.potato(p, (-.05 + math.cos(a) * .08 * (j > 0), -.05 + math.sin(a) * .08 * (j > 0), .56), .042)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- basket stack
def basket_stack():
    """Wicker shopping baskets stacked by the door on a little stand, with a slate: TAKE A BASKET."""
    root, p, path = s.begin('greengrocer-basket-stack', 'v1')
    box(p, '@oak', (0, 0, .15), (.6, .45, .03), .006)
    for x in (-.27, .27):
        for y in (-.19, .19):
            rod(p, '@oak', (x, y, 0), (x, y, .15), .02, 6)
    for i in range(5):
        with p.framed(Matrix.Translation((0, 0, .165 + i * .075)) @ Matrix.Rotation(.04 * (i % 2 - .5), 4, 'Z')):
            lathe(p, 'wicker', [(.16, 0), (.22, .14), (.23, .15)], (0, 0, 0), 20, True, cap1=False, squash=(1, .72),
                  ripple=lambda a, z: 1 + .03 * math.cos(a * 20))
            rim = [(math.cos(a) * .23, math.sin(a) * .23 * .72, .15) for a in [k * math.tau / 24 for k in range(24)]]
            tube(p, 'wicker_dark', rim, .012, 5, closed=True)
            if i == 4:
                tube(p, 'wicker_dark', [(-.2, 0, .15), (-.15, 0, .38), (0, 0, .45), (.15, 0, .38), (.2, 0, .15)], .014, 6)
    rod(p, 'iron', (.34, -.2, 0), (.34, -.2, .9), .01, 5)
    box(p, 'chalk', (.34, -.2, .95), (.03, .3, .2), .004)
    text(p, 'chalk_line/f', 'TAKE A', s.k.facing_text(.356, -.2, .99, (1, 0)), .04, 'alegreya')
    text(p, 'chalk_line/f', 'BASKET', s.k.facing_text(.356, -.2, .92, (1, 0)), .04, 'alegreya')
    s.finish(root, p, path, RECORD)


AUTHORS = {'greengrocer-shell': shell, 'greengrocer-produce-stand': produce_stand, 'greengrocer-counter': counter,
           'greengrocer-jar-shelves': jar_shelves, 'greengrocer-bin-wall': bin_wall, 'greengrocer-sack-row': sack_row,
           'greengrocer-barrels': barrels, 'greengrocer-dairy': dairy, 'greengrocer-barrow': barrow,
           'greengrocer-flower-stand': flower_stand, 'greengrocer-squash-pallet': squash_pallet,
           'greengrocer-crate-stack': crate_stack, 'greengrocer-pendant': pendant,
           'greengrocer-basket-table': basket_table, 'greengrocer-platform-scale': platform_scale,
           'greengrocer-basket-stack': basket_stack}

if __name__ == '__main__':
    s.run(AUTHORS, RECORD)
