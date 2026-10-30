"""One-time, guarded authoring of the bespoke Sparks loft furniture.

Run with Blender from this checkout. Every resulting model.blend is thereafter
the editable authority; export only with scripts/world-art.sh build <id>.
This record must never regenerate an existing master.
"""
from pathlib import Path
import hashlib
import json
import math
import random
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
REF = 'docs/concept/v0.7/art/4-opening/T7a-workshop-loft.wheels.png'
M = {}
PARENT = None
RNG = random.Random(73)


def linear(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4


def material(name, color, texture=None, emission=0, metallic=0):
    m = bpy.data.materials.new('loft_' + name)
    m.use_nodes = True
    c = tuple(linear(int(color[i:i+2], 16)/255) for i in (0, 2, 4))
    m.diffuse_color = (*c, 1)
    b = m.node_tree.nodes.get('Principled BSDF')
    b.inputs['Base Color'].default_value = (*c, 1)
    b.inputs['Roughness'].default_value = .86
    b.inputs['Metallic'].default_value = metallic
    if texture:
        t = m.node_tree.nodes.new('ShaderNodeTexImage')
        t.image = bpy.data.images.load(str(HERE / (texture + '.png')), check_existing=True)
        t.interpolation = 'Linear'
        m.node_tree.links.new(t.outputs['Color'], b.inputs['Base Color'])
        if emission:
            m.node_tree.links.new(t.outputs['Color'], b.inputs['Emission Color'])
    elif emission:
        b.inputs['Emission Color'].default_value = (*c, 1)
    b.inputs['Emission Strength'].default_value = emission
    M[name] = m
    return m


def start(asset):
    global PARENT
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.context.preferences.filepaths.save_version = 0
    M.clear()
    for n,c in {
        'wood':'ad794a','wood_dark':'795033','wood_edge':'c39663','ink':'543b2b',
        'cream':'efe4cc','linen':'eee5d3','linen_shade':'c8bea7','teal':'397c7c',
        'teal_light':'74a69b','teal_dark':'315c5a','blue':'536b89','blue_light':'8494aa',
        'plum':'806278','red':'b55e4d','ochre':'c59c58','paper':'f5e9cc',
        'pages':'d6c4a0','leather':'80563b','leather_dark':'5b3c2c','soil':'5b4936',
        'leaf':'4f8246','leaf_light':'729953','leaf_dark':'355f3b','ceramic':'cab798',
        'glass':'483c29','rubber':'3c4140','cable':'343b3b','white':'f3e8ce'
    }.items():
        material(n,c)
    material('oak','ad794a','honey-oak')
    material('quilt','ffffff','teal-quilt')
    material('rug','ffffff','woven-rug')
    material('harbour','ffffff','harbour-view',.3)
    material('brass','c49a53',metallic=.18)
    material('lamp_glass','ffe0a0',emission=.65)
    PARENT = bpy.data.objects.new(asset.replace('-','_'),None)
    bpy.context.scene.collection.objects.link(PARENT)


def put(o, mat, smooth=False):
    o.parent = PARENT
    o.data.materials.append(M[mat])
    if smooth:
        for p in o.data.polygons: p.use_smooth = True
    if mat == 'oak': wood_uv(o)
    return o


def wood_uv(o):
    uv = o.data.uv_layers.new(name='Painted grain') if not o.data.uv_layers else o.data.uv_layers.active
    coords = [v.co for v in o.data.vertices]
    spans = [max(v[i] for v in coords)-min(v[i] for v in coords) for i in range(3)]
    off = (RNG.random()*.6,RNG.random()*.6)
    for p in o.data.polygons:
        axes = [i for i in range(3) if i != max(range(3),key=lambda a: abs(p.normal[a]))]
        axes.sort(key=lambda a: spans[a],reverse=True)
        for li in p.loop_indices:
            v = o.data.vertices[o.data.loops[li].vertex_index].co
            uv.data[li].uv = (v[axes[0]]/3.2+off[0],v[axes[1]]/.9+off[1])


def box(name, at, size, mat='oak', bevel=.025, segments=2):
    bpy.ops.mesh.primitive_cube_add(size=1,location=at)
    o=bpy.context.object; o.name=name; o.scale=size
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    if bevel:
        mod=o.modifiers.new('Soft painted arris','BEVEL'); mod.width=bevel; mod.segments=segments
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return put(o,mat)


def sphere(name, at, scale, mat, segments=16, rings=8):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=segments,ring_count=rings,radius=1,location=at)
    o=bpy.context.object; o.name=name; o.scale=scale
    bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
    return put(o,mat,True)


