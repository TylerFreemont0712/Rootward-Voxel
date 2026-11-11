"""One-time guarded authoring of T7b workshop assets. Never overwrites a master.
After adoption open model.blend for deliberate edits; export with world-art.sh.
"""
from pathlib import Path
import bpy
import math
import json
import random
import hashlib
import importlib.util
from mathutils import Vector

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
LOFT=HERE.parents[1]/'sparks-loft/v1'
spec=importlib.util.spec_from_file_location('furniture_helpers',LOFT/'author.py')
h=importlib.util.module_from_spec(spec);spec.loader.exec_module(h)
RNG=random.Random(2710)
M=h.M
B=h.box
S=h.sphere
C=h.cylinder
R=h.rod
T=h.torus
Q=h.curve


def start(asset):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version=0
    M.clear()
    for name,color in {'wood':'a07950','wood_dark':'715038','wood_edge':'bd9567','ink':'503d30',
        'cream':'e8dfca','linen':'e5ddc8','linen_shade':'bcb29a','teal':'457d76','teal_dark':'355f5b',
        'teal_light':'84aaa0','blue':'687d8a','blue_light':'98a8a8','plum':'866875','red':'a8654d',
        'ochre':'b39b61','paper':'f4e8cc','pages':'cbbc98','leather':'8f533d','leather_dark':'674633',
        'leaf':'507b47','leaf_light':'7e9d5e','leaf_dark':'345c3d','soil':'594a3b','ceramic':'b6ad91',
        'rubber':'3c4140','steel':'58636a','steel_light':'89908c','steel_dark':'343e44','white':'f4ead8',
        'plaster':'e2d4ba','cork':'b08a59','upholstery':'a95d49','upholstery_light':'c47b60',
        'charcoal':'393a38','glass':'b4b89d'}.items():h.material(name,color)
    h.material('oak','ffffff',str(LOFT/'honey-oak-v2'))
    h.material('bench','ffffff',str(HERE/'workbench-oak'))
    h.material('plaid','ffffff',str(HERE/'wool-plaid'))
    h.material('plaster_paint','ffffff',str(LOFT/'cream-plaster'))
    h.material('harbour','ffffff',str(LOFT/'harbour-view'),.25)
    h.material('brass','c29b59',metallic=.28)
    h.material('lamp_glass','ffe4ad',emission=.7)
    h.material('ember','f4ac53',emission=.85)
    for name,mat in M.items():mat.name='workshop_'+name
    h.PARENT=bpy.data.objects.new(asset.replace('-','_'),None)
    bpy.context.scene.collection.objects.link(h.PARENT)


def wood(name,at,size,mat='oak',bevel=.025):
    o=B(name,at,size,mat,bevel)
    if mat=='bench':h.wood_uv(o)
    return o


def fabric(name,rows,width,mat='linen',nx=24):
    verts=[];faces=[]
    for j,(y,z) in enumerate(rows):
        for i in range(nx+1):
            u=i/nx*2-1
            verts.append((u*width/2,y+.012*math.sin(u*9+j*.5),
                z+.016*math.sin(u*13+j*.7)+(.015*math.sin(u*6) if j==len(rows)-1 else 0)))
    for j in range(len(rows)-1):
        for i in range(nx):
            a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
    mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
    o=bpy.data.objects.new(name,mesh);bpy.context.scene.collection.objects.link(o);h.put(o,mat,True)
    uv=mesh.uv_layers.new(name='Whole woven cloth')
    for p in mesh.polygons:
        for li in p.loop_indices:
            n=mesh.loops[li].vertex_index;uv.data[li].uv=(n%(nx+1)/nx,n//(nx+1)/(len(rows)-1))
    sol=o.modifiers.new('Cloth edge thickness','SOLIDIFY');sol.thickness=.012
    bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=sol.name)
    return o


def gear(at,r=.14,teeth=12):
    T('Machined gear rim',at,r,.025,'brass')
    C('Gear hub',at,r*.36,.035,'brass')
    for k in range(teeth):
        a=k*math.tau/teeth
        o=B('Gear tooth',(at[0]+math.cos(a)*r,at[1]+math.sin(a)*r,at[2]),(.048,.048,.035),'brass',.008)
        o.rotation_euler.z=a


