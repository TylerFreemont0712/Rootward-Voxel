"""Shared authoring kit for the second pass on the three market shops (2026-11-12): Morning Loaf, The Pantry and
Finch & Thread. Imported by the author_*.py records beside it; it imports no model geometry.

What it adds to the seaside house kit (`house_kit.Parts` still does the boxes, cylinders and joins):

* **One palette atlas.** Plain colours are 16-pixel cells of `textures/shops-palette.png`, so a piece made of forty
  colours still exports a handful of materials: `shops_paint` (matte, outlined), `shops_gloss` (glazes, icing,
  enamel, outlined), `shops_metal` (brass, copper, steel; no outline) and `_fine` twins of paint and gloss for small
  parts that must not grow an ink outline. A colour key may end in `/f` to use its fine twin.
* **Painted surfaces.** Oak, dark oak, linen, brick, marble, metro tile, wallpaper, rug and the like are textured
  materials (`shops_<name>`); the procedural ones are painted here, deterministically, into `textures/`.
* **Turned, swept and draped forms.** `lathe` (jars, loaves, stands, legs), `tube` (bentwood, wire, scrolls,
  pretzels), `torus`, and `sheet` (cloth with real thickness: curtains, drapes, awnings).
* **Lettering** in the game's own Cinzel and Alegreya faces (ui/fonts), as flat geometry.

Blender +X east, +Y north (logical north), +Z up, front toward -Y; one unit is one metre and one game cell.
A master, once saved, is the editable authority: export it only through scripts/world-art.sh build <id>.
"""
from contextlib import contextmanager
from pathlib import Path
import hashlib
import json
import math
import random
import sys

import bmesh
import bpy
import numpy as np
from mathutils import Matrix, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(ROOT / 'art/source/world/seaside-houses/v1'))
import house_kit as k  # noqa: E402

TEX = HERE / 'textures'
NATIVE = ROOT / 'art/source/world/textures/v2-detail/native'
TOWN = ROOT / 'art/source/world/town-ground/v1/native'
DETAIL = ROOT / 'assets/world/textures/seaside-houses/detail'
FONTS = {'cinzel': ROOT / 'ui/fonts/cinzel.ttf', 'alegreya': ROOT / 'ui/fonts/alegreya.ttf',
         'spectral': ROOT / 'ui/fonts/spectral-600.ttf'}

# --- the palette --------------------------------------------------------------------------------------------------
# Appending keeps every earlier cell in place; a saved master keeps its own packed copy either way.
PALETTE = {
    # ink, metal, paper
    'ink': '2a2522', 'iron': '3b3f42', 'iron_light': '5d6569', 'steel': '8e999c', 'silver': 'c9ced1',
    'brass': 'c49a52', 'brass_dark': '8f6c34', 'copper': 'd0814e', 'copper_dark': '9a5634', 'gold': 'd8b259',
    'zinc': 'a2abad', 'chrome': 'dfe4e6', 'paper': 'f2e9d3', 'kraft': 'c9a676', 'card': 'e8dcc0',
    'linen': 'ece3cd', 'cream': 'f3e9d2', 'white': 'f8f5ee', 'chalk': '2b3430', 'chalk_line': 'e9e4d6',
    'label_red': 'b0412f', 'label_blue': '3f5f8c', 'label_green': '3f6e4c', 'string': 'ddd0b0',
    # wood and stone accents
    'wood_dark': '4a3324', 'wood_mid': '7a5236', 'wood_light': 'b48a5c', 'wood_end': 'd9b484', 'cork': 'b98c5a',
    'marble_white': 'eeeae2', 'marble_grey': 'b9b8b4', 'slate': '4a5052', 'terracotta': 'c4643e',
    'terracotta_dark': '9d4a2e', 'soil': '5c4433',
    # the bakery
    'crust': 'c27a3c', 'crust_light': 'dca25c', 'crust_dark': '8f4f22', 'crust_deep': '6b3818', 'crumb': 'ecd3a0',
    'flour': 'f4efe3', 'dough': 'efdcb8', 'icing': 'fbf7ef', 'icing_pink': 'f0b6c0', 'icing_mint': 'bfe0cf',
    'icing_lemon': 'f5e3a1', 'chocolate': '5a3423', 'chocolate_light': '7d4a30', 'jam': 'a8303a',
    'raspberry': 'c23b54', 'strawberry': 'd0323a', 'blueberry': '3d4f8c', 'whip': 'fff8ec', 'caramel': 'c98a3c',
    'sesame': 'e2cf9a', 'poppy': '2e2a2e', 'mac_pink': 'f2a7b8', 'mac_lav': 'c4b0e0', 'mac_pist': 'b9d39a',
    'mac_lemon': 'f4e08a', 'mac_choc': '8a5a42', 'glaze': 'e8a24a',
    # the pantry
    'apple': 'b8332a', 'apple_dark': '8e2420', 'apple_green': '93b53f', 'apple_gold': 'd9c45a', 'orange': 'e8892a',
    'lemon': 'eccb45', 'lime': '8fbf3f', 'pear': 'c8c35a', 'plum': '5e2f52', 'grape': 'b4c96a',
    'grape_dark': '4f2f5a', 'banana': 'f0d24a', 'cherry': '9c1f2b', 'tomato': 'd8402f', 'carrot': 'e0782a',
    'potato': 'c09a68', 'onion': 'c4853f', 'onion_red': '8c3550', 'garlic': 'efe6d4', 'beet': '7a2240',
    'cabbage': '8fb466', 'cabbage_dark': '557d3c', 'leaf': '4e8a3e', 'leaf_dark': '35652f', 'leaf_light': '8fbf5c',
    'aubergine': '4a2a4f', 'pepper': 'c9302b', 'pepper_gold': 'e8b830', 'pumpkin': 'e07f2a', 'squash': '6d8d3f',
    'mushroom': 'd8c8ad', 'cheese': 'f0cd6a', 'rind': 'd3a24a', 'wax': 'b52a2a', 'egg': 'efe4cf',
    'egg_brown': 'c99d6e', 'milk': 'f6f4ee', 'honey': 'd4952a', 'oil': 'c8b34a', 'tea': '3f6b4f',
    'flower_pink': 'e89aae', 'flower_yellow': 'f2cf4a', 'flower_white': 'f8f4ea', 'flower_violet': '8f6bb5',
    'flower_red': 'd54a42', 'flower_blue': '6d8fd0', 'stem': '4f7d3a', 'wicker': 'c49a55', 'wicker_dark': '8f6a32',
    'salami': '8a3b33', 'ham': 'd99a8a', 'herb': '5b8f4a', 'lavender': '9a86c4',
    # the tailor
    'cloth_navy': '2f3d5c', 'cloth_slate': '4f6890', 'cloth_sky': '8fb1d6', 'cloth_rose': 'c9848c',
    'cloth_blush': 'e9c1c1', 'cloth_wine': '7a2838', 'cloth_plum': '5e3a63', 'cloth_mustard': 'c9a03f',
    'cloth_ochre': 'b8842f', 'cloth_olive': '6e7a3e', 'cloth_forest': '2f5a43', 'cloth_teal': '2f6f6f',
    'cloth_tweed': '8a7a5e', 'cloth_camel': 'b8925e', 'cloth_charcoal': '3e3f45', 'cloth_grey': '8e9196',
    'cloth_ivory': 'efe6d2', 'cloth_black': '25252b', 'cloth_rust': 'a4542f', 'cloth_lilac': 'a796c4',
    'velvet_wine': '6e1f30', 'velvet_teal': '1f5458', 'form': 'e2d3b4', 'form_dark': '3a2f2a', 'pin': 'c94f4f',
    'tape': 'e9cf6a', 'thread_white': 'f3efe6',
    # the shops' own paints
    'oxblood': '7a2e2a', 'oxblood_dark': '5a1f1c', 'bottle': '2e5a43', 'bottle_dark': '214434',
    'navy': '3d5579', 'navy_dark': '2b3d5a', 'rose': 'd8a7a0', 'sage': '9fb79a', 'teal': '2c6a5f',
    'cream_paint': 'efe4c8', 'butter': 'f2dc9a', 'gold_leaf': 'd9b35f', 'enamel_white': 'f4f1e8',
    'enamel_green': '2f6b52', 'enamel_blue': '3d5f8a', 'enamel_red': 'b83b2f', 'china': 'f6f3ec',
    'china_blue': '4f6fa8', 'glass_green': '7fa08a', 'glass_amber': 'b07a30', 'glass_clear': 'cfe0dc',
    'rose_dark': 'a86e6a', 'stripe_cream': 'f1ead6',
    # appended 2026-11-12, after the oven
    'limestone': 'ddd2b9', 'limestone_dark': 'b9ab8e', 'oxblood_glaze': '8a2f2b', 'cane': 'd8b878', 'sky': 'c9dbe0',
    'leaf_mid': '6a9a4c', 'geranium': 'd8473f', 'canvas': 'f1ead6', 'chocolate_dark': '3e2318', 'eclair': 'c58a45',
    'glass_bottle': '2f6b4c', 'pink_box': 'efc3c8', 'mint_box': 'c3e0d2', 'ribbon_red': 'b8333a', 'coffee': '4a2c1e', 'tea_liquid': '9a5a2a',
}
METAL = {'brass', 'brass_dark', 'copper', 'copper_dark', 'gold', 'silver', 'steel', 'chrome', 'zinc'}
GLOSS = {'icing', 'icing_pink', 'icing_mint', 'icing_lemon', 'glaze', 'jam', 'raspberry', 'strawberry', 'blueberry',
         'cherry', 'marble_white', 'marble_grey', 'enamel_white', 'enamel_green', 'enamel_blue', 'enamel_red',
         'china', 'china_blue', 'glass_green', 'glass_amber', 'glass_clear', 'honey', 'oil', 'apple', 'apple_dark',
         'apple_green', 'apple_gold', 'tomato', 'aubergine', 'pepper', 'pepper_gold', 'wax', 'chocolate',
         'mac_pink', 'mac_lav', 'mac_pist', 'mac_lemon', 'mac_choc', 'grape', 'grape_dark', 'plum', 'velvet_wine',
         'velvet_teal', 'gold_leaf', 'oxblood_glaze', 'glass_bottle'}
