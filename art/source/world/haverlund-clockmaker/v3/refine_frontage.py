"""Second saved-master pass: concept joinery/glazing, supported displays, corrected rear openings and material tone."""
from pathlib import Path
import sys,math,hashlib,random,json
import bpy,bmesh
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).parent));from edit_support import *
path=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path(__file__).with_name('model.blend');bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('clockmaker_refinement_pass')!=1:raise RuntimeError('Requires the saved first refinement pass.')
before=hashlib.sha256(path.read_bytes()).hexdigest();bind_materials();root=bpy.data.objects['haverlund_clockmaker']
# Keep v2 semantic hands/pendulum/entry pivots. Remove only front display/upper-window islands and obsolete pipes.
for o in list(bpy.context.scene.objects):
 if o.type!='MESH' or o.name.startswith(('refined_','clock_hour_hand','clock_minute_hand','clock_pendulum','door_leaf')):continue
 discard_components(o,lambda lo,hi,c:(c.x>-1.65 and c.y<-2.30 and hi.z<3.64) or (-1.0<c.x<3.13 and c.y<-2.25 and lo.z>3.57 and hi.z<5.86) or (abs(c.x)>3.5 and c.y<-3.2) or (o.name=='clock_ink' and -3.5<c.x<-1.6 and c.y<-2.90 and lo.z>7.25 and hi.z<9.15))
# Rear wall: the saved door was behind solid plaster, while the empty opening was on the other side.
o=bpy.data.objects.get('seaside_plaster')
if o:
 bm=bmesh.new();bm.from_mesh(o.data)
 fs=[f for f in bm.faces if 2.035<f.calc_center_median().y<2.365 and .145<f.calc_center_median().z<6.26]
 bmesh.ops.delete(bm,geom=fs,context='FACES');bm.to_mesh(o.data);bm.free();o.data.update()