def wrench(at,length=.47,angle=0):
    root=Vector(at)
    def pt(x,y,z=0):return root+Vector((x,y,z)).xy.to_3d() if False else Vector((root.x+x*math.cos(angle)-y*math.sin(angle),root.y+x*math.sin(angle)+y*math.cos(angle),root.z+z))
    R('Spanner steel handle',pt(0,0),pt(0,length-.12),.027,'steel_light',10)
    T('Spanner ring end',pt(0,0),.057,.018,'steel')
    Q('Open spanner jaw',[pt(-.058,length),pt(-.07,length-.065),pt(0,length-.12),pt(.07,length-.065),pt(.058,length)],.023,'steel_light')


def vice(at=(0,0,0)):
    x,y,z=at
    B('Vice mounting foot',(x,y+.05,z+.045),(.47,.38,.09),'steel_dark',.025)
    B('Fixed vice anvil',(x,y+.05,z+.20),(.39,.21,.28),'teal_dark',.025)
    B('Fixed jaw steel face',(x,y-.07,z+.31),(.44,.055,.10),'steel_light',.008)
    B('Sliding vice jaw',(x,y-.29,z+.22),(.42,.14,.22),'teal',.03)
    B('Sliding jaw steel face',(x,y-.22,z+.31),(.44,.04,.10),'steel_light',.008)
    R('Vice threaded screw',(x,y+.20,z+.15),(x,y-.55,z+.15),.045,'steel')
    for k in range(9):T('Screw thread',(x,y-.17-k*.035,z+.15),.047,.007,'steel_dark',(math.pi/2,0,0))
    R('Vice handle',(x-.20,y-.56,z+.15),(x+.20,y-.56,z+.15),.019,'steel_light')
    for xx in (-.21,.21):S('Vice handle cap',(x+xx,y-.56,z+.15),(.035,.035,.035),'steel')


def tool_cup(at,scale=1):
    x,y,z=at
    C('Tin brush pot',(x,y,z+.13*scale),.10*scale,.26*scale,'steel')
    T('Tin rolled rim',(x,y,z+.26*scale),.10*scale,.009*scale,'steel_light')
    for n in range(6):
        dx=(n-2.5)*.025*scale
        a=(x+dx,y,z+.17*scale);b=(x+dx+(n-2.5)*.018*scale,y+.025*((n%2)*2-1),z+(.48+.035*(n%3))*scale)
        R('Brush wooden shaft',a,b,.011*scale,'wood_dark')
        R('Brush pale bristles',b,(b[0],b[1],b[2]+.07*scale),.022*scale,'linen_shade')


