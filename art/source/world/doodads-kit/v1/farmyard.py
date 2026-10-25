import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import voxel_lib as vx

import math

# One-time Blender authoring record for four farmyard doodads: a wooden barrel, a crate stack, a grain-sack pile and
# a woodpile. Run once from the project root:
#   blender --background --factory-startup --python-exit-code 1 --python art/source/world/doodads-kit/v1/farmyard.py
# It refuses to run over a saved source. After this handoff, edit each model.blend in Blender and run
# scripts/world-art.sh build <id>; this file records how v1 was made and is not the master.
# The grain sacks and woodpile were redrawn once after review. To author only some models, pass their ids after --,
# for example: ... --python farmyard.py -- grain-sacks woodpile (their saved sources must be removed first).
#
# Each model is a set of integer voxel cells at 0.05 m, with z = 0 as the base. author_models() centres each model on
# the middle of its footprint (the bounding-box centre), so an odd or even voxel count still puts the origin there.
# Shading follows the game camera: tops lightest, the front mid-tone, the +X side darkest.

# Timber and iron are from the shared palette (art/world_palette.gd). Burlap, twine, pale cut wood and iron_light are
# new to this kit and are not in the palette yet.
COLOURS = {
    'oak': 'b07a45', 'oak_light': 'c59458',
    'wood': '765039', 'wood_light': 'a47b51', 'wood_dark': '49382f',
    'iron': '394446', 'iron_light': '5f6c6e',
    'burlap': 'b8843f', 'burlap_light': 'd9ae66', 'burlap_dark': '7a4f26', 'twine': '5e4a2e',
    'cut': 'e2c48f', 'cut_ring': 'b07a45',
}
PART = {
    'oak': 'Timber', 'oak_light': 'Timber', 'wood': 'Timber', 'wood_light': 'Timber', 'wood_dark': 'Timber',
    'iron': 'Iron', 'iron_light': 'Iron',
    'burlap': 'Sacks', 'burlap_light': 'Sacks', 'burlap_dark': 'Sacks', 'twine': 'Twine',
    'cut': 'Logs', 'cut_ring': 'Logs',
}


def barrel():
    """0.45 m across at the belly, 0.5 m with the lid: oak staves in three tones with dark seams, three iron hoops."""
    cells = {}
    radius = {0: 3.6, 1: 4.2, 2: 4.4, 3: 4.4, 4: 4.4, 5: 4.4, 6: 4.4, 7: 4.2, 8: 3.7}
    hoops = {1, 4, 7}
    step = 2 * math.pi / 8  # eight staves
    for z, r in radius.items():
        for x in range(-5, 6):
            for y in range(-5, 6):
                hoop = z in hoops
                if math.hypot(x, y) > (r + 0.45 if hoop else r) + 1e-9:
                    continue
                angle = math.atan2(y, x)
                lit = math.cos(angle + math.pi / 4)  # 1 faces the camera's front-right, -1 faces away
                offset = angle % step
                seam = min(offset, step - offset) < 0.2
                if hoop:
                    colour = 'iron_light' if lit > 0.5 else 'iron'
                elif z == 0 or seam:
                    colour = 'wood_dark'
                elif lit > 0.5:
                    colour = 'oak_light'
                elif lit < -0.5:
                    colour = 'wood'
                else:
                    colour = 'oak'
                cells[(x, y, z)] = colour
    for x in range(-4, 5):
        for y in range(-4, 5):
            d = math.hypot(x, y)
            if d <= 3.7 + 1e-9:
                cells[(x, y, 9)] = 'wood_dark' if y == 0 else ('oak' if d > 3.1 else 'oak_light')
    cells[(0, -5, 3)] = 'wood_dark'  # bung on the front
    return cells


def crate(cells, x0, x1, y0, y1, z0, z1, seam):
    """A closed timber crate: dark corner posts, a dark base rail, a plank seam across the sides and one on the lid."""
    mid_y = (y0 + y1) // 2
    for x in range(x0, x1 + 1):
        for y in range(y0, y1 + 1):
            for z in range(z0, z1 + 1):
                if x in (x0, x1) and y in (y0, y1):
                    colour = 'wood_dark'
                elif z == z0:
                    colour = 'wood_dark'
                elif z == z1:
                    colour = 'wood' if y == mid_y else 'oak_light'
                elif z == seam:
                    colour = 'wood_dark'
                elif x == x1:
                    colour = 'wood'
                else:
                    colour = 'oak'
                cells[(x, y, z)] = colour


def crate_stack():
    """Two timber crates: the top one 7 voxels square and shifted one voxel to +X, so its left ledge shows."""
    cells = {}
    crate(cells, -4, 4, -4, 4, 0, 4, seam=2)  # 0.45 m square, 0.25 m tall
    crate(cells, -2, 4, -3, 3, 5, 9, seam=7)  # 0.35 m square, 0.25 m tall, offset to +X
    return cells


