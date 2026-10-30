"""Guarded one-time authoring of haverlund-square-ground: the base ground of Rootward Square version 3 and of the town
round it, built from plan.py. It carries land only: paving, levels, retaining walls, copings, stairs and the town's
ground past every edge. Buildings, railings, lamps and houses are separate models placed by the area document on top.

    blender --background --factory-startup --python art/source/world/square-hub/v1/author_ground.py
    ... -- --draft .cache/square-hub/drafts      (a review draft outside art/source)

The whole town is rasterised onto a 1 m grid of heights and surfaces (the square's own cells from plan.cells(), the
rest from the slabs below). Tops are merged into runs; a wall stands wherever neighbouring heights differ, with
dressed stone courses and a coping near the square and pilasters on the tall drops; stairs carry their treads and
cheeks. Logical x/y are Blender x/y; z is up; the model sits at the area's origin.
"""
import hashlib
import json
import math
import random
import sys
from pathlib import Path

import bmesh
import bpy
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE))
sys.path.insert(0, str(HERE.parents[1] / 'seaside-houses/v1'))
import plan  # noqa: E402
import house_kit as kit  # noqa: E402

ASSET = 'haverlund-square-ground'
LANE = ROOT / 'art/source/world/sparks-lane/v1'
PALETTE = {'stone': 'seaside_stone_limestone', 'roof': 'seaside_roof_terracotta', 'ridge': 'seaside_roof_terracotta',
           'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_teal'}
REPEAT = {'ground_cobbles': 2.0, 'ground_flags': 3.0, 'ground_grass': 8.0, 'stone': 1.9}
X0, X1, Y0, Y1 = -32, 106, -40, 96
LT = plan.LOWER_TOWN
UP = {'N': (0, 1), 'S': (0, -1), 'E': (1, 0), 'W': (-1, 0)}


def materials():
    kit.material('ground_cobbles', 'ffffff', LANE / 'lane-cobbles.png', .95)
    kit.material('ground_flags', 'ffffff', LANE / 'lane-flags.png', .95)
    kit.material('ground_grass', 'ffffff', LANE / 'lane-grass-lush.png', .97)
    kit.material('ground_brass', 'c99d55', roughness=.4, metallic=.5)


# --- the town as a grid ---------------------------------------------------------------------------------------------
def slab(cells, rect, z, mat):
    """Raises or lowers a rectangle of the town. Grass slabs become gardens and yards in their organic pattern."""
    x0, y0, x1, y1 = rect
    for x in range(math.ceil(x0), math.floor(x1) + 1):
        for y in range(math.ceil(y0), math.floor(y1) + 1):
            if (x, y) in cells and not cells[(x, y)]['inside']:
                surface = mat if mat != 'ground_grass' else ('ground_grass' if garden(x, y) else 'ground_flags')
                cells[(x, y)].update(z=z, mat=surface, stair=None)


def stair(cells, x, y, up, low, high, mat='stone'):
    cells[(x, y)].update(z=high, low=low, mat=mat, stair=up)


def garden(x, y):
    """Organic garden patches: grass where a few crossing waves add up, flags elsewhere."""
    return math.sin(x * .37 + 1.3) + math.sin(y * .41 + x * .13) + .6 * math.sin((x - y) * .23) > 1.1


def lower_town(x, y):
    """Streets under the walls and between the house rows; yards in flags; gardens in grass."""
    if -4 <= y <= -2 and x <= 76 or 74 <= x <= 76 and y <= 40 or x in (27, 28) and y < -2 or y in (-20, -21) or x in (90, 91) and y < 40:
        return 'ground_cobbles'
    return 'ground_grass' if garden(x, y) else 'ground_flags'


def surface(x, y, kind):
    if kind == 'hill':
        return 'ground_flags' if x >= 9 and (y % 9 in (0, 1)) else 'ground_grass'
    if kind in ('band', 'cafe'):
        return 'ground_flags'
    if kind == 'street':
        return 'ground_cobbles'
    if y <= 1 or x >= 70 or y >= 46 or x <= 21 and y >= 12 or x <= 13:
        return 'ground_flags'
    return 'ground_cobbles'


