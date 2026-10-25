"""One-time original mesh authoring from the left cottage in voxel-isometric.png.
Refuses existing source. model.blend is the editable master after this handoff.
Blender front=-Y; exporter handles Godot +Z. No prior building meshes reused.
"""
import bpy, math, random, json, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path.cwd();BASE=ROOT/'art/source/world/concept-cottage/v1';SOURCE=BASE/'model.blend'
if SOURCE.exists():raise RuntimeError('Edit the adopted .blend; never regenerate it.')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
rng=random.Random(251025);M={};RECIPES={};PART='Walls'

def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
def material(name,color,texture=None,tint=1,emission=0,metal=0):
 m=bpy.data.materials.new(name);m.use_nodes=True
 bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 rgb=[linear(int(color[i:i+2],16)/255) for i in (0,2,4)]
 bs.inputs['Base Color'].default_value=(*rgb,1);bs.inputs['Roughness'].default_value=.86;bs.inputs['Metallic'].default_value=metal
 if texture:
  image=bpy.data.images.load(str(ROOT/'assets/world/textures/lush'/f'{texture}.png'),check_existing=True)
  n=m.node_tree.nodes.new('ShaderNodeTexImage');n.image=image;n.interpolation='Linear'
  if tint!=1:
   mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(tint,tint,tint,1)
   m.node_tree.links.new(n.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])
  else:m.node_tree.links.new(n.outputs['Color'],bs.inputs['Base Color'])
 if emission:
  bs.inputs['Emission Color'].default_value=(*rgb,1);bs.inputs['Emission Strength'].default_value=emission
 M[name]=m
 return m
material('cottage_oak','b77a3f','cottage_honey_oak',.86)
material('cottage_oak_light','c88c49','cottage_honey_oak',1.02)
material('cottage_timber','634020','cottage_honey_oak',.48)
material('cottage_endgrain','a56b32')
for name,col in [('cottage_stone','c6baa0'),('cottage_stone_light','e0d3b5'),('cottage_stone_warm','b9ac91'),('cottage_mortar','706d5e')]:material(name,col)
for name,tint in [('cottage_roof',.79),('cottage_roof_light',.95),('cottage_roof_dark',.65)]:material(name,'7a61ae','cottage_violet_glaze',tint)
material('cottage_iron','344341',metal=.35);material('cottage_brass','c5913d',metal=.55)
material('cottage_window','ffc969',emission=.38);material('cottage_glass','536272')
material('cottage_recess','211c16');material('cottage_leaf','426939');material('cottage_leaf_light','6b963f')
material('cottage_flower','fff0cb');material('cottage_pollen','edbd4e')

def uv(o,mode='world',tile=2.0):
 d=o.data;d.update();layer=d.uv_layers.active or d.uv_layers.new(name='UVMap')
 for p in d.polygons:
  axis=max(range(3),key=lambda i:abs(p.normal[i]))
  coords=[]
  for li in p.loop_indices:
   v=d.vertices[d.loops[li].vertex_index].co
   coords.append((v.y,v.z) if axis==0 else ((v.x,v.z) if axis==1 else (v.x,v.y)))
  us=[v[0] for v in coords];vs=[v[1] for v in coords]
  for li,(u,v) in zip(p.loop_indices,coords):
   layer.data[li].uv=((u-min(us))/max(max(us)-min(us),.00001),(v-min(vs))/max(max(vs)-min(vs),.00001)) if mode=='face' else (u/tile,v/tile)

def mesh(name,verts,faces,mat):
 d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(M[mat]);d.update()
 o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);o['part']=PART;uv(o);return o

def box(name,at,size,mat,bevel=.018,rotation=None,face=False):
 x,y,z=[v/2 for v in size]
 verts=[(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)]
 o=mesh(name,verts,[(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)],mat);o.location=at
 if rotation:o.rotation_euler=rotation
 if bevel:
  bpy.context.view_layer.objects.active=o
  mod=o.modifiers.new('Small hand-cut arris','BEVEL');mod.width=bevel;mod.segments=1
  bpy.ops.object.modifier_apply(modifier=mod.name)
 uv(o,'face' if face else 'world')
 return o

def beam(name,a,b,w,mat):
 a,b=Vector(a),Vector(b);o=box(name,(a+b)/2,(w,w,(b-a).length),mat)
 o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o

