"""Initial authoring record for original reusable clockshop models. Refuses saved masters.
After adoption, edit each model.blend and use the normal world-art build.
"""
from pathlib import Path
import sys,math,json,hashlib,random
import bpy
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/seaside-houses/v1'));import house_kit as k
floor=ROOT/'assets/world/textures/clockshop/detail/clockshop_parquet.png'
if not floor.exists():raise RuntimeError('Run scripts/art.sh first.')
def begin(id):
 path=ROOT/'art/source/world'/id/'v1/model.blend'
 if path.exists():raise RuntimeError('Saved editable source exists: '+id)
 bpy.ops.wm.read_factory_settings(use_empty=True);k.M.clear()
 k.material('clockshop_walnut','ffffff',ROOT/'assets/world/textures/seaside-houses/detail/seaside_timber_oak.png',roughness=.62)
 k.material('clockshop_darkwood','38271e',roughness=.68)
 k.material('clockshop_ivory','e2d6b6',roughness=.78)
 k.material('clockshop_brass','b58a42',roughness=.43,metallic=.58)
 k.material('clockshop_steel','59686b',roughness=.4,metallic=.7)
 k.material('clockshop_ink','272b2a',roughness=.85)
 k.material('clockshop_teal','294d4c',roughness=.74)
 k.material('clockshop_wall','d6cbb1',roughness=.93)
 k.material('clockshop_felt','49645a',roughness=.98)
 k.material('clockshop_leather','784b32',roughness=.85)
 k.material('clockshop_floor','ffffff',floor,roughness=.78)
 mat=k.material('clockshop_clear_glass','e6eee5',roughness=.18)
 bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED');bs.inputs['Alpha'].default_value=.10
 mat.surface_render_method='BLENDED'
 k.material('clockshop_lamp_glass','ffe1a0',roughness=.28,emission=.5)
 root=bpy.data.objects.new(id.replace('-','_'),None);bpy.context.scene.collection.objects.link(root)
 return root,k.Parts(110404),path
def finish(root,p,path):
 p.finish(root)
 # Fine mechanical parts use physical rims, not expanded outline hulls.
 for obj in bpy.context.scene.objects:
  if obj.type=='MESH' and any(w in obj.name for w in ['brass','ink','steel','clear_glass']):obj['illustrated_edges']=False
 path.parent.mkdir(parents=True,exist_ok=True);bpy.context.preferences.filepaths.save_version=0
 bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
 path.with_name('provenance.json').write_text(json.dumps({'record':str(Path(__file__).relative_to(ROOT)),'units':'metres','front':'Blender -Y','source_sha256':hashlib.sha256(path.read_bytes()).hexdigest()},indent=2)+'\n')
def box(p,mat,at,size,b=.012):p.box('clockshop_'+mat,at,size,bevel=b)
def rod(p,mat,a,b,r=.015,n=12):p.cylinder('clockshop_'+mat,a,b,r,n)
def ring(p,cx,y,z,r,thick=.018,mat='brass',n=40):
 for i in range(n):
  a=math.tau*i/n;b=math.tau*(i+1)/n
  pts=[(cx+r*math.sin(a),y,z+r*math.cos(a)),(cx+r*math.sin(b),y,z+r*math.cos(b)),(cx+(r+thick)*math.sin(b),y,z+(r+thick)*math.cos(b)),(cx+(r+thick)*math.sin(a),y,z+(r+thick)*math.cos(a))]
  p.solid('clockshop_'+mat,pts,.018,(0,-1,0))
def dial(p,x,y,z,r=.35):
 rod(p,'ivory',(x,y+.018,z),(x,y,z),r,48);ring(p,x,y-.012,z,r,.025)
 ring(p,x,y-.018,z,r*.88,.006,'ink')
 for n in range(12):
  a=math.tau*n/12
  rod(p,'ink',(x+math.sin(a)*r*.70,y-.025,z+math.cos(a)*r*.70),(x+math.sin(a)*r*.82,y-.025,z+math.cos(a)*r*.82),r*.020,6)
 p.beam('clockshop_ink',(x,y-.036,z),(x+r*.38,y-.036,z+r*.42),r*.07,r*.06,up=(0,1,0))
 p.beam('clockshop_ink',(x,y-.039,z),(x-r*.57,y-.039,z+r*.20),r*.05,r*.05,up=(0,1,0))
 rod(p,'brass',(x,y-.04,z),(x,y-.07,z),r*.065,12)
