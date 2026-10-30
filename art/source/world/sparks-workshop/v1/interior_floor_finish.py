from pathlib import Path
import bpy,bmesh,json,hashlib,shutil
root=Path(__file__).resolve().parents[5]
p=root/'art/source/world/workshop-umbrella-stand/v1/model.blend'
b=p.with_name('model.pre-interior-floor.blend')
if b.exists():raise RuntimeError('already revised')
shutil.copy2(p,b)
before=hashlib.sha256(p.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(p));bpy.context.preferences.filepaths.save_version=0
for o in bpy.context.scene.objects:
 if o.type!='MESH' or o.data.materials[0].name!='workshop_ceramic':continue
 bm=bmesh.new();bm.from_mesh(o.data)
 for f in bm.faces:
  if len(f.verts)==40 and f.normal.z<-.9:f.normal_flip()
 bm.to_mesh(o.data);bm.free()
bpy.ops.wm.save_as_mainfile(filepath=str(p))
r={'asset':'workshop-umbrella-stand','before':before,'after':hashlib.sha256(p.read_bytes()).hexdigest(),'backup':str(b.relative_to(root)),'change':'Face the recessed interior floor upwards into the opening.'}
(root/'art/source/world/sparks-workshop/v1/interior-floor-finish.json').write_text(json.dumps(r,indent=2)+'\n')
