"""One-time bespoke concept model. No imported building or shop shell; saved v2 .blend becomes authority."""
from pathlib import Path
import sys,math,json,hashlib
import bpy
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'))
import house_kit as k
TARGET=Path(__file__).with_name('model.blend')
if TARGET.exists():raise RuntimeError('Clockmaker v2 exists. Edit the adopted master instead of rerunning this record.')
PALETTE={'plaster':'seaside_plaster_cream','stone':'seaside_stone_limestone','timber':'seaside_timber_oak','roof':'seaside_roof_teal','shutter':'seaside_shutter_teal'}
root=k.begin('haverlund-clockmaker',PALETTE)
k.material('clock_copper','ffffff',k.DETAIL/'seaside_roof_teal.png',roughness=.65,metallic=.18)
k.material('clock_recess','263432',roughness=.84)
k.material('clock_cream','f1e3b9',roughness=.7)
k.material('clock_brass','b98d43',roughness=.4,metallic=.45)
k.material('clock_ink','292822',roughness=.85)
k.material('clock_fascia','284d4d',roughness=.72)
k.material('clock_glass','729998',roughness=.3)
k.material('clock_lamp_glass','ffd28b',roughness=.4,emission=.5)
p=k.Parts(110326)
F=(0,-1)
# The two-storey main body has actual cut openings; tower and bay silhouettes are independent.
X,Y=3.7,2.35
k.wall(p,'plaster',(-X,-Y),(X,-Y),3.3,6.25,.3,[(2.65,4.15,3.85,5.65),(4.95,6.35,3.85,5.65)])
k.wall(p,'plaster',(X,-Y),(X,Y),.15,6.25,.3,[(1.1,2.2,3.85,5.5)])
k.wall(p,'plaster',(X,Y),(-X,Y),.15,6.25,.3,[(1.3,2.5,3.9,5.55),(4.7,5.65,.25,2.65)])
k.wall(p,'plaster',(-X,Y),(-X,-Y),.15,6.25,.3,[(1.8,2.9,3.85,5.5)])
# Rear/side gables fill the steep copper roof instead of a copied house roof recipe.
k.gable(p,'plaster','x',-X,-Y,Y,6.25,8.05,-1);k.gable(p,'plaster','x',X,-Y,Y,6.25,8.05,1)
# Stone plinth and staggered corner quoins.
for a,b in [((-X,-Y),(X,-Y)),((X,-Y),(X,Y)),((X,Y),(-X,Y)),((-X,Y),(-X,-Y))]:
 if a[1]==-Y and b[1]==-Y:continue
 k.wall(p,'stone',a,b,0,.55,.38)
for x in [-X,X]:
 for y in [-Y,Y]:k.quoins(p,(x,y),[(1 if x>0 else -1,0),(0,1 if y>0 else -1)],.5,6.2,course=.32,long=.4,short=.25)
# Main standing-seam roof: broad slopes, raised seams, folded eaves and ridge.
for side in [-1,1]:
 y0=side*2.72;z0=6.18;y1=0;z1=8.18
 p.solid('clock_copper',[(-4.0,y0,z0),(4.0,y0,z0),(4.0,y1,z1),(-4.0,y1,z1)],.07,(0,side,.9))
 for n in range(15):
  x=-3.92+n*.56;p.cylinder('clock_copper',(x,y0,z0+.04),(x,0,z1+.04),.021,5)
 p.cylinder('clock_copper',(-4.02,y0,z0),(4.02,y0,z0),.075,8)
p.cylinder('clock_copper',(-4.07,0,8.22),(4.07,0,8.22),.09,8)
for x in [-3.85,-1.1,.3,2.0,3.6]:
 p.box('timber',(x,-2.52,6.05),(.17,.3,.26),bevel=.02)
 p.beam('timber',(x,-2.39,5.73),(x,-2.78,6.1),.15,.16)