def ring(name,at,outer,inner,depth,mat,n=16,start=0,end=math.tau):
 verts=[]
 for y in [-depth/2,depth/2]:
  for r in [inner,outer]:
   for k in range(n+1):
    a=start+(end-start)*k/n;verts.append((at[0]+r*math.cos(a),at[1]+y,at[2]+r*math.sin(a)))
 h=n+1;faces=[]
 for k in range(n):
  faces.extend([(k,k+1,h+k+1,h+k),(2*h+k,3*h+k,3*h+k+1,2*h+k+1),(k,2*h+k,2*h+k+1,k+1),(h+k,h+k+1,3*h+k+1,3*h+k)])
 faces.extend([(0,h,3*h,2*h),(n,2*h-1,4*h-1,3*h-1)])
 return mesh(name,verts,faces,mat)

# Three staggered courses of individually dressed limestone.
PART='Masonry';w=3.8;d=3.4;front=-1.7
for course in range(2):
 z=.09+course*.17
 for side in [-1,1]:
  for k in range(6):
   x=-1.61+k*.64+(course%2)*.04
   if side<0 and abs(x)<.58:continue
   box('Foundation face block',(x,side*1.68,z),(.62,.27,.16),rng.choice(['cottage_stone','cottage_stone_light','cottage_stone_warm']))
  for k in range(5):
   box('Foundation side block',(side*1.82,-1.33+k*.65,z),(.27,.63,.16),rng.choice(['cottage_stone','cottage_stone_light','cottage_stone_warm']))
# Cavity, floor and opening are real meshes, with no solid block behind the door.
box('Indoor floor',(0,0,.18),(3.5,3.15,.12),'cottage_timber')
box('Dark vestibule back',(0,-.54,1.35),(1.32,.08,2.3),'cottage_recess',0)
PART='Logs'
for course in range(10):
 z=.45+course*.235
 for side in [-1,1]:
  # Wall panels stop at the door opening, including its rounded crown.
  opening=.55 if z<1.89 else (math.sqrt(max(0,.55**2-(z-1.89)**2)) if z<2.44 else 0)
  if side<0 and opening>0:
   for s in [-1,1]:box('Front cut log',(s*(1.88+opening)/2,front,z),(1.88-opening,.24,.217),'cottage_oak_light' if course%3==0 else 'cottage_oak',.025)
  else:box('Full back or upper log',(0,side*1.7,z),(3.86,.24,.217),'cottage_oak',.025)
 for side in [-1,1]:
  o=box('Return log wall',(side*1.82,0,z),(.25,3.44,.217),'cottage_oak_light' if course%4==1 else 'cottage_oak',.025)
  # End grain at every other alternating corner, as in the concept.
  if course%2==0:
   for sy in [-1,1]:box('Notched log end',(side*1.82,sy*1.83,z),(.25,.035,.19),'cottage_endgrain',.022)
# Gables: short courses under the pitch.
eave=2.68;ridge=4.40;half=2.18
for k in range(8):
 z=2.80+k*.19;span=(ridge-z)/(ridge-eave)*half
 if span<.12:continue
 for side in [-1,1]:box('Gable log',(0,side*1.7,z),(span*2,.22,.177),'cottage_oak_light' if k%3==0 else 'cottage_oak',.02)
PART='Timber'
for side in [-1,1]:
 for sy in [-1,1]:
  box('Corner upright',(side*1.74,sy*1.77,1.53),(.18,.18,2.36),'cottage_timber')
 box('Eave beam',(side*1.85,0,2.60),(.21,3.88,.23),'cottage_timber')
 for y in [-1.98,1.98]:beam('Gable oak bargeboard',(0,y,ridge+.025),(side*2.22,y,eave-.055),.16,'cottage_timber')
 for y in [-1.38,.0,1.38]:beam('Eave peg bracket',(side*1.78,y,2.24),(side*2.12,y,2.65),.105,'cottage_oak_light')
# Arched stone entry and hinged seven-board leaf.
PART='Entry';doorwidth=1.08;bottom=.22;spring=1.78;radius=.55
hinge=bpy.data.objects.new('DoorHinge',None);bpy.context.scene.collection.objects.link(hinge);hinge.location=(-.54,-1.85,bottom)
bpy.context.view_layer.update()
leaves=[]
for k in range(7):
 x=-.54+(k+.5)*1.08/7;top=spring+math.sqrt(max(0,radius**2-x*x))
 leaves.append(box('Door oak board',(x,-1.855,(bottom+top)/2),(1.08/7-.009,.10,top-bottom),'cottage_oak_light',.012,face=True))
