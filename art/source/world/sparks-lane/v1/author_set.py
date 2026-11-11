"""One-time guarded authoring of haverlund-lane-set: the lane's ground, terraces, walls, stairs, tram cutting,
track and overhead wire, balustrade, fences, poles and wires, in area coordinates (one Blender unit is one cell).

content/areas/haverlund-lane.json owns traversal; these meshes never decide where anyone may stand. Level 0 (the
tram halt, y < 4.5) is at z 0; level 1 (the lane) is at z 1. The houses stand along the west side in a row: the
workshop, Nell's house and Bram's cottage; the green, the rail and the lookout are on the east. Refuses an existing
master.
"""
import math
import random
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lane_kit as k  # noqa: E402

ASSET = 'haverlund-lane-set'
RNG = random.Random(2810)
BOTTOM = -1.6
WIDTH, HEIGHT = 24, 28
EAST_EDGE, NORTH_EDGE, NEAR_EDGE = WIDTH - .5, HEIGHT - .5, -1.4
HALT = 4.5                                   # the retaining wall's face; the halt is below it
TRACK_Y, GAUGE, WIRE_Z = .45, 1.1, 3.75
KERB = 1.55                                  # the platform's edge
STAIRS = (12.5, 14.5)
LANE = (9.5, 15.5)
GREEN_X = 17.5
LOOKOUT_Y = 21.5
RAIL_Y = 27.25
GATE = (11.5, 13.5)
FENCE_X, FENCE_Y = 9.45, (22.6, 26.95)
GARDEN_GATE = (24.47, 25.53)
TUNNEL_X, ARCH_HALF, ARCH_SPRING = -.45, 1.35, 2.55
POLES = {'south': (10.25, 6.3), 'middle': (16.3, 14.6), 'north': (16.3, 23.4)}
POLE_TOP = 1.0 + 4.35
WIRE_POSTS = (3.5, 8.5, 16.0, 22.4)
TREE_BED = (19.9, 14.4)
PUMP = (21.6, 11.0)
CAT = (23.27, 12.4, 1.5)


def region(x, y):
    """The paving or planting under a half-cell centre on the upper terrace, or None for the stair notch."""
    if STAIRS[0] <= x <= STAIRS[1] and y < HALT + 1.0:
        return None
    if LANE[0] <= x < LANE[1]:
        return 'cobbles'
    if x < LANE[0]:
        if y < 9.5:
            return 'grass' if (x < 3.5 and y < 7.6) else 'flags'
        if x >= 4.95 and y >= FENCE_Y[0]:
            return 'grass'
        return 'flags'
    if x < GREEN_X or y >= LOOKOUT_Y:
        return 'flags'
    if 17.8 <= x <= 20.8 and 5.4 <= y <= 7.6:
        return 'soil'
    return 'grass'


def ground(b):
    spans = {'cobbles': 2.0, 'flags': 3.0, 'grass': 8.0}
    quads = {}
    step = .5
    x = -.5
    while x < EAST_EDGE - 1e-6:
        y = HALT
        while y < NORTH_EDGE - 1e-6:
            kind = region(x + step / 2, y + step / 2)
            if kind:
                quads.setdefault(kind, []).append((x, y, x + step, y + step))
            y += step
        x += step
    for kind, items in quads.items():
        if kind == 'soil':
            for x0, y0, x1, y1 in items:
                b.box('soil', ((x0 + x1) / 2, (y0 + y1) / 2, .99), (x1 - x0, y1 - y0, .02), 0)
            continue
        k.quad_surface('Terrace ' + kind, kind, items, spans[kind], 1.0)
    # The halt: a cobbled street bed for the tram and a flagged platform behind its kerb.
    k.quad_surface('Halt street', 'cobbles', [(TUNNEL_X, NEAR_EDGE, EAST_EDGE, KERB)], 2.0, 0.0)
    k.quad_surface('Halt platform', 'flags', [(TUNNEL_X, KERB, EAST_EDGE, HALT)], 3.0, 0.0)
    x = TUNNEL_X
    while x < EAST_EDGE - .1:
        w = min(1.0, EAST_EDGE - x)
        b.box('limestone_pale', (x + w / 2, KERB, .03), (w - .02, .16, .08), .02)
        x += w
    # A bed under each level, just below its surface, so no gap shows between the faces.
    b.box('soil_dark', ((-.45 + EAST_EDGE) / 2, (HALT + 1.0 + NORTH_EDGE) / 2, (BOTTOM + .97) / 2), (EAST_EDGE + .45, NORTH_EDGE - HALT - 1.0, .97 - BOTTOM), 0)
    for x0, x1 in ((-.45, STAIRS[0] - .05), (STAIRS[1] + .05, EAST_EDGE)):
        b.box('soil_dark', ((x0 + x1) / 2, HALT + .55, (BOTTOM + .97) / 2), (x1 - x0, .9, .97 - BOTTOM), 0)
    b.box('soil_dark', ((TUNNEL_X + EAST_EDGE) / 2, (NEAR_EDGE + HALT) / 2, (BOTTOM - .03) / 2), (EAST_EDGE - TUNNEL_X, HALT - NEAR_EDGE, -.03 - BOTTOM), 0)


