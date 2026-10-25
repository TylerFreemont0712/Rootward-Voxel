"""Attach all preserved strap hinges and studs to their existing moving leaf.
The original front positions are preserved exactly; only parenting changes.
"""
import bpy,json,hashlib,shutil
from pathlib import Path
R=Path.cwd();cat=json.loads((R/'pipeline/world-catalog.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for aid in ['cottage','mill-house','log-cabin','log-cabin-large','log-cabin-large-teal','hollow-bakery','hollow-smithy']:
 p=R/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('hinge_hardware_review'):raise RuntimeError('Hardware already attached')
 backup=p.with_name('model.pre-hinge-hardware.blend')
 if backup.exists():raise RuntimeError('Preserved source exists')
 shutil.copy2(p,backup);hinge=bpy.data.objects['DoorHinge'];bpy.context.view_layer.update()
 for o in bpy.context.scene.objects:
  if o.name.startswith(('Entrance strap hinge','Entrance hinge stud')):
   matrix=o.matrix_world.copy();o.parent=hinge;o.matrix_world=matrix
 bpy.context.scene['hinge_hardware_review']='Preserved straps and studs follow the leaf; original world placement unchanged.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'hardware_backup':backup.name,'hardware_backup_sha256':sha(backup),'hardware_review':'art/source/world/doorways/v1/hinge_hardware.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('Hardware attached',aid,flush=True)
