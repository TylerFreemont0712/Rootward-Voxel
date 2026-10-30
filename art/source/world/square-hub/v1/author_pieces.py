"""Guarded one-time authoring of the town's modular edge pieces: stone balustrades, iron railings (level and raked),
garden walls, their piers, posts and a gate. Each is its own small model. The square's area document lays them end
to end along its edges (author_area.py), so any run can be lengthened, moved or replaced without touching the ground.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_pieces.py [-- ids]
    ... -- --draft .cache/square-hub/drafts [ids]

Conventions: a bay runs along +X from 0 to its length on its base line (z 0 = the coping it stands on), centred on
Y 0. Bays carry no piers or posts; the area places one at every bay joint and run end, so nothing doubles up. A raked
railing rises 1 m over its 1 m run, matching one stair cell, its handrail continuous with the level railing's.
"""
import math
import sys
from pathlib import Path

from mathutils import Vector

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import house_kit as kit  # noqa: E402

PALETTE = {'stone': 'seaside_stone_limestone', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
           'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}
RAIL_TOP, RAIL_MID, RAIL_FOOT = 1.0, .82, .1
PIER = .46


def baluster(p, x, z0, z1, y=0.0):
    """A turned stone baluster: square foot and cap, a vase between."""
    h = z1 - z0
    p.box('stone', (x, y, z0 + .03), (.14, .14, .06), bevel=.008, uv=('blocks', 0))
    p.box('stone', (x, y, z1 - .03), (.13, .13, .06), bevel=.008, uv=('blocks', 0))
    profile = [(.045, .06), (.06, .12), (.072, .32), (.06, .5), (.036, .72), (.03, .8), (.05, .88), (.05, .94)]
    verts, faces, uvs = [], [], []
    sides = 6
    for r, t in profile:
        for s in range(sides):
            a = math.tau * (s + .5) / sides
            verts.append((x + math.cos(a) * r, y + math.sin(a) * r, z0 + h * t))
    for i in range(len(profile) - 1):
        for s in range(sides):
            sn = (s + 1) % sides
            faces.append((i * sides + s, i * sides + sn, (i + 1) * sides + sn, (i + 1) * sides + s))
            uvs.append([(.3, .3 + i * .05), (.32, .3 + i * .05), (.32, .35 + i * .05), (.3, .35 + i * .05)])
    p.add('stone', verts, faces, uvs, True)


def balustrade(p, length):
    """A stone balustrade bay: a plinth course, turned balusters at 0.25 m, a moulded handrail."""
    a, b = PIER / 2 - .04, length - PIER / 2 + .04
    p.box('stone', ((a + b) / 2, 0, .08), (b - a, .36, .16), bevel=.02, uv=('blocks', 0))
    p.box('stone', ((a + b) / 2, 0, .175), (b - a, .3, .04), bevel=.01, uv=('blocks', 0))
    count = max(1, round((b - a - .1) / .25))
    for k in range(count):
        baluster(p, a + .05 + (b - a - .1) * (k + .5) / count, .195, .86)
    p.box('stone', ((a + b) / 2, 0, .885), (b - a, .3, .05), bevel=.01, uv=('blocks', 0))
    p.box('stone', ((a + b) / 2, 0, .95), (b - a, .36, .1), bevel=.03, segments=2, uv=('blocks', 0))


def balustrade_pier(p):
    p.box('stone', (0, 0, .11), (PIER + .08, PIER + .08, .22), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, 0, .62), (PIER, PIER, .8), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, 0, .955), (PIER - .06, PIER - .06, .07), bevel=.01, uv=('blocks', 0))
    p.box('stone', (0, 0, 1.03), (PIER + .1, PIER + .1, .1), bevel=.025, segments=2, uv=('blocks', 0))
    p.prism('stone', [(-.22, -.22), (.22, -.22), (.22, .22), (-.22, .22)], 1.08, 1.1)
    p.box('stone', (0, 0, 1.13), (.3, .3, .06), bevel=.02, uv=('blocks', 0))


