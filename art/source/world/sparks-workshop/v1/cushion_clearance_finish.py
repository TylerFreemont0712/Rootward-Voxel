"""Move the loose cushion forward onto the seat, clear of the throw's rear fold."""
from pathlib import Path
import bpy
import hashlib
import json
import shutil

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
source=ROOT/'art/source/world/workshop-armchair/v1/model.blend'
backup=source.with_name('model.pre-cushion-clearance.blend')
if backup.exists():raise RuntimeError('Already revised; edit the current master deliberately.')
shutil.copy2(source,backup)
before=hashlib.sha256(source.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(source))
bpy.context.preferences.filepaths.save_version=0
for o in bpy.context.scene.objects:
    if o.type=='MESH' and o.data.materials[0].name=='workshop_teal_dark':o.location.y-=.20
bpy.ops.wm.save_as_mainfile(filepath=str(source))
(HERE/'cushion-clearance-finish.json').write_text(json.dumps({
    'asset':'workshop-armchair','before':before,'after':hashlib.sha256(source.read_bytes()).hexdigest(),
    'backup':str(backup.relative_to(ROOT)),'change':'Loose cushion rests forward on the seat, clear of the plaid rear fold.'
},indent=2)+'\n')
