"""One-time guarded authoring of the lane's three houses: Nell's workshop seen from the street (lane-workshop), her
own house next door (lane-nell-house) and Bram's cottage (lane-cottage). Origins are the centre of each footprint at
ground height; the street fronts face +X.

The workshop matches the rooms inside it: a tall workshop floor with the street doors a third of the way along the
front from its south corner, and the loft above it as a jettied, half-timbered upper floor under a roof whose ridge
runs north–south (gables to the north and south, as in the loft). Walls are slabs with real openings, so glass sits
inside them and never shares a plane with the plaster.

The area document owns the footprints and the doorway link; these meshes never decide traversal. Refuses an
existing master.
"""
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lane_kit as k  # noqa: E402

ASSETS = ('lane-workshop', 'lane-nell-house', 'lane-cottage')


def timber(b, a, z0, z1, w=.15, proud=.06, axis='x', at=0.0, side=-1):
    """A vertical post on a wall face. axis='x': wall along x at y=at; axis='y': wall along y at x=at. `side` is the
    face's outward sign along the other axis."""
    if axis == 'x':
        b.box('timber', (a, at + side * proud / 2, (z0 + z1) / 2), (w, proud + .02, z1 - z0), .015)
    else:
        b.box('timber', (at + side * proud / 2, a, (z0 + z1) / 2), (proud + .02, w, z1 - z0), .015)


def beam(b, a0, a1, z, w=.15, proud=.06, axis='x', at=0.0, side=-1):
    if axis == 'x':
        b.box('timber', ((a0 + a1) / 2, at + side * proud / 2, z), (a1 - a0, proud + .02, w), .015)
    else:
        b.box('timber', (at + side * proud / 2, (a0 + a1) / 2, z), (proud + .02, a1 - a0, w), .015)


def brace(b, p0, p1, axis, at, proud=.06, w=.13, side=-1):
    (a0, z0), (a1, z1) = p0, p1
    length = math.hypot(a1 - a0, z1 - z0)
    angle = math.atan2(z1 - z0, a1 - a0)
    if axis == 'x':
        b.box('timber', ((a0 + a1) / 2, at + side * proud / 2, (z0 + z1) / 2), (length, proud + .02, w), .012, (0, -angle, 0))
    else:
        b.box('timber', (at + side * proud / 2, (a0 + a1) / 2, (z0 + z1) / 2), (proud + .02, length, w), .012, (angle, 0, 0))


def plinth(b, rng, x0, x1, y0, y1, top, skip_east=None):
    k.stone_courses(b, rng, 'x', x0 - .04, x1 + .04, 0, top, y0 - .04, depth=.22, course=top / 2)
    k.stone_courses(b, rng, 'x', x0 - .04, x1 + .04, 0, top, y1 + .04 - .22, depth=.22, course=top / 2)
    k.stone_courses(b, rng, 'y', y0, y1, 0, top, x1 + .04, depth=.22, course=top / 2, skip=skip_east)
    k.stone_courses(b, rng, 'y', y0, y1, 0, top, x0 - .04 + .22, depth=.22, course=top / 2)


def studs(b, a0, a1, z0, z1, axis, at, side, gaps, spacing=.5):
    """Close studding between a0 and a1, leaving out the posts that would cross an opening (a0, a1, bottom, top)."""
    count = max(1, round((a1 - a0) / spacing))
    for i in range(count + 1):
        a = a0 + (a1 - a0) * i / count
        if any(g0 - .1 < a < g1 + .1 for g0, g1, _, _ in gaps):
            for g0, g1, bottom, top in gaps:
                if g0 - .1 < a < g1 + .1:
                    if bottom - z0 > .2:
                        timber(b, a, z0, bottom - .06, .11, axis=axis, at=at, side=side)
                    if z1 - top > .2:
                        timber(b, a, top + .06, z1, .11, axis=axis, at=at, side=side)
            continue
        timber(b, a, z0, z1, .12, axis=axis, at=at, side=side)


def ivy(b, rng, count, points):
    for _ in range(count):
        x, y, z, squash = points(rng)
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][rng.randrange(3)], (x, y, z), rng.uniform(.06, .1), 1, squash)


# --- Nell's workshop ---------------------------------------------------------------------------------------------
X0, X1, Y0, Y1 = -4.25, 4.25, -4.0, 4.0     # ground floor walls (outer faces)
GROUND, PLATE = 3.45, 5.65                  # the jetty's floor line and the upper wall plate
JETTY = .35                                 # the loft floor oversails the street and the yard by this much
EAST, SOUTH = X1 + JETTY, Y0 - JETTY        # upper wall faces
PITCH = math.tan(math.radians(36))
RIDGE_X = (X0 + EAST) / 2
RIDGE_Z = PLATE + (EAST - RIDGE_X) * PITCH
EAVE_X_E, EAVE_X_W = EAST + .35, X0 - .35
EAVE_Z = PLATE - .35 * PITCH
DOOR = (-2.3, -.7)                          # along y; a third of the way from the south corner, as inside
SHOP = (-.1, 2.5, 1.05, 2.75)
NARROW = (2.95, 3.6, 1.3, 2.55)
UPPER_E = (-2.68, -.18, 2.96)               # the loft's three street windows (sparks-loft flipped revision)
UPPER_S = (-2.04, 1.76)                     # its two gable windows over the yard, either side of the oculus
WINDOW_W, WINDOW_Z0, WINDOW_Z1 = .95, 4.05, 5.2
CHIMNEY = (2.05, 2.9)


