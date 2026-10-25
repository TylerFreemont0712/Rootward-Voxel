"""Ten rural garden/farm objects. Shelters are scenery; the library does not invent livestock AI."""
import math
from modeling import legs, roof


def straw_beehive(m):
    legs(m,.65,.65,.30,thickness=.09)
    m.box((0,0,.32),(.80,.77,.07),'wood_dark')
    for i in range(9):
        z=.39+i*.075
        radius=.32*math.sqrt(max(.05,1-(i/9)**2))
        m.cylinder((0,0,z),radius,.08,'hay' if i%2 else 'hay_light',sides=12,top=radius*.96)
    m.box((0,-.31,.48),(.14,.025,.11),'wood_dark')
    m.box((0,-.37,.40),(.22,.23,.045),'oak')
    m.cylinder((0,0,1.07),.08,.055,'hay_light',sides=8,top=.04)


def rabbit_hutch(m):
    legs(m,1.24,.57,.45,thickness=.11)
    m.box((0,0,.46),(1.36,.68,.10),'oak')
    m.box((0,.28,.81),(1.34,.09,.62),'wood')
    for x in [-.64,.64]:
        m.box((x,0,.81),(.08,.62,.61),'oak')
    m.box((.28,0,.79),(.55,.60,.56),'wood_dark')
    m.box((.28,-.31,.80),(.49,.05,.48),'oak')
    m.box((.28,-.344,.75),(.22,.02,.25),'wood_dark')
    m.box((-.30,-.31,.80),(.56,.06,.56),'oak_light')
    m.box((-.30,-.35,.80),(.45,.015,.44),'wood_dark')
    for x in [-.48,-.36,-.24,-.12]:
        m.box((x,-.37,.80),(.013,.018,.41),'silver')
    for z in [.65,.77,.89]:
        m.box((-.30,-.38,z),(.43,.012,.012),'silver')
    roof(m,1.46,.79,1.10,'roof_teal',.18)
    m.box((-.37,.07,.55),(.30,.28,.06),'hay')
    m.bowl((-.15,-.10,.52),.09,'clay')


def chicken_coop(m):
    legs(m,1.32,.95,.28,thickness=.13)
    m.box((0,.08,.36),(1.41,1.03,.16),'wood_dark')
    m.box((0,.09,.83),(1.34,.96,.86),'oak')
    for x in [-.61,.61]:
        m.box((x,-.43,.84),(.11,.09,.86),'wood_dark')
    m.box((-.21,-.412,.78),(.42,.035,.53),'wood_dark')
    m.box((.39,-.432,.98),(.32,.035,.27),'glass_blue')
    for x in [.21,.57]:
        m.box((x,-.46,.98),(.07,.05,.33),'cloth_teal')
    m.box((.39,-.46,.98),(.025,.05,.28),'wood_dark')
    roof(m,1.57,1.23,1.26,'roof',.38)
    m.box((.44,.10,.48),(.50,.73,.24),'wood')
    m.box((.45,.10,.63),(.55,.77,.075),'roof_teal')
    m.box((-.21,-.66,.23),(.37,.60,.055),'oak',(-.55,0,0))
    for y in [-.84,-.70,-.56]:
        z=.12+(y+.84)*.56
        m.box((-.21,y,z+.06),(.40,.05,.04),'wood_dark')


def seedling_tray(m):
    m.box((0,0,.055),(1.08,.58,.11),'wood_dark')
    m.box((0,0,.13),(.99,.49,.09),'soil')
    for x in [-.52,.52]:
        m.box((x,0,.17),(.065,.60,.19),'oak')
    for y in [-.27,.27]:
        m.box((0,y,.17),(1.08,.06,.19),'oak_light')
    for x in [-.33,0,.33]:
        for y in [-.13,.13]:
            m.beam((x,y,.17),(x,y,.40),.018,'leaf_dark')
            m.leaf((x-.06,y,.29),.18,'leaf_light')
            m.leaf((x+.055,y,.36),.17,'leaf')
    for x in [-.35,.32]:
        m.beam((x,.23,.16),(x,.23,.45),.024,'wood')
        m.box((x,.23,.45),(.14,.027,.08),'cream')


def herb_drying_rack(m):
    for x in [-.54,.54]:
        m.box((x,0,.055),(.22,.61,.11),'wood_dark')
        m.box((x,.05,.76),(.09,.09,1.45),'oak')
    m.box((0,.05,1.45),(1.28,.10,.10),'oak_light')
    m.beam((-.54,.22,.14),(.54,.22,1.34),.045,'wood')
    for i,x in enumerate([-.38,-.13,.13,.38]):
        m.beam((x,.02,1.38),(x,.02,1.12),.014,'linen')
        for j in range(5):
            dx=(j-2)*.035
            m.beam((x,.02,1.15),(x+dx,.02,.85-.02*(j%2)),.016,'leaf_dark')
            m.ellipsoid((x+dx,.02,.92),(.075,.07,.23),'leaf' if i%2 else 'cloth_lilac',sides=6,rings=3)
        m.ring((x,.02,1.12),.045,.032,.035,'linen',sides=8)
    for x in [-.30,.30]:
        m.cylinder((x,0,.16),.20,.32,'oak',sides=10,top=.24)
        for z in [.06,.14,.22,.30]:
            m.ring((x,0,z),.21+(z-.06)*.12,.19+(z-.06)*.12,.022,'oak_light',sides=10)


