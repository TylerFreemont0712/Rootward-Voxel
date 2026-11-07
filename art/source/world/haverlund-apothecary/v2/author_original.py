"""Thyme & Tonic, the apothecary: bespoke model after art/source/world/spindle-strip/v1/apothecary-concept.png.

One-time authoring record. No existing building or shop shell is imported; v1 (the rejected reused greengrocer shell)
stays untouched beside it. Once saved, v2/model.blend is the editable authority: edit it in Blender or with a
deliberate source-edit record, never by rerunning this file.

    blender -b --factory-startup --python author_original.py            # writes v2/model.blend (refuses to overwrite)
    blender -b --factory-startup --python author_original.py -- --draft DIR   # review draft elsewhere

Model frame: footprint centre at the ground, shopfront toward Blender -Y (Godot +Z), x along the front (-x is the
viewer's left). Placed turned 90 in the square, -x is south (toward the clockmaker) and the front faces Spindle Walk.
"""
from pathlib import Path
import sys, math, json, hashlib
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
sys.path.insert(0, str(ROOT / 'art/source/world/seaside-houses/v1'))
import house_kit as k

argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
DRAFT = Path(argv[argv.index('--draft') + 1]) if '--draft' in argv else None
TARGET = Path(__file__).with_name('model.blend')
if DRAFT is None and TARGET.exists():
    raise RuntimeError('Apothecary v2 exists. Edit the adopted master instead of rerunning this record.')

PALETTE = {'stone': 'seaside_stone_limestone', 'plaster': 'seaside_plaster_cream', 'roof': 'seaside_roof_slate', 'ridge': 'seaside_roof_slate',
           'timber': 'seaside_timber_oak', 'shutter': 'seaside_shutter_sage'}
root = k.begin('haverlund-apothecary', PALETTE)
k.material('apoth_green', '2f4a3c', roughness=.72)            # deep green enamelled joinery
k.material('apoth_green_light', '4d6b55', roughness=.7)
k.material('apoth_plum', '6b3446', roughness=.74)             # door and shutters
k.material('apoth_gold', 'd8b25c', roughness=.42, metallic=.4)
k.material('apoth_copper', 'a8683f', roughness=.5, metallic=.35)
k.material('apoth_recess', '231e19', roughness=.9)            # shop interior seen behind the glazing
k.material('apoth_bottle_amber', 'b5722c', roughness=.3, emission=.12)
k.material('apoth_bottle_green', '4f7d4c', roughness=.3)
k.material('apoth_bottle_blue', '4e6f8f', roughness=.3)
k.material('apoth_lamp_glass', 'ffd28b', roughness=.4, emission=.5)
glass = k.material('apoth_clear_glass', 'e9efe6', roughness=.18)
gh = k.material('apoth_house_glass', 'dfeee2', roughness=.2)
for mat, alpha in [(glass, .12), (gh, .22)]:
    bs = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Alpha'].default_value = alpha
    # Blender 5 exports BLENDED materials as glTF alphaMode BLEND; read the enum rather than assume an identifier.
    choices = [i.identifier for i in bpy.types.Material.bl_rna.properties['surface_render_method'].enum_items]
    mat.surface_render_method = next(v for v in choices if 'BLEND' in v)

slate = bpy.data.materials['seaside_roof']
nodes = slate.node_tree.nodes
tex = next(n for n in nodes if n.type == 'TEX_IMAGE')
mix = nodes.new('ShaderNodeMixRGB'); mix.blend_type = 'MULTIPLY'; mix.inputs[0].default_value = 1
mix.inputs[2].default_value = (.66, .86, .74, 1)
slate.node_tree.links.new(tex.outputs['Color'], mix.inputs[1])
slate.node_tree.links.new(mix.outputs['Color'], next(n for n in nodes if n.type == 'BSDF_PRINCIPLED').inputs['Base Color'])
p = k.Parts(20261105)
F = (0, -1)
up = Vector((0, 0, 1))

# --- plan ----------------------------------------------------------------------------------------------------------
MX0, MX1, MY0, MY1 = -1.85, 4.75, -2.3, 2.6       # main stone block
GX0, GX1, GY0, GY1 = -4.75, -1.85, -2.05, 2.35    # herb glasshouse wing
EAVE = 3.9
PITCH = 52
T = math.tan(math.radians(PITCH))
CY = (MY0 + MY1) / 2
RIDGE = EAVE + (MY1 - MY0) / 2 * T
PORCH = (-1.5, .7)          # porch opening along the front
DOOR_X = -.4                # door centre; placed at the square's door cell
BAY_X0, BAY_STRAIGHT, BAY_R, BAY_Y = .85, 3.85, .9, -2.95


def slab(mat, a, b, z0, z1, depth, uv=('blocks',)):
    """A vertical slab whose outer face runs a→b (2D) with its outside to the right of travel."""
    a, b = Vector((*a, 0)), Vector((*b, 0))
    along = (b - a).normalized()
    out = Vector((along.y, -along.x, 0))
    pts = [a + up * z0, b + up * z0, b + up * z1, a + up * z1]
    p.solid(mat, [tuple(q) for q in pts], depth, tuple(out), uv=uv)


def bay_curve(inset=0.0, steps=8):
    """The bowed shopfront's plan: straight along the front, then a quarter round to the side wall."""
    pts = [(BAY_X0, BAY_Y + inset), (BAY_STRAIGHT, BAY_Y + inset)]
    cx, cy, r = BAY_STRAIGHT, BAY_Y + BAY_R, BAY_R - inset
    for n in range(1, steps + 1):
        a = -math.pi / 2 + (math.pi / 2) * n / steps
        pts.append((cx + r * math.cos(a), cy + r * math.sin(a)))
    return pts


def along(pts):
    out, d = [0.0], 0.0
    for a, b in zip(pts, pts[1:]):
        d += (Vector(b) - Vector(a)).length
        out.append(d)
    return out


