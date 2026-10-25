"""Ten market and household arrangements, shaped separately rather than dressed copies of a box."""
import math
from modeling import legs, tabletop, roof, flame


def counter(m,w,d,h=.72):
    legs(m,w-.1,d-.1,h-.10,thickness=.10)
    tabletop(m,w,d,h,4)
    for i in range(7):
        m.box((-(w-.08)*.5+(i+.5)*(w-.08)/7,-d*.5+.045,.42),((w-.08)/7-.012,.07,.44),'oak' if i%2 else 'oak_light')


def loaf(m,x,y,z,long=False):
    m.ellipsoid((x,y,z+.075),(.38 if long else .22,.12 if long else .20,.15),'bread',sides=10,rings=4)
    for dx in ([-.10,0,.10] if long else [-.04,.04]):
        m.box((x+dx,y,z+.148),(.018,.08,.008),'bread_light',(0,0,.3))


def bakers_oven(m):
    m.box((0,.12,.12),(1.45,1.12,.24),'stone_dark')
    m.box((0,.17,.49),(1.38,1.04,.51),'stone_light')
    m.box((0,-.367,.50),(.94,.03,.34),'wood_dark')
    for i in range(3):
        m.cylinder((-.32+i*.31,-.31,.47),.075,.68,'wood',axis='Y',sides=8)
    m.box((0,.14,.80),(1.52,1.15,.14),'stone')
    m.box((0,.20,1.13),(1.29,.98,.60),'plaster')
    m.box((0,-.304,1.10),(.74,.025,.46),'wood_dark')
    for x in [-.48,.48]:
        m.box((x,-.34,1.05),(.18,.13,.45),'stone_light')
    for x,z in [(-.30,1.34),(0,1.40),(.30,1.34)]:
        m.box((x,-.34,z),(.28,.14,.16),'stone_light',(0,-x*.75,0))
    for x in [-.22,.02,.23]:
        flame(m,(x,-.26,.92),.32)
    m.box((0,-.48,.86),(1.12,.26,.10),'stone_light')
    roof(m,1.54,1.20,1.42,'roof',.26)
    m.box((.43,.40,1.73),(.25,.26,.45),'stone')
    m.box((.43,.40,1.97),(.34,.34,.08),'stone_dark')


def bread_display(m):
    counter(m,1.45,.70)
    m.box((-.28,-.02,.79),(.73,.55,.07),'wood_dark')
    for x in [-.50,-.25,0]:
        for y in [-.16,.06]:
            loaf(m,x,y,.82)
    for i in range(3):
        loaf(m,.38,-.13+i*.16,.80,True)
    m.box((0,.26,.99),(1.42,.07,.24),'oak')
    m.box((-.40,-.39,.52),(.30,.025,.14),'cream')
    m.box((-.40,-.41,.52),(.19,.012,.018),'wood')


def cheese_stand(m):
    counter(m,1.25,.70)
    for x in [-.55,.55]:
        m.box((x,.22,1.19),(.07,.08,.94),'wood_dark')
    for i in range(6):
        m.box((-.61+(i+.5)*1.22/6,0,1.68),(1.22/6-.008,.87,.075),'cream' if i%2 else 'cloth_teal',(.12,0,0))
        m.box((-.61+(i+.5)*1.22/6,-.43,1.57),(1.22/6-.008,.04,.15),'cream' if i%2 else 'cloth_teal')
    for x,y,r in [(-.32,.03,.23),(.24,.09,.18),(.30,-.21,.14)]:
        m.cylinder((x,y,.82),r,.14,'cheese',sides=12)
        m.ring((x,y,.895),r,r-.025,.017,'bread',sides=12)
    m.box((-.25,-.20,.91),(.22,.16,.12),'cheese',(0,0,.25))
    for x,y in [(-.31,-.23),(-.21,-.17),(-.28,-.14)]:
        m.cylinder((x,y,.973),.014,.004,'bread',sides=6)


def fishmongers_counter(m):
    counter(m,1.55,.80,.77)
    m.box((0,0,.83),(1.44,.70,.06),'cloth_teal')
    for y in [-.33,.33]:
        m.box((0,y,.90),(1.47,.055,.12),'wood_dark')
    for x in [-.46,0,.46]:
        m.ellipsoid((x,-.02,.94),(.35,.16,.12),'silver',sides=10,rings=4)
        m.box((x+.19,-.02,.95),(.12,.20,.025),'glass_blue',(0,0,.2))
        m.box((x-.11,-.102,.96),(.024,.012,.024),'iron')
        m.beam((x-.07,-.01,1.0),(x+.07,-.01,1.0),.015,'glass_blue')
    m.cylinder((-.42,.03,.19),.18,.36,'wood',sides=10,top=.22)
    for z in [.04,.30]:
        m.ring((-.42,.03,z),.21,.18,.045,'iron')