def track(b):
    # Two rails on oak sleepers from deep in the cutting to the buffer stop at the end of the line.
    x0, x1 = -2.0, EAST_EDGE - .55
    for y in (TRACK_Y - GAUGE / 2, TRACK_Y + GAUGE / 2):
        b.box('rail', ((x0 + x1) / 2, y, .018), (x1 - x0, .07, .036), .008)
        b.box('iron', ((x0 + x1) / 2, y + (.055 if y > TRACK_Y else -.055), .004), (x1 - x0, .04, .01), 0)
    x = x0 + .3
    while x < x1:
        b.box('wood_dark', (x, TRACK_Y, -.005), (.16, GAUGE + .5, .02), 0)
        x += .6
    # Buffer stop: a red-and-cream beam on an iron frame with its struts.
    bx = EAST_EDGE - .35
    for y in (TRACK_Y - GAUGE / 2, TRACK_Y + GAUGE / 2):
        b.box('iron', (bx, y, .35), (.14, .14, .7), .02)
        b.cylinder('iron', (bx + .3, y, .02), (bx, y, .6), .045, 6)
    b.box('red', (bx - .08, TRACK_Y, .58), (.18, GAUGE + .3, .24), .03)
    for y in (TRACK_Y - .3, TRACK_Y + .3):
        b.box('white', (bx - .175, y, .58), (.02, .22, .16), .01)
    b.cylinder('ochre', (bx - .18, TRACK_Y, .9), (bx - .2, TRACK_Y, .9), .08, 10)
    b.box('iron', (bx - .1, TRACK_Y, .8), (.04, .04, .2), .005)
    # The overhead wire: iron posts on the platform, scrolled arms over the track, hangers and the running wire.
    for x in WIRE_POSTS:
        b.box('limestone', (x, HALT - .32, .1), (.3, .3, .2), .02)
        b.cylinder('iron', (x, HALT - .32, .2), (x, HALT - .32, WIRE_Z + .55), .06, 10, .045)
        b.cylinder('iron', (x, HALT - .32, WIRE_Z + .4), (x, TRACK_Y - .1, WIRE_Z + .4), .03, 6)
        k.h.curve('Wire arm scroll', [(x, HALT - .32, WIRE_Z - .3), (x, HALT - .9, WIRE_Z + .05), (x, HALT - 1.6, WIRE_Z + .38)], .018, 'iron')
        b.cylinder('iron', (x, TRACK_Y, WIRE_Z + .4), (x, TRACK_Y, WIRE_Z + .04), .012, 4)
        b.sphere('iron', (x, HALT - .32, WIRE_Z + .58), .07, 1)
    b.cylinder('steel_dark', (-2.0, TRACK_Y, WIRE_Z), (EAST_EDGE - .7, TRACK_Y, WIRE_Z), .022, 6)


def cut_faces(b):
    # Near edges of the diorama: limestone over a band of soil, on the south and east.
    k.stone_courses(b, RNG, 'x', TUNNEL_X - .4, EAST_EDGE, -.85, 0.0, NEAR_EDGE, depth=.28, course=.28)
    b.box('soil', ((TUNNEL_X + EAST_EDGE) / 2, NEAR_EDGE + .02, (BOTTOM - .85) / 2), (EAST_EDGE - TUNNEL_X + .4, .2, -.85 - BOTTOM), 0)
    k.stone_courses(b, RNG, 'y', NEAR_EDGE, HALT, -.85, 0.0, EAST_EDGE, depth=.28, course=.28)
    k.stone_courses(b, RNG, 'y', HALT, NORTH_EDGE, -.6, 1.0, EAST_EDGE, depth=.28, course=.32)
    b.box('soil', (EAST_EDGE - .02, (NEAR_EDGE + HALT) / 2, (BOTTOM - .85) / 2), (.2, HALT - NEAR_EDGE, -.85 - BOTTOM), 0)
    b.box('soil', (EAST_EDGE - .02, (HALT + NORTH_EDGE) / 2, (BOTTOM - .6) / 2), (.2, NORTH_EDGE - HALT, -.6 - BOTTOM), 0)
    for _ in range(80):
        if RNG.random() < .55:
            b.box('rock', (RNG.uniform(TUNNEL_X, EAST_EDGE - .1), NEAR_EDGE - .11, RNG.uniform(BOTTOM + .1, -.95)), (RNG.uniform(.12, .3), .1, RNG.uniform(.08, .2)), .03)
        else:
            b.box('rock', (EAST_EDGE + .1, RNG.uniform(NEAR_EDGE + .1, NORTH_EDGE - .2), RNG.uniform(BOTTOM + .1, -.7)), (.1, RNG.uniform(.12, .3), RNG.uniform(.08, .2)), .03)
    # The platform's far end: a short iron railing beyond the buffer stop.
    for y in (KERB + .15, (KERB + HALT) / 2, HALT - .1):
        b.box('iron', (EAST_EDGE - .12, y, .5), (.05, .05, 1.0), .01)
    for z in (.45, .95):
        b.box('iron', (EAST_EDGE - .12, (KERB + HALT) / 2 + .02, z), (.04, HALT - KERB - .2, .04), .005)


