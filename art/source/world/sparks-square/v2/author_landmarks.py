"""One-time authoring of Guildhall Square's landmarks, after docs/concept/v0.72/art/guildhall-square.png: the amber
root-power beacon, the guild hall, the post office and the terrace of three shop-houses on the square's west side.

Run with Blender: blender -b --python author_landmarks.py [-- asset ...]. Refuses any existing master; after
creation each model.blend is the authority. Origins are the ground centre of the footprint.
"""
import math
import random
import sys
from pathlib import Path
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import square_kit as s  # noqa: E402

k, h = s.k, s.h
RECORD = 'author_landmarks.py'


# --- the beacon -----------------------------------------------------------------------------------------------------
def beacon():
    """Octagonal limestone steps and a stone drum with the big pressure dial on the face toward the camera (south-
    east), a little notice board and a kiosk door on its neighbours; teal columns hold an amber glass bell over a
    glowing root; a ribbed copper dome, a lantern and a gold finial. About eight metres to the finial."""
    rng = random.Random(29102)
    b = k.Batch(rng)
    tones = ('limestone', 'limestone_pale', 'limestone_warm')
    for apothem, z0, z1 in ((3.25, 0, .18), (2.95, .18, .36), (2.65, .36, .54)):
        s.octagon(b, 'limestone_shade', z0, z1 - .03, apothem - .04)
        side = 2 * apothem * math.tan(math.pi / 8)
        for f in range(8):
            angle = f * math.pi / 4
            centre, out, along = s.face_frame(angle, apothem - .15)
            count = max(2, round(side / .6))
            for i in range(count):
                p = centre + along * (-side / 2 + side * (i + .5) / count)
                b.box(tones[(i + f) % 3], (p.x, p.y, z1 - .045), (.3, side / count - .035, .09), .022, (0, 0, angle))
    # The drum: dressed courses, a dark base course, quoins at every corner and a moulded cornice.
    DRUM = 2.3
    s.octagon(b, 'limestone_shade', .54, .72, 2.32)
    s.octagon(b, 'ashlar', .72, DRUM - .2, 2.2)
    for i, (x, y) in enumerate(s.octagon_points(2.2)):
        for j in range(5):
            z = .84 + j * .29
            long = (i + j) % 2 == 0
            a = math.atan2(y, x)
            b.box('limestone_pale', (x * 1.01, y * 1.01, z), (.34 if long else .22, .2, .26), .025, (0, 0, a))
    s.octagon(b, 'limestone_pale', DRUM - .22, DRUM - .08, 2.36)
    s.octagon(b, 'limestone', DRUM - .08, DRUM, 2.27)
    for i, (x, y) in enumerate(s.octagon_points(2.4)):
        b.box('limestone_pale', (x * .97, y * .97, DRUM - .16), (.1, .1, .05), .01)
    # South-east face, toward the camera: the big low-reading dial in a teal enamel surround, a brass hatch and
    # the brass pipes that leave the drum into the paving.
    c, out, along = s.face_frame(-math.pi / 4, 2.2)
    rot = (math.pi / 2, 0, -math.pi / 4 + math.pi / 2)
    b.box('teal_dark', tuple(c + out * .03 + Vector((0, 0, 1.45))), (.06, 1.5, 1.2), .02, (0, 0, -math.pi / 4))
    dial = c + out * .07 + Vector((0, 0, 1.45))
    h.cylinder('Dial face', tuple(dial), .52, .03, 'enamel_cream', 40).rotation_euler = rot
    h.torus('Dial brass ring', tuple(dial + out * .02), .54, .045, 'brass', rot)
    h.torus('Dial inner ring', tuple(dial + out * .02), .43, .008, 'ink', rot)
    for i in range(16):
        a = math.tau * i / 16
        p = dial + out * .025 + along * math.cos(a) * .46 + Vector((0, 0, math.sin(a) * .46))
        major = i % 4 == 0
        radial = along * math.cos(a) + Vector((0, 0, math.sin(a)))
        tangent = Vector((0, 0, math.cos(a))) - along * math.sin(a)
        b.box('ink', tuple(p), (.012, .022 if major else .012, .07 if major else .04), 0, s.basis_rotation(out, -tangent, radial))
    for i in range(4):
        a = math.radians(200 + i * 25)
        p = dial + out * .026 + along * math.cos(a) * .31 + Vector((0, 0, math.sin(a) * .31))
        b.box('red', tuple(p), (.01, .05, .05), 0, (0, 0, -math.pi / 4))
    needle_angle = math.radians(212)
    tip = dial + out * .04 + along * math.cos(needle_angle) * .4 + Vector((0, 0, math.sin(needle_angle) * .4))
    b.cylinder('red_dark', tuple(dial + out * .04), tuple(tip), .012, 6, .005)
    b.sphere('brass', tuple(dial + out * .05), .045, 1)
    for z in (.84, .96):
        b.box('brass', tuple(c + out * .05 + Vector((0, 0, z))), (.04, .9, .03), .005, (0, 0, -math.pi / 4))
    b.box('brass', tuple(c + out * .05 + Vector((0, 0, .66))), (.05, .55, .28), .01, (0, 0, -math.pi / 4))
    for side in (-1, 1):
        p = c + out * .12 + along * side * .16
        b.cylinder('brass', (p.x, p.y, .7), (p.x, p.y, .1), .055, 10)
        b.cylinder('brass', (p.x, p.y, .12), tuple(c + out * 1.2 + along * side * .16 + Vector((0, 0, .06))), .055, 10)
        for z in (.45, .2):
            b.cylinder('brass', (p.x, p.y, z - .03), (p.x, p.y, z + .03), .075, 10)
    # South face: the square's own notice board under a little tiled hood, papers pinned to it.
    c, out, along = s.face_frame(-math.pi / 2, 2.2)
    board = c + out * .18
    for side in (-1, 1):
        p = board + along * side * .55
        b.box('wood_dark', (p.x, p.y, 1.05), (.08, .08, 1.0), .01)
    b.box('wood', (board.x, board.y, 1.12), (.05, 1.15, .78), .01, (0, 0, -math.pi / 2))
    b.box('cork' if 'cork' in k.M else 'wood_light', tuple(board + out * .03 + Vector((0, 0, 1.12))), (.02, 1.02, .66), 0, (0, 0, -math.pi / 2))
    for i, (u, v, w, hh, mat) in enumerate(((-.3, 1.3, .3, .22, 'paper'), (.05, 1.28, .26, .3, 'paper'), (.33, 1.2, .2, .26, 'enamel_cream'),
                                             (-.25, .98, .34, .2, 'paper'), (.18, .95, .3, .22, 'paper'))):
        p = board + out * .05 + along * u
        b.box(mat, (p.x, p.y, v), (.01, w, hh), 0, (0, 0, -math.pi / 2 + (i % 3 - 1) * .0))
        b.sphere('red', tuple(p + out * .01 + Vector((0, 0, hh / 2 - .03))), .015, 1)
    hood = board + out * .1
    for tilt in (-1, 1):
        b.box('terracotta', tuple(hood + along * tilt * .3 + Vector((0, 0, 1.62))), (.36, .7, .05), .015, (-tilt * .42, 0, -math.pi / 2))
    # East face: a low maintenance door with a tiled hood and a brass pull.
    c, out, along = s.face_frame(0, 2.2)
    b.box('teal', tuple(c + out * .02 + Vector((0, 0, 1.15))), (.07, .72, 1.18), .02)
    for z in (.85, 1.42):
        b.box('teal_dark', tuple(c + out * .06 + Vector((0, 0, z))), (.02, .52, .4), .01)
    b.sphere('brass', tuple(c + out * .08 + along * .24 + Vector((0, 0, 1.1))), .035, 1)
    for tilt in (-1, 1):
        b.box('terracotta', tuple(c + out * .3 + along * tilt * .22 + Vector((0, 0, 1.86))), (.55, .48, .05), .015, (-tilt * .45, 0, 0))
    b.box('terracotta_dark', tuple(c + out * .3 + Vector((0, 0, 1.97))), (.56, .07, .07), .01)
    for side in (-1, 1):
        b.box('iron', tuple(c + out * .2 + along * side * .4 + Vector((0, 0, 1.7))), (.4, .03, .03), .005)
    # Valve wheels on spindles on two faces, a plaque, and ivy up the camera-side faces.
    for angle in (-3 * math.pi / 4, math.pi / 4):
        c, out, along = s.face_frame(angle, 2.2)
        hub = c + out * .2 + Vector((0, 0, 1.15))
        b.cylinder('brass', tuple(c), tuple(hub), .035, 8)
        rot = (math.pi / 2, 0, angle + math.pi / 2)
        h.torus('Valve wheel', tuple(hub), .2, .025, 'brass', rot)
        for i in range(5):
            a = i * math.tau / 5
            p = hub + along * math.cos(a) * .19 + Vector((0, 0, math.sin(a) * .19))
            b.cylinder('brass', tuple(hub), tuple(p), .014, 6)
        b.sphere('brass', tuple(hub + out * .02), .045, 1)
    c, out, along = s.face_frame(math.pi, 2.2)
    b.box('brass', tuple(c + out * .02 + Vector((0, 0, 1.35))), (.03, .7, .42), .01, (0, 0, math.pi))
    for angle, lean in ((-math.pi / 2, -1), (0, 1)):
        c, out, along = s.face_frame(angle, 2.22)
        s.ivy(b, rng, [tuple(c + along * lean * .75 + Vector((0, 0, .6))), tuple(c + along * lean * .62 + Vector((0, 0, 1.4))),
                       tuple(c + along * lean * .3 + Vector((0, 0, 2.0)))], .1, (out.x, out.y), 10, .15)
    # Planted boxes on the steps and two clipped cones beside the dial.
    for angle in (-math.pi / 2 - .26, -math.pi / 2 + .2, .26, -.2, math.pi * .62, math.pi * .9):
        p = Vector((math.cos(angle), math.sin(angle), 0)) * 2.48
        b.box('wood_dark', (p.x, p.y, .66), (.52, .26, .24), .02, (0, 0, angle + math.pi / 2))
        k.flower_clump(b, (p.x, p.y, .78), .2, rng, ('flower_pink', 'flower_white', 'flower_red', 'flower_yellow'), count=8)
    for angle in (-math.pi / 4 - .3, -math.pi / 4 + .3):
        p = Vector((math.cos(angle), math.sin(angle), 0)) * 2.52
        s.topiary(b, rng, (p.x, p.y, .54), .95, .28, .4)
    # The crown: a brass foot ring, a bolted teal collar, four columns with brass bands and two lanterns.
    base = DRUM
    b.cylinder('brass', (0, 0, base), (0, 0, base + .14), 1.78, 32)
    b.cylinder('teal', (0, 0, base + .14), (0, 0, base + .46), 1.62, 32)
    for i in range(24):
        a = math.tau * i / 24
        b.sphere('brass', (math.cos(a) * 1.63, math.sin(a) * 1.63, base + .3), .03, 1)
    h.torus('Collar rim', (0, 0, base + .46), 1.6, .04, 'brass')
    col_top = 6.55
    for i, a in enumerate((0, math.pi / 2, math.pi, 3 * math.pi / 2)):
        x, y = math.cos(a) * 1.58, math.sin(a) * 1.58
        b.cylinder('brass', (x, y, base + .14), (x, y, base + .46), .18, 12)
        b.cylinder('teal', (x, y, base + .46), (x, y, col_top), .12, 12)
        for z in (3.3, 4.6, 5.9):
            b.cylinder('brass', (x, y, z - .05), (x, y, z + .05), .145, 12)
        b.cylinder('brass', (x, y, col_top - .1), (x, y, col_top + .08), .18, 12, .21)
    for a in (0, -math.pi / 2):
        x, y = math.cos(a) * 1.58, math.sin(a) * 1.58
        out = Vector((math.cos(a), math.sin(a), 0))
        arm = Vector((x, y, 4.95)) + out * .4
        b.cylinder('iron', (x + out.x * .1, y + out.y * .1, 4.95), tuple(arm), .02, 6)
        b.cylinder('iron', tuple(arm), tuple(arm + Vector((0, 0, -.1))), .015, 6)
        lamp = arm + Vector((0, 0, -.32))
        b.cylinder('iron', tuple(lamp + Vector((0, 0, .15))), tuple(lamp + Vector((0, 0, .24))), .11, 6, .03)
        h.cylinder('Beacon lantern glass', tuple(lamp), .085, .26, 'lamp_glass', 6)
        b.cylinder('iron', tuple(lamp + Vector((0, 0, -.15))), tuple(lamp + Vector((0, 0, -.13))), .1, 6)
        for i in range(6):
            q = lamp + Vector((math.cos(i * math.tau / 6) * .095, math.sin(i * math.tau / 6) * .095, 0))
            b.cylinder('iron', tuple(q + Vector((0, 0, -.14))), tuple(q + Vector((0, 0, .15))), .008, 4)
    # The bell: amber glass, brass glazing bars following its swell, hoops tying it to the columns.
    centre_z, rx, rz = 4.62, 1.3, 1.85
    h.sphere('Beacon bell glass', (0, 0, centre_z), (rx, rx, rz), 'beacon_glass', 40, 20)
    for i in range(8):
        a = math.tau * i / 8 + math.pi / 8
        points = []
        for j in range(9):
            t = (-1 + 2 * j / 8) * .93
            r = rx * math.sqrt(max(0.0, 1 - t * t)) + .012
            points.append((math.cos(a) * r, math.sin(a) * r, centre_z + t * rz))
        h.curve('Glazing bar', points, .014, 'brass')
    for t in (-.6, 0, .6):
        r = rx * math.sqrt(1 - t * t) + .02
        h.torus('Bell hoop', (0, 0, centre_z + t * rz), r, .022, 'brass')
    for a in (0, math.pi / 2, math.pi, 3 * math.pi / 2):
        r = rx + .02
        b.cylinder('brass', (math.cos(a) * r, math.sin(a) * r, centre_z), (math.cos(a) * 1.48, math.sin(a) * 1.48, centre_z), .025, 6)
    # The root: a living trunk out of a curl of roots, forking into limbs that reach up the glass; a warm heart
    # where it forks.
    def inside(a, z, fraction):
        r = rx * math.sqrt(max(0.0, 1 - ((z - centre_z) / rz) ** 2)) * fraction
        return (math.cos(a) * r, math.sin(a) * r, z)
    for i in range(6):
        a = i * math.tau / 6 + .3
        h.curve('Root curl', [(0, 0, 3.15), inside(a, 3.05, .45), inside(a + .5, 3.0, .7), inside(a + 1.0, 3.12, .78)], .045, 'spark')
    h.curve('Root trunk', [(0, 0, 2.95), (.08, .03, 3.4), (-.06, .02, 3.9), (0, 0, 4.3)], .14, 'spark')
    limbs = []
    for i in range(5):
        a = i * math.tau / 5 + .5
        end = Vector(inside(a, 5.55 + (i % 2) * .35, .8))
        mid = Vector(inside(a, 4.75, .38))
        h.curve('Root limb', [(0, 0, 4.2), tuple(mid), tuple(end)], .07, 'spark')
        limbs.append((mid, end, a))
    for mid, end, a in limbs:
        for side in (-1, 1):
            tip = Vector(inside(a + side * .42, min(end.z + .32, 6.2), .78))
            h.curve('Root twig', [tuple(mid.lerp(end, .55)), tuple(mid.lerp(end, .8) + Vector((0, 0, .1))), tuple(tip)], .03, 'spark')
        h.curve('Root twig', [tuple(mid.lerp(end, .3)), tuple(Vector(inside(a - .3, mid.z + .45, .7)))], .03, 'spark')
    h.sphere('Spark heart', (0, 0, 4.3), (.17, .17, .19), 'spark_core', 20, 10)
    # The cap: a copper cornice with brass edges on the columns, a ribbed dome, a glazed lantern, a finial.
    cap = col_top + .08
    b.cylinder('copper_dark', (0, 0, cap), (0, 0, cap + .17), 1.82, 32)
    h.torus('Cap edge', (0, 0, cap + .17), 1.8, .045, 'brass')
    h.torus('Cap lower edge', (0, 0, cap + .01), 1.8, .03, 'brass')
    dome_r, dome_h = 1.6, 1.05
    s.dome('Copper dome', (0, 0, cap + .17), dome_r, dome_h, 'copper', 32, 16)
    for i in range(12):
        a = math.tau * i / 12
        points = [(math.cos(a) * dome_r * math.cos(t), math.sin(a) * dome_r * math.cos(t), cap + .17 + dome_h * math.sin(t)) for t in (0, .35, .7, 1.05, 1.3)]
        h.curve('Dome rib', points, .03, 'brass')
    lan = cap + .17 + dome_h - .1
    b.cylinder('teal', (0, 0, lan), (0, 0, lan + .45), .4, 12)
    for i in range(6):
        a = math.tau * i / 6
        p = Vector((math.cos(a) * .405, math.sin(a) * .405, lan + .22))
        h.cylinder('Lantern pane', tuple(p), .1, .02, 'spark_face', 12).rotation_euler = (math.pi / 2, 0, a + math.pi / 2)
    h.torus('Lantern band', (0, 0, lan + .45), .42, .03, 'brass')
    s.dome('Lantern dome', (0, 0, lan + .45), .44, .3, 'copper_dark', 20, 10)
    b.cylinder('gold', (0, 0, lan + .65), (0, 0, lan + 1.25), .07, 8, .01)
    b.sphere('gold', (0, 0, lan + .8), .1, 2)
    b.finish()