def spice_cart(m):
    m.box((0,0,.43),(1.26,.74,.15),'wood_dark')
    for y in [-.28,.28]:
        m.beam((-.67,y,.32),(.67,y,.32),.09,'iron')
    for x in [-.65,.65]:
        for y in [-.28,.28]:
            m.wheel((x,y,.28),.28,'X',6)
    counter(m,1.40,.75,.76)
    for x in [-.62,.62]:
        m.box((x,.22,1.22),(.07,.08,1.05),'oak')
    for i in range(7):
        m.box((-.73+(i+.5)*1.46/7,0,1.79),(1.46/7-.006,.97,.07),'cloth_plum' if i%2==0 else 'linen',(.12,0,0))
    for row,y in enumerate([-.18,.11]):
        for col,x in enumerate([-.44,0,.44]):
            m.cylinder((x,y,.87),.13,.15,'clay',sides=10,top=.15)
            m.cylinder((x,y,.95),.13,.02,['rust','cheese','leaf','cloth_plum','bread','clay_light'][(row*3+col)%6],sides=10)


def covered_handcart(m):
    m.box((0,0,.39),(1.08,1.64,.16),'wood_dark')
    for y in [-.52,.52]:
        m.beam((-.59,y,.31),(.59,y,.31),.09,'iron')
    for x in [-.55,.55]:
        for y in [-.52,.52]:
            m.wheel((x,y,.31),.31,'X',8)
    for x in [-.48,.48]:
        m.box((x,0,.71),(.10,1.70,.49),'oak')
    m.box((0,.78,.71),(1.0,.11,.47),'oak')
    for y in [-.68,0,.68]:
        for x in [-.48,.48]:
            m.beam((x,y,.92),(x*.67,y,1.31),.045,'wood')
            m.beam((x*.67,y,1.31),(0,y,1.43),.045,'wood')
    for i,(x,z,sx,sz) in enumerate([(-.43,1.11,.24,.47),(-.23,1.35,.36,.20),(0,1.44,.25,.08),(.23,1.35,.36,.20),(.43,1.11,.24,.47)]):
        m.box((x,0,z),(sx,1.70,sz),'cream' if i%2 else 'linen')
    m.beam((-.30,-.76,.43),(-.30,-1.12,.24),.065,'oak')
    m.beam((.30,-.76,.43),(.30,-1.12,.24),.065,'oak')
    m.beam((-.30,-1.12,.24),(.30,-1.12,.24),.07,'wood_dark')


def linen_rack(m):
    for x in [-.48,.48]:
        m.box((x,0,.055),(.22,.53,.11),'wood_dark')
        m.box((x,.05,.72),(.07,.08,1.37),'oak')
    m.box((0,.05,1.39),(1.15,.09,.09),'oak_light')
    m.box((0,.05,.35),(1.10,.12,.09),'wood')
    for x,mat in [(-.28,'linen'),(.25,'cream')]:
        m.box((x,0,1.0),(.36,.055,.74),mat)
        m.box((x,-.05,.65),(.36,.04,.055),'cloth_teal')
    m.box((0,0,.15),(.54,.37,.21),'oak')
    for z in [.12,.17,.22,.27]:
        m.box((0,-.195,z),(.53,.018,.012),'oak_light')
    for z in [.28,.33,.38]:
        m.box((0,0,z),(.44,.30,.045),'cream' if z!=.33 else 'linen')


def pottery_shelf(m):
    for x in [-.56,.56]:
        m.box((x,.14,.86),(.09,.10,1.72),'wood_dark')
    for z in [.10,.61,1.13,1.67]:
        m.box((0,0,z),(1.23,.48,.08),'oak_light')
    for row,z in enumerate([.14,.65,1.17]):
        for i,x in enumerate([-.38,0,.38]):
            if (row+i)%3==0:
                m.bowl((x,-.02,z),.15,'cream')
                m.bowl((x,-.02,z+.08),.14,'linen')
            else:
                m.jug((x,-.01,z),.12,.32+.05*(i%2),'glass_teal' if (row+i)%2 else 'clay')
    m.beam((-.56,.19,.17),(.56,.19,1.55),.04,'wood')


def candle_stand(m):
    m.cylinder((0,0,.045),.27,.09,'brass',sides=10)
    m.cylinder((0,0,.14),.15,.12,'copper',sides=8,top=.07)
    m.cylinder((0,0,.58),.055,.82,'brass',sides=10)
    for x,z in [(-.23,.94),(0,1.16),(.23,.94)]:
        if x:
            m.beam((0,0,.75),(x,0,.85),.047,'brass')
            m.beam((x,0,.85),(x,0,z),.047,'brass')
        m.cylinder((x,0,z),.10,.04,'brass',sides=10)
        m.cylinder((x,0,z+.13),.055,.25,'cream',sides=10)
        m.box((x+.043,-.018,z+.16),(.02,.035,.12),'linen')
        flame(m,(x,0,z+.27),.13)


def copper_wash_tub(m):
    m.cylinder((0,0,.20),.37,.40,'copper',sides=12,top=.49)
    m.ring((0,0,.41),.50,.44,.065,'copper_light',sides=12)
    m.cylinder((0,0,.39),.435,.02,'water',sides=12)
    for x in [-.50,.50]:
        m.ring((x,0,.32),.09,.055,.06,'iron',axis='Y',sides=8)
    m.box((0,.18,.61),(.43,.08,.62),'wood_dark',(-.22,0,0))
    for i in range(7):
        m.box((0,.12-i*.014,.42+i*.065),(.34,.025,.025),'silver',(-.22,0,0))