# Offset tower: 2.1 m wide, projects forward; clock face above the entire pendulum bay.
tx=-2.55;tf=-2.76;tb=-.45;tw=2.15
p.box('stone',(tx,(tf+tb)/2,8.16),(tw,tb-tf,1.93),bevel=.025,uv=('blocks',))
# Narrow side walls around the tall glazed mechanism, and masonry jambs around the recessed entrance.
for x in [tx-tw/2+.16,tx+tw/2-.16]:
 p.box('stone',(x,(tf+tb)/2,4.1),(.32,tb-tf,5.5),bevel=.015,uv=('blocks',))
 for z in [n*.34+.17 for n in range(22)]:p.box('stone',(x,tf-.04,z),(.39,.22,.31),bevel=.012,uv=('blocks',))
for z,w,h in [(0.18,2.35,.36),(3.22,2.45,.22),(3.45,2.25,.13),(7.19,2.4,.18),(9.17,2.48,.19)]:p.box('stone',(tx,tf+.55,z),(w,1.35,h),bevel=.025,uv=('blocks',))
# Arches are actual voussoir rings; no rectangle is used as the visible arched trim.
def arch(cx,y,z,r,mat='stone',thick=.13,start=0,end=math.pi,steps=20):
 for n in range(steps):
  a=start+(end-start)*n/steps;b=start+(end-start)*(n+1)/steps
  pts=[(cx+rr*math.cos(q),y,z+rr*math.sin(q)) for rr,q in [(r,a),(r,b),(r+thick,b),(r+thick,a)]]
  p.solid(mat,pts,.18,(0,-1,0),uv=('blocks',) if mat=='stone' else 'world')
def arched_glass(cx,y,z0,width,height,frame='timber',rim=.07):
 r=width*.5;spring=z0+height-r
 pts=[(cx-r,y,z0),(cx+r,y,z0)]+[(cx+r*math.cos(a),y,spring+r*math.sin(a)) for a in [n*math.pi/20 for n in range(21)]]
 p.solid('clock_recess',pts,.035,(0,-1,0))
 for x in [cx-r,cx+r]:p.box(frame,(x,y-.055,(z0+spring)/2),(rim,.11,spring-z0),bevel=.009)
 arch(cx,y-.06,spring,r,frame,rim)
 p.box(frame,(cx,y-.06,z0),(width+.1,.12,.09),bevel=.01)
 p.box('clock_brass',(cx,y-.09,(z0+spring)/2),(.025,.035,spring-z0),bevel=0)
 return spring
# Entry recess beneath the tower. The leaf is its own hinge, the fanlight and stone arch remain fixed.
spring=arched_glass(tx,tf+.40,.08,1.4,2.9,'stone',.13)
arch(tx,tf-.03,2.24,.74,'stone',.22)
for x in [tx-.88,tx+.88]:p.box('stone',(x,tf+.03,1.13),(.3,.48,2.25),bevel=.02,uv=('blocks',))
p.box('stone',(tx,tf-.12,.055),(1.64,.68,.11),bevel=.025,uv=('blocks',))
# The only runtime door leaf is the recessed left entrance; a fixed glazed central panel completes the display frontage.
hinge=Vector((tx-.65,tf+.34,.07))
with p.into('door_leaf_clockmaker'):
 p.box('timber',(tx,tf+.34,1.17),(1.3,.09,2.2),bevel=.018)
 for x in [tx-.53,tx+.53]:p.box('timber',(x,tf+.275,1.17),(.12,.08,2.12),bevel=.01)
 for z in [.23,.92,2.18]:p.box('timber',(tx,tf+.27,z),(1.15,.08,.12),bevel=.012)
 for x in [tx-.26,tx+.26]:
  p.box('shutter',(x,tf+.28,.56),(.43,.035,.51),bevel=.016)
  p.box('clock_glass',(x,tf+.28,1.55),(.42,.025,1.02),bevel=.01)
 p.box('clock_brass',(tx+.42,tf+.205,1.05),(.06,.025,.23),bevel=.01)
 p.cylinder('clock_brass',(tx+.42,tf+.19,1.13),(tx+.42,tf+.1,1.13),.035,10)