def workshop():
    rng = random.Random(2820)
    b = k.Batch(rng)
    # Ground floor: plastered walls with the street doors, the shop window and a narrow window; a plinth of
    # coursed limestone in front of their foot.
    def s_east(y):
        return y - Y0
    east_openings = [(s_east(DOOR[0]), s_east(DOOR[1]), .14, 2.78), (s_east(SHOP[0]), s_east(SHOP[1]), SHOP[2], SHOP[3]),
                     (s_east(NARROW[0]), s_east(NARROW[1]), NARROW[2], NARROW[3])]
    south_window = (1.15, 2.15, 1.15, 2.45)
    k.wall('Workshop east wall', 'plaster', (X1, Y0), (X1, Y1), 0, GROUND, .2, east_openings)
    k.wall('Workshop south wall', 'plaster', (X0, Y0), (X1, Y0), 0, GROUND, .2, [(south_window[0] - X0, south_window[1] - X0, south_window[2], south_window[3])])
    k.wall('Workshop north wall', 'plaster', (X1, Y1), (X0, Y1), 0, GROUND, .2)
    k.wall('Workshop west wall', 'plaster', (X0, Y1), (X0, Y0), 0, GROUND, .2)
    k.stone_courses(b, rng, 'y', Y0 - .04, Y1, 0, .42, X1 + .2, depth=.2, course=.21, skip=lambda mid, z: DOOR[0] - .2 < mid < DOOR[1] + .2)
    k.stone_courses(b, rng, 'x', X0, X1 + .2, 0, .42, Y0 - .2, depth=.2, course=.21)
    # Heavy framing on the ground floor: sill, head and plate beams, posts at the corners and beside every opening.
    for a0, a1 in ((Y0 - .02, DOOR[0] - .07), (DOOR[1] + .07, Y1)):
        beam(b, a0, a1, .5, .16, axis='y', at=X1, side=1)
    for z in (2.92, GROUND - .12):
        beam(b, Y0 - .02, Y1, z, .16, axis='y', at=X1, side=1)
    for y in (DOOR[0] - .07, DOOR[1] + .07, SHOP[1] + .1, NARROW[1] + .12, Y1 - .07):
        timber(b, y, .42, GROUND - .05, .15, axis='y', at=X1, side=1)
    brace(b, (Y0 + .45, .6), (DOOR[0] - .16, 2.82), 'y', X1, side=1)
    for z in (.5, 2.92, GROUND - .12):
        beam(b, X0, X1 + .02, z, .16, axis='x', at=Y0, side=-1)
    for x in (X0 + .06, -2.0, south_window[0] - .1, south_window[1] + .1):
        timber(b, x, .42, GROUND - .05, .15, axis='x', at=Y0, side=-1)
    brace(b, (south_window[1] + .2, .6), (X1 - .18, 2.82), 'x', Y0, side=-1)
    # Limestone quoins up the street corner.
    for i in range(8):
        z = .6 + i * .36
        long = i % 2 == 0
        b.box('limestone_pale', (X1 + .03 - (.18 if long else .1), Y0 - .05, z), (.36 if long else .2, .14, .3), .03)
        b.box('limestone_pale', (X1 + .05, Y0 + (.18 if not long else .1), z), (.14, .36 if not long else .2, .3), .03)
    # The jetty: joist ends, a moulded bressummer and curved brackets carry the loft out over the street and yard.
    y = Y0
    while y < Y1 - .1:
        b.box('timber', (X1 + JETTY / 2, y + .2, GROUND - .02), (JETTY + .02, .12, .14), .015)
        y += .45
    x = X0 + .2
    while x < X1:
        b.box('timber', (x, Y0 - JETTY / 2, GROUND - .02), (.12, JETTY + .02, .14), .015)
        x += .45
    b.box('timber', (X1 + JETTY / 2, (Y0 - JETTY + Y1) / 2, GROUND + .03), (JETTY + .08, Y1 - Y0 + JETTY, .06), .01)
    b.box('timber', ((X0 + X1 + JETTY) / 2, Y0 - JETTY / 2, GROUND + .03), (X1 - X0 + JETTY, JETTY + .08, .06), .01)
    b.box('wood_dark', (EAST - .04, (SOUTH + Y1) / 2, GROUND + .13), (.2, Y1 - SOUTH, .22), .025)
    b.box('wood_dark', ((X0 + EAST) / 2, SOUTH + .04, GROUND + .13), (EAST - X0, .2, .22), .025)
    b.box('wood_dark', (EAST + .02, (SOUTH + Y1) / 2, GROUND + .26), (.1, Y1 - SOUTH, .05), .01)
    b.box('wood_dark', ((X0 + EAST) / 2, SOUTH - .02, GROUND + .26), (EAST - X0, .1, .05), .01)
    for y in (Y0 + .06, DOOR[0] - .07, DOOR[1] + .07, SHOP[1] + .1, Y1 - .07):
        k.h.curve('Jetty bracket', [(X1 + .06, y, 2.72), (X1 + .12, y, 3.1), (X1 + .3, y, 3.3), (EAST - .05, y, GROUND)], .05, 'timber')
    for x in (X0 + .06, -2.0, X1 - .06):
        k.h.curve('Jetty bracket', [(x, Y0 - .06, 2.95), (x, Y0 - .12, 3.2), (x, Y0 - .3, 3.36), (x, SOUTH + .05, GROUND)], .05, 'timber')
    # The loft: a half-timbered upper floor, close-studded, its windows over the street and over the yard.
    def s_upper_e(y):
        return y - SOUTH
    upper_e = [(s_upper_e(c - WINDOW_W / 2), s_upper_e(c + WINDOW_W / 2), WINDOW_Z0, WINDOW_Z1) for c in UPPER_E]
    upper_s = [(c - WINDOW_W / 2 - X0, c + WINDOW_W / 2 - X0, WINDOW_Z0, WINDOW_Z1) for c in UPPER_S]
    k.wall('Loft east wall', 'plaster', (EAST, SOUTH), (EAST, Y1), GROUND + .24, PLATE, .2, upper_e)
    k.wall('Loft south wall', 'plaster', (X0, SOUTH), (EAST, SOUTH), GROUND + .24, PLATE, .2, upper_s)
    k.wall('Loft north wall', 'plaster', (EAST, Y1), (X0, Y1), GROUND, PLATE, .2)
    k.wall('Loft west wall', 'plaster', (X0, Y1), (X0, SOUTH), GROUND, PLATE, .2)
    gaps_e = [(c - WINDOW_W / 2 - .02, c + WINDOW_W / 2 + .02, WINDOW_Z0 - .06, WINDOW_Z1 + .06) for c in UPPER_E]
    gaps_s = [(c - WINDOW_W / 2 - .02, c + WINDOW_W / 2 + .02, WINDOW_Z0 - .06, WINDOW_Z1 + .06) for c in UPPER_S]
    for z in (3.75, PLATE - .07):
        beam(b, SOUTH - .02, Y1, z, .13, axis='y', at=EAST, side=1)
        beam(b, X0, EAST + .02, z, .13, axis='x', at=SOUTH, side=-1)
    studs(b, SOUTH + .06, Y1 - .06, 3.8, PLATE - .12, 'y', EAST, 1, gaps_e)
    studs(b, X0 + .06, EAST - .06, 3.8, PLATE - .12, 'x', SOUTH, -1, gaps_s)
    for p0, p1 in (((SOUTH + .1, 3.84), (-3.25, 5.52)), ((.85, 3.84), (2.15, 5.52))):
        brace(b, p0, p1, 'y', EAST, side=1)
    for p0, p1 in (((X0 + .1, 3.84), (-2.55, 5.52)), ((EAST - .1, 3.84), (2.35, 5.52))):
        brace(b, p0, p1, 'x', SOUTH, side=-1)
    for c in UPPER_E:
        k.window(b, (EAST, c, (WINDOW_Z0 + WINDOW_Z1) / 2), WINDOW_W, WINDOW_Z1 - WINDOW_Z0, (1, 0), bars=(1, 2), name='Loft window glass')
    for c in UPPER_S:
        k.window(b, (c, SOUTH, (WINDOW_Z0 + WINDOW_Z1) / 2), WINDOW_W, WINDOW_Z1 - WINDOW_Z0, (0, -1), bars=(1, 2), name='Loft window glass',
                 flowers=('flower_violet', 'flower_white', 'flower_yellow'))
    # The south gable over the yard: plaster between a collar, a king post and struts, and the loft's round window.
    k.gable_plaster('Loft gable', 'plaster', SOUTH, X0, EAST, PLATE - .02, RIDGE_Z - .14, RIDGE_X, -1, axis='y')
    k.gable_plaster('North gable', 'plaster', Y1, X0, EAST, PLATE - .02, RIDGE_Z - .14, RIDGE_X, 1, axis='y')
    collar_z = PLATE + 1.2
    beam(b, RIDGE_X - (RIDGE_Z - .14 - collar_z) / PITCH, RIDGE_X + (RIDGE_Z - .14 - collar_z) / PITCH, collar_z, .15, axis='x', at=SOUTH, side=-1)
    timber(b, RIDGE_X, PLATE, collar_z, .14, axis='x', at=SOUTH, side=-1)
    oculus_z = collar_z + .55
    timber(b, RIDGE_X, oculus_z + .47, RIDGE_Z - .3, .14, axis='x', at=SOUTH, side=-1)
    for side in (-1, 1):
        brace(b, (RIDGE_X + side * .2, PLATE + .06), (RIDGE_X + side * 2.1, collar_z - .06), 'x', SOUTH, side=-1)
        reach = 3.3
        timber(b, RIDGE_X + side * reach, PLATE, RIDGE_Z - .14 - reach * PITCH - .06, .12, axis='x', at=SOUTH, side=-1)
    k.h.torus('Loft oculus frame', (RIDGE_X, SOUTH - .06, oculus_z), .4, .06, 'timber', (math.pi / 2, 0, 0))
    k.disc_pane('Loft oculus glass', 'window_pane', (RIDGE_X, SOUTH, oculus_z), .38, (0, -1), .03)
    for angle in (0, math.pi / 2):
        b.box('timber', (RIDGE_X, SOUTH - .07, oculus_z), (.74 * abs(math.cos(angle)) + .04, .04, .74 * abs(math.sin(angle)) + .04), 0)
    # Roof: clay tiles on both slopes, the ridge running north–south like the loft's, barge boards on the gable.
    for eave_x in (EAVE_X_E, EAVE_X_W):
        k.roof_deck(b, SOUTH - .4, Y1 + .1, eave_x, RIDGE_X, EAVE_Z, RIDGE_Z, axis='y')
        k.tiled_roof(b, SOUTH - .4, Y1 + .1, eave_x, RIDGE_X, EAVE_Z, RIDGE_Z, rng, axis='y')
    for eave_x in (EAVE_X_E + .03, EAVE_X_W - .03):
        p0, p1 = (eave_x, EAVE_Z - .02), (RIDGE_X, RIDGE_Z + .02)
        length = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        angle = math.atan2(p1[1] - p0[1], p1[0] - p0[0])
        b.box('timber', ((p0[0] + p1[0]) / 2, SOUTH - .42, (p0[1] + p1[1]) / 2), (length, .08, .2), .015, (0, -angle, 0))
    # Gutter along the street eave, a downpipe that steps in under the jetty, and the water butt.
    b.cylinder('iron', (EAVE_X_E - .05, SOUTH - .4, EAVE_Z - .08), (EAVE_X_E - .05, Y1 + .1, EAVE_Z - .08), .06, 8)
    b.cylinder('iron', (EAVE_X_E - .05, Y1 - .12, EAVE_Z - .08), (EAST + .08, Y1 - .12, EAVE_Z - .4), .045, 8)
    b.cylinder('iron', (EAST + .08, Y1 - .12, EAVE_Z - .4), (EAST + .08, Y1 - .12, GROUND + .3), .045, 8)
    b.cylinder('iron', (EAST + .08, Y1 - .12, GROUND + .3), (X1 + .1, Y1 - .12, GROUND - .2), .045, 8)
    b.cylinder('iron', (X1 + .1, Y1 - .12, GROUND - .2), (X1 + .1, Y1 - .12, .95), .045, 8)
    bx, by = X1 + .32, Y1 - .3
    b.cylinder('wood_dark', (bx, by, 0), (bx, by, .82), .26, 12)
    for z in (.18, .64):
        b.cylinder('iron', (bx, by, z - .02), (bx, by, z + .02), .268, 12)
    b.cylinder('water', (bx, by, .79), (bx, by, .8), .22, 12)
    # The street doors: two green leaves of upright boards set in the opening, a glazed transom, brass rings, a step.
    d0, d1 = DOOR
    mid = (d0 + d1) / 2
    for y0, y1 in ((d0 + .02, mid - .01), (mid + .01, d1 - .02)):
        b.box('teal', (X1 - .07, (y0 + y1) / 2, 1.29), (.07, y1 - y0, 2.3), .02)
        for i in range(1, 5):
            b.box('teal_dark', (X1 - .03, y0 + (y1 - y0) * i / 5, 1.29), (.01, .025, 2.2), 0)
        b.box('teal_dark', (X1 - .025, (y0 + y1) / 2, 1.29), (.02, math.hypot(y1 - y0, 1.5) * .9, .09), .01, (math.atan2(1.5, y1 - y0) * (1 if y0 < mid else -1), 0, 0))
        for z in (.45, 2.1):
            b.box('teal_dark', (X1 - .025, (y0 + y1) / 2, z), (.02, y1 - y0 - .04, .09), .01)
    for y in (mid - .1, mid + .1):
        k.h.torus('Brass door ring', (X1 - .01, y, 1.25), .055, .012, 'brass', (0, math.pi / 2, 0))
    b.box('timber', (X1 - .05, mid, 2.47), (.12, d1 - d0, .1), .015)
    k.pane('Transom glass', 'window_shop', (X1, mid, 2.63), d1 - d0 - .04, .26, (1, 0), -.1)
    for y in (mid - .4, mid, mid + .4):
        b.box('timber', (X1 - .07, y, 2.63), (.04, .04, .28), .005)
    b.box('limestone_pale', (X1 + .25, mid, .07), (.5, d1 - d0 + .3, .14), .03)
    # The shop window: teal sashes over a panelled stall riser, its picture a warm room of shelves.
    s0, s1, z0, z1 = SHOP
    k.window(b, (X1, (s0 + s1) / 2, (z0 + z1) / 2), s1 - s0, z1 - z0, (1, 0), shutters=False, box=False, frame='teal_dark',
             glass='window_shop', bars=(3, 1), name='Shop window glass')
    b.box('teal', (X1 + .04, (s0 + s1) / 2, .73), (.08, s1 - s0 + .1, .6), .02)
    for i in range(4):
        y = s0 + (s1 - s0) * (i + .5) / 4
        b.box('teal_dark', (X1 + .085, y, .73), (.02, (s1 - s0) / 4 - .12, .42), .01)
    n0, n1, nz0, nz1 = NARROW
    k.window(b, (X1, (n0 + n1) / 2, (nz0 + nz1) / 2), n1 - n0, nz1 - nz0, (1, 0), shutters=False, box=False, bars=(0, 2), name='Narrow window glass')
    sw = south_window
    k.window(b, ((sw[0] + sw[1]) / 2, Y0, (sw[2] + sw[3]) / 2), sw[1] - sw[0], sw[3] - sw[2], (0, -1), bars=(1, 1), name='Yard window glass')
    # The gear sign on its scrolled bracket under the jetty, just north of the doors.
    sx, sy, sz = X1, d1 + .32, 3.12
    b.box('iron', (sx + .45, sy, sz + .02), (.9, .05, .05), .01)
    k.h.curve('Sign bracket scroll', [(sx + .02, sy, sz - .38), (sx + .25, sy, sz - .32), (sx + .55, sy, sz - .12), (sx + .86, sy, sz)], .02, 'iron')
    k.h.torus('Sign bracket curl', (sx + .2, sy, sz - .18), .1, .016, 'iron', (math.pi / 2, 0, 0))
    for dx in (.42, .8):
        b.cylinder('iron', (sx + dx, sy, sz), (sx + dx, sy, sz - .2), .008, 4)
    cx, cz = sx + .61, sz - .58
    b.cylinder('teal_dark', (cx, sy - .03, cz), (cx, sy + .03, cz), .36, 24)
    k.h.torus('Sign rim', (cx, sy, cz), .36, .025, 'brass', (math.pi / 2, 0, 0))
    for face in (-1, 1):
        k.h.torus('Sign gear', (cx, sy + face * .045, cz), .17, .035, 'gold', (math.pi / 2, 0, 0))
        for i in range(12):
            a = math.tau * i / 12
            b.box('gold', (cx + math.cos(a) * .215, sy + face * .045, cz + math.sin(a) * .215), (.065, .03, .065), .006, (0, -a, 0))
        b.cylinder('gold', (cx, sy + face * .07, cz), (cx, sy + face * .03, cz), .06, 12)
    # The lean-to woodshed against the yard wall: posts, boarded ends, a little clay roof, split logs in rows.
    w0, w1, front = -3.9, -.7, Y0 - 1.0
    for x in (w0 + .06, w1 - .06):
        b.box('timber', (x, front + .06, 1.07), (.12, .12, 2.14), .015)
        for i in range(6):
            yy = front + .12 + i * .15
            top = 2.15 + (yy - front) * .7 / 1.0
            b.box(['wood', 'wood_light'][i % 2], (x, yy + .07, top / 2), (.05, .14, top), .008)
    b.box('timber', ((w0 + w1) / 2, front + .06, 2.14), (w1 - w0 + .1, .12, .12), .015)
    b.box('timber', ((w0 + w1) / 2, Y0 - .06, 2.86), (w1 - w0 + .1, .12, .1), .015)
    k.roof_deck(b, w0 - .1, w1 + .1, front - .15, Y0, 2.12, 2.86, 'timber')
    k.tiled_roof(b, w0 - .1, w1 + .1, front - .15, Y0, 2.12, 2.84, rng, .24, .3, cap=False)
    for row in range(5):
        for i in range(11):
            x = w0 + .3 + i * .27 + (.13 if row % 2 else 0)
            if x > w1 - .2:
                continue
            z = .2 + row * .27
            b.cylinder(['wood', 'wood_light', 'wood_dark'][(i + row) % 3], (x, Y0 - .1, z), (x, front + .2, z), .13, 8)
            b.cylinder('wood_light', (x, front + .19, z), (x, front + .18, z), .11, 8)
    # Chopping block by the shed with the axe sunk into it, and a few split pieces at its foot.
    cbx, cby = .1, Y0 - .7
    b.cylinder('wood', (cbx, cby, 0), (cbx, cby, .44), .23, 12)
    b.cylinder('wood_light', (cbx, cby, .44), (cbx, cby, .45), .2, 12)
    b.box('steel', (cbx + .02, cby, .5), (.2, .035, .13), .01, (0, math.radians(-8), 0))
    b.box('steel_dark', (cbx - .08, cby, .53), (.06, .05, .08), .01)
    b.cylinder('wood_light', (cbx - .08, cby, .55), (cbx - .55, cby + .05, 1.05), .022, 6)
    for i, (dx, dy, turn) in enumerate(((.35, .1, .3), (.3, -.2, 1.2), (-.3, .25, 2.1))):
        b.box(['wood_light', 'wood'][i % 2], (cbx + dx, cby + dy, .06), (.32, .1, .1), .02, (0, 0, turn))
    # Chimney for the stove, through the street slope near the north end; the game draws its smoke.
    cx, cy = CHIMNEY
    base = PLATE + (EAST - cx) * PITCH - .4
    k.stone_courses(b, rng, 'x', cx - .38, cx + .38, base, RIDGE_Z + .6, cy - .32, depth=.64, course=.3, block=(.3, .5), tones=('brick', 'terracotta_dark', 'brick', 'limestone_warm'))
    b.box('limestone_pale', (cx, cy, RIDGE_Z + .66), (.9, .78, .12), .03)
    for dx in (-.16, .16):
        b.cylinder('terracotta', (cx + dx, cy, RIDGE_Z + .7), (cx + dx, cy, RIDGE_Z + 1.0), .1, 10, .085)
    # A broom by the doors, a wire bracket on the loft wall, ivy up the street corner.
    b.cylinder('wood_light', (X1 + .1, d1 + .14, .02), (X1 + .16, d1 + .22, 1.35), .018, 6)
    b.cylinder('wood_dark', (X1 + .09, d1 + .13, .02), (X1 + .1, d1 + .14, .28), .08, 8, .05)
    b.box('iron', (EAST + .06, 1.5, 5.25), (.08, .14, .08), .01)
    b.cylinder('white', (EAST + .12, 1.5, 5.25), (EAST + .12, 1.5, 5.35), .03, 8)

    def corner(r):
        z = r.uniform(.45, 3.2)
        if r.random() < .5:
            return X1 + .05, r.uniform(Y0, Y0 + .7), z, (.5, 1, 1)
        return r.uniform(X1 - .9, X1), Y0 - .05, z, (1, .5, 1)
    ivy(b, rng, 110, corner)
    b.finish()


