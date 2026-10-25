import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import math  # noqa: E402
import random  # noqa: E402
import voxel_lib as vx  # noqa: E402

# Garden doodads, v1: a window planter, a mossy boulder, a tree stump and a clump of stream reeds.
# One-time Blender authoring record. Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/garden.py
# It refuses to overwrite a saved source (voxel_lib.author_models). Afterwards, edit each model.blend in Blender and
# run scripts/world-art.sh build <id>. These are candidates only: unplaced, off the build shelf, decorative.
# Each cell is a 0.05 m voxel and the pivot is the ground origin. The planter's flower side faces Blender -Y (Godot +Z).

# Hex colours from art/world_palette.gd keep their palette hex. The petal centre matches flower-pot; the reed stalks,
# seed heads and the planter's flower-box shades are new here.
COLOURS = {
    'wood': '765039', 'wood_light': 'a47b51', 'wood_dark': '49382f',
    'soil': '755846', 'soil_dark': '584b48',
    'leaf': '4d7e35', 'leaf_light': '7ca946', 'leaf_dark': '2e5835',
    'moss': '638b41', 'moss_light': '83a852', 'moss_dark': '4e763b',
    'stone': '929a9a', 'stone_light': 'bcc2ae', 'stone_dark': '626f73',
    'cut_pale': 'e8ddbd', 'cut_ring': 'c59458', 'cut_heart': 'b07a45',
    'blade': '398c7d', 'blade_dark': '31554f',
    'petal_violet': '8271b1', 'petal_cream': 'fff0cb', 'petal_mauve': 'c399ad',
    'centre': 'c98a3c', 'reed': '8a9a52', 'reed_dark': '5e6e3a', 'seed': '6e4a2c', 'seed_light': '8f6138',
}
PART = {
    'wood': 'Timber', 'wood_light': 'Timber', 'wood_dark': 'Timber',
    'soil': 'Soil', 'soil_dark': 'Soil',
    'leaf': 'Plants', 'leaf_light': 'Plants', 'leaf_dark': 'Plants',
    'moss': 'Moss', 'moss_light': 'Moss', 'moss_dark': 'Moss',
    'stone': 'Stone', 'stone_light': 'Stone', 'stone_dark': 'Stone',
    'cut_pale': 'Cut', 'cut_ring': 'Cut', 'cut_heart': 'Cut',
    'blade': 'Reeds', 'blade_dark': 'Reeds', 'reed': 'Reeds', 'reed_dark': 'Reeds',
    'seed': 'Seedheads', 'seed_light': 'Seedheads',
    'petal_violet': 'Blossoms', 'petal_cream': 'Blossoms', 'petal_mauve': 'Blossoms', 'centre': 'Blossoms',
}


def window_planter():
    """A timber flower box 0.8 m by 0.25 m by 0.25 m: walls round a soil bed, a lit rim, a plank seam on the front,
    five blossoms on short stems (violet, cream, mauve), and two trails of ivy over the front edge."""
    rng = random.Random(231027)
    cells = {}
    for x in range(-8, 8):
        for y in range(-3, 2):
            wall = y in (-3, 1) or x in (-8, 7)
            for z in range(5):
                if not wall:
                    cells[(x, y, z)] = 'soil'
                elif z == 4:
                    cells[(x, y, z)] = 'wood_light'
                elif z == 0:
                    cells[(x, y, z)] = 'wood_dark'
                elif y == -3 and z == 2:
                    cells[(x, y, z)] = 'wood_dark'
                else:
                    cells[(x, y, z)] = 'wood'
    for x in range(-7, 7):
        for y in range(-2, 1):
            if rng.random() < 0.25:
                cells[(x, y, 4)] = 'soil_dark'
    # Blossoms: a stem from the soil, a plus of four petals round a centre, and a leaf on one side of the stem.
    for x, head, petal, leaf_side in ((-6, 7, 'petal_violet', 1), (-3, 8, 'petal_cream', -1),
                                      (0, 9, 'petal_mauve', 1), (3, 8, 'petal_cream', -1),
                                      (6, 7, 'petal_violet', 1)):
        y = -1
        for z in range(5, head):
            cells[(x, y, z)] = 'leaf_dark'
        cells[(x + leaf_side, y, 6)] = 'leaf_light' if leaf_side < 0 else 'leaf'
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            cells[(x + dx, y + dy, head)] = petal
        cells[(x, y, head)] = 'centre'
        cells[(x, y, head + 1)] = 'centre'
    # Ivy trails hang over the front face from the rim.
    for x, length in ((-5, 3), (4, 2)):
        for k in range(length):
            cells[(x, -4, 3 - k)] = 'leaf' if k == 0 else 'leaf_dark'
    return cells


