import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import voxel_lib as vx  # noqa: E402

import math  # noqa: E402

# One-time Blender authoring record for six yard doodads: a watering can, a wooden bucket, a wheelbarrow, a clay jug, a
# notice board and a milk churn. Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/yard.py
# It refuses to run over a saved source. After this handoff, edit each model.blend in Blender and run
# scripts/world-art.sh build <id>; this file records how v1 was made and is not the master.
# To author only some models, pass their ids after --, with their saved sources removed first.
#
# Each model is a set of integer voxel cells at 0.05 m, with z = 0 as the base. A cell (x, y, z) covers the space from
# x to x + 1, and so on, so a symmetric run of cells from a to b has its centre at (a + b + 1) / 2. author_models() puts
# the origin at the middle of each footprint. Shading follows the game camera: tops are lightest, the front and the left
# are mid-tone, and the right and back are dark.

# Timber and iron are from the shared palette (art/world_palette.gd) or the kit. Iron_dark, terracotta, hay, the twine
# strands and the galvanised tones (taken from the palette's stone colours) are the only new names here.
COLOURS = {
    'oak': 'b07a45', 'oak_light': 'c59458', 'wood': '765039', 'wood_light': 'a47b51', 'wood_dark': '49382f',
    'iron': '394446', 'iron_light': '5f6c6e', 'iron_dark': '2b3335',
    'galv_light': 'bcc2ae', 'galv': '929a9a', 'galv_dark': '626f73',
    'clay_light': 'd08a60', 'clay': 'b06a46', 'clay_dark': '80442f',
    'cream': 'fff0cb', 'plaster': 'e8ddbd', 'plaster_shade': 'd3c6a4',
    'hay_light': 'e6c875', 'hay': 'c9a04e', 'hay_dark': 'a07a3a',
    'twine_light': '8c7447', 'twine': '6d5837', 'twine_dark': '4a3d26',
    'water_light': '9bd1c2', 'water': '5baca9', 'water_dark': '3a878c',
    'roof_light': '8271b1', 'roof': '66509a', 'roof_dark': '493c71',
    'teal': '347b85',
}
PART = {
    'galv_light': 'Metal', 'galv': 'Metal', 'galv_dark': 'Metal',
    'iron': 'Iron', 'iron_light': 'Iron', 'iron_dark': 'Iron',
    'oak': 'Timber', 'oak_light': 'Timber', 'wood': 'Timber', 'wood_light': 'Timber', 'wood_dark': 'Timber',
    'clay_light': 'Clay', 'clay': 'Clay', 'clay_dark': 'Clay',
    'cream': 'Cream', 'plaster': 'Cream', 'plaster_shade': 'Cream',
    'hay_light': 'Hay', 'hay': 'Hay', 'hay_dark': 'Hay',
    'twine_light': 'Rope', 'twine': 'Rope', 'twine_dark': 'Rope',
    'water_light': 'Water', 'water': 'Water', 'water_dark': 'Water',
    'roof_light': 'Roof', 'roof': 'Roof', 'roof_dark': 'Roof',
    'teal': 'Pins',
}

# A family is (light, mid, dark). A plain string is a fixed material and is not shaded.
GALV = ('galv_light', 'galv', 'galv_dark')
IRON = ('iron_light', 'iron', 'iron_dark')
OAK = ('oak_light', 'oak', 'wood')
WOOD = ('wood_light', 'wood', 'wood_dark')
CLAY = ('clay_light', 'clay', 'clay_dark')
CREAM = ('cream', 'plaster', 'plaster_shade')
HAY = ('hay_light', 'hay', 'hay_dark')
ROPE = ('twine_light', 'twine', 'twine_dark')
WATER = ('water_light', 'water', 'water_dark')
ROOF = ('roof_light', 'roof', 'roof_dark')

UP = (0.0, 0.0, 1.0)
DOWN = (0.0, 0.0, -1.0)


def normalise(v):
    length = math.sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])
    if length < 1e-9:
        return UP
    return (v[0] / length, v[1] / length, v[2] / length)


def dot(a, b):
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]


# The light comes from above and the front-left, so a face's tone follows how it turns toward that light.
LIGHT = normalise((-0.35, -0.55, 0.75))


def shade(normal, fam):
    light, mid, dark = fam
    d = dot(normal, LIGHT)
    if d > 0.6:
        return light
    if d < 0.0:
        return dark
    return mid


