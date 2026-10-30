"""Guarded one-time authoring of three more modular seaside background houses after
docs/concept/v0.72/background-houses.md: D, the Lantern Row lodging house; G, the Shingle Court cottage; and H, the
Eaveside terrace pair. Built from the same kit as E and F (house_kit.py).

    blender --background --factory-startup --python art/source/world/seaside-houses/v1/author_houses_dgh.py -- [ids]
    ... -- --draft .cache/seaside-houses/drafts [ids]     (review drafts outside art/source)

Refuses an existing master. After authoring, each model.blend is the editable authority; export only with
scripts/world-art.sh build <id>. Fronts face Blender -Y (Godot +Z); the pivot is the footprint centre at ground.
Roofs whose gable faces the street are built with their ridge along X in a frame turned -90 degrees
(`parts.turned(-90)`): there, x = -(final y) and y = final x, so the gable built at +x is the front.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import house_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

REF = 'docs/concept/v0.72/art/background-houses/'
def SIDES(X0, X1, Y0, Y1):
    """The four walls of a rectangle, counter-clockwise from the front, with their outward normals."""
    return (((X0, Y0), (X1, Y0), (0, -1)), ((X1, Y0), (X1, Y1), (1, 0)), ((X1, Y1), (X0, Y1), (0, 1)), ((X0, Y1), (X0, Y0), (-1, 0)))


def corners(X0, X1, Y0, Y1):
    return (((X0, Y0), ((0, -1), (-1, 0))), ((X1, Y0), ((0, -1), (1, 0))), ((X1, Y1), ((0, 1), (1, 0))), ((X0, Y1), ((0, 1), (-1, 0))))


# --- D: Lantern Row lodging house ----------------------------------------------------------------------------------
LANTERN_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                   'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def lantern_row(p):
    """A tall, narrow lodging house: four storeys and an attic under a steep gable facing the street. A dressed
    limestone ground floor with an arched door; three limewashed floors framed by oak floor beams and corner posts,
    two shuttered windows to each; plain side walls with one small window a floor so neighbours can stand close; a
    dormer on the side slope and a brick chimney. Behind: a low pantry lean-to, the kitchen door and washing hung
    from the top floor."""
    X, Y = 2.0, 2.8
    G = 2.9
    floors = (2.9, 5.6, 8.3)
    E = 11.0
    rng = p.rng
    door_x, door_w, door_h = -.95, .9, 2.4
    win = (.85, .75, 1.2, 1.6)
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .26, [(door_x - door_w / 2 + X, door_x + door_w / 2 + X, 0, door_h),
                                                          (win[0] - win[1] / 2 + X, win[0] + win[1] / 2 + X, win[3] - win[2] / 2, win[3] + win[2] / 2)])
    sw, sh = .5, .8
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, G, .26, [(1.4 + Y - .25, 1.4 + Y + .25, 1.2, 2.0)])
    back_door_x = -.9
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, G, .26, [(X - back_door_x - .45, X - back_door_x + .45, 0, 2.15)])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, G, .26, [(Y - 1.4 - .25, Y - 1.4 + .25, 1.2, 2.0)])
    for a, b, f in SIDES(-X, X, -Y, Y):
        kit.band(p, 'stone', a, b, 0, .36, .05, f)
    for corner, faces in corners(-X, X, -Y, Y):
        kit.quoins(p, corner, faces, .36, G, course=.32, long=.46, short=.28, proud=.03)
    kit.door(p, door_x, -Y, door_w, door_h, (0, -1), style='plank', arch=True)
    kit.window(p, (win[0], -Y, win[3]), win[1], win[2], (0, -1), shutters='open', flowers=('flower_white', 'flower_red', 'flower_pink'))
    kit.window(p, (X, 1.4, 1.6), sw, sh, (1, 0), shutters=None, box=False, bars=(1, 1))
    kit.window(p, (-X, 1.4, 1.6), sw, sh, (-1, 0), shutters=None, box=False, bars=(1, 1))
    kit.door(p, back_door_x, Y, .9, 2.15, (0, 1), style='plank')
    kit.lantern(p, (-.15, -Y, 2.1), (0, -1))
    kit.lantern(p, (-.15, Y, 2.0), (0, 1))
    # Three limewashed floors in an oak frame.
    uw, uh = .72, 1.2
    for k, z0 in enumerate(floors):
        z1 = floors[k + 1] if k + 1 < len(floors) else E
        zc = z0 + 1.45
        kit.wall(p, 'plaster', (-X, -Y), (X, -Y), z0, z1, .22, [(x - uw / 2 + X, x + uw / 2 + X, zc - uh / 2, zc + uh / 2) for x in (-.85, .85)])
        kit.wall(p, 'plaster', (X, Y), (-X, Y), z0, z1, .22, [(X - x - uw / 2, X - x + uw / 2, zc - uh / 2, zc + uh / 2) for x in (-.85, .85)])
        kit.wall(p, 'plaster', (X, -Y), (X, Y), z0, z1, .22, [(.9 + Y - sw / 2, .9 + Y + sw / 2, zc - sh / 2 + .05, zc + sh / 2 + .05)])
        kit.wall(p, 'plaster', (-X, Y), (-X, -Y), z0, z1, .22, [(Y - .9 - sw / 2, Y - .9 + sw / 2, zc - sh / 2 + .05, zc + sh / 2 + .05)])
        for a, b, f in SIDES(-X, X, -Y, Y):
            kit.band(p, 'timber', a, b, z0 - .06, .26, .05, f)
        for x in (-.85, .85):
            kit.window(p, (x, -Y, zc), uw, uh, (0, -1), shutters='both' if (k, x) == (1, .85) else 'open',
                       flowers=('flower_white', 'flower_red', 'flower_pink', 'flower_orange'))
            kit.window(p, (x, Y, zc), uw, uh, (0, 1), shutters='open', box=k < 2 or x < 0, flowers=('flower_white', 'flower_pink'))
        kit.window(p, (X, .9, zc + .05), sw, sh, (1, 0), shutters=None, box=False, bars=(1, 1))
        kit.window(p, (-X, .9, zc + .05), sw, sh, (-1, 0), shutters=None, box=False, bars=(1, 1))
    for x, y in ((-X, -Y), (X, -Y), (X, Y), (-X, Y)):
        p.box('timber', (x, y, (G + E) / 2 - .05), (.2, .2, E - G - .2), bevel=.015, uv='local')
    for a, b, f in SIDES(-X, X, -Y, Y):
        kit.band(p, 'timber', a, b, E - .2, .24, .05, f)
    # The steep gable roof, ridge front to back, with a side dormer and the chimney.
    with p.turned(-90):
        ridge, z_eave, eave = kit.gable_roof(p, -Y, Y, -X, X, E, 52, eave=.35, verge=.3)
        t = math.tan(math.radians(52))
        kit.dormer(p, .7, X + eave, z_eave, 52, 1, in_from_eave=.8, ridge_run=X + eave, width=1.0, height=.9,
                   window_w=.5, window_h=.6, shutters=None, box=False)
        collar = ridge - .75 * t - .25
        for style in ('brick', 'stone'):
            with p.into('alt_chimney_' + style):
                kit.chimney(p, -1.85, .75, collar - 1.2, ridge + 1.0, style=style, collar=collar, width=.66, depth=.56)
    for y, out in ((-Y, -1), (Y, 1)):
        kit.gable(p, 'plaster', 'y', y, -X, X, E, ridge - .12, out, .22)
    kit.window(p, (0, -Y, E + 1.05), .55, .7, (0, -1), recess=-.04, shutters='open', bars=(1, 1),
               flowers=('flower_white', 'flower_pink'))
    kit.window(p, (0, Y, E + 1.0), .5, .62, (0, 1), recess=-.04, shutters=None, box=False, bars=(1, 1))
    for x, y, wall_out in ((-X - eave + .02, -Y + .12, (eave - .08, 0)), (X + eave - .02, -Y + .12, (-(eave - .08), 0)),
                           (-X - eave + .02, Y - .12, (eave - .08, 0)), (X + eave - .02, Y - .12, (-(eave - .08), 0))):
        kit.downpipe(p, (x, y, z_eave - .08), 0, wall_out, swan=.35)
    # Behind: the pantry lean-to with its small window.
    kit.lean_to_shed(p, .05, X, Y, 1.35, G - .15, 2.3, 1, window_x=1.05)
    with p.into('detail_yard'):
        kit.barrel(p, (-1.55, Y + .45, 0), .28, .72)
        kit.crate(p, (-1.55, Y + 1.05, 0), (.45, .38, .3), -.2)
        kit.pot(p, (-.25, Y + .5, 0), .85, 'flowers', ('flower_red', 'flower_white'))
        kit.pot(p, (X + .4, 1.0, 0), .9, 'tree')
        kit.barrel(p, (X + .42, -.2, 0), .27, .7)
    with p.into('detail_laundry'):
        z = floors[2] + 2.05
        for x in (.25, 1.5):
            p.beam('iron', (x, Y, z), (x, Y + .4, z), .03, .03)
        kit.laundry(p, (.25, Y + .38, z), (1.5, Y + .38, z), [('linen', .32, .45), ('linen', .3, .5), ('cloth_blue', .26, .36)], .05)
    with p.into('detail_planters'):
        kit.pot(p, (-1.65, -Y - .42, 0), .95, 'cone')
        kit.pot(p, (-.25, -Y - .38, 0), .7, 'flowers', ('flower_white', 'flower_pink'))
        p.box('timber', (1.2, -Y - .35, .22), (1.0, .36, .34), bevel=.015, uv='local')
        for k in range(7):
            p.sphere(('leaf', 'leaf_light')[k % 2], (.78 + k * .14, -Y - .35 + rng.uniform(-.06, .06), .45), .09, 1)
            p.sphere(('flower_red', 'flower_white', 'flower_orange')[k % 3], (.78 + k * .14, -Y - .42, .53), .045, 1)
        kit.pot(p, (X + .38, -Y + .3, 0), .7, 'flowers', ('flower_orange', 'flower_white'))
    with p.into('detail_vines'):
        kit.climber(p, (X + .04, -Y + .45, .36), 6.8, (1, 0), flowers=('flower_white', 'flower_white', 'flower_pink'), bloom=.35)
        kit.climber(p, (-X - .04, -Y + .5, .36), 4.4, (-1, 0), flowers=('flower_white',), bloom=.25)


# --- G: Shingle Court cottage --------------------------------------------------------------------------------------
SHINGLE_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                   'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def shingle_court(p):
    """A low, wide courtyard cottage: one storey of dressed limestone under a broad pan-tiled roof, two dormers to each
    slope, a tiled hood over the front door, shuttered windows with flower boxes and a stone chimney. A tall plank gate
    under a little tiled pergola closes the courtyard beside it. Behind: a covered kitchen stoop with a work table."""
    X, Y = 4.0, 2.5
    E = 2.8
    rng = p.rng
    front = [(-.3, .95, 0, 2.15), (-2.5, .9, 1.0, 2.15), (1.7, .9, 1.0, 2.15)]
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, E, .3, [(x - w / 2 + X, x + w / 2 + X, lo, hi) for x, w, lo, hi in front])
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, E, .3, [(.4 + Y - .4, .4 + Y + .4, 1.05, 2.1)])
    back = [(-.6, .9, 0, 2.1), (1.0, .85, 1.0, 2.1), (-2.7, .8, 1.05, 2.1)]
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, E, .3, [(X - x - w / 2, X - x + w / 2, lo, hi) for x, w, lo, hi in back])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, E, .3, [(Y + .5 - .4, Y + .5 + .4, 1.05, 2.1)])
    for a, b, f in SIDES(-X, X, -Y, Y):
        kit.band(p, 'stone', a, b, 0, .38, .05, f)
        kit.band(p, 'stone', a, b, E - .2, .2, .06, f)
    for corner, faces in corners(-X, X, -Y, Y):
        kit.quoins(p, corner, faces, .38, E - .2, course=.34, long=.5, short=.3, proud=.035)
    kit.door(p, -.3, -Y, .95, 2.15, (0, -1), style='plank', hood='canopy', canopy_lift=.2)
    p.box('wicker', (-.3, -Y - .55, .015), (.8, .45, .03), bevel=0, uv='flat')
    for x in (-2.5, 1.7):
        kit.window(p, (x, -Y, 1.575), .9, 1.15, (0, -1), shutters='both' if x > 0 else 'open', flowers=('flower_white', 'flower_red', 'flower_pink'))
    kit.window(p, (X, .4, 1.575), .8, 1.05, (1, 0), shutters='open', box=False)
    kit.window(p, (-X, -.5, 1.575), .8, 1.05, (-1, 0), shutters='open', box=False)
    kit.door(p, -.6, Y, .9, 2.1, (0, 1), style='plank')
    kit.window(p, (1.0, Y, 1.55), .85, 1.1, (0, 1), shutters='open', flowers=('flower_white', 'flower_pink'))
    kit.window(p, (-2.7, Y, 1.575), .8, 1.05, (0, 1), shutters='open', box=False)
    kit.lantern(p, (.45, -Y, 2.0), (0, -1))
    kit.lantern(p, (.2, Y, 2.0), (0, 1))
    # The broad roof, four dormers, the gables with their attic lights, the stone chimney.
    ridge, z_eave, eave = kit.gable_roof(p, -X, X, -Y, Y, E, 45, eave=.42, verge=.3)
    run = Y + eave
    for x in (-2.0, 1.6):
        kit.dormer(p, x, -Y - eave, z_eave, 45, -1, in_from_eave=.7, ridge_run=run, width=1.15, height=.92,
                   window_w=.55, window_h=.62, flowers=('flower_white', 'flower_pink'))
    for x in (-2.1, 1.9):
        kit.dormer(p, x, Y + eave, z_eave, 45, 1, in_from_eave=.7, ridge_run=run, width=1.1, height=.88,
                   window_w=.52, window_h=.6, shutters='open' if x > 0 else None, box=x > 0)
    for x, out in ((-X, -1), (X, 1)):
        kit.gable(p, 'stone', 'x', x, -Y, Y, E, ridge - .12, out, .3)
        kit.window(p, (x, 0, E + 1.05), .4, .48, (out, 0), recess=-.05, shutters=None, box=False, stone=False, bars=(1, 1))
    t = math.tan(math.radians(45))
    collar = ridge - .2 * t - .25
    for style in ('stone', 'brick'):
        with p.into('alt_chimney_' + style):
            kit.chimney(p, -3.05, .2, collar - 1.0, ridge + .85, style=style, collar=collar, width=.7, depth=.6)
    for x, y, wall_out in ((-X + .12, -Y - eave + .02, (0, eave - .08)), (X - .12, -Y - eave + .02, (0, eave - .08)),
                           (-X + .12, Y + eave - .02, (0, -(eave - .08))), (X - .12, Y + eave - .02, (0, -(eave - .08)))):
        kit.downpipe(p, (x, y, z_eave - .08), 0, wall_out, swan=.3)
    # Behind: the covered kitchen stoop over the back door and window, with its work table.
    a0, a1, reach = -1.55, 1.85, 1.7
    # Tucked under the main eave, so its roof never meets the overhang above.
    kit.lean_to(p, a0, a1, Y, reach, 2.3, 2.0, 1)
    with p.into('detail_yard'):
        tx, ty = .95, Y + .75
        p.box('timber', (tx, ty, .82), (1.2, .55, .06), bevel=.01, uv='local')
        for dx in (-.52, .52):
            for dy in (-.2, .2):
                p.box('timber', (tx + dx, ty + dy, .4), (.06, .06, .8), bevel=0, uv='local')
        p.box('timber', (tx, ty, .2), (1.1, .46, .04), bevel=0, uv='local')
        for k, dx in enumerate((-.38, .02, .38)):
            kit.pot(p, (tx + dx, ty, .85), .45 + k * .06, 'flowers' if k != 1 else 'tree', ('flower_red', 'flower_white', 'flower_pink'))
        kit.basket(p, (tx - .3, ty, .22), .18, .16, linen=False)
        kit.barrel(p, (1.55, Y + 1.35, 0), .28, .72)
        kit.basket(p, (-.05, Y + 1.0, 0), .22, .24)
        kit.pot(p, (-1.25, Y + .45, 0), .85, 'flowers', ('flower_red', 'flower_white'))
        p.box('timber', (2.6, Y + .35, .25), (.9, .34, .38), bevel=.015, uv='local')
        for k in range(6):
            p.sphere(('leaf', 'leaf_light')[k % 2], (2.22 + k * .15, Y + .35, .5), .09, 1)
            p.sphere(('flower_white', 'flower_pink')[k % 2], (2.22 + k * .15, Y + .43, .58), .045, 1)
    with p.into('detail_laundry'):
        kit.laundry(p, (a0 + .12, Y + reach - .16, 1.85), (a1 - .12, Y + reach - .16, 1.85),
                    [('linen', .45, .6), ('linen', .4, .52), ('cloth_rose', .3, .4), ('linen', .38, .5)], .08)
    with p.into('detail_planters'):
        kit.pot(p, (-.95, -Y - .4, 0), .8, 'flowers', ('flower_red', 'flower_white', 'flower_pink'))
        kit.pot(p, (.35, -Y - .42, 0), .9, 'flowers', ('flower_white', 'flower_pink'))
        kit.pot(p, (-3.55, -Y - .45, 0), 1.0, 'tree')
        kit.pot(p, (3.05, -Y - .45, 0), .9, 'tree')
        kit.pot(p, (-X - .4, .9, 0), .8, 'flowers', ('flower_orange', 'flower_white'))
    with p.into('detail_vines'):
        kit.climber(p, (X + .04, -Y + .4, .38), 2.3, (1, 0), flowers=('flower_pink', 'flower_white'), bloom=.4)
        kit.climber(p, (-X - .04, Y - .4, .38), 2.2, (-1, 0), flowers=('flower_white',), bloom=.3)
    # Beside it, a tall plank gate between stone piers under a little tiled pergola, closing a courtyard.
    with p.into('detail_garden_gate'):
        gy = -Y + .15
        for x0, x1 in ((X, X + .42), (X + 1.88, X + 2.3)):
            p.box('stone', ((x0 + x1) / 2, gy, 1.05), (x1 - x0, .42, 2.1), bevel=.02, uv='world')
            p.box('stone', ((x0 + x1) / 2, gy, 2.15), (x1 - x0 + .08, .5, .1), bevel=.015, uv=('blocks', 0))
        p.box('stone', (X + 2.25, gy + .85, .8), (.32, 1.4, 1.6), bevel=.02, uv='world')
        p.box('stone', (X + 2.25, gy + .85, 1.64), (.38, 1.46, .08), bevel=.012, uv=('blocks', 0))
        lo, hi = X + .44, X + 1.86
        leaf = (hi - lo) / 2
        for side in range(2):
            l0 = lo + side * leaf
            boards = 4
            for k in range(boards):
                x = l0 + leaf * (k + .5) / boards
                top = 1.85 + .08 * math.sin(math.pi * (k + .5) / boards + side * 0)
                p.box('timber', (x, gy, .06 + (top - .06) / 2), (leaf / boards - .012, .05, top - .06), bevel=.006, uv='local')
            for z in (.45, 1.5):
                p.box('timber', (l0 + leaf / 2, gy - .04, z), (leaf - .06, .03, .1), bevel=0, uv='local')
                p.box('iron', (l0 + (leaf * .3 if side == 0 else leaf * .7), gy - .06, z), (leaf * .55, .012, .035), bevel=0, uv='flat')
            p.box('timber', (l0 + leaf / 2, gy - .04, .97), (math.hypot(leaf - .1, 1.0), .03, .08), (0, (1 if side else -1) * math.atan2(1.0, leaf - .1), 0), 0, 'local')
        p.sphere('iron', (X + 1.15 - .05, gy - .07, 1.0), .03, 1)
        p.sphere('iron', (X + 1.15 + .05, gy - .07, 1.0), .03, 1)
        for x in (X + .2, X + 2.1):
            p.beam('timber', (x, gy - .55, 2.25), (x, gy + .5, 2.25), .1, .12)
        kit.slope_courses(p, (X + 1.35, gy - .55, 2.32), (1, 0, 0), Vector((0, 1.0, .35)).normalized(), 1.1, 2.15, 2.15)
        kit.eave_tiles(p, (X + 1.35, gy - .55, 2.32), (1, 0, 0), Vector((0, 1.0, .35)).normalized(), 2.15)
        kit.ridge_caps(p, (X + .25, gy + .5, 2.7), (X + 2.45, gy + .5, 2.7), 'ridge', .08, .4)
        kit.climber(p, (X + .21, gy - .23, .1), 2.3, (0, -1), spread=.18, flowers=('flower_pink', 'flower_pink', 'flower_white'), bloom=.45)
        kit.climber(p, (X + 2.09, gy - .23, .1), 2.2, (0, -1), spread=.18, flowers=('flower_pink', 'flower_white'), bloom=.4)


# --- H: Eaveside terrace pair --------------------------------------------------------------------------------------
EAVESIDE_PALETTE = {'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                    'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal',
                    'plaster_2': 'seaside_plaster_ochre', 'roof_2': 'seaside_roof_teal', 'ridge_2': 'seaside_roof_terracotta',
                    'shutter_2': 'seaside_shutter_teal'}


def eaveside(p):
    """Two joined homes as one background cluster. West: three limewashed storeys and an attic under a steep terracotta
    gable facing the street, oak floor beams, quoins, an arched door. East: two ochre storeys under a hipped deep-teal
    roof with terracotta hips and a dormer, a door under a tiled hood, a bench. Each home paints its own plaster, roof,
    ridge and shutters (the `_2` slots are the east home's). Behind: a wash-house lean-to, a sink and a washing line."""
    rng = p.rng
    # West home.
    AX0, AX1, Y0, Y1 = -4.4, -.4, -2.6, 2.6
    floors = (0, 2.9, 5.6)
    EA = 8.2
    aw, ah = .75, 1.2
    for k, z0 in enumerate(floors):
        z1 = floors[k + 1] if k + 1 < len(floors) else EA
        zc = z0 + 1.45 if k else 1.6
        front = [(x - aw / 2 - AX0, x + aw / 2 - AX0, zc - ah / 2, zc + ah / 2) for x in ((-3.35, -1.5) if k else (-1.55,))]
        if k == 0:
            front.append((-3.35 - .475 - AX0, -3.35 + .475 - AX0, 0, 2.4))
        kit.wall(p, 'plaster', (AX0, Y0), (AX1, Y0), z0, z1, .24, front)
        back = [(AX1 - x - aw / 2, AX1 - x + aw / 2, zc - ah / 2, zc + ah / 2) for x in ((-3.35, -1.5) if k else (-3.5,))]
        if k == 0:
            back.append((AX1 + 2.3 - .45, AX1 + 2.3 + .45, 0, 2.15))  # the back door at x = -2.3
        kit.wall(p, 'plaster', (AX1, Y1), (AX0, Y1), z0, z1, .24, back)
        kit.wall(p, 'plaster', (AX0, Y1), (AX0, Y0), z0, z1, .24, [(Y1 - .3 - .25, Y1 - .3 + .25, zc - .4, zc + .4)] if k else [])
        kit.wall(p, 'plaster', (AX1, Y0), (AX1, Y1), z0, z1, .24, [(.2 - Y0 - .25, .2 - Y0 + .25, zc - .4, zc + .4)] if k == 2 else [])
        if k:
            for a, b, f in SIDES(AX0, AX1, Y0, Y1):
                kit.band(p, 'timber', a, b, z0 - .06, .24, .05, f)
            for x in (-3.35, -1.5):
                kit.window(p, (x, Y0, zc), aw, ah, (0, -1), shutters='both' if (k, x) == (2, -1.5) else 'open',
                           flowers=('flower_white', 'flower_red', 'flower_pink'))
                kit.window(p, (x, Y1, zc), aw, ah, (0, 1), shutters='open', flowers=('flower_white', 'flower_pink'))
            kit.window(p, (AX0, .3, zc), .5, .8, (-1, 0), shutters=None, box=False, bars=(1, 1))
    kit.window(p, (AX1, .2, floors[2] + 1.45), .5, .8, (1, 0), shutters=None, box=False, bars=(1, 1))
    kit.band(p, 'stone', (AX0, Y0), (AX1, Y0), 0, .36, .05, (0, -1))
    kit.band(p, 'stone', (AX0, Y1), (AX0, Y0), 0, .36, .05, (-1, 0))
    kit.band(p, 'stone', (AX1, Y1), (AX0, Y1), 0, .36, .05, (0, 1))
    for corner, faces in corners(AX0, AX1, Y0, Y1):
        kit.quoins(p, corner, faces, .36, EA - .25, course=.33, long=.48, short=.28, proud=.03)
    kit.door(p, -3.35, Y0, .95, 2.4, (0, -1), style='plank', arch=True)
    kit.window(p, (-1.55, Y0, 1.6), aw, ah, (0, -1), shutters='open', flowers=('flower_red', 'flower_white'))
    kit.window(p, (-3.5, Y1, 1.6), aw, 1.2, (0, 1), shutters='open', box=False)
    kit.door(p, -2.3, Y1, .9, 2.15, (0, 1), style='plank', hood='canopy')
    kit.lantern(p, (-2.4, Y0, 2.1), (0, -1))
    for a, b, f in SIDES(AX0, AX1, Y0, Y1):
        kit.band(p, 'timber', a, b, EA - .2, .22, .05, f)
    with p.turned(-90):
        ridge, z_eave, eave = kit.gable_roof(p, Y0, Y1, AX0, AX1, EA, 50, eave=.32, verge=.28)
        t = math.tan(math.radians(50))
        collar = ridge - .35 * t - .25
        for style in ('stone', 'brick'):
            with p.into('alt_chimney_' + style):
                kit.chimney(p, -1.9, -2.05, collar - 1.0, ridge + .9, style=style, collar=collar, width=.62, depth=.55)
    for y, out in ((Y0, -1), (Y1, 1)):
        kit.gable(p, 'plaster', 'y', y, AX0, AX1, EA, ridge - .12, out, .24)
    kit.window(p, (-2.4, Y0, EA + .95), .5, .62, (0, -1), recess=-.04, shutters='open', bars=(1, 1), flowers=('flower_white', 'flower_red'))
    kit.window(p, (-2.4, Y1, EA + .9), .45, .55, (0, 1), recess=-.04, shutters=None, box=False, bars=(1, 1))
    for y, wall_out in ((Y0 + .12, (eave - .08, 0)), (Y1 - .12, (eave - .08, 0))):
        kit.downpipe(p, (AX0 - eave + .02, y, z_eave - .08), 0, wall_out, swan=.32)
    # East home, joined to the west home's east wall.
    BX0, BX1, BY1 = AX1, 4.2, 1.8
    EB, FB = 5.5, 2.8
    bw, bh = .8, 1.15
    kit.wall(p, 'plaster_2', (BX0, Y0), (BX1, Y0), 0, FB, .24, [(1.0 - BX0 - .475, 1.0 - BX0 + .475, 0, 2.2), (3.0 - BX0 - .425, 3.0 - BX0 + .425, 1.0, 2.2)])
    kit.wall(p, 'plaster_2', (BX0, Y0), (BX1, Y0), FB, EB, .24, [(x - BX0 - bw / 2, x - BX0 + bw / 2, 3.55, 3.55 + bh) for x in (.9, 3.0)])
    kit.wall(p, 'plaster_2', (BX1, Y0), (BX1, BY1), 0, EB, .24, [(-.4 - Y0 - .375, -.4 - Y0 + .375, 1.05, 2.15), (-.4 - Y0 - .375, -.4 - Y0 + .375, 3.55, 4.65)])
    kit.wall(p, 'plaster_2', (BX1, BY1), (BX0, BY1), 0, EB, .24, [(BX1 - 3.2 - .425, BX1 - 3.2 + .425, 0, 2.1)] +
             [(BX1 - x - bw / 2, BX1 - x + bw / 2, 3.55, 3.55 + bh) for x in (1.0, 3.0)])
    for a, b, f in (((BX0, Y0), (BX1, Y0), (0, -1)), ((BX1, Y0), (BX1, BY1), (1, 0)), ((BX1, BY1), (BX0, BY1), (0, 1))):
        kit.band(p, 'stone', a, b, 0, .36, .05, f)
        kit.band(p, 'stone', a, b, FB - .08, .16, .05, f)
        kit.band(p, 'stone', a, b, EB - .2, .14, .06, f)
    for corner, faces in (((BX1, Y0), ((0, -1), (1, 0))), ((BX1, BY1), ((0, 1), (1, 0)))):
        kit.quoins(p, corner, faces, .36, EB - .2, course=.33, long=.46, short=.28, proud=.03)
    kit.door(p, 1.0, Y0, .95, 2.2, (0, -1), style='plank', leaf_mat='shutter_2', hood='canopy', canopy_mat='ridge_2')
    kit.window(p, (3.0, Y0, 1.6), .85, 1.2, (0, -1), shutters='open', shutter_mat='shutter_2', flowers=('flower_red', 'flower_white', 'flower_orange'))
    for x in (.9, 3.0):
        kit.window(p, (x, Y0, 3.55 + bh / 2), bw, bh, (0, -1), shutters='open', shutter_mat='shutter_2', flowers=('flower_red', 'flower_white', 'flower_pink'))
    for z in (1.6, 4.1):
        kit.window(p, (BX1, -.4, z), .75, 1.1, (1, 0), shutters='open', shutter_mat='shutter_2', box=z > 3, flowers=('flower_white', 'flower_pink'))
    for x in (1.0, 3.0):
        kit.window(p, (x, BY1, 3.55 + bh / 2), bw, bh, (0, 1), shutters='open', shutter_mat='shutter_2', box=x > 2, flowers=('flower_white', 'flower_red'))
    kit.door(p, 3.2, BY1, .85, 2.1, (0, 1), style='plank', leaf_mat='shutter_2')
    kit.lantern(p, (1.85, Y0, 2.1), (0, -1))
    kit.lantern(p, (2.45, BY1, 2.0), (0, 1))
    ridge_b, ends_b, z_eave_b = kit.hip_roof(p, BX0 - .1, BX1 + .1, Y0 - .1, BY1 + .1, EB + .05, 34, eave=.4, roof_mat='roof_2', cap_mat='ridge_2')
    kit.dormer(p, 2.1, Y0 - .1 - .4, z_eave_b, 34, -1, in_from_eave=.45, ridge_run=(BY1 - Y0) / 2 + .5, width=.9, height=.7,
               window_w=.45, window_h=.5, shutters=None, box=False, wall_mat='plaster_2', shutter_mat='shutter_2',
               roof_mat='roof_2', cap_mat='ridge_2')
    cy = (Y0 + BY1) / 2
    for style in ('stone', 'brick'):
        with p.into('alt_chimney_' + style):
            kit.chimney(p, 2.2, cy + .35, ridge_b - 1.2, ridge_b + .85, style=style, collar=ridge_b - .35, width=.6, depth=.5)
    g = .4 + .1 + .04
    for x, y, wall_out in ((BX1 + .1, Y0 - g, (-.1, g - .1)), (BX1 + .1, BY1 + g, (-.1, -(g - .1)))):
        kit.downpipe(p, (x - .1, y, z_eave_b - .08), 0, wall_out, swan=.32)
    # Behind the east home: a wash house with its own door, a stone sink, a washing line on posts.
    kit.lean_to_shed(p, BX0 + .05, 2.2, BY1, 1.3, FB - .12, 2.25, 1, wall_mat='plaster_2', roof_mat='ridge_2', door_x=1.45,
                     shutter_mat='shutter_2')
    with p.into('detail_yard'):
        sx, sy = 3.55, BY1 + .4
        p.box('stone', (sx, sy, .4), (.9, .55, .8), bevel=.03, uv=('blocks', 0))
        p.box('water', (sx, sy, .77), (.72, .38, .05), bevel=0, uv='flat')
        p.cylinder('iron', (sx, BY1 + .05, 1.15), (sx, sy, 1.15), .022, 6, uv='flat')
        kit.barrel(p, (2.55, BY1 + .45, 0), .27, .7)
        kit.crate(p, (2.55, BY1 + 1.05, 0), (.45, .38, .3), .25)
        kit.pot(p, (-1.0, Y1 + .45, 0), .9, 'flowers', ('flower_red', 'flower_white'))
        kit.pot(p, (-3.9, Y1 + .45, 0), 1.0, 'tree')
    with p.into('detail_laundry'):
        for x in (2.7, 4.3):
            p.beam('timber', (x, BY1 + 2.0, 0), (x, BY1 + 2.0, 2.1), .08, .08, up=(0, 1, 0))
            p.beam('timber', (x - .3, BY1 + 2.0, 2.05), (x + .3, BY1 + 2.0, 2.05), .06, .06)
        kit.laundry(p, (2.7, BY1 + 2.0, 2.0), (4.3, BY1 + 2.0, 2.0), [('linen', .4, .55), ('cloth_blue', .32, .45), ('linen', .4, .5)], .08)
        kit.basket(p, (3.5, BY1 + 1.6, 0), .2, .22)
    with p.into('detail_planters'):
        kit.bench(p, (3.0, Y0 - .3, 0), (0, -1))
        kit.pot(p, (-4.0, Y0 - .5, 0), 1.1, 'tree')
        kit.pot(p, (-2.55, Y0 - .38, 0), .7, 'flowers', ('flower_white', 'flower_pink'))
        kit.pot(p, (-.75, Y0 - .45, 0), .9, 'flowers', ('flower_red', 'flower_white'))
        kit.pot(p, (.25, Y0 - .42, 0), .75, 'flowers', ('flower_white', 'flower_orange'))
        kit.barrel(p, (1.95, Y0 - .42, 0), .25, .65)
        kit.pot(p, (BX1 + .45, .6, 0), .9, 'tree')
    with p.into('detail_vines'):
        kit.climber(p, (AX0 - .04, Y0 + .4, .36), 6.0, (-1, 0), flowers=('flower_white', 'flower_white', 'flower_pink'), bloom=.4)
        kit.climber(p, (BX0 + .25, Y0 - .04, .36), 5.0, (0, -1), spread=.22, flowers=('flower_white', 'flower_pink'), bloom=.4)
        kit.climber(p, (BX1 + .04, Y0 + .35, .36), 4.6, (1, 0), flowers=('flower_white',), bloom=.3)
        kit.climber(p, (AX1 - .3, Y1 + .04, .36), 5.2, (0, 1), spread=.22, flowers=('flower_white', 'flower_pink'), bloom=.35)


ASSETS = {
    'seaside-lantern-row-house': (lantern_row, LANTERN_PALETTE, 12004, 'D-lantern-row-lodging-house-v2.png'),
    'seaside-shingle-court-cottage': (shingle_court, SHINGLE_PALETTE, 12007, 'G-shingle-court-cottage.png'),
    'seaside-eaveside-terrace': (eaveside, EAVESIDE_PALETTE, 12008, 'H-eaveside-terrace-pair-v2.png'),
}

if __name__ == '__main__':
    chosen, out = kit.selected(list(ASSETS))
    for asset in chosen:
        make, palette, seed, reference = ASSETS[asset]
        root = kit.begin(asset, palette)
        parts = kit.Parts(seed)
        make(parts)
        parts.finish(root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, 'author_houses_dgh.py', palette, {'reference': REF + reference})
