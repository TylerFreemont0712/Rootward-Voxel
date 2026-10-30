"""Guarded first authoring of three household additions, never existing masters."""
from pathlib import Path
import importlib.util
import hashlib
import json
import math
import bpy

HERE = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('workshop_helpers', HERE / 'author.py')
w = importlib.util.module_from_spec(spec)
spec.loader.exec_module(w)


def bread_cupboard():
    for x in (-.78, .78):
        for y in (-.27, .27):
            w.wood('Cupboard short foot', (x,y,.10), (.12,.12,.20), 'wood_dark')
    w.wood('Bread cupboard carcass', (0,0,.49), (1.74,.70,.70), 'wood_dark')
    for x in (-.88,.88):
        w.wood('Cupboard corner stile', (x,0,.48), (.10,.72,.77), 'oak')
    for x in (-.43,.43):
        w.wood('Framed cupboard door', (x,-.366,.46), (.80,.055,.56), 'oak', .018)
        w.wood('Recessed cupboard panel', (x,-.398,.46), (.60,.018,.37), 'wood', .015)
        w.S('Worn brass cupboard knob', (x+(.23 if x<0 else -.23),-.425,.54), (.029,.029,.029), 'brass')
    w.wood('Food preparation worktop', (0,-.005,.86), (1.95,.80,.12), 'bench', .03)
    # A real open tin: bottom, separate walls, rolled lip and a hinged lid.
    tx,ty,tz = -.40,.10,.925
    w.B('Bread tin enamel bottom', (tx,ty,tz+.018), (.88,.48,.036), 'teal_light', .018)
    for x in (-.44,.44):
        w.B('Bread tin enamel end', (tx+x,ty,tz+.16), (.035,.48,.31), 'teal', .025, 3)
    for y in (-.24,.24):
        w.B('Bread tin enamel wall', (tx,ty+y,tz+.16), (.89,.035,.31), 'teal', .025, 3)
    for x in (-.445,.445):
        w.R('Tin rolled lip', (tx+x,ty-.24,tz+.32), (tx+x,ty+.24,tz+.32), .012, 'cream')
    for y in (-.24,.24):
        w.R('Tin rolled lip', (tx-.445,ty+y,tz+.32), (tx+.445,ty+y,tz+.32), .012, 'cream')
    angle=math.radians(68)
    lid=w.B('Raised hinged bread tin lid', (tx,ty+.24-.25*math.cos(angle),tz+.32+.25*math.sin(angle)), (.93,.50,.035), 'teal_light', .026, 3)
    lid.rotation_euler.x=-angle
    for x in (-.27,.27):
        w.R('Bread tin hinge', (tx+x-.055,ty+.25,tz+.32), (tx+x+.055,ty+.25,tz+.32), .022, 'brass')
    w.B('Bread tin label plate', (tx,ty-.263,tz+.17), (.52,.012,.14), 'cream', .016, 3)
    bpy.ops.object.text_add(location=(tx,ty-.272,tz+.128), rotation=(math.pi/2,0,0))
    text=bpy.context.object
    text.name='Bread tin lettering'
    text.data.body='BREAD'; text.data.align_x='CENTER'; text.data.size=.102
    text.data.extrude=.0005
    bpy.ops.object.convert(target='MESH');w.h.put(bpy.context.object,'ink')
    # Raised scored loaf peeks above the open rim, with breakfast already cut.
    w.h.material('bread_crust','bb8248');w.M['bread_crust'].name='workshop_bread_crust'
    w.h.material('bread_crumb','e3cda0');w.M['bread_crumb'].name='workshop_bread_crumb'
    w.S('Golden loaf in open tin', (tx,ty,tz+.28), (.35,.19,.22), 'bread_crust', 32,16)
    for x in (-.20,0,.20):
        w.Q('Loaf scoring', [(tx+x-.04,ty-.15,tz+.40),(tx+x,ty,tz+.498),(tx+x+.04,ty+.14,tz+.42)], .009,'bread_crumb')
    board=w.wood('Used chopping board', (.50,-.13,.94), (.58,.40,.035), 'wood_edge', .035)
    board.rotation_euler.z=-.08
    for x in (.35,.50):
        crust=w.S('Cut bread crust', (x,-.15,.986), (.12,.14,.037), 'bread_crust',20,10)
        w.S('Soft cut bread face', (x,-.15,1.018), (.10,.119,.009), 'bread_crumb',20,8)
    w.B('Bread knife blade', (.71,-.13,.97), (.034,.28,.009), 'steel_light', .008)
    w.B('Bread knife wooden handle', (.71,.08,.982), (.056,.17,.036), 'wood_dark', .02)
    for x,y in ((.24,-.30),(.39,-.34),(.61,-.28),(.48,-.36)):
        w.S('Breakfast crumb', (x,y,.965), (.009,.012,.006), 'bread_crumb',8,6)
    # A narrow linen tea towel hangs from a rail at the cupboard end; no machine covers.
    w.R('Cupboard end towel rail', (.98,-.17,.63), (.98,.18,.63), .016, 'brass')


