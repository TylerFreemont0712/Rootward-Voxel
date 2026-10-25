"""Village fixtures and modest fantasy objects. No new gameplay authority is hidden in a mesh."""
import math
from modeling import roof, gem, flame


def copper_brazier(m):
    for angle in [0,math.tau/3,math.tau*2/3]:
        x,y=math.cos(angle)*.32,math.sin(angle)*.32
        m.beam((x,y,.035),(x*.55,y*.55,.61),.075,'iron')
        m.box((x,y,.035),(.13,.13,.07),'iron')
    m.cylinder((0,0,.58),.24,.24,'copper',sides=12,top=.39)
    m.ring((0,0,.71),.40,.34,.08,'copper_light',sides=12)
    m.cylinder((0,0,.72),.32,.015,'wood_dark',sides=12)
    m.beam((-.23,-.10,.75),(.23,.10,.77),.09,'wood')
    m.beam((.20,-.18,.75),(-.16,.20,.77),.09,'wood')
    for x,y,s in [(-.13,0,.38),(.12,.06,.32),(0,-.15,.28)]:
        flame(m,(x,y,.77),s)
    for angle in [0,math.pi/2,math.pi,3*math.pi/2]:
        x,y=.325*math.cos(angle),.325*math.sin(angle)
        m.ellipsoid((x,y,.60),(.07,.07,.09),'brass',sides=6,rings=3)


def shard_lantern(m):
    m.box((0,0,.08),(.60,.60,.16),'stone_dark')
    m.box((0,0,.21),(.49,.49,.11),'brass')
    for x in [-.23,.23]:
        for y in [-.23,.23]:
            m.beam((x,y,.25),(x*.76,y*.76,1.18),.045,'brass')
    gem(m,(0,0,.34),.72,'state_glow')
    m.box((0,0,1.17),(.56,.56,.09),'wood_dark')
    roof(m,.71,.64,1.22,'roof',.24)
    m.ring((0,0,1.60),.11,.065,.05,'brass',axis='Y',sides=10)


def crystal_obelisk(m):
    m.box((0,0,.08),(.94,.92,.16),'stone_dark')
    m.box((0,0,.21),(.78,.77,.13),'stone_light')
    m.box((0,0,.32),(.64,.63,.09),'stone')
    gem(m,(0,.06,.37),1.30,'glass_teal')
    gem(m,(-.28,-.12,.33),.70,'glass_blue')
    gem(m,(.28,.06,.35),.88,'glass_teal')
    m.beam((0,-.26,.65),(0,-.26,1.36),.038,'state_glow')
    m.beam((-.09,-.26,1.05),(0,-.26,1.15),.033,'state_glow')
    m.beam((.09,-.26,1.05),(0,-.26,1.15),.033,'state_glow')
    for x in [-.34,.34]:
        m.box((x,-.18,.30),(.065,.21,.08),'brass')


def rune_standing_stone(m):
    m.box((0,0,.09),(.91,.61,.18),'stone_dark')
    m.box((0,.01,.78),(.72,.42,1.43),'stone')
    m.box((-.12,.01,1.52),(.48,.40,.15),'stone_light')
    m.box((.24,.01,1.43),(.24,.42,.16),'stone_dark')
    for z in [.55,.92,1.28]:
        m.box((-.01,-.215,z),(.54,.025,.026),'stone_dark')
    for start,end in [((0,-.237,.48),(0,-.237,1.30)),((0,-.237,1.25),(-.20,-.237,1.04)),
                      ((-.20,-.237,1.04),(0,-.237,.83)),((0,-.237,.83),(.20,-.237,1.04)),
                      ((.20,-.237,1.04),(0,-.237,1.25))]:
        m.beam(start,end,.045,'state_glow')
    m.box((0,-.25,.38),(.14,.04,.10),'brass')
    for x,y in [(-.34,-.18),(.23,.19),(.35,-.11)]:
        m.ellipsoid((x,y,.18),(.22,.18,.14),'moss',sides=7,rings=3)


def village_bell(m):
    for x in [-.46,.46]:
        m.box((x,0,.075),(.30,.67,.15),'stone_dark')
        m.box((x,0,.87),(.14,.17,1.60),'wood_dark')
        m.box((x,-.10,.48),(.16,.035,.31),'brass')
    m.box((0,0,1.61),(1.12,.19,.16),'oak')
    roof(m,1.28,.89,1.72,'roof',.24)
    m.moving((0,0,1.51))
    m.cylinder((0,0,1.44),.10,.12,'brass',sides=10)
    m.cylinder((0,0,1.22),.28,.32,'brass',sides=12,top=.12)
    m.ring((0,0,1.04),.35,.27,.10,'brass',sides=12)
    m.cylinder((0,0,1.037),.265,.014,'wood_dark',sides=12)
    m.beam((0,0,1.44),(0,0,.95),.03,'iron')
    m.ellipsoid((0,0,.96),(.105,.105,.12),'brass',sides=8,rings=4)
    m.fixed()
    m.beam((.13,.13,1.40),(.13,.13,.65),.02,'linen')
    m.ring((.13,.13,.61),.06,.035,.025,'linen',axis='Y',sides=8)


