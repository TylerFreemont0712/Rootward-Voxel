"""One deliberate edit of existing adopted masters, plus two new authored shop buildings.

Run in Blender from the repository root with -- <asset-id>. Existing files must not already
carry this revision. This is a recorded source edit, not a replacement seed/build pipeline.
Normal subsequent work edits model.blend and uses scripts/world-art.sh build <id>.
"""
import hashlib
import json
import math
from pathlib import Path
import shutil
import sys

import bpy
import bmesh
from mathutils import Vector

ROOT = Path.cwd()
sys.path.insert(0, str(ROOT / 'pipeline'))
from blender_retexture import retexture_material, uv_object

ID = sys.argv[sys.argv.index('--') + 1]
CATALOG = json.loads((ROOT / 'pipeline/world-catalog.json').read_text())
TEXTURES = ROOT / 'assets/world/textures/lush'
RECIPES = {}
REVISION = '2026-10-24-buildings-v1'


def material(name, texture=None, tile=1, color=(1, 1, 1), emission=0):
    mat = bpy.data.materials.get(name)
    if mat is None:
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
        bsdf.inputs['Base Color'].default_value = (*color, 1)
        bsdf.inputs['Roughness'].default_value = .92
        if texture:
            retexture_material(mat, {'texture': texture, 'tile': tile, 'mode': 'world', 'emission': emission}, TEXTURES)
    if texture:
        RECIPES[name] = {'texture': texture, 'tile': tile, 'mode': 'world'}
    return mat


def box(name, at, size, mat, rotation=None):
    x, y, z = (v / 2 for v in size)
    verts = [(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)]
    faces = [(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]
    obj = mesh(name, verts, faces, mat)
    obj.location = at
    if rotation: obj.rotation_euler = rotation
    return obj


def mesh(name, verts, faces, mat):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


def beam(name, a, b, width, depth, mat):
    a, b = Vector(a), Vector(b)
    obj = box(name, (a+b)/2, (width,depth,(b-a).length), mat)
    obj.rotation_euler = (b-a).to_track_quat('Z','Y').to_euler()
    return obj


def ring(name, at, radius, tube, mat, axis='Y'):
    # Low-poly torus, deliberately front facing for a readable knocker or bracket ring.
    verts, faces = [], []
    for i in range(16):
        a = i*math.tau/16
        for j in range(6):
            b = j*math.tau/6
            r = radius+tube*math.cos(b)
            p = (r*math.cos(a),tube*math.sin(b),r*math.sin(a))
            if axis == 'Z': p = (p[0],p[2],p[1])
            verts.append(tuple(p[k]+at[k] for k in range(3)))
    for i in range(16):
        for j in range(6):faces.append((i*6+j,((i+1)%16)*6+j,((i+1)%16)*6+(j+1)%6,i*6+(j+1)%6))
    return mesh(name, verts, faces, mat)


def component_edit(obj, predicate, shift=None):
    bm = bmesh.new(); bm.from_mesh(obj.data)
    todo = set(bm.verts); erase = []
    while todo:
        first = todo.pop(); connected = [first]; stack = [first]
        while stack:
            for edge in stack.pop().link_edges:
                for other in edge.verts:
                    if other in todo:todo.remove(other);stack.append(other);connected.append(other)
        points = [obj.matrix_world@v.co for v in connected]
        lo = Vector(tuple(min(v[k] for v in points) for k in range(3)))
        hi = Vector(tuple(max(v[k] for v in points) for k in range(3)))
        if predicate(lo, hi):
            if shift:
                offset = obj.matrix_world.inverted().to_3x3() @ Vector(shift)
                for v in connected:v.co += offset
            else:erase.extend(connected)
    if erase:bmesh.ops.delete(bm,geom=erase,context='VERTS')
    bm.to_mesh(obj.data);bm.free()


def entrance(front, width=1.04, height=2.05, bottom=.17, center=0):
    oak = material('entrance_oak','plank_wood',1.2)
    stone = material('entrance_stone','limestone_flags',1.5)
    dark = material('entrance_recess',color=(.055,.033,.022))
    iron = material('iron',color=(.08,.105,.11))
    brass = material('gold',color=(.65,.39,.11))
    radius=width/2; spring=bottom+height-radius
    box('Entrance shadow reveal',(center,front+.035,bottom+height*.5),(width+.1,.1,height+.06),dark)
    # Tall planks clipped to one continuous arched silhouette; small gaps retain their legibility.
    for index in range(7):
        x=(index/6-.5)*(width-.13)
        top=spring+math.sqrt(max(0,radius*radius-x*x))
        box('Entrance oak plank',(center+x,front-.015,(bottom+top)/2),(width/7-.009,.11,top-bottom),oak)
    for side in [-1,1]:
        for row in range(5):
            z=bottom+(spring-bottom)*(row+.5)/5
            box('Entrance jamb stone',(center+side*(radius+.105),front-.035,z),(.19,.22,(spring-bottom)/5-.012),stone)
    for i in range(9):
        low=i*math.pi/9+.012; high=(i+1)*math.pi/9-.012
        points=[]
        for y in [front+.08,front-.15]:
            for r,a in [(radius+.015,low),(radius+.015,high),(radius+.21,high),(radius+.21,low)]:
                points.append((center+r*math.cos(a),y,spring+r*math.sin(a)))
        mesh('Entrance arch voussoir',points,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],stone)
    for z in [bottom+.36,bottom+height*.66]:
        box('Entrance strap hinge',(center-width*.16,front-.09,z),(width*.65,.045,.07),iron)
        for x in [-.34,.1]:box('Entrance hinge stud',(center+x*width,front-.121,z),(.035,.025,.035),brass)
    box('Entrance knocker plate',(center+width*.27,front-.1,bottom+height*.43),(.12,.04,.18),iron)
    ring('Entrance brass knocker',(center+width*.27,front-.16,bottom+height*.41),.075,.018,brass)
    box('Entrance threshold',(center,front-.1,bottom-.045),(width+.42,.52,.12),stone)
    box('Entrance lower step',(center,front-.4,.055),(width+.62,.34,.11),stone)