# --- stone body ----------------------------------------------------------------------------------------------------
# Front wall: the porch is a real opening; the bay stands proud of a dark shop interior behind it.
k.wall(p, 'stone', (MX0, MY0), (MX1, MY0), 0, EAVE, .32,
       [(PORCH[0] - MX0, PORCH[1] - MX0, 0, 2.95), (BAY_X0 - MX0 + .05, MX1 - MX0 - .02, .62, 2.62)])
k.wall(p, 'stone', (MX1, MY0), (MX1, MY1), 0, EAVE, .32, [(1.2, 1.95, 1.0, 2.2)])
k.wall(p, 'stone', (MX1, MY1), (MX0, MY1), 0, EAVE, .32, [(1.15, 2.15, 0, 2.3), (3.6, 4.5, 1.1, 2.2)])
k.wall(p, 'stone', (MX0, MY1), (MX0, MY0), 0, EAVE, .32)
k.gable(p, 'stone', 'x', MX0, MY0, MY1, EAVE, RIDGE, -1, .32)
for corner, faces in [((MX1, MY0), ((1, 0), (0, -1))), ((MX1, MY1), ((1, 0), (0, 1))), ((MX0, MY1), ((-1, 0), (0, 1)))]:
    k.quoins(p, corner, faces, .05, EAVE - .05, course=.34, long=.46, short=.28)
# A darker plinth course all round, as in the concept's heavier base stones.
for a, b in [((MX1, MY0), (MX1, MY1)), ((MX1, MY1), (MX0, MY1))]:
    slab('stone', a, b, 0, .42, .38)

# Porch: lined reveals, a raised floor, stone steps and the hinged plum door.
pz = .3
p.box('stone', ((PORCH[0] + PORCH[1]) / 2, MY0 + .45, pz / 2), (PORCH[1] - PORCH[0], .9, pz), bevel=.02, uv=('blocks',))
for n, (dy, h) in enumerate([(-.18, .2), (-.48, .1)]):
    p.box('stone', (DOOR_X - .05, MY0 + dy, h / 2), (1.75 - n * .1 + .5 * n, .32 if n == 0 else .3, h), bevel=.025, uv=('blocks',))
for x in PORCH:
    p.box('stone', (x + (.04 if x < 0 else -.04), MY0 + .45, 1.5), (.08, .9, 3.0), bevel=.01, uv=('blocks',))
p.box('apoth_recess', ((PORCH[0] + PORCH[1]) / 2, MY0 + .45, 2.98), (PORCH[1] - PORCH[0], .9, .06), bevel=0)
wall_back = MY0 + .9
for x0, x1 in [(PORCH[0], DOOR_X - .55), (DOOR_X + .55, PORCH[1])]:
    p.box('stone', ((x0 + x1) / 2, wall_back + .1, 1.5), (x1 - x0, .2, 3.0), bevel=.01, uv=('blocks',))
p.box('stone', (DOOR_X, wall_back + .1, 2.72), (1.1, .2, .56), bevel=.01, uv=('blocks',))
p.box('apoth_green', (DOOR_X, wall_back - .02, 2.43), (1.18, .08, .1), bevel=.01)
for x in [DOOR_X - .55, DOOR_X + .55]:
    p.box('apoth_green', (x, wall_back - .02, 1.35), (.09, .08, 2.15), bevel=.01)
hinge = Vector((DOOR_X - .5, wall_back - .02, pz))
with p.into('door_leaf_apothecary'):
    dz0 = pz
    p.box('apoth_plum', (DOOR_X, wall_back - .03, dz0 + 1.06), (.98, .07, 2.1), bevel=.015)
    for x in [DOOR_X - .38, DOOR_X + .38]:
        p.box('apoth_plum', (x, wall_back - .075, dz0 + 1.06), (.12, .04, 2.0), bevel=.008)
    for z in [.12, .95, 1.98]:
        p.box('apoth_plum', (DOOR_X, wall_back - .075, dz0 + z), (.86, .04, .1), bevel=.008)
    p.box('apoth_plum', (DOOR_X, wall_back - .078, dz0 + .52), (.6, .03, .62), bevel=.01)
    # Leaded glazing in the upper leaf.
    p.box('apoth_clear_glass', (DOOR_X, wall_back - .06, dz0 + 1.46), (.62, .015, .88), bevel=0)
    for d in [-.2, 0, .2]:
        p.box('iron', (DOOR_X + d, wall_back - .075, dz0 + 1.46), (.018, .012, .88), bevel=0)
    for dz in [-.3, -.1, .1, .3]:
        p.box('iron', (DOOR_X, wall_back - .075, dz0 + 1.46 + dz), (.62, .012, .018), bevel=0)
    p.box('brass', (DOOR_X + .36, wall_back - .1, dz0 + 1.02), (.05, .03, .2), bevel=.006)
    p.sphere('brass', (DOOR_X + .36, wall_back - .13, dz0 + 1.0), .035, 1)

# Green porch frame with a round arch, pilasters and capitals, as in the concept.
fy = MY0 - .1
for x in [PORCH[0] - .05, PORCH[1] + .05]:
    p.box('apoth_green', (x, fy, 1.45), (.22, .2, 2.9), bevel=.02)
    p.box('stone', (x, fy, .2), (.32, .26, .4), bevel=.02, uv=('blocks',))
    p.box('apoth_green', (x, fy - .02, 2.95), (.3, .24, .12), bevel=.015)
r = (PORCH[1] - PORCH[0]) / 2
cx = (PORCH[0] + PORCH[1]) / 2
spring = 2.95 - r * .55
for n in range(14):
    a0 = math.pi * n / 14; a1 = math.pi * (n + 1) / 14
    q0 = (cx + r * math.cos(a0), fy, spring + r * .55 * math.sin(a0))
    q1 = (cx + r * math.cos(a1), fy, spring + r * .55 * math.sin(a1))
    p.beam('apoth_green', q0, q1, .14, .2, up=(0, -1, 0), bevel=.008)
