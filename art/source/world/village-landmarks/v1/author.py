"""One-time original landmark authorship. Refuses existing editable sources.

After this handoff, edit each saved model.blend and use world-art.sh build.
Blender is Z-up; fronts face -Y. Existing painted library textures are reused.
"""
import bpy
import math
import random
import json
import hashlib
from pathlib import Path
from mathutils import Vector, Matrix

ROOT = Path.cwd()
IDS = ['rootward-tree', 'morning-town-hall']
for asset in IDS:
    if (ROOT / f'art/source/world/{asset}/v1/model.blend').exists():
        raise RuntimeError(f'Edit the existing {asset} Blender source; authoring refuses to overwrite it.')
M = {}
PART = 'Structure'
rng = random.Random(261026)


def linear(v):
    return v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4


def material(name, colour, texture=None, tint=1, emission=0, metal=0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = [linear(int(colour[i:i+2], 16) / 255) for i in (0, 2, 4)]
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value = (*rgb, 1)
    bs.inputs['Roughness'].default_value = .86
    bs.inputs['Metallic'].default_value = metal
    if texture:
        n = m.node_tree.nodes.new('ShaderNodeTexImage')
        n.image = bpy.data.images.load(str(ROOT / 'assets/world/textures/lush' / f'{texture}.png'), check_existing=True)
        mix = m.node_tree.nodes.new('ShaderNodeMixRGB')
        mix.blend_type = 'MULTIPLY'
        mix.inputs[0].default_value = 1
        mix.inputs[2].default_value = (tint, tint, tint, 1)
        m.node_tree.links.new(n.outputs['Color'], mix.inputs[1])
        m.node_tree.links.new(mix.outputs[0], bs.inputs['Base Color'])
    if emission:
        bs.inputs['Emission Color'].default_value = (*rgb, 1)
        bs.inputs['Emission Strength'].default_value = emission
    M[name] = m


def uv(o, tile=1.6):
    d = o.data
    d.update()
    layer = d.uv_layers.active or d.uv_layers.new(name='UVMap')
    for p in d.polygons:
        axis = max(range(3), key=lambda i: abs(p.normal[i]))
        for li in p.loop_indices:
            v = d.vertices[d.loops[li].vertex_index].co
            a, b = (v.y, v.z) if axis == 0 else ((v.x, v.z) if axis == 1 else (v.x, v.y))
            layer.data[li].uv = (a / tile, b / tile)


def mesh(name, verts, faces, mat):
    d = bpy.data.meshes.new(name)
    d.from_pydata(verts, [], faces)
    d.materials.append(M[mat])
    o = bpy.data.objects.new(name, d)
    bpy.context.scene.collection.objects.link(o)
    o['part'] = PART
    uv(o)
    return o


def box(name, at, size, mat, bevel=.015, rotation=None):
    x, y, z = [v / 2 for v in size]
    o = mesh(name, [(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],
             [(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)], mat)
    o.location = at
    if rotation:
        o.rotation_euler = rotation
    if bevel:
        bpy.context.view_layer.objects.active = o
        mod = o.modifiers.new('Hand cut edges', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.ops.object.modifier_apply(modifier=mod.name)
    uv(o)
    return o


def beam(name, a, b, width, mat):
    a, b = Vector(a), Vector(b)
    o = box(name, (a+b)/2, (width,width,(b-a).length), mat)
    o.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    return o


def tube(name, points, radii, mat, sides=12):
    verts, faces = [], []
    for k, (point, radius) in enumerate(zip(points,radii)):
        p = Vector(point)
        direction = Vector(points[min(k+1,len(points)-1)]) - Vector(points[max(k-1,0)])
        rotation = direction.to_track_quat('Z','Y')
        for j in range(sides):
            a = math.tau*j/sides + .08*k
            verts.append(tuple(p + rotation @ Vector((radius*math.cos(a),radius*math.sin(a),0))))
    faces.append(tuple(reversed(range(sides))))
    for k in range(len(points)-1):
        for j in range(sides):
            faces.append((k*sides+j,k*sides+(j+1)%sides,(k+1)*sides+(j+1)%sides,(k+1)*sides+j))
    faces.append(tuple(range((len(points)-1)*sides,len(points)*sides)))
    return mesh(name, verts, faces, mat)


def ring(name, at, outer, inner, depth, mat, n=24, start=0, end=math.tau):
    verts = []
    for y in [-depth/2,depth/2]:
        for r in [inner,outer]:
            for k in range(n+1):
                a = start+(end-start)*k/n
                verts.append((at[0]+r*math.cos(a),at[1]+y,at[2]+r*math.sin(a)))
    h = n+1
    faces = []
    for k in range(n):
        faces.extend([(k,k+1,h+k+1,h+k),(2*h+k,3*h+k,3*h+k+1,2*h+k+1),(k,2*h+k,2*h+k+1,k+1),(h+k,h+k+1,3*h+k+1,3*h+k)])
    faces.extend([(0,h,3*h,2*h),(n,2*h-1,4*h-1,3*h-1)])
    return mesh(name,verts,faces,mat)


def finish(asset):
    # Merge static geometry by material and semantic part. Hinged leaves stay separate.
    objects = list(bpy.context.scene.objects)
    for part in sorted({o.get('part','') for o in objects if o.type=='MESH' and not o.parent}):
        for m in M.values():
            objs = [o for o in bpy.context.scene.objects if o.type=='MESH' and not o.parent and o.get('part')==part and o.data.materials[0]==m]
            if len(objs)>1:
                bpy.ops.object.select_all(action='DESELECT')
                for o in objs:
                    o.select_set(True)
                bpy.context.view_layer.objects.active=objs[0]
                bpy.ops.object.join()
                bpy.context.object.name=part+'__'+m.name
    bpy.context.scene['source_authority']='Saved model.blend is the editable master; author.py is a one-time record.'
    folder = ROOT / f'art/source/world/{asset}/v1'
    folder.mkdir(parents=True,exist_ok=True)
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'model.blend'))
    (folder/'provenance.json').write_text(json.dumps({
        'asset':asset,'version':'v1','authoring_record':'art/source/world/village-landmarks/v1/author.py',
        'authoring_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'source_sha256':hashlib.sha256((folder/'model.blend').read_bytes()).hexdigest(),
        'textures':'Existing painted library in assets/world/textures/lush; packed into source and GLB.',
        'note':'Original geometry. No prior models overwritten. Edit the saved Blender source after handoff.'
    },indent=2)+'\n')


material('root_bark','795337','bark',.74)
material('root_bark_light','a17a47','bark',1.02)
material('root_bark_shadow','4c3d2b','bark',.48)
material('root_moss','567447')
material('root_gold','d8b663',emission=.38)
for name,col in [('leaf_deep','344f39'),('leaf_shadow','49623b'),('leaf_fern','658245'),('leaf_green','80a153'),('leaf_light','a8bc65'),('leaf_tip','c5cb7c')]:
    material(name,col)
material('hall_plaster','e9d8ad','plaster',.95)
material('hall_stone','c3b995','stone_block_warm',.94)
material('hall_stone_light','e2d6b5','stone_block_warm',1.13)
material('hall_timber','5e3d29','timber_dark',.75)
material('hall_oak','b58b50','plank_wood',.85)
material('hall_roof','397c7d','roof_tile_teal',.8)
material('hall_roof_light','5b9690','roof_tile_teal',1.05)
material('hall_roof_dark','2e555b','roof_tile_teal',.58)
material('hall_window','ffcf7e',emission=.24)
material('hall_iron','354444',metal=.4)
material('hall_brass','d6aa50',metal=.45)
material('hall_recess','252b28')
material('hall_banner','436e63')
material('hall_paper','eadcb5')

# Rootward: a broad, wind-shaped ancient oak, not a scaled ordinary tree.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
PART='Heartwood'
trunk = [(0,0,0),(-.35,.08,1.4),(-.48,.15,3.1),(-.10,.22,4.7),(.42,.18,6.3),(.18,.2,8.3)]
tube('Twisted ancient bole',trunk,[1.72,1.44,1.15,1.02,.72,.36],'root_bark',16)
# Raised bark flutes twist with the trunk rather than drawing a flat cylinder.
for j in range(14):
    a=math.tau*j/14
    points=[]
    for k, p in enumerate(trunk[:-1]):
        r=[1.65,1.42,1.14,1.0,.70][k]
        theta=a+k*.07
        points.append((p[0]+r*math.cos(theta),p[1]+r*math.sin(theta),p[2]))
    tube('Twisting bark ridge',points,[.15,.17,.14,.11,.065], 'root_bark_light' if j%3==0 else 'root_bark_shadow',5)
PART='Buttress roots'
for j in range(10):
    a=math.tau*j/10+.12
    reach=4.1+rng.uniform(-.45,.35)
    def point(r,z,angle=a):return (math.cos(angle)*r,math.sin(angle)*r,z)
    tube('Sculpted buttress', [point(.85,2.05),point(1.65,.85),point(2.7,.30),point(reach,.10)], [.47,.52,.34,.045], 'root_bark',8)
    tube('Moss along root', [point(1.6,.96),point(2.65,.48),point(reach-.2,.17)], [.12,.15,.025], 'root_moss',5)
    tube('Fine root fork',[point(2.5,.23),point(3.15,.12,a+.17),point(reach+.1,.06,a+.3)],[.18,.12,.015],'root_bark_light',6)
PART='Boughs'
for j in range(9):
    a=math.tau*j/9+.1
    z=3.8+(j%3)*.75
    reach=4.0+rng.uniform(-.3,1.0)
    p0=(-.3,.1,z)
    p1=(math.cos(a)*1.9,math.sin(a)*1.9,z+1.0)
    p2=(math.cos(a)*reach,math.sin(a)*reach,z+1.8)
    p3=(math.cos(a)*(reach+1.1),math.sin(a)*(reach+1.1),z+2.7)
    tube('Great sweeping bough',[p0,p1,p2,p3],[.56,.46,.27,.09],'root_bark',10)
    for side in [-1,1]:
        tip=(math.cos(a+side*.31)*(reach+1.4),math.sin(a+side*.31)*(reach+1.4),z+2.7)
        tube('Forked oak limb',[p1,p2,tip],[.30,.23,.045],'root_bark_light',8)
# A subtle golden fissure gives the namesake a restrained fantastical heart.
PART='Heart seams'
for points in [[(-.48,-1.42,.35),(-.58,-1.34,1.1),(-.45,-1.02,1.8),(-.30,-.97,2.3)],
               [(-.58,-1.34,1.1),(-.92,-1.09,1.53),(-1.08,-.89,1.9)]]:
    tube('Amber heartwood seam',points,[.045]*len(points),'root_gold',5)
# Polygonal, tiered crown: lower dark leaf pads, asymmetric sunlit upper lobes.
PART='Crown'
for layer,(z,radius,count) in enumerate([(6.1,5.2,17),(7.6,5.5,18),(9.0,3.9,13),(10.3,2.0,6)]):
    for j in range(count):
        a=math.tau*j/count+layer*.4
        r=radius*(.80+rng.random()*.25)
        if layer==3:r*=.65
        at=(math.cos(a)*r+.2,math.sin(a)*r,z+rng.uniform(-.35,.35))
        dims=(rng.uniform(2.7,3.9),rng.uniform(2.6,3.8),rng.uniform(1.5,2.2))
        base=['leaf_deep','leaf_shadow','leaf_fern','leaf_green'][layer]
        # Broad cut corners and sparse stepped edge pads retain the world's chunky silhouette.
        box('Angular leaf lobe',at,dims,base,.42,(0,0,rng.uniform(-.3,.3)))
        for k in range(4):
            offset=(rng.uniform(-1.1,1.1),rng.uniform(-1,1),dims[2]*.42+rng.uniform(-.1,.15))
            box('Sunlit leaf patch',tuple(at[i]+offset[i] for i in range(3)),(rng.uniform(.65,1.35),rng.uniform(.6,1.2),.24),
                ['leaf_fern','leaf_green','leaf_light','leaf_tip'][layer],.12)
    # Fill the crown's center without making an even sphere.
    box('Central crown tier',(.15,.2,z+.18),(radius*1.4,radius*1.2,1.85),['leaf_shadow','leaf_fern','leaf_green','leaf_light'][layer],.42)
finish('rootward-tree')

# Town hall: limestone plinth, cream half-timbered hall and a true open belfry.
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
PART='Masonry'
for course in range(3):
    for y in [-3.3,3.3]:
        for j in range(12):
            x=-3.85+j*.70
            if y<0 and abs(x)<.9:continue
            box('Limestone plinth course',(x,y,.12+course*.23),(.68,.28,.21),'hall_stone_light' if (course+j)%4==0 else 'hall_stone')
    for x in [-4.15,4.15]:
        for j in range(9):box('Plinth return',(x,-2.95+j*.73,.12+course*.23),(.28,.71,.21),'hall_stone')
PART='Hall walls'
for side in [-1,1]:
    box('Side plaster wall',(side*4.05,0,2.28),(.20,6.6,3.35),'hall_plaster')
box('Rear plaster wall',(0,3.3,2.28),(8.1,.20,3.35),'hall_plaster')
for side in [-1,1]:box('Front wall beside opening',(side*2.58,-3.3,2.28),(3.0,.20,3.35),'hall_plaster')
box('Front overdoor',(0,-3.3,3.42),(2.2,.2,1.1),'hall_plaster')
box('Dark entry recess',(0,-2.55,1.6),(2.0,.04,2.6),'hall_recess')
PART='Timber frame'
for y in [-3.43,3.43]:
    for x in [-4.0,-2.6,-1.05,1.05,2.6,4.0]:box('Pegged oak upright',(x,y,2.25),(.19,.22,3.7),'hall_timber')
    for z in [.74,3.78]:box('Continuous tie beam',(0,y,z),(8.4,.24,.24),'hall_timber')
    for side in [-1,1]:
        beam('Facade diagonal',(side*1.20,y,2.95),(side*2.45,y,3.67),.14,'hall_timber')
        beam('Outer corner brace',(side*3.95,y,2.92),(side*3.05,y,3.70),.16,'hall_timber')
for x in [-4.18,4.18]:
    for y in [-3.25,-1.65,0,1.65,3.25]:box('Side oak post',(x,y,2.25),(.22,.19,3.7),'hall_timber')
    for z in [.74,3.78]:box('Side tie beam',(x,0,z),(.24,6.9,.24),'hall_timber')
    for y in [-2.5,.8]:beam('Side angled brace',(x,y-.65,2.9),(x,y+.65,3.7),.13,'hall_timber')

def window(x,y,z,angle=0,width=.92,height=1.65):
    before=set(bpy.context.scene.objects)
    box('Deep window reveal',(0,0,0),(width+.20,.11,height+.20),'hall_timber')
    box('Warm divided window',(0,-.075,0),(width,.06,height),'hall_window')
    for xx in [-width/2,0,width/2]:box('Window oak mullion',(xx,-.13,0),(.055,.12,height+.13),'hall_oak')
    for zz in [-height/2,0,height/2]:box('Window crossbar',(0,-.13,zz),(width+.14,.12,.07),'hall_oak')
    box('Stone window ledge',(0,-.16,-height/2-.13),(width+.44,.45,.16),'hall_stone_light')
    rot=Matrix.Rotation(angle,4,'Z')
    for o in set(bpy.context.scene.objects)-before:
        o.location=rot@o.location+Vector((x,y,z))
        o.rotation_euler.z+=angle

PART='Windows'
for x in [-3.2,-1.8,1.8,3.2]:window(x,-3.46,2.08,width=.72)
for x,a in [(4.25,math.pi/2),(-4.25,-math.pi/2)]:
    for y in [-2.35,0,2.35]:window(x,y,2.15,a,width=1.15)
# Actual doubled oak leaf, with two hinges understood by the existing door adapter.
PART='Entrance'
for side in [-1,1]:
    for k in range(8):box('Dressed jamb stone',(side*1.04,-3.53,.54+k*.28),(.24,.38,.26),'hall_stone_light')
for k in range(11):ring('Segmental arch voussoir',(0,-3.53,2.66),1.18,.91,.38,'hall_stone_light' if k%3 else 'hall_stone',1,k*math.pi/11+.01,(k+1)*math.pi/11-.01)
for side in [-1,1]:
    hinge=bpy.data.objects.new('DoorHinge_L' if side<0 else 'DoorHinge_R',None)
    bpy.context.scene.collection.objects.link(hinge)
    hinge.location=(side*.9,-3.51,.25)
    bpy.context.view_layer.update()
    before=set(bpy.context.scene.objects)
    for j in range(5):
        x=side*(j+.5)*.18
        top=2.66+math.sqrt(max(0,.90**2-x*x))
        box('Double door board',(x,-3.51,(top+.25)/2),(.171,.12,top-.25),'hall_oak')
    for z in [.85,1.85]:box('Forged door strap',(side*.45,-3.59,z),(.78,.045,.07),'hall_iron')
    ring('Brass door pull',(side*.18,-3.62,1.3),.075,.042,.04,'hall_brass',12)
    for o in set(bpy.context.scene.objects)-before:
        matrix=o.matrix_world.copy()
        o.parent=hinge
        o.matrix_world=matrix
for outer,inner,width,top in [(4.55,3.9,2.65,.13),(4.05,2.7,2.4,.26)]:
    box('Broad entry tread',(0,-(outer+inner)/2,top/2),(width,outer-inner,top),'hall_stone_light',.025)
# Gable roof with individually staggered, overlapping teal tiles.
PART='Roof'
eave,ridge,half=3.98,6.70,4.65
angle=math.atan2(ridge-eave,half)
slope=math.hypot(half,ridge-eave)
for y in [-3.31,3.31]:
    mesh('Plaster gable',[(-4.08,y,3.9),(4.08,y,3.9),(0,y,6.33)],[(0,1,2),(2,1,0)],'hall_plaster')
    beam('Gable king post',(0,y-.06,3.85),(0,y-.06,6.5),.20,'hall_timber')
for side in [-1,1]:
    box('Roof underlay',(side*half/2,0,(eave+ridge)/2-.06),(slope,7.55,.16),'hall_roof_dark',.025,(0,side*angle,0))
    for row in range(12):
        dist=(row+.5)*slope/12
        for j in range(17):
            lo=max(-3.78,-3.78+j*.47-(.235 if row%2 else 0))
            hi=min(3.78,-3.78+j*.47-(.235 if row%2 else 0)+.455)
            if hi-lo<.06:continue
            box('Staggered teal shingle',(side*dist*math.cos(angle),(lo+hi)/2,ridge-dist*math.sin(angle)+.045),(slope/12+.06,hi-lo,.09),rng.choices(['hall_roof','hall_roof_light','hall_roof_dark'],[8,2,1])[0],.018,(0,side*angle,0))
    for y in [-3.87,3.87]:beam('Heavy carved bargeboard',(0,y,ridge+.08),(side*4.75,y,eave-.02),.19,'hall_timber')
    box('Roof fascia',(side*4.68,0,eave-.015),(.18,7.9,.24),'hall_timber')
    for y in [-2.95,-1.3,.4,2.2]:beam('Eave oak corbel',(side*4.07,y,3.45),(side*4.60,y,3.95),.13,'hall_oak')
for j in range(16):box('Roof ridge cap',(0,-3.56+j*.47,ridge+.08),(.38,.45,.16),'hall_roof_light',.045)
# Central front dormer clock/bell tower, with an open belfry and restrained cap.
PART='Clock tower'
tx,ty=0,-1.65
box('Tower plaster shaft',(tx,ty,6.14),(2.15,1.95,3.0),'hall_plaster')
for x in [-1.1,1.1]:
    for y in [ty-1.0,ty+1.0]:box('Tower oak corner',(x,y,6.2),(.20,.20,3.2),'hall_timber')
for z in [5.4,7.25,7.5]:box('Tower cornice',(0,ty,z),(2.5,2.3,.16),'hall_stone_light')
ring('Clock dark face',(0,ty-1.07,6.35),.69,0,.05,'hall_recess',32)
ring('Clock brass bezel',(0,ty-1.12,6.35),.75,.67,.07,'hall_brass',32)
for j in range(12):
    a=math.tau*j/12
    box('Clock hour marker',(.565*math.sin(a),ty-1.17,6.35+.565*math.cos(a)),(.045,.025,.12),'hall_brass',.005,(0,a,0))
beam('Clock minute hand',(0,ty-1.20,6.35),(.0,ty-1.20,6.82),.055,'hall_paper')
beam('Clock hour hand',(0,ty-1.22,6.35),(-.28,ty-1.22,6.50),.065,'hall_brass')
for x in [-.95,.95]:
    for y in [ty-.85,ty+.85]:
        box('Open belfry post',(x,y,8.05),(.18,.18,1.1),'hall_timber')
        for s in [-1,1]:beam('Belfry knee brace',(x,y,7.93),(x-s*.32,y,8.47),.09,'hall_oak')
box('Belfry lintel',(0,ty,8.55),(2.35,2.12,.20),'hall_timber')
beam('Bell axle',(-.9,ty,8.28),(.9,ty,8.28),.11,'hall_iron')
tube('Cast bronze bell',[(0,ty,7.65),(0,ty,7.73),(0,ty,8.06),(0,ty,8.25)],[.46,.38,.22,.17],'hall_brass',16)
box('Bell clapper',(0,ty,7.62),(.12,.12,.24),'hall_iron')
for side in [-1,1]:
    for axis in [0,1]:
        at=[0,ty,8.99]
        at[axis]+=side*.64
        dims=(1.85,2.65,.12) if axis==0 else (2.65,1.85,.12)
        rotation=(0,side*.56,0) if axis==0 else (-side*.56,0,0)
        box('Belfry copper hip cap',at,dims,'hall_roof',.035,rotation)
box('Tower finial',(0,ty,9.72),(.10,.10,.66),'hall_brass')
beam('Leaf weather vane',(-.42,ty,9.96),(.42,ty,9.96),.055,'hall_brass')
box('Vane leaf',(.42,ty,9.96),(.25,.05,.14),'hall_brass',.04,(0,.35,0))
# Civic details: nameboard, carved oak-tree seal, banners, porch notice papers.
PART='Civic details'
box('Hall nameboard',(0,-3.57,4.55),(3.35,.16,.52),'hall_timber',.035)
font=bpy.data.curves.new('Carved hall lettering','FONT')
font.body='TOWN HALL'
font.align_x='CENTER'
font.size=.32
font.extrude=.005
o=bpy.data.objects.new('Town Hall gold lettering',font)
bpy.context.scene.collection.objects.link(o)
o.location=(0,-3.67,4.44)
o.rotation_euler=(math.pi/2,0,0)
o.data.materials.append(M['hall_brass'])
bpy.context.view_layer.objects.active=o
o.select_set(True)
bpy.ops.object.convert(target='MESH')
o['part']=PART
for side in [-1,1]:
    box('Hanging green civic banner',(side*3.62,-3.68,2.63),(.44,.055,1.65),'hall_banner',.025)
    beam('Banner oak emblem',(side*3.62,-3.72,2.17),(side*3.62,-3.72,2.91),.035,'hall_brass')
    for dx,dz in [(-.12,.2),(.12,.3),(-.1,.43)]:beam('Banner emblem branch',(side*3.62,-3.72,2.4+dz/3),(side*3.62+dx,-3.72,2.5+dz),.03,'hall_brass')
# Noticeboard is wall mounted; no hidden new ground obstacle beyond the footprint.
box('Public noticeboard',(4.34,-1.2,1.8),(.12,1.28,1.10),'hall_timber')
for j in range(4):box('Pinned civic notice',(4.415,-1.65+j*.30,1.8+(j%2)*.12),(.025,.25,.58),'hall_paper',.006)
finish('morning-town-hall')
