"""One-time Blender authoring record for six unplaced scenery candidates.

Run once with Blender --background --factory-startup --python this-file.
Refuses existing sources. After this handoff, edit each saved model.blend and
use scripts/world-art.sh build <id>; this recipe is history, not the master.
Coordinates here are Blender Z-up, front -Y (Godot +Z), one metre per tile.
"""
import hashlib
import json
import math
import random
from pathlib import Path

import bpy
from mathutils import Vector, Matrix, Euler

ROOT = Path(__file__).resolve().parents[5]
IDS = ['hearth-oak', 'ridge-cedar', 'river-willow', 'hearth-house', 'lantern-loft', 'brook-mill']
for asset_id in IDS:
    if (ROOT / f'art/source/world/{asset_id}/v1/model.blend').exists():
        raise RuntimeError('Editable source already exists: ' + asset_id + '. Open it; never rerun the maker over edits.')

MAT = {}
PART = 'Structure'
PARENT = None
RNG = random.Random(231023)


def linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def material(name, color, texture=None):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    rgb = tuple(int(color[i:i+2], 16) / 255 for i in (0, 2, 4))
    m.diffuse_color = (*rgb, 1)
    bs = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value = (*map(linear, rgb), 1)
    bs.inputs['Roughness'].default_value = 0.92
    bs.inputs['Metallic'].default_value = 0
    if texture:
        image = bpy.data.images.load(str(ROOT / f'assets/world/textures/{texture}.png'), check_existing=True)
        node = m.node_tree.nodes.new('ShaderNodeTexImage')
        node.image = image
        node.interpolation = 'Closest'
        node.extension = 'REPEAT'
        m.node_tree.links.new(node.outputs['Color'], bs.inputs['Base Color'])
    MAT[name] = m
    return m


def materials():
    definitions = {
        'timber': ('49382f', 'solid/timber_dark'), 'oak': ('b07a45', 'lush/plank_wood'),
        'oak_edge': ('c59458', None), 'bark': ('765039', 'lush/bark'),
        'bark_dark': ('49382f', None), 'moss': ('638b41', None),
        'cream': ('e8ddbd', 'solid/plaster'), 'plaster_warm': ('d3c6a4', 'lush/plaster'),
        'stone': ('c8bb99', 'lush/stone_block_warm'), 'stone_edge': ('d4c9ad', None),
        'mortar': ('6b6251', None), 'grey': ('929a9a', 'lush/stone_block_grey'),
        'roof_violet': ('66509a', None), 'roof_violet_hi': ('8271b1', None),
        'roof_violet_dark': ('493c71', None), 'roof_teal': ('347b85', None),
        'roof_teal_hi': ('4c939b', None), 'roof_teal_dark': ('255560', None),
        'iron': ('394446', None), 'brass': ('e3b16a', None),
        'glass': ('526f7a', 'solid/window_glass'), 'glow': ('f0b45a', 'solid/window_glow'),
        'dark': ('263632', None), 'endgrain': ('c59458', None),
        'leaf': ('4d7e35', None), 'leaf_light': ('7ca946', None), 'leaf_dark': ('2e5835', None),
        'leaf_mid': ('638b41', None), 'cedar': ('3f7061', None), 'cedar_light': ('65936b', None),
        'cedar_dark': ('2d554c', None), 'willow': ('638b41', None),
        'willow_light': ('96b35a', None), 'willow_dark': ('416a40', None),
    }
    for name, (color, texture) in definitions.items():
        material(name, color, texture)


def mesh(name, verts, faces, mat, uv=True):
    data = bpy.data.meshes.new(name)
    data.from_pydata(verts, [], faces)
    data.materials.append(MAT[mat])
    data.update()
    obj = bpy.data.objects.new(name, data)
    bpy.context.scene.collection.objects.link(obj)
    obj['part'] = PART
    if PARENT:
        obj.parent = PARENT
        obj.matrix_parent_inverse = PARENT.matrix_world.inverted()
    if uv:
        layer = data.uv_layers.new(name='UVMap')
        for poly in data.polygons:
            normal = poly.normal
            axis = max(range(3), key=lambda k: abs(normal[k]))
            for li in poly.loop_indices:
                co = data.vertices[data.loops[li].vertex_index].co
                # World-sized box projection: one texture repeat per metre, grain stays vertical.
                coords = (co.y, co.z) if axis == 0 else ((co.x, co.z) if axis == 1 else (co.x, co.y))
                layer.data[li].uv = coords
    return obj


def box(name, at, size, mat, rotation=(0, 0, 0), bevel=0.018):
    x, y, z = (s / 2 for s in size)
    r = Euler(rotation).to_matrix()
    verts = [tuple(Vector(at) + r @ Vector(p)) for p in [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]]
    obj = mesh(name, verts, [(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)], mat)
    if bevel:
        modifier = obj.modifiers.new('Small hand-cut edges', 'BEVEL')
        modifier.width = min(bevel, min(size) * .22)
        modifier.segments = 1
        modifier.affect = 'EDGES'
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=modifier.name)
    return obj


