"""Final saved-source review corrections. Keep pass 2 and edit this master.
Clean manifold entrance stones, fine tile arrises, layered ridge caps, painted
window panes and fewer moving meshes. The original home is never opened.
"""
import bpy,bmesh,math,json,hashlib,shutil
from pathlib import Path
from mathutils import Vector

ROOT=Path.cwd();BASE=ROOT/'art/source/world/reference-cottage/v1';SOURCE=BASE/'model.blend'
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
if bpy.context.scene.get('review_pass')!=2:raise RuntimeError('Pass 3 applies only to the reviewed second master.')
backup=SOURCE.with_name('model.pass-02.blend')
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
            for j in neighbors[i]:
                if j not in seen:seen.add(j);stack.append(j)
        result.append(sorted(group))
    return result


def uv(o):
    d=o.data;d.update();layer=d.uv_layers.active or d.uv_layers.new(name='UVMap')
    for f in d.polygons:
        normal=max(range(3),key=lambda k:abs(f.normal[k]));axes=[k for k in range(3) if k!=normal]
        for li in f.loop_indices:
            co=d.vertices[d.loops[li].vertex_index].co;layer.data[li].uv=(co[axes[0]]/1.35,co[axes[1]]/1.35)


def mesh(name,verts,faces,mat,part):
    d=bpy.data.meshes.new(name);d.from_pydata(verts,[],faces);d.materials.append(bpy.data.materials[mat]);d.update()
    bm=bmesh.new();bm.from_mesh(d);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(d);bm.free()
    o=bpy.data.objects.new(name,d);bpy.context.scene.collection.objects.link(o);o['part']=part;uv(o);return o


def bevel(o,width=.028):
    bpy.context.view_layer.objects.active=o
    mod=o.modifiers.new('Clean dressed stone arris','BEVEL');mod.width=width;mod.segments=2
    bpy.ops.object.modifier_apply(modifier=mod.name);uv(o)


def box(name,at,size,mat,part,width=.028):
    x,y,z=[v/2 for v in size]
    o=mesh(name,[(-x,-y,-z),(-x,-y,z),(-x,y,-z),(-x,y,z),(x,-y,-z),(x,-y,z),(x,y,-z),(x,y,z)],[(2,6,4,0),(5,7,3,1),(4,5,1,0),(3,7,6,2),(1,3,2,0),(6,7,5,4)],mat,part)
    o.location=at
    if width:bevel(o,width)
    return o


def arch_stone(name,a,b,inner,outer,depth,mat,center_y=-2.01):
    # A single closed trapezoidal prism, consistently wound before beveling.
    vertices=[]
    for y in [center_y-depth/2,center_y+depth/2]:
        for radius,angle in [(inner,a),(outer,a),(outer,b),(inner,b)]:
            vertices.append((radius*math.cos(angle),y,1.84+radius*math.sin(angle)))
    return mesh(name,vertices,[(0,1,2,3),(7,6,5,4),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],mat,'Stone entrance')


# The pass-2 arch bevel exposed inconsistent prism topology. Replace only the
# reviewed entrance component; retain the roof, logs, joinery, plants and door.
for o in list(bpy.context.scene.objects):
    if o.type=='MESH' and o.get('part')=='Stone entrance':bpy.data.objects.remove(o,do_unlink=True)
for side in [-1,1]:
    box('Entry mortar bed',(side*.7275,-1.985,1.06),(.29,.08,1.56),'study_mortar','Stone entrance',.01)
    for j in range(6):
        box('Rounded limestone jamb block',(side*.7275,-2.01,.410+j*.26),(.275,.34,.244),'study_stone_light' if j%3 else 'study_stone','Stone entrance',.030)
for j in range(11):
    arch_stone('Recessed arch mortar',j*math.pi/11,(j+1)*math.pi/11,.585,.87,.08,'study_mortar',-1.985)
    stone=arch_stone('Dressed arch voussoir',j*math.pi/11+.009,(j+1)*math.pi/11-.009,.59,.865,.34,'study_stone_light' if j%3 else 'study_stone')
    bevel(stone,.023)
for outer,inner,width,top in [(3.15,2.56,1.80,.12),(2.72,1.47,1.55,.26)]:
    for j in range(3):
        box('Separate dressed tread stone',(-width/2+(j+.5)*width/3,-(outer+inner)/2,top/2),(width/3-.014,outer-inner,top),'study_stone_light','Stone entrance',.023)