def mossy_boulder():
    """A rounded grey stone 0.8 m across and 0.6 m tall: a lumpy ellipsoid cut flat at the ground, a shadowed lower
    band, a few lit facets on the upper front, and moss patches on top."""
    rng = random.Random(231028)
    phase = [rng.uniform(0.0, 2 * math.pi) for _ in range(4)]
    rx, ry, rz, zc = 8.0, 8.0, 7.0, 5.0

    def lump(x, y, z):
        return (0.12 * math.sin(0.9 * x + phase[0]) * math.cos(0.8 * y + phase[1])
                + 0.08 * math.sin(0.7 * (x - y) + 0.6 * z + phase[2]))

    def normal(x, y, z):
        nx, ny, nz = 2 * x / rx ** 2, 2 * y / ry ** 2, 2 * (z - zc) / rz ** 2
        length = math.sqrt(nx * nx + ny * ny + nz * nz)
        return nx / length, ny / length, nz / length

    solid = set()
    for x in range(-8, 8):
        for y in range(-8, 8):
            for z in range(0, 13):
                cx, cy, cz = x + 0.5, y + 0.5, z + 0.5
                d = (cx / rx) ** 2 + (cy / ry) ** 2 + ((cz - zc) / rz) ** 2
                if d + lump(cx, cy, cz) + rng.uniform(-0.02, 0.02) <= 1.0:
                    solid.add((x, y, z))

    light = (0.45, -0.55, 0.70)
    light_length = math.sqrt(sum(c * c for c in light))
    light = tuple(c / light_length for c in light)
    cells = {}
    for x, y, z in solid:
        if z <= 1:
            cells[(x, y, z)] = 'stone_dark'
            continue
        nx, ny, nz = normal(x + 0.5, y + 0.5, z + 0.5)
        facing = nx * light[0] + ny * light[1] + nz * light[2]
        if facing > 0.9:
            cells[(x, y, z)] = 'stone_light'
        elif facing < -0.3:
            cells[(x, y, z)] = 'stone_dark'
        else:
            cells[(x, y, z)] = 'stone'
    for x, y, z in solid:
        if (x, y, z + 1) in solid:
            continue
        nx, ny, nz = normal(x + 0.5, y + 0.5, z + 0.5)
        if nz < 0.4:
            continue
        field = (math.sin(0.8 * x + phase[3]) * math.cos(0.75 * y + phase[0])
                 + 0.3 * math.sin(1.3 * (x - y) + phase[1]))
        if field > 0.5:
            cells[(x, y, z + 1)] = 'moss_light' if field > 0.95 else ('moss_dark' if field < 0.7 else 'moss')
    return cells


