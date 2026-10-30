"""Deliberate edit of the adopted workshop shell, preserving the previous master.

The workshop's north wall is the party wall with Nell's house next door (Spindle Lane), so a window in it would look
into her rooms. This removes only that window's pieces: its painted view, mullions, crossrails, deep sill and the
pot on it. The wall, wainscot, rail, timber uprights and every other surface are kept. A shelf of jars and parts
(jar_shelf.py) takes its place on the wall.

Run: blender --background --python-exit-code 1 --python art/source/world/sparks-workshop/v1/party_wall_revision.py
"""
from pathlib import Path
import hashlib
import json
import shutil
import bmesh
import bpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
SOURCE = ROOT / 'art/source/world/workshop-shell/v1/model.blend'
BACKUP = SOURCE.with_name('model.pre-party-wall.blend')
NOTE = SOURCE.with_name('party-wall-revision.json')
if NOTE.exists() or BACKUP.exists():
    raise RuntimeError('This deliberate shell edit already ran; edit the saved master instead.')
# The north window was authored at x 10.4 in front of the wall (sparks-workshop/v1/author.py, shell()).
REGION = ((9.5, 11.35), (10.9, 11.45), (1.15, 2.95))

before = hashlib.sha256(SOURCE.read_bytes()).hexdigest()
shutil.copy2(SOURCE, BACKUP)
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0


def inside(points):
    return all(REGION[i][0] <= min(p[i] for p in points) and max(p[i] for p in points) <= REGION[i][1] for i in range(3))


removed = {}
for obj in list(bpy.context.scene.objects):
    if obj.type != 'MESH':
        continue
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    bm.faces.ensure_lookup_table()
    seen, doomed = set(), []
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
            doomed.extend(island)
    if doomed:
        verts = {v for f in doomed for v in f.verts}
        bmesh.ops.delete(bm, geom=list(verts), context='VERTS')
        bm.to_mesh(obj.data)
        obj.data.update()
        removed[obj.name] = len(doomed)
    bm.free()
    if obj.type == 'MESH' and len(obj.data.polygons) == 0:
        bpy.data.objects.remove(obj, do_unlink=True)

if not removed:
    raise RuntimeError('Found nothing of the north window to remove; the master differs from the record.')
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
NOTE.write_text(json.dumps({
    'date': '2026-10-28', 'source_before_sha256': before, 'preserved_source': BACKUP.name,
    'edit_record': 'art/source/world/sparks-workshop/v1/party_wall_revision.py', 'removed_faces_by_object': removed,
    'note': "Deliberate source edit: the north window is removed because the north wall is the party wall with Nell's house. Everything else is retained; a jar shelf (workshop-jar-shelf) is placed on the wall by the area document.",
}, indent=2) + '\n')
print('Removed the party-wall window:', removed)