def gear(p,x,y,z,r,teeth=16):
 # Actual open spokes and individual teeth; no textured gear discs.
 ring(p,x,y,z,r*.70,r*.18,'brass',teeth*2)
 for a in [math.tau*i/5 for i in range(5)]:p.beam('clockshop_brass',(x,y,z),(x+math.sin(a)*r*.74,y,z+math.cos(a)*r*.74),r*.11,.035,up=(0,1,0))
 rod(p,'steel',(x,y+.03,z),(x,y-.045,z),r*.14,12)
 for i in range(teeth):
  a=math.tau*i/teeth
  p.box('clockshop_brass',(x+math.sin(a)*r*.92,y,z+math.cos(a)*r*.92),(r*.17,.045,r*.19),rot=(0,a,0),bevel=.003)
def pane(p,x,y,z,w,h):p.pane('clockshop_clear_glass',(x,y,z),w,h,(0,-1))
def drawer(p,x,y,z,w=.46,h=.24):
 box(p,'walnut',(x,y,z),(w,.09,h),.012);box(p,'brass',(x,y-.053,z+.015),(.13,.012,.055),.005)
 rod(p,'brass',(x-.045,y-.075,z-.025),(x+.045,y-.075,z-.025),.012,8)
def feet(p,xs,ys,z=.15):
 for x in xs:
  for y in ys:
   box(p,'walnut',(x,y,z),( .14,.14,z*2),.022)
def mantel(p,x,y,z,r=.20):
 box(p,'walnut',(x,y+.06,z+.29),(r*2.65,.30,.58),.035)
 rod(p,'walnut',(x,y+.21,z+.57),(x,y-.075,z+.57),r*1.33,32)
 box(p,'darkwood',(x,y+.07,z+.04),(r*3.05,.38,.08),.015)
 dial(p,x,y-.095,z+.48,r)
 for sx in [-1,1]:box(p,'brass',(x+sx*r*1.1,y+.06,z+.015),(.08,.25,.04),.008)
def shell():
 root,p,path=begin('clockshop-shell')
 box(p,'darkwood',(5.5,5.5,-.11),(12,12,.22),.012)
 # UV-mapped floor tiles keep the imagegen pattern consistent across the room.
 for x in range(4):
  for y in range(4):
   a=x*3-.5;b=y*3-.5
   p.box('clockshop_floor',(a+1.5,b+1.5,-.0125),(3,3,.025),bevel=0,uv='world',repeat=2.4)
 for x in [-.27,11.27]:box(p,'walnut',(x,5.5,.015),(.30,11.8,.035))
 for y in [-.27,11.27]:box(p,'walnut',(5.5,y,.015),(11.8,.30,.035))
 for x in [-.08,11.08]:box(p,'brass',(x,5.5,.038),(.018,11.15,.012),.001)
 # Cutaway plaster walls with real rear windows and finely panelled wainscot.
 box(p,'wall',(-.56,5.5,2.05),(.24,12.2,4.1),.015)
 for x,w in [(2.0,5.2),(10.55,2.1)]:box(p,'wall',(x,11.56,2.05),(w,.24,4.1),.015)
 box(p,'wall',(7.2,11.56,.76),(5.2,.24,1.52),.015)
 box(p,'wall',(7.2,11.56,3.92),(5.2,.24,.36),.015)
 for x in [5.4,9.0]:
  box(p,'darkwood',(x,11.45,2.62),(.12,.17,2.24))
 box(p,'darkwood',(7.2,11.45,2.62),(.09,.17,2.24))
 pane(p,7.2,11.50,2.63,3.5,2.14)
 for z in [1.48,2.64,3.76]:box(p,'walnut',(7.2,11.40,z),(3.72,.22,.10))
 for z in [.12,1.18,3.98]:
  box(p,'walnut',(5.5,11.36,z),(12,.18,.14))
  box(p,'walnut',(-.36,5.5,z),(.18,12,.14))
 for n in range(12):
  x=n
  box(p,'teal',(x,11.40,.65),(.82,.08,.92))
  box(p,'walnut',(x-.49,11.32,.65),(.07,.16,1.06))
  box(p,'teal',(-.40,x,.65),(.08,.82,.92))
  box(p,'walnut',(-.32,x-.49,.65),(.16,.07,1.06))
 # New single shop door; no reused workshop fitting.
 for x in [5.23,6.77]:box(p,'walnut',(x,-.08,1.45),(.16,.23,2.9),.018)
 box(p,'walnut',(6,-.08,2.87),(1.72,.23,.18),.018)
 with p.into('door_leaf_clockshop'):
  for x in [5.40,6.60]:box(p,'walnut',(x,-.08,1.4),(.12,.12,2.7))
  for z in [.13,.84,2.73]:box(p,'walnut',(6,-.08,z),(1.30,.12,.13))
  box(p,'teal',(6,-.08,.49),(1.16,.10,.58))
  pane(p,6,-.08,1.78,1.10,1.68)
  box(p,'brass',(6.49,-.16,1.17),(.06,.045,.25))
 p.finish(root);hinge=Vector((5.34,-.08,0))
 for obj in bpy.context.scene.objects:
  if obj.name.startswith('door_leaf'):
   for v in obj.data.vertices:v.co-=hinge
   obj.location=hinge;obj['swing']=-95
 finish(root,k.Parts(1),path)
