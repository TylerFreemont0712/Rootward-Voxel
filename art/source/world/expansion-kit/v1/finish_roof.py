"""Deliberate Blender-source edit: finish the loft's broken-pitch roof cage after camera review."""
import math
from pathlib import Path
import bpy
import bmesh
from mathutils import Vector, Euler

ROOT=Path(__file__).resolve().parents[5]
path=ROOT/'art/source/world/lantern-loft/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(path))
if bpy.context.scene.get('finished_gambrel'):
    raise RuntimeError('Roof already finished; use the editable source.')


def mesh(name,verts,faces,mat,part):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.materials.append(bpy.data.materials[mat]);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(obj);obj['part']=part
    return obj


def box(name,at,size,mat,rotation=(0,0,0)):
    x,y,z=[s/2 for s in size];r=Euler(rotation).to_matrix()
    return mesh(name,[tuple(Vector(at)+r@Vector(p)) for p in [(-x,-y,-z),(x,-y,-z),(x,y,-z),(-x,y,-z),(-x,-y,z),(x,-y,z),(x,y,z),(-x,y,z)]],[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],mat,'Roof')


# Remove the original straight rake/underboard components, keeping eaves and brackets.
obj=bpy.data.objects['Roof__timber'];bm=bmesh.new();bm.from_mesh(obj.data)
remaining=set(bm.verts);discard=[]
while remaining:
    stack=[remaining.pop()];component=[]
    while stack:
        v=stack.pop();component.append(v)
        for e in v.link_edges:
            other=e.other_vert(v)
            if other in remaining:remaining.remove(other);stack.append(other)
    span=[max(v.co[i] for v in component)-min(v.co[i] for v in component) for i in range(3)]
    if span[0]>2.5 and (span[1]<.3 or span[1]>7):discard.extend(component)
bmesh.ops.delete(bm,geom=discard,context='VERTS');bm.to_mesh(obj.data);bm.free()
for obj in list(bpy.context.scene.objects):
    if obj.name.startswith('Gambrel gable infill'):bpy.data.objects.remove(obj,do_unlink=True)
for s in [-1,1]:
    points=[(0,7.41),(s*2.295,6.81),(s*3.825,5.26)]
    for i in range(2):
        a,b=points[i:i+2];theta=math.atan2(a[1]-b[1],abs(b[0]-a[0]))*s
        box('Broken pitch underboard',((a[0]+b[0])/2,0,(a[1]+b[1])/2-.10),(math.hypot(b[0]-a[0],b[1]-a[1]),7.7,.14),'timber',(0,theta,0))
        for end in [-1,1]:
            va=Vector((a[0],end*3.90,a[1]));vb=Vector((b[0],end*3.90,b[1]));direction=vb-va
            box('Broken pitch bargeboard',(va+vb)/2,(.17,.16,direction.length+.08),'timber',direction.to_track_quat('Z','Y').to_euler())
for side in [-1,1]:
    outline=[(-3.425,5.22),(-3.425,5.665),(-2.295,6.81),(0,7.28),(2.295,6.81),(3.425,5.665),(3.425,5.22)]
    verts=[(x,side*3.47+depth,z) for depth in [-.035,.035] for x,z in outline]
    n=len(outline)
    mesh('Complete gambrel gable',verts,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'cream','Walls')
for obj in bpy.context.scene.objects:
    if obj.type!='MESH':continue
    data=obj.data;data.update();layer=data.uv_layers.active or data.uv_layers.new(name='UVMap')
    for poly in data.polygons:
        axis=max(range(3),key=lambda k:abs(poly.normal[k]))
        for li in poly.loop_indices:
            c=data.vertices[data.loops[li].vertex_index].co
            layer.data[li].uv=(c.y,c.z) if axis==0 else ((c.x,c.z) if axis==1 else (c.x,c.y))
bpy.context.scene['finished_gambrel']=True
bpy.context.preferences.filepaths.save_version=0
bpy.ops.wm.save_as_mainfile(filepath=str(path))
print('Finished loft roof cage and gables.')