def beam(name, a, b, width, mat='timber', depth=None):
    a, b = Vector(a), Vector(b)
    direction = b-a
    rotation = direction.to_track_quat('Z', 'Y').to_euler()
    return box(name, (a+b)*.5, (width, depth or width, direction.length), mat, rotation, min(.025,width*.12))


def cone(name, at, radius1, radius2, height, mat, sides=8):
    x,y,z = at
    verts = [(x+r*math.cos(t*math.tau/sides),y+r*math.sin(t*math.tau/sides),z+h) for r,h in [(radius1,0),(radius2,height)] for t in range(sides)]
    return mesh(name, verts, [tuple(reversed(range(sides))), tuple(range(sides,2*sides))] + [(i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides)], mat)


def branch(name, points, radii, mat='bark', sides=7):
    verts=[]
    for k,p in enumerate(points):
        tangent = Vector(points[min(k+1,len(points)-1)])-Vector(points[max(0,k-1)])
        rot=tangent.to_track_quat('Z','Y').to_matrix()
        for i in range(sides):
            angle=math.tau*i/sides+.17
            verts.append(tuple(Vector(p)+rot@Vector((radii[k]*math.cos(angle),radii[k]*math.sin(angle),0))))
    faces=[tuple(reversed(range(sides))),tuple(range((len(points)-1)*sides,len(points)*sides))]
    for k in range(len(points)-1):
        for i in range(sides):
            a=k*sides+i;b=k*sides+(i+1)%sides
            faces.append((a,b,b+sides,a+sides))
    return mesh(name,verts,faces,mat)


def foundation(w,d,base=.45):
    global PART
    PART='Masonry'
    box('Mortar core',(0,0,base/2),(w,d,base),'mortar')
    for row in range(2):
        h=base/2-.015
        n=math.ceil(w/.62)
        for side in [-1,1]:
            for i in range(n):
                x=-w/2+(i+.5)*w/n
                box('Limestone foundation course',(x,side*(d/2-.10),h/2+row*base/2+.012),(w/n-.016,.24,h),'stone' if (i+row)%4 else 'stone_edge')
            n2=math.ceil((d-.4)/.6)
            for i in range(n2):
                y=-(d-.4)/2+(i+.5)*(d-.4)/n2
                box('Limestone side course',(side*(w/2-.10),y,h/2+row*base/2+.012),(.24,(d-.4)/n2-.016,h),'stone')
    box('Foundation cap',(0,0,base-.025),(w+.06,d+.06,.12),'stone_edge')


def triangle(name, cx, y, width, eave, rise, mat):
    return mesh(name,[(cx-width/2,y-.09,eave),(cx+width/2,y-.09,eave),(cx,y-.09,eave+rise),(cx-width/2,y+.09,eave),(cx+width/2,y+.09,eave),(cx,y+.09,eave+rise)],[(0,2,1),(3,4,5),(0,1,4,3),(1,2,5,4),(2,0,3,5)],mat)


def roof(cx,cy,w,d,eave,rise,palette='violet',rows=None):
    global PART
    PART='Roof'
    half=w/2
    theta=math.atan2(rise,half)
    slope=math.hypot(half,rise)
    rows=rows or math.ceil(slope/.45)
    columns=math.ceil(d/.55)
    for s in [-1,1]:
        box('Roof underboard',(cx+s*half/2,cy,eave+rise/2-.08),(slope+.04,d+.06,.15),'timber',(0,s*theta,0))
        for row in range(rows):
            t=(row+.5)/rows
            # Full raised clay tiles with staggered vertical joints.
            cuts=[-d/2]
            offset=.5 if row%2 else 0
            cuts.extend(-d/2+(i+offset)*d/columns for i in range(columns+1) if 0<(i+offset)<columns)
            cuts.append(d/2)
            for k in range(len(cuts)-1):
                length=cuts[k+1]-cuts[k]-.012
                yy=cy+(cuts[k]+cuts[k+1])/2
                mat='roof_'+palette+RNG.choices(['','_hi','_dark'],[.74,.18,.08])[0]
                box('Staggered clay tile',(cx+s*t*half,yy,eave+rise*(1-t)+.035),(slope/rows+.045,length,.075),mat,(0,s*theta,0),.014)
        for end in [-1,1]:
            beam('Gable bargeboard',(cx,cy+end*(d/2+.04),eave+rise+.045),(cx+s*(half+.03),cy+end*(d/2+.04),eave-.015),.15,'timber',.12)
        box('Heavy eave fascia',(cx+s*(half+.005),cy,eave-.06),(.16,d+.17,.22),'timber')
        for yy in [cy-d*.34,cy,cy+d*.34]:
            beam('Eave bracket',(cx+s*(half-.20),yy,eave-.36),(cx+s*(half+.02),yy,eave-.07),.12,'oak_edge')
    for i in range(columns):
        box('Ridge cap',(cx,cy-d/2+(i+.5)*d/columns,eave+rise+.12),(.28,d/columns+.03,.16),'roof_'+palette+'_dark',bevel=.04)


def face_box(name, base, angle, x,z,out,size,mat,bevel=.018):
    rot=Matrix.Rotation(angle,3,'Z')
    p=Vector(base)+rot@Vector((x,-out,z))
    return box(name,p,size,mat,(0,0,angle),bevel)


