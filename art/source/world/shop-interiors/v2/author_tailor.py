"""Finch & Thread, second pass (2026-11-12): Gret Finch's tailoring and haberdashery, the room and its furniture as
editable masters.

    blender -b --factory-startup --python author_tailor.py -- [asset-id ...]

Refuses an existing master unless it is this record's own untouched output and `--redo` is given. After adoption,
edit each model.blend and rebuild with scripts/world-art.sh build <id>.

Finch & Thread is an atelier: navy panelling with gilt lines under a rose regency stripe, herringbone oak and a knotted
rug, wine velvet drapes, brass and glass; a fitting booth, a three-way mirror, three dress forms, a rail of finished
orders under the order board, a thread wall, a bolt cabinet with a ladder and a glass haberdashery counter.
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
JOIN = '#navy'
R = random.Random(1301)
WEST_OPEN = [(5.8, 1.6, 1.0, 2.9)]
NORTH_OPEN = [(5.2, 1.3, 1.1, 2.9)]
CLOTHS = ['cloth_navy', 'cloth_slate', 'cloth_sky', 'cloth_rose', 'cloth_blush', 'cloth_wine', 'cloth_plum', 'cloth_mustard',
          'cloth_ochre', 'cloth_olive', 'cloth_forest', 'cloth_teal', 'cloth_tweed', 'cloth_camel', 'cloth_charcoal',
          'cloth_grey', 'cloth_ivory', 'cloth_black', 'cloth_rust', 'cloth_lilac']


def drape(p, x0, x1, y, z_top, z_bottom, colour='velvet_wine', folds=8, depth=.05, tie=None, face=(0, -1), tieback=.45):
    """A hanging velvet curtain from x0 to x1 (along the wall) at y, pleated; gathered at height `tie` toward
    whichever end `tieback` (0 left .. 1 right) says."""
    fx, fy = face

    def fn(u, v):
        z = z_top - v * (z_top - z_bottom)
        along = x0 + u * (x1 - x0)
        if tie is not None:
            pull = math.exp(-((z - tie) / .35) ** 2)
            along = along + (x0 + tieback * (x1 - x0) - along) * pull * .7
        out = depth * math.sin(u * math.pi * folds) * (1 - .4 * v)
        if fx == 0:
            return (along, y + out * fy * -1 + .0, z)
        return (y + out, along, z)
    sheet(p, colour, fn, folds * 4, 10, .01)


def pelmet(p, x0, x1, y, z, h=.3, colour=JOIN, trim='gold_leaf', face=(0, -1)):
    """A shaped pelmet board over a window, with a gilt edge and a scalloped hem."""
    fx, fy = face
    w = x1 - x0
    c = (x0 + x1) / 2
    if fx == 0:
        box(p, colour, (c, y, z), (w, .06, h), .01)
        box(p, trim, (c, y + fy * .032, z - h / 2 + .03), (w - .02, .006, .02), 0)
        for i in range(int(w / .18)):
            xx = x0 + .09 + i * .18
            lathe(p, colour, [(0, 0), (.08, 0), (.08, .03), (0, .03)], (xx, y, z - h / 2), 12, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    else:
        box(p, colour, (y, c, z), (.06, w, h), .01)
        box(p, trim, (y + fx * .032, c, z - h / 2 + .03), (.006, w - .02, .02), 0)
        for i in range(int(w / .18)):
            yy = x0 + .09 + i * .18
            lathe(p, colour, [(0, 0), (.08, 0), (.08, .03), (0, .03)], (y, yy, z - h / 2), 12, True, axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))


# ------------------------------------------------------------------------------------------------- the room
def shell():
    """Herringbone oak; navy panelled wainscot with gilt lines; a rose regency stripe above a gilt picture rail; wine
    velvet drapes on pelmets; framed fashion plates; a gilt-lettered frieze; a doormat and a shop bell."""
    root, p, path = s.begin('tailor-shell', 'v2')
    s.floor(p, 'floor_herringbone', 1.5)
    for wall, openings in ((s.NORTH, NORTH_OPEN), (s.WEST, WEST_OPEN)):
        s.strip(p, '@stripe_paper', wall, 0, s.HEIGHT, 0, -.24, openings)
        s.strip(p, 'navy_dark', wall, 0, .16, .035, 0, openings)
        s.strip(p, JOIN, wall, .16, 1.12, .02, 0, openings)
        s.strip(p, 'cream_paint', wall, 1.12, 1.2, .05, 0, openings)
        s.strip(p, 'gold_leaf', wall, 1.2, 1.22, .04, 0, openings)
        s.strip(p, 'gold_leaf', wall, 2.92, 2.96, .03, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.5, 3.62, .05, 0, openings)
        s.strip(p, 'cream_paint', wall, 3.62, 3.72, .09, 0, openings)
        s.strip(p, 'navy', wall, 3.72, 3.76, .1, 0, openings)
    # Wainscot panels: raised mouldings with a gilt line, between the openings.
    for wall, openings in ((s.NORTH, NORTH_OPEN), (s.WEST, WEST_OPEN)):
        a, b = wall['span']
        u = a + .1
        while u + .8 < b:
            c = u + .4
            if not any(abs(c - oc) < ow / 2 + .45 and o0 < 1.1 for oc, ow, o0, o1 in openings):
                for dz, h in ((.27, .06), (1.0, .06)):
                    s.wall_box(p, JOIN, wall, c, .035, dz, .72, .03, h, .006)
                for du in (-.33, .33):
                    s.wall_box(p, JOIN, wall, c + du, .035, .635, .06, .03, .79, .006)
                s.wall_box(p, 'gold_leaf/f', wall, c, .028, .635, .5, .004, .006, 0)
                s.wall_box(p, 'gold_leaf/f', wall, c, .028, .635 - .3, .5, .004, .006, 0)
                s.wall_box(p, 'gold_leaf/f', wall, c, .028, .635 + .3, .5, .004, .006, 0)
                for du in (-.25, .25):
                    s.wall_box(p, 'gold_leaf/f', wall, c + du, .028, .635, .006, .004, .6, 0)
            u += .82
    s.window(p, s.WEST, 5.8, 1.6, 1.0, 2.9, '#cream_paint', '@oak', (3, 3))
    s.window(p, s.NORTH, 5.2, 1.3, 1.1, 2.9, '#cream_paint', '@oak', (2, 3))
    # Velvet drapes, tied back with gilt cords, under navy pelmets.
    for side, (y0, y1) in enumerate(((4.8, 5.15), (6.45, 6.8))):
        drape(p, y0, y1, -.42, 3.15, .02, 'velvet_wine', 3, .04, 1.25, (1, 0), 0.0 if side == 0 else 1.0)
        torus(p, 'gold', (-.4, y0 + (y1 - y0) * (0.0 if side == 0 else 1.0), 1.25), .05, .012, normal=(0, 0, 1), seg=12, n=4)
        ball(p, 'gold', (-.38, y0 + (y1 - y0) * (0.0 if side == 0 else 1.0), 1.1), .03, (1, 1, 1.6))
    pelmet(p, 4.7, 6.9, -.42, 3.25, .32, JOIN, 'gold_leaf', (1, 0))
    for side, (x0, x1) in enumerate(((4.3, 4.6), (5.8, 6.1))):
        drape(p, x0, x1, 11.42, 3.15, .02, 'velvet_wine', 3, .04, 1.25, (0, -1), 0.0 if side == 0 else 1.0)
    pelmet(p, 4.2, 6.2, 11.42, 3.25, .32, JOIN, 'gold_leaf', (0, -1))
    # Fashion plates in gilt frames on the west wall, lettering in the frieze, a gilt-framed oval looking glass.
    for i, (yy, figure) in enumerate(((4.05, 'cloth_wine'), (7.4, 'cloth_navy'), (8.2, 'cloth_forest'))):
        x, y, z = s.on_wall(s.WEST, yy, .03, 2.45 if i == 0 else 3.25)
        box(p, 'gold', (x, y, z), (.04, .5, .66), .01)
        box(p, 'paper', (x + .022, y, z), (.006, .4, .56), 0)
        lathe(p, figure + '/f', [(0, 0), (.13, 0), (.06, .25), (.05, .3), (.1, .34), (.04, .4), (0, .4)], (x + .03, y, z - .25), 10,
              True, squash=(.08, 1))
        ball(p, 'form/f', (x + .03, y, z + .2), .045, (.3, 1, 1.2))
    s.wall_text(p, 'gold_leaf/f', 'BESPOKE  ·  ALTERATIONS  ·  HABERDASHERY', s.WEST, 6.2, .006, 3.35, .15)
    # Doormat and the shop bell.
    box(p, 'navy', (6, .32, .012), (1.15, .62, .024), .01)
    box(p, 'gold_leaf/f', (6, .32, .027), (1.0, .5, .006), 0)
    box(p, 'navy', (6, .32, .033), (.96, .46, .006), 0)
    text(p, 'gold_leaf/f', 'FINCH & THREAD', s.flat_text(6, .32, .0375), .085, 'cinzel')
    tube(p, 'brass', [(6.62, -.3, 3.0), (6.62, -.15, 3.0), (6.6, -.05, 2.98)] +
         [(6.6 + .04 * math.cos(t), -.05 + .004 * t, 2.95 - .012 * t) for t in [i * .6 for i in range(12)]], .006, 5)
    lathe(p, 'brass', [(0, 0), (.06, 0), (.05, .02), (.03, .08), (0, .1)], (6.6, 0, 2.72), 14, True, cap0=False)
    s.front_door(p, 'tailor', 'navy', 'gold_leaf')
    s.beams(p)
    p.finish(root)
    s.hinge_doors('tailor')
    s.finish(root, s.Parts(1), path, RECORD, extras={'room': 'shop-tailor', 'door_colour': s.PALETTE['navy']})


# ------------------------------------------------------------------------------------------------- bolt cabinet
def cloth_shelves():
    """A tall bolt cabinet in navy with gilt lines: pigeonholes of cloth bolts on their boards, sorted by colour and
    weight, a gap where the plum wool should be (with its ORDERED note), drawers below and a ladder on a brass rail."""
    root, p, path = s.begin('tailor-cloth-shelves', 'v2')
    W, D, H = 3.0, .55, 2.75
    box(p, JOIN, (0, .02, .42), (W, D - .04, .84), .01)
    for i in range(5):
        x = -W / 2 + W / 10 + i * W / 5
        for z in (.25, .62):
            s.panel(p, JOIN, x, -D / 2 + .02, z, W / 5 - .05, .32, .04, .02, 'gold_leaf', 'brass')
    box(p, '@oak', (0, 0, .87), (W + .06, D + .04, .05), .01)
    box(p, '@oak_dark', (0, D / 2 - .03, 1.8), (W - .06, .03, 1.85), 0)
    cols = 5
    for i in range(cols + 1):
        x = -W / 2 + .03 + i * (W - .06) / cols
        box(p, JOIN, (x, 0, 1.8), (.05, D - .06, 1.86), .006)
    rows = (.9, 1.38, 1.86, 2.34)
    for z in rows + (2.72,):
        box(p, JOIN, (0, 0, z), (W - .04, D - .06, .035), .004)
    index = 0
    for r, z in enumerate(rows):
        for c in range(cols):
            cx = -W / 2 + .03 + (c + .5) * (W - .06) / cols
            if r == 1 and c == 3:
                box(p, 'paper/f', (cx, -.2, z + .2), (.14, .004, .1), 0, rot=(0, .1, 0))
                text(p, 'ink/f', 'ORDERED', facing(cx, -.204, z + .2), .028, 'alegreya')
                ball(p, 'pin/f', (cx, -.21, z + .25), .01)
                continue
            for k in range(4):
                colour = CLOTHS[(c * 4 + r * 3 + k) % len(CLOTHS)]
                xx = cx - .2 + k * .135
                # A bolt: cloth wound on a flat board, seen end on, with its fold showing.
                box(p, 'card/f', (xx, -.02, z + .23), (.012, D - .14, .4), 0)
                s.soft(p, colour, (xx, -.02, z + .23), (.11, D - .16, .38), .03)
                index += 1
    s.cornice(p, JOIN, 0, W, -D / 2, D, 2.74)
    box(p, 'gold_leaf', (0, -D / 2 - .012, 2.79), (W - .1, .006, .02), 0)
    rod(p, 'brass', (-W / 2, -D / 2 - .1, 2.5), (W / 2, -D / 2 - .1, 2.5), .015, 8)
    for x in (-W / 2 + .1, W / 2 - .1):
        rod(p, 'brass', (x, -D / 2 - .1, 2.5), (x, -D / 2 + .05, 2.5), .012, 6)
    lx = -.6
    for dx in (-.2, .2):
        rod(p, '@oak', (lx + dx, -D / 2 - .1, 2.52), (lx + dx, -D / 2 - .7, 0), .025, 8)
        lathe(p, 'ink', [(0, -.02), (.035, -.02), (.035, .02), (0, .02)], (lx + dx, -D / 2 - .7, .035), 10, True,
              axis=Matrix.Rotation(math.pi / 2, 3, 'Y'))
    for i in range(8):
        t = (i + 1) / 9
        rod(p, '@oak', (lx - .2, -D / 2 - .1 - .6 * t, 2.52 * (1 - t)), (lx + .2, -D / 2 - .1 - .6 * t, 2.52 * (1 - t)), .018, 6)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- thread wall
def spool_wall():
    """The thread wall: 128 spools on pegs in rows of sixteen, each row light to dark except one where two blues have
    swapped, in a navy frame over a chest of labelled button drawers, with ribbons on rollers and a pincushion."""
    root, p, path = s.begin('tailor-spool-wall', 'v2')
    W = 2.6
    box(p, JOIN, (0, .05, .45), (W, .5, .9), .01)
    for i in range(4):
        for j in range(3):
            x = -W / 2 + W / 8 + i * W / 4
            z = .2 + j * .25
            s.panel(p, JOIN, x, -.2, z, W / 4 - .04, .22, .03, .02, None, 'brass')
            box(p, 'card/f', (x, -.205, z + .055), (.1, .004, .04), 0)
            for b in range(3):
                rod(p, ['china', 'gold', 'cloth_wine', 'ink', 'cloth_sky', 'silver'][(i * 3 + j + b) % 6] + '/f',
                    (x - .03 + b * .03, -.205, z + .055), (x - .03 + b * .03, -.209, z + .055), .009, 8)
    box(p, '@oak', (0, .02, .92), (W + .06, .56, .04), .008)
    box(p, '@oak_dark', (0, .27, 1.9), (W - .1, .04, 1.9), 0)
    box(p, JOIN, (0, .2, 2.88), (W, .2, .1), .01)
    for x in (-W / 2 + .05, W / 2 - .05):
        box(p, JOIN, (x, .2, 1.9), (.1, .2, 1.96), .01)
    ramps = [['cloth_ivory', 'cloth_blush', 'cloth_rose', 'cloth_wine'], ['cloth_sky', 'cloth_slate', 'cloth_navy', 'cloth_black'],
             ['butter', 'cloth_mustard', 'cloth_ochre', 'cloth_rust'], ['leaf_light', 'cloth_olive', 'cloth_forest', 'bottle_dark'],
             ['cloth_lilac', 'cloth_plum', 'velvet_wine', 'ink'], ['cream', 'cloth_camel', 'cloth_tweed', 'wood_dark'],
             ['chalk_line', 'cloth_grey', 'cloth_charcoal', 'cloth_black'], ['mint_box', 'cloth_teal', 'velvet_teal', 'navy_dark']]
    for row in range(8):
        z = 1.08 + row * .2
        box(p, '@oak', (0, .18, z - .055), (W - .2, .14, .02), .003)
        ramp = ramps[row]
        for i in range(16):
            x = -W / 2 + .2 + i * (W - .4) / 15
            colour = ramp[min(3, i // 4)]
            if row == 1 and i in (6, 9):
                colour = ramp[2] if i == 6 else ramp[1]
            lathe(p, '@oak', [(.028, 0), (.028, .012), (.018, .014), (.018, .1), (.028, .102), (.028, .114)], (x, .15, z - .045), 10, True)
            rod(p, colour, (x, .15, z - .03), (x, .15, z + .055), .03, 10)
    for i in range(8):
        x = -W / 2 + .3 + i * (W - .6) / 7
        rod(p, ['ribbon_red', 'cloth_sky', 'gold', 'cloth_forest', 'cloth_blush', 'navy', 'cloth_ivory', 'cloth_plum'][i],
            (x - .1, -.12, 1.05), (x + .1, -.12, 1.05), .055, 14)
        rod(p, 'brass', (x - .13, -.12, 1.05), (x + .13, -.12, 1.05), .008, 6)
    for x in (-W / 2 + .2, W / 2 - .2):
        box(p, 'brass', (x, -.05, 1.05), (.02, .2, .06), .004)
    rod(p, 'brass', (-W / 2 + .2, -.12, 1.05), (W / 2 - .2, -.12, 1.05), .006, 4)
    ball(p, 'velvet_wine', (W / 2 - .25, -.15, .99), .07, (1, 1, .6))
    lathe(p, 'brass', [(.06, 0), (.07, .02), (.065, .03)], (W / 2 - .25, -.15, .94), 12, True, cap1=False)
    for a in range(8):
        rod(p, 'steel', (W / 2 - .25, -.15, 1.0), (W / 2 - .25 + math.cos(a * .8) * .05, -.15 + math.sin(a * .8) * .05, 1.06), .003, 3)
        ball(p, ['pin', 'gold', 'cloth_sky'][a % 3] + '/f', (W / 2 - .25 + math.cos(a * .8) * .05, -.15 + math.sin(a * .8) * .05, 1.06), .008)
    text(p, 'gold_leaf/f', 'THREADS', facing(0, .095, 2.88), .07, 'cinzel')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- cutting table
def cutting_table():
    """A long cutting table on turned legs: navy wool laid out and pinned to a paper pattern, chalk lines, a brass
    yard rule let into the edge, shears, a tape measure, a pin box, a pressing cloth and a bolt being unrolled."""
    root, p, path = s.begin('tailor-cutting-table', 'v2')
    W, D, H = 3.0, 1.25, .9
    for x in (-W / 2 + .12, 0, W / 2 - .12):
        for y in (-D / 2 + .12, D / 2 - .12):
            s.leg(p, '@oak_dark', x, y, 0, H - .1, .05)
    box(p, '@oak_dark', (0, 0, H - .14), (W - .16, D - .16, .12), .01)
    for x in (-.8, .8):
        s.panel(p, '@oak_dark', x, -D / 2 + .07, H - .14, .6, .1, .025, .015, None, 'brass')
    box(p, '@oak', (0, 0, H - .04), (W, D, .06), .01)
    box(p, 'brass', (0, -D / 2 + .02, H - .008), (W - .04, .05, .006), .002)
    for i in range(37):
        box(p, 'ink/f', (-W / 2 + .03 + i * (W - .06) / 36, -D / 2 + .02, H - .004), (.004, .025 if i % 4 else .045, .002), 0)
    box(p, '@oak', (0, 0, .2), (W - .26, D - .26, .03), .004)
    for i in range(5):
        lathe(p, CLOTHS[(i * 3) % len(CLOTHS)], [(0, 0), (.1, 0), (.1, .5), (0, .5)], (-1.1 + i * .3, 0, .27), 14, True,
              axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    top = H - .01
    sheet(p, 'cloth_navy', lambda u, v: (-1.3 + u * 2.0, -.45 + v * .95, top + .012 + .003 * math.sin(u * 9) * math.sin(v * 5)), 12, 6, .008)
    box(p, 'paper/f', (-.45, .05, top + .03), (1.3, .75, .003), 0)
    for x, y, w, d in ((-.85, -.1, .35, .5), (-.35, .1, .4, .55), (.05, -.12, .25, .4)):
        for dx, dy, ww, dd in ((0, -d / 2, w, .006), (0, d / 2, w, .006), (-w / 2, 0, .006, d), (w / 2, 0, .006, d)):
            box(p, 'ink/f', (x + dx, y + dy, top + .031), (ww, dd, .002), 0)
    for x, y in ((-1.0, -.32), (-.7, .4), (-.15, -.28), (.15, .35), (-.5, .42), (.2, -.2)):
        ball(p, 'pin/f', (x, y, top + .036), .012)
        rod(p, 'steel', (x, y, top + .031), (x + .03, y - .02, top + .029), .002, 3)
    lathe(p, 'cloth_navy', [(0, 0), (.13, 0), (.13, .82), (0, .82)], (.95, .02, top + .14), 18, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
    for i in range(3):
        box(p, 'white/f', (-.3 + i * .25, -.32, top + .02), (.18, .006, .002), 0, rot=(0, 0, .3 * (i - 1)))
    # Shears, a tape measure, a pin box and chalk.
    with p.placed((.55, -.35, top + .015), 25):
        for a in (.18, -.18):
            box(p, 'steel', (.12, 0, .006), (.26, .022, .006), 0, rot=(0, 0, a))
        torus(p, 'ink', (-.05, .035, .006), .03, .008, seg=12, n=4)
        torus(p, 'ink', (-.05, -.035, .006), .03, .008, seg=12, n=4)
    pts = [(1.25 + math.cos(t) * .05 * (1 + t / 12), -.3 + math.sin(t) * .05 * (1 + t / 12), top + .012) for t in [i * .4 for i in range(28)]]
    tube(p, 'tape', pts + [(1.1, -.5, top + .012), (1.0, -.58, top - .05), (.98, -.6, top - .25)], .006, 4)
    box(p, 'velvet_teal', (1.3, .4, top + .03), (.16, .1, .04), .01)
    box(p, 'white', (1.05, .45, top + .012), (.06, .04, .012), .004)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- dress forms
def _form_stand(p, mat='@oak_dark'):
    for a in range(3):
        tube(p, mat, [(0, 0, .14), (math.cos(a * 2.094) * .18, math.sin(a * 2.094) * .18, .08), (math.cos(a * 2.094) * .34, math.sin(a * 2.094) * .34, .02)],
             .022, 7)
        ball(p, 'brass', (math.cos(a * 2.094) * .34, math.sin(a * 2.094) * .34, .02), .02)
    lathe(p, mat, [(.04, .08), (.03, .3), (.04, .34), (.025, .4), (.025, .95), (.035, 1.0)], (0, 0, 0), 12, True)
    lathe(p, 'brass', [(0, .55), (.04, .55), (.045, .6), (0, .6)], (0, 0, 0), 12, True)


def _torso(p, colour='form', z=1.0, squash=(1.18, .82), scale=1.0):
    prof = [(.15, 0), (.19, .08), (.18, .2), (.14, .32), (.15, .4), (.19, .5), (.19, .56), (.15, .63), (.07, .7), (.05, .74),
            (.05, .8), (0, .82)]
    lathe(p, colour, [(r * scale, zz * scale) for r, zz in prof], (0, 0, z), 20, True, squash=squash)


def dress_form():
    """Braum's coat on a dress form: navy wool tacked with white basting, lapels and buttons, the sleeves pinned to
    the shoulders waiting to be set, a paper tag at the hem, on a turned walnut stand with brass feet."""
    root, p, path = s.begin('tailor-dress-form', 'v2')
    _form_stand(p)
    _torso(p, 'form')
    ball(p, 'form_dark', (0, 0, 1.84), .045)
    prof = [(.2, 0), (.215, .1), (.2, .25), (.165, .32), (.175, .4), (.205, .5), (.21, .56), (.17, .63), (.09, .68)]
    lathe(p, 'cloth_navy', [(r, z + .0) for r, z in prof], (0, 0, .82), 22, True, cap0=True, cap1=False, squash=(1.2, .86))
    lathe(p, 'cloth_navy', [(.2, 0), (.22, .02), (.205, .18)], (0, 0, .64), 22, True, cap0=False, cap1=False, squash=(1.2, .86))
    for side in (-1, 1):
        p.solid('cloth_navy', [(side * .02, -.17, 1.45), (side * .13, -.16, 1.32), (side * .1, -.17, 1.2), (side * .03, -.18, 1.12)], .015,
                (0, -1, 0))
        tube(p, 'cloth_navy', [(side * .25, 0, 1.35), (side * .29, -.02, 1.1), (side * .3, -.03, .82)], .055, 10,
             radii=[.06, .055, .05])
        for i in range(5):
            ball(p, 'pin/f', (side * .25, -.05, 1.38 - i * .01), .009)
    for z in (1.07, .97, .87):
        ball(p, 'brass', (.03, -.185, z), .015)
    for i in range(10):
        a = math.pi * (i / 9 - .5) * 1.1
        box(p, 'white/f', (math.sin(a) * .245, -math.cos(a) * .21, .66), (.025, .004, .004), 0, rot=(0, 0, a))
    for z in (1.0, 1.2, .8):
        box(p, 'white/f', (-.1, -.2, z), (.004, .004, .03), 0)
    box(p, 'paper/f', (.12, -.2, .7), (.06, .004, .04), 0, rot=(0, .3, 0))
    text(p, 'ink/f', 'BRAUM', s.k.facing_text(.12, -.205, .7, (0, -1)), .014, 'alegreya')
    s.finish(root, p, path, RECORD)


def dress_form_gown():
    """An evening gown on a form: wine velvet, a draped neckline with a gilt brooch, a full skirt to the floor with a
    short train, a sash of blush silk — the window piece."""
    root, p, path = s.begin('tailor-dress-form-gown', 'v1')
    _form_stand(p)
    _torso(p, 'form', 1.0, (1.1, .78), .95)
    ball(p, 'form_dark', (0, 0, 1.8), .045)
    lathe(p, 'velvet_wine', [(.16, 0), (.15, .1), (.17, .22), (.18, .3), (.12, .36)], (0, 0, 1.3), 22, True, cap0=False, cap1=True,
          squash=(1.1, .8))
    sheet(p, 'velvet_wine', lambda u, v: (math.cos(u * math.tau) * (.17 + .3 * v ** 1.4) * (1 + .05 * math.sin(u * math.tau * 9)) * 1.05,
                                          math.sin(u * math.tau) * (.14 + .3 * v ** 1.4) * (1 + .05 * math.sin(u * math.tau * 9))
                                          + .2 * max(0, math.sin(u * math.tau)) * v ** 3,
                                          1.32 - v * 1.3), 36, 8, .012)
    torus(p, 'cloth_blush', (0, 0, 1.3), .17, .03, seg=22, n=6)
    ball(p, 'cloth_blush', (.12, -.12, 1.28), .045)
    hem = [(math.cos(u * math.tau) * .47 * (1 + .05 * math.sin(u * math.tau * 9)) * 1.05,
            math.sin(u * math.tau) * .44 * (1 + .05 * math.sin(u * math.tau * 9)) + .2 * max(0, math.sin(u * math.tau)), .04)
           for u in [i / 48 for i in range(48)]]
    tube(p, 'gold', hem, .012, 5, closed=True)
    for i in range(9):
        u = (i + .5) / 9 * .5 + .5
        tube(p, 'velvet_wine/f', [(math.cos(u * math.tau) * (.17 + .3 * v ** 1.4) * 1.07, math.sin(u * math.tau) * (.14 + .3 * v ** 1.4) * 1.05
                                   + .2 * max(0, math.sin(u * math.tau)) * v ** 3, 1.32 - v * 1.3) for v in (.25, .5, .75, .98)], .008, 4)
    for i in range(2):
        tube(p, 'cloth_blush', [(.12, -.13, 1.27), (.15 + i * .04, -.15, 1.1), (.13 + i * .07, -.16, .9)], .025, 6)
    torus(p, 'velvet_wine', (0, 0, 1.6), .13, .025, normal=(0, .3, 1), seg=20, n=6)
    ball(p, 'gold', (0, -.13, 1.55), .025)
    ball(p, 'cloth_ivory/f', (0, -.135, 1.55), .012)
    s.finish(root, p, path, RECORD)


def dress_form_suit():
    """A gentleman's form in a tweed waistcoat and shirt with a silk tie, a measuring tape round the neck and a
    folded pocket square."""
    root, p, path = s.begin('tailor-dress-form-suit', 'v1')
    _form_stand(p)
    _torso(p, 'cloth_ivory', 1.0, (1.25, .86), 1.03)
    ball(p, 'form_dark', (0, 0, 1.88), .045)
    lathe(p, 'cloth_ivory', [(.065, 1.72), (.06, 1.8)], (0, 0, 0), 14, True)
    torso = [(.19, .08), (.18, .2), (.14, .32), (.15, .4), (.19, .5), (.19, .56), (.15, .63)]
    lathe(p, 'cloth_tweed', [(r * 1.03 * 1.07, z * 1.03) for r, z in torso], (0, 0, 1.0), 22, True, cap0=True, cap1=False,
          squash=(1.25, .86))
    p.solid('cloth_tweed', [(-.13, -.16, 1.09), (0, -.18, 1.0), (.13, -.16, 1.09)], .02, (0, -1, 0))
    for side in (-1, 1):
        p.solid('cloth_ivory', [(side * .005, -.19, 1.66), (side * .07, -.175, 1.62), (side * .02, -.185, 1.45)], .01, (0, -1, 0))
    p.solid('cloth_wine', [(-.025, -.195, 1.66), (.025, -.195, 1.66), (.035, -.2, 1.3), (0, -.205, 1.25), (-.035, -.2, 1.3)], .012, (0, -1, 0))
    for z in (1.42, 1.34, 1.26, 1.18, 1.1):
        ball(p, 'brass', (0, -.205, z), .012)
    box(p, 'cloth_blush', (.14, -.19, 1.42), (.06, .02, .04), .004, rot=(0, .3, 0))
    pts = [(math.cos(t) * .09, math.sin(t) * .07, 1.75) for t in [i * math.tau / 20 for i in range(20)]]
    tube(p, 'tape', pts, .008, 4, closed=True)
    for side in (-1, 1):
        tube(p, 'tape', [(side * .05, -.07, 1.74), (side * .07, -.21, 1.5), (side * .06, -.22, 1.25)], .008, 4)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- sewing table
def sewing_table():
    """A treadle sewing machine in black and gilt on its iron stand, a bentwood chair, a work lamp (the switchable
    `sewing-lamp`, lamp glass), a basket of mending and a tin of bobbins."""
    root, p, path = s.begin('tailor-sewing-table', 'v2')
    for x in (-.55, .55):
        p.solid('iron', [(x, -.3, 0), (x, .3, 0), (x, .22, .72), (x, -.22, .72)], .05, (1, 0, 0))
        torus(p, 'iron', (x, 0, .38), .1, .015, normal=(1, 0, 0), seg=16, n=5)
    rod(p, 'iron', (-.55, 0, .2), (.55, 0, .2), .02, 8)
    box(p, 'iron', (0, -.12, .1), (.55, .3, .03), .005, rot=(.2, 0, 0))
    for i in range(6):
        box(p, 'iron_light/f', (-.2 + i * .08, -.12, .12), (.02, .26, .006), 0, rot=(.2, 0, 0))
    torus(p, 'iron', (.48, .05, .38), .2, .018, normal=(1, 0, 0), seg=24, n=5)
    for i in range(6):
        a = i * math.tau / 6
        rod(p, 'iron', (.48, .05, .38), (.48, .05 + math.cos(a) * .2, .38 + math.sin(a) * .2), .008, 4)
    box(p, '@oak_dark', (0, 0, .76), (1.3, .6, .06), .01)
    for x in (-.4, .4):
        s.panel(p, '@oak_dark', x, -.3, .66, .3, .12, .025, .015, None, 'brass')
    box(p, 'ink', (.05, 0, .82), (.6, .28, .06), .015)
    box(p, 'ink', (.28, 0, .97), (.12, .18, .26), .03)
    box(p, 'ink', (.05, 0, 1.08), (.55, .14, .1), .035)
    box(p, 'ink', (-.2, 0, .98), (.1, .12, .2), .02)
    for x in (-.05, .1, .2):
        box(p, 'gold_leaf/f', (x, -.072, 1.08), (.06, .004, .05), 0, rot=(0, .4, 0))
    text(p, 'gold_leaf/f', 'FINCH', s.k.facing_text(.06, -.072, 1.1, (0, -1)), .025, 'cinzel')
    rod(p, 'steel', (-.2, 0, .88), (-.2, 0, .84), .006, 6)
    torus(p, 'chrome', (.39, 0, 1.0), .1, .014, normal=(1, 0, 0), seg=18, n=5)
    rod(p, 'cloth_wine', (.1, 0, 1.14), (.1, 0, 1.2), .03, 10)
    tube(p, 'cloth_wine/f', [(.1, -.03, 1.18), (.0, -.06, 1.15), (-.2, -.06, 1.0), (-.2, -.03, .9)], .002, 3)
    sheet(p, 'cloth_sky', lambda u, v: (-.5 + u * .55, -.25 + v * .4, .85 + .01 * math.sin(u * 8)), 6, 4, .006)
    # The work lamp: a brass swing arm and a green shade over the needle.
    rod(p, 'brass', (-.55, .22, .79), (-.55, .22, 1.3), .015, 8)
    tube(p, 'brass', [(-.55, .22, 1.3), (-.45, .12, 1.36), (-.3, .02, 1.36)], .012, 6)
    lathe(p, 'enamel_green', [(.11, -.08), (.09, -.02), (.05, .02), (.03, .03)], (-.3, .02, 1.36), 16, True, cap0=False)
    lathe(p, 'shops_lamp_glass', [(0, -.07), (.045, -.06), (.04, -.02), (0, -.01)], (-.3, .02, 1.36), 12, True, cap0=False)
    lathe(p, 'brass', [(0, 0), (.07, 0), (.06, .03), (0, .03)], (-.55, .22, .79), 14, True)
    # Bentwood chair at the treadle; the mending basket and a bobbin tin.
    with p.placed((0, -.62, 0), 0):
        lathe(p, 'velvet_wine', [(0, 0), (.19, 0), (.2, .04), (0, .05)], (0, 0, .44), 20, True)
        for a in (.6, 2.5, 3.8, 5.6):
            tube(p, 'wood_dark', [(math.cos(a) * .15, math.sin(a) * .15, .44), (math.cos(a) * .19, math.sin(a) * .19, .0)], .017, 6)
        torus(p, 'wood_dark', (0, 0, .2), .16, .01, seg=24, n=5)
        tube(p, 'wood_dark', [(-.15, -.12, .45), (-.17, -.15, .75), (0, -.19, .86), (.17, -.15, .75), (.15, -.12, .45)], .017, 6)
    s.basket(p, (.95, .05, 0), .2, .22, True)
    for i in range(3):
        ball(p, CLOTHS[i * 5], (.9 + i * .05, .05, .24), .1, (1, 1, .45))
    s.tin(p, (-.3, .2, .79), .05, .05, 'label_blue', 'gold')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the mirror
def mirror():
    """A three-way fitting mirror in gilt frames on a round navy dais with a brass edge, a footstool beside it."""
    root, p, path = s.begin('tailor-mirror', 'v2')
    lathe(p, JOIN, [(0, 0), (.55, 0), (.55, .12), (0, .12)], (0, -.1, 0), 36, True)
    torus(p, 'brass', (0, -.1, .12), .55, .012, seg=36, n=4)
    lathe(p, 'velvet_teal', [(0, .128), (.5, .128), (0, .13)], (0, -.1, 0), 36, False)
    for i, a in enumerate((-55, 0, 55)):
        with p.placed((math.sin(math.radians(a)) * .35, .45 - math.cos(math.radians(a)) * .1 - (0 if i == 1 else .12), 0), -a * .7):
            box(p, 'gold', (0, 0, 1.0), (.6, .06, 1.95), .02)
            p.pane('shops_mirror', (0, -.04, 1.0), .5, 1.82, (0, -1))
            for z in (.02, 1.98):
                box(p, 'gold', (0, 0, z), (.66, .08, .05), .01)
            lathe(p, 'gold', [(0, 0), (.08, 0), (.05, .05), (0, .08)], (0, 0, 2.0), 12, True)
    lathe(p, '@oak_dark', [(.15, 0), (.15, .25), (.17, .27)], (.85, -.35, 0), 16, True, cap1=False)
    lathe(p, 'velvet_wine', [(0, .25), (.18, .25), (.17, .32), (0, .33)], (.85, -.35, 0), 16, True, cap0=False)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the fitting booth
def fitting_room():
    """A curtained fitting booth for a corner: a navy side panel with a gilt line, a brass rail on a cornice, wine
    velvet drawn half across, a stool, a hook with a jacket and a looking glass inside."""
    root, p, path = s.begin('tailor-fitting-room', 'v1')
    S, H = 1.4, 2.5
    box(p, JOIN, (S / 2, 0, H / 2), (.05, S, H), .01)
    with p.placed((S / 2 + .03, 0, 0), 90):
        s.panel(p, JOIN, 0, -.0, 1.2, S - .2, 2.1, .07, .03, 'gold_leaf')
    box(p, JOIN, (0, -S / 2, H), (S + .05, .12, .14), .01)
    box(p, 'gold_leaf', (0, -S / 2 - .062, H), (S, .004, .03), 0)
    rod(p, 'brass', (-S / 2, -S / 2 + .05, H - .12), (S / 2, -S / 2 + .05, H - .12), .015, 8)
    for i in range(12):
        torus(p, 'brass', (-S / 2 + .1 + i * .045, -S / 2 + .05, H - .12), .022, .005, normal=(1, 0, 0), seg=10, n=3)
    drape(p, -S / 2 + .05, -S / 2 + .62, -S / 2 + .05, H - .14, .02, 'velvet_wine', 4, .05, None, (0, -1))
    ball(p, 'gold', (-S / 2 + .62, -S / 2 + .02, 1.1), .03, (1, 1, 1.5))
    # Inside: a looking glass on the back, a stool, a hook with a jacket.
    box(p, 'gold', (0, S / 2 - .04, 1.35), (.5, .03, 1.2), .01)
    p.pane('shops_mirror', (0, S / 2 - .065, 1.35), .42, 1.1, (0, -1))
    lathe(p, '@oak_dark', [(.15, 0), (.13, .38), (.16, .4)], (.25, .1, 0), 14, True, cap1=False)
    lathe(p, 'velvet_teal', [(0, .4), (.17, .4), (.16, .45), (0, .46)], (.25, .1, 0), 14, True, cap0=False)
    rod(p, 'brass', (S / 2 - .03, .3, 1.7), (S / 2 - .1, .3, 1.75), .01, 5)
    sheet(p, 'cloth_charcoal', lambda u, v: (S / 2 - .1 - .02 * math.sin(u * math.pi), .1 + u * .4, 1.72 - v * .75 - .1 * (u - .5) ** 2), 6, 6, .02)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the order rail
def _garment(p, x, y, z, length=1.0, colour='cloth_navy', cover=True, name=None, coat=True):
    """A garment on a wooden hanger hooked to a rail at height z, its front toward -y, in an optional paper cover."""
    tube(p, 'brass', [(x, y, z + .02), (x, y + .03, z + .06), (x, y + .015, z + .09), (x, y - .01, z + .07)], .005, 4)
    tube(p, '@oak', [(x - .22, y, z - .1), (x - .1, y, z - .04), (x, y, z - .02), (x + .1, y, z - .04), (x + .22, y, z - .1)], .015, 6)
    shape = lambda u, v: (x + (u - .5) * (.46 if v < .15 else .42 - .04 * v) * (1 - .4 * max(0, .15 - v) / .15 * abs(u - .5) * 0),
                          y + .03 * math.sin(u * math.pi) - .04,
                          z - .08 - v * length - .05 * max(0, .2 - v) * abs(u - .5) * 4)
    sheet(p, colour, shape, 6, 8, .05)
    if coat:
        for side in (-1, 1):
            p.solid(colour, [(x + side * .02, y - .1, z - .12), (x + side * .12, y - .095, z - .25), (x + side * .04, y - .1, z - .45)], .01,
                    (0, -1, 0))
        for i in range(3):
            ball(p, 'brass', (x + .03, y - .1, z - .5 - i * .1), .012)
    if cover:
        sheet(p, 'paper', lambda u, v: (x + (u - .5) * .52, y - .1 + .015 * math.sin(u * math.pi * 3), z - .06 - v * (length * .8)), 6, 6, .004)
    if name:
        box(p, 'card/f', (x + .12, y - .125, z - .2), (.1, .004, .06), 0, rot=(0, .25, 0))
        text(p, 'ink/f', name, s.k.facing_text(x + .12, y - .129, z - .2, (0, -1)), .024, 'alegreya')


def order_rail():
    """Under the order board: a brass rail on turned stands holding the finished orders, each in a paper cover with
    its name ticket (Braum, Iona, Mira and eleven more), a shelf of hatboxes and boxed shirts above."""
    root, p, path = s.begin('tailor-order-rail', 'v1')
    W = 3.6
    for x in (-W / 2 + .05, W / 2 - .05):
        lathe(p, '@oak_dark', [(.16, 0), (.12, .05), (.04, .1), (.035, 1.75), (.05, 1.8)], (x, 0, 0), 14, True)
    rod(p, 'brass', (-W / 2 + .05, 0, 1.72), (W / 2 - .05, 0, 1.72), .02, 10)
    rod(p, '@oak_dark', (-W / 2 + .05, .1, .08), (W / 2 - .05, .1, .08), .025, 8)
    names = ['BRAUM', 'IONA', 'MIRA', 'NELL', 'MR ODD', 'ROWAN', 'TEO', 'TESSA', 'ADA', 'MISS PIP', 'HALL', 'BAND', 'REVD', 'J.K.']
    colours = ['cloth_navy', 'cloth_charcoal', 'cloth_forest', 'cloth_wine', 'cloth_tweed', 'cloth_camel', 'cloth_slate',
               'cloth_plum', 'cloth_rust', 'cloth_grey', 'cloth_black', 'cloth_navy', 'cloth_black', 'cloth_olive']
    for i in range(14):
        x = -W / 2 + .25 + i * (W - .5) / 13
        _garment(p, x, (i % 2) * .05 - .02, 1.72, .95 + (i % 3) * .12, colours[i], i not in (0, 1, 2), names[i])
    # Shelf of hatboxes and shirt boxes over the rail, on brackets fixed to the wall behind.
    box(p, '@oak', (0, .12, 2.12), (W, .38, .035), .006)
    for x in (-W / 2 + .2, 0, W / 2 - .2):
        p.solid(s.surface('oak'), [(x, .3, 2.1), (x, .3, 1.9), (x, .05, 2.1)], .04, (1, 0, 0))
    for i in range(6):
        x = -W / 2 + .35 + i * (W - .7) / 5
        if i % 2 == 0:
            lathe(p, ['cloth_blush', 'stripe_cream', 'mint_box'][i // 2], [(0, 0), (.16, 0), (.16, .2), (0, .2)], (x, .12, 2.14), 22, True)
            lathe(p, 'navy', [(0, .19), (.17, .19), (.17, .23), (0, .23)], (x, .12, 2.14), 22, True)
            tube(p, 'ribbon_red', [(x - .1, .12, 2.37), (x, .12, 2.44), (x + .1, .12, 2.37)], .006, 4)
        else:
            for j in range(3):
                box(p, ['white', 'cloth_sky', 'card'][j], (x, .12, 2.18 + j * .085), (.3, .26, .08), .008)
            box(p, 'ribbon_red/f', (x, .12 - .131, 2.3), (.02, .004, .25), 0)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- hat stand
def hat_stand():
    """A bentwood hat stand with a bowler, a boater with a ribbon, a cap and a scarf, beside a stack of round
    hatboxes in stripes."""
    root, p, path = s.begin('tailor-hat-stand', 'v1')
    for a in range(4):
        tube(p, 'wood_dark', s.bezier(((0, 0, .5)), (math.cos(a * math.pi / 2) * .1, math.sin(a * math.pi / 2) * .1, .3),
                                      (math.cos(a * math.pi / 2) * .25, math.sin(a * math.pi / 2) * .25, .08),
                                      (math.cos(a * math.pi / 2) * .3, math.sin(a * math.pi / 2) * .3, .0), 8), .02, 6)
    rod(p, 'wood_dark', (0, 0, .2), (0, 0, 1.75), .028, 10)
    ball(p, 'wood_dark', (0, 0, 1.79), .04)
    for i in range(4):
        a = i * math.pi / 2 + .4
        d = Vector((math.cos(a), math.sin(a), 0))
        tube(p, 'wood_dark', [(d.x * .02, d.y * .02, 1.55), (d.x * .16, d.y * .16, 1.62), (d.x * .2, d.y * .2, 1.72), (d.x * .17, d.y * .17, 1.76)],
             .014, 5)
    lathe(p, 'cloth_black', [(0, 0), (.16, 0), (.16, .008), (.1, .012), (.1, .06), (.08, .12), (0, .14)], (.16, 0, 1.7), 18, True)
    lathe(p, 'cane', [(0, 0), (.2, 0), (.2, .01), (.11, .012), (.11, .09), (0, .09)], (-.1, .14, 1.74), 18, True)
    lathe(p, 'cloth_navy', [(.111, .02), (.111, .05)], (-.1, .14, 1.74), 18, True, cap0=False, cap1=False)
    lathe(p, 'cloth_tweed', [(0, 0), (.12, 0), (.11, .05), (0, .07)], (-.05, -.16, 1.68), 14, True)
    box(p, 'cloth_tweed', (-.05, -.28, 1.69), (.14, .1, .015), .006)
    sheet(p, 'cloth_rose', lambda u, v: (.12 + .03 * math.sin(v * 9), -.1 + u * .08, 1.6 - v * .7), 2, 8, .01)
    for i, (r, colour) in enumerate(((.22, 'stripe_cream'), (.19, 'cloth_blush'), (.15, 'mint_box'))):
        z = i * .24
        lathe(p, colour, [(0, 0), (r, 0), (r, .2), (0, .2)], (.48, .1, z), 24, True)
        lathe(p, 'navy', [(0, .19), (r + .01, .19), (r + .01, .23), (0, .23)], (.48, .1, z), 24, True)
        for k in range(8):
            a = k * math.tau / 8
            box(p, 'cloth_rose/f' if i == 0 else 'white/f', (.48 + math.cos(a) * r * 1.002, .1 + math.sin(a) * r * 1.002, z + .1), (.02, .02, .18), 0,
                rot=(0, 0, a))
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- haberdashery counter
def counter():
    """The haberdashery counter: navy with gilt lines and a glass top over trays of buttons, a rack of ribbons on
    rollers, button cards, cotton reels, a brass yard rule along the front edge, the order book and a small till."""
    root, p, path = s.begin('tailor-counter', 'v1')
    W, D, H = 2.8, .8, .95
    box(p, JOIN, (0, .03, H / 2 - .05), (W - .04, D - .06, H - .1), .01)
    box(p, 'navy_dark', (0, 0, .045), (W, D - .02, .09), .008)
    for i in range(4):
        x = -W / 2 + W / 8 + i * W / 4
        s.panel(p, JOIN, x, -D / 2 + .01, .48, W / 4 - .06, .62, .06, .03, 'gold_leaf')
    for side in (-1, 1):
        with p.placed((side * (W / 2 - .01), 0, 0), 90 * side):
            s.panel(p, JOIN, 0, -.01, .48, D - .14, .62, .06, .03, 'gold_leaf')
    box(p, '@oak_dark', (0, 0, H - .07), (W + .04, D + .04, .04), .006)
    # Glass top over trays of buttons and thimbles.
    for i in range(8):
        x = -W / 2 + .2 + i * (W - .4) / 7
        box(p, 'velvet_teal' if i % 2 else 'velvet_wine', (x, -.05, H - .035), (.3, .5, .02), .004)
        for j in range(12):
            bx = x - .1 + (j % 3) * .1
            by = -.25 + (j // 3) * .13
            colour = [['gold', 'silver', 'ink', 'china'], ['wood_mid', 'cloth_wine', 'cloth_sky', 'cream'], ['brass', 'cloth_forest', 'oxblood', 'white']][i % 3][j % 4]
            rod(p, colour + '/f', (bx, by, H - .024), (bx, by, H - .016), .022, 10)
            for h in ((-.006, 0), (.006, 0)):
                rod(p, 'ink/f', (bx + h[0], by, H - .016), (bx + h[0], by, H - .0155), .003, 4)
    box(p, 'shops_clear_glass', (0, 0, H - .004), (W, D, .008), 0)
    box(p, 'brass', (0, -D / 2 - .005, H + .004), (W, .02, .012), .002)
    for i in range(29):
        box(p, 'ink/f', (-W / 2 + .05 + i * (W - .1) / 28, -D / 2 - .016, H - .004), (.004, .002, .008 if i % 4 else .012), 0)
    # Ribbon rack: rollers on a brass frame at the left end.
    rx = -1.0
    for x in (rx - .3, rx + .3):
        rod(p, 'brass', (x, .2, H), (x, .2, H + .55), .012, 6)
    for k in range(4):
        z = H + .1 + k * .13
        rod(p, 'brass', (rx - .3, .2, z), (rx + .3, .2, z), .006, 4)
        for i in range(5):
            x = rx - .24 + i * .12
            colour = ['ribbon_red', 'cloth_sky', 'gold', 'cloth_blush', 'navy', 'cloth_forest', 'cloth_ivory', 'cloth_plum'][(i + k * 2) % 8]
            rod(p, colour, (x - .04, .2, z), (x + .04, .2, z), .045, 12)
            if k == 0 and i % 2 == 0:
                sheet(p, colour, lambda u, v, x=x: (x - .03 + u * .06, .155 - .02 * v, z - .045 - v * .25), 1, 4, .003)
    # Button cards on a little stand, cotton reels, the order book and a small brass till.
    for i in range(4):
        with p.framed(Matrix.Translation((-.1 + i * .17, .15, H + .01)) @ Matrix.Rotation(-.25, 4, 'X')):
            box(p, 'card', (0, 0, .1), (.15, .01, .2), .003)
            for j in range(6):
                rod(p, ['gold', 'ink', 'china', 'cloth_wine', 'cloth_sky', 'silver'][(i + j) % 6] + '/f',
                    (-.03 + (j % 2) * .06, -.006, .05 + (j // 2) * .055), (-.03 + (j % 2) * .06, -.01, .05 + (j // 2) * .055), .016, 8)
    for i in range(6):
        x = .55 + (i % 3) * .07
        y = .2 + (i // 3) * .08
        lathe(p, '@oak', [(.025, 0), (.025, .01), (.017, .012), (.017, .07), (.025, .072), (.025, .082)], (x, y, H), 10, True)
        rod(p, CLOTHS[i * 3], (x, y, H + .012), (x, y, H + .07), .023, 10)
    box(p, 'cloth_wine', (.9, -.15, H + .02), (.36, .26, .04), .006)
    box(p, 'paper', (.9, -.15, H + .042), (.34, .24, .008), 0)
    for k in range(6):
        box(p, 'ink/f', (.85 + (k % 2) * .1, -.24 + k * .03, H + .047), (.1, .004, .002), 0)
        box(p, 'enamel_red/f', (1.05, -.24 + k * .03, H + .047), (.012, .004, .002), 0) if k < 2 else None
    box(p, 'brass', (1.2, .2, H + .12), (.3, .25, .22), .02)
    box(p, 'ink/f', (1.2, .07, H + .2), (.2, .004, .06), 0)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the settee
def settee():
    """A buttoned settee in teal velvet on turned legs for those who wait, a little round table beside it with tea
    and a fashion journal, and a footstool."""
    root, p, path = s.begin('tailor-settee', 'v1')
    W = 1.7
    for x in (-W / 2 + .08, W / 2 - .08):
        for y in (-.25, .25):
            lathe(p, '@oak_dark', [(.03, 0), (.04, .05), (.03, .12), (.04, .2)], (x, y, 0), 10, True)
    s.soft(p, 'velvet_teal', (0, .02, .3), (W, .62, .2), .06)
    s.soft(p, 'velvet_teal', (0, -.02, .43), (W - .2, .55, .12), .05)
    s.soft(p, 'velvet_teal', (0, .27, .7), (W - .1, .16, .55), .07)
    for side in (-1, 1):
        s.soft(p, 'velvet_teal', (side * (W / 2 - .06), 0, .55), (.14, .62, .32), .06)
        ball(p, 'velvet_teal', (side * (W / 2 - .06), -.25, .7), .09, (.8, 1, .7))
    for i in range(5):
        for j in range(2):
            ball(p, 'gold/f', (-W / 2 + .35 + i * (W - .7) / 4, .18, .62 + j * .16), .012)
    tube(p, 'gold', [(-W / 2 + .1, .2, .97), (0, .2, 1.0), (W / 2 - .1, .2, .97)], .01, 5)
    s.soft(p, 'cloth_blush', (-.45, .1, .58), (.32, .12, .3), .06, rot=(-.3, .2, 0))
    # Side table with tea and a journal.
    tx = W / 2 + .4
    lathe(p, '@oak_dark', [(.15, 0), (.12, .02), (.03, .05), (.025, .5), (.06, .55)], (tx, 0, 0), 14, True)
    lathe(p, '@oak_dark', [(0, .55), (.26, .55), (.27, .58), (0, .58)], (tx, 0, 0), 24, True)
    s.cup(p, (tx + .1, .06, .58), .035, .055, 'china', 'cloth_rose', angle=0)
    box(p, 'paper', (tx - .05, -.08, .59), (.18, .24, .012), .002, rot=(0, 0, .3))
    box(p, 'cloth_rose/f', (tx - .05, -.08, .601), (.16, .22, .002), 0, rot=(0, 0, .3))
    text(p, 'ink/f', 'LA MODE', s.flat_text(tx - .05, -.08, .605, .3), .028, 'cinzel')
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- pressing station
def pressing():
    """A pressing station: a padded ironing board on folding legs with a sleeve board, two sad irons heating on a
    little black stove, a sprinkler bottle and a stack of pressed shirts on a stool."""
    root, p, path = s.begin('tailor-pressing', 'v1')
    for x in (-.35, .35):
        for a in (-1, 1):
            rod(p, 'wood_dark', (x - a * .2, 0, 0), (x + a * .15, 0, .82), .016, 6)
    p.solid('cloth_ivory', [(-.75, -.18, .86), (.5, -.18, .86), (.75, -.06, .86), (.78, 0, .86), (.75, .06, .86), (.5, .18, .86), (-.75, .18, .86)],
            .05, (0, 0, 1))
    p.solid('@gingham_blue', [(-.73, -.16, .868), (.5, -.16, .868), (.72, -.05, .868), (.75, 0, .868), (.72, .05, .868), (.5, .16, .868),
                               (-.73, .16, .868)], .003, (0, 0, 1))
    box(p, 'cloth_ivory', (-.3, 0, .97), (.5, .14, .04), .015)
    rod(p, 'wood_dark', (-.3, 0, .89), (-.3, 0, .95), .02, 6)
    sheet(p, 'cloth_sky', lambda u, v: (-.6 + u * .7, -.15 + v * .3, .88 + .004 * math.sin(u * 7)), 6, 3, .006)
    with p.placed((.25, .02, .872), -20):
        p.solid('iron', [(-.1, -.05, 0), (.06, -.05, 0), (.12, 0, 0), (.06, .05, 0), (-.1, .05, 0)], .06, (0, 0, -1))
        tube(p, 'wood_dark', [(-.07, 0, .06), (-.05, 0, .12), (.04, 0, .12), (.06, 0, .06)], .014, 6)
    # The stove with two irons.
    sx = 1.05
    box(p, 'iron', (sx, 0, .35), (.36, .36, .6), .03)
    box(p, 'iron_light', (sx, 0, .66), (.4, .4, .03), .006)
    box(p, 'ink', (sx, -.185, .3), (.18, .01, .14), .004)
    box(p, 'enamel_red', (sx, -.194, .3), (.14, .004, .08), 0)
    for i in range(4):
        rod(p, 'iron', (sx + (i % 2 - .5) * .28, (i // 2 - .5) * .28, 0), (sx + (i % 2 - .5) * .28, (i // 2 - .5) * .28, .06), .025, 6)
    rod(p, 'iron', (sx + .1, .1, .66), (sx + .1, .1, 1.5), .04, 10)
    for i, x in enumerate((sx - .08, sx + .06)):
        with p.placed((x, -.05, .675), 90 + i * 20):
            p.solid('iron', [(-.08, -.04, 0), (.05, -.04, 0), (.1, 0, 0), (.05, .04, 0), (-.08, .04, 0)], .055, (0, 0, -1))
            tube(p, 'iron', [(-.06, 0, .055), (-.04, 0, .1), (.03, 0, .1), (.05, 0, .055)], .01, 5)
    lathe(p, 'glass_green', [(.03, 0), (.035, .1), (.015, .14), (.01, .18)], (-.65, .1, .88), 10, True)
    lathe(p, 'zinc', [(0, .18), (.015, .18), (.012, .2), (0, .21)], (-.65, .1, .88), 8, True)
    lathe(p, '@oak_dark', [(.16, 0), (.14, .4), (.17, .42)], (-1.05, 0, 0), 14, True, cap1=False)
    for i in range(4):
        box(p, ['white', 'cloth_sky', 'white', 'cloth_blush'][i], (-1.05, 0, .45 + i * .05), (.3, .24, .045), .01, rot=(0, 0, .05 * (i % 2)))
        box(p, 'paper/f', (-1.05, 0, .45 + i * .05), (.12, .25, .054), 0, rot=(0, 0, .05 * (i % 2))) if i == 3 else None
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- the rug
def rug():
    """A knotted rug, 2.8 x 2.0, wine field and navy border, with a fringe at the ends. It lies flat and casts nothing."""
    root, p, path = s.begin('tailor-rug', 'v1')
    W, D = 2.8, 2.0
    p.box(s.surface('rug_wine'), (0, 0, .008), (W, D, .012), bevel=0, uv=('rect', (0, 0, 1, 1)))
    for side in (-1, 1):
        for i in range(40):
            y = -D / 2 + .04 + i * (D - .08) / 39
            box(p, 'cream/f', (side * (W / 2 + .03), y, .004), (.06, .012, .004), 0)
    s.finish(root, p, path, RECORD)


# ------------------------------------------------------------------------------------------------- chandelier
def chandelier():
    """A small brass chandelier: a ceiling rose and chain, a turned stem, five curled arms with tulip glass shades and
    candle bulbs (one lamp-glass mesh, so the room binds it as one fixture), crystal drops. Pivot at the top; it
    hangs 1.25 m."""
    root, p, path = s.begin('tailor-chandelier', 'v1')
    lathe(p, 'cream_paint', [(0, 0), (.12, 0), (.1, -.03), (0, -.04)], (0, 0, 0), 18, True)
    for i in range(10):
        torus(p, 'brass', (0, 0, -.06 - i * .055), .014, .004, normal=(1, 0, 0) if i % 2 else (0, 1, 0), seg=8, n=3)
    lathe(p, 'brass', [(0, -1.25), (.05, -1.24), (.07, -1.2), (.04, -1.15), (.03, -1.05), (.06, -1.0), (.03, -.95), (.025, -.7),
                       (.04, -.66), (0, -.6)], (0, 0, 0), 14, True)
    for i in range(5):
        a = i * math.tau / 5
        d = Vector((math.cos(a), math.sin(a), 0))
        pts = [(d.x * .04, d.y * .04, -1.1), (d.x * .18, d.y * .18, -1.16), (d.x * .3, d.y * .3, -1.1), (d.x * .34, d.y * .34, -1.0)]
        tube(p, 'brass', s.bezier(*pts, 8), .01, 5)
        tube(p, 'brass', [(d.x * .3, d.y * .3, -1.1), (d.x * .26, d.y * .26, -1.2), (d.x * .2, d.y * .2, -1.22)], .006, 4)
        lathe(p, 'brass', [(0, 0), (.035, 0), (.03, .03), (.02, .04)], (d.x * .34, d.y * .34, -1.0), 10, True)
        lathe(p, 'shops_clear_glass', [(.02, .03), (.05, .06), (.07, .12), (.075, .15)], (d.x * .34, d.y * .34, -1.0), 12, True,
              cap0=False, cap1=False, ripple=lambda aa, z: 1 + .08 * math.cos(aa * 6))
        lathe(p, 'shops_lamp_glass', [(0, .03), (.014, .04), (.014, .09), (.008, .11), (0, .12)], (d.x * .34, d.y * .34, -1.0), 8, True,
              cap0=False)
        ball(p, 'glass_clear', (d.x * .22, d.y * .22, -1.26), .018, (1, 1, 1.6))
    ball(p, 'glass_clear', (0, 0, -1.3), .03, (1, 1, 1.7))
    s.finish(root, p, path, RECORD)


AUTHORS = {'tailor-shell': shell, 'tailor-cloth-shelves': cloth_shelves, 'tailor-spool-wall': spool_wall,
           'tailor-cutting-table': cutting_table, 'tailor-dress-form': dress_form, 'tailor-dress-form-gown': dress_form_gown,
           'tailor-dress-form-suit': dress_form_suit, 'tailor-sewing-table': sewing_table, 'tailor-mirror': mirror,
           'tailor-fitting-room': fitting_room, 'tailor-order-rail': order_rail, 'tailor-hat-stand': hat_stand,
           'tailor-counter': counter, 'tailor-settee': settee, 'tailor-pressing': pressing, 'tailor-rug': rug,
           'tailor-chandelier': chandelier}

if __name__ == '__main__':
    s.run(AUTHORS, RECORD)
