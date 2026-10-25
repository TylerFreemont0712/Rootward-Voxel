"""Clip two residual coplanar faces in the adopted large cabin's log batch.
Triangle splitting preserves the log art outside the clear doorway volume.
"""
import bpy,bmesh,json,hashlib,shutil
from pathlib import Path
from mathutils import Vector
R=Path.cwd();cat=json.loads((R/'pipeline/world-catalog.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
for aid in ['log-cabin-large','log-cabin-large-teal']:
 p=R/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('cabin_reveal_review'):raise RuntimeError('Already clipped')
 backup=p.with_name('model.pre-cabin-reveal.blend')
 if backup.exists():raise RuntimeError('Backup exists')
 shutil.copy2(p,backup)
 o=bpy.data.objects['oak_light_geometry'];m=o.matrix_world;inv=m.inverted();bm=bmesh.new();bm.from_mesh(o.data)
 for normal,point in [((1,0,0),(-.563,0,0)),((1,0,0),(.563,0,0)),((0,0,1),(0,0,.155)),((0,0,1),(0,0,2.385)),((0,1,0),(0,-.88,0))]:
  n=(m.to_3x3().transposed()@Vector(normal)).normalized();co=inv@Vector(point)
  bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=co,plane_no=n,clear_inner=False,clear_outer=False)
 erase=[]
 for face in bm.faces:
  c=m@face.calc_center_median()
  if -.563<c.x<.563 and c.y<-.87999 and .155<c.z<2.385:erase.append(face)
 bmesh.ops.delete(bm,geom=erase,context='FACES');bm.to_mesh(o.data);bm.free()
 bpy.context.scene['cabin_reveal_review']='Residual coplanar log faces clipped from the doorway only.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'cabin_reveal_backup':backup.name,'cabin_reveal_backup_sha256':sha(backup),'cabin_reveal_review':'art/source/world/doorways/v1/cabin_reveal.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('Clipped doorway faces',aid,len(erase),flush=True)