def town():
    cells = {}
    for x in range(X0, X1 + 1):
        for y in range(Y0, Y1 + 1):
            cells[(x, y)] = {'z': LT, 'mat': lower_town(x, y), 'stair': None, 'inside': False, 'kind': 'outside'}
    # West: the hill rising behind the square, the street climbing on to the lane, house plots south of it.
    slab(cells, (-32.5, 10.5, -0.5, 96.5), 4.0, 'ground_grass')
    slab(cells, (-2.5, 10.5, -0.5, 96.5), 2.0, 'ground_grass')
    slab(cells, (-32.5, 10.5, -14.5, 96.5), 6.0, 'ground_grass')
    slab(cells, (-32.5, -20.5, -0.5, -8.5), -3.5, 'ground_grass')
    slab(cells, (-18.5, -8.5, -0.5, 5.5), 3.0, 'ground_flags')
    slab(cells, (-32.5, -8.5, -18.5, 5.5), 4.5, 'ground_grass')
    slab(cells, (-32.5, 5.5, -0.5, 10.5), 2.0, 'ground_cobbles')
    for k, x in enumerate((-3, -8, -13, -18)):
        for y in plan.STREET_Y:
            stair(cells, x, y, 'W', 2.0 + k, 3.0 + k, 'stone')
        slab(cells, (x - 4.5, 5.5, x - 0.5, 10.5), 3.0 + k, 'ground_cobbles')
    slab(cells, (-32.5, 5.5, -22.5, 10.5), 6.0, 'ground_cobbles')
    # North: the band's yards carry on east, then the upper town terraces up the hill; Hill Street climbs through.
    slab(cells, (17.5, 63.5, 106.5, 96.5), 1.5, 'ground_flags')
    slab(cells, (17.5, 77.5, 106.5, 96.5), 3.0, 'ground_grass')
    slab(cells, (-0.5, 63.5, 11.5, 96.5), 3.0, 'ground_grass')
    slab(cells, (71.5, 48.5, 106.5, 63.5), 0.0, 'ground_flags')
    slab(cells, (11.5, 63.5, 17.5, 96.5), 1.0, 'ground_cobbles')
    for k, y in enumerate((70, 77, 84)):
        for x in plan.NW_STREET_X:
            stair(cells, x, y, 'N', 1.0 + k, 2.0 + k)
        slab(cells, (11.5, y + .5, 17.5, 96.5), 2.0 + k, 'ground_cobbles')
    # East: Lantern Row carries on along the hill at the square's level, the lower town below its south wall.
    slab(cells, (71.5, 42.5, 106.5, 48.5), 0.0, 'ground_cobbles')
    # The square's own cells.
    grid, stairs = plan.cells()
    for (x, y), c in grid.items():
        cells[(x, y)] = {'z': float(c['level']), 'mat': surface(x, y, c['kind']), 'stair': None, 'inside': True, 'kind': c['kind'], 'walk': c['walk']}
    for s in stairs:
        x, y = s['at']
        low = float(grid[(x, y)]['level'])
        stair(cells, x, y, s['up'], low, low + 1)
    # South-east: the Harbour Steps, three flights of half-metre treads with two landings, down to the lower town.
    z = 0.0
    for y in range(-1, -25, -1):
        flight = -1 >= y >= -6 or -9 >= y >= -14 or -17 >= y >= -24
        for x in plan.SE_STEPS_X:
            if flight:
                stair(cells, x, y, 'N', z - .5, z)
            else:
                cells[(x, y)].update(z=z, mat='ground_flags', stair=None)
        if flight:
            z -= .5
    for x in plan.SE_STEPS_X:
        for y in range(-25, -30, -1):
            cells[(x, y)].update(z=LT, mat='ground_cobbles', stair=None)
    return cells


# --- drawing ----------------------------------------------------------------------------------------------------------
def tops(p, cells):
    """Each row's runs of equal height and surface, as single quads painted in world units."""
    for y in range(Y0, Y1 + 1):
        x = X0
        while x <= X1:
            c = cells[(x, y)]
            if c['stair'] or c.get('skip'):
                x += 1
                continue
            end = x
            while end + 1 <= X1 and not cells[(end + 1, y)]['stair'] and not cells[(end + 1, y)].get('skip') and cells[(end + 1, y)]['z'] == c['z'] and cells[(end + 1, y)]['mat'] == c['mat']:
                end += 1
            a, b, z, rep = x - .5, end + .5, c['z'], REPEAT[c['mat']]
            verts = [(a, y - .5, z), (b, y - .5, z), (b, y + .5, z), (a, y + .5, z)]
            p.add(c['mat'], verts, [(0, 1, 2, 3)], [[(v[0] / rep, v[1] / rep) for v in verts]])
            x = end + 1