def rail(p, a, b, w=.032, h=.022, mat='iron'):
    p.beam(mat, a, b, w, h, up=(0, 0, 1), uv='flat')


def railing(p, length, rise=0.0, base=0.0):
    """An iron railing bay: a rounded handrail, a mid rail with rings, a foot rail and square bars at 0.11 m. With a
    rise it rakes up its run (bars stay vertical), the rails parallel to the stair's nosing line."""
    def z(x, h):
        return base + h + rise * x / length

    a, b = .04, length - .04
    rail(p, (a, 0, z(a, RAIL_TOP)), (b, 0, z(b, RAIL_TOP)), .055, .035)
    p.cylinder('iron_light', (a, 0, z(a, RAIL_TOP) + .02), (b, 0, z(b, RAIL_TOP) + .02), .025, 6, uv='flat')
    rail(p, (a, 0, z(a, RAIL_MID)), (b, 0, z(b, RAIL_MID)))
    rail(p, (a, 0, z(a, RAIL_FOOT)), (b, 0, z(b, RAIL_FOOT)))
    count = max(2, round((b - a) / .11))
    for k in range(count + 1):
        x = a + (b - a) * k / count
        p.box('iron', (x, 0, (z(x, RAIL_FOOT) - .1 + z(x, RAIL_TOP)) / 2), (.016, .016, z(x, RAIL_TOP) - z(x, RAIL_FOOT) + .1), bevel=0, uv='flat')
        if k < count:
            xm = x + (b - a) / count / 2
            zm = (z(xm, RAIL_MID) + z(xm, RAIL_TOP)) / 2
            ring(p, (xm, 0, zm), .04)


def ring(p, centre, r):
    pts = [Vector(centre) + Vector((math.cos(math.tau * i / 8) * r, 0, math.sin(math.tau * i / 8) * r)) for i in range(9)]
    for q0, q1 in zip(pts, pts[1:]):
        p.beam('iron', q0, q1, .012, .012, up=(0, 1, 0), uv='flat')


def railing_post(p):
    """A square iron post leaded into the coping, a collar under the handrail and a ball finial."""
    p.box('lead', (0, 0, .015), (.14, .14, .03), bevel=0, uv='flat')
    p.box('iron', (0, 0, .58), (.07, .07, 1.1), bevel=.006, uv='flat')
    p.box('iron', (0, 0, .07), (.1, .1, .1), bevel=.008, uv='flat')
    p.box('iron', (0, 0, 1.07), (.1, .1, .04), bevel=.008, uv='flat')
    p.cylinder('iron', (0, 0, 1.13), (0, 0, 1.17), .03, 8, uv='flat')
    p.sphere('iron', (0, 0, 1.21), .05, 1)


def garden_wall(p, length):
    """A rubble-faced garden wall with a dressed coping and a little ivy, 1.25 m high."""
    a, b = .24, length - .24
    rng = p.rng
    p.box('stone', ((a + b) / 2, 0, .58), (b - a, .36, 1.16), bevel=.015, uv='world')
    for side in (-1, 1):
        z = .05
        while z < 1.05:
            h = rng.uniform(.18, .26)
            x = a + rng.uniform(0, .3)
            while x < b - .1:
                w = min(rng.uniform(.3, .55), b - x)
                p.box('stone', (x + w / 2, side * .185, min(z + h / 2, 1.08)), (w - .02, .02, min(h - .02, 1.1 - z)), bevel=.006, uv=('blocks', 0))
                x += w
            z += h
    p.box('stone', ((a + b) / 2, 0, 1.2), (b - a + .02, .44, .1), bevel=.03, segments=2, uv=('blocks', 0))
    if rng.random() < .8:
        x = rng.uniform(a + .3, b - .3)
        side = rng.choice((-1, 1))
        for i in range(10):
            p.sphere(('leaf', 'leaf_dark', 'leaf_light')[i % 3], (x + rng.uniform(-.35, .35), side * .22, 1.18 - i * .09), .08, 1, (1, .6, 1))


