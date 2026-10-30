"""Review 2: edit the saved study, preserving pass 1. Never rerun initial authoring.
Give each existing shingle a real raised lap/rolled profile; finish the limestone
and tread courses, close the jamb joints, and refine the coopered barrel.
"""
import bpy, bmesh, math, json, hashlib, shutil
from pathlib import Path
from mathutils import Vector

ROOT=Path.cwd();BASE=ROOT/'art/source/world/reference-cottage/v1';SOURCE=BASE/'model.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
if bpy.context.scene.get('review_pass')!=1:raise RuntimeError('Pass 2 applies only to the reviewed first master.')
backup=SOURCE.with_name('model.pass-01.blend')
if not backup.exists():shutil.copy2(SOURCE,backup)
before=hashlib.sha256(SOURCE.read_bytes()).hexdigest()


def components(data):
    neighbors=[[] for _ in data.vertices]
    for edge in data.edges:
        a,b=edge.vertices;neighbors[a].append(b);neighbors[b].append(a)
    seen=set();result=[]
    for start in range(len(data.vertices)):
        if start in seen:continue
        stack=[start];seen.add(start);group=[]
        while stack:
            i=stack.pop();group.append(i)
            for neighbor in neighbors[i]:
                if neighbor not in seen:seen.add(neighbor);stack.append(neighbor)
        result.append(sorted(group))
    return result


roof=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')=='Violet roof')
angle=math.atan2(4.65-2.78,2.28)
transform=roof.matrix_world;inverse=transform.inverted();count=0
for group in components(roof.data):
    if len(group)!=50:continue
    positions=[transform@roof.data.vertices[i].co for i in group]
    side=1 if sum(v.x for v in positions)>0 else -1
    normal=Vector((side*math.sin(angle),0,math.cos(angle)))
    # Preserve every authored tile, clipped boundary and UV. Deform its existing
    # 5x5 top/bottom grid: the upper row's nose must sit above the next tile.
    for local,index in enumerate(group):
        row=(local%25)//5;col=local%5
        u=[-.5,-.43,.25,.44,.5][row];v=[-.5,-.43,0,.43,.5][col]
        delta=.09*(u+.5)+.046*(1-(v*2)**2)-(.020 if local>=25 else 0)
        roof.data.vertices[index].co=inverse@(positions[local]+normal*delta)
    count+=1
roof.data.update()
if count<160:raise RuntimeError(f'Expected the reviewed shingle topology, found only {count} tiles.')

# Paint the actual stone surfaces, with old palettes/material roles retained.
image=bpy.data.images.load(str(ROOT/'assets/world/textures/lush/reference_cream_limestone.png'),check_existing=True)
for name,tint in [('study_stone',.89),('study_stone_light',1.02),('study_stone_warm',.79)]:
    mat=bpy.data.materials[name];bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
    mix=mat.node_tree.nodes.new('ShaderNodeMixRGB');mix.blend_type='MULTIPLY';mix.inputs[0].default_value=1
    mix.inputs[2].default_value=(tint,tint,tint,1)
    mat.node_tree.links.new(tex.outputs['Color'],mix.inputs[1]);mat.node_tree.links.new(mix.outputs[0],bs.inputs['Base Color'])


def uv(o,grain=None):
    d=o.data;d.update();layer=d.uv_layers.active or d.uv_layers.new(name='UVMap')
    for f in d.polygons:
        normal=max(range(3),key=lambda k:abs(f.normal[k]));axes=[k for k in range(3) if k!=normal]
        if grain is not None and grain!=normal:axes=[grain,next(k for k in axes if k!=grain)]
        for li in f.loop_indices:
            co=d.vertices[d.loops[li].vertex_index].co;layer.data[li].uv=(co[axes[0]]/1.35,co[axes[1]]/1.35)


def mesh(name,verts,faces,mat,part):
    data=bpy.data.meshes.new(name);data.from_pydata(verts,[],faces);data.materials.append(bpy.data.materials[mat]);data.update()
    o=bpy.data.objects.new(name,data);bpy.context.scene.collection.objects.link(o);o['part']=part;uv(o);return o


