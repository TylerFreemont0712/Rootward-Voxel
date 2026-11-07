"""Scope the adopted garden hinge independently from the town stair gate."""
import bpy,json,hashlib
from pathlib import Path
source=Path(__file__).with_name('model.blend')
bpy.ops.wm.open_mainfile(filepath=str(source))
gate=bpy.data.objects['BraumGardenGate']
if gate.get('door_group'):raise RuntimeError('Scope already authored; inspect the master.')
gate['door_group']=True
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(source))
record=source.with_name('welcome-gate.json')
data=json.loads(record.read_text());data['scoped_source_sha256']=hashlib.sha256(source.read_bytes()).hexdigest()
record.write_text(json.dumps(data,indent=2)+'\n')
