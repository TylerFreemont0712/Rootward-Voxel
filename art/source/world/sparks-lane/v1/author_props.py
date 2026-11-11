"""One-time guarded authoring of the lane's furniture and street props (P1 street props, T7c).

Each prop's origin is its footprint centre at ground height; fronts face -Y unless noted. The area document owns
placement, turning and blocking. lane-lamp keeps its glass a separate mesh with the material lamp_glass, which the
game lights; lane-laundry keeps each cloth a separate object named cloth_N with its origin on the line, which the
game sways; lane-tram runs along +X. Refuses an existing master.
"""
import math
import random
import sys
from pathlib import Path
import bmesh
import bpy
from mathutils import Vector

sys.path.insert(0, str(Path(__file__).resolve().parent))
import lane_kit as k  # noqa: E402

B = k.h


def lamp():
    b = k.Batch(random.Random(1))
    for i, (w, hgt) in enumerate(((.5, .32), (.46, .3), (.42, .28))):
        z = sum(x[1] for x in ((.5, .32), (.46, .3), (.42, .28))[:i])
        b.box(['limestone', 'limestone_pale', 'limestone_warm'][i], (0, 0, z + hgt / 2), (w, w, hgt), .035)
    b.box('limestone_pale', (0, 0, .95), (.52, .52, .08), .025)
    b.box('iron', (0, 0, 1.08), (.2, .2, .18), .02)
    b.cylinder('iron', (0, 0, 1.15), (0, 0, 2.15), .045, 10)
    for z in (1.4, 1.9):
        B.torus('Post collar', (0, 0, z), .055, .012, 'iron')
    b.box('iron', (0, 0, 2.18), (.3, .3, .06), .01)
    for x in (-.12, .12):
        for y in (-.12, .12):
            b.box('iron', (x, y, 2.38), (.035, .035, .38), .006)
    B.box('lamp_glass', (0, 0, 2.38), (.22, .22, .34), 'lamp_glass', .01)
    b.cylinder('iron', (0, 0, 2.57), (0, 0, 2.72), .21, 4, .03)
    b.box('iron', (0, 0, 2.58), (.32, .32, .04), .006)
    b.sphere('brass', (0, 0, 2.76), .04, 1)
    B.torus('Wire eye', (0, .1, 2.62), .03, .008, 'iron', (math.pi / 2, 0, 0))
    b.finish()


def post_box():
    b = k.Batch(random.Random(2))
    b.cylinder('iron', (0, 0, 0), (0, 0, .16), .27, 20)
    b.cylinder('red', (0, 0, .16), (0, 0, 1.1), .22, 24)
    B.torus('Box rim', (0, 0, 1.1), .23, .03, 'red_dark')
    B.sphere('Domed cap', (0, 0, 1.1), (.24, .24, .13), 'red', 24, 12)
    b.sphere('red_dark', (0, 0, 1.24), .05, 1)
    b.box('ink', (0, -.215, .9), (.2, .03, .035), .008)
    b.box('red_dark', (0, -.225, .925), (.24, .02, .02), .005)
    b.box('white', (0, -.205, .62), (.16, .03, .2), .01)
    for z in (.67, .62, .57):
        b.box('ink', (0, -.222, z), (.11, .005, .012), 0)
    b.box('brass', (0, -.215, .38), (.09, .02, .06), .008)
    b.finish()


def notice_board():
    rng = random.Random(3)
    b = k.Batch(rng)
    for x in (-.62, .62):
        b.box('limestone', (x, 0, .12), (.18, .18, .24), .02)
        b.box('timber', (x, 0, .95), (.1, .1, 1.5), .015)
    b.box('wood_dark', (0, .02, 1.15), (1.3, .08, .82), .02)
    b.box('wood_light', (0, -.025, 1.15), (1.18, .02, .7), .01)
    notes = [(-.4, 1.3, .3, .34, 'paper'), (.02, 1.32, .34, .26, 'white'), (.38, 1.25, .28, .38, 'paper'), (-.35, .94, .32, .24, 'cream'), (.08, .98, .26, .3, 'paper')]
    for x, z, w, hh, mat in notes:
        b.box(mat, (x, -.04, z), (w, .01, hh), 0, (0, rng.uniform(-.06, .06), 0))
        for i in range(3):
            b.box('ink', (x - w * .08, -.047, z + hh * .25 - i * hh * .2), (w * .7, .003, .015), 0)
        b.sphere('red', (x, -.05, z + hh / 2 - .03), .018, 1)
    # The cat poster: a grey cat and its name in block letters.
    b.sphere('blue', (.38, -.05, 1.2), .07, 1, (1, .2, .8))
    b.sphere('blue', (.38, -.05, 1.3), .045, 1, (1, .2, 1))
    for dx in (-.03, .03):
        b.box('blue', (.38 + dx, -.05, 1.35), (.02, .005, .03), 0)
    # A little pitched roof over the board: two slopes falling away from a ridge, a header board under it.
    b.box('wood_dark', (0, .02, 1.6), (1.46, .12, .1), .01)
    pitch = math.radians(32)
    for side in (-1, 1):
        b.box('terracotta', (0, .02 + side * .16, 1.8), (1.66, .38, .05), .015, (-side * pitch, 0, 0))
        for i in range(7):
            b.box(['terracotta_light', 'terracotta_dark'][i % 2], (-.7 + i * .233, .02 + side * .3, 1.715), (.2, .05, .045), .01, (-side * pitch, 0, 0))
    b.cylinder('terracotta_dark', (-.85, .02, 1.91), (.85, .02, 1.91), .055, 8)
    b.finish()


