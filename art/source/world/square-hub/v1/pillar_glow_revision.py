"""Deliberate, backed-up source edit of the adopted town-power-pillar: the whole column is now the power strip.

The first version kept stone stiles either side of a 0.62 m pane, which read in game as the old pilasters with a slit
down the middle. Here the stone shaft goes: the column is one tall amber glass shaft, 1.12 m across its face and
wrapping round both sides back to the wall, held by slim brass corner rails and thin brass hoops every 2.4 m. The
moulded stone capital under the coping and the plinth where the square's 10 m walls meet the lower town stay.
The glass keeps the `power_column` flag, so Godot gives it the climbing-light shader (art/power_column.gdshader).
The file as it was is kept once as model.pre-full-glow.blend.

    blender --background --factory-startup --python art/source/world/square-hub/v1/pillar_glow_revision.py
"""
import json
import shutil
import sys
from pathlib import Path

import bpy

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
import author_street as street  # noqa: E402

kit = street.kit
ROOT = HERE.parents[4]
SOURCE = ROOT / 'art/source/world/town-power-pillar/v1/model.blend'
DEPTH, HALF = .52, .56          # the glass face stands DEPTH out of the wall and runs HALF either side of the centre
BOTTOM, TOP = -14.0, -.7        # the shaft hangs from just under the capital (buried where a wall is shorter)
HOOPS = 2.4


def column(p):
    face = -DEPTH
    with p.into('pillar_glass'):
        uv = [[(0, BOTTOM), (1, BOTTOM), (1, TOP), (0, TOP)]]
        p.add('pillar_glass', [(-HALF, face, BOTTOM), (HALF, face, BOTTOM), (HALF, face, TOP), (-HALF, face, TOP)], [(0, 1, 2, 3)], uv)
        for x in (-HALF, HALF):
            side = [(x, face, BOTTOM), (x, -.02, BOTTOM), (x, -.02, TOP), (x, face, TOP)]
            p.add('pillar_glass', side if x > 0 else list(reversed(side)), [(0, 1, 2, 3)], uv)
    street.flag_last(p, 'pillar_glass', 'power_column')
    height = TOP - BOTTOM
    # Slim brass rails on the two front corners and where the sides meet the wall.
    for x in (-HALF, HALF):
        p.box('brass', (x, face, (BOTTOM + TOP) / 2), (.055, .055, height), bevel=.01, uv='flat')
        p.box('brass', (x, -.03, (BOTTOM + TOP) / 2), (.05, .05, height), bevel=.008, uv='flat')
    # Thin brass hoops round the three glass faces, with a rivet at each front corner.
    z = TOP - 1.2
    while z > BOTTOM + .4:
        p.box('brass', (0, face - .012, z), (2 * HALF + .06, .035, .06), bevel=.01, uv='flat')
        for x in (-HALF, HALF):
            p.box('brass', (x + (.012 if x > 0 else -.012), face / 2, z), (.035, DEPTH, .06), bevel=.01, uv='flat')
            p.sphere('brass', (x, face - .03, z), .03, 1)
        z -= HOOPS
    # A brass collar where the glass meets the capital.
    p.box('brass', (0, face / 2 - .01, TOP + .03), (2 * HALF + .12, DEPTH + .06, .1), bevel=.015, uv='flat')
    # The capital under the coping: a moulded stone block, a brass plate with the city's sprout.
    width = 2 * HALF + .08
    p.box('stone', (0, -.275 - .04, -.42), (width + .16, .55 + .08, .4), bevel=.03, segments=2, uv=('blocks', 0))
    p.box('stone', (0, -.275 - .02, -.66), (width + .04, .55 + .04, .1), bevel=.015, uv=('blocks', 0))
    p.box('brass', (0, -.55 - .06, -.42), (.5, .03, .26), bevel=.01, uv='flat')
    p.box('brass', (0, -.55 - .075, -.42), (.06, .01, .18), bevel=0, uv='flat')
    for side in (-1, 1):
        p.box('brass', (side * .07, -.55 - .075, -.38), (.1, .01, .04), (0, side * .6, 0), 0, 'flat')
    # The plinth where the square's 10 m walls meet the lower town (buried under shorter walls).
    p.box('stone', (0, -.275 - .05, -9.7), (width + .2, .55 + .1, .6), bevel=.03, uv=('blocks', 0))


def main():
    bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
    scene = bpy.context.scene
    if scene.get('pillar_revision') == 'full-glow':
        raise SystemExit('town-power-pillar is already the full glass column; edit model.blend directly.')
    backup = SOURCE.with_name('model.pre-full-glow.blend')
    if not backup.exists():
        shutil.copy2(SOURCE, backup)
    root = next(o for o in scene.objects if o.type == 'EMPTY' and o.parent is None)
    kit.M.clear()
    for mat in bpy.data.materials:
        kit.M[mat.name] = mat
    for obj in list(root.children):
        if obj.type == 'MESH':
            mesh = obj.data
            bpy.data.objects.remove(obj)
            bpy.data.meshes.remove(mesh)
    street.FLAGS.clear()
    parts = kit.Parts(4200)
    column(parts)
    street.finish(parts, root)
    scene['pillar_revision'] = 'full-glow'
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
    SOURCE.with_name('full-glow-revision.json').write_text(json.dumps({
        'asset': 'town-power-pillar', 'date': '2026-10-29', 'record': 'art/source/world/square-hub/v1/pillar_glow_revision.py',
        'backup': backup.name, 'glass_face': [2 * HALF, DEPTH], 'hangs': [TOP, BOTTOM], 'hoops': HOOPS,
        'note': 'The stone stiles replaced by one full-width glass shaft wrapping the sides; capital and plinth kept.'}, indent=2) + '\n')
    print('REVISED town-power-pillar', flush=True)


if __name__ == '__main__':
    main()
