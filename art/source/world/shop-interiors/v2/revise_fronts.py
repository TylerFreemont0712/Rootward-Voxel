"""Deliberate storefront edits for the three market shops, 2026-11-12: copies each adopted v2 master to v3 and gives
it a front of its own. Never touches the upper storeys, the roof, the door leaf's hinge or the wall lantern.

    blender -b --factory-startup --python revise_fronts.py -- [haverlund-bakery|haverlund-greengrocer|haverlund-tailor]

For each shop it:
  * takes out the old shelf of wares in both windows and deepens each window into a lit display box 0.7 m deep;
  * paints the joinery in the shop's own colour (oxblood, bottle green, navy), which the door inside now matches;
  * dresses each window with the shop's own display, glazes it, and letters the glass in gold;
  * adds the shop's own street features: an awning or valance, window boxes or a ledge of crates, hanging baskets,
    a projecting bracket sign.
Nothing stands more than 0.25 m in front of the wall, because the pavement cells in front are the door approach.
Refuses an existing v3 unless it is this record's own untouched output and `--redo` is given. Normal exports:
scripts/world-art.sh build <id>. Front is Blender -Y, one unit is one metre.
"""
from pathlib import Path
import hashlib
import json
import math
import sys

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import interior_kit as s  # noqa: E402
import goods as g  # noqa: E402
from interior_kit import arc, ball, box, lathe, rod, sheet, text, torus, tube  # noqa: E402

k = s.k
ROOT = s.ROOT
FACE = -3.2           # the shopfront plane
GLASS = -3.172        # the new panes, just behind the old glazing strokes
BACK = -2.45          # the deepened display's back wall
FLOOR, CEIL = .72, 2.79

# label, half width X, door centre dx, joinery colour, the shop's dark accent
SHOPS = {
    'haverlund-bakery': ('MORNING LOAF', 2.5, .3, 'oxblood', 'oxblood_dark'),
    'haverlund-greengrocer': ('THE PANTRY', 2.3, .5, 'bottle', 'bottle_dark'),
    'haverlund-tailor': ('FINCH & THREAD', 2.5, -.3, 'navy', 'navy_dark'),
}


def windows(X, dx):
    """The two display openings (x0, x1) between the corner piers and the door, as the v2 revision drew them."""
    dw = 1.15
    out = []
    for a, b in ((-X + .36, dx - dw / 2 - .17), (dx + dw / 2 + .17, X - .36)):
        if b - a >= .23:
            out.append((a, b))
    return out


def clear_old_wares(spans):
    """Deletes every face lying wholly inside a window's old display volume (the shelves and their wares), and the
    old dark backing behind each window. Frames, mullions, transoms, sills, glazing strokes and the door stay."""
    removed = 0
    for obj in list(bpy.context.scene.objects):
        if obj.type != 'MESH' or obj.parent is None or obj.parent.type != 'EMPTY' or obj.parent.parent is not None:
            continue
        if obj.name.startswith(('door_leaf', 'detail_', 'lamp_glass', 'shop_glazing')):
            continue
        bm = bmesh.new()
        bm.from_mesh(obj.data)
        take = []
        for f in bm.faces:
            pts = [obj.matrix_world @ v.co for v in f.verts]
            for a, b in spans:
                inside_x = all(a - .002 < p.x < b + .002 for p in pts)
                wares = inside_x and all(-3.28 < p.y < -2.86 and .715 < p.z < 2.715 for p in pts)
                backing = obj.name.startswith('shop_recess') and all(a - .01 < p.x < b + .01 and -2.9 < p.y < -2.8 and p.z > .5 for p in pts)
                if wares or backing:
                    take.append(f)
                    break
        removed += len(take)
        if take:
            bmesh.ops.delete(bm, geom=take, context='FACES')
        bm.to_mesh(obj.data)
        bm.free()
        obj.data.update()
    return removed


def recolour(name, colour):
    mat = bpy.data.materials[name]
    rgb = (*k._rgb(s.PALETTE[colour]), 1)
    mat.diffuse_color = rgb
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = rgb


