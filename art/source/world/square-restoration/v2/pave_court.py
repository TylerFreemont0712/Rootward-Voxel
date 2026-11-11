"""Saved-master edit: the clockmaker's court. Copies ground v6 to v7 (v6 is untouched) and, in the blocked rear shelf
behind Spindle Walk (x 9.5-15.5, y 14.5-54.5, the floor at z 2):
  * removes the clockmaker plot's pit walls and floors (clock_plot_*), which left two free-standing two-metre cheeks
    and a rear wall around the shop;
  * removes every ground face in that rectangle (the random grass patches among them) and lays one continuous flagged
    court. Lawns, hedges, walls, gates and trees are placed by content/areas/haverlund-square.json, which owns them.
Nothing the player can walk on changes: the rectangle lies west of the walkable terrace (x >= 16).
Run once with Blender: blender -b --python this.py   (it refuses to overwrite v7)."""
from pathlib import Path
import bpy, bmesh, hashlib, json
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[5]
src = ROOT / 'art/source/world/haverlund-square-ground/v6/model.blend'
dst = ROOT / 'art/source/world/haverlund-square-ground/v7/model.blend'
if dst.exists():
    raise RuntimeError('v7 exists; edit the saved master instead.')
bpy.ops.wm.open_mainfile(filepath=str(src))
before = hashlib.sha256(src.read_bytes()).hexdigest()
x0, x1, y0, y1 = 9.5, 15.5, 14.5, 54.5
removed_objects = 0
for obj in list(bpy.data.objects):
    if obj.name.startswith('clock_plot_'):
        bpy.data.objects.remove(obj, do_unlink=True)
        removed_objects += 1
removed_faces = 0
for obj in list(bpy.context.scene.objects):
    if obj.type != 'MESH' or not any(m and m.name.startswith('ground_') for m in obj.data.materials):
        continue
    pts = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    if max(p.x for p in pts) < x0 or min(p.x for p in pts) > x1 or max(p.y for p in pts) < y0 or min(p.y for p in pts) > y1:
        continue
    bm = bmesh.new(); bm.from_mesh(obj.data)
    bmesh.ops.transform(bm, matrix=obj.matrix_world, verts=list(bm.verts))
    for axis, cuts in [(0, [x0, x1]), (1, [y0, y1])]:
        for value in cuts:
            n = Vector((int(axis == 0), int(axis == 1), 0))
            bmesh.ops.bisect_plane(bm, geom=list(bm.verts) + list(bm.edges) + list(bm.faces), dist=.00001, plane_co=n * value, plane_no=n)
    doomed = []
    for f in bm.faces:
        c = f.calc_center_median()
        if x0 - 1e-5 < c.x < x1 + 1e-5 and y0 - 1e-5 < c.y < y1 + 1e-5 and abs(c.z - 2.0) < .05 and abs(f.normal.z) > .9:
            doomed.append(f)
    removed_faces += len(doomed)
    if doomed:
        bmesh.ops.delete(bm, geom=doomed, context='FACES')
    if not bm.faces:
        bm.free(); bpy.data.objects.remove(obj, do_unlink=True); continue
    bm.to_mesh(obj.data); bm.free(); obj.matrix_world.identity(); obj.data.update()

def floor(name, rect, mat, scale=3.0):
    a, b, c, d = rect
    pts = [(a, c, 2.0), (b, c, 2.0), (b, d, 2.0), (a, d, 2.0)]
    mesh = bpy.data.meshes.new(name); mesh.from_pydata(pts, [], [(0, 1, 2, 3)])
    mesh.materials.append(bpy.data.materials[mat]); mesh.update()
    uv = mesh.uv_layers.new(name='UVMap')
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            v = mesh.vertices[mesh.loops[li].vertex_index].co
            uv.data[li].uv = (v[0] / scale, v[1] / scale)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj['ground_chunk'] = True
# One quad per 6 m so the spatial light sections stay small.
yy = y0
while yy < y1 - 1e-6:
    top = min(yy + 8.0, y1)
    floor(f'court_flags_{yy:g}', (x0, x1, yy, top), 'ground_flags')
    yy = top
bpy.context.scene['clockmaker_court_paved'] = True
bpy.context.preferences.filepaths.save_version = 0
dst.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(dst))
(dst.parent / 'court.json').write_text(json.dumps({'previous': 'v6', 'previous_sha256': before, 'removed_plot_objects': removed_objects,
    'removed_ground_faces': removed_faces, 'rect': [x0, y0, x1 - x0, y1 - y0], 'record': str(Path(__file__).relative_to(ROOT))}, indent=2) + '\n')
print('court paved', removed_objects, removed_faces)