def trolley():
    for x in (-.45,.45):
        for y in (-.27,.27):
            w.R('Trolley caster fork', (x,y,.08), (x,y,.20), .025, 'steel')
            wheel=w.C('Rubber trolley wheel', (x,y,.08), .08,.055,'rubber',20)
            wheel.rotation_euler.x=math.pi/2
            w.S('Caster hub', (x,y-.033,.08), (.026,.010,.026), 'steel_light')
            w.wood('Trolley corner upright', (x,y,.48), (.06,.06,.64), 'wood_dark', .014)
    for z in (.22,.72):
        w.wood('Service trolley shelf', (0,0,z), (1.08,.72,.065), 'bench', .018)
        for y in (-.34,.34): w.wood('Trolley shelf retaining edge', (0,y,z+.06), (1.08,.035,.10), 'oak', .01)
    w.Q('Trolley push handle', [(-.49,.29,.74),(-.49,.43,.91),(.49,.43,.91),(.49,.29,.74)], .025,'steel_dark')
    w.parts_tray((-.15,-.02,.76),(.53,.40))
    w.C('Refillable oil can', (.34,.05,.88), .115,.24,'red',24,.075)
    w.C('Oil can lid', (.34,.05,1.01), .073,.024,'brass',20)
    w.Q('Oil can curved spout', [(.36,.05,1.01),(.47,.05,1.08),(.56,.05,1.16)], .017,'brass')
    w.h.book((-.17,.02,.27),(.56,.44,.08),'blue',.06)
    w.h.book((-.12,.02,.35),(.51,.40,.07),'red',-.09)
    w.C('Spare wire spool', (.35,.06,.36), .12,.19,'wood_edge',20)
    for z in (.27,.45):w.C('Wire spool end', (.35,.06,z), .15,.028,'wood_dark',20)
    for z in (.30,.33,.36,.39,.42):w.T('Coiled copper wire', (.35,.06,z), .12,.009,'brass')


def clock():
    body=w.C('Round oak clock case', (0,0,0), .34,.12,'wood_dark',48)
    body.rotation_euler.x=math.pi/2
    face=w.C('Cream clock dial', (0,-.069,0), .295,.015,'paper',48)
    face.rotation_euler.x=math.pi/2
    w.T('Clock brass bezel', (0,-.082,0), .305,.017,'brass',(math.pi/2,0,0))
    for n in range(12):
        a=n*math.tau/12
        w.R('Clock hour marker', (math.sin(a)*.248,-.083,math.cos(a)*.248), (math.sin(a)*.275,-.083,math.cos(a)*.275), .007,'ink')
    for a,length,width in ((math.radians(305),.145,.013),(math.radians(60),.215,.009)):
        w.R('Clock hand', (0,-.101,0), (math.sin(a)*length,-.101,math.cos(a)*length), width,'steel_dark')
    w.S('Clock hand pin', (0,-.11,0), (.022,.012,.022),'brass')


BUILDERS={'workshop-bread-cupboard':bread_cupboard,'workshop-service-trolley':trolley,'workshop-wall-clock':clock}
if __name__=='__main__':
    for asset in BUILDERS:
        if (w.ROOT/'art/source/world'/asset/'v1/model.blend').exists():
            raise RuntimeError('Existing master; deliberately edit it instead: '+asset)
    for asset,make in BUILDERS.items():
        w.start(asset);make();w.save(asset)
        path=w.ROOT/'art/source/world'/asset/'v1/provenance.json'
        record=json.loads(path.read_text())
        record.update(record=str(Path(__file__).relative_to(w.ROOT)),record_sha256=hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),purpose='Smaller downstairs furniture, household breakfast continuity and useful repair storage.')
        path.write_text(json.dumps(record,indent=2)+'\n')
