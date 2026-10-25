import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import math  # noqa: E402
import voxel_lib as vx  # noqa: E402

# Indoor doodads, v1: a wooden chair, a dining table, a cottage bed, a bookshelf, a storage chest and a hearth stool.
# One-time Blender authoring record. Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/indoor.py
# It refuses to overwrite a saved source (voxel_lib.author_models). Afterwards, edit each model.blend in Blender and
# run scripts/world-art.sh build <id>. These are candidates only: unplaced, off the build shelf, decorative. Interiors
# are not placeable yet. Each cell is a 0.05 m voxel. The origin is the footprint centre on the base (z = 0). The front
# faces Blender -Y (Godot +Z). Shading follows the game camera: tops lightest, the -Y front mid-tone, the +X side darkest.

# Timber, iron, cream plaster, violet and teal come from the shared palette (art/world_palette.gd). iron_light is the one
# new colour here: a lit iron, the same value the farmyard kit uses. It is not in the palette yet.
COLOURS = {
    'oak': 'b07a45', 'oak_light': 'c59458',
    'wood': '765039', 'wood_dark': '49382f',
    'iron': '394446', 'iron_light': '5f6c6e',
    'plaster': 'e8ddbd', 'plaster_shade': 'd3c6a4', 'cream': 'fff0cb',
    'roof': '66509a', 'roof_light': '8271b1',
    'teal': '347b85', 'teal_light': '4c939b',
}
PART = {
    'oak': 'Timber', 'oak_light': 'Timber', 'wood': 'Timber', 'wood_dark': 'Timber',
    'iron': 'Iron', 'iron_light': 'Iron',
    'plaster': 'Linen', 'plaster_shade': 'Linen', 'cream': 'Linen',
    'roof': 'Books', 'roof_light': 'Books', 'teal': 'Books', 'teal_light': 'Books',
}


def box(cells, x0, x1, y0, y1, z0, z1, material):
    """Fill the inclusive box of cells with one material. Later calls overwrite earlier ones."""
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            for z in range(z0, z1 + 1):
                cells[(x, y, z)] = material


def check(model_id, cells):
    """Every voxel must touch the model (one connected group) and the base must sit on z = 0."""
    start = next(iter(cells))
    seen, todo = {start}, [start]
    while todo:
        x, y, z = todo.pop()
        for dx, dy, dz in vx.DIRECTIONS:
            neighbour = (x + dx, y + dy, z + dz)
            if neighbour in cells and neighbour not in seen:
                seen.add(neighbour)
                todo.append(neighbour)
    if len(seen) != len(cells):
        raise RuntimeError(f'{model_id}: {len(cells) - len(seen)} voxels are not attached')
    if min(z for _, _, z in cells) != 0:
        raise RuntimeError(f'{model_id}: the base must sit on z = 0')


def wooden_chair():
    """A 0.45 m square seat on four 0.1 m legs, 0.45 m high. The 0.9 m back is two posts with three slats."""
    cells = {}
    for x0, x1 in ((-4, -3), (3, 4)):
        for y0, y1 in ((-4, -3), (3, 4)):
            box(cells, x0, x1, y0, y1, 0, 6, 'wood')
            box(cells, x0, x1, y0, y1, 0, 0, 'wood_dark')
    box(cells, -4, 4, -4, 4, 7, 7, 'oak')
    box(cells, -4, 4, -4, 4, 8, 8, 'oak_light')
    box(cells, -4, 3, 0, 0, 8, 8, 'wood')  # seam between the two seat planks
    box(cells, -4, -3, 3, 4, 9, 17, 'oak')  # back posts
    box(cells, 3, 4, 3, 4, 9, 17, 'oak')
    for z0 in (10, 13):  # two slats with one-voxel gaps
        box(cells, -4, 4, 3, 4, z0, z0 + 1, 'oak')
    box(cells, -4, 4, 3, 4, 16, 16, 'oak')  # top rail
    box(cells, -4, 4, 3, 4, 17, 17, 'oak_light')
    box(cells, 4, 4, -4, 4, 7, 8, 'wood')  # +X edge in shadow
    box(cells, 4, 4, 3, 4, 9, 17, 'wood')
    return cells