def roof_materials():
    entries={}
    for mat in list(bpy.data.materials):
        name=mat.name
        if not (name.startswith('roof') or name in ['teal','teal_dark','teal_light']):continue
        teal='teal' in name
        tint=.82 if name.endswith('dark') else (1.06 if name.endswith(('light','hi')) else .96)
        recipe={'texture':'roof_tile_teal' if teal else 'roof_tile_violet','mode':'world','tile':1.2,'tint':tint,'roughness':.94}
        retexture_material(mat,recipe,TEXTURES);entries[name]=recipe
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':uv_object(obj,entries)


def lamp_polish():
    iron=material('iron');brass=material('gold',color=(.66,.42,.14))
    # Preserve lamp_glass exactly and keep all cage pieces separate from it.
    box('Lantern metal plinth',(0,-.62,1.91),(.48,.48,.075),iron)
    box('Lantern cap brim',(0,-.62,2.31),(.52,.52,.065),iron)
    box('Lantern cap crown',(0,-.62,2.38),(.35,.35,.085),iron)
    box('Lantern cap finial',(0,-.62,2.47),(.09,.09,.13),brass)
    for x in [-.21,.21]:
        for y in [-.83,-.41]:
            box('Lantern brass cage',(x,y,2.105),(.025,.025,.34),brass)
    ring('Lantern suspension ring',(0,-.62,2.58),.075,.018,iron)
    beam('Bracket diagonal',(0,-.08,2.3),(0,-.48,2.63),.075,.075,iron)
    for z in [.63,.83,2.56]:
        box('Post iron collar',(-.02,0,z),(.29,.23,.055),iron)
        box('Post brass rivet',(-.02,-.125,z),(.045,.025,.045),brass)
    box('Pedestal rain cap',(-.02,0,.47),(.65,.63,.07),material('stone_light'))


