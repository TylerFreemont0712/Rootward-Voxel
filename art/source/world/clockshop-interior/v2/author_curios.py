"""Initial bespoke curio collection. Every model is independently reusable and refuses existing sources."""
from pathlib import Path
import sys,math
import bpy
sys.path.insert(0,str(Path(__file__).parent));from curio_kit import *
def plinth():
 root,p,path=begin('clockshop-display-plinth')
 for z,r,h,m in [(.07,.53,.14,'darkwood'),(.20,.45,.16,'walnut'),(.52,.40,.60,'teal'),(.83,.48,.10,'walnut'),(.91,.55,.08,'darkwood')]:
  p.cylinder('clockshop_'+m,(0,0,z-h/2),(0,0,z+h/2),r,12)
 for n in range(8):
  a=math.tau*n/8;rod(p,'brass',(.39*math.cos(a),.39*math.sin(a),.30),(.39*math.cos(a),.39*math.sin(a),.75),.012,8)
 rod(p,'felt',(0,0,.955),(0,0,.97),.47,40);save(root,p,path)
def orrery():
 root,p,path=begin('clockshop-orrery')
 rod(p,'walnut',(0,0,.025),(0,0,.13),.36,32)
 rod(p,'brass',(0,0,.13),(0,0,.20),.30,32)
 rod(p,'brass',(0,0,.17),(0,0,.67),.025,12)
 # Three-dimensional orbital rings use actual tubular segments, tilted on distinct planes.
 for j,r in enumerate([.24,.37,.49]):
  tilt=.20+j*.19
  for n in range(64):
   a=math.tau*n/64;b=math.tau*(n+1)/64
   rod(p,'brass',(r*math.cos(a),r*math.sin(a)*math.cos(tilt),.67+r*math.sin(a)*math.sin(tilt)),(r*math.cos(b),r*math.sin(b)*math.cos(tilt),.67+r*math.sin(b)*math.sin(tilt)),.008,6)
  a=1.3+j*2.1;x=r*math.cos(a);y=r*math.sin(a)*math.cos(tilt);z=.67+r*math.sin(a)*math.sin(tilt)
  rod(p,'brass',(0,0,.56+j*.03),(x,y,z),.011,8)
  p.sphere('clockshop_teal' if j%2 else 'clockshop_steel',(x,y,z),.055+j*.012,2)
 p.sphere('clockshop_brass',(0,0,.68),.10,2)
 for x,r in [(-.13,.10),(.13,.14)]:gear(p,x,-.07,.33,r,18)
 for x in [-.24,.24]:rod(p,'brass',(x,0,.14),(x,0,.42),.017,10)
 box(p,'brass',(0,0,.43),(.55,.12,.035));save(root,p,path)
def watch_cabinet():
 root,p,path=begin('clockshop-watch-cabinet')
 box(p,'darkwood',(0,.10,1.28),(1.75,.34,2.44),.025)
 for x in [-.88,.88]:box(p,'walnut',(x,0,1.27),(.12,.56,2.50),.02)
 for z in [.10,2.46]:box(p,'walnut',(0,0,z),(1.96,.62,.14),.022)
 for z in [.40,1.15,1.90]:
  box(p,'felt',(0,-.08,z+.22),(1.58,.045,.68),.012)
  box(p,'walnut',(0,-.05,z),(1.65,.42,.055))
  for x in [-.51,0,.51]:
   dial(p,x,-.14,z+.28,.135)
   ring(p,x,-.145,z+.45,.038,.010)
   rod(p,'brass',(x,-.10,z+.63),(x,-.10,z+.49),.007,6)
   box(p,'ivory',(x,-.21,z+.02),(.22,.15,.02),.004)
 p.pane('clockshop_clear_glass',(0,-.29,1.28),1.64,2.14,(0,-1))
 for x in [-.82,0,.82]:box(p,'brass',(x,-.30,1.28),(.022,.025,2.15),.003)
 rod(p,'brass',(.72,-.32,1.20),(.72,-.39,1.20),.025,10)
 box(p,'teal',(0,-.322,2.48),(1.45,.018,.14))
 text(p,'POCKET WATCHES',0,-.336,2.48,.105,'ivory');save(root,p,path)
def winder():
 root,p,path=begin('clockshop-spring-winder')
 box(p,'walnut',(0,0,.055),(.72,.52,.11),.03)
 for x in [-.25,.25]:
  box(p,'steel',(x,.03,.29),(.10,.22,.38),.015)
  rod(p,'brass',(x,.02,.20),(x,.02,.45),.055,16)
 rod(p,'steel',(-.38,.03,.43),(.39,.03,.43),.025,14)
 # Helical mainspring and winding arbor, made from a continuous tube path.
 for n in range(100):
  a=math.tau*5*n/100;b=math.tau*5*(n+1)/100
  rod(p,'steel',(-.15+n*.003,.03+.13*math.cos(a),.43+.13*math.sin(a)),(-.15+(n+1)*.003,.03+.13*math.cos(b),.43+.13*math.sin(b)),.009,6)
 gear(p,0,-.16,.43,.17,20)
 rod(p,'brass',(.39,.03,.43),(.39,.03,.65),.022,10)
 rod(p,'walnut',(.39,.03,.65),(.55,.03,.65),.035,16)
 box(p,'brass',(-.20,-.23,.085),(.20,.018,.055));save(root,p,path)
