"""Guarded one-time authoring of the three new buildings on Rootward Square: the post office, the fruit market hall
and Haverlund Savings, the bank. Each is its own model with a ground pivot at its footprint centre and its front
toward Blender -Y, built from the seaside house kit so they share the town's stone, tiles, timber and paint.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_buildings.py [-- ids]
    ... -- --draft .cache/square-hub/drafts [ids]

After authoring, each model.blend is the editable authority; export only with scripts/world-art.sh build <id>.
"""
import math
import sys
from pathlib import Path

from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import house_kit as kit  # noqa: E402

RECORD = 'art/source/world/square-hub/v1/author_buildings.py'
REF = 'docs/concept/v0.72/art/guildhall-square.png'
VERDIGRIS = ROOT / 'art/source/world/rootwell/v1/verdigris.png'


def fronts(X, Y):
    return (((-X, -Y), (X, -Y), (0, -1)), ((X, -Y), (X, Y), (1, 0)), ((X, Y), (-X, Y), (0, 1)), ((-X, Y), (-X, -Y), (-1, 0)))


def corners(X, Y):
    return (((-X, -Y), ((0, -1), (-1, 0))), ((X, -Y), ((0, -1), (1, 0))), ((X, Y), ((0, 1), (1, 0))), ((-X, Y), ((0, 1), (-1, 0))))


# --- the post office ------------------------------------------------------------------------------------------------
POST_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_dark', 'shutter': 'seaside_shutter_teal'}


