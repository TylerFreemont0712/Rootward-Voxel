"""One-time Blender helpers for the Kindle Hollow library. Saved .blend files become the masters.

One metre = one cell, Z up, front -Y. Chunky silhouettes, flat facets, painted world-scale UVs.
Geometry is combined by semantic part/material; moving parts keep their own authored ground-relative pivot.
"""
from collections import defaultdict
from pathlib import Path
import math

import bpy
from mathutils import Euler, Vector

ROOT = Path(__file__).resolve().parents[5]
TEXTURES = ROOT / 'assets/world/textures/lush'
PALETTE = {
    'oak': ('b07a45', 'plank_wood'), 'oak_light': ('c59458', 'plank_wood'),
    'wood': ('765039', 'log_wood'), 'wood_dark': ('49382f', 'timber_dark'),
    'stone': ('929a9a', 'stone_block_grey'), 'stone_light': ('c8bb99', 'stone_block_warm'),
    'stone_dark': ('626f73', 'stone_block_grey'), 'plaster': ('e8ddbd', 'plaster'),
    'iron': ('394446', 'iron'), 'brass': ('cfa65e', 'brass'),
    'copper': ('b87949', None), 'copper_light': ('d49b64', None),
    'cloth_teal': ('347b85', None), 'cloth_light': ('78aaa5', None),
    'cloth_plum': ('66509a', None), 'cloth_lilac': ('9882b7', None),
    'cream': ('eee1ba', None), 'linen': ('d6cba9', None), 'rust': ('9c573d', None),
    'roof': ('66509a', 'roof_tile_violet'), 'roof_teal': ('347b85', 'roof_tile_teal'),
    'leaf': ('4d7e35', None), 'leaf_light': ('7ca946', None), 'leaf_dark': ('2e5835', None),
    'hay': ('d9a94e', None), 'hay_light': ('ecc86c', None), 'soil': ('755846', 'soil'),
    'clay': ('b86b45', None), 'clay_light': ('d68d62', None),
    'glass_teal': ('69acac', None), 'glass_blue': ('779bb7', None),
    'glass_violet': ('9a7fae', None), 'silver': ('afc1ba', None),
    'bread': ('bf8746', None), 'bread_light': ('e0b776', None), 'cheese': ('e5c36e', None),
    'water': ('68b2b0', None), 'moss': ('5c7844', None),
    'state_glow': ('86e4d1', None), 'state_flame': ('f5b75f', None),
}


def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4


def materials():
    result = {}
    for name, (colour, texture) in PALETTE.items():
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        rgb = tuple(int(colour[i:i + 2], 16) / 255 for i in (0, 2, 4))
        mat.diffuse_color = (*rgb, 1)
        bsdf = mat.node_tree.nodes.get('Principled BSDF')
        bsdf.inputs['Base Color'].default_value = (*map(linear, rgb), 1)
        bsdf.inputs['Roughness'].default_value = .9 if name not in ['brass', 'copper', 'silver', 'iron'] else .55
        bsdf.inputs['Metallic'].default_value = .35 if name in ['brass', 'copper', 'silver', 'iron'] else 0
        if texture:
            image = bpy.data.images.load(str(TEXTURES / (texture + '.png')), check_existing=True)
            node = mat.node_tree.nodes.new('ShaderNodeTexImage')
            node.image = image
            node.interpolation = 'Closest'
            mat.node_tree.links.new(node.outputs['Color'], bsdf.inputs['Base Color'])
        if name.startswith('state_'):
            bsdf.inputs['Emission Color'].default_value = (*map(linear, rgb), 1)
            bsdf.inputs['Emission Strength'].default_value = 1.5
        result[name] = mat
    return result