def display_box(p, a, b, back='cream_paint', floor='@oak', dado=None):
    """A deep display box behind one window: back wall, sides, floor and ceiling, a dado rail on the back."""
    w = b - a
    c = (a + b) / 2
    box(p, back, (c, BACK - .02, (FLOOR + CEIL) / 2), (w, .04, CEIL - FLOOR), 0)
    # Sides stand 3-5 cm inside the opening, clear of the stone reveal's own faces; sides, floor and ceiling stop
    # 1 cm short of the back wall's rear face, so no two of them share a plane.
    y0, y1 = FACE + .05, BACK - .03
    for x in (a + .04, b - .04):
        box(p, back, (x, (y0 + y1) / 2, (FLOOR + CEIL) / 2), (.02, y1 - y0, CEIL - FLOOR), 0)
    box(p, floor, (c, (y0 + y1) / 2, FLOOR - .01), (w, y1 - y0, .02), 0)
    box(p, back, (c, (y0 + y1) / 2, CEIL + .01), (w, y1 - y0, .02), 0)
    if dado:
        box(p, dado, (c, BACK - .045, FLOOR + .4), (w - .04, .01, .8), 0)
        box(p, 'gold_leaf', (c, BACK - .052, FLOOR + .81), (w - .04, .006, .02), 0)


def glaze(p, a, b):
    p.pane('shops_clear_glass', ((a + b) / 2, GLASS, (FLOOR + 2.72) / 2), b - a - .13, 2.72 - FLOOR - .04, (0, -1))


def window_box(p, a, b, colour, flowers=('geranium', 'flower_white', 'geranium')):
    """A planter on brackets under a window, its front 0.25 m proud of the wall, with geraniums and trailing ivy."""
    c, w = (a + b) / 2, b - a - .08
    box(p, '#' + colour, (c, -3.37, .58), (w, .2, .2), .015)
    box(p, 'gold_leaf', (c, -3.472, .58), (w - .06, .004, .02), 0)
    for x in (a + .12, b - .12):
        p.solid(s.joinery('paint_' + colour, s.PALETTE[colour]), [(x, -3.26, .48), (x, -3.26, .3), (x, -3.44, .48)], .03, (1, 0, 0))
    box(p, 'soil', (c, -3.37, .655), (w - .04, .16, .02), 0)
    n = max(3, int(w / .16))
    for i in range(n):
        x = c - w / 2 + .08 + i * (w - .16) / (n - 1)
        col = flowers[i % len(flowers)]
        for j in range(5):
            aa = j * 1.3 + i
            ball(p, 'leaf/f', (x + math.cos(aa) * .04, -3.37 + math.sin(aa) * .04, .7 + (j % 2) * .03), .035, (1, 1, .6))
        if i % 2 == 0:
            for j in range(3):
                ball(p, col + '/f', (x + (j - 1) * .03, -3.36 + (j % 2) * .02, .78), .028)
        else:
            tube(p, 'leaf_dark/f', [(x, -3.45, .66), (x + .02, -3.49, .55), (x - .01, -3.5, .42)], .008, 3)
            for z in (.6, .5):
                ball(p, 'leaf_dark/f', (x + .01, -3.49, z), .02, (1, .5, 1))


def bracket_sign(p, x, z, colour, emblem, words, side=-1):
    """A projecting sign on a scrolled iron bracket, hung at right angles to the wall so it reads along the street.
    `emblem(p, x, y, z)` draws the gilt device on both faces of the board."""
    reach = .95
    tube(p, 'iron', [(x, FACE + .02, z + .5), (x, FACE - reach, z + .5)], .02, 6)
    tube(p, 'iron', s.bezier((x, FACE + .02, z + .05), (x, FACE - .3, z + .1), (x, FACE - .6, z + .35), (x, FACE - reach + .05, z + .5), 10), .014, 5)
    pts = [(x, FACE - .3 - .12 * math.cos(t) * (1 - t / 9), z + .27 + .12 * math.sin(t) * (1 - t / 9)) for t in [i * .45 for i in range(18)]]
    tube(p, 'iron', pts, .01, 4)
    box(p, 'iron', (x, FACE + .01, z + .28), (.08, .03, .56), .006)
    for dy in (-.25, -.75):
        tube(p, 'iron', [(x, FACE + dy, z + .5), (x, FACE + dy, z + .42)], .008, 4)
        torus(p, 'iron', (x, FACE + dy, z + .41), .02, .005, normal=(0, 1, 0), seg=8, n=3)
    with p.placed((x, FACE - .5, z), 0):
        box(p, '#' + colour, (0, 0, 0), (.05, .7, .66), .02)
        box(p, 'gold_leaf', (0, 0, 0), (.066, .64, .6), .004)
        box(p, '#' + colour, (0, 0, 0), (.082, .6, .56), .004)
        for face in (-1, 1):
            emblem(p, face * .044, 0, .06, face)
            text(p, 'gold_leaf', words, k.facing_text(face * .046, 0, -.21, (face, 0)), .065, 'cinzel')


