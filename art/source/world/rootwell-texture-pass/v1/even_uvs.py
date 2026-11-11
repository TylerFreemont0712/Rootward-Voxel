"""Saved-master edit: even texture density on the Rootwell and its plaza.

The adopted masters mapped their dressed stone (and the beacon's verdigris metal) at very different scales from face
to face: from 0.15 to 3.7 UV units per metre, so some stones showed one blotch of the painting stretched over six
metres while their neighbours were crowded. This copies a master to its next version and re-projects the UVs of the
named materials from world position, per face along its dominant axis, at one repeat (the square's own 1.9 m for
stone). The stone picture is coursed masonry, right for walls but not for flags and treads that are already modelled
stone by stone, so an upward face of a material marked `@` instead takes the inside of one painted block (one of six,
chosen by the face's position), and no painted joint crosses a modelled one. Geometry, materials and every other UV
are untouched.

    blender -b --factory-startup --python even_uvs.py -- <asset> <from version> <to version> <material>[@]=<repeat m> ...
"""
from pathlib import Path
import bpy, hashlib, json, sys
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
args = sys.argv[sys.argv.index('--') + 1:]
asset, old, new = args[0], args[1], args[2]
repeats = {pair.split('=')[0].rstrip('@'): float(pair.split('=')[1]) for pair in args[3:]}
blocky = {pair.split('=')[0].rstrip('@') for pair in args[3:] if pair.split('=')[0].endswith('@')}
# Inside six blocks of the 512 px seaside stone painting (x0, y0, x1, y1 in pixels from the top left), clear of joints.
BLOCKS = [(140, 120, 280, 175), (305, 120, 450, 175), (170, 280, 310, 335), (335, 280, 480, 335), (165, 440, 300, 495), (325, 440, 460, 495)]
SRC = ROOT / f'art/source/world/{asset}/{old}/model.blend'
DST = ROOT / f'art/source/world/{asset}/{new}/model.blend'
if DST.exists():
    raise RuntimeError(f'{DST} exists; edit the saved master instead.')
bpy.ops.wm.open_mainfile(filepath=str(SRC))
before = hashlib.sha256(SRC.read_bytes()).hexdigest()
counts = {name: 0 for name in repeats}
for obj in bpy.context.scene.objects:
    if obj.type != 'MESH' or not obj.data.uv_layers:
        continue
    names = [s.material.name if s.material else '' for s in obj.material_slots]
    if not any(n in repeats for n in names):
        continue
    if obj.data.users > 1:
        obj.data = obj.data.copy()
    mw = obj.matrix_world
    rot = mw.to_3x3()
    uv = obj.data.uv_layers.active.data
    for poly in obj.data.polygons:
        name = names[poly.material_index] if poly.material_index < len(names) else ''
        if name not in repeats:
            continue
        n = (rot @ poly.normal).normalized()
        if name in blocky and n.z > 0.85:
            points = [mw @ obj.data.vertices[obj.data.loops[li].vertex_index].co for li in poly.loop_indices]
            x0 = min(q.x for q in points); x1 = max(q.x for q in points); y0 = min(q.y for q in points); y1 = max(q.y for q in points)
            centre = sum(points, Vector()) / len(points)
            bx0, by0, bx1, by1 = BLOCKS[int(abs(centre.x * 7.31 + centre.y * 3.17 + centre.z * 1.7) * 13) % len(BLOCKS)]
            # The block's long side follows the face's long side.
            along_x = (x1 - x0) >= (y1 - y0)
            for li, q in zip(poly.loop_indices, points):
                s_ = (q.x - x0) / max(x1 - x0, 1e-4); t_ = (q.y - y0) / max(y1 - y0, 1e-4)
                if not along_x: s_, t_ = t_, s_
                uv[li].uv = ((bx0 + (bx1 - bx0) * s_) / 512.0, 1.0 - (by0 + (by1 - by0) * t_) / 512.0)
            counts[name] += 1
            continue
        axis = max(range(3), key=lambda i: abs(n[i]))
        a, b = [(1, 2), (0, 2), (0, 1)][axis]
        size = repeats[name]
        for li in poly.loop_indices:
            w = mw @ obj.data.vertices[obj.data.loops[li].vertex_index].co
            uv[li].uv = (w[a] / size, w[b] / size)
        counts[name] += 1
bpy.context.scene['even_uvs'] = json.dumps(repeats)
bpy.context.preferences.filepaths.save_version = 0
DST.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(DST))
record = {'asset': asset, 'previous': old, 'previous_sha256': before, 'record': str(Path(__file__).relative_to(ROOT)),
          'repeat_m': repeats, 'faces_reprojected': counts}
(DST.parent / 'even-uvs.json').write_text(json.dumps(record, indent=2) + '\n')
print('EVEN UVS SAVED', json.dumps(record))
