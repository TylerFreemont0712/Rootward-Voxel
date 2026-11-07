"""One-time lobby and service desks. Existing masters are refused; future edits use saved .blend sources."""
from pathlib import Path
import sys,math,random
import bpy
ROOT=Path(__file__).resolve().parents[5]
sys.path.insert(0,str(ROOT/'art/source/world/sparks-square/v2'))
import square_kit as s
k,h=s.k,s.h

def begin(asset):
 if (ROOT/'art/source/world'/asset/'v1/model.blend').exists():raise RuntimeError('Adopted master exists: '+asset)
 s.begin(asset)

def finish(asset):s.save(asset,'../../civic-cycle/v1/author_lobby.py')

def shell():
 asset='city-hall-shell';begin(asset);b=k.Batch(random.Random(1102))
 # Warm polished oak in a stone border, board seams visible without a noisy checker pattern.
 b.box('limestone_shade',(13.5,10.5,-.18),(28.3,22.3,.32),.025)
 for row in range(43):
  y=-.25+row*.5
  for column in range(7):
   x=-.2+column*4+(2 if row%2 else 0);left=max(-.45,x);right=min(27.45,x+3.98)
   if right>left:b.box('oak' if (row+column)%3 else 'wood',((left+right)/2,y,-.018),(right-left,.485,.065),.008)
 for x in [-.55,27.55]:b.box('limestone_pale',(x,10.5,.01),(.18,22.3,.12),.02)
 for y in [-.55,21.55]:b.box('limestone_pale',(13.5,y,.01),(28.3,.18,.12),.02)
 # Cutaway west and north walls, generous light above head height.
 k.wall('North hall wall','ashlar',(-.5,21.5),(27.5,21.5),0,5.1,.3,[(2.3,4.1,2,4.4),(8.0,9.8,2,4.4),(17.7,19.5,2,4.4),(23.4,25.2,2,4.4)])
 k.wall('West hall wall','ashlar',(-.5,-.5),(-.5,21.5),0,5.1,.3,[(3.0,4.7,2.0,4.4),(9.1,10.8,2,4.4),(15.1,16.8,2,4.4)])
 for x in [2.7,8.4,18.1,23.8]:k.window(b,(x,21.32,3.2),1.8,2.4,(0,-1),shutters=False,box=False,glass='window_shop',bars=(1,3),name='Hall high window')
 for y in [3.35,9.45,15.45]:k.window(b,(-.32,y,3.2),1.7,2.4,(1,0),shutters=False,box=False,glass='window_shop',bars=(1,3),name='Hall side window')
 for y in [.10,1.25,4.98]:
  b.box('oak',(-.30,10.5,y),(.13,22.1,.16),.015);b.box('oak',(13.5,21.27,y),(28.0,.15,.16),.015)
 for x in [0,6.5,13.5,20.5,27.0]:
  b.box('limestone_pale',(x,21.21,2.55),(.34,.2,5.1),.025)
  b.box('oak',(x,21.1,1.9),(.42,.28,.11),.018)
 for y in [0,6.7,13.4,20.8]:b.box('limestone_pale',(-.21,y,2.55),(.25,.34,5.1),.025)
 # Low east partition frames the archive, leaving the audience-facing cutaway open.
 b.box('oak',(23.5,17.8,.65),(.16,6.8,1.3),.018)
 for y in [14.4,21.2]:b.box('brass',(23.5,y,.68),(.24,.24,1.36),.025)
 # Central inlaid runner ties door, hall and service counters together.
 b.box('teal',(13.5,9.8,.023),(3.3,18.2,.025),.008)
 for x in [11.90,15.10]:b.box('gold',(x,9.8,.04),(.055,18.15,.015),.002)
 for y in [2.3,17.3]:
  for dx in [-.7,0,.7]:b.box('gold',(13.5+dx,y,.042),(.20,.20,.015),.003,(0,0,math.pi/4))
 k.lettering('Civic wall lettering','HAVERLUND', (13.5,21.07,4.3),.42,'brass',(math.pi/2,0,0))
 k.lettering('Civic wall motto','PUBLIC WORKS  /  ENQUIRIES', (13.5,21.04,3.7),.16,'ink',(math.pi/2,0,0))
 b.finish();finish(asset)

def desk(asset,label,width):
 begin(asset);b=k.Batch(random.Random(1103));b.box('oak',(0,0,.57),(width,.95,1.14),.025)
 b.box('wood_dark',(0,-.493,.56),(width-.15,.04,.94),.012)
 for x in [-width*.35,0,width*.35]:
  b.box('oak',(x,-.526,.57),(width*.26,.05,.76),.018)
  b.box('wood_dark',(x,-.557,.57),(width*.21,.02,.62),.012)
 b.box('limestone_pale',(0,-.01,1.17),(width+.16,1.15,.14),.035)
 b.box('brass',(0,-.60,1.13),(width+.16,.025,.045),.004)
 b.box('teal',(0,-.57,.84),(1.70,.035,.29),.014)
 k.lettering('Desk name',label,(0,-.598,.84),.16,'enamel_cream',(math.pi/2,0,0))
 for index in range(5):b.box('pages',(-width*.27,.1,1.28+index*.023),(.62,.42,.02),.002,(0,0,(index%2-.5)*.09))
 b.box('red',(-width*.27,.1,1.415),(.65,.44,.03),.004)
 b.box('paper',(.15,.10,1.25),(.6,.45,.025),.003,(0,0,.12))
 for i in range(6):b.box('ink',(.13,.01+i*.04,1.265),(.36,.006,.003),0)
 b.cylinder('brass',(width*.32,-.24,1.25),(width*.32,-.24,1.29),.12,16)
 b.sphere('brass',(width*.32,-.24,1.32),.08,1)
 b.cylinder('ink',(.75,.22,1.25),(.75,.22,1.45),.065,12)
 for i in range(3):b.cylinder('wood',(.73+i*.025,.22,1.40),(.72+i*.025,.22,1.68),.012,6)
 b.finish();finish(asset)

chosen = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['city-hall-shell','city-hall-help-desk','city-hall-job-desk']
if 'city-hall-shell' in chosen: shell()
if 'city-hall-help-desk' in chosen: desk('city-hall-help-desk','ENQUIRIES',5.4)
if 'city-hall-job-desk' in chosen: desk('city-hall-job-desk','PUBLIC WORKS',4.6)