def parts_tray(at,size=(.65,.40)):
    x,y,z=at;w,d=size
    wood('Parts tray bottom',(x,y,z+.035),(w,d,.07),'wood_dark',.012)
    for xx in (-w/2,w/2):wood('Tray side',(x+xx,y,z+.12),(.045,d,.23),'oak',.01)
    for yy in (-d/2,d/2):wood('Tray end',(x,y+yy,z+.12),(w,.045,.23),'oak',.01)
    wood('Tray partition',(x,y,z+.10),(.035,d,.15),'wood',.008)
    gear((x-w*.24,y,z+.085),.09,8)
    for n in range(5):C('Small bolt in tray',(x+w*.2+(n%2)*.07,y-.1+(n//2)*.08,z+.09),.025,.065,'steel',6)


def shell():
    wood('Thick workshop floor',(6.5,6.19,-.18),(14,10.62,.38),'wood_dark',.015)
    # Herringbone pairs tile a lattice A=(4,4), B=(1,-1), in quarter-plank units.
    unit=.235
    for i in range(-12,15):
        for j in range(-65,65):
            ax=(4*i+j)*unit;ay=(4*i-j)*unit
            for x0,y0,x1,y1 in [(ax,ay,ax+4*unit,ay+unit),(ax+4*unit,ay,ax+5*unit,ay+4*unit)]:
                x0=max(-.5,x0);x1=min(13.5,x1);y0=max(.88,y0);y1=min(11.5,y1)
                if x1-x0<.025 or y1-y0<.025:continue
                wood('Individual herringbone stave',((x0+x1)/2,(y0+y1)/2,.015),(x1-x0-.009,y1-y0-.009,.035),'oak',.003)
    for axis in ('west','north'):
        if axis=='west':at=(-.64,6.2,1.65);size=(.24,10.9,3.30)
        else:at=(6.5,11.64,1.65);size=(14.3,.24,3.30)
        B('Cream workshop plaster '+axis,at,size,'plaster_paint',.015)
    for y in [1.0,3.4,7.0,11.5]:
        wood('West timber upright',(-.49,y,1.67),(.19,.19,3.34),'wood_dark')
        for z in (.15,3.12):B('Forged post shoe',(-.377,y,z),(.035,.24,.18),'brass',.009)
    for x in [-.45,3.2,7.0,10.0,13.5]:wood('North timber upright',(x,11.48,1.67),(.19,.19,3.34),'wood_dark')
    wood('West top plate',(-.50,6.2,3.22),(.23,10.8,.22),'oak')
    wood('North top plate',(6.5,11.48,3.22),(14.2,.23,.22),'oak')
    for y in [1.0+i*.27 for i in range(39)]:
        wood('West wainscot board',(-.486,y,.49),(.065,.255,.94),'wood',.008)
    for x in [-.35+i*.28 for i in range(50)]:wood('North wainscot board',(x,11.486,.49),(.267,.065,.94),'wood',.008)
    wood('West dado rail',(-.43,6.2,.98),(.10,10.6,.08),'oak')
    wood('North dado rail',(6.5,11.43,.98),(14.0,.10,.08),'oak')
    # Pictures and windows are separate in front of the retained wall surface.
    for side,c in [('west',6.9),('north',10.4)]:
        if side=='west':
            h.face('West window painted view',[(-.36,c-.66,1.32),(-.36,c+.66,1.32),(-.36,c+.66,2.76),(-.36,c-.66,2.76)],'harbour',[(.24,.35),(.48,.35),(.48,.71),(.24,.71)])
            for y in [c-.70,c,c+.70]:wood('West window mullion',(-.31,y,2.04),(.11,.065,1.56),'wood_edge',.012)
            for z in [1.28,2.02,2.80]:wood('West window crossrail',(-.31,c,z),(.11,1.48,.065),'wood_edge',.012)
            wood('Deep west sill',(-.22,c,1.24),(.52,1.64,.10),'oak')
            for dy in (-.47,.42):h.pot((-.13,c+dy,1.30),.7,False,True)
        else:
            h.face('North window painted view',[(c-.74,11.35,1.32),(c+.74,11.35,1.32),(c+.74,11.35,2.76),(c-.74,11.35,2.76)],'harbour',[(.56,.35),(.82,.35),(.82,.71),(.56,.71)])
            for x in [c-.78,c,c+.78]:wood('North window mullion',(x,11.30,2.04),(.07,.11,1.56),'wood_edge',.012)
            for z in [1.28,2.02,2.80]:wood('North window crossrail',(c,11.30,z),(1.64,.11,.065),'wood_edge',.012)
            wood('Deep north sill',(c,11.20,1.24),(1.80,.48,.10),'oak')
            h.pot((c-.49,11.12,1.30),.75,False,True)


def staircase():
    # Local coordinates are absolute room coordinates so tread data can be audited.
    for k in range(13):
        y=5.65+(k+.5)*.35;top=(k+1)*.20
        wood('Stair tread %02d'%k,(6,y,top-.045),(1.20,.35,.09),'bench',.014)
        wood('Closed stair riser',(6,y-.17,top-.13),(1.18,.055,.18),'wood',.009)
    for x in (5.31,6.69):
        R('Sloping staircase stringer',(x,5.58,.05),(x,10.26,2.69),.09,'wood_dark',12)
        R('Continuous stair handrail',(x,5.56,.95),(x,10.24,3.57),.055,'oak',12)
        for k in range(0,13,2):
            y=5.65+(k+.5)*.35;z=(k+1)*.2
            wood('Stair baluster',(x,y,z+.45),(.055,.055,.90),'wood_dark',.009)
        for y,z in [(5.61,.08),(10.18,2.60)]:
            wood('Stair newel',(x,y,z+.49),(.14,.14,.98),'wood_dark',.02)
            S('Round newel cap',(x,y,z+1.01),(.09,.09,.08),'wood_edge')
    wood('Upper loft landing',(6,10.42,2.555),(1.34,.48,.09),'oak',.014)
    # Real open storage beneath the upper flight, with repair cloths and jars.
    for x in (5.58,6.25):parts_tray((x,9.40,.04),(.55,.70))
    h.book((5.78,9.6,.3),(.44,.5,.10),'teal',.09)


def bench():
    for x in (-2.25,2.25):
        for y in (-.68,.68):wood('Mortised workbench leg',(x,y,.61),(.16,.16,1.22),'wood_dark')
    wood('Five-board workbench top',(0,0,1.21),(5.0,1.8,.16),'bench',.035)
    for y in (-.52,-.17,.18,.53):Q('Workbench board joint',[(-2.43,y,1.294),(2.43,y,1.294)],.003,'wood_dark')
    wood('Bench lower shelf',(0,.05,.28),(4.64,1.42,.10),'wood')
    for x in (-1.9,1.9):
        wood('Workbench drawer bank',(x,.04,.85),(.72,1.30,.56),'wood_dark')
        for z in (.70,.91,1.10):
            wood('Inset bench drawer',(x,-.63,z),(.66,.065,.16),'bench',.01)
            h.pull(x,-.69,z,.22)
    vice((-1.67,-.76,1.29))
    parts_tray((1.60,.30,1.30),(.62,.46));tool_cup((1.05,.45,1.30),.9)
    h.book((.96,-.27,1.30),(.45,.36,.055),'teal_dark',-.14)
    B('Repair notes',(-.60,-.18,1.302),(.55,.42,.009),'paper',.002)
    for n in range(6):B('Repair pencil marks',(-.72+n*.013,-.32+n*.046,1.31),(.28-n*.018,.004,.002),'ink',0)
    wrench((-.52,.3,1.32),.47,.7)
    # A partially disassembled automaton rests safely above the sheet.
    cloth=fabric('Loose dust sheet on bench',[(-.82,.94),(-.85,1.30),(-.45,1.33),(.0,1.36),(.42,1.34),(.78,1.31)],1.50)
    cloth.location.x=.15
    S('Cream enamel automaton shell',(.1,.13,1.62),(.48,.38,.34),'cream',24,12)
    T('Unlit round inspection window',(.1,-.20,1.65),.19,.04,'brass',(math.pi/2,0,0))
    S('Dark inspection glass',(.1,-.225,1.65),(.16,.025,.16),'steel_dark')
    for side in (-1,1):
        R('Detached forearm',(.1+side*.48,-.11,1.37),(.1+side*.65,-.44,1.33),.07,'cream')
        C('Exposed arm joint',(.1+side*.48,-.11,1.38),.10,.09,'brass')
    h.book((-1.4,.3,.35),(.6,.5,.12),'blue',.12)
    parts_tray((1.55,.03,.35),(.82,.90))


def tool_wall():
    wood('Tool hanging board',(0,0,.75),(4.7,.085,1.34),'wood_dark')
    for x in [-2.1+i*.40 for i in range(11)]:
        R('Tool hook',(x,-.06,1.16),(x,-.16,1.16),.013,'steel')
        if int(round((x+2.1)/.4))%3==0:
            Q('Hanging spanner',[(x-.055,-.13,.47),(x,-.13,.52),(x,-.13,1.07)],.027,'steel_light')
            T('Spanner open jaw',(x,-.13,1.07),.075,.021,'steel',(math.pi/2,0,0))
        elif int(round((x+2.1)/.4))%3==1:
            R('Screwdriver steel',(x,-.14,.55),(x,-.14,.95),.017,'steel_light')
            R('Screwdriver wood grip',(x,-.14,.92),(x,-.14,1.16),.040,'wood_edge')
        else:
            R('Hammer hanging grip',(x,-.14,.50),(x,-.14,1.10),.027,'wood')
            B('Hammer forged head',(x,-.14,1.13),(.23,.10,.10),'steel',.02)
    wood('Tool-wall upper shelf',(0,-.08,1.49),(4.9,.52,.10),'oak')
    parts_tray((-1.50,-.08,1.55),(.60,.38));parts_tray((1.15,-.08,1.55),(.72,.40))
    h.pot((-.35,-.10,1.55),.85,True)


def drawers():
    wood('Apothecary carcass',(0,0,1.20),(2.18,.80,2.4),'wood_dark')
    for x in (-1.04,1.04):wood('Drawer cabinet corner stile',(x,-.04,1.25),(.13,.83,2.5),'oak')
    wood('Cabinet plinth',(0,0,.10),(2.28,.9,.20),'wood_dark')
    wood('Cabinet cornice',(0,0,2.44),(2.32,.94,.13),'bench')
    for row in range(6):
        for col in range(4):
            x=-.78+col*.52;z=.33+row*.35
            wood('Small parts drawer',(x,-.43,z),(.47,.09,.30),'bench',.013)
            B('Brass label holder',(x,-.484,z+.035),(.21,.018,.10),'brass',.008)
            B('Cream drawer label',(x,-.497,z+.035),(.16,.008,.058),'paper',.002)
            h.pull(x,-.51,z-.066,.15)
    parts_tray((-.45,0,2.52),(.80,.60))
    h.book((.64,0,2.52),(.43,.42,.10),'teal',.13)


def assembly():
    for x in (-1.88,1.88):
        for y in (-.58,.58):wood('Assembly leg',(x,y,.57),(.16,.16,1.14),'wood_dark')
    wood('Assembly lower deck',(0,0,.26),(4.05,1.25,.11),'wood')
    wood('Thick assembly tabletop',(0,0,1.16),(4.4,1.65,.18),'bench',.04)
    for y in (-.36,0,.36):Q('Tabletop joint',[(-2.12,y,1.254),(2.12,y,1.254)],.004,'wood_dark')
    for x in (-1.45,1.45):
        wood('Assembly drawer',(x,-.67,.90),(.90,.09,.28),'oak')
        h.pull(x,-.75,.9,.23)
    parts_tray((-1.22,.25,1.26),(.73,.50));tool_cup((1.7,.45,1.26))
    # The cloth folds over the tabletop edge, never through its apron.
    o=fabric('Overhanging assembly cloth',[(-.98,.65),(-.94,.94),(-.87,1.22),(-.79,1.28),(-.45,1.29),(.05,1.28)],.92)
    o.location.x=.78
    B('Assembly blueprint',(-.60,-.27,1.262),(1.0,.63,.008),'blue_light',.006)
    for n in range(4):Q('Pencil blueprint line',[(-1.0,-.48+n*.12,1.271),(-.22,-.48+n*.12,1.271)],.003,'steel')
    gear((-.65,-.23,1.28),.18);wrench((.15,.28,1.28),.48,-.9)
    S('Spare enamel head',(.74,.06,1.49),(.31,.27,.23),'cream',24,12)
    T('Spare head window',(.74,-.18,1.49),.13,.026,'brass',(math.pi/2,0,0))
    S('Spare dark window',(.74,-.198,1.49),(.105,.017,.105),'steel_dark')
    R('Detached cream arm',(1.1,.34,1.34),(1.45,.18,1.34),.10,'cream')
    for x in (-1.45,-.40,.65):
        wood('Under-table crate',(x,0,.52),(.82,1.0,.42),'wood_dark')
        for z in (.38,.55,.70):wood('Crate front slat',(x,-.52,z),(.85,.045,.13),'oak',.008)
    for n in range(3):C('Oil tin',(1.56,-.15,.48+n*.02),.12,.34,'steel',16)


def parts_crate():
    wood('Parts crate floor',(0,0,.12),(1.6,1.12,.10),'wood_dark')
    for z in (.26,.48,.70):
        for y in (-.55,.55):wood('Crate long slat',(0,y,z),(1.62,.065,.19),'bench',.012)
        for x in (-.79,.79):wood('Crate end slat',(x,0,z),(.065,1.08,.19),'bench',.012)
    for x in (-.75,.75):
        for y in (-.52,.52):wood('Crate corner upright',(x,y,.46),(.10,.10,.82),'wood_dark')
    for x,y in [(-.42,-.20),(.36,.16),(-.25,.25)]:
        S('Salvaged enamel part',(x,y,.62),(.27,.22,.22),'cream')
        T('Salvaged brass collar',(x,y,.76),.15,.03,'brass')
    o=fabric('Crate protective rag',[(-.68,.22),(-.65,.49),(-.60,.84),(-.45,.87),(-.20,.81)],.48)
    o.location.x=.30


def stove():
    for x in (-.43,.43):
        for y in (-.32,.32):B('Stove cast foot',(x,y,.14),(.13,.13,.28),'steel_dark',.025)
    B('Cast iron stove',(0,0,.65),(1.02,.78,1.05),'steel_dark',.06,3)
    B('Stove projecting top',(0,0,1.20),(1.15,.90,.10),'steel',.025)
    B('Firebox amber window',(0,-.405,.70),(.64,.025,.58),'ember',.15,6)
    for x in (-.22,0,.22):R('Fire door iron bar',(x,-.435,.43),(x,-.435,.98),.018,'charcoal')
    Q('Arched stove window frame',[(-.35,-.445,.42),(-.35,-.445,.85),(-.23,-.445,1.01),(0,-.445,1.08),(.23,-.445,1.01),(.35,-.445,.85),(.35,-.445,.42)],.033,'steel')
    R('Door latch',(.37,-.45,.65),(.47,-.47,.65),.025,'brass')
    for n in range(4):R('Stacked fire log',(-.30+n*.19,-.20,.27),(-.30+n*.19,.22,.27),.08,'wood_dark',10)
    C('Stove flue',(0,.20,2.25),.13,2.0,'charcoal',20)
    for z in (1.30,2.05,2.85):T('Flue rolled collar',(0,.20,z),.136,.018,'steel')
    # Copper kettle: body, loop handle, lid and tapered spout.
    S('Copper kettle body',(.07,-.13,1.41),(.23,.21,.18),'leather')
    C('Kettle lid',(.07,-.13,1.58),.16,.028,'brass')
    S('Kettle lid knob',(.07,-.13,1.62),(.035,.035,.033),'wood_dark')
    Q('Kettle arch handle',[(-.13,-.13,1.48),(-.12,-.13,1.77),(.23,-.13,1.77),(.26,-.13,1.48)],.026,'steel_dark')
    Q('Kettle pouring spout',[(.25,-.13,1.36),(.37,-.13,1.43),(.42,-.13,1.56)],.038,'leather')


def armchair():
    for x in (-.48,.48):
        for y in (-.44,.44):wood('Armchair short foot',(x,y,.13),(.12,.12,.26),'wood_dark')
    B('Worn chair base',(0,0,.38),(1.20,1.14,.40),'upholstery',.15,6)
    B('Soft seat cushion',(0,-.13,.64),(.92,.85,.23),'upholstery_light',.14,6)
    back=B('Rounded chair back',(0,.44,1.08),(1.16,.27,1.12),'upholstery',.18,6);back.rotation_euler.x=-.07
    for x in (-.54,.54):B('Rolled upholstered arm',(x,-.05,.84),(.28,1.00,.40),'upholstery',.14,6)
    for x in (-.35,0,.35):
        for z in (.98,1.30):S('Upholstery button',(x,.285,z),(.018,.008,.018),'leather_dark',10,6)
    for x in (-.57,.57):Q('Arm piping',[(x,-.50,.82),(x,-.45,1.00),(x,.36,1.00)],.009,'upholstery_light')
    # Throw drapes across the back, cushions and front, in one supported surface.
    cloth=fabric('Green plaid throw',[(.62,.62),(.62,1.35),(.48,1.65),(.29,1.60),(.22,1.10),(.13,.79),(-.30,.78),(-.60,.65),(-.63,.32)],.54,'plaid')
    cloth.location.x=.12
    cushion=B('Small old cushion',(-.27,.14,.95),(.49,.22,.43),'teal_dark',.11,5);cushion.rotation_euler.y=.18
    for n in range(10):R('Throw fringe',(-.13+n*.053,-.65,.34),(-.12+n*.053,-.66,.26),.007,'ochre',6)


def tea_table():
    C('Round tea-table top',(0,0,.74),.44,.08,'bench',32)
    for n in range(3):
        a=n*math.tau/3;R('Splayed tea-table leg',(math.cos(a)*.33,math.sin(a)*.33,.02),(math.cos(a)*.24,math.sin(a)*.24,.72),.045,'wood_dark')
    C('Tea mug',(0,-.06,.89),.10,.20,'cream',24)
    T('Mug handle',(.12,-.06,.90),.065,.015,'cream',(math.pi/2,0,0))
    C('Tea in mug',(0,-.06,.992),.081,.006,'leather_dark',24)
    h.book((-.08,.14,.79),(.40,.28,.065),'red',-.12)


def job_board():
    B('Cork board backing',(0,0,0),(2.20,.12,1.50),'cork',.02)
    for x in (-1.12,1.12):wood('Job-board side frame',(x,-.04,0),(.13,.17,1.62),'wood_dark')
    for z in (-.76,.76):wood('Job-board rail',(0,-.04,z),(2.35,.17,.13),'oak')
    for k in range(140):
        x=RNG.uniform(-1.03,1.03);z=RNG.uniform(-.67,.67)
        S('Natural cork fleck',(x,-.064,z),(.007,.001,.005),'wood_edge',6,4)
    B('Single pinned ticket',(-.26,-.085,.06),(.63,.018,.90),'paper',.008)
    S('Ticket brass pin',(-.26,-.11,.45),(.025,.016,.025),'brass',10,6)
    for n in range(7):B('Ticket written line',(-.28,-.098,.31-n*.07),(.37-(n%3)*.04,.003,.004),'linen_shade',0)
    T('Red circular ticket stamp',(-.13,-.103,-.22),.075,.007,'red',(math.pi/2,0,0))
    B('Pencil tucked in frame',(.79,-.12,-.64),(.025,.035,.39),'ochre',.004)


def doors():
    for x in (-1.52,1.52):
        B('Stone door pier',(x,0,1.47),(.28,.38,2.94),'plaster',.025)
        wood('Door-frame upright',(x* .91,-.02,1.45),(.14,.26,2.90),'wood_dark')
    wood('Green doorway lintel',(0,0,2.91),(3.30,.33,.18),'wood_dark')
    B('Stone doorstep',(0,-.30,.08),(3.4,.80,.16),'ceramic',.025)
    for side in (-1,1):
        x=side*.69
        B('Green shop door leaf',(x,0,1.27),(1.30,.14,2.50),'teal_dark',.025)
        for col in range(6):
            xx=x-.54+col*.215
            B('Painted door board',(xx,-.085,1.14),(.202,.035,2.16),'teal',.01)
            for z in (.14,2.13):B('Worn door arris',(xx-.073,-.108,z),(.025,.008,.12),'wood_edge',.003)
        for z in (.31,1.91):B('Door cross-brace',(x,-.12,z),(1.25,.065,.13),'teal_dark',.012)
        R('Door diagonal brace',(x-.52,-.125,.39),(x+.52,-.125,1.82),.055,'teal_dark')
        for z in (.44,1.76):
            B('Forged door strap',(x+side*.32,-.17,z),(.52,.04,.09),'brass',.012)
            for dx in (-.18,.18):S('Hinge rivet',(x+side*.32+dx,-.195,z),(.018,.009,.018),'wood_dark',8,6)
        T('Brass door ring',(side*.16,-.18,1.17),.065,.016,'brass',(math.pi/2,0,0))
    # Glazed transom admits morning light even while the street leaves are latched.
    h.face('Transom harbour glass',[(-1.26,-.09,2.50),(1.26,-.09,2.50),(1.26,-.09,2.78),(-1.26,-.09,2.78)],'harbour',[(.2,.65),(.8,.65),(.8,.78),(.2,.78)])
    for x in (-1.3,-.65,0,.65,1.3):wood('Transom bar',(x,-.13,2.64),(.055,.06,.35),'wood_edge',.01)
    for z in (2.47,2.81):wood('Transom rail',(0,-.13,z),(2.68,.06,.06),'wood_dark',.01)
    for x in (-1.93,1.95):h.pot((x,-.04,.02),1.3,False,True)


def hanging_lamp():
    Q('Ceiling lamp wire',[(0,0,1.15),(0,0,.35)],.012,'steel_dark')
    C('Enamel pendant shade',(0,0,.27),.31,.24,'teal_dark',32,.095)
    C('Warm lamp diffuser',(0,0,.155),.27,.012,'lamp_glass',32)
    T('Pendant rolled rim',(0,0,.15),.31,.015,'brass')


def stool():
    wood('Old square stool seat',(0,0,.63),(.56,.52,.10),'bench',.05)
    for x in (-.19,.19):
        for y in (-.18,.18):R('Stool splayed leg',(x*1.35,y*1.35,.02),(x,y,.60),.034,'wood_dark')
    for y in (-.20,.20):R('Stool rung',(-.23,y,.22),(.23,y,.22),.019,'wood')


def rug():
    B('Worn workshop rug',(0,0,.03),(4.4,3.0,.035),'teal_dark',.03)
    for x in (-2.0,2.0):B('Woven cream border',(x,0,.052),(.075,2.8,.003),'linen_shade',.005)
    for y in (-1.28,1.28):B('Rug cross border',(0,y,.052),(4.05,.075,.003),'linen_shade',.005)
    for n in range(25):
        y=-1.2+n*.10
        Q('Subtle rug weave',[(-1.92,y,.053),(1.92,y,.053)],.002,'teal')
    for side in (-1,1):
        for n in range(40):R('Knotted rug fringe',(-2.1+n*.108,side*1.51,.03),(-2.1+n*.108,side*1.60,.025),.006,'linen',6)


def wall_shelf():
    for z in (.0,.64):wood('Workshop wall shelf',(0,0,z),(1.90,.49,.09),'oak')
    for x in (-.70,.70):
        Q('Shelf wrought bracket',[(x,.12,-.31),(x,.12,.03),(x,-.18,-.08),(x,.12,-.31)],.019,'steel_dark')
    for n in range(6):h.book((-.65+n*.18,.05,.70),(.14,.29,.35+n%3*.045),['red','teal','ochre'][n%3],.02*((n%2)*2-1))
    h.pot((.60,-.05,.70),.75,True)
    parts_tray((-.23,0,.06),(.60,.34))


def umbrella_stand():
    C('Umbrella crock',(0,0,.34),.22,.66,'ceramic',20,.27)
    T('Crock rim',(0,0,.67),.27,.022,'wood_edge')
    for x in (-.09,.09):
        R('Folded umbrella',(x,0,.20),(x-.08,0,1.17),.055,'blue')
        Q('Umbrella crook',[(x-.08,0,1.17),(x-.08,0,1.30),(x+.04,0,1.32),(x+.07,0,1.23)],.022,'wood_dark')


BUILDERS={'workshop-shell':shell,'workshop-staircase':staircase,'workshop-repair-bench':bench,
    'workshop-tool-wall':tool_wall,'workshop-parts-drawers':drawers,'workshop-assembly-table':assembly,
    'workshop-parts-crate':parts_crate,'workshop-stove':stove,'workshop-armchair':armchair,
    'workshop-tea-table':tea_table,'workshop-job-board':job_board,'workshop-shop-doors':doors,
    'workshop-hanging-lamp':hanging_lamp,'workshop-stool':stool,'workshop-rug':rug,
    'workshop-wall-shelf':wall_shelf,'workshop-umbrella-stand':umbrella_stand}


def save(asset):
    groups={}
    for o in list(bpy.context.scene.objects):
        if o.type=='CURVE':
            bpy.ops.object.select_all(action='DESELECT');o.select_set(True)
            bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
        if o.type!='MESH':continue
        if not o.data.uv_layers:
            uv=o.data.uv_layers.new(name='Source planar UV')
            for p in o.data.polygons:
                axes=[i for i in range(3) if i!=max(range(3),key=lambda a:abs(p.normal[a]))]
                for li in p.loop_indices:
                    v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v[axes[0]],v[axes[1]])
        groups.setdefault(o.data.materials[0].name,[]).append(o)
    for name,objects in groups.items():
        parts=[o.name for o in objects]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        bpy.context.object.name=name;bpy.context.object['authored_parts']=parts
    bpy.ops.file.pack_all()
    folder=ROOT/'art/source/world'/asset/'v1';folder.mkdir(parents=True,exist_ok=True)
    bpy.context.scene['source_authority']='Editable T7b workshop master. Never regenerate; open and deliberately edit.'
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'model.blend'))
    (folder/'provenance.json').write_text(json.dumps({'asset':asset,'date':'2026-10-27',
        'reference':'docs/concept/v0.7/art/4-opening/T7b-workshop-floor.png',
        'record':'art/source/world/sparks-workshop/v1/author.py',
        'record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'painted_sources':'art/source/world/sparks-workshop/v1/prompts.json'},indent=2)+'\n')
    (folder/'brief.md').write_text('# '+asset+'\n\nBespoke outlined workshop asset after the selected T7b and P3 references. The saved `model.blend` is the editable authority. Export with `scripts/world-art.sh build '+asset+'`. Placement and collision belong to `content/areas/workshop-floor.json`. Painted sources and authoring record: [workshop source pack](../../sparks-workshop/v1/README.md).\n')
    print('AUTHORED',asset,flush=True)


if __name__=='__main__':
    for asset in BUILDERS:
        if (ROOT/'art/source/world'/asset/'v1/model.blend').exists():raise RuntimeError('Existing master; open it instead: '+asset)
    for asset,make in BUILDERS.items():start(asset);make();save(asset)