def vine_trellis(m):
    m.box((0,0,.14),(1.48,.53,.28),'stone')
    m.box((0,0,.29),(1.34,.40,.04),'soil')
    for x in [-.62,.62]:
        m.box((x,.12,1.02),(.085,.085,1.64),'wood_dark')
    for z in [.65,1.13,1.66]:
        m.box((0,.12,z),(1.40,.06,.06),'oak')
    for x in [-.46,0,.46]:
        m.beam((x-.15,.12,.34),(x+.13,.12,1.66),.035,'oak_light')
        m.beam((x+.15,.13,.34),(x-.13,.13,1.66),.035,'oak_light')
    for i in range(14):
        x=-.60+i*.09
        z=.57+(.47*math.sin(i*.71)+.48)
        m.beam((x,.01,.30),(x,.01,z),.023,'leaf_dark')
        for dz in [0,.13]:
            m.leaf((x-.04,-.025,z+dz),.21,'leaf' if i%2 else 'leaf_light')
        if i%3==0:
            for dx,dz in [(-.025,0),(.025,0),(0,-.05)]:
                m.ellipsoid((x+dx,-.10,z-.14+dz),(.07,.07,.07),'cloth_plum',sides=6,rings=3)


def field_scarecrow(m):
    m.box((0,0,.36),(.12,.12,.72),'wood_dark')
    m.box((0,0,.06),(.58,.44,.12),'stone_dark')
    m.beam((-.48,0,1.10),(.48,0,1.10),.075,'wood')
    m.box((0,0,.99),(.40,.23,.43),'rust')
    m.box((0,-.13,1.10),(.43,.055,.12),'cloth_teal')
    m.box((.17,-.14,.91),(.10,.045,.36),'cloth_teal',(.1,-.12,0))
    for x in [-.34,.34]:
        m.box((x,0,1.10),(.27,.20,.18),'rust')
        for dz in [-.035,.035]:
            m.beam((x*1.26,0,1.10+dz),(x*1.49,0,1.10+dz),.025,'hay')
    m.ellipsoid((0,0,1.37),(.30,.25,.32),'linen',sides=8,rings=4)
    for x in [-.06,.06]:
        m.box((x,-.126,1.40),(.03,.012,.03),'wood_dark')
    m.beam((-.06,-.132,1.30),(.06,-.132,1.28),.015,'wood_dark')
    m.cylinder((0,0,1.53),.26,.055,'hay',sides=10)
    m.cylinder((0,0,1.63),.15,.18,'hay_light',sides=10,top=.11)
    m.ring((0,0,1.57),.154,.14,.055,'cloth_plum',sides=10)


def rain_barrel(m):
    m.cylinder((0,0,.42),.33,.84,'wood',sides=12,top=.38)
    for z,r in [(.09,.345),(.39,.368),(.74,.39)]:
        m.ring((0,0,z),r,r-.035,.06,'iron',sides=12)
    m.cylinder((0,0,.87),.395,.055,'oak',sides=12)
    m.box((0,0,.907),(.74,.055,.025),'wood_dark')
    m.beam((.27,.26,.85),(.27,.26,1.48),.08,'copper')
    m.beam((.27,.26,1.48),(.13,.26,1.48),.08,'copper')
    m.cylinder((0,-.38,.31),.055,.19,'brass',axis='Y',sides=8)
    m.beam((0,-.48,.31),(0,-.48,.25),.065,'brass')
    m.beam((-.09,-.40,.40),(.09,-.40,.40),.035,'iron')


def butter_churn(m):
    m.cylinder((0,0,.37),.23,.74,'oak',sides=10,top=.20)
    for z,r in [(.07,.235),(.38,.22),(.67,.207)]:
        m.ring((0,0,z),r,r-.025,.045,'iron',sides=10)
    m.cylinder((0,0,.76),.22,.06,'oak_light',sides=10)
    m.cylinder((0,0,1.0),.035,.48,'wood_dark',sides=8)
    m.beam((-.14,0,1.22),(.14,0,1.22),.055,'oak_light')
    m.box((.17,-.07,.68),(.20,.29,.025),'linen',(.35,.3,0))


def hay_handcart(m):
    m.box((0,0,.40),(1.05,1.32,.15),'wood_dark')
    for x in [-.56,.56]:
        m.wheel((x,.10,.33),.33,'X',8)
        m.box((x*.86,0,.63),(.07,1.4,.37),'oak')
        for y in [-.56,0,.56]:
            m.box((x*.86,y,.82),(.07,.07,.49),'wood_dark')
    m.box((0,.63,.65),(1.01,.07,.37),'oak')
    for x in [-.26,.26]:
        for y in [-.34,.25]:
            m.box((x,y,.77),(.47,.52,.43),'hay')
            for z in [.60,.69,.78,.87,.95]:
                m.box((x,y-.265,z),(.43,.015,.018),'hay_light')
            m.box((x,y,1.0),(.045,.54,.035),'linen')
    m.box((0,0,1.16),(.71,.68,.29),'hay_light')
    m.box((0,0,1.31),(.045,.69,.025),'linen')
    for x in [-.34,.34]:
        m.beam((x,-.59,.42),(x,-.97,.22),.07,'wood')
    m.beam((-.34,-.97,.22),(.34,-.97,.22),.07,'oak')
    m.beam((.30,.43,.80),(.30,.43,1.65),.035,'oak')
    for x in [.22,.30,.38]:
        m.beam((x,.43,1.58),(x,.43,1.80),.025,'wood_dark')
