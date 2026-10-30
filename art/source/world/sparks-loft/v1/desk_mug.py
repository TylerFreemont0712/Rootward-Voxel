"""Deliberate edit of the adopted loft-desk master: the desk mug held a flat disc standing for something to drink.

It is now a hollow enamel mug, left empty. The saved master is copied beside itself first, once, and every edit is
recorded with hashes. Later changes open the current model.blend.
"""
from pathlib import Path
import bmesh
import bpy
import hashlib
import json
import math
import shutil
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
ASSET = 'loft-desk'
path = ROOT / 'art/source/world' / ASSET / 'v1/model.blend'
backup = path.with_name('model.pre-empty-mug.blend')
if backup.exists():
    raise RuntimeError('Already revised; edit the current master: ' + ASSET)
shutil.copy2(path, backup)
before = hashlib.sha256(path.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(path))
bpy.context.preferences.filepaths.save_version = 0


def remove_components(predicate):
    removed = 0
    for o in list(bpy.context.scene.objects):
        if o.type != 'MESH':
            continue
        bm = bmesh.new()
        bm.from_mesh(o.data)
        unseen = set(bm.verts)
        doomed = []
        while unseen:
            seed = unseen.pop()
            group = {seed}
            todo = [seed]
            while todo:
                for e in todo.pop().link_edges:
                    for v in e.verts:
                        if v in unseen:
                            unseen.remove(v)
                            group.add(v)
                            todo.append(v)
            pts = [o.matrix_world @ v.co for v in group]
            lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
            hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            if predicate(lo, hi, o.data.materials[0].name):
                doomed.extend(group)
                removed += 1
        if doomed:
            bmesh.ops.delete(bm, geom=doomed, context='VERTS')
        bm.to_mesh(o.data)
        bm.free()
        o.data.update()
    return removed


# The body is a closed cylinder (x .75-.93, y -.33 to -.15, z 1.11-1.31) and the dark disc lies on its lid.
gone = remove_components(lambda lo, hi, mat: (mat == 'loft_cream' and lo.x > .7 and lo.x < .8 and hi.z > 1.28 and hi.z < 1.34 and hi.x - lo.x < .2 and hi.y - lo.y < .2) or mat == 'loft_leather_dark')
assert gone == 2, gone
centre = (.84, -.24)
profile = [(0.0, 1.11), (.082, 1.11), (.090, 1.12), (.090, 1.31), (.0775, 1.31), (.0775, 1.14), (0.0, 1.14)]
segments = 28
verts, faces, rings = [], [], []
for r, z in profile:
    rings.append(len(verts))
    if r == 0:
        verts.append((centre[0], centre[1], z))
    else:
        for i in range(segments):
            a = i / segments * math.tau
            verts.append((centre[0] + r * math.cos(a), centre[1] + r * math.sin(a), z))
for k in range(len(profile) - 1):
    r0, r1 = profile[k][0], profile[k + 1][0]
    for i in range(segments):
        j = (i + 1) % segments
        if r0 == 0:
            faces.append((rings[k], rings[k + 1] + j, rings[k + 1] + i))
        elif r1 == 0:
            faces.append((rings[k] + i, rings[k] + j, rings[k + 1]))
        else:
            faces.append((rings[k] + i, rings[k] + j, rings[k + 1] + j, rings[k + 1] + i))
mesh = bpy.data.meshes.new('Hollow desk mug')
mesh.from_pydata(verts, [], faces)
mesh.update()
bm = bmesh.new()
bm.from_mesh(mesh)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(mesh)
bm.free()
for p in mesh.polygons:
    p.use_smooth = True
mesh.uv_layers.new(name='UVMap')
mug = bpy.data.objects.new('Hollow desk mug', mesh)
bpy.context.scene.collection.objects.link(mug)
mug.parent = bpy.data.objects['loft_cream'].parent
mesh.materials.append(bpy.data.materials['loft_cream'])
bpy.ops.object.select_all(action='DESELECT')
mug.select_set(True)
bpy.data.objects['loft_cream'].select_set(True)
bpy.context.view_layer.objects.active = bpy.data.objects['loft_cream']
bpy.ops.object.join()
bpy.context.object.name = 'loft_cream'
bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(path))
(HERE / 'desk-mug.json').write_text(json.dumps({
    'date': '2026-10-27', 'record': 'art/source/world/sparks-loft/v1/desk_mug.py', 'asset': ASSET,
    'before': before, 'backup': str(backup.relative_to(ROOT)), 'after': hashlib.sha256(path.read_bytes()).hexdigest()}, indent=2) + '\n')
print('REVISED', ASSET, flush=True)
