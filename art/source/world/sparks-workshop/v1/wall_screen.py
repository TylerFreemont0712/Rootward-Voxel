"""One-time authoring of the workshop's wall screen: the zone node the field tablet jacks into.

Refuses an existing master. After creation, edit model.blend and export with scripts/world-art.sh build workshop-wall-screen.
Blender +Y is the wall; the front (the room side) faces -Y. The glass keeps the name terminal_screen and the
indicator connection_lamp, which the game finds by name for the zone's lettering and lamp.
"""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ASSET = 'workshop-wall-screen'
SOURCE = ROOT / 'art/source/world' / ASSET / 'v1/model.blend'
if SOURCE.exists():
    raise RuntimeError('Existing workshop-wall-screen master; edit it instead of regenerating.')
spec = importlib.util.spec_from_file_location('loft_helpers', ROOT / 'art/source/world/sparks-loft/v1/author.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
h.start(ASSET)
h.material('screen_glass', '173d3c', emission=.12)
h.material('terminal_cream', 'e8ddc2')
h.material('terminal_shadow', 'b6b09b')
h.material('terminal_teal', '3d7773')
h.material('steel_dark', '343e44', metallic=.3)
h.material('steel', '6d777d', metallic=.35)
B = h.box

# A cream enamel panel on a teal backplate, flat against the wall. Nothing about it is a desk computer:
# no keys, a long glass, and a brass-collared socket below it where a slate's plug seats.
B('Teal wall plate', (0, -.015, .42), (1.30, .03, .84), 'teal_dark', .05, 4)
for sx in (-1, 1):
    for z in (.065, .775):
        h.sphere('Brass mounting screw', (sx * .59, -.034, z), (.022, .012, .022), 'brass', 12, 6)
B('Cream enamel housing', (0, -.075, .42), (1.20, .09, .74), 'terminal_cream', .05, 4)
B('Teal inner bezel', (0, -.122, .49), (1.00, .02, .50), 'terminal_teal', .03, 4)
B('Dark screen well', (0, -.132, .495), (.94, .012, .45), 'ink', .02, 4)
glass = B('terminal_screen', (0, -.140, .495), (.90, .008, .45), 'screen_glass', .015, 4)
h.curve('Glass upper glint', [(-.40, -.146, .695), (-.40, -.147, .71), (-.32, -.147, .71)], .003, 'teal_light')

# The jack panel under the glass.
B('Teal jack panel', (0, -.128, .155), (1.00, .02, .15), 'terminal_teal', .02, 3)
rim = h.torus('Socket brass collar', (0, -.143, .155), .05, .0125, 'brass', (math.pi / 2, 0, 0))
bore = h.cylinder('Socket bore', (0, -.145, .155), .038, .012, 'ink', 24)
bore.rotation_euler.x = math.pi / 2
h.box('Socket key notch', (0, -.147, .205), (.014, .008, .022), 'ink', .002)
for x in (-.34, -.25):
    knob = h.cylinder('Cream dial', (x, -.147, .155), .033, .02, 'cream', 20)
    knob.rotation_euler.x = math.pi / 2
    cap = h.cylinder('Brass dial cap', (x, -.157, .155), .014, .008, 'brass', 14)
    cap.rotation_euler.x = math.pi / 2
B('Blank brass label plate', (-.44, -.141, .155), (.09, .008, .045), 'brass', .006)
B('Blank brass label plate', (.44, -.141, .155), (.09, .008, .045), 'brass', .006)
lamp = h.sphere('connection_lamp', (.27, -.145, .155), (.026, .012, .026), 'ochre', 12, 6)

# The node is wired into the building: a conduit rising from the top rail to the ceiling.
B('Brass top rail', (0, -.095, .805), (1.12, .07, .036), 'brass', .012, 2)
h.rod('Wall conduit', (0, -.045, .82), (0, -.045, 1.95), .03, 'steel_dark', 16)
for z in (1.05, 1.5):
    B('Brass conduit clamp', (0, -.045, z), (.085, .06, .05), 'brass', .012, 2)
    for sx in (-1, 1):
        h.sphere('Clamp screw', (sx * .055, -.077, z), (.01, .008, .01), 'brass', 10, 6)

for obj in bpy.context.scene.objects:
    if obj.type == 'MESH':
        obj['part'] = 'screen' if obj == glass else ('connection' if obj == lamp else 'case')
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1
bpy.context.scene['rootward_source'] = 'Editable authority; the workshop zone node with a jack socket.'
bpy.ops.file.pack_all()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(SOURCE.parent / 'provenance.json').write_text(json.dumps({
    'asset': ASSET, 'date': '2026-10-27',
    'authoring_record': 'art/source/world/sparks-workshop/v1/wall_screen.py',
    'authoring_record_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
    'reference': 'docs/concept/v0.7/art/4-opening/T7b-workshop-floor.png',
    'note': 'New source; no adopted master overwritten. Native geometry and the existing palette. Blender source is now authority.'}, indent=2) + '\n')
print('AUTHORED', ASSET, flush=True)