def post_office(p):
    """Two storeys and an attic: a limestone ground floor with a central double door under a fanlight, a counter
    window either side under red-and-cream awnings and the gold POST OFFICE fascia, a red enamel envelope sign on a
    bracket; cream limewash above with three shuttered windows and a balcony; a hipped clay roof with a dormer, two
    chimneys and a gilded envelope weathervane. A parcel bench and a letter slot outside."""
    X, Y = 4.5, 3.4
    G, E = 3.3, 6.4
    rng = p.rng
    door_w, door_h = 1.3, 2.55
    win_w, win_h, win_z = 1.55, 1.75, 1.6
    front = [(-door_w / 2 + X, door_w / 2 + X, 0, door_h)] + [(x - win_w / 2 + X, x + win_w / 2 + X, win_z - win_h / 2, win_z + win_h / 2) for x in (-2.75, 2.75)]
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .3, front)
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, G, .3, [(1.2 + Y - .45, 1.2 + Y + .45, 1.0, 2.3)])
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, G, .3, [(X - 1.5 - .45, X - 1.5 + .45, 0, 2.2)])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, G, .3, [(Y - 1.2 - .45, Y - 1.2 + .45, 1.0, 2.3)])
    uw, uh, uz = 1.0, 1.5, G + .55 + .75
    kit.wall(p, 'plaster', (-X, -Y), (X, -Y), G, E, .26, [(x - uw / 2 + X, x + uw / 2 + X, uz - uh / 2, uz + uh / 2) for x in (-2.75, 0, 2.75)])
    kit.wall(p, 'plaster', (X, -Y), (X, Y), G, E, .26, [(Y - .45, Y + .45, uz - .7, uz + .7)])
    kit.wall(p, 'plaster', (X, Y), (-X, Y), G, E, .26, [(X - x - uw / 2, X - x + uw / 2, uz - uh / 2, uz + uh / 2) for x in (-2.0, 2.0)])
    kit.wall(p, 'plaster', (-X, Y), (-X, -Y), G, E, .26, [(Y - .45, Y + .45, uz - .7, uz + .7)])
    for a, b, f in fronts(X, Y):
        kit.band(p, 'stone', a, b, 0, .42, .06, f)
        kit.band(p, 'stone', a, b, G - .12, .24, .08, f)
        kit.band(p, 'stone', a, b, E - .18, .18, .1, f)
    for corner, faces in corners(X, Y):
        kit.quoins(p, corner, faces, G + .12, E - .18, course=.34, long=.5, short=.3, proud=.035)
    # The door: a panelled pair in red, a fanlight, brass handles and a letter slot; a moulded stone hood.
    for side in (-1, 1):
        leaf = door_w / 2
        x = side * leaf / 2
        p.box('enamel_red', (x, -Y + .1, (door_h - .48) / 2), (leaf - .03, .06, door_h - .5), bevel=.01, uv='flat')
        for z0, z1 in ((.18, .9), (1.05, door_h - .62)):
            p.box('enamel_red_dark', (x, -Y + .065, (z0 + z1) / 2), (leaf - .2, .02, z1 - z0), bevel=.01, uv='flat')
        p.sphere('brass', (x - side * (leaf / 2 - .1), -Y + .05, 1.0), .035, 1)
    p.box('brass', (-door_w / 4, -Y + .055, .98 + .25), (.26, .01, .05), bevel=.003, uv='flat')
    kit.text(p, 'ink', 'LETTERS', kit.facing_text(-door_w / 4, -Y + .048, 1.31, (0, -1)), .035)
    p.pane('window_pane', (0, -Y + .12, door_h - .25), door_w - .1, .42, (0, -1))
    for k in range(4):
        p.box('sash', (-door_w / 2 + .05 + (door_w - .1) * k / 3, -Y + .09, door_h - .25), (.035, .04, .42), bevel=0, uv='flat')
    p.box('sash', (0, -Y + .09, door_h - .48), (door_w - .06, .05, .05), bevel=0, uv='flat')
    kit.surround(p, (0, -Y, door_h / 2), door_w, door_h, (0, -1), sill=False, keystone=True)
    p.box('stone', (0, -Y - .18, .04), (door_w + .5, .4, .08), bevel=.02, uv=('blocks', 0))
    # Counter windows under striped awnings, the gold-lettered fascia between them.
    for x in (-2.75, 2.75):
        kit.window(p, (x, -Y, win_z), win_w, win_h, (0, -1), shutters=None, box=False, bars=(2, 1), recess=.14, stone=False)
        p.box('enamel_red_dark', (x, -Y - .05, .45), (win_w + .2, .1, .3), bevel=.015, uv='flat')
        kit.awning(p, (x, -Y - .02, 2.6), win_w + .4, .85, 2.6, .4, (0, -1), ('enamel_red', 'canvas'))
    p.box('enamel_red_dark', (0, -Y - .06, G - .38), (2 * X - .5, .08, .36), bevel=.012, uv='flat')
    p.box('gold_leaf', (0, -Y - .1, G - .38), (2 * X - .62, .01, .3), bevel=0, uv='flat')
    p.box('enamel_red', (0, -Y - .105, G - .38), (2 * X - .7, .01, .26), bevel=0, uv='flat')
    for x, words in ((-2.75, 'POST'), (2.75, 'OFFICE')):
        kit.text(p, 'gold_leaf', words, kit.facing_text(x, -Y - .112, G - .38, (0, -1)), .19)
    kit.text(p, 'gold_leaf', 'HAVERLUND', kit.facing_text(0, -Y - .112, G - .38, (0, -1)), .11)
    # The enamel envelope sign hanging from a scrolled iron bracket off the front wall, seen edge-on from the street.
    sx, sz = X - .45, 2.6
    p.box('iron', (sx, -Y - .03, sz + .32), (.14, .06, .55), bevel=.005, uv='flat')
    p.cylinder('iron', (sx, -Y - .02, sz + .58), (sx, -Y - 1.0, sz + .58), .025, 8, uv='flat')
    p.cylinder('iron', (sx, -Y - .02, sz + .1), (sx, -Y - .55, sz + .55), .018, 6, uv='flat')
    p.sphere('iron', (sx, -Y - 1.02, sz + .58), .035, 1)
    for dy in (-.3, -.86):
        p.cylinder('iron', (sx, -Y + dy, sz + .58), (sx, -Y + dy, sz + .42), .008, 4, uv='flat')
    c = Vector((sx, -Y - .58, sz))
    p.box('enamel_red', tuple(c), (.05, .78, .78), bevel=.03, uv='flat')
    p.box('gold_leaf', tuple(c), (.058, .7, .7), bevel=0, uv='flat')
    p.box('enamel_red', tuple(c), (.064, .64, .64), bevel=0, uv='flat')
    for side in (-1, 1):
        face = c + Vector((side * .035, 0, 0))
        p.box('canvas', tuple(face), (.006, .44, .3), bevel=0, uv='flat')
        for s2 in (-1, 1):
            p.box('enamel_red', tuple(face + Vector((side * .003, s2 * .11, .06))), (.006, .28, .025), (s2 * .55, 0, 0), 0, 'flat')
    # The upper floor: shuttered windows with boxes, a balcony on stone brackets in the middle.
    for x in (-2.75, 2.75):
        kit.window(p, (x, -Y, uz), uw, uh, (0, -1), shutters='open', flowers=('flower_red', 'flower_white', 'flower_pink'))
    kit.window(p, (0, -Y, uz), uw, uh, (0, -1), shutters='open', box=False)
    bz = G + .46
    p.box('stone', (0, -Y - .38, bz), (1.9, .76, .12), bevel=.02, uv=('blocks', 0))
    for x in (-.75, .75):
        for k, (dd, hh) in enumerate(((.5, .12), (.32, .14), (.16, .14))):
            p.box('stone', (x, -Y - dd / 2, bz - .12 - k * .13), (.16, dd, hh), bevel=.015, uv=('blocks', 0))
    for k in range(17):
        x = -.88 + k * .11
        p.box('iron', (x, -Y - .72, bz + .48), (.016, .016, .84), bevel=0, uv='flat')
    for zz, ww in ((bz + .9, .045), (bz + .12, .03)):
        p.beam('iron', (-.92, -Y - .72, zz), (.92, -Y - .72, zz), ww, ww * .7, up=(0, 0, 1), uv='flat')
        for side in (-1, 1):
            p.beam('iron', (side * .92, -Y - .72, zz), (side * .92, -Y - .02, zz), ww, ww * .7, up=(0, 0, 1), uv='flat')
    for x in (-.55, .55):
        kit.pot(p, (x, -Y - .45, bz + .06), .7, 'flowers', ('flower_red', 'flower_white'))
    for x in (-1.5, 1.5):
        kit.window(p, (x, Y, uz), uw, uh, (0, 1), shutters='open', box=False)
    for side in (-1, 1):
        kit.window(p, (side * X, 1.2 if side > 0 else -1.2, 1.65), .9, 1.3, (side, 0), shutters=None, box=False)
        kit.window(p, (side * X, 0, uz), .9, 1.4, (side, 0), shutters='open', box=False)
    kit.door(p, -1.5, Y, .9, 2.2, (0, 1), style='plank', leaf_mat='shutter')
    # The hipped roof, a dormer to the square, two chimneys and the envelope weathervane.
    top, ends, z_eave = kit.hip_roof(p, -X - .15, X + .15, -Y - .15, Y + .15, E, 34, eave=.45)
    run = Y + .15 + .45
    kit.dormer(p, 0, -Y - .15 - .45, z_eave, 34, -1, in_from_eave=.55, ridge_run=run, width=1.1, height=.85,
               window_w=.5, window_h=.55, shutters=None, box=False)
    t34 = math.tan(math.radians(34))
    for x in (-2.9, 2.9):
        surface = z_eave + min(X + .6 - abs(x), Y + .6 - 1.0) * t34
        kit.chimney(p, x, 1.0, surface - .4, top + .9, width=.66, depth=.56, style='brick', collar=surface - .05)
    mast = (ends[0][0] + ends[1][0]) / 2
    p.cylinder('iron', (mast, 0, top), (mast, 0, top + 1.25), .025, 8, uv='flat')
    for k, (dx, dy) in enumerate(((1, 0), (0, 1), (-1, 0), (0, -1))):
        p.cylinder('iron', (mast, 0, top + .65), (mast + dx * .28, dy * .28, top + .65), .01, 4, uv='flat')
        kit.text(p, 'gold_leaf', 'ESWN'[k], Matrix.Translation((mast + dx * .36, dy * .36, top + .65)) @ Matrix.Rotation(math.pi / 2, 4, 'X'), .09)
    env = Vector((mast + .12, 0, top + 1.05))
    p.box('gold_leaf', tuple(env), (.42, .03, .26), bevel=.01, uv='flat')
    for s in (-1, 1):
        p.box('gold_leaf', tuple(env + Vector((s * .1, -.018, .05))), (.25, .01, .025), (0, s * .5, 0), 0, 'flat')
    p.cylinder('gold_leaf', (mast - .12, 0, top + 1.05), (mast - .32, 0, top + 1.05), .02, 6, uv='flat')
    p.sphere('gold_leaf', (mast, 0, top + 1.3), .06, 1)
    for x, y, out in ((-X - .15 - .45 + .02, -Y + .12, (.37, 0)), (X + .15 + .45 - .02, -Y + .12, (-.37, 0))):
        kit.downpipe(p, (x, y, z_eave - .08), 0, out, swan=.35)
    kit.lantern(p, (-1.35, -Y, 2.45), (0, -1))
    kit.lantern(p, (1.35, -Y, 2.45), (0, -1))
    # The parcel bench outside the west window: parcels in brown paper and string, a brass scale.
    with p.into('detail_parcels'):
        bx, by = -2.75, -Y - .62
        p.box('timber', (bx, by, .55), (1.7, .55, .06), bevel=.01, uv='local')
        for dx in (-.75, .75):
            for dy in (-.2, .2):
                p.box('timber', (bx + dx, by + dy, .27), (.06, .06, .54), bevel=0, uv='local')
        p.box('timber', (bx, by, .14), (1.55, .45, .03), bevel=0, uv='local')
        for k, (dx, w, d, h, turn) in enumerate(((-.55, .4, .3, .24, .1), (-.15, .3, .26, .32, -.08), (.3, .44, .32, .18, .05), (.3, .3, .24, .14, -.2))):
            z = .58 + (.18 if k == 3 else 0)
            p.box('wicker_dark' if k % 2 else 'wood_end', (bx + dx, by, z + h / 2), (w, d, h), (0, 0, turn), .01, 'flat')
            p.box('rope', (bx + dx, by, z + h / 2), (w + .006, .015, h + .006), (0, 0, turn), 0, 'flat')
            p.box('rope', (bx + dx, by, z + h / 2), (.015, d + .006, h + .006), (0, 0, turn), 0, 'flat')
        p.box('brass', (bx + .62, by, .62), (.24, .2, .04), bevel=.008, uv='flat')
        p.cylinder('brass', (bx + .62, by, .64), (bx + .62, by, .8), .015, 6, uv='flat')
        p.box('brass', (bx + .62, by, .81), (.22, .18, .015), bevel=0, uv='flat')
        for k in range(3):
            kit.crate(p, (bx - .3 + k * .45, by - .05, 0), (.4, .32, .14), .1 * (k - 1))
    with p.into('detail_planters'):
        for x in (-1.25, 1.25):
            kit.pot(p, (x, -Y - .45, 0), .8, 'cone')
        kit.pot(p, (X + .45, -1.6, 0), 1.0, 'tree')
    with p.into('detail_vines'):
        kit.climber(p, (-X - .04, -Y + .35, .42), 4.3, (-1, 0), flowers=('flower_white', 'flower_pink'), bloom=.3)