# Pendant porch lantern under the arch.
lan = Vector((cx + .55, MY0 + .35, 2.35))
p.cylinder('iron', lan + Vector((0, 0, .6)), lan + Vector((0, 0, .26)), .012, 5)
p.cylinder('iron', lan + Vector((0, 0, .26)), lan + Vector((0, 0, .2)), .09, 8, radius_b=.03)
p.box('apoth_lamp_glass', lan, (.16, .16, .26), bevel=0)
for dx, dy in [(-1, -1), (1, -1), (1, 1), (-1, 1)]:
    p.box('iron', lan + Vector((dx * .08, dy * .08, 0)), (.02, .02, .3), bevel=0)
p.cylinder('iron', lan + Vector((0, 0, -.13)), lan + Vector((0, 0, -.2)), .06, 8, radius_b=.015)
# A stool with lavender inside the porch, and pots on the steps.
sx, sy = PORCH[0] + .3, MY0 + .3
p.cylinder('timber', (sx, sy, pz + .52), (sx, sy, pz + .58), .19, 12)
for dx, dy in [(-.12, -.12), (.12, -.12), (.12, .12), (-.12, .12)]:
    p.beam('timber', (sx + dx, sy + dy, pz), (sx + dx * .7, sy + dy * .7, pz + .53), .035, .035)
k.pot(p, (sx, sy, pz + .58), scale=.8, plant='flowers', flowers=['flower_violet', 'flower_violet', 'leaf'])

# --- the bowed shopfront -------------------------------------------------------------------------------------------
outer = bay_curve()
inner = bay_curve(.55)
backs = [(BAY_X0, MY0 + .02), (MX1 - .02, MY0 + .02), (MX1 - .02, BAY_Y + BAY_R)]
# Stone stall riser.
for a, b in zip(outer, outer[1:]):
    slab('stone', a, b, 0, .62, .2)
slab('stone', (BAY_X0, MY0), outer[0], 0, .62, .2)
# Floor, sill and dark interior (the shop beyond).
for z, h, mat in [(.6, .06, 'stone'), (2.62, .06, 'apoth_recess')]:
    poly = [(BAY_X0, MY0)] + outer + [(MX1, MY0)]
    p.prism(mat, [poly[0]] + list(reversed(poly[1:])) if False else poly[::-1], z, z + h)
for a, b in zip(outer, outer[1:]):
    a2 = Vector(a); b2 = Vector(b); along_v = (b2 - a2).normalized(); out = Vector((along_v.y, -along_v.x))
    p.beam('apoth_green', (*(a2 + out * .05), .68), (*(b2 + out * .05), .68), .16, .1)
p.box('apoth_recess', ((BAY_X0 + MX1) / 2, MY0 - .03, 1.62), (MX1 - BAY_X0, .04, 2.0), bevel=0)
# Shelves of jars and bottles, with herbs on the stall board; warm lamps light them at night.
shelf_rng = __import__('random').Random(7)
for z in [1.12, 1.66, 2.16]:
    pts = bay_curve(.18)
    for a, b in zip(pts, pts[1:]):
        a2 = Vector(a); b2 = Vector(b); along_v = (b2 - a2).normalized(); inn = Vector((-along_v.y, along_v.x))
        p.beam('timber', (*(a2 + inn * .1), z), (*(b2 + inn * .1), z), .3, .04)
        L = (b2 - a2).length
        for i in range(max(1, int(L / .17))):
            t = (i + .5) / max(1, int(L / .17))
            q = a2.lerp(b2, t) + inn * shelf_rng.uniform(.03, .2)
            kind = shelf_rng.random()
            mat = 'apoth_bottle_amber' if kind < .45 else 'apoth_bottle_green' if kind < .75 else 'apoth_bottle_blue'
            h = shelf_rng.uniform(.18, .34)
            if kind < .85:
                rr = shelf_rng.uniform(.04, .065)
                p.cylinder(mat, (q.x, q.y, z + .02), (q.x, q.y, z + .02 + h), rr, 8)
                p.cylinder(mat, (q.x, q.y, z + .02 + h), (q.x, q.y, z + .08 + h), rr * .45, 6)
                p.cylinder('timber' if kind < .5 else 'brass', (q.x, q.y, z + .08 + h), (q.x, q.y, z + .11 + h), rr * .5, 6)
            else:
                p.cylinder('linen', (q.x, q.y, z + .02), (q.x, q.y, z + .2), .07, 10)
                p.cylinder('apoth_green', (q.x, q.y, z + .2), (q.x, q.y, z + .24), .075, 10)
for x in [1.5, 2.6, 3.6]:
    k.pot(p, (x, BAY_Y + .3, .66), scale=.6, plant='flowers', flowers=['leaf', 'olive', 'flower_white'])
for x in [1.4, 3.1]:
    q = Vector((x, BAY_Y + .45, 2.45))
    p.cylinder('iron', q + Vector((0, 0, .17)), q + Vector((0, 0, .1)), .01, 4)
    p.sphere('apoth_lamp_glass', q, .08, 1)
# Clear glazing on the outer line, with green mullions and an arched head to every light.
lengths = along(outer)
total = lengths[-1]
lights = 7
for i, (a, b) in enumerate(zip(outer, outer[1:])):
    a2 = Vector(a); b2 = Vector(b)
    pts = [(a2.x, a2.y, .72), (b2.x, b2.y, .72), (b2.x, b2.y, 2.6), (a2.x, a2.y, 2.6)]
    av = (b2 - a2).normalized(); out = (av.y, -av.x, 0)
    p.solid('apoth_clear_glass', pts, .012, out)


def point_at(d):
    for (a, b), l0, l1 in zip(zip(outer, outer[1:]), lengths, lengths[1:]):
        if d <= l1 + 1e-6:
            t = (d - l0) / max(l1 - l0, 1e-6)
            return Vector(a).lerp(Vector(b), t), (Vector(b) - Vector(a)).normalized()
    return Vector(outer[-1]), (Vector(outer[-1]) - Vector(outer[-2])).normalized()


