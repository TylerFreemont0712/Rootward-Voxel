"""Deliberate edit of adopted v3: flat upper shelf, westward map extension; preserve the lower square."""
from pathlib import Path
import json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
source=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
target=ROOT/'art/source/world/haverlund-square-ground/v4/model.blend'
if target.exists():raise RuntimeError('v4 exists; edit the saved master deliberately')
bpy.ops.wm.open_mainfile(filepath=str(source))
removed=0
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 pts=[obj.matrix_world@Vector(v) for v in obj.bound_box]
 if min(p.x for p in pts)>11.6 or max(p.y for p in pts)<-.6:continue
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.transform(bm,matrix=obj.matrix_world,verts=list(bm.verts))
 for axis,cuts in [(0,[-32.5,5.5,11.5]),(1,[-.5,9.5,96.5])]:
  for at in cuts:
   n=Vector((axis==0,axis==1,0));bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=n*at,plane_no=n,clear_inner=False,clear_outer=False)
 fs=[]
 for f in bm.faces:
  c=f.calc_center_median()
  inside=-32.5001<c.x<11.4999 and -.5001<c.y<96.5001 and (c.x<5.4999 or c.y>9.5001)
  # Retain the terrace's outer east retaining masonry and all stair bay geometry.
  if inside and c.z>-.025:
   if c.x>11.1 and f.normal.z<.9:continue
   fs.append(f)
 removed+=len(fs)
 if fs:bmesh.ops.delete(bm,geom=fs,context='FACES')
 if not bm.faces:bm.free();bpy.data.objects.remove(obj,do_unlink=True);continue
 # Bake world transform once so the 16-cell rebase affects every mesh identically.
 bm.to_mesh(obj.data);bm.free();obj.matrix_world.identity();obj.location.x=16;obj.data.update()
buckets={}
def face(mat,points):
 c=sum((Vector(p) for p in points),Vector())/len(points);chunk=4 if c.x>-17 and c.y<56 else 16
 buckets.setdefault((mat,math.floor(c.x/chunk),math.floor(c.y/chunk),chunk),[]).append(points)
for x in range(-32,12):
 for y in range(0,97):
  if x>=6 and y<10:continue
  mat='ground_grass'
  if 10<=y<=14:mat='ground_cobbles' if 10<=y<=13 else 'ground_flags'
  if y>=15 and 1<=x<=3:mat='ground_cobbles'
  if y>=15 and x in [0,4]:mat='ground_flags'
  if -6<=x<0 and any(a<=y<=b for a,b in [(16,23),(26,34),(37,43),(46,51)]):mat='ground_flags'
  if x<=5 and y==2:mat='ground_flags'
  if y<=9 and x==3:mat='ground_flags'
  face(mat,[(x-.5,y-.5,2),(x+.5,y-.5,2),(x+.5,y+.5,2),(x-.5,y+.5,2)])
# Park edge continues the existing retaining wall at the stair bay. Individual sampled bricks preserve masonry UVs.
import sys,random
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'));import house_kit as kit
rng=random.Random(1103)
wall_faces=[]
for x in range(-32,6):
 for row in range(8):
  for half in range(2):
   a=x-.5+half*.5;b=a+.5;z=row*.25
   wall_faces.append(([(a,-.5,z),(b,-.5,z),(b,-.5,z+.25),(a,-.5,z+.25)],rng.choice(kit.STONE_BLOCKS)))
for (mat,cx,cy,chunk),polys in buckets.items():
 verts=[];faces=[]
 for pts in polys:base=len(verts);verts.extend(pts);faces.append(tuple(range(base,base+4)))
 name=f'upper_flat_{mat}_{cx}_{cy}_{chunk}';mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.materials.append(bpy.data.materials[mat]);mesh.update();layer=mesh.uv_layers.new(name='UVMap')
 for p in mesh.polygons:
  for li in p.loop_indices:
   co=mesh.vertices[mesh.loops[li].vertex_index].co;layer.data[li].uv=(co.x/(8 if mat=='ground_grass' else 3),co.y/(8 if mat=='ground_grass' else 3))
 obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj);obj.location.x=16;obj['ground_chunk']=True
# Small masonry sections also retain bounded local-light influence.
for start in range(0,len(wall_faces),64):
 verts=[];faces=[];uvs=[]
 for pts,(x0,x1,y0,y1) in wall_faces[start:start+64]:
  base=len(verts);verts.extend(pts);faces.append(tuple(range(base,base+4)));uvs.append([(x0/512,1-y1/512),(x1/512,1-y1/512),(x1/512,1-y0/512),(x0/512,1-y0/512)])
 mesh=bpy.data.meshes.new(f'upper_park_masonry_{start}');mesh.from_pydata(verts,[],faces);mesh.materials.append(bpy.data.materials['seaside_stone']);layer=mesh.uv_layers.new(name='UVMap')
 for p,coords in zip(mesh.polygons,uvs):
  for li,uv in zip(p.loop_indices,coords):layer.data[li].uv=uv
 mesh.update();obj=bpy.data.objects.new(mesh.name,mesh);bpy.context.scene.collection.objects.link(obj);obj.location.x=16
bpy.context.scene['flat_upper_revision']=True
bpy.context.preferences.filepaths.save_version=0;target.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(target))
target.with_name('revision.json').write_text(json.dumps({'previous_source':str(source.relative_to(ROOT)),'previous_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'removed_faces':removed,'offset':[16,0],'script':str(Path(__file__).relative_to(ROOT))},indent=2))
print('Flat upper:',removed,'old faces replaced;',len(buckets),'ground sections')