def longcase():
 root,p,path=begin('clockshop-longcase')
 feet(p,[-.32,.32],[-.18,.18],.12)
 for z,size in [(.24,(.98,.60,.18)),(.40,(.84,.52,.14)),(2.20,(.82,.53,.12)),(3.06,(1.0,.64,.15)),(3.19,(.90,.58,.10))]:box(p,'walnut',(0,0,z),size,.025)
 box(p,'darkwood',(0,.12,1.35),(.80,.30,1.8))
 for x in [-.38,.38]:box(p,'walnut',(x,-.10,1.33),(.11,.32,1.72))
 pane(p,0,-.275,1.33,.62,1.62)
 rod(p,'brass',(0,-.10,.65),(0,-.10,1.98),.016,12)
 rod(p,'brass',(0,-.06,.74),(0,-.19,.74),.19,32)
 for x in [-.20,.20]:
  rod(p,'brass',(x,-.10,2.0),(x,-.10,1.22),.008,6)
  rod(p,'brass',(x,-.10,1.20),(x,-.10,1.03),.047,12)
 box(p,'walnut',(0,0,2.62),(.90,.52,.78),.04)
 dial(p,0,-.29,2.64,.32)
 for x in [-.48,.48]:rod(p,'walnut',(x,-.21,2.25),(x,-.21,3.05),.047,16)
 # Bonnet is curved crown joinery with finials rather than a stacked rectangular silhouette.
 rod(p,'walnut',(0,.23,3.03),(0,-.25,3.03),.44,40)
 box(p,'walnut',(0,0,3.04),(.94,.58,.10))
 for x in [-.34,0,.34]:
  rod(p,'brass',(x,0,3.23),(x,0,3.36),.017,10)
  p.sphere('clockshop_brass',(x,0,3.39),.055,2)
 finish(root,p,path)
def regulator():
 root,p,path=begin('clockshop-regulator')
 box(p,'darkwood',(0,.03,1.08),(.68,.18,1.62),.04)
 for z in [.28,1.90]:box(p,'walnut',(0,0,z),(.80,.32,.12),.022)
 for x in [-.32,.32]:box(p,'walnut',(x,-.05,.82),(.075,.25,1.0),.012)
 rod(p,'brass',(0,-.11,.48),(0,-.11,1.22),.012,10)
 rod(p,'brass',(0,-.10,.50),(0,-.16,.50),.14,24)
 pane(p,0,-.20,.80,.55,.91)
 dial(p,0,-.17,1.52,.28)
 box(p,'walnut',(0,0,2.02),(.60,.28,.13),.025)
 finish(root,p,path)
def counter():
 root,p,path=begin('clockshop-display-counter');feet(p,[-1.28,1.28],[-.36,.36],.14)
 box(p,'walnut',(0,0,.48),(2.95,1.0,.72),.025)
 for x in [-.94,0,.94]:
  box(p,'teal',(x,-.516,.53),(.80,.03,.47),.018)
  for dx in [-.43,.43]:box(p,'brass',(x+dx,-.536,.53),(.016,.012,.43),.002)
 box(p,'darkwood',(0,0,.89),(3.10,1.10,.11),.02)
 box(p,'felt',(0,0,.96),(2.90,.90,.035),.005)
 for x in [-1.46,1.46]:
  for y in [-.46,.46]:rod(p,'brass',(x,y,.95),(x,y,1.65),.026,12)
 for y in [-.47,.47]:box(p,'brass',(0,y,1.66),(3.0,.05,.055),.007)
 for x in [-1.47,1.47]:box(p,'brass',(x,0,1.66),(.05,.98,.055),.007)
 pane(p,0,-.485,1.30,2.87,.64);pane(p,0,.485,1.30,2.87,.64)
 p.solid('clockshop_clear_glass',[(-1.42,-.43,1.67),(1.42,-.43,1.67),(1.42,.43,1.67),(-1.42,.43,1.67)],.008,(0,0,1))
 for x in [-.91,0,.91]:mantel(p,x,.16,.99,.14)
 for x in [-.92,-.30,.32,.94]:
  box(p,'ivory',(x,-.26,1.01),(.26,.18,.025),.008)
  rod(p,'brass',(x,-.18,1.01),(x,-.18,1.06),.072,20)
 finish(root,p,path)