COLUMNS, CELL = 16, 16


def _palette_image():
    """Paints every plain colour as one 16-pixel cell (the same picture every run)."""
    rows = math.ceil(len(PALETTE) / COLUMNS)
    width, height = COLUMNS * CELL, rows * CELL
    pixels = np.ones((height, width, 4), dtype=np.float32)
    for index, colour in enumerate(PALETTE.values()):
        col, row = index % COLUMNS, index // COLUMNS
        rgb = [int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4)]
        top = height - (row + 1) * CELL
        pixels[top:top + CELL, col * CELL:(col + 1) * CELL, :3] = rgb
    return _save_png('shops-palette', pixels)


def palette_uv(name):
    index = list(PALETTE).index(name)
    rows = math.ceil(len(PALETTE) / COLUMNS)
    return ((index % COLUMNS + .5) / COLUMNS, 1 - (index // COLUMNS + .5) / rows)


# --- painted textures ---------------------------------------------------------------------------------------------
def _save_png(name, pixels):
    """pixels: rows bottom-up, RGBA floats in sRGB."""
    TEX.mkdir(parents=True, exist_ok=True)
    path = TEX / (name + '.png')
    h, w = pixels.shape[:2]
    image = bpy.data.images.new(name + '_painting', w, h, alpha=False)
    image.pixels = np.clip(pixels, 0, 1).ravel()
    image.filepath_raw = str(path)
    image.file_format = 'PNG'
    image.save()
    bpy.data.images.remove(image)
    return path


def _reduced(name, source, size, tint=None):
    """A smaller copy of a native painting, so a prop does not carry a 1254-pixel picture; `tint` multiplies it."""
    image = bpy.data.images.load(str(source))
    image.scale(size, size)
    pixels = np.array(image.pixels[:], dtype=np.float32).reshape(size, size, 4)
    if tint:
        pixels[..., :3] *= _hex(tint)
    bpy.data.images.remove(image)
    return _save_png(name, pixels)


def _noise(rng, h, w, octaves=4, scale=8):
    """Smooth value noise in 0..1, tiling."""
    out = np.zeros((h, w), dtype=np.float32)
    amp, total = 1.0, 0.0
    for o in range(octaves):
        n = scale * 2 ** o
        grid = rng.random((n, n)).astype(np.float32)
        ys = np.linspace(0, n, h, endpoint=False)
        xs = np.linspace(0, n, w, endpoint=False)
        y0 = np.floor(ys).astype(int) % n
        x0 = np.floor(xs).astype(int) % n
        fy = (ys - np.floor(ys))[:, None]
        fx = (xs - np.floor(xs))[None, :]
        fy = fy * fy * (3 - 2 * fy)
        fx = fx * fx * (3 - 2 * fx)
        a = grid[y0][:, x0]
        b = grid[y0][:, (x0 + 1) % n]
        c = grid[(y0 + 1) % n][:, x0]
        d = grid[(y0 + 1) % n][:, (x0 + 1) % n]
        out += amp * ((a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy)
        total += amp
        amp *= .5
    return out / total


def _hex(colour):
    return np.array([int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4)], dtype=np.float32)


def paint_metro(size=256):
    """White glazed metro tiles, 4 courses by 2 tiles per repeat, offset bond, grey grout, a soft glaze highlight."""
    rng = np.random.default_rng(1101)
    px = np.ones((size, size, 4), dtype=np.float32)
    rows, cols = 8, 4
    th, tw = size // rows, size // cols
    grout = _hex('bdb7ab')
    noise = _noise(rng, size, size, 3, 4)
    for r in range(rows):
        shift = (tw // 2) * (r % 2)
        for c in range(cols + 1):
            x0 = c * tw - shift
            tint = 1 - rng.random() * .05
            base = _hex('f6f2e8') * tint + _hex('e6efe9') * (1 - tint) * 4
            for y in range(r * th + 2, (r + 1) * th - 1):
                v = (y - r * th) / th
                shade = 1.0 + .05 * (1 - v) - .06 * max(0, v - .75) * 4
                for x in range(max(0, x0 + 2), min(size, x0 + tw - 1)):
                    u = (x - x0) / tw
                    edge = min(u, 1 - u, v, 1 - v)
                    s = shade - (.08 if edge < .05 else 0)
                    px[y, x, :3] = np.clip(base * s * (.97 + .05 * noise[y, x]), 0, 1)
            for y in range(r * th, (r + 1) * th):
                for x in (x0, x0 + 1, x0 + tw - 1):
                    if 0 <= x < size:
                        px[y, x, :3] = grout
        px[r * th:r * th + 2, :, :3] = grout
    return _save_png('metro-tile', px[::-1].copy())


def paint_marble(size=256, base='efebe3', vein='8a857c', seed=1102):
    rng = np.random.default_rng(seed)
    n = _noise(rng, size, size, 5, 3)
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32) / size
    veins = np.abs(np.sin((xs * 2 + ys * 1 + n * 2.6) * math.pi * 2))
    veins = np.clip(1 - veins * 4.5, 0, 1) ** 1.5
    fine = np.abs(np.sin((xs * 5 - ys * 3 + n * 4) * math.pi * 2))
    fine = np.clip(1 - fine * 9, 0, 1) * .55
    b, v = _hex(base), _hex(vein)
    mix = np.clip(veins * .8 + fine, 0, 1)[..., None]
    px = np.ones((size, size, 4), dtype=np.float32)
    px[..., :3] = b * (1 - mix) + v * mix
    px[..., :3] *= (.97 + .04 * n)[..., None]
    return _save_png('marble-' + base, px)


def paint_stripe_paper(size=256):
    """Regency stripe: cream ground, broad dusty-rose stripes edged in fine gold, a sprig dot between."""
    rng = np.random.default_rng(1103)
    px = np.ones((size, size, 4), dtype=np.float32)
    cream, rose, gold, dark = _hex('f1e4d6'), _hex('d6a39d'), _hex('c7a15a'), _hex('b98580')
    n = _noise(rng, size, size, 3, 6)
    for x in range(size):
        u = (x / size * 4) % 1.0           # four stripes per repeat
        colour = cream
        if .08 < u < .38:
            colour = rose
            if .1 < u < .14 or .32 < u < .36:
                colour = dark * .3 + rose * .7
        elif .05 < u < .07 or .39 < u < .41:
            colour = gold
        px[:, x, :3] = colour
    for i in range(4):
        cx = int(((i + .7) / 4) * size)
        for j in range(4):
            cy = int((j + .5) / 4 * size)
            for dy in range(-4, 5):
                for dx in range(-4, 5):
                    if dx * dx + dy * dy <= 12:
                        px[(cy + dy) % size, (cx + dx) % size, :3] = gold * .8 + cream * .2
            for dy in range(-10, 11):
                for dx in (-1, 0, 1):
                    if 5 < abs(dy):
                        px[(cy + dy) % size, (cx + dx) % size, :3] = _hex('9fb08f')
    px[..., :3] *= (.96 + .06 * n)[..., None]
    return _save_png('stripe-paper', px)


def paint_rug(size=512, seed=1104, field='8e2f33', border='2f3d5c', guard='e8dcc0', accent='d8a24a', name='rug'):
    """A knotted rug, one whole picture: border, guard stripes, a stepped central medallion and corner pieces."""
    rng = np.random.default_rng(seed)
    f, b, g, a = _hex(field), _hex(border), _hex(guard), _hex(accent)
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32) / size
    px = np.ones((size, size, 4), dtype=np.float32)
    px[..., :3] = f
    edge = np.minimum(np.minimum(xs, 1 - xs), np.minimum(ys, 1 - ys))
    px[edge < .12, :3] = b
    px[(edge > .035) & (edge < .045), :3] = g
    px[(edge > .105) & (edge < .118), :3] = g
    # running motif in the border
    motif = (np.abs(((xs + ys) * 22) % 2 - 1) < .3) & (edge > .055) & (edge < .095)
    px[motif, :3] = a
    cx, cy = np.abs(xs - .5), np.abs(ys - .5)
    diamond = cx + cy
    px[(diamond < .26) & (edge >= .12), :3] = b
    px[(diamond < .2) & (edge >= .12), :3] = a
    px[(diamond < .15) & (edge >= .12), :3] = f * .7 + g * .3
    px[(diamond < .08) & (edge >= .12), :3] = g
    px[(np.abs(diamond - .23) < .006) & (edge >= .12), :3] = g
    corner = (np.minimum(xs, 1 - xs) + np.minimum(ys, 1 - ys) < .32) & (edge >= .12)
    px[corner, :3] = b * .5 + f * .5
    px[(np.abs(np.minimum(xs, 1 - xs) + np.minimum(ys, 1 - ys) - .32) < .006) & (edge >= .12), :3] = a
    # small diamonds scattered in the field
    dots = ((np.abs(((xs * 9) % 1) - .5) + np.abs(((ys * 9) % 1) - .5)) < .12) & (diamond > .3) & (edge >= .14) & ~corner
    px[dots, :3] = g * .6 + f * .4
    n = _noise(rng, size, size, 4, 16)
    px[..., :3] *= (.9 + .14 * n)[..., None]
    return _save_png(name, px)


def paint_check(name, a, b, size=128, squares=8, line=None):
    """Gingham or a chequer: two colours, optional crossing lines."""
    rng = np.random.default_rng(len(name) * 97)
    ca, cb = _hex(a), _hex(b)
    ys, xs = np.mgrid[0:size, 0:size]
    sq = size // squares
    across = (xs // sq) % 2
    down = (ys // sq) % 2
    px = np.ones((size, size, 4), dtype=np.float32)
    if line:
        mix = (across + down) / 2.0
        px[..., :3] = cb[None, None] * (1 - mix[..., None]) + ca[None, None] * mix[..., None]
    else:
        px[..., :3] = np.where(((across + down) % 2)[..., None] == 1, ca, cb)
    n = _noise(rng, size, size, 2, 8)
    px[..., :3] *= (.95 + .07 * n)[..., None]
    return _save_png(name, px)


def paint_panel_paint(name, colour, size=128, seed=1105):
    """A brushed painted-wood surface in one colour (for painted joinery that should not look like plastic)."""
    rng = np.random.default_rng(seed)
    c = _hex(colour)
    n = _noise(rng, size, size, 3, 4)
    streak = _noise(rng, size, size, 2, 2)
    ys, xs = np.mgrid[0:size, 0:size].astype(np.float32) / size
    grain = .5 + .5 * np.sin((ys * 30 + streak * 6) * math.pi)
    px = np.ones((size, size, 4), dtype=np.float32)
    px[..., :3] = c * (.93 + .06 * n + .03 * grain)[..., None]
    return _save_png(name, px)


# --- materials ----------------------------------------------------------------------------------------------------
REPEAT = {}


def material(name, colour='ffffff', image=None, roughness=.85, metallic=0.0, emission=0.0, repeat=1.0, alpha=None,
          interpolation='Linear'):
    mat = k.material(name, colour, image, roughness=roughness, emission=emission, metallic=metallic,
                     interpolation=interpolation)
    if alpha is not None:
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bsdf.inputs['Alpha'].default_value = alpha
        mat.surface_render_method = 'BLENDED'
    REPEAT[name] = repeat
    return mat


def _base_materials():
    palette = _palette_image()
    for cls, rough, metal in (('paint', .84, 0.0), ('gloss', .32, 0.0), ('metal', .4, .3)):
        material('shops_' + cls, 'ffffff', palette, rough, metal, interpolation='Closest')
        if cls != 'metal':
            material('shops_' + cls + '_fine', 'ffffff', palette, rough, metal, interpolation='Closest')
    material('shops_clear_glass', 'e3eeea', roughness=.08, alpha=.16)
    material('shops_mirror', 'b5c4c8', roughness=.06, metallic=.25)
    material('shops_lamp_glass', 'ffd697', roughness=.3, emission=.9)


# Textured surfaces a record may ask for by name; each is created on first use.
SURFACES = {
    'oak': (lambda: DETAIL / 'seaside_timber_oak.png', .66, 1.6),
    'oak_dark': (lambda: DETAIL / 'seaside_timber_dark.png', .62, 1.6),
    'driftwood': (lambda: DETAIL / 'seaside_timber_driftwood.png', .8, 1.6),
    'linen': (lambda: _reduced('woven-linen-256', NATIVE / 'woven_linen.png', 256), .95, .9),
    'burlap': (lambda: _reduced('burlap-256', NATIVE / 'woven_linen.png', 256, 'c9ab78'), .97, .45),
    'brick': (lambda: _reduced('red-brick-256', NATIVE / 'red_brick.png', 256), .9, 1.1),
    'panels': (lambda: _reduced('timber-panels-256', NATIVE / 'timber_panels.png', 256), .7, 1.4),
    'leather': (lambda: _reduced('tooled-leather-256', NATIVE / 'tooled_leather.png', 256), .55, .7),
    'quilt': (lambda: _reduced('violet-quilt-256', NATIVE / 'violet_quilt.png', 256), .9, .9),
    'encaustic': (lambda: _reduced('encaustic-tile-256', NATIVE / 'encaustic_tile.png', 256), .5, 1.2),
    'sage_paper': (lambda: _reduced('sage-wallpaper-256', NATIVE / 'sage_wallpaper.png', 256), .9, 1.5),
    'limewash': (lambda: _reduced('limewash-256', NATIVE / 'limewash.png', 256), .95, 2.4),
    'patina': (lambda: _reduced('copper-patina-256', NATIVE / 'copper_patina.png', 256), .5, 1.0),
    'metro': (paint_metro, .22, 1.2),
    'marble': (lambda: paint_marble(), .25, 1.1),
    'marble_green': (lambda: paint_marble(base='5f7f6a', vein='e3e8dc', seed=1106), .25, 1.1),
    'stripe_paper': (paint_stripe_paper, .88, 1.6),
    'gingham_red': (lambda: paint_check('gingham-red', 'b8433a', 'f4ece0', line=True), .9, .5),
    'gingham_blue': (lambda: paint_check('gingham-blue', '4f6fa8', 'f4ece0', line=True), .9, .5),
    'gingham_green': (lambda: paint_check('gingham-green', '4f8a6a', 'f4ece0', line=True), .9, .5),
    'chequer': (lambda: paint_check('chequer-floor', 'efe8da', '3b3f42', size=128, squares=2), .45, 1.0),
}
FLOOR_SURFACES = {
    'floor_terracotta': (NATIVE / 'terracotta_tile.png', .8, 1.6),
    'floor_flags': (TOWN / 'town_flags.png', .82, 3.0),
    'floor_herringbone': (NATIVE / 'herringbone_oak.png', .7, 1.5),
}


def surface(name):
    full = 'shops_' + name
    if full not in k.M:
        if name in FLOOR_SURFACES:
            image, rough, rep = FLOOR_SURFACES[name]
        elif name.startswith('rug_'):
            image, rough, rep = RUGS[name](), .95, 1.0
        else:
            make, rough, rep = SURFACES[name]
            image = make()
        material(full, 'ffffff', image, rough, repeat=rep)
    return full


RUGS = {
    'rug_wine': lambda: paint_rug(),
    'rug_teal': lambda: paint_rug(seed=1107, field='2f5a5a', border='7a2e2a', guard='efe4c8', accent='d8b259', name='rug-teal'),
}


def joinery(name, colour):
    """A painted-wood surface in a shop's own colour (doors, wainscot, counters)."""
    full = 'shops_' + name
    if full not in k.M:
        material(full, 'ffffff', paint_panel_paint(name.replace('_', '-'), colour), .62, repeat=1.0)
    return full


# --- geometry -----------------------------------------------------------------------------------------------------
class Parts(k.Parts):
    """House-kit parts that understand palette keys (`crust`, `crust/f`), textured surfaces (`@oak`) and painted
    joinery (`#oxblood`)."""

    def resolve(self, key):
        if key.startswith('@'):
            return surface(key[1:]), None
        if key.startswith('#'):
            return joinery('paint_' + key[1:], PALETTE[key[1:]]), None
        if key.startswith('shops_') or key in k.M:
            return key, None
        fine = key.endswith('/f')
        name = key[:-2] if fine else key
        if name not in PALETTE:
            raise KeyError('No palette colour or surface called ' + key)
        cls = 'metal' if name in METAL else 'gloss' if name in GLOSS else 'paint'
        if fine and cls != 'metal':
            cls += '_fine'
        return 'shops_' + cls, palette_uv(name)

    @contextmanager
    def framed(self, matrix):
        """Authors pieces through any 4x4 matrix inside the current frame (a tilted basket, a leaning board)."""
        previous = self.frame
        self.frame = self.frame @ matrix
        try:
            yield
        finally:
            self.frame = previous

    def add(self, mat, verts, faces, uvs, smooth=False):
        mat, cell = self.resolve(mat)
        if cell is not None:
            uvs = [[cell] * len(face) for face in faces]
        bucket = self.bucket(mat)
        base = len(bucket['v'])
        bucket['v'].extend(tuple(self.frame @ Vector(v)) for v in verts)
        for face, loop_uvs in zip(faces, uvs):
            bucket['f'].append(tuple(base + i for i in face))
            bucket['uv'].append([tuple(uv) for uv in loop_uvs])
            bucket['smooth'].append(smooth)

    def _take(self, bm, matrix, mat, uv='world', repeat=None, smooth=False, offset=None):
        resolved, _ = self.resolve(mat)
        if repeat is None:
            repeat = REPEAT.get(resolved, 1.0)
        if offset is None:
            offset = (self.rng.random(), self.rng.random()) if uv == 'local' else (0.0, 0.0)
        uvs = self._uvs(bm, matrix, resolved, uv, repeat, offset)
        verts = [matrix @ v.co for v in bm.verts]
        index = {v: i for i, v in enumerate(bm.verts)}
        faces = [[index[l.vert] for l in f.loops] for f in bm.faces]
        self.add(mat, verts, faces, uvs, smooth)
        bm.free()


def box(p, m, at, size, b=.012, rot=(0, 0, 0), seg=1, uv=None):
    if uv is None:
        uv = 'local' if m.startswith('@') and m[1:] in ('oak', 'oak_dark', 'driftwood', 'panels') else 'world'
    p.box(m, at, size, rot=rot, bevel=b, segments=seg, uv=uv)


def soft(p, m, at, size, r=.04, rot=(0, 0, 0)):
    """A rounded block (cushions, loaves, folded cloth)."""
    p.box(m, at, size, rot=rot, bevel=min(r, min(size) * .45), segments=3, uv='world')


def rod(p, m, a, b, r=.015, n=12, rb=None, smooth=True, caps=True):
    p.cylinder(m, a, b, r, n, radius_b=rb, uv='local', smooth=smooth, caps=caps)


def ball(p, m, at, r, squash=(1, 1, 1), sub=None):
    if sub is None:
        sub = 0 if r < .025 else 1 if r < .07 else 2
    bm = bmesh.new()
    bmesh.ops.create_icosphere(bm, subdivisions=sub, radius=1.0)
    bmesh.ops.scale(bm, vec=Vector((r * squash[0], r * squash[1], r * squash[2])), verts=bm.verts)
    p._take(bm, Matrix.Translation(Vector(at)), m, 'world', None, True)


def lathe(p, m, profile, at=(0, 0, 0), n=24, smooth=True, cap0=True, cap1=True, squash=(1, 1), phase=0.0,
          axis=None, ripple=None):
    """A surface of revolution. `profile` is [(radius, height), ...] from the bottom up; a radius of 0 is a pole.
    `axis` (a 3x3 matrix) lays the turned form over, e.g. for a rolled bolt; `ripple(a, z)` scales the radius
    (fluted tins, ribbed squash, scalloped cake boards)."""
    origin = Vector(at)
    rot = axis if axis is not None else Matrix.Identity(3)
    verts, faces, uvs = [], [], []
    rings = []
    length = 0.0
    lengths = [0.0]
    for (r0, z0), (r1, z1) in zip(profile, profile[1:]):
        length += math.hypot(r1 - r0, z1 - z0)
        lengths.append(length)
    rep = REPEAT.get(Parts.resolve(p, m)[0], 1.0)
    for (r, z), s in zip(profile, lengths):
        if r <= 1e-6:
            verts.append(tuple(origin + rot @ Vector((0, 0, z))))
            rings.append([len(verts) - 1])
            continue
        ring = []
        for i in range(n):
            a = phase + math.tau * i / n
            rr = r * (ripple(a, z) if ripple else 1.0)
            verts.append(tuple(origin + rot @ Vector((rr * math.cos(a) * squash[0], rr * math.sin(a) * squash[1], z))))
            ring.append(len(verts) - 1)
        rings.append(ring)
    lengths_u = [s / rep for s in lengths]
    for j in range(len(rings) - 1):
        lo, hi = rings[j], rings[j + 1]
        rr = max(profile[j][0], profile[j + 1][0])
        for i in range(n):
            i2 = (i + 1) % n
            u0, u1 = rr * math.tau * i / n / rep, rr * math.tau * (i + 1) / n / rep
            v0, v1 = lengths_u[j], lengths_u[j + 1]
            if len(lo) == 1:
                faces.append((lo[0], hi[i2], hi[i]))
                uvs.append([((u0 + u1) / 2, v0), (u1, v1), (u0, v1)])
            elif len(hi) == 1:
                faces.append((lo[i], lo[i2], hi[0]))
                uvs.append([(u0, v0), (u1, v0), ((u0 + u1) / 2, v1)])
            else:
                faces.append((lo[i], lo[i2], hi[i2], hi[i]))
                uvs.append([(u0, v0), (u1, v0), (u1, v1), (u0, v1)])
    p.add(m, verts, faces, uvs, smooth)
    # Flat caps are separate so they do not round the rim's shading.
    for cap, flip, (r, z) in ((cap0, True, profile[0]), (cap1, False, profile[-1])):
        if not cap or r <= 1e-6:
            continue
        ring = []
        for i in range(n):
            a = phase + math.tau * i / n
            rr = r * (ripple(a, z) if ripple else 1.0)
            ring.append(tuple(origin + rot @ Vector((rr * math.cos(a) * squash[0], rr * math.sin(a) * squash[1], z))))
        face = list(range(n))
        if flip:
            face.reverse()
        p.add(m, ring, [tuple(face)], [[(.5 + .5 * math.cos(math.tau * i / n) * r / rep,
                                           .5 + .5 * math.sin(math.tau * i / n) * r / rep) for i in face]], False)


def _frames(points, closed):
    pts = [Vector(q) for q in points]
    count = len(pts)
    tangents = []
    for i in range(count):
        if closed:
            t = pts[(i + 1) % count] - pts[i - 1]
        elif i == 0:
            t = pts[1] - pts[0]
        elif i == count - 1:
            t = pts[-1] - pts[-2]
        else:
            t = pts[i + 1] - pts[i - 1]
        tangents.append(t.normalized())
    seed = Vector((0, 0, 1)) if abs(tangents[0].z) < .9 else Vector((1, 0, 0))
    normal = (seed - tangents[0] * seed.dot(tangents[0])).normalized()
    normals = [normal]
    for i in range(1, count):
        n = normals[-1]
        t = tangents[i]
        n = (n - t * n.dot(t)).normalized()
        normals.append(n)
    return pts, tangents, normals


def tube(p, m, points, r=.012, n=8, closed=False, caps=True, smooth=True, radii=None):
    """A round section swept along a polyline (bentwood, wire, ironwork, piping, a pretzel)."""
    pts, tangents, normals = _frames(points, closed)
    verts, faces, uvs = [], [], []
    count = len(pts)
    for i in range(count):
        t, nrm = tangents[i], normals[i]
        b = t.cross(nrm)
        rr = radii[i] if radii else r
        for j in range(n):
            a = math.tau * j / n
            verts.append(tuple(pts[i] + (nrm * math.cos(a) + b * math.sin(a)) * rr))
    segs = count if closed else count - 1
    for i in range(segs):
        i2 = (i + 1) % count
        for j in range(n):
            j2 = (j + 1) % n
            faces.append((i * n + j, i * n + j2, i2 * n + j2, i2 * n + j))
            uvs.append([(j / n, i / 4), ((j + 1) / n, i / 4), ((j + 1) / n, (i + 1) / 4), (j / n, (i + 1) / 4)])
    p.add(m, verts, faces, uvs, smooth)
    if caps and not closed:
        for idx, flip in ((0, False), (count - 1, True)):
            ring = [verts[idx * n + j] for j in range(n)]
            face = tuple(range(n)) if not flip else tuple(reversed(range(n)))
            p.add(m, ring, [face], [[(0, 0)] * n], False)


def torus(p, m, centre, R, r, normal=(0, 0, 1), seg=24, n=8, arc=math.tau, start=0.0):
    c = Vector(centre)
    nz = Vector(normal).normalized()
    ax = Vector((1, 0, 0)) if abs(nz.x) < .9 else Vector((0, 1, 0))
    ax = (ax - nz * ax.dot(nz)).normalized()
    ay = nz.cross(ax)
    closed = arc >= math.tau - 1e-6
    steps = seg if closed else seg + 1
    pts = [c + (ax * math.cos(start + arc * i / seg) + ay * math.sin(start + arc * i / seg)) * R for i in range(steps)]
    tube(p, m, pts, r, n, closed=closed)


def sheet(p, m, fn, nu, nv, thick=.008, smooth=True, rims=True):
    """A thin solid surface from fn(u, v) -> (x, y, z), u and v in 0..1: cloth, drapes, awnings, paper."""
    grid = [[Vector(fn(i / nu, j / nv)) for j in range(nv + 1)] for i in range(nu + 1)]
    normals = []
    for i in range(nu + 1):
        row = []
        for j in range(nv + 1):
            du = grid[min(i + 1, nu)][j] - grid[max(i - 1, 0)][j]
            dv = grid[i][min(j + 1, nv)] - grid[i][max(j - 1, 0)]
            nrm = du.cross(dv)
            row.append(nrm.normalized() if nrm.length > 1e-9 else Vector((0, 0, 1)))
        normals.append(row)
    verts, faces, uvs = [], [], []
    rep = REPEAT.get(Parts.resolve(p, m)[0], 1.0)

    def index(i, j, back):
        return (back * (nu + 1) * (nv + 1)) + i * (nv + 1) + j
    for back in (0, 1):
        for i in range(nu + 1):
            for j in range(nv + 1):
                offset = normals[i][j] * (thick / 2) * (1 if back == 0 else -1)
                verts.append(tuple(grid[i][j] + offset))
    span_u = sum((grid[i + 1][0] - grid[i][0]).length for i in range(nu))
    span_v = sum((grid[0][j + 1] - grid[0][j]).length for j in range(nv))
    for i in range(nu):
        for j in range(nv):
            a, b, c, d = index(i, j, 0), index(i + 1, j, 0), index(i + 1, j + 1, 0), index(i, j + 1, 0)
            uv = [(i / nu * span_u / rep, j / nv * span_v / rep), ((i + 1) / nu * span_u / rep, j / nv * span_v / rep),
                  ((i + 1) / nu * span_u / rep, (j + 1) / nv * span_v / rep), (i / nu * span_u / rep, (j + 1) / nv * span_v / rep)]
            faces.append((a, b, c, d))
            uvs.append(uv)
            faces.append(tuple(x + (nu + 1) * (nv + 1) for x in (d, c, b, a)))
            uvs.append(list(reversed(uv)))
    if rims and thick > 0:
        edges = [((i, 0), (i + 1, 0)) for i in range(nu)] + [((nu, j), (nu, j + 1)) for j in range(nv)] + \
                [((i + 1, nv), (i, nv)) for i in range(nu)] + [((0, j + 1), (0, j)) for j in range(nv)]
        for (i0, j0), (i1, j1) in edges:
            a, b = index(i0, j0, 0), index(i1, j1, 0)
            faces.append((b, a, a + (nu + 1) * (nv + 1), b + (nu + 1) * (nv + 1)))
            uvs.append([(0, 0), (.01, 0), (.01, .01), (0, .01)])
    p.add(m, verts, faces, uvs, smooth)


def arc(centre, r, a0, a1, n, plane='xz'):
    cx, cy, cz = centre
    out = []
    for i in range(n + 1):
        a = a0 + (a1 - a0) * i / n
        if plane == 'xz':
            out.append((cx + r * math.cos(a), cy, cz + r * math.sin(a)))
        elif plane == 'yz':
            out.append((cx, cy + r * math.cos(a), cz + r * math.sin(a)))
        else:
            out.append((cx + r * math.cos(a), cy + r * math.sin(a), cz))
    return out


def bezier(p0, p1, p2, p3, n=12):
    out = []
    for i in range(n + 1):
        t = i / n
        mt = 1 - t
        out.append(tuple(mt ** 3 * a + 3 * mt * mt * t * b + 3 * mt * t * t * c + t ** 3 * d
                         for a, b, c, d in zip(p0, p1, p2, p3)))
    return out


def text(p, m, words, matrix, size, font='cinzel', align='CENTER', extrude=0.0, spacing=1.0):
    """Lettering as flat (or lightly extruded) geometry in one of the game's own faces."""
    curve = bpy.data.curves.new('lettering', 'FONT')
    curve.body = words
    curve.size = size
    curve.align_x = align
    curve.align_y = 'CENTER'
    curve.space_character = spacing
    curve.extrude = extrude
    path = FONTS.get(font)
    if path and path.exists():
        curve.font = bpy.data.fonts.load(str(path), check_existing=True)
    obj = bpy.data.objects.new('lettering', curve)
    bpy.context.scene.collection.objects.link(obj)
    bpy.context.view_layer.update()
    mesh = bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()))
    verts = [matrix @ v.co for v in mesh.vertices]
    faces = [tuple(poly.vertices) for poly in mesh.polygons]
    p.add(m, verts, faces, [[(0, 0)] * len(f) for f in faces])
    bpy.data.objects.remove(obj)
    bpy.data.curves.remove(curve)
    bpy.data.meshes.remove(mesh)


def facing(x, y, z, face=(0, -1)):
    return k.facing_text(x, y, z, face)


def flat_text(x, y, z, angle=0.0):
    """A lettering matrix lying flat, reading along +X turned by `angle`, facing up."""
    return Matrix.Translation((x, y, z)) @ Matrix.Rotation(angle, 4, 'Z')


# --- saving -------------------------------------------------------------------------------------------------------
NO_OUTLINE = ('_fine', 'metal', 'glass', 'mirror', 'lamp')


def begin(asset, version, seed=None):
    """A fresh scene for one master. Refuses a saved master unless the record that made it is re-run with
    `--redo` and the master is byte-identical to what that record saved (so human edits are never overwritten)."""
    path = ROOT / 'art/source/world' / asset / version / 'model.blend'
    if path.exists():
        note = path.with_name('provenance.json')
        recorded = json.loads(note.read_text()).get('source_sha256') if note.exists() else None
        untouched = recorded == hashlib.sha256(path.read_bytes()).hexdigest()
        if '--redo' not in sys.argv or not untouched:
            raise RuntimeError('Saved editable master exists (and is not an untouched draft): ' + str(path))
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    k.M.clear()
    REPEAT.clear()
    _base_materials()
    root = bpy.data.objects.new(asset.replace('-', '_'), None)
    bpy.context.scene.collection.objects.link(root)
    return root, Parts(seed if seed is not None else sum(ord(c) * (i + 1) for i, c in enumerate(asset))), path


def finish(root, p, path, record, anchors=(), extras=None, objects_extra=None):
    p.finish(root)
    for name, at in anchors:
        empty = bpy.data.objects.new(name, None)
        empty.location = at
        bpy.context.scene.collection.objects.link(empty)
        empty.parent = root
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and any(word in obj.name for word in NO_OUTLINE):
            obj['illustrated_edges'] = False
    if objects_extra:
        objects_extra()
    scene = bpy.context.scene
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    note = {'record': str(Path(record).resolve().relative_to(ROOT)), 'kit': str((HERE / 'interior_kit.py').relative_to(ROOT)),
            'date': '2026-11-12', 'units': 'metres', 'front': 'Blender -Y', 'palette': 'textures/shops-palette.png',
            'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    note.update(extras or {})
    path.with_name('provenance.json').write_text(json.dumps(note, indent=2) + '\n')
    print('AUTHORED', path.parent.parent.name, path.parent.name, flush=True)


def run(authors, record):
    """Runs the chosen authors: `blender -b --factory-startup --python <record> -- [id ...] [--redo]`."""
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    chosen = [a for a in argv if not a.startswith('--')]
    for asset, make in authors.items():
        if not chosen or asset in chosen:
            make()


# --- small shared goods -------------------------------------------------------------------------------------------
def jar(p, at, h=.2, r=.07, fill='jam', lid='gold', label='paper', glass='glass_clear'):
    """A glass jar of something, with a lid and a paper label."""
    x, y, z = at
    lathe(p, fill, [(0, .006), (r * .9, .006), (r * .9, h * .78), (0, h * .78)], (x, y, z), 16, True)
    lathe(p, glass + '/f', [(r * .8, 0), (r, .01), (r, h * .82), (r * .78, h * .9), (r * .76, h * .92)], (x, y, z), 16, True,
          cap0=True, cap1=False)
    lathe(p, lid, [(r * .82, h * .9), (r * .84, h), (0, h * 1.02)], (x, y, z), 16, True, cap0=True, cap1=False)
    if label:
        box(p, label + '/f', (x, y - r * .97, z + h * .45), (r * 1.1, .006, h * .34), 0)


def bottle(p, at, h=.3, r=.045, colour='glass_green', cork='cork', label='paper'):
    x, y, z = at
    lathe(p, colour, [(r * .7, 0), (r, .01), (r, h * .6), (r * .45, h * .78), (r * .32, h * .84), (r * .32, h * .95)],
          (x, y, z), 14, True)
    rod(p, cork + '/f', (x, y, z + h * .93), (x, y, z + h), r * .3, 8)
    if label:
        box(p, label + '/f', (x, y - r * .98, z + h * .35), (r * 1.2, .005, h * .25), 0)


def tin(p, at, h=.16, r=.06, colour='label_red', band='gold'):
    x, y, z = at
    rod(p, colour, (x, y, z), (x, y, z + h), r, 16)
    for zz in (z + .012, z + h - .012):
        rod(p, band + '/f', (x, y, zz - .006), (x, y, zz + .006), r + .005, 16)
    rod(p, 'steel', (x, y, z + h), (x, y, z + h + .008), r * .98, 16)


def crate(p, at, w=.6, d=.4, h=.24, wood='@oak', dark='wood_dark', slats=3, label=None):
    """An open slatted crate with dark gaps and corner posts."""
    x, y, z = at
    box(p, dark + '/f', (x, y, z + .02), (w - .03, d - .03, .02), 0)
    for side in (-1, 1):
        for s in range(slats):
            zz = z + .02 + (s + .5) * (h - .02) / slats
            box(p, wood, (x, y + side * (d / 2 - .012), zz), (w, .022, (h - .02) / slats * .78), .004)
            box(p, wood, (x + side * (w / 2 - .012), y, zz), (.022, d - .04, (h - .02) / slats * .78), .004)
    for sx in (-1, 1):
        for sy in (-1, 1):
            box(p, wood, (x + sx * (w / 2 - .02), y + sy * (d / 2 - .02), z + h / 2), (.04, .04, h), .006)
    if label:
        box(p, 'chalk/f', (x, y - d / 2 - .016, z + h * .62), (min(.2, w * .4), .012, .09), .003)
        text(p, 'chalk_line/f', label, facing(x, y - d / 2 - .023, z + h * .62), .045, 'alegreya')


def basket(p, at, r=.22, h=.16, handle=True, colour='wicker', dark='wicker_dark', oval=1.0, bands=True):
    """A woven basket: ribbed wall, rolled rim, optional bow handle."""
    x, y, z = at
    lathe(p, colour, [(r * .72, 0), (r * .86, h * .3), (r, h)], (x, y, z), 20, True, cap0=True, cap1=False,
          squash=(1, oval), ripple=lambda a, zz: 1 + .035 * math.cos(a * 20))
    lathe(p, dark, [(r * .7, h * .05), (r * .7, h * .12)], (x, y, z), 20, True, cap0=False, cap1=True, squash=(1, oval))
    if oval == 1.0:
        torus(p, dark, (x, y, z + h), r, .018, seg=24, n=6)
    else:
        rim = [(x + math.cos(a) * r, y + math.sin(a) * r * oval, z + h) for a in [i * math.tau / 28 for i in range(28)]]
        tube(p, dark, rim, .018, 6, closed=True)
    if bands and oval == 1.0:
        for i in range(3):
            torus(p, dark + '/f', (x, y, z + h * (.25 + i * .22)), r * (.8 + i * .06), .008, seg=20, n=4)
    if handle:
        tube(p, dark, arc((x, y, z + h), r * .95, 0, math.pi, 10, 'xz'), .014, 6)


# --- joinery helpers ----------------------------------------------------------------------------------------------
def panel(p, mat, x, y, z, w, h, frame=.06, depth=.03, trim=None, knob=None, knob_at=None, inset_mat=None):
    """A framed, fielded panel whose front face is the plane y (facing -y): stiles, rails, a sunk field with a raised
    centre, an optional gilt line and a knob."""
    box(p, mat, (x - w / 2 + frame / 2, y + depth / 2, z), (frame, depth, h), .006)
    box(p, mat, (x + w / 2 - frame / 2, y + depth / 2, z), (frame, depth, h), .006)
    box(p, mat, (x, y + depth / 2, z + h / 2 - frame / 2), (w - frame * 2 + .002, depth, frame), .006)
    box(p, mat, (x, y + depth / 2, z - h / 2 + frame / 2), (w - frame * 2 + .002, depth, frame), .006)
    box(p, inset_mat or mat, (x, y + depth * .8, z), (w - frame * 2, depth * .4, h - frame * 2), 0)
    box(p, inset_mat or mat, (x, y + depth * .45, z), (w - frame * 3.2, depth * .3, h - frame * 3.2), .004)
    if trim:
        t = .008
        iw, ih = w - frame * 3.6, h - frame * 3.6
        ty = y + depth * .3 - .006   # the gilt line stands 6 mm proud of the raised field, never in its plane
        for dx in (-1, 1):
            box(p, trim + '/f' if not trim.startswith(('@', '#')) else trim, (x + dx * iw / 2, ty, z), (t, .004, ih), 0)
        for dz in (-1, 1):
            box(p, trim + '/f' if not trim.startswith(('@', '#')) else trim, (x, ty, z + dz * ih / 2), (iw + t, .004, t), 0)
    if knob:
        kx, kz = knob_at if knob_at else (x, z)
        lathe(p, knob, [(0, 0), (.012, 0), (.008, .015), (.02, .03), (0, .036)], (kx, y, kz), 10, True,
              axis=Matrix.Rotation(math.pi / 2, 3, 'X'))


def leg(p, mat, x, y, z0, z1, r=.035, style='turned'):
    """A turned table leg with a block at the top, beads and a tapered foot."""
    h = z1 - z0
    if style == 'turned':
        prof = [(r * .7, 0), (r * .85, h * .04), (r * .75, h * .08), (r * .55, h * .3), (r * .62, h * .5), (r * .9, h * .62),
                (r * .9, h * .66), (r * .6, h * .7), (r * .75, h * .74), (r * .75, h * .78)]
        lathe(p, mat, prof, (x, y, z0), 12, True)
        box(p, mat, (x, y, z0 + h * .89), (r * 2, r * 2, h * .22), .006)
    else:
        lathe(p, mat, [(r * .6, 0), (r, h)], (x, y, z0), 10, True)


def cornice(p, mat, cx, width, y_front, depth, z, steps=((.0, .04, .05), (.025, .05, .03), (.05, .025, .025))):
    """Stepped moulding along x on top of a carcass whose front face is y_front: (outset, height, ...)."""
    zz = z
    for out, h, _ in steps:
        box(p, mat, (cx, y_front - out + depth / 2, zz + h / 2), (width + out * 2, depth + out * 2 if False else depth + out, h), .006)
        zz += h
    return zz


def plate(p, at, r=.11, colour='china', rim='china_blue', facing_y=True, tilt=.25):
    """A plate standing on a rail (facing -y, leaning back by `tilt`), with a painted rim and centre motif."""
    x, y, z = at
    rot = Matrix.Rotation(math.pi / 2 - tilt, 3, 'X')
    lathe(p, colour, [(0, 0), (r * .6, 0), (r, .012), (r, .016), (r * .62, .006), (0, .006)], (x, y, z + r), 20, True,
          axis=rot, cap0=False, cap1=False)
    torus(p, rim + '/f', (x, y - .0145 * math.cos(tilt) + .001, z + r + .0145 * math.sin(tilt) * 0), r * .86, .007,
          normal=(0, -math.cos(tilt), math.sin(tilt)), seg=20, n=4)
    lathe(p, rim + '/f', [(0, 0), (r * .25, 0), (0, .001)], (x, y - .008, z + r), 10, False, axis=rot)


def cup(p, at, r=.035, h=.06, colour='china', rim='china_blue', saucer=True, liquid='tea_liquid', angle=0.0):
    x, y, z = at
    if saucer:
        lathe(p, colour, [(0, 0), (r * 1.2, 0), (r * 1.9, .012), (r * 1.9, .015), (0, .008)], (x, y, z), 18, True, cap0=False)
        z += .008
    lathe(p, colour, [(r * .6, 0), (r * .85, h * .2), (r, h), (r * .9, h), (r * .8, h * .3), (0, h * .25)], (x, y, z), 16,
          True, cap0=True, cap1=False)
    if liquid:
        lathe(p, liquid + '/f', [(0, h * .8), (r * .93, h * .8), (0, h * .81)], (x, y, z), 14, False)
    torus(p, rim + '/f', (x, y, z + h), r * .97, .0035, seg=16, n=4)
    hx, hy = math.cos(angle), math.sin(angle)
    tube(p, colour, [(x + hx * r * .95, y + hy * r * .95, z + h * .8), (x + hx * r * 1.45, y + hy * r * 1.45, z + h * .7),
                     (x + hx * r * 1.45, y + hy * r * 1.45, z + h * .35), (x + hx * r * .9, y + hy * r * .9, z + h * .3)],
         .006, 5)


def teapot(p, at, r=.07, colour='china_blue', angle=0.0):
    x, y, z = at
    lathe(p, colour, [(0, 0), (r * .7, 0), (r, r * .6), (r * .95, r * 1.1), (r * .55, r * 1.35), (r * .5, r * 1.4)], (x, y, z),
          18, True, cap0=False, cap1=True)
    lathe(p, colour, [(r * .52, r * 1.4), (r * .45, r * 1.5), (r * .1, r * 1.6), (0, r * 1.6)], (x, y, z), 14, True, cap0=False)
    ball(p, 'white/f', (x, y, z + r * 1.68), r * .12)
    c, s_ = math.cos(angle), math.sin(angle)
    tube(p, colour, [(x + c * r * .8, y + s_ * r * .8, z + r * .5), (x + c * r * 1.25, y + s_ * r * 1.25, z + r * .8),
                     (x + c * r * 1.5, y + s_ * r * 1.5, z + r * 1.25)], .016, 6, radii=[.02, .015, .01])
    tube(p, colour, [(x - c * r * .85, y - s_ * r * .85, z + r * 1.15), (x - c * r * 1.35, y - s_ * r * 1.35, z + r * 1.1),
                     (x - c * r * 1.4, y - s_ * r * 1.4, z + r * .55), (x - c * r * .9, y - s_ * r * .9, z + r * .4)], .012, 5)


# --- room shells --------------------------------------------------------------------------------------------------
# A shop room is a 12 x 12 cutaway: floor -0.5..11.5, the west wall (inner face x -0.5) and the north wall (inner face
# y 11.5) standing 4.1 m, the front (y -0.5) and east (x 11.5) open, the shop's glazed door at x 6 on the front.
NORTH = {'axis': 'x', 'plane': 11.5, 'into': -1, 'span': (-.5, 11.5)}
WEST = {'axis': 'y', 'plane': -.5, 'into': 1, 'span': (-.5, 11.5)}
HEIGHT = 4.1


def _cut(span, holes):
    """Pieces of span [a, b] left after removing hole intervals."""
    pieces = [span]
    for h0, h1 in holes:
        out = []
        for a, b in pieces:
            if h1 <= a or h0 >= b:
                out.append((a, b))
                continue
            if h0 > a:
                out.append((a, h0))
            if h1 < b:
                out.append((h1, b))
        pieces = out
    return [(a, b) for a, b in pieces if b - a > .004]


def strip(p, mat, wall, z0, z1, near, far, openings=(), span=None, bevel=.004, uv='world'):
    """A layer on a wall between heights z0..z1, from `far` to `near` metres into the room (negative is behind the
    face), with rectangular openings [(centre, width, bottom, top)] cut out of it."""
    a, b = span or wall['span']
    rects = [(a, b, z0, z1)]
    for c, w, o0, o1 in openings:
        h0, h1 = c - w / 2, c + w / 2
        out = []
        for x0, x1, y0, y1 in rects:
            if h1 <= x0 or h0 >= x1 or o1 <= y0 or o0 >= y1:
                out.append((x0, x1, y0, y1))
                continue
            if h0 > x0:
                out.append((x0, h0, y0, y1))
            if h1 < x1:
                out.append((h1, x1, y0, y1))
            m0, m1 = max(x0, h0), min(x1, h1)
            if o0 > y0:
                out.append((m0, m1, y0, o0))
            if o1 < y1:
                out.append((m0, m1, o1, y1))
        rects = [r for r in out if r[1] - r[0] > .004 and r[3] - r[2] > .004]
    d0, d1 = sorted((near, far))
    for x0, x1, zz0, zz1 in rects:
        mid_in = (d0 + d1) / 2
        depth = d1 - d0
        if wall['axis'] == 'x':
            at = ((x0 + x1) / 2, wall['plane'] + wall['into'] * mid_in, (zz0 + zz1) / 2)
            size = (x1 - x0, depth, zz1 - zz0)
        else:
            at = (wall['plane'] + wall['into'] * mid_in, (x0 + x1) / 2, (zz0 + zz1) / 2)
            size = (depth, x1 - x0, zz1 - zz0)
        p.box(mat, at, size, bevel=bevel, uv=uv)


def on_wall(wall, along, into, z):
    """A room point on a wall: `along` the wall, `into` the room from its face, at height z."""
    if wall['axis'] == 'x':
        return (along, wall['plane'] + wall['into'] * into, z)
    return (wall['plane'] + wall['into'] * into, along, z)


def wall_box(p, mat, wall, along, into, z, size_along, size_into, size_z, b=.008):
    if wall['axis'] == 'x':
        box(p, mat, on_wall(wall, along, into, z), (size_along, size_into, size_z), b)
    else:
        box(p, mat, on_wall(wall, along, into, z), (size_into, size_along, size_z), b)


def wall_facing(wall):
    return (0, -1) if wall['axis'] == 'x' else (1, 0)


def wall_text(p, mat, words, wall, along, into, z, size, font='cinzel', spacing=1.0):
    fx, fy = wall_facing(wall)
    x, y, zz = on_wall(wall, along, into, z)
    text(p, mat, words, k.facing_text(x, y, zz, (fx, fy)), size, font, spacing=spacing)


def window(p, wall, c, w, z0, z1, frame='@oak', sill='@oak', bars=(2, 3), glass='shops_clear_glass', depth=.24):
    """A glazed sash in an opening: jambs, head, a deep sill into the room, glazing bars and a pane."""
    fw = .07
    wall_box(p, frame, wall, c - w / 2 + fw / 2, -depth / 2, (z0 + z1) / 2, fw, depth, z1 - z0)
    wall_box(p, frame, wall, c + w / 2 - fw / 2, -depth / 2, (z0 + z1) / 2, fw, depth, z1 - z0)
    wall_box(p, frame, wall, c, -depth / 2, z1 - fw / 2, w - fw * 2, depth, fw)
    wall_box(p, sill, wall, c, .02, z0 - .02, w + .16, .3, .06)
    wall_box(p, frame, wall, c, -depth * .55, z0 + .03, w - fw * 2, .08, .06)
    cols, rows = bars
    inner_w, inner_h = w - fw * 2, z1 - z0 - fw - .06
    for i in range(1, cols):
        wall_box(p, frame, wall, c - inner_w / 2 + inner_w * i / cols, -depth * .55, z0 + .06 + inner_h / 2, .035, .05, inner_h)
    for j in range(1, rows):
        wall_box(p, frame, wall, c, -depth * .55, z0 + .06 + inner_h * j / rows, inner_w, .05, .035)
    fx, fy = wall_facing(wall)
    centre = on_wall(wall, c, -depth * .62, z0 + .06 + inner_h / 2)
    p.pane(glass, centre, inner_w, inner_h, (fx, fy))


def front_door(p, shop, colour, trim, brass='brass'):
    """The shop's glazed front door at x 6 (hinged on `door_leaf_<shop>` at x 5.33), in the shopfront's colour,
    with a fanlight. Same opening and hinge as the first rooms, so the square's door link is unchanged."""
    door = '#' + colour
    for x in [5.23, 6.77]:
        box(p, door, (x, -.42, 1.45), (.16, .2, 2.9), .015)
    box(p, door, (6, -.42, 2.87), (1.72, .2, .16), .015)
    box(p, trim, (6, -.42, 3.02), (1.9, .24, .1), .01)
    box(p, door, (6, -.42, 2.62), (1.3, .16, .06))
    p.pane('shops_clear_glass', (6, -.40, 2.74), 1.26, .2, (0, -1))
    for i in range(5):
        a = math.pi * (i + 1) / 6
        box(p, trim, (6 + math.cos(a) * .3, -.4, 2.66 + math.sin(a) * .12), (.02, .03, .1), 0, rot=(0, -(a - math.pi / 2), 0))
    with p.into(f'door_leaf_{shop}'):
        for x in [5.38, 6.62]:
            box(p, door, (x, -.42, 1.27), (.1, .1, 2.48))
        for z in [.08, .92, 2.47]:
            box(p, door, (6, -.42, z), (1.28, .1, .12))
        box(p, door, (6, -.42, .5), (1.12, .07, .74))
        box(p, trim, (6, -.47, .5), (.9, .02, .5), .004)
        p.pane('shops_clear_glass', (6, -.42, 1.70), 1.12, 1.48, (0, -1))
        box(p, door, (6, -.42, 1.70), (.04, .08, 1.48))
        box(p, brass, (6.5, -.5, 1.14), (.05, .05, .26))
        box(p, brass, (6, -.48, .85), (.32, .02, .07), .004)
        box(p, brass, (6, -.36, .25), (1.0, .012, .26), .003)


def hinge_doors(shop):
    """Moves each door leaf's pivot onto its hinge after `finish` has made the objects."""
    hinge = Vector((5.33, -.42, 0))
    for obj in bpy.context.scene.objects:
        if obj.name.startswith('door_leaf'):
            for v in obj.data.vertices:
                v.co -= hinge
            obj.location = hinge
            obj['swing'] = -95


def floor(p, name, repeat):
    box(p, 'wood_dark', (5.5, 5.5, -.14), (12, 12, .22), .01)
    for x in range(4):
        for y in range(4):
            p.box(surface(name), (x * 3 + 1, y * 3 + 1, -.0125), (3, 3, .025), bevel=0, uv='world', repeat=repeat)


def beams(p, mat='@oak'):
    """Ceiling beams along the two cut edges, with brackets, so the room does not float."""
    box(p, mat, (-.55, 5.5, 4.08), (.34, 12.3, .24), .02)
    box(p, mat, (5.5, 11.55, 4.08), (12.3, .34, .24), .02)
    # Brackets stand 1 cm off the plaster, so their backs never share its plane.
    for y in (1.5, 5.5, 9.5):
        p.solid(surface(mat[1:]) if mat.startswith('@') else mat, [(-.49, y - .08, 3.96), (-.49, y - .08, 3.66), (-.2, y - .08, 3.96)],
                .16, (0, -1, 0))
    for x in (1.5, 5.5, 9.5):
        p.solid(surface(mat[1:]) if mat.startswith('@') else mat, [(x - .08, 11.49, 3.96), (x - .08, 11.49, 3.66), (x - .08, 11.2, 3.96)],
                .16, (-1, 0, 0))


def attach(seed):
    """Registers the kit's materials in an already-open master for a deliberate source edit, without clearing it.
    Existing materials stay in `k.M` under their own names, so a record can reuse them too."""
    k.M.clear()
    REPEAT.clear()
    for mat in bpy.data.materials:
        k.M[mat.name] = mat
    _base_materials()
    return Parts(seed)


def arched_text(p, mat, words, centre, radius, size, span, face=(0, -1), font='cinzel', lift=0.0):
    """Lettering set on an arc (signwriting on shop glass): characters spread over `span` radians round `centre`."""
    x, y, z = centre
    n = len(words)
    for i, ch in enumerate(words):
        if ch == ' ':
            continue
        t = (i - (n - 1) / 2) / max(1, n - 1)
        a = -t * span
        px = x + math.sin(-a) * radius * (1 if face == (0, -1) else 0)
        pz = z + math.cos(a) * radius - radius + lift
        m = k.facing_text(px, y, pz, face) @ Matrix.Rotation(a, 4, 'Z')
        text(p, mat, ch, m, size, font)
