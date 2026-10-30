"""Lower the posed crate so Heron's face stays visible, preserving a source backup."""
import hashlib
import importlib.util
import json
from pathlib import Path
import shutil
import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('edit',HERE/'refine_sources.py');e=importlib.util.module_from_spec(spec);spec.loader.exec_module(e)
source=e.ROOT/'art/source/world/robot-heron/v2/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
if bpy.context.scene.get('lowered_payload'):raise RuntimeError('Payload pose already corrected; edit the saved source.')
backup=source.with_name('model.pre-payload-pose.blend')
if backup.exists():raise RuntimeError('Source backup already exists.')
shutil.copy2(source,backup)
e.ROOT_OBJECT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.parent is None)
e.M={'ink':bpy.data.materials['robot_ink']}
for obj in list(bpy.context.scene.objects):
    if obj.type!='MESH' or obj.get('part')!='payload':continue
    if any(mat and mat.name.startswith('robot_ink') for mat in obj.data.materials):bpy.data.objects.remove(obj,do_unlink=True);continue
    for vertex in obj.data.vertices:
        point=obj.matrix_world@vertex.co;point.z-=.365
        vertex.co=obj.matrix_world.inverted()@point
for side in [-1,1]:e.curve('Lowered crate sling',[(0,-.40,.845),(side*.105,-.425,.403)],.006,'ink','payload')
e.consolidate()
bpy.context.scene['lowered_payload']=True
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(source))
(source.parent/'payload-pose.json').write_text(json.dumps({'asset':'robot-heron','date':'2026-10-29','source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':backup.name,'backup_sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),'edit_record':str(Path(__file__).relative_to(e.ROOT)),'edit_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'reason':'Keep the held crate and its actual slings below Heron’s readable spark face.'},indent=2)+'\n')
