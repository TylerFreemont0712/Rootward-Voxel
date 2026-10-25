"""Restore canonical material identities after loading preserved source mesh data.
Blender appends .001 to existing names when a backup is read into the open file.
The saved material roles, original paintings and finish bindings must stay stable.
"""
import bpy,json,re,hashlib,shutil
from pathlib import Path
R=Path.cwd();cat=json.loads((R/'pipeline/world-catalog.json').read_text())
ids=['cottage','mill-house','log-cabin','log-cabin-large','log-cabin-large-teal','hearth-house','lantern-loft','brook-mill','hollow-bakery','hollow-smithy','concept-cottage']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for aid in ids:
 p=R/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('doorway_bindings_review'):raise RuntimeError('Bindings already reviewed')
 backup=p.with_name('model.pre-material-bindings.blend')
 if backup.exists():raise RuntimeError('Preserved source already exists')
 shutil.copy2(p,backup);changed=0
 for o in bpy.context.scene.objects:
  if o.type!='MESH':continue
  for i,m in enumerate(o.data.materials):
   if not m:continue
   base=re.sub(r'(\.\d{3})+$','',m.name)
   canonical=bpy.data.materials.get(base)
   if canonical and canonical!=m:o.data.materials[i]=canonical;changed+=1
 bpy.context.scene['doorway_bindings_review']='Canonical material names preserved after backup data append.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/('provenance.json' if aid=='concept-cottage' else 'doorways.json');d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'binding_backup':backup.name,'binding_backup_sha256':sha(backup),'binding_review':'art/source/world/doorways/v1/restore_bindings.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print(aid,'canonical material slots restored',changed,flush=True)