def height_toward(cell, side):
    """A cell's surface height at its edge on `side` (a stair is low at its downhill edge, high uphill)."""
    if not cell['stair']:
        return cell['z'], cell['z']
    up = UP[cell['stair']]
    if side == up:
        return cell['z'], cell['z']
    if side == (-up[0], -up[1]):
        return cell['low'], cell['low']
    return None


def walls(p, cells):
    """Walls along every edge whose two sides differ in height, merged into straight runs."""
    runs = {}
    for (x, y), c in cells.items():
        for side in ((1, 0), (0, 1), (-1, 0), (0, -1)):
            n = cells.get((x + side[0], y + side[1]))
            if n is None or c.get('skip') or n.get('skip'):
                continue          # a cell another model draws (the lane set) keeps its own edges
            if c['stair'] and height_toward(c, side) is None:
                continue          # a stair's sides are its cheeks, drawn with the treads
            high = height_toward(c, side)[0] if c['stair'] else c['z']
            if n['stair']:
                back = height_toward(n, (-side[0], -side[1]))
                low = n['low'] if back is None else back[0]
            else:
                low = n['z']
            if high - low < .05:
                continue
            near = c.get('inside') or n.get('inside') or high >= -.5
            flush = bool(c.get('walk')) or c.get('kind') == 'outside' and high > LT and c['mat'] == 'ground_cobbles'
            if side[0]:
                key = ('y', x + side[0] * .5, side[0], round(low, 2), round(high, 2), near, flush)
                runs.setdefault(key, []).append(y)
            else:
                key = ('x', y + side[1] * .5, side[1], round(low, 2), round(high, 2), near, flush)
                runs.setdefault(key, []).append(x)
    for (axis, line, out, low, high, near, flush), stops in runs.items():
        stops.sort()
        start = prev = stops[0]
        for s in stops[1:] + [None]:
            if s is not None and s == prev + 1:
                prev = s
                continue
            wall(p, axis, line, out, start - .5, prev + .5, low, high, near, flush)
            if s is not None:
                start = prev = s


def wall(p, axis, line, out, a, b, low, high, near, flush):
    """One straight wall facing `out` along `axis`, from `low` up to `high`. Near the square: dressed courses and a
    coping; tall walls get a plinth, a string course and pilasters."""
    rng = p.rng
    o = Vector((out, 0, 0)) if axis == 'y' else Vector((0, out, 0))
    along = Vector((0, 1, 0)) if axis == 'y' else Vector((1, 0, 0))
    base = Vector((line, 0, 0)) if axis == 'y' else Vector((0, line, 0))

    def at(s, z, d=0.0):
        return base + along * s + o * d + Vector((0, 0, z))

    verts = [at(a, low), at(b, low), at(b, high), at(a, high)]
    if (verts[1] - verts[0]).cross(verts[3] - verts[0]).dot(o) < 0:
        verts = [verts[1], verts[0], verts[3], verts[2]]
    rep = REPEAT['stone']
    p.add('stone', [tuple(v) for v in verts], [(0, 1, 2, 3)], [[((v - base).dot(along) / rep, v.z / rep) for v in verts]])
    height = high - low
    tall = height > 3.2
    dressed = min(height, 2.3) if near else 0.0
    if dressed > 0:
        course = .31
        top = high - (.14 if flush else 0)
        n = max(1, round((dressed - (.14 if flush else 0)) / course))
        hh = (dressed - (.14 if flush else 0)) / n
        for k in range(n):
            z0 = top - (k + 1) * hh
            s = a + (rng.uniform(.2, .6) if k % 2 else 0)
            first = True
            while s < b - .05:
                w = min(rng.uniform(.55, .95), b - s)
                if b - (s + w) < .25:
                    w = b - s
                if first and s > a:
                    p_block(p, at(a, z0), at(s, z0 + hh - .02), o, along)
                first = False
                p_block(p, at(s + .012, z0), at(s + w - .012, z0 + hh - .02), o, along)
                s += w
    # The coping: flush with a walk on top, proud on garden walls.
    zc0, zc1 = (high - .14, high) if flush else (high, high + .16)
    s = a
    while s < b - .05:
        w = min(rng.uniform(.8, 1.2), b - s)
        if b - (s + w) < .3:
            w = b - s
        lo, hi = at(s + .01, zc0, .07), at(s + w - .01, zc1, -.36)
        p_box(p, 'stone', lo, hi, ('blocks', 0))
        s += w
    if tall:
        p_box(p, 'stone', at(a, low, .1), at(b, low + .45, -.1), 'world')
        sc = high - 2.45
        p_box(p, 'stone', at(a, sc - .14, .08), at(b, sc, -.1), 'world')
        k = math.floor(a / 6) + 1
        while k * 6 < b - .4:
            s = k * 6
            p_box(p, 'stone', at(s - .3, low + .45, .14), at(s + .3, sc - .14, -.05), ('blocks', 0))
            k += 1