def retaining_wall(b):
    for x0, x1 in ((TUNNEL_X - .35, STAIRS[0]), (STAIRS[1], EAST_EDGE)):
        k.stone_courses(b, RNG, 'x', x0, x1, 0, 1.0, HALT, depth=.3, course=.333)
        b.box('limestone_pale', ((x0 + x1) / 2, HALT + .16, 1.05), (x1 - x0, .36, .1), .03)
    # Stair cheeks, then four treads rising a quarter each (the rules' four-step flight).
    k.stone_courses(b, RNG, 'y', HALT, HALT + 1.0, 0, 1.0, STAIRS[0] + .25, depth=.25, course=.333)
    k.stone_courses(b, RNG, 'y', HALT, HALT + 1.0, 0, 1.0, STAIRS[1], depth=.25, course=.333)
    for step in range(4):
        top = .25 * (step + 1)
        y0 = HALT + .25 * step
        for x0, w in ((STAIRS[0] + .25, .5), (STAIRS[0] + .75, .5), (STAIRS[0] + 1.25, .5)):
            b.box(['limestone', 'limestone_pale', 'limestone_warm'][(step + int(x0 * 3)) % 3], (x0 + w / 2, (y0 + HALT + 1.0) / 2, top / 2), (w - .02, HALT + 1.0 - y0, top), .02)
    for x in (STAIRS[0] + .17, STAIRS[1] - .17):
        b.cylinder('iron', (x, HALT + .05, .9), (x, HALT + .95, 1.9), .025, 6)
        for y, z in ((HALT + .05, 0.0), (HALT + .95, 1.0)):
            b.cylinder('iron', (x, y, z), (x, y, z + .9), .022, 6)
    # A brass spout over a stone basin, the lip worn on one side.
    sx = 7.0
    b.box('limestone_shade', (sx, HALT - .03, .62), (.5, .06, .5), .02)
    b.cylinder('brass', (sx, HALT - .03, .66), (sx, HALT - .17, .6), .03, 8)
    for dy in (-.09, .09):
        b.box('limestone_pale', (sx, HALT - .09 + dy, .16), (.62, .04, .32), .01)
    for dx in (-.29, .29):
        b.box('limestone_pale', (sx + dx, HALT - .09, .16), (.04, .2, .32), .01)
    b.box('limestone_shade', (sx, HALT - .09, .03), (.62, .2, .06), .01)
    b.box('water', (sx, HALT - .09, .27), (.52, .14, .01), 0)
    # The street's name, where you arrive: an enamel plate on the wall at the foot of the steps, and a chalk arrow.
    px = 10.0
    b.box('enamel_blue', (px, HALT - .02, .64), (1.36, .03, .32), .02)
    b.box('cream', (px, HALT - .036, .64), (1.28, .004, .24), 0)
    b.box('enamel_blue', (px, HALT - .04, .64), (1.24, .004, .2), 0)
    k.lettering('Street name', 'SPINDLE LANE', (px, HALT - .045, .64), .14, 'cream')
    for x0 in (px - .65, px + .65):
        b.sphere('iron', (x0, HALT - .04, .64), .018, 1)
    b.box('rail', (px + .52, HALT - .039, .74), (.14, .003, .05), 0)
    b.box('chalk', (px + .2, HALT - .003, .33), (.7, .004, .03), 0)
    for side in (-1, 1):
        b.box('chalk', (px + .5, HALT - .003, .33 + side * .05), (.18, .004, .025), 0, (0, side * math.radians(35), 0))
    # Ivy on the wall face.
    for cx, width in ((1.6, 1.6), (4.8, .8), (17.2, 2.0), (21.6, 1.0)):
        for _ in range(int(width * 22)):
            x = cx + RNG.uniform(-width / 2, width / 2)
            z = 1.05 - abs(RNG.gauss(0, .38))
            b.sphere(['leaf', 'leaf_dark', 'leaf_light'][RNG.randrange(3)], (x, HALT - .03, max(.08, z)), RNG.uniform(.05, .09), 1, (1, .45, 1))


