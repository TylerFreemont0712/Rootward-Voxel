"""Guarded one-time authoring of the shops on Rootward Square, built from one shop-house recipe in the seaside house
kit's language: a stone ground storey with painted shopfront joinery (pilasters, a gold-lettered fascia under a
cornice, a panelled stall riser, a display window showing the lit shop, a glazed door with a transom), a striped
awning, a hanging sign on an iron bracket, the shop's wares set out in front, and limewashed upper floors with
shuttered windows under a clay roof. Each shop is its own model: footprint centre at ground, front toward -Y.

    haverlund-bakery        Morning Loaf: three storeys under a street gable; bread on a table, a chalkboard
    haverlund-greengrocer   the greengrocer: two storeys and a dormer under eaves; tiered crates and an orange pyramid
    haverlund-bookshop      Finch & Sons: three storeys under a street gable; a penny tray of books, a bench
    haverlund-cafe          the Harbour Cup: a wide café of two storeys under a hipped roof; menu board, planters

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_shops.py [-- ids]
    ... -- --draft .cache/square-hub/drafts [ids]
"""
import math
import sys
from pathlib import Path

from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import house_kit as kit  # noqa: E402
import author_buildings as hall  # noqa: E402  (fruit crates and market stalls)

RECORD = 'art/source/world/square-hub/v1/author_shops.py'
SHOP_GLASS = HERE.parents[1] / 'sparks-lane/v1/lane-glass-shop.png'


def shopfront(p, X, Y, G, *, name, kind, door_side=1, awning=('canvas_green', 'canvas'), sign=None, frame='shutter'):
    """The ground storey's front: a stone wall with one wide opening filled by painted joinery."""
    rng = p.rng
    x0, x1 = -X + .38, X - .38
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .3, [(x0 + X, x1 + X, 0, G - .45)])
    top = G - .45
    # Pilasters with plinths and capitals at either end of the opening.
    for x in (x0 + .11, x1 - .11):
        p.box(frame, (x, -Y - .04, top / 2), (.22, .14, top), bevel=.015, uv='local')
        p.box(frame, (x, -Y - .07, .15), (.3, .2, .3), bevel=.015, uv='local')
        p.box(frame, (x, -Y - .08, top - .05), (.3, .22, .1), bevel=.015, uv='local')
    # The fascia with its lettering, the cornice over it.
    p.box(frame, (0, -Y - .06, top + .22), (2 * X - .5, .12, .44), bevel=.015, uv='local')
    p.box('gold_leaf', (0, -Y - .123, top + .22), (2 * X - .9, .006, .32), bevel=0, uv='flat')
    p.box(frame, (0, -Y - .128, top + .22), (2 * X - .98, .006, .26), bevel=0, uv='flat')
    kit.text(p, 'gold_leaf', name, kit.facing_text(0, -Y - .133, top + .21, (0, -1)), min(.2, (2 * X - 1.4) / max(len(name), 1) * 1.45))
    p.box('timber', (0, -Y - .12, top + .48), (2 * X - .3, .26, .09), bevel=.02, uv='local')
    p.box('timber', (0, -Y - .08, top + .54), (2 * X - .4, .18, .05), bevel=.01, uv='local')
    # The door on one side, the display window beside it.
    dw, dh = .95, top - .4
    dx = door_side * (x1 - .22 - dw / 2)
    wx0, wx1 = (x0 + .22, dx - dw / 2 - .1) if door_side > 0 else (dx + dw / 2 + .1, x1 - .22)
    wc, ww = (wx0 + wx1) / 2, wx1 - wx0
    p.box(frame, (wc, -Y + .02, .3), (ww + .06, .14, .6), bevel=.015, uv='local')
    for k in range(max(1, round(ww / .7))):
        n = max(1, round(ww / .7))
        p.box(frame, (wx0 + ww * (k + .5) / n, -Y - .06, .3), (ww / n - .12, .02, .38), bevel=.02, uv='local')
    p.pane('shop_glass', (wc, -Y + .08, .6 + (top - .7) / 2), ww, top - .7, (0, -1))
    for k in range(1, max(2, round(ww / .55))):
        n = max(2, round(ww / .55))
        p.box('sash', (wx0 + ww * k / n, -Y + .03, .6 + (top - .7) / 2), (.04, .05, top - .7), bevel=0, uv='flat')
    p.box('sash', (wc, -Y + .03, top - .55), (ww, .05, .04), bevel=0, uv='flat')
    p.box(frame, (wc, -Y - .02, .63), (ww + .1, .2, .06), bevel=.01, uv='local')
    # The door: a glazed upper half over a panel, a transom light, brass, a step and a boot scraper.
    p.box(frame, (dx, -Y + .06, dh / 2), (dw, .06, dh), bevel=.01, uv='local')
    p.pane('shop_glass', (dx, -Y + .02, dh * .68), dw - .3, dh * .5, (0, -1))
    p.box(frame, (dx, -Y + .02, dh * .22), (dw - .3, .03, dh * .3), bevel=.02, uv='local')
    p.sphere('brass', (dx - door_side * .32, -Y - .01, dh * .48), .035, 1)
    p.box('brass', (dx, -Y + .015, dh * .35), (.3, .01, .05), bevel=0, uv='flat')
    p.pane('shop_glass', (dx, -Y + .06, (dh + top) / 2), dw - .06, top - dh - .1, (0, -1))
    p.box('stone', (dx, -Y - .2, .05), (dw + .3, .4, .1), bevel=.02, uv=('blocks', 0))
    p.box('iron', (dx + door_side * .65, -Y - .2, .08), (.2, .04, .14), bevel=0, uv='flat')
    if awning:
        kit.awning(p, (wc, -Y - .05, top - .02), ww + .3, 1.0, top - .02, .5, (0, -1), awning)
    if sign:
        hanging_sign(p, (X - .3 if door_side < 0 else -X + .3), -Y, G + .9, sign)


