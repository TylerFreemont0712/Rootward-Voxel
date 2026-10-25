"""Recorded deliberate edits of adopted masters, with immutable pre-edit backups.
Not a build recipe: subsequent edits belong in the saved .blend and world-art.sh.
"""
import bpy, bmesh, json, hashlib, shutil, math
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd()
CAT=ROOT/'pipeline/world-catalog.json'
cat=json.loads(CAT.read_text())
REV='2026-10-25-doorways'
SPECS={
 'cottage':(1.50,.86,1.82,.17), 'mill-house':(1.50,.86,1.82,.17),
 'log-cabin':(1.53,.86,1.82,.17),
 'log-cabin-large':(2.43,1.10,2.20,.17), 'log-cabin-large-teal':(2.43,1.10,2.20,.17),
 'hearth-house':(2.47,1.15,2.18,.18), 'lantern-loft':(3.31,1.30,2.28,.15),
 'brook-mill':(2.52,1.38,2.20,.28), 'hollow-bakery':(2.15,1.07,2.13,.17),
 'hollow-smithy':(2.65,1.07,2.13,.17)}

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def bounds(o):
 vs=[o.matrix_world@Vector(v) for v in o.bound_box]
 return Vector([min(v[i] for v in vs) for i in range(3)]),Vector([max(v[i] for v in vs) for i in range(3)])
def box(name,at,size,mat):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at)
 o=bpy.context.object;o.name=name;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 if mat:o.data.materials.append(mat)
 return o
def extract(o,predicate,name):
 bm=bmesh.new();bm.from_mesh(o.data);todo=set(bm.verts);chosen=[]
 while todo:
  stack=[todo.pop()];group=[]
  while stack:
   v=stack.pop();group.append(v)
   for e in v.link_edges:
    other=e.other_vert(v)
    if other in todo:todo.remove(other);stack.append(other)
  vs=[o.matrix_world@v.co for v in group]
  lo=Vector([min(v[i] for v in vs) for i in range(3)]);hi=Vector([max(v[i] for v in vs) for i in range(3)])
  if predicate(lo,hi):chosen.extend(group)
 if not chosen:bm.free();return None
 indices={v.index for v in chosen}
 copy=bm.copy();bmesh.ops.delete(copy,geom=[v for v in copy.verts if v.index not in indices],context='VERTS')
 data=bpy.data.meshes.new(name);copy.to_mesh(data);copy.free()
 for m in o.data.materials:data.materials.append(m)
 new=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(new);new.matrix_world=o.matrix_world.copy()
 bmesh.ops.delete(bm,geom=chosen,context='VERTS');bm.to_mesh(o.data);bm.free()
 return new

def difference(o,cutter):
 bpy.context.view_layer.objects.active=o
 mod=o.modifiers.new('Real doorway opening','BOOLEAN');mod.operation='DIFFERENCE';mod.solver='EXACT';mod.object=cutter
 bpy.ops.object.modifier_apply(modifier=mod.name)

def loft_fix():
 # The old oriel was buried in the main roof; its windows and roof were
 # incorrectly batched with ordinary windows. Move the complete assembly
 # together, bring its cap down, and remove the duplicate straight gables.
 offset=Vector((.45,-.62,0))
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  if o.name.startswith('Turret__'):o.location+=offset
  elif o.name.startswith('Windows__'):
   part=extract(o,lambda lo,hi:lo.x>1.0 and hi.x<4.1 and lo.y< -1.2 and hi.y< -1.1 and lo.z>3.1,'Oriel_'+o.name)
   if part:
    part.location+=offset
    if 'roof_teal' in o.name or 'brass' in o.name:
     # Affine correction keeps every roof course joined at the same pitch.
     for v in part.data.vertices:v.co.z=5.76+(v.co.z-5.76)*.78
  elif o.name in ['Walls__cream','Walls__plaster_warm']:
   obsolete=extract(o,lambda lo,hi:lo.z>=5.20 and hi.z>6.0,'ObsoleteGable')
   if obsolete:bpy.data.objects.remove(obsolete,do_unlink=True)
 # Cut a seat for the oriel instead of letting main roof tiles cover its cap.
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=1.16,depth=4,location=(2.93,-3.14,7.1),rotation=(0,0,math.pi/8))
 cutter=bpy.context.object
 for o in list(bpy.context.scene.objects):
  if o.type=='MESH' and (o.name.startswith('Roof__') or o.name.startswith('Broken pitch')):
   difference(o,cutter)
 bpy.data.objects.remove(cutter,do_unlink=True)