def p_box(p, mat, lo, hi, uv):
    centre = (lo + hi) / 2
    size = Vector((abs(hi.x - lo.x), abs(hi.y - lo.y), abs(hi.z - lo.z)))
    p.box(mat, tuple(centre), tuple(size), bevel=.012 if min(size) > .1 else 0, uv=uv)


def p_block(p, lo, hi, o, along):
    """A dressed stone standing a little proud of its wall."""
    lo2, hi2 = lo + o * .035, hi - o * .06
    p_box(p, 'stone', lo2, hi2, ('blocks', 0))


def kerbs(p, cells):
    """A dressed kerb wherever the walkable square meets a garden, yard or hill strip at the same height, so the edge
    of where one may walk is a thing you can see."""
    runs = {}
    for (x, y), c in cells.items():
        if not c.get('inside') or not c.get('walk') or c['stair']:
            continue
        for side in ((1, 0), (0, 1), (-1, 0), (0, -1)):
            n = cells.get((x + side[0], y + side[1]))
            if n is None or not n.get('inside') or n.get('walk', True) or n['stair'] or abs(n['z'] - c['z']) > .05:
                continue
            key = ('y', x + side[0] * .5, side[0], c['z']) if side[0] else ('x', y + side[1] * .5, side[1], c['z'])
            runs.setdefault(key, []).append(y if side[0] else x)
    for (axis, line, out, z), stops in runs.items():
        stops.sort()
        start = prev = stops[0]
        for s in stops[1:] + [None]:
            if s is not None and s == prev + 1:
                prev = s
                continue
            a, b = start - .5, prev + .5
            if axis == 'y':
                p.box('stone', (line + out * .1, (a + b) / 2, z + .06), (.22, b - a, .12), bevel=.02, uv=('blocks', 0))
            else:
                p.box('stone', ((a + b) / 2, line + out * .1, z + .06), (b - a, .22, .12), bevel=.02, uv=('blocks', 0))
            if s is not None:
                start = prev = s


def treads(p, cells):
    """Stair cells: treads with nosings, and cheek walls on any side that drops away."""
    for (x, y), c in cells.items():
        if not c['stair'] or c.get('skip'):
            continue
        ux, uy = UP[c['stair']]
        rise = c['z'] - c['low']
        n = max(2, round(rise / .2))
        along = Vector((ux, uy, 0))
        across = Vector((-uy, ux, 0))
        centre = Vector((x, y, 0))
        for k in range(n):
            t0, t1 = k / n, (k + 1) / n
            z1 = c['low'] + rise * (k + 1) / n
            lo = centre + along * (t0 - .5 - .02) + across * -.5
            hi = centre + along * (.5) + across * .5
            lo.z, hi.z = c['low'] + rise * k / n - .02 if k else c['low'] - .3, z1
            p_box(p, 'stone', Vector((min(lo.x, hi.x), min(lo.y, hi.y), lo.z)), Vector((max(lo.x, hi.x), max(lo.y, hi.y), hi.z)), ('blocks', 0))
        for side in (across, -across):
            n_cell = cells.get((x + int(side.x), y + int(side.y)))
            if n_cell is None or n_cell['stair'] or n_cell.get('skip') or n_cell['z'] >= c['z'] - .05:
                continue
            floor = n_cell['z']
            edge = centre + side * .5
            pts = [edge + along * -.5 + Vector((0, 0, floor)), edge + along * .5 + Vector((0, 0, floor)),
                   edge + along * .5 + Vector((0, 0, c['z'])), edge + along * -.5 + Vector((0, 0, max(c['low'], floor)))]
            o = Vector((side.x, side.y, 0))
            if (pts[1] - pts[0]).cross(pts[3] - pts[0]).dot(o) < 0:
                pts = [pts[1], pts[0], pts[3], pts[2]]
            rep = REPEAT['stone']
            p.add('stone', [tuple(v) for v in pts], [(0, 1, 2, 3)], [[((v.x + v.y) / rep, v.z / rep) for v in pts]])
            # A raked coping along the cheek's top.
            a = edge + along * -.5 + Vector((0, 0, c['low'])) - o * .18
            b = edge + along * .5 + Vector((0, 0, c['z'])) - o * .18
            p.beam('stone', a, b, .42, .14, up=(0, 0, 1), uv=('blocks', 0))


