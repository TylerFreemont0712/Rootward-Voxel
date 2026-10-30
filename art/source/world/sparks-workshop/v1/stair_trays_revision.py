"""Deliberate edit of the adopted workshop staircase, preserving the previous master.

Since the staircase was turned round (2026-10-28) its high end stands in the middle of the workshop floor, and the
two parts trays with the teal lidded box sat on the floor beneath it, where the room now lets you walk under the
stairs. This slides only those pieces (trays, washers, screws, the box and its papers) back along the flight to under
its low part, where there is no headroom to walk anyway. Nothing else in the model changes.

Run: blender --background --python-exit-code 1 --python art/source/world/sparks-workshop/v1/stair_trays_revision.py
"""
from pathlib import Path
import hashlib
import json
import shutil
import bmesh
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SOURCE = ROOT / 'art/source/world/workshop-staircase/v1/model.blend'
BACKUP = SOURCE.with_name('model.pre-stair-trays.blend')
NOTE = SOURCE.with_name('stair-trays-revision.json')
if NOTE.exists() or BACKUP.exists():
    raise RuntimeError('This deliberate staircase edit already ran; edit the saved master instead.')
# The trays were authored in the model's own frame (it is placed turned 180 degrees in the room), under the treads
# nearest its high end. Over the new place the treads are at least 0.51 high and the stringers 0.41; the box's lid is 0.4.
REGION = ((5.25, 6.6), (9.0, 9.9), (-0.01, 0.45))
SHIFT = Vector((0.0, -2.7, 0.0))

before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
shutil.copy2(SOURCE, BACKUP)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0


def inside(points):
    return all(REGION[i][0] <= min(p[i] for p in points) and max(p[i] for p in points) <= REGION[i][1] for i in range(3))


moved = {}
for obj in list(bpy.context.scene.objects):
    if obj.type != 'MESH':
        continue
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen, chosen = set(), []
    for face in bm.faces:
        if face.index in seen:
            continue
        island, stack = [], [face]
        seen.add(face.index)
        while stack:
            f = stack.pop()
            island.append(f)
            for edge in f.edges:
                for other in edge.link_faces:
                    if other.index not in seen:
                        seen.add(other.index)
                        stack.append(other)
        if inside([obj.matrix_world @ v.co for f in island for v in f.verts]):
            chosen.extend(island)
    if chosen:
        local_shift = obj.matrix_world.inverted().to_3x3() @ SHIFT
        bmesh.ops.translate(bm, vec=local_shift, verts=list({v for f in chosen for v in f.verts}))
        bm.to_mesh(obj.data)
        obj.data.update()
        moved[obj.name] = len(chosen)
    bm.free()

if not moved:
    raise RuntimeError('Found no trays under the high end; the master differs from the record.')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
NOTE.write_text(json.dumps({
    'date': '2026-10-28', 'source_before_sha256': before, 'preserved_source': BACKUP.name,
    'edit_record': 'art/source/world/sparks-workshop/v1/stair_trays_revision.py', 'moved_faces_by_object': moved,
    'shift_model_frame': list(SHIFT),
    'note': 'Deliberate source edit: the parts trays and lidded box move from under the high end of the turned staircase to under its low part, so the floor beneath the high end is clear to walk under. Everything else is retained.',
}, indent=2) + '\n')
print('Moved the stair trays:', moved)