def hanging_sign(p, x, wall_y, z, kind):
    """An iron bracket from the front wall with a carved sign hanging from it, side-on to the street."""
    p.box('iron', (x, wall_y - .03, z), (.12, .06, .4), bevel=.005, uv='flat')
    p.cylinder('iron', (x, wall_y - .02, z + .18), (x, wall_y - .95, z + .18), .022, 8, uv='flat')
    p.cylinder('iron', (x, wall_y - .02, z - .15), (x, wall_y - .55, z + .15), .016, 6, uv='flat')
    p.sphere('iron', (x, wall_y - .97, z + .18), .03, 1)
    c = Vector((x, wall_y - .6, z - .25))
    for dy in (-.25, .25):
        p.cylinder('iron', (x, c.y + dy, z + .18), (x, c.y + dy, c.z + .25), .006, 4, uv='flat')
    if kind == 'loaf':
        p.sphere('bread', tuple(c), .32, 2, (.3, 1.0, .55))
        for k in range(3):
            p.box('bread_dark', (x, c.y - .15 + k * .15, c.z + .13), (.2, .03, .04), (math.radians(30), 0, 0), 0, 'flat')
    elif kind == 'pear':
        p.box('shutter', tuple(c), (.05, .6, .5), bevel=.02, uv='local')
        for side in (-1, 1):
            p.sphere('olive', (x + side * .04, c.y, c.z - .05), .14, 1, (.4, 1, 1))
            p.sphere('olive', (x + side * .04, c.y, c.z + .1), .09, 1, (.4, 1, 1))
            p.box('bark', (x + side * .04, c.y, c.z + .2), (.01, .02, .06), bevel=0, uv='flat')
    elif kind == 'book':
        p.box('enamel_red', tuple(c), (.12, .55, .4), bevel=.01, uv='flat')
        p.box('linen', tuple(c + Vector((0, .02, 0))), (.13, .5, .36), bevel=0, uv='flat')
        for side in (-1, 1):
            p.box('gold_leaf', (x + side * .066, c.y, c.z), (.004, .3, .04), bevel=0, uv='flat')
    elif kind == 'cup':
        p.box('canvas', tuple(c), (.05, .6, .5), bevel=.02, uv='flat')
        for side in (-1, 1):
            p.cylinder('canvas_green', (x + side * .03, c.y, c.z - .12), (x + side * .03, c.y, c.z + .08), .1, 10, .13, uv='flat')
            p.cylinder('canvas_green', (x + side * .03, c.y + .14, c.z - .02), (x + side * .03, c.y + .18, c.z - .02), .05, 8, uv='flat')