def face_beam(name,base,angle,a,b,width,mat='timber'):
    rot=Matrix.Rotation(angle,3,'Z')
    return beam(name,Vector(base)+rot@Vector((a[0],-a[2],a[1])),Vector(base)+rot@Vector((b[0],-b[2],b[1])),width,mat)


def window(base,angle=0,w=.95,h=1.1,shutters=True):
    global PART
    PART='Windows'
    fb=lambda name,x,z,o,size,mat: face_box(name,base,angle,x,z,o,size,mat)
    fb('Recess shadow',0,0,.028,(w+.20,.045,h+.2),'dark')
    fb('Window pane',0,0,.055,(w,.045,h),'glow')
    for x in [-w/2-.055,w/2+.055]:
        fb('Window jamb',x,0,.105,(.11,.16,h+.21),'timber')
    for z in [-h/2-.055,h/2+.055]:
        fb('Window header',0,z,.105,(w,.16,.11),'timber')
    fb('Window mullion',0,0,.11,(.055,.10,h),'oak_edge')
    fb('Window transom',0,.07,.11,(w,.10,.055),'oak_edge')
    fb('Stone sill',0,-h/2-.16,.17,(w+.4,.34,.12),'stone_edge')
    if shutters:
        for s in [-1,1]:
            x=s*(w*.5+.23)
            fb('Teal shutter',x,0,.085,(.23,.09,h+.08),'roof_teal_dark')
            for z in [-h*.34,h*.34]:
                fb('Shutter strap',x,z,.145,(.26,.035,.04),'iron')
            for xx in [x-.067,x+.067]:
                fb('Shutter joint',xx,0,.138,(.012,.014,h),'roof_teal_hi')


def round_window(base,r=.46,angle=0):
    global PART
    PART='Windows'
    rot=Matrix.Rotation(angle,3,'Z')
    verts=[tuple(Vector(base)+rot@Vector((r*math.cos(i*math.tau/12),-.06,r*math.sin(i*math.tau/12)))) for i in range(12)]
    mesh('Round glass',verts,[tuple(range(12))],'glass')
    for i in range(12):
        a=i*math.tau/12;b=(i+1)*math.tau/12
        face_beam('Oculus stone ring',base,angle,(r*math.cos(a),r*math.sin(a),.09),(r*math.cos(b),r*math.sin(b),.09),.12,'stone_edge')
    face_box('Oculus mullion',base,angle,0,0,.105,(.055,.1,r*1.85),'oak_edge')
    face_box('Oculus cross',base,angle,0,0,.105,(r*1.85,.1,.055),'oak_edge')


def door(base,width=1.15,height=2.18,angle=0,arch=True):
    global PART
    PART='Door'
    rad=width/2
    spring=height-rad if arch else height
    for i in range(7):
        x=(i-3)*width/7
        top=spring+math.sqrt(max(0,rad**2-x*x)) if arch else height
        face_box('Door plank',base,angle,x,top/2,.04,(width/7-.012,.1,top),'oak')
    for z in [.45,1.25]:
        face_box('Door iron hinge',base,angle,0,z,.105,(width*.9,.035,.075),'iron')
        for x in [-width*.36,width*.36]:
            face_box('Door hinge rivet',base,angle,x,z,.13,(.045,.025,.045),'brass',.008)
    for s in [-1,1]:
        for k in range(6):
            face_box('Door stone jamb',base,angle,s*(rad+.13),spring*(k+.5)/6,.08,(.25,.25,spring/6-.015),'stone_edge' if k%2 else 'stone')
    if arch:
        rot=Matrix.Rotation(angle,3,'Z')
        for i in range(9):
            a=math.pi*i/9;b=math.pi*(i+1)/9
            vv=[]
            for depth in [-.045,-.24]:
                for rr,t in [(rad+.015,a+.016),(rad+.25,a+.016),(rad+.25,b-.016),(rad+.015,b-.016)]:
                    vv.append(tuple(Vector(base)+rot@Vector((rr*math.cos(t),depth,spring+rr*math.sin(t)))))
            mesh('Arch voussoir',vv,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'stone_edge' if i==4 else 'stone')
    else:
        face_box('Door lintel',base,angle,0,height+.08,.09,(width+.5,.25,.18),'timber')
    face_box('Door brass latch',base,angle,width*.29,.98,.135,(.065,.05,.19),'brass')
    face_box('Door handle',base,angle,width*.29,.94,.175,(.13,.08,.055),'iron')


def timber_frame(w,d,bottom,eave,middle=None):
    global PART
    PART='Timber'
    for x in [-w/2,w/2]:
        for y in [-d/2,d/2]:
            box('Corner post',(x,y,(bottom+eave)/2),(.22,.22,eave-bottom+.1),'timber')
    for z in [bottom+.08,eave-.05]+([middle] if middle else []):
        for side in [-1,1]:
            box('Girt front-back',(0,side*d/2,z),(w+.12,.19,.19),'timber')
            box('Girt side',(side*w/2,0,z),(.19,d,.19),'timber')
    for y,ang in [(-d/2,0),(d/2,math.pi)]:
        for x in [-w*.29,w*.29]:
            face_box('Intermediate upright',(0,y,0),ang,x,(bottom+eave)/2,.04,(.14,.17,eave-bottom),'timber')
            for z in ([bottom+.2,middle+.15] if middle else [bottom+.2]):
                face_beam('Diagonal brace',(0,y,0),ang,(x,z,.07),(x+(.65 if x<0 else -.65),z+.72,.07),.115)
    for side in [-1,1]:
        for y in [-d*.26,d*.26]:
            box('Side upright',(side*w/2,y,(bottom+eave)/2),(.19,.14,eave-bottom),'timber')


