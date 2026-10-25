import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import math  # noqa: E402
import voxel_lib as vx  # noqa: E402

# Street doodads, v1: a park bench, a signpost, a stone well and a cart wheel.
# One-time Blender authoring record. Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/street.py
# It refuses to overwrite a saved source (voxel_lib.author_models). Afterwards, edit each model.blend in Blender and
# run scripts/world-art.sh build <id>. These are candidates only: unplaced, off the build shelf, decorative.
# Each cell is a 0.05 m voxel and the pivot is the ground origin. Fronts face Blender -Y (Godot +Z).

# Palette hex keeps the values from art/world_palette.gd. New here: iron_light and iron_dark (the iron shades),
# stone_warm_dark (limestone in shadow) and well_water (the dark surface inside the well).
COLOURS = {
    'oak': 'b07a45', 'oak_light': 'c59458',
    'wood': '765039', 'wood_light': 'a47b51',
    'iron': '394446', 'iron_light': '5a6667', 'iron_dark': '262d2f',
    'stone_warm': 'c8bb99', 'stone_warm_dark': 'a69e80', 'plaster': 'e8ddbd',
    'cream': 'fff0cb', 'plaster_shade': 'd3c6a4',
    'roof': '66509a', 'roof_light': '8271b1', 'roof_dark': '493c71',
    'leather_light': 'a87b48', 'well_water': '23505a',
}
# Parts group by material family: materials are shared across the four models, and PART holds one name per material.
PART = {
    'oak': 'Timber', 'oak_light': 'Timber', 'wood': 'Timber', 'wood_light': 'Timber',
    'iron': 'Iron', 'iron_light': 'Iron', 'iron_dark': 'Iron',
    'stone_warm': 'Stone', 'stone_warm_dark': 'Stone', 'plaster': 'Stone',
    'cream': 'Cream', 'plaster_shade': 'Cream',
    'roof': 'Violet', 'roof_light': 'Violet', 'roof_dark': 'Violet',
    'leather_light': 'Rope', 'well_water': 'Water',
}


def box(cells, x0, x1, y0, y1, z0, z1, material):
    """Fill the inclusive box of cells with one material. Later calls overwrite earlier ones."""
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            for z in range(z0, z1 + 1):
                cells[(x, y, z)] = material


def park_bench():
    """0.9 m long, 0.4 m deep, seat at 0.45 m, backrest to 0.9 m. Oak slats on dark iron end frames."""
    cells = {}
    for y0 in (-4, -1, 2):  # three pairs of seat slats with a gap between each pair
        box(cells, -9, 8, y0, y0 + 1, 7, 7, 'oak')
        box(cells, -9, 8, y0, y0 + 1, 8, 8, 'oak_light')
    for z0 in (10, 13, 16):  # three slats in the backrest, on the back edge of the seat
        box(cells, -9, 8, 2, 3, z0, z0, 'oak')
        box(cells, -9, 8, 2, 3, z0 + 1, z0 + 1, 'oak_light')
    box(cells, -1, 0, -4, 3, 5, 5, 'iron_dark')  # centre bearer under the seat
    box(cells, -1, 0, -4, 3, 6, 6, 'iron')
    for x0 in (-9, 7):  # the two end frames, each two cells thick
        x1 = x0 + 1
        box(cells, x0, x1, -4, 3, 5, 5, 'iron_dark')  # rail under the seat
        box(cells, x0, x1, -4, 3, 6, 6, 'iron')
        box(cells, x0, x1, -4, -3, 0, 12, 'iron')  # front post, rising to the armrest
        box(cells, x0, x1, -4, -3, 12, 12, 'iron_light')
        box(cells, x0, x1, -2, 1, 11, 11, 'iron')  # armrest
        box(cells, x0, x1, -2, 1, 12, 12, 'iron_light')
        box(cells, x0, x1, 2, 3, 0, 17, 'iron')  # back leg, rising through the backrest
        box(cells, x0, x1, 2, 3, 17, 17, 'iron_light')
        box(cells, x0, x1, -5, -5, 0, 0, 'iron_dark')  # feet
        box(cells, x0, x1, 4, 4, 0, 0, 'iron_dark')
    return cells


def arrow_spans(low, direction):
    """Rows for a five-row board from x -6 to 6, with a point at x 7 to 10 that flares one row at its base.
    direction +1 points to +X; -1 points to -X."""
    spans = {x: (low + 1, low + 5) for x in range(-6, 7)}
    for step, (bottom, top) in enumerate(((0, 6), (1, 5), (2, 4), (3, 3))):
        spans[direction * (7 + step)] = (low + bottom, low + top)
    return spans