# --- the fruit market --------------------------------------------------------------------------------------------------
MARKET_PALETTE = {'plaster': 'seaside_plaster_ochre', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                  'stone': 'seaside_stone_honey', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_sage'}
FRUIT = {'orange': ('flower_orange',), 'apple': ('flower_red', 'enamel_red'), 'pear': ('olive', 'leaf_light'), 'lemon': ('flower_yellow',),
         'grape': ('flower_violet',), 'melon': ('leaf_dark', 'olive'), 'plum': ('flower_violet', 'enamel_red_dark')}


def fruit_crate(p, at, kind, size=(.5, .36, .16), tilt=0.0, heap=True):
    """A slatted crate tipped toward the buyer and heaped with fruit."""
    rng = p.rng
    x, y, z = at
    w, d, h = size
    rot = (tilt, 0, 0)      # positive tilt raises the back, so the fruit faces the buyer
    p.box('timber', (x, y, z + h / 2), (w, d, h), rot, .008, 'local')
    for k in (-1, 1):
        p.box('wood_end', (x + k * (w / 2 - .02), y, z + h / 2), (.03, d + .01, h + .01), rot, .004, 'flat')
    if not heap:
        return
    colours = FRUIT[kind]
    r = {'melon': .09, 'grape': .025, 'lemon': .035, 'plum': .03}.get(kind, .042)
    n_x, n_y = max(1, int(w / (2 * r) - .3)), max(1, int(d / (2 * r) - .3))
    for i in range(n_x):
        for j in range(n_y):
            fx = x - w / 2 + r + .02 + i * (w - 2 * r - .04) / max(1, n_x - 1)
            fy = y - d / 2 + r + .02 + j * (d - 2 * r - .04) / max(1, n_y - 1)
            lift = math.sin(math.pi * (i + .5) / n_x) * math.sin(math.pi * (j + .5) / n_y) * r * 1.4
            fz = z + h + r * .6 + lift + (fy - y) * math.tan(tilt)
            squash = (1.05, 1, .95) if kind != 'lemon' else (1.3, 1, .9)
            p.sphere(colours[(i + j) % len(colours)], (fx + rng.uniform(-.006, .006), fy, fz), r, 1 if r > .03 else 0, squash)


def spandrels(p, centre, width, height, facing, depth=.36):
    """Stone filling the corners of a rectangular wall opening above its round head."""
    f = Vector((facing[0], facing[1], 0))
    across = Vector((-f.y, f.x, 0))
    c = Vector((centre[0], centre[1], 0))
    r = width / 2
    spring = height - r
    for side in (-1, 1):
        outline = [(side * r * math.cos(math.pi / 2 * k / 8), spring + r * math.sin(math.pi / 2 * k / 8)) for k in range(9)]
        outline.append((side * r, height))
        p.solid('stone', [c + across * x + Vector((0, 0, z)) for x, z in outline], depth, (f.x, f.y, 0))


def market_stall(p, x0, x1, y_front, depth, kinds):
    """Three tiers of crates stepping back from the buyer on a timber stand."""
    width = x1 - x0
    p.box('timber', ((x0 + x1) / 2, y_front + depth / 2, .36), (width, depth, .06), bevel=.008, uv='local')
    for xx in (x0 + .06, x1 - .06):
        for yy in (y_front + .06, y_front + depth - .06):
            p.box('timber', (xx, yy, .18), (.06, .06, .36), bevel=0, uv='local')
    p.box('shutter', ((x0 + x1) / 2, y_front - .015, .2), (width, .03, .32), bevel=.005, uv='local')
    count = max(1, int(width / .55))
    w = width / count
    for tier, (dy, dz) in enumerate(((.22, .4), (.55, .58), (.88, .78))):
        if dy > depth:
            break
        for k in range(count):
            kind = kinds[(k + tier * 2) % len(kinds)]
            fruit_crate(p, (x0 + w * (k + .5), y_front + dy, dz), kind, (w - .05, .3, .14), .18)
        if tier:
            p.box('timber', ((x0 + x1) / 2, y_front + dy, dz - .02), (width, .32, .04), bevel=.004, uv='local')
            for xx in (x0 + .06, x1 - .06):
                p.box('timber', (xx, y_front + dy, (dz + .36) / 2), (.05, .05, dz - .36), bevel=0, uv='local')


def fruit_market(p):
    """An open market hall, its front on four cast-iron columns under a timber fascia lettered FRUIT MARKET, striped
    awnings on every bay; a stone back and gable ends; a clay-tiled roof with a louvred vent on the ridge. Inside,
    tiered stalls of oranges, apples, pears, lemons, grapes and melons, a hanging scale and a chalkboard."""
    X, Y = 6.0, 4.0
    E = 4.2
    rng = p.rng
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, E, .35, [(X - x - .35, X - x + .35, 2.6, 3.3) for x in (-4, -1.3, 1.3, 4)])
    for side in (-1, 1):
        a, b = ((X, -Y), (X, Y)) if side > 0 else ((-X, Y), (-X, -Y))
        arch = (Y - 1.4, Y + 1.4, 0, 3.0)
        kit.wall(p, 'stone', a, b, 0, E, .35, [arch])
        kit.surround(p, (side * X, 0, 1.5), 2.8, 3.0, (side, 0), sill=False, lintel=False, arch=True)
        spandrels(p, (side * X, 0), 2.8, 3.0, (side, 0))
    for a, b, f in fronts(X, Y)[1:]:
        kit.band(p, 'stone', a, b, 0, .4, .05, f)
        kit.band(p, 'stone', a, b, E - .18, .18, .08, f)
    for corner, faces in corners(X, Y):
        kit.quoins(p, corner, faces, .4, E - .18, course=.34, long=.5, short=.3, proud=.035)
    # The arched gable openings stay open: a low iron gate folded back in each.
    # The front: a stone kerb, four iron columns with capitals and brackets, a fascia beam and lettered board.
    p.box('stone', (0, -Y + .05, .1), (2 * X + .1, .5, .2), bevel=.02, uv=('blocks', 0))
    cols = [-X + .25, -X / 3, X / 3, X - .25]
    for x in cols:
        p.box('stone', (x, -Y + .05, .3), (.34, .34, .2), bevel=.02, uv=('blocks', 0))
        p.cylinder('canvas_green', (x, -Y + .05, .4), (x, -Y + .05, 2.95), .09, 12, uv='flat')
        for z, r in ((.45, .13), (2.9, .14)):
            p.cylinder('canvas_green', (x, -Y + .05, z - .05), (x, -Y + .05, z + .05), r, 12, uv='flat')
        p.box('canvas_green', (x, -Y + .05, 3.03), (.3, .3, .1), bevel=.01, uv='flat')
        for side in (-1, 1):
            if (x == cols[0] and side < 0) or (x == cols[-1] and side > 0):
                continue
            arc = [Vector((x + side * (.6 - .6 * math.cos(math.pi / 2 * i / 6)), -Y + .05, 2.48 + .6 * math.sin(math.pi / 2 * i / 6))) for i in range(7)]
            for q0, q1 in zip(arc, arc[1:]):
                p.beam('canvas_green', q0, q1, .05, .05, up=(0, 1, 0), uv='flat')
    p.box('timber', (0, -Y + .05, 3.3), (2 * X + .3, .3, .5), bevel=.015, uv='local')
    p.box('canvas', (0, -Y - .13, 3.3), (4.6, .04, .4), bevel=.01, uv='flat')
    kit.text(p, 'canvas_green', 'FRUIT  MARKET', kit.facing_text(0, -Y - .155, 3.28, (0, -1)), .26)
    p.box('stone', (0, -Y + .05, 3.85), (2 * X + .1, .35, .6), bevel=.01, uv='world')
    p.box('timber', (0, -Y + .05, 4.12), (2 * X + .5, .5, .1), bevel=.01, uv='local')
    # Above the fascia the front gable wall is closed in boards, stopping at the roof.
    # Awnings over each bay, each in the hall's own two colours.
    bays = [(cols[i] + cols[i + 1]) / 2 for i in range(3)]
    for x in bays:
        kit.awning(p, (x, -Y - .12, 2.9), (cols[1] - cols[0]) - .45, .85, 2.9, .38, (0, -1), ('canvas_green', 'canvas'), .3)
    # The roof: a clay gable with its ridge along the front, and a louvred vent along the ridge.
    ridge, z_eave, eave = kit.gable_roof(p, -X, X, -Y, Y, E, 32, eave=.35, verge=.35)
    for x, out in ((-X, -1), (X, 1)):
        kit.gable(p, 'stone', 'x', x, -Y, Y, E, ridge - .12, out, .35)
        p.pane('window_pane', (x + out * .02, 0, E + .85), .9, .5, (out, 0), .02)
        p.box('timber', (x + out * .06, 0, E + .85), (.06, 1.0, .6), bevel=.01, uv='local')
    vx0, vx1 = -3.2, 3.2
    vz = ridge + .02
    for x in (vx0, vx1):
        p.box('timber', (x, 0, vz + .3), (.12, .9, .6), bevel=.01, uv='local')
    for k in range(4):
        p.box('timber', (0, -.42, vz + .1 + k * .13), (vx1 - vx0, .04, .1), (math.radians(-30), 0, 0), .004, 'local')
        p.box('timber', (0, .42, vz + .1 + k * .13), (vx1 - vx0, .04, .1), (math.radians(30), 0, 0), .004, 'local')
    for sign in (-1, 1):
        kit.slope_courses(p, (0, sign * .62, vz + .62), (sign, 0, 0), Vector((0, -sign * .6, .3)).normalized(), .7, vx1 - vx0 + .3, vx1 - vx0 + .3)
    kit.ridge_caps(p, (vx0 - .15, 0, vz + .97), (vx1 + .15, 0, vz + .97), 'ridge', .08, .4)
    for x, y, out in ((-X - .35 + .05, -Y - eave + .02, (0, eave - .1)), (X + .35 - .05, -Y - eave + .02, (0, eave - .1))):
        kit.downpipe(p, (x, y, z_eave - .08), 0, out, swan=.3)
    # Inside: the floor, stalls along the back and both ends, a centre table, the scale, the chalkboard, lanterns.
    p.box('stone', (0, 0, .015), (2 * X - .7, 2 * Y - .7, .03), bevel=0, uv='world')
    market_stall(p, -X + .5, X - .5, Y - 1.4, 1.1, ['orange', 'apple', 'pear', 'lemon', 'plum'])
    market_stall(p, -X / 3 - 1.2, X / 3 + 1.2, -.9, 1.1, ['apple', 'orange', 'grape', 'pear'])
    for k, kind in enumerate(('melon', 'melon', 'orange', 'apple')):
        fruit_crate(p, (-X + 1.1 + k * .62, -Y + .75, 0), kind, (.55, .4, .3))
    for k, kind in enumerate(('lemon', 'pear', 'orange')):
        fruit_crate(p, (X - 1.1 - k * .62, -Y + .75, 0), kind, (.55, .4, .3))
    for k in range(3):
        kit.crate(p, (X - 1.0, Y - 2.1 + k * .02, k * .3), (.55, .4, .3), .1 * k)
    kit.basket(p, (-X + .8, -.5, 0), .26, .26, linen=False)
    kit.basket(p, (-X + 1.4, -.2, 0), .22, .24, linen=False)
    for k in range(6):
        p.sphere('flower_orange', (-X + .8 + rng.uniform(-.12, .12), -.5 + rng.uniform(-.12, .12), .3), .045, 1)
    sx = 1.6
    p.cylinder('iron', (sx, -1.6, 3.0), (sx, -1.6, 2.35), .01, 4, uv='flat')
    p.box('brass', (sx, -1.6, 2.32), (.08, .08, .08), bevel=.01, uv='flat')
    p.cylinder('brass', (sx, -1.6, 2.28), (sx, -1.6, 2.0), .006, 4, uv='flat')
    p.cylinder('brass', (sx, -1.6, 1.98), (sx, -1.6, 1.92), .17, 14, .12, uv='flat', smooth=True)
    for k in range(4):
        p.sphere('flower_red', (sx + (k - 1.5) * .06, -1.6, 2.0), .04, 1)
    bx, by = -2.4, -Y - .35
    p.box('timber', (bx, by, .55), (.62, .04, .8), (math.radians(-8), 0, 0), .01, 'local')
    p.box('ink', (bx, by - .025, .58), (.54, .01, .7), (math.radians(-8), 0, 0), 0, 'flat')
    for x, y, z, words, size in ((bx, by - .035, .8, 'PEACHES', .085), (bx, by - .035, .7, 'TOMORROW', .07), (bx, by - .035, .52, 'probably', .05)):
        kit.text(p, 'canvas', words, kit.facing_text(x, y, z, (0, -1)), size)
    for leg in (-.25, .25):
        p.box('timber', (bx + leg, by + .12, .4), (.04, .04, .82), (math.radians(14), 0, 0), 0, 'local')
    for x in (-3, 3):
        p.cylinder('iron', (x, 0, ridge - .5), (x, 0, 2.95), .01, 4, uv='flat')
        p.box('lamp_glass', (x, 0, 2.8), (.2, .2, .26), bevel=0, uv='flat')
        p.box('iron', (x, 0, 2.97), (.26, .26, .04), bevel=.005, uv='flat')
    for x in (-X - .3, X + .3):
        with p.into('detail_planters'):
            kit.pot(p, (x, -Y - .5, 0), .9, 'flowers', ('flower_orange', 'flower_red', 'flower_white'))