class Model:
    def __init__(self):
        self.geometry = defaultdict(lambda: [[], []])
        self.pivots = {'body': (0, 0, 0)}
        self.part = 'body'

    def moving(self, pivot):
        self.pivots['mechanism'] = pivot
        self.part = 'mechanism'

    def fixed(self):
        self.part = 'body'

    def mesh(self, vertices, faces, material, part=None):
        verts, polys = self.geometry[(part or self.part, material)]
        offset = len(verts)
        verts.extend(vertices)
        polys.extend(tuple(i + offset for i in face) for face in faces)

    def box(self, at, size, material='oak', rotation=(0, 0, 0)):
        basis = Euler(rotation).to_matrix()
        corners = [Vector((x * size[0], y * size[1], z * size[2])) for x, y, z in
                   [(-.5,-.5,-.5),(.5,-.5,-.5),(.5,.5,-.5),(-.5,.5,-.5),
                    (-.5,-.5,.5),(.5,-.5,.5),(.5,.5,.5),(-.5,.5,.5)]]
        vertices = [tuple(basis @ c + Vector(at)) for c in corners]
        self.mesh(vertices, [(3,2,1,0),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)], material)

    def beam(self, start, end, width=.07, material='wood', depth=None):
        vector = Vector(end) - Vector(start)
        if vector.length < .0001:
            return
        rotation = vector.to_track_quat('Z', 'Y').to_euler()
        self.box(tuple((Vector(start) + Vector(end)) * .5), (width, depth or width, vector.length), material, rotation)

    def cylinder(self, at, radius, height, material='oak', sides=12, axis='Z', top=None):
        top = radius if top is None else top
        vertices = []
        basis = Euler((0, math.pi / 2, 0) if axis == 'X' else ((math.pi / 2, 0, 0) if axis == 'Y' else (0,0,0))).to_matrix()
        for z, r in [(-height * .5, radius), (height * .5, top)]:
            for i in range(sides):
                p = Vector((math.cos(i * math.tau / sides) * r, math.sin(i * math.tau / sides) * r, z))
                vertices.append(tuple(basis @ p + Vector(at)))
        faces = [tuple(reversed(range(sides)))]
        if top > 0:
            faces.append(tuple(range(sides, sides * 2)))
        faces.extend((i,(i+1)%sides,i+sides) if top == 0 else (i,(i+1)%sides,(i+1)%sides+sides,i+sides) for i in range(sides))
        self.mesh(vertices, faces, material)

    def ring(self, at, radius, inner, depth, material='iron', axis='Z', sides=12):
        basis = Euler((0, math.pi / 2, 0) if axis == 'X' else ((math.pi / 2, 0, 0) if axis == 'Y' else (0,0,0))).to_matrix()
        vertices = []
        for z, r in [(-depth*.5,radius),(depth*.5,radius),(-depth*.5,inner),(depth*.5,inner)]:
            for i in range(sides):
                p=Vector((math.cos(i*math.tau/sides)*r,math.sin(i*math.tau/sides)*r,z))
                vertices.append(tuple(basis@p+Vector(at)))
        faces=[]
        for i in range(sides):
            j=(i+1)%sides
            faces.extend([(i,j,j+sides,i+sides),(i+2*sides,i+3*sides,j+3*sides,j+2*sides),
                          (i+2*sides,j+2*sides,j,i),(i+sides,j+sides,j+3*sides,i+3*sides)])
        self.mesh(vertices,faces,material)

    def ellipsoid(self, at, size, material='clay', sides=10, rings=5):
        vertices=[]
        for r in range(rings+1):
            latitude=-math.pi*.5+math.pi*r/rings
            for i in range(sides):
                angle=math.tau*i/sides
                vertices.append((at[0]+size[0]*.5*math.cos(latitude)*math.cos(angle),
                                 at[1]+size[1]*.5*math.cos(latitude)*math.sin(angle),
                                 at[2]+size[2]*.5*math.sin(latitude)))
        faces=[]
        for r in range(rings):
            for i in range(sides):
                j=(i+1)%sides
                if r == 0:
                    faces.append((r*sides+i,(r+1)*sides+j,(r+1)*sides+i))
                elif r == rings-1:
                    faces.append((r*sides+i,r*sides+j,(r+1)*sides+i))
                else:
                    faces.append((r*sides+i,r*sides+j,(r+1)*sides+j,(r+1)*sides+i))
        self.mesh(vertices,faces,material)

    def wheel(self, at, radius=.35, axis='X', spokes=8):
        self.ring(at,radius,radius-.055,.08,'iron',axis)
        self.ring(at,radius-.04,radius-.1,.085,'oak',axis)
        self.cylinder(at,.085,.15,'brass',axis=axis)
        for i in range(spokes):
            angle=math.tau*i/spokes
            radial=(0,math.cos(angle),math.sin(angle)) if axis=='X' else (math.cos(angle),math.sin(angle),0)
            self.beam(at,tuple(a+b*(radius-.07) for a,b in zip(at,radial)),.045,'oak_light')

    def bowl(self, at, radius=.25, material='cream'):
        self.cylinder((at[0],at[1],at[2]+.07),radius*.7,.14,material,top=radius)
        self.cylinder((at[0],at[1],at[2]+.145),radius*.85,.012,'wood_dark')
        self.ring((at[0],at[1],at[2]+.15),radius,radius*.82,.035,material)

    def jug(self, at, radius=.13, height=.36, material='clay'):
        self.cylinder((at[0],at[1],at[2]+height*.35),radius,height*.7,material,top=radius*.75)
        self.cylinder((at[0],at[1],at[2]+height*.8),radius*.48,height*.23,material)
        self.ring((at[0],at[1],at[2]+height*.94),radius*.61,radius*.36,.045,material)
        self.ring((at[0]+radius,at[1],at[2]+height*.65),radius*.7,radius*.4,.045,material,axis='Y',sides=8)

    def bottle(self, at, height=.32, material='glass_teal'):
        self.cylinder((at[0],at[1],at[2]+height*.34),height*.22,height*.68,material,sides=8)
        self.cylinder((at[0],at[1],at[2]+height*.79),height*.10,height*.23,material,sides=8)
        self.cylinder((at[0],at[1],at[2]+height*.95),height*.12,height*.09,'oak',sides=8)
        self.box((at[0],at[1]-height*.22,at[2]+height*.37),(height*.22,.012,height*.23),'cream')

    def leaf(self, at, size=.2, material='leaf', tilt=0):
        self.ellipsoid(at,(size,size*.45,size*.4),material,sides=6,rings=3)

    def finish(self, material_bank):
        groups={}
        for part,pivot in self.pivots.items():
            group=bpy.data.objects.new(part,None)
            group.location=pivot
            group['rootward_part']=part
            bpy.context.scene.collection.objects.link(group)
            groups[part]=group
        for (part, material),(verts,faces) in self.geometry.items():
            if not verts:
                continue
            pivot=Vector(self.pivots[part])
            data=bpy.data.meshes.new(part+'_'+material)
            data.from_pydata([tuple(Vector(v)-pivot) for v in verts],[],faces)
            data.materials.append(material_bank[material])
            data.update()
            uv=data.uv_layers.new(name='UVMap')
            for polygon in data.polygons:
                axis=max(range(3),key=lambda k:abs(polygon.normal[k]))
                for index in polygon.loop_indices:
                    point=data.vertices[data.loops[index].vertex_index].co+pivot
                    uv.data[index].uv=(point.y,point.z) if axis==0 else ((point.x,point.z) if axis==1 else (point.x,point.y))
            obj=bpy.data.objects.new(part+'_'+material,data)
            obj.parent=groups[part]
            obj['material_role']=material
            bpy.context.scene.collection.objects.link(obj)
        return groups