def upper(p, X, Y, z0, z1, *, windows, shutters='open', plaster='plaster', flowers=None, side_windows=True, back=True):
    zc = (z0 + z1) / 2 + .1
    w, h = .85, min(1.35, z1 - z0 - .9)
    kit.wall(p, plaster, (-X, -Y), (X, -Y), z0, z1, .24, [(x - w / 2 + X, x + w / 2 + X, zc - h / 2, zc + h / 2) for x in windows])
    kit.wall(p, plaster, (X, Y), (-X, Y), z0, z1, .24, [(X - x - w / 2, X - x + w / 2, zc - h / 2, zc + h / 2) for x in windows] if back else [])
    kit.wall(p, plaster, (X, -Y), (X, Y), z0, z1, .24, [(Y - .5, Y + .5, zc - .5, zc + .5)] if side_windows else [])
    kit.wall(p, plaster, (-X, Y), (-X, -Y), z0, z1, .24, [(Y - .5, Y + .5, zc - .5, zc + .5)] if side_windows else [])
    for x in windows:
        kit.window(p, (x, -Y, zc), w, h, (0, -1), shutters=shutters, flowers=flowers)
        if back:
            kit.window(p, (x, Y, zc), w, h, (0, 1), shutters='open', box=False)
    if side_windows:
        for side in (-1, 1):
            kit.window(p, (side * X, 0, zc), .7, 1.0, (side, 0), shutters=None, box=False, bars=(1, 1))


def ground_back(p, X, Y, G):
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, G, .3, [])
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, G, .3, [(X - .5, X + .5, 0, 2.2)])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, G, .3, [])
    kit.door(p, 0, Y, .9, 2.2, (0, 1), style='plank', step=False)
    for a, b, f in hall.fronts(X, Y):
        kit.band(p, 'stone', a, b, 0, .36, .05, f)
        kit.band(p, 'stone', a, b, G - .12, .2, .07, f)
    for corner, faces in hall.corners(X, Y):
        kit.quoins(p, corner, faces, .36, G - .12, course=.32, long=.46, short=.28, proud=.03)


def street_gable(p, X, Y, E, pitch=50, chimney_x=-.6):
    with p.turned(-90):
        ridge, z_eave, eave = kit.gable_roof(p, -Y, Y, -X, X, E, pitch, eave=.3, verge=.08)
        t = math.tan(math.radians(pitch))
        # Turned frame: its x runs toward the back (-x is the front), its y is the final x.
        kit.chimney(p, -(Y - 1.2), chimney_x, ridge - 2.0, ridge + .8, width=.6, depth=.5, style='brick', collar=ridge - abs(chimney_x) * t - .1)
    for y, out in ((-Y, -1), (Y, 1)):
        kit.gable(p, 'plaster', 'y', y, -X, X, E, ridge - .1, out, .22)
    kit.window(p, (0, -Y, E + 1.0), .55, .7, (0, -1), recess=-.04, shutters='open', bars=(1, 1), flowers=('flower_red', 'flower_white'))
    return ridge, z_eave, eave


# --- the four shops ----------------------------------------------------------------------------------------------------
BAKERY_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                  'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_sage'}


