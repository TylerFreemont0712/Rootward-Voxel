"""Final camera-fit edits to the saved loft roof and original cottage side windows.
Keeps the preceding source and records the review chain. Never rerun on adoption.
"""
import bpy,bmesh,json,shutil,math,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd();cat=json.loads((ROOT/'pipeline/world-catalog.json').read_text())
exec(compile((ROOT/'art/source/world/doorways/v1/edit_sources.py').read_text().split('\nfor aid,(')[0],'helpers','exec'))
for aid in ['lantern-loft','concept-cottage']:
 source=ROOT/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(source))
 if bpy.context.scene.get('final_fit_review'):raise RuntimeError('Already reviewed')
 backup=source.with_name('model.pre-final-fit.blend')
 if backup.exists() and sha(backup)!=sha(source):raise RuntimeError('Preserved source differs; inspect before editing')
 if not backup.exists():shutil.copy2(source,backup)
 if aid=='lantern-loft':
  # Boolean against a batch of intersecting warped tile solids loses remote
  # faces. Keep the authored roof and trim only whole tiles under the turret.
  old=source.with_name('model.pre-doorways.blend')
  with bpy.data.libraries.load(str(old),link=False) as (data_from,data_to):
   names=[n for n in data_from.objects if n.startswith(('Roof__','Broken pitch'))];data_to.objects=names.copy()
  for name,original in zip(names,data_to.objects):
   target=bpy.data.objects.get(name)
   if target:target.data=original.data.copy()
   bpy.data.objects.remove(original,do_unlink=True)
  for o in bpy.context.scene.objects:
   if o.type!='MESH' or not o.name.startswith('Roof__roof_'):continue
   obsolete=extract(o,lambda lo,hi:Vector(((lo.x+hi.x)/2-2.93,(lo.y+hi.y)/2+3.14)).length<1.04,'UnderTurretTile')
   if obsolete:bpy.data.objects.remove(obsolete,do_unlink=True)
 else:
  # Explicit side-facing trim avoids a board being coplanar with a log edge.
  for o in list(bpy.context.scene.objects):
   if o.type=='MESH' and o.name.startswith('Windows__'):
    old=extract(o,lambda lo,hi:lo.x>1.8 or hi.x< -1.8,'Old side window')
    if old:bpy.data.objects.remove(old,do_unlink=True)
  for side in [-1,1]:
   for y in [-.70,.70]:
    dark=bpy.data.materials['cottage_timber'];oak=bpy.data.materials['cottage_oak_light'];glow=bpy.data.materials['cottage_window']
    box('Side window reveal',(side*2.01,y,1.44),(.10,.90,1.02),dark)
    box('Side window warm pane',(side*2.075,y,1.44),(.045,.69,.80),glow)
    for yy in [y-.41,y+.41]:box('Side window raised stile',(side*2.15,yy,1.44),(.19,.12,1.08),dark)
    for zz in [.94,1.94]:box('Side window projecting sill',(side*2.15,y,zz),(.24,.98,.12),oak)
    box('Side window horizontal mullion',(side*2.15,y,1.44),(.12,.72,.06),dark)
    box('Side window vertical mullion',(side*2.15,y,1.44),(.12,.055,.84),dark)
 # Recalculate closed components; boolean-free roof keeps its original bounds.
 for o in bpy.context.scene.objects:
  if o.type=='MESH':
   bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 bpy.context.scene['final_fit_review']='Whole-tile turret seat; side windows with explicit surface clearance.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=source.parent/('doorways.json' if aid=='lantern-loft' else 'provenance.json');record=json.loads(note.read_text());record['source_sha256']=sha(source);record['final_fit_backup']=backup.name;record['final_fit_backup_sha256']=sha(backup);record['final_fit_script']='art/source/world/doorways/v1/final_fit.py';note.write_text(json.dumps(record,indent=2)+'\n')
 print('FINAL FIT SAVED',aid,flush=True)