# The tower's long pendulum is visible against a dark recessed arched bay.
arched_glass(tx,tf-.015,3.57,1.48,3.4,'clock_brass',.065)
for x in [tx-.7,tx+.7]:p.box('clock_brass',(x,tf-.12,5.05),(.035,.04,2.7),bevel=0)
with p.into('clock_pendulum'):
 p.cylinder('clock_brass',(tx,tf-.12,6.62),(tx,tf-.12,4.28),.025,8)
 p.cylinder('clock_brass',(tx,tf-.14,4.43),(tx,tf-.22,4.43),.37,40)
 p.cylinder('clock_cream',(tx,tf-.225,4.43),(tx,tf-.235,4.43),.31,40)
 p.cylinder('clock_brass',(tx,tf-.24,4.43),(tx,tf-.25,4.43),.27,40)
for x in [tx-.52,tx+.52]:p.cylinder('clock_brass',(x,tf-.08,4.05),(x,tf-.08,6.5),.018,6)
for x in [tx-.48,tx,tx+.48]:
 p.cylinder('clock_brass',(x,tf-.2,3.68),(x,tf-.23,3.68),.105,16)
 p.beam('clock_brass',(x-.12,tf-.22,3.68),(x+.12,tf-.22,3.68),.02,.02)
# Main dial, minute ticks and Roman numerals; the semantic hand pivots use the shared town clock.
cc=Vector((tx,tf-.13,8.22));r=.84
p.cylinder('clock_brass',cc+Vector((0,.05,0)),cc+Vector((0,-.035,0)),r+.09,64)
p.cylinder('clock_cream',cc+Vector((0,-.04,0)),cc+Vector((0,-.055,0)),r,64)
for n in range(60):
 a=math.tau*n/60;rr=r-.06;tip=cc+Vector((rr*math.sin(a),-.065,rr*math.cos(a)))
 p.beam('clock_ink',tip,tip+Vector((-.07*math.sin(a),0,-.07*math.cos(a))),.012,.018)
for n,roman in enumerate(['XII','I','II','III','IV','V','VI','VII','VIII','IX','X','XI']):
 a=math.tau*n/12
 k.text(p,'clock_ink',roman,k.facing_text(tx+.64*math.sin(a),tf-.205,8.22+.64*math.cos(a),F),.16)
for name,length,width in [('clock_hour_hand',.45,.065),('clock_minute_hand',.65,.042)]:
 with p.into(name):
  p.beam('clock_ink',cc+Vector((0,-.095,-.1)),cc+Vector((0,-.095,length)),width,.035)
  p.sphere('clock_brass',cc+Vector((0,-.115,0)),.075,1,squash=(1,.4,1))
# Bell-shaped copper tower cap, with square rings rather than the previous gabled shop shell.
rings=[(9.29,1.33),(9.4,1.24),(9.58,1.11),(9.87,.93),(10.13,.65),(10.32,.28)]
for (z0,w0),(z1,w1) in zip(rings,rings[1:]):
 for a,b in [((-1,-1),(1,-1)),((1,-1),(1,1)),((1,1),(-1,1)),((-1,1),(-1,-1))]:
  p.solid('clock_copper',[(tx+a[0]*w0,-1.6+a[1]*w0,z0),(tx+b[0]*w0,-1.6+b[1]*w0,z0),(tx+b[0]*w1,-1.6+b[1]*w1,z1),(tx+a[0]*w1,-1.6+a[1]*w1,z1)],.05,(a[0]+b[0],a[1]+b[1],1))
for q in [-1,-.5,0,.5,1]:
 for side in [-1,1]:
  for (z0,w0),(z1,w1) in zip(rings,rings[1:]):p.cylinder('clock_copper',(tx+q*w0,-1.6+side*w0,z0+.015),(tx+q*w1,-1.6+side*w1,z1+.015),.016,5)
p.cylinder('clock_brass',(tx,-1.6,10.3),(tx,-1.6,10.73),.065,12,radius_b=.025)
p.sphere('clock_brass',(tx,-1.6,10.51),.10,2);p.cylinder('clock_brass',(tx,-1.6,10.69),(tx,-1.6,10.95),.07,10,radius_b=0)
# Glazed curved display bays; individual clocks behind the front brass mullions.
def small_clock(cx,y,z,rad,style=0):
 if style%2==0:p.box('timber',(cx,y+.06,z),(.44,.18,.57),bevel=.055)
 else:p.cylinder('clock_brass',(cx,y+.02,z),(cx,y-.035,z),rad+.04,28)
 p.cylinder('clock_cream',(cx,y-.045,z),(cx,y-.055,z),rad,28)
 p.beam('clock_ink',(cx,y-.065,z),(cx+.07,y-.065,z+.10),.018,.014)
 p.beam('clock_ink',(cx,y-.068,z),(cx-.10,y-.068,z+.04),.014,.012)