class Build:
    """Voxels as {cell: (family or fixed material, outward normal)}. finish() resolves each to a material name. A cell
    with an empty cell above it faces up, and one with an empty cell below it faces down, whatever its normal says."""

    def __init__(self):
        self.cells = {}

    def put(self, cell, fam, normal=UP):
        self.cells[cell] = (fam, normal)

    def remove(self, cell):
        self.cells.pop(cell, None)

    def finish(self):
        out = {}
        for cell, (fam, normal) in self.cells.items():
            if isinstance(fam, str):
                out[cell] = fam
                continue
            x, y, z = cell
            if (x, y, z + 1) not in self.cells:
                normal = UP
            elif (x, y, z - 1) not in self.cells:
                normal = DOWN
            out[cell] = shade(normal, fam)
        return out


def cyl(B, cx, cy, z0, z1, r, fam):
    """A vertical cylinder of radius r around the continuous centre (cx, cy)."""
    for z in range(z0, z1 + 1):
        for x in range(math.floor(cx - r) - 1, math.ceil(cx + r) + 1):
            for y in range(math.floor(cy - r) - 1, math.ceil(cy + r) + 1):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                if dx * dx + dy * dy <= r * r + 1e-9:
                    B.put((x, y, z), fam, normalise((dx, dy, 0.0)))


def box(B, x0, x1, y0, y1, z0, z1, fam):
    """A solid box of cells, both ends inclusive. Each cell's normal points out through the faces it lies on."""
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            for z in range(z0, z1 + 1):
                n = (-(x == x0) + (x == x1), -(y == y0) + (y == y1), -(z == z0) + (z == z1))
                B.put((x, y, z), fam, normalise(n))


def ellipsoid(B, centre, radii, fam):
    cx, cy, cz = centre
    rx, ry, rz = radii
    for x in range(math.floor(cx - rx) - 1, math.ceil(cx + rx) + 1):
        for y in range(math.floor(cy - ry) - 1, math.ceil(cy + ry) + 1):
            for z in range(math.floor(cz - rz) - 1, math.ceil(cz + rz) + 1):
                u, v, w = x + 0.5 - cx, y + 0.5 - cy, z + 0.5 - cz
                if (u / rx) ** 2 + (v / ry) ** 2 + (w / rz) ** 2 <= 1 + 1e-9:
                    B.put((x, y, z), fam, normalise((u / rx ** 2, v / ry ** 2, w / rz ** 2)))


def stroke(B, path, radii, fam, step=0.25):
    """A thick tube along a polyline of continuous points. A cell belongs to it when its centre is inside an ellipsoid
    of the given radii around the path."""
    rx, ry, rz = radii
    samples = []
    for a, b in zip(path, path[1:]):
        n = max(1, math.ceil(math.dist(a, b) / step))
        for k in range(n):
            t = k / n
            samples.append(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))
    samples.append(tuple(path[-1]))
    for p in samples:
        for x in range(math.floor(p[0] - rx) - 1, math.ceil(p[0] + rx) + 1):
            for y in range(math.floor(p[1] - ry) - 1, math.ceil(p[1] + ry) + 1):
                for z in range(math.floor(p[2] - rz) - 1, math.ceil(p[2] + rz) + 1):
                    u, v, w = x + 0.5 - p[0], y + 0.5 - p[1], z + 0.5 - p[2]
                    if (u / rx) ** 2 + (v / ry) ** 2 + (w / rz) ** 2 <= 1 + 1e-9:
                        B.put((x, y, z), fam, normalise((u / rx ** 2, v / ry ** 2, w / rz ** 2)))


def bezier(points, n=16):
    out = []
    for k in range(n + 1):
        t = k / n
        m = 1 - t
        coef = (m ** 3, 3 * m * m * t, 3 * m * t * t, t ** 3)
        out.append(tuple(sum(c * p[i] for c, p in zip(coef, points)) for i in range(3)))
    return out


def disc(B, centre, axis, radius, thickness, fam):
    """A flat round plate `thickness` cells deep, facing along `axis`."""
    ax = normalise(axis)
    reach = radius + 1
    for x in range(math.floor(centre[0] - reach), math.ceil(centre[0] + reach) + 1):
        for y in range(math.floor(centre[1] - reach), math.ceil(centre[1] + reach) + 1):
            for z in range(math.floor(centre[2] - reach), math.ceil(centre[2] + reach) + 1):
                u = (x + 0.5 - centre[0], y + 0.5 - centre[1], z + 0.5 - centre[2])
                t = dot(u, ax)
                in_plane = dot(u, u) - t * t
                if abs(t) <= thickness / 2 + 1e-9 and in_plane <= radius * radius + 1e-9:
                    face = ax if t >= 0 else (-ax[0], -ax[1], -ax[2])
                    B.put((x, y, z), fam, face)


def connected(cells):
    start = next(iter(cells))
    seen = {start}
    todo = [start]
    while todo:
        x, y, z = todo.pop()
        for dx, dy, dz in vx.DIRECTIONS:
            n = (x + dx, y + dy, z + dz)
            if n in cells and n not in seen:
                seen.add(n)
                todo.append(n)
    return len(seen) == len(cells)