def terrace_edge(b):
    # Hedge along the yard, an iron railing along the lane and the green.
    count = int((LANE[0] - .1 + .4) / .225)
    for i in range(count):
        x = -.35 + i * .225
        for row, (y, z, r) in enumerate(((HALT + .3, 1.3, (.2, .26)), (HALT + .45, 1.36, (.18, .24)), (HALT + .37, 1.52, (.13, .18)))):
            if row == 2 and i % 2:
                continue
            b.sphere(['leaf', 'leaf_dark', 'leaf_light', 'leaf'][RNG.randrange(4)], (x + RNG.uniform(-.06, .06), y + RNG.uniform(-.04, .04), z + RNG.uniform(-.05, .06)), RNG.uniform(*r), 1, (1, .9, .9))
    for x0, x1 in ((LANE[0] + .05, STAIRS[0] - .05), (STAIRS[1] + .05, EAST_EDGE - .2)):
        posts = max(2, int((x1 - x0) / 1.1) + 1)
        for i in range(posts):
            x = x0 + (x1 - x0) * i / (posts - 1)
            b.box('iron', (x, HALT + .22, 1.5), (.06, .06, 1.0), .01)
        b.box('iron', ((x0 + x1) / 2, HALT + .22, 1.98), (x1 - x0, .07, .05), .01)
        b.box('iron', ((x0 + x1) / 2, HALT + .22, 1.22), (x1 - x0, .05, .04), .01)
        bars = int((x1 - x0) / .16)
        for i in range(bars):
            x = x0 + (x1 - x0) * (i + .5) / bars
            b.cylinder('iron', (x, HALT + .22, 1.2), (x, HALT + .22, 1.96), .012, 5)


def tunnel(b):
    # The cutting where the hill tram comes up: a tall limestone headwall with a round arch over the track, dark
    # reveals going back into the hill, and planting over the top.
    def opening(mid, z):
        d = mid - TRACK_Y
        return abs(d) < ARCH_HALF + .02 and (z < ARCH_SPRING or d * d + (z - ARCH_SPRING) ** 2 < (ARCH_HALF + .03) ** 2)
    k.stone_courses(b, RNG, 'y', NEAR_EDGE, 2.7, -.85, 4.6, TUNNEL_X, depth=.4, course=.34, skip=opening)
    k.stone_courses(b, RNG, 'y', 2.7, HALT + .3, -.0, 2.2, TUNNEL_X, depth=.4, course=.34)
    for i in range(17):
        a = math.pi * i / 16
        b.box('limestone_pale', (TUNNEL_X + .03, TRACK_Y + math.cos(a) * (ARCH_HALF + .12), ARCH_SPRING + math.sin(a) * (ARCH_HALF + .12)), (.46, .22, .34), .03, (a - math.pi / 2, 0, 0))
    b.box('limestone_pale', (TUNNEL_X + .03, TRACK_Y, ARCH_SPRING + ARCH_HALF + .28), (.5, .4, .42), .03)
    depth = 1.4
    for side in (-1, 1):
        b.box('tunnel', (TUNNEL_X - depth / 2, TRACK_Y + side * (ARCH_HALF + .02), ARCH_SPRING / 2), (depth, .04, ARCH_SPRING), 0)
    for i in range(16):
        a0, a1 = math.pi * i / 16, math.pi * (i + 1) / 16
        am = (a0 + a1) / 2
        y = TRACK_Y + math.cos(am) * (ARCH_HALF + .02)
        z = ARCH_SPRING + math.sin(am) * (ARCH_HALF + .02)
        b.box('tunnel', (TUNNEL_X - depth / 2, y, z), (depth, .04, (ARCH_HALF + .02) * (a1 - a0) + .02), 0, (am, 0, 0))
    b.box('tunnel', (TUNNEL_X - depth, TRACK_Y, (ARCH_SPRING + ARCH_HALF) / 2), (.06, 2 * ARCH_HALF + .1, ARCH_SPRING + ARCH_HALF + .1), 0)
    b.box('limestone_pale', (TUNNEL_X - .2, (NEAR_EDGE + 2.7) / 2, 4.66), (.62, 2.7 - NEAR_EDGE + .1, .14), .03)
    b.box('limestone_pale', (TUNNEL_X - .2, (2.7 + HALT + .3) / 2, 2.26), (.62, HALT + .3 - 2.7, .14), .03)
    # The hill the cutting goes into: solid behind the headwall, cut off at the diorama's edge like the terraces, so
    # nothing of the tunnel's back shows past the portal; a grassy bank and shrubs on top.
    hill = TUNNEL_X - 3.0
    back = TUNNEL_X - .4
    bore = (TRACK_Y - ARCH_HALF - .05, TRACK_Y + ARCH_HALF + .05, ARCH_SPRING + ARCH_HALF + .05)
    for y0, y1, z0 in ((NEAR_EDGE, bore[0], BOTTOM), (bore[1], 2.7, BOTTOM), (bore[0], bore[1], bore[2])):
        b.box('soil_dark', ((hill + back) / 2, (y0 + y1) / 2, (z0 + 4.68) / 2), (back - hill, y1 - y0, 4.68 - z0), 0)
    b.box('soil_dark', ((hill + back) / 2, (bore[0] + bore[1]) / 2, (BOTTOM - .02) / 2), (back - hill, bore[1] - bore[0], -.02 - BOTTOM), 0)
    b.box('soil_dark', ((hill + TUNNEL_X - .4) / 2, (2.7 + HALT + .3) / 2, (BOTTOM + 2.2) / 2), (TUNNEL_X - .4 - hill, HALT + .3 - 2.7, 2.2 - BOTTOM), 0)
    k.stone_courses(b, RNG, 'x', hill, TUNNEL_X - .4, -.85, 4.6, NEAR_EDGE, depth=.28, course=.34)
    b.box('soil', ((hill + TUNNEL_X - .4) / 2, NEAR_EDGE + .02, (BOTTOM - .85) / 2), (TUNNEL_X - .4 - hill, .2, -.85 - BOTTOM), 0)
    k.quad_surface('Hill over the cutting', 'grass', [(hill, NEAR_EDGE, TUNNEL_X - .4, 2.7)], 8.0, 4.7)
    k.quad_surface('Bank beside the yard', 'grass', [(hill, 2.7, TUNNEL_X - .4, HALT + .3)], 8.0, 2.22)
    for _ in range(46):
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][RNG.randrange(3)], (TUNNEL_X - .5 + RNG.uniform(-.2, .15), RNG.uniform(NEAR_EDGE, 2.6), 4.8 + RNG.uniform(0, .25)), RNG.uniform(.2, .34), 1)
    for _ in range(30):
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][RNG.randrange(3)], (TUNNEL_X - .45 + RNG.uniform(-.15, .1), RNG.uniform(2.8, HALT + .2), 2.4 + RNG.uniform(0, .2)), RNG.uniform(.17, .28), 1)
    for _ in range(50):
        y = RNG.uniform(NEAR_EDGE, 2.6)
        b.sphere(['leaf', 'leaf_dark'][RNG.randrange(2)], (TUNNEL_X + .02, y, 4.55 - abs(RNG.gauss(0, .7))), RNG.uniform(.05, .08), 1, (.45, 1, 1))


