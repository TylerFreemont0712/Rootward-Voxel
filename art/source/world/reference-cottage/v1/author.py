"""First original-concept cottage study. One-time source authoring, not a build path.
Refuses an existing model. Later passes edit this saved Blender master deliberately.
Blender Z-up, front -Y; glTF supplies the Godot conversion.
"""
import bpy
import math
import random
import json
import hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path.cwd()
BASE=ROOT/'art/source/world/reference-cottage/v1'
SOURCE=BASE/'model.blend'
if SOURCE.exists():raise RuntimeError('Editable source exists. Edit model.blend; initial authoring never overwrites it.')
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
M={};PART='Structure';rng=random.Random(261028)


def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4


def material(name,colour,texture=None,tint=1.0,rough=.85,metal=0,emission=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    rgb=[linear(int(colour[i:i+2],16)/255) for i in [0,2,4]]
    n.inputs['Base Color'].default_value=(*rgb,1)
    n.inputs['Roughness'].default_value=rough;n.inputs['Metallic'].default_value=metal
    if texture:
        tex=m.node_tree.nodes.new('ShaderNodeTexImage')
        tex.image=bpy.data.images.load(str(ROOT/'assets/world/textures/lush'/f'{texture}.png'),check_existing=True)
        if tint!=1:
            mix=m.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
            mix.inputs[2].default_value=(tint,tint,tint,1)
            m.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);m.node_tree.links.new(mix.outputs[0],n.inputs['Base Color'])
        else:m.node_tree.links.new(tex.outputs['Color'],n.inputs['Base Color'])
    if emission:
        n.inputs['Emission Color'].default_value=(*rgb,1);n.inputs['Emission Strength'].default_value=emission
    M[name]=m


for name,tint in [('study_oak',.86),('study_oak_warm',.73),('study_oak_light',1.03),('study_timber',.40),('study_door_oak',.95)]:
    material(name,'b37c39','reference_honey_oak',tint)
for name,col in [('study_endgrain','aa7336'),('study_endgrain_dark','714721'),('study_mortar','756e5e'),('study_stone','c6bea5'),('study_stone_light','e1d8bf'),('study_stone_warm','b6ad91')]:material(name,col)
for name,tint in [('study_violet',.82),('study_violet_light',1.04),('study_violet_dark',.68)]:
    material(name,'665292','reference_violet_clay',tint,rough=.52)
material('study_tile_edge','aaa0be',rough=.64)
material('study_clay_under','514265')
material('study_iron','34403b',rough=.65,metal=.3)
material('study_brass','bf9342',rough=.42,metal=.45)
material('study_glass','405170',rough=.4)
material('study_glass_light','596b8a',rough=.36)
material('study_window','ffca6b',rough=.7,emission=.25)
material('study_window_light','ffe0a1',rough=.7,emission=.20)
material('study_recess','211b18')
material('study_leaf_dark','365536');material('study_leaf','4c793b');material('study_leaf_light','7f9d45')
material('study_flower','f4efd8');material('study_pollen','e3b447');material('study_soil','43382a')


def uv(o,grain=None,tile=1.35):
    d=o.data;d.update();layer=d.uv_layers.active or d.uv_layers.new(name='UVMap')
    for face in d.polygons:
        normal_axis=max(range(3),key=lambda i:abs(face.normal[i]))
        axes=[i for i in range(3) if i!=normal_axis]
        if grain is not None and grain!=normal_axis:axes=[grain,next(i for i in axes if i!=grain)]
        for li in face.loop_indices:
            co=d.vertices[d.loops[li].vertex_index].co
            layer.data[li].uv=(co[axes[0]]/tile,co[axes[1]]/tile)


def mesh(name,vertices,faces,mat):
    d=bpy.data.meshes.new(name);d.from_pydata(vertices,[],faces);d.materials.append(M[mat]);d.update()
    o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);o['part']=PART
    uv(o);return o


