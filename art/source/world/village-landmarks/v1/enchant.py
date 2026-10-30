"""Deliberate edit of the first Rootward master after the larger/mystical direction.
Preserves the first model beside it; never recreates an adopted master.
"""
import bpy, math, random, shutil, sys
from pathlib import Path
from mathutils import Vector

ROOT=Path.cwd()
source=ROOT/'art/source/world/rootward-tree/v1/model.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
if bpy.context.scene.get('enchantment_revision'):
    raise RuntimeError('This revision is already applied; edit the saved master.')
backup=source.with_name('model.pre-enchantment.blend')
if not backup.exists():shutil.copy2(source,backup)
# Enlarge the actual saved geometry, keeping the ground pivot and source ownership.
for o in bpy.context.scene.objects:
    if o.type=='MESH':
        o.location.x*=1.55;o.location.y*=1.55;o.location.z*=2.05
        for v in o.data.vertices:
            v.co.x*=1.55;v.co.y*=1.55;v.co.z*=2.05

M={}
def material(name,rgb,emission=0):
    m=bpy.data.materials.new(name);m.use_nodes=True
    n=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    n.inputs['Base Color'].default_value=(*rgb,1)
    n.inputs['Roughness'].default_value=.7
    if emission:
        n.inputs['Emission Color'].default_value=(*rgb,1)
        n.inputs['Emission Strength'].default_value=emission
    M[name]=m
material('rootward_lantern_gold',(.68,.38,.09))
material('rootward_chain',(.12,.20,.17))
material('rootward_amber_glass',(1,.67,.24),3.0)
material('rootward_jade_glass',(.28,1,.78),2.0)
material('rootward_lilac_glass',(.72,.52,1),2.0)
material('rootward_living_gold',(.88,.67,.24),2.0)
material('rootward_moonstone',(.23,.50,.43),.25)
rng=random.Random(261026)

def mesh(name,verts,faces,mat):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(M[mat])
    o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o)
    o['part']='Enchantment';return o
def box(name,at,size,mat,rotation=0):
    x,y,z=[v/2 for v in size]
    o=mesh(name,[(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],[(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)],mat)
    o.location=at;o.rotation_euler.z=rotation;return o
def tube(name,points,radii,mat,n=8):
    verts=[];faces=[]
    for i,p in enumerate(points):
        direction=Vector(points[min(i+1,len(points)-1)])-Vector(points[max(0,i-1)])
        q=direction.to_track_quat('Z','Y')
        for j in range(n):
            a=math.tau*j/n
            verts.append(tuple(Vector(p)+q@Vector((math.cos(a)*radii[i],math.sin(a)*radii[i],0))))
    faces.append(tuple(reversed(range(n))))
    for i in range(len(points)-1):
        for j in range(n):faces.append((i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j))
    faces.append(tuple(range((len(points)-1)*n,len(points)*n)))
    return mesh(name,verts,faces,mat)
def marker(name,at):
    o=bpy.data.objects.new(name,None);bpy.context.scene.collection.objects.link(o);o.location=at

# Great root seams: narrow forks of living amber follow the sculpted buttresses.
for j in range(10):
    a=math.tau*j/10+.12
    points=[]
    for r,z in [(1.7,2.8),(2.8,1.45),(4.15,.77),(6.05,.27)]:
        points.append((r*math.cos(a),r*math.sin(a),z))
    tube('Living light in a root',points,[.065,.08,.065,.018],'rootward_living_gold',6)
    for side in [-1,1]:
        tube('Root light tributary',[points[1],(4.25*math.cos(a+side*.12),4.25*math.sin(a+side*.12),.57),(5.4*math.cos(a+side*.2),5.4*math.sin(a+side*.2),.18)],[.045,.035,.005],'rootward_living_gold',5)
# Three interrupted rings of ancient stone and gold glyphs under the boughs.
for j in range(28):
    a=math.tau*j/28
    r=8.2
    box('Old ward stone',(r*math.cos(a),r*math.sin(a),.10),(.60,.44,.18),'rootward_moonstone',a)
    box('Gold ward glyph',(r*math.cos(a),r*math.sin(a),.202),(.19,.07,.018),'rootward_living_gold',a)
    if j%2==0:box('Glyph crossing',(r*math.cos(a),r*math.sin(a),.203),(.06,.23,.018),'rootward_living_gold',a)

# Long suspended chains and warm jewel lanterns, visibly hung from the boughs.
for j in range(30):
    a=math.tau*j/15 + (.21 if j>=15 else 0)
    r=rng.uniform(5.0,9.0) if j<15 else rng.uniform(3.3,6.3)
    z=rng.uniform(4.0,8.1) if j<15 else rng.uniform(9.0,13.8)
    x,y=r*math.cos(a),r*math.sin(a)
    anchor_z=13.0 if j<15 else 17.4
    tube('Suspended lantern chain',[(x,y,z+.7),(x,y,anchor_z)],[.023,.023],'rootward_chain',5)
    glass=['rootward_amber_glass','rootward_amber_glass','rootward_jade_glass','rootward_lilac_glass'][j%4]
    box('Luminous jewel lantern',(x,y,z),(.45,.45,.65),glass,math.pi/4)
    for zz in [-.37,.37]:box('Lantern copper rim',(x,y,z+zz),(.62,.62,.09),'rootward_lantern_gold',math.pi/4)
    for k in range(4):
        aa=math.tau*k/4+math.pi/4
        box('Lantern corner rib',(x+.31*math.cos(aa),y+.31*math.sin(aa),z),(.045,.045,.80),'rootward_lantern_gold')
    tube('Lantern peaked cap',[(x,y,z+.42),(x,y,z+.66)],[.44,.06],'rootward_lantern_gold',4)
    tube('Lantern pendant',[(x,y,z-.43),(x,y,z-.80)],[.08,.025],'rootward_lantern_gold',6)
    marker('RootwardLight_'+str(j),(x,y,z))

# Festooned lights trace sagging garlands between the great limbs.
for j in range(9):
    a=math.tau*j/9
    b=a+math.tau/9
    points=[]
    for k in range(13):
        t=k/12
        x=7.6*((1-t)*math.cos(a)+t*math.cos(b))
        y=7.6*((1-t)*math.sin(a)+t*math.sin(b))
        z=10.0-math.sin(t*math.pi)*1.0
        points.append((x,y,z))
        if k%2==0:
            tube('Garland star droplet',[(x,y,z),(x,y,z-.18)],[.085,.025],'rootward_amber_glass',6)
    tube('Bough garland',points,[.018]*len(points),'rootward_chain',5)

# Presentation anchors are editable in Blender and have no gameplay occupancy.
for j in range(84):
    a=rng.uniform(0,math.tau);r=rng.uniform(3.3,10.3);z=rng.uniform(.45,13)
    marker('RootwardWisp_'+str(j),(r*math.cos(a),r*math.sin(a),z))

# Merge only this revision's static pieces; retain meaningful light/wisp anchors.
for mat in M.values():
    objs=[o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')=='Enchantment' and o.data.materials[0]==mat]
    if len(objs)>1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in objs:o.select_set(True)
        bpy.context.view_layer.objects.active=objs[0];bpy.ops.object.join();bpy.context.object.name='Enchantment__'+mat.name
bpy.context.scene['enchantment_revision']='2026-10-26 monumental tree; lanterns, living root seams, ward ring and wisp anchors'
bpy.context.preferences.filepaths.save_version=0
bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(source))