for x in [-1,1]:
 for k in range(5):box('Door jamb stone',(x*.66,-1.88,.37+k*.275),(.23,.31,.255),'cottage_stone_light' if k%2 else 'cottage_stone',.025)
for k in range(9):
 a=k*math.pi/9+.008;b=(k+1)*math.pi/9-.008
 ring('Arched voussoir',(0,-1.88,spring),.78,.555,.32,'cottage_stone_light' if k%3 else 'cottage_stone_warm',1,a,b)
for z in [.67,1.35]:
 leaves.append(box('Door forged strap',(0,-1.922,z),(.89,.026,.052),'cottage_iron',.005))
 for x in [-.38,.38]:leaves.append(box('Door strap rivet',(x,-1.942,z),(.038,.025,.038),'cottage_brass',.008))
# Small upper blue pane and cross make the leaf read like the reference.
leaves.append(box('Door upper pane',(0,-1.919,1.73),(.47,.016,.57),'cottage_glass',.006))
for z in [1.44,2.015]:leaves.append(box('Door pane frame',(0,-1.937,z),(.55,.045,.055),'cottage_timber',.005))
for x in [-.26,.0,.26]:leaves.append(box('Door pane mullion',(x,-1.94,1.73),(.045,.045,.62),'cottage_oak_light',.005))
leaves.append(ring('Door brass ring',(.31,-1.95,.99),.08,.049,.025,'cottage_brass',12))
for o in leaves:
 matrix=o.matrix_world.copy();o.parent=hinge;o.matrix_world=matrix
for i,(outer,inner,sw,top) in enumerate([[2.55,2.03,1.66,.12],[2.15,1.18,1.46,.235]]):
 box('Entry tread '+str(i),(0,-(outer+inner)/2,top/2),(sw,outer-inner,top),'cottage_stone_light',.025)
# Windows on front and side: recessed frame, warm panes, thick mullions.
def window(x,y,z,angle=0):
 pieces=[]
 for name,at,size,mat in [('Window recess',(0,0,0),(.84,.10,.95),'cottage_recess'),('Amber panes',(0,-.065,0),(.65,.04,.76),'cottage_window')]:
  pieces.append(box(name,at,size,mat,.01))
 for xx in [-.40,.40]:pieces.append(box('Window stile',(xx,-.10,0),(.105,.15,1.03),'cottage_timber',.012))
 for zz in [-.48,.48]:pieces.append(box('Window sill',(0,-.11,zz),(.94,.23,.11),'cottage_oak_light',.015))
 pieces.append(box('Window cross',(0,-.11,0),(.68,.12,.055),'cottage_timber',.005));pieces.append(box('Window mullion',(0,-.11,0),(.05,.12,.82),'cottage_timber',.005))
 from mathutils import Matrix
 rot=Matrix.Rotation(angle,4,'Z')
 for o in pieces:o.location=rot@o.location+Vector((x,y,z));o.rotation_euler.z+=angle
PART='Windows'
window(-1.25,-1.86,1.38);window(1.25,-1.86,1.60)
for x,a in [(1.98,math.pi/2),(-1.98,-math.pi/2)]:
 for y in [-.70,.70]:window(x,y,1.44,a)
# Round cross-barred gable window with stone surround, in front of log courses.
box('Round window recess',(0,-1.845,3.19),(.64,.04,.64),'cottage_recess',.10)
ring('Porthole glass',(0,-1.88,3.19),.285,0,.035,'cottage_glass',20)
ring('Porthole stone ring',(0,-1.91,3.19),.36,.285,.10,'cottage_stone_light',16)
box('Porthole cross',(0,-1.98,3.19),(.59,.045,.045),'cottage_oak_light',.005)
box('Porthole mullion',(0,-1.98,3.19),(.045,.045,.59),'cottage_oak_light',.005)
# The roof is actual staggered overlapping clay tiles, each with a bevel and UVs.
PART='Roof';angle=math.atan2(ridge-eave,half);slope=math.hypot(half,ridge-eave)
for side in [-1,1]:
 box('Dark roof underlay',(side*half/2,0,(ridge+eave)/2-.045),(slope,4.08,.11),'cottage_roof_dark',.015,(0,side*angle,0))
 for row in range(7):
  distance=(row+.5)*slope/7
  x=side*distance*math.cos(angle);z=ridge-distance*math.sin(angle)+.065
  # Half bond is real geometry. Boundary tiles are clipped to the eaves.
  for col in range(11):
   start=-2.04+col*.408-(.204 if row%2 else 0)
   lo=max(-2.04,start);hi=min(2.04,start+.396)
   if hi-lo<.07:continue
   mat=rng.choices(['cottage_roof','cottage_roof_light','cottage_roof_dark'],[7,2,1])[0]
   box('Glazed violet tile',(x,(lo+hi)/2,z),(slope/7+.04,hi-lo,.095),mat,.026,(0,side*angle,0),face=True)
