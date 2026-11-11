"""User-marked workshop touchups. Edits adopted masters and preserves each before copy."""
from pathlib import Path
import bpy,bmesh,math,json,hashlib,shutil,importlib.util
from mathutils import Vector
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[4]
spec=importlib.util.spec_from_file_location('workshop_helpers',HERE/'author.py')
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
records=[]
def opened(asset):
    path=ROOT/'art/source/world'/asset/'v1/model.blend';backup=path.with_name('model.pre-user-touchups.blend')
    if backup.exists():raise RuntimeError('Already revised; edit the current master: '+asset)
    shutil.copy2(path,backup);records.append({'asset':asset,'before':hashlib.sha256(path.read_bytes()).hexdigest(),'backup':str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(path));bpy.context.preferences.filepaths.save_version=0
    w.h.PARENT=next(o for o in bpy.context.scene.objects if o.type=='EMPTY');w.M.clear()
    for m in bpy.data.materials:
        if m.name.startswith('workshop_'):w.M[m.name[9:].split('.')[0]]=m
    return path
def components(predicate,action=None):
    for o in list(bpy.context.scene.objects):
        if o.type!='MESH':continue
        bm=bmesh.new();bm.from_mesh(o.data);unseen=set(bm.verts);remove=[]
        while unseen:
            seed=unseen.pop();group={seed};todo=[seed]
            while todo:
                for e in todo.pop().link_edges:
                    for v in e.verts:
                        if v in unseen:unseen.remove(v);group.add(v);todo.append(v)
            pts=[o.matrix_world@v.co for v in group]
            lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            if predicate(lo,hi,o.data.materials[0].name):
                if action:
                    for v in group:v.co=o.matrix_world.inverted()@action(o.matrix_world@v.co)
                else:remove.extend(group)
        if remove:bmesh.ops.delete(bm,geom=remove,context='VERTS')
        bm.to_mesh(o.data);bm.free();o.data.update()
        if not o.data.vertices:bpy.data.objects.remove(o,do_unlink=True)
def finish(path):
    groups={}
    for o in list(bpy.context.scene.objects):
        if o.type=='CURVE':
            bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o;bpy.ops.object.convert(target='MESH')
        if o.type!='MESH':continue
        if not o.data.uv_layers:
            uv=o.data.uv_layers.new(name='Source planar UV')
            for p in o.data.polygons:
                axes=[i for i in range(3) if i!=max(range(3),key=lambda a:abs(p.normal[a]))]
                for li in p.loop_indices:
                    v=o.data.vertices[o.data.loops[li].vertex_index].co;uv.data[li].uv=(v[axes[0]],v[axes[1]])
        groups.setdefault(o.data.materials[0].name,[]).append(o)
    for name,items in groups.items():
        names=[o.name for o in items];bpy.ops.object.select_all(action='DESELECT')
        for o in items:o.select_set(True)
        bpy.context.view_layer.objects.active=items[0]
        if len(items)>1:bpy.ops.object.join()
        bpy.context.object.name=name;bpy.context.object['user_touchup_parts']=names
    bpy.ops.file.pack_all();bpy.ops.wm.save_as_mainfile(filepath=str(path));records[-1]['after']=hashlib.sha256(path.read_bytes()).hexdigest()

for asset in ['workshop-repair-bench','workshop-assembly-table','workshop-parts-crate']:
    path=opened(asset)
    components(lambda lo,hi,mat:mat=='workshop_linen')
    finish(path)

path=opened('workshop-shop-doors')
components(lambda lo,hi,mat:(lo.x>1.45 or hi.x< -1.45) and hi.z<1.2,lambda p:p+Vector((0,0,.15)))
finish(path)

path=opened('workshop-umbrella-stand')
components(lambda lo,hi,mat:mat=='workshop_ceramic')
# Continuous outer wall, annular rim and inner wall down to a recessed floor.
count=40;verts=[];faces=[]
for radius,z in [(.20,.025),(.27,.67),(.239,.67),(.174,.085)]:
    verts.extend([(math.cos(i/count*math.tau)*radius,math.sin(i/count*math.tau)*radius,z) for i in range(count)])
for ring in range(3):
    for i in range(count):
        a=ring*count+i;b=ring*count+(i+1)%count;faces.append((a,b,b+count,a+count))
faces.append(tuple(3*count+i for i in reversed(range(count))))
mesh=bpy.data.meshes.new('Open crock with deep interior');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Hollow umbrella crock',mesh);bpy.context.scene.collection.objects.link(o);w.h.put(o,'ceramic',True)
# Bring the complete group above the parquet surface.
for o in bpy.context.scene.objects:
    if o.type=='MESH':o.location.z+=.035
finish(path)

path=opened('workshop-armchair')
components(lambda lo,hi,mat:mat in ['workshop_plaid','workshop_ochre'])
profile=[(.65,.60),(.67,1.35),(.60,1.72),(.24,1.72),(.20,1.12),(.13,.79),(-.30,.79),(-.61,.79),(-.67,.35)]
distance=[0.0]
for a,b in zip(profile,profile[1:]):distance.append(distance[-1]+math.hypot(b[0]-a[0],b[1]-a[1]))
nx=28;ny=64;verts=[];faces=[]
for j in range(ny+1):
    k=min(7,j//8);t=(j-k*8)/8;f=t*t*(3-2*t)
    y=profile[k][0]*(1-f)+profile[k+1][0]*f;z=profile[k][1]*(1-f)+profile[k+1][1]*f
    for i in range(nx+1):
        u=i/nx*2-1;verts.append((u*.36,y+.002*math.sin(u*9+j*.2),z+.005*math.sin(u*11+j*.17)))
for j in range(ny):
    for i in range(nx):
        a=j*(nx+1)+i;faces.append((a,a+1,a+nx+2,a+nx+1))
mesh=bpy.data.meshes.new('Throw supported around chair');mesh.from_pydata(verts,[],faces);mesh.update()
o=bpy.data.objects.new('Draped plaid clear of upholstery',mesh);bpy.context.scene.collection.objects.link(o);w.h.put(o,'plaid',True)
uv=mesh.uv_layers.new(name='Physical wool spacing')
for p in mesh.polygons:
    for li in p.loop_indices:
        n=mesh.loops[li].vertex_index;j=n//(nx+1);k=min(7,j//8);t=(j-k*8)/8
        uv.data[li].uv=(.10+(n%(nx+1)/nx)*.72/1.5,distance[k]*(1-t)+distance[k+1]*t)
sol=o.modifiers.new('Wool thickness','SOLIDIFY');sol.thickness=.008;bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=sol.name)
for n in range(14):w.R('Throw fringe',(-.34+n*.052,-.67,.35),(-.34+n*.052,-.68,.28),.006,'ochre',6)
for o in bpy.context.scene.objects:
    if o.type!='MESH' or o.data.materials[0].name!='workshop_teal_dark':continue
    for v in o.data.vertices:v.co.x*=.42/.49;v.co.z*=.39/.43
    o.rotation_euler=(.08,-.08,-.03);o.location=Vector((0,.17,0))
    bpy.context.view_layer.update()
    minimum=min((o.matrix_world@v.co).z for v in o.data.vertices)
    o.location.z=.797-minimum
finish(path)

path=opened('workshop-stove')
components(lambda lo,hi,mat:mat in ['workshop_charcoal','workshop_steel'] and hi.y<-.40 and lo.z>.35 and hi.z<1.14)
front=-.45
w.Q('Connected arched stove surround',[(-.335,front,.41),(-.335,front,.80),(-.22,front,.965),(0,front,1.025),(.22,front,.965),(.335,front,.80),(.335,front,.41)],.029,'steel')
w.R('Grate lower frame',(-.335,front,.41),(.335,front,.41),.029,'steel')
for x in (-.22,0,.22):
    top=.80+.225*math.sqrt(1-(x/.335)**2)
    w.R('Welded vertical grate bar',(x,front-.012,.40),(x,front-.012,top+.012),.018,'charcoal')
w.R('Welded horizontal grate bar',(-.345,front-.015,.73),(.345,front-.015,.73),.015,'charcoal')
# Furniture is 15% smaller downstairs; keep the flue connected to the ceiling.
def flue(p):p.z=1.25+(p.z-1.25)*((3.25/.85-1.25)/2.0);return p
components(lambda lo,hi,mat:lo.y>.03 and hi.x<.17 and lo.x>-.17 and lo.z>1.20,flue)
finish(path)
(HERE/'user-touchups.json').write_text(json.dumps({'date':'2026-10-27','sources':records},indent=2)+'\n')
