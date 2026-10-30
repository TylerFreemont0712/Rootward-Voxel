"""A wide seat derived from the adopted park bench, preserving its human height.
The original park-bench master is untouched. Refuses an existing new source.
"""
import bpy, json, hashlib
from pathlib import Path
ROOT=Path.cwd();base=ROOT/'art/source/world/morning-civic-bench/v1';p=base/'model.blend'
if p.exists():raise RuntimeError('Edit the existing civic bench source.')
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/source/world/park-bench/v1/model.blend'))
for o in bpy.context.scene.objects:
    if o.type=='MESH':
        o.location.x*=2.6
        for v in o.data.vertices:v.co.x*=2.6
base.mkdir(parents=True,exist_ok=True)
bpy.context.scene['source_authority']='Wide civic seat derived from the park-bench master; original unchanged. Edit this saved model.'
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(p))
(base/'provenance.json').write_text(json.dumps({'asset':'morning-civic-bench','version':'v1','derived_from':'art/source/world/park-bench/v1/model.blend','authoring_record':'art/source/world/village-landmarks/v1/civic_bench.py','source_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'note':'Seat widened to 2.34m while retaining its 0.9m backrest height. Original master unchanged.'},indent=2)+'\n')
