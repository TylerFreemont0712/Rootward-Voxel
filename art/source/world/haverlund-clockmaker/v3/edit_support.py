"""Small source-edit helpers; no building generator or runtime dependency."""
from pathlib import Path
import sys,math,json,hashlib
import bpy,bmesh
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'))
import house_kit as k

def bind_materials():
 k.M.clear();k.M.update({m.name:m for m in bpy.data.materials})

def discard_components(obj,predicate):
 if obj.type!='MESH':return 0
 bm=bmesh.new();bm.from_mesh(obj.data);seen=set();discard=[]
 for seed in bm.verts:
  if seed in seen:continue
  stack=[seed];seen.add(seed);group=[]
  while stack:
   v=stack.pop();group.append(v)
   for edge in v.link_edges:
    other=edge.other_vert(v)
    if other not in seen:seen.add(other);stack.append(other)
  pts=[obj.matrix_world@v.co for v in group];lo=Vector(tuple(min(v[i] for v in pts) for i in range(3)));hi=Vector(tuple(max(v[i] for v in pts) for i in range(3)))
  if predicate(lo,hi,(lo+hi)*.5):discard.extend(group)
 if discard:bmesh.ops.delete(bm,geom=discard,context='VERTS');bm.to_mesh(obj.data);obj.data.update()
 n=len(discard);bm.free();return n

def remove_material_faces(obj, predicate):
 if obj.type!='MESH':return 0
 bm=bmesh.new();bm.from_mesh(obj.data);faces=[]
 for f in bm.faces:
  mat=obj.data.materials[f.material_index] if f.material_index<len(obj.data.materials) else None
  c=obj.matrix_world@f.calc_center_median()
  if predicate(mat.name if mat else '',c):faces.append(f)
 if faces:bmesh.ops.delete(bm,geom=faces,context='FACES');bm.to_mesh(obj.data);obj.data.update()
 n=len(faces);bm.free();return n

def arch(p,cx,y,z,width,rise,mat='timber',thick=.08,depth=.10,steps=24):
 # Segmental or semicircular arches: x is elliptical, so shallow lintels remain shallow.
 r=width/2
 for i in range(steps):
  a=math.pi*i/steps;b=math.pi*(i+1)/steps
  pts=[(cx+r*math.cos(a),y,z+rise*math.sin(a)),(cx+r*math.cos(b),y,z+rise*math.sin(b)),(cx+(r+thick)*math.cos(b),y,z+(rise+thick)*math.sin(b)),(cx+(r+thick)*math.cos(a),y,z+(rise+thick)*math.sin(a))]
  p.solid(mat,pts,depth,(0,-1,0),uv=('blocks',) if mat=='stone' else 'world')

def arched_face(p,cx,y,z0,width,spring,rise,mat):
 r=width/2;pts=[(cx-r,y,z0),(cx+r,y,z0)]+[(cx+r*math.cos(math.pi*i/24),y,spring+rise*math.sin(math.pi*i/24)) for i in range(25)]
 p.solid(mat,pts,.018,(0,-1,0))

def finish(p,root):
 p.finish(root)

def save_record(path,record,previous):
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name(record+'.json').write_text(json.dumps({'previous_sha256':previous,'record':'art/source/world/haverlund-clockmaker/v3/'+record+'.py','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()},indent=2)+'\n')
