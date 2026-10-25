"""Final saved-source corrections from the gameplay camera: legible larger-house
leaves, continuous loft tiling at its oriel junction and canonical material names.
"""
import bpy,bmesh,json,hashlib,math,shutil,re
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd();cat=json.loads((ROOT/'pipeline/world-catalog.json').read_text())
exec(compile((ROOT/'art/source/world/doorways/v1/edit_sources.py').read_text().split('\nfor aid,(')[0],'helpers','exec'))
for aid in ['hearth-house','lantern-loft','brook-mill']:
 p=ROOT/cat['assets'][aid]['source'];bpy.ops.wm.open_mainfile(filepath=str(p))
 if bpy.context.scene.get('door_detail_review'):raise RuntimeError('Already reviewed')
 backup=p.with_name('model.pre-door-detail.blend')
 if backup.exists():raise RuntimeError('Preserved source exists')
 shutil.copy2(p,backup)
 front,width,height,bottom=SPECS[aid];hinge=bpy.data.objects['DoorHinge']
 for o in list(hinge.children):bpy.data.objects.remove(o,do_unlink=True)
 # Preserve the existing stone frame, make the leaf a deliberate readable part.
 oak=bpy.data.materials['oak'];iron=bpy.data.materials['iron'];brass=bpy.data.materials['brass']
 leaves=[]
 for k in range(7):
  x=-width/2+(k+.5)*width/7
  crown=0 if aid=='lantern-loft' else .12*(abs(x)/(width/2))**2
  top=bottom+height-crown
  leaves.append(box('Hinged oak plank',(x,-front-.045,(bottom+top)/2),(width/7-.012,.105,top-bottom),oak))
 for z in [bottom+height*.24,bottom+height*.68]:
  leaves.append(box('Forged door strap',(0,-front-.112,z),(width*.86,.035,.065),iron))
  for x in [-width*.35,width*.35]:leaves.append(box('Door strap rivet',(x,-front-.14,z),(.045,.026,.045),brass))
 leaves.append(box('Door knocker plate',(width*.29,-front-.14,bottom+height*.43),(.13,.035,.19),iron))
 # A low-poly brass knocker ring in the door's vertical plane.
 verts=[];faces=[]
 for j in range(16):
  a=math.tau*j/16
  for k in range(6):
   b=math.tau*k/6;r=.075+.017*math.cos(b)
   verts.append((width*.29+r*math.cos(a),-front-.18+.017*math.sin(b),bottom+height*.41+r*math.sin(a)))
 for j in range(16):
  for k in range(6):faces.append((j*6+k,((j+1)%16)*6+k,((j+1)%16)*6+(k+1)%6,j*6+(k+1)%6))
 data=bpy.data.meshes.new('Brass knocker');data.from_pydata(verts,[],faces);data.materials.append(brass);data.update()
 ring=bpy.data.objects.new('Brass knocker',data);bpy.context.scene.collection.objects.link(ring);leaves.append(ring)
 bpy.context.view_layer.update()
 for o in leaves:
  matrix=o.matrix_world.copy();o.parent=hinge;o.matrix_world=matrix
 if aid=='lantern-loft':
  # The moved oriel now projects far enough to meet the main roof naturally;
  # complete its original tile cover over the supporting underboards.
  with bpy.data.libraries.load(str(p.with_name('model.pre-doorways.blend')),link=False) as (data_from,data_to):
   names=[n for n in data_from.objects if n.startswith('Roof__roof_')];data_to.objects=names.copy()
  for name,original in zip(names,data_to.objects):
   target=bpy.data.objects.get(name)
   if target:target.data=original.data.copy()
   bpy.data.objects.remove(original,do_unlink=True)
 for o in bpy.context.scene.objects:
  if o.type!='MESH':continue
  for i,m in enumerate(o.data.materials):
   if not m:continue
   base=re.sub(r'(\.\d{3})+$','',m.name)
   if base!=m.name:
    canonical=bpy.data.materials.get(base)
    if canonical:o.data.materials[i]=canonical
    else:m.name=base
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free()
 bpy.context.scene['door_detail_review']='Separate centered oak boards, forged straps, brass knocker; continuous loft roof junction.'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note=p.parent/'doorways.json';d=json.loads(note.read_text());d.update({'source_sha256':sha(p),'detail_backup':backup.name,'detail_backup_sha256':sha(backup),'detail_review':'art/source/world/doorways/v1/door_detail.py'});note.write_text(json.dumps(d,indent=2)+'\n')
 print('DOOR DETAIL SAVED',aid,flush=True)