def dining_table():
    """A 0.8 m square top, 0.75 m high, on four 0.1 m legs with a one-voxel apron and three planks."""
    cells = {}
    for x in range(-5, 5):  # apron ring, tucked between the legs
        for y in range(-5, 5):
            if x in (-5, 4) or y in (-5, 4):
                box(cells, x, x, y, y, 11, 12, 'oak')
    for x0, x1 in ((-7, -6), (5, 6)):
        for y0, y1 in ((-7, -6), (5, 6)):
            box(cells, x0, x1, y0, y1, 0, 12, 'wood')
            box(cells, x0, x1, y0, y1, 0, 0, 'wood_dark')
    box(cells, -8, 7, -8, 7, 13, 13, 'wood_dark')  # underside of the top
    for x in range(-8, 8):
        for y in range(-8, 8):
            if x in (-8, 7) or y in (-8, 7):
                colour = 'oak'  # lip
            elif y in (-4, 3):
                colour = 'wood'  # seams between the planks
            else:
                colour = 'oak_light'
            cells[(x, y, 14)] = colour
    box(cells, 7, 7, -8, 7, 13, 13, 'wood')  # +X edge in shadow
    return cells


def cottage_bed():
    """1.1 m long, 0.7 m wide, 0.5 m high at the headboard: an oak frame on four legs, a cream blanket and a pillow."""
    cells = {}
    for x0, x1 in ((-11, -10), (9, 10)):
        for y0, y1 in ((-7, -6), (5, 6)):
            box(cells, x0, x1, y0, y1, 0, 2, 'wood')
            box(cells, x0, x1, y0, y1, 0, 0, 'wood_dark')
    for x in range(-11, 11):  # frame rails, two voxels all round, lit on top
        for y in range(-7, 7):
            if x in (-11, -10, 9, 10) or y in (-7, -6, 5, 6):
                cells[(x, y, 3)] = 'wood'
                cells[(x, y, 4)] = 'oak_light'
    box(cells, -9, 8, -5, 4, 3, 3, 'wood_dark')  # deck boards inside the frame
    box(cells, -9, 8, -5, 4, 4, 4, 'plaster_shade')  # blanket, tucked in
    box(cells, -9, 8, -5, 4, 5, 5, 'plaster')
    box(cells, -9, 8, -5, -5, 5, 5, 'plaster_shade')  # turned-down front edge
    box(cells, -9, -7, -3, 2, 6, 6, 'plaster_shade')  # folded pillow at the head
    box(cells, -9, -7, -3, 2, 7, 7, 'cream')
    box(cells, -9, -7, 0, 0, 7, 7, 'plaster')  # fold line
    box(cells, -11, -10, -7, 6, 5, 9, 'oak')  # headboard, 0.5 m high
    box(cells, -11, -11, -7, 6, 5, 9, 'wood')  # outer face in shadow
    box(cells, -11, -10, -7, 6, 9, 9, 'oak_light')
    box(cells, 9, 10, -7, 6, 5, 6, 'oak')  # low footboard
    box(cells, 9, 10, -7, 6, 6, 6, 'oak_light')
    return cells


BOOKS = {'violet': ('roof', 'roof_light'), 'teal': ('teal', 'teal_light'), 'cream': ('plaster', 'cream')}


def books(cells, z0, spec):
    """Upright books on the shelf at z0 - 1, spines to -Y, left to right from x = -4. Each entry is (width, family,
    height); a family of None leaves a gap. The top row of each book is lighter, like a spine's head band."""
    x = -4
    for width, family, height in spec:
        if family:
            base, light = BOOKS[family]
            for dx in range(width):
                for y in range(-3, 2):
                    for z in range(z0, z0 + height):
                        cells[(x + dx, y, z)] = light if z == z0 + height - 1 else base
        x += width
    if x != 4:
        raise ValueError(f'shelf row at z {z0} is {x + 4} cells wide, not 8')


def bookshelf():
    """0.5 m wide, 0.3 m deep, 1.0 m tall: two sides, four open compartments and a top, with violet, teal and cream books."""
    cells = {}
    box(cells, -5, -5, -3, 2, 0, 19, 'oak')  # left side
    box(cells, 4, 4, -3, 2, 0, 19, 'wood')  # right side in shadow
    box(cells, -4, 3, 2, 2, 1, 18, 'wood_dark')  # back panel
    box(cells, -4, 3, -2, 2, 0, 0, 'wood_dark')  # recessed plinth
    box(cells, -4, 3, -3, 2, 1, 1, 'oak')  # base board
    for z in (5, 10, 15):
        box(cells, -4, 3, -3, 2, z, z, 'oak')  # shelves
    box(cells, -5, 4, -3, 2, 19, 19, 'oak_light')  # top
    books(cells, 2, [(1, 'violet', 3), (1, 'teal', 3), (1, 'cream', 2), (1, 'violet', 3),
                     (2, 'teal', 3), (1, 'cream', 3), (1, 'violet', 3)])
    books(cells, 6, [(2, 'cream', 4), (1, 'teal', 4), (1, 'violet', 3), (1, 'teal', 4),
                     (1, 'violet', 4), (2, 'cream', 3)])
    books(cells, 11, [(1, 'violet', 4), (1, None, 0), (1, 'cream', 4), (1, 'teal', 3),
                      (2, 'violet', 4), (1, 'teal', 4), (1, None, 0)])
    books(cells, 16, [(1, 'teal', 3), (2, 'violet', 3), (1, 'cream', 2), (1, 'teal', 3),
                      (1, 'violet', 3), (2, 'cream', 3)])
    return cells


