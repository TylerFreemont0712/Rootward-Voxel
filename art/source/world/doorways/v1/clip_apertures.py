"""Final adopted apertures: split existing faces along five planes and remove
only the opening. No Boolean solid operation is used on intersecting art batches.
Restores affected mesh data from the preserved original, retaining all other edits.
"""
import bpy,bmesh,json,shutil,re
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd();cat=json.loads((ROOT/'pipeline/world-catalog.json').read_text())
exec(compile((ROOT/'art/source/world/doorways/v1/edit_sources.py').read_text().split('\nfor aid,(')[0],'helpers','exec'))
for aid,(front,width,height,bottom) in SPECS.items():
 p=ROOT/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('plane_aperture_review'):raise RuntimeError('Already clipped')
 backup=p.with_name('model.pre-plane-aperture.blend')
 if backup.exists():raise RuntimeError('Preserved source exists')
 shutil.copy2(p,backup)
 old=p.with_name('model.pre-doorways.blend');back=-front+1.55
 with bpy.data.libraries.load(str(old),link=False) as (data_from,data_to):
  names=list(data_from.objects);data_to.objects=names.copy()
 original=dict(zip(names,data_to.objects));temp=bpy.data.collections.new('Original source data');bpy.context.scene.collection.children.link(temp)
 for o in original.values():
  if o:temp.objects.link(o)
 bpy.context.view_layer.update();targets=[]
 for name,o in original.items():
  if not o or o.type!='MESH':continue
  if name.startswith(('Entrance','Door__','Fittings__','Windows__','Roof__','Turret__','Balcony__')):continue
  lo,hi=bounds(o)
  if hi.x> -width/2 and lo.x<width/2 and lo.y<back and hi.y> -20 and hi.z>bottom and lo.z<bottom+height:
   target=bpy.data.objects.get(name)
   if target:target.data=o.data.copy();targets.append(target)
 for o in original.values():
  if o:bpy.data.objects.remove(o,do_unlink=True)
 bpy.data.collections.remove(temp)
 for o in targets:
  m=o.matrix_world.copy();inv=m.inverted();bm=bmesh.new();bm.from_mesh(o.data)
  bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
  half=width/2+.0125;low=bottom-.015;top=bottom+height+.015
  planes=[((1,0,0),(-half,0,0)),((1,0,0),(half,0,0)),((0,0,1),(0,0,low)),((0,0,1),(0,0,top)),((0,1,0),(0,back,0))]
  for normal,point in planes:
   n=(m.to_3x3().transposed()@Vector(normal)).normalized();co=inv@Vector(point)
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.000001,plane_co=co,plane_no=n,clear_inner=False,clear_outer=False)
  erase=[]
  for f in bm.faces:
   c=m@f.calc_center_median()
   if -half-.000001<c.x<half+.000001 and c.y<back+.000001 and low-.000001<c.z<top+.000001:erase.append(f)
  bmesh.ops.delete(bm,geom=erase,context='FACES');bm.to_mesh(o.data);bm.free()
 if aid=='lantern-loft':
  for name in ['Walls__cream','Walls__plaster_warm']:
   o=bpy.data.objects.get(name)
   if o:
    obsolete=extract(o,lambda lo,hi:lo.z>=5.20 and hi.z>6.0,'Duplicate gable removed')
    if obsolete:bpy.data.objects.remove(obsolete,do_unlink=True)
 for o in bpy.context.scene.objects:
  if o.type!='MESH':continue
  for i,m in enumerate(o.data.materials):
   if not m:continue
   base=re.sub(r'(\.\d{3})+$','',m.name)
   if base!=m.name:
    canonical=bpy.data.materials.get(base)
    if canonical:o.data.materials[i]=canonical
    else:m.name=base
 bpy.context.scene['plane_aperture_review']='Only existing faces split/removed in the doorway. Original outer bounds preserved; no Boolean closing planes or extrusions.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'plane_aperture_backup':backup.name,'plane_aperture_backup_sha256':sha(backup),'plane_aperture_review':'art/source/world/doorways/v1/clip_apertures.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('FACE-CLIPPED APERTURE',aid,flush=True)