# --- the bank ---------------------------------------------------------------------------------------------------------
BANK_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_slate', 'ridge': 'seaside_roof_slate',
                'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_dark', 'shutter': 'seaside_shutter_blue'}


def rusticated(p, a, b, z0, z1, facing, course=.36, depth=.12):
    """Rusticated ashlar: deep-jointed blocks standing proud of a wall face from a to b (2D)."""
    rng = p.rng
    a3, b3 = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
    along = (b3 - a3).normalized()
    length = (b3 - a3).length
    out = Vector((facing[0], facing[1], 0))
    n = max(1, round((z1 - z0) / course))
    h = (z1 - z0) / n
    for k in range(n):
        s = (rng.uniform(.3, .5) if k % 2 else 0)
        if s:
            q = a3 + along * s / 2 + out * depth / 2
            size = (s - .05, depth, h - .05) if abs(out.y) > .5 else (depth, s - .05, h - .05)
            p.box('stone', (q.x, q.y, z0 + h * (k + .5)), size, bevel=.035, uv=('blocks', 0))
        while s < length - .05:
            w = min(rng.uniform(.75, 1.05), length - s)
            if length - (s + w) < .3:
                w = length - s
            q = a3 + along * (s + w / 2) + out * depth / 2
            size = (w - .05, depth, h - .05) if abs(out.y) > .5 else (depth, w - .05, h - .05)
            p.box('stone', (q.x, q.y, z0 + h * (k + .5)), size, bevel=.035, uv=('blocks', 0))
            s += w


