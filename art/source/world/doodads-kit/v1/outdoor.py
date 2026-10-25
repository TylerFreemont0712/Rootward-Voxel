import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import voxel_lib as vx

import math
import random

# One-time Blender authoring record for six outdoor doodads: stepping stones, an upturned rowboat, a fallen log, a
# mushroom cluster, a market stall and a hanging inn sign. Candidates only: unplaced, off the build shelf, decorative.
# Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/outdoor.py
# It refuses to run over a saved source. After this handoff, edit each model.blend in Blender and run
# scripts/world-art.sh build <id>; this file records how v1 was made and is not the master.
#
# Each cell is a 0.05 m voxel and z = 0 is the ground. Fronts face Blender -Y (Godot +Z). Shading follows the game
# camera: tops lightest, the front mid-tone, the +X side darkest.

# Stone, moss, timber, violet, cream, iron and leaf colours are the palette hex from art/world_palette.gd. New here:
# cut (the pale cut wood from the farmyard kit), twine, iron_light (also from farmyard) and apple and apple_light.
COLOURS = {
    'stone': '929a9a', 'stone_light': 'bcc2ae', 'stone_dark': '626f73', 'pebbles': 'b2a58b',
    'grass': '638b41', 'grass_light': '83a852', 'grass_dark': '4e763b',
    'oak': 'b07a45', 'oak_light': 'c59458',
    'wood': '765039', 'wood_light': 'a47b51', 'wood_dark': '49382f',
    'cut': 'e2c48f', 'twine': '6d5837',
    'iron': '394446', 'iron_light': '5f6c6e',
    'cream': 'fff0cb', 'plaster': 'e8ddbd', 'plaster_shade': 'd3c6a4',
    'roof': '66509a', 'roof_light': '8271b1', 'roof_dark': '493c71',
    'leaf_dark': '2e5835',
    'apple': 'b5503d', 'apple_light': 'd7795a',
}
PART = {
    'stone': 'Stones', 'stone_light': 'Stones', 'stone_dark': 'Stones', 'pebbles': 'Stones',
    'grass': 'Moss', 'grass_light': 'Moss', 'grass_dark': 'Moss',
    'oak': 'Timber', 'oak_light': 'Timber', 'wood': 'Timber', 'wood_light': 'Timber', 'wood_dark': 'Timber',
    'cut': 'Timber', 'twine': 'Twine',
    'iron': 'Iron', 'iron_light': 'Iron',
    'cream': 'Cream', 'plaster': 'Cream', 'plaster_shade': 'Cream',
    'roof': 'Violet', 'roof_light': 'Violet', 'roof_dark': 'Violet',
    'leaf_dark': 'Fruit',
    'apple': 'Fruit', 'apple_light': 'Fruit',
}


def stepping_stones():
    """Three flat grey stones in a line, each 0.4 m across and 0.1 m thick, set in a strip of gravel so the model is one
    piece. Moss sits on the back (+Y) rim of each stone. The stones are centred at x = -12, 0 and 12 voxels."""
    cells = {}
    rng = random.Random(230501)
    for centre, radius in ((-12, 4.2), (0, 4.3), (12, 4.1)):
        phase = rng.uniform(0, 2 * math.pi)
        for x in range(centre - 4, centre + 4):
            for y in range(-4, 4):
                xc, yc = x + 0.5 - centre, y + 0.5
                wobble = 0.15 * math.sin(3 * math.atan2(yc, xc) + phase)
                d = math.hypot(xc, yc) + wobble
                if d > radius:
                    continue
                cells[(x, y, 0)] = 'stone_dark'
                if d > radius - 1.2:
                    cells[(x, y, 1)] = 'stone_dark' if xc > 1.5 else 'stone'
                else:
                    cells[(x, y, 1)] = 'stone_light' if yc < -0.8 else 'stone'
                if yc > 0.5 and d > radius - 1.8 and rng.random() < 0.7:
                    cells[(x, y, 2)] = rng.choice(['grass', 'grass_dark', 'grass_light'])
    # Gravel fills the gaps between the stones at ground level, so every stone touches the bed.
    for x in list(range(-8, -4)) + list(range(4, 8)):
        for y in range(-2, 2):
            cells.setdefault((x, y, 0), 'pebbles')
    return cells


