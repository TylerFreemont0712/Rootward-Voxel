"""Deliberate source edit: open the upper cabinet body so the authored bottles are visible."""
from pathlib import Path
import hashlib,json,shutil
import bpy,bmesh
from mathutils import Vector
root=Path.cwd()
folder=root/'art/source/world/hollow-apothecary-cabinet/v1'
source=folder/'model.blend'
backup=folder/'model.before-open-shelves.blend'
if not backup.exists():shutil.copy2(source,backup)
if (folder/'shelf-refinement.json').exists():
    raise RuntimeError('This source edit is already applied; preserve the editable master.')
before=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source))
obj=bpy.data.objects.get('body_wood_dark')
assert obj is not None
mesh=obj.data
bm=bmesh.new();bm.from_mesh(mesh);bm.verts.ensure_lookup_table()
# The full cabinet backing is the first eight vertices; preserve its panels and all other authored meshes.
old=list(bm.verts[:8])
upper_back=list(bm.verts[8:16])
for v in upper_back:v.co.y+=.525
bmesh.ops.delete(bm,geom=old,context='VERTS')
for at,size in [((0,.245,.75),(1.26,.07,1.50)),((-.59,0,.75),(.08,.55,1.50)),((.59,0,.75),(.08,.55,1.50)),((0,0,.39),(1.18,.51,.78))]:
    cube=bmesh.ops.create_cube(bm,size=1)['verts']
    for v in cube:
        v.co=Vector((v.co.x*size[0]+at[0],v.co.y*size[1]+at[1],v.co.z*size[2]+at[2]))
bm.to_mesh(mesh);bm.free();mesh.update()
uv=mesh.uv_layers.active
for face in mesh.polygons:
    axis=max(range(3),key=lambda k:abs(face.normal[k]))
    for index in face.loop_indices:
        co=mesh.vertices[mesh.loops[index].vertex_index].co
        uv.data[index].uv=(co.y,co.z) if axis==0 else ((co.x,co.z) if axis==1 else (co.x,co.y))
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(source))
(folder/'shelf-refinement.json').write_text(json.dumps({'reason':'Gameplay review: a solid upper cabinet box hid the authored bottles. Opened its shelves, kept lower drawers, side walls and back.','method':'Deliberate BMesh source edit; no regeneration.','before_sha256':before,'after_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':backup.name,'script_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