def watering_can():
    """A galvanised body on a dark foot ring, a spout rising to a rose with holes, and an iron carrying handle."""
    B = Build()
    cx, cy = 0.5, 0.5
    cyl(B, cx, cy, 1, 4, 2.5, GALV)
    cyl(B, cx, cy, 0, 0, 2.5, IRON)
    cyl(B, cx, cy, 2, 2, 2.5, 'galv_dark')
    spout = [(0.5, -1.5, 1.5), (0.5, -3.5, 2.6), (0.5, -5.2, 4.0)]
    stroke(B, spout, (1.0, 0.9, 0.9), GALV)
    axis = normalise((0.0, -1.7, 1.4))
    rose = (0.5, -5.2 + 0.5 * axis[1], 4.0 + 0.5 * axis[2])
    disc(B, rose, axis, 2.0, 1.0, GALV)
    e1 = (1.0, 0.0, 0.0)
    e2 = (0.0, -axis[2], axis[1])
    for a, b in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
        p = [rose[i] + 1.0 * (a * e1[i] + b * e2[i]) for i in range(3)]
        cell = tuple(math.floor(c) for c in p)
        if cell in B.cells:
            B.put(cell, 'iron_dark')
    arc = [(0.5, 0.5 + 2.1 * math.cos(math.pi * k / 12), 3.8 + 2.1 * math.sin(math.pi * k / 12)) for k in range(13)]
    stroke(B, arc, (1.0, 0.9, 0.9), IRON)
    return B.finish()


def wooden_bucket():
    """Eight oak staves in a shell one voxel thick, a dark floor, two iron hoops, water in the top and a twine bail."""
    B = Build()
    cx = cy = 1.0
    step = 2 * math.pi / 8

    def outer(z):
        return 2.6 + 0.4 * z / 6

    for z in range(0, 7):
        r = outer(z)
        for x in range(-4, 6):
            for y in range(-4, 6):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = math.hypot(dx, dy)
                if d > r + 1e-9:
                    continue
                cell = (x, y, z)
                if z == 0:
                    B.put(cell, 'wood_dark')
                elif d <= r - 1.0 + 1e-9:
                    if z == 5:
                        B.put(cell, WATER)
                else:
                    offset = (math.atan2(dy, dx) + math.pi) % step
                    if min(offset, step - offset) < 0.12:
                        B.put(cell, 'wood_dark')
                    else:
                        B.put(cell, OAK, normalise((dx, dy, 0.0)))
    for z in (1, 4):
        r = outer(z)
        for x in range(-4, 6):
            for y in range(-4, 6):
                d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
                if r - 1.0 < d <= r + 1e-9:
                    B.put((x, y, z), IRON, normalise((x + 0.5 - cx, y + 0.5 - cy, 0.0)))
    bail = [(1.0 - 2.5 * math.cos(math.pi * k / 16), 1.0, 6.0 + 2.0 * math.sin(math.pi * k / 16)) for k in range(17)]
    stroke(B, bail, (0.8, 0.9, 0.8), ROPE)
    return B.finish()


def wheelbarrow():
    """A timber tray with iron rim, a hay load, one wheel at the front on an iron axle, and two handles at the back."""
    B = Build()
    wy, wz = -4.5, 3.5
    for x in (-1, 0, 1):
        for y in range(-8, -1):
            for z in range(0, 7):
                u, v = y + 0.5 - wy, z + 0.5 - wz
                r = math.hypot(u, v)
                if 2.0 < r <= 3.2 + 1e-9:
                    B.put((x, y, z), IRON, normalise((x, u, v)))
                elif 1.0 < r <= 2.0 + 1e-9:
                    spoke = min(abs(-u * math.sin(a) + v * math.cos(a))
                                for a in (0.0, math.pi / 4, math.pi / 2, 3 * math.pi / 4))
                    if spoke <= 0.6:
                        B.put((x, y, z), WOOD, normalise((x, u, v)))
    for x in range(-2, 3):
        for y in range(-7, -1):
            for z in range(1, 6):
                u, v = y + 0.5 - wy, z + 0.5 - wz
                if math.hypot(u, v) <= 1.0 + 1e-9:
                    B.put((x, y, z), IRON, normalise((0.0, u, v)))
    for sx in (-2.0, 3.0):
        stroke(B, [(sx, -4.5, 3.5), (sx, -0.5, 4.5)], (1.0, 0.9, 0.9), IRON)
    box(B, -4, 4, -1, 7, 4, 4, WOOD)
    box(B, -4, 4, -1, 7, 5, 7, OAK)
    for x in range(-3, 4):
        for y in range(0, 7):
            for z in range(5, 8):
                B.remove((x, y, z))
    for x in range(-4, 5):
        for y in range(-1, 8):
            if x in (-4, 4) or y in (-1, 7):
                B.put((x, y, 7), 'iron_light')
    box(B, -3, 3, 0, 6, 5, 6, HAY)
    ellipsoid(B, (0.5, 3.5, 7.0), (3.3, 3.8, 2.6), HAY)
    for hx in (-2.0, 3.0):
        stroke(B, [(hx, 7.5, 5.5), (hx, 9.5, 1.0)], (0.9, 0.9, 0.9), WOOD)
    return B.finish()


