"""Guarded one-time authoring of two modular seaside background houses after docs/concept/v0.72/background-houses.md:
F, the Rosewash lane house, and E, the Saltwind apartment house.

    blender --background --factory-startup --python art/source/world/seaside-houses/v1/author_houses.py -- [ids]
    ... -- --draft .cache/seaside-houses/drafts [ids]     (review drafts outside art/source)

Refuses an existing master. After authoring, each model.blend is the editable authority; export only with
scripts/world-art.sh build <id>. Fronts face Blender -Y (Godot +Z); the pivot is the footprint centre at ground.
"""
import math
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import house_kit as kit  # noqa: E402
from mathutils import Vector  # noqa: E402

REF = 'docs/concept/v0.72/art/background-houses/'


# --- F: Rosewash lane house ----------------------------------------------------------------------------------------
ROSEWASH_PALETTE = {'plaster': 'seaside_plaster_rose', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
                    'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def rosewash(p):
    """A compact two-storey family home with a loft: a limestone ground floor, a jettied rose-limewashed upper floor on
    an oak bressummer, an off-centre front dormer, a steep pan-tiled gable roof and a brick chimney. Behind: a tiled
    porch over the kitchen door with a little gate, a log store and a washing line."""
    X, Y, J = 2.7, 2.3, .16
    G, E = 2.9, 5.55
    rng = p.rng
    # Ground storey: dressed limestone with the front door, a shuttered window and the side and back openings.
    door_x, door_w, door_h = -1.45, .95, 2.2
    win_x, win_w, win_h, win_z = 1.0, .9, 1.2, 1.55
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .26, [(door_x - door_w / 2 + X, door_x + door_w / 2 + X, 0, door_h),
                                                          (win_x - win_w / 2 + X, win_x + win_w / 2 + X, win_z - win_h / 2, win_z + win_h / 2)])
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, G, .26, [(Y + .1 - .35, Y + .1 + .35, 1.1, 2.05)])
    back_door_x, pantry_x = 1.35, -1.2
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, G, .26, [(X - back_door_x - .45, X - back_door_x + .45, 0, 2.15), (X - pantry_x - .3, X - pantry_x + .3, 1.1, 1.9)])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, G, .26, [(Y - .7 - .32, Y - .7 + .32, 1.1, 2.0)])
    for a, b, f in (((-X, -Y), (X, -Y), (0, -1)), ((X, -Y), (X, Y), (1, 0)), ((X, Y), (-X, Y), (0, 1)), ((-X, Y), (-X, -Y), (-1, 0))):
        kit.band(p, 'stone', a, b, 0, .36, .05, f)
    for corner, faces in (((-X, -Y), ((0, -1), (-1, 0))), ((X, -Y), ((0, -1), (1, 0))), ((X, Y), ((0, 1), (1, 0))), ((-X, Y), ((0, 1), (-1, 0)))):
        kit.quoins(p, corner, faces, .36, G, course=.32, long=.46, short=.28, proud=.03)
    kit.door(p, door_x, -Y, door_w, door_h, (0, -1), style='plank', leaf_mat='shutter')
    kit.window(p, (win_x, -Y, win_z), win_w, win_h, (0, -1), shutters='open', box=False, sill_pots=2)
    kit.window(p, (X, .1, 1.575), .7, .95, (1, 0), shutters=None, box=False, sill_pots=2)
    kit.window(p, (-X, .7, 1.55), .64, .9, (-1, 0), shutters=None, box=False)
    kit.window(p, (pantry_x, Y, 1.5), .6, .8, (0, 1), shutters=None, box=False)
    kit.door(p, back_door_x, Y, .9, 2.15, (0, 1), style='plank', leaf_mat='shutter')
    kit.lantern(p, (-.62, -Y, 2.05), (0, -1))
    kit.lantern(p, (.62, Y, 2.0), (0, 1))
    # The jetty: an oak bressummer on carved brackets, joist ends, and a timber band round the other three sides.
    p.box('timber', (0, -Y - J / 2 + .02, G + .13), (2 * X + .22, J + .3, .3), bevel=.02, uv='local')
    for x in (-X + .12, -.2, X - .12):
        p.beam('timber', (x, -Y - .02, G - .62), (x, -Y - J - .06, G - .02), .12, .12, up=(0, -1, 0))
        p.box('timber', (x, -Y - .06, G - .02), (.14, .16, .1), bevel=.01, uv='local')
    for k in range(13):
        x = -X + .3 + k * (2 * X - .6) / 12
        p.box('timber', (x, -Y - J - .09, G - .04), (.1, .12, .1), bevel=.012, uv='local')
    for a, b, f in (((X, -Y - J), (X, Y), (1, 0)), ((X, Y), (-X, Y), (0, 1)), ((-X, Y), (-X, -Y - J), (-1, 0))):
        kit.band(p, 'timber', a, b, G - .02, .26, .04, f)
    # Upper storey: rose limewash, oversailing the front, with timber corner posts.
    Yf = -Y - J
    up_w, up_h, up_z = .85, 1.15, 4.25
    kit.wall(p, 'plaster', (-X, Yf), (X, Yf), G + .24, E, .22, [(x - up_w / 2 + X, x + up_w / 2 + X, up_z - up_h / 2, up_z + up_h / 2) for x in (-1.2, 1.2)])
    kit.wall(p, 'plaster', (X, Yf), (X, Y), G + .24, E, .22, [(-.5 - Yf - .375, -.5 - Yf + .375, 3.7, 4.75)])
    kit.wall(p, 'plaster', (X, Y), (-X, Y), G + .24, E, .22, [(X + 1.0 - up_w / 2, X + 1.0 + up_w / 2, up_z - up_h / 2, up_z + up_h / 2)])
    kit.wall(p, 'plaster', (-X, Y), (-X, Yf), G + .24, E, .22, [(Y - .3 - .375, Y - .3 + .375, 3.7, 4.75)])
    for x, y in ((-X, Yf), (X, Yf)):
        # Corner posts stop under the eave so they never show through the tiles.
        p.box('timber', (x, y, (G + .2 + E - .14) / 2), (.18, .18, E - .14 - G - .2), bevel=.015, uv='local')
    for x in (-1.2, 1.2):
        kit.window(p, (x, Yf, up_z), up_w, up_h, (0, -1), shutters='both' if x > 0 else 'open', flowers=('flower_white', 'flower_orange', 'flower_pink'))
    kit.window(p, (X, -.5, 4.225), .75, 1.05, (1, 0), shutters=None, box=True, flowers=('flower_white', 'flower_pink'))
    kit.window(p, (-1.0, Y, up_z), up_w, up_h, (0, 1), shutters='open', flowers=('flower_red', 'flower_white'))
    kit.window(p, (-X, .3, 4.225), .75, 1.05, (-1, 0), shutters='open', box=False)
    # Roof, gables, dormers and the attic vent.
    ridge, z_eave, eave = kit.gable_roof(p, -X, X, Yf, Y, E, 47, eave=.38, verge=.3)
    for x, out in ((-X, -1), (X, 1)):
        kit.gable(p, 'plaster', 'x', x, Yf, Y, E, ridge - .12, out, .22)
        p.box('timber', (x + out * .03, (Yf + Y) / 2, E - .07), (.08, Y - Yf, .12), bevel=.01, uv='local')
        vent_z = E + 1.15
        p.pane('window_pane', (x + out * .01, (Yf + Y) / 2, vent_z), .36, .46, (out, 0), -.06)
        p.box('timber', (x + out * .04, (Yf + Y) / 2, vent_z), (.06, .5, .58), bevel=.01, uv='local')
        for k in range(4):
            p.box('timber', (x + out * .07, (Yf + Y) / 2, vent_z - .17 + k * .11), (.04, .38, .04), (0, out * .5, 0), .004, 'local')
    t = math.tan(math.radians(47))
    run = (Y - Yf) / 2 + eave
    kit.dormer(p, -.55, Yf - eave, z_eave, 47, -1, in_from_eave=.8, ridge_run=run, width=1.25, height=1.0, window_w=.58,
               window_h=.68, flowers=('flower_white', 'flower_orange'))
    kit.dormer(p, .95, Y + eave, z_eave, 47, 1, in_from_eave=.85, ridge_run=run, width=1.0, height=.9, window_w=.5,
               window_h=.58, shutters=None, box=False)
    # Chimney alternatives: painted brick (the concept) or dressed stone.
    cy = .3
    collar = ridge - cy * t - .25
    for style in ('brick', 'stone'):
        with p.into('alt_chimney_' + style):
            kit.chimney(p, -1.85, cy, collar - 1.2, ridge + .95, style=style, collar=collar)
    # Gutters' downpipes at all four corners.
    for x, y, wall_out in ((-X + .12, Yf - eave + .02, (0, eave - .08)), (X - .12, Yf - eave + .02, (0, eave - .08)),
                           (-X + .12, Y + eave - .02, (0, -(eave - .08))), (X - .12, Y + eave - .02, (0, -(eave - .08)))):
        kit.downpipe(p, (x, y, z_eave - .08), 0, wall_out, swan=.35)
    # Behind: a tiled porch over the kitchen door, closed to the east with a framed board wall, a little gate west.
    x0, x1, reach = .25, X, 1.35
    kit.lean_to(p, x0, x1, Y, reach, G - .1, 2.25, 1, verge_right=False)
    p.box('stone', (X - .08, Y + reach / 2, .3), (.2, reach, .6), bevel=.02, uv='world')
    for k in range(int(reach / .17)):
        y = Y + .1 + k * .17
        top = G - .1 - (G - .1 - 2.25) * (y - Y) / reach - .04
        p.box('timber', (X - .06, y, (.6 + top) / 2), (.05, .16, top - .6), bevel=.006, uv='local')
    p.beam('timber', (X - .02, Y + .05, .62), (X - .02, Y + reach - .1, 2.1), .08, .08, up=(1, 0, 0))
    p.box('timber', (X - .02, Y + reach / 2, 1.35), (.09, reach - .1, .09), bevel=.01, uv='local')
    with p.into('detail_yard'):
        for k in range(6):
            y = Y + .12 + k * .2
            p.box('timber', (x0 + .1, y, .55), (.04, .16, .9), bevel=.006, uv='local')
        p.box('timber', (x0 + .1, Y + .65, .35), (.05, 1.15, .08), bevel=.008, uv='local')
        p.box('timber', (x0 + .1, Y + .65, .82), (.05, 1.15, .08), bevel=.008, uv='local')
        p.box('timber', (x0 + .1, Y + .65, .58), (.05, 1.2, .07), (math.radians(22), 0, 0), .006, 'local')
        kit.pot(p, (1.95, Y + .55, 0), .9, 'flowers', ('flower_red', 'flower_white'))
        kit.pot(p, (2.35, Y + 1.0, 0), .75, 'tree')
        kit.basket(p, (.75, Y + .55, 0))
        kit.barrel(p, (X + .45, .95, 0), .28, .72)
        kit.crate(p, (X + .45, 1.6, 0), (.45, .38, .3), .2)
        kit.pot(p, (X + .5, .25, 0), .8, 'flowers', ('flower_orange', 'flower_white'))
    with p.into('detail_wood_store'):
        kit.log_store(p, -2.55, -1.4, Y, .72, 1.35, 1)
    with p.into('detail_laundry'):
        pole = Vector((-2.35, Y + 1.75, 0))
        p.beam('timber', pole, pole + Vector((0, 0, 2.15)), .09, .09, up=(0, 1, 0))
        p.beam('timber', pole + Vector((0, -.35, 2.1)), pole + Vector((0, .35, 2.1)), .07, .07)
        kit.laundry(p, (x0 + .08, Y + reach - .1, 2.05), (pole.x, pole.y - .3, 2.1),
                    [('linen', .55, .7), ('cloth_blue', .4, .5), ('linen', .5, .65), ('cloth_rose', .32, .42)])
        kit.basket(p, (-1.0, Y + 1.35, 0))
    with p.into('detail_planters'):
        kit.pot(p, (-2.3, -Y - .42, 0), 1.0, 'cone')
        kit.pot(p, (-.68, -Y - .4, 0), .9, 'flowers', ('flower_white', 'flower_pink', 'flower_red'))
        kit.pot(p, (2.25, -Y - .4, 0), .7, 'flowers', ('flower_orange', 'flower_white'))
        kit.pot(p, (X + .45, -1.6, 0), 1.05, 'tree')
    with p.into('detail_vines'):
        kit.climber(p, (-X - .04, -Y + .3, .35), 4.6, (-1, 0), flowers=('flower_white', 'flower_white', 'flower_pink'))
        kit.climber(p, (-X - .04, Y - .35, .35), 3.4, (-1, 0), flowers=('flower_white',))
        kit.climber(p, (X + .04, -Y + .5, .35), 2.3, (1, 0), flowers=('flower_pink', 'flower_white'), bloom=.2)


