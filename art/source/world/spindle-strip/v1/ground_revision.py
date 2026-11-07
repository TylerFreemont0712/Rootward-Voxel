"""Bounded deliberate edit of adopted v3 ground: enlarged landing, park, and shopping promenade.
Preserves the rest of the saved source, existing local-light sections and eastward stair treads.
"""
from pathlib import Path
import sys,json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
path=ROOT/'art/source/world/haverlund-square-ground/v3/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('spindle_strip_revision'):raise RuntimeError('Already revised: edit the saved master.')
source_hash=hashlib.sha256(path.read_bytes()).hexdigest()
# Replace only these specific terrain pieces; all other authored square geometry survives.
rects=[(-12.5,-.5,5.5,5.5),(-12.5,5.5,5.5,14.5),(-.5,10.5,11.5,54.5),(5.5,9.5,11.5,10.5)]
removed=0
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 corners=[obj.matrix_world@Vector(p) for p in obj.bound_box]
 if max(p.x for p in corners)<-12.6 or min(p.x for p in corners)>11.6 or max(p.y for p in corners)<-.6 or min(p.y for p in corners)>54.6:continue
 bm=bmesh.new();bm.from_mesh(obj.data);bmesh.ops.transform(bm,matrix=obj.matrix_world,verts=list(bm.verts))
 for axis,cuts in [(0,[-12.5,-.5,5.5,11.5]),(1,[-.5,5.5,9.5,10.5,14.5,54.5])]:
  for at in cuts:
   normal=Vector((int(axis==0),int(axis==1),0))
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=normal*at,plane_no=normal,clear_inner=False,clear_outer=False)
 faces=[]
 for f in bm.faces:
  c=f.calc_center_median()
  if c.z<-.025:continue  # retain lower-town retaining foundations
  inside=any(a-.0001<c.x<b+.0001 and d-.0001<c.y<e+.0001 for a,d,b,e in rects)
  if not inside:continue
  # Keep the east retaining wall along the long terrace, its coping, and the replacement bay.
  if c.x>11.10 and c.y>14.5 and f.normal.z<.9:continue
  faces.append(f)
 removed+=len(faces)
 if faces:bmesh.ops.delete(bm,geom=faces,context='FACES')
 if not bm.faces:
  bm.free();bpy.data.objects.remove(obj,do_unlink=True);continue
 bm.to_mesh(obj.data);bm.free();obj.data.update()
# Native packed ground materials; no new texture or alternate runtime pipeline.
mats={n:bpy.data.materials[n] for n in ['ground_flags','ground_cobbles','ground_grass','seaside_stone']}
buckets={}
def face(mat,verts):
 center=sum((Vector(v) for v in verts),Vector())/len(verts);key=(mat,math.floor(center.x/4),math.floor(center.y/4))
 buckets.setdefault(key,[]).append(verts)
# One metre quads keep logical support and local light bounds exact.
for x in range(-12,12):
 for y in range(0,55):
  park=x<=5 and y<=5;arrival=x<=5 and 6<=y<=14;terrace=0<=x<=11 and 11<=y<=54;lip=6<=x<=11 and y==10
  if not (park or arrival or terrace or lip):continue
  if park:
   mat='ground_flags' if x==3 or y==2 else 'ground_grass'
  elif arrival or lip:mat='ground_cobbles' if 10<=y<=13 else 'ground_flags'
  elif terrace:
   mat='ground_cobbles' if 6<=x<=8 else 'ground_flags'
   if x<5 and y>=16 and y<52:mat='ground_grass'
   # Four paved frontage courts, ready for original models after concept approval.
   if 0<=x<=4 and any(a<=y<=b for a,b in [(16,23),(26,34),(37,43),(46,51)]):mat='ground_flags'
  face(mat,[(x-.5,y-.5,2),(x+.5,y-.5,2),(x+.5,y+.5,2),(x-.5,y+.5,2)])
# Retaining faces at the raised park's east/south edges and enlarged north stair cheek.
def wall(a,b,z0,z1,normal):
 # Small sections with the same metre/world UV convention as the existing ashlar.
 length=math.dist(a,b);count=max(1,math.ceil(length))
 for n in range(count):
  t0=n/count;t1=(n+1)/count
  x0=a[0]+(b[0]-a[0])*t0;y0=a[1]+(b[1]-a[1])*t0
  x1=a[0]+(b[0]-a[0])*t1;y1=a[1]+(b[1]-a[1])*t1
  points=[(x0,y0,z0),(x1,y1,z0),(x1,y1,z1),(x0,y0,z1)]
  u=Vector(points[1])-Vector(points[0]);v=Vector(points[2])-Vector(points[0])
  if u.cross(v).dot(Vector(normal))<0:points.reverse()
  face('seaside_stone',points)
wall((-12.5,-.5),(5.5,-.5),0,2,(0,-1,0))
wall((5.5,-.5),(5.5,5.5),0,2,(1,0,0))
wall((5.5,9.5),(6.5,9.5),1,2,(0,-1,0))
wall((6.5,9.5),(10.5,9.5),1,2,(0,-1,0))
wall((10.5,9.5),(11.5,9.5),0,2,(0,-1,0))
# The long promenade already retains its original east wall; new landing meets it at the stair head.
wall((-12.5,14.5),(-2.5,14.5),2,4,(0,-1,0))
wall((-12.5,-.5),(-12.5,14.5),2,3,(1,0,0))
# Export ordinary editable meshes with world-aligned UVs; retain 4 m lighting sections.
for (mat,cx,cy),faces in buckets.items():
 verts=[];polys=[]
 for points in faces:base=len(verts);verts.extend(points);polys.append(tuple(range(base,len(verts))))
 name=f'spindle_{mat}_{cx}_{cy}';mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],polys);mesh.materials.append(mats[mat]);uv=mesh.uv_layers.new(name='UVMap')
 for p in mesh.polygons:
  axis=max(range(3),key=lambda i:abs(p.normal[i]));a,b=[(1,2),(0,2),(0,1)][axis]
  for li in p.loop_indices:
   co=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(co[a]/(1.9 if mat=='seaside_stone' else (8 if mat=='ground_grass' else 3)),co[b]/(1.9 if mat=='seaside_stone' else (8 if mat=='ground_grass' else 3)))
 mesh.update();obj=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(obj);obj['ground_chunk']=True
bpy.context.scene['spindle_strip_revision']=True;bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('spindle-strip.json').write_text(json.dumps({'previous_source_sha256':source_hash,'removed_faces':removed,'new_sections':len(buckets),'record':'art/source/world/spindle-strip/v1/ground_revision.py'},indent=2))
print('SPINDLE GROUND',removed,'faces replaced;',len(buckets),'new local sections')
