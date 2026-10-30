"""Deliberate review edit of existing masters; preserves first-pass sources."""
import bpy
from pathlib import Path
import hashlib
import json
import math
import random
import shutil
import sys
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[5]
KIND=sys.argv[sys.argv.index('--')+1]
ID={'tree':'painted-oak','cottage':'painted-cottage'}[KIND]
base=ROOT/'art/source/world'/ID/'v1'
source=base/'model.blend';backup=base/'model.pass-01.blend'
if backup.exists():raise RuntimeError('Review edit already recorded; open the current master.')
shutil.copy2(source,backup)
bpy.ops.wm.open_mainfile(filepath=str(source))
bpy.context.preferences.filepaths.save_version=0
rng=random.Random(262)

def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4

def colour(mat,hex):
    rgb=[linear(int(hex[i:i+2],16)/255) for i in [0,2,4]]
    node=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    node.inputs['Base Color'].default_value=(*rgb,1)
    mat.diffuse_color=(*rgb,1)

def uv(obj):
    layer=obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
    for face in obj.data.polygons:
        axis=max(range(3),key=lambda i:abs(face.normal[i]))
        axes=[i for i in range(3) if i!=axis]
        for li in face.loop_indices:
            p=obj.data.vertices[obj.data.loops[li].vertex_index].co
            layer.data[li].uv=(p[axes[0]],p[axes[1]])

if KIND=='tree':
    names=['leaf_shadow','leaf_deep','leaf_green','leaf_light','leaf_sun','leaf_gold']
    for name,hex in zip(names,['284e38','38643c','4f7c3f','70984a','8bad52','a3b866']):colour(bpy.data.materials[name],hex)
    old=bpy.data.objects['Sculpted stepped leaf crown']
    # Cluster centres cover the reviewed crown's exposed shell, with individual
    # offsets, volumes and bevels to break the long flat terrace faces.
    centres=set()
    for face in old.data.polygons:
        p=face.center-face.normal*.085
        key=tuple(round(float(p[i])/.34) for i in range(3))
        centres.add(key)
    bpy.data.objects.remove(old,do_unlink=True)
    groups={name:[] for name in names}
    for ix,iy,iz in sorted(centres):
        at=(ix*.34+rng.uniform(-.065,.065),iy*.34+rng.uniform(-.065,.065),iz*.34+rng.uniform(-.045,.045))
        size=rng.uniform(.33,.48)
        bpy.ops.mesh.primitive_cube_add(size=1,location=at)
        obj=bpy.context.object;obj.dimensions=(size*rng.uniform(.8,1.15),size*rng.uniform(.85,1.1),size*rng.uniform(.65,.95))
        bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
        mod=obj.modifiers.new('Leaf-clump softened corners','BEVEL');mod.width=size*.17;mod.segments=1
        bpy.ops.object.modifier_apply(modifier=mod.name)
        obj.rotation_euler.z=rng.uniform(-.12,.12)
        tone=1 if at[2]<3.0 else (2 if at[2]<3.8 else 3)
        tone+=rng.choices([-1,0,1],[2,6,3])[0]
        if at[0]<-.5 and at[1]>.5:tone-=1
        tone=max(0,min(5,tone))
        obj.data.materials.append(bpy.data.materials[names[tone]])
        uv(obj);groups[names[tone]].append(obj)
    # Compact render batches, retaining independent leaf-clump topology for ink.
    for name,objects in groups.items():
        if not objects:continue
        bpy.ops.object.select_all(action='DESELECT')
        for obj in objects:obj.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        bpy.ops.object.join()
        obj=bpy.context.object;obj.name='Painted leaf clumps '+name;obj['part']='Crown'
    note='The first review had broad flat terraces. Replaced only the crown by individually offset, bevelled leaf clumps in six deeper greens. Trunk and root extent unchanged.'
else:
    mat=bpy.data.materials.new('Painted honey grain');mat.use_nodes=True;colour(mat,'8b5e35')
    light=bpy.data.materials.new('Painted honey glint');light.use_nodes=True;colour(light,'d4a35e')
    def ribbon(name,points,width,material):
        vertices=[]
        for i,p in enumerate(points):
            w=width*(.28 if i in [0,len(points)-1] else 1)
            vertices.extend([(p[0],p[1],p[2]-w),(p[0],p[1],p[2]+w)])
        faces=[(i*2,i*2+1,i*2+3,i*2+2) for i in range(len(points)-1)]
        data=bpy.data.meshes.new(name);data.from_pydata(vertices,[],faces);data.materials.append(material);data.update()
        obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj);uv(obj)
    # Sparse, slightly bowed strokes suggest grain without reinstating texture
    # noise. The house front is -Y; return walls run along Y at +/-X.
    for course in [2,4,6,8,10]:
        z=.50+course*.215
        for side in [-1,1]:
            x0=side*1.10
            points=[(x0-.33+j*.22,-1.929,z+math.sin(j*.9)*.012) for j in range(4)]
            # Avoid the arch/reveal and its dressing.
            if abs(x0)>.9:ribbon('Drawn front grain',points,.009,mat)
        for side in [-1,1]:
            y0=rng.choice([-.95,.55])
            points=[(side*2.008,y0+j*.33,z+math.sin(j*.8)*.01) for j in range(4)]
            # Ribbons for this wall are vertical in X/Z instead of X/Y.
            vertices=[]
            for i,p in enumerate(points):
                w=.009*(.3 if i in [0,3] else 1)
                vertices.extend([(p[0],p[1],p[2]-w),(p[0],p[1],p[2]+w)])
            data=bpy.data.meshes.new('Return wall grain');data.from_pydata(vertices,[],[(0,1,3,2),(2,3,5,4),(4,5,7,6)]);data.materials.append(mat);data.update()
            obj=bpy.data.objects.new('Drawn return grain',data);bpy.context.scene.collection.objects.link(obj);uv(obj)
    # Slightly warmer cream in shade; the earlier model geometry is retained.
    for name,hex in [('study_stone','d1c2a0'),('study_stone_light','e5d5b0'),('study_stone_warm','c1b18d')]:colour(bpy.data.materials[name],hex)
    note='Retained the reviewed geometry and added sparse drawn timber grain strokes. Quiet warm masonry palette; no old bitmap sources altered.'

bpy.ops.wm.save_as_mainfile(filepath=str(source))
(base/'pass-02.json').write_text(json.dumps({'before_sha256':hashlib.sha256(backup.read_bytes()).hexdigest(),
 'after_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'backup':backup.name,'note':note,
 'source_edit':'art/source/world/illustrated-village/v1/refine_pass02.py'},indent=2)+'\n')
print('Reviewed source edit saved:',ID)
