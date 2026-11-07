"""Deliberate, guarded edits of the adopted guild hall and Rootwell masters; no regeneration."""
from pathlib import Path
import bpy,bmesh,math,json,shutil,hashlib
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[5]

def open_edit(asset):
 p=ROOT/'art/source/world'/asset/'v1/model.blend'; backup=p.with_name('model.pre-city-cycle.blend')
 if backup.exists():raise RuntimeError('Revision already exists; inspect the saved master.')
 shutil.copy2(p,backup);before=hashlib.sha256(p.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(p));return p,before

def save(p,before,details):
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(p))
 p.with_name('city-cycle-revision.json').write_text(json.dumps({'before':before,'after':hashlib.sha256(p.read_bytes()).hexdigest(),'record':'art/source/world/civic-cycle/v1/revise.py',**details},indent=2)+'\n')

def box(name,loc,size,mat,parent=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 bevel=o.modifiers.new('Worked edge','BEVEL');bevel.width=.014;bevel.segments=2;bpy.ops.object.modifier_apply(modifier=bevel.name)
 if parent:
  world=o.matrix_world.copy();o.parent=parent;o.matrix_world=world
 return o

p,before=open_edit('rootwell-beacon');needle=bpy.data.objects['gauge_needle'];frame=needle.matrix_world.copy();inv=frame.inverted();red=bpy.data.materials.get('rootwell_red');count=0
for o in bpy.context.scene.objects:
 if o.type!='MESH' or red not in list(o.data.materials):continue
 for v in o.data.vertices:
  q=inv@o.matrix_world@v.co
  if .3<math.hypot(q.x,q.z)<.55 and abs(q.y)<.05:
   q=Matrix.Rotation(math.radians(243),4,'Y')@q;v.co=o.matrix_world.inverted()@frame@q;count+=1
if count<20:raise RuntimeError('Existing red gauge band was not found.')
for name,colour,lo,hi in [('rootwell_pressure_green',(0.19,.48,.30,1),0,8),('rootwell_pressure_amber',(.80,.53,.15,1),8,9)]:
 mat=red.copy();mat.name=name;mat.diffuse_color=colour;mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=colour
 verts=[];faces=[]
 for i in range(49):
  a=math.radians(225-27*(lo+(hi-lo)*i/48))
  for r in [.40,.46]:verts.append(frame@Vector((math.cos(a)*r,-.001,math.sin(a)*r)))
 for i in range(48):faces.append((i*2,i*2+2,i*2+3,i*2+1))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.materials.append(mat);o=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(o)
save(p,before,{'red_band_vertices_moved':count,'bands':'green 0–8, amber 8–9, red 9–10; needle remains authored at 1.3 for runtime calibration'})

p,before=open_edit('square-guildhall');removed=0
for o in list(bpy.context.scene.objects):
 if o.type!='MESH':continue
 bm=bmesh.new();bm.from_mesh(o.data);seen=set();delete=[]
 for v in bm.verts:
  if v in seen:continue
  group=[];stack=[v];seen.add(v)
  while stack:
   v=stack.pop();group.append(v)
   for edge in v.link_edges:
    w=edge.other_vert(v)
    if w not in seen:seen.add(w);stack.append(w)
  coords=[o.matrix_world@v.co for v in group];lo=Vector([min(q[j] for q in coords) for j in range(3)]);hi=Vector([max(q[j] for q in coords) for j in range(3)]);c=(lo+hi)/2
  if abs(c.x)<1.05 and -3.95<c.y<-2.0 and .52<c.z<3.15 and hi.x-lo.x<2.2 and hi.z-lo.z<3.5:delete+=group
 if delete:bmesh.ops.delete(bm,geom=delete,context='VERTS');bm.to_mesh(o.data);removed+=len(delete)
 bm.free()
 if not o.data.vertices:bpy.data.objects.remove(o,do_unlink=True)
if removed<200:raise RuntimeError('Doorway counter/old leaves were not found.')
wood=bpy.data.materials['square_oak'];dark=bpy.data.materials['square_wood_dark'];brass=bpy.data.materials['square_brass']
for side in [-1,1]:
 x=side*1.02; bpy.ops.object.empty_add(type='PLAIN_AXES',location=(x,-3.94,.48));hinge=bpy.context.object;hinge.name='door_leaf_city_hall_'+str(side);hinge['swing']=side*100.0;hinge['part']='door_leaf'
 box('Solid oak hall leaf',(side*.51,-3.94,1.79),(1.02,.12,2.62),wood,hinge)
 for z in [1.12,2.33]:
  box('Recessed field',(side*.51,-4.013,z),(.76,.025,.96),dark,hinge)
  box('Raised oak panel',(side*.51,-4.032,z),(.66,.035,.85),wood,hinge)
 for z in [.72,1.8,2.85]:box('Brass hall hinge',(side*.99,-4.035,z),(.065,.05,.22),brass,hinge)
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.055,location=(side*.14,-4.075,1.72));o=bpy.context.object;o.name='Hall brass handle';o.data.materials.append(brass);world=o.matrix_world.copy();o.parent=hinge;o.matrix_world=world
save(p,before,{'doorway_vertices_removed':removed,'door_leaves':'Two hinged panelled oak leaves, common door_leaf/swing extras. Exterior counter removed; public desk moves inside.'})