def balustrade(b):
    piers = [LANE[0] + .2, GATE[0] - .25, GATE[1] + .25, 16.2, 18.2, 20.2, 22.2, EAST_EDGE - .2]
    for x0, x1 in ((LANE[0], GATE[0] - .25), (GATE[1] + .25, EAST_EDGE)):
        b.box('limestone', ((x0 + x1) / 2, RAIL_Y, 1.12), (x1 - x0, .42, .24), .03)
    for x in piers:
        tall = 1.75 if x in (GATE[0] - .25, GATE[1] + .25) else 1.15
        b.box(['limestone', 'limestone_pale'][int(x) % 2], (x, RAIL_Y, 1.0 + tall / 2), (.42, .42, tall), .035)
        b.box('limestone_pale', (x, RAIL_Y, 1.0 + tall + .05), (.52, .52, .1), .03)
        if tall > 1.5:
            b.sphere('limestone_pale', (x, RAIL_Y, 1.0 + tall + .22), .14, 2)
    for x0, x1 in zip(piers, piers[1:]):
        if x0 == GATE[0] - .25:
            continue
        x0 += .22
        x1 -= .22
        b.box('iron', ((x0 + x1) / 2, RAIL_Y, 2.02), (x1 - x0, .05, .05), .01)
        b.box('iron', ((x0 + x1) / 2, RAIL_Y, 1.3), (x1 - x0, .05, .04), .01)
        bars = int((x1 - x0) / .15)
        for i in range(bars):
            x = x0 + (i + .5) * (x1 - x0) / bars
            b.cylinder('iron', (x, RAIL_Y, 1.24), (x, RAIL_Y, 2.0), .012, 5)
    # The gate at the head of the town steps: two iron leaves, shut, a ring latch.
    mid = (GATE[0] + GATE[1]) / 2
    for x0, x1 in ((GATE[0] - .02, mid - .02), (mid + .02, GATE[1] + .02)):
        b.box('iron', ((x0 + x1) / 2, RAIL_Y, 1.12), (x1 - x0, .05, .05), .01)
        b.box('iron', ((x0 + x1) / 2, RAIL_Y, 2.25), (x1 - x0, .05, .05), .01)
        for x in (x0, x1):
            b.box('iron', (x, RAIL_Y, 1.7), (.05, .05, 1.2), .01)
        for i in range(6):
            x = x0 + (i + .5) * (x1 - x0) / 6
            b.cylinder('iron', (x, RAIL_Y, 1.1), (x, RAIL_Y, 2.25 + .12 * math.sin(math.pi * (i + .5) / 6)), .014, 5)
        k.h.torus('Gate scroll', ((x0 + x1) / 2, RAIL_Y, 1.68), .2, .014, 'iron', (math.pi / 2, 0, 0))
    k.h.torus('Gate ring latch', (mid, RAIL_Y - .05, 1.6), .06, .012, 'brass', (math.pi / 2, 0, 0))
    # Steps dropping away beyond the gate toward the square.
    for i in range(7):
        top = 1.0 - .22 * (i + 1)
        y = RAIL_Y + .3 + .3 * i
        b.box(['limestone', 'limestone_pale'][i % 2], (mid, y + .15, top - .3), (2.0, .3, .6), .02)
    for x in (GATE[0] - .2, GATE[1] + .2):
        b.box('limestone_shade', (x, RAIL_Y + 1.35, .3), (.32, 2.2, 1.4), .03)
    b.box('limestone', (mid, RAIL_Y + .25, .8), (2.4, .2, .4), .02)


