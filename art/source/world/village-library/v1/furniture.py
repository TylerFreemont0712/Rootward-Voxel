"""Ten individually designed cottage furnishings. Dimensions match library.json; not colour variants."""
import math
from modeling import legs, tabletop, cabinet, drawer


def highback_armchair(m):
    legs(m,.88,.78,.40,thickness=.13)
    m.box((0,0,.42),(.96,.84,.14),'oak')
    m.box((0,-.035,.52),(.74,.67,.14),'cloth_plum')
    m.box((0,-.035,.60),(.67,.60,.045),'cloth_lilac')
    for x in [-.43,.43]:
        m.box((x,.30,.85),(.13,.14,.87),'wood_dark')
        m.box((x,-.28,.63),(.13,.13,.40),'oak')
        m.box((x,-.02,.81),(.17,.77,.11),'oak_light')
        m.cylinder((x,-.40,.81),.095,.10,'oak',axis='Y',sides=8)
    m.box((0,.32,.97),(.73,.14,.66),'oak')
    m.box((0,.225,.99),(.57,.08,.49),'cloth_plum')
    m.box((0,.30,1.32),(.80,.18,.12),'oak_light')
    m.box((0,.24,1.40),(.24,.14,.12),'oak',(0,math.pi/4,0))
    for x in [-.23,0,.23]:
        m.cylinder((x,.165,.79),.025,.025,'brass',axis='Y',sides=6)
        m.cylinder((x,.165,1.19),.025,.025,'brass',axis='Y',sides=6)


def trestle_table(m):
    for x in [-.72,.72]:
        m.box((x,0,.08),(.28,.97,.15),'wood_dark')
        for y in [-.34,.34]:
            m.beam((x,y,.13),(x,y*.35,.77),.13,'oak')
        m.box((x,0,.73),(.19,.85,.13),'wood')
    m.box((0,0,.28),(1.65,.13,.13),'oak')
    for x in [-.87,.87]:
        m.box((x,0,.28),(.06,.21,.24),'wood_dark')
        m.cylinder((x,-.12,.28),.035,.055,'brass',axis='Y',sides=8)
    tabletop(m,2.2,1.0,.87,6)
    for x in [-.8,.8]:
        for y in [-.36,.36]:
            m.cylinder((x,y,.916),.025,.008,'wood_dark',sides=6)


def writing_desk(m):
    legs(m,1.43,.67,.74,thickness=.11)
    m.box((0,0,.66),(1.47,.70,.18),'wood_dark')
    tabletop(m,1.55,.8,.80,4)
    for x in [-.48,.48]:
        drawer(m,x,-.385,.66,.44,.16)
    m.box((0,.12,.925),(.83,.45,.08),'wood',(math.radians(14),0,0))
    m.box((0,.095,.974),(.71,.34,.014),'cream',(math.radians(14),0,0))
    for i in range(4):
        m.box((-.03,-.025+i*.045,.983+i*.012),(.40,.011,.006),'linen')
    m.bottle((-.59,.15,.85),.15,'glass_blue')
    m.beam((-.59,.15,1.0),(-.44,.15,1.31),.018,'cream')
    m.ellipsoid((-.46,.15,1.22),(.07,.025,.20),'cream',sides=6,rings=3)
    m.box((.56,.19,.87),(.28,.30,.045),'linen',(0,0,.12))
    m.box((.56,.19,.90),(.25,.27,.014),'cream',(0,0,.12))


def mapmakers_table(m):
    legs(m,1.48,.82,.77,thickness=.14)
    tabletop(m,1.65,1.0,.85,5)
    m.box((0,0,.904),(1.32,.76,.024),'linen')
    m.box((0,0,.92),(1.20,.65,.013),'cream')
    for x in [-.67,.67]:
        m.cylinder((x,0,.95),.05,.78,'cream',axis='Y',sides=10)
        for y in [-.42,.42]:
            m.cylinder((x,y,.95),.065,.045,'brass',axis='Y',sides=8)
    for start,end in [((-.48,-.22,.933),(-.14,-.1,.933)),((-.14,-.1,.933),(.16,.16,.933)),((.16,.16,.933),(.48,.11,.933))]:
        m.beam(start,end,.026,'cloth_teal',depth=.012)
    for x,y in [(-.4,-.20),(.16,.16),(.44,.12)]:
        m.cylinder((x,y,.95),.043,.03,'rust',sides=6)
    m.cylinder((.48,-.23,.96),.12,.035,'brass',sides=12)
    m.cylinder((.48,-.23,.982),.095,.012,'cream',sides=12)
    m.beam((.43,-.28,.992),(.53,-.18,.992),.02,'iron')


def apothecary_cabinet(m):
    cabinet(m,1.26,.56,1.50)
    m.box((0,-.29,1.12),(1.05,.03,.61),'wood_dark')
    for z in [.83,1.13,1.48]:
        m.box((0,-.04,z),(1.15,.55,.065),'oak_light')
    for x in [-.55,.55]:
        m.box((x,-.29,1.16),(.07,.08,.66),'oak')
    for row in range(3):
        for col in range(4):
            x=-.435+col*.29
            drawer(m,x,-.30,.23+row*.19,.25,.16)
            m.box((x,-.34,.26+row*.19),(.10,.012,.035),'cream')
    for row,z in enumerate([.87,1.17]):
        for i,x in enumerate([-.40,-.14,.14,.40]):
            m.bottle((x,-.07,z),.22+.025*(i%2),['glass_teal','glass_violet','clay','glass_blue'][(i+row)%4])
    m.box((0,0,1.60),(.57,.52,.12),'plaster')
    m.box((0,-.29,1.61),(.12,.035,.12),'brass',(0,math.pi/4,0))


