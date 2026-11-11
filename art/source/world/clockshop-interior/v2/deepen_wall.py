"""Append only previously culled vertical masonry between -3 and -9 m, preserving v5 edits."""
from pathlib import Path
import bpy,bmesh,json,hashlib
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/haverlund-square-ground/v5/model.blend'
original=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
target=ROOT/'art/source/world/haverlund-square-ground/v6/model.blend'
if target.exists():raise RuntimeError('Saved source exists; edit it deliberately.')
bpy.ops.wm.open_mainfile(filepath=str(source));added=0
with bpy.data.libraries.load(str(original),link=False) as (data,out):out.objects=[n for n in data.objects]
for obj in out.objects:
 if obj is None:continue
 if obj.type!='MESH':bpy.data.objects.remove(obj,do_unlink=True);continue
 bm=bmesh.new();bm.from_mesh(obj.data);remove=[]
 for f in bm.faces:
  zs=[(obj.matrix_world@v.co).z for v in f.verts];mat=obj.data.materials[f.material_index]
  if not(max(zs)<-3.05 and max(zs)>-9.0 and abs(f.normal.z)<.8 and mat and 'stone' in mat.name):remove.append(f)
 if remove:bmesh.ops.delete(bm,geom=remove,context='FACES')
 if not bm.faces:bm.free();bpy.data.objects.remove(obj,do_unlink=True);continue
 added+=len(bm.faces);bm.to_mesh(obj.data);bm.free();obj.data.update();obj.location.x+=16
 obj.name='deep_wall_'+obj.name;bpy.context.scene.collection.objects.link(obj)
target.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(target))
target.with_name('deep-wall.json').write_text(json.dumps({'previous_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'reference_sha256':hashlib.sha256(original.read_bytes()).hexdigest(),'added_vertical_faces':added,'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
print('Restored',added,'vertical masonry faces; no lower streets, parks or houses')