def clay_jug():
    """A terracotta belly with a cream glazed shoulder, neck and lip, a dark throat, and one loop handle on the right."""
    B = Build()
    cx = cy = 0.5
    profile = [2.8, 3.4, 3.9, 4.2, 4.2, 4.0, 3.6, 2.8, 2.0, 2.4]
    for z, r in enumerate(profile):
        fam = 'clay_dark' if z == 0 else (CLAY if z <= 5 else CREAM)
        cyl(B, cx, cy, z, z, r, fam)
    for x in range(-3, 5):
        for y in range(-3, 5):
            if math.hypot(x + 0.5 - cx, y + 0.5 - cy) <= 1.0 + 1e-9:
                B.remove((x, y, 9))
                B.put((x, y, 8), 'clay_dark')
    handle = bezier([(2.6, 0.5, 8.0), (6.6, 0.5, 8.2), (6.6, 0.5, 3.6), (4.6, 0.5, 3.0)], 16)
    stroke(B, handle, (0.9, 1.0, 0.9), CLAY)
    return B.finish()


def notice_board():
    """Two posts, a framed timber board with a cream notice pinned to it, and a violet tiled cap."""
    B = Build()
    box(B, -8, -7, -1, 0, 0, 20, WOOD)
    box(B, 6, 7, -1, 0, 0, 20, WOOD)
    box(B, -8, 7, -3, -2, 9, 18, WOOD)
    box(B, -7, 6, -3, -3, 10, 17, OAK)
    box(B, -6, 3, -4, -4, 11, 16, CREAM)
    for z in (15, 13):
        for x in range(-5, 2):
            B.put((x, -4, z), 'wood_dark')
    for x in (-5, 2):
        B.put((x, -4, 16), 'teal')
    box(B, -9, 8, -4, 1, 21, 21, ROOF)
    box(B, -9, 8, -3, 0, 22, 22, ROOF)
    box(B, -9, 8, -2, -1, 23, 23, ROOF)
    return B.finish()


def milk_churn():
    """A tall galvanised churn on a dark iron foot, two iron bands, a flared lid and a small arched handle on the lid."""
    B = Build()
    cx = cy = 1.0
    cyl(B, cx, cy, 0, 0, 3.4, IRON)
    for z in range(1, 12):
        cyl(B, cx, cy, z, z, 4.0, GALV)
    for z in (3, 4, 9, 10):
        cyl(B, cx, cy, z, z, 4.5, IRON)
    cyl(B, cx, cy, 12, 12, 4.6, GALV)
    cyl(B, cx, cy, 13, 13, 4.0, GALV)
    cyl(B, cx, cy, 14, 14, 3.0, GALV)
    arch = [(1.0 - 2.0 * math.cos(math.pi * k / 10), 1.0, 14.5 + 0.9 * math.sin(math.pi * k / 10)) for k in range(11)]
    stroke(B, arch, (0.8, 0.8, 0.8), IRON)
    return B.finish()


MODELS = {
    'watering-can': watering_can,
    'wooden-bucket': wooden_bucket,
    'wheelbarrow': wheelbarrow,
    'clay-jug': clay_jug,
    'notice-board': notice_board,
    'milk-churn': milk_churn,
}


def centre_of(cells):
    """The origin sits at the middle of the footprint and on the base (z = 0)."""
    assert min(z for _, _, z in cells) == 0, 'the base must sit on z = 0'
    xs = [x for x, _, _ in cells]
    ys = [y for _, y, _ in cells]
    return ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, 0)


wanted = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
chosen = []
for model_id, build in MODELS.items():
    if wanted and model_id not in wanted:
        continue
    cells = build()
    if not connected(cells):
        raise RuntimeError(f'{model_id} has loose voxels; every voxel must be attached')
    centre = centre_of(cells)
    xs = [x for x, _, _ in cells]
    ys = [y for _, y, _ in cells]
    zs = [z for _, _, z in cells]
    print(f'{model_id}: {max(xs) - min(xs) + 1} x {max(ys) - min(ys) + 1} x {max(zs) - min(zs) + 1} voxels, '
          f'origin at cell coordinates {centre}')
    chosen.append((model_id, cells, centre))
vx.author_models(__file__, chosen, COLOURS, PART)