def bakery(p):
    X, Y, G = 2.5, 3.2, 3.4
    E = G + 2.8 * 2
    shopfront(p, X, Y, G, name='MORNING LOAF', kind='bakery', door_side=1, awning=('canvas_green', 'canvas'), sign='loaf')
    ground_back(p, X, Y, G)
    for z0 in (G, G + 2.8):
        upper(p, X, Y, z0, z0 + 2.8, windows=(-1.0, 1.0), flowers=('flower_red', 'flower_white', 'flower_pink'))
        for a, b, f in hall.fronts(X, Y):
            kit.band(p, 'timber', a, b, z0 - .06, .2, .04, f)
    ridge, z_eave, eave = street_gable(p, X, Y, E)
    kit.downpipe(p, (X + .05, -Y - .25, E - .4), 0, (0, .2), swan=.2)
    with p.into('detail_wares'):
        tx, ty = -.85, -Y - .7
        p.box('timber', (tx, ty, .72), (1.2, .5, .05), bevel=.01, uv='local')
        for dx in (-.52, .52):
            p.box('timber', (tx + dx, ty, .36), (.05, .45, .72), bevel=0, uv='local')
        p.box('linen', (tx, ty, .75), (1.22, .52, .01), bevel=0, uv='flat')
        for k in range(3):
            kit.basket(p, (tx - .38 + k * .38, ty, .75), .16, .12, linen=False)
            for j in range(3):
                p.sphere(('bread', 'bread_dark')[(k + j) % 2], (tx - .38 + k * .38 + (j - 1) * .07, ty + (j - 1) * .04, .9), .08, 1, (1.4, .8, .7))
        for j in range(4):
            p.sphere('bread', (tx - .45 + j * .3, ty + .18, .8), .06, 1, (2.2, .7, .6))
        p.box('timber', (1.5, -Y - .55, .5), (.55, .04, .85), (math.radians(-10), 0, 0), .01, 'local')
        p.box('ink', (1.5, -Y - .58, .55), (.47, .01, .7), (math.radians(-10), 0, 0), 0, 'flat')
        for z, words, size in ((.75, 'SECOND', .07), (.66, 'BATCH', .07), (.55, 'AT ELEVEN', .06)):
            kit.text(p, 'canvas', words, kit.facing_text(1.5, -Y - .6, z, (0, -1)), size)
    with p.into('detail_planters'):
        kit.pot(p, (X - .25, -Y - .35, 0), .7, 'cone')