def east_wall(b):
    k.stone_courses(b, RNG, 'y', HALT + .3, RAIL_Y - .2, 1.0, 1.42, EAST_EDGE, depth=.45, course=.21, block=(.4, .7))
    b.box('limestone_pale', (EAST_EDGE - .23, (HALT + .3 + RAIL_Y - .2) / 2, 1.46), (.52, RAIL_Y - .5 - HALT, .08), .02)
    y = HALT + .5
    while y < RAIL_Y - .4:
        if not (CAT[1] - 1.6 < y < CAT[1] + 1.4 or PUMP[1] - .9 < y < PUMP[1] + .9 or y > 25.6):
            b.sphere(['leaf', 'leaf_dark', 'leaf_light', 'leaf'][RNG.randrange(4)], (EAST_EDGE - .35 + RNG.uniform(-.1, .1), y + RNG.uniform(-.05, .05), 1.6 + RNG.uniform(-.02, .22)), RNG.uniform(.17, .28), 1, (.9, 1, .9))
        y += .105


def fences(b):
    # The white picket fence along Bram's garden, its return to Nell's corner, and its shut gate.
    x = FENCE_X
    y0, y1 = FENCE_Y
    g0, g1 = GARDEN_GATE
    for y in (y0, (y0 + g0) / 2, g0 - .03, g1 + .03, (g1 + y1) / 2, y1):
        b.box('white', (x, y, 1.48), (.1, .1, .96), .015)
    for z in (1.3, 1.7):
        for a, c in ((y0, g0), (g1, y1)):
            b.box('white', (x + .05, (a + c) / 2, z), (.04, c - a, .06), .01)
    y = y0 + .08
    while y < y1 - .02:
        if not g0 - .01 < y < g1 + .01:
            b.box('white', (x + .08, y, 1.42), (.035, .07, .78), .008)
            b.box('white', (x + .08, y, 1.84), (.035, .05, .05), .01, (math.radians(45), 0, 0))
        y += .155
    for z in (1.25, 1.75):
        b.box('white', (x + .07, (g0 + g1) / 2, z), (.04, g1 - g0 - .1, .06), .01)
    for i in range(6):
        b.box('white', (x + .09, g0 + .13 + i * .16, 1.5), (.035, .07, .6), .008)
    b.box('white', (x + .09, (g0 + g1) / 2, 1.5), (.03, .06, 1.05), .008, (math.atan2(.5, .9), 0, 0))
    b.box('brass', (x + .12, g1 - .13, 1.55), (.02, .05, .05), .005)
    b.box('white', ((8.62 + x) / 2, y0, 1.48), (x - 8.62, .1, .1), .01)
    for xx in (8.75, 9.05):
        b.box('white', (xx, y0 - .06, 1.42), (.07, .035, .78), .008)
    # Bram's garden: a bed along his cottage, stepping stones from the gate to his door, bushes and a barrel.
    for i in range(10):
        k.flower_clump(b, (5.35, 23.75 + i * .36, 1.0), .16, RNG, ('flower_pink', 'flower_white', 'flower_violet'))
    for x0, y in ((8.5, 25.0), (7.6, 24.95), (6.7, 24.9), (5.85, 24.85)):
        b.box('limestone_pale', (x0 + RNG.uniform(-.08, .08), y, 1.01), (.4, .32, .03), .02)
    for x0, y0 in ((8.9, 26.6), (6.0, 26.9), (8.95, 23.15)):
        for _ in range(5):
            b.sphere(['leaf', 'leaf_dark', 'leaf_light'][RNG.randrange(3)], (x0 + RNG.uniform(-.25, .25), y0 + RNG.uniform(-.2, .2), 1.25 + RNG.uniform(0, .2)), RNG.uniform(.18, .26), 1)
    b.cylinder('wood_dark', (6.2, 22.95, 1.0), (6.2, 22.95, 1.62), .26, 12)
    for z in (1.12, 1.5):
        b.cylinder('iron', (6.2, 22.95, z - .02), (6.2, 22.95, z + .02), .268, 12)
    b.cylinder('water', (6.2, 22.95, 1.6), (6.2, 22.95, 1.61), .22, 12)


def pole(b, at, arm_along_y=False):
    x, y = at
    b.box('limestone', (x, y, 1.2), (.36, .36, .4), .03)
    b.box('iron', (x, y, 1.47), (.2, .2, .14), .015)
    b.box('timber', (x, y, (1.4 + POLE_TOP + .2) / 2), (.15, .15, POLE_TOP + .2 - 1.4), .02)
    arm = (0, .55, 0) if arm_along_y else (.55, 0, 0)
    size = (.1, 1.2, .11) if arm_along_y else (1.2, .1, .11)
    b.box('timber', (x, y, POLE_TOP - .12), size, .015)
    tips = []
    for side in (-1, 0, 1):
        tx = x + arm[0] * side
        ty = y + arm[1] * side
        b.cylinder('white', (tx, ty, POLE_TOP - .06), (tx, ty, POLE_TOP + .06), .035, 8)
        b.cylinder('ceramic', (tx, ty, POLE_TOP + .06), (tx, ty, POLE_TOP + .1), .045, 8)
        tips.append((tx, ty, POLE_TOP + .1))
    b.box('timber', (x + arm[0] * .4, y + arm[1] * .4, POLE_TOP - .4), (.06, .06, .55), .01, (0, math.radians(35), 0) if not arm_along_y else (math.radians(-35), 0, 0))
    b.box('steel', (x + .1, y - .1, 2.3), (.18, .1, .26), .02)
    return tips