def harbour_parapets(p, cells):
    """Solid stone parapets either side of the Harbour Steps, following their fall, with piers at the landings."""
    for x in (plan.SE_STEPS_X[0] - .5 - .2, plan.SE_STEPS_X[-1] + .5 + .2):
        prev = None
        for y in range(-1, -25, -1):
            c = cells[(plan.SE_STEPS_X[0], y)]
            top_hi = c['z'] if not c['stair'] else c['z']
            top_lo = c['low'] if c['stair'] else c['z']
            a = Vector((x, y + .5, top_hi + .85))
            b = Vector((x, y - .5, top_lo + .85))
            pts = [Vector((x, y + .5, LT)), Vector((x, y - .5, LT)), b, a]
            for side in (-1, 1):
                q = [v + Vector((side * .2, 0, 0)) for v in pts]
                o = Vector((side, 0, 0))
                if (q[1] - q[0]).cross(q[3] - q[0]).dot(o) < 0:
                    q = [q[1], q[0], q[3], q[2]]
                p.add('stone', [tuple(v) for v in q], [(0, 1, 2, 3)], [[(v.y / 1.9, v.z / 1.9) for v in q]])
            p.beam('stone', a + Vector((0, 0, .07)), b + Vector((0, 0, .07)), .52, .14, up=(0, 0, 1), uv=('blocks', 0))
            if not c['stair'] and (prev is None or prev['stair']):
                p.box('stone', (x, y + .5, top_hi + 1.0), (.62, .62, 1.2), bevel=.02, uv=('blocks', 0))
            prev = c


# --- the square's paving details -----------------------------------------------------------------------------------
def rootwell_ring(p):
    """Three courses of pale setts round the Rootwell, a brass band and four brass power channels out to the square's
    edges: west to the market, north to the hall, east to the garden and south to the promenade."""
    cx, cy = plan.ROOTWELL
    for course, (r0, r1) in enumerate(((3.8, 4.7), (4.7, 5.6), (5.6, 6.5))):
        count = int(2 * math.pi * r1 / .7)
        shift = (course % 2) * .5
        for k in range(count):
            a0 = 2 * math.pi * (k + shift + .03) / count
            a1 = 2 * math.pi * (k + shift + .97) / count
            poly = [(cx + math.cos(a) * r, cy + math.sin(a) * r) for r, a in ((r0 + .02, a0), (r0 + .02, a1), (r1 - .02, a1), (r1 - .02, a0))]
            if (poly[1][0] - poly[0][0]) * (poly[2][1] - poly[0][1]) - (poly[1][1] - poly[0][1]) * (poly[2][0] - poly[0][0]) < 0:
                poly = poly[::-1]
            bm = bmesh.new()
            lower = [bm.verts.new((px, py, -.04)) for px, py in poly]
            upper = [bm.verts.new((px, py, .012)) for px, py in poly]
            bm.faces.new(list(reversed(lower)))
            bm.faces.new(upper)
            for i in range(4):
                j = (i + 1) % 4
                bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
            bm.normal_update()
            p._take(bm, Matrix.Identity(4), 'stone', ('blocks', 0))
    segs = 96
    for r in (6.55, 3.75):
        verts, faces = [], []
        for k in range(segs):
            a = 2 * math.pi * k / segs
            for rr in (r, r + .09):
                verts.append((cx + math.cos(a) * rr, cy + math.sin(a) * rr, .016))
        for k in range(segs):
            i, j = 2 * k, 2 * ((k + 1) % segs)
            faces.append((i, j, j + 1, i + 1))
        p.add('ground_brass', verts, faces, [[(0, 0)] * 4 for _ in faces])
    for (dx, dy), end in (((-1, 0), 21.6), ((0, 1), 45.6), ((1, 0), 69.6), ((0, -1), 1.6)):
        start = 6.7
        length = (abs(end - cx) if dx else abs(end - cy)) - start
        channel(p, Vector((cx + dx * start, cy + dy * start, 0)), Vector((dx, dy, 0)), length)