# --- the guild hall -------------------------------------------------------------------------------------------------
def guildhall():
    """Cream dressed stone over a dark plinth. A central pavilion with a tall arched entrance and its public counter,
    a clock in the pediment and a steep copper roof; wings of tall windows with flower boxes and keystones under a
    copper mansard with dormers; stone pinnacles with gold balls, banners, lanterns, ivy, clipped evergreens and three
    doorstep treads. Front toward -y (south); detailed on the front and the east return, which the camera sees."""
    rng = random.Random(29103)
    b = k.Batch(rng)
    X0, X1, Y0, Y1 = -7.0, 7.0, -3.5, 3.5
    P0, P1, PY = -2.6, 2.6, -4.05
    G, TOP, ATTIC = 3.55, 6.3, 8.3
    wing_windows = [-5.9, -3.8, 3.8, 5.9]
    ground = (1.05, 3.0)
    upper = (4.15, 5.65)
    # Walls with real openings; each window's glass sits back inside its reveal.
    def openings_for(xs, x_from):
        out = []
        for x in xs:
            out.append((x - .5 - x_from, x + .5 - x_from, ground[0], ground[1]))
            out.append((x - .48 - x_from, x + .48 - x_from, upper[0], upper[1]))
        return out
    k.wall('Front wall west wing', 'ashlar', (X0, Y0), (P0, Y0), 0, TOP, .3, openings_for(wing_windows[:2], X0))
    k.wall('Front wall east wing', 'ashlar', (P1, Y0), (X1, Y0), 0, TOP, .3, openings_for(wing_windows[2:], P1))
    k.wall('Pavilion front', 'ashlar', (P0, PY), (P1, PY), 0, TOP, .3, [(1.55, 3.65, .45, 4.15), (2.05, 3.15, 4.75, 6.0)])
    k.wall('Pavilion west return', 'ashlar', (P0, Y0), (P0, PY), 0, TOP, .3)
    k.wall('Pavilion east return', 'ashlar', (P1, PY), (P1, Y0 + .3), 0, TOP, .3)
    k.wall('East wall', 'ashlar', (X1, Y0), (X1, Y1), 0, TOP, .3, [(1.0, 2.0, ground[0], ground[1]), (1.0, 2.0, upper[0], upper[1]),
                                                                     (4.6, 5.6, ground[0], ground[1]), (4.6, 5.6, upper[0], upper[1])])
    k.wall('Back wall', 'ashlar', (X1, Y1), (X0, Y1), 0, TOP, .3)
    k.wall('West wall', 'ashlar', (X0, Y1), (X0, Y0), 0, TOP, .3, [(2.5, 3.4, upper[0], upper[1])])
    b.box('limestone_shade', (0, 0, TOP - .2), (X1 - X0 - .3, Y1 - Y0 - .3, .2), 0)
    # Plinth, string course, cornice with dentils, and pilasters at the corners and either side of the pavilion.
    plinth = ('stone_dark', 'limestone_shade', 'limestone')
    k.stone_courses(b, rng, 'x', X0 - .14, P0, 0, .48, Y0 - .14, depth=.14, course=.24, tones=plinth)
    k.stone_courses(b, rng, 'x', P1, X1 + .14, 0, .48, Y0 - .14, depth=.14, course=.24, tones=plinth)
    k.stone_courses(b, rng, 'y', Y0 - .14, Y1, 0, .48, X1 + .14, depth=.14, course=.24, tones=plinth)
    k.stone_courses(b, rng, 'x', P0 - .14, P0 + 1.45, 0, .48, PY - .14, depth=.14, course=.24, tones=plinth)
    k.stone_courses(b, rng, 'x', P1 - 1.45, P1 + .14, 0, .48, PY - .14, depth=.14, course=.24, tones=plinth)
    for (x0, x1, y) in ((X0 - .05, P0, Y0), (P1, X1 + .05, Y0), (P0 - .05, P1 + .05, PY)):
        b.box('limestone_pale', ((x0 + x1) / 2, y - .08, G), (x1 - x0, .18, .16), .02)
    b.box('limestone_pale', (X1 + .08, 0, G), (.18, Y1 - Y0 + .1, .16), .02)
    for (x0, x1, y, z) in ((X0 - .2, P0, Y0, TOP), (P1, X1 + .2, Y0, TOP)):
        b.box('limestone_pale', ((x0 + x1) / 2, y - .14, z - .05), (x1 - x0, .3, .2), .025)
        for i in range(int((x1 - x0) / .32)):
            b.box('limestone', (x0 + .16 + i * .32, y - .1, z - .2), (.14, .14, .1), .01)
    b.box('limestone_pale', (X1 + .14, 0, TOP - .05), (.3, Y1 - Y0 + .3, .2), .025)
    for i in range(int((Y1 - Y0) / .32)):
        b.box('limestone', (X1 + .1, Y0 + .16 + i * .32, TOP - .2), (.14, .14, .1), .01)
    for x in (X0 + .12, -4.85, P0 - .18, P1 + .18, 4.85, X1 - .12):
        b.box('limestone_pale', (x, Y0 - .07, (TOP + .48) / 2), (.42, .14, TOP - .48), .02)
        for z in (G - .3, TOP - .45):
            b.box('limestone_pale', (x, Y0 - .12, z), (.5, .1, .1), .01)
    for y in (Y0 + .12, Y1 - .12):
        b.box('limestone_pale', (X1 + .07, y, (TOP + .48) / 2), (.14, .42, TOP - .48), .02)
    for x in (P0 + .12, P1 - .12):
        b.box('limestone_pale', (x, PY - .08, 3.9), (.44, .16, 7.0), .02)
    # Tall windows: white sashes, keystone heads, flower boxes on the first floor.
    for x in wing_windows:
        k.window(b, (x, Y0, sum(ground) / 2), 1.0, ground[1] - ground[0], (0, -1), shutters=False, box=False, glass='window_shop', bars=(1, 2), name='Hall window glass', recess=.2)
        k.window(b, (x, Y0, sum(upper) / 2), .96, upper[1] - upper[0], (0, -1), shutters=False, box=True, bars=(1, 2), name='Hall window glass', recess=.2,
                 flowers=('flower_red', 'flower_pink', 'flower_white'))
        for z in (ground[1] + .12, upper[1] + .12):
            b.box('limestone_pale', (x, Y0 - .06, z), (1.3, .12, .16), .015)
            b.box('limestone', (x, Y0 - .1, z + .02), (.22, .12, .26), .015)
    for y in (1.5 + Y0, 5.1 + Y0):
        k.window(b, (X1, y, sum(ground) / 2), 1.0, ground[1] - ground[0], (1, 0), shutters=False, box=False, glass='window_shop', bars=(1, 2), name='Hall window glass', recess=.2)
        k.window(b, (X1, y, sum(upper) / 2), 1.0, upper[1] - upper[0], (1, 0), shutters=False, box=True, bars=(1, 2), name='Hall window glass', recess=.2)
        for z in (ground[1] + .12, upper[1] + .12):
            b.box('limestone_pale', (X1 + .06, y, z), (.12, 1.3, .16), .015)
            b.box('limestone', (X1 + .1, y, z + .02), (.12, .22, .26), .015)
    k.window(b, (-4.85 + 1.9, Y1, sum(upper) / 2), .9, 1.5, (0, 1), shutters=False, box=False, recess=-.03)
    # The arched entrance: voussoirs and keystone, solid spandrels, a radiating fanlight, open doors and the
    # public counter just inside, with the hall's warm room behind.
    ax, az, ar = 0.0, 3.1, 1.05
    for i in range(13):
        a = math.pi * i / 12
        p = Vector((ax + math.cos(a) * (ar + .12), PY - .04, az + math.sin(a) * (ar + .12)))
        b.box('limestone_pale' if i != 6 else 'limestone', tuple(p), (.26 if i != 6 else .34, .2, .22 if i != 6 else .36), .02, (0, -a + math.pi / 2, 0))
    for i in range(14):
        x = -ar + (i + .5) * (2 * ar / 14)
        z_arch = az + math.sqrt(max(0.0, ar * ar - x * x))
        if z_arch < 4.13:
            b.box('ashlar', (x, PY + .13, (z_arch + 4.15) / 2), (2 * ar / 14 + .01, .28, 4.15 - z_arch), 0)
    s.half_disc_pane('Fanlight glass', 'window_shop', (0, PY + .2, az), ar - .02, (0, -1), 20)
    for i in range(7):
        a = math.pi * (i + 1) / 8
        b.cylinder('white', (0, PY + .16, az), (math.cos(a) * (ar - .04), PY + .16, az + math.sin(a) * (ar - .04)), .018, 4)
    b.box('white', (0, PY + .16, az), (2 * ar, .04, .05), .005)
    for side in (-1, 1):
        # Each leaf hangs on its jamb and stands open into the hall.
        swing = side * .32
        door = Vector((side * (ar - .5 * math.sin(abs(swing))), PY + .3 + .5 * math.cos(swing), 1.75))
        b.box('oak', tuple(door), (.08, 1.0, 2.6), .02, (0, 0, swing))
        b.sphere('brass', tuple(door + Vector((-side * .06, .3, -.1))), .03, 1)
    k.pane('Hall interior glass', 'window_shop', (0, PY + 1.7, 2.1), 2.1, 3.3, (0, -1), 0)
    b.box('limestone_pale', (0, PY + .7, .46), (2.2, 1.5, .02), 0)
    b.box('oak', (0, PY + .75, .95), (1.25, .42, .95), .02)
    b.box('wood_dark', (0, PY + .75, 1.44), (1.4, .55, .06), .015)
    for x in (-.45, 0, .45):
        b.box('wood_dark', (x, PY + .53, .95), (.04, .02, .7), .005)
    b.box('paper', (-.35, PY + .7, 1.48), (.32, .24, .02), .002, (0, 0, .15))
    b.box('red', (-.35, PY + .7, 1.5), (.3, .18, .01), 0, (0, 0, .15))
    b.box('pages', (.15, PY + .72, 1.5), (.4, .3, .05), .005, (0, 0, -.1))
    b.cylinder('brass', (.5, PY + .66, 1.47), (.5, PY + .66, 1.55), .06, 12, .03)
    b.sphere('brass', (.5, PY + .66, 1.57), .02, 1)
    b.cylinder('ink', (-.58, PY + .75, 1.47), (-.58, PY + .75, 1.6), .03, 8)
    b.box('enamel_cream', (0, PY + .53, 1.2), (.7, .02, .22), .004)
    k.lettering('Counter plate', 'ENQUIRIES', (0, PY + .515, 1.2), .085, 'teal_dark', (math.pi / 2, 0, 0))
    # First-floor window over the arch with a little iron balcony.
    k.window(b, (0, PY, 5.38), 1.1, 1.25, (0, -1), shutters=False, box=False, bars=(1, 2), name='Hall window glass', recess=.2)
    b.box('limestone_pale', (0, PY - .3, 4.72), (1.8, .6, .1), .02)
    for x in [-.85 + i * .1 for i in range(18)]:
        b.cylinder('iron', (x, PY - .57, 4.77), (x, PY - .57, 5.3), .01, 4)
    b.box('iron', (0, PY - .57, 5.3), (1.8, .04, .04), .005)
    for side in (-1, 1):
        b.box('iron', (side * .9, PY - .3, 5.3), (.04, .58, .04), .005)
    k.lettering('Frieze lettering', 'GUILD HALL', (0, PY - .012, 4.52), .2, 'gold', (math.pi / 2, 0, 0))
    # Pavilion cornice, the pediment with its clock, raking cornices and gold balls.
    b.box('limestone_pale', (0, PY - .16, TOP + .02), (P1 - P0 + .45, .34, .22), .025)
    for i in range(int((P1 - P0) / .32)):
        b.box('limestone', (P0 + .2 + i * .32, PY - .12, TOP - .15), (.14, .14, .1), .01)
    apex = 8.55
    b.box('ashlar', (0, (PY + Y0 + 4.6) / 2, (TOP + ATTIC) / 2), (P1 - P0, Y0 + 4.6 - PY, ATTIC - TOP), 0)
    b.box('limestone_pale', (0, (PY + Y0 + 4.6) / 2 - .05, ATTIC - .05), (P1 - P0 + .24, Y0 + 4.7 - PY, .16), .02)
    for side in (-1, 1):
        k.disc_pane('Attic oculus glass', 'window_pane', (side * P1, PY + 2.2, 7.35), .34, (side, 0), .01, 18)
        h.torus('Attic oculus ring', (side * (P1 + .02), PY + 2.2, 7.35), .36, .05, 'limestone_pale', (math.pi / 2, 0, math.pi / 2))
    s.gable_end(b, 'ashlar', 'y', PY - .12, P0 - .1, P1 + .1, TOP + .13, apex, -1)
    for side in (-1, 1):
        a0 = Vector((side * (P1 + .3), PY - .27, TOP + .1))
        a1 = Vector((0, PY - .27, apex + .12))
        mid, length = (a0 + a1) / 2, (a1 - a0).length
        b.box('limestone_pale', tuple(mid), (length, .34, .2), .025, (0, math.atan2(-(a1.z - a0.z), a1.x - a0.x), 0))
    for p in ((0, PY - .27, apex + .3), (P0 - .2, PY - .27, TOP + .3), (P1 + .2, PY - .27, TOP + .3)):
        b.cylinder('limestone_pale', (p[0], p[1], p[2] - .2), (p[0], p[1], p[2]), .1, 8)
        b.sphere('gold', p, .14, 2)
    clock = Vector((0, PY - .14, 7.25))
    rot = (math.pi / 2, 0, 0)
    h.cylinder('Clock face', tuple(clock + Vector((0, -.03, 0))), .64, .04, 'enamel_cream', 40).rotation_euler = rot
    h.torus('Clock gold ring', tuple(clock + Vector((0, -.06, 0))), .67, .055, 'gold', rot)
    h.torus('Clock inner ring', tuple(clock + Vector((0, -.06, 0))), .55, .01, 'ink', rot)
    for i in range(12):
        a = math.tau * i / 12
        b.box('ink', tuple(clock + Vector((math.cos(a) * .5, -.07, math.sin(a) * .5))), (.035 if i % 3 == 0 else .02, .01, .1 if i % 3 == 0 else .06), 0, (0, -a + math.pi / 2, 0))
    for length, angle, width in ((.38, math.radians(80), .03), (.27, math.radians(-30), .04)):
        tip = clock + Vector((math.cos(angle) * length, -.08, math.sin(angle) * length))
        b.cylinder('ink', tuple(clock + Vector((0, -.08, 0))), tuple(tip), width / 2, 6, width / 4)
    b.sphere('gold', tuple(clock + Vector((0, -.09, 0))), .04, 1)
    for x in (-.95, .95):
        b.box('gold', (x, PY - .16, 7.25), (.32, .03, .05), .005)
    # Wing roofs: a steep copper mansard to a curb, then a low hip; dormers in the steep slopes; the pavilion's own
    # steep copper roof rises behind the pediment.
    o = .28
    lx0, lx1, ly0, ly1, lz = X0 - o, X1 + o, Y0 - o, Y1 + o, TOP + .05
    run, curb = .62, 8.25
    length = math.hypot(run, curb - lz)
    for mid, along, up, w0 in (((0, ly1, lz), (-1, 0, 0), (0, -run, curb - lz), lx1 - lx0),
                               ((lx1, 0, lz), (0, 1, 0), (-run, 0, curb - lz), ly1 - ly0), ((lx0, 0, lz), (0, -1, 0), (run, 0, curb - lz), ly1 - ly0)):
        s.roof_slope(b, rng, mid, along, up, w0, w0 - 2 * run, length, s.ROOF_COPPER, deck='copper_dark')
    for span in ((lx0, P0, lx0 + run, P0), (P1, lx1, P1, lx1 - run)):
        s.roof_slope(b, rng, (0, ly0, lz), (1, 0, 0), (0, run, curb - lz), 0, 0, length, s.ROOF_COPPER, deck='copper_dark', span=span)
    ridge = s.hip_roof(b, rng, lx0 + run, lx1 - run, ly0 + run, ly1 - run, curb, 21, s.ROOF_COPPER, deck='copper_dark', cap='copper_dark')
    for x0, x1 in ((lx0 + run, lx1 - run),):
        b.box('brass', ((x0 + x1) / 2, ly0 + run - .02, curb + .03), (x1 - x0, .06, .06), .01)
    b.box('brass', (lx1 - run + .02, 0, curb + .03), (.06, ly1 - ly0 - 2 * run, .06), .01)
    for x in (-5.0, 5.0):
        z0 = TOP + .6
        b.box('limestone_pale', (x, ly0 + .55, z0 + .55), (.86, .5, 1.15), .02)
        k.pane('Dormer glass', 'window_pane', (x, ly0 + .29, z0 + .55), .52, .78, (0, -1), .01)
        for xx in (x - .28, x + .28):
            b.box('white', (xx, ly0 + .27, z0 + .55), (.05, .05, .82), .005)
        b.box('white', (x, ly0 + .27, z0 + .55), (.04, .04, .78), .004)
        for side in (-1, 1):
            b.box('copper', (x + side * .27, ly0 + .5, z0 + 1.28), (.62, .7, .05), .015, (0, side * .62, 0))
        b.sphere('gold', (x, ly0 + .28, z0 + 1.52), .06, 1)
    for y in (-1.6, 1.6):
        z0 = TOP + .6
        b.box('limestone_pale', (lx1 - .55, y, z0 + .55), (.5, .86, 1.15), .02)
        k.pane('Dormer glass', 'window_pane', (lx1 - .29, y, z0 + .55), .52, .78, (1, 0), .01)
        for side in (-1, 1):
            b.box('copper', (lx1 - .5, y + side * .27, z0 + 1.28), (.7, .62, .05), .015, (-side * .62, 0, 0))
        b.sphere('gold', (lx1 - .28, y, z0 + 1.52), .06, 1)
    half = (P1 - P0) / 2 + .22
    top_z = s.hip_roof(b, rng, -half, half, PY - .22, Y0 + 4.82, ATTIC, 42, s.ROOF_COPPER, deck='copper_dark', cap='brass')
    mid_y = (PY - .22 + Y0 + 4.82) / 2
    b.cylinder('gold', (0, mid_y, top_z - .2), (0, mid_y, top_z + .8), .06, 8, .01)
    for z in (top_z + .12, top_z + .42):
        b.sphere('gold', (0, mid_y, z), .09, 1)
    for x in (-half + .05, half - .05):
        for y in (PY - .17, Y0 + 4.77):
            b.cylinder('limestone_pale', (x, y, ATTIC - .02), (x, y, ATTIC + .25), .09, 8)
            b.sphere('gold', (x, y, ATTIC + .34), .09, 1)
    # Stone pinnacles with gold balls at the corners, and two chimneys behind.
    for x, y in ((X0 + .1, Y0 + .1), (X1 - .1, Y0 + .1), (X1 - .1, Y1 - .1), (X0 + .1, Y1 - .1)):
        b.box('limestone_pale', (x, y, TOP + 1.45), (.58, .58, 2.7), .03)
        b.box('limestone', (x, y, TOP + 2.85), (.7, .7, .12), .02)
        b.cylinder('limestone_pale', (x, y, TOP + 2.9), (x, y, TOP + 3.15), .14, 8, .08)
        b.sphere('gold', (x, y, TOP + 3.25), .13, 2)
    for x in (-3.8, 3.8):
        s.chimney(b, rng, x, 2.1, curb - .3, ridge + .9, .62, 'limestone', 2)
    # Banners either side of the arch, lanterns on brackets, ivy, flower boxes and two clipped cones by the steps.
    for side in (-1, 1):
        x = side * 1.78
        b.box('iron', (x, PY - .25, 5.15), (.04, .5, .04), .005)
        b.box('iron', (x, PY - .45, 5.15), (.9, .04, .04), .005)
        b.box('banner', (x, PY - .47, 4.25), (.78, .03, 1.75), .01)
        for xx in (x - .2, x + .2):
            b.box('banner', (xx, PY - .47, 3.3), (.38, .03, .26), .005, (0, side * 0, 0))
        b.box('gold', (x, PY - .49, 5.08), (.8, .01, .04), 0)
        for xx in (x - .37, x + .37):
            b.box('gold', (xx, PY - .49, 4.2), (.03, .01, 1.8), 0)
        s.emblem(b, (x, PY - .5, 4.45), (0, -1), 1.15)
    for side in (-1, 1):
        x = side * 1.42
        b.box('iron', (x, PY - .14, 2.75), (.05, .26, .05), .005)
        lamp = Vector((x, PY - .3, 2.55))
        b.cylinder('iron', tuple(lamp + Vector((0, 0, .17))), tuple(lamp + Vector((0, 0, .27))), .12, 6, .03)
        h.cylinder('Hall lantern glass', tuple(lamp), .09, .3, 'lamp_glass', 6)
        b.cylinder('iron', tuple(lamp + Vector((0, 0, -.17))), tuple(lamp + Vector((0, 0, -.15))), .11, 6)
    s.ivy(b, rng, [(X1 + .02, Y0 + .3, .5), (X1 + .02, Y0 + .4, 2.5), (X1 + .02, Y0 + .25, 4.8), (X1 + .02, Y0 + .5, 6.1)], .18, (1, 0), 12, .1)
    s.ivy(b, rng, [(X0 + .4, Y0 - .02, .5), (X0 + .3, Y0 - .02, 2.8), (X0 + .5, Y0 - .02, 5.6)], .2, (0, -1), 12, .1)
    s.ivy(b, rng, [(P1 + .25, Y0 - .02, .5), (P1 + .4, Y0 - .02, 3.2)], .15, (0, -1), 10, 0)
    for x in (-5.9, -3.8, 3.8, 5.9):
        b.box('wood_dark', (x, Y0 - .3, .62), (1.05, .32, .28), .02)
        k.flower_clump(b, (x, Y0 - .3, .76), .4, rng, ('flower_red', 'flower_pink', 'flower_white'), count=10)
    for x in (-2.15, 2.15):
        s.topiary(b, rng, (x, PY - 1.25, 0), 1.25, .34, .52)
    for step, (depth, top) in enumerate(((.96, .15), (.64, .3), (.32, .45))):
        b.box(('limestone', 'limestone_pale', 'limestone')[step], (0, PY - depth / 2, top / 2), (3.3 - step * .2, depth, top), .025)
    b.finish()


