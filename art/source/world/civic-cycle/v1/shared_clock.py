"""Deliberate follow-up: separate the two existing hall clock hands, retaining their original geometry and UVs."""
from pathlib import Path
import bpy,bmesh,shutil,math,json,hashlib
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[5];p=ROOT/'art/source/world/square-guildhall/v1/model.blend';backup=p.with_name('model.pre-shared-clock.blend')
if backup.exists():raise RuntimeError('Clock revision exists; inspect its saved source.')
shutil.copy2(p,backup);bpy.ops.wm.open_mainfile(filepath=str(p));centre=Vector((0,-4.27,7.25));found=0
for o in list(bpy.context.scene.objects):
 if o.type!='MESH' or not any(m.name.startswith('square_ink') for m in o.data.materials):continue
 bm=bmesh.new();bm.from_mesh(o.data);seen=set();remove=[]
 for v in bm.verts:
  if v in seen:continue
  group=[];stack=[v];seen.add(v)
  while stack:
   cur=stack.pop();group.append(cur)
   for edge in cur.link_edges:
    q=edge.other_vert(cur)
    if q not in seen:seen.add(q);stack.append(q)
  coords=[o.matrix_world@v.co-centre for v in group];dist=[math.hypot(q.x,q.z) for q in coords]
  if min(dist)<.03 and .20<max(dist)<.42 and max(abs(q.y) for q in coords)<.035:
   length=max(dist);angle=math.radians(80 if length>.32 else -30);name='clock_minute_hand' if length>.32 else 'clock_hour_hand';rot=Matrix.Rotation(angle-math.pi/2,4,'Y');verts=list(group);indices={v:i for i,v in enumerate(verts)};keep=set(verts);faces=[f for f in bm.faces if all(v in keep for v in f.verts)]
   mesh=bpy.data.meshes.new(name);mesh.from_pydata([rot@(o.matrix_world@v.co-centre) for v in verts],[],[[indices[v] for v in f.verts] for f in faces])
   for m in o.data.materials:mesh.materials.append(m)
   uv=mesh.uv_layers.new(name='UVMap')
   for poly,face in zip(mesh.polygons,faces):
    poly.material_index=face.material_index
    if bm.loops.layers.uv.active:
     for index,loop in zip(poly.loop_indices,face.loops):uv.data[index].uv=loop[bm.loops.layers.uv.active].uv
   hand=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(hand);hand.location=centre;hand['part']=name;remove+=verts;found+=1
 if remove:bmesh.ops.delete(bm,geom=remove,context='VERTS');bm.to_mesh(o.data)
 bm.free()
if found!=2:raise RuntimeError('Expected two distinct original clock hands, found '+str(found))
bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p));f=p.with_name('city-cycle-revision.json');d=json.loads(f.read_text());d['after']=hashlib.sha256(p.read_bytes()).hexdigest();d['clock_record']='art/source/world/civic-cycle/v1/shared_clock.py';d['clock_parts']=['clock_hour_hand','clock_minute_hand'];f.write_text(json.dumps(d,indent=2)+'\n')