def cylinder(name, at, radius, depth, mat, vertices=16, radius_top=None):
    bpy.ops.mesh.primitive_cone_add(vertices=vertices,radius1=radius,radius2=radius if radius_top is None else radius_top,depth=depth,location=at)
    o=bpy.context.object; o.name=name
    return put(o,mat)


def torus(name, at, radius, thickness, mat, rotation=None):
    bpy.ops.mesh.primitive_torus_add(major_radius=radius,minor_radius=thickness,major_segments=24,minor_segments=6,location=at)
    o=bpy.context.object; o.name=name
    if rotation: o.rotation_euler=rotation
    return put(o,mat,True)


def rod(name,a,b,r,mat,vertices=10):
    a,b=Vector(a),Vector(b)
    o=cylinder(name,(a+b)/2,r,(b-a).length,mat,vertices)
    o.rotation_euler=(b-a).to_track_quat('Z','Y').to_euler()
    return o


def curve(name, points, radius, mat):
    c=bpy.data.curves.new(name,'CURVE'); c.dimensions='3D'; c.resolution_u=5
    c.bevel_depth=radius; c.bevel_resolution=2
    s=c.splines.new('BEZIER'); s.bezier_points.add(len(points)-1)
    for p,co in zip(s.bezier_points,points):
        p.co=co; p.handle_left_type='AUTO'; p.handle_right_type='AUTO'
    o=bpy.data.objects.new(name,c); bpy.context.scene.collection.objects.link(o)
    bpy.context.view_layer.objects.active=o; o.select_set(True)
    bpy.ops.object.convert(target='MESH'); o=bpy.context.object
    return put(o,mat,True)


def face(name, coords, mat, uvs=None):
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(coords,[],[tuple(range(len(coords)))]); mesh.update()
    o=bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(o); put(o,mat)
    if uvs:
        layer=mesh.uv_layers.new(name='Illustration')
        for p in mesh.polygons:
            for li in p.loop_indices: layer.data[li].uv=uvs[mesh.loops[li].vertex_index]
    return o


def pull(x,y,z,width=.17):
    for dx in (-width/2,width/2): sphere('Brass pull fixing',(x+dx,y,z),(.025,.018,.025),'brass',12,6)
    curve('Rounded brass drawer pull',[(x-width/2,y-.005,z),(x-width/2,y-.045,z-.045),(x+width/2,y-.045,z-.045),(x+width/2,y-.005,z)],.016,'brass')


def book(at, size, color, angle=0):
    x,y,z=at; w,d,h=size
    parts=[box('Bound book pages',(x,y,z+h/2),(w*.83,d*.92,h*.85),'pages',.006),
           box('Book cover',(x,y,z+.025),(w,d,.05),color,.01),
           box('Book cover',(x,y,z+h-.025),(w,d,.05),color,.01),
           box('Rounded book spine',(x-w*.46,y,z+h/2),(.075,d,h),color,.012)]
    if angle:
        for p in parts:
            p.location=Vector(at)+__import__('mathutils').Matrix.Rotation(angle,3,'Z')@(p.location-Vector(at)); p.rotation_euler.z=angle