for cx,width in [(-.42,1.62),(2.58,1.70)]:
 x0=cx-width/2;x1=cx+width/2
 arched_glass(cx,-2.44,.57,width,2.38,'timber',.1)
 for n in range(6):
  a=-math.pi/2+math.pi*n/6;b=-math.pi/2+math.pi*(n+1)/6
  # Faceted curved bay uses a shallow elliptical bow, with full stone riser below.
  xx0=cx+width/2*math.sin(a);xx1=cx+width/2*math.sin(b);yy0=-2.43-.4*math.cos(a);yy1=-2.43-.4*math.cos(b)
  p.solid('stone',[(xx0,yy0,0),(xx1,yy1,0),(xx1,yy1,.55),(xx0,yy0,.55)],.12,(0,-1,0),uv=('blocks',))
  p.beam('timber',(xx0,yy0-.02,.59),(xx1,yy1-.02,.59),.12,.10)
  p.beam('timber',(xx0,yy0-.02,2.72),(xx1,yy1-.02,2.72),.10,.12)
  if n in [0,2,4,6]:p.cylinder('clock_brass',(xx0,yy0-.025,.65),(xx0,yy0-.025,2.68),.026,8)
 for n in range(3):small_clock(cx+(n-1)*.43,-2.68,.94+(n%2)*.28,.17,n)
 for n in range(2):small_clock(cx+(n-.5)*.57,-2.55,1.95+(n%2)*.35,.19,n+1)
 # Reflected highlights suggest glass without adding transparent draw passes.
 for n in [-1,1]:p.beam('clock_glass',(cx+n*.53,-2.79,1.25),(cx+n*.40,-2.79,2.38),.025,.008)
# The narrow glazed center display has its own fanlight and polished handle, fixed while interiors are rebuilt.
arched_glass(1.12,-2.43,.08,1.05,2.92,'timber',.1)
p.box('timber',(1.12,-2.51,.4),(.95,.12,.65),bevel=.02)
for z in [.9,1.5,2.1]:
 p.box('timber',(1.12,-2.48,z),(.85,.11,.06),bevel=.01)
 small_clock(1.12,-2.52,z+.2,.13,1)
# Enamel fascia, gold text, projecting cornice and brass end lanterns.
p.box('timber',(1.0,-2.55,3.17),(5.6,.27,.47),bevel=.025)
p.box('clock_brass',(1,-2.7,3.17),(5.37,.05,.35),bevel=.02)
p.box('clock_fascia',(1,-2.733,3.17),(5.25,.025,.29),bevel=.012)
k.text(p,'clock_brass','PENDULUM & PIN',k.facing_text(1,-2.755,3.165,F),.285)
for x in [-1.48,3.56]:
 p.box('timber',(x,-2.55,1.6),(.20,.25,2.85),bevel=.02)
 p.box('stone',(x,-2.6,.16),(.37,.32,.32),bevel=.02,uv=('blocks',))
 k.lantern(p,(x,-2.91,3.22),F,scale=.75)
# Upper arched windows and spilling flower boxes use the common paintings, unique placement and trim.
for x in [0,2.25]:
 arched_glass(x,-2.38,3.86,1.38,1.86,'timber',.1)
 p.box('timber',(x,-2.48,4.5),(1.35,.1,.055),bevel=.008)
 for d in [-.35,.35]:p.box('clock_glass',(x+d,-2.41,4.55),(.4,.008,1.05),bevel=0)
 p.box('stone',(x,-2.55,3.78),(1.65,.48,.18),bevel=.025,uv=('blocks',))
 for i in range(9):
  xx=x-.65+i*.16;p.sphere('leaf_dark',(xx,-2.65,3.94),.14,1,squash=(1,1,.6))
  p.sphere('flower_white' if i%3 else 'flower_yellow',(xx,-2.68,4.02),.06,1)