def edit_existing():
    source=ROOT/CATALOG['assets'][ID]['source']
    bpy.ops.wm.open_mainfile(filepath=str(source))
    if bpy.context.scene.get('rootward_building_revision')==REVISION:
        raise RuntimeError('This source was already deliberately edited. Open the saved master for later revisions.')
    backup=source.with_name('model.pre-building-polish.blend')
    if not backup.exists():shutil.copy2(source,backup)
    before=hashlib.sha256(source.read_bytes()).hexdigest()
    if ID=='lamppost':lamp_polish()
    else:
        roof_materials()
        if ID in ['cottage','mill-house','log-cabin','log-cabin-large','log-cabin-large-teal']:
            large=ID.startswith('log-cabin-large'); cottage=ID in ['cottage','mill-house']
            front=-2.43 if large else (-1.5 if cottage else -1.53)
            half=.77 if large else .66
            for obj in list(bpy.context.scene.objects):
                if obj.type=='MESH':
                    component_edit(obj,lambda lo,hi:lo.x>=-half and hi.x<=half and hi.y<front+.2 and hi.z<2.6 and lo.z<2.3)
            entrance(front,width=1.08 if large else .86,height=2.2 if large else 1.82)
        elif ID=='lantern-loft':
            # Align the existing ground entrance with the logical, centre-front doorstep.
            for obj in bpy.context.scene.objects:
                if obj.type=='MESH' and obj.name.startswith('Door__'):obj.location.x+=.85
            for obj in bpy.context.scene.objects:
                if obj.type=='MESH' and obj.name.startswith('Fittings__stone'):
                    component_edit(obj,lambda lo,hi:hi.z<.3,shift=(.85,0,0))
        elif ID=='brook-mill':
            for obj in bpy.context.scene.objects:
                if obj.type=='MESH' and obj.name.startswith('Door__'):
                    component_edit(obj,lambda lo,hi:hi.z<2.9,shift=(.7,0,0))
        # A threshold marker makes the real entry distinguishable from lit windows and cargo doors.
        if ID in ['hearth-house','lantern-loft','brook-mill']:
            front={'hearth-house':-2.68,'lantern-loft':-3.5,'brook-mill':-2.72}[ID]
            box('Entrance threshold marker',(0,front,.16),(1.18,.36,.09),material('entrance_stone','limestone_flags',1.5))
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':uv_object(obj,RECIPES)
    bpy.context.scene['rootward_building_revision']=REVISION
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all();bpy.ops.wm.save_mainfile()
    (source.parent/'building-polish.json').write_text(json.dumps({'revision':REVISION,'asset':ID,'before_sha256':before,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':backup.name,'script':'art/source/world/building-polish/v1/edit_sources.py','note':'Deliberate edit of existing source; original geometry retained except selected entrance components. Common painted roof scale, readable door hardware/thresholds; lamp glass preserved.'},indent=2)+'\n')


def shop_building():
    source=ROOT/'art/source/world'/ID/'v1/model.blend'
    if source.exists():raise RuntimeError('New building already has an adopted source; edit it directly.')
    bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
    # New bespoke masters. Shared helper proportions are explicit, with distinct bakery/forge forms.
    stone=material('stone','limestone_flags',1.5)
    brick=material('brick','red_brick',1)
    plaster=material('plaster','limewash',1.5)
    wood=material('wood','plank_wood',1.2)
    dark=material('wood_dark','plank_wood',1.2)
    iron=material('iron',color=(.07,.10,.105))
    gold=material('gold',color=(.62,.34,.085))
    glass=material('window_warm','window_glow',1,emission=.45)
    shadow=material('recess',color=(.04,.025,.02))
    bakery=ID=='hollow-bakery'
    w,d=5.0 if bakery else 6.0,4.0 if bakery else 5.0
    front=-d/2
    box('Dressed limestone footing',(0,0,.17),(w,d,.34),stone)
    if bakery:box('Cream bakery walls',(0,0,1.64),(w-.18,d-.18,2.62),plaster)
    else:
        box('Smithy stone hall',(-1.05,0,1.65),(3.7,d-.18,2.65),stone)
        box('Smithy open bay back',(1.8,d/2-.15,1.6),(2.15,.18,2.6),brick)
    eave=3.0;ridge=4.8;half=w/2+.28
    roof=material('roof_teal' if not bakery else 'roof_violet','roof_tile_teal' if not bakery else 'roof_tile_violet',1.2)
    for side in [-1,1]:
        angle=side*math.atan2(ridge-eave,half)
        box('Painted tiled roof',(side*half/2,0,(ridge+eave)/2),(math.hypot(half,ridge-eave),d+.6,.14),roof,(0,angle,0))
        for y in [-d/2-.33,d/2+.33]:
            beam('Oak bargeboard',(side*.02,y,ridge),(side*(half+.08),y,eave-.04),.14,.16,wood)
        box('Eave fascia',(side*(half-.03),0,eave-.08),(.15,d+.65,.2),wood)
    box('Tile ridge cap',(0,0,ridge+.07),(.22,d+.72,.18),roof)
    for y in [front+.04,-front-.04]:
        verts=[(-w/2+.08,y,eave),(w/2-.08,y,eave),(0,y,ridge-.04)]
        # Double sided prism rather than a one-sided gable plane.
        verts += [(x,y+.1,z) for x,y,z in verts]
        mesh('Infilled gable',verts,[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],plaster)
        box('Gable collar',(0,y-.06,eave), (w,.16,.18),wood)
        beam('Gable king post',(0,y-.06,eave),(0,y-.06,ridge-.1),.14,.15,wood)
    for x in [-w/2+.06,w/2-.06]:
        for y in [front+.02,-front-.02]:
            box('Corner timber',(x,y,1.7),(.17,.2,2.8),wood)
    entrance(front-.15,width=1.05,height=2.13)
    def window(x,y,z,width=1.05):
        box('Window recess',(x,y,z),(width+.18,.16,1.3),shadow)
        box('Amber panes',(x,y-.1,z),(width,.05,1.12),glass)
        for offset in [-width/2,width/2]:box('Window jamb',(x+offset,y-.15,z),(.09,.12,1.28),wood)
        for h in [-.6,0,.6]:box('Window rail',(x,y-.15,z+h),(width+.1,.12,.085),wood)
        box('Window mullion',(x,y-.15,z),(.07,.12,1.2),wood)
        box('Window stone sill',(x,y-.18,z-.7),(width+.3,.42,.12),stone)
    if bakery:
        window(-1.62,front-.08,1.6,1.05)
        box('Bread display shelf',(-1.62,front-.38,1.03),(1.2,.53,.1),wood)
        for x in [-1.98,-1.62,-1.26]:
            box('Display golden loaf',(x,front-.35,1.19),(.26,.3,.2),gold,(0,.08,0))
        box('Brick oven breast',(1.64,front-.02,1.2),(1.15,.6,1.65),brick)
        box('Oven mouth',(1.64,front-.34,1.12),(.8,.035,.72),shadow)
        for i in range(7):
            a=(i+.5)*math.pi/7
            box('Oven arch brick',(1.64+.46*math.cos(a),front-.38,1.36+.46*math.sin(a)),(.2,.2,.21),brick,(0,-a,0))
        box('Baking hearth',(1.64,front-.42,.72),(1.3,.8,.13),stone)
        chimney_at=(1.6,.8);chimney_top=5.8
    else:
        window(-1.85,front-.07,1.65,.95)
        box('Open workbay header',(1.8,front,2.9),(2.25,.24,.22),wood)
        box('Forge firebrick base',(1.8,.85,.65),(1.5,1.45,.9),brick)
        box('Forge chimney breast',(1.8,1.35,2.15),(1.3,.5,2.3),brick)
        fire=material('forge_embers','window_glow',1,emission=.8)
        box('Forge dark firebox',(1.8,.95,1.27),(1.08,.6,.37),shadow)
        box('Forge amber coals',(1.8,.48,1.13),(.7,.45,.055),fire)
        box('Anvil stump',(1.8,-1.5,.52),(.8,.72,.55),wood)
        box('Anvil foot',(1.8,-1.5,.85),(.7,.48,.12),iron)
        box('Anvil waist',(1.8,-1.5,1.02),(.38,.34,.26),iron)
        box('Anvil face',(1.8,-1.5,1.22),(1.02,.43,.16),iron)
        beam('Anvil tapered horn',(2.2,-1.5,1.21),(2.52,-1.5,1.17),.13,.16,iron)
        for z in [1.0,1.65,2.3]:box('Tool rack rail',(1.8,2.24,z),(1.5,.12,.08),wood)
        for x in [1.25,1.7,2.15]:beam('Hanging forge tongs',(x,2.12,1.5),(x+.1,2.12,2.35),.04,.04,iron)
        chimney_at=(1.8,1.25);chimney_top=6.0
    x,y=chimney_at
    box('Brick flue',(x,y,4.1),(.83,.83,chimney_top-2.2),brick)
    box('Chimney cap',(x,y,chimney_top), (1.04,1.04,.17),stone)
    box('Chimney dark opening',(x,y,chimney_top+.09),(.58,.58,.025),shadow)
    # A shape sign reads at the actual camera scale without small lettering.
    sx=-w/2+.15
    beam('Shop sign arm',(sx,front,2.65),(sx,front-.85,2.65),.065,.065,iron)
    box('Shop sign board',(sx,front-.73,2.23),(.72,.1,.6),wood)
    if bakery:
        box('Bread sign loaf',(sx,front-.8,2.25),(.53,.08,.22),gold)
        for dx in [-.17,0,.17]:box('Bread sign scoring',(sx+dx,front-.85,2.27),(.035,.02,.15),stone,(0,.3,0))
    else:
        box('Anvil sign top',(sx,front-.8,2.36),(.53,.07,.11),iron)
        box('Anvil sign waist',(sx,front-.8,2.23),(.2,.07,.2),iron)
        box('Anvil sign base',(sx,front-.8,2.1),(.43,.07,.09),iron)
    for obj in bpy.context.scene.objects:
        if obj.type=='MESH':uv_object(obj,RECIPES)
    bpy.context.scene['rootward_building_revision']=REVISION
    bpy.context.scene['rootward_source']='Adopted editable master. Do not regenerate.'
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    bpy.context.preferences.filepaths.save_version=0
    source.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(source))
    (source.parent/'provenance.json').write_text(json.dumps({'asset':ID,'authoring':'Bespoke Blender mesh source; shared painted village materials','script':'art/source/world/building-polish/v1/edit_sources.py','revision':REVISION,'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'note':'One-time original authoring; edit this saved master for later changes.'},indent=2)+'\n')


if ID in ['hollow-bakery','hollow-smithy']:shop_building()
else:edit_existing()
