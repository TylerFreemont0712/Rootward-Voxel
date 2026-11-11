"""Guarded one-time authoring of the square's street furniture and power fittings, each its own small model placed by
the area documents:

    town-power-pillar     a tall glowing power column for a retaining wall: stone stiles, an amber glass shaft banded
                          in brass, a capital under the coping. Origin at the top of the wall face; it hangs 14 m down
                          (buried where a wall is shorter) and stands out of the wall toward -Y.
    rootwell-plaza        the wider ring of setts round the enlarged Rootwell with its brass band, and the four conduit
                          bridges from its steps to the square's conduits. Origin at the Rootwell's centre.
    town-kiosk            an octagonal newspaper kiosk with posters, a zinc dome and an open counter.
    town-fountain         a cast-iron drinking fountain on a stone step with a basin and a dog bowl.
    town-bollard          a cast-iron bollard.
    town-bin              a slatted litter bin on an iron post.
    town-parasol-table    a café table, three chairs and a striped parasol.
    town-lawn             a 5 x 5 m lawn panel with a stone edge and flowers, for the pocket parks.
    town-tree-grate       an iron tree grate with a ring guard, for a tree standing in paving.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_street.py [-- ids]
    ... -- --draft .cache/square-hub/drafts [ids]

Glowing glass carries the custom property `power_column` (pillars) or `power_grid` (conduits); Godot gives those parts
their moving-light shaders (art/world_assets.gd). Conduits match the city-power-grid pass: a 0.38 m bed, two bronze
rails and an inset amber pane.
"""
import math
import random
import sys
from pathlib import Path

import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import house_kit as kit  # noqa: E402

RECORD = 'art/source/world/square-hub/v1/author_street.py'
PALETTE = {'stone': 'seaside_stone_limestone', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
           'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal', 'plaster': 'seaside_plaster_cream'}
LANE = HERE.parents[1] / 'sparks-lane/v1'
ROOTWELL_SCALE = 1.35


def grid_materials():
    for name, colour, metal in (('grid_bed', '4c5552', .45), ('grid_bronze', '9b8459', .68), ('grid_glass', 'b08a46', .18)):
        kit.material(name, colour, roughness=.56, metallic=metal)
    kit.material('pillar_glass', 'e9a34a', roughness=.3, emission=1.2)
    kit.material('ground_grass', 'ffffff', LANE / 'lane-grass-lush.png', .97)
    kit.material('ground_flags', 'ffffff', LANE / 'lane-flags.png', .95)


def flag_last(p, group, key):
    """Marks the object a group will become with a custom property once finished (see finish())."""
    FLAGS.setdefault(group, {})[key] = True


FLAGS = {}


def finish(p, root):
    """Finishes the parts and marks each flagged group's object (named after its group, '_glass' added for glass)."""
    p.finish(root)
    for obj in bpy.context.scene.objects:
        for group, keys in FLAGS.items():
            if obj.name == group or obj.name.startswith(group + '_'):
                for key in keys:
                    obj[key] = True