def bench():
 root,p,path=begin('clockshop-repair-bench');feet(p,[-1.30,1.30],[-.36,.36],.48)
 box(p,'walnut',(0,0,.99),(3.05,1.10,.15),.035)
 box(p,'darkwood',(0,.35,.41),(2.75,.12,.16))
 for x in [-.99,0,.99]:drawer(p,x,-.44,.78,.88,.27)
 box(p,'felt',(-.36,0,1.08),(1.46,.69,.022),.012)
 # Elevated back rail and a small bank of named-part drawers.
 box(p,'walnut',(.80,.36,1.41),(1.14,.35,.65),.02)
 for x in [.43,.78,1.13]:
  for z in [1.21,1.41,1.61]:drawer(p,x,.14,z,.31,.16)
 # Bench vise, lamp, loupe, laid-out screwdrivers and a half-built escapement.
 box(p,'steel',(-1.21,-.48,1.13),(.22,.28,.13))
 rod(p,'steel',(-1.21,-.38,.91),(-1.21,-.38,1.20),.035,12)
 rod(p,'brass',(-1.40,-.44,1.15),(-1.03,-.44,1.15),.016,10)
 rod(p,'brass',(-1.10,.32,1.08),(-1.10,.32,1.68),.025,12)
 rod(p,'brass',(-1.10,.32,1.68),(-.76,.10,1.84),.022,12)
 p.cylinder('clockshop_brass',(-.76,.10,1.87),(-.76,.10,1.67),.14,24,radius_b=.23)
 rod(p,'ivory',(-.76,.10,1.66),(-.76,.10,1.64),.19,24)
 for i in range(4):
  x=-.71+i*.22
  rod(p,'steel',(x,-.19,1.10),(x,.01,1.10),.009,8)
  rod(p,'leather',(x,.01,1.10),(x,.15,1.10),.023,12)
 # Exposed assembly is upright in a repair stand, with meshing wheels.
 for x,z,r in [(-.30,1.30,.12),(-.05,1.35,.15),(.15,1.22,.10)]:gear(p,x,.27,z,r,14)
 box(p,'steel',(-.10,.28,1.10),(.76,.25,.045),.008)
 box(p,'leather',(.90,-.14,1.11),(.42,.35,.07),.015)
 finish(root,p,path)
def cabinet():
 root,p,path=begin('clockshop-parts-cabinet');feet(p,[-.82,.82],[-.23,.23],.12)
 box(p,'darkwood',(0,.10,1.23),(1.92,.50,2.15),.022)
 for x in [-.71,-.24,.24,.71]:
  for n in range(7):drawer(p,x,-.21,.41+n*.27,.43,.225)
 for x in [-.98,.98]:box(p,'walnut',(x,0,1.24),(.11,.72,2.26),.02)
 for z in [.23,2.32]:box(p,'walnut',(0,0,z),(2.15,.78,.13),.022)
 box(p,'brass',(0,-.41,2.32),(.52,.018,.07),.006)
 finish(root,p,path)
def tray():
 root,p,path=begin('clockshop-clockwork-tray')
 box(p,'walnut',(0,0,.045),(.92,.64,.09),.025)
 box(p,'felt',(0,0,.095),(.82,.54,.022),.008)
 for x in [-.44,.44]:box(p,'walnut',(x,0,.12),(.05,.64,.10))
 for y in [-.29,.29]:box(p,'walnut',(0,y,.12),(.87,.05,.10))
 for x,y,r in [(-.22,-.07,.12),(.12,.08,.15),(.29,-.14,.085)]:
  # Individual loose wheels lie flat in the tray.
  with p.into('loose_wheels'):gear(p,x,0,.0,r,16)
 # Rotate only the loose-wheel group into the tray plane after mesh creation.
 p.finish(root)
 for obj in bpy.context.scene.objects:
  if obj.name.startswith('loose_wheels'):
   obj.rotation_euler.x=math.pi/2;obj.location.z=.17;obj['illustrated_edges']=False
 finish(root,k.Parts(1),path)
def pendant():
 root,p,path=begin('clockshop-brass-pendant')
 rod(p,'brass',(0,0,0),(0,0,-.62),.018,12)
 p.cylinder('clockshop_brass',(0,0,-.62),(0,0,-.78),.10,32,radius_b=.34)
 rod(p,'lamp_glass',(0,0,-.79),(0,0,-.92),.27,32)
 ring(p,0,-.28,-.85,.07,.01)
 rod(p,'brass',(0,0,-.93),(0,0,-.98),.07,16)
 finish(root,p,path)
def mantel_asset():
 root,p,path=begin('clockshop-mantel-clock');mantel(p,0,0,0,.24);finish(root,p,path)
for author in [shell,longcase,regulator,counter,bench,cabinet,tray,pendant,mantel_asset]:author()
