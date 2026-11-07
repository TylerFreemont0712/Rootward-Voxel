"""Initial authoring record for the three market shop interiors: Morning Loaf (baker), The Pantry (grocer) and
Finch & Thread (tailor and haberdasher). Original models, registered individually so the layout studio and later
rooms can reuse them. Refuses saved masters: after adoption, edit each model.blend and use the normal world build.

    blender -b --factory-startup --python author.py

Room shells follow the clockshop's convention: a 12 x 12 m cutaway, floor from -0.5 to 11.5, the west and north walls
standing, the front open with the shop's own glazed door at x 6 (its leaf hinged on `door_leaf_<shop>`). Each door
is painted in its shopfront's colour so walking in from the square reads as the same door.
"""
from pathlib import Path
import sys, math, json, hashlib
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / 'art/source/world/seaside-houses/v1'))
import house_kit as k

NATIVE = ROOT / 'art/source/world/textures/v2-detail/native'
TOWN = ROOT / 'art/source/world/town-ground/v1/native'
OAK = ROOT / 'assets/world/textures/seaside-houses/detail/seaside_timber_oak.png'
for picture in [NATIVE / 'terracotta_tile.png', NATIVE / 'herringbone_oak.png', NATIVE / 'red_brick.png', TOWN / 'town_flags.png', OAK]:
    if not picture.exists():
        raise RuntimeError('Missing source painting ' + str(picture))

FLAT = {
    'ink': '252a28', 'iron': '3a3f40', 'brass': 'b58a42', 'steel': '6a7678', 'chalk': '2a332f', 'paper': 'efe6cf',
    'flour': 'f1ece0', 'sack': 'c9b48a', 'crust': 'b5733a', 'crust_dark': '8d5126', 'crumb': 'e9cf9a', 'dough': 'eedcb6',
    'cream': 'f4ead2', 'jam': 'a3302f', 'apple': 'b8362a', 'apple_green': '8fae3e', 'orange': 'e2892a', 'lemon': 'e9c94a',
    'cabbage': '6f9a45', 'leaf': '4e7d36', 'carrot': 'd8722a', 'potato': 'b89668', 'onion': 'c58a4e', 'plum': '6d3557',
    'jar_glass': 'bfd5c9', 'tin_red': 'a8473c', 'tin_blue': '45648a', 'tin_gold': 'c49a3b', 'wood_dark': '4a3324',
    'wood_mid': '7a5236', 'linen': 'e6dcc6', 'felt': '49645a', 'mirror': 'b9c9cc', 'pin': 'c94f4f',
}
CLOTH = ['8a3b46', '3c5e7e', 'c9a14a', '5d7a52', 'b9786a', '2f3a4f', 'd8c7a0', '7b5b8f', 'a4542f', '6d8f8c']
SHOPS = {
    # floor painting, floor repeat, wall plaster, wainscot, door/frame colour, trim, rear windows (x centres)
    'bakery': {'floor': NATIVE / 'terracotta_tile.png', 'repeat': 1.6, 'wall': 'efe2c4', 'wainscot': '2c6a5f', 'door': '2c6a5f', 'trim': 'c08a3e', 'windows': [8.6], 'side_windows': [3.2]},
    'pantry': {'floor': TOWN / 'town_flags.png', 'repeat': 3.0, 'wall': 'e7e4cf', 'wainscot': '3e7766', 'door': '3e7766', 'trim': 'd8c79a', 'windows': [6.0], 'side_windows': [7.6]},
    'tailor': {'floor': NATIVE / 'herringbone_oak.png', 'repeat': 1.5, 'wall': 'e3c6bd', 'wainscot': '4f6890', 'door': '4f6890', 'trim': 'd7c08a', 'windows': [6.4], 'side_windows': [6.5]},
}