def bench():
    b = k.Batch(random.Random(4))
    for x in (-.62, .62):
        b.box('shutter_dark', (x, .02, .22), (.07, .42, .07), .015)
        b.box('shutter_dark', (x, -.12, .12), (.06, .06, .24), .01)
        b.box('shutter_dark', (x, .18, .3), (.06, .06, .6), .01)
        b.box('shutter_dark', (x, .17, .66), (.06, .08, .3), .01, (math.radians(-12), 0, 0))
        b.box('shutter_dark', (x, -.02, .5), (.05, .34, .04), .008)
    for i in range(4):
        b.box(['wood', 'wood_light'][i % 2], (0, -.13 + i * .09, .44), (1.5, .075, .045), .012)
    for i in range(3):
        b.box(['wood', 'wood_light'][i % 2], (0, .2 + i * .015, .58 + i * .11), (1.5, .045, .085), .012, (math.radians(-12), 0, 0))
    b.finish()


def telescope():
    b = k.Batch(random.Random(5))
    b.cylinder('iron', (0, 0, 0), (0, 0, .08), .24, 12)
    b.cylinder('iron', (0, 0, .08), (0, 0, .95), .07, 10, .05)
    b.box('iron', (0, 0, 1.0), (.18, .18, .12), .02)
    b.box('teal', (0, 0, 1.13), (.22, .26, .2), .03)
    b.box('brass', (.112, 0, 1.15), (.01, .07, .02), 0)
    b.cylinder('brass', (0, .1, 1.24), (0, -.5, 1.38), .07, 14, .085)
    b.cylinder('iron', (0, -.5, 1.38), (0, -.56, 1.39), .088, 14)
    b.cylinder('ink', (0, -.565, 1.39), (0, -.57, 1.39), .07, 14)
    b.cylinder('iron', (0, .1, 1.24), (0, .2, 1.22), .05, 10)
    b.finish()


def tree():
    """A blossom tree: a leaning, flared trunk in the project's bark picture, boughs that fork into twigs, a crown of
    lumpy clumps lit lighter on top and shaded underneath, blossom gathered on the sunny side, petals fallen."""
    rng = random.Random(6)
    b = k.Batch(rng)
    spine = [(0, 0, 0), (.06, .02, .7), (.02, .1, 1.35), (-.06, .04, 1.95), (-.02, -.02, 2.35)]
    for i, (a, c) in enumerate(zip(spine, spine[1:])):
        b.cylinder('bark', a, c, .2 - i * .03, 10, .2 - (i + 1) * .03)
    for i in range(6):
        a = math.tau * i / 6 + rng.uniform(-.2, .2)
        reach = rng.uniform(.35, .55)
        b.cylinder('bark', (0, 0, .28), (math.cos(a) * reach, math.sin(a) * reach, .0), .08, 6, .025)
    tips = []
    for i in range(6):
        a = math.tau * i / 6 + rng.uniform(-.3, .3)
        base = spine[2 + i % 3]
        r = rng.uniform(.75, 1.15)
        mid = (base[0] + math.cos(a) * r * .55, base[1] + math.sin(a) * r * .5, base[2] + rng.uniform(.45, .7))
        end = (base[0] + math.cos(a) * r, base[1] + math.sin(a) * r * .9, base[2] + rng.uniform(.9, 1.3))
        b.cylinder('bark', base, mid, .085, 7, .06)
        b.cylinder('bark', mid, end, .06, 6, .03)
        tips.append(end)
        for j in range(2):
            t = (mid[0] + rng.uniform(-.35, .35), mid[1] + rng.uniform(-.35, .35), mid[2] + rng.uniform(.25, .5))
            b.cylinder('timber', mid, t, .03, 5, .012)
            tips.append(t)
    tips.append((0, 0, 3.4))
    clumps = []
    for x, y, z in tips:
        size = rng.uniform(.42, .58)
        clumps.append((x, y, z, size))
        for _ in range(5):
            a = rng.uniform(0, math.tau)
            lift = rng.uniform(-.25, .35)
            d = size * rng.uniform(.65, .9)
            clumps.append((x + math.cos(a) * d, y + math.sin(a) * d, z + lift * size, size * rng.uniform(.42, .6)))
    for x, y, z, s in clumps:
        tone = 'leaf_dark' if z < 2.75 else ('leaf_light' if z > 3.35 and rng.random() < .7 else 'leaf')
        b.sphere(tone, (x, y, z), s, 1, (1, 1, .82))
    # Sprigs at the crown's edge break its outline.
    for _ in range(40):
        x, y, z, s = clumps[rng.randrange(len(clumps))]
        a = rng.uniform(0, math.tau)
        b.sphere(['leaf', 'leaf_light'][rng.randrange(2)], (x + math.cos(a) * s * .95, y + math.sin(a) * s * .95, z + rng.uniform(-.1, .25)), rng.uniform(.09, .14), 1, (1, 1, .7))
    # Blossom gathered on the upper, sunny side of each clump, a few petals already down.
    for _ in range(110):
        x, y, z, s = clumps[rng.randrange(len(clumps))]
        a = rng.uniform(-1.2, 2.4)
        u = rng.uniform(.1, 1)
        cx, cy, cz = x + math.cos(a) * s * .92, y + math.sin(a) * s * .92, z + u * s * .78
        petal = ['flower_white', 'flower_white', 'flower_pink'][rng.randrange(3)]
        for _ in range(3):
            b.sphere(petal, (cx + rng.uniform(-.05, .05), cy + rng.uniform(-.05, .05), cz + rng.uniform(-.03, .04)), .05, 1)
    for _ in range(36):
        a = rng.uniform(0, math.tau)
        d = rng.uniform(.4, 1.5)
        b.box(['flower_white', 'flower_pink'][rng.randrange(2)], (math.cos(a) * d, math.sin(a) * d, .012), (.06, .045, .008), 0, (0, 0, rng.uniform(0, 3)))
    b.finish()


