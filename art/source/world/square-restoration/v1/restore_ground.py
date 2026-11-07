"""Restore the adopted v3 terraced master; retain local-light subdivision and the removable wall bay."""
from pathlib import Path
import bpy,bmesh,json,hashlib
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
target=ROOT/'art/source/world/haverlund-square-ground/v5/model.blend'
if target.exists():
 import shutil
 backup=target.with_name('model.original-baseline-draft.blend')
 if backup.exists():raise RuntimeError('Restoration already revised; edit the saved source.')
 shutil.copy2(target,backup)
bpy.ops.wm.open_mainfile(filepath=str(source));removed=0
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 bm=bmesh.new();bm.from_mesh(obj.data)
 # Geometry below the fog no longer needs detailed lower streets or foundations.
 faces=[f for f in bm.faces if max((obj.matrix_world@v.co).z for v in f.verts)<-3.05]
 removed+=len(faces)
 if faces:bmesh.ops.delete(bm,geom=faces,context='FACES')
 if not bm.faces:bm.free();bpy.data.objects.remove(obj,do_unlink=True);continue
 bm.to_mesh(obj.data);bm.free();obj.location.x+=16;obj.data.update()
bpy.context.preferences.filepaths.save_version=0;target.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(target))
target.with_name('restoration.json').write_text(json.dumps({'source':str(source.relative_to(ROOT)),'sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'removed_subfog_faces':removed,'offset':[16,0]},indent=2)+'\n')
print('Restored terraced ground;',removed,'sub-fog faces removed')