def tree_stump():
    """A cut stump 0.5 m across and 0.4 m tall: bark sides with vertical ridges, a root flare at the base, a pale cut
    top with growth rings and a heart, and a small moss cap draped over one edge."""
    rng = random.Random(231029)
    cells = {}

    def dist(x, y):
        return math.hypot(x + 0.5, y + 0.5)

    def angle(x, y):
        return math.atan2(y + 0.5, x + 0.5)

    disc = {(x, y) for x in range(-5, 5) for y in range(-5, 5) if dist(x, y) <= 5.0}
    for x, y in disc:
        d = dist(x, y)
        ridge = math.sin(angle(x, y) * 10)
        for z in range(0, 7):
            if z == 0 or ridge > 0.7:
                cells[(x, y, z)] = 'wood_dark'
            elif ridge < -0.8:
                cells[(x, y, z)] = 'wood_light'
            else:
                cells[(x, y, z)] = 'wood'
        if d >= 4.3:
            cells[(x, y, 7)] = 'wood'
        elif d < 1.0:
            cells[(x, y, 7)] = 'cut_heart'
        else:
            cells[(x, y, 7)] = 'cut_ring' if int(d) % 2 else 'cut_pale'
    for x in range(-6, 6):
        for y in range(-6, 6):
            if (x, y) in disc or not 5.0 < dist(x, y) <= 5.8:
                continue
            touches = any((x + dx, y + dy) in disc for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
            if touches and rng.random() < 0.6:
                cells[(x, y, 0)] = 'wood_dark'

    theta0, half = -0.9, 0.75

    def on_cap(x, y):
        delta = (angle(x, y) - theta0 + math.pi) % (2 * math.pi) - math.pi
        return abs(delta) <= half

    for x, y in disc:
        d = dist(x, y)
        if not on_cap(x, y):
            continue
        if d >= 4.3:
            cells[(x, y, 7)] = 'moss'
        if d >= 4.5:
            cells[(x, y, 6)] = 'moss_dark'
        if d >= 3.4:
            cells[(x, y, 8)] = rng.choice(['moss', 'moss', 'moss_light'])
    return cells


def stream_reeds():
    """A clump of six one-voxel reeds, 0.6 m to 1.0 m tall, on a small mud bed: three carry brown seed heads, and
    teal-green blades sit low on the stalks. No footprint: reeds stand at the water's edge."""
    cells = {}
    for x in range(-4, 4):
        for y in range(-4, 4):
            if math.hypot(x + 0.5, y + 0.5) <= 3.0:
                cells[(x, y, 0)] = 'soil'
    # (x, y, top z, seed head): the top z is the stalk height in voxels; with the mud, 11 to 19 gives 0.6 m to 1.0 m.
    # A seed head is two voxels long along x, one deep, and four tall, so it reads as a cattail spike.
    stalks = [(-2, -1, 17, True), (0, -2, 12, False), (2, -1, 19, True),
              (-1, 1, 14, False), (1, 1, 15, True), (-2, 2, 11, False)]
    for x, y, top, head in stalks:
        for z in range(1, top + 1):
            cells[(x, y, z)] = 'reed_dark' if z <= 4 else 'reed'
        if head:
            for dx in (0, 1):
                for z in range(top - 5, top - 1):
                    cells[(x + dx, y, z)] = 'seed_light' if z == top - 2 else 'seed'

    def blade(x, y, z, dx, dy, moves, material):
        """A leaf that leaves the stalk at (x, y, z): 'o' steps outward along (dx, dy), 'u' up, 'd' down."""
        cur = [x, y, z]
        for step in moves:
            if step == 'o':
                cur[0] += dx
                cur[1] += dy
            elif step == 'u':
                cur[2] += 1
            else:
                cur[2] -= 1
            key = tuple(cur)
            if key in cells:
                raise RuntimeError(f'Blade overlaps at {key}')
            cells[key] = material

    blade(-2, -1, 3, -1, 0, 'oodo', 'blade')
    blade(-2, -1, 5, 0, -1, 'odo', 'blade_dark')
    blade(0, -2, 4, 0, -1, 'oodo', 'blade')
    blade(2, -1, 4, 0, -1, 'odo', 'blade_dark')
    blade(2, -1, 2, 1, 0, 'oodo', 'blade')
    blade(1, 1, 3, 0, 1, 'oodo', 'blade')
    blade(-1, 1, 5, -1, 0, 'ouo', 'blade_dark')
    blade(-2, 2, 3, 0, 1, 'odo', 'blade_dark')
    return cells


def check_attached(name, cells):
    """Every voxel must connect face to face to the rest of the model (no floating parts)."""
    start = next(iter(cells))
    seen = {start}
    frontier = [start]
    while frontier:
        x, y, z = frontier.pop()
        for dx, dy, dz in vx.DIRECTIONS:
            neighbour = (x + dx, y + dy, z + dz)
            if neighbour in cells and neighbour not in seen:
                seen.add(neighbour)
                frontier.append(neighbour)
    if len(seen) != len(cells):
        raise RuntimeError(f'{name}: {len(cells) - len(seen)} voxels are not attached to the model')


MODELS = [
    ('window-planter', window_planter()),
    ('mossy-boulder', mossy_boulder()),
    ('tree-stump', tree_stump()),
    ('stream-reeds', stream_reeds()),
]
for model_id, model_cells in MODELS:
    check_attached(model_id, model_cells)
vx.author_models(__file__, [(model_id, model_cells, (0, 0, 0)) for model_id, model_cells in MODELS], COLOURS, PART)