def pot(at, scale=1, trailing=False, flowers=False):
    x,y,z=at; r=.17*scale; h=.25*scale
    cylinder('Hand-thrown flowerpot',(x,y,z+h/2),r*.76,h,'ochre',16,r)
    torus('Pot rolled lip',(x,y,z+h),r,.025*scale,'ceramic')
    cylinder('Dark potting soil',(x,y,z+h+.002),r*.85,.02,'soil')
    if trailing:
        for side in (-1,1):
            path=[(x,y,z+h),(x+side*.21*scale,y-.08*scale,z+h+.09*scale),(x+side*.27*scale,y-.22*scale,z+h-.3*scale),(x+side*.2*scale,y-.23*scale,z+h-.75*scale)]
            curve('Trailing ivy stem',path,.012*scale,'leaf_dark')
            for k in range(8):
                t=k/7; cx=x+side*(.1+.16*math.sin(t*2))*scale; cy=y-.18*scale; cz=z+h+(.1-t*.78)*scale
                leaf=sphere('Ivy leaf',(cx+(-1)**k*.08*scale,cy,cz),(.12*scale,.035*scale,.075*scale),['leaf','leaf_light','leaf_dark'][k%3],10,6)
                leaf.rotation_euler.y=(-1)**k*.5
    else:
        for k in range(7):
            a=k*2.4; end=(x+math.cos(a)*.2*scale,y+math.sin(a)*.17*scale,z+h+(.2+(k%3)*.07)*scale)
            rod('Plant stem',(x,y,z+h),end,.009*scale,'leaf_dark')
            leaf=sphere('Broad leaf',end,(.13*scale,.055*scale,.065*scale),['leaf','leaf_light'][k%2],10,6); leaf.rotation_euler.z=a
            if flowers and k%2==0:
                fx,fy,fz=end
                for j in range(5):
                    b=j*math.tau/5
                    sphere('Cream flower petal',(fx+math.cos(b)*.05*scale,fy+math.sin(b)*.05*scale,fz+.03*scale),(.04*scale,.035*scale,.015*scale),'white',10,6)
                sphere('Ochre flower centre',(fx,fy,fz+.04*scale),(.025*scale,)*3,'ochre',10,6)


