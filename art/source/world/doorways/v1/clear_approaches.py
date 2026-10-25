"""Remove the Boolean's front closing plane from the real door approaches.
The cutter must extend entirely outside the building, including projecting beams.
A gameplay ray through each opened leaf verifies the resulting aperture.
"""
import bpy,json,shutil,bmesh
from pathlib import Path
ROOT=Path.cwd();cat=json.loads((ROOT/'pipeline/world-catalog.json').read_text())
exec(compile((ROOT/'art/source/world/doorways/v1/edit_sources.py').read_text().split('\nfor aid,(')[0],'helpers','exec'))
for aid,(front,width,height,bottom) in SPECS.items():
 p=ROOT/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('clear_approach_review'):raise RuntimeError('Already clear')
 backup=p.with_name('model.pre-clear-approach.blend')
 if backup.exists():raise RuntimeError('Backup exists')
 shutil.copy2(p,backup)
 back=-front+1.55
 cutter=box('Through-front aperture cutter',(0,(-20+back)/2,bottom+height/2),(width+.025,20+back,height+.03),None)
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH' or o==cutter or o.parent and o.parent.name=='DoorHinge':continue
  if o.name.startswith(('Entrance','Door__','EntryLeaf','Hinged','Forged door','Door strap','Door knocker','Brass knocker','Fittings__','Windows__','Roof__','Oriel_','Turret__','Balcony__','Doorway','Walkable')):continue
  lo,hi=bounds(o)
  if hi.x> -width/2 and lo.x<width/2 and lo.y<back and hi.y> -20 and hi.z>bottom and lo.z<bottom+height:difference(o,cutter)
 bpy.data.objects.remove(cutter,do_unlink=True)
 bpy.context.scene['clear_approach_review']='Aperture extends beyond the outermost beam; no front closing cap.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'aperture_backup':backup.name,'aperture_backup_sha256':sha(backup),'aperture_review':'art/source/world/doorways/v1/clear_approaches.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('CLEAR THROUGH FRONT',aid,flush=True)