# --- the power pillar ------------------------------------------------------------------------------------------------
def power_pillar(p):
    depth, width = .55, 1.2
    bottom = -14.0
    # Stone stiles either side of the glass, dressed in courses; a back plate tying into the wall.
    course = .45
    z = bottom
    k = 0
    while z < -.62:
        h = min(course, -.62 - z)
        for side in (-1, 1):
            w = .28 if k % 2 else .32
            p.box('stone', (side * (width / 2 - w / 2), -depth / 2, z + h / 2), (w, depth, h - .02), bevel=.02, uv=('blocks', 0))
        z += h
        k += 1
    p.box('stone', (0, -.06, (bottom - .62) / 2), (width - .5, .12, -.62 - bottom), bevel=0, uv='world')
    # The glowing shaft: one tall amber pane set between the stiles, banded in brass every 1.6 m.
    with p.into('pillar_glass'):
        verts = [(-.31, -depth + .1, bottom), (.31, -depth + .1, bottom), (.31, -depth + .1, -.62), (-.31, -depth + .1, -.62)]
        p.add('pillar_glass', verts, [(0, 1, 2, 3)], [[(0, bottom), (1, bottom), (1, -.62), (0, -.62)]])
        for x in (-.31, .31):
            side = [(x, -depth + .1, bottom), (x, -.14, bottom), (x, -.14, -.62), (x, -depth + .1, -.62)]
            p.add('pillar_glass', side if x > 0 else list(reversed(side)), [(0, 1, 2, 3)], [[(0, bottom), (1, bottom), (1, -.62), (0, -.62)]])
    flag_last(p, 'pillar_glass', 'power_column')
    z = -1.4
    while z > bottom + .3:
        p.box('brass', (0, -depth + .06, z), (.72, .06, .07), bevel=.012, uv='flat')
        for side in (-1, 1):
            p.sphere('brass', (side * .28, -depth + .02, z), .035, 1)
        z -= 1.6
    for side in (-1, 1):
        p.box('brass', (side * .34, -depth + .07, (bottom - .62) / 2), (.04, .05, -.62 - bottom), bevel=.006, uv='flat')
    # The capital under the coping: a moulded stone block, a brass collar and a small sprout plate.
    p.box('stone', (0, -depth / 2 - .04, -.42), (width + .16, depth + .08, .4), bevel=.03, segments=2, uv=('blocks', 0))
    p.box('stone', (0, -depth / 2 - .02, -.66), (width + .04, depth + .04, .1), bevel=.015, uv=('blocks', 0))
    p.box('brass', (0, -depth - .06, -.42), (.5, .03, .26), bevel=.01, uv='flat')
    p.box('brass', (0, -depth - .075, -.42), (.06, .01, .18), bevel=0, uv='flat')
    for side in (-1, 1):
        p.box('brass', (side * .07, -depth - .075, -.38), (.1, .01, .04), (0, side * .6, 0), 0, 'flat')
    # A plinth where the square's 10 m walls meet the lower town (buried under shorter walls).
    p.box('stone', (0, -depth / 2 - .05, -9.7), (width + .2, depth + .1, .6), bevel=.03, uv=('blocks', 0))


# --- the Rootwell's plaza ring and conduit bridges ---------------------------------------------------------------------
def conduit(p, a, b, z=.002):
    """A straight conduit run from a to b at height z, in the city-power-grid style; glass UV.x is distance from a."""
    a, b = Vector((a[0], a[1], z)), Vector((b[0], b[1], z))
    d = (b - a)
    length = d.length
    side = Vector((-d.y, d.x, 0)).normalized()
    up = Vector((0, 0, 1))

    def quad(mat, c0, c1, half, lift, u0, u1):
        q = [c0 - side * half + up * lift, c1 - side * half + up * lift, c1 + side * half + up * lift, c0 + side * half + up * lift]
        p.add(mat, [tuple(v) for v in q], [(0, 1, 2, 3)], [[(u0, 0), (u1, 0), (u1, 1), (u0, 1)]])

    quad('grid_bed', a, b, .19, -.012, 0, length)
    for off in (-.142, .142):
        quad('grid_bronze', a + side * off, b + side * off, .018, .004, 0, length)
    count = max(1, math.ceil(length / .55))
    with p.into('conduit_glass'):
        for i in range(count):
            t0, t1 = (i + .025) / count, (i + .975) / count
            quad('grid_glass', a.lerp(b, t0), a.lerp(b, t1), .082, -.004, length * t0, length * t1)
    flag_last(p, 'conduit_glass', 'power_grid')


