"""Deliberate saved-master refinement: real-volume clock hands and properly filled side-wall openings."""
from pathlib import Path
import sys,json,hashlib,math
import bpy,bmesh
P=Path(__file__).with_name('model.blend');ROOT=Path(__file__).resolve().parents[5]
bpy.ops.wm.open_mainfile(filepath=str(P))
if bpy.context.scene.get('detail_finish'):raise RuntimeError('Already finished; edit the saved master.')
before=hashlib.sha256(P.read_bytes()).hexdigest()
for name,L,w in [('clock_hour_hand',.45,.065),('clock_minute_hand',.65,.045)]:
 obj=bpy.data.objects[name]
 pts=[(-w*.5,-.12),(w*.5,-.12),(w*.5,L*.68),(w*1.1,L*.77),(0,L),(-w*1.1,L*.77),(-w*.5,L*.68)]
 verts=[(x,y,z) for y in [-.10,-.135] for x,z in pts];n=len(pts)
 faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 mats=[0]*len(faces)
 for zc,r in [(0,.072),(-.1,.038)]:
  base=len(verts)
  for y in [-.14,-.155]:
   for i in range(20):a=math.tau*i/20;verts.append((r*math.cos(a),y,zc+r*math.sin(a)))
  faces+=[tuple(range(base+19,base-1,-1)),tuple(range(base+20,base+40))];mats += [1,1]
  for i in range(20):faces.append((base+i,base+(i+1)%20,base+20+(i+1)%20,base+20+i));mats.append(1)
 mesh=bpy.data.meshes.new(name+'_refined');mesh.from_pydata(verts,[],faces);mesh.materials.append(bpy.data.materials['clock_ink']);mesh.materials.append(bpy.data.materials['clock_brass']);uv=mesh.uv_layers.new(name='UVMap')
 for p,mat in zip(mesh.polygons,mats):p.material_index=mat
 bm=bmesh.new();bm.from_mesh(mesh);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(mesh);bm.free();mesh.update();obj.data=mesh
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'));import house_kit as k
k.M.update({m.name:m for m in bpy.data.materials});p=k.Parts(110329)
k.window(p,(-3.7,0,4.675),1.1,1.65,(-1,0),shutters=None,box=False)
k.window(p,(3.7,-.7,4.675),1.1,1.65,(1,0),shutters=None,box=False)
# Side-facing tower slit reinforces the clock tower as a distinct mass.
with p.into('tower_side_window'):
 k.window(p,(-3.65,-1.6,8.15),.54,1.05,(-1,0),shutters=None,box=False)
with p.into('side_window_finish'):
 for x in [-3.8,3.8]:
  for z in [.7,3.1,5.4]:p.box('iron',(x,-2.55,z),(.15,.27,.055),bevel=.006,uv='flat')
p.finish(bpy.data.objects['haverlund_clockmaker'])
bpy.context.scene['detail_finish']=True;bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(P))
P.with_name('detail-finish.json').write_text(json.dumps({'previous_sha256':before,'record':'art/source/world/haverlund-clockmaker/v2/detail_finish.py','change':'Replace degenerate vertical beam hands with modeled spade hands; fill side openings and add tower slit, pipe brackets.'},indent=2))