def poles_and_wires(b):
    south = pole(b, POLES['south'])
    middle = pole(b, POLES['middle'])
    north = pole(b, POLES['north'])
    wires = [
        ((15.9, 32.0, 4.2), north[0], .5), ((16.5, 32.0, 4.2), north[2], .5),
        (north[0], middle[0], .32), (north[2], middle[2], .32), (north[1], middle[1], .3),
        (middle[0], south[0], .4), (middle[2], south[2], .4),
        (north[1], (14.35, 27.3, 3.62), .12),
        (north[0], (5.08, 25.45, 5.0), .35),
        (middle[0], (9.47, 15.0, 6.35), .3),
        (south[1], (11.6, 4.05, 2.62), .3),
    ]
    for i, (a, z, sag) in enumerate(wires):
        k.catenary('Overhead wire %d' % i, a, z, sag)
    b.box('iron', (5.06, 25.45, 4.95), (.08, .14, .08), .01)
    b.cylinder('white', (5.12, 25.45, 4.95), (5.12, 25.45, 5.05), .03, 8)


def green(b):
    # The tree's raised round bed, kerbs, the allotment, the pump's apron and a second tree's ring of flowers.
    cx, cy = TREE_BED
    for i in range(14):
        a = math.tau * i / 14
        b.box(['limestone', 'limestone_pale', 'limestone_warm'][i % 3], (cx + math.cos(a) * .98, cy + math.sin(a) * .98, 1.13), (.44, .24, .26), .04, (0, 0, a + math.pi / 2))
    b.cylinder('soil', (cx, cy, 1.0), (cx, cy, 1.2), .9, 20)
    for i in range(9):
        a = math.tau * i / 9 + .3
        k.flower_clump(b, (cx + math.cos(a) * .66, cy + math.sin(a) * .66, 1.2), .12, RNG, ('flower_white', 'flower_yellow', 'flower_blue'), count=4)
    for i in range(10):
        a = math.tau * i / 10
        k.flower_clump(b, (21.2 + math.cos(a) * .75, 19.6 + math.sin(a) * .75, 1.0), .12, RNG, ('flower_pink', 'flower_white', 'flower_violet'), count=4)
    b.box('limestone_pale', (GREEN_X, (HALT + .6 + LOOKOUT_Y) / 2, 1.02), (.12, LOOKOUT_Y - HALT - .6, .05), .015)
    b.box('limestone_pale', ((GREEN_X + EAST_EDGE - .45) / 2, LOOKOUT_Y, 1.02), (EAST_EDGE - .45 - GREEN_X, .12, .05), .015)
    for y in (5.9, 6.5, 7.1):
        b.box('soil_dark', (19.3, y, 1.06), (2.8, .42, .12), .05)
        for i in range(8):
            b.sphere(['leaf_light', 'leaf'][i % 2], (18.1 + i * .34, y, 1.16), .085, 1, (1, 1, .7))
    for x0, x1, y in ((17.75, 20.85, 5.42), (17.75, 20.85, 7.58)):
        b.box('wood', ((x0 + x1) / 2, y, 1.06), (x1 - x0, .06, .12), .01)
    for x in (17.75, 20.85):
        b.box('wood', (x, 6.5, 1.06), (.06, 2.2, .12), .01)
    for x in (20.2, 20.55):
        for lean in (-.12, .12):
            b.cylinder('wood_light', (x + lean, 7.1, 1.05), (x, 7.1, 1.95), .012, 4)
        for z in (1.3, 1.55, 1.8):
            b.sphere('leaf', (x + RNG.uniform(-.08, .08), 7.1 + RNG.uniform(-.06, .06), z), .08, 1)
    px, py = PUMP
    for i in range(9):
        a = math.tau * i / 9 + .2
        r = .55 + (i % 2) * .12
        b.box(['limestone', 'limestone_pale', 'limestone_warm'][i % 3], (px + .05 + math.cos(a) * r, py - .1 + math.sin(a) * r * .8, 1.01), (.36, .3, .03), .03, (0, 0, a))
    # Wildflowers and tufts on the green, at the foot of the walls and along the platform.
    for _ in range(18):
        k.flower_clump(b, (RNG.uniform(18.0, 22.6), RNG.uniform(8.4, 21.0), 1.0), .1, RNG, ('flower_white', 'flower_yellow'), count=3)
    for _ in range(60):
        x, y = RNG.uniform(17.7, 22.8), RNG.uniform(4.9, 21.3)
        if 17.6 <= x <= 21.0 and 5.3 <= y <= 7.7:
            continue
        for j in range(3):
            b.cylinder(['leaf_light', 'leaf', 'leaf_dark'][j], (x + j * .03, y, 1.0), (x + j * .03 + RNG.uniform(-.05, .05), y + RNG.uniform(-.04, .04), 1.1 + RNG.uniform(0, .06)), .012, 3, .002)
    for x in (2.2, 5.6, 15.2, 17.0, 23.0):
        k.flower_clump(b, (x, HALT - .2, 0.0), .15, RNG, ('flower_white', 'flower_pink', 'flower_yellow'), count=5)