# One asymmetric dormer with a curved copper hood and its own finial.
dx=1.1;dy=-.9
p.box('timber',(dx,dy,7.53),(1.25,.8,1.45),bevel=.025)
arched_glass(dx,dy-.43,6.95,.72,1.13,'timber',.09)
profile=[(-.82,7.94),(-.64,8.01),(-.42,8.29),(0,8.55),(.42,8.29),(.64,8.01),(.82,7.94)]
for (x0,z0),(x1,z1) in zip(profile,profile[1:]):
 p.solid('clock_copper',[(dx+x0,dy-.62,z0),(dx+x1,dy-.62,z1),(dx+x1,dy+.62,z1),(dx+x0,dy+.62,z0)],.05,(0,-.2,1))
 p.cylinder('timber',(dx+x0,dy-.65,z0),(dx+x1,dy-.65,z1),.065,8)
p.cylinder('clock_brass',(dx,dy,8.49),(dx,dy,8.91),.05,10,radius_b=.012)
# Tall limestone chimney, paired terracotta pots and rainwater hardware.
k.chimney(p,2.6,.8,6.9,8.75,width=.67,depth=.6,style='stone',pots=2)
for x in [-3.8,3.8]:k.downpipe(p,(x,-2.65,6.15),.15,(0,-1))
# Rear service porch and details are modeled, with no additional unimplemented room interaction.
k.lean_to(p,-.1,2.25,Y,.95,3.15,2.77,1,posts=False,mat='clock_copper')
k.door(p,1.1,Y,1.0,2.4,(0,1),style='panel',leaf_mat='timber',recess=.15)
for cx in [-1.6,2.0]:k.window(p,(cx,Y,4.75),1.05,1.55,(0,1),shutters='none',box=False)
k.barrel(p,(-2.8,2.65,0),radius=.28,height=.68);k.crate(p,(-2.0,2.65,.01),(.65,.46,.4))
for x,y in [(-3.65,-2.85),(3.62,-2.78)]:
 k.pot(p,(x,y,0),scale=.76);k.climber(p,(x,y,.35),1.9,F,spread=.25,density=9)
# Finish into ordinary editable meshes, preserve semantic pivots without material batching them away.
p.finish(root)
for name,center in [('door_leaf_clockmaker',hinge),('clock_hour_hand',cc),('clock_minute_hand',cc),('clock_pendulum',Vector((tx,tf-.12,6.62)))]:
 matches=[o for o in bpy.context.scene.objects if o.name==name or o.name==name+'_glass']
 if not matches:raise RuntimeError('Missing semantic part '+name)
 for obj in matches:
  for v in obj.data.vertices:v.co-=center
  obj.location=center
  obj['part']=name
  if name.startswith('door_leaf'):obj['swing']=-100
# Authoring records, reference and working-space setup; no camera or procedural scene becomes a runtime requirement.
scene=bpy.context.scene;scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['rootward_source']='Original clockmaker concept v2; model.blend is editable authority. No preset building was imported.'
scene['concept_reference']='art/source/world/spindle-strip/v1/clockmaker-concept.png'
for screen in bpy.data.screens:
 for area in screen.areas:
  if area.type=='VIEW_3D':
   area.spaces.active.region_3d.view_location=(0,0,5);area.spaces.active.region_3d.view_distance=18;area.spaces.active.shading.type='MATERIAL'
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(TARGET))
TARGET.with_name('provenance.json').write_text(json.dumps({'asset':'haverlund-clockmaker','version':'v2','reference':scene['concept_reference'],'record':str(Path(__file__).relative_to(ROOT)),'record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'shared_utilities':'art/source/world/seaside-houses/v1/house_kit.py','geometry':'Independently authored tower, bell roof, tall pendulum bay, recessed entry, curved display bays, standing-seam roof and curved dormer. No existing building mesh imported.','retained_previous_source':'art/source/world/haverlund-clockmaker/v1/model.blend','palette':PALETTE},indent=2)+'\n')
print('ORIGINAL CLOCKMAKER SAVED',TARGET)