# --- E: Saltwind apartment house -----------------------------------------------------------------------------------
SALTWIND_PALETTE = {'plaster': 'seaside_plaster_ochre', 'roof': 'seaside_roof_teal', 'ridge': 'seaside_roof_terracotta',
                    'stone': 'seaside_stone_limestone', 'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}


def saltwind(p):
    """A broad three-storey apartment house: three window bays, a dressed limestone ground floor, ochre limewash above
    with quoins and string courses, a low hipped deep-teal roof with terracotta hips and two brick chimneys, a
    panelled front door under a stone hood. Behind: an arched kitchen door and a tiled laundry alcove."""
    X, Y = 4.3, 3.0
    G, F2, E = 3.1, 6.1, 8.95
    bays = (-2.75, 0.0, 2.75)
    rng = p.rng
    gw, gh, gz = .95, 1.45, 1.6
    door_w, door_h = 1.1, 2.45
    front_openings = [(x - gw / 2 + X, x + gw / 2 + X, gz - gh / 2, gz + gh / 2) for x in (bays[0], bays[2])]
    front_openings.append((-door_w / 2 + X, door_w / 2 + X, 0, door_h))
    kit.wall(p, 'stone', (-X, -Y), (X, -Y), 0, G, .28, front_openings)
    side_w, side_h, side_y = .55, 1.0, 1.4
    kit.wall(p, 'stone', (X, -Y), (X, Y), 0, G, .28, [(side_y + Y - side_w / 2, side_y + Y + side_w / 2, 1.2, 2.2)])
    back_door_x, back_win_x = -2.6, 1.15
    kit.wall(p, 'stone', (X, Y), (-X, Y), 0, G, .28, [(X - back_door_x - .5, X - back_door_x + .5, 0, 2.45), (X - back_win_x - .45, X - back_win_x + .45, .95, 2.25)])
    kit.wall(p, 'stone', (-X, Y), (-X, -Y), 0, G, .28, [(Y - side_y - side_w / 2, Y - side_y + side_w / 2, 1.2, 2.2)])
    # Upper floors in limewash, each with three bays front and back and a narrow window in each side.
    uw, uh = .95, 1.5
    floors = ((G + .65 + uh / 2, True), (F2 + .55 + uh / 2 - .05, False))
    for z0, z1 in ((G, F2), (F2, E)):
        zc = floors[0][0] if z0 == G else floors[1][0]
        kit.wall(p, 'plaster', (-X, -Y), (X, -Y), z0, z1, .26, [(x - uw / 2 + X, x + uw / 2 + X, zc - uh / 2, zc + uh / 2) for x in bays])
        kit.wall(p, 'plaster', (X, Y), (-X, Y), z0, z1, .26, [(X - x - uw / 2, X - x + uw / 2, zc - uh / 2, zc + uh / 2) for x in bays])
        sz = zc - .1
        kit.wall(p, 'plaster', (X, -Y), (X, Y), z0, z1, .26, [(side_y + Y - side_w / 2, side_y + Y + side_w / 2, sz - side_h / 2, sz + side_h / 2)])
        kit.wall(p, 'plaster', (-X, Y), (-X, -Y), z0, z1, .26, [(Y - side_y - side_w / 2, Y - side_y + side_w / 2, sz - side_h / 2, sz + side_h / 2)])
    sides = (((-X, -Y), (X, -Y), (0, -1)), ((X, -Y), (X, Y), (1, 0)), ((X, Y), (-X, Y), (0, 1)), ((-X, Y), (-X, -Y), (-1, 0)))
    for a, b, f in sides:
        kit.band(p, 'stone', a, b, 0, .45, .06, f)
        kit.band(p, 'stone', a, b, G - .1, .2, .07, f)
        kit.band(p, 'stone', a, b, F2 - .08, .16, .06, f)
        kit.band(p, 'stone', a, b, E - .22, .14, .06, f)
        kit.band(p, 'stone', a, b, E - .09, .12, .13, f)
    for corner, faces in (((-X, -Y), ((0, -1), (-1, 0))), ((X, -Y), ((0, -1), (1, 0))), ((X, Y), ((0, 1), (1, 0))), ((-X, Y), ((0, 1), (-1, 0)))):
        kit.quoins(p, corner, faces, G + .1, E - .22, course=.34, long=.55, short=.32, proud=.035)
    # Worn limewash showing brick, as in the concept, on wall between the openings.
    for at, facing, rows in (((-1.4, -Y, 5.55), (0, -1), 3), ((1.35, -Y, 7.0), (0, -1), 2), ((-3.75, -Y, 4.1), (0, -1), 2),
                             ((X, -1.5, 4.6), (1, 0), 3), ((X, .1, 7.75), (1, 0), 2), ((-1.3, Y, 7.4), (0, 1), 3)):
        kit.worn_patch(p, at, facing, rows)
    # Ground floor: shuttered windows either side of a panelled door under a stone hood, the lantern by the door.
    for x in (bays[0], bays[2]):
        kit.window(p, (x, -Y, gz), gw, gh, (0, -1), shutters='open', box=True, flowers=('flower_red', 'flower_white', 'flower_orange'))
    for style, mat in (('oak', 'timber'), ('painted', 'shutter')):
        with p.into('alt_front_door_' + style):
            kit.door(p, 0, -Y, door_w, door_h, (0, -1), style='panel', leaf_mat=mat, step=False, fanlight=True, hood='cornice')
    p.box('stone', (0, -Y - .26, .07), (door_w + .8, .52, .14), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, -Y - .14, .21), (door_w + .5, .3, .14), bevel=.02, uv=('blocks', 0))
    kit.lantern(p, (-1.0, -Y, 2.25), (0, -1))
    # Upper windows: shutters and boxes on the first floor, shutters on the second; one window can be drawn.
    for z, boxed in floors:
        for x in bays:
            kit.window(p, (x, -Y, z), uw, uh, (0, -1), shutters='both' if (x, boxed) in ((2.75, False), (-2.75, True)) else 'open',
                       box=boxed or x == 0, flowers=('flower_red', 'flower_white', 'flower_pink', 'flower_orange'))
            kit.window(p, (x, Y, z), uw, uh, (0, 1), shutters='open', box=boxed and x != 0, flowers=('flower_white', 'flower_pink'))
        sz = z - .1
        kit.window(p, (X, side_y, sz), side_w, side_h, (1, 0), shutters=None, box=False, bars=(1, 1))
        kit.window(p, (-X, side_y, sz), side_w, side_h, (-1, 0), shutters=None, box=False, bars=(1, 1))
    kit.window(p, (X, side_y, 1.7), side_w, side_h, (1, 0), shutters=None, box=False, bars=(1, 1))
    kit.window(p, (-X, side_y, 1.7), side_w, side_h, (-1, 0), shutters=None, box=False, bars=(1, 1))
    # Behind: an arched plank door, a window and a tiled laundry alcove.
    kit.door(p, back_door_x, Y, 1.0, 2.45, (0, 1), style='plank', leaf_mat='shutter', arch=True)
    kit.lantern(p, (-1.65, Y, 2.3), (0, 1))
    kit.window(p, (back_win_x, Y, 1.6), .9, 1.3, (0, 1), shutters=None, box=False)
    a0, a1, reach = -.85, 3.95, 1.55
    kit.lean_to(p, a0, a1, Y, reach, G - .12, 2.35, 1, mat='ridge')
    with p.into('detail_yard'):
        tx, ty = 2.75, Y + .45
        p.box('stone', (tx, ty, .42), (1.1, .62, .84), bevel=.03, uv=('blocks', 0))
        p.box('water', (tx, ty, .8), (.9, .44, .05), bevel=0, uv='flat')
        p.cylinder('iron', (tx + .25, Y + .06, 1.25), (tx + .25, Y + .4, 1.25), .025, 6, uv='flat')
        p.cylinder('iron', (tx + .25, Y + .4, 1.25), (tx + .25, Y + .4, 1.05), .022, 6, uv='flat')
        p.box('timber', (tx - .2, ty + .02, .87), (.4, .5, .04), (0, math.radians(8), 0), .006, 'local')
        kit.barrel(p, (3.55, Y + 1.1, 0), .3, .78)
        kit.basket(p, (1.75, Y + .55, 0), .24, .26)
        kit.basket(p, (2.0, Y + 1.1, 0), .2, .2, linen=False)
        kit.crate(p, (.0, Y + .45, 0), (.5, .4, .34), .1)
        kit.crate(p, (.02, Y + .45, .41), (.45, .36, .28), -.15)
        kit.pot(p, (-1.25, Y + .4, 0), .85, 'flowers', ('flower_red', 'flower_white'))
        kit.pot(p, (-3.6, Y + .5, 0), 1.05, 'tree')
    with p.into('detail_laundry'):
        kit.laundry(p, (a0 + .12, Y + reach - .15, 2.1), (a1 - .12, Y + reach - .15, 2.1),
                    [('linen', .6, .75), ('cloth_blue', .38, .55), ('linen', .55, .7), ('cloth_ochre', .4, .5), ('linen', .5, .6)])
        z = floors[1][0] + .55
        for x in (1.95, 3.55):
            p.beam('iron', (x, Y, z), (x, Y + .4, z), .03, .03)
        kit.laundry(p, (1.95, Y + .38, z), (3.55, Y + .38, z), [('linen', .4, .55), ('cloth_blue', .3, .4), ('linen', .38, .5)], .06)
    # The low hipped roof with terracotta hips, two chimneys and downpipes at every corner.
    ridge, ends, z_eave = kit.hip_roof(p, -X - .12, X + .12, -Y - .12, Y + .12, E + .05, 27, eave=.42)
    t = math.tan(math.radians(27))
    for style in ('brick', 'stone'):
        with p.into('alt_chimney_' + style):
            for cx, cy in ((-1.5, .45), (1.5, -.45)):
                collar = ridge - abs(cy) * t - .25
                kit.chimney(p, cx, cy, collar - 1.0, ridge + 1.1, style=style, collar=collar)
    g = .42 + .12 + .04
    for x, y, wall_out in ((-X - .12, -Y - g, (0, g - .1)), (X + .12, -Y - g, (0, g - .1)), (X + .12, Y + g, (0, -(g - .1))), (-X - .12, Y + g, (0, -(g - .1)))):
        kit.downpipe(p, (x + (.1 if x < 0 else -.1), y, z_eave - .08), 0, wall_out, swan=.4)
    with p.into('detail_planters'):
        kit.pot(p, (-X + .35, -Y - .55, 0), 1.15, 'tree')
        kit.pot(p, (-.95, -Y - .45, 0), .9, 'cone')
        kit.pot(p, (.95, -Y - .45, 0), .9, 'cone')
        kit.pot(p, (X - .4, -Y - .5, 0), 1.1, 'tree')
        kit.pot(p, (1.65, -Y - .38, 0), .7, 'flowers', ('flower_orange', 'flower_red', 'flower_white'))
        kit.pot(p, (X + .45, -1.4, 0), .8, 'flowers', ('flower_pink', 'flower_white'))
        p.box('timber', (X + .42, .2, .3), (.42, 1.1, .45), bevel=.015, uv='local')
        for k in range(8):
            p.sphere(('leaf', 'leaf_light')[k % 2], (X + .42 + rng.uniform(-.1, .1), -.25 + k * .13, .58), .1, 1)
            p.sphere(('flower_red', 'flower_white', 'flower_orange')[k % 3], (X + .5 + rng.uniform(-.05, .05), -.25 + k * .13, .68), .05, 1)
    with p.into('detail_vines'):
        kit.climber(p, (-X - .04, Y - .4, .45), 3.6, (-1, 0), flowers=('flower_white', 'flower_pink'))
        kit.climber(p, (X + .04, -Y + .45, .45), 2.6, (1, 0), flowers=('flower_white',), bloom=.15)


ASSETS = {
    'seaside-rosewash-house': (rosewash, ROSEWASH_PALETTE, 12007, 'F-rosewash-lane-house.png'),
    'seaside-saltwind-house': (saltwind, SALTWIND_PALETTE, 12005, 'E-saltwind-apartment-house.png'),
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
            kit.save(asset, 'author_houses.py', palette, {'reference': REF + reference})