def pots(b):
    # Terracotta pots against walls and railings, out of the walking cells.
    for x, y, z, s in ((EAST_EDGE - .45, HALT - .25, 0.0, 1.0),
                       (.3, HALT - .25, 0.0, .9), (17.1, 26.8, 1.0, 1.0), (EAST_EDGE - .5, 26.75, 1.0, .9)):
        k.h.pot((x, y, z), s, False, True)


def yard(b):
    # West edge behind the yard: shrubs where the hill rises.
    for _ in range(20):
        b.sphere(['leaf', 'leaf_dark', 'leaf_light'][RNG.randrange(3)], (-.35 + RNG.uniform(-.1, .15), RNG.uniform(HALT + .5, 9.4), 1.25 + RNG.uniform(0, .4)), RNG.uniform(.28, .4), 1)
    for _ in range(10):
        k.flower_clump(b, (RNG.uniform(-.2, 3.0), RNG.uniform(HALT + .5, 7.4), 1.0), .14, RNG, ('flower_white', 'flower_yellow', 'flower_pink'), count=4)


def lived_in(b):
    # Chalk squares someone has hopped through, Nell's coir mat, a basket on the middle pole, and Pepper, the
    # grey cat from the notice board, asleep on the warm coping of the east wall.
    for i, (dx, dy) in enumerate(((0, 0), (0, .55), (-.28, 1.1), (.28, 1.1), (0, 1.65), (-.28, 2.2), (.28, 2.2), (0, 2.75))):
        x, y = 12.4 + dx, 7.2 + dy
        for (ax, ay, sx, sy) in ((0, -.26, .52, .03), (0, .26, .52, .03), (-.26, 0, .03, .52), (.26, 0, .03, .52)):
            b.box('chalk', (x + ax, y + ay, 1.003), (sx, sy, .004), 0)
    b.box('wood_light', (9.75, 12.0, 1.006), (.42, .95, .012), .004)
    for i in range(6):
        b.box('wood', (9.75, 11.6 + i * .16, 1.012), (.38, .04, .004), 0)
    mx, my = POLES['middle']
    b.box('iron', (mx - .3, my, 3.2), (.6, .04, .04), .005)
    k.h.curve('Basket chain', [(mx - .58, my, 3.2), (mx - .62, my, 2.95)], .006, 'iron')
    b.sphere('wood_light', (mx - .62, my, 2.82), .2, 2, (1, 1, .6))
    k.flower_clump(b, (mx - .62, my, 2.84), .15, RNG, ('flower_red', 'flower_white', 'flower_violet'), count=6)
    for i in range(5):
        a = math.tau * i / 5
        k.h.curve('Trailing basket ivy', [(mx - .62 + math.cos(a) * .18, my + math.sin(a) * .18, 2.82), (mx - .62 + math.cos(a) * .24, my + math.sin(a) * .24, 2.55)], .008, 'leaf_dark')
    cx, cy, cz = CAT
    b.sphere('cat', (cx, cy, cz + .1), .17, 2, (1.05, 1.5, .62))
    b.sphere('cat', (cx - .02, cy + .2, cz + .14), .1, 2, (1, .95, .85))
    for side in (-1, 1):
        b.cylinder('cat', (cx - .02 + side * .05, cy + .2, cz + .2), (cx - .02 + side * .055, cy + .21, cz + .29), .03, 4, .004)
    k.h.curve('Cat tail', [(cx + .05, cy - .25, cz + .07), (cx + .14, cy - .1, cz + .05), (cx + .12, cy + .1, cz + .05), (cx + .05, cy + .2, cz + .06)], .03, 'cat')
    b.sphere('cat_light', (cx - .1, cy + .25, cz + .1), .04, 1)


def make():
    b = k.Batch(RNG)
    ground(b)
    track(b)
    cut_faces(b)
    retaining_wall(b)
    terrace_edge(b)
    tunnel(b)
    balustrade(b)
    east_wall(b)
    fences(b)
    poles_and_wires(b)
    green(b)
    pots(b)
    yard(b)
    lived_in(b)
    b.finish()


if __name__ == '__main__':
    k.guard([ASSET])
    k.start(ASSET)
    make()
    k.save(ASSET, 'author_set.py', {'poles': POLES})