def kitchen_dresser(m):
    cabinet(m,1.45,.60,.83)
    for x in [-.36,.36]:
        drawer(m,x,-.325,.37,.61,.48)
        drawer(m,x,-.325,.69,.61,.15)
    m.box((0,.24,1.25),(1.44,.09,.85),'wood_dark')
    for x in [-.68,.68]:
        m.box((x,.08,1.31),(.12,.36,1.0),'oak')
    for z in [1.04,1.43,1.80]:
        m.box((0,.03,z),(1.50,.43,.075),'oak_light')
    for row,z in enumerate([1.24,1.62]):
        for i,x in enumerate([-.46,-.15,.16,.47]):
            m.cylinder((x,.13,z),.13,.04,'cream',axis='Y',sides=12)
            m.ring((x,.102,z),.11,.09,.008,'cloth_teal' if (row+i)%2 else 'cloth_plum',axis='Y',sides=12)
    m.box((-.35,-.10,.91),(.42,.61,.025),'linen')
    m.jug((.40,-.10,.90),.12,.30,'clay')
    m.bowl((.05,-.15,.90),.14,'cream')


def oak_wardrobe(m):
    cabinet(m,1.24,.65,1.81)
    for x in [-.30,.30]:
        m.box((x,-.345,.96),(.55,.07,1.48),'oak')
        for z in [.59,1.30]:
            m.box((x,-.388,z),(.42,.02,.56),'wood')
            m.box((x,-.407,z),(.18,.015,.18),'cloth_plum',(0,math.pi/4,0))
    for x in [-.10,.10]:
        m.ring((x,-.415,.97),.046,.025,.035,'brass',axis='Y',sides=8)
    m.box((0,0,1.92),(.93,.65,.15),'oak')
    m.box((0,0,2.01),(.46,.58,.09),'oak_light')
    for x in [-.53,.53]:
        m.cylinder((x,0,1.93),.065,.19,'brass',sides=8)


def washstand(m):
    legs(m,.91,.55,.73,thickness=.10)
    m.box((0,0,.18),(.83,.50,.075),'oak')
    tabletop(m,1.0,.65,.77,4)
    m.bowl((-.16,-.07,.82),.25,'cream')
    m.cylinder((-.16,-.07,.972),.195,.012,'water')
    m.jug((.32,.10,.82),.105,.31,'glass_teal')
    for x in [-.33,.33]:
        m.box((x,.27,1.24),(.065,.075,.91),'wood_dark')
    m.box((0,.28,1.42),(.62,.075,.58),'brass')
    m.box((0,.232,1.42),(.52,.025,.48),'glass_blue')
    m.beam((-.20,.212,1.22),(.15,.212,1.62),.014,'cream')
    m.box((-.34,-.23,.27),(.25,.30,.11),'linen')


def woven_settee(m):
    legs(m,1.47,.69,.32,thickness=.13)
    m.box((0,0,.39),(1.60,.8,.18),'wood_dark')
    m.box((0,.31,.80),(1.53,.14,.73),'oak')
    for x in [-.72,.72]:
        m.box((x,0,.69),(.13,.77,.48),'oak')
        m.box((x,-.02,.95),(.18,.82,.09),'oak_light')
    for x in [-.34,.34]:
        m.box((x,-.05,.54),(.65,.61,.18),'cloth_teal')
        m.box((x,.21,.83),(.65,.13,.39),'cloth_light')
    for x in [-.50,.50]:
        m.box((x,.09,.69),(.25,.20,.25),'cream',(-.15,0,.18 if x>0 else -.18))
    for x in [-.58,-.28,.02,.32,.58]:
        m.box((x,.234,.82),(.014,.015,.31),'linen')


def patchwork_bed(m):
    legs(m,1.0,1.86,.30,thickness=.12)
    m.box((0,0,.31),(1.10,2.0,.16),'wood_dark')
    for x in [-.49,.49]:
        for y in [-.91,.91]:
            height=.98 if y>0 else .66
            m.box((x,y,height*.5),(.13,.13,height),'oak')
            m.ellipsoid((x,y,height+.035),(.18,.18,.15),'brass',sides=8,rings=4)
    m.box((0,.91,.74),(.93,.12,.44),'oak')
    m.box((0,-.91,.50),(.93,.11,.20),'oak')
    m.box((0,0,.45),(.95,1.77,.18),'linen')
    for x in range(4):
        for y in range(6):
            material=['cloth_plum','cloth_lilac','cream'][(x+y*2)%3]
            m.box((-.36+x*.24,-.68+y*.23,.558),(.233,.224,.045),material)
    m.box((0,.64,.59),(.76,.32,.14),'cream')
    m.box((0,.64,.663),(.65,.23,.012),'linen')
    for x in [-.34,.34]:
        m.box((x,.91,.78),(.10,.135,.10),'brass',(0,math.pi/4,0))