# --- the post office ------------------------------------------------------------------------------------------------
def post_office():
    """A two-storey cream house with dressed quoins, its ground floor a post office: a red tiled canopy on brackets,
    a red hanging banner with a white envelope, a glazed counter window with POST on the fascia, a teal door, a parcel
    counter outside. Shuttered windows and a corner balcony above, a hipped clay roof. Front toward -y."""
    rng = random.Random(29104)
    b = k.Batch(rng)
    X, Y, F, TOP = 3.6, 2.6, 3.2, 6.0
    shop = (.6, 3.4, .75, 2.65)
    door = (-2.55, -1.45, 0, 2.5)
    k.wall('Front wall', 'plaster', (-X, -Y), (X, -Y), 0, TOP, .22, [(shop[0] + X, shop[1] + X, shop[2], shop[3]), (door[0] + X, door[1] + X, door[2], door[3]),
                                                                    (-2.7 + X, -1.7 + X, 3.85, 5.25), (-.5 + X, .5 + X, 3.85, 5.25), (1.9 + X, 2.9 + X, 3.85, 5.4)])
    k.wall('East wall', 'plaster', (X, -Y), (X, Y), 0, TOP, .22, [(1.0, 2.0, 1.0, 2.5), (1.0, 2.0, 3.85, 5.25), (3.4, 4.4, 3.85, 5.25)])
    k.wall('Back wall', 'plaster', (X, Y), (-X, Y), 0, TOP, .22)
    k.wall('West wall', 'plaster', (-X, Y), (-X, -Y), 0, TOP, .22)
    k.stone_courses(b, rng, 'x', -X - .12, X + .12, 0, .36, -Y - .12, depth=.12, course=.18, tones=('limestone_shade', 'limestone', 'limestone_warm'),
                    skip=lambda mid, z: door[0] - .1 < mid < door[1] + .1)
    k.stone_courses(b, rng, 'y', -Y - .12, Y, 0, .36, X + .12, depth=.12, course=.18, tones=('limestone_shade', 'limestone', 'limestone_warm'))
    for x, y, fx in ((-X, -Y, 1), (X, -Y, -1)):
        for i in range(14):
            z = .5 + i * .38
            long = i % 2 == 0
            b.box('limestone_pale', (x + fx * (.18 if long else .11), y - .05, z), (.36 if long else .22, .12, .3), .025)
    for i in range(14):
        z = .5 + i * .38
        b.box('limestone_pale', (X + .05, -Y + (.18 if i % 2 == 0 else .11), z), (.12, .36 if i % 2 == 0 else .22, .3), .025)
    b.box('limestone_pale', (0, -Y - .07, F), (2 * X + .1, .16, .14), .02)
    b.box('limestone_pale', (X + .07, 0, F), (.16, 2 * Y + .1, .14), .02)
    # The counter window and fascia, the teal door with a fanlight, the tiled canopy and the envelope banner.
    k.window(b, (sum(shop[:2]) / 2, -Y, sum(shop[2:]) / 2), shop[1] - shop[0], shop[3] - shop[2], (0, -1), shutters=False, box=False, glass='window_shop',
             frame='teal_dark', bars=(3, 1), name='Counter window glass', recess=.12)
    b.box('teal_dark', (sum(shop[:2]) / 2, -Y - .05, .5), (shop[1] - shop[0] + .3, .1, .5), .02)
    b.box('teal', (sum(shop[:2]) / 2, -Y - .08, 2.88), (shop[1] - shop[0] + .5, .08, .34), .015)
    k.lettering('Fascia lettering', 'POST  &  PARCELS', (sum(shop[:2]) / 2, -Y - .125, 2.88), .18, 'gold', (math.pi / 2, 0, 0))
    d0, d1 = door[0], door[1]
    b.box('teal', ((d0 + d1) / 2, -Y + .08, 1.2), (d1 - d0 - .06, .07, 2.36), .02)
    for z in (.65, 1.55):
        b.box('teal_dark', ((d0 + d1) / 2, -Y + .04, z), (d1 - d0 - .3, .03, .62), .01)
    b.sphere('brass', (d1 - .2, -Y + .03, 1.2), .035, 1)
    b.box('brass', ((d0 + d1) / 2, -Y + .03, .95), (.36, .02, .07), .005)
    b.box('white', ((d0 + d1) / 2, -Y - .04, 2.45), (d1 - d0 + .14, .08, .08), .01)
    for x in (d0 - .06, d1 + .06):
        b.box('white', (x, -Y - .04, 1.25), (.08, .08, 2.5), .01)
    for step, (depth, top) in enumerate(((.5, .12),)):
        b.box('limestone_pale', ((d0 + d1) / 2, -Y - depth / 2, top / 2), (d1 - d0 + .4, depth, top), .02)
    for x in (-3.0, 0.0, 3.0):
        b.box('wood_dark', (x, -Y - .45, 3.05), (.08, .9, .08), .01, (math.radians(-20), 0, 0))
        b.box('wood_dark', (x, -Y - .12, 2.78), (.07, .07, .5), .01)
    b.box('wood_dark', (0, -Y - .88, 3.22), (2 * X + .3, .1, .1), .01)
    s.roof_slope(b, rng, (0, -Y - 1.0, 3.18), (1, 0, 0), (0, 1.0, .5), 2 * X + .5, 2 * X + .5, math.hypot(1.0, .5), s.ROOF_RED)
    bx = .1
    b.box('iron', (bx, -Y - .62, 2.92), (.9, .03, .03), .004)
    for side in (-1, 1):
        b.cylinder('iron', (bx + side * .38, -Y - .62, 2.92), (bx + side * .38, -Y - .62, 2.82), .01, 4)
    b.box('enamel_red', (bx, -Y - .62, 2.3), (.82, .04, 1.05), .015)
    b.box('enamel_red_dark', (bx, -Y - .64, 1.8), (.82, .03, .08), .005)
    b.box('gold', (bx, -Y - .645, 2.3), (.72, .005, .9), 0)
    b.box('enamel_red', (bx, -Y - .65, 2.3), (.66, .008, .84), 0)
    b.box('white', (bx, -Y - .66, 2.35), (.46, .01, .32), .003)
    for side in (-1, 1):
        b.box('enamel_red', (bx + side * .12, -Y - .665, 2.43), (.28, .008, .03), 0, (0, side * .55, 0))
    b.box('teal', (0, -Y - 1.02, 3.08), (2 * X + .4, .05, .28), .01)
    k.lettering('Valance lettering', 'POST OFFICE', (0, -Y - 1.05, 3.08), .17, 'gold', (math.pi / 2, 0, 0))
    # Shuttered windows with flower boxes above, a little iron balcony at the east end, the east side windows.
    for x0, x1, top in ((-2.7, -1.7, 5.25), (-.5, .5, 5.25)):
        k.window(b, ((x0 + x1) / 2, -Y, (3.85 + top) / 2), x1 - x0, top - 3.85, (0, -1), bars=(1, 2), recess=.1, name='Upper window glass',
                 flowers=('flower_red', 'flower_white', 'flower_pink'))
    k.window(b, (2.4, -Y, 4.62), 1.0, 1.55, (0, -1), shutters=False, box=False, bars=(1, 2), recess=.1, name='Balcony door glass')
    b.box('limestone_pale', (2.4, -Y - .32, 3.82), (1.5, .64, .1), .02)
    for x in [1.7 + i * .1 for i in range(15)]:
        b.cylinder('iron', (x, -Y - .62, 3.87), (x, -Y - .62, 4.38), .01, 4)
    b.box('iron', (2.4, -Y - .62, 4.38), (1.5, .04, .04), .005)
    for xx in (1.68, 3.12):
        b.box('iron', (xx, -Y - .33, 4.38), (.04, .6, .04), .005)
    for xx in (1.95, 2.85):
        k.h.pot((xx, -Y - .4, 3.87), .8, xx > 2, xx < 2)
    for y, z0, z1, box in ((1.5 - Y, 1.0, 2.5, False), (1.5 - Y, 3.85, 5.25, True), (3.9 - Y, 3.85, 5.25, True)):
        k.window(b, (X, y, (z0 + z1) / 2), 1.0, z1 - z0, (1, 0), box=box, bars=(1, 2), recess=.1, name='Side window glass')
    # A hipped clay roof, a brick chimney, a drainpipe and a little ivy.
    s.hip_roof(b, rng, -X - .3, X + .3, -Y - .3, Y + .3, TOP, 33, s.ROOF_RED)
    s.chimney(b, rng, -1.9, 1.1, TOP + 1.0, TOP + 2.6, .6, 'brick', 2)
    b.cylinder('iron', (X - .12, -Y - .12, TOP - .05), (X - .12, -Y - .12, .1), .045, 8)
    s.ivy(b, rng, [(X + .03, Y - .3, .4), (X + .03, Y - .6, 2.6), (X + .03, Y - .2, 4.5)], .16, (1, 0), 10, .12)
    # The parcel counter outside the window: parcels in brown paper and string, a scale, a bell, a stamp.
    cx, cy = 2.0, -Y - .55
    b.box('oak', (cx, cy, .52), (1.7, .5, .9), .02)
    b.box('wood_dark', (cx, cy, 1.0), (1.85, .62, .06), .015)
    for i, (dx, dz, w, d, hh) in enumerate(((-.6, 1.03, .4, .3, .22), (-.6, 1.25, .3, .24, .16), (-.15, 1.03, .3, .26, .3), (.55, 1.03, .36, .3, .16))):
        b.box('ochre' if i % 2 else 'wood_light', (cx + dx, cy, dz + hh / 2), (w, d, hh), .01, (0, 0, (i - 1.5) * .12))
        b.box('linen', (cx + dx, cy, dz + hh / 2), (w + .01, .02, hh + .01), 0, (0, 0, (i - 1.5) * .12))
    b.box('brass', (cx + .3, cy - .05, 1.06), (.3, .22, .04), .01)
    b.cylinder('brass', (cx + .3, cy - .05, 1.08), (cx + .3, cy - .05, 1.3), .02, 6)
    b.box('brass', (cx + .3, cy - .05, 1.32), (.26, .2, .02), .005)
    b.cylinder('brass', (cx + .75, cy - .1, 1.03), (cx + .75, cy - .1, 1.08), .05, 12, .02)
    for x in (cx - .7, cx + .7):
        b.box('wood_dark', (x, cy, .05), (.12, .5, .1), .01)
    b.finish()