# Discrete, pitched ridge caps.
for j in range(11):
 y=-1.99+j*.395
 for s in [-1,1]:box('Ridge cap',(s*.074,y,ridge+.115),(.21,.38,.08),'cottage_roof_light',.025,(0,s*.30,0),face=True)
# Tall cream block chimney with visible mortar and a hollow cap.
PART='Chimney';cx,cy=-.83,.68
box('Chimney mortar',(cx,cy,4.21),(.61,.58,1.83),'cottage_mortar',.006)
for course in range(7):
 z=3.36+course*.25
 for s in [-1,1]:
  for k in range(2):
   box('Chimney face stone',(cx-.157+k*.315,cy+s*.305,z),(.298,.10,.232),'cottage_stone_light' if (course+k)%3 else 'cottage_stone',.018)
  box('Chimney side stone',(cx+s*.32,cy,z),(.10,.54,.232),'cottage_stone_light',.018)
for x in [-.34,.34]:box('Chimney cap rim',(cx+x,cy,5.085),(.15,.78,.16),'cottage_stone_light',.018)
for y in [-.34,.34]:box('Chimney cap rim',(cx,cy+y,5.085),(.55,.15,.16),'cottage_stone_light',.018)
box('Chimney hollow',(cx,cy,5.04),(.50,.50,.02),'cottage_recess',0)
# The reference's stone flower box, with real low-poly daisy petals.
PART='Planter';px,py=1.26,-2.02
box('Planter masonry',(px,py,.54),(1.00,.48,.42),'cottage_stone',.04)
box('Planter soil',(px,py,.765),(.88,.36,.035),'cottage_recess',.01)
for side in [-1,1]:box('Planter rim',(px,py+side*.23,.77),(1.08,.10,.13),'cottage_stone_light',.015)
for k in range(13):
 x=px+rng.uniform(-.4,.4);y=py+rng.uniform(-.15,.15);z=.81+rng.uniform(0,.15)
 box('Planter leaves',(x,y,z),(.16,.14,.18),rng.choice(['cottage_leaf','cottage_leaf_light']),.025)
 if k%2==0:
  z+=.16
  box('Daisy gold heart',(x,y,z),(.065,.065,.045),'cottage_pollen',.012)
  for a in range(5):
   theta=math.tau*a/5
   box('Daisy ivory petal',(x+.07*math.cos(theta),y+.07*math.sin(theta),z),(.09,.055,.025),'cottage_flower',.012,(0,0,theta))
# Merge static parts by semantic material; keep hinged leaf and hinge untouched.
for part in sorted({o.get('part','') for o in bpy.context.scene.objects if o.type=='MESH' and o.parent!=hinge}):
 for mat in M.values():
  objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.parent!=hinge and o.get('part')==part and o.data.materials and o.data.materials[0]==mat]
  if len(objs)>1:
   bpy.ops.object.select_all(action='DESELECT')
   for o in objs:o.select_set(True)
   bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();bpy.context.object.name=part+'__'+mat.name
bpy.context.scene['source_authority']='Original concept cottage; saved .blend is the editable master.'
bpy.context.scene['reference']='reference/voxel-isometric.png, left log cottage'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
(BASE/'provenance.json').write_text(json.dumps({'asset':'concept-cottage','version':'v1','source_sha256':sha(SOURCE),'authoring_record':'art/source/world/concept-cottage/v1/author.py','reference_sha256':sha(ROOT/'reference/voxel-isometric.png'),'textures':'textures/generation.json','note':'Original geometry authored from scratch. No previous building meshes reused. Subsequent edits use model.blend and scripts/world-art.sh build concept-cottage.'},indent=2)+'\n')
print('ORIGINAL COTTAGE SAVED',SOURCE,flush=True)
