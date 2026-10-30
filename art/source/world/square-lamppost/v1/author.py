"""One-time, deliberate Blender source edit. Refuses an existing editable master."""
from pathlib import Path
import hashlib
import json
import math
import random

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[5]
HERE = Path(__file__).resolve().parent
SOURCE = ROOT / 'art/source/world/lamppost/v1/model.blend'
OUTPUT = HERE / 'model.blend'
if OUTPUT.exists():
    raise RuntimeError('Open the existing square lamp master; authoring never overwrites it.')
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
bpy.context.preferences.filepaths.save_version = 0

# Retain the adopted hierarchy and the straight timber section from its combined
# wood batch. The original file is preserved; this is a separate design study.
post = bpy.data.objects['wood_geometry']
world_vertices = [post.matrix_world @ v.co for v in post.data.vertices]
keep_faces = [p for p in post.data.polygons if all(world_vertices[i].y > -.15 for i in p.vertices)]
used = sorted({i for p in keep_faces for i in p.vertices})
remap = {old: new for new, old in enumerate(used)}
mesh = bpy.data.meshes.new('Retained adopted timber')
mesh.from_pydata([world_vertices[i] for i in used], [], [[remap[i] for i in p.vertices] for p in keep_faces])
root = bpy.data.objects['lamppost']
root.name = 'Square lamp'
for obj in list(bpy.context.scene.objects):
    if obj.type == 'MESH':
        bpy.data.objects.remove(obj, do_unlink=True)

def linear(c):
    return c / 12.92 if c <= .04045 else ((c + .055) / 1.055) ** 2.4

def material(name, color, emission=0):
    if bpy.data.materials.get(name):
        bpy.data.materials[name].name = 'Earlier ' + name
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    rgb = tuple(linear(int(color[i:i+2], 16) / 255) for i in (0, 2, 4))
    mat.diffuse_color = (*rgb, 1)
    bsdf = next(n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
    bsdf.inputs['Base Color'].default_value = (*rgb, 1)
    bsdf.inputs['Roughness'].default_value = .88
    if emission:
        bsdf.inputs['Emission Color'].default_value = (*rgb, 1)
        bsdf.inputs['Emission Strength'].default_value = emission
    return mat

mats = {k: material(k, v) for k, v in {
    'square_oak': '70503a', 'square_oak_light': '98734b',
    'square_oak_shadow': '493829', 'square_iron': '343639',
    'square_iron_edge': '53555a', 'square_brass': 'ae8547',
    'square_limestone': 'cabd98', 'square_stone_light': 'e1d3b1',
    'square_stone_shade': 'acaa8d', 'square_mortar': '817c64',
    'square_soil': '554432', 'square_leaf_dark': '285445',
    'square_leaf': '487247', 'square_leaf_light': '7d9950',
    'square_bud': 'ddb65e', 'lamp_glass': 'e7ad53',
}.items()}

def put(obj, name, mat, group=None, bevel=0):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(mats[mat])
    obj.parent = group or root
    if bevel:
        mod = obj.modifiers.new('Soft painted arris', 'BEVEL')
        mod.width = bevel
        mod.segments = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier=mod.name)
    return obj

def box(name, at, size, mat, bevel=.012):
    bpy.ops.mesh.primitive_cube_add(size=1, location=at)
    obj = bpy.context.object
    obj.dimensions = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return put(obj, name, mat, bevel=bevel)

def beam(name, a, b, width, mat, depth=None):
    a, b = Vector(a), Vector(b)
    obj = box(name, (a+b)*.5, (width, depth or width, (b-a).length), mat, .008)
    obj.rotation_euler = (b-a).to_track_quat('Z', 'Y').to_euler()
    return obj

def frustum(name, at, bottom, top, height, mat):
    vertices = [(x*w*.5, y*w*.5, z) for w,z in [(bottom,-height*.5),(top,height*.5)] for x,y in [(-1,-1),(1,-1),(1,1),(-1,1)]]
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], [(3,2,1,0),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)])
    obj = bpy.data.objects.new(name,data)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = at
    return put(obj,name,mat,bevel=.009)

# Quiet, warm timber with one broad highlighted edge, rather than a noisy
# photographic grain. The retained post is shifted into the rear of the planter.
obj = bpy.data.objects.new('Adopted timber post', mesh)
bpy.context.scene.collection.objects.link(obj)
obj.location = (-.17,.12,0)
put(obj,obj.name,'square_oak',bevel=.012)
box('Long sunlit timber edge',(-.218,.025,1.79),(.025,.012,1.70),'square_oak_light',.004)
box('Iron socket',(-.19,.12,.58),(.27,.27,.42),'square_iron')
box('Socket chamfer',(-.19,.12,.80),(.23,.23,.06),'square_iron_edge')
box('Post crown',(-.19,.12,2.75),(.28,.28,.10),'square_iron')
box('Crown glint',(-.19,.12,2.805),(.21,.21,.028),'square_iron_edge',.007)
beam('Hanging arm',(-.19,.13,2.63),(-.19,-.57,2.63),.12,'square_iron')
beam('Small angled support',(-.19,.05,2.31),(-.19,-.36,2.60),.055,'square_iron')
box('Timber arm face',(-.255,-.19,2.645),(.012,.50,.036),'square_oak_light',.003)