posts = [total * n / lights for n in range(lights + 1)]
for d in posts:
    q, av = point_at(d)
    out = Vector((av.y, -av.x, 0))
    q3 = Vector((q.x, q.y, 0)) + out * .03
    p.box('apoth_green', (q3.x, q3.y, 1.66), (.09, .09, 1.9), rot=(0, 0, math.atan2(av.y, av.x)), bevel=.012)
for n in range(lights):
    d0, d1 = posts[n], posts[n + 1]
    rr = (d1 - d0) / 2
    for s in range(8):
        e0 = d0 + rr - rr * math.cos(math.pi * s / 8)
        e1 = d0 + rr - rr * math.cos(math.pi * (s + 1) / 8)
        z0 = 2.18 + rr * .55 * math.sin(math.pi * s / 8)
        z1 = 2.18 + rr * .55 * math.sin(math.pi * (s + 1) / 8)
        q0, av0 = point_at(e0); q1, av1 = point_at(e1)
        o0 = Vector((av0.y, -av0.x)) * .035; o1 = Vector((av1.y, -av1.x)) * .035
        p.beam('apoth_green', (*(q0 + o0), z0), (*(q1 + o1), z1), .05, .06, up=(0, 0, 1), bevel=0)
    q, av = point_at(d0 + rr)
    o = Vector((av.y, -av.x)) * .035
    p.beam('apoth_green', (*(point_at(d0)[0] + o), 2.18), (*(point_at(d1)[0] + o), 2.18), .04, .04, bevel=0)
    # Glazing highlight.
    h0, _ = point_at(d0 + rr * .5); h1, _ = point_at(d0 + rr * .8)
    p.beam('apoth_clear_glass', (*(h0 + o * 1.3), 1.05), (*(h1 + o * 1.3), 1.85), .02, .006, bevel=0)
# Head rail, fascia board, gold sign and cornice, all following the bow.
for a, b in zip(outer, outer[1:]):
    a2 = Vector(a); b2 = Vector(b); av = (b2 - a2).normalized(); out = Vector((av.y, -av.x))
    p.beam('apoth_green', (*(a2 + out * .02), 2.64), (*(b2 + out * .02), 2.64), .14, .1, bevel=.008)
    slab('apoth_green', tuple(a2 + out * .05), tuple(b2 + out * .05), 2.7, 3.28, .12, uv='world')
    p.beam('apoth_green_light', (*(a2 + out * .12), 3.34), (*(b2 + out * .12), 3.34), .14, .12, bevel=.012)
    p.beam('apoth_copper', (*(a2 + out * .16), 3.44), (*(b2 + out * .16), 3.44), .1, .08, bevel=0)
slab('apoth_green', (PORCH[0] - .2, MY0 - .05), (BAY_X0, MY0 - .05), 3.02, 3.42, .1, uv='world')
p.beam('apoth_green_light', (PORCH[0] - .2, MY0 - .14, 3.46), (BAY_X0 + .05, MY0 - .14, 3.46), .16, .1)
mid = (BAY_X0 + BAY_STRAIGHT) / 2
p.box('apoth_gold', (mid, BAY_Y - .02, 2.99), (2.85, .03, .42), bevel=.008)
p.box('apoth_green', (mid, BAY_Y - .035, 2.99), (2.75, .03, .34), bevel=.006)
k.text(p, 'apoth_gold', 'THYME & TONIC', k.facing_text(mid, BAY_Y - .055, 2.98, F), .25)
for dx in [-1.23, 1.23]:
    for s in range(3):
        a = s * 2.1 + .5
        p.sphere('apoth_gold', (mid + dx + .06 * math.cos(a), BAY_Y - .06, 2.99 + .06 * math.sin(a)), .035, 1, squash=(1.4, .3, .7))
# Copper bay roof falling to its gutter.
roof_back = MY0 - .02
poly_outer = bay_curve(-.18)
for a, b in zip(poly_outer, poly_outer[1:]):
    p.solid('roof', [(a[0], a[1], 3.48), (b[0], b[1], 3.48), (b[0], max(b[1] + .9, roof_back) if b[0] < MX1 - .1 else b[1], 3.78), (a[0], max(a[1] + .9, roof_back) if a[0] < MX1 - .1 else a[1], 3.78)], .04, (0, -.3, 1))
p.solid('roof', [(PORCH[0] - .3, MY0 - .3, 3.5), (BAY_X0, MY0 - .3, 3.5), (BAY_X0, roof_back, 3.72), (PORCH[0] - .3, roof_back, 3.72)], .04, (0, -.3, 1))
# Window box below the bow, spilling lavender and ivy.
p.box('timber', (mid, BAY_Y - .16, .46), (2.4, .26, .22), bevel=.015)
for i in range(13):
    x = mid - 1.1 + i * .183
    p.sphere('leaf_dark', (x, BAY_Y - .17, .6), .1, 1, squash=(1, 1, .7))
    for j in range(2):
        p.cylinder('leaf', (x + .02 * j, BAY_Y - .17, .58), (x + .02 * j, BAY_Y - .17, .82 + .06 * (i % 3)), .012, 4)
        p.sphere('flower_violet', (x + .02 * j, BAY_Y - .17, .84 + .06 * (i % 3)), .03, 1, squash=(1, 1, 2.2))
for i in range(5):
    x = mid - 1.0 + i * .5
    p.sphere('leaf_dark', (x, BAY_Y - .3, .36), .07, 1, squash=(1, 1, 1.6))

# --- roofs ---------------------------------------------------------------------------------------------------------
eave_out = .38
ze = EAVE - eave_out * T
RX1 = MX1 - (MY1 - MY0) / 2           # where the hipped end meets the ridge
L = MX0 - .32
for side in (-1, 1):
    ey = (MY0 - eave_out) if side < 0 else (MY1 + eave_out)
    p.solid('roof', [(L, ey, ze), (MX1 + eave_out, ey, ze), (RX1, CY, RIDGE), (L, CY, RIDGE)], .1,
            (0, side, 1 / T))
