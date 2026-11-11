"""Refine the saved model after the real-size Godot review: avoid overlapping ink hulls on fine roof/dial geometry."""
from pathlib import Path
import sys,hashlib
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clock_runtime_details'):raise RuntimeError('Already refined after runtime review.')
before=hashlib.sha256(path.read_bytes()).hexdigest()
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH' or obj.name not in ['refined_structure','refined_frontage']:continue
 # Dials need enough physical separation from their cases, independent of their silhouette ink.
 if obj.name=='refined_frontage':
  bm=bmesh.new();bm.from_mesh(obj.data);seen=set()
  for seed in bm.verts:
   if seed in seen:continue
   stack=[seed];seen.add(seed);group=[]
   while stack:
    v=stack.pop();group.append(v)
    for e in v.link_edges:
     other=e.other_vert(v)
     if other not in seen:seen.add(other);stack.append(other)
   fs={f for v in group for f in v.link_faces};mats={obj.data.materials[f.material_index].name for f in fs}
   lo=Vector(tuple(min(v.co[i] for v in group) for i in range(3)));hi=Vector(tuple(max(v.co[i] for v in group) for i in range(3)));c=(lo+hi)*.5
   in_bay=(-1.24<c.x<.42) or (1.72<c.x<3.44)
   if in_bay and c.y<-2.43 and .73<lo.z and hi.z<2.60 and mats.issubset({'clock_ivory_dial','clock_watch_gold','clock_bronze_dark'}):
    for v in group:v.co.y-=.05
  bm.to_mesh(obj.data);bm.free();obj.data.update()
 # Split only opaque fine-detail roles. Main plaster, masonry and wooden joinery keep the approved outlines.
 roles={}
 for f in obj.data.polygons:
  mat=obj.data.materials[f.material_index].name
  role='roof' if mat in ['clock_copper_painted','clock_copper_edge'] else 'dial_details' if mat in ['clock_ivory_dial','clock_watch_gold','clock_bronze_dark'] else 'structure'
  roles.setdefault(role,[]).append(f.index)
 for role,indices in roles.items():
  bm=bmesh.new();bm.from_mesh(obj.data);bm.faces.ensure_lookup_table();keep=set(indices)
  bmesh.ops.delete(bm,geom=[f for f in bm.faces if f.index not in keep],context='FACES')
  mesh=bpy.data.meshes.new(obj.name+'_'+role);bm.to_mesh(mesh);bm.free()
  for m in obj.data.materials:mesh.materials.append(m)
  mesh.update();out=bpy.data.objects.new(obj.name+'_'+role,mesh);bpy.context.scene.collection.objects.link(out);out.parent=obj.parent;out.matrix_world=obj.matrix_world.copy()
  if role in ['roof','dial_details']:out['illustrated_edges']=False
 bpy.data.objects.remove(obj,do_unlink=True)
# Main clock chapter disc and semantic hands already have modeled rims and shapes.
for name in ['clock_cream','clock_brass','clock_hour_hand','clock_minute_hand','clock_pendulum','refined_mechanism']:
 obj=bpy.data.objects.get(name)
 if obj:obj['illustrated_edges']=False
# One double-sided skin is sufficient for each pane; avoid layering two tinted glass faces at the same depth.
for obj in bpy.context.scene.objects:
 if obj.type!='MESH':continue
 bm=bmesh.new();bm.from_mesh(obj.data);remove=[]
 for f in bm.faces:
  mat=obj.data.materials[f.material_index]
  if mat and mat.name=='clock_clear_glass' and f.normal.y>=-.0001:remove.append(f)
 if remove:bmesh.ops.delete(bm,geom=remove,context='FACES');bm.to_mesh(obj.data);obj.data.update()
 bm.free()
bpy.context.scene['clock_runtime_details']=True
save_record(path,'runtime_detail_finish',before)
print('RUNTIME DETAIL FINISH SAVED')