# --- the west terrace ----------------------------------------------------------------------------------------------
def shop_house(b, rng, y0, y1, eave, plaster, roof, name, ground_floor):
    """One house of the terrace, front toward +x at x = 3: a shop on the ground floor, two floors above."""
    X0, X1 = -3.0, 3.0
    F = 3.05
    floors = [(3.65, 4.95), (5.4, 6.55)] if eave > 6.8 else [(3.65, 5.0)]
    width = y1 - y0
    centres = [y0 + width * .27, y0 + width * .73]
    shop_w = width * .58
    shop_c = y0 + width * .38
    door_c = y0 + width * .82
    openings = [(shop_c - shop_w / 2 - y0, shop_c + shop_w / 2 - y0, .7, 2.6), (door_c - .45 - y0, door_c + .45 - y0, 0, 2.45)]
    for z0, z1 in floors:
        for c in centres:
            openings.append((c - .45 - y0, c + .45 - y0, z0, z1))
    k.wall(name + ' front', plaster, (X1, y0), (X1, y1), 0, eave, .22, openings)
    k.wall(name + ' back', plaster, (X0, y1), (X0, y0), 0, eave, .22)
    b.box('limestone_shade', (0, (y0 + y1) / 2, eave - .2), (X1 - X0 - .3, width - .3, .2), 0)
    # Plinth and floor band.
    k.stone_courses(b, rng, 'y', y0, y1, 0, .32, X1 + .16, depth=.14, course=.16, tones=('limestone_shade', 'limestone', 'limestone_warm'),
                    skip=lambda mid, z: door_c - .55 < mid < door_c + .55)
    b.box('limestone_pale', (X1 + .07, (y0 + y1) / 2, F), (.15, width, .14), .02)
    # Shop window, its stall riser and fascia, the door with a transom.
    k.window(b, (X1, shop_c, 1.65), shop_w, 1.9, (1, 0), shutters=False, box=False, glass='window_shop', frame='teal_dark' if ground_floor != 'bakery' else 'shutter_dark',
             bars=(2, 1), name=name + ' shop glass', recess=.12)
    b.box('teal_dark' if ground_floor != 'bakery' else 'shutter_dark', (X1 + .05, shop_c, .38), (.1, shop_w + .2, .45), .02)
    b.box('cream', (X1 + .06, shop_c, 2.88), (.07, shop_w + .4, .34), .015)
    b.box('teal' if ground_floor != 'bakery' else 'shutter', (X1 + .05, (y0 + y1) / 2, 2.9), (.06, width - .1, .42), .01)
    b.box('shutter_dark' if ground_floor == 'bakery' else 'teal_dark', (X1 + .1, door_c, 1.2), (.06, .82, 2.36), .02)
    for z in (.65, 1.5):
        b.box('shutter' if ground_floor == 'bakery' else 'teal', (X1 + .13, door_c, z), (.02, .58, .6), .01)
    b.sphere('brass', (X1 + .16, door_c - .28, 1.2), .03, 1)
    b.box('limestone_pale', (X1 + .25, door_c, .06), (.5, 1.1, .12), .02)
    # Upper windows with shutters and flower boxes; a balcony on the first floor of some.
    for i, (z0, z1) in enumerate(floors):
        for c in centres:
            k.window(b, (X1, c, (z0 + z1) / 2), .9, z1 - z0, (1, 0), bars=(1, 2), recess=.1, name=name + ' upper glass',
                     box=not (i == 0 and roof != 'gable'), flowers=('flower_red', 'flower_pink', 'flower_white', 'flower_yellow'))
    if roof != 'gable':
        z = floors[0][0] - .12
        b.box('limestone_pale', (X1 + .32, (y0 + y1) / 2, z), (.64, width - .5, .1), .02)
        for yy in [y0 + .3 + j * .1 for j in range(int((width - .6) / .1) + 1)]:
            b.cylinder('iron', (X1 + .62, yy, z + .05), (X1 + .62, yy, z + .58), .01, 4)
        b.box('iron', (X1 + .62, (y0 + y1) / 2, z + .58), (.04, width - .55, .04), .005)
        for c in centres:
            b.box('wood_dark', (X1 + .5, c, z + .62), (.22, .7, .18), .015)
            k.flower_clump(b, (X1 + .5, c, z + .72), .3, rng, ('flower_red', 'flower_pink', 'flower_white'), count=8)
        # Washing on a line across the balcony.
        line_z = z + 1.25
        k.catenary(name + ' line', (X1 + .55, y0 + .35, line_z), (X1 + .55, y1 - .35, line_z), .1, .007, 'rail')
        for j, mat in enumerate(('linen', 'cloth_blue', 'cloth_rose', 'linen')):
            yy = y0 + .7 + j * (width - 1.4) / 3
            b.box(mat, (X1 + .55, yy, line_z - .28), (.02, .36, .5), .008)
    # Roof: a gable to the square, or eaves to it with a dormer.
    if roof == 'gable':
        ridge = s.gable_roof(b, rng, X0, X1, y0, y1, eave, 44, 'x', s.ROOF_RED)
        s.gable_end(b, plaster, 'x', X1 + .001, y0, y1, eave, ridge - .08, 1)
        s.gable_end(b, plaster, 'x', X0 - .001, y0, y1, eave, ridge - .08, -1)
        k.pane(name + ' attic glass', 'window_pane', (X1 + .02, (y0 + y1) / 2, eave + .85), .5, .7, (1, 0), .02)
        for yy in ((y0 + y1) / 2 - .3, (y0 + y1) / 2 + .3):
            b.box('white', (X1 + .05, yy, eave + .85), (.05, .06, .8), .005)
        for zz in (eave + .48, eave + 1.22):
            b.box('white', (X1 + .05, (y0 + y1) / 2, zz), (.05, .66, .06), .005)
        for side in (-1, 1):
            a0 = Vector((X1 + .3, (y0 + y1) / 2 + side * (width / 2 + .25), eave - .25 * math.tan(math.radians(44))))
            a1 = Vector((X1 + .3, (y0 + y1) / 2, ridge + .02))
            mid, length = (a0 + a1) / 2, (a1 - a0).length
            b.box('wood_dark', tuple(mid), (.08, length, .18), .015, (math.atan2(a1.z - a0.z, a1.y - a0.y), 0, 0))
    else:
        ridge = s.gable_roof(b, rng, X0, X1, y0, y1, eave, 40, 'y', s.ROOF_RED)
        dz = eave + .15
        b.box(plaster, (X1 - .35, (y0 + y1) / 2, dz + .55), (.7, 1.2, 1.1), .02)
        k.pane(name + ' dormer glass', 'window_pane', (X1 + .01, (y0 + y1) / 2, dz + .55), .62, .72, (1, 0), .01)
        for yy in ((y0 + y1) / 2 - .34, (y0 + y1) / 2 + .34):
            b.box('white', (X1 + .03, yy, dz + .55), (.05, .06, .78), .005)
        for side in (-1, 1):
            b.box('terracotta', (X1 - .3, (y0 + y1) / 2 + side * .36, dz + 1.3), (.9, .82, .06), .015, (side * .6, 0, 0))
    s.chimney(b, rng, X0 + 1.0, y0 + .7, ridge - 1.4, ridge + .8, .58, 'brick', 2)
    b.cylinder('iron', (X1 - .1, y1 - .12, eave), (X1 - .1, y1 - .12, .1), .04, 8)
    return ridge