def storage_chest():
    """0.6 m long, 0.4 m deep, 0.4 m high: a timber body with iron corner straps, a dark lid band and an iron latch."""
    cells = {}
    box(cells, -6, 5, -4, 3, 0, 5, 'oak')  # body
    box(cells, -6, 5, -4, 3, 0, 0, 'wood_dark')  # dark base band
    box(cells, 5, 5, -4, 3, 1, 5, 'wood')  # +X end in shadow
    for cx, dx in ((-6, 1), (5, -1)):  # iron corner straps: an L of three voxels at each corner
        for cy, dy in ((-4, 1), (3, -1)):
            for z in range(1, 6):
                cells[(cx, cy, z)] = 'iron'
                cells[(cx + dx, cy, z)] = 'iron'
                cells[(cx, cy + dy, z)] = 'iron'
    box(cells, -6, 5, -4, 3, 6, 6, 'wood_dark')  # dark lid band
    box(cells, -5, 4, -3, 2, 7, 7, 'oak_light')  # lid top, inset
    box(cells, -5, 4, -1, 0, 7, 7, 'wood_dark')  # dark band across the lid
    box(cells, -1, 0, -4, -4, 4, 5, 'iron')  # latch plate on the front, flush with the body
    box(cells, -1, 0, -4, -4, 5, 5, 'iron_light')
    return cells


def hearth_stool():
    """0.35 m across, 0.45 m high: three 0.1 m legs spread on a triangle under a timber seat and a pale round cushion."""
    cells = {}
    for x0, x1, y0, y1 in ((-3, -2, -1, 0), (2, 3, -1, 0), (-1, 0, 2, 3)):  # the legs are spread apart so they read
        box(cells, x0, x1, y0, y1, 0, 4, 'wood')
        box(cells, x0, x1, y0, y1, 0, 0, 'wood_dark')
    for x in range(-3, 4):
        for y in range(-3, 4):
            d = math.hypot(x, y)
            if d > 3.5 + 1e-9:
                continue
            cells[(x, y, 5)] = 'wood_dark'  # underside of the seat, in shadow
            cells[(x, y, 6)] = 'wood' if x == 3 else ('oak_light' if d > 2.9 else 'oak')
            if d <= 2.9 + 1e-9:
                cells[(x, y, 7)] = 'plaster_shade'  # cushion, lower layer
                cells[(x, y, 8)] = 'cream' if d <= 2.0 + 1e-9 else 'plaster'
    return cells


def centre_of(cells):
    """The origin sits at the middle of the footprint and on the base (z = 0)."""
    assert min(z for _, _, z in cells) == 0, 'the base must sit on z = 0'
    xs = [x for x, _, _ in cells]
    ys = [y for _, y, _ in cells]
    return ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, 0)


MODELS = {
    'wooden-chair': wooden_chair(),
    'dining-table': dining_table(),
    'cottage-bed': cottage_bed(),
    'bookshelf': bookshelf(),
    'storage-chest': storage_chest(),
    'hearth-stool': hearth_stool(),
}
for model_id, model_cells in MODELS.items():
    check(model_id, model_cells)
    ox, oy, _ = centre_of(model_cells)
    xs = [x for x, _, _ in model_cells]
    ys = [y for _, y, _ in model_cells]
    zs = [z for _, _, z in model_cells]
    left, right = (min(xs) - ox) * vx.VOXEL, (max(xs) + 1 - ox) * vx.VOXEL
    back, front = (min(ys) - oy) * vx.VOXEL, (max(ys) + 1 - oy) * vx.VOXEL
    print(f'{model_id}: {right - left:.2f} x {front - back:.2f} x {(max(zs) + 1) * vx.VOXEL:.2f} m, '
          f'footprint [{left:.3f}, {back:.3f}, {right - left:.3f}, {front - back:.3f}]')
wanted = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
vx.author_models(__file__, [(model_id, cells, centre_of(cells)) for model_id, cells in MODELS.items() if not wanted or model_id in wanted], COLOURS, PART)