def begin(asset):
    path = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    if path.exists():
        raise RuntimeError('Saved editable source exists: ' + asset)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    k.M.clear()
    for name, colour in FLAT.items():
        k.material('shop_' + name, colour, roughness=.8 if name not in ('brass', 'steel', 'iron') else .45, metallic=.55 if name in ('brass', 'steel') else 0.0)
    for index, colour in enumerate(CLOTH):
        k.material(f'shop_cloth_{index}', colour, roughness=.95)
    k.material('shop_oak', 'ffffff', OAK, roughness=.66)
    k.material('shop_brick', 'ffffff', NATIVE / 'red_brick.png', roughness=.9)
    for shop, spec in SHOPS.items():
        k.material(f'shop_{shop}_floor', 'ffffff', spec['floor'], roughness=.8)
        k.material(f'shop_{shop}_wall', spec['wall'], roughness=.93)
        k.material(f'shop_{shop}_wainscot', spec['wainscot'], roughness=.74)
        k.material(f'shop_{shop}_door', spec['door'], roughness=.7)
        k.material(f'shop_{shop}_trim', spec['trim'], roughness=.6)
    glass = k.material('shop_clear_glass', 'e6eee5', roughness=.15)
    bsdf = next(n for n in glass.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Alpha'].default_value = .12
    glass.surface_render_method = 'BLENDED'
    k.material('shop_lamp_glass', 'ffcf8a', roughness=.3, emission=.9)
    root = bpy.data.objects.new(asset.replace('-', '_'), None)
    bpy.context.scene.collection.objects.link(root)
    return root, k.Parts(sum(ord(c) for c in asset)), path


def finish(root, p, path, anchors=()):
    p.finish(root)
    for name, at in anchors:
        bpy.ops.object.empty_add(type='PLAIN_AXES', location=at)
        bpy.context.object.name = name
        bpy.context.object.parent = root
    for obj in bpy.context.scene.objects:
        if obj.type == 'MESH' and any(word in obj.name for word in ('brass', 'steel', 'clear_glass', 'lamp_glass', 'ink', 'pin')):
            obj['illustrated_edges'] = False
    path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.preferences.filepaths.save_version = 0
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    path.with_name('provenance.json').write_text(json.dumps({'record': str(Path(__file__).relative_to(ROOT)), 'units': 'metres',
        'front': 'Blender -Y', 'source_sha256': hashlib.sha256(path.read_bytes()).hexdigest()}, indent=2) + '\n')
    print('AUTHORED', path.parent.parent.name)


def box(p, mat, at, size, b=.012, rot=(0, 0, 0)):
    p.box('shop_' + mat, at, size, rot=rot, bevel=b)


def rod(p, mat, a, b, r=.015, n=12, rb=None):
    p.cylinder('shop_' + mat, a, b, r, n, radius_b=rb)


def ball(p, mat, at, r, squash=(1, 1, 1)):
    p.sphere('shop_' + mat, at, r, 1, squash)


def feet(p, xs, ys, h, mat='oak'):
    for x in xs:
        for y in ys:
            box(p, mat, (x, y, h / 2), (.09, .09, h), .015)


def loaf(p, x, y, z, length=.32, kind='tin'):
    if kind == 'round':
        ball(p, 'crust', (x, y, z + .07), .11, (1, 1, .62))
        for i in (-1, 0, 1):
            box(p, 'crumb', (x + i * .05, y - .02, z + .135), (.012, .14, .01), 0, rot=(0, 0, .5))
    elif kind == 'baguette':
        rod(p, 'crust', (x - length, y, z + .04), (x + length, y, z + .04), .042, 10)
    else:
        box(p, 'crust', (x, y, z + .06), (length, .16, .12), .04)
        ball(p, 'crust_dark', (x, y, z + .12), .09, (length / .18, .9, .45))


# ------------------------------------------------------------------------------------------------- the rooms
def shell(shop):
    spec = SHOPS[shop]
    root, p, path = begin(f'{shop}-shell')
    # The subfloor's cap stays 3 cm below the floor painting, so the two never share a plane.
    box(p, 'wood_dark', (5.5, 5.5, -.14), (12, 12, .22), .01)
    for x in range(4):
        for y in range(4):
            p.box(f'shop_{shop}_floor', (x * 3 + 1, y * 3 + 1, -.0125), (3, 3, .025), bevel=0, uv='world', repeat=spec['repeat'])
    wall, wains, trim, door = f'{shop}_wall', f'{shop}_wainscot', f'{shop}_trim', f'{shop}_door'
    # The west wall, with a high side window, and the north wall with the rear window.
    sw = spec['side_windows'][0]
    for y0, y1 in [(-.5, sw - .8), (sw + .8, 11.7)]:
        box(p, wall, (-.62, (y0 + y1) / 2, 2.05), (.24, y1 - y0, 4.1), .015)
    box(p, wall, (-.62, sw, .85), (.24, 1.6, 1.7), .015)
    box(p, wall, (-.62, sw, 3.75), (.24, 1.6, .7), .015)
    rw = spec['windows'][0]
    for x0, x1 in [(-.5, rw - 1.0), (rw + 1.0, 11.5)]:
        box(p, wall, ((x0 + x1) / 2, 11.62, 2.05), (x1 - x0, .24, 4.1), .015)
    box(p, wall, (rw, 11.62, .85), (2.0, .24, 1.7), .015)
    box(p, wall, (rw, 11.62, 3.75), (2.0, .24, .7), .015)
    for x, y, w, d, facing in [(rw, 11.5, 2.0, .2, (0, -1)), (-.5, sw, .2, 1.6, (1, 0))]:
        frame = [(x - w / 2 + .05, y, 2.55, .1, d, 1.7), (x + w / 2 - .05, y, 2.55, .1, d, 1.7)] if facing == (0, -1) else \
                [(x, y - d / 2 + .05, 2.55, .2, .1, 1.7), (x, y + d / 2 - .05, 2.55, .2, .1, 1.7)]
        for fx, fy, fz, sx, sy, sz in frame:
            box(p, 'oak', (fx, fy, fz), (sx, sy, sz))
        if facing == (0, -1):
            box(p, 'oak', (x, y - .08, 1.72), (w, .3, .08))
            box(p, 'oak', (x, y, 3.4), (w, .2, .1))
            box(p, 'oak', (x, y, 2.55), (.06, .12, 1.6))
            box(p, 'oak', (x, y, 2.55), (w - .1, .12, .05))
            p.pane('shop_clear_glass', (x, y + .02, 2.55), w - .2, 1.6, (0, -1))
        else:
            box(p, 'oak', (x + .08, y, 1.72), (.3, d, .08))
            box(p, 'oak', (x, y, 3.4), (.2, d, .1))
            box(p, 'oak', (x, y, 2.55), (.12, .06, 1.6))
            p.pane('shop_clear_glass', (x + .02, y, 2.55), d - .2, 1.6, (1, 0))
    # Wainscot panels in the shopfront colour, dado and picture rails, skirting.
    for n in range(12):
        box(p, wains, (n, 11.48, .62), (.86, .06, .9))
        box(p, trim, (n - .5, 11.46, .62), (.05, .08, 1.0))
        if not (sw - .9 < n < sw + .9):
            box(p, wains, (-.48, n, .62), (.06, .86, .9))
            box(p, trim, (-.46, n - .5, .62), (.08, .05, 1.0))
    for z, h in [(.07, .14), (1.15, .07), (3.2, .06)]:
        box(p, trim, (5.5, 11.45, z), (12, .1, h))
        box(p, trim, (-.45, 5.5, z), (.1, 12, h))
    # A beamed ceiling line along the cut edge keeps the room from floating.
    box(p, 'oak', (-.5, 5.5, 4.05), (.3, 12.2, .22))
    box(p, 'oak', (5.5, 11.5, 4.05), (12.2, .3, .22))
    # The shop's own glazed door, in its shopfront colour, with a fanlight and brass furniture.
    for x in [5.23, 6.77]:
        box(p, door, (x, -.42, 1.45), (.16, .2, 2.9), .015)
    box(p, door, (6, -.42, 2.87), (1.72, .2, .16), .015)
    box(p, trim, (6, -.42, 3.02), (1.9, .24, .1), .01)
    box(p, door, (6, -.42, 2.62), (1.3, .16, .06))
    p.pane('shop_clear_glass', (6, -.40, 2.74), 1.26, .2, (0, -1))
    with p.into(f'door_leaf_{shop}'):
        for x in [5.38, 6.62]:
            box(p, door, (x, -.42, 1.27), (.1, .1, 2.48))
        for z in [.08, .92, 2.47]:
            box(p, door, (6, -.42, z), (1.28, .1, .12))
        box(p, door, (6, -.42, .5), (1.12, .07, .74))
        box(p, trim, (6, -.47, .5), (.9, .02, .5), .004)
        p.pane('shop_clear_glass', (6, -.42, 1.70), 1.12, 1.48, (0, -1))
        box(p, door, (6, -.42, 1.70), (.04, .08, 1.48))
        box(p, 'brass', (6.5, -.5, 1.14), (.05, .05, .26))
        box(p, 'brass', (6, -.48, .85), (.32, .02, .07), .004)
    p.finish(root)
    hinge = Vector((5.33, -.42, 0))
    for obj in bpy.context.scene.objects:
        if obj.name.startswith('door_leaf'):
            for v in obj.data.vertices:
                v.co -= hinge
            obj.location = hinge
            obj['swing'] = -95
    finish(root, k.Parts(1), path)


# --------------------------------------------------------------------------------------------- Morning Loaf
def oven():
    """A domed brick bread oven with an arched iron door, an ash shelf and a flue; the fire shows through the door."""
    root, p, path = begin('bakery-oven')
    box(p, 'brick', (0, 0, .45), (2.6, 1.8, .9), .02)
    box(p, 'oak', (0, -.88, .92), (2.7, .14, .08))
    for i in range(10):
        a0 = math.pi * i / 10
        a1 = math.pi * (i + 1) / 10
        r = 1.1
        pts = [(math.cos(a0) * r, -.85, .95 + math.sin(a0) * r * .78), (math.cos(a1) * r, -.85, .95 + math.sin(a1) * r * .78),
               (math.cos(a1) * r, .85, .95 + math.sin(a1) * r * .78), (math.cos(a0) * r, .85, .95 + math.sin(a0) * r * .78)]
        p.solid('shop_brick', pts, .22, (math.cos((a0 + a1) / 2), 0, math.sin((a0 + a1) / 2)))
    p.prism('shop_brick', [(-1.1, -.85), (1.1, -.85), (1.1, .85), (-1.1, .85)], .9, .97)
    for x in (-1.1, 1.1):
        p.prism('shop_brick', [(x - .02, -.85), (x + .02, -.85), (x + .02, .85), (x - .02, .85)], .95, 1.0)
    # Arched door opening: iron frame, a lit mouth (lamp glass, so the room can switch it with the town's fixtures)
    rod(p, 'iron', (-.38, -.93, 1.12), (.38, -.93, 1.12), .05, 10)
    for x in (-.4, .4):
        box(p, 'iron', (x, -.93, 1.32), (.07, .07, .45))
    p.solid('shop_lamp_glass', [(-.33, -.9, 1.12), (.33, -.9, 1.12), (.33, -.9, 1.45), (0, -.9, 1.62), (-.33, -.9, 1.45)], .03, (0, -1, 0))
    box(p, 'iron', (.55, -.94, 1.3), (.3, .04, .4))
    rod(p, 'brass', (.66, -.99, 1.3), (.66, -1.05, 1.3), .03, 8)
    # Flue and hood.
    box(p, 'brick', (0, .45, 2.0), (.62, .62, .5), .02)
    rod(p, 'iron', (0, .45, 2.2), (0, .45, 3.9), .16, 16)
    rod(p, 'iron', (0, .45, 2.6), (0, .45, 2.66), .2, 16)
    # Peel and wood store underneath.
    for i in range(6):
        rod(p, 'wood_mid', (-1.15, -.6 + i * .12, .3 + (i % 2) * .1), (-.35, -.6 + i * .12, .3 + (i % 2) * .1), .05, 7)
    rod(p, 'oak', (1.2, -.95, .2), (1.2, -.95, 2.0), .02, 8)
    box(p, 'oak', (1.2, -.98, 2.12), (.34, .02, .3), .01)
    finish(root, p, path)


def bread_rack():
    """Open oak rack against a wall: five slatted shelves of tin loaves, rounds and baguettes in a basket."""
    root, p, path = begin('bakery-bread-rack')
    for x in (-1.2, 1.2):
        for y in (-.18, .18):
            box(p, 'oak', (x, y, 1.15), (.07, .07, 2.3))
    box(p, 'oak', (0, .2, 1.15), (2.45, .04, 2.2))
    kinds = ['tin', 'round', 'tin', 'round', 'baguette']
    for n, z in enumerate([.3, .72, 1.14, 1.56, 1.98]):
        for s in range(5):
            box(p, 'oak', (0, -.16 + s * .08, z), (2.4, .06, .03), .004)
        kind = kinds[n]
        count = 5 if kind != 'baguette' else 3
        for i in range(count):
            x = -.95 + i * (1.9 / (count - 1))
            loaf(p, x, 0, z + .015, .3 if kind == 'tin' else .45, kind)
    box(p, 'paper', (0, -.22, 2.3), (.8, .02, .18), .004)
    k.text(p, 'shop_ink', 'TODAY', k.facing_text(0, -.24, 2.3, (0, -1)), .12)
    finish(root, p, path)


def bakery_counter():
    """Glass-fronted serving counter: cakes and buns under glass, a brass till and a cake stand on top."""
    root, p, path = begin('bakery-counter')
    box(p, 'oak', (0, .15, .45), (3.0, .7, .9), .02)
    for x in (-1.0, 0, 1.0):
        box(p, 'bakery_door', (x, -.21, .45), (.86, .03, .64), .01)
        box(p, 'bakery_trim', (x, -.23, .45), (.7, .01, .48), .004)
    box(p, 'oak', (0, 0, .93), (3.1, 1.0, .07))
    for x in (-1.45, 1.45):
        for y in (-.42, .42):
            rod(p, 'brass', (x, y, .96), (x, y, 1.42), .02, 8)
    p.pane('shop_clear_glass', (0, -.45, 1.19), 2.85, .44, (0, -1))
    p.solid('shop_clear_glass', [(-1.42, -.45, 1.42), (1.42, -.45, 1.42), (1.42, .2, 1.42), (-1.42, .2, 1.42)], .006, (0, 0, 1))
    box(p, 'brass', (0, -.45, 1.43), (2.95, .03, .03))
    for i in range(6):
        x = -1.15 + i * .46
        box(p, 'paper', (x, -.15, .975), (.34, .3, .01), 0)
        if i % 2 == 0:
            for j in range(3):
                ball(p, 'crust', (x - .1 + j * .1, -.15, 1.02), .055, (1, 1, .7))
                ball(p, 'cream', (x - .1 + j * .1, -.15, 1.06), .03)
        else:
            rod(p, 'crumb', (x, -.15, .98), (x, -.15, 1.08), .13, 16)
            rod(p, 'cream', (x, -.15, 1.08), (x, -.15, 1.1), .13, 16)
            ball(p, 'jam', (x, -.15, 1.12), .03)
    # Till and cake stand on the open end.
    box(p, 'brass', (1.1, .25, 1.12), (.45, .4, .3), .03)
    box(p, 'ink', (1.1, .06, 1.32), (.38, .05, .14), .01)
    rod(p, 'brass', (-1.0, .25, .97), (-1.0, .25, 1.15), .03, 10)
    rod(p, 'cream', (-1.0, .25, 1.15), (-1.0, .25, 1.18), .2, 20)
    rod(p, 'crumb', (-1.0, .25, 1.18), (-1.0, .25, 1.34), .16, 20)
    rod(p, 'cream', (-1.0, .25, 1.34), (-1.0, .25, 1.37), .16, 20)
    for a in range(8):
        ball(p, 'jam', (-1.0 + math.cos(a * .785) * .11, .25 + math.sin(a * .785) * .11, 1.39), .022)
    finish(root, p, path)


def proving_table():
    """Floury work table with dough rising in bowls, a rolling pin, scales and a stack of tins."""
    root, p, path = begin('bakery-proving-table')
    feet(p, (-1.0, 1.0), (-.4, .4), .86)
    box(p, 'oak', (0, 0, .9), (2.3, 1.0, .08))
    box(p, 'oak', (0, 0, .25), (2.1, .85, .04))
    box(p, 'flour', (-.3, -.05, .945), (1.2, .7, .006), 0)
    for x in (-.65, .05):
        rod(p, 'cream', (x, .1, .94), (x, .1, 1.08), .17, 18, .21)
        ball(p, 'dough', (x, .1, 1.08), .16, (1, 1, .55))
    rod(p, 'oak', (-.6, -.3, .97), (.2, -.3, .97), .04, 10)
    for x0, x1 in ((-.75, -.6), (.2, .35)):
        rod(p, 'oak', (x0, -.3, .97), (x1, -.3, .97), .02, 8)
    box(p, 'brass', (.75, .15, 1.0), (.36, .26, .16), .02)
    rod(p, 'brass', (.75, .15, 1.08), (.75, .15, 1.12), .16, 16)
    for i in range(4):
        box(p, 'steel', (.8, -.25, .97 + i * .065), (.32, .18, .06), .01)
    for i in range(3):
        box(p, 'sack', (-.2 + i * .45, 0, .32), (.38, .55, .1), .03)
    finish(root, p, path)


def flour_sacks():
    root, p, path = begin('bakery-flour-sacks')
    spots = [(-.45, 0, 0), (.45, .05, 0), (0, .3, 0), (-.05, -.05, .55)]
    for x, y, z in spots:
        ball(p, 'sack', (x, y, z + .32), .34, (1, .75, 1.05))
        rod(p, 'sack', (x, y, z + .6), (x, y, z + .74), .12, 10, .06)
        rod(p, 'ink', (x, y, z + .66), (x, y, z + .69), .125, 10)
        box(p, 'paper', (x, y - .26, z + .32), (.24, .01, .2), 0)
    box(p, 'flour', (0, -.4, .006), (1.4, .5, .012), 0)
    rod(p, 'brass', (.6, -.5, .02), (.6, -.5, .14), .12, 14, .16)
    finish(root, p, path)


# ------------------------------------------------------------------------------------------------- The Pantry
def crate(p, x, y, z, w=.6, d=.42, h=.26, tilt=0.0):
    box(p, 'oak', (x, y, z + h / 2), (w, d, h), .01, rot=(tilt, 0, 0))
    box(p, 'wood_dark', (x, y - d / 2 - .002, z + h * .7), (w * .9, .01, .04), 0, rot=(tilt, 0, 0))


def heap(p, kind, x, y, z, w=.5, d=.34, rows=2):
    if kind == 'carrot':
        for i in range(6):
            p.cylinder('shop_carrot', (x - w / 2 + i * w / 5, y - .1, z + .05), (x - w / 2 + i * w / 5, y + .14, z + .07), .035, 8, radius_b=.006)
            ball(p, 'leaf', (x - w / 2 + i * w / 5, y + .17, z + .08), .04)
        return
    if kind == 'cabbage':
        for i in range(3):
            ball(p, 'cabbage', (x - w / 3 + i * w / 3, y, z + .1), .12)
            ball(p, 'leaf', (x - w / 3 + i * w / 3, y + .02, z + .14), .085)
        return
    size = {'apple': .055, 'apple_green': .055, 'orange': .06, 'lemon': .05, 'potato': .06, 'onion': .055, 'plum': .04}[kind]
    for r in range(rows):
        n = int(w / (size * 2.05)) - r
        for i in range(n):
            for j in range(int(d / (size * 2.1)) - r):
                ball(p, kind, (x - w / 2 + size + r * size + i * size * 2.05, y - d / 2 + size + r * size + j * size * 2.1, z + size * (1 + 1.5 * r)), size, (1, 1, .95 if kind != 'lemon' else .8))


def produce_stand():
    """Three tilted tiers of crates: apples, oranges, lemons, greens, carrots and plums, with slate price tags."""
    root, p, path = begin('pantry-produce-stand')
    for x in (-1.25, 1.25):
        box(p, 'oak', (x, .1, .6), (.08, 1.1, 1.2))
    for z, y in [(.35, -.3), (.7, .05), (1.05, .4)]:
        box(p, 'oak', (0, y, z - .02), (2.6, .42, .04))
    goods = [['apple', 'orange', 'lemon', 'apple_green'], ['cabbage', 'carrot', 'potato', 'onion'], ['plum', 'apple', 'orange', 'lemon']]
    for tier, (z, y) in enumerate([(.35, -.3), (.7, .05), (1.05, .4)]):
        for i, kind in enumerate(goods[tier]):
            x = -.93 + i * .62
            crate(p, x, y, z, .58, .4, .16)
            heap(p, kind, x, y, z + .14, .5, .32, 2)
            box(p, 'chalk', (x, y - .22, z + .1), (.2, .01, .1), .005)
            box(p, 'paper', (x, y - .225, z + .1), (.12, .005, .03), 0)
    box(p, 'pantry_wainscot', (0, .55, 1.6), (2.6, .05, .25), .01)
    k.text(p, 'shop_paper', 'FRESH FROM THE HILLS', k.facing_text(0, .52, 1.6, (0, -1)), .12)
    finish(root, p, path)


def sack_row():
    """Open sacks of potatoes, onions, beans and oats along a wall, rolled down at the necks, with scoops."""
    root, p, path = begin('pantry-sack-row')
    goods = ['potato', 'onion', 'crumb', 'flour']
    for i, kind in enumerate(goods):
        x = -1.2 + i * .8
        rod(p, 'sack', (x, 0, 0), (x, 0, .62), .3, 14, .27)
        rod(p, 'sack', (x, 0, .58), (x, 0, .68), .33, 14)
        if kind in ('potato', 'onion'):
            heap(p, kind, x, 0, .55, .42, .4, 1)
        else:
            ball(p, kind, (x, 0, .62), .27, (1, 1, .3))
        box(p, 'paper', (x, -.31, .36), (.26, .01, .16), 0)
        if i % 2:
            rod(p, 'steel', (x + .08, -.05, .68), (x + .2, -.12, .78), .035, 8)
    finish(root, p, path)


def jar_shelves():
    """A tall dresser of jars, tins and bottles: preserves, honey, spices and tea, with a ladder rail."""
    root, p, path = begin('pantry-jar-shelves')
    for x in (-1.3, 1.3):
        box(p, 'oak', (x, 0, 1.25), (.08, .45, 2.5))
    box(p, 'oak', (0, .2, 1.25), (2.6, .04, 2.45))
    box(p, 'oak', (0, 0, 2.52), (2.75, .5, .08))
    box(p, 'pantry_wainscot', (0, -.02, .25), (2.55, .44, .5), .015)
    contents = ['jar_glass', 'tin_red', 'tin_blue', 'tin_gold']
    fills = ['jam', 'lemon', 'onion', 'plum', 'leaf', 'crumb']
    for n, z in enumerate([.55, 1.05, 1.55, 2.05]):
        box(p, 'oak', (0, 0, z), (2.55, .42, .04), .006)
        for i in range(9):
            x = -1.1 + i * .275
            kind = contents[(i + n) % len(contents)]
            if kind == 'jar_glass':
                rod(p, fills[(i * 3 + n) % len(fills)], (x, -.02, z + .02), (x, -.02, z + .2), .075, 12)
                rod(p, 'jar_glass', (x, -.02, z + .02), (x, -.02, z + .23), .085, 12)
                rod(p, 'paper', (x, -.02, z + .23), (x, -.02, z + .26), .09, 12)
                box(p, 'paper', (x, -.11, z + .12), (.1, .005, .07), 0)
            else:
                rod(p, kind, (x, -.02, z + .02), (x, -.02, z + .22), .08, 12)
                rod(p, 'steel', (x, -.02, z + .22), (x, -.02, z + .24), .08, 12)
    rod(p, 'brass', (-1.3, -.3, 2.3), (1.3, -.3, 2.3), .018, 8)
    finish(root, p, path)


def pantry_counter():
    """Panelled counter with a brass beam scale, a stack of paper bags, a ledger and a bell."""
    root, p, path = begin('pantry-counter')
    box(p, 'oak', (0, .1, .46), (2.6, .8, .92), .02)
    for x in (-.85, 0, .85):
        box(p, 'pantry_wainscot', (x, -.31, .46), (.75, .03, .68), .01)
        box(p, 'pantry_trim', (x, -.33, .46), (.6, .01, .52), .004)
    box(p, 'oak', (0, .05, .95), (2.75, .95, .07))
    # Beam scale: pillar, beam, pans, weights.
    box(p, 'brass', (-.55, .1, 1.0), (.4, .25, .04), .01)
    rod(p, 'brass', (-.55, .1, 1.0), (-.55, .1, 1.45), .025, 10)
    rod(p, 'brass', (-.85, .1, 1.45), (-.25, .1, 1.45), .015, 8)
    for x, z in ((-.85, 1.18), (-.25, 1.2)):
        for dx in (-.08, .08):
            rod(p, 'brass', (x, .1, 1.45), (x + dx, .1, z + .02), .004, 6)
        rod(p, 'brass', (x, .1, z), (x, .1, z + .02), .13, 18)
    ball(p, 'apple', (-.85, .1, 1.26), .05)
    for i, r in enumerate((.04, .035, .03)):
        rod(p, 'brass', (-.25 + i * .015, .1, 1.22 + i * .05), (-.25 + i * .015, .1, 1.26 + i * .05), r, 12)
    for i in range(6):
        box(p, 'sack', (.4, .2, 1.0 + i * .012), (.3, .22, .01), 0)
    box(p, 'wood_dark', (.9, .1, 1.02), (.34, .24, .05), .01)
    box(p, 'paper', (.9, .1, 1.05), (.3, .2, .012), 0)
    rod(p, 'brass', (1.15, -.2, 1.0), (1.15, -.2, 1.06), .06, 14, .03)
    ball(p, 'brass', (1.15, -.2, 1.08), .02)
    finish(root, p, path)


# ---------------------------------------------------------------------------------------------- Finch & Thread
def cloth_shelves():
    """Pigeonholes of rolled cloth bolts in every colour of the shop, with a ladder rail and a cutting-length rod."""
    root, p, path = begin('tailor-cloth-shelves')
    for x in (-1.4, -.47, .47, 1.4):
        box(p, 'oak', (x, 0, 1.3), (.06, .5, 2.6))
    for z in (.05, .7, 1.35, 2.0, 2.62):
        box(p, 'oak', (0, 0, z), (2.85, .5, .05))
    box(p, 'oak', (0, .23, 1.3), (2.85, .04, 2.6))
    for col, x in enumerate((-.93, 0, .93)):
        for row, z in enumerate((.08, .73, 1.38, 2.03)):
            for i in range(3):
                colour = CLOTH[(col * 4 + row * 3 + i) % len(CLOTH)]
                index = CLOTH.index(colour)
                zz = z + .13 + (i % 2) * .22
                xx = x - .26 + i * .26
                rod(p, f'cloth_{index}', (xx, -.22, zz), (xx, .2, zz), .11, 12)
                rod(p, 'linen', (xx, -.225, zz), (xx, -.23, zz), .035, 8)
    rod(p, 'brass', (-1.45, -.32, 2.4), (1.45, -.32, 2.4), .018, 8)
    finish(root, p, path)


def spool_wall():
    """A slatted wall rack of thread spools in graded colours, with ribbons on rollers below and a pin cushion."""
    root, p, path = begin('tailor-spool-wall')
    box(p, 'oak', (0, .05, 1.45), (2.4, .06, 1.7), .015)
    for row in range(8):
        z = .75 + row * .2
        box(p, 'oak', (0, -.02, z - .05), (2.3, .1, .025), .004)
        for i in range(16):
            x = -1.08 + i * .144
            index = (i + row * 3) % len(CLOTH)
            rod(p, 'oak', (x, -.05, z - .035), (x, -.05, z + .1), .03, 8)
            rod(p, f'cloth_{index}', (x, -.05, z - .02), (x, -.05, z + .085), .045, 10)
    box(p, 'oak', (0, -.1, .45), (2.4, .3, .5), .015)
    for i in range(7):
        x = -.95 + i * .32
        rod(p, f'cloth_{(i * 2) % len(CLOTH)}', (x - .12, -.18, .6), (x + .12, -.18, .6), .07, 12)
    ball(p, 'pin', (1.0, -.05, .76), .08, (1, 1, .7))
    for a in range(6):
        rod(p, 'steel', (1.0, -.05, .8), (1.0 + math.cos(a) * .06, -.05 + math.sin(a) * .06, .88), .004, 4)
    finish(root, p, path)


def cutting_table():
    """Long cutting table with a brass yard rule, a bolt laid out and pinned to a paper pattern, shears and chalk."""
    root, p, path = begin('tailor-cutting-table')
    feet(p, (-1.4, 1.4), (-.5, .5), .9)
    box(p, 'oak', (0, 0, .93), (3.1, 1.2, .07))
    box(p, 'oak', (0, 0, .3), (2.9, 1.0, .04))
    box(p, 'brass', (0, -.57, .975), (3.0, .05, .015), .002)
    for i in range(31):
        box(p, 'ink', (-1.5 + i * .1, -.565, .985), (.005, .03 if i % 5 else .05, .004), 0)
    box(p, 'cloth_1', (-.3, .05, .975), (1.9, .95, .02), .005)
    rod(p, 'cloth_1', (.75, -.42, 1.03), (.75, .5, 1.03), .07, 12)
    box(p, 'paper', (-.45, .05, .99), (1.2, .7, .006), 0)
    for x, y in ((-.95, -.25), (-.95, .35), (.05, -.25), (.05, .35), (-.45, .4)):
        ball(p, 'pin', (x, y, 1.0), .015)
    for a in (.35, -.35):
        box(p, 'steel', (1.2, .25, 1.0), (.32, .04, .015), .003, rot=(0, 0, a))
    rod(p, 'ink', (1.05, .25, 1.0), (1.05, .25, 1.02), .035, 10)
    box(p, 'linen', (1.25, -.25, .975), (.08, .05, .02), .005)
    for i in range(4):
        rod(p, f'cloth_{(i * 3) % len(CLOTH)}', (-1.3 + i * .25, .1, .32), (-1.3 + i * .25, .1, .5), .1, 10)
    finish(root, p, path)


def dress_form():
    """A tailor's dummy on a turned stand, wearing a half-finished coat tacked with white basting thread."""
    root, p, path = begin('tailor-dress-form')
    for a in range(3):
        rod(p, 'oak', (0, 0, .12), (math.cos(a * 2.094) * .32, math.sin(a * 2.094) * .32, .02), .025, 8)
    rod(p, 'oak', (0, 0, .1), (0, 0, 1.0), .03, 10)
    rod(p, 'brass', (0, 0, .55), (0, 0, .6), .045, 10)
    ball(p, 'linen', (0, 0, 1.18), .22, (1, .7, .9))
    ball(p, 'linen', (0, 0, 1.42), .24, (1.05, .72, .75))
    rod(p, 'linen', (0, 0, 1.55), (0, 0, 1.68), .06, 10)
    ball(p, 'wood_dark', (0, 0, 1.73), .05)
    # The coat: shoulders, lapels and a hem with a row of pins, sleeves not yet set in.
    ball(p, 'cloth_5', (0, -.01, 1.4), .255, (1.08, .76, .8))
    p.cylinder('shop_cloth_5', (0, -.01, .95), (0, -.01, 1.32), .25, 14, radius_b=.235)
    for side in (-1, 1):
        p.solid('shop_cloth_2', [(side * .02, -.19, 1.48), (side * .14, -.18, 1.32), (side * .06, -.19, 1.2)], .01, (0, -1, 0))
    for i in range(8):
        a = math.pi * (i / 7 - .5) * .9
        ball(p, 'paper', (math.sin(a) * .26, -math.cos(a) * .2, .98), .008)
    for z in (1.1, 1.2):
        ball(p, 'brass', (.03, -.2, z), .018)
    finish(root, p, path)


def sewing_table():
    """A treadle sewing machine on its iron stand, a work lamp and a basket of mending."""
    root, p, path = begin('tailor-sewing-table')
    for x in (-.55, .55):
        p.solid('shop_iron', [(x, -.3, 0), (x, .3, 0), (x, .2, .72), (x, -.2, .72)], .05, (1, 0, 0))
        rod(p, 'iron', (x, -.05, .35), (x, .05, .35), .1, 12)
    rod(p, 'iron', (-.55, 0, .2), (.55, 0, .2), .02, 8)
    box(p, 'iron', (0, -.12, .1), (.5, .3, .03), .005, rot=(.2, 0, 0))
    box(p, 'oak', (0, 0, .76), (1.3, .6, .06))
    # The machine: bed, pillar, arm, head, wheel and spool.
    box(p, 'ink', (.05, 0, .82), (.6, .28, .06), .015)
    box(p, 'ink', (.28, 0, .97), (.12, .18, .26), .03)
    box(p, 'ink', (.05, 0, 1.08), (.55, .14, .1), .035)
    box(p, 'ink', (-.2, 0, .98), (.1, .12, .2), .02)
    rod(p, 'steel', (-.2, 0, .88), (-.2, 0, .84), .006, 6)
    rod(p, 'brass', (.39, -.08, 1.0), (.39, .08, 1.0), .11, 18)
    rod(p, 'cloth_0', (.1, 0, 1.14), (.1, 0, 1.2), .03, 10)
    box(p, 'brass', (.05, -.075, 1.08), (.4, .01, .02), 0)
    box(p, 'cloth_3', (-.25, 0, .8), (.4, .35, .015), .004)
    rod(p, 'brass', (-.55, .2, .79), (-.55, .2, 1.3), .015, 8)
    rod(p, 'brass', (-.55, .2, 1.3), (-.35, .05, 1.38), .013, 8)
    p.cylinder('shop_brass', (-.35, .05, 1.42), (-.35, .05, 1.3), .06, 14, radius_b=.11)
    rod(p, 'lamp_glass', (-.35, .05, 1.3), (-.35, .05, 1.28), .09, 14)
    rod(p, 'sack', (.95, .1, 0), (.95, .1, .3), .2, 14, .24)
    for i in range(3):
        ball(p, f'cloth_{i * 3}', (.9 + i * .06, .1, .32), .09, (1, 1, .5))
    finish(root, p, path)


def tailor_mirror():
    """A tall cheval mirror in an oak frame on swing pivots, and a little measuring stool."""
    root, p, path = begin('tailor-mirror')
    for x in (-.45, .45):
        rod(p, 'oak', (x, 0, 0), (x, 0, 1.6), .03, 8)
        box(p, 'oak', (x, 0, .02), (.08, .5, .04), .01)
    with p.placed((0, 0, 1.0), 0):
        box(p, 'oak', (0, 0, 0), (.78, .06, 1.7), .02, rot=(-.08, 0, 0))
        p.pane('shop_mirror', (0, -.04, 0), .66, 1.56, (0, -1))
    rod(p, 'brass', (-.45, 0, 1.0), (.45, 0, 1.0), .02, 8)
    rod(p, 'oak', (.8, -.3, 0), (.8, -.3, .3), .17, 14)
    rod(p, 'cloth_0', (.8, -.3, .3), (.8, -.3, .36), .18, 14)
    finish(root, p, path)


# ------------------------------------------------------------------------------------------------ shared signs
def shop_board():
    """The shops' chalk board for live lettering: a framed slate on brackets, with a chalk ledge; the lettering is
    drawn by the game at `SignFace` (front centre, two rows of sixteen characters)."""
    root, p, path = begin('shop-chalk-board')
    box(p, 'oak', (0, 0, 0), (2.62, .08, .86), .02)
    box(p, 'chalk', (0, -.045, 0), (2.48, .02, .72), .006)
    box(p, 'oak', (0, -.08, -.46), (2.4, .12, .04), .01)
    for x in (-.9, .4):
        box(p, 'paper', (x, -.1, -.43), (.08, .02, .02), 0)
    for x in (-1.1, 1.1):
        box(p, 'iron', (x, .05, .52), (.04, .12, .2), .005)
    finish(root, p, path, [('SignFace', (0, -.06, 0))])


AUTHORS = [lambda: shell('bakery'), lambda: shell('pantry'), lambda: shell('tailor'), oven, bread_rack, bakery_counter,
           proving_table, flour_sacks, produce_stand, sack_row, jar_shelves, pantry_counter, cloth_shelves, spool_wall,
           cutting_table, dress_form, sewing_table, tailor_mirror, shop_board]
if __name__ == '__main__':
    only = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
    for author in AUTHORS:
        author()