def column(p, x, y, z0, z1, r=.2):
    """A column: a square plinth and moulded base, a tapering shaft with fillets, a scrolled capital."""
    p.box('stone', (x, y, z0 + .09), (2.4 * r + .1, 2.4 * r + .1, .18), bevel=.015, uv=('blocks', 0))
    for zz, rr in ((z0 + .24, r * 1.22), (z0 + .32, r * 1.12)):
        p.cylinder('stone', (x, y, zz - .04), (x, y, zz + .04), rr, 16, uv=('blocks', 0))
    p.cylinder('stone', (x, y, z0 + .36), (x, y, z1 - .36), r, 16, r * .86, uv=('blocks', 0))
    for k in range(12):
        a = math.tau * k / 12
        p.box('stone', (x + math.cos(a) * r * .97, y + math.sin(a) * r * .97, (z0 + z1) / 2), (.02, .02, z1 - z0 - .8), (0, 0, a), 0, ('blocks', 0))
    p.cylinder('stone', (x, y, z1 - .36), (x, y, z1 - .28), r * .95, 16, uv=('blocks', 0))
    p.box('stone', (x, y, z1 - .2), (2.3 * r, 1.6 * r, .16), bevel=.03, uv=('blocks', 0))
    for side in (-1, 1):
        p.cylinder('stone', (x + side * r * 1.05, y - r * .9, z1 - .2), (x + side * r * 1.05, y + r * .9, z1 - .2), .08, 10, uv=('blocks', 0))
    p.box('stone', (x, y, z1 - .05), (2.6 * r, 2.6 * r, .1), bevel=.015, uv=('blocks', 0))


