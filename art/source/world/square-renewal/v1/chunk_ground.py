"""Spatially split the copied adopted ground, preserving its mesh, UVs and materials.
Faces are bisected, not discarded; per-chunk bounds keep local lights and culling local.
A 4 m near grid and 16 m far grid avoid the Compatibility renderer's eight-light competition.
"""
from pathlib import Path
import sys,json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
id='haverlund-square-ground';cat=json.load(open(ROOT/'pipeline/world-catalog.json'));path=ROOT/cat['assets'][id]['source']
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('square_chunks'):raise RuntimeError('Already split; edit the adopted master.')
source_hash=hashlib.sha256(path.read_bytes()).hexdigest();counts=[]
# New shop terrace: a narrow flagstone pavement on the existing level-two lawn.
flags=bpy.data.materials.get('ground_flags')
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':continue
 bm=bmesh.new();bm.from_mesh(o.data)
 # Apply object transform so chunking is in area coordinates, then reset on each result.
 bmesh.ops.transform(bm,matrix=o.matrix_world,verts=list(bm.verts))
 for axis in [0,1]:
  low=min(v.co[axis] for v in bm.verts);high=max(v.co[axis] for v in bm.verts)
  cuts=set(range(math.floor(low/16)*16+16,math.ceil(high/16)*16,16))
  cuts.update(range(0,77 if axis==0 else 69,4))
  # Terrace's ground paint boundary (UVs stay continuous).
  cuts.update([-0.5,11.5] if axis==0 else [10.5,12.5,18.5])
  for at in sorted(cuts):
   if at<=low+.0001 or at>=high-.0001:continue
   normal=Vector((int(axis==0),int(axis==1),0));point=normal*at
   bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=point,plane_no=normal,use_snap_center=False,clear_inner=False,clear_outer=False)
 bm.normal_update();uv=bm.loops.layers.uv.active
 mats=list(o.data.materials)
 if flags not in mats:mats.append(flags)
 buckets={}
 for f in bm.faces:
  c=f.calc_center_median();near=-.5<=c.x<76 and -.5<=c.y<68
  size=4 if near else 16
  key=(math.floor(c.x/size),math.floor(c.y/size),size)
  mat=f.material_index
  if o.name=='ground_grass' and -.5<c.x<11.5 and 10.5<c.y<12.5 and abs(c.z-2)<.02 and f.normal.z>.9:mat=mats.index(flags)
  buckets.setdefault(key,[]).append(([(v.co.x,v.co.y,v.co.z) for v in f.verts],[tuple(l[uv].uv) if uv else (0,0) for l in f.loops],mat,f.smooth))
 for key,faces in buckets.items():
  name=f'{o.name}_chunk_{key[0]}_{key[1]}_{key[2]}';verts=[];polys=[]
  for pts,_,_,_ in faces:base=len(verts);verts.extend(pts);polys.append(tuple(range(base,len(verts))))
  mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],polys)
  for m in mats:mesh.materials.append(m)
  layer=mesh.uv_layers.new(name='UVMap')
  for poly,(_,uvs,mat,smooth) in zip(mesh.polygons,faces):
   poly.material_index=mat;poly.use_smooth=smooth
   for li,tex in zip(poly.loop_indices,uvs):layer.data[li].uv=tex
  mesh.update();n=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(n)
  for prop in o.keys():n[prop]=o[prop]
  n['ground_chunk']=True
 counts.append([o.name,len(bm.faces),len(buckets)])
 bm.free();bpy.data.objects.remove(o,do_unlink=True)
bpy.context.scene['square_chunks']=True
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
path.with_name('spatial-chunks.json').write_text(json.dumps({'source_sha256':source_hash,'chunks':counts,'near_metres':4,'far_metres':16},indent=2))
print('CHUNKS',counts)