p.solid('roof', [(MX1 + eave_out, MY0 - eave_out, ze), (MX1 + eave_out, MY1 + eave_out, ze), (RX1, CY, RIDGE)], .1, (1, 0, 1 / T))
# Slate courses: thin raised lines across every slope.
for side in (-1, 1):
    ey = (MY0 - eave_out) if side < 0 else (MY1 + eave_out)
    for n in range(1, 11):
        t = n / 11
        y = ey + (CY - ey) * t; z = ze + (RIDGE - ze) * t
        x1 = (MX1 + eave_out) + (RX1 - (MX1 + eave_out)) * t
        p.beam('roof', (L, y, z + .055), (x1, y, z + .055), .05, .025, bevel=0)
p.cylinder('ridge', (L - .05, CY, RIDGE + .06), (RX1, CY, RIDGE + .06), .085, 8)
for sy in (MY0 - eave_out, MY1 + eave_out):
    p.cylinder('ridge', (RX1, CY, RIDGE + .06), (MX1 + eave_out, sy, ze + .06), .075, 8)
# Green bargeboards on the left gable end, with a turned finial.
for sy in (MY0 - eave_out, MY1 + eave_out):
    p.beam('apoth_green', (L - .02, sy, ze - .05), (L - .02, CY, RIDGE - .02), .07, .24, up=(0, 0, 1))
p.cylinder('apoth_green', (L - .02, CY, RIDGE - .2), (L - .02, CY, RIDGE + .45), .05, 8, radius_b=.015)
# Cross gable over the porch, facing the walk.
CG0, CG1 = MX0, BAY_X0 + .2
cgx = (CG0 + CG1) / 2
cpitch = math.tan(math.radians(60))
capex = EAVE + (CG1 - CG0) / 2 * cpitch
k.gable(p, 'stone', 'y', MY0, CG0, CG1, EAVE, capex, -1, .32)
front_y = MY0 - .45
cze = EAVE - .3 * cpitch


def valley_y(z):
    return MY0 + (z - EAVE) / T


for side in (-1, 1):
    ex = (CG0 - .3) if side < 0 else (CG1 + .3)
    p.solid('roof', [(ex, front_y, cze), (cgx, front_y, capex), (cgx, valley_y(capex), capex), (ex, valley_y(cze), cze)][::(-1 if side < 0 else 1)], .1, (side * cpitch, 0, 1))
    # Bargeboards with a little drop at the apex.
    p.beam('apoth_green', (ex, front_y - .03, cze - .06), (cgx, front_y - .03, capex - .03), .07, .26, up=(0, 0, 1))
p.cylinder('ridge', (cgx, front_y - .04, capex + .06), (cgx, valley_y(capex), capex + .06), .08, 8)
p.cylinder('apoth_green', (cgx, front_y - .06, capex - .7), (cgx, front_y - .06, capex + .35), .045, 8, radius_b=.012)
# Brackets under the cross gable and the herb drying pole with hanging bundles.
for x in [CG0 + .05, CG1 - .05]:
    p.beam('timber', (x, MY0, EAVE - .45), (x, front_y + .05, EAVE - .05), .1, .1)
pole_z = EAVE - .1
p.cylinder('timber', (CG0 - .55, MY0 - .62, pole_z), (CG1 + .25, MY0 - .62, pole_z), .05, 8)
for x in [CG0 - .2, CG1 - .1]:
    p.beam('iron', (x, MY0, pole_z + .05), (x, MY0 - .62, pole_z + .02), .03, .03)
bundles = ['olive', 'flower_violet', 'leaf_light', 'wicker', 'flower_violet', 'olive', 'leaf']
for i, mat in enumerate(bundles):
    x = CG0 - .38 + i * ((CG1 + .1 - (CG0 - .38)) / (len(bundles) - 1))
    drop = .35 + .12 * (i % 3)
    p.cylinder('rope', (x, MY0 - .62, pole_z), (x, MY0 - .62, pole_z - .12), .012, 4)
    p.cylinder('rope', (x, MY0 - .62, pole_z - .12), (x, MY0 - .62, pole_z - .18), .05, 6)
    p.cylinder(mat, (x, MY0 - .62, pole_z - .18), (x, MY0 - .62, pole_z - .18 - drop), .07, 7, radius_b=.018)
# Upper gable window with plum shutters standing open.
gw = Vector((cgx, MY0 - .02, 4.75))
p.box('apoth_recess', gw + Vector((0, .1, 0)), (.62, .05, .82), bevel=0)
p.box('stone', gw + Vector((0, -.03, -.47)), (.86, .2, .1), bevel=.015, uv=('blocks',))
for dx in (-.36, .36):
    p.box('stone', gw + Vector((dx, -.02, 0)), (.12, .14, .9), bevel=.01, uv=('blocks',))
for s in range(8):
    a0 = math.pi * s / 8; a1 = math.pi * (s + 1) / 8
    p.beam('stone', gw + Vector((.36 * math.cos(a0), -.02, .41 + .2 * math.sin(a0))), gw + Vector((.36 * math.cos(a1), -.02, .41 + .2 * math.sin(a1))), .14, .1, up=(0, -1, 0), bevel=0)
p.box('apoth_green', gw + Vector((0, -.01, 0)), (.05, .03, .8), bevel=0)
p.box('apoth_green', gw + Vector((0, -.01, .1)), (.6, .03, .05), bevel=0)
for dx in (-1, 1):
    with p.placed((gw.x + dx * .63, gw.y - .07, gw.z), 0):
        p.box('apoth_plum', (0, 0, 0), (.32, .04, .82), bevel=.01)
        for dz in (-.25, 0, .25):
            p.box('apoth_plum', (0, -.025, dz), (.3, .02, .05), bevel=0)