def west_terrace():
    """Three attached shop-houses facing the square (+x): Morning Loaf the bakery under a green and white striped
    awning, with a round loaf sign and bread racks; the greengrocer under a cream awning with crates of fruit; Finch &
    Sons under a little tiled canopy with books in trays. Balconies, shutters, flower boxes and washing above."""
    rng = random.Random(29105)
    b = k.Batch(rng)
    shop_house(b, rng, -7.0, -2.35, 7.2, 'plaster', 'eaves', 'Morning Loaf', 'bakery')
    shop_house(b, rng, -2.35, 2.35, 6.3, 'salmon', 'gable', 'Greengrocer', 'grocer')
    shop_house(b, rng, 2.35, 7.0, 7.6, 'plaster', 'eaves', 'Finch and Sons', 'books')
    pitch = math.tan(math.radians(40))
    k.wall('Terrace south end', 'plaster', (-3.0, -7.0), (3.0, -7.0), 0, 7.2, .22, [(1.0, 1.9, 3.7, 4.95), (3.9, 4.8, 3.7, 4.95), (1.0, 1.9, 5.45, 6.55)])
    k.wall('Terrace north end', 'plaster', (3.0, 7.0), (-3.0, 7.0), 0, 7.6, .22, [(2.6, 3.4, 3.7, 4.95)])
    s.gable_end(b, 'plaster', 'y', -7.0, -3.0, 3.0, 7.2, 7.2 + 3 * pitch - .08, -1)
    s.gable_end(b, 'plaster', 'y', 7.0, -3.0, 3.0, 7.6, 7.6 + 3 * pitch - .08, 1)
    k.wall('Finch south wall', 'plaster', (-3.0, 2.35), (3.0, 2.35), 5.9, 7.6, .22)
    s.gable_end(b, 'plaster', 'y', 2.35, -3.0, 3.0, 7.6, 7.6 + 3 * pitch - .08, -1)
    k.wall('Bakery north wall', 'plaster', (3.0, -2.35), (-3.0, -2.35), 5.9, 7.2, .22)
    s.gable_end(b, 'plaster', 'y', -2.35, -3.0, 3.0, 7.2, 7.2 + 3 * pitch - .08, 1)
    for x, z0, z1 in ((-1.55, 3.7, 4.95), (1.35, 3.7, 4.95), (-1.55, 5.45, 6.55)):
        k.window(b, (x, -7.0, (z0 + z1) / 2), .9, z1 - z0, (0, -1), bars=(1, 2), recess=.1, name='End window glass', flowers=('flower_pink', 'flower_white', 'flower_red'))
    s.ivy(b, rng, [(2.6, -7.03, .4), (2.2, -7.03, 2.6), (2.5, -7.03, 4.2)], .2, (0, -1), 10, .1)
    # Morning Loaf: striped awning, bread racks, a round hanging loaf sign, a chalk board and the lettering.
    yy0, yy1 = -6.8, -3.3
    for i in range(10):
        y = yy0 + (i + .5) * (yy1 - yy0) / 10
        b.box('shutter' if i % 2 else 'stripe_cream', (3.55, y, 2.42), (1.2, (yy1 - yy0) / 10 + .005, .04), .01, (0, math.radians(22), 0))
        b.box('shutter' if i % 2 else 'stripe_cream', (4.13, y, 2.07), (.04, (yy1 - yy0) / 10 + .005, .26), .005)
    for y in (yy0, yy1):
        b.cylinder('iron', (3.1, y, 2.62), (4.14, y, 2.2), .015, 4)
    k.lettering('Bakery lettering', 'MORNING LOAF', (3.1, -4.7, 2.88), .2, 'shutter_dark', (math.pi / 2, 0, math.pi / 2))
    for i, y in enumerate((-6.25, -5.45)):
        b.box('wood', (3.6, y, .45), (.55, .7, .06), .01)
        b.box('wood', (3.6, y, .8), (.55, .7, .06), .01)
        for leg in (-1, 1):
            for lx in (-.24, .24):
                b.box('wood_dark', (3.6 + lx, y + leg * .32, .42), (.04, .04, .84), .005)
        for j in range(6):
            yy = y - .27 + (j % 3) * .27
            zz = .5 if j < 3 else .85
            b.sphere('bread' if (i + j) % 2 else 'bread_dark', (3.6 + rng.uniform(-.12, .12), yy, zz + .05), .1, 1, (1.5, .9, .7))
    b.box('iron', (3.35, -3.5, 3.4), (.7, .04, .04), .005)
    b.cylinder('iron', (3.62, -3.5, 3.38), (3.62, -3.5, 3.2), .01, 4)
    h.cylinder('Loaf sign', (3.62, -3.5, 2.95), .3, .05, 'shutter_dark', 24).rotation_euler = (math.pi / 2, 0, 0)
    h.torus('Loaf sign rim', (3.62, -3.5, 2.95), .3, .025, 'gold', (math.pi / 2, 0, 0))
    b.sphere('bread', (3.62, -3.53, 2.95), .17, 2, (1.2, .3, .7))
    for i in range(3):
        b.box('bread_dark', (3.55 + i * .07, -3.56, 2.95), (.02, .01, .12), 0, (0, .4, 0))
    b.box('ink', (3.75, -6.95 + .3, .45), (.04, .5, .7), .01, (0, .12, 0))
    b.box('chalk', (3.78, -6.65, .5), (.005, .34, .02), 0)
    # Greengrocer: a cream awning with a scalloped edge, crates of oranges, apples and pears on a stepped stand.
    yy0, yy1 = -2.15, .9
    b.box('canvas', (3.6, (yy0 + yy1) / 2, 2.42), (1.25, yy1 - yy0, .04), .01, (0, math.radians(20), 0))
    for i in range(8):
        y = yy0 + (i + .5) * (yy1 - yy0) / 8
        b.sphere('canvas', (4.18, y, 2.16), .1, 1, (.2, 1.9, .9))
    k.lettering('Grocer lettering', 'GREENGROCER', (3.1, (yy0 + yy1) / 2 - .2, 2.88), .19, 'teal_dark', (math.pi / 2, 0, math.pi / 2))
    for row, (dx, dz) in enumerate(((.95, .25), (.6, .55), (.3, .85))):
        for j, fruit in enumerate(('orange', 'apple', 'pear', 'lemon')):
            y = yy0 + .25 + j * .7
            b.box('wood_light', (3.0 + dx, y, dz - .08), (.42, .6, .22), .015)
            for n in range(6):
                b.sphere(('orange', 'apple', 'pear', 'apple')[(j + row) % 4] if row else fruit, (3.0 + dx + rng.uniform(-.12, .12), y + rng.uniform(-.2, .2), dz + .07), .075, 1)
    # Finch & Sons: a small tiled canopy on brackets, books in trays on trestles, a lettered board.
    s.roof_slope(b, rng, (3.95, 4.3, 2.55), (0, 1, 0), (-.9, 0, .45), 3.6, 3.6, math.hypot(.9, .45), s.ROOF_RED)
    for y in (2.7, 4.3, 5.9):
        b.box('wood_dark', (3.5, y, 2.65), (.9, .07, .07), .01, (0, math.radians(26), 0))
    k.lettering('Books lettering', 'FINCH & SONS', (3.1, 4.3, 3.24), .19, 'gold', (math.pi / 2, 0, math.pi / 2))
    for y in (3.0, 4.15):
        b.box('wood_dark', (3.65, y, .72), (.6, .9, .07), .01)
        for leg in (-1, 1):
            b.box('wood_dark', (3.65, y + leg * .38, .36), (.5, .04, .7), .005)
        for j in range(9):
            mat = ('red', 'blue', 'teal', 'ochre', 'plum', 'shutter')[j % 6]
            b.box(mat, (3.5 + (j % 3) * .15, y - .32 + (j // 3) * .3, .84), (.12, .24, .17), .006, (0, .18 if j % 2 else -.1, 0))
    b.finish()


ASSETS = {'square-beacon': beacon, 'square-guildhall': guildhall, 'square-post-office': post_office, 'square-west-terrace': west_terrace}
for asset in s.selected(list(ASSETS)):
    s.begin(asset)
    ASSETS[asset]()
    s.save(asset, RECORD, keep_separate=())