def bank(p):
    """Haverlund Savings: two tall storeys in pale limestone. A rusticated ground floor with arched windows behind iron
    grilles; a portico of two columns under a pediment over panelled doors at the head of the steps; pilasters and
    pedimented windows above; a dentilled cornice, a balustrade along the roof and a copper-roofed lantern with a
    weathered dome behind it."""
    X, Y = 5.0, 4.0
    G, E = 3.6, 7.5
    door_w, door_h = 1.6, 2.9
    aw, ah = 1.1, 2.1
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, E, .35, [(-door_w / 2 + X, door_w / 2 + X, .45, .45 + door_h)] +
             [(x - aw / 2 + X, x + aw / 2 + X, 1.0, 1.0 + ah) for x in (-3.3, 3.3)] +
             [(x - .55 + X, x + .55 + X, G + .7, G + .7 + 1.9) for x in (-3.3, -1.1, 1.1, 3.3)])
    for (a, b, f), openings in zip(fronts(X, Y)[1:], ([(.5 + Y - .5, .5 + Y + .5, 1.2, 2.9), (.5 + Y - .5, .5 + Y + .5, G + .8, G + 2.5)],
                                                       [(X - x - .5, X - x + .5, G + .8, G + 2.5) for x in (-3, 0, 3)] + [(X - 2.6 - .5, X - 2.6 + .5, 0, 2.3)],
                                                       [(Y - .5 - .5, Y - .5 + .5, 1.2, 2.9), (Y - .5 - .5, Y - .5 + .5, G + .8, G + 2.5)])):
        kit.wall(p, 'stone', a, b, 0, E, .35, openings)
    # Rustication on the front and sides of the ground floor, with the openings left clear.
    for a, b, f in fronts(X, Y)[:2] + fronts(X, Y)[3:]:
        a3, b3 = Vector((a[0], a[1], 0)), Vector((b[0], b[1], 0))
        along = (b3 - a3).normalized()
        holes = ([(-door_w / 2 - .5, door_w / 2 + .5)] + [(x - aw / 2 - .25, x + aw / 2 + .25) for x in (-3.3, 3.3)]) if f == (0, -1) else [(.5 - .75, .5 + .75)]
        coord = (lambda v: v.x) if f[1] else (lambda v: v.y)
        cuts = sorted([coord(a3) if coord(a3) < coord(b3) else coord(b3)] + [c for h in holes for c in h] + [max(coord(a3), coord(b3))])
        spans = [(cuts[i], cuts[i + 1]) for i in range(0, len(cuts) - 1, 2)]
        for s0, s1 in spans:
            if s1 - s0 < .2:
                continue
            if f[1]:
                rusticated(p, (s0, a[1]), (s1, a[1]), .45, G - .1, f)
            else:
                rusticated(p, (a[0], s0), (a[0], s1), .45, G - .1, f)
    for a, b, f in fronts(X, Y):
        kit.band(p, 'stone', a, b, 0, .45, .1, f)
        kit.band(p, 'stone', a, b, G - .1, .3, .14, f)
        kit.band(p, 'stone', a, b, E - .5, .3, .12, f)
        kit.band(p, 'stone', a, b, E - .2, .22, .3, f)
    # Dentils under the cornice on the front.
    for k in range(int(2 * X / .22)):
        p.box('stone', (-X + .11 + k * .22, -Y - .16, E - .27), (.1, .14, .1), bevel=.008, uv=('blocks', 0))
    # Arched ground-floor windows with iron grilles; pedimented upper windows between pilasters.
    for x in (-3.3, 3.3):
        kit.window(p, (x, -Y, 1.0 + ah / 2), aw, ah, (0, -1), shutters=None, box=False, bars=(1, 3), recess=.18, keystone=True)
        for k in range(6):
            p.box('iron', (x - aw / 2 + .1 + k * (aw - .2) / 5, -Y - .03, 1.0 + ah / 2 - .2), (.02, .02, ah - .3), bevel=0, uv='flat')
        for z in (1.15, 1.0 + ah - .55):
            p.box('iron', (x, -Y - .03, z), (aw - .1, .02, .03), bevel=0, uv='flat')
    for x in (-3.3, -1.1, 1.1, 3.3):
        kit.window(p, (x, -Y, G + .7 + .95), 1.1, 1.9, (0, -1), shutters=None, box=False, bars=(1, 2), recess=.16)
        apex = G + .7 + 1.9 + .55
        for side in (-1, 1):
            p.beam('stone', (x + side * .75, -Y - .14, G + .7 + 1.9 + .25), (x, -Y - .14, apex), .26, .12, up=(0, 0, 1), uv=('blocks', 0))
        p.box('stone', (x, -Y - .1, G + .7 + 1.9 + .2), (1.5, .24, .1), bevel=.01, uv=('blocks', 0))
    for x in (-4.4, -2.2, 0, 2.2, 4.4):
        if x == 0:
            continue
        p.box('stone', (x, -Y - .06, (G + 0.2 + E - .5) / 2), (.42, .14, E - .7 - G), bevel=.015, uv=('blocks', 0))
        p.box('stone', (x, -Y - .1, E - .65), (.52, .2, .14), bevel=.015, uv=('blocks', 0))
    for side in (-1, 1):
        kit.window(p, (side * X, .5, G + .8 + .85), 1.0, 1.7, (side, 0), shutters=None, box=False, bars=(1, 2), recess=.16)
        kit.window(p, (side * X, .5, 2.05), 1.0, 1.7, (side, 0), shutters=None, box=False, bars=(1, 2), recess=.16)
    for x in (-3, 0, 3):
        kit.window(p, (x, Y, G + .8 + .85), 1.0, 1.7, (0, 1), shutters=None, box=False, bars=(1, 2), recess=.16)
    kit.door(p, 2.6, Y, 1.0, 2.3, (0, 1), style='plank', leaf_mat='timber')
    # The steps and the portico.
    for k in range(3):
        d = 1.3 - k * .35
        p.box('stone', (0, -Y - d / 2, .075 + k * .15), (door_w + 2.6 - k * .3, d, .15), bevel=.02, uv=('blocks', 0))
    for side in (-1, 1):
        column(p, side * 1.25, -Y - .85, .45, G + .3)
    p.box('stone', (0, -Y - .45, G + .42), (3.3, 1.1, .26), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, -Y - .5, G + .62), (3.5, 1.2, .14), bevel=.02, uv=('blocks', 0))
    kit.gable(p, 'stone', 'y', -Y - 1.08, -1.75, 1.75, G + .69, G + 1.55, -1, .9)
    for side in (-1, 1):
        p.beam('stone', (side * 1.82, -Y - 1.14, G + .72), (0, -Y - 1.14, G + 1.62), .3, .14, up=(0, 0, 1), uv=('blocks', 0))
    p.box('gold_leaf', (0, -Y - 1.0, G + 1.0), (.36, .02, .3), bevel=.01, uv='flat')
    kit.text(p, 'ink', 'HAVERLUND  SAVINGS', kit.facing_text(0, -Y - 1.004, G + .42, (0, -1)), .15)
    # The doors: panelled oak pair, brass, a fanlight; the brass plate by them.
    for side in (-1, 1):
        x = side * door_w / 4
        p.box('timber', (x, -Y + .12, .45 + (door_h - .55) / 2), (door_w / 2 - .03, .07, door_h - .55), bevel=.01, uv='local')
        for z0, z1 in ((.6, 1.5), (1.65, door_h - .3)):
            p.box('timber', (x, -Y + .08, (z0 + z1) / 2), (door_w / 2 - .22, .02, z1 - z0), bevel=.02, uv='local')
        p.cylinder('brass', (x - side * .12, -Y + .06, 1.6), (x - side * .12, -Y + .03, 1.6), .05, 12, uv='flat')
    p.pane('window_pane', (0, -Y + .12, .45 + door_h - .28), door_w - .1, .46, (0, -1))
    for k in range(5):
        p.box('sash', (-door_w / 2 + .05 + (door_w - .1) * k / 4, -Y + .09, .45 + door_h - .28), (.03, .04, .46), bevel=0, uv='flat')
    kit.surround(p, (0, -Y, .45 + door_h / 2), door_w, door_h, (0, -1), sill=False, keystone=True)
    p.box('brass', (door_w / 2 + .62, -Y - .03, 1.65), (.42, .02, .3), bevel=.01, uv='flat')
    kit.text(p, 'ink', 'AVERLUND', kit.facing_text(door_w / 2 + .66, -Y - .042, 1.7, (0, -1)), .045)
    kit.text(p, 'ink', 'SAVINGS', kit.facing_text(door_w / 2 + .62, -Y - .042, 1.6, (0, -1)), .045)
    for side in (-1, 1):
        kit.lantern(p, (side * (door_w / 2 + 1.75), -Y, 2.65), (0, -1))
    # The roof: a low slate hip behind a balustrade on the cornice, and a copper-roofed lantern with a dome.
    top, ends, z_eave = kit.hip_roof(p, -X + .35, X - .35, -Y + .35, Y - .35, E + .2, 22, eave=.0, gutters=False)
    for a, b, f in fronts(X - .12, Y - .12):
        length = (Vector(b) - Vector(a)).length
        count = max(1, round(length / .27))
        along = (Vector(b) - Vector(a)) / length
        for k in range(count):
            q = Vector(a) + along * length * (k + .5) / count
            p.box('stone', (q.x, q.y, E + .2), (.13, .13, .38), bevel=.02, uv=('blocks', 0))
        mid = (Vector(a) + Vector(b)) / 2
        p.box('stone', (mid.x, mid.y, E + .44), (length + .3 if f[1] else .3, .3 if f[1] else length + .3, .1), bevel=.02, uv=('blocks', 0))
    for x, y in ((-X, -Y), (X, -Y), (X, Y), (-X, Y), (0, -Y)):
        p.box('stone', (x * .976, y * .97, E + .3), (.4, .4, .6), bevel=.02, uv=('blocks', 0))
        p.sphere('stone', (x * .976, y * .97, E + .74), .14, 2)
    lz = top - .2
    p.box('stone', (0, .5, lz + .6), (2.0, 2.0, 1.2), bevel=.02, uv=('blocks', 0))
    for f in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        c = Vector((f[0] * 1.0, .5 + f[1] * 1.0, lz + .65))
        p.pane('window_pane', tuple(c), .5, .75, f, .02)
        across = Vector((-f[1], f[0], 0))
        for s in (-1, 1):
            q = c + across * s * .32 + Vector((f[0], f[1], 0)) * .04
            p.box('stone', tuple(q), (.1 if abs(f[1]) else .06, .06 if abs(f[1]) else .1, .9), bevel=.01, uv=('blocks', 0))
    p.box('stone', (0, .5, lz + 1.25), (2.3, 2.3, .12), bevel=.02, uv=('blocks', 0))
    profile = [(1.05, 0), (1.0, .25), (.85, .55), (.6, .82), (.3, 1.0), (.05, 1.06)]
    verts, faces, uvs = [], [], []
    segs = 32
    for r, z in profile:
        for s in range(segs):
            a = math.tau * s / segs
            verts.append((math.cos(a) * r, .5 + math.sin(a) * r, lz + 1.31 + z))
    for i in range(len(profile) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            faces.append((i * segs + s, i * segs + sn, (i + 1) * segs + sn, (i + 1) * segs + s))
            uvs.append([(s / segs * 4, i * .25), ((s + 1) / segs * 4, i * .25), ((s + 1) / segs * 4, (i + 1) * .25), (s / segs * 4, (i + 1) * .25)])
    p.add('bank_copper', verts, faces, uvs, True)
    for s in range(8):
        a = math.tau * s / 8
        rib = [Vector((math.cos(a) * (r + .01), .5 + math.sin(a) * (r + .01), lz + 1.31 + z)) for r, z in profile]
        for q0, q1 in zip(rib, rib[1:]):
            p.beam('brass', q0, q1, .04, .03, up=(0, 0, 1), uv='flat')
    p.cylinder('brass', (0, .5, lz + 2.36), (0, .5, lz + 2.5), .06, 10, uv='flat')
    p.sphere('gold_leaf', (0, .5, lz + 2.62), .12, 2)
    for x in (-3.2, 3.2):
        surface = E + .2 + min(X - .35 - abs(x), Y - .35 - 2.6) * math.tan(math.radians(22))
        kit.chimney(p, x, 2.6, surface - .3, top + .7, width=.6, depth=.5, style='stone', collar=surface - .05)
    with p.into('detail_planters'):
        for side in (-1, 1):
            kit.pot(p, (side * 2.2, -Y - .55, 0), 1.1, 'cone')
            p.box('stone', (side * 4.1, -Y - .45, .3), (.9, .5, .6), bevel=.03, uv=('blocks', 0))
            for k in range(6):
                p.sphere(('leaf', 'leaf_dark')[k % 2], (side * 4.1 + (k - 2.5) * .14, -Y - .45, .66), .1, 1)
                p.sphere(('flower_red', 'flower_white')[k % 2], (side * 4.1 + (k - 2.5) * .14, -Y - .52, .74), .045, 1)


ASSETS = {
    'haverlund-post-office': (post_office, POST_PALETTE, 7101, 'Haverlund post office'),
    'haverlund-fruit-market': (fruit_market, MARKET_PALETTE, 7102, 'The fruit market hall'),
    'haverlund-bank': (bank, BANK_PALETTE, 7103, 'Haverlund Savings, the bank'),
}

if __name__ == '__main__':
    chosen, out = kit.selected(list(ASSETS))
    for asset in chosen:
        make, palette, seed, label = ASSETS[asset]
        root = kit.begin(asset, palette)
        kit.material('bank_copper', 'ffffff', VERDIGRIS, .62, metallic=.25)
        parts = kit.Parts(seed)
        make(parts)
        parts.finish(root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, RECORD, palette, {'reference': REF})