def chimney(x,y,base,top):
    global PART
    PART='Masonry'
    box('Chimney mortar',(x,y,(base+top)/2),(.64,.68,top-base),'mortar')
    n=math.ceil((top-base)/.26)
    for k in range(n):
        z=base+(k+.5)*(top-base)/n
        for side in [-1,1]:
            for i in range(2):
                box('Chimney stone',(x+(i-.5)*.34,y+side*.30,z),(.325,.17,(top-base)/n-.018),'stone')
                box('Chimney corner',(x+side*.27,y+(i-.5)*.26,z),(.17,.25,(top-base)/n-.018),'stone_edge' if k%4==0 else 'stone')
    box('Chimney cap',(x,y,top+.04),(.88,.90,.16),'stone_edge')
    box('Chimney dark opening',(x,y,top+.13),(.49,.49,.025),'dark',bevel=0)


def lantern(at):
    global PART
    PART='Fittings'
    x,y,z=at
    box('Lantern wall bracket',(x,y+.10,z+.28),(.10,.38,.09),'iron')
    box('Lantern amber pane',(x,y-.08,z),(.23,.20,.36),'glow')
    for sx in [-1,1]:
        for sy in [-1,1]:
            box('Lantern frame',(x+sx*.13,y-.08+sy*.12,z),(.035,.035,.42),'iron',bevel=.005)
    box('Lantern roof',(x,y-.08,z+.23),(.37,.33,.11),'iron')
    box('Lantern foot',(x,y-.08,z-.23),(.31,.28,.07),'brass')


def hearth_house():
    global PART
    w=d=4.8
    foundation(5,5,.42)
    PART='Walls'
    box('Cream walls',(0,0,1.69),(w,d,2.54),'cream')
    triangle('Front gable',0,-d/2,w,2.96,1.88,'plaster_warm')
    triangle('Rear gable',0,d/2,w,2.96,1.88,'plaster_warm')
    timber_frame(w,d,.42,2.96)
    # A broad central entry below a lower porch, flanked by shuttered windows.
    door((0,-d/2-.03,.18))
    for x in [-1.55,1.55]:
        window((x,-d/2,1.73),w=.78,h=1.02)
    for side in [-1,1]:
        for yy in [-1.1,1.15]:
            window((side*w/2,yy,1.72),angle=side*math.pi/2,w=.95,h=1.12)
    round_window((0,-d/2-.03,3.66),.43)
    round_window((0,d/2+.03,3.66),.36,math.pi)
    roof(0,0,5.65,5.65,2.95,2.05,'violet')
    PART='Porch'
    # Doorstep projects beyond the declared wall footprint; it is approach decoration.
    for k in range(2):
        box('Broad entry step',(0,-2.72-k*.26,.12-k*.06),(2.05+k*.3,.62,.12),'stone_edge')
    for x in [-1.04,1.04]:
        box('Porch post',(x,-3.10,1.28),(.17,.17,2.36),'timber')
        for s in [-1,1]:
            beam('Porch knee brace',(x,-3.10,1.95),(x+s*.32,-3.10,2.30),.11,'oak_edge')
    roof(0,-2.66,2.65,1.65,2.43,.72,'violet',rows=4)
    lantern((1.0,-2.53,1.72))
    chimney(-1.55,.6,2.35,5.72)
    # Separate shallow dormer, facing the visible east roof slope.
    PART='Dormer'
    box('Dormer cheek',(1.80,.75,3.90),(1.2,1.25,.75),'cream')
    # Dormer faces +X: tiny pitched roof rotates around the vertical axis as a whole.
    before=set(bpy.context.scene.objects)
    triangle('Dormer gable',0,-.65,1.35,4.24,.65,'cream')
    roof(0,0,1.65,1.5,4.24,.68,'violet',rows=3)
    rot=Matrix.Rotation(math.pi/2,3,'Z')
    for obj in set(bpy.context.scene.objects)-before:
        for vert in obj.data.vertices:
            vert.co = rot@vert.co+Vector((1.70,.75,0))
    window((2.36,.75,4.02),angle=math.pi/2,w=.65,h=.65,shutters=False)


