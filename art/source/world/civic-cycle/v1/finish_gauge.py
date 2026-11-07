"""Follow-up of the deliberate gauge edit: retain audit UVs and keep coloured scale behind needle."""
from pathlib import Path
import bpy,json,hashlib
ROOT=Path(__file__).resolve().parents[5];p=ROOT/'art/source/world/rootwell-beacon/v1/model.blend'
if json.loads(p.with_name('city-cycle-revision.json').read_text()).get('follow_up'):
 raise RuntimeError('Follow-up already applied; inspect the saved master.')
bpy.ops.wm.open_mainfile(filepath=str(p))
for o in bpy.context.scene.objects:
 if o.name.startswith(('rootwell_pressure_green','rootwell_pressure_amber')):
  if not o.data.uv_layers:o.data.uv_layers.new(name='UVMap')
  # Shift along the face normal, behind the moving needle just as the authored red band sits.
  needle=bpy.data.objects['gauge_needle'];axis=needle.matrix_world.to_3x3() @ __import__('mathutils').Vector((0,.0145,0))
  for v in o.data.vertices:v.co+=axis
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p))
f=p.with_name('city-cycle-revision.json');d=json.loads(f.read_text());d['after']=hashlib.sha256(p.read_bytes()).hexdigest();d['follow_up']='art/source/world/civic-cycle/v1/finish_gauge.py';f.write_text(json.dumps(d,indent=2)+'\n')
