"""Spatial edit of copied adopted landmark masters. Keeps UVs, corner normals, metadata and moving parts."""
from pathlib import Path
import sys,json,math,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
remaining = '--remaining' in sys.argv
for id in (['rootwell-beacon'] if remaining else ['rootwell-plaza','rootwell-beacon']):
 cat=json.load(open(ROOT/'pipeline/world-catalog.json'));path=ROOT/cat['assets'][id]['source']
 bpy.ops.wm.open_mainfile(filepath=str(path))
 if bpy.context.scene.get('landmark_chunks') and not remaining:raise RuntimeError('Already split '+id)
 source_hash=hashlib.sha256(path.read_bytes()).hexdigest();counts=[]
 for o in list(bpy.context.scene.objects):
  if o.type!='MESH':continue
  # These known static surface buckets caused overlap; semantic moving parts stay whole.
  allowed=('conduit_glass_glass','grid_bed','grid_bronze','house_paint','seaside_stone','rootwell_brass','rootwell_conduit_frame_grid_bed','rootwell_conduit_frame_grid_bronze','rootwell_conduit_glass','rootwell_verdigris','seaside_timber')
  if o.name not in allowed or remaining and o.name not in ['rootwell_brass','rootwell_verdigris']:continue
  pts=[o.matrix_world@Vector(v) for v in o.bound_box]
  if max(max(p[a] for p in pts)-min(p[a] for p in pts) for a in [0,1])<2.8:continue
  bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.transform(bm,matrix=o.matrix_world,verts=list(bm.verts))
  for axis in [0,1]:
   lo=min(v.co[axis] for v in bm.verts);hi=max(v.co[axis] for v in bm.verts)
   for at in range(math.floor(lo/3)*3+3,math.ceil(hi/3)*3,3):
    n=Vector((int(axis==0),int(axis==1),0))
    bmesh.ops.bisect_plane(bm,geom=list(bm.verts)+list(bm.edges)+list(bm.faces),dist=.00001,plane_co=n*at,plane_no=n,clear_inner=False,clear_outer=False)
  bm.normal_update();temp=bpy.data.meshes.new('Landmark split temporary');bm.to_mesh(temp);bm.free();temp.update()
  uv=temp.uv_layers.active;groups={}
  for f in temp.polygons:
   center=sum((temp.vertices[i].co for i in f.vertices),Vector())/len(f.vertices)
   key=(math.floor(center.x/3),math.floor(center.y/3))
   groups.setdefault(key,[]).append(f)
  for key,faces in groups.items():
   name=f'{o.name}_section_{key[0]}_{key[1]}';verts=[];polys=[];uvs=[];normals=[];mapping={}
   for f in faces:
    indices=[]
    for vi,li in zip(f.vertices,f.loop_indices):
     if vi not in mapping:mapping[vi]=len(verts);verts.append(tuple(temp.vertices[vi].co))
     indices.append(mapping[vi]);uvs.append(tuple(uv.data[li].uv) if uv else (0,0));normals.append(tuple(temp.corner_normals[li].vector))
    polys.append(indices)
   mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],polys)
   for m in o.data.materials:mesh.materials.append(m)
   layer=mesh.uv_layers.new(name='UVMap')
   for f,old in zip(mesh.polygons,faces):f.material_index=old.material_index;f.use_smooth=old.use_smooth
   for li,tex in enumerate(uvs):layer.data[li].uv=tex
   mesh.update();mesh.normals_split_custom_set(normals)
   n=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(n)
   for prop in o.keys():n[prop]=o[prop]
   n['spatial_section']=True
  counts.append([o.name,len(groups)])
  bpy.data.meshes.remove(temp);bpy.data.objects.remove(o,do_unlink=True)
 bpy.context.scene['landmark_chunks']=True;bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 record=path.with_name('spatial-sections.json')
 previous=json.loads(record.read_text()) if remaining and record.exists() else {}
 record.write_text(json.dumps({'source_sha256':previous.get('source_sha256',source_hash),'followup_source_sha256':source_hash if remaining else None,'chunks':previous.get('chunks',[])+counts,'metres':3},indent=2))
 print('LANDMARK CHUNKS',id,counts)
