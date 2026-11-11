"""Review refinement: connect the planter bench's scattered blooms to its new sprigs."""
from pathlib import Path
import importlib.util
import json
import shutil
import bpy
import bmesh
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('plant_revision', HERE / 'revise.py')
r = importlib.util.module_from_spec(spec)
spec.loader.exec_module(r)
path = ROOT / 'art/source/world/town-planter-bench/v1/model.blend'
record_path = path.with_name('plant-style.json')
record = json.loads(record_path.read_text())
if 'flower_stems' in record:
    raise RuntimeError('Already refined; edit the saved bench master.')
bpy.ops.wm.open_mainfile(filepath=str(ROOT / record['backup']))
old = bpy.data.objects['house_paint']
bm = bmesh.new()
bm.from_mesh(old.data)
bm.verts.ensure_lookup_table()
bm.faces.ensure_lookup_table()
uv = bm.loops.layers.uv.active
leaves, flowers = [], []
for verts in r.inventory.components(bm):
    faces = {f for v in verts for f in v.link_faces}
    colour = r.inventory.colour(old, faces, uv)
    centre = sum((old.matrix_world @ v.co for v in verts), Vector()) / len(verts)
    if colour in {'leaf', 'leaf_dark', 'leaf_light'}:
        leaves.append(centre)
    elif colour.startswith('flower_'):
        flowers.append(centre)
bm.free()
previous = ROOT / '.cache/world-art/town-planter-bench/previous.glb'
shutil.copy2(previous, ROOT / '.cache/plant-style/bench-before.glb')
bpy.ops.wm.open_mainfile(filepath=str(path))
bpy.context.preferences.filepaths.save_version = 0
obj = bpy.data.objects['house_paint']
bm = bmesh.new()
bm.from_mesh(obj.data)
drawing = r.Drawing(bm, obj)
drawing.uv = r.inventory.kit.paint_uv('leaf_dark')
for centre in flowers:
    base = min(leaves, key=lambda leaf: (leaf - centre).length)
    drawing.stem(base, centre, .007)
bm.to_mesh(obj.data)
bm.free()
obj.data.update()
bpy.ops.wm.save_as_mainfile(filepath=str(path))
record['flower_stems'] = len(flowers)
record['after_sha256'] = r.digest(path)
record_path.write_text(json.dumps(record, indent=2) + '\n')
records = json.loads((HERE / 'revision.json').read_text())
records = [record if item['asset'] == record['asset'] else item for item in records]
(HERE / 'revision.json').write_text(json.dumps(records, indent=2) + '\n')