def rootwell_plaza(p):
    rng = p.rng
    gap = .24
    for course, (r0, r1) in enumerate(((6.55, 7.3), (7.3, 8.05), (8.05, 8.8))):
        count = int(2 * math.pi * r1 / .72)
        shift = (course % 2) * .5
        for k in range(count):
            a0 = 2 * math.pi * (k + shift + .03) / count
            a1 = 2 * math.pi * (k + shift + .97) / count
            mid = (a0 + a1) / 2
            # Leave the four conduit lanes open where the square's channels run out from the ring.
            near = min(abs(math.sin(mid)), abs(math.cos(mid)))
            if near * (r0 + r1) / 2 < gap + .2:
                continue
            poly = [(math.cos(a) * r, math.sin(a) * r) for r, a in ((r0 + .02, a0), (r0 + .02, a1), (r1 - .02, a1), (r1 - .02, a0))]
            if (poly[1][0] - poly[0][0]) * (poly[2][1] - poly[0][1]) - (poly[1][1] - poly[0][1]) * (poly[2][0] - poly[0][0]) < 0:
                poly = poly[::-1]
            top = .014 + rng.uniform(-.003, .003)
            p.prism('stone', poly, -.02, top, uv=('blocks', 0))
    # The new brass band at the ring's edge, broken where the conduits leave.
    segs = 128
    for k in range(segs):
        a0, a1 = 2 * math.pi * k / segs, 2 * math.pi * (k + 1) / segs
        mid = (a0 + a1) / 2
        if min(abs(math.sin(mid)), abs(math.cos(mid))) * 8.85 < gap + .05:
            continue
        verts = []
        for a in (a0, a1):
            for r in (8.8, 8.9):
                verts.append((math.cos(a) * r, math.sin(a) * r, .018))
        p.add('brass', [verts[0], verts[2], verts[3], verts[1]], [(0, 1, 2, 3)], [[(0, 0)] * 4])
    # Conduit bridges from the foot of the enlarged Rootwell's steps (3.75 x 1.35) out to the square's channels.
    foot = 3.75 * ROOTWELL_SCALE - .02
    for dx, dy in ((1, 0), (0, 1), (-1, 0), (0, -1)):
        conduit(p, (dx * foot, dy * foot), (dx * 6.8, dy * 6.8), .016)


# --- kiosk, fountain, bollard, bin, parasol table, lawn, tree grate ---------------------------------------------------
def kiosk(p):
    """An octagonal newspaper kiosk: a stone step, panelled green walls papered with posters, an open counter on the
    front with papers and magazines, a fascia lettered NEWS, a zinc dome and a finial."""
    r = .95
    p.prism('stone', [(math.cos(math.radians(22.5 + 45 * k)) * (r + .15), math.sin(math.radians(22.5 + 45 * k)) * (r + .15)) for k in range(8)], 0, .12, uv=('blocks', 0))
    for k in range(8):
        a = math.radians(45 * k)
        out = Vector((math.cos(a), math.sin(a), 0))
        across = Vector((-out.y, out.x, 0))
        c = out * r * math.cos(math.pi / 8)
        w = 2 * r * math.sin(math.pi / 8)
        front = k == 6
        rot = (0, 0, a + math.pi / 2)
        if front:
            p.box('shutter', tuple(c + Vector((0, 0, .5))), (w, .06, .76), rot, .01, 'local')
            p.box('timber', tuple(c + out * .18 + Vector((0, 0, .92))), (w + .1, .4, .05), rot, .01, 'local')
            for j in range(4):
                q = c + out * .2 + across * (j - 1.5) * w / 4.4 + Vector((0, 0, .96))
                p.box(('linen', 'sash', 'cloth_ochre', 'linen')[j], tuple(q), (w / 5, .26, .03 + .01 * j), (0, 0, a + math.pi / 2 + (j - 1.5) * .08), .004, 'flat')
            p.box('ink', tuple(c - out * .02 + Vector((0, 0, 1.45))), (w - .04, .02, .9), rot, 0, 'flat')
            for j in range(5):
                q = c - out * .01 + across * (j - 2) * .1 + Vector((0, 0, 1.25 + (j % 2) * .3))
                p.box(('cloth_rose', 'cloth_blue', 'flower_yellow', 'cloth_ochre', 'linen')[j], tuple(q), (.08, .02, .12), rot, 0, 'flat')
        else:
            p.box('shutter', tuple(c + Vector((0, 0, 1.05))), (w, .06, 1.86), rot, .01, 'local')
            for z0 in (.35, 1.35):
                p.box('shutter', tuple(c + out * .035 + Vector((0, 0, z0 + .3))), (w * .78, .02, .66), rot, .006, 'local')
            if k in (5, 7, 0, 4):
                colours = (('canvas', 'enamel_red'), ('linen', 'canvas_green'), ('cloth_ochre', 'ink'), ('canvas', 'cloth_blue'))[k % 4]
                p.box(colours[0], tuple(c + out * .05 + Vector((0, 0, 1.45))), (w * .7, .01, .5), rot, 0, 'flat')
                p.box(colours[1], tuple(c + out * .056 + Vector((0, 0, 1.6))), (w * .6, .01, .12), rot, 0, 'flat')
                for j in range(3):
                    p.box('ink', tuple(c + out * .056 + Vector((0, 0, 1.4 - j * .06))), (w * .5, .006, .02), rot, 0, 'flat')
        p.box('canvas_green', tuple(out * r + Vector((0, 0, 1.05))), (.07, .07, 1.9), (0, 0, a + math.pi / 8 + math.pi / 2), .01, 'flat')
    p.prism('canvas_green', [(math.cos(math.radians(22.5 + 45 * k)) * (r + .08), math.sin(math.radians(22.5 + 45 * k)) * (r + .08)) for k in range(8)], 1.98, 2.3)
    p.box('canvas', (0, -r - .07, 2.14), (.9, .02, .22), bevel=0, uv='flat')
    kit.text(p, 'ink', 'NEWS', kit.facing_text(0, -r - .085, 2.14, (0, -1)), .15)
    profile = [(r + .25, 2.3), (r + .12, 2.42), (r * .75, 2.7), (r * .4, 2.88), (.08, 2.95)]
    verts, faces = [], []
    segs = 16
    for rr, z in profile:
        for s in range(segs):
            a = math.tau * s / segs
            verts.append((math.cos(a) * rr, math.sin(a) * rr, z))
    for i in range(len(profile) - 1):
        for s in range(segs):
            sn = (s + 1) % segs
            faces.append((i * segs + s, i * segs + sn, (i + 1) * segs + sn, (i + 1) * segs + s))
    p.add('lead', verts, faces, [[(0, 0)] * 4 for _ in faces], True)
    p.cylinder('brass', (0, 0, 2.95), (0, 0, 3.15), .03, 8, uv='flat')
    p.sphere('brass', (0, 0, 3.2), .07, 1)