def box(name,at,size,mat,part,bevel=.025):
    x,y,z=[v/2 for v in size]
    o=mesh(name,[(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],[(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)],mat,part)
    o.location=at;bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Hand dressed edges','BEVEL');mod.width=bevel;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name);uv(o);return o


# Remove only the two connected tread slabs from the joined entrance, keeping
# the rest of the reviewed masonry/UVs. Three separate stones replace each slab.
treads=0
for o in list(bpy.context.scene.objects):
    if o.type!='MESH' or o.get('part')!='Stone entrance':continue
    remove=[]
    for group in components(o.data):
        positions=[o.matrix_world@o.data.vertices[i].co for i in group]
        low=Vector(tuple(min(p[k] for p in positions) for k in range(3)))
        high=Vector(tuple(max(p[k] for p in positions) for k in range(3)))
        size=high-low
        if size.x>1.4 and size.y>.5 and .10<size.z<.30 and high.y<-.9:
            remove.extend(group);treads+=1
    if remove:
        bm=bmesh.new();bm.from_mesh(o.data);bm.verts.ensure_lookup_table()
        bmesh.ops.delete(bm,geom=[bm.verts[i] for i in remove],context='VERTS')
        bm.to_mesh(o.data);bm.free();o.data.update()
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Rounded arch stone arris','BEVEL');mod.width=.018;mod.segments=2;mod.limit_method='ANGLE';mod.angle_limit=.41
    bpy.ops.object.modifier_apply(modifier=mod.name)
if treads!=2:raise RuntimeError(f'Expected two tread slabs to refine, found {treads}.')
for outer,inner,width,top in [(3.15,2.56,1.80,.12),(2.72,1.47,1.55,.26)]:
    for j in range(3):box('Individually dressed tread stone',(-width/2+(j+.5)*width/3,-(outer+inner)/2,top/2),(width/3-.010,outer-inner,top),'study_stone_light','Stone entrance',.022)
for side in [-1,1]:box('Upper jamb joint stone',(side*.72,-1.995,1.82),(.27,.35,.095),'study_stone_light','Stone entrance',.012)

# Barrel grain follows its staves; narrow curved seams follow its bulging body.
for o in bpy.context.scene.objects:
    if o.type=='MESH' and o.get('part')=='Rain barrel' and o.data.materials[0].name=='study_oak_warm':uv(o,2)
verts=[];faces=[];bx,by=-2.16,.98
for j in range(16):
    a=math.tau*j/16
    start=len(verts)
    for radius,z in [(.257,.05),(.304,.14),(.338,.39),(.314,.66),(.278,.775)]:
        for delta in [-.012,.012]:verts.append((bx+radius*math.cos(a+delta),by+radius*math.sin(a+delta),z))
    for k in range(4):faces.append(tuple(start+i for i in [k*2,k*2+1,k*2+3,k*2+2]))
mesh('Individual curved barrel stave joints',verts,faces,'study_endgrain_dark','Rain barrel')

# Merge added static islands into their semantic material groups, not the door.
for part in ['Stone entrance','Rain barrel']:
    for mat in bpy.data.materials:
        objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.parent and o.get('part')==part and len(o.data.materials)==1 and o.data.materials[0]==mat]
        if len(objects)>1:
            bpy.ops.object.select_all(action='DESELECT')
            for o in objects:o.select_set(True)
            bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name=part+'__'+mat.name
bpy.context.scene['review_pass']=2
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(BASE/'pass-02.json').write_text(json.dumps({'pass':2,'prior_source':backup.name,'before_sha256':before,'after_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'shingles_refined':count,'treads_refined':treads,'review':'Godot pass 1 showed flat overlap, uniform masonry and slab-like steps. Existing tiles were deformed, source geometry preserved elsewhere, stone surfaces painted and entry joints/treads refined.','source_edit':'art/source/world/reference-cottage/v1/refine_pass02.py'},indent=2)+'\n')
print('Pass 2 saved:',count,'raised rolled shingles; dressed treads and painted stone.',flush=True)