# Existing native paint in a restrained teal-dominant crop, tinted through the exporter-supported multiply factor.
mat=bpy.data.materials['clock_copper_painted'];nodes=mat.node_tree.nodes;bs=next(n for n in nodes if n.type=='BSDF_PRINCIPLED');tex=next(n for n in nodes if n.type=='TEX_IMAGE')
tex.image=bpy.data.images.load(str(ROOT/'art/source/world/textures/v2-detail/native/copper_patina.png'),check_existing=True)
mix=nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1;mix.inputs[2].default_value=(.66,.85,1,1)
mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);mat.node_tree.links.new(mix.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Metallic'].default_value=.30
for o in bpy.context.scene.objects:
 if o.type!='MESH':continue
 for poly in o.data.polygons:
  if o.data.materials[poly.material_index].name!='clock_copper_painted':continue
  for li in poly.loop_indices:
   co=o.data.vertices[o.data.loops[li].vertex_index].co
   o.data.uv_layers.active.data[li].uv=(.548+(co.x%1.4)/1.4*.16,.285+(co.z%1.8)/1.8*.17)
# Semitransparent exterior panes have geometry behind them; they are not solid blue strips over black rectangles.
glass=k.material('clock_clear_glass','9bc1c6',roughness=.20)
glass_bs=next(n for n in glass.node_tree.nodes if n.type=='BSDF_PRINCIPLED');glass_bs.inputs['Alpha'].default_value=.16
# Blender 5 exports BLENDED materials as glTF alphaMode BLEND. Read the enum rather than assume an identifier.
choices=[v.identifier for v in glass.bl_rna.properties['surface_render_method'].enum_items]
glass.surface_render_method=next(v for v in choices if 'BLEND' in v)
k.material('clock_warm_backing','423b2e',roughness=.9)
k.material('clock_warm_glass','6a786f',roughness=.4)
k.material('clock_watch_gold','b8934e',roughness=.37,metallic=.45)
k.material('clock_bronze_dark','695635',roughness=.5,metallic=.4)
k.material('clock_ivory_dial','ebdfbf',roughness=.7)
p=k.Parts(110304);p.group='refined_frontage'
k.wall(p,'plaster',(3.7,2.35),(-3.7,2.35),.15,6.25,.30,[(1.18,2.22,3.97,5.53),(4.78,5.82,3.97,5.53),(2.10,3.10,.15,2.45)])
# Front upper casements: shallow arched lintels, correctly sized holes, proper cross bars and spilling flower boxes.
for cx,width in [(0,1.50),(2.25,1.40)]:
 z0=3.86;spring=5.42;rise=.24;r=width/2
 arched_face(p,cx,-2.20,z0,width,spring,rise,'clock_warm_backing')
 # Reflective painted panes sit inside the opening, with a clear exterior skin in front of them.
 p.pane('window_pane',(cx,-2.245,4.66),width-.12,1.45,(0,-1))
 arched_face(p,cx,-2.405,z0+.04,width-.05,spring,rise-.025,'clock_clear_glass')
 for x in [cx-r-.035,cx+r+.035]:p.box('timber',(x,-2.40,(z0+spring)/2),(.12,.18,spring-z0+.08),bevel=.018)
 for z in [z0+.04,4.67]:p.box('timber',(cx,-2.42,z),(width,.13,.055),bevel=.008)
 p.box('timber',(cx,-2.425,4.66),(.048,.10,1.52),bevel=.006)
 arch(p,cx,-2.43,spring,width,rise,'timber',.12,.15)
 # Fill the rectangular wall's corners above the segmental arch; no sky gaps behind a false arch.
 for i in range(16):
  a=-r+width*i/16;b=-r+width*(i+1)/16
  za=spring+rise*math.sqrt(max(0,1-(a/r)**2));zb=spring+rise*math.sqrt(max(0,1-(b/r)**2))
  p.solid('plaster',[(cx+a,-2.351,za),(cx+b,-2.351,zb),(cx+b,-2.351,5.67),(cx+a,-2.351,5.67)],.28,(0,-1,0))
 p.box('stone',(cx,-2.53,3.78),(width+.24,.46,.14),bevel=.025,uv=('blocks',))
 p.box('timber',(cx,-2.57,3.83),(width+.05,.34,.18),bevel=.018)
 for i in range(13):
  x=cx+random.Random(i+round(cx*20)).uniform(-r+.03,r-.03);y=-2.63-p.rng.random()*.10;z=3.99+p.rng.uniform(-.07,.11)
  p.sphere('leaf_dark' if i%2 else 'olive',(x,y,z),p.rng.uniform(.10,.16),1,squash=(1.2,.8,.65))
  if i%2==0:
   for j in range(3):p.sphere('flower_white',(x+p.rng.uniform(-.07,.07),y-.03,z+.05+p.rng.uniform(-.02,.04)),.032,1)
 for side in [-1,1]:
  for n in range(4):p.sphere('leaf',(cx+side*(r-.13)+.04*n,-2.68,3.90-.10*n),.075,1,squash=(.8,.6,1))
# Each bowed bay has coherent stone courses, a polished sill, three glazed panels and fine fanlight tracery.
def front_y(cx,width,x):return -2.43-.43*math.sqrt(max(0,1-((x-cx)/(width*.5))**2))
def ring(cx,y,z,r,mat='clock_watch_gold',thick=.025):
 for i in range(36):
  a=math.tau*i/36;b=math.tau*(i+1)/36
  p.solid(mat,[(cx+r*math.cos(a),y,z+r*math.sin(a)),(cx+r*math.cos(b),y,z+r*math.sin(b)),(cx+(r+thick)*math.cos(b),y,z+(r+thick)*math.sin(b)),(cx+(r+thick)*math.cos(a),y,z+(r+thick)*math.sin(a))],.025,(0,-1,0))
def dial(cx,y,z,r,style=0):
 p.cylinder('clock_ivory_dial',(cx,y+.008,z),(cx,y-.008,z),r,32)
 ring(cx,y-.018,z,r,'clock_watch_gold',.024)
 for n in range(12):
  a=math.tau*n/12;p.cylinder('clock_bronze_dark',(cx+math.sin(a)*r*.83,y-.028,z+math.cos(a)*r*.83),(cx+math.sin(a)*r*.69,y-.028,z+math.cos(a)*r*.69),.009,5)
 p.beam('clock_bronze_dark',(cx,y-.038,z),(cx+r*.25,y-.038,z+r*.48),.016,.014,up=(0,1,0))
 p.beam('clock_bronze_dark',(cx,y-.04,z),(cx-r*.62,y-.04,z+r*.17),.012,.012,up=(0,1,0))
 p.cylinder('clock_watch_gold',(cx,y-.04,z),(cx,y-.06,z),.024,10)
def mantel(cx,y,z,r,variant=0):
 # All cases rest on a sill/shelf, with feet below and carved arched or stepped shoulders.
 h=r*2.8
 p.box('timber',(cx,y+.10,z+h*.46),(r*2.5,.19,h*.92),bevel=.035)
 if variant%2:p.cylinder('timber',(cx,y+.14,z+h*.85),(cx,y-.005,z+h*.85),r*1.25,28)
 else:
  p.box('timber',(cx,y+.10,z+h),(r*2.2,.23,.09),bevel=.018)
  p.sphere('clock_watch_gold',(cx,y+.1,z+h+.08),.047,1)
 for x in [-1,1]:p.box('timber',(cx+x*r*.78,y+.08,z+.025),(.07,.18,.06),bevel=.008)
 dial(cx,y-.015,z+h*.58,r)
for cx,width in [(-.42,1.62),(2.58,1.70)]:
 r=width/2
 p.box('clock_warm_backing',(cx,-2.28,1.68),(width,.18,2.35),bevel=.015)
 for row in range(2):
  for n in range(12):
   a=-math.pi/2+math.pi*n/12;b=-math.pi/2+math.pi*(n+1)/12
   x0=cx+r*math.sin(a);x1=cx+r*math.sin(b);y0=-2.43-.43*math.cos(a);y1=-2.43-.43*math.cos(b)
   p.solid('stone',[(x0,y0,row*.26+.05),(x1,y1,row*.26+.05),(x1,y1,row*.26+.30),(x0,y0,row*.26+.30)],.10,(0,-1,0),uv=('blocks',))
 for n in range(12):
  a=-math.pi/2+math.pi*n/12;b=-math.pi/2+math.pi*(n+1)/12
  x0=cx+r*math.sin(a);x1=cx+r*math.sin(b);y0=-2.43-.43*math.cos(a);y1=-2.43-.43*math.cos(b)
  for z,mat,w in [(.08,'stone',.11),(.59,'timber',.11),(.68,'timber',.055),(2.65,'timber',.08),(2.91,'timber',.12)]:p.beam(mat,(x0,y0,z),(x1,y1,z),.12,w)
  if n in [0,4,8]:p.cylinder('clock_watch_gold',(x0,y0-.015,.71),(x0,y0-.015,2.87),.022,8)
  p.solid('clock_clear_glass',[(x0,y0-.025,.71),(x1,y1-.025,.71),(x1,y1-.025,2.88),(x0,y0-.025,2.88)],.008,(0,-1,0))
 # Crossed curved fanlight braces, same arc as the bay's top rail.
 for offset in [-.42,.42]:
  x=cx+offset;y=front_y(cx,width,x)-.032
  arch(p,x,y,2.57,.69,.30,'clock_watch_gold',.025,.035,16)
 # A small verdigris riser inset matches the concept's basement panels.
 p.box('timber',(cx,-2.873,.31),(.70,.065,.28),bevel=.018)
 p.box('clock_fascia',(cx,-2.911,.31),(.59,.014,.18),bevel=.014)
 # Three lower mantel cases sit on the sill; upper pocket watches hang from explicit hooks/chains.
 for n,offset in enumerate([-.49,0,.49]):
  x=cx+offset;y=front_y(cx,width,x)+.13
  mantel(x,y,.72,.14 if n!=1 else .20,n)
 for n,offset in enumerate([-.40,.37]):
  x=cx+offset;y=front_y(cx,width,x)+.11;z=1.93+(n%2)*.25
  p.cylinder('clock_watch_gold',(x,y,2.73),(x,y,z+.17),.009,6)
  ring(x,y,z+.185,.045,'clock_watch_gold',.014)
  dial(x,y,z,.16)
 # Warm wooden shelf grounds the display rather than placing discs directly on the window.
 p.box('timber',(cx,-2.51,.72),(width-.10,.43,.055),bevel=.012)
# Central glazed secondary door: panelled oak and fanlight, rather than a column of floating clocks.
cx=1.12
p.box('clock_warm_backing',(cx,-2.27,1.5),(1.03,.12,2.85),bevel=.015)
for x in [cx-.54,cx+.54]:p.box('timber',(x,-2.49,1.46),(.13,.26,2.88),bevel=.02)
for z in [.14,.82,2.49]:p.box('timber',(cx,-2.45,z),(1.00,.13,.12),bevel=.013)
for x in [cx-.24,cx+.24]:
 p.box('timber',(x,-2.44,.47),(.39,.10,.53),bevel=.018)
 p.box('clock_fascia',(x,-2.497,.47),(.29,.018,.38),bevel=.012)
p.pane('window_pane',(cx,-2.37,1.62),.88,1.52,(0,-1));p.pane('clock_clear_glass',(cx,-2.46,1.62),.88,1.52,(0,-1))
p.box('timber',(cx,-2.49,1.64),(.045,.09,1.63),bevel=.007)
arch(p,cx,-2.51,2.49,1.00,.32,'timber',.095,.14)
p.box('clock_watch_gold',(cx+.37,-2.53,1.04),(.045,.025,.20),bevel=.008)
p.sphere('clock_watch_gold',(cx+.37,-2.56,1.1),.035,2)
p.box('stone',(cx,-2.65,.045),(1.18,.58,.09),bevel=.022,uv=('blocks',))
# Deeper fascia and stepped cornices, serif gold lettering, pilasters, capitals and lantern arms.
for z,w,d,h,mat in [(3.00,5.40,.24,.10,'timber'),(3.27,5.50,.25,.45,'timber'),(3.53,5.74,.38,.12,'timber'),(3.63,5.90,.43,.08,'timber')]:p.box(mat,(1,-2.53,z),(w,d,h),bevel=.022)
p.box('clock_watch_gold',(1,-2.678,3.27),(5.28,.025,.32),bevel=.013)
p.box('clock_fascia',(1,-2.699,3.27),(5.17,.018,.25),bevel=.01)
# Mesh lettering is packed into the blend; no font is required at runtime.
font=Path('/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf')
def serif(words,cx,y,z,size,mat,maxwidth=None):
 curve=bpy.data.curves.new('clock_serif','FONT');curve.body=words;curve.align_x='CENTER';curve.align_y='CENTER';curve.size=size
 if font.exists():curve.font=bpy.data.fonts.load(str(font),check_existing=True)
 obj=bpy.data.objects.new('clock_serif',curve);bpy.context.scene.collection.objects.link(obj);bpy.context.view_layer.update()
 if maxwidth and obj.dimensions.x>maxwidth:curve.size*=maxwidth/obj.dimensions.x;bpy.context.view_layer.update()
 mesh=bpy.data.meshes.new_from_object(obj.evaluated_get(bpy.context.evaluated_depsgraph_get()));M=k.facing_text(cx,y,z,(0,-1));p.add(mat,[M@v.co for v in mesh.vertices],[tuple(f.vertices) for f in mesh.polygons],[[(0,0)]*len(f.vertices) for f in mesh.polygons])
 bpy.data.objects.remove(obj,do_unlink=True);bpy.data.curves.remove(curve);bpy.data.meshes.remove(mesh)
serif('PENDULUM & PIN',1,-2.715,3.27,.295,'clock_watch_gold',4.85)
for x in [-1.48,3.56]:
 p.box('timber',(x,-2.47,1.67),(.21,.24,2.75),bevel=.025)
 for z,w,h in [(.19,.40,.32),(.41,.29,.10),(2.87,.35,.10),(2.97,.42,.10)]:p.box('timber',(x,-2.49,z),(w,.29,h),bevel=.018)
 p.beam('clock_bronze_dark',(x,-2.44,3.52),(x,-2.91,3.52),.05,.05)
 k.lantern(p,(x,-2.83,3.42),(0,-1),scale=.92)
# Better chapter ring and visible Roman numerals; preserve working hour/minute pivots and their stable names.
tx=-2.55;tf=-2.76
ring(tx,tf-.208,8.22,.85,'clock_watch_gold',.033);ring(tx,tf-.209,8.22,.79,'clock_bronze_dark',.009)
for n in range(60):
 a=math.tau*n/60
 p.cylinder('clock_bronze_dark',(tx+.78*math.sin(a),tf-.215,8.22+.78*math.cos(a)),(tx+(.72 if n%5 else .69)*math.sin(a),tf-.215,8.22+(.72 if n%5 else .69)*math.cos(a)),.006 if n%5 else .010,5)
for n,roman in enumerate(['XII','I','II','III','IV','V','VI','VII','VIII','IX','X','XI']):
 a=math.tau*n/12;serif(roman,tx+.60*math.sin(a),tf-.221,8.22+.60*math.cos(a),.175,'clock_bronze_dark')
for name in ['clock_hour_hand','clock_minute_hand']:
 o=bpy.data.objects[name]
 for i,m in enumerate(o.data.materials):
  if m.name=='clock_ink':o.data.materials[i]=bpy.data.materials['clock_bronze_dark']
# Tower glass, an escapement frame and supported weights replace a bare disc on a pole.
with p.into('refined_mechanism'):
 arched_face(p,tx,tf-.275,3.61,1.42,6.23,.70,'clock_clear_glass')
 for x in [tx-.61,tx+.61]:p.cylinder('clock_watch_gold',(x,tf-.17,3.77),(x,tf-.17,6.25),.018,6)
 for z in [3.76,6.26]:p.box('clock_watch_gold',(tx,tf-.17,z),(1.26,.05,.045),bevel=.005)
 for x in [tx-.45,tx+.45]:
  p.cylinder('clock_watch_gold',(x,tf-.13,6.34),(x,tf-.13,4.82),.009,6)
  p.cylinder('clock_watch_gold',(x,tf-.13,4.82),(x,tf-.13,4.56),.055,12)
 ring(tx,tf-.19,6.49,.15,'clock_watch_gold',.028)
 for n in range(12):
  a=math.tau*n/12;x=tx+.18*math.sin(a);z=6.49+.18*math.cos(a)
  p.box('clock_watch_gold',(x,tf-.18,z),(.04,.04,.06),rot=(0,a,0),bevel=.004)
 p.box('clock_watch_gold',(tx,tf-.17,6.70),(.50,.10,.09),bevel=.014)
# Porch pendant and supported greenery soften the entry without blocking it.
with p.into('refined_entry_lantern'):
 p.cylinder('clock_bronze_dark',(tx,tf+.05,2.87),(tx,tf+.05,2.66),.015,8)
 k.lantern(p,(tx,tf+.04,2.57),(0,-1),scale=.57)
for x,y in [(3.62,-2.71),(-3.68,-2.79)]:
 k.pot(p,(x,y,0),scale=.67);k.climber(p,(x,y,.28),1.45,(0,-1),spread=.20,density=13,flowers=('flower_white',))
finish(p,root)
# Rebuild only the existing working leaf around its unchanged hinge; cut-out glazing replaces the solid backing.
for name in ['door_leaf_clockmaker','door_leaf_clockmaker_glass']:
 obj=bpy.data.objects[name];bpy.data.objects.remove(obj,do_unlink=True)
p=k.Parts(110305);hinge=Vector((-3.2,-2.42,.07));cx=-2.55;y=-2.42
with p.into('door_leaf_clockmaker'):
 for x in [cx-.57,cx+.57]:p.box('timber',(x,y,1.15),(.15,.10,2.16),bevel=.015)
 for z in [.16,.83,2.18]:p.box('timber',(cx,y-.01,z),(1.20,.11,.13),bevel=.015)
 for x in [cx-.26,cx+.26]:
  p.box('timber',(x,y-.005,.48),(.42,.10,.50),bevel=.022)
  p.box('clock_fascia',(x,y-.066,.48),(.32,.02,.36),bevel=.014)
 p.box('timber',(cx,y-.01,1.50),(.048,.10,1.26),bevel=.006)
 p.pane('clock_clear_glass',(cx,y,1.50),1.02,1.22,(0,-1))
 p.box('clock_watch_gold',(cx+.41,y-.07,1.06),(.052,.035,.24),bevel=.01)
 p.cylinder('clock_watch_gold',(cx+.41,y-.07,1.13),(cx+.41,y-.15,1.13),.036,12)
 for z in [.35,1.85]:p.box('clock_bronze_dark',(cx-.60,y-.07,z),(.11,.045,.17),bevel=.01)
finish(p,root)
for name in ['door_leaf_clockmaker','door_leaf_clockmaker_glass']:
 obj=bpy.data.objects[name]
 for v in obj.data.vertices:v.co-=hinge
 obj.location=hinge;obj['part']='door_leaf_clockmaker';obj['swing']=-100
# Do not retain unused material slots and orphan zero-face meshes from bounded source edits.
for obj in list(bpy.context.scene.objects):
 if obj.type!='MESH':continue
 if not obj.data.polygons:bpy.data.objects.remove(obj,do_unlink=True);continue
 used=sorted({p.material_index for p in obj.data.polygons});old=list(obj.data.materials);mapping={i:j for j,i in enumerate(used)}
 indices=[mapping[f.material_index] for f in obj.data.polygons]
 obj.data.materials.clear()
 for i in used:obj.data.materials.append(old[i])
 for f,index in zip(obj.data.polygons,indices):f.material_index=index
bpy.context.scene['clockmaker_refinement_pass']=2
save_record(path,'refine_frontage',before)
print('PASS 2 SAVED')