def fountain(p):
    """A cast-iron drinking fountain: a square stone step, a fluted column with a lion-mask spout, a shell basin, a cup
    on a chain and a low dog bowl."""
    p.box('stone', (0, 0, .07), (1.0, 1.0, .14), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, 0, .18), (.7, .7, .08), bevel=.015, uv=('blocks', 0))
    p.cylinder('canvas_green', (0, 0, .22), (0, 0, .34), .22, 12, .18, uv='flat')
    p.cylinder('canvas_green', (0, 0, .34), (0, 0, 1.25), .12, 12, .1, uv='flat')
    for k in range(10):
        a = math.tau * k / 10
        p.box('canvas_green', (math.cos(a) * .11, math.sin(a) * .11, .8), (.03, .03, .85), (0, 0, a), 0, 'flat')
    p.cylinder('canvas_green', (0, 0, 1.25), (0, 0, 1.35), .17, 12, uv='flat')
    p.sphere('canvas_green', (0, 0, 1.45), .13, 2)
    p.sphere('brass', (0, 0, 1.6), .05, 1)
    p.sphere('brass', (0, -.13, 1.1), .07, 1, (1, .5, 1))
    p.cylinder('brass', (0, -.15, 1.06), (0, -.24, 1.03), .015, 6, uv='flat')
    p.cylinder('canvas_green', (0, -.3, .78), (0, -.3, .86), .2, 14, .26, uv='flat')
    p.cylinder('water', (0, -.3, .85), (0, -.3, .86), .22, 14, uv='flat')
    p.cylinder('canvas_green', (0, -.12, .7), (0, -.25, .78), .04, 6, uv='flat')
    p.cylinder('brass', (.12, -.18, 1.0), (.18, -.22, .9), .006, 4, uv='flat')
    p.cylinder('brass', (.18, -.22, .9), (.18, -.22, .82), .03, 8, .025, uv='flat')
    p.cylinder('stone', (.35, -.35, .14), (.35, -.35, .22), .14, 12, .16, uv=('blocks', 0))
    p.cylinder('water', (.35, -.35, .2), (.35, -.35, .21), .12, 12, uv='flat')


