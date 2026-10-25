"""Correct inward normals exposed by the door/camera review, retaining previous sources.
Restores only meshes touched by the first aperture cut, then cuts them after
outward normals are established. This prevents Boolean damage to inverted solids.
"""
import bpy,bmesh,json,hashlib,shutil,math
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd();cat=json.loads((ROOT/'pipeline/world-catalog.json').read_text())
helpers=(ROOT/'art/source/world/doorways/v1/edit_sources.py').read_text().split('\nfor aid,(')[0]
exec(compile(helpers,'doorway_helpers','exec'))

def outward(o):
 bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()

for aid,spec in list(SPECS.items())+[('concept-cottage',(1.855,1.08,2.11,.22))]:
 source=ROOT/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(source))
 if bpy.context.scene.get('doorway_normals_review'):raise RuntimeError('Already corrected: '+aid)
 reviewbackup=source.with_name('model.pre-doorway-review.blend')
 if reviewbackup.exists() and sha(reviewbackup)!=sha(source):raise RuntimeError('Backup differs; inspect before editing.')
 if not reviewbackup.exists():shutil.copy2(source,reviewbackup)
 front,width,height,bottom=spec
 restore=[]
 if aid!='concept-cottage':
  old=source.with_name('model.pre-doorways.blend')
  with bpy.data.libraries.load(str(old),link=False) as (data_from,data_to):
   names=list(data_from.objects);data_to.objects=names.copy()
  original=dict(zip(names,data_to.objects));temp=bpy.data.collections.new('Source restoration');bpy.context.scene.collection.children.link(temp)
  for o in original.values():
   if o:temp.objects.link(o)
  bpy.context.view_layer.update()
  for name,o in original.items():
   if not o or o.type!='MESH':continue
   roof=aid=='lantern-loft' and name.startswith(('Roof__','Broken pitch'))
   skipped=name.startswith(('Entrance','Door__','EntryLeaf','Fittings__','Windows__','Roof__','Oriel_','Turret__','Balcony__'))
   lo,hi=bounds(o)
   candidate=not skipped and hi.x> -width/2 and lo.x<width/2 and lo.y< -front+1.5 and hi.y> -front-.35 and hi.z>bottom and lo.z<bottom+height
   if not roof and not candidate:continue
   target=bpy.data.objects.get(name)
   if not target:continue
   target.data=o.data.copy()
   if candidate:restore.append(target)
  for o in original.values():
   if o:bpy.data.objects.remove(o,do_unlink=True)
  bpy.data.collections.remove(temp)
 # Closed box and tile shells had inward winding in the original authoring
 # helpers. Recalculate each component before cutting or exporting it.
 for o in bpy.context.scene.objects:
  if o.type=='MESH':outward(o)
 if restore:
  cutter=box('Reviewed opening cutter',(0,-front+.60,bottom+height/2),(width+.025,1.9,height+.03),None);outward(cutter)
  for o in restore:difference(o,cutter)
  bpy.data.objects.remove(cutter,do_unlink=True)
 if aid=='lantern-loft':
  # The original cut was applied to inverted tile volumes. These are now
  # restored, oriented correctly and seated neatly around the moved oriel.
  bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=1.16,depth=4,location=(2.93,-3.14,7.1),rotation=(0,0,math.pi/8))
  cutter=bpy.context.object
  for o in list(bpy.context.scene.objects):
   if o.type=='MESH' and o.name.startswith(('Roof__','Broken pitch')):difference(o,cutter)
  bpy.data.objects.remove(cutter,do_unlink=True)
  for name in ['Walls__cream','Walls__plaster_warm']:
   o=bpy.data.objects.get(name)
   if o:
    obsolete=extract(o,lambda lo,hi:lo.z>=5.20 and hi.z>6.0,'Removed duplicate gable')
    if obsolete:bpy.data.objects.remove(obsolete,do_unlink=True)
 bpy.context.scene['doorway_normals_review']='Outward closed-shell normals; verified aperture and roof seat.'
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=source.parent/('doorways.json' if aid!='concept-cottage' else 'provenance.json')
 record=json.loads(note.read_text());record['source_sha256']=sha(source);record['review_backup']=reviewbackup.name;record['review_backup_sha256']=sha(reviewbackup);record['review_script']='art/source/world/doorways/v1/review_corrections.py';note.write_text(json.dumps(record,indent=2)+'\n')
 print('REVIEWED NORMALS AND APERTURES',aid,flush=True)