# A sack is a stack of ellipses from its base to its gathered mouth: (half-width, half-depth, kind). The belly is the
# widest part. The tie is a twine band at the neck, and the neck is the gathered mouth, lightest on top.
SACK_LAYERS = [(4.2, 3.6, 'body'), (4.8, 4.2, 'body'), (4.9, 4.3, 'body'), (4.6, 4.0, 'body'), (4.0, 3.5, 'body'),
               (3.0, 2.8, 'body'), (2.4, 2.2, 'body'), (2.2, 2.0, 'tie'), (2.6, 2.4, 'neck')]
FOLDS = (-0.35, 0.4)  # two soft vertical creases across the belly, as fractions of its half-width


def sack(cells, cx, cy, base, layers=SACK_LAYERS):
    """One burlap sack built layer by layer from its base. The belly has a light side, a dark side and vertical folds
    between them, the shoulder narrows into a gathered neck, a twine tie closes the neck and the mouth flares above it."""
    last = len(layers) - 1
    for i, (rx, ry, kind) in enumerate(layers):
        z = base + i
        for x in range(math.floor(cx - rx), math.ceil(cx + rx) + 1):
            for y in range(math.floor(cy - ry), math.ceil(cy + ry) + 1):
                dx, dy = (x - cx) / rx, (y - cy) / ry
                if dx * dx + dy * dy > 1 + 1e-9:
                    continue
                if kind == 'tie':
                    colour = 'twine'
                elif kind == 'neck':
                    colour = 'burlap_light' if i == last else 'burlap'
                elif i == 0 or dx > 0.55:
                    colour = 'burlap_dark'
                elif dx < -0.55:
                    colour = 'burlap_light'
                elif any(abs(dx - fold) < 0.14 for fold in FOLDS):
                    colour = 'burlap_dark'
                else:
                    colour = 'burlap'
                cells[(x, y, z)] = colour
    tie_z = base + next(i for i, layer in enumerate(layers) if layer[2] == 'tie')
    cells[(math.floor(cx), math.floor(cy) - 2, tie_z)] = 'twine'  # the knot, on the front of the tie


def grain_sacks():
    """Three sacks: a pair side by side on the ground and one sitting in the gap between them."""
    cells = {}
    sack(cells, -4.6, 0, 0)
    sack(cells, 4.6, 0, 0)
    sack(cells, 0, 0, 5)
    return cells


# A log lies along y with its round ends to the front. Log centres are on the x axis and the rows are stacked in z.
LOG_RADIUS = 2.5  # 0.25 m across
BOTTOM_ROW = ([-6.75, -2.25, 2.25, 6.75], 2.5)  # four logs on the ground, their centres at z = 2.5 voxels
TOP_ROW = ([-4.5, 0.0, 4.5], 6.9)  # three logs nested in the grooves above


def log(cells, u, vz, index):
    """One round log: bark shaded by side (alternate logs have a lighter bark), and pale cut ends with rings."""
    light, mid, dark = ('oak_light', 'oak', 'wood') if index % 2 == 0 else ('wood_light', 'wood', 'wood_dark')
    r = LOG_RADIUS
    for x in range(math.floor(u - r), math.ceil(u + r) + 1):
        for z in range(math.floor(vz - r), math.ceil(vz + r) + 1):
            du, dz = x + 0.5 - u, z + 0.5 - vz
            d = math.hypot(du, dz)
            if d > r:
                continue
            for y in range(-4, 4):
                if y in (-4, 3):
                    colour = 'cut_ring' if d <= 0.9 else ('cut' if d <= r - 0.9 else 'wood')
                elif dz > 0.5 * r:
                    colour = light
                elif du > 0.6 * r or dz < -0.5 * r:
                    colour = dark
                else:
                    colour = mid
                cells[(x, y, z)] = colour


def woodpile():
    """Round split logs in two rows, four on the ground and three nested above, with their ends to the front."""
    cells = {}
    index = 0
    for centres, vz in (BOTTOM_ROW, TOP_ROW):
        for u in centres:
            log(cells, u, vz, index)
            index += 1
    return cells


def centre_of(cells):
    """The origin sits at the middle of the footprint and on the base (z = 0)."""
    assert min(z for _, _, z in cells) == 0, 'the base must sit on z = 0'
    xs = [x for x, _, _ in cells]
    ys = [y for _, y, _ in cells]
    return ((min(xs) + max(xs) + 1) / 2, (min(ys) + max(ys) + 1) / 2, 0)


MODELS = {
    'wooden-barrel': barrel(),
    'crate-stack': crate_stack(),
    'grain-sacks': grain_sacks(),
    'woodpile': woodpile(),
}
wanted = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
vx.author_models(__file__, [(model_id, cells, centre_of(cells)) for model_id, cells in MODELS.items() if not wanted or model_id in wanted], COLOURS, PART)
