"""Settle the woven rug against its backing without intersecting it."""
from pathlib import Path
import bpy,json,hashlib
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/workshop-rug/v1/model.blend'
before=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source));bpy.context.preferences.filepaths.save_version=0
for o in bpy.context.scene.objects:
    if o.type=='MESH' and o.data.materials[0].name=='workshop_woven':
        for v in o.data.vertices:v.co.z=.056+(v.co.z-.054)*.12
        o.data.update()
bpy.ops.wm.save_as_mainfile(filepath=str(source))
Path(__file__).with_suffix('.json').write_text(json.dumps({'asset':'workshop-rug','before':before,
    'after':hashlib.sha256(source.read_bytes()).hexdigest()},indent=2)+'\n')
