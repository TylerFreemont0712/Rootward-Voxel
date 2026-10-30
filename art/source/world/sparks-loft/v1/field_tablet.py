"""One-time authoring of Nell's field tablet: the slate the traveller carries between rooms.

Refuses an existing master. After creation, edit model.blend and export with scripts/world-art.sh build field-tablet.
The model rests on its bottom face with its cord coiled beside it, as it lies on the loft bed; its screen is unlit.
"""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ASSET = 'field-tablet'
SOURCE = ROOT / 'art/source/world' / ASSET / 'v1/model.blend'
if SOURCE.exists():
    raise RuntimeError('Existing field-tablet master; edit it instead of regenerating.')
spec = importlib.util.spec_from_file_location('loft_helpers', HERE / 'author.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
h.start(ASSET)
h.material('screen_glass', '173d3c', emission=.12)
h.material('screen_ink', '9de0c1', emission=.5)
h.material('steel', '6d777d', metallic=.35)
B = h.box

W, D, T = .32, .22, .024            # twelve inches by eight, a little over half an inch thick
B('Cream enamel case', (0, 0, T / 2), (W, D, T), 'cream', .022, 3)
B('Teal glass surround', (0, 0, T + .002), (W - .04, D - .04, .008), 'teal_dark', .012, 3)
B('Slate glass', (0, 0, T + .007), (W - .075, D - .075, .004), 'screen_glass', .012, 3)
for i, width in enumerate((.17, .13, .15)):
    B('Faint screen line %d' % i, (-.045 + (width - .17) / 2, .045 - i * .036, T + .0095), (width, .009, .0014), 'screen_ink', 0)
for sx in (-1, 1):
    for sy in (-1, 1):
        B('Brass corner cap', (sx * (W / 2 - .02), sy * (D / 2 - .02), T / 2), (.046, .046, T + .004), 'brass', .014, 2)
h.sphere('Brass indicator', (-W / 2 + .052, 0, T + .006), (.009, .009, .005), 'ochre', 12, 6)

# The cord leaves the right edge, coils twice on whatever the slate rests on, and ends in a brass plug.
cx, cy = W / 2 + .13, .0
lead = [(W / 2 - .01, 0, T / 2), (W / 2 + .03, .0, .010), (cx + .07, cy, .009)]
h.curve('Slate cord lead', lead, .0075, 'cable')
coil = []
steps = 26
for k in range(steps + 1):
    t = k / steps
    angle = t * 3.5 * math.pi
    radius = .07 - t * .04
    coil.append((cx + radius * math.cos(angle), cy + radius * math.sin(angle), .009 + t * .002))
h.curve('Coiled slate cord', coil, .0075, 'cable')
tail = [(cx, cy - .03, .011), (cx, cy - .06, .022), (cx, cy - .10, .02), (cx, cy - .135, .013)]
h.curve('Slate cord tail', tail, .0075, 'cable')
collar = h.cylinder('Brass plug collar', (cx, cy - .152, .0135), .0115, .03, 'brass', 18)
collar.rotation_euler.x = math.pi / 2
barrel = h.cylinder('Plug barrel', (cx, cy - .184, .0135), .0075, .036, 'steel', 14)
barrel.rotation_euler.x = math.pi / 2
tip = h.sphere('Plug tip', (cx, cy - .204, .0135), (.0075, .006, .0075), 'steel', 10, 6)

for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        obj['part'] = 'slate'
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1
bpy.context.scene['rootward_source'] = 'Editable authority; the traveller\'s field tablet and its cord.'
bpy.ops.file.pack_all()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(SOURCE.parent / 'provenance.json').write_text(json.dumps({
    'asset': ASSET, 'date': '2026-10-27',
    'authoring_record': 'art/source/world/sparks-loft/v1/field_tablet.py',
    'authoring_record_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'style_reference': 'docs/concept/v0.7/art/4-opening/T7a-workshop-loft.wheels.png',
    'note': 'New source; no adopted master overwritten. Native geometry and the existing loft palette. Blender source is now authority.'}, indent=2) + '\n')
print('AUTHORED', ASSET, flush=True)
