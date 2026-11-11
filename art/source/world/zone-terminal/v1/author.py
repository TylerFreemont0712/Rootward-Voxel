"""One-time authoring of a reusable outlined zone computer. Refuses existing masters.
After creation, edit model.blend and export with scripts/world-art.sh build zone-terminal.
"""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SOURCE = HERE / 'model.blend'
if SOURCE.exists():
    raise RuntimeError('Existing zone-terminal master; edit it instead of regenerating.')
spec = importlib.util.spec_from_file_location('loft_helpers', ROOT / 'art/source/world/sparks-loft/v1/author.py')
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
h.start('zone-terminal')
h.material('screen_glass', '173d3c', emission=.12)
h.material('screen_ink', '9de0c1', emission=.5)
h.material('terminal_cream', 'e8ddc2')
h.material('terminal_shadow', 'b6b09b')
h.material('terminal_teal', '3d7773')
B = h.box
# Low keyboard deck and two feet; the face is Blender -Y / Godot +Z.
for x in (-.30, .30):
    B('Soft rubber foot', (x, .015, .025), (.12, .37, .05), 'rubber', .018)
B('Teal lower chassis', (0, -.055, .085), (.86, .62, .10), 'teal_dark', .045, 4)
B('Cream keyboard deck', (0, -.105, .155), (.83, .57, .10), 'terminal_cream', .035, 4)
# A rounded monitor and substantial surround, with a genuinely recessed screen.
B('Monitor shell', (0, .13, .445), (.79, .35, .55), 'terminal_cream', .065, 5)
B('Teal inner bezel', (0, -.052, .47), (.67, .036, .385), 'terminal_teal', .035, 4)
B('Dark screen well', (0, -.075, .48), (.604, .018, .314), 'ink', .022, 4)
screen = B('terminal_screen', (0, -.087, .48), (.578, .009, .288), 'screen_glass', .018, 4)
# Screen corner reflection, deliberately on the glass rather than an external aura.
h.curve('Glass upper glint', [(-.24, -.094, .589), (-.24, -.095, .606), (-.18, -.095, .606)], .003, 'teal_light')
# Four rows of individual ivory keys; a long spacebar and a distinct send key.
for row in range(3):
    for col in range(9):
        B('Ivory key %d %d' % (row, col), (-.285+col*.064, -.319+row*.065, .219), (.048, .043, .023), 'cream', .006)
B('Long space key', (-.05, -.37, .219), (.31, .038, .023), 'terminal_shadow', .006)
B('Teal send key', (.28, -.37, .221), (.10, .042, .026), 'terminal_teal', .009)
for x in (-.31, -.27, -.23):
    B('Speaker grille slot', (x, -.064, .255), (.018, .012, .036), 'ink', .004)
light = h.sphere('connection_lamp', (.284, -.075, .266), (.016, .009, .016), 'ochre', 12, 6)
knob = h.cylinder('Screen brightness knob', (.344, -.073, .27), .025, .018, 'brass', 16)
knob.rotation_euler.x = math.pi/2
# Side vents, exposed port and rear strain relief communicate a connected appliance.
for i in range(5):
    B('Side vent %d' % i, (.397, .085+i*.031, .42), (.009, .015, .13), 'terminal_shadow', .003)
B('Handset docking port', (.422, -.04, .12), (.015, .075, .025), 'ink', .005)
h.curve('Rear power lead', [(0,.30,.15),(.15,.37,.12),(.31,.40,.09),(.41,.37,.045)], .012, 'cable')
# Keep screen and connection indicator independent for presentation.
for obj in bpy.context.scene.objects:
    if obj.type == 'MESH': obj['part'] = 'screen' if obj == screen else ('connection' if obj == light else 'case')
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1
bpy.context.scene['rootward_source'] = 'Editable authority; reusable Sparks zone computer.'
bpy.ops.file.pack_all()
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(HERE/'provenance.json').write_text(json.dumps({'asset':'zone-terminal','date':'2026-10-27','authoring_record':'art/source/world/zone-terminal/v1/author.py','authoring_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'style_reference':'docs/concept/v0.7/art/4-opening/T7a-workshop-loft.wheels.png','note':'New source; no adopted master overwritten. Native geometry and existing palette. Blender source is now authority.'},indent=2)+'\n')
