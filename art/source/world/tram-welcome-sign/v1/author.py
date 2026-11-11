"""One-time new source and deliberate adopted gate edit; never a runtime dependency."""
import bpy,bmesh,math,json,shutil,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
SOURCE=Path(__file__).parent/'model.blend'
def material(name,colour,metal=0,emit=0):
 m=bpy.data.materials.new(name);m.diffuse_color=(*colour,1);m.use_nodes=True
 b=m.node_tree.nodes.get('Principled BSDF');b.inputs['Base Color'].default_value=(*colour,1);b.inputs['Roughness'].default_value=.62;b.inputs['Metallic'].default_value=metal
 if emit: b.inputs['Emission Color'].default_value=(*colour,1);b.inputs['Emission Strength'].default_value=emit
 return m

def box(name,loc,size,mat,bevel=.025):
 bpy.ops.mesh.primitive_cube_add(size=1,location=loc);o=bpy.context.object;o.name=name;o.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);o.data.materials.append(mat)
 if bevel:
  m=o.modifiers.new('Soft worked edge','BEVEL');m.width=bevel;m.segments=3
  bpy.ops.object.modifier_apply(modifier=m.name)
 return o

def bolt(name,x,y,z,mat):
 bpy.ops.mesh.primitive_uv_sphere_add(segments=12,ring_count=6,radius=.035,location=(x,y,z));o=bpy.context.object;o.name=name;o.scale=(1,.45,1);o.data.materials.append(mat)

def create_sign():
 if SOURCE.exists(): raise RuntimeError('Source exists; edit its saved master instead of rerunning authoring.')
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 cream=material('Warm cream enamel',(.79,.75,.59));teal=material('Deep teal enamel',(.06,.25,.27));brass=material('Worked brass',(.58,.38,.13),.55);dark=material('Display glass',(.025,.055,.065));wood=material('Oiled walnut',(.23,.12,.055));paint=material('Dried cream paint',(.87,.81,.63))
 for x in [-1.0,1.0]:
  box('Brass foot', (x,0,.06),(.46,.44,.12),brass)
  box('Cast enamel upright',(x,0,1.18),(.14,.18,2.25),teal)
  for z in [.24,1.2]: box('Upright collar',(x,0,z),(.19,.22,.08),brass)
 box('Walnut back',(0,0,2.25),(2.7,.25,1.2),wood,.07)
 box('Enamel surround',(0,-.14,2.25),(2.82,.13,1.26),cream,.08)
 box('Inset brass bezel',(0,-.225,2.25),(2.58,.075,.94),brass,.035)
 box('Display glass',(0,-.27,2.25),(2.42,.045,.78),dark,.025)
 box('Weather hood',(0,-.09,2.91),(3.02,.62,.09),teal,.04)
 box('Hood brass lip',(0,-.405,2.89),(3.06,.045,.075),brass,.012)
 for x in [-1.29,1.29]:
  for z in [1.75,2.75]: bolt('Rivet',x,-.225,z,brass)
 box('Service enclosure',(.77,-.15,1.35),(.52,.28,.3),teal)
 box('Openable brass access',(.77,-.30,1.35),(.46,.04,.25),brass,.02)
 bpy.ops.mesh.primitive_torus_add(major_radius=.066,minor_radius=.016,major_segments=20,minor_segments=6,location=(.78,-.337,1.35),rotation=(math.pi/2,0,0));bpy.context.object.name='Slate socket';bpy.context.object.data.materials.append(brass)
 box('Socket dark core',(.78,-.344,1.35),(.09,.025,.09),dark,.035)
 for x in [-.12,.04,.20]: box('Cooling slots',(x,.145,2.40),(.04,.014,.3),dark,.005)
 # Artist's small tool rest, leaving the approach uncluttered.
 box('Tool rest',(-.9,.24,.45),(.64,.4,.12),wood)
 box('Rolled canvas',(-.86,.25,.57),(.5,.26,.13),teal,.045)
 for x in [-1.01,-.87,-.72]: box('Brass brush ferrule',(x,.27,.72),(.045,.07,.10),brass,.01)
 box('Cream paint dab',(-.95,.12,.655),(.08,.04,.015),paint,.008)
 bpy.ops.object.empty_add(type='PLAIN_AXES',location=(0,-.301,2.25));bpy.context.object.name='SignFace'
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))