# ------------------------------------------------------------------------------------------------- Morning Loaf
def bakery(p, spans, dx):
    (a1, b1), (a2, b2) = spans
    for a, b in spans:
        display_box(p, a, b, 'cream_paint', '@oak', 'oxblood')
        glaze(p, a, b)
        window_box(p, a, b, 'oxblood')
    # Left window: oxblood steps with lace, a wedding cake at the back, loaves and a plait, tarts and cupcakes in front.
    c = (a1 + b1) / 2
    w = b1 - a1 - .06
    for i, (y0, y1, top) in enumerate(((-3.12, -2.9, FLOOR + .02), (-2.9, -2.7, FLOOR + .22), (-2.7, -2.47, FLOOR + .42))):
        box(p, 'oxblood', (c, (y0 + y1) / 2, (FLOOR + top) / 2), (w, y1 - y0, top - FLOOR), .006)
        box(p, 'white/f', (c, y0 - .004, top - .03), (w, .006, .05), 0)
        for j in range(int(w / .05)):
            ball(p, 'white/f', (c - w / 2 + .025 + j * .05, y0 - .005, top - .06), .012)
    top = g.cake_stand(p, (c, -2.58, FLOOR + .42), .17, .1)
    g.cake(p, (c, -2.58, top), .14, 3, 'crumb', 'icing', None, roses='raspberry')
    for i, x in enumerate((c - .55, c + .5)):
        g.boule(p, (x, -2.6, FLOOR + .42), .12, 'crust' if i else 'crust_light', 'crumb', .5 * i)
    g.plait(p, (c - .3, -2.8, FLOOR + .22), .34, .03, angle=0)
    g.batard(p, (c + .3, -2.8, FLOOR + .22), .32, .07, 'crust_light', angle=0)
    for i in range(5):
        x = c - .6 + i * .3
        g.doily(p, (x, -3.0, FLOOR + .026), .09)
        if i % 2 == 0:
            g.tart(p, (x, -3.0, FLOOR + .03), .08, ['strawberry', 'blueberry', 'raspberry'][i // 2])
        else:
            for j in range(3):
                g.cupcake(p, (x - .05 + j * .05, -3.0 + (j % 2) * .03, FLOOR + .03), .025,
                          ['mac_pink', 'mac_pist', 'mac_lemon'][j], ['icing_pink', 'icing_mint', 'icing_lemon'][j])
    # Pretzels hung on ribbons from the ceiling, and a garland of wheat across the top.
    for i in range(4):
        x = a1 + .25 + i * (w - .3) / 3
        rod(p, 'ribbon_red/f', (x, -3.05, CEIL), (x, -3.05, 2.3), .004, 3)
        with p.framed(Matrix.Translation((x, -3.05, 2.22)) @ Matrix.Rotation(math.pi / 2, 4, 'X')):
            g.pretzel(p, (0, 0, -.02), .07, 'crust_dark', 0)
    pts = [(a1 + .06 + t * (w), -3.08, 2.66 - .14 * math.sin(math.pi * t * 2) ** 2) for t in [i / 24 for i in range(25)]]
    tube(p, 'cane/f', pts, .012, 4)
    for t in range(0, 25, 2):
        x, y, z = pts[t]
        for j in range(3):
            rod(p, 'butter/f', (x, y, z), (x + (j - 1) * .03, y - .01, z - .09), .005, 3)
            ball(p, 'crust_light/f', (x + (j - 1) * .035, y - .012, z - .1), .012, (1, 1, 2))
    # Right window: a tall basket of baguettes, a leaning rack of boules, a chalk sign.
    c2 = (a2 + b2) / 2
    lathe(p, 'wicker', [(.11, 0), (.14, .4), (.15, .42)], (c2 - .25, -2.75, FLOOR), 16, True, cap1=False,
          ripple=lambda aa, zz: 1 + .04 * math.cos(aa * 16))
    for i in range(6):
        aa = i * 2.4
        g.baguette(p, (c2 - .25 + math.cos(aa) * .05, -2.75 + math.sin(aa) * .05, FLOOR + .05),
                   (c2 - .25 + math.cos(aa) * .14, -2.75 + math.sin(aa) * .1, FLOOR + .8 + (i % 3) * .05), .03)
    for k_, z in enumerate((FLOOR + .05, FLOOR + .4, FLOOR + .75)):
        y = -2.62 - k_ * .07
        box(p, '@oak', (c2 + .2, y, z), (.5, .2, .025), .004, rot=(.25, 0, 0))
        for j in range(2):
            g.boule(p, (c2 + .08 + j * .24, y, z + .02), .09, 'crust' if (j + k_) % 2 else 'crust_light', 'crumb', j)
    for x in (c2 - .05, c2 + .45):
        rod(p, '@oak', (x, -2.6, FLOOR), (x, -2.82, FLOOR + 1.0), .015, 6)
    box(p, 'chalk', (c2 + .2, -3.05, FLOOR + .2), (.36, .02, .26), .006, rot=(-.2, 0, 0))
    box(p, '@oak', (c2 + .2, -3.04, FLOOR + .2), (.4, .015, .3), .006, rot=(-.2, 0, 0))
    m = k.facing_text(c2 + .2, -3.065, FLOOR + .24, (0, -1)) @ Matrix.Rotation(-.2, 4, 'X')
    text(p, 'chalk_line', 'FRESH', m, .06, 'alegreya')
    m = k.facing_text(c2 + .2, -3.068, FLOOR + .14, (0, -1)) @ Matrix.Rotation(-.2, 4, 'X')
    text(p, 'chalk_line', 'TODAY', m, .06, 'alegreya')
    # Gold lettering on the glass.
    s.arched_text(p, 'gold_leaf', 'BREAD & CAKES', ((a1 + b1) / 2, -3.207, 2.05), 1.4, .1, .9)
    s.arched_text(p, 'gold_leaf', 'PASTRIES', ((a2 + b2) / 2, -3.207, 2.07), .9, .09, .7)
    # Street: a cream and oxblood awning; a bracket sign with a gilt pretzel at the left corner.
    k.awning(p, (.4, -3.36), 4.1, .46, 2.84, .26, (0, -1), ('stripe_cream', 'oxblood'), .3)

    def emblem(p, x, y, z, face):
        with p.framed(Matrix.Translation((x + face * .006, y, z)) @ Matrix.Rotation(math.pi / 2, 4, 'Y') @ Matrix.Rotation(math.pi / 2, 4, 'Z')):
            g.pretzel(p, (0, 0, -.02), .11, 'gold_leaf', 0, salt=False)
    bracket_sign(p, -2.3, 3.95, 'oxblood', emblem, 'BAKERY')


# ------------------------------------------------------------------------------------------------- The Pantry
def pantry(p, spans, dx):
    (a1, b1), (a2, b2) = spans
    for a, b in spans:
        display_box(p, a, b, '@green_boards', '@oak', None)
        glaze(p, a, b)
    # Left window: a raked stand of crates, a pyramid of jam jars and honey, onion and garlic strings above.
    c = (a1 + b1) / 2
    w = b1 - a1 - .06
    for row, (y, z) in enumerate(((-2.98, FLOOR + .02), (-2.72, FLOOR + .28))):
        kinds = [['apple', 'orange', 'lemon'], ['apple_green', 'plum', 'pear']][row]
        if row == 1:
            box(p, '@oak', (c, -2.645, FLOOR + .13), (w - .1, .29, .26), .006)
        for i, kind in enumerate(kinds):
            x = c - w / 3 + i * w / 3
            with p.framed(Matrix.Translation((x, y, z)) @ Matrix.Rotation(.25, 4, 'X')):
                s.crate(p, (0, 0, 0), w / 3 - .04, .26, .12, '@oak', 'wood_dark', 2)
                g.heap(p, kind, (0, 0, .1), w / 3 - .1, .2, 2)
            box(p, 'chalk', (x, y - .15, z + .05), (.13, .01, .06), .003)
            text(p, 'chalk_line/f', ['3P', '4P', '2P', '3P', '5P', '4P'][row * 3 + i], k.facing_text(x, y - .157, z + .05, (0, -1)), .035, 'alegreya')
    s.jar(p, (c + w / 2 - .18, -2.55, FLOOR + .56), .14, .05, 'jam', 'gold')
    for i in range(3):
        for j in range(3 - i):
            s.jar(p, (c + w / 2 - .42 + j * .12 + i * .06, -2.55, FLOOR + .56 + i * .145), .13, .05,
                  ['jam', 'honey', 'raspberry', 'lemon'][(i + j) % 4], 'gold')
    rod(p, '@oak', (a1 + .06, -2.9, 2.5), (b1 - .06, -2.9, 2.5), .02, 6)
    for i in range(6):
        x = a1 + .2 + i * (w - .25) / 5
        kind = ['onion', 'garlic', 'onion_red'][i % 3]
        for j in range(6):
            g.onion(p, (x + (.03 if j % 2 else -.03), -2.9, 2.38 - j * .075), .035, kind if kind != 'garlic' else 'garlic')
        rod(p, 'string/f', (x, -2.9, 2.5), (x, -2.9, 2.0), .005, 3)
    # Right window: flowers in zinc buckets and a basket of eggs.
    c2 = (a2 + b2) / 2
    for i, (x, col) in enumerate(((c2 - .15, 'flower_yellow'), (c2 + .15, 'flower_pink'))):
        lathe(p, 'zinc', [(.08, 0), (.1, .24), (.105, .25)], (x, -2.7, FLOOR), 14, True, cap1=False)
        g.flower_bunch(p, (x, -2.7, FLOOR + .15), .5, col, 8, .07)
    s.basket(p, (c2, -3.0, FLOOR), .14, .09, True)
    for j in range(8):
        aa = j * 2.4
        g.plum(p, (c2 + math.cos(aa) * .07 * (j > 0), -3.0 + math.sin(aa) * .06 * (j > 0), FLOOR + .06), .028, 'egg' if j % 3 else 'egg_brown')
    s.arched_text(p, 'gold_leaf', 'FRUIT & VEG', (c, -3.207, 2.08), 1.4, .1, .8)
    s.arched_text(p, 'gold_leaf', 'DAIRY', (c2, -3.207, 2.1), .6, .08, .7)
    # Street: a green and cream awning; a sloped ledge of crates under the big window; hanging baskets by the door.
    k.awning(p, (.175, -3.36), 4.05, .5, 2.84, .3, (0, -1), ('bottle', 'stripe_cream'), .3)
    lw = b1 - a1 - .06
    box(p, '@oak', (c, -3.34, .66), (lw, .26, .03), .006, rot=(.3, 0, 0))
    for x in (a1 + .1, b1 - .1):
        p.solid(s.surface('oak'), [(x, -3.22, .64), (x, -3.22, .4), (x, -3.45, .64)], .03, (1, 0, 0))
    for i, kind in enumerate(('cabbage', 'carrot', 'potato')):
        x = c - lw / 3 + i * lw / 3
        with p.framed(Matrix.Translation((x, -3.34, .68)) @ Matrix.Rotation(.3, 4, 'X')):
            s.crate(p, (0, 0, 0), lw / 3 - .04, .22, .1, '@oak', 'wood_dark', 1)
            if kind == 'cabbage':
                for j in range(3):
                    g.cabbage(p, ((j - 1) * .14, 0, .04), .065)
            elif kind == 'carrot':
                g.carrot_bunch(p, (-.08, 0, .04), 4, .16, 0)
                g.carrot_bunch(p, (.1, 0, .04), 4, .16, .2)
            else:
                g.heap(p, 'potato', (0, 0, .07), lw / 3 - .12, .16, 1, .032)
    for x in (dx - .8, dx + .8):
        tube(p, 'iron', [(x, FACE + .01, 2.6), (x, FACE - .22, 2.6), (x, FACE - .24, 2.56)], .012, 5)
        for t in range(3):
            aa = t * math.tau / 3
            rod(p, 'iron/f', (x, FACE - .24, 2.55), (x + math.cos(aa) * .14, FACE - .24 + math.sin(aa) * .1, 2.25), .004, 3)
        lathe(p, 'wicker', [(.05, 0), (.14, .08), (.15, .12)], (x, FACE - .24, 2.15), 16, True, cap1=False)
        for j in range(7):
            aa = j * 2.4
            ball(p, ['flower_red', 'flower_white', 'flower_violet'][j % 3] + '/f', (x + math.cos(aa) * .09, FACE - .24 + math.sin(aa) * .07, 2.3), .03)
            ball(p, 'leaf/f', (x + math.cos(aa + 1) * .12, FACE - .24 + math.sin(aa + 1) * .09, 2.24), .035, (1, 1, .6))
        for j in range(3):
            tube(p, 'leaf_dark/f', [(x + (j - 1) * .08, FACE - .3, 2.2), (x + (j - 1) * .1, FACE - .32, 2.0), (x + (j - 1) * .09, FACE - .3, 1.85)],
                 .007, 3)
    lathe(p, 'zinc', [(.09, 0), (.12, .32), (.125, .33)], (dx + .8, FACE - .13, 0), 14, True, cap1=False)
    g.flower_bunch(p, (dx + .8, FACE - .13, .2), .6, 'flower_yellow', 7, .08)


# ------------------------------------------------------------------------------------------------- Finch & Thread
def _velvet_back(p, a, b, colour):
    for side in (0, 1):
        x0 = a + .03 if side == 0 else (a + b) / 2 + .05
        x1 = (a + b) / 2 - .05 if side == 0 else b - .03
        sheet(p, colour, lambda u, v, x0=x0, x1=x1: (x0 + u * (x1 - x0), BACK - .06 - .03 * math.sin(u * math.pi * 7) * (1 - .3 * v),
                                                       CEIL - .02 - v * (CEIL - FLOOR - .02)), 28, 8, .01)
    box(p, 'gold', ((a + b) / 2, BACK - .12, CEIL - .05), (b - a - .04, .04, .06), .006)


def tailor(p, spans, dx):
    (a1, b1), (a2, b2) = spans
    for (a, b), col in zip(spans, ('velvet_teal', 'velvet_wine')):
        display_box(p, a, b, 'navy_dark', '@oak_dark', None)
        _velvet_back(p, a, b, col)
        glaze(p, a, b)
    # Left (narrow) window: a gentleman's form in a navy tailcoat with a silk square, a top hat on a stand.
    c = (a1 + b1) / 2
    lathe(p, 'gold', [(0, 0), (.22, 0), (.22, .06), (0, .06)], (c - .1, -2.75, FLOOR), 24, True)
    with p.placed((c - .1, -2.75, FLOOR + .06), 0):
        rod(p, '@oak_dark', (0, 0, 0), (0, 0, .7), .025, 8)
        prof = [(.15, 0), (.18, .1), (.15, .3), (.17, .42), (.19, .52), (.19, .57), (.1, .64), (.05, .7)]
        lathe(p, 'cloth_navy', [(r, z) for r, z in prof], (0, 0, .7), 20, True, squash=(1.2, .85))
        for side in (-1, 1):
            p.solid('cloth_navy', [(side * .03, -.16, 1.26), (side * .13, -.15, 1.12), (side * .04, -.17, .95)], .012, (0, -1, 0))
            tube(p, 'cloth_navy', [(side * .23, 0, 1.22), (side * .26, -.03, .95), (side * .25, -.04, .78)], .05, 8)
            sheet(p, 'cloth_navy', lambda u, v, side=side: (side * (.05 + .13 * u), .02 + .1 * v, .72 - v * .3), 2, 3, .01)
        p.solid('cloth_ivory', [(-.03, -.165, 1.36), (.03, -.165, 1.36), (0, -.17, 1.18)], .01, (0, -1, 0))
        box(p, 'cloth_wine', (.12, -.16, 1.17), (.05, .02, .035), .004, rot=(0, .2, 0))
        ball(p, 'form_dark', (0, 0, 1.45), .04)
    rod(p, '@oak_dark', (c + .28, -2.95, FLOOR), (c + .28, -2.95, FLOOR + .95), .015, 6)
    lathe(p, '@oak_dark', [(.1, 0), (.08, .02), (0, .03)], (c + .28, -2.95, FLOOR), 12, True)
    lathe(p, 'cloth_black', [(0, 0), (.13, 0), (.13, .008), (.085, .01), (.085, .17), (.09, .2), (0, .2)], (c + .28, -2.95, FLOOR + .95), 16, True)
    lathe(p, 'cloth_wine', [(.087, .02), (.087, .05)], (c + .28, -2.95, FLOOR + .95), 16, True, cap0=False, cap1=False)
    # Right (wide) window: the gown on its form, a fan of bolts, gloves and a card.
    c2 = (a2 + b2) / 2
    lathe(p, 'gold', [(0, 0), (.3, 0), (.3, .06), (0, .06)], (c2 + .1, -2.72, FLOOR), 28, True)
    with p.placed((c2 + .1, -2.72, FLOOR + .06), 0):
        rod(p, '@oak_dark', (0, 0, 0), (0, 0, .3), .025, 8)
        lathe(p, 'velvet_wine', [(.15, 0), (.14, .1), (.16, .22), (.17, .3), (.11, .36)], (0, 0, .95), 20, True, squash=(1.1, .8))
        sheet(p, 'velvet_wine', lambda u, v: (math.cos(u * math.tau) * (.16 + .26 * v ** 1.4) * (1 + .05 * math.sin(u * math.tau * 9)),
                                              math.sin(u * math.tau) * (.13 + .22 * v ** 1.4) * (1 + .05 * math.sin(u * math.tau * 9)),
                                              .97 - v * .95), 32, 7, .012)
        torus(p, 'cloth_blush', (0, 0, .96), .16, .025, seg=20, n=5)
        ball(p, 'cloth_blush', (.11, -.11, .94), .04)
        lathe(p, 'form', [(.05, 1.3), (.04, 1.38), (0, 1.4)], (0, 0, 0), 10, True)
        ball(p, 'gold', (0, -.12, 1.2), .022)
    for i in range(5):
        a = -.9 + i * .3
        with p.framed(Matrix.Translation((c2 - .55, -2.75, FLOOR + .02)) @ Matrix.Rotation(a, 4, 'Z') @ Matrix.Rotation(-.5, 4, 'Y')):
            box(p, ['cloth_navy', 'cloth_rose', 'cloth_mustard', 'cloth_forest', 'cloth_sky'][i], (.18, 0, 0), (.38, .14, .05), .02)
    box(p, 'cloth_ivory', (c2 - .3, -3.02, FLOOR + .03), (.16, .08, .02), .01, rot=(0, 0, .3))
    box(p, 'cloth_ivory', (c2 - .2, -3.04, FLOOR + .03), (.16, .08, .02), .01, rot=(0, 0, -.2))
    box(p, 'card', (c2 + .5, -3.0, FLOOR + .1), (.22, .015, .16), .004, rot=(-.3, 0, 0))
    m = k.facing_text(c2 + .5, -3.01, FLOOR + .11, (0, -1)) @ Matrix.Rotation(-.3, 4, 'X')
    text(p, 'ink', 'BESPOKE', m, .035, 'cinzel')
    # Gilt script on the glass.
    s.arched_text(p, 'gold_leaf', 'TAILORING', (c, -3.207, 2.3), .8, .085, .8)
    s.arched_text(p, 'gold_leaf', 'BESPOKE & ALTERATIONS', (c2, -3.207, 2.28), 1.6, .075, 1.0)
    # Street: a fixed navy valance with gilt fringe, topiary in navy tubs by the door, and a bracket sign with shears.
    X = 2.5
    vx0, vx1 = -X + .45, X - .1
    box(p, '#navy', ((vx0 + vx1) / 2, -3.38, 2.72), (vx1 - vx0, .34, .04), .01, rot=(-.25, 0, 0))
    for i in range(int((vx1 - vx0) / .2)):
        x = vx0 + .1 + i * .2
        lathe(p, '#navy', [(0, 0), (.1, 0), (.1, .025), (0, .025)], (x, -3.53, 2.66), 14, True, axis=Matrix.Rotation(math.pi / 2, 3, 'X'))
        ball(p, 'gold/f', (x, -3.56, 2.55), .02, (1, 1, 1.5))
    box(p, 'gold_leaf', ((vx0 + vx1) / 2, -3.555, 2.7), (vx1 - vx0, .01, .02), 0)
    for x in (vx0, vx1):
        tube(p, 'brass', [(x, FACE, 2.4), (x, -3.5, 2.66)], .01, 5)
    for x in (dx - .82, dx + .82):
        lathe(p, '#navy', [(.11, 0), (.13, .3), (.14, .32)], (x, FACE - .14, 0), 16, True, cap1=False)
        torus(p, 'gold', (x, FACE - .14, .28), .135, .008, seg=16, n=4)
        rod(p, 'wood_dark', (x, FACE - .14, .3), (x, FACE - .14, .75), .015, 6)
        ball(p, 'leaf_dark', (x, FACE - .14, .9), .13)
        ball(p, 'leaf', (x + .04, FACE - .18, .95), .09)

    def emblem(p, x, y, z, face):
        for a in (.35, -.35):
            with p.framed(Matrix.Translation((x + face * .008, y, z)) @ Matrix.Rotation(a, 4, 'X')):
                box(p, 'gold_leaf', (0, -.04, .02), (.01, .26, .035), .004)
                torus(p, 'gold_leaf', (0, .13, .02), .04, .008, normal=(1, 0, 0), seg=12, n=4)
    bracket_sign(p, 2.3, 3.95, 'navy', emblem, 'TAILOR')


DRESS = {'haverlund-bakery': bakery, 'haverlund-greengrocer': pantry, 'haverlund-tailor': tailor}


def revise(asset):
    catalog = json.loads((ROOT / 'pipeline/world-catalog.json').read_text())
    source = ROOT / 'art/source/world' / asset / 'v2/model.blend'
    out = ROOT / 'art/source/world' / asset / 'v3/model.blend'
    if out.exists():
        note = out.with_name('storefront.json')
        recorded = json.loads(note.read_text()).get('source_sha256') if note.exists() else None
        if '--redo' not in sys.argv or recorded != hashlib.sha256(out.read_bytes()).hexdigest():
            raise RuntimeError('v3 exists and is not this record\'s untouched output: ' + asset)
    derived = hashlib.sha256(source.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if not bpy.context.scene.get('square_renewal'):
        raise RuntimeError('Expected the square-renewal storefront master: ' + asset)
    label, X, dx, colour, dark = SHOPS[asset]
    spans = windows(X, dx)
    removed = clear_old_wares(spans)
    recolour('shop_joinery', colour)
    root = next(o for o in bpy.data.objects if o.type == 'EMPTY' and o.parent is None)
    s.SURFACES.setdefault('green_boards', (lambda: s._reduced('green-boards-256', s.NATIVE / 'timber_panels.png', 256, '6f9f80'), .7, 1.2))
    p = s.attach(20261112)
    DRESS[asset](p, spans, dx)
    p.finish(root)
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and obj.name.startswith('shops_') and any(w in obj.name for w in s.NO_OUTLINE):
            obj['illustrated_edges'] = False
    bpy.context.scene['storefront_2026_11_12'] = True
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(out))
    out.with_name('storefront.json').write_text(json.dumps({
        'record': str(Path(__file__).resolve().relative_to(ROOT)), 'kit': 'art/source/world/shop-interiors/v2/interior_kit.py',
        'derived_from': f'art/source/world/{asset}/v2/model.blend', 'derived_from_sha256': derived,
        'removed_faces': removed, 'joinery': s.PALETTE[colour], 'windows': [list(map(lambda v: round(v, 3), w)) for w in spans],
        'source_sha256': hashlib.sha256(out.read_bytes()).hexdigest()}, indent=2) + '\n')
    print('REVISED', asset, removed, flush=True)


if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    for asset in [a for a in argv if not a.startswith('--')] or list(SHOPS):
        revise(asset)