for aid,(front,width,height,bottom) in SPECS.items():
 source=ROOT/cat['assets'][aid]['source']
 bpy.ops.wm.open_mainfile(filepath=str(source))
 if bpy.context.scene.get('doorway_revision'):raise RuntimeError('Already adopted doorway revision: '+aid)
 backup=source.with_name('model.pre-doorways.blend')
 if backup.exists():raise RuntimeError('Backup exists; inspect before editing: '+str(backup))
 shutil.copy2(source,backup);before=sha(source)
 if aid=='lantern-loft':loft_fix()
 leaf=[]
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  if o.name.startswith(('Entrance oak plank','Entrance iron hinge','Entrance brass knocker','Entrance knocker plate')):leaf.append(o)
  elif o.name in ['Door__oak','Door__iron','Door__brass']:
   part=extract(o,lambda lo,hi:hi.z<2.85,'EntryLeaf_'+o.name)
   if part:leaf.append(part)
  elif o.name.startswith('Entrance shadow reveal'):bpy.data.objects.remove(o,do_unlink=True)
 if not leaf:raise RuntimeError('No door leaf found for '+aid)
 hinge=bpy.data.objects.new('DoorHinge',None);bpy.context.scene.collection.objects.link(hinge)
 hinge.location=(-width/2,-front,bottom)
 bpy.context.view_layer.update()
 for o in leaf:
  matrix=o.matrix_world.copy();o.parent=hinge;o.matrix_world=matrix
 # Carve the wall and footing behind the opening. Exclude the preserved
 # stone arch, hardware, steps, and unrelated decorative fittings.
 cutter=box('Doorway cutter',(0,-front+.60,bottom+height/2),(width+.025,1.9,height+.03),None)
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH' or o==cutter or o in leaf or o.parent==hinge:continue
  if o.name.startswith(('Entrance','Door__','EntryLeaf','Fittings__','Windows__','Roof__','Oriel_','Turret__','Balcony__')):continue
  lo,hi=bounds(o)
  if hi.x> -width/2 and lo.x<width/2 and lo.y< -front+1.5 and hi.y> -front-.35 and hi.z>bottom and lo.z<bottom+height:
   difference(o,cutter)
 bpy.data.objects.remove(cutter,do_unlink=True)
 dark=bpy.data.materials.get('entrance_recess') or bpy.data.materials.get('dark')
 if not dark:
  dark=bpy.data.materials.new('entrance_recess');dark.use_nodes=True
  bs=next(n for n in dark.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Base Color'].default_value=(.018,.012,.008,1)
 box('Doorway dark interior',(0,-front+1.32,bottom+height/2),(width+.15,.08,height+.12),dark)
 # Replace uneven/offset approach blocks with a centered, two-tread landing.
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  if o.name.startswith(('Entrance threshold','Entrance lower step')):bpy.data.objects.remove(o,do_unlink=True)
  elif o.name=='Fittings__stone_edge':
   obsolete=extract(o,lambda lo,hi:hi.z<.5,'OldSteps')
   if obsolete:bpy.data.objects.remove(obsolete,do_unlink=True)
 stone=bpy.data.materials.get('entrance_stone') or bpy.data.materials.get('stone_edge') or bpy.data.materials.get('stone_light')
 half=cat['assets'][aid]['logical_footprint'][3]/2
 top=max(.185,bottom+.015)
 steps=[[half+.85,half+.30,width+.65,top*.52],[half+.42,half-.65,width+.40,top]]
 for i,(outer,inner,w,z) in enumerate(steps):box('Walkable entry tread '+str(i),(0,-(outer+inner)/2,z/2),(w,outer-inner,z),stone)
 # The player can actually stand in the opening before the scene fades.
 ent=cat['assets'][aid].setdefault('entrance',{})
 ent.update({'plane':front,'width':width,'height':height,'bottom':bottom,'steps':steps,'hinge':'DoorHinge'})
 bpy.context.scene['doorway_revision']=REV
 bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
 note={'revision':REV,'asset':aid,'before_sha256':before,'source_sha256':sha(source),'backup':backup.name,'script':'art/source/world/doorways/v1/edit_sources.py','note':'Preserved adopted geometry; extracted hinged leaf, carved opening and centered two-tread approach. Loft oriel moved as a whole, lowered cap, main roof seat, duplicate gable removed.'}
 (source.parent/'doorways.json').write_text(json.dumps(note,indent=2)+'\n')
 print('DOORWAY SAVED',aid,flush=True)
CAT.write_text(json.dumps(cat,indent=2)+'\n')