k.pot(p, (gw.x - .2, gw.y - .2, 4.3), scale=.55, plant='ivy')
p.box('timber', (gw.x, gw.y - .18, 4.24), (.8, .22, .14), bevel=.01)
# Arched dormer with a curved hood on the front slope over the bow.
dx, dz0 = 3.0, EAVE + .55
dy = MY0 + .55 / T * 0 + .25
p.box('stone', (dx, dy + .35, dz0 + .62), (1.12, .85, 1.3), bevel=.02, uv=('blocks',))
p.box('apoth_recess', (dx, dy - .09, dz0 + .62), (.62, .04, .9), bevel=0)
for s in range(10):
    a0 = math.pi * s / 10; a1 = math.pi * (s + 1) / 10
    p.beam('apoth_green', (dx + .33 * math.cos(a0), dy - .12, dz0 + .95 + .3 * math.sin(a0)), (dx + .33 * math.cos(a1), dy - .12, dz0 + .95 + .3 * math.sin(a1)), .09, .07, up=(0, -1, 0), bevel=0)
for xx in (dx - .33, dx + .33):
    p.box('apoth_green', (xx, dy - .12, dz0 + .55), (.09, .07, .82), bevel=0)
p.box('apoth_green', (dx, dy - .12, dz0 + .15), (.75, .1, .07), bevel=0)
for d in (-.11, .11):
    p.box('apoth_green', (dx + d, dy - .12, dz0 + .65), (.025, .03, .95), bevel=0)
for zz in (.45, .78):
    p.box('apoth_green', (dx, dy - .12, dz0 + zz), (.62, .03, .025), bevel=0)
hood = [(-.75, 1.22), (-.58, 1.34), (-.36, 1.55), (0, 1.72), (.36, 1.55), (.58, 1.34), (.75, 1.22)]
for (x0, z0), (x1, z1) in zip(hood, hood[1:]):
    p.solid('roof', [(dx + x0, dy - .25, dz0 + z0), (dx + x1, dy - .25, dz0 + z1), (dx + x1, dy + .8, dz0 + z1), (dx + x0, dy + .8, dz0 + z0)], .06, (0, -.15, 1))
    p.cylinder('apoth_green', (dx + x0, dy - .27, dz0 + z0 - .02), (dx + x1, dy - .27, dz0 + z1 - .02), .05, 6)
p.box('timber', (dx, dy - .32, dz0 + .08), (.95, .26, .16), bevel=.012)
for i in range(7):
    xx = dx - .4 + i * .133
    p.sphere('leaf' if i % 2 else 'leaf_dark', (xx, dy - .33, dz0 + .22), .09, 1, squash=(1, 1, .7))
    p.sphere('flower_violet' if i % 3 else 'flower_white', (xx + .03, dy - .38, dz0 + .3), .04, 1)
# Tall limestone chimney with two pots, and copper rainwater goods.
k.chimney(p, 3.55, 1.25, RIDGE - 1.5, RIDGE + 1.25, width=.8, depth=.66, style='stone', pots=2)
k.gutter(p, (L, MY0 - eave_out + .05, ze - .05), (BAY_X0 - .1, MY0 - eave_out + .05, ze - .05))
k.downpipe(p, (BAY_X0 - .12, MY0 - eave_out + .05, ze - .1), 3.4, (0, -1))
p.cylinder('apoth_copper', (BAY_X0 - .12, MY0 - .2, 3.4), (BAY_X0 - .12, MY0 - .2, .1), .055, 8)
k.gutter(p, (L, MY1 + eave_out - .05, ze - .05), (MX1 + eave_out, MY1 + eave_out - .05, ze - .05))
k.downpipe(p, (MX1 + eave_out - .1, MY1 + eave_out - .05, ze - .1), .1, (0, 1))

# --- hanging sign: scrolled iron bracket and a mortar-and-pestle disc ----------------------------------------------
bx, by, bz = MX1, -1.25, 3.35
p.box('iron', (bx + .03, by, bz), (.06, .16, .5), bevel=.01)
p.beam('iron', (bx, by, bz + .2), (bx + 1.05, by, bz + .2), .04, .05)
p.beam('iron', (bx, by, bz - .2), (bx + .55, by, bz + .18), .03, .03)
for s in range(10):
    a0 = math.tau * s / 10; a1 = math.tau * (s + 1) / 10
    rr0 = .16 - .012 * s; rr1 = .16 - .012 * (s + 1)
    p.beam('iron', (bx + .55 + rr0 * math.cos(a0), by, bz + .02 + rr0 * math.sin(a0)), (bx + .55 + rr1 * math.cos(a1), by, bz + .02 + rr1 * math.sin(a1)), .02, .02, up=(0, 1, 0), bevel=0)
for xx in (bx + .62, bx + .98):
    p.cylinder('iron', (xx, by, bz + .2), (xx, by, bz - .02), .01, 4)
sc = Vector((bx + .8, by, bz - .42))
p.cylinder('apoth_gold', sc + Vector((0, -.04, 0)), sc + Vector((0, .04, 0)), .4, 32)
for side in (-1, 1):
    p.cylinder('apoth_green', sc + Vector((0, side * .042, 0)), sc + Vector((0, side * .05, 0)), .35, 32)
    # Mortar bowl and pestle in cream, on both faces.
    face = sc + Vector((0, side * .055, 0))
    p.sphere('linen', face + Vector((0, 0, -.06)), .17, 2, squash=(1, .08, .62))
    p.box('apoth_green', face + Vector((0, side * .006, .03)), (.38, .01, .1), bevel=0)
    p.box('linen', face + Vector((0, 0, -.2)), (.22, .01, .05), bevel=0)
    p.beam('linen', face + Vector((.02, 0, -.02)), face + Vector((.17, 0, .2)), .05, .012, up=(0, 1, 0), bevel=0)
    p.sphere('linen', face + Vector((.17, 0, .2)), .04, 1, squash=(1, .3, 1))
p.cylinder('apoth_gold', sc + Vector((0, 0, .4)), sc + Vector((0, 0, .5)), .02, 6)

# --- the herb glasshouse -------------------------------------------------------------------------------------------
GZ0, GZE, GZR = .55, 2.3, 3.25
for a, b in [((GX0, GY0), (GX1, GY0)), ((GX0, GY1), (GX0, GY0)), ((GX1, GY1), (GX0, GY1))]:
    slab('stone', a, b, 0, GZ0, .26)
