"""Saved-master edit: the lane's town steps. Copies haverlund-lane-surround v1 to v2 (v1 is untouched).

Beyond the lane's north gate the town steps run down away from the camera, so the game only ever saw their east
handrail: a thin rail zig-zagging over the lower lawn, with the treads hidden. That rail is replaced by a stepped
stone parapet with coping that follows the flight (0.9 m above each tread, never lower than 0.9 m above the lawn
beside it), so the head of the steps reads as solid masonry from the gameplay angle. The west handrail stays.

Run once with Blender (refuses to overwrite v2):
    blender -b --factory-startup --python lane_surround_v2.py
"""
from pathlib import Path
import bpy, bmesh, hashlib, json
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
SRC = ROOT / 'art/source/world/haverlund-lane-surround/v1/model.blend'
DST = ROOT / 'art/source/world/haverlund-lane-surround/v2/model.blend'
if DST.exists():
    raise RuntimeError('v2 exists; edit the saved master instead.')
bpy.ops.wm.open_mainfile(filepath=str(SRC))
before = hashlib.sha256(SRC.read_bytes()).hexdigest()
scene = bpy.context.scene
rail = bpy.data.objects['stair_handrail_east']
parent = rail.parent
bpy.data.objects.remove(rail, do_unlink=True)
for o in scene.objects:
    if o.name == 'stair_handrail_west':
        o.hide_set(True)
depsgraph = bpy.context.evaluated_depsgraph_get()


def ground(x, y):
    hit, loc, *_ = scene.ray_cast(depsgraph, Vector((x, y, 80)), Vector((0, 0, -1)))
    return loc.z if hit else None


X0, X1 = 13.47, 13.77
LAWN = -3.0
segments = []
y = 30.75
while y < 41.75 - 1e-6:
    tread = ground(12.9, y + .25)
    top = max(tread + .9, LAWN + .9)
    segments.append((y, y + .5, min(tread, LAWN) - .05, top))
    y += .5
bm = bmesh.new()
uv = bm.loops.layers.uv.new('UVMap')


def box(x0, y0, z0, x1, y1, z1):
    geom = bmesh.ops.create_cube(bm, size=1.0)['verts']
    bmesh.ops.scale(bm, vec=Vector((x1 - x0, y1 - y0, z1 - z0)), verts=geom)
    bmesh.ops.translate(bm, vec=Vector(((x0 + x1) / 2, (y0 + y1) / 2, (z0 + z1) / 2)), verts=geom)


for y0, y1, z0, top in segments:
    box(X0, y0, z0, X1, y1, top - .08)
    box(X0 - .05, y0, top - .08, X1 + .05, y1, top)      # coping
for f in bm.faces:
    n = f.normal
    axis = max(range(3), key=lambda i: abs(n[i]))
    a, b = [(1, 2), (0, 2), (0, 1)][axis]
    for loop in f.loops:
        loop[uv].uv = (loop.vert.co[a] / 1.9, loop.vert.co[b] / 1.9)
mesh = bpy.data.meshes.new('stair_parapet_east'); bm.to_mesh(mesh); bm.free()
mesh.materials.append(bpy.data.materials['seaside_stone'])
obj = bpy.data.objects.new('stair_parapet_east', mesh); scene.collection.objects.link(obj)
if parent is not None:
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()
for o in scene.objects:
    if o.name == 'stair_handrail_west':
        o.hide_set(False)

scene['lane_steps_parapet'] = 1
bpy.context.preferences.filepaths.save_version = 0
DST.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.file.pack_all(); bpy.ops.wm.save_as_mainfile(filepath=str(DST))
record = {'previous': 'v1', 'previous_sha256': before, 'record': str(Path(__file__).relative_to(ROOT)),
          'removed': ['stair_handrail_east'], 'added': 'stair_parapet_east', 'segments': len(segments),
          'x': [X0, X1], 'y': [segments[0][0], segments[-1][1]]}
(DST.parent / 'town-steps.json').write_text(json.dumps(record, indent=2) + '\n')
print('LANE SURROUND V2 SAVED', json.dumps(record))