def rack():
 root,p,path=begin('clockshop-pendulum-rack')
 for x in [-.90,.90]:
  box(p,'walnut',(x,0,1.16),(.12,.40,2.32),.02)
  box(p,'darkwood',(x,0,.07),(.38,.76,.14),.02)
 for z in [.24,2.26]:box(p,'walnut',(0,0,z),(1.90,.30,.14),.018)
 for i in range(5):
  x=-.66+i*.33;bottom=.48+(i%3)*.18
  rod(p,'brass',(x,-.02,2.19),(x,-.02,bottom),.014,10)
  rod(p,'brass',(x,.02,bottom),(x,-.08,bottom),.11+(i%2)*.025,28)
  box(p,'ivory',(x,-.17,2.29),(.22,.02,.08),.004)
 for x in [-.62,.62]:box(p,'steel',(x,.15,1.22),(.03,.035,1.95))
 text(p,'REGULATION',0,-.165,.24,.13,'brass');save(root,p,path)
def blueprint():
 root,p,path=begin('clockshop-blueprint-board')
 box(p,'walnut',(0,0,.65),(1.85,.15,1.30),.025)
 box(p,'teal',(0,-.085,.65),(1.66,.025,1.12),.012)
 box(p,'ivory',(-.14,-.108,.64),(1.15,.012,.84),.007)
 for x,y,z,r in [(-.35,-.13,.70,.19),(0,-.13,.53,.14),(.10,-.13,.86,.12)]:
  ring(p,x,y,z,r,.006,'ink',32)
  for n in range(8):
   a=math.tau*n/8;rod(p,'ink',(x+math.sin(a)*r*.80,y,z+math.cos(a)*r*.80),(x+math.sin(a)*r,y,z+math.cos(a)*r),.003,4)
 for z in [.30,.97]:rod(p,'ink',(-.59,-.13,z),(.30,-.13,z),.003,4)
 for x in [-.58,.31]:rod(p,'ink',(x,-.13,.29),(x,-.13,.99),.003,4)
 for z in [.44,.62,.80]:box(p,'ivory',(.62,-.11,z),(.25,.012,.12),.003)
 text(p,'ESCAPEMENT',0,-.14,1.15,.105,'ivory')
 for x in [-.70,.48]:p.sphere('clockshop_brass',(x,-.13,1.01),.018,1)
 save(root,p,path)
def service_shelf():
 root,p,path=begin('clockshop-service-shelf')
 for x in [-1.18,1.18]:box(p,'walnut',(x,.03,.71),(.10,.54,1.42),.015)
 for z in [.18,.70,1.23,1.44]:box(p,'walnut',(0,0,z),(2.52,.62,.10),.018)
 for x in [-.83,0,.83]:
  box(p,'teal',(x,-.03,.44),(.68,.48,.40),.022)
  box(p,'brass',(x,-.282,.46),(.20,.012,.07),.004)
  rod(p,'brass',(x-.06,-.30,.38),(x+.06,-.30,.38),.013,10)
 for x in [-.90,-.45,0,.45,.90]:
  rod(p,'steel',(x,.02,.76),(x,.02,1.03),.105,20)
  rod(p,'brass',(x,.02,1.03),(x,.02,1.07),.115,20)
 text(p,'SPRINGS  /  JEWELS',0,-.326,1.44,.11,'ivory');save(root,p,path)
def oils():
 root,p,path=begin('clockshop-oil-and-tools')
 box(p,'walnut',(0,0,.045),(.70,.44,.09),.02)
 for x,y,r,h in [(-.20,.03,.085,.30),(.03,.07,.065,.36),(.22,.07,.065,.24)]:
  rod(p,'teal',(x,y,.09),(x,y,h),r,20)
  rod(p,'brass',(x,y,h),(x,y,h+.06),r*.7,16)
  box(p,'ivory',(x,y-r-.005,(h+.09)/2),(r*1.3,.008,.10),.003)
 rod(p,'steel',(-.20,-.12,.14),(.21,-.12,.14),.012,8)
 rod(p,'walnut',(.21,-.12,.14),(.32,-.12,.14),.028,12)
 for n in range(7):rod(p,'ivory',(-.25,-.12+n*.008,.14),(-.34,-.12+n*.008,.14),.005,5)
 save(root,p,path)