def cypress():
    """A cypress: a short bark trunk and a tall spindle of layered, feathery tufts, darker within."""
    rng = random.Random(7)
    b = k.Batch(rng)
    b.cylinder('bark', (0, 0, 0), (0, 0, .7), .12, 8, .09)
    for i in range(4):
        a = math.tau * i / 4 + .4
        b.cylinder('bark', (0, 0, .12), (math.cos(a) * .25, math.sin(a) * .25, 0), .05, 5, .02)
    for i in range(10):
        z = .55 + i * .42
        r = .55 * math.sin(math.pi * min(1, (i + 1.6) / 11.2)) + .08
        b.sphere('cypress', (0, 0, z), r * .8, 1, (1, 1, 1.3))
        for j in range(7):
            a = rng.uniform(0, math.tau)
            d = r * rng.uniform(.55, .85)
            tone = ['cypress', 'cypress_light', 'leaf_dark', 'cypress_light'][(i + j) % 4]
            b.sphere(tone, (math.cos(a) * d, math.sin(a) * d, z + rng.uniform(-.15, .2)), r * rng.uniform(.35, .5), 1, (1, 1, 1.4))
    for _ in range(50):
        z = rng.uniform(.8, 4.6)
        r = .55 * math.sin(math.pi * min(1, ((z - .55) / .42 + 1.6) / 11.2)) + .08
        a = rng.uniform(0, math.tau)
        b.sphere('cypress_light', (math.cos(a) * r * .95, math.sin(a) * r * .95, z), rng.uniform(.06, .1), 1, (1, 1, 1.6))
    b.sphere('cypress_light', (0, 0, 4.95), .12, 1, (1, 1, 1.8))
    b.finish()


def bicycle():
    b = k.Batch(random.Random(8))
    for x in (-.52, .52):
        B.torus('Tyre', (x, 0, .34), .31, .028, 'rubber', (math.pi / 2, 0, 0))
        B.torus('Rim', (x, 0, .34), .28, .012, 'rail', (math.pi / 2, 0, 0))
        for i in range(12):
            a = math.pi * i / 12
            b.cylinder('rail', (x + math.cos(a) * .27, 0, .34 + math.sin(a) * .27), (x - math.cos(a) * .27, 0, .34 - math.sin(a) * .27), .004, 3)
        b.cylinder('shutter_dark', (x, -.05, .34), (x, .05, .34), .03, 8)
    frame = [((-.52, 0, .34), (-.05, 0, .36)), ((-.05, 0, .36), (.3, 0, .78)), ((-.52, 0, .34), (-.12, 0, .8)), ((-.12, 0, .8), (.3, 0, .78)), ((-.12, 0, .8), (-.05, 0, .36)), ((.3, 0, .78), (.52, 0, .34)), ((.3, 0, .78), (.27, 0, .95))]
    for a, c in frame:
        b.cylinder('shutter', a, c, .022, 6)
    b.cylinder('rail', (-.12, 0, .8), (-.15, 0, .9), .015, 5)
    b.box('wood_dark', (-.17, 0, .93), (.22, .1, .05), .02)
    b.cylinder('rail', (.27, -.24, .97), (.27, .24, .97), .014, 5)
    for y in (-.24, .24):
        b.cylinder('rubber', (.27, y, .97), (.2, y * 1.05, .97), .022, 6)
    b.box('wood_light', (.5, 0, .82), (.26, .3, .18), .03)
    for i in range(4):
        b.box('wood', (.5, 0, .75 + i * .045), (.27, .31, .01), 0)
    b.box('rail', (-.5, 0, .7), (.34, .2, .02), .005)
    b.box('wood_dark', (-.52, 0, .8), (.26, .18, .16), .03)
    b.box('brass', (-.52, -.092, .82), (.04, .005, .03), 0)
    b.finish()


