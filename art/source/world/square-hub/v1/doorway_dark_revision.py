"""Deliberate, backed-up source edit: the doorway between the street and the workshop no longer shows a picture.

    lane-workshop         the green street doors opened onto a painted warm shop. The quad behind them is now flat
                          black (a new `doorway_dark` material), so the shop reads as a dark room and the apprentice
                          walks out of the dark.
    workshop-shop-doors   the same doors from inside opened onto a painted harbour hung in mid-air beyond the room.
                          That quad is removed; the doorway is open to the room's own backdrop. The transom glass
                          above the doors keeps its harbour view.

Only the `doorway_beyond` quad of each model is touched. The file as it was is kept once as
model.pre-doorway-dark.blend. Export afterwards with scripts/world-art.sh build <id>.

    blender --background --factory-startup --python art/source/world/square-hub/v1/doorway_dark_revision.py -- <id>
"""
import json
import shutil
import sys
from pathlib import Path

import bpy

ROOT = Path(__file__).resolve().parents[5]
QUAD = 'doorway_beyond'


def dark_material():
    material = bpy.data.materials.get('doorway_dark') or bpy.data.materials.new('doorway_dark')
    material.use_nodes = True
    nodes = material.node_tree.nodes
    nodes.clear()
    output = nodes.new('ShaderNodeOutputMaterial')
    shader = nodes.new('ShaderNodeBsdfPrincipled')
    shader.inputs['Base Color'].default_value = (0.0, 0.0, 0.0, 1.0)
    shader.inputs['Roughness'].default_value = 1.0
    shader.inputs['Metallic'].default_value = 0.0
    for name in ('Specular IOR Level', 'Specular'):
        if name in shader.inputs:
            shader.inputs[name].default_value = 0.0
    material.node_tree.links.new(shader.outputs['BSDF'], output.inputs['Surface'])
    return material


def revise(asset):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = source.with_name('model.pre-doorway-dark.blend')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    quad = bpy.data.objects.get(QUAD)
    if quad is None:
        raise SystemExit(f'{asset} has no {QUAD}; it was already revised or the model has changed.')
    if not backup.exists():
        shutil.copy2(source, backup)
    if asset == 'lane-workshop':
        quad.data.materials.clear()
        quad.data.materials.append(dark_material())
        result = 'doorway quad is flat black'
    else:
        mesh = quad.data
        bpy.data.objects.remove(quad, do_unlink=True)
        if mesh.users == 0:
            bpy.data.meshes.remove(mesh)
        result = 'doorway quad removed'
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    source.with_name('doorway-dark.json').write_text(json.dumps({
        'asset': asset, 'date': '2026-10-30', 'record': 'art/source/world/square-hub/v1/doorway_dark_revision.py',
        'backup': backup.name, 'result': result,
        'note': 'Only the doorway_beyond quad changed; geometry and the transom glass are untouched.'}, indent=2) + '\n')
    print('REVISED', asset, result, flush=True)


if __name__ == '__main__':
    revise(sys.argv[sys.argv.index('--') + 1])