def box(name,at,size,mat,bevel=.025,grain=None,rotation=None):
    x,y,z=[v/2 for v in size]
    o=mesh(name,[(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],
           [(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)],mat)
    o.location=at
    if rotation:o.rotation_euler=rotation
    if bevel:
        bpy.context.view_layer.objects.active=o
        mod=o.modifiers.new('Soft hand-hewn arris','BEVEL');mod.width=bevel;mod.segments=2
        bpy.ops.object.modifier_apply(modifier=mod.name)
    uv(o,grain)
    return o


def beam(name,a,b,width,mat,depth=None):
    a,b=Vector(a),Vector(b)
    o=box(name,(a+b)/2,(width,depth or width,(b-a).length),mat,.018,2)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler();return o


def ring(name,at,outer,inner,depth,mat,n=24,start=0,end=math.tau):
    verts=[]
    for yy in [-depth/2,depth/2]:
        for radius in [inner,outer]:
            for k in range(n+1):
                a=start+(end-start)*k/n
                verts.append((at[0]+radius*math.cos(a),at[1]+yy,at[2]+radius*math.sin(a)))
    h=n+1;faces=[]
    for k in range(n):
        faces.extend([(k,k+1,h+k+1,h+k),(2*h+k,3*h+k,3*h+k+1,2*h+k+1),(k,2*h+k,2*h+k+1,k+1),(h+k,h+k+1,3*h+k+1,3*h+k)])
    faces.extend([(0,h,3*h,2*h),(n,2*h-1,4*h-1,3*h-1)])
    return mesh(name,verts,faces,mat)


def lathe(name,at,profile,mat,n=16):
    verts=[];faces=[]
    for radius,z in profile:
        for j in range(n):
            a=math.tau*j/n
            verts.append((at[0]+radius*math.cos(a),at[1]+radius*math.sin(a),at[2]+z))
    for k in range(len(profile)-1):
        for j in range(n):faces.append((k*n+j,k*n+(j+1)%n,(k+1)*n+(j+1)%n,(k+1)*n+j))
    faces.append(tuple(reversed(range(n))));faces.append(tuple(range((len(profile)-1)*n,len(profile)*n)))
    return mesh(name,verts,faces,mat)


# A low dressed plinth, built from separate, slightly unequal limestone blocks.
PART='Masonry'
for course in range(2):
    z=.10+course*.20
    for side in [-1,1]:
        for j in range(7):
            lo=-1.96+j*.56+(course%2)*.03
            x=lo+.27
            if side<0 and abs(x)<.62:continue
            box('Coursed foundation face',(x,side*1.77,z),(.54,.30,.18),rng.choice(['study_stone','study_stone_light','study_stone_warm']),.035)
        for j in range(6):
            box('Coursed foundation return',(side*1.89,-1.48+j*.59,z),(.30,.565,.18),rng.choice(['study_stone','study_stone_light']),.034)
box('Raised oak floor',(0,0,.25),(3.64,3.34,.12),'study_timber',.01,0)
box('Dark vestibule back',(0,-.78,1.36),(1.32,.08,2.22),'study_recess',0)

# Shallow hewn horizontal timbers, never a solid plank behind the doorway.
PART='Log walls'
front=-1.80
for course in range(10):
    z=.51+course*.225
    # The round-topped leaf has a real corresponding opening.
    opening=.59 if z<=1.84 else (math.sqrt(max(0,.59**2-(z-1.84)**2)) if z<2.43 else 0)
    for side in [-1,1]:
        mat=rng.choice(['study_oak','study_oak','study_oak_warm','study_oak_light'])
        if side<0 and opening:
            for s in [-1,1]:box('Front log beside entry',(s*(1.91+opening)/2,front,z),(1.91-opening,.24,.208),mat,.036,0)
        else:box('Continuous back or upper log',(0,side*1.80,z),(3.88,.24,.208),mat,.036,0)
        box('Return wall log',(side*1.87,0,z),(.26,3.63,.208),mat,.032,1)
    # Interlocking ends alternate. End grain is separate from long-grain timber.
    for side in [-1,1]:
        for sy in [-1,1]:
            if course%2==0:
                box('Exposed corner end grain',(side*1.87,sy*1.94,z),(.255,.045,.205),'study_endgrain',.024)
            else:
                box('Cross-notched log end',(side*2.00,sy*1.80,z),(.045,.25,.205),'study_endgrain',.024)

eave=2.78;ridge=4.65;half=2.28;roof_depth=4.5
angle=math.atan2(ridge-eave,half);slope=math.hypot(half,ridge-eave)
PART='Gable logs'
for k in range(9):
    z=2.84+k*.197
    span=max(0,(ridge-z)/(ridge-eave)*half-.13)
    if span<.10:continue
    for sy in [-1,1]:box('Short gable course',(0,sy*1.80,z),(span*2,.24,.183),'study_oak_light' if k%3==0 else 'study_oak',.030,0)

PART='Oak frame'
for side in [-1,1]:
    for sy in [-1,1]:
        box('Substantial corner upright',(side*1.76,sy*1.87,1.56),(.22,.22,2.36),'study_timber',.027,2)
        box('Upright foot block',(side*1.76,sy*1.87,.53),(.30,.30,.30),'study_oak_warm',.038,2)
    box('Eave purlin',(side*1.89,0,2.67),(.25,4.02,.25),'study_timber',.026,1)
    for yy in [-1.48,-.45,.65,1.55]:
        beam('Pegged eave corbel',(side*1.84,yy,2.31),(side*2.12,yy,2.75),.13,'study_oak_light')
    for yy in [-2.25,2.25]:
        beam('Front and rear carved bargeboard',(0,yy,ridge+.035),(side*2.33,yy,eave-.055),.18,'study_timber',.22)
        box('Visible eave beam end',(side*2.17,yy,eave+.025),(.25,.29,.23),'study_oak_light',.032,1)
for yy in [-1.93,1.93]:
    box('Gable tie beam',(0,yy,2.74),(3.90,.16,.20),'study_timber',.022,0)
    beam('Gable ridge peg',(0,yy,4.12),(0,yy,4.61),.16,'study_oak_light')

# Curved, rounded ceramic shingles. Every tile has volume, a rolled nose and UVs.
PART='Violet roof'
def tile(at,length,width,side,mat):
    us=[-.5,-.43,.25,.44,.5]
    vs=[-.5,-.43,0,.43,.5]
    verts=[]
    for bottom in [False,True]:
        for u in us:
            for v in vs:
                bulge=.022*(1-(v*2)**2)
                nose=-.025 if u==.5 else (-.009 if u==.44 else .007)
                verts.append((u*length,v*width,bulge+nose-(.084 if bottom else 0)))
    faces=[]
    for k in range(4):
        for j in range(4):
            i=k*5+j
            faces.extend([(i,i+5,i+6,i+1),(25+i+1,25+i+6,25+i+5,25+i)])
    edge=[0,1,2,3,4,9,14,19,24,23,22,21,20,15,10,5]
    for k,a in enumerate(edge):
        b=edge[(k+1)%len(edge)];faces.append((a,b,b+25,a+25))
    o=mesh('Hand-rolled glazed shingle',verts,faces,mat)
    o.data.materials.append(M['study_tile_edge']);o.data.materials.append(M['study_clay_under'])
    # A pale clay arris catches the light along the nose, as in the concept.
    for polygon in o.data.polygons:
        if polygon.index<32:polygon.material_index=0 if polygon.index%2==0 else 2
        else:polygon.material_index=1 if polygon.center.x>length*.43 else 0
    layer=o.data.uv_layers.active
    for face in o.data.polygons:
        for li in face.loop_indices:
            co=o.data.vertices[o.data.loops[li].vertex_index].co
            layer.data[li].uv=(co.y/width+.5,co.x/length+.5)
    u=Vector((side*math.cos(angle),0,-math.sin(angle)))
    v=Vector((0,side,0));n=u.cross(v)
    o.matrix_world=Matrix.Translation(Vector(at))@Matrix((u,v,n)).transposed().to_4x4()
    return o

for side in [-1,1]:
    box('Weathered roof underside',(side*half/2,0,(ridge+eave)/2-.075),(slope,roof_depth,.13),'study_clay_under',.015,rotation=(0,side*angle,0))
    for row in range(8):
        distance=(row+.5)*slope/8
        for col in range(12):
            start=-roof_depth/2+col*.405-(.2025 if row%2 else 0)
            lo=max(-roof_depth/2,start);hi=min(roof_depth/2,start+.390)
            if hi-lo<.06:continue
            mat=rng.choices(['study_violet','study_violet_light','study_violet_dark'],[8,2,1])[0]
            tile((side*distance*math.cos(angle),(lo+hi)/2,ridge-distance*math.sin(angle)+.095),slope/8+.09,hi-lo,side,mat)

# Hollow half-round ridge caps, each slightly overlapped over the next.
PART='Ridge caps'
for j in range(12):
    at=(0,-2.19+j*.39,ridge+.015)
    ring('Glazed half-round ridge cap',at,.205,.135,.42,'study_violet_light',10,0,math.pi)

# Real stone voussoirs and a plank leaf hung inside the opening, not on its face.
PART='Stone entrance'
for side in [-1,1]:
    for course in range(6):
        box('Hand-dressed entry jamb',(side*.72,-1.995,.43+course*.247),(.27,.35,.232),'study_stone_light' if course%3 else 'study_stone',.036)
for k in range(11):
    a=k*math.pi/11+.012;b=(k+1)*math.pi/11-.012
    ring('Wedge arch stone',(0,-1.995,1.84),.865,.59,.35,'study_stone_light' if k%3 else 'study_stone_warm',2,a,b)
for outer,inner,width,top in [(3.15,2.56,1.80,.12),(2.72,1.47,1.55,.26)]:
    box('Dressed limestone entry tread',(0,-(outer+inner)/2,top/2),(width,outer-inner,top),'study_stone_light',.035)

PART='Door leaf'
hinge=bpy.data.objects.new('DoorHinge',None);bpy.context.scene.collection.objects.link(hinge)
hinge.location=(-.575,-1.985,.28);bpy.context.view_layer.update()
leaves=[]
for j in range(7):
    x=-.575+(j+.5)*1.15/7;top=1.84+math.sqrt(max(0,.575**2-x*x))
    leaves.append(box('Rebated oak door board',(x,-1.985,(top+.28)/2),(1.15/7-.008,.115,top-.28),'study_door_oak',.014,2))
for z in [.63,1.30]:
    leaves.append(box('Door forged hinge strap',(-.09,-2.055,z),(.89,.035,.052),'study_iron',.008))
    for x in [-.49,.31]:leaves.append(box('Hammered strap rivet',(x,-2.079,z),(.042,.022,.042),'study_brass',.01))
# Blue upper panes sit on a recessed dark backing with physically projecting oak bars.
leaves.append(box('Door glazing recess',(0,-2.048,1.77),(.60,.025,.61),'study_timber',.012))
for x in [-.125,.125]:
    for z in [1.64,1.90]:leaves.append(box('Door blue glass pane',(x,-2.067,z),(.21,.025,.22),'study_glass',.012))
for x in [-.28,0,.28]:leaves.append(box('Door glazing upright',(x,-2.09,1.77),(.048,.05,.65),'study_oak_light',.008,2))
for z in [1.47,1.77,2.07]:leaves.append(box('Door glazing crossbar',(0,-2.091,z),(.60,.05,.05),'study_oak_light',.008,0))
leaves.append(ring('Round brass latch rose',(.36,-2.082,1.05),.065,0,.025,'study_iron',12))
leaves.append(ring('Brass ring pull',(.36,-2.115,1.03),.065,.038,.035,'study_brass',12))
for o in leaves:
    bpy.context.view_layer.update();matrix=o.matrix_world.copy();o.parent=hinge;o.matrix_world=matrix

PART='Windows'
def window(at,angle_z,width=.85,height=1.03,lit=True):
    before=set(bpy.context.scene.objects)
    box('Deep side window reveal',(0,0,0),(width+.18,.12,height+.15),'study_timber',.025)
    box('Inset warm window panes',(0,-.075,0),(width,.055,height),'study_window' if lit else 'study_glass',.014)
    for x in [-width/2,0,width/2]:box('Side window oak mullion',(x,-.13,0),(.065,.15,height+.15),'study_oak_light',.012,2)
    for z in [-height/2,0,height/2]:box('Side window cross rail',(0,-.14,z),(width+.16,.16,.07),'study_timber',.012,0)
    box('Projecting window sill',(0,-.18,-height/2-.10),(width+.34,.40,.13),'study_oak_light',.024,0)
    rot=Matrix.Rotation(angle_z,4,'Z')
    for o in set(bpy.context.scene.objects)-before:
        o.location=rot@o.location+Vector(at);o.rotation_euler.z+=angle_z
window((-2.015,-.55,1.39),-math.pi/2)
window((2.015,.50,1.42),math.pi/2,width=.70,height=.88)
window((.60,1.95,1.44),math.pi,width=.68,height=.84,lit=False)
# A circular glass opening, with thin masonry casing and timber cross.
ring('Round gable dark opening',(0,-1.956,3.37),.395,0,.06,'study_timber',32)
ring('Round gable blue glass',(0,-1.996,3.37),.317,0,.045,'study_glass',32)
ring('Slim gable stone surround',(0,-2.018,3.37),.405,.320,.075,'study_stone_warm',24)
box('Porthole timber upright',(0,-2.078,3.37),(.055,.055,.64),'study_oak_light',.01,2)
box('Porthole timber cross',(0,-2.078,3.37),(.64,.055,.055),'study_oak_light',.01,0)

# A substantial, hollow limestone chimney with individually staggered courses.
PART='Chimney'
cx,cy=-.91,.73
box('Chimney dark mortar',(cx,cy,4.38),(.59,.59,1.65),'study_mortar',.01)
for course in range(6):
    z=3.65+course*.25
    for side in [-1,1]:
        for j in range(2):
            box('Chimney dressed face',(cx-.17+j*.34,cy+side*.31,z),(.322,.13,.231),'study_stone_light' if (course+j)%3 else 'study_stone',.028)
        box('Chimney return stone',(cx+side*.34,cy,z),(.13,.53,.231),'study_stone_light',.028)
for x in [-.36,.36]:box('Hollow chimney cap',(cx+x,cy,5.25),(.14,.84,.17),'study_stone_light',.025)
for y in [-.36,.36]:box('Hollow chimney cap',(cx,cy+y,5.25),(.58,.14,.17),'study_stone_light',.025)
box('Dark open chimney well',(cx,cy,5.205),(.55,.55,.025),'study_recess',0)

PART='Daisy planter'
px,py=1.36,-2.19
box('Front planter stone base',(px,py,.54),(1.03,.53,.41),'study_stone',.045)
box('Planter dark soil',(px,py,.765),(.88,.39,.035),'study_soil',.015)
for side in [-1,1]:
    box('Planter limestone rim',(px,py+side*.26,.76),(1.10,.10,.15),'study_stone_light',.024)
    box('Planter side rim',(px+side*.52,py,.76),(.10,.45,.15),'study_stone_light',.024)

def flower(at,scale=1):
    x,y,z=at
    beam('Daisy slender stem',(x,y,z-.25*scale),(x,y,z),.022*scale,'study_leaf')
    for j in range(2):
        a=math.tau*j/2+.4
        box('Pointed green daisy leaf',(x+.055*math.cos(a)*scale,y+.055*math.sin(a)*scale,z-.16*scale),(.15*scale,.055*scale,.025*scale),'study_leaf_light',.016,rotation=(0,.15,a))
    for j in range(7):
        a=math.tau*j/7
        box('Rounded ivory daisy petal',(x+.064*math.cos(a)*scale,y+.064*math.sin(a)*scale,z),(.115*scale,.045*scale,.025*scale),'study_flower',.019*scale,rotation=(0,.10,a))
    lathe('Golden daisy center',(x,y,z),[(.032*scale,-.008),(.038*scale,.012),(.026*scale,.029)],'study_pollen',8)

for j in range(17):
    x=px+rng.uniform(-.43,.43);y=py+rng.uniform(-.17,.17);z=.82+rng.uniform(0,.10)
    box('Planter dense foliage',(x,y,z),(.19,.16,.15),rng.choice(['study_leaf','study_leaf_dark','study_leaf_light']),.05)
for dx,dy,dz in [(-.36,-.05,1.04),(-.15,.07,1.13),(.06,-.09,1.01),(.27,.03,1.11),(.41,-.04,1.04),(-.02,.13,1.20)]:flower((px+dx,py+dy,dz),.95)

# Small fenced front bed from the reference. It stays beside, never across, the steps.
PART='Front garden'
gx,gy=-1.38,-2.40
box('Garden soil',(gx,gy,.08),(1.05,.71,.13),'study_soil',.03)
for x in [-1.94,-1.37,-.80]:
    box('Garden fence oak post',(x,-2.78,.38),(.13,.13,.76),'study_oak',.025,2)
    box('Fence post cap',(x,-2.78,.78),(.17,.17,.09),'study_oak_light',.018)
for z in [.28,.56]:box('Garden oak rail',(-1.37,-2.78,z),(1.14,.09,.09),'study_oak_light',.012,0)
for x,y in [(-1.81,-2.39),(-1.56,-2.49),(-1.20,-2.35),(-.96,-2.36)]:
    for j in range(3):box('Garden upright leaves',(x+j*.035,y,.24+j*.09),(.09,.09,.31),'study_leaf' if j%2 else 'study_leaf_light',.025,rotation=(0,.1*j,.25*j))
flower((-1.69,-2.14,.62),.75);flower((-1.04,-2.27,.59),.65)

# A complete coopered barrel on the visible side, not a cylinder with a painted band.
PART='Rain barrel'
bx,by=-2.16,.98
lathe('Bulging oak barrel',(bx,by,0),[(.255,.04),(.30,.14),(.335,.39),(.31,.66),(.275,.78)],'study_oak_warm',16)
for z,r in [(.13,.305),(.64,.32)]:
    lathe('Barrel iron hoop',(bx,by,0),[(r,z-.035),(r+.012,z-.022),(r+.012,z+.022),(r,z+.035)],'study_iron',16)
lathe('Barrel wood lid',(bx,by,.78),[(.275,0),(.275,.025)],'study_oak_light',16)
for dx in [-.14,-.035,.075,.18]:box('Barrel lid stave seam',(bx+dx,by,.807),(.009,.40,.003),'study_endgrain_dark',0)

# Join static material/role groups; keep the real door and hinge separate.
for part in sorted({o.get('part','') for o in bpy.context.scene.objects if o.type=='MESH' and not o.parent}):
    for material in M.values():
        objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.parent and o.get('part')==part and material in list(o.data.materials)]
        # Roof shingles contain extra edge/underside materials; merge their whole group once.
        if part=='Violet roof' and material.name!='study_violet':continue
        if part=='Violet roof':objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')==part]
        if len(objects)>1:
            bpy.ops.object.select_all(action='DESELECT')
            for o in objects:o.select_set(True)
            bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=part+'__'+material.name
bpy.context.scene['source_authority']='Saved model.blend is the editable master. author.py is a guarded first-authoring record.'
bpy.context.scene['reference']='reference/voxel-isometric.png: original left-hand violet-roofed log cottage'
bpy.context.scene['review_pass']=1
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(BASE/'provenance.json').write_text(json.dumps({'asset':'reference-cottage','version':'v1','authoring_record':'art/source/world/reference-cottage/v1/author.py','authoring_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'reference_sha256':hashlib.sha256((ROOT/'reference/voxel-isometric.png').read_bytes()).hexdigest(),'note':'New geometry and new textures. Existing Concept Cottage master and placed morning-home remain untouched. Subsequent review passes deliberately edit this saved master.'},indent=2)+'\n')
print('Original concept cottage study saved for pass 1 review.',flush=True)