# --- Nell's house ------------------------------------------------------------------------------------------------
def nell_house():
    """A narrow dressed-stone house of two storeys next to the workshop, its gable to the lane: a plum door under a
    stone hood, teal shutters, lavender in the window boxes and a climbing rose."""
    rng = random.Random(2822)
    b = k.Batch(rng)
    X, Y = 3.8, 2.5
    top, ridge_z = 6.0, 6.0 + Y * math.tan(math.radians(42))
    door = (-1.2, -.2, .3, 2.45)
    ground_window = (.55, 1.75, 1.0, 2.5)
    upper = [(-1.85, -1.0), (.85, 1.7)]
    up_z = (3.8, 5.05)
    attic = (-.3, .3, 6.7, 7.3)
    openings = [(door[0] + Y, door[1] + Y, door[2], 2.88), (ground_window[0] + Y, ground_window[1] + Y, ground_window[2], ground_window[3])]
    openings += [(a + Y, c + Y, up_z[0], up_z[1]) for a, c in upper]
    k.wall('Front wall', 'ashlar', (X, -Y + .02), (X, Y), 0, top, .22, [(o[0] - .02, o[1] - .02, o[2], o[3]) for o in openings])
    k.wall('North wall', 'ashlar', (X, Y), (-X, Y), 0, top, .22, [(X - 1.6, X - 1.0, 1.2, 2.4), (X - 2.4, X - 1.8, 3.9, 5.0)])
    k.wall('West wall', 'ashlar', (-X, Y), (-X, -Y + .02), 0, top, .22)
    k.wall('Party wall', 'ashlar', (-X, -Y + .02), (X, -Y + .02), 0, top, .22)
    k.gable_plaster('Stone gable', 'ashlar', X, -Y + .02, Y, top - .02, ridge_z - .1, 0, 1)
    k.gable_plaster('Back gable', 'ashlar', -X, -Y + .02, Y, top - .02, ridge_z - .1, 0, -1)
    k.pane('Attic window glass', 'window_pane', (X, 0, (attic[2] + attic[3]) / 2), attic[1] - attic[0], attic[3] - attic[2], (1, 0), .03)
    for (a, c, z) in ((attic[0] - .05, attic[1] + .05, attic[2] - .05), (attic[0] - .05, attic[1] + .05, attic[3] + .05)):
        b.box('limestone_pale', (X + .06, (a + c) / 2, z), (.08, c - a + .1, .1), .015)
    for yy in (attic[0] - .05, attic[1] + .05):
        b.box('limestone_pale', (X + .06, yy, (attic[2] + attic[3]) / 2), (.08, .1, attic[3] - attic[2] + .1), .015)
    b.box('limestone_pale', (X + .065, 0, (attic[2] + attic[3]) / 2), (.03, .03, attic[3] - attic[2]), 0)
    # Plinth, a string course at the floor line, and quoins up the street corner.
    k.stone_courses(b, rng, 'y', -Y + .02, Y + .02, 0, .32, X + .18, depth=.16, course=.16, tones=('limestone_shade', 'limestone', 'limestone_warm'),
                    skip=lambda mid, z: door[0] - .25 < mid < door[1] + .25)
    b.box('limestone_pale', (X + .07, .02, 3.35), (.14, 2 * Y + .04, .16), .02)
    for i in range(14):
        z = .5 + i * .4
        long = i % 2 == 0
        b.box('limestone_pale', (X + .05, Y - (.15 if long else .09), z), (.12, .3 if long else .18, .32), .03)
    # The plum door, panelled, with a brass knocker and a number; a fanlight; a stone hood on two brackets; steps.
    d0, d1, dz0, dz1 = door
    b.box('plum', (X - .08, (d0 + d1) / 2, (dz0 + dz1) / 2), (.07, d1 - d0 - .04, dz1 - dz0), .02)
    for row in range(3):
        for col in range(2):
            zz = dz0 + .35 + row * .62
            yy = d0 + .27 + col * .46
            b.box('plum', (X - .035, yy, zz), (.03, .32, .48), .02)
    k.h.torus('Brass knocker', (X - .01, (d0 + d1) / 2, 1.55), .07, .014, 'brass', (0, math.pi / 2, 0))
    b.sphere('brass', (X - .02, (d0 + d1) / 2, 1.66), .03, 1)
    b.sphere('brass', (X - .02, d0 + .18, 1.2), .028, 1)
    b.box('limestone_pale', (X - .05, (d0 + d1) / 2, dz1 + .03), (.1, d1 - d0, .06), .01)
    k.pane('Fanlight glass', 'window_shop', (X, (d0 + d1) / 2, (dz1 + 2.88) / 2 + .02), d1 - d0 - .04, 2.88 - dz1 - .08, (1, 0), -.1)
    for yy in (d0 + .33, d1 - .33):
        b.box('white', (X - .07, yy, (dz1 + 2.88) / 2 + .02), (.03, .03, .36), .005)
    for yy in (d0 - .12, d1 + .12):
        b.box('limestone_pale', (X + .06, yy, 1.6), (.12, .2, 2.65), .02)
        b.box('limestone_pale', (X + .2, yy, 2.95), (.3, .12, .2), .02)
    b.box('limestone_pale', (X + .22, (d0 + d1) / 2, 3.1), (.46, d1 - d0 + .62, .1), .02)
    b.box('limestone', (X + .2, (d0 + d1) / 2, 3.18), (.4, d1 - d0 + .52, .06), .02)
    b.box('enamel_cream', (X + .02, d1 + .38, 1.85), (.03, .2, .2), .01)
    k.lettering('House number', '3', (X + .04, d1 + .38, 1.85), .16, 'teal_dark', (math.pi / 2, 0, math.pi / 2))
    for step, (depth, height) in enumerate(((.62, .15), (.36, .3))):
        b.box(['limestone', 'limestone_pale'][step], (X + depth / 2, (d0 + d1) / 2, height / 2), (depth, d1 - d0 + .5, height), .02)
    b.box('iron', (X + .45, d1 + .32, .12), (.04, .3, .18), .005)
    b.box('iron', (X + .45, d1 + .32, .2), (.02, .3, .02), 0)
    # Windows: dressed stone surrounds, teal sashes and shutters; lavender and white flowers in the boxes.
    g = ground_window
    k.window(b, (X, (g[0] + g[1]) / 2, (g[2] + g[3]) / 2), g[1] - g[0], g[3] - g[2], (1, 0), frame='limestone_pale', shutters=False, flowers=('flower_violet', 'flower_white', 'flower_violet'), bars=(2, 1), name='Parlour window glass', recess=.11)
    for a, c in upper:
        k.window(b, (X, (a + c) / 2, sum(up_z) / 2), c - a, up_z[1] - up_z[0], (1, 0), frame='limestone_pale',
                 shutter_mats=('teal', 'teal_dark'), flowers=('flower_violet', 'flower_white', 'flower_pink'), bars=(1, 2), name='Bedroom window glass', recess=.11)
    for (xx, zz, hh) in ((1.3, 1.8, 1.2), (2.1, 4.45, 1.1)):
        k.pane('Back window glass', 'window_pane', (xx, Y, zz), .6, hh, (0, 1), -.1)
    # A climbing rose up the street corner from a little bed by the step.
    b.box('soil', (X + .25, Y - .3, .06), (.5, .5, .12), .02)
    for i in range(70):
        t = i / 70
        zz = .2 + t * 4.6
        yy = Y - .35 + math.sin(t * 9) * .25
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][rng.randrange(3)], (X + .07, yy + rng.uniform(-.12, .12), zz), rng.uniform(.07, .11), 1, (.5, 1, 1))
        if i % 3 == 0:
            b.sphere(['flower_pink', 'flower_red', 'flower_pink'][rng.randrange(3)], (X + .12, yy + rng.uniform(-.1, .1), zz + .05), .05, 1)
    for side in (-1, 1):
        k.h.pot((X + .35, (d0 + d1) / 2 + side * .85, 0), .85, False, True)
    # Roof, ridge to the lane, barge boards on the gable; a stone chimney at the back end.
    eave = Y + .32
    eave_z = top - .32 * math.tan(math.radians(42))
    k.roof_deck(b, -X - .25, X + .35, eave, 0, eave_z, ridge_z)
    k.tiled_roof(b, -X - .25, X + .35, eave, 0, eave_z, ridge_z, rng)
    k.roof_deck(b, -X - .25, X + .35, -Y + .02, 0, top, ridge_z)
    k.tiled_roof(b, -X - .25, X + .35, -Y + .02, 0, top, ridge_z, rng, cap=False)
    for side in (-1, 1):
        p0, p1 = (side * (eave if side > 0 else Y), eave_z if side > 0 else top), (0, ridge_z + .02)
        length = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
        b.box('wood_dark', (X + .33, (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2), (.08, length, .18), .015, (math.atan2(p1[1] - p0[1], p1[0] - p0[0]), 0, 0))
    b.cylinder('iron', (X + .35, eave - .05, eave_z - .08), (-X - .25, eave - .05, eave_z - .08), .055, 8)
    b.cylinder('iron', (X + .1, eave - .05, eave_z - .08), (X + .1, Y + .05, eave_z - .4), .04, 8)
    b.cylinder('iron', (X + .1, Y + .05, eave_z - .4), (X + .1, Y + .05, .2), .04, 8)
    cx = -2.7
    k.stone_courses(b, rng, 'x', cx - .36, cx + .36, ridge_z - 1.2, ridge_z + .9, -.36, depth=.72, course=.3, block=(.3, .45), tones=('limestone', 'limestone_pale', 'limestone_warm'))
    b.box('limestone_pale', (cx, 0, ridge_z + .95), (.84, .84, .1), .03)
    b.cylinder('terracotta', (cx, 0, ridge_z + 1.0), (cx, 0, ridge_z + 1.32), .11, 10, .09)
    b.finish()


# --- Bram's cottage ----------------------------------------------------------------------------------------------
def cottage():
    rng = random.Random(2821)
    b = k.Batch(rng)
    X, Y, top, eave_z, ridge_z = 2.45, 1.95, 3.3, 3.05, 5.05
    door = (-1.03, -.17, .36, 2.47)
    side_window = (.7, 1.5, 1.25, 2.25)
    south = [(-1.6, -.8, 1.225, 2.275), (.65, 1.45, 1.225, 2.275)]
    plinth(b, rng, -X, X, -Y, Y, .36, lambda mid, z: door[0] - .1 < mid < door[1] + .1)
    k.wall('Salmon wall', 'salmon', (-X, -Y), (X, -Y), .36, top, .2, [(a + X, c + X, z0, z1) for a, c, z0, z1 in south])
    k.wall('Salmon wall', 'salmon', (X, -Y), (X, Y), .36, top, .2, [(door[0] + Y, door[1] + Y, door[2], door[3]), (side_window[0] + Y, side_window[1] + Y, side_window[2], side_window[3])])
    k.wall('Salmon wall', 'salmon', (X, Y), (-X, Y), .36, top, .2)
    k.wall('Salmon wall', 'salmon', (-X, Y), (-X, -Y), .36, top, .2)
    for x in (X, -X):
        k.gable_plaster('Salmon gable', 'salmon', x, -Y, Y, top, ridge_z - .1, 0, 1 if x > 0 else -1)
    # Limestone quoins at the street corners.
    for cx, cy in ((X, -Y), (X, Y), (-X, -Y)):
        for i in range(8):
            z = .5 + i * .36
            long = i % 2 == 0
            b.box('limestone_pale', (cx + (-.15 if long and cx > 0 else 0) - (0 if cx > 0 else -.12), cy + (.12 if cy < 0 else -.12), z), (.42 if long else .26, .3, .3), .03)
    # The door to the lane, set in its opening under a striped awning, with a window beside it.
    d0, d1, dz0, dz1 = door
    b.box('shutter', (X - .08, (d0 + d1) / 2, (dz0 + dz1) / 2), (.07, d1 - d0 - .02, dz1 - dz0), .02)
    for i in range(1, 4):
        b.box('shutter_dark', (X - .04, d0 + (d1 - d0) * i / 4, (dz0 + dz1) / 2), (.01, .02, dz1 - dz0 - .1), 0)
    b.box('limestone_pale', (X + .06, (d0 + d1) / 2, dz1 + .08), (.1, d1 - d0 + .2, .16), .02)
    for y in (d0 - .06, d1 + .06):
        b.box('limestone_pale', (X + .06, y, (dz0 + dz1) / 2 + .04), (.1, .12, dz1 - dz0 + .1), .02)
    b.sphere('brass', (X - .03, d1 - .1, 1.35), .035, 1)
    b.box('limestone', (X + .3, (d0 + d1) / 2, .09), (.5, 1.1, .18), .03)
    for i, y in enumerate((-.92, -.82)):
        b.cylinder('milk', (X + .42, y, .18), (X + .42, y, .4), .045, 10, .035)
        b.cylinder('white' if i else 'cream', (X + .42, y, .4), (X + .42, y, .43), .03, 8)
    b.box('paper', (X + .4, -.28, .2), (.18, .26, .04), .005, (0, 0, .4))
    sw = side_window
    k.window(b, (X, (sw[0] + sw[1]) / 2, (sw[2] + sw[3]) / 2), sw[1] - sw[0], sw[3] - sw[2], (1, 0), name='Cottage window glass')
    for i in range(7):
        y = -1.3 + i * .2
        colour = 'stripe_cream' if i % 2 == 0 else 'teal'
        b.box(colour, (X + .38, y, 2.75), (.75, .2, .03), 0, (0, math.radians(26), 0))
        b.box(colour, (X + .72, y, 2.48), (.03, .2, .22), 0)
    b.cylinder('iron', (X + .02, -1.32, 2.93), (X + .02, .12, 2.93), .02, 6)
    # South face: two shuttered windows with boxes, a hanging basket, ivy round the far corner.
    k.window(b, (-1.2, -Y, 1.75), .8, 1.05, (0, -1), flowers=('flower_violet', 'flower_white', 'flower_pink'), name='Cottage window glass')
    k.window(b, (1.05, -Y, 1.75), .8, 1.05, (0, -1), flowers=('flower_red', 'flower_white', 'flower_yellow'), name='Cottage window glass')
    b.box('iron', (X + .25, -1.75, 2.75), (.5, .03, .03), .005)
    k.h.pot((X + .45, -1.75, 2.15), .7, True, False)
    for _ in range(70):
        z = rng.uniform(.4, 3.1)
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][rng.randrange(3)], (rng.uniform(-X, -1.9), -Y - .04, z), rng.uniform(.06, .1), 1, (1, .5, 1))
    k.h.torus('Gable oculus', (X + .06, 0, 4.1), .22, .045, 'limestone_pale', (0, math.pi / 2, 0))
    k.disc_pane('Gable oculus glass', 'window_pane', (X, 0, 4.1), .2, (1, 0), .03)
    # Gutter and roof.
    b.cylinder('iron', (-X - .3, -Y - .38, eave_z - .05), (X + .3, -Y - .38, eave_z - .05), .055, 8)
    b.cylinder('iron', (X + .1, -Y - .38, eave_z - .05), (X + .1, -Y - .38, .35), .04, 8)
    k.roof_deck(b, -X - .3, X + .3, -Y - .38, 0, eave_z, ridge_z)
    k.roof_deck(b, -X - .3, X + .3, Y + .38, 0, eave_z, ridge_z)
    k.tiled_roof(b, -X - .3, X + .3, -Y - .38, 0, eave_z, ridge_z, rng)
    k.tiled_roof(b, -X - .3, X + .3, Y + .38, 0, eave_z, ridge_z, rng)
    for x in (X + .28, -X - .28):
        for side in (-1, 1):
            p0, p1 = (side * (Y + .4), eave_z - .02), (0, ridge_z + .02)
            length = math.hypot(p1[0] - p0[0], p1[1] - p0[1])
            b.box('wood_light', (x, (p0[0] + p1[0]) / 2, (p0[1] + p1[1]) / 2), (.07, length, .15), .015, (math.atan2(p1[1] - p0[1], p1[0] - p0[0]), 0, 0))
    cx, cy = -1.9, .35
    k.stone_courses(b, rng, 'x', cx - .32, cx + .32, 3.9, 5.8, cy - .32, depth=.64, course=.28, block=(.28, .4), tones=('limestone', 'limestone_pale', 'limestone_warm'))
    b.box('limestone_pale', (cx, cy, 5.85), (.76, .76, .1), .03)
    b.cylinder('terracotta', (cx, cy, 5.9), (cx, cy, 6.2), .11, 10, .09)
    b.finish()


if __name__ == '__main__':
    k.guard(ASSETS)
    for asset, make in (('lane-workshop', workshop), ('lane-nell-house', nell_house), ('lane-cottage', cottage)):
        k.start(asset)
        make()
        k.save(asset, 'author_buildings.py')