def legs(m, w, d, h, material='wood_dark', thickness=.10):
    for x in [-w*.5+thickness*.7,w*.5-thickness*.7]:
        for y in [-d*.5+thickness*.7,d*.5-thickness*.7]:
            m.box((x,y,h*.5),(thickness,thickness,h),material)


def tabletop(m,w,d,h,planks=5):
    m.box((0,0,h-.08),(w,.9*d,.12),'wood_dark')
    for i in range(planks):
        m.box((0,-d*.5+(i+.5)*d/planks,h),(w,d/planks-.012,.08),'oak_light' if i%3==0 else 'oak')


def roof(m,w,d,z,material='roof',pitch=.38):
    # Two sloping slabs, with a capped ridge. Front is the low -Y eave.
    length=math.hypot(d*.5,pitch)
    angle=math.atan2(pitch,d*.5)
    for sign in [-1,1]:
        m.box((0,sign*d*.25,z+pitch*.5),(w,length,.10),material,(-sign*angle,0,0))
        m.box((0,sign*d*.5,z-.035),(w+.03,.09,.13),'wood_dark')
    m.box((0,0,z+pitch+.04),(w+.06,.13,.12),material)


def cabinet(m,w,d,h):
    m.box((0,0,h*.5),(w,d,h),'wood_dark')
    m.box((0,0,.08),(w+.08,d+.07,.16),'oak')
    m.box((0,0,h),(w+.10,d+.10,.11),'oak_light')
    for x in [-w*.5+.06,w*.5-.06]:
        m.box((x,-d*.5-.025,h*.5),(.1,.08,h),'oak')


def drawer(m,x,y,z,w,h):
    m.box((x,y,z),(w,.065,h),'oak')
    m.box((x,y-.035,z),(w-.07,.025,h-.06),'wood')
    m.cylinder((x,y-.07,z),.032,.045,'brass',sides=8,axis='Y')


def flame(m,at,size=.3):
    m.ellipsoid((at[0],at[1],at[2]+size*.45),(size*.6,size*.55,size),'state_flame',sides=6,rings=4)
    m.ellipsoid((at[0]+size*.12,at[1],at[2]+size*.8),(size*.3,size*.3,size*.65),'state_flame',sides=5,rings=3)


def gem(m,at,size=.4,material='glass_teal'):
    m.cylinder((at[0],at[1],at[2]+size*.35),size*.23,size*.7,material,sides=6,top=size*.20)
    m.cylinder((at[0],at[1],at[2]+size*.82),size*.20,size*.24,material,sides=6,top=0)