def bollard(p):
    p.cylinder('canvas_green', (0, 0, 0), (0, 0, .08), .13, 12, uv='flat')
    p.cylinder('canvas_green', (0, 0, .08), (0, 0, .78), .085, 12, .07, uv='flat')
    for z in (.2, .66):
        p.cylinder('canvas_green', (0, 0, z - .02), (0, 0, z + .02), .1, 12, uv='flat')
    p.sphere('canvas_green', (0, 0, .82), .09, 2)
    p.box('brass', (0, -.075, .45), (.06, .01, .06), bevel=0, uv='flat')


def litter_bin(p):
    p.box('canvas_green', (0, 0, .48), (.06, .06, .96), bevel=.006, uv='flat')
    p.box('lead', (0, 0, .02), (.24, .24, .04), bevel=.006, uv='flat')
    for k in range(10):
        a = math.tau * k / 10
        p.box('timber', (math.cos(a) * .2, -.25 + math.sin(a) * .2, .55), (.06, .03, .55), (0, 0, a + math.pi / 2), .004, 'local')
    for z in (.32, .8):
        p.cylinder('canvas_green', (0, -.25, z - .015), (0, -.25, z + .015), .225, 14, uv='flat')
    p.cylinder('lead', (0, -.25, .28), (0, -.25, .3), .2, 14, uv='flat')


def parasol_table(p):
    """A round café table with three bentwood chairs and a striped parasol."""
    p.cylinder('lead', (0, 0, 0), (0, 0, .03), .22, 12, uv='flat')
    p.cylinder('iron', (0, 0, .03), (0, 0, .72), .025, 8, uv='flat')
    p.cylinder('canvas', (0, 0, .72), (0, 0, .75), .42, 18, uv='flat')
    p.cylinder('ink', (.1, .05, .75), (.1, .05, .83), .035, 8, .045, uv='flat')
    p.box('linen', (-.12, -.08, .755), (.16, .12, .01), (0, 0, .4), 0, 'flat')
    for k in range(3):
        a = math.tau * k / 3 + .4
        c = Vector((math.cos(a) * .62, math.sin(a) * .62, 0))
        p.cylinder('wicker', tuple(c + Vector((0, 0, .42))), tuple(c + Vector((0, 0, .46))), .19, 12, uv='flat')
        for j in range(4):
            b = math.tau * j / 4 + a
            leg = c + Vector((math.cos(b) * .14, math.sin(b) * .14, 0))
            p.cylinder('iron', tuple(leg), tuple(leg + Vector((0, 0, .43))), .012, 5, uv='flat')
        back = c + Vector((math.cos(a), math.sin(a), 0)) * .17
        p.cylinder('iron', tuple(back - Vector((-math.sin(a), math.cos(a), 0)) * .14 + Vector((0, 0, .44))), tuple(back - Vector((-math.sin(a), math.cos(a), 0)) * .14 + Vector((0, 0, .88))), .012, 5, uv='flat')
        p.cylinder('iron', tuple(back + Vector((-math.sin(a), math.cos(a), 0)) * .14 + Vector((0, 0, .44))), tuple(back + Vector((-math.sin(a), math.cos(a), 0)) * .14 + Vector((0, 0, .88))), .012, 5, uv='flat')
        kit_ring = [back + Vector((-math.sin(a), math.cos(a), 0)) * .14 * math.cos(math.pi * i / 8) + Vector((0, 0, .88 + .1 * math.sin(math.pi * i / 8))) for i in range(9)]
        for q0, q1 in zip(kit_ring, kit_ring[1:]):
            p.cylinder('iron', tuple(q0), tuple(q1), .012, 5, uv='flat')
    p.cylinder('iron', (0, 0, .75), (0, 0, 2.25), .02, 6, uv='flat')
    segs = 16
    for k in range(segs):
        a0, a1 = math.tau * k / segs, math.tau * (k + 1) / segs
        verts = [(0, 0, 2.35), (math.cos(a0) * 1.15, math.sin(a0) * 1.15, 1.95), (math.cos(a1) * 1.15, math.sin(a1) * 1.15, 1.95)]
        p.add(('canvas_green', 'canvas')[k % 2], verts, [(0, 1, 2), (0, 2, 1)], [[(0, 0)] * 3, [(0, 0)] * 3])
        mid = ((a0 + a1) / 2)
        p.sphere(('canvas_green', 'canvas')[k % 2], (math.cos(mid) * 1.13, math.sin(mid) * 1.13, 1.9), .07, 0, (1, 1, .6))
    p.sphere('brass', (0, 0, 2.38), .04, 1)