# A square, slightly tapering lantern. Its panes are one separate, lightable mesh.
cx,cy = -.19,-.53
box('Lantern foot',(cx,cy,1.91),(.43,.43,.075),'square_iron')
frustum('Tapered amber panes',(cx,cy,2.145),.32,.38,.41,'lamp_glass')
for sx in [-1,1]:
    for sy in [-1,1]:
        beam('Dark lantern corner',(cx+sx*.16,cy+sy*.16,1.96),(cx+sx*.19,cy+sy*.19,2.35),.036,'square_iron')
box('Canopy dark lip',(cx,cy,2.36),(.48,.48,.055),'square_iron')
frustum('Sloping rain hood',(cx,cy,2.455),.47,.15,.16,'square_iron')
box('Roof top highlight',(cx,cy,2.54),(.16,.16,.025),'square_iron_edge',.007)
beam('Suspension',(cx,cy,2.54),(cx,cy,2.64),.045,'square_iron')
for z in [.72,2.58]:
    box('Iron post strap',(-.19,.12,z),(.205,.205,.046),'square_iron',.006)
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8,ring_count=4,radius=.022,location=(-.19,.008,z))
    put(bpy.context.object,'Hammered brass pin','square_brass')

# Limestone planter: broad blocks with dark mortar joints and bevel highlights.
# Height and width fit the same adjacent grid passages as the old pedestal.
box('Planter mortar',(0,0,.23),(.76,.76,.42),'square_mortar',.018)
for row in range(2):
    z=.125+row*.19
    for side in range(4):
        for part in range(2):
            a=-.205+part*.41
            at = [(a,-.375,z),(.375,a,z),(-a,.375,z),(-.375,-a,z)][side]
            dims = (.39,.13,.175) if side%2==0 else (.13,.39,.175)
            box('Limestone course',at,dims,['square_limestone','square_stone_light','square_stone_shade'][(side+row+part)%3],.018)
for side in range(4):
    at=[(0,-.375,.455),(.375,0,.455),(0,.375,.455),(-.375,0,.455)][side]
    size=(.88,.15,.095) if side%2==0 else (.15,.59,.095)
    box('Rounded coping',at,size,'square_stone_light',.023)
box('Visible soil',(0,0,.445),(.59,.59,.045),'square_soil',.004)

# Broad irregular leaf clumps instead of a stack of identical cubes.
rng=random.Random(26)
for i in range(26):
    z=rng.uniform(.51,1.05)
    t=(z-.51)/.54
    radius=.25*(1-t*.65)
    angle=rng.random()*math.tau
    x=.08+math.cos(angle)*rng.uniform(.02,radius)
    y=-.03+math.sin(angle)*rng.uniform(.02,radius)
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=rng.uniform(.10,.16)*(1-t*.2),location=(x,y,z))
    leaf=bpy.context.object
    leaf.scale=(1,.85,1.15)
    put(leaf,'Evergreen leaf cluster',['square_leaf_dark','square_leaf','square_leaf_light'][0 if i%5==0 else (2 if z>.8 else 1)])
for x,y,z in [(.22,-.19,.61),(-.12,-.18,.58),(.18,.15,.67)]:
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=.031,location=(x,y,z))
    put(bpy.context.object,'Small golden bud','square_bud')

# A hand-authored warm gradient on the pane, packed into the editable source.
# It becomes the lit material's albedo/emission map without a runtime service.
image=bpy.data.images.new('Painted amber pane',width=64,height=64,alpha=True)
pixels=[]
for y in range(64):
    for x in range(64):
        u,v=x/63,y/63
        center=max(0,1-abs(u-.5)*1.7)*max(0,1-abs(v-.47)*1.25)
        rgb=[(214+40*center)/255,(131+108*center)/255,(38+116*center)/255]
        pixels.extend([*rgb,1])
image.pixels=pixels
image.pack()
mat=mats['lamp_glass']
bsdf=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
bsdf.inputs['Base Color'].default_value=(1,1,1,1)
texture=mat.node_tree.nodes.new('ShaderNodeTexImage');texture.image=image
mat.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
panes=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.data.materials and o.data.materials[0]==mat)
bpy.context.view_layer.objects.active=panes
bpy.ops.object.select_all(action='DESELECT');panes.select_set(True)
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.cube_project(cube_size=.42);bpy.ops.object.mode_set(mode='OBJECT')
scene=bpy.context.scene
scene.unit_settings.system='METRIC';scene.unit_settings.scale_length=1
scene['rootward_source']='Editable square lamp authority; earlier adopted lamp preserved.'
for obj in [o for o in scene.objects if o.type=='MESH' and not o.data.uv_layers]:
    bpy.context.view_layer.objects.active=obj
    bpy.ops.object.select_all(action='DESELECT');obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=1);bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.wm.save_as_mainfile(filepath=str(OUTPUT))
(HERE/'provenance.json').write_text(json.dumps({
    'asset':'square-lamppost','version':'v1','date':'2026-10-26',
    'derived_from':str(SOURCE.relative_to(ROOT)),
    'original_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'reference':'reference/voxel-isometric.png',
    'authoring_record':'author.py',
    'note':'Deliberate new design from the earlier post; original untouched. model.blend is now authority.'
},indent=2)+'\n')
print('Saved square lamp',OUTPUT)