p.box('stone', ((GX0 + GX1) / 2, (GY0 + GY1) / 2, GZ0 + .03), (GX1 - GX0 + .08, GY1 - GY0 + .08, .06), bevel=.015, uv=('blocks',))
# Glass walls and roof.
for a, b, nrm in [((GX0, GY0), (GX1, GY0), (0, -1, 0)), ((GX0, GY1), (GX0, GY0), (-1, 0, 0)), ((GX1, GY1), (GX0, GY1), (0, 1, 0))]:
    p.solid('apoth_house_glass', [(a[0], a[1], GZ0), (b[0], b[1], GZ0), (b[0], b[1], GZE), (a[0], a[1], GZE)], .01, nrm)
gcy = (GY0 + GY1) / 2
p.solid('apoth_house_glass', [(GX0, GY0 - .08, GZE), (GX1, GY0 - .08, GZE), (GX1, gcy, GZR), (GX0, gcy, GZR)], .01, (0, -1, 1.6))
p.solid('apoth_house_glass', [(GX1, GY1 + .08, GZE), (GX0, GY1 + .08, GZE), (GX0, gcy, GZR), (GX1, gcy, GZR)], .01, (0, 1, 1.6))
p.solid('apoth_house_glass', [(GX0, GY0, GZE), (GX0, GY1, GZE), (GX0, gcy, GZR)], .01, (-1, 0, 0))
# Green iron frame: posts, rails, glazing bars, roof bars and the gable-end tracery.
step = .58
n_front = round((GX1 - GX0) / step)
for i in range(n_front + 1):
    x = GX0 + (GX1 - GX0) * i / n_front
    for y in (GY0, GY1):
        p.box('apoth_green', (x, y, (GZ0 + GZE) / 2), (.06, .06, GZE - GZ0), bevel=0)
    p.beam('apoth_green', (x, GY0 - .08, GZE), (x, gcy, GZR), .05, .05, bevel=0)
    p.beam('apoth_green', (x, GY1 + .08, GZE), (x, gcy, GZR), .05, .05, bevel=0)
n_side = round((GY1 - GY0) / step)
for i in range(n_side + 1):
    y = GY0 + (GY1 - GY0) * i / n_side
    p.box('apoth_green', (GX0, y, (GZ0 + GZE) / 2), (.06, .06, GZE - GZ0), bevel=0)
for z in (GZ0 + .04, 1.55, GZE):
    p.beam('apoth_green', (GX0, GY0, z), (GX1, GY0, z), .07, .06, bevel=0)
    p.beam('apoth_green', (GX0, GY1, z), (GX1, GY1, z), .07, .06, bevel=0)
    p.beam('apoth_green', (GX0, GY0, z), (GX0, GY1, z), .07, .06, bevel=0)
p.beam('apoth_green', (GX0, gcy, GZR), (GX1, gcy, GZR), .08, .08, bevel=0)
for i in range(n_side):
    y0 = GY0 + (GY1 - GY0) * i / n_side; y1 = GY0 + (GY1 - GY0) * (i + 1) / n_side
    rr = (y1 - y0) / 2
    for s in range(6):
        a0 = math.pi * s / 6; a1 = math.pi * (s + 1) / 6
        p.beam('apoth_green', (GX0 - .02, y0 + rr - rr * math.cos(a0), 1.25 + rr * math.sin(a0)), (GX0 - .02, y0 + rr - rr * math.cos(a1), 1.25 + rr * math.sin(a1)), .03, .03, bevel=0)
for i in range(n_front):
    x0 = GX0 + (GX1 - GX0) * i / n_front; x1 = GX0 + (GX1 - GX0) * (i + 1) / n_front
    rr = (x1 - x0) / 2
    for s in range(6):
        a0 = math.pi * s / 6; a1 = math.pi * (s + 1) / 6
        p.beam('apoth_green', (x0 + rr - rr * math.cos(a0), GY0 - .02, 1.25 + rr * math.sin(a0)), (x0 + rr - rr * math.cos(a1), GY0 - .02, 1.25 + rr * math.sin(a1)), .03, .03, bevel=0)
# Iron cresting and finials along the ridge; one roof light propped open.
for i in range(int((GX1 - GX0) / .16)):
    x = GX0 + .08 + i * .16
    p.cylinder('apoth_green', (x, gcy, GZR + .03), (x, gcy, GZR + .2), .012, 4, radius_b=.004)
p.beam('apoth_green', (GX0, gcy, GZR + .12), (GX1, gcy, GZR + .12), .02, .02, bevel=0)
for x in (GX0 - .02, GX1 - .3):
    p.cylinder('apoth_green', (x, gcy, GZR), (x, gcy, GZR + .45), .03, 6, radius_b=.01)
    p.sphere('apoth_gold', (x, gcy, GZR + .3), .045, 1)
vx = GX0 + 1.2
p.solid('apoth_house_glass', [(vx, GY0 + .4, 2.62), (vx + .55, GY0 + .4, 2.62), (vx + .55, GY0 + .85, 2.98), (vx, GY0 + .85, 2.98)], .01, (0, -1, 1.2))
p.beam('apoth_green', (vx + .27, GY0 + .55, 2.75), (vx + .27, GY0 + .45, 2.55), .02, .02, bevel=0)
# Benches of seedlings and herbs inside.
for y in (GY0 + .45, GY1 - .45):
    p.box('timber', ((GX0 + GX1) / 2, y, .95), (GX1 - GX0 - .3, .55, .05), bevel=.01)
    p.box('timber', ((GX0 + GX1) / 2, y, 1.65), (GX1 - GX0 - .3, .4, .04), bevel=.01)
    for x in (GX0 + .2, GX1 - .2):
        p.box('timber', (x, y, .75), (.05, .5, .45), bevel=0)
    for i in range(6):
        x = GX0 + .4 + i * .42
        k.pot(p, (x, y, .98), scale=.75, plant='flowers', flowers=['leaf', 'flower_white', 'olive'] if i % 2 else ['leaf_light', 'flower_violet'])
        if i % 2:
            k.pot(p, (x + .1, y, 1.67), scale=.5, plant='ivy')