def hinge_garden():
 path=ROOT/'art/source/world/haverlund-lane-set/v1/model.blend';backup=path.with_name('model.pre-welcome-quest.blend')
 if backup.exists(): raise RuntimeError('Gate revision exists; inspect master rather than rerunning.')
 shutil.copy2(path,backup);before=hashlib.sha256(path.read_bytes()).hexdigest();bpy.ops.wm.open_mainfile(filepath=str(path))
 bpy.ops.object.empty_add(type='PLAIN_AXES',location=(9.52,24.52,1));root=bpy.context.object;root.name='BraumGardenGate'
 bpy.ops.object.empty_add(type='PLAIN_AXES',location=(9.52,24.52,1));leaf=bpy.context.object;leaf.name='door_leaf_braum';leaf['swing']=-95.0;leaf.parent=root;leaf.matrix_parent_inverse=root.matrix_world.inverted()
 extracted=0
 for obj in list(bpy.context.scene.objects):
  if obj.type!='MESH':continue
  bm=bmesh.new();bm.from_mesh(obj.data);seen=set();selected=[]
  for v in bm.verts:
   if v in seen:continue
   group=[];stack=[v];seen.add(v)
   while stack:
    cur=stack.pop();group.append(cur)
    for edge in cur.link_edges:
     other=edge.other_vert(cur)
     if other not in seen:seen.add(other);stack.append(other)
   coords=[obj.matrix_world@p.co for p in group];lo=Vector([min(p[i] for p in coords) for i in range(3)]);hi=Vector([max(p[i] for p in coords) for i in range(3)]);c=(lo+hi)/2
   if 9.46<c.x<9.68 and 24.50<c.y<25.50 and 1.1<c.z<1.95 and hi.x-lo.x<.18:selected.extend(group)
  if selected:
   keep=set(selected);faces=[f for f in bm.faces if all(v in keep for v in f.verts)];verts=list(keep);index={v:i for i,v in enumerate(verts)}
   mesh=bpy.data.meshes.new('Original garden gate parts');mesh.from_pydata([obj.matrix_world@v.co-leaf.matrix_world.translation for v in verts],[],[[index[v] for v in f.verts] for f in faces])
   for m in obj.data.materials:mesh.materials.append(m)
   for p,f in zip(mesh.polygons,faces):p.material_index=f.material_index
   gate=bpy.data.objects.new('Garden gate original finish',mesh);bpy.context.collection.objects.link(gate);gate.parent=leaf
   # Preserve original UV loop data while splitting these connected parts.
   if bm.loops.layers.uv.active:
    uv=mesh.uv_layers.new(name='UVMap')
    for poly,face in zip(mesh.polygons,faces):
     for loop_i,loop in zip(poly.loop_indices,face.loops):uv.data[loop_i].uv=loop[bm.loops.layers.uv.active].uv
   bmesh.ops.delete(bm,geom=selected,context='VERTS');bm.to_mesh(obj.data);extracted+=len(verts)
  bm.free()
 if extracted<30:raise RuntimeError('No sufficient gate geometry found; original master has not been saved.')
 bpy.context.preferences.filepaths.save_version=0;bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('welcome-gate.json').write_text(json.dumps({'before':before,'after':hashlib.sha256(path.read_bytes()).hexdigest(),'vertices_moved':extracted,'backup':backup.name,'edit_script':str(Path(__file__).relative_to(ROOT))},indent=2)+'\n')
create_sign();hinge_garden()
