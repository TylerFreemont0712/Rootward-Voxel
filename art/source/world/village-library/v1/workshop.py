"""Ten craft objects: individually composed tools and benches, with explicit moving-part pivots."""
import math
from modeling import legs, tabletop, flame


def carpenters_bench(m):
    legs(m,1.74,.72,.77,thickness=.16)
    tabletop(m,1.9,.85,.83,5)
    m.box((0,0,.25),(1.67,.59,.08),'oak')
    for x in [-.68,.68]:
        m.beam((x,-.29,.27),(x,.29,.72),.09,'wood')
    m.box((-.61,-.47,.74),(.36,.17,.18),'wood_dark')
    m.cylinder((-.61,-.60,.74),.042,.30,'iron',axis='Y',sides=10)
    m.beam((-.73,-.77,.74),(-.49,-.77,.74),.045,'oak_light')
    m.box((.20,-.07,.93),(.42,.17,.13),'wood')
    m.box((.20,-.07,1.00),(.05,.14,.10),'iron',(0,.25,0))
    m.box((.47,.20,.92),(.64,.08,.10),'silver',(0,0,.23))
    m.ring((.72,.26,.95),.12,.065,.07,'oak',axis='Y',sides=8)
    for x in [-.72,-.45,-.18,.09]:
        m.cylinder((x,.31,.88),.026,.035,'iron',sides=8)
    m.box((.40,.04,.34),(.61,.28,.10),'oak_light')


def blacksmiths_anvil(m):
    m.cylinder((0,0,.24),.29,.48,'wood',sides=10,top=.26)
    for z in [.09,.38]:
        m.ring((0,0,z),.295,.272,.05,'iron',sides=10)
    m.box((0,0,.53),(.69,.43,.12),'iron')
    m.box((0,0,.67),(.35,.26,.20),'iron')
    m.box((-.05,0,.82),(.67,.36,.14),'silver')
    m.box((-.25,0,.89),(.24,.37,.045),'iron')
    # A tapering horn follows X, leaving a clear silhouette beside the heel.
    m.cylinder((.38,0,.81),.16,.38,'iron',axis='X',sides=6,top=.025)
    m.box((-.24,-.24,.57),(.32,.11,.08),'oak',(0,.4,0))
    m.box((-.35,-.24,.62),(.18,.16,.16),'iron',(0,.4,0))


def bellows_forge(m):
    m.box((-.16,.10,.15),(1.23,.94,.30),'stone_dark')
    m.box((-.16,.10,.55),(1.18,.88,.54),'stone')
    m.box((-.16,-.35,.54),(.80,.03,.32),'wood_dark')
    m.box((-.16,.17,.87),(1.16,.73,.12),'stone_light')
    for x in [-.56,-.29,-.02,.25]:
        m.cylinder((x,-.16,.85),.09,.09,'iron',sides=7)
    for x in [-.40,-.16,.10]:
        flame(m,(x,-.15,.90),.29)
    m.box((-.16,.28,1.28),(1.0,.66,.10),'copper',(.28,0,0))
    m.box((-.16,.40,1.61),(.47,.43,.62),'copper')
    m.box((-.16,.40,1.95),(.59,.55,.10),'iron')
    m.box((.62,.05,.60),(.38,.65,.18),'wood_dark')
    for z in [.55,.61,.67]:
        m.box((.62,.05,z),(.36,.61,.035),'rust')
    m.box((.62,.05,.73),(.39,.65,.065),'oak')
    m.beam((.46,-.10,.66),(.21,-.10,.82),.085,'iron')


def grinding_wheel(m):
    for x in [-.35,.35]:
        m.box((x,0,.08),(.22,.72,.16),'wood_dark')
        m.beam((x,-.24,.15),(x,0,.88),.13,'oak')
        m.beam((x,.24,.15),(x,0,.88),.13,'oak')
    m.beam((-.49,0,.91),(.49,0,.91),.075,'iron')
    m.box((0,-.22,.19),(.55,.27,.075),'oak_light')
    m.moving((0,0,.91))
    m.cylinder((0,0,.91),.36,.23,'stone',sides=16,axis='X')
    for x in [-.125,.125]:
        m.cylinder((x,0,.91),.13,.03,'stone_light',sides=12,axis='X')
        m.cylinder((x*1.15,0,.91),.055,.045,'brass',sides=8,axis='X')
    m.fixed()
    m.bowl((-.35,.20,.49),.13,'clay')


def tool_rack(m):
    for x in [-.58,.58]:
        m.box((x,0,.07),(.23,.49,.14),'wood_dark')
        m.box((x,.10,.82),(.10,.12,1.55),'oak')
    for z in [.32,1.31,1.57]:
        m.box((0,.10,z),(1.35,.12,.12),'wood')
    for i,x in enumerate([-.46,-.15,.16,.47]):
        m.beam((x,-.02,.37),(x,-.02,1.35),.046,'oak_light')
        if i==0:
            m.box((x+.045,-.02,1.22),(.28,.055,.22),'iron')
        elif i==1:
            m.box((x,-.02,.43),(.21,.075,.25),'silver')
        elif i==2:
            m.box((x,-.02,1.30),(.24,.08,.06),'iron')
            for dx in [-.09,-.03,.03,.09]:
                m.box((x+dx,-.02,1.20),(.025,.065,.17),'iron')
        else:
            m.box((x,-.02,1.25),(.23,.12,.12),'iron')
        m.ring((x,-.035,1.43),.055,.035,.03,'iron',axis='Y',sides=8)