def ledgers():
 root,p,path=begin('clockshop-ledger-set')
 for x,z,w in [(.23,.07,.37),(.21,.15,.40)]:
  box(p,'leather',(x,.06,z),(w,.51,.11),.012)
  box(p,'ivory',(x,.035,z+.004),(w-.035,.46,.065),.005)
 box(p,'leather',(-.25,-.01,.045),(.48,.57,.08),.015)
 for x,angle in [(-.38,-.08),(-.14,.08)]:
  p.box('clockshop_ivory',(x,-.01,.10),(.23,.50,.035),rot=(0,angle,0),bevel=.006)
  for row in range(7):box(p,'ink',(x,-.20+row*.055,.125),(.15,.005,.003),.001)
 rod(p,'brass',(-.05,-.18,.15),(.19,-.35,.15),.008,8)
 p.solid('clockshop_ivory',[(.18,-.34,.15),(.29,-.29,.22),(.35,-.40,.17)],.006,(0,0,1))
 box(p,'teal',(-.26,.24,.11),(.04,.25,.01),.001);save(root,p,path)
def crates():
 root,p,path=begin('clockshop-clock-crates')
 for z in [.07,.72]:box(p,'darkwood',(0,0,z),(1.20,.82,.12),.012)
 for x in [-.55,.55]:
  for y in [-.35,.35]:box(p,'walnut',(x,y,.42),(.09,.09,.74))
 for n in range(4):
  z=.18+n*.145
  for y in [-.38,.38]:box(p,'walnut',(0,y,z),(1.15,.07,.105),.01)
  for x in [-.58,.58]:box(p,'walnut',(x,0,z),(.07,.76,.105),.01)
 for x in [-.40,.40]:box(p,'steel',(x,-.425,.41),(.045,.012,.65),.003)
 box(p,'ivory',(0,-.43,.45),(.55,.012,.24),.008)
 text(p,'FRAGILE',0,-.441,.48,.09,'ink');text(p,'CLOCKWORK',0,-.441,.37,.055,'ink')
 # Rolled protective felt and a wrapped case break the crate's silhouette.
 box(p,'felt',(-.22,.04,.87),(.40,.58,.26),.04)
 rod(p,'ivory',(.24,-.27,.84),(.24,.27,.84),.13,20)
 save(root,p,path)
def stool():
 root,p,path=begin('clockshop-stool')
 rod(p,'walnut',(0,0,.57),(0,0,.63),.34,32)
 rod(p,'felt',(0,0,.63),(0,0,.70),.32,32)
 for n in range(4):
  a=math.tau*n/4+math.pi/4;x=.22*math.cos(a);y=.22*math.sin(a)
  rod(p,'walnut',(x*1.25,y*1.25,.08),(x,y,.57),.034,12)
  p.sphere('clockshop_walnut',(x*1.1,y*1.1,.34),.05,2)
  rod(p,'brass',(x*1.25,y*1.25,.02),(x*1.25,y*1.25,.10),.035,12)
 for n in range(32):
  a=math.tau*n/32;b=math.tau*(n+1)/32
  rod(p,'brass',(.26*math.cos(a),.26*math.sin(a),.22),(.26*math.cos(b),.26*math.sin(b),.22),.012,8)
 save(root,p,path)
def wall_shelf():
 root,p,path=begin('clockshop-wall-shelf')
 box(p,'walnut',(0,0,.055),(1.95,.50,.11),.022)
 for x in [-.66,.66]:
  box(p,'brass',(x,.16,-.15),(.07,.12,.36),.008)
  p.beam('clockshop_brass',(x,-.18,0),(x,.16,-.30),.05,.05,up=(1,0,0))
 box(p,'brass',(0,-.258,.055),(1.90,.018,.035),.003);save(root,p,path)
def cuckoo():
 root,p,path=begin('clockshop-cuckoo-clock')
 box(p,'walnut',(0,.03,.75),(.66,.25,.80),.025)
 for side in [-1,1]:
  p.beam('clockshop_teal',(0,-.01,1.42),(side*.50,-.01,.99),.13,.42,up=(0,1,0))
  for n in range(3):p.sphere('clockshop_walnut',(side*(.30+n*.055),-.15,.87-n*.12),.075,1,squash=(.65,.55,1.2))
 dial(p,0,-.12,.70,.205)
 rod(p,'ink',(0,-.11,1.12),(0,-.14,1.12),.10,24)
 p.sphere('clockshop_ivory',(0,-.205,1.12),.055,2,squash=(1,1.5,.8))
 p.sphere('clockshop_brass',(.045,-.235,1.14),.02,1)
 for x,z in [(-.17,.14),(.17,.02)]:
  rod(p,'brass',(x,-.02,.37),(x,-.02,z),.007,6)
  for n in range(4):p.sphere('clockshop_darkwood',(x,-.02,z-n*.035),.047,1,squash=(.8,.8,1.2))
 rod(p,'brass',(0,0,.36),(0,0,.05),.01,8)
 rod(p,'walnut',(0,.02,.05),(0,-.05,.05),.065,20);save(root,p,path)
for fn in [plinth,orrery,watch_cabinet,winder,rack,blueprint,service_shelf,oils,ledgers,crates,stool,wall_shelf,cuckoo]:fn()
