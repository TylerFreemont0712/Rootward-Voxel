"""Lower only the shell's subfloor cap, preventing coplanar faces beneath the parquet."""
from pathlib import Path
import bpy,hashlib,json
ROOT=Path(__file__).resolve().parents[5];path=ROOT/'art/source/world/clockshop-shell/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('parquet_support_clearance'):raise RuntimeError('Support already fitted; edit saved master.')
before=hashlib.sha256(path.read_bytes()).hexdigest();count=0
for obj in bpy.context.scene.objects:
 if obj.type!='MESH' or obj.name!='clockshop_darkwood':continue
 for vertex in obj.data.vertices:
  if -.04<vertex.co.z<.001:vertex.co.z-=.03;count+=1
 obj.data.update()
bpy.context.scene['parquet_support_clearance']=True;bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('floor-support.json').write_text(json.dumps({'previous_sha256':before,'edited_vertices':count,'clearance':.03,'record':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