def lantern_loft():
    global PART
    foundation(7,7,.46)
    PART='Walls'
    box('Ground floor plaster',(0,0,1.62),(6.48,6.48,2.32),'plaster_warm')
    box('Jettied upper floor',(0,0,4.0),(6.85,6.85,2.44),'cream')
    timber_frame(6.48,6.48,.46,2.80)
    timber_frame(6.85,6.85,2.79,5.24,3.05)
    for side in [-1,1]:
        for v in [-2.6,-1.3,0,1.3,2.6]:
            beam('Jetty corbel',(v,side*3.18,2.34),(v,side*3.51,2.83),.17,'oak_edge')
            beam('Side jetty corbel',(side*3.18,v,2.34),(side*3.51,v,2.83),.17,'oak_edge')
    PART='Walls'
    triangle('Tall front gable',0,-3.425,6.85,5.24,2.04,'cream')
    triangle('Tall back gable',0,3.425,6.85,5.24,2.04,'cream')
    for side in [-1,1]:
        for x in [-2.15,0,2.15]:
            window((x,side*3.425,4.15),angle=0 if side<0 else math.pi,w=1.0,h=1.23,shutters=False)
        for yy in [-1.7,1.7]:
            window((side*3.425,yy,4.18),angle=side*math.pi/2,w=1.04,h=1.25,shutters=False)
            window((side*3.24,yy,1.68),angle=side*math.pi/2,w=.88,h=1.05)
    door((-.85,-3.27,.15),width=1.30,height=2.28,arch=False)
    window((1.53,-3.24,1.65),w=1.10,h=1.17)
    roof(0,0,7.65,7.65,5.26,2.15,'teal')
    # Gable fan framing and small attic window.
    round_window((0,-3.46,6.1),.43)
    for s in [-1,1]:
        beam('Gable fan beam',(0,-3.49,7.10),(s*2.7,-3.49,5.34),.13)
        beam('Gable fan inner',(0,-3.50,7.10),(s*1.6,-3.50,5.34),.10,'oak_edge')
    PART='Balcony'
    box('Balcony deck',(-.65,-3.92,2.83),(3.75,1.15,.18),'oak')
    for x in [-2.38,1.08]:
        beam('Balcony support',(x,-3.24,1.85),(x,-4.32,2.78),.18)
    for i in range(10):
        x=-2.42+i*3.55/9
        box('Balcony baluster',(x,-4.43,3.32),(.075,.09,.86),'timber')
    box('Balcony front rail',(-.65,-4.43,3.78),(3.88,.14,.13),'oak_edge')
    for x in [-2.52,1.22]:
        box('Balcony return rail',(x,-3.93,3.78),(.13,1.14,.13),'oak_edge')
    # A projecting eight-sided stair oriel gives this house a different silhouette.
    PART='Turret'
    tx,ty=2.48,-2.52
    cone('Oriel lower bracket',(tx,ty,2.15),.38,1.04,.76,'timber')
    cone('Octagonal oriel',(tx,ty,2.91),1.03,1.03,2.76,'plaster_warm')
    for k in range(8):
        a=math.tau*k/8
        box('Oriel upright',(tx+1.03*math.cos(a),ty+1.03*math.sin(a),4.28),(.12,.12,2.82),'timber')
    cone('Oriel sill',(tx,ty,3.46),1.10,1.10,.13,'oak_edge')
    cone('Oriel cornice',(tx,ty,5.61),1.16,1.16,.18,'timber')
    for a in [-math.pi/2,-math.pi/4,0]:
        base=(tx+1.005*math.cos(a),ty+1.005*math.sin(a),4.61)
        window(base,angle=a+math.pi/2,w=.52,h=1.12,shutters=False)
    # Four overlapping octagonal roof skirts, ending in a brass finial.
    for k in range(6):
        z=5.82+k*.31
        radius=1.40*(1-k/6)
        cone('Turret tiled roof',(tx,ty,z),radius,max(.03,radius-.30),.39,'roof_teal' if k%2 else 'roof_teal_hi')
    cone('Brass finial',(tx,ty,7.65),.105,.025,.43,'brass')
    chimney(-2.25,1.05,4.3,8.02)
    lantern((.14,-3.38,1.96))
    for k in range(2):
        box('Loft doorstep',(-.85,-3.66-k*.24,.11-k*.05),(1.8+k*.25,.60,.12),'stone_edge')


def wheel(x,y,z,r=1.62):
    global PART,PARENT
    PART='Wheel'
    pivot=bpy.data.objects.new('waterwheel_pivot',None)
    bpy.context.scene.collection.objects.link(pivot)
    pivot.location=(x,y,z)
    pivot['role']='future rotating assembly; local X axle; no runtime behavior connected'
    bpy.context.view_layer.update()
    PARENT=pivot
    # Two open timber rims, reinforced with iron bands; no solid disk hides the spokes.
    for xx in [x-.38,x+.38]:
        for i in range(20):
            a=i*math.tau/20;b=(i+1)*math.tau/20
            beam('Wheel rim',(xx,y+r*math.cos(a),z+r*math.sin(a)),(xx,y+r*math.cos(b),z+r*math.sin(b)),.17,'oak')
            beam('Iron rim band',(xx+(.09 if xx>x else -.09),y+(r+.025)*math.cos(a),z+(r+.025)*math.sin(a)),(xx+(.09 if xx>x else -.09),y+(r+.025)*math.cos(b),z+(r+.025)*math.sin(b)),.047,'iron')
        for i in range(8):
            a=i*math.tau/8+.15
            beam('Wheel spoke',(xx,y,z),(xx,y+(r-.05)*math.cos(a),z+(r-.05)*math.sin(a)),.13,'oak_edge')
    for i in range(20):
        a=(i+.5)*math.tau/20
        box('Wheel paddle',(x,y+r*math.cos(a),z+r*math.sin(a)),(.92,.34,.14),'oak',(a,0,0))
        for side in [-1,1]:
            box('Paddle bolt',(x+side*.47,y+r*math.cos(a),z+r*math.sin(a)),(.04,.065,.065),'brass',bevel=.006)
    beam('Wheel axle',(x-1.1,y,z),(x+.72,y,z),.27,'timber')
    # Axle boss on the visible outside face.
    box('Axle boss',(x+.49,y,z),(.24,.50,.50),'iron',(math.pi/4,0,0))
    box('Axle pin',(x+.64,y,z),(.08,.18,.18),'brass')
    PARENT=None