def mushroom(cells, cx, cy, cap_r, cap_low, seed):
    """One mushroom: a stem from z = 2 up to the cap, a cream cap with a flared underside and violet spots on top.
    Whole-number centres give a 2 by 2 stem; half-number centres give a single-voxel stem."""
    cap_top = cap_low + 1
    if float(cx).is_integer() and float(cy).is_integer():
        ix, iy = int(cx), int(cy)
        stem = [(ix - 1, iy - 1), (ix, iy - 1), (ix - 1, iy), (ix, iy)]
    else:
        stem = [(math.floor(cx), math.floor(cy))]
    for x, y in stem:
        for z in range(2, cap_low):
            cells[(x, y, z)] = 'plaster_shade' if x + 0.5 > cx else 'plaster'
    for x in range(math.floor(cx - cap_r) - 1, math.ceil(cx + cap_r) + 1):
        for y in range(math.floor(cy - cap_r) - 1, math.ceil(cy + cap_r) + 1):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= cap_r:
                cells[(x, y, cap_low)] = 'plaster_shade'
            if d <= cap_r - 0.4:
                spot = (x * 3 + y * 5 + seed) % 5 == 0
                cells[(x, y, cap_top)] = ('roof' if (x + y) % 2 else 'roof_light') if spot else 'cream'


def mushroom_cluster():
    """Six mushrooms on a short stump: three tall ones and three small ones, 0.3 m tall in all. The stump is 0.5 m
    across with bark sides and a pale cut top with growth rings. Stems and caps are cream, with violet spots."""
    cells = {}
    for x in range(-6, 6):
        for y in range(-6, 6):
            xc, yc = x + 0.5, y + 0.5
            d = math.hypot(xc, yc)
            if d <= 4.8:
                cells[(x, y, 0)] = 'wood_dark' if (yc > 1.0 or xc > 1.5) else 'wood'
            if d <= 4.4:
                if d > 3.4:
                    colour = 'wood'
                elif d > 2.5:
                    colour = 'cut'
                elif d > 1.9:
                    colour = 'oak'
                elif d > 0.9:
                    colour = 'cut'
                else:
                    colour = 'oak'
                cells[(x, y, 1)] = colour
    # Small mushrooms first so the taller caps sit over them where they meet. Whole-number centres have 2 by 2 stems.
    for seed, (cx, cy) in enumerate([(-0.5, -3.5), (3.5, 1.5), (-3.5, 2.5)]):
        mushroom(cells, cx, cy, 1.3, 3, seed)
    for seed, (cx, cy) in enumerate([(-2, 0), (2, -2), (1, 3)]):
        mushroom(cells, cx, cy, 1.9, 4, seed + 3)
    return cells


def fallen_log():
    """A fallen trunk 1.2 m long and 0.4 m across, lying on the ground along X. Bark in three tones with longitudinal
    ridges, a pale cut end with growth rings at +X, a bark end at -X, and moss patches along the top."""
    cells = {}
    radius = 4.0
    for x in range(-12, 12):
        for y in range(-4, 4):
            for z in range(0, 8):
                yc, zc = y + 0.5, z + 0.5 - 4.0
                d = math.hypot(yc, zc)
                if d > radius:
                    continue
                if x == 11:
                    if d <= 0.9:
                        colour = 'oak'
                    elif d <= 1.9:
                        colour = 'cut'
                    elif d <= 2.5:
                        colour = 'oak'
                    elif d <= 3.3:
                        colour = 'cut'
                    else:
                        colour = 'wood'
                else:
                    light = (-0.6 * yc + 0.8 * zc) / d
                    colour = 'oak_light' if light > 0.45 else ('oak' if light > -0.25 else 'wood')
                    if light < -0.6:
                        colour = 'wood_dark'
                    bin_index = int((math.atan2(zc, yc) + math.pi) / (2 * math.pi) * 10)
                    if bin_index % 3 == 0:
                        colour = {'oak_light': 'oak', 'oak': 'wood', 'wood': 'wood_dark'}.get(colour, colour)
                cells[(x, y, z)] = colour
    for x in range(-9, 9):
        for y in range(-2, 2):
            field = math.sin(0.7 * x + 0.5 * y) + math.cos(1.3 * y - 0.4 * x)
            if field > 0.3:
                cells[(x, y, 8)] = 'grass_dark' if field < 1.0 else ('grass' if field < 1.6 else 'grass_light')
    return cells


