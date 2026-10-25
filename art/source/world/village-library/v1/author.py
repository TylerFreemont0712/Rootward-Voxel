"""Author exactly one new asset. Refuses existing .blend; normal rebuilds use scripts/world-art.sh.

blender --background --factory-startup --python-exit-code 1 --python <this file> -- hollow-<id>
"""
import hashlib
import importlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Euler, Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
sys.path.insert(0, str(HERE))
from modeling import Model, materials

args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else []
if len(args) != 1:
    raise RuntimeError('Pass exactly one asset id; models are authored and checked one by one.')
specs = json.loads((HERE / 'library.json').read_text())['assets']
spec = next((item for item in specs if item['id'] == args[0]), None)
if spec is None:
    raise RuntimeError('Unknown library asset: ' + args[0])
folder = ROOT / 'art/source/world' / spec['id'] / 'v1'
source = folder / 'model.blend'
if source.exists():
    raise RuntimeError('Editable source already exists. Preserve it; edit in Blender and use scripts/world-art.sh build ' + spec['id'])

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
module_name = spec['category'].replace('village-magic', 'village_magic')
module = importlib.import_module(module_name)
model = Model()
getattr(module, spec['recipe'])(model)
model.finish(materials())
points = [obj.matrix_world @ Vector(v) for obj in bpy.context.scene.objects if obj.type == 'MESH' for v in obj.bound_box]
# Update the authored parent pivots before measuring the model.
bpy.context.view_layer.update()
points = [obj.matrix_world @ Vector(v) for obj in bpy.context.scene.objects if obj.type == 'MESH' for v in obj.bound_box]
lower = [min(p[i] for p in points) for i in range(3)]
upper = [max(p[i] for p in points) for i in range(3)]
if abs(lower[2]) > .025 or max(upper[i]-lower[i] for i in range(3)) > 4:
    raise RuntimeError('Model must be grounded and fit the small-object library envelope: ' + str((lower,upper)))
bpy.context.scene.unit_settings.system = 'METRIC'
bpy.context.scene.unit_settings.scale_length = 1.0
bpy.context.scene['rootward_source'] = 'Village library v1: editable master; never regenerate over this file.'
bpy.context.scene['asset_id'] = spec['id']
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type == 'VIEW_3D':
            region = area.spaces.active.region_3d
            region.view_location = (Vector(lower)+Vector(upper))*.5
            region.view_distance = max((Vector(upper)-Vector(lower)).length*1.6,2.5)
            region.view_rotation = Euler((math.radians(60),0,math.radians(45))).to_quaternion()
            region.view_perspective = 'ORTHO'
            area.spaces.active.shading.type = 'MATERIAL'
bpy.context.preferences.filepaths.save_version = 0
bpy.ops.file.pack_all()
folder.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(source))
dependencies = [Path(__file__),HERE/'modeling.py',HERE/(module_name+'.py'),HERE/'library.json']
provenance = {
    'asset':spec['id'],'version':'v1','authoring_tool':'Blender 5.2.2 LTS; deliberate scripted geometry',
    'source_authority':'model.blend; this script is a protected one-time authoring record',
    'recipe':spec['recipe'],'sources':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in dependencies},
    'materials':'Shared village palette; existing lush texture PNGs packed losslessly; no generated-image dependency.',
    'blender_bounds':[lower,upper], 'spec':spec,
}
(folder/'provenance.json').write_text(json.dumps(provenance,indent=2,ensure_ascii=False)+'\n')
height = upper[2]-lower[2]
interaction = spec['interaction']
(folder/'brief.md').write_text(f'''# Asset brief: {spec['id']}

Status: authored for the village builder library.

- Purpose: {spec['blurb']}
- Reference: the approved voxel village; warm substantial forms, painted timber/cream stone, restrained violet/teal/brass.
- Source: `art/source/world/{spec['id']}/v1/model.blend`, authored individually in Blender 5.2.2 LTS.
- One-time recipe: `{module_name}.py::{spec['recipe']}` in `art/source/world/village-library/v1/`; provenance records dependencies.
- Dimensions: approximately {upper[0]-lower[0]:.2f} × {upper[1]-lower[1]:.2f} × {height:.2f} metres; the boy is 1.45 metres high.
- Pivot: centred at ground; front Blender -Y / Godot +Z. One metre is one cell.
- Blocking footprint: {spec['width']} × {spec['depth']} metres; decorative handles, cloth, horns and caps may slightly overhang it.
- Materials: semantic named materials and continuous world-scale UVs; packed PNG textures from the existing lush set. No new runtime service.
- Moving/changing parts: {json.dumps(interaction)}. Authored `mechanism` pivot or separate `state_glow` / `state_flame` material meshes as applicable.
- Runtime: `assets/world/{spec['id']}/model.glb`; registered in the world and builder catalogs.
- Rebuild: `scripts/world-art.sh build {spec['id']}` reads this saved source without modifying it. Never rerun the author over it.
- Review: see `pipeline/reviews/2026-10-24-builder-library.md`; individual captures and a second placement/rebuild are part of that review.
''')
print('Authored one asset:',spec['id'],'bounds:',lower,upper)