def brook_mill():
    global PART
    foundation(6,5,.62)
    PART='Walls'
    box('Mill stone ground storey',(0,0,1.75),(5.82,4.82,2.3),'stone')
    box('Mill upper plaster',(0,0,3.87),(5.90,4.90,1.94),'cream')
    timber_frame(5.9,4.9,2.9,4.87)
    triangle('Mill front gable',0,-2.45,5.9,4.87,1.85,'plaster_warm')
    triangle('Mill rear gable',0,2.45,5.9,4.87,1.85,'plaster_warm')
    for side in [-1,1]:
        for row in range(6):
            for y in [-2.2,2.2]:
                box('Mill corner quoins',(side*2.91,y,.8+row*.32),(.33,.43,.27),'stone_edge')
    door((-.7,-2.45,.28),width=1.38,height=2.30)
    window((1.68,-2.45,1.85),w=.85,h=1.0,shutters=False)
    for side in [-1,1]:
        for yy in [-1.25,1.30]:
            window((side*2.95,yy,3.83),angle=side*math.pi/2,w=.80,h=1.08,shutters=False)
    for xx in [-1.78,1.78]:
        window((xx,-2.45,3.86),w=.82,h=1.08,shutters=False)
    # The upper loading hatch, crane and projecting covered hoist identify a working mill.
    door((0,-2.48,3.10),width=.98,height=1.70,arch=False)
    round_window((0,2.49,5.53),.44,math.pi)
    roof(0,0,6.65,5.65,4.88,1.98,'violet')
    PART='Hoist'
    box('Hoist projecting beam',(0,-3.03,5.38),(.22,1.65,.22),'timber')
    beam('Hoist diagonal',(0,-2.48,4.70),(0,-3.65,5.38),.14,'oak_edge')
    box('Hoist pulley housing',(0,-3.62,5.18),(.28,.25,.34),'iron')
    beam('Hoist rope',(0,-3.65,5.08),(0,-3.65,3.72),.035,'brass')
    box('Loading platform',(0,-2.98,3.03),(1.65,1.20,.18),'oak')
    for xx in [-.67,.67]:
        beam('Loading platform brace',(xx,-2.44,2.35),(xx,-3.43,2.98),.14)
    roof(0,-2.68,1.85,1.35,5.42,.68,'teal',rows=3)
    PART='Wheel supports'
    # Wheel sits low enough to meet a future river without lowering the building pivot.
    wheel(3.77,.23,1.77)
    for yy in [-.57,1.02]:
        box('Wheel bearing pier',(4.22,yy,.55),(.55,.55,1.10),'grey')
        beam('Wheel bearing brace',(4.22,yy,.95),(4.22,.23,1.77),.18)
    box('Bearing pillow',(4.22,.23,1.78),(.30,.47,.36),'iron')
    # Elevated timber launder with separate dry channel and a plausible feed to the wheel.
    PART='Launder'
    box('Sluice channel bed',(3.76,1.79,3.34),(.83,2.65,.13),'oak')
    for xx in [3.30,4.22]:
        box('Launder side wall',(xx,1.79,3.53),(.12,2.73,.46),'timber')
    for yy in [1.40,2.90]:
        for xx in [3.31,4.21]:
            box('Launder trestle',(xx,yy,1.70),(.18,.18,3.40),'timber')
        beam('Trestle cross brace',(3.31,yy,.80),(4.21,yy,2.88),.12,'oak_edge')
    box('Feed gate',(3.76,2.74,3.79),(.89,.10,.78),'oak')
    beam('Gate screw',(3.76,2.74,3.88),(3.76,2.74,4.51),.075,'iron')
    box('Gate hand crank',(3.76,2.74,4.52),(.52,.10,.08),'iron')
    PART='Masonry'
    chimney(-2.0,1.0,4.5,7.10)
    lantern((.39,-2.58,2.04))
    for k in range(3):
        box('Mill stair',(-.7,-2.70-k*.28,.30-k*.1),(2.08+k*.2,.70,.20),'stone_edge')