def crates():
    rng = random.Random(9)
    b = k.Batch(rng)

    # A workshop's scrap crate waiting for collection: slatted sides, rope handles, a gear wheel, pipe offcuts and a
    # coil of wire standing up out of it; a smaller crate beside it with a sack folded over the top.
    def crate(x, y, w, d, hh):
        for zz in (.05, hh - .05):
            for yy in (-d / 2, d / 2):
                b.box('wood_light', (x, y + yy, zz), (w, .04, .08), .01)
            for xx in (-w / 2, w / 2):
                b.box('wood_light', (x + xx, y, zz), (.04, d, .08), .01)
        for i in range(2):
            z = .17 + i * (hh - .3)
            for yy in (-d / 2, d / 2):
                b.box('wood', (x, y + yy, z + .06), (w - .06, .03, .1), .008)
            for xx in (-w / 2, w / 2):
                b.box('wood', (x + xx, y, z + .06), (.03, d - .06, .1), .008)
        for xx in (-w / 2, w / 2):
            for yy in (-d / 2, d / 2):
                b.box('wood_dark', (x + xx, y + yy, hh / 2), (.06, .06, hh), .01)
        b.box('wood_dark', (x, y, .025), (w - .04, d - .04, .03), 0)
        for xx in (-w / 2 - .02, w / 2 + .02):
            B.torus('Rope handle', (x + xx, y, hh - .14), .07, .014, 'pages', (0, math.pi / 2, 0))
    crate(0, 0, .7, .5, .48)
    B.torus('Gear in the crate', (-.12, .02, .62), .17, .035, 'steel', (math.radians(70), 0, .3))
    for i in range(10):
        a = math.tau * i / 10
        b.box('steel', (-.12 + math.cos(a) * .2, .02 + math.sin(a) * .2 * .34, .62 + math.sin(a) * .2 * .94), (.05, .05, .05), .005)
    for dx, dy, lean in ((.14, -.08, .18), (.2, .1, -.12), (.08, .12, .1)):
        b.cylinder(['iron', 'brass', 'iron_light'][int(dx * 10) % 3], (dx, dy, .3), (dx + lean, dy, .82), .035, 8)
    B.torus('Wire coil', (.16, -.02, .5), .13, .03, 'iron')
    crate(.62, .02, .42, .36, .32)
    b.box('pages', (.62, .02, .335), (.46, .4, .03), .02)
    b.box('pages', (.62, -.17, .26), (.44, .03, .16), .01)
    b.finish()


def planter():
    rng = random.Random(10)
    b = k.Batch(rng)
    b.box('wood', (0, 0, .2), (1.1, .4, .4), .03)
    for x in (-.5, .5):
        b.box('wood_dark', (x, 0, .2), (.08, .44, .42), .015)
    for i in range(3):
        b.box('wood_dark', (0, -.205, .07 + i * .13), (1.0, .015, .02), 0)
    b.box('iron', (0, -.21, .32), (1.12, .02, .04), .005)
    b.box('soil', (0, 0, .39), (1.0, .32, .03), 0)
    for i in range(7):
        k.flower_clump(b, (-.42 + i * .14, rng.uniform(-.05, .05), .4), .1, rng, ('flower_red', 'flower_white', 'flower_pink'), count=4)
    for x in (-.5, .5):
        B.curve('Trailing ivy', [(x * .8, -.18, .42), (x * .82, -.24, .3), (x * .78, -.24, .12)], .01, 'leaf_dark')
    b.finish()


def handcart():
    rng = random.Random(11)
    b = k.Batch(rng)
    for y in (-.48, .48):
        B.torus('Cart tyre', (-.1, y, .3), .29, .035, 'iron', (math.pi / 2, 0, 0))
        for i in range(8):
            a = math.pi * i / 8
            b.cylinder('wood_dark', (-.1 + math.cos(a) * .27, y, .3 + math.sin(a) * .27), (-.1 - math.cos(a) * .27, y, .3 - math.sin(a) * .27), .016, 4)
        b.cylinder('wood_dark', (-.1, y - .06, .3), (-.1, y + .06, .3), .05, 8)
    b.cylinder('iron', (-.1, -.5, .3), (-.1, .5, .3), .025, 6)
    b.box('wood', (0, 0, .46), (1.25, .82, .06), .015)
    for y in (-.4, .4):
        b.box('wood_light', (0, y, .58), (1.25, .04, .2), .01)
    b.box('wood_light', (-.6, 0, .58), (.04, .82, .2), .01)
    for y in (-.3, .3):
        b.box('wood_dark', (.95, y, .5), (.8, .06, .06), .01, (0, math.radians(-8), 0))
    b.box('wood_dark', (.62, 0, .12), (.05, .05, .4), .01)
    for x in (-.32, .2):
        b.box('wood_light', (x, -.05, .68), (.42, .36, .26), .02)
        b.box('wood_dark', (x, -.05, .81), (.38, .32, .01), 0)
    B.torus('Cable coil', (.3, .22, .56), .14, .035, 'iron')
    B.torus('Cable coil', (.3, .22, .6), .13, .035, 'iron')
    b.box('white', (.42, .3, .58), (.05, .05, .03), .005)
    b.box('pages', (-.05, .25, .52), (.22, .3, .05), .01, (0, 0, .3))
    b.box('red_dark', (-.05, .25, .55), (.23, .31, .01), 0, (0, 0, .3))
    b.cylinder('ochre', (-.12, .2, .565), (.04, .32, .565), .008, 4)
    b.finish()


