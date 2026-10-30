"""Refine the saved tree: fit living gold to the actual root surfaces.
Retain the prior revision; do not regenerate the tree.
"""
import bpy, math, shutil, random
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path.cwd();p=ROOT/'art/source/world/rootward-tree/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(p))
if bpy.context.scene.get('root_surface_light'):raise RuntimeError('Revision already applied.')
backup=p.with_name('model.pre-surface-light.blend')
if not backup.exists():shutil.copy2(p,backup)
verts=[];faces=[]
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.get('part') not in ['Buttress roots','Heartwood']:continue
    start=len(verts);verts.extend(o.matrix_world@v.co for v in o.data.vertices)
    faces.extend(tuple(start+i for i in f.vertices) for f in o.data.polygons)
surface=BVHTree.FromPolygons(verts,faces)
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o.get('part')=='Enchantment' and o.data.materials[0].name=='rootward_living_gold':
        # Keep the small ward glyphs; remove only the earlier freehand root lines.
        # Their joined object is reconstructed with the glyph geometry below.
        bpy.data.objects.remove(o,do_unlink=True)
gold=bpy.data.materials['rootward_living_gold']
n=next(n for n in gold.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
n.inputs['Base Color'].default_value=(.65,.38,.08,1)
n.inputs['Emission Color'].default_value=(.65,.38,.08,1)
n.inputs['Emission Strength'].default_value=1.4
stone=bpy.data.materials['rootward_moonstone']
n=next(n for n in stone.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
n.inputs['Base Color'].default_value=(.07,.13,.10,1)
n.inputs['Emission Strength'].default_value=0
def mesh(name,vertices,polygons):
    d=bpy.data.meshes.new(name);d.from_pydata(vertices,[],polygons);d.materials.append(gold);d.update()
    uv=d.uv_layers.new(name='UVMap')
    for f in d.polygons:
        for li in f.loop_indices:
            co=d.vertices[d.loops[li].vertex_index].co;uv.data[li].uv=(co.x,co.y)
    o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);o['part']='Root surface light';return o
all_verts=[];all_faces=[]
for j in range(10):
    a=math.tau*j/10+.12
    for branch in [0,-1,1]:
        points=[]
        for k in range(28):
            t=k/27;r=1.7+t*4.55
            theta=a+branch*max(0,t-.25)*.22
            x,y=r*math.cos(theta),r*math.sin(theta)
            hit=surface.ray_cast(Vector((x,y,18)),Vector((0,0,-1)))[0]
            if hit is None:continue
            points.append(hit+Vector((0,0,.025)))
        # Tiny luminous strips follow the bark as a seam, not floating light spikes.
        for q in range(len(points)-1):
            aa,bb=points[q],points[q+1]
            if (bb-aa).length>1.0:continue
            width=.035 if branch==0 else .018
            across=Vector((-math.sin(a)*width,math.cos(a)*width,0))
            start=len(all_verts);all_verts.extend([aa-across,aa+across,bb+across,bb-across]);all_faces.append(tuple(start+i for i in range(4)))
# Small angular runes, rather than luminous crosses, inset on each old ward stone.
for j in range(28):
    a=math.tau*j/28;center=Vector((8.2*math.cos(a),8.2*math.sin(a),.202))
    radial=Vector((math.cos(a),math.sin(a),0));tangent=Vector((-math.sin(a),math.cos(a),0))
    for aa,bb in [(center-radial*.12,center+tangent*.11),(center+tangent*.11,center+radial*.12)]:
        side=(bb-aa).cross(Vector((0,0,1))).normalized()*.018
        start=len(all_verts);all_verts.extend([aa-side,aa+side,bb+side,bb-side]);all_faces.append(tuple(start+i for i in range(4)))
mesh('Living gold fitted to bark and ward stones',all_verts,all_faces)
# Leaf-scale facets soften the large planar pads without hiding their silhouette.
leafverts=[];leaffaces=[];rng=random.Random(73026)
canopy=[];canopyfaces=[]
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.get('part')!='Crown':continue
    start=len(canopy);canopy.extend(o.matrix_world@v.co for v in o.data.vertices)
    canopyfaces.extend(tuple(start+i for i in f.vertices) for f in o.data.polygons)
tree=BVHTree.FromPolygons(canopy,canopyfaces)
for j in range(1600):
    x,y=rng.uniform(-12,12),rng.uniform(-12,12)
    hit,normal,_,_=tree.ray_cast(Vector((x,y,30)),Vector((0,0,-1)))
    if hit is None or normal.z<.3:continue
    hit.z+=.015
    r=rng.uniform(.09,.24);dx=Vector((r,0,0));dy=Vector((0,r*.65,0))
    start=len(leafverts);leafverts.extend([hit-dx,hit+dy,hit+dx,hit-dy]);leaffaces.append(tuple(start+i for i in range(4)))
o=mesh('Tiny sunlit oak leaves',leafverts,leaffaces);o.data.materials.clear();o.data.materials.append(bpy.data.materials['leaf_light']);o['part']='Crown'
bpy.context.scene['root_surface_light']=True
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(p))