def foliage(clusters,step,mats,label):
    """Voxel surface union: no hidden cube faces, deterministic sculpted crown lobes."""
    cells={}
    for center,radii in clusters:
        lo=[math.floor((center[i]-radii[i])/step) for i in range(3)]
        hi=[math.ceil((center[i]+radii[i])/step) for i in range(3)]
        for x in range(lo[0],hi[0]+1):
            for y in range(lo[1],hi[1]+1):
                for z in range(lo[2],hi[2]+1):
                    v=sum((((n+.5)*step-center[i])/radii[i])**2 for i,n in enumerate((x,y,z)))
                    # Slightly irregular edge, not a regular ellipsoid or random loose cubes.
                    jitter=.08*math.sin(x*2.1+y*.8+z*1.7)
                    if v<1+jitter:
                        cells[(x,y,z)]=mats[(x*13+y*7+z*3)%len(mats)]
    verts_by={m:[] for m in mats};faces_by={m:[] for m in mats}
    dirs=[((1,0,0),[(1,0,0),(1,1,0),(1,1,1),(1,0,1)]),((-1,0,0),[(0,1,0),(0,0,0),(0,0,1),(0,1,1)]),((0,1,0),[(1,1,0),(0,1,0),(0,1,1),(1,1,1)]),((0,-1,0),[(0,0,0),(1,0,0),(1,0,1),(0,0,1)]),((0,0,1),[(0,0,1),(1,0,1),(1,1,1),(0,1,1)]),((0,0,-1),[(0,1,0),(1,1,0),(1,0,0),(0,0,0)])]
    for p,mat in cells.items():
        for direction,corners in dirs:
            if tuple(p[k]+direction[k] for k in range(3)) in cells:
                continue
            # Larger coherent patches keep the crown readable without confetti noise.
            shade=mat
            if direction[2]<0: shade=mats[-1]
            vv=verts_by[shade]; ff=faces_by[shade];a=len(vv)
            vv.extend(tuple((p[k]+c[k])*step for k in range(3)) for c in corners)
            ff.append(tuple(range(a,a+4)))
    for mat in dict.fromkeys(mats):
        if verts_by[mat]:mesh(label,verts_by[mat],faces_by[mat],mat,False)


def roots(radius=.48,span=1.2,count=6):
    for i in range(count):
        a=i*math.tau/count+.22
        x,y=math.cos(a),math.sin(a)
        branch('Buttress root',[(x*.12,y*.12,.50),(x*radius,y*radius,.22),(x*span,y*span,.065)],[.25,.19,.045])


def oak():
    global PART
    PART='Trunk'
    roots()
    branch('Ancient bent trunk',[(0,0,0),(-.18,.05,.8),(.04,.08,1.7),(-.15,.1,2.6),(.11,.16,3.4)],[.48,.36,.29,.24,.14])
    endpoints=[(-1.65,-.5,3.5),(1.6,-.15,3.6),(.4,1.3,3.8),(-.7,-1.1,4.25)]
    for i,end in enumerate(endpoints):
        start=(-.05,.08,1.85+i*.25)
        mid=((start[0]+end[0])*.45,(start[1]+end[1])*.45,2.6+i*.19)
        branch('Twisting scaffold limb',[start,mid,end],[.23,.17,.055])
        branch('Forked limb',[mid,(end[0]+.15,end[1]+.5,end[2]+.32)],[.13,.035])
    # Long vertical bark ridges and broad moss strips, plus a dark knot on the front.
    for i in range(8):
        a=i*math.tau/8
        branch('Bark ridge',[(.34*math.cos(a),.34*math.sin(a),.4),(.28*math.cos(a)-.11,.28*math.sin(a)+.05,1.1),(.24*math.cos(a),.24*math.sin(a)+.08,1.8)],[.033,.028,.022],'bark_dark',4)
    cone('Trunk knot',(.13,-.279,1.44),.15,.07,.16,'bark_dark')
    PART='Canopy'
    foliage([((-1.35,-.20,3.58),(1.38,1.38,.98)),((1.34,-.12,3.78),(1.37,1.32,1.04)),((.08,1.07,4.17),(1.55,1.35,1.1)),((-.55,-.92,4.52),(1.60,1.28,1.0)),((.46,.0,4.92),(1.55,1.43,.95))],.22,['leaf','leaf_mid','leaf','leaf_light','leaf_dark'],'Oak leaf crown')
    PART='Moss'
    for at,size in [((-.3,.25,.35),(.24,.29,.5)),((-.28,.25,.8),(.15,.12,.45)),((.4,.28,.14),(.55,.28,.12))]:
        box('Root moss',at,size,'moss',bevel=.02)


def cedar():
    global PART
    PART='Trunk'
    roots(.36,.86,5)
    branch('Leaning cedar trunk',[(0,0,0),(.10,.02,1.5),(.20,.08,3.0),(.35,.1,4.5),(.22,.03,6.3)],[.34,.25,.19,.12,.025])
    PART='Branches'
    clusters=[]
    for level,(z,rad) in enumerate([(1.85,1.8),(2.85,1.65),(3.85,1.35),(4.75,1.0),(5.6,.66)]):
        count=4 if level<3 else 3
        for i in range(count):
            a=i*math.tau/count+level*.83
            end=(.14+math.cos(a)*rad,.05+math.sin(a)*rad,z+.03)
            branch('Sweeping cedar bough',[(.15,.05,z+.32),(end[0]*.65,end[1]*.65,z-.12),end],[.14 if level<2 else .09,.07,.025])
            clusters.append(((end[0]*.64,end[1]*.64,z+.24),(rad*.69,rad*.65,.44)))
            # Fine branch-tip fans make flat bough pads rather than cone stacks.
            clusters.append(((end[0],end[1],z+.12),(.53,.49,.29)))
    clusters.append(((.22,.03,6.08),(.62,.57,.63)))
    PART='Canopy'
    foliage(clusters,.18,['cedar','cedar_light','cedar','cedar_dark'],'Cedar needle pads')
    PART='Bark'
    for i in range(7):
        a=i*math.tau/7
        branch('Cedar bark flute',[(math.cos(a)*.26,math.sin(a)*.26,.3),(.10+math.cos(a)*.2,.02+math.sin(a)*.2,1.4),(.2+math.cos(a)*.15,.08+math.sin(a)*.15,2.8)],[.025,.021,.018],'bark_dark',4)