def laundry():
    b = k.Batch(random.Random(12))
    for x in (-1.6, 1.6):
        b.box('wood', (x, 0, .9), (.1, .1, 1.8), .015)
        b.box('wood', (x, 0, 1.75), (.08, .5, .06), .01)
    B.curve('Washing line', [(-1.6, 0, 1.72), (-.8, 0, 1.64), (0, 0, 1.6), (.8, 0, 1.64), (1.6, 0, 1.72)], .008, 'linen')
    cloths = [(-1.15, .5, .62, 'white'), (-.55, .42, .5, 'cloth_blue'), (.0, .36, .72, 'linen'), (.48, .44, .46, 'cloth_rose'), (1.05, .5, .58, 'white')]
    for i, (x, w, hh, mat) in enumerate(cloths):
        line_z = 1.6 + .12 * (abs(x) / 1.6) ** 2 - .01
        mesh = bpy.data.meshes.new('cloth_%d' % i)
        bm = bmesh.new()
        nx, nz = 6, 6
        grid = []
        for j in range(nz + 1):
            row = []
            for ii in range(nx + 1):
                u = ii / nx - .5
                v = j / nz
                row.append(bm.verts.new((u * w, .012 * math.sin(u * 9 + v * 4) + .03 * v * v, -v * hh)))
            grid.append(row)
        for j in range(nz):
            for ii in range(nx):
                bm.faces.new((grid[j][ii], grid[j][ii + 1], grid[j + 1][ii + 1], grid[j + 1][ii]))
        bmesh.ops.solidify(bm, geom=list(bm.faces), thickness=.008)
        uv = bm.loops.layers.uv.new('Cloth')
        for face in bm.faces:
            for loop in face.loops:
                loop[uv].uv = (loop.vert.co.x / w + .5, -loop.vert.co.z / hh)
        bm.to_mesh(mesh)
        bm.free()
        obj = bpy.data.objects.new('cloth_%d' % i, mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.location = (x, 0, line_z)
        B.put(obj, mat)
        for dx in (-w * .4, w * .4):
            b.box('wood_light', (x + dx, 0, line_z + .02), (.025, .03, .08), .005)
    b.finish()


def pump():
    rng = random.Random(13)
    b = k.Batch(rng)
    # A hollow stone trough: a floor, four walls with a worn lip, water standing inside.
    tx, ty = .15, -.32
    b.box('limestone_shade', (tx, ty, .06), (1.1, .52, .12), .03)
    for dy in (-.22, .22):
        b.box('limestone', (tx, ty + dy, .23), (1.1, .08, .42), .025)
    for dx in (-.51, .51):
        b.box('limestone', (tx + dx, ty, .23), (.08, .52, .42), .025)
    b.box('water', (tx, ty, .34), (.94, .36, .01), 0)
    b.box('limestone_pale', (tx - .2, ty - .22, .445), (.4, .1, .03), .01)
    b.box('limestone_pale', (-.15, .15, .06), (.45, .45, .12), .02)
    b.cylinder('shutter_dark', (-.15, .15, .12), (-.15, .15, 1.15), .09, 12, .075)
    B.sphere('Pump cap', (-.15, .15, 1.18), (.11, .11, .1), 'shutter_dark', 12, 6)
    b.cylinder('shutter_dark', (-.15, .05, .9), (-.15, -.2, .82), .035, 8)
    b.cylinder('brass', (-.15, -.2, .82), (-.15, -.24, .76), .03, 8)
    b.cylinder('shutter_dark', (-.15, .22, 1.08), (.35, .5, 1.3), .022, 6)
    b.sphere('shutter_dark', (.35, .5, 1.3), .04, 1)
    b.box('iron', (-.15, .15, .5), (.2, .2, .04), .01)
    b.finish()


def shed():
    rng = random.Random(14)
    b = k.Batch(rng)
    b.box('limestone', (0, 0, .08), (2.0, 1.75, .16), .03)
    for y in (-.82, .82):
        for i in range(14):
            x = -.95 + i * .146
            b.box(['wood', 'wood_light'][(i + (y > 0)) % 2], (x + .073, y, .95), (.14, .06, 1.6), .01)
    for x in (-.97, .97):
        for i in range(12):
            y = -.82 + i * .14
            b.box(['wood', 'wood_light'][i % 2], (x, y + .07, 1.0), (.06, .14, 1.7), .01)
    b.box('shutter', (.35, -.86, .95), (.62, .04, 1.4), .02)
    b.box('shutter_dark', (.35, -.885, .95), (.6, .01, .06), 0, (0, math.radians(-62), 0))
    b.sphere('brass', (.6, -.9, .95), .03, 1)
    k.window(b, (1.0, .2, 1.25), .5, .45, (1, 0), shutters=False, box=False, frame='white', recess=-.03, name='Shed window glass')
    for side in (-1, 1):
        b.box('timber', (0, side * .5, 1.98), (2.3, 1.15, .08), .02, (side * math.radians(-28), 0, 0))
        k.tiled_roof(b, -1.15, 1.15, side * 1.05, 0, 1.68, 2.25, rng, .24, .3)
    b.cylinder('wood_light', (-.6, -.95, .15), (-.75, -.88, 1.45), .02, 5)
    b.box('rail', (-.76, -.88, 1.5), (.3, .04, .04), .005)
    b.cylinder('wood_light', (-.35, -.95, .15), (-.45, -.9, 1.25), .02, 5)
    b.box('rail', (-.33, -.96, .22), (.16, .02, .2), .005)
    b.cylinder('teal', (-.1, -1.05, .16), (-.1, -1.05, .42), .1, 12)
    b.cylinder('teal', (-.02, -1.05, .32), (.15, -1.05, .45), .02, 6)
    b.finish()


def tram_shelter():
    rng = random.Random(15)
    b = k.Batch(rng)
    for x in (-1.55, 1.55):
        for y in (-.55, .4):
            b.box('limestone', (x, y, .1), (.2, .2, .2), .02)
            b.box('timber', (x, y, 1.15), (.12, .12, 2.1), .015)
    b.box('timber', (0, -.55, 2.18), (2.9, .12, .14), .015)
    b.box('timber', (0, .4, 2.18), (2.9, .12, .14), .015)
    b.box('timber', (0, .44, 1.2), (2.7, .06, 1.8), .01)
    for i in range(10):
        b.box(['wood', 'wood_light'][i % 2], (-1.25 + i * .28, .4, 1.2), (.26, .05, 1.75), .008)
    k.tiled_roof(b, -1.65, 1.65, -.95, .3, 2.2, 2.55, rng, .24, .3)
    k.tiled_roof(b, -1.65, 1.65, .8, .3, 2.25, 2.55, rng, .24, .3)
    for i in range(4):
        b.box(['wood', 'wood_light'][i % 2], (0, .02 + i * .09, .44), (2.2, .075, .045), .012)
    for x in (-1.0, 1.0):
        b.box('shutter_dark', (x, .15, .22), (.06, .36, .44), .01)
    b.box('iron', (-1.32, -.4, 1.85), (.05, .3, .05), .01)
    B.box('Shelter lantern', (-1.32, -.55, 1.7), (.14, .14, .2), 'glass', .01)
    b.box('iron', (-1.32, -.55, 1.82), (.18, .18, .04), .005)
    k.h.pot((-1.65, -.2, 0), .8, False, True)
    k.h.pot((1.65, -.2, 0), .8, True, False)
    # The stop: an enamel disc on an arm from the corner post, and the timetable framed on the post itself.
    b.box('iron', (-1.75, -.55, 1.95), (.42, .04, .04), .005)
    b.cylinder('enamel_teal', (-1.98, -.53, 1.95), (-1.98, -.57, 1.95), .2, 20)
    k.h.torus('Stop disc rim', (-1.98, -.55, 1.95), .2, .016, 'enamel_cream', (math.pi / 2, 0, 0))
    b.box('enamel_cream', (-1.98, -.575, 1.95), (.28, .01, .065), 0)
    b.box('wood_dark', (-1.55, -.63, 1.2), (.36, .05, .46), .01)
    b.box('paper', (-1.55, -.66, 1.2), (.3, .01, .4), 0)
    for i in range(7):
        b.box('ink', (-1.59, -.667, 1.36 - i * .052), (.19, .003, .012), 0)
    b.box('glass', (-1.55, -.67, 1.2), (.31, .004, .41), 0)
    b.finish()


def tram():
    """The hill tram: a double-ended teal and cream car on two four-wheeled trucks, its trolley pole trailing up to
    the wire. Runs along +X (the headlamp end); origin on the track centreline at rail height. Wheels sit on the
    lane's rails, 1.1 apart; the pole's shoe meets the wire at 3.75."""
    rng = random.Random(16)
    b = k.Batch(rng)
    L, Wd, gauge = 6.2, 1.9, 1.1
    floor, waist, sill, head, eave = .8, 1.58, 1.66, 2.42, 2.62
    # Trucks: wheels and axle boxes on leaf springs, side frames, a brake shoe at every wheel.
    for truck in (-1.85, 1.85):
        b.box('steel_dark', (truck, 0, .5), (1.2, gauge - .1, .1), .02)
        for side in (-1, 1):
            y = side * (gauge / 2 + .17)
            b.box('steel_dark', (truck, y, .46), (1.72, .07, .2), .02)
            b.box('steel_dark', (truck, y, .33), (1.1, .06, .08), .015)
            for ax in (-.6, .6):
                b.cylinder('iron', (truck + ax, side * (gauge / 2 - .02), .3), (truck + ax, side * (gauge / 2 + .06), .3), .3, 18)
                b.cylinder('steel', (truck + ax, side * (gauge / 2 + .06), .3), (truck + ax, side * (gauge / 2 + .075), .3), .16, 14)
                b.cylinder('iron_light', (truck + ax, side * (gauge / 2 - .05), .3), (truck + ax, side * (gauge / 2 - .02), .3), .33, 18)
                b.box('iron', (truck + ax, y, .3), (.2, .1, .16), .02)
                for i in range(4):
                    b.box('steel', (truck + ax, y, .43 + i * .03), (.42 - i * .07, .09, .022), .005)
                b.box('iron', (truck + ax + (.33 if ax > 0 else -.33), side * (gauge / 2 + .02), .3), (.06, .07, .22), .01)
            b.cylinder('steel_dark', (truck, -gauge / 2, .3), (truck, gauge / 2, .3), .035, 6)
    # Underframe, the lifeguard trays and drawbars, sandboxes and a step under each door.
    b.box('iron', (0, 0, .68), (L - .3, Wd - .1, .16), .02)
    for end in (-1, 1):
        x = end * (L / 2 + .05)
        for i in range(5):
            b.box('iron_light', (x + end * .08, -.6 + i * .3, .2), (.24, .04, .03), .005)
        b.box('iron', (x + end * .08, 0, .26), (.3, 1.4, .05), .01)
        b.box('iron', (x + end * .16, 0, .55), (.2, .22, .12), .02)
        b.box('iron', (x + end * .03, 0, .7), (.08, Wd - .2, .14), .02)
        for side in (-1, 1):
            b.box('iron', (end * 2.62, side * (Wd / 2 + .06), .62), (.6, .14, .04), .01)
            b.box('steel_dark', (end * 2.62, side * (Wd / 2 + .03), .67), (.6, .02, .06), 0)
    # The body: panelled teal dash with gold lining, a cream rocker band, the fleet number and the town's name.
    b.box('teal', (0, 0, (floor + waist) / 2), (L, Wd, waist - floor), .06, segments=2)
    b.box('enamel_cream', (0, 0, floor + .07), (L + .02, Wd + .02, .1), .02)
    b.box('teal_dark', (0, 0, waist + .04), (L + .04, Wd + .04, .08), .015)
    for side in (-1, 1):
        y = side * (Wd / 2 + .006)
        for x0, x1 in ((-2.35, -.1), (.1, 2.35)):
            for z in (floor + .2, waist - .1):
                b.box('gold', ((x0 + x1) / 2, y, z), (x1 - x0, .01, .02), 0)
            for x in (x0, x1):
                b.box('gold', (x, y, (floor + waist) / 2 + .05), (.02, .01, waist - floor - .3), 0)
        rot = (math.pi / 2, 0, 0) if side < 0 else (math.pi / 2, 0, math.pi)
        k.lettering('Tram number', '7', (0, side * (Wd / 2 + .012), (floor + waist) / 2 + .05), .3, 'gold', rot)
        k.lettering('Tram fleet name', 'HAVERLUND', (-1.25 if side < 0 else 1.25, side * (Wd / 2 + .012), (floor + waist) / 2 + .05), .17, 'gold', rot)
        k.lettering('Tram fleet name', 'TRAMWAYS', (1.25 if side < 0 else -1.25, side * (Wd / 2 + .012), (floor + waist) / 2 + .05), .17, 'gold', rot)
    # Window band: cream pillars, six saloon windows a side with drop-lights over them, the platform doors.
    b.box('enamel_cream', (0, 0, (sill + head) / 2), (L - .1, Wd - .1, head - sill), .02)
    windows = [-1.75, -1.05, -.35, .35, 1.05, 1.75]
    for side in (-1, 1):
        face = side * (Wd / 2 - .05)
        for x in windows:
            k.pane('Tram window glass', 'window_tram', (x, face, 1.99), .58, .5, (0, side), .03)
            k.pane('Tram drop-light glass', 'window_tram', (x, face, 2.32), .58, .13, (0, side), .03)
            b.box('teal_dark', (x, face + side * .045, 2.255), (.6, .03, .025), 0)
        for end in (-1, 1):
            x = end * 2.65
            b.box('teal_dark', (x, side * (Wd / 2 + .01), 1.55), (.62, .05, 1.45), .015)
            for leaf in (-1, 1):
                k.pane('Tram door glass', 'window_tram', (x + leaf * .15, side * Wd / 2, 2.0), .24, .55, (0, side), .04)
                b.box('teal', (x + leaf * .15, side * (Wd / 2 + .04), 1.25), (.26, .02, .55), .01)
            b.box('teal_dark', (x, side * (Wd / 2 + .045), 1.55), (.02, .02, 1.4), 0)
            for rail in (-1, 1):
                b.cylinder('brass', (x + rail * .36, side * (Wd / 2 + .07), 1.0), (x + rail * .36, side * (Wd / 2 + .07), 2.1), .018, 6)
    # The ends: three windows round each driver's platform, the headlamp, tail and marker lamps, the destination.
    for end in (-1, 1):
        x = end * (L / 2 - .05)
        for dy in (-.6, 0, .6):
            k.pane('Tram end glass', 'window_tram', (x, dy, 2.02), .52, .58, (end, 0), .03)
        b.cylinder('brass', (x + end * .04, 0, 1.22), (x + end * .1, 0, 1.22), .13, 16)
        b.cylinder('enamel_cream' if end > 0 else 'red', (x + end * .1, 0, 1.22), (x + end * .11, 0, 1.22), .1, 16)
        for dy in (-.75, .75):
            b.sphere('ochre' if end > 0 else 'red_dark', (x + end * .04, dy, 2.5), .045, 1)
        rot = (math.pi / 2, 0, math.pi / 2) if end > 0 else (math.pi / 2, 0, -math.pi / 2)
        k.lettering('Tram number', '7', (x + end * .03, 0, 1.45), .2, 'gold', rot)
        b.box('iron', (end * (L / 2 - .3), 0, eave + .22), (.14, .9, .26), .02)
        b.box('enamel_cream', (end * (L / 2 - .23), 0, eave + .22), (.02, .82, .18), 0)
        k.lettering('Destination', 'HARBOUR' if end > 0 else 'SPINDLE LANE', (end * (L / 2 - .21), 0, eave + .22), .1 if end > 0 else .075, 'ink', rot)
    # Letterboard, roof, clerestory with its little lights, ventilators, the trolley base and pole, the retriever.
    for side in (-1, 1):
        b.box('enamel_cream', (0, side * (Wd / 2 + .005), (head + eave) / 2), (L - .3, .02, eave - head - .04), 0)
        rot = (math.pi / 2, 0, 0) if side < 0 else (math.pi / 2, 0, math.pi)
        k.lettering('Letterboard', 'SPINDLE LANE  ·  THE SQUARE  ·  HARBOUR', (0, side * (Wd / 2 + .018), (head + eave) / 2), .09, 'teal_dark', rot)
    b.box('teal', (0, 0, eave + .02), (L + .06, Wd + .1, .06), .02)
    b.box('iron_light', (0, 0, eave + .1), (L - .1, Wd - .05, .12), .05, segments=2)
    b.box('enamel_cream', (0, 0, eave + .22), (4.4, .9, .16), .02)
    for side in (-1, 1):
        for i in range(8):
            k.pane('Clerestory glass', 'window_tram', (-1.9 + i * .54, side * .45, eave + .22), .34, .1, (0, side), .01)
    b.box('steel_dark', (0, 0, eave + .32), (4.6, 1.05, .05), .02)
    for x in (-1.4, 1.4):
        b.cylinder('iron', (x, 0, eave + .34), (x, 0, eave + .44), .07, 10)
        B.sphere('Ventilator cap', (x, 0, eave + .46), (.09, .09, .05), 'iron', 10, 5)
    base = (.5, 0, eave + .4)
    b.box('iron', (base[0], 0, base[2]), (.42, .32, .1), .02)
    for side in (-1, 1):
        b.cylinder('steel', (base[0] - .15, side * .1, base[2] + .05), (base[0] + .2, side * .1, base[2] + .05), .035, 8)
    tip = (-.95, 0, 3.72)
    b.cylinder('iron', (base[0], 0, base[2] + .05), tip, .028, 8, .02)
    b.box('brass', (tip[0] - .04, 0, tip[2] + .02), (.12, .05, .06), .01)
    b.cylinder('steel', (tip[0] - .04, -.03, tip[2] + .05), (tip[0] - .04, .03, tip[2] + .05), .035, 10)
    B.curve('Trolley retriever rope', [(-.5, 0, 3.45), (-1.7, .1, 2.9), (-2.7, .15, 2.4), (-3.05, .15, 1.9)], .008, 'pages')
    b.box('iron', (-3.12, .15, 1.75), (.08, .08, .22), .01)
    b.finish()


BUILDERS = {
    'lane-lamp': lamp, 'lane-post-box': post_box, 'lane-notice-board': notice_board, 'lane-bench': bench,
    'lane-telescope': telescope, 'lane-tree': tree, 'lane-cypress': cypress, 'lane-bicycle': bicycle,
    'lane-crates': crates, 'lane-planter': planter, 'lane-handcart': handcart, 'lane-laundry': laundry,
    'lane-pump': pump, 'lane-shed': shed, 'lane-tram-shelter': tram_shelter, 'lane-tram': tram,
}

if __name__ == '__main__':
    k.guard(BUILDERS)
    for asset, make in BUILDERS.items():
        k.start(asset)
        make()
        k.save(asset, 'author_props.py', keep_separate=('cloth_',) if asset == 'lane-laundry' else ())