# Split each existing nose into a thin pale top arris and a darker clay return.
# Preserve the UVs and rolled surface of the 184 individually reviewed tiles.
roof=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')=='Violet roof')
groups=[g for g in components(roof.data) if len(g)==50]
bm=bmesh.new();bm.from_mesh(roof.data);bm.verts.ensure_lookup_table();old_vertices=list(bm.verts)
edge_index=next(i for i,m in enumerate(roof.data.materials) if m.name=='study_tile_edge')
clay_index=next(i for i,m in enumerate(roof.data.materials) if m.name=='study_clay_under')
uv_layer=bm.loops.layers.uv.active
for group in groups:
    top=[old_vertices[group[20+j]] for j in range(5)]
    bottom=[old_vertices[group[45+j]] for j in range(5)]
    nose=set(top+bottom)
    faces=[f for f in list(top[0].link_faces)+list(top[1].link_faces)+list(top[2].link_faces)+list(top[3].link_faces)+list(top[4].link_faces) if len(f.verts)==4 and all(v in nose for v in f.verts)]
    for f in set(faces):bm.faces.remove(f)
    middle=[bm.verts.new(a.co.lerp(b.co,.20)) for a,b in zip(top,bottom)]
    for j in range(4):
        for verts,material in [((top[j+1],top[j],middle[j],middle[j+1]),edge_index),((middle[j+1],middle[j],bottom[j],bottom[j+1]),clay_index)]:
            f=bm.faces.new(verts);f.material_index=material
            for k,loop in enumerate(f.loops):loop[uv_layer].uv=[(0,0),(1,0),(1,1),(0,1)][k]
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(roof.data);bm.free();roof.data.update()

# Ridge caps also overlap in height, avoiding coplanar surfaces/flickering seams.
caps=next(o for o in bpy.context.scene.objects if o.type=='MESH' and o.get('part')=='Ridge caps')
transform=caps.matrix_world;inverse=transform.inverted()
cap_count=0
for group in components(caps.data):
    positions=[transform@caps.data.vertices[i].co for i in group]
    low=min(p.y for p in positions);high=max(p.y for p in positions)
    if high-low<.1:continue
    for index,p in zip(group,positions):
        radius=math.hypot(p.x,p.z-4.665)
        factor=(radius+.026*(p.y-low)/(high-low))/radius
        caps.data.vertices[index].co=inverse@Vector((p.x*factor,p.y,4.665+(p.z-4.665)*factor))
    cap_count+=1
caps.data.update()

# The reference's warm glass has painterly dark edges instead of flat yellow fills.
mat=bpy.data.materials['study_window'];bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
tex=mat.node_tree.nodes.new('ShaderNodeTexImage')
tex.image=bpy.data.images.load(str(ROOT/'assets/world/textures/lush/window_glow.png'),check_existing=True)
mat.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Emission Strength'].default_value=.12
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.get('part')!='Windows' or o.data.materials[0]!=mat:continue
    layer=o.data.uv_layers.active
    for group in components(o.data):
        points={i:o.matrix_world@o.data.vertices[i].co for i in group}
        low_y=min(v.y for v in points.values());high_y=max(v.y for v in points.values())
        low_z=min(v.z for v in points.values());high_z=max(v.z for v in points.values())
        for f in o.data.polygons:
            if f.vertices[0] not in points:continue
            for li in f.loop_indices:
                p=points[o.data.loops[li].vertex_index]
                layer.data[li].uv=(2*(p.y-low_y)/(high_y-low_y),2*(p.z-low_z)/(high_z-low_z))

# A small glass colour difference reads through the four upper door panes.
glass_light=bpy.data.materials.get('study_glass_light')
if glass_light is None:
    glass_light=bpy.data.materials['study_glass'].copy();glass_light.name='study_glass_light'
    bs=next(n for n in glass_light.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    def linear(v):return v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4
    bs.inputs['Base Color'].default_value=(*[linear(int('596b8a'[i:i+2],16)/255) for i in [0,2,4]],1)
for o in bpy.context.scene.objects:
    if o.type=='MESH' and o.parent and o.name.startswith('Door blue glass pane') and o.location.z>1.5:
        o.data.materials[0]=glass_light

# Merge rigid leaf pieces by material under the same semantic hinge. Moving
# parts remain separately editable, with fewer runtime draw calls.
hinge=bpy.data.objects['DoorHinge'];before_leaf=sum(1 for o in hinge.children if o.type=='MESH')
for mat in bpy.data.materials:
    objects=[o for o in hinge.children if o.type=='MESH' and len(o.data.materials)==1 and o.data.materials[0]==mat]
    if len(objects)>1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='Door leaf__'+mat.name
for mat in bpy.data.materials:
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and not o.parent and o.get('part')=='Stone entrance' and o.data.materials[0]==mat]
    if len(objects)>1:
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();bpy.context.object.name='Stone entrance__'+mat.name
after_leaf=sum(1 for o in hinge.children if o.type=='MESH')
bpy.context.scene['review_pass']=3
bpy.context.preferences.filepaths.save_version=0;bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE))
(BASE/'pass-03.json').write_text(json.dumps({'pass':3,'prior_source':backup.name,'before_sha256':before,'after_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'rolled_noses_finished':len(groups),'ridge_caps_layered':cap_count,'moving_meshes_before':before_leaf,'moving_meshes_after':after_leaf,'review':'Pass 2 exposed ragged arch bevels, flat warm glass and cap overlap. Entrance prisms were corrected, existing roof noses/caps refined and the existing painted window material reused.','source_edit':'art/source/world/reference-cottage/v1/refine_pass03.py'},indent=2)+'\n')
print('Pass 3 saved: clean entrance,',len(groups),'tile arrises,',cap_count,'layered caps;',before_leaf,'->',after_leaf,'moving meshes.',flush=True)