def willow():
    global PART
    PART='Trunk'
    roots(.5,1.22,7)
    branch('Willow hollow trunk',[(0,0,0),(.10,.0,1.0),(-.22,.03,2.0),(-.3,.04,2.9)],[.46,.38,.29,.19])
    clusters=[]
    PART='Limbs'
    for i in range(8):
        a=i*math.tau/8+.17
        tip=(math.cos(a)*2.22,math.sin(a)*1.95,3.36+(i%3)*.22)
        mid=(math.cos(a)*1.2,math.sin(a)*1.1,4.0+(i%2)*.28)
        branch('Arched willow limb',[(-.17,.02,1.9),mid,tip],[.21,.12,.035])
        clusters.append(((mid[0]*.95,mid[1]*.95,4.06),(.95,.83,.52)))
        # Separated drooping fronds leave glimpses of the sculpted trunk.
        for j in range(3):
            aa=a+(j-1)*.18
            xx=math.cos(aa)*(2.05+j*.12);yy=math.sin(aa)*(1.85+j*.12)
            endz=1.12+(i*3+j)%4*.21
            branch('Hanging twig',[(xx*.80,yy*.80,3.65),(xx,yy,2.9),(xx*.98,yy*.98,endz)],[.025,.018,.006],'bark',4)
            for k in range(4):
                t=k/3
                clusters.append(((xx*(.90+.09*t),yy*(.90+.09*t),3.44-t*(3.44-endz)),(.43-.15*t,.40-.14*t,.54-.10*t)))
    clusters.extend([((-.45,-.05,4.50),(1.23,1.14,.59)),((.55,.45,4.35),(1.24,1.20,.64))])
    PART='Canopy'
    foliage(clusters,.18,['willow','willow_light','willow','willow_dark'],'Willow hanging foliage')
    PART='Moss'
    for at,size in [((-.38,.16,.29),(.24,.32,.4)),((-.40,.12,.6),(.14,.20,.32))]:
        box('Willow moss',at,size,'moss')


def finish(asset_id):
    # Batch by editable architectural role/material/parent, retaining a real wheel pivot.
    groups={}
    for obj in list(bpy.context.scene.objects):
        if obj.type=='MESH':
            key=(obj.get('part','Structure'),obj.data.materials[0].name,obj.parent.name if obj.parent else '')
            groups.setdefault(key,[]).append(obj)
    for (part,mat,parent),objects in groups.items():
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        obj=bpy.context.view_layer.objects.active
        obj.name=part.replace(' ','_')+'__'+mat
        obj.data.name=obj.name
    scene=bpy.context.scene
    scene.unit_settings.system='METRIC'
    scene.unit_settings.scale_length=1
    scene['rootward_status']='unplaced candidate; no area, collision or mechanism integration'
    scene['rootward_asset']=asset_id
    scene['rootward_source']='Editable Blender authority. Do not regenerate from historical author.py.'
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type=='VIEW_3D':
                space=area.spaces.active
                space.region_3d.view_location=(0,0,3)
                space.region_3d.view_distance=14
                space.region_3d.view_rotation=Euler((math.radians(60),0,math.radians(45))).to_quaternion()
                space.region_3d.view_perspective='ORTHO'
                space.shading.type='MATERIAL'
    bpy.context.preferences.filepaths.save_version=0
    bpy.ops.file.pack_all()
    folder=ROOT/f'art/source/world/{asset_id}/v1'
    folder.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(folder/'model.blend'))
    (folder/'provenance.json').write_text(json.dumps({
        'asset':asset_id,'version':'v1','status':'unplaced candidate','tool':'Blender '+bpy.app.version_string,
        'initial_authoring_record':'art/source/world/expansion-kit/v1/author.py',
        'record_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
        'seed':231023,'seed_scope':'deterministic geometry/tile variation only; no AI generation',
        'texture_source':'art/source/world/textures/v1/manifest.json',
        'authority':'saved model.blend; normal rebuild uses scripts/world-art.sh build '+asset_id,
    },indent=2)+'\n')


for asset_id,make in zip(IDS,[oak,cedar,willow,hearth_house,lantern_loft,brook_mill]):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MAT.clear()
    PART='Structure'
    PARENT=None
    RNG.seed(231023)
    materials()
    make()
    finish(asset_id)
    print('SAVED CANDIDATE',asset_id,flush=True)