def lawn(p):
    """A 5 x 5 m lawn panel with a dressed stone edge and a border of flowers; origin at its centre."""
    half = 2.5
    verts = [(-half, -half, .02), (half, -half, .02), (half, half, .02), (-half, half, .02)]
    p.add('ground_grass', verts, [(0, 1, 2, 3)], [[(v[0] / 8, v[1] / 8) for v in verts]])
    for a, b, horizontal in (((-half, -half), (half, -half), True), ((-half, half), (half, half), True), ((-half, -half), (-half, half), False), ((half, -half), (half, half), False)):
        mid = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2, .045)
        p.box('stone', mid, (half * 2 + .14, .14, .09) if horizontal else (.14, half * 2 + .14, .09), bevel=.015, uv=('blocks', 0))
    rng = p.rng
    for k in range(40):
        side = k % 4
        t = rng.uniform(-half + .3, half - .3)
        x, y = [(t, -half + .25), (t, half - .25), (-half + .25, t), (half - .25, t)][side]
        p.sphere(('leaf', 'leaf_dark', 'leaf_light')[k % 3], (x, y, .1), rng.uniform(.08, .12), 1, (1, 1, .8))
        if k % 2:
            p.sphere(('flower_white', 'flower_pink', 'flower_red', 'flower_yellow')[k % 4], (x + rng.uniform(-.05, .05), y, .2), .045, 1)
    for k in range(30):
        p.sphere('leaf_light', (rng.uniform(-half + .5, half - .5), rng.uniform(-half + .5, half - .5), .03), .04, 0, (1.4, 1.4, .5))


def tree_grate(p):
    p.box('stone', (0, 0, .02), (1.5, 1.5, .04), bevel=.01, uv=('blocks', 0))
    p.box('grate', (0, 0, .045), (1.3, 1.3, .02), bevel=0, uv='flat')
    for k in range(9):
        off = -.6 + k * .15
        p.box('iron_light', (off, 0, .058), (.025, 1.26, .01), bevel=0, uv='flat')
    p.cylinder('soil', (0, 0, .045), (0, 0, .06), .25, 12, uv='flat')
    for k in range(4):
        a = math.tau * k / 4 + math.pi / 4
        p.cylinder('iron', (math.cos(a) * .45, math.sin(a) * .45, .05), (math.cos(a) * .45, math.sin(a) * .45, 1.2), .016, 6, uv='flat')
    for z in (.5, 1.15):
        ring = [Vector((math.cos(math.tau * i / 24) * .46, math.sin(math.tau * i / 24) * .46, z)) for i in range(25)]
        for q0, q1 in zip(ring, ring[1:]):
            p.cylinder('iron', tuple(q0), tuple(q1), .012, 5, uv='flat')


PIECES = {
    'town-power-pillar': (power_pillar, 'Glowing power pillar for a retaining wall'),
    'rootwell-plaza': (rootwell_plaza, 'The Rootwell plaza ring and conduit bridges'),
    'town-kiosk': (kiosk, 'Newspaper kiosk'),
    'town-fountain': (fountain, 'Drinking fountain'),
    'town-bollard': (bollard, 'Cast-iron bollard'),
    'town-bin': (litter_bin, 'Litter bin'),
    'town-parasol-table': (parasol_table, 'Café table with parasol'),
    'town-lawn': (lawn, 'Lawn panel, 5 x 5 m'),
    'town-tree-grate': (tree_grate, 'Tree grate with guard'),
}

if __name__ == '__main__':
    chosen, out = kit.selected(list(PIECES))
    for index, asset in enumerate(chosen):
        make, label = PIECES[asset]
        FLAGS.clear()
        root = kit.begin(asset, PALETTE)
        grid_materials()
        parts = kit.Parts(4200 + index)
        make(parts)
        finish(parts, root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, RECORD, PALETTE, {'reference': 'docs/concept/v0.72/art/guildhall-square.png'})