def rowboat():
    """An upturned rowboat 1.6 m long, 0.6 m wide and 0.4 m tall: the gunwales rest on the ground and the keel is up.
    Plank strakes alternate in two tones, a dark keel runs along the top and a dark rub strake sits on the ground. An
    oar lies along each flank, touching the hull, with a flat blade at opposite ends."""
    cells = {}
    half_len, half_wid, height = 16.0, 6.0, 8.0

    def half_width(u):
        return half_wid * max(0.0, 1 - u * u) ** 0.6

    def top_height(xc, yc):
        u = xc / half_len
        width = half_width(u)
        if width <= 0:
            return None
        v = abs(yc) / width
        if v >= 1:
            return None
        return height * (1 - u * u) ** 0.35 * (1 - v ** 2.4) ** 0.5

    hull = set()
    for x in range(-16, 16):
        for y in range(-7, 7):
            zt = top_height(x + 0.5, y + 0.5)
            if zt is None:
                continue
            for z in range(0, 9):
                if z + 0.5 > zt:
                    break
                hull.add((x, y, z))
    for (x, y, z) in hull:
        yc = y + 0.5
        shadow = yc > 1.5
        top = (x, y, z + 1) not in hull
        if z == 0:
            colour = 'wood_dark'
        elif top:
            colour = 'wood_dark' if abs(yc) < 1.5 else 'oak_light'
        elif shadow:
            colour = 'wood' if (z // 2) % 2 == 0 else 'wood_dark'
        else:
            colour = 'oak' if (z // 2) % 2 == 0 else 'wood_light'
        cells[(x, y, z)] = colour

    # Oar on the -Y flank: loom in rows -8 and -7, touching the hull at row -6, with a blade centred on row -7 at -X.
    for x in range(-14, 9):
        for y in (-8, -7):
            for z in (0, 1):
                cells[(x, y, z)] = 'oak'
    for x in range(-22, -14):
        for y in range(-10, -4):
            xc, yc = x + 0.5 + 18, y + 0.5 + 7
            if (xc / 3.6) ** 2 + (yc / 2.2) ** 2 <= 1:
                cells[(x, y, 1)] = 'oak_light'
                cells[(x, y, 0)] = 'oak'
    # Oar on the +Y flank: loom in rows 6 and 7, touching the hull at row 5, with a blade centred on row 7 at +X.
    for x in range(-4, 13):
        for y in (6, 7):
            for z in (0, 1):
                cells[(x, y, z)] = 'oak'
    for x in range(13, 22):
        for y in range(4, 11):
            xc, yc = x + 0.5 - 17, y + 0.5 - 7
            if (xc / 3.6) ** 2 + (yc / 2.2) ** 2 <= 1:
                cells[(x, y, 1)] = 'oak_light'
                cells[(x, y, 0)] = 'oak'
    return cells


APPLE = [(dx, dy, dz) for dx in (-1, 0, 1) for dy in (-1, 0, 1) for dz in (-1, 0, 1) if dx * dx + dy * dy + dz * dz <= 2]


def apple(cells, ax, ay, az, stem=False):
    """A round apple of 19 voxels, three across, centred on the cell (ax, ay, az). Lit from the top-left."""
    for dx, dy, dz in APPLE:
        cells[(ax + dx, ay + dy, az + dz)] = 'apple_light' if (dz == 1 and dx <= 0) else 'apple'
    if stem:
        cells[(ax, ay, az + 2)] = 'leaf_dark'


def basket(cells, cx, cy):
    """A woven basket about 0.3 m across and 0.2 m tall on the counter, with a twine rim. Its interior is the top layer."""
    for x in range(cx - 3, cx + 3):
        for y in range(cy - 3, cy + 3):
            d = math.hypot(x + 0.5 - cx, y + 0.5 - cy)
            if d <= 2.5:
                cells[(x, y, 11)] = 'oak'
            if d <= 3.0:
                cells[(x, y, 12)] = 'oak_light' if (x + y) % 2 == 0 else 'wood_light'
                cells[(x, y, 13)] = 'wood_light' if (x + y) % 2 == 0 else 'oak'
                cells[(x, y, 14)] = 'twine' if d > 2.0 else 'oak'


def market_stall():
    """A timber market stall 1.6 m wide, 1.0 m deep and 1.4 m tall. A plank counter stands at the front with a back board
    and two corner posts behind it. A violet and cream striped canopy slopes down to a scalloped valance at the front.
    Two baskets and a few apples sit on the counter."""
    cells = {}

    def canopy_top(y):
        return round(23 + (y + 10) / 19 * 4)

    for x in range(-16, 16):
        violet = ((x + 16) // 4) % 2 == 0
        for y in range(-10, 10):
            top = canopy_top(y)
            cells[(x, y, top)] = 'roof_light' if violet else 'cream'
            cells[(x, y, top - 1)] = 'roof' if violet else 'plaster_shade'
        cells[(x, -10, 21)] = 'roof_dark' if violet else 'plaster'
        if (x + 16) % 4 in (1, 2):
            cells[(x, -10, 20)] = 'roof_dark' if violet else 'plaster'

    for x0 in (-15, 13):
        for x in (x0, x0 + 1):
            for y in (7, 8):
                for z in range(0, 26):
                    if y == 7:
                        colour = 'wood_light'
                    elif x == 14:
                        colour = 'wood_dark'
                    else:
                        colour = 'wood'
                    cells[(x, y, z)] = colour

    for x in range(-13, 13):
        for z in range(0, 16):
            cells[(x, 8, z)] = 'oak' if ((x + 13) // 2) % 2 == 0 else 'wood'

    for x in range(-14, 14):
        for y in range(-9, 1):
            for z in range(0, 11):
                if z == 10:
                    colour = 'wood_light' if ((y + 9) // 2) % 2 == 0 else 'oak_light'
                elif y == -9:
                    colour = 'wood_dark' if z == 0 else ('oak' if ((x + 14) // 2) % 2 == 0 else 'wood')
                elif x == 13:
                    colour = 'wood_dark'
                else:
                    colour = 'wood'
                cells[(x, y, z)] = colour
    # A plank floor runs from the counter back to the back board, so the counter, posts and canopy form one model.
    for x in range(-13, 13):
        for y in range(1, 8):
            cells.setdefault((x, y, 0), 'wood_dark')

    basket(cells, -8, -4)
    apple(cells, -10, -4, 16)
    apple(cells, -7, -4, 16, stem=True)
    basket(cells, 5, -5)
    apple(cells, 5, -5, 16, stem=True)
    apple(cells, -2, -6, 12)
    apple(cells, -1, -2, 12, stem=True)
    return cells


def hanging_sign():
    """An inn sign: a 3 by 3 voxel timber post 1.4 m tall, an iron arm reaching out to the front with a diagonal brace,
    and a small wooden board hung from an iron bar. The board has a violet rim and a cream face."""
    cells = {}
    for x in range(-1, 2):
        for y in range(0, 3):
            for z in range(0, 28):
                if y == 0:
                    colour = 'wood_light'
                elif x == 1:
                    colour = 'wood_dark'
                else:
                    colour = 'wood'
                cells[(x, y, z)] = colour

    for x in (0, 1):
        for y in range(-9, 0):
            cells[(x, y, 22)] = 'iron'
            cells[(x, y, 23)] = 'iron_light'
    brace = [(-1, 17), (-2, 17), (-2, 18), (-3, 18), (-3, 19), (-4, 19), (-4, 20), (-5, 20), (-5, 21)]
    for x in (0, 1):
        for y, z in brace:
            cells[(x, y, z)] = 'iron'

    for x in range(-3, 5):
        cells[(x, -9, 20)] = 'iron_light'
    for x in (0, 1):
        cells[(x, -9, 21)] = 'iron'

    for x in range(-4, 6):
        for z in range(11, 20):
            cells[(x, -8, z)] = 'wood'
            if x in (-4, 5) or z in (11, 19):
                cells[(x, -9, z)] = 'roof'
            elif z == 12:
                cells[(x, -9, z)] = 'plaster_shade'
            else:
                cells[(x, -9, z)] = 'cream'
    return cells


def centre_of(cells):
    """The origin sits at the middle of the footprint and on the base (z = 0)."""
    assert min(z for _, _, z in cells) == 0, 'the base must sit on z = 0'
    xs = [x for x, _, _ in cells]
    ys = [y for _, y, _ in cells]
    return ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, 0)


def check_attached(name, cells):
    """Every voxel must connect face to face to the rest of its model (no floating parts)."""
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


def report(model_id, cells, centre):
    """Print the bounds relative to the pivot in metres, for the brief and the proposed footprint."""
    lo = [min(c[i] for c in cells) for i in range(3)]
    hi = [max(c[i] + 1 for c in cells) for i in range(3)]
    rel_lo = [round((lo[i] - centre[i]) * vx.VOXEL, 3) for i in range(2)]
    rel_hi = [round((hi[i] - centre[i]) * vx.VOXEL, 3) for i in range(2)]
    size = [round((hi[i] - lo[i]) * vx.VOXEL, 3) for i in range(3)]
    print(f'{model_id}: {len(cells)} voxels, size m {size}, x/y min {rel_lo}, x/y max {rel_hi}')


MODELS = {
    'stepping-stones': stepping_stones(),
    'rowboat-upturned': rowboat(),
    'fallen-log': fallen_log(),
    'mushroom-cluster': mushroom_cluster(),
    'market-stall': market_stall(),
    'hanging-sign': hanging_sign(),
}
# The sign's origin is the foot of its post rather than the middle of its bounds: the board and arm hang well out
# in front, so a bounds centre would put the pivot off the post. The post occupies x -1..1 and y 0..2 voxels.
PIVOT = {'hanging-sign': (0.5, 1.5, 0)}
for model_id, model_cells in MODELS.items():
    check_attached(model_id, model_cells)
wanted = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
selected = [(model_id, cells, PIVOT.get(model_id, centre_of(cells))) for model_id, cells in MODELS.items()
            if not wanted or model_id in wanted]
for model_id, cells, centre in selected:
    report(model_id, cells, centre)
vx.author_models(__file__, selected, COLOURS, PART)