def potters_wheel(m):
    legs(m,.94,.77,.56,thickness=.12)
    m.box((0,0,.60),(1.08,.88,.11),'wood')
    m.cylinder((0,0,.40),.055,.58,'iron',sides=8)
    m.moving((0,0,.69))
    m.cylinder((0,0,.28),.39,.07,'stone',sides=14)
    m.cylinder((0,0,.70),.35,.065,'oak_light',sides=14)
    m.jug((0,0,.74),.17,.43,'clay')
    m.fixed()
    m.bowl((-.41,-.30,.66),.12,'clay_light')
    m.box((.30,-.23,.16),(.31,.31,.07),'wood_dark')


def weavers_loom(m):
    for x in [-.60,.60]:
        m.box((x,0,.08),(.23,.94,.16),'wood_dark')
        m.box((x,.18,.87),(.14,.14,1.65),'oak')
    for z in [.44,1.68]:
        m.box((0,.18,z),(1.38,.17,.15),'oak_light')
    for i in range(17):
        x=-.51+i*.064
        m.beam((x,.13,.57),(x,.13,1.61),.012,'cream')
    m.box((0,.09,.87),(1.03,.055,.58),'cloth_plum')
    for z in [.62,.69,.76,.83,.90]:
        m.box((0,.051,z),(1.0,.012,.023),'cloth_lilac')
    m.box((0,.05,1.02),(1.20,.08,.055),'oak_light')
    m.cylinder((0,-.17,.50),.075,1.31,'oak',axis='X')
    m.box((0,-.24,.60),(.38,.065,.06),'brass')
    m.beam((-.60,-.40,.10),(-.60,.18,1.26),.07,'wood')
    m.beam((.60,-.40,.10),(.60,.18,1.26),.07,'wood')


def spinning_wheel(m):
    for x in [-.40,.40]:
        m.box((x,0,.07),(.20,.61,.14),'wood_dark')
        m.beam((x,-.15,.13),(x,.03,.85),.10,'oak')
    m.box((0,0,.22),(.95,.15,.10),'oak')
    m.moving((.05,.02,.89))
    m.wheel((.05,.02,.89),.47,'X',10)
    m.fixed()
    m.beam((-.48,.07,.40),(-.48,.07,1.25),.07,'wood')
    m.beam((-.53,.07,1.23),(-.26,.07,1.23),.03,'iron')
    m.ellipsoid((-.45,.07,1.10),(.20,.20,.35),'cream',sides=8,rings=4)
    m.beam((-.36,-.07,1.22),(.06,-.07,1.18),.012,'linen')
    m.box((.10,-.20,.16),(.49,.20,.06),'oak_light')


def alchemy_bench(m):
    legs(m,1.40,.68,.76,thickness=.13)
    tabletop(m,1.55,.8,.83,5)
    m.box((0,.28,1.18),(1.40,.09,.63),'wood_dark')
    m.box((0,.25,1.52),(1.52,.25,.08),'oak')
    for x,z,colour in [(-.48,.91,'glass_teal'),(-.15,.91,'glass_violet'),(.19,.91,'glass_blue')]:
        m.bottle((x,-.10,z),.36,colour)
        m.cylinder((x,-.10,z+.13),.068,.16,'state_glow',sides=8)
    m.beam((.55,.04,.87),(.55,.04,1.43),.07,'copper')
    m.beam((.55,.04,1.43),(.12,.04,1.43),.07,'copper')
    m.ring((.57,.04,1.17),.12,.08,.04,'brass',axis='X',sides=8)
    for i,x in enumerate([-.48,-.22,.04]):
        m.bottle((x,.25,1.57),.21+.03*i,['glass_violet','glass_teal','clay'][i])


def bookbinders_press(m):
    legs(m,1.02,.66,.43,thickness=.13)
    tabletop(m,1.15,.80,.49,4)
    for x in [-.43,.43]:
        m.box((x,.06,1.0),(.14,.17,.95),'oak')
        m.cylinder((x,.06,1.25),.055,.47,'iron',sides=8)
        for z in [1.06,1.14,1.22,1.30,1.38,1.46]:
            m.ring((x,.06,z),.068,.045,.025,'brass',sides=8)
    m.box((0,.06,1.41),(1.13,.30,.14),'wood_dark')
    m.box((0,-.04,.83),(.94,.57,.12),'oak')
    m.box((0,-.04,.69),(.76,.43,.12),'cream')
    for z in [.61,.76]:
        m.box((0,-.04,z),(.83,.48,.045),'cloth_plum')
    for x in [-.33,.33]:
        for y in [-.22,.14]:
            m.box((x,y,.789),(.10,.10,.015),'brass')
    m.cylinder((0,.06,1.55),.065,.19,'iron',sides=8)
    m.beam((-.27,.06,1.63),(.27,.06,1.63),.06,'oak_light')