GROCER_PALETTE = {'plaster': 'seaside_plaster_ochre', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                  'stone': 'seaside_stone_honey', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def greengrocer(p):
    X, Y, G = 2.3, 3.2, 3.4
    E = G + 2.8
    shopfront(p, X, Y, G, name='GREENGROCER', kind='grocer', door_side=-1, awning=('enamel_red', 'canvas'), sign='pear')
    ground_back(p, X, Y, G)
    upper(p, X, Y, G, E, windows=(-.95, .95), shutters='open', flowers=('flower_white', 'flower_yellow', 'flower_red'), side_windows=False)
    for a, b, f in hall.fronts(X, Y):
        kit.band(p, 'stone', a, b, G - .06, .2, .05, f)
    ridge, z_eave, eave = kit.gable_roof(p, -X, X, -Y, Y, E, 44, eave=.35, verge=.05)
    for x, out in ((-X, -1), (X, 1)):
        kit.gable(p, 'plaster', 'x', x, -Y, Y, E, ridge - .1, out, .24)
    kit.dormer(p, 0, -Y - .35, z_eave, 44, -1, in_from_eave=.6, ridge_run=Y + .35, width=1.1, height=.9, window_w=.5, window_h=.6,
               flowers=('flower_red', 'flower_white'))
    kit.chimney(p, 1.4, .6, ridge - 1.8, ridge + .7, width=.55, depth=.5, style='brick', collar=ridge - .45)
    with p.into('detail_wares'):
        # Tiered crates on a stand under the awning; on the top tier a careful pyramid of oranges, one short.
        x0, x1 = -X + .3, X - 1.4
        for tier, (dy, dz, kinds) in enumerate(((-.75, .35, ('apple', 'pear', 'lemon')), (-.45, .6, ('orange', 'plum', 'apple')))):
            p.box('timber', ((x0 + x1) / 2, -Y + dy, dz - .03), (x1 - x0, .34, .05), bevel=.006, uv='local')
            for k, kind in enumerate(kinds):
                hall.fruit_crate(p, (x0 + (x1 - x0) * (k + .5) / 3, -Y + dy, dz), kind, ((x1 - x0) / 3 - .04, .3, .14), .2)
        for x in (x0 + .05, x1 - .05):
            p.box('timber', (x, -Y - .6, .3), (.05, .5, .6), bevel=0, uv='local')
        cx, cy, cz = x1 - .25, -Y - .45, .85
        n = 3
        for layer in range(n):
            size = n - layer
            for i in range(size):
                for j in range(size):
                    if layer == n - 1:
                        continue      # the top orange is the one that's missing
                    p.sphere('flower_orange', (cx + (i - (size - 1) / 2) * .085, cy + (j - (size - 1) / 2) * .085, cz + layer * .07), .045, 1)
        kit.basket(p, (X - .5, -Y - .55, 0), .2, .22, linen=False)
        for k in range(4):
            p.sphere('olive', (X - .5 + (k - 1.5) * .06, -Y - .55, .26), .045, 1)


BOOK_PALETTE = {'plaster': 'seaside_plaster_rose', 'roof': 'seaside_roof_slate', 'ridge': 'seaside_roof_slate',
                'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_dark', 'shutter': 'seaside_shutter_blue'}


def bookshop(p):
    X, Y, G = 2.5, 3.2, 3.4
    E = G + 2.7 * 2
    shopfront(p, X, Y, G, name='FINCH & SONS', kind='books', door_side=1, awning=None, sign='book', frame='shutter')
    ground_back(p, X, Y, G)
    for z0 in (G, G + 2.7):
        upper(p, X, Y, z0, z0 + 2.7, windows=(-1.0, 1.0), shutters='open', flowers=('flower_white', 'flower_violet'))
        for a, b, f in hall.fronts(X, Y):
            kit.band(p, 'stone', a, b, z0 - .06, .2, .05, f)
    street_gable(p, X, Y, E, 54, .6)
    with p.into('detail_wares'):
        # A trestle with a penny tray of books, a card propped on top; a bench under the window.
        tx, ty = -1.0, -Y - .65
        for dx in (-.45, .45):
            p.box('timber', (tx + dx, ty, .35), (.05, .4, .7), (0, math.radians(8 * (1 if dx > 0 else -1)), 0), 0, 'local')
        p.box('timber', (tx, ty, .72), (1.15, .5, .04), bevel=.006, uv='local')
        p.box('timber', (tx, ty, .78), (1.05, .42, .1), bevel=.006, uv='local')
        colours = ('enamel_red', 'canvas_green', 'cloth_blue', 'cloth_ochre', 'ink', 'linen', 'enamel_red_dark', 'cloth_rose')
        for k in range(14):
            p.box(colours[k % len(colours)], (tx - .45 + (k % 7) * .15, ty - .08 + (k // 7) * .16, .86), (.12, .15, .05 + .02 * (k % 3)), (0, 0, (k % 5 - 2) * .08), .004, 'flat')
        p.box('linen', (tx + .2, ty - .1, 1.0), (.25, .01, .18), (math.radians(-15), 0, 0), 0, 'flat')
        kit.text(p, 'ink', 'PENNY', kit.facing_text(tx + .2, ty - .107, 1.0, (0, -1)), .05)
    with p.into('detail_planters'):
        kit.pot(p, (X - .3, -Y - .35, 0), .75, 'flowers', ('flower_white', 'flower_violet'))


CAFE_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_teal', 'ridge': 'seaside_roof_terracotta',
                'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def cafe(p):
    """A wide café: two display windows either side of glazed double doors, a long striped awning, the menu board."""
    X, Y, G = 3.5, 3.0, 3.5
    E = G + 2.9
    top = G - .45
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .3, [(.38, 2 * X - .38, 0, top)])
    for x in (-X + .49, X - .49, -.75, .75):
        p.box('shutter', (x, -Y - .04, top / 2), (.22, .14, top), bevel=.015, uv='local')
        p.box('shutter', (x, -Y - .07, .15), (.3, .2, .3), bevel=.015, uv='local')
    p.box('shutter', (0, -Y - .06, top + .22), (2 * X - .5, .12, .44), bevel=.015, uv='local')
    p.box('gold_leaf', (0, -Y - .123, top + .22), (2 * X - .9, .006, .32), bevel=0, uv='flat')
    p.box('shutter', (0, -Y - .128, top + .22), (2 * X - .98, .006, .26), bevel=0, uv='flat')
    kit.text(p, 'gold_leaf', 'THE HARBOUR CUP', kit.facing_text(0, -Y - .133, top + .21, (0, -1)), .2)
    p.box('timber', (0, -Y - .12, top + .48), (2 * X - .3, .26, .09), bevel=.02, uv='local')
    for side in (-1, 1):
        x0, x1 = (-X + .6, -.86) if side < 0 else (.86, X - .6)
        wc, ww = (x0 + x1) / 2, x1 - x0
        p.box('shutter', (wc, -Y + .02, .3), (ww + .06, .14, .6), bevel=.015, uv='local')
        p.pane('shop_glass', (wc, -Y + .08, .6 + (top - .7) / 2), ww, top - .7, (0, -1))
        for k in range(1, 4):
            p.box('sash', (x0 + ww * k / 4, -Y + .03, .6 + (top - .7) / 2), (.04, .05, top - .7), bevel=0, uv='flat')
        p.box('sash', (wc, -Y + .03, top - .55), (ww, .05, .04), bevel=0, uv='flat')
        p.box('shutter', (wc, -Y - .02, .63), (ww + .1, .2, .06), bevel=.01, uv='local')
        p.box('shutter', (side * .32, -Y + .06, (top - .4) / 2), (.6, .06, top - .4), bevel=.01, uv='local')
        p.pane('shop_glass', (side * .32, -Y + .02, (top - .4) * .62), .44, (top - .4) * .62, (0, -1))
        p.cylinder('brass', (side * .06, -Y - .02, 1.1), (side * .06, -Y - .02, 1.4), .015, 6, uv='flat')
    p.pane('shop_glass', (0, -Y + .06, (top - .4 + top) / 2), 1.4, .32, (0, -1))
    p.box('stone', (0, -Y - .2, .05), (1.9, .4, .1), bevel=.02, uv=('blocks', 0))
    kit.awning(p, (0, -Y - .05, top - .02), 2 * X - .6, 1.3, top - .02, .55, (0, -1), ('canvas_green', 'canvas'))
    hanging_sign(p, X - .3, -Y, G + .9, 'cup')
    ground_back(p, X, Y, G)
    upper(p, X, Y, G, E, windows=(-2.1, 0, 2.1), shutters='open', flowers=('flower_red', 'flower_white', 'flower_orange'))
    for a, b, f in hall.fronts(X, Y):
        kit.band(p, 'stone', a, b, G - .06, .2, .05, f)
    top_z, ends, z_eave = kit.hip_roof(p, -X - .1, X + .1, -Y - .1, Y + .1, E, 32, eave=.4)
    kit.dormer(p, 0, -Y - .1 - .4, z_eave, 32, -1, in_from_eave=.5, ridge_run=Y + .5, width=1.0, height=.8, window_w=.45, window_h=.5,
               shutters=None, box=False)
    kit.chimney(p, -2.3, 1.0, top_z - 1.5, top_z + .8, width=.6, depth=.5, style='brick', collar=top_z - .5)
    with p.into('detail_wares'):
        bx, by = -X - .1 + .5, -Y - .6
        p.box('timber', (bx, by, .55), (.6, .05, .9), (math.radians(-10), 0, 0), .01, 'local')
        p.box('ink', (bx, by - .03, .6), (.52, .01, .74), (math.radians(-10), 0, 0), 0, 'flat')
        for z, words, size in ((.85, 'TODAY', .07), (.74, 'TEA  2d', .055), (.64, 'COFFEE  3d', .055), (.54, 'BUNS  1d', .055)):
            kit.text(p, 'canvas', words, kit.facing_text(bx, by - .045, z, (0, -1)), size)
    with p.into('detail_planters'):
        for x in (-X + .2, X - .2):
            p.box('timber', (x, -Y - .35, .25), (.45, .45, .5), bevel=.015, uv='local')
            kit.pot(p, (x, -Y - .35, .5), .6, 'cone')


SHOPS = {
    'haverlund-bakery': (bakery, BAKERY_PALETTE, 7201),
    'haverlund-greengrocer': (greengrocer, GROCER_PALETTE, 7202),
    'haverlund-bookshop': (bookshop, BOOK_PALETTE, 7203),
    'haverlund-cafe': (cafe, CAFE_PALETTE, 7204),
}

if __name__ == '__main__':
    chosen, out = kit.selected(list(SHOPS))
    for asset in chosen:
        make, palette, seed = SHOPS[asset]
        root = kit.begin(asset, palette)
        kit.material('shop_glass', 'ffffff', SHOP_GLASS, .35, emission=.15)
        kit.material('bread', 'cd8f4a', roughness=.8)
        kit.material('bread_dark', 'a76a34', roughness=.8)
        parts = kit.Parts(seed)
        make(parts)
        parts.finish(root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, RECORD, palette, {'reference': 'docs/concept/v0.72/art/guildhall-square.png'})