def garden_pier(p):
    p.box('stone', (0, 0, .7), (.56, .56, 1.4), bevel=.02, uv=('blocks', 0))
    p.box('stone', (0, 0, 1.45), (.66, .66, .1), bevel=.025, segments=2, uv=('blocks', 0))
    p.cylinder('stone', (0, 0, 1.5), (0, 0, 1.56), .12, 10, uv=('blocks', 0))
    p.sphere('stone', (0, 0, 1.68), .14, 2)


def garden_gate(p, length=2.0):
    """A pair of ledged and braced timber gate leaves, closed, between the piers at either end."""
    lo, hi = .29, length - .29
    leaf = (hi - lo) / 2
    for side in range(2):
        x0 = lo + side * leaf
        boards = 5
        for k in range(boards):
            x = x0 + leaf * (k + .5) / boards
            top = 1.3 + .1 * math.sin(math.pi * (k + .5 + side * boards) / (2 * boards))
            p.box('shutter', (x, 0, .08 + (top - .08) / 2), (leaf / boards - .012, .045, top - .08), bevel=.005, uv='local')
        for zz in (.32, 1.08):
            p.box('shutter', (x0 + leaf / 2, -.035, zz), (leaf - .05, .03, .1), bevel=.004, uv='local')
            hinge = x0 + (.12 if side == 0 else leaf - .12)
            p.box('iron', (x0 + leaf / 2 + (-.08 if side == 0 else .08), -.055, zz), (leaf * .6, .012, .04), bevel=0, uv='flat')
            p.cylinder('iron', (hinge - .02 if side == 0 else hinge + .02, -.03, zz - .06), (hinge - .02 if side == 0 else hinge + .02, -.03, zz + .06), .016, 6, uv='flat')
        brace = math.hypot(leaf - .14, .66)
        angle = math.atan2(.66, leaf - .14) * (1 if side == 0 else -1)
        p.box('shutter', (x0 + leaf / 2, -.035, .7), (brace, .028, .08), (0, -angle, 0), .004, 'local')
    mid = (lo + hi) / 2
    p.box('iron', (mid, -.07, .9), (.22, .015, .04), bevel=0, uv='flat')
    torus = [Vector((mid + .06 + math.cos(math.tau * i / 8) * .035, -.08, .82 + math.sin(math.tau * i / 8) * .035)) for i in range(9)]
    for q0, q1 in zip(torus, torus[1:]):
        p.beam('iron', q0, q1, .01, .01, up=(0, 1, 0), uv='flat')


PIECES = {
    'town-balustrade': (lambda p: balustrade(p, 3.0), 'Stone balustrade bay, 3 m'),
    'town-balustrade-short': (lambda p: balustrade(p, 1.5), 'Stone balustrade bay, 1.5 m'),
    'town-balustrade-pier': (balustrade_pier, 'Balustrade pier'),
    'town-railing': (lambda p: railing(p, 2.0), 'Iron railing bay, 2 m'),
    'town-railing-short': (lambda p: railing(p, 1.0), 'Iron railing bay, 1 m'),
    'town-railing-stair': (lambda p: railing(p, 1.0, 1.0, .07), 'Raked iron railing for one stair cell'),
    'town-railing-post': (railing_post, 'Iron railing post'),
    'town-garden-wall': (lambda p: garden_wall(p, 3.0), 'Garden wall bay, 3 m'),
    'town-garden-wall-short': (lambda p: garden_wall(p, 1.5), 'Garden wall bay, 1.5 m'),
    'town-garden-pier': (garden_pier, 'Garden wall pier'),
    'town-garden-gate': (garden_gate, 'Garden gate between two piers, 2 m'),
}


if __name__ == '__main__':
    chosen, out = kit.selected(list(PIECES))
    for index, asset in enumerate(chosen):
        make, label = PIECES[asset]
        root = kit.begin(asset, PALETTE)
        parts = kit.Parts(3100 + index)
        make(parts)
        parts.finish(root)
        if out:
            kit.draft(asset, out)
        else:
            kit.save(asset, 'art/source/world/square-hub/v1/author_pieces.py', PALETTE, {'reference': 'docs/concept/v0.72/art/guildhall-square.png'})