def cloth(name, xsize, y0, y1, z, mat, drop=.0):
    nx,ny=24,20; verts=[]; faces=[]
    for j in range(ny+1):
        y=y0+(y1-y0)*j/ny
        for i in range(nx+1):
            x=-xsize/2+xsize*i/nx
            edge=max(0,abs(x)/(xsize/2)-.78)/.22
            foot=max(0,1-(y-y0)/.20)
            zz=z-drop*max(edge,foot)+.012*math.sin(x*16+y*6)
            verts.append((x,y,zz))
    for j in range(ny):
        for i in range(nx):
            a=j*(nx+1)+i; faces.append((a,a+1,a+nx+2,a+nx+1))
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(o); put(o,mat,True)
    uv=mesh.uv_layers.new(name='Whole fabric')
    for p in mesh.polygons:
        for li in p.loop_indices:
            n=mesh.loops[li].vertex_index; uv.data[li].uv=(n%(nx+1)/nx,n//(nx+1)/ny)
    bpy.context.view_layer.objects.active=o; bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
    sol=o.modifiers.new('Cotton thickness','SOLIDIFY'); sol.thickness=.012
    bpy.ops.object.modifier_apply(modifier=sol.name)
    return o


def bed():
    for x in (-.99,.99):
        for y in (-1.4,1.4):
            box('Turned bed post',(x,y,.64),(.13,.13,1.28),'wood_dark',.035,3)
            cylinder('Bed post collar',(x,y,1.23),.09,.07,'wood_edge')
            sphere('Bed post finial',(x,y,1.37),(.105,.105,.09),'wood_dark')
            cylinder('Soft brass post cap',(x,y,1.29),.095,.04,'brass')
    for x in (-.96,.96): box('Bed side rail',(x,0,.48),(.12,2.84,.34),'oak',.025)
    for y in (-1.4,1.4):
        box('Bed end framing',(0,y,.72),(1.95,.14,.17),'oak')
        for x in (-.65,-.32,0,.32,.65): box('Recessed end panel',(x,y,.49),(.28,.075,.4),'wood',.015)
        box('End lower rail',(0,y,.27),(1.95,.15,.12),'wood_dark')
    box('Linen mattress',(0,0,.66),(1.86,2.72,.27),'linen',.11,4)
    cloth('Draped patchwork quilt',2.18,-1.48,.76,.83,'quilt',.29)
    cloth('Folded cream top sheet',1.9,.57,.86,.87,'linen',.04)
    for x in (-.43,.43):
        p=box('Soft cream pillow',(x,1.03,.88),(.83,.58,.19),'white',.09,5); p.rotation_euler.z=x*.08
        curve('Pillow seam',[(x-.32,.79,.89),(x+.32,.79,.89)],.007,'linen_shade')


def desk():
    for x in (-1.12,1.12):
        for y in (-.44,.44):
            box('Desk tapered leg',(x,y,.49),(.1,.1,.98),'wood_dark',.02)
            cylinder('Turned leg collar',(x,y,.23),.072,.08,'oak')
    box('Desk back apron',(0,.43,.88),(2.35,.12,.23),'wood')
    box('Writing surface',(0,0,1.04),(2.6,1.16,.12),'oak',.045,3)
    for x in (-.87,.87):
        box('Drawer pedestal',(x,.02,.73),(.58,.86,.53),'wood_dark')
        for z in (.56,.76,.95):
            box('Inset desk drawer',(x,-.432,z),(.52,.06,.16),'oak',.02)
            pull(x,-.48,z,.17)
    for y in (-.32,.06,.36):
        curve('Desktop board seam',[(-1.24,y,1.106),(1.24,y,1.106)],.0045,'wood')
    # The desk's small, personal writing objects are part of the editable prop.
    book((.66,.19,1.11),(.36,.47,.08),'teal_dark',-.16)
    book((.70,.16,1.19),(.32,.43,.065),'blue',-.09)
    box('Loose letter',(0,.19,1.113),(.45,.35,.009),'paper',.002)
    for n in range(5): box('Ink handwriting stroke',(-.13+n*.012,.08+n*.043,1.121),(.23-n*.025,.006,.001),'wood_dark',0)
    cylinder('Pencil cup',(.99,.31,1.24),.09,.25,'teal',16)
    for n in range(5):
        x=.99+(n-2)*.023; y=.31+((n%2)*2-1)*.025
        rod('Pencil in cup',(x,y,1.25),(x+.035*(n-2),y,1.57+(n%2)*.06),.012,['ochre','blue','red'][n%3])
    cylinder('Tea mug body',(.84,-.24,1.21),.09,.2,'cream',20)
    torus('Mug rim',(.84,-.24,1.31),.087,.012,'ceramic')
    cylinder('Tea surface',(.84,-.24,1.303),.072,.006,'leather_dark',20)
    torus('Mug handle',(.96,-.24,1.22),.065,.017,'cream',(math.pi/2,0,0))
    # Brass angle-poise lamp, a small warm accent, with a real shade.
    cylinder('Lamp foot',(.98,.44,1.13),.14,.055,'brass')
    curve('Lamp bent stem',[(.98,.44,1.15),(.98,.44,1.58),(.85,.44,1.71),(.65,.44,1.69)],.022,'brass')
    cylinder('Brass desk shade',(.64,.44,1.65),.17,.18,'brass',20,.075)
    cylinder('Shade warm interior',(.64,.44,1.555),.145,.012,'lamp_glass',20)


def chair():
    box('Worn chair seat',(0,0,.55),(.67,.65,.12),'oak',.06,3)
    for x in (-.26,.26):
        for y in (-.25,.25):
            rod('Chair leg',(x*1.12,y*1.15,.02),(x,y,.54),.045,'wood_dark')
    for y in (-.25,.25): rod('Chair low rung',(-.28,y,.22),(.28,y,.22),.025,'wood')
    for x in (-.27,.27): rod('Chair back stile',(x,.25,.51),(x,.29,1.21),.04,'wood_dark')
    box('Curved chair back',(0,.29,1.15),(.64,.08,.22),'oak',.05,3)
    for x in (-.12,.12): rod('Back spindle',(x,.25,.62),(x,.28,1.08),.021,'wood')
    box('Woven seat cushion',(0,-.01,.63),(.53,.48,.055),'linen',.04,3)


def shelf():
    for x in (-1.12,1.12): box('Bookcase upright',(x,0,1.08),(.14,.62,2.16),'wood_dark',.035)
    for z in (.16,.78,1.41,1.97): box('Thick shelf',(0,-.01,z),(2.3,.68,.11),'oak',.03)
    for x in (-.73,-.36,0,.36,.73): box('Bookcase back board',(x,.28,1.07),(.34,.07,2.03),'wood',.01)
    for n in range(8):
        x=-.84+n*.16; h=.28+(n%3)*.055
        # Upright books, with covers and visible cream page ends.
        box('Upright book pages',(x,.02,.87+h/2),(.11,.34,h),'pages',.008)
        for dx in (-.065,.065): box('Upright cloth book cover',(x+dx,.02,.87+h/2),(.018,.39,h+.025),['teal','blue','red','ochre'][n%4],.005)
        box('Book spine',(x,-.18,.87+h/2),(.14,.025,h+.025),['teal','blue','red','ochre'][n%4],.01)
        for zz in (.93,.93+h*.62): box('Book spine gilt band',(x,-.199,zz),(.1,.005,.012),'brass',0)
    book((-.7,-.04,.22),(.62,.42,.12),'blue')
    book((-.69,-.04,.34),(.66,.43,.105),'red',.04)
    book((-.65,-.04,.445),(.56,.42,.09),'teal',-.05)
    box('Wicker basket body',(.45,.0,.43),(.81,.45,.38),'ceramic',.04)
    for z in (.28,.35,.42,.49,.57): box('Basket woven band',(.45,-.235,z),(.84,.025,.025),'wood_edge',.005)
    for x in (.12,.27,.43,.59,.75): box('Basket upright weave',(x,-.25,.43),(.022,.025,.34),'ochre',.005)
    box('Old lidded box',(.62,0,1.61),(.6,.46,.28),'teal_dark',.025)
    box('Box lid',(.62,0,1.76),(.64,.49,.06),'teal',.02)
    box('Box paper label',(.62,-.246,1.61),(.2,.01,.09),'paper',.004)
    book((-.75,0,1.47),(.42,.39,.08),'ochre')
    pot((.90,.0,2.03),.9,True)
    book((-.80,.01,2.03),(.38,.42,.09),'blue')


def luggage():
    box('Leather suitcase body',(0,0,.3),(1.35,.85,.53),'leather_dark',.085,3)
    box('Suitcase lining',(0,0,.56),(1.17,.70,.08),'ochre',.045)
    # Raised lid with explicit hinge pivot, ready for a future interaction.
    lid=box('Open leather lid',(0,.38,.96),(1.34,.12,.89),'leather',.065,3)
    lid.rotation_euler.x=math.radians(-12)
    box('Lid inner lining',(0,.293,.96),(1.15,.03,.70),'ceramic',.035)
    for x in (-.5,.5):
        box('Case strap',(x,-.43,.30),(.09,.025,.44),'leather',.01)
        box('Brass suitcase latch',(x,-.46,.39),(.115,.035,.1),'brass',.015)
    for x in (-.62,.62):
        for y in (-.37,.37): box('Brass case corner',(x,y,.52),(.12,.10,.07),'brass',.022)
    pull(0,-.48,.28,.3)
    for n,c in enumerate(['blue','blue_light','linen']):
        box('Folded unpacked clothes',(-.27,.0,.65+n*.095),(.50,.58,.09),c,.045,3)
    box('Rolled cream shirt',(.34,.02,.68),(.44,.60,.17),'linen',.07,3)
    # A scarf lies over the front lip rather than floating above the case.
    face('Scarf over suitcase',[(.17,-.1,.80),(.51,-.1,.80),(.51,-.48,.70),(.51,-.49,.23),(.17,-.49,.23),(.17,-.48,.70)],'ochre')
    for n in range(7): rod('Scarf fringe',(.20+n*.045,-.49,.24),(.20+n*.045,-.49,.17),.007,'ochre',6)
    for x in (-.25,.20):
        box('Spare boot sole',(x,-.91,.07),(.27,.48,.09),'leather_dark',.06,3)
        box('Spare boot upper',(x,-.82,.22),(.25,.25,.32),'leather',.07,3)
        sphere('Rounded boot toe',(x,-1.02,.14),(.13,.18,.11),'leather')


def cabinet():
    for x in (-.43,.43):
        for y in (-.25,.25): box('Cabinet short foot',(x,y,.11),(.11,.12,.22),'wood_dark')
    box('Cabinet case',(0,0,.57),(1.0,.68,.88),'wood_dark',.025)
    box('Cabinet top',(0,0,1.04),(1.12,.78,.12),'oak',.035)
    for z in (.32,.60,.88):
        box('Bedside drawer',(0,-.355,z),(.89,.055,.22),'oak',.02); pull(0,-.40,z,.20)
    # Bedside lantern, kept modest beside the daylight windows.
    cylinder('Lantern base',(-.27,0,1.14),.12,.10,'brass')
    cylinder('Lantern warm glass',(-.27,0,1.32),.083,.27,'lamp_glass')
    cylinder('Lantern cap',(-.27,0,1.49),.12,.07,'brass',16,.07)
    for a in (0,math.pi/2,math.pi,math.pi*1.5):
        rod('Lantern cage',(-.27+math.cos(a)*.1,math.sin(a)*.1,1.18),(-.27+math.cos(a)*.1,math.sin(a)*.1,1.47),.012,'brass')
    torus('Lantern carrying loop',(-.27,0,1.6),.075,.013,'brass',(math.pi/2,0,0))
    cylinder('Flower vase',(.25,.1,1.23),.105,.27,'cream',16,.065)
    for n in range(3):
        x=.25+(n-1)*.08; rod('Vase flower stem',(.25,.1,1.34),(x,.12,1.59+abs(n-1)*.07),.009,'leaf_dark')
        sphere('Dried cream flower',(x,.12,1.60+abs(n-1)*.07),(.075,.055,.055),'white')


def wall_life():
    box('Peg rail',(0,0,1.73),(1.75,.1,.13),'wood_dark')
    for x in (-.6,-.1,.55):
        rod('Wooden coat peg',(x,-.02,1.74),(x,-.18,1.74),.035,'oak')
        sphere('Peg cap',(x,-.18,1.74),(.05,.04,.05),'wood_edge')
    # Hanging coat with broad folds, lapels and shaped sleeves.
    box('Blue coat body',(-.54,-.16,1.18),(.50,.14,.88),'blue',.10,4)
    for side in (-1,1):
        sleeve=box('Hanging coat sleeve',(-.54+side*.30,-.14,1.35),(.19,.17,.58),'blue',.075,3); sleeve.rotation_euler.y=side*.20
    box('Coat cream collar',(-.54,-.22,1.64),(.25,.055,.11),'linen',.03)
    for z in (.97,1.15,1.34,1.49): sphere('Coat button',(-.54,-.245,z),(.018,.009,.018),'brass',10,6)
    box('Coat pocket',(-.69,-.242,1.0),(.14,.02,.14),'blue_light',.02)
    curve('Canvas bag strap',[(.48,-.07,1.75),(.28,-.14,1.49),(.30,-.15,1.17),(.66,-.15,1.17),(.69,-.14,1.49),(.55,-.07,1.75)],.018,'leather')
    box('Hanging canvas satchel',(.48,-.17,.98),(.44,.22,.47),'linen',.06,3)
    box('Satchel flap',(.48,-.30,1.13),(.45,.04,.22),'cream',.035)
    box('Satchel buckle',(.48,-.33,1.02),(.06,.018,.07),'brass',.008)
    box('Little wall book shelf',(-.60,-.02,2.40),(.80,.42,.08),'oak')
    book((-.62,-.02,2.45),(.48,.32,.08),'blue')
    book((-.60,-.01,2.53),(.43,.30,.07),'red',.09)
    pot((.1,.0,2.43),.6,True)


def rug():
    cloth('Woven rag rug',3.7,-1.22,1.22,.043,'rug',.006)
    for y in (-1.235,1.235):
        for n in range(50):
            x=-1.8+n*.073
            rod('Cream knotted fringe',(x,y,.05),(x+.015,y+(.11 if y>0 else -.11),.035),.009,'linen',6)


def travel_stacks():
    box('Packing crate',(-.30,.0,.31),(.82,.69,.62),'wood_dark',.025)
    for z in (.12,.32,.52): box('Packing crate plank',(-.30,-.36,z),(.84,.035,.16),'oak',.012)
    for x in (-.64,.04): box('Crate corner batten',(x,-.39,.31),(.08,.045,.59),'wood',.012)
    book((.50,0,.02),(.55,.49,.12),'blue')
    book((.50,0,.14),(.59,.45,.10),'red',.05)
    book((.53,0,.24),(.52,.47,.10),'teal',-.08)
    pot((-.3,0,.66),.9,False)
    cylinder('Rolled charts basket',(.46,.45,.36),.23,.69,'ceramic',16,.27)
    for k in range(4):
        x=.46+((k%2)*2-1)*.09; y=.45+((k//2)*2-1)*.08
        cylinder('Rolled paper chart',(x,y,.72),.055,.63+(k%2)*.12,'paper',12)
        torus('Chart rolled rim',(x,y,1.03+(k%2)*.06),.038,.01,'pages')


def window_life():
    pot((-.30,0,.02),.9,False,True)
    book((.27,.02,.01),(.42,.28,.085),'ochre',-.05)
    box('Small keepsake box',(.32,.02,.19),(.30,.24,.17),'teal_dark',.025)
    box('Keepsake lid',(.32,.02,.29),(.32,.25,.035),'teal',.012)


def postcard():
    box('Postcard wooden backing',(0,0,0),(.88,.05,.64),'wood_dark',.016)
    box('Cream postcard border',(0,-.032,0),(.84,.014,.60),'paper',.003)
    face('Painted harbour postcard',[(-.38,-.044,-.25),(.38,-.044,-.25),(.38,-.044,.25),(-.38,-.044,.25)],'harbour',[(0,0),(1,0),(1,1),(0,1)])
    for x in (-.33,.33): box('Postcard corner pin',(x,-.06,.27),(.05,.025,.04),'brass',.009)


def tape_machine():
    box('Tape machine timber base',(0,0,.075),(.73,.45,.15),'wood_dark',.035)
    box('Cream enamel reader',(0,-.09,.23),(.64,.28,.20),'cream',.06,4)
    box('Reader inset plate',(.09,-.24,.24),(.29,.015,.09),'brass',.015)
    for n in range(3): box('Reader mechanical key',(-.17+n*.12,-.27,.27),(.065,.05,.045),'teal_dark',.012)
    rod('Spool axle',(-.28,.07,.42),(.28,.07,.42),.05,'brass')
    # Real wheel, paper rim and holes, all held on a semantic spindle.
    spool=cylinder('tape_spool',(0,.07,.42),.205,.29,'paper',32); spool.rotation_euler.y=math.pi/2
    for x in (-.17,.17):
        wheel=cylinder('Spool brass flange',(x,.07,.42),.225,.025,'brass',24); wheel.rotation_euler.y=math.pi/2
        hub=cylinder('Spool hub',(x*1.16,.07,.42),.065,.055,'wood_dark',16); hub.rotation_euler.y=math.pi/2
    # Paper tape curves down from the spool over the reader.
    verts=[]; quads=[]
    for j in range(17):
        t=j/16; y=.07-.38*t; z=.42+.21*math.cos(t*math.pi/2)
        for x in (-.115,.115): verts.append((x,y,z))
        if j: a=(j-1)*2; quads.append((a,a+1,a+3,a+2))
    mesh=bpy.data.meshes.new('Paper feed'); mesh.from_pydata(verts,[],quads); mesh.update()
    ob=bpy.data.objects.new('paper_feed',mesh); bpy.context.scene.collection.objects.link(ob); put(ob,'paper')
    for j in range(7):
        t=(j+.5)/8; y=.07-.38*t; z=.42+.21*math.cos(t*math.pi/2)+.003
        for x in (-.07,.0,.07): sphere('Punched tape hole',(x,y,z),(.011,.009,.003),'leather_dark',8,4)
    box('Nell note card',(.25,.17,.57),(.26,.024,.29),'paper',.008)
    for j in range(4): box('Note ink stroke',(.25,.153,.64-j*.035),(.18-j*.02,.004,.004),'wood_dark',0)


def hotaru():
    sphere('Squat cream enamel body',(0,0,.245),(.225,.19,.215),'cream',24,12)
    for z,r in ((.105,.18),(.39,.205)): torus('Teal body band',(0,0,z),r,.024,'teal')
    cylinder('Low rolling chassis',(0,0,.067),.17,.075,'teal_dark',20)
    for x in (-.15,.15):
        w=cylinder('Tucked rubber wheel',(x,0,.055),.06,.055,'rubber',16); w.rotation_euler.y=math.pi/2
        hub=cylinder('Wheel brass hub',(x*1.18,0,.055),.03,.012,'brass',16); hub.rotation_euler.y=math.pi/2
    sphere('Oversized teal cap',(0,0,.445),(.265,.228,.15),'teal',24,12)
    cylinder('Wide softened cap brim',(0,0,.403),.275,.045,'teal',32)
    torus('Cap pale edge',(0,0,.402),.268,.010,'teal_light')
    # One genuinely dark window: no eyes, mouth, or dormant spark.
    ring=torus('Round brass spark window',(0,-.183,.26),.143,.029,'brass',(math.pi/2,0,0))
    sphere('spark_glass',(0,-.193,.26),(.135,.035,.135),'glass',24,12)
    sphere('Faint reflected glass glint',(-.055,-.226,.32),(.018,.003,.03),'wood_edge',12,6)
    for x in (-.17,.17):
        sphere('Rosy enamel cheek',(x,-.14,.24),(.028,.009,.023),'red')
        sphere('Tiny mitten hand',(x*1.47,-.01,.22),(.062,.065,.066),'teal')
        rod('Stub brass arm',(x,0,.26),(x*1.44,-.01,.22),.027,'brass')
    cylinder('Rotor spindle',(0,0,.605),.021,.14,'brass',12)
    blade=box('rotor',(0,0,.647),(.55,.065,.022),'brass',.025,3); blade.rotation_euler.z=.15
    sphere('Red rotor bobble',(0,0,.673),(.043,.043,.045),'red')
    box('Tape slot',(0,-.166,.092),(.085,.025,.025),'wood_dark',.007)
    face('Short curl of paper tape',[(-.03,-.17,.095),(.03,-.17,.095),(.03,-.225,.045),(-.03,-.225,.045)],'paper')


def cable():
    curve('Shelf to desk cable',[(0,0,1.99),(-.12,.15,1.98),(-.22,.53,1.56),(-.15,1.17,1.30),(.15,1.58,1.17),(.50,1.75,1.12)],.017,'cable')


BUILDERS={
    'loft-bed':bed,'loft-desk':desk,'loft-chair':chair,'loft-shelf':shelf,
    'loft-luggage':luggage,'loft-cabinet':cabinet,'loft-wall-life':wall_life,
    'loft-rug':rug,'loft-travel-stacks':travel_stacks,'loft-window-life':window_life,
    'loft-postcard':postcard,'loft-tape-machine':tape_machine,'loft-hotaru':hotaru,'loft-cable':cable,
}
def save(asset):
    # Batch static pieces by material, retaining source component names as extras.
    # Semantic machinery stays independent for deliberate later animation.
    groups={}
    for o in list(bpy.context.scene.objects):
        if o.type=='MESH':
            semantic=o.name if o.name in ('tape_spool','paper_feed','rotor','spark_glass') else 'static'
            groups.setdefault((semantic,o.data.materials[0].name),[]).append(o)
    for (semantic,mat),objects in groups.items():
        names=[o.name for o in objects]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects: o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1: bpy.ops.object.join()
        o=bpy.context.object; o.name=semantic if semantic!='static' else mat
        o['authored_parts']=names
    scene=bpy.context.scene; scene.unit_settings.system='METRIC'; scene.unit_settings.scale_length=1
    scene['rootward_source']='Editable authority; source geometry and paintings after T7a. Do not rerun author.py.'
    bpy.ops.file.pack_all()
    folder=ROOT/'art/source/world'/asset/'v1'; folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'model.blend'))
    (folder/'provenance.json').write_text(json.dumps({'asset':asset,'date':'2026-10-27','reference':REF,'authoring_record':'art/source/world/sparks-loft/v1/author.py','authoring_record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'textures':'art/source/world/sparks-loft/v1/prompts.json','note':'New bespoke authored asset; model.blend is now authority. Build through scripts/world-art.sh.'},indent=2)+'\n')
    print('AUTHORED',asset,flush=True)


if __name__=='__main__':
    for asset in BUILDERS:
        if (ROOT/'art/source/world'/asset/'v1/model.blend').exists():
            raise RuntimeError('Existing editable master; authoring refuses to overwrite '+asset)
    for asset,make in BUILDERS.items():
        start(asset); make(); save(asset)