def arrow_board(cells, spans, y, face, edge):
    """A flat board in the XZ plane, one cell thick. spans maps each x column to its (low, high) z rows.
    Cells on the outline take the edge colour, so the board reads as a framed board."""
    board = {(x, z) for x, (low, high) in spans.items() for z in range(low, high + 1)}
    for x, z in board:
        outline = any((x + dx, z + dz) not in board for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        cells[(x, y, z)] = edge if outline else face


def signpost():
    """A 1.3 m timber post on an iron shoe, with a cream board pointing right above a violet board pointing left."""
    cells = {}
    box(cells, -2, 1, -2, 1, 0, 0, 'iron_dark')  # shoe on the ground
    box(cells, -2, 1, -2, 1, 1, 1, 'iron')
    box(cells, -1, 0, -1, 0, 2, 24, 'wood')  # post, two cells square
    box(cells, -1, 0, -1, 0, 25, 25, 'wood_light')  # lit cap
    box(cells, -1, 0, -3, -3, 19, 23, 'iron_light')  # iron strap, post-wide, that binds the cream board to the post
    box(cells, -1, 0, -3, -3, 12, 16, 'iron_light')  # iron strap for the violet board
    arrow_board(cells, arrow_spans(18, 1), -2, 'cream', 'plaster_shade')
    arrow_board(cells, arrow_spans(11, -1), -2, 'roof', 'roof_dark')
    return cells


def limestone(z, angle):
    """Wall colour for a cell in row z at a given angle round the well. Courses of three rows, blocks ten to a ring."""
    if z == 0:
        return 'stone_warm_dark'
    if z == 11:
        return 'plaster'
    course = (z - 1) // 3
    block = (int(angle / (2 * math.pi) * 10) + course * 5) % 10
    return 'stone_warm_dark' if (block * 5 + course * 3) % 7 == 0 else 'stone_warm'


def stone_well():
    """A limestone ring 0.9 m across and 0.6 m tall, dark water inside, a timber frame and a violet hood. Under 1.5 m."""
    cells = {}
    for x in range(-9, 9):
        for y in range(-9, 9):
            d = math.hypot(x + 0.5, y + 0.5)
            if 6.5 <= d <= 9.0:
                angle = math.atan2(y + 0.5, x + 0.5) + math.pi
                for z in range(0, 12):
                    cells[(x, y, z)] = limestone(z, angle)
            elif d < 6.5:
                cells[(x, y, 7)] = 'well_water'
    box(cells, -8, -7, -1, 0, 12, 21, 'wood')  # two uprights standing on the ring
    box(cells, 6, 7, -1, 0, 12, 21, 'wood')
    box(cells, -8, 7, -1, 0, 22, 23, 'wood')  # crossbeam
    box(cells, -1, -1, -1, -1, 12, 21, 'leather_light')  # rope from the beam into the bucket
    box(cells, -1, 0, -1, 0, 8, 8, 'wood')  # bucket: narrow base, then a four-by-four octagon
    for x in range(-2, 2):
        for y in range(-2, 2):
            if (x, y) in ((-2, -2), (1, -2), (-2, 1), (1, 1)):
                continue
            centre = x in (-1, 0) and y in (-1, 0)
            cells[(x, y, 9)] = 'iron'
            cells[(x, y, 10)] = 'wood_light'
            cells[(x, y, 11)] = 'well_water' if centre else 'iron'
    for half, material in ((9, 'roof_dark'), (8, 'roof'), (7, 'roof_light'), (6, 'roof'), (5, 'roof_light')):
        z = 24 + (9 - half)  # each row steps in one cell as it climbs: a hipped, shingled hood
        box(cells, -half, half - 1, -half, half - 1, z, z, material)
    return cells


def cart_wheel():
    """A wagon wheel 1.0 m across, standing on its rim in the XZ plane, 0.1 m thick, with six spokes and a hub."""
    cells = {}
    cx, cz = 0.0, 10.0  # the centre sits 0.5 m up, so the rim touches the ground at z = 0
    for x in range(-10, 10):
        for z in range(0, 20):
            d = math.hypot(x + 0.5 - cx, z + 0.5 - cz)
            if 8.0 <= d <= 10.0:  # iron rim, two cells thick, lighter on the outside
                for y in (-1, 0):
                    cells[(x, y, z)] = 'iron_light' if d >= 9.0 else 'iron'
    for k in range(6):  # six timber spokes from the hub to the rim
        angle = math.radians(30 + 60 * k)
        ux, uz = math.cos(angle), math.sin(angle)
        for x in range(-10, 10):
            for z in range(0, 20):
                rx, rz = x + 0.5 - cx, z + 0.5 - cz
                along = rx * ux + rz * uz
                across = -rx * uz + rz * ux
                if 2.0 <= along <= 8.5 and abs(across) <= 0.8:
                    for y in (-1, 0):
                        cells[(x, y, z)] = 'oak'
    for x in range(-3, 3):  # timber hub, standing out a cell each side of the wheel
        for z in range(7, 13):
            d = math.hypot(x + 0.5 - cx, z + 0.5 - cz)
            if d <= 2.6:
                for y in range(-2, 2):
                    cells[(x, y, z)] = 'wood'
                if d <= 1.5:
                    cells[(x, -2, z)] = 'iron_dark'  # iron cap on the front of the hub
    return cells


vx.author_models(__file__, [
    ('park-bench', park_bench(), (0, 0, 0)),
    ('signpost', signpost(), (0, 0, 0)),
    ('stone-well', stone_well(), (0, 0, 0)),
    ('cart-wheel', cart_wheel(), (0, 0, 0)),
], COLOURS, PART)
