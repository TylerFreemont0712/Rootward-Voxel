"""One-time deliberate source revisions for the four remaining adopted robots.
Uses the same source-edit tools as Pip/Wick; never replaces an existing v2 source.
"""
import hashlib
import importlib.util
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

HERE=Path(__file__).resolve().parent
spec=importlib.util.spec_from_file_location('robot_source_edit',HERE/'refine_sources.py')
e=importlib.util.module_from_spec(spec)
spec.loader.exec_module(e)


def palette():
    e.M={}
    # These images are native painted material bakes from the first source revision.
    for name,hex_colour in [('cream','F4E4BF'),('teal','167C80')]:
        mat=e.material(name,hex_colour,.08,.42 if name=='cream' else .32)
        texture=bpy.data.images.load(str(HERE/'textures'/(name+'.png')),check_existing=True)
        texture.pack()
        node=mat.node_tree.nodes.new('ShaderNodeTexImage');node.image=texture
        mat.node_tree.links.new(node.outputs['Color'],mat.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
    for args in [('teal_dark','105156',.1,.4,0),('brass','C48A2D',.62,.31,0),('gold','E8AF3F',.6,.26,0),
                 ('ink','242B2B',0,.65,0),('rubber','303638',0,.82,0),('rubber_edge','505354',0,.7,0),
                 ('amber','F6AC28',.06,.24,.18),('eyes','FFF0B4',0,.3,1.1),('paper','F3E7C6',0,.85,0),
                 ('leaf','407545',0,.7,0),('leaf_light','7B9A43',0,.75,0),('flower','F8EACB',0,.7,0),
                 ('soil','60472E',0,.95,0),('terracotta','AE5238',0,.8,0),('wood','976B41',0,.8,0)]:e.material(*args)


def eyes_metadata():
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH' and obj.get('part')=='head' and any(m and m.name.startswith('robot_eyes') for m in obj.data.materials):
            obj['blink_eyes']=True


def base(two=True,r=.13,x=.25,y=.17):
    if two:
        for side,label in [(-1,'l'),(1,'r')]:e.wheel('wheel_'+label,(side*x,0,r),r,.09,'wheel_fl' if side<0 else 'wheel_fr')
        e.wheel('wheel_c',(0,y+.03,.052),.052,.042)
    else:
        for name,sx,sy in [('fl',-1,-1),('fr',1,-1),('bl',-1,1),('br',1,1)]:e.wheel('wheel_'+name,(sx*x,sy*y,r),r,.075)
    e.box('Low teal chassis',(0,0,r+.045),(x*1.8,y*2+.08,.10),'teal',.04)
    e.tube('Solid axle',(-x,0,r),(x,0,r),.025,'brass')


def rear_cover(z,y,width=.18,height=.18,colour='teal'):
    e.box('Rear service gasket',(0,y,z),(width+.025,.018,height+.025),'ink',.018)
    e.box('Rear service cover',(0,y+.012,z),(width,.017,height),colour,.014)
    for dz in [-.035,0,.035]:e.box('Recessed ventilation slot',(0,y+.023,z+dz),(width*.55,.006,.010),'ink',.004)
    e.screws((0,0,z),width*.78,height*.76,y+.025)
    for dz in [-height*.25,height*.25]:e.box('Small service hinge',(width*.56,y+.018,z+dz),(.015,.028,.038),'brass',.005)


def foliage(at,size=.1,flowers=True):
    x,y,z=at
    for i in range(7):
        a=i*math.tau/7
        leaf=e.sphere('Rounded leaf',(x+math.cos(a)*size*.55,y+math.sin(a)*size*.55,z+.015+(i%3)*.012),(size*.27,size*.15,size*.39),'leaf' if i%2 else 'leaf_light','plants')
        leaf.rotation_euler=(math.sin(a)*.7,math.cos(a)*.7,a)
    if flowers:
        for i in range(5):
            a=i*math.tau/5
            e.sphere('Daisy petal',(x+math.cos(a)*.019,y+math.sin(a)*.019,z+.055),(.014,.010,.006),'flower','plants')
        e.sphere('Daisy heart',(x,y,z+.06),(.008,.008,.005),'gold','plants')


def trowel():
    base(True,.135,.25,.15)
    e.sphere('Rounded watering-can body',(0,0,.46),(.262,.235,.262),'cream')
    e.lathe('Teal lower bowl',(0,0,0),[(.23,.18,.17),(.26,.235,.213),(.33,.25,.227)],'teal')
    e.lathe('Small watering-can lid',(0,0,0),[(.678,.18,.17),(.695,.192,.177),(.735,.11,.10),(.747,.04,.04)],'teal')
    e.face(.482,-.224,.135)
    e.curve('Arched carrying handle',[(-.12,0,.70),(-.09,0,.83),(.04,0,.85),(.14,0,.73)],.022,'brass')
    # The pouring arm stays on the robot's own RIGHT (-X), opposite its mitten.
    a=(-.23,-.01,.46);b=(-.38,-.01,.58);c=(-.47,-.01,.74)
    e.sphere('Spout shoulder',a,(.060,.06,.06),'brass')
    e.tube('Cream tapered spout',a,b,.057,'cream',radius_end=.048)
    e.tube('Rising spout',b,c,.048,'cream',radius_end=.035)
    end=Vector(c)+Vector((-.035,0,.065))
    rose=e.tube('Teal rose socket',c,end,.043,'teal',radius_end=.073)
    normal=(end-Vector(c)).normalized(); tip=end+normal*.012
    e.tube('Perforated brass rose',end,tip,.078,'brass')
    tangent=Vector((0,1,0));other=normal.cross(tangent).normalized()
    for i in range(7):
        angle=math.tau*i/6
        point=tip+(tangent*math.cos(angle)+other*math.sin(angle))*(.041 if i<6 else 0)
        e.sphere('Rose watering hole',point,(.006,.006,.006),'ink')
    e.arm(1,(.25,0,.49),(.34,-.07,.38),(.32,-.19,.34),'cream')
    e.lathe('Open terracotta plant pot',(.03,.185,0),[(.707,.078,.078),(.87,.116,.116),(.892,.118,.118),(.892,.102,.102),(.85,.10,.10)],'terracotta','plants')
    e.tube('Pot soil',(.03,.185,.84),(.03,.185,.846),.097,'soil','plants')
    for dx,dy,dz in [(-.045,0,.89),(.05,.02,.9),(0,-.04,.92)]:foliage((.03+dx,.185+dy,dz),.12)
    for at in [(-.17,.15,.76),(.13,.17,.72),(.15,.20,.61)]:foliage(at,.065,False)
    rear_cover(.48,.228,.17,.16,'cream')


def beam(name,a,b,width,depth,mat='teal'):
    av,bv=Vector(a),Vector(b)
    obj=e.box(name,(av+bv)/2,(width,depth,(bv-av).length),mat,.012,'crane')
    obj.rotation_euler=(bv-av).to_track_quat('Z','Y').to_euler()
    return obj


def heron():
    base(False,.125,.285,.20)
    e.box('Cream crane bumper',(0,0,.29),(.66,.55,.12),'cream',.035)
    # Flush diagonal enamel bands on the front and back of the solid bumper.
    for side in [-1,1]:
        for x in [-.22,-.04,.14]:
            vertices=[(x,side*.278,.236),(x+.085,side*.278,.236),(x+.15,side*.278,.344),(x+.065,side*.278,.344)]
            mesh=bpy.data.meshes.new('Enamel diagonal');mesh.from_pydata(vertices,[],[(0,1,2,3)]);mesh.uv_layers.new()
            obj=bpy.data.objects.new('Bumper safety stripe',mesh);bpy.context.scene.collection.objects.link(obj);e.finish(obj,obj.name,'teal')
    e.lathe('Round cream crane cabin',(0,0,0),[(.34,.245,.225),(.42,.267,.245),(.66,.251,.23),(.72,.22,.20)],'cream')
    e.face(.548,-.239,.125)
    e.lathe('Teal crane turret cap',(0,0,0),[(.701,.225,.21),(.73,.23,.215),(.79,.16,.14),(.82,.075,.065)],'teal')
    for side in [-1,1]:
        e.tube('Winch brass side drum',(side*.26,.025,.555),(side*.315,.025,.555),.092,'brass','crane')
        e.torus('Winch dark belt',(side*.292,.025,.555),.083,.018,'teal_dark','X','crane')
        e.sphere('Winch axle cap',(side*.326,.025,.555),(.015,.062,.062),'gold','crane')
    a,b,c=(0,.10,.78),(0,-.08,1.06),(0,-.47,1.435)
    beam('Lower articulated boom',a,b,.12,.085)
    beam('Long crane boom',b,c,.11,.085)
    for point in [a,b,c]:
        for side in [-1,1]:
            e.tube('Boom brass hinge',(side*.045,point[1],point[2]),(side*.073,point[1],point[2]),.065,'brass','crane')
            e.sphere('Teal hinge cap',(side*.077,point[1],point[2]),(.011,.031,.031),'teal','crane')
    e.curve('Lift cable',[(-.29,.045,.63),(-.09,.055,.95),(-.07,-.08,1.1),(-.07,-.47,1.465)],.006,'ink','crane')
    for x in [-.022,.022]:e.tube('Hanging hoist cable',(x,-.47,1.43),(x,-.47,1.02),.006,'ink','crane')
    e.box('Rounded hoist block',(0,-.47,.991),(.09,.075,.105),'brass',.018,'crane')
    for x in [-.028,.028]:
        for z in [.958,1.023]:e.sphere('Hoist block rivet',(x,-.513,z),(.008,.006,.008),'gold','crane')
    e.curve('Rounded brass hook',[(0,-.47,.94),(.0,-.47,.86),(.0,-.43,.825),(.0,-.385,.865)],.014,'brass','crane')
    rear_cover(.545,.239,.17,.16)
    for x in [-.18,.18]:
        for z in [.44,.66]:e.sphere('Cabin rivet',(x,-.192,z),(.008,.008,.008),'brass')


def tender():
    base(False,.105,.27,.17)
    e.sphere('Low rounded maintenance shell',(0,0,.39),(.333,.307,.29),'cream')
    e.lathe('Teal maintenance rim',(0,0,0),[(.24,.292,.27),(.28,.313,.287),(.31,.316,.29)],'teal')
    e.face(.435,-.286,.142)
    e.lathe('Teal service roof',(0,.025,0),[(.595,.205,.19),(.62,.22,.2),(.669,.15,.135),(.685,.06,.05)],'teal')
    e.curve('Top carrying handle',[(-.085,.01,.665),(-.06,.01,.73),(.06,.01,.73),(.085,.01,.665)],.018,'brass')
    for side in [-1,1]:
        e.arm(side,(side*.305,-.025,.43),(side*.355,-.15,.33),(side*.265,-.265,.305),'cream')
    rear_cover(.414,.293,.205,.19,'cream')
    e.torus('Rear tow ring',(0,.315,.22),.031,.008,'brass','Y')
    # User-selected physical RIGHT is -X when facing Blender -Y; moss stays rear-right.
    for at in [(-.125,.12,.66),(-.18,.17,.64),(-.225,.18,.59),(-.17,.22,.565)]:foliage(at,.075)
    e.tube('Own right service coupling',(-.30,.075,.43),(-.344,.075,.43),.034,'brass')
    e.torus('Coupling outer ring',(-.349,.075,.43),.032,.007,'gold','X')


def tally():
    # Keep the existing l/r/c object names for this adopted three-wheel chassis.
    for side,label in [(-1,'l'),(1,'r')]:e.wheel('wheel_'+label,(side*.25,0,.15),.15,.09)
    e.wheel('wheel_c',(0,.19,.054),.054,.043)
    e.box('Teal till chassis',(0,0,.24),(.45,.38,.13),'teal',.045)
    e.box('Rounded cream cashbox',(0,0,.558),(.47,.405,.61),'cream',.087)
    e.lathe('Domed teal till lid',(0,0,0),[(.837,.247,.217),(.86,.26,.228),(.917,.20,.177),(.96,.08,.07),(.964,.025,.021)],'teal',exponent=.78)
    e.lathe('Brass lid bead',(0,0,0),[(.837,.251,.220),(.847,.254,.223)],'brass',exponent=.78)
    e.sphere('Till cap finial',(0,0,1.005),(.036,.036,.036),'gold')
    e.face(.677,-.201,.132)
    for side in [-1,1]:
        e.tube('Round brass ear',(side*.23,0,.68),(side*.267,0,.68),.059,'brass')
        e.sphere('Ear cap',(side*.274,0,.68),(.013,.038,.038),'gold')
        e.arm(side,(side*.235,-.018,.53),(side*.265,-.145,.46),(side*.18,-.304,.458),'cream')
    e.box('Till drawer border',(0,-.205,.318),(.268,.017,.15),'brass',.018)
    e.box('Teal till drawer',(0,-.218,.318),(.245,.022,.125),'teal',.015)
    e.sphere('Drawer pull',(0,-.244,.318),(.018,.014,.018),'gold')
    e.box('Receipt slot',(0,-.211,.531),(.20,.012,.027),'ink',.009)
    e.box('Counting tray',(0,-.349,.433),(.405,.22,.026),'brass',.015,'tray')
    for x in [-.196,.196]:e.box('Tray raised edge',(x,-.349,.456),(.016,.214,.038),'brass',.006,'tray')
    e.box('Tray front lip',(0,-.454,.456),(.40,.016,.038),'brass',.006,'tray')
    for x,y,height in [(-.085,-.35,.015),(-.085,-.35,.030),(.014,-.38,.015),(.085,-.32,.015)]:
        e.tube('Counting coin',(x,y,.449+height-.014),(x,y,.449+height),.037,'gold','tray')
        e.torus('Coin rim',(x,y,.449+height),.031,.0025,'brass',group='tray')
    # A short curved paper receipt over the tray, anchored at the real slot.
    e.curve('Receipt paper edge',[(.055,-.22,.53),(.055,-.255,.548),(.055,-.30,.50),(.055,-.35,.48)],.004,'paper','tray')
    rear_cover(.545,.206,.23,.27)


def main(asset):
    if asset not in {'robot-trowel','robot-heron','robot-tender','robot-tally'}:raise RuntimeError('Only the four requested adopted robots may be revised.')
    source=e.ROOT/'art/source/world'/asset/'v1/model.blend';output=source.parent.parent/'v2/model.blend'
    if output.exists():raise RuntimeError('New source already exists. Open v2 model.blend instead of rerunning the edit.')
    bpy.ops.wm.open_mainfile(filepath=str(source))
    e.ROOT_OBJECT=next(obj for obj in bpy.context.scene.objects if obj.type=='EMPTY' and obj.parent is None)
    for obj in list(bpy.context.scene.objects):
        if obj==e.ROOT_OBJECT:continue
        keep=obj.type=='MESH' and obj.name.startswith('wheel')
        if asset=='robot-trowel':keep=keep and obj.name.startswith(('wheel_fl','wheel_fr'))
        if not keep:bpy.data.objects.remove(obj,do_unlink=True)
    palette()
    {'robot-trowel':trowel,'robot-heron':heron,'robot-tender':tender,'robot-tally':tally}[asset]()
    e.consolidate();eyes_metadata()
    bpy.context.scene['rootward_source']='Editable adopted v2 robot source after the approved concept; original source and pivots preserved.'
    bpy.context.scene['concept_reference']='docs/concept/v0.72/art/robots/'+asset.removeprefix('robot-')+'-sheet.png'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all();output.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(output))
    (output.parent/'provenance.json').write_text(json.dumps({'asset':asset,'date':'2026-10-29','previous_source':str(source.relative_to(e.ROOT)),'previous_source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source':str(output.relative_to(e.ROOT)),'source_sha256':hashlib.sha256(output.read_bytes()).hexdigest(),'edit_record':str(Path(__file__).relative_to(e.ROOT)),'edit_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'helper':str((HERE/'refine_sources.py').relative_to(e.ROOT)),'helper_sha256':hashlib.sha256((HERE/'refine_sources.py').read_bytes()).hexdigest(),'note':'Deliberate native geometry refinement preserving adopted root/wheel objects; further edits use the saved source.'},indent=2)+'\n')


if __name__=='__main__':
    for asset in sys.argv[sys.argv.index('--')+1:]:main(asset)
