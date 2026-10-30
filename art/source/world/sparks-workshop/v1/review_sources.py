"""Deliberate gameplay-review corrections of adopted workshop masters.
Preserves previous source files; no initial asset recipe is rerun.
"""
from pathlib import Path
import bpy,bmesh,math,hashlib,json,shutil,importlib.util
from mathutils import Vector
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
spec=importlib.util.spec_from_file_location('workshop_helpers',HERE/'author.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
records=[]

def opened(asset):
    path=ROOT/'art/source/world'/asset/'v1/model.blend'
    backup=path.with_name('model.pre-gameplay-review.blend')
    if backup.exists():raise RuntimeError('This review edit already ran: '+asset)
    shutil.copy2(path,backup)
    records.append({'asset':asset,'before':hashlib.sha256(path.read_bytes()).hexdigest(),'backup':str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.preferences.filepaths.save_version=0
    w.h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY')
    w.M.clear()
    for m in bpy.data.materials:
        if m.name.startswith('workshop_'):w.M[m.name[9:].split('.')[0]]=m
    return path

def edit(predicate,action):
    for o in bpy.context.scene.objects:
        if o.type!='MESH':continue
        bm=bmesh.new();bm.from_mesh(o.data);unseen=set(bm.verts)
        while unseen:
            seed=unseen.pop();group={seed};todo=[seed]
            while todo:
                for e in todo.pop().link_edges:
                    for v in e.verts:
                        if v in unseen:unseen.remove(v);group.add(v);todo.append(v)
            pts=[o.matrix_world@v.co for v in group]
            lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)))
            hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            if predicate(lo,hi):
                for v in group:v.co=o.matrix_world.inverted()@action(o.matrix_world@v.co)
        bm.to_mesh(o.data);bm.free();o.data.update()

def save(path):
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path))
    records[-1]['after']=hashlib.sha256(path.read_bytes()).hexdigest()

path=opened('workshop-shell')
edit(lambda lo,hi:hi.x<.60 and lo.y>6.0 and hi.y<8.0 and lo.z>1.1,
    lambda p:p+Vector((0,.50,0)))
save(path)

path=opened('workshop-shop-doors')
def widen(p):p.x*=4.6/3.4;return p
edit(lambda lo,hi:lo.z<.001 and hi.z<.17 and hi.x-lo.x>3.0,widen)
save(path)

path=opened('workshop-repair-bench')
# A second, supported dust cover lies over the rear of the housing. Its front
# edge leaves the brass window exposed, and its far edge rests on the bench.
nx,ny=32,16;verts=[];faces=[]
for j in range(ny+1):
    y=.16+j/ny*.62
    for i in range(nx+1):
        x=-.65+i/nx*1.50
        s=((x-.1)/.50)**2+((y-.13)/.40)**2
        edge=max(0,1-(abs(x-.1)/.76)**4)
        fall=max(0,min(1,(.78-y)/.18))
        z=1.33+.73*math.exp(-s*.65)*edge*fall
        if s<1:z=max(z,1.62+.34*math.sqrt(1-s)+.028)
        z+=.012*math.sin(x*15+y*6)
        verts.append((x,y,z))
for j in range(ny):
    for i in range(nx):
        a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
mesh=bpy.data.meshes.new('Dust cover over repair');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Covering sheet',mesh);bpy.context.scene.collection.objects.link(o);w.h.put(o,'linen',True)
uv=mesh.uv_layers.new(name='Cloth UV')
for p in mesh.polygons:
    for li in p.loop_indices:
        n=mesh.loops[li].vertex_index;uv.data[li].uv=(n%(nx+1)/nx,n//(nx+1)/ny)
sol=o.modifiers.new('Cotton hem','SOLIDIFY');sol.thickness=.01
bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=sol.name)
save(path)

path=opened('workshop-stove')
mat=w.M['ember'];bsdf=mat.node_tree.nodes.get('Principled BSDF')
def color(code):return tuple(w.h.linear(int(code[i:i+2],16)/255) for i in (0,2,4))+(1,)
bsdf.inputs['Base Color'].default_value=color('df8037')
bsdf.inputs['Emission Color'].default_value=color('ef9e4a')
bsdf.inputs['Emission Strength'].default_value=.42
mat.diffuse_color=color('df8037')
save(path)
(HERE/'gameplay-review.json').write_text(json.dumps({'date':'2026-10-27','record':str(Path(__file__).relative_to(ROOT)),'sources':records},indent=2)+'\n')