def channel(p, start, direction, length):
    """A brass power channel let into the paving: a brass strip between iron edges, studs, and a grate every 6 m."""
    across = Vector((-direction.y, direction.x, 0))
    end = start + direction * length
    for off, mat, w in ((0, 'ground_brass', .1), (.075, 'iron', .03), (-.075, 'iron', .03)):
        a, b = start + across * off, end + across * off
        verts = [a - across * w / 2, b - across * w / 2, b + across * w / 2, a + across * w / 2]
        verts = [(v.x, v.y, .014) for v in verts]
        v0, v1, v3 = Vector(verts[0]), Vector(verts[1]), Vector(verts[3])
        face = (0, 1, 2, 3) if (v1 - v0).cross(v3 - v0).z > 0 else (3, 2, 1, 0)
        p.add(mat, verts, [face], [[(0, 0)] * 4])
    k = .5
    while k < length:
        q = start + direction * k
        p.sphere('ground_brass', (q.x, q.y, .015), .03, 0, (1, 1, .4))
        k += .5
    k = 6.0
    while k < length - 1:
        q = start + direction * k
        size = (.5, .5, .02)
        p.box('grate', (q.x, q.y, .012), size, bevel=0, uv='flat')
        for j in range(5):
            r = q + across * (j - 2) * .08
            p.box('iron_light', (r.x, r.y, .024), (.03 if abs(direction.x) > .5 else .44, .44 if abs(direction.x) > .5 else .03, .008), bevel=0, uv='flat')
        k += 6.0


def drains(p):
    """Gutter grates along the promenade and the hall forecourt."""
    for x in range(16, 70, 8):
        p.box('grate', (x + .5, 1.2, .012), (.6, .32, .02), bevel=0, uv='flat')
        p.box('grate', (x + .5, 46.2, .012), (.6, .32, .02), bevel=0, uv='flat')


# --- saving ---------------------------------------------------------------------------------------------------------
def assemble():
    root = kit.begin(ASSET, PALETTE)
    materials()
    p = kit.Parts(5203)
    cells = town()
    tops(p, cells)
    walls(p, cells)
    kerbs(p, cells)
    treads(p, cells)
    harbour_parapets(p, cells)
    rootwell_ring(p)
    drains(p)
    p.finish(root)


def save(out=None):
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    bpy.ops.file.pack_all()
    if out:
        path = Path(out) / ASSET / 'model.blend'
        path.parent.mkdir(parents=True, exist_ok=True)
        bpy.ops.wm.save_as_mainfile(filepath=str(path))
        print('DRAFT', ASSET, path, flush=True)
        return
    scene['rootward_source'] = 'Editable authority: the base ground of Rootward Square v3. Do not rerun the authoring record.'
    folder = ROOT / 'art/source/world' / ASSET / 'v1'
    folder.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder / 'model.blend'))
    digest = lambda path: hashlib.sha256(Path(path).read_bytes()).hexdigest()  # noqa: E731
    note = {'asset': ASSET, 'date': '2026-10-29', 'reference': 'docs/concept/v0.72/art/guildhall-square.png',
            'authoring_record': 'art/source/world/square-hub/v1/author_ground.py', 'authoring_record_sha256': digest(__file__),
            'plan': 'art/source/world/square-hub/v1/plan.py', 'plan_sha256': digest(HERE / 'plan.py'),
            'kit': 'art/source/world/seaside-houses/v1/house_kit.py', 'kit_sha256': digest(kit.__file__),
            'note': 'Base ground only; buildings, railings and houses are separate placed models. Build through scripts/world-art.sh.'}
    (folder / 'provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', ASSET, flush=True)


if __name__ == '__main__':
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    draft = argv[argv.index('--draft') + 1] if '--draft' in argv else None
    if not draft and (ROOT / 'art/source/world' / ASSET / 'v1/model.blend').exists():
        raise RuntimeError('Existing editable master; authoring refuses to overwrite ' + ASSET)
    assemble()
    save(draft)