def brass_lever(m):
    m.box((0,0,.07),(.61,.60,.14),'stone_dark')
    m.box((0,0,.21),(.49,.47,.15),'stone')
    m.box((0,0,.31),(.40,.38,.08),'brass')
    m.box((0,0,.36),(.10,.31,.035),'wood_dark')
    for x in [-.17,.17]:
        m.cylinder((x,0,.40),.09,.06,'brass',axis='X',sides=10)
    m.moving((0,0,.40))
    m.beam((0,0,.40),(0,-.15,.96),.065,'iron')
    m.box((0,-.16,.97),(.27,.10,.14),'cloth_teal',(.25,0,0))
    m.fixed()
    for y,mat in [(-.19,'glass_teal'),(.19,'rust')]:
        m.cylinder((.14,y,.364),.035,.018,mat,sides=8)


def water_pump(m):
    m.box((0,.04,.075),(.76,.67,.15),'stone_dark')
    m.cylinder((0,.14,.61),.13,.95,'iron',sides=10)
    m.cylinder((0,.14,1.10),.19,.12,'cloth_teal',sides=10)
    m.cylinder((0,.14,.22),.21,.13,'cloth_teal',sides=10)
    m.beam((0,.07,.89),(0,-.23,.89),.10,'brass')
    m.beam((0,-.23,.89),(0,-.23,.79),.10,'brass')
    m.moving((0,.14,1.06))
    m.beam((0,.14,1.06),(0,.48,1.22),.055,'iron')
    m.box((0,.49,1.22),(.20,.09,.09),'oak')
    m.fixed()
    m.box((0,-.22,.22),(.62,.42,.24),'stone')
    m.box((0,-.22,.35),(.49,.30,.025),'water')
    m.cylinder((0,-.23,.57),.022,.40,'state_glow',sides=6)


def wayfarers_chest(m):
    m.box((0,0,.06),(1.12,.72,.12),'wood_dark')
    for x in [-.51,.51]:
        m.box((x,0,.33),(.10,.68,.48),'oak')
    for y in [-.31,.31]:
        m.box((0,y,.33),(1.10,.10,.48),'oak')
    m.box((0,0,.135),(.91,.50,.025),'wood_dark')
    for x in [-.42,.42]:
        for y in [-.365,.365]:
            m.box((x,y,.34),(.08,.025,.44),'iron')
            for z in [.18,.48]:
                m.cylinder((x,y*1.04,z),.018,.018,'brass',sides=6,axis='Y')
    m.moving((0,.31,.57))
    for i in range(7):
        y=-.31+i*.1033
        z=.58+.14*math.sqrt(max(0,1-(y/.39)**2))
        m.box((0,y,z),(1.12,.106,.075),'cloth_plum' if i%3 else 'oak')
        for x in [-.42,.42]:
            m.box((x,y,z+.045),(.075,.108,.025),'iron')
    m.box((0,-.36,.56),(.15,.06,.19),'brass')
    m.box((0,-.397,.55),(.05,.013,.07),'wood_dark')
    m.fixed()
    for x in [-.57,.57]:
        m.ring((x,0,.35),.085,.05,.04,'iron',axis='X',sides=8)


def little_shrine(m):
    m.box((0,0,.06),(1.05,.76,.12),'stone_dark')
    m.box((0,0,.19),(.89,.65,.14),'stone_light')
    m.box((0,.24,.70),(.86,.10,.93),'plaster')
    for x in [-.39,.39]:
        m.box((x,.05,.73),(.10,.43,.99),'wood_dark')
    m.box((0,.05,.46),(.77,.49,.10),'oak')
    gem(m,(0,-.04,.51),.48,'state_glow')
    for x in [-.26,.26]:
        m.cylinder((x,-.09,.58),.055,.16,'cream',sides=8)
    roof(m,1.12,.87,1.23,'roof_teal',.31)
    m.cylinder((0,0,1.61),.075,.12,'brass',sides=8)


def weather_vane(m):
    m.box((0,0,.075),(.62,.62,.15),'stone_dark')
    m.box((0,0,.22),(.44,.44,.14),'stone')
    m.cylinder((0,0,1.11),.035,1.67,'iron',sides=8)
    for start,end in [((-.31,0,1.36),(.31,0,1.36)),((0,-.31,1.36),(0,.31,1.36))]:
        m.beam(start,end,.025,'brass')
    for x,y in [(-.31,0),(.31,0),(0,-.31),(0,.31)]:
        m.box((x,y,1.36),(.08,.08,.025),'brass',(0,0,math.pi/4))
    m.beam((-.37,0,1.75),(.37,0,1.75),.035,'brass')
    m.box((.35,0,1.75),(.13,.04,.13),'brass',(0,math.pi/4,0))
    m.ellipsoid((-.02,0,1.90),(.30,.07,.21),'brass',sides=8,rings=4)
    m.box((.11,0,2.03),(.09,.06,.17),'brass')
    m.box((.15,0,2.10),(.14,.07,.10),'brass')
    m.box((.24,0,2.08),(.09,.06,.045),'copper')
    m.box((.15,0,2.17),(.10,.055,.06),'rust')
    m.box((-.20,0,2.01),(.11,.06,.28),'brass',(0,-.4,0))
    for x in [-.07,.06]:
        m.beam((x,0,1.87),(x,0,1.76),.018,'iron')