p.sphere('leaf', ((GX0 + GX1) / 2 - .3, gcy, 1.2), .45, 2, squash=(1, 1, 1.3))
p.cylinder('terracotta', ((GX0 + GX1) / 2 - .3, gcy, GZ0 + .06), ((GX0 + GX1) / 2 - .3, gcy, .9), .2, 12, radius_b=.26)
# A glazed garden door in the glasshouse side, toward the clockmaker's yard.
for dy in (-.42, .42):
    p.box('apoth_green', (GX0 - .04, gcy + dy, 1.13), (.07, .07, 2.12), bevel=0)
for z in (GZ0 + .05, 1.2, 2.18):
    p.box('apoth_green', (GX0 - .04, gcy, z), (.07, .9, .07), bevel=0)
p.box('apoth_green', (GX0 - .04, gcy, .87), (.05, .8, .55), bevel=0)
p.box('brass', (GX0 - .1, gcy + .3, 1.15), (.03, .03, .12), bevel=0)

# --- garden life round the front ------------------------------------------------------------------------------------
for x, y, sc, fl in [(-1.15, MY0 - .9, .9, ['flower_violet', 'flower_violet', 'leaf']), (.55, MY0 - .75, .75, ['flower_violet', 'leaf']),
                     (GX0 + .45, GY0 - .4, .8, ['flower_violet', 'leaf_light']), (GX1 - .55, GY0 - .38, .7, ['flower_white', 'leaf']),
                     (MX1 + .35, MY0 - .3, .8, ['leaf', 'flower_white'])]:
    k.pot(p, (x, y, 0), scale=sc, plant='flowers', flowers=fl)
# Long timber planter along the glasshouse front.
p.box('timber', ((GX0 + GX1) / 2, GY0 - .38, .22), (1.5, .4, .38), bevel=.015)
for i in range(9):
    x = (GX0 + GX1) / 2 - .65 + i * .16
    p.sphere('leaf_dark', (x, GY0 - .38, .46), .1, 1, squash=(1, 1, .8))
    p.sphere('flower_violet' if i % 2 else 'flower_pink', (x, GY0 - .42, .55), .045, 1)
# Climbing rose on the downpipe between the glasshouse and the porch.
k.climber(p, (MX0 + .1, MY0 - .12, .0), 3.2, F, spread=.32, flowers=('flower_white', 'flower_white'), density=14)
# Watering can beside the step.
wc = Vector((-1.75, MY0 - .55, 0))
p.cylinder('lead', wc, wc + Vector((0, 0, .26)), .12, 10)
p.beam('lead', wc + Vector((.1, 0, .12)), wc + Vector((.32, 0, .3)), .03, .03)
p.beam('lead', wc + Vector((-.08, 0, .3)), wc + Vector((.06, 0, .3)), .02, .06)
# Rear service side: drying rail, water butt, crates.
k.barrel(p, (MX1 - .7, MY1 + .45, 0), radius=.3, height=.72)
k.crate(p, (MX0 + 1.0, MY1 + .4, 0), (.6, .45, .38))
k.crate(p, (MX0 + 1.05, MY1 + .42, .38), (.5, .4, .3), rot=.2)
k.door(p, MX0 + 1.65, MY1, .95, 2.25, (0, 1), style='plank', leaf_mat='apoth_plum', recess=.14)
k.window(p, (MX0 + 4.05, MY1, 1.65), .85, 1.05, (0, 1), shutters='none', box=False)
k.window(p, (MX1, MY0 + 1.55, 1.6), .7, 1.1, (1, 0), shutters='open', box=True, shutter_mat='apoth_plum', flowers=['flower_violet', 'flower_white'])

# --- finish --------------------------------------------------------------------------------------------------------
p.finish(root)
for name, centre in [('door_leaf_apothecary', hinge)]:
    matches = [o for o in bpy.context.scene.objects if o.name == name or o.name == name + '_glass']
    if not matches:
        raise RuntimeError('Missing semantic part ' + name)
    for obj in matches:
        for v in obj.data.vertices:
            v.co -= centre
        obj.location = centre
        obj['part'] = name
        obj['swing'] = -100
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1
scene['rootward_source'] = 'Original apothecary concept v2; model.blend is editable authority. No preset building was imported.'
scene['concept_reference'] = 'art/source/world/spindle-strip/v1/apothecary-concept.png'
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            area.spaces.active.region_3d.view_location = (0, 0, 4)
            area.spaces.active.region_3d.view_distance = 20
            area.spaces.active.shading.type = 'MATERIAL'
bpy.ops.file.pack_all()
if DRAFT is not None:
    out = DRAFT / 'haverlund-apothecary' / 'model.blend'
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out))
    print('DRAFT APOTHECARY', out)
else:
    bpy.ops.wm.save_as_mainfile(filepath=str(TARGET))
    TARGET.with_name('provenance.json').write_text(json.dumps({
        'asset': 'haverlund-apothecary', 'version': 'v2', 'date': '2026-11-05',
        'reference': scene['concept_reference'], 'record': str(Path(__file__).relative_to(ROOT)),
        'record_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'shared_utilities': 'art/source/world/seaside-houses/v1/house_kit.py', 'palette': PALETTE,
        'geometry': 'Independently authored stone body, steep slate roof with hipped end, front cross gable with herb '
                    'drying pole, arched dormer with copper hood, bowed glazed shopfront with fascia and copper roof, '
                    'recessed porch with arched green frame and hinged plum door, herb glasshouse wing with cresting, '
                    'hanging mortar-and-pestle sign. No existing building mesh imported.',
        'retained_previous_source': 'art/source/world/haverlund-apothecary/v1/model.blend'}, indent=2) + '\n')
    print('ORIGINAL APOTHECARY SAVED', TARGET)
