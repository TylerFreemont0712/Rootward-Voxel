"""Deliberate edits of the three adopted masters after the lived-in loft review.
Preserves before copies. Does not call the guarded one-time asset builders.
"""
from pathlib import Path
import hashlib
import importlib.util
import json
import math
import shutil
import bpy
import bmesh
from mathutils import Vector

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[4]
spec = importlib.util.spec_from_file_location('loft_helpers', HERE / 'author.py')
h = importlib.util.module_from_spec(spec); spec.loader.exec_module(h)
records = []


def open_source(asset):
    path = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = path.with_name('model.pre-lived-in.blend')
    if backup.exists():
        if backup.read_bytes() != path.read_bytes():
            raise RuntimeError('This edit already ran; open the current master: ' + asset)
    else:
        shutil.copy2(path, backup)
    records.append({'asset':asset, 'before':hashlib.sha256(path.read_bytes()).hexdigest(),
                    'backup':str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(path))
    bpy.context.preferences.filepaths.save_version = 0
    h.PARENT = next(o for o in bpy.context.scene.objects if o.type == 'EMPTY')
    h.M.clear()
    for mat in bpy.data.materials:
        if mat.name.startswith('loft_'): h.M[mat.name[5:].split('.')[0]] = mat
    for key, color in {'blue':'536b89','blue_light':'8494aa','teal_dark':'315c5a',
                       'linen':'eee5d3','cream':'efe4cc','leather':'80563b','brass':'c49a53'}.items():
        if key not in h.M: h.material(key, color)
    return path


def edit_components(predicate, action=None):
    for o in list(bpy.context.scene.objects):
        if o.type != 'MESH': continue
        bm = bmesh.new(); bm.from_mesh(o.data)
        unseen = set(bm.verts); remove = []
        while unseen:
            seed = unseen.pop(); group = {seed}; todo = [seed]
            while todo:
                for edge in todo.pop().link_edges:
                    for v in edge.verts:
                        if v in unseen: unseen.remove(v); group.add(v); todo.append(v)
            pts = [o.matrix_world @ v.co for v in group]
            lo = Vector(tuple(min(p[i] for p in pts) for i in range(3)))
            hi = Vector(tuple(max(p[i] for p in pts) for i in range(3)))
            mat = o.data.materials[0].name
            if predicate(lo, hi, mat):
                if action:
                    for v in group:
                        v.co = o.matrix_world.inverted() @ action(o.matrix_world @ v.co, lo, hi)
                else: remove.extend(group)
        if remove: bmesh.ops.delete(bm, geom=remove, context='VERTS')
        bm.to_mesh(o.data); bm.free(); o.data.update()
        if not o.data.vertices: bpy.data.objects.remove(o, do_unlink=True)


def fabric(name, points, nx, ny, mat, thickness=.012):
    faces = []
    for j in range(ny):
        for i in range(nx):
            a = j*(nx+1)+i; faces.append((a,a+1,a+nx+2,a+nx+1))
    mesh = bpy.data.meshes.new(name); mesh.from_pydata(points, [], faces); mesh.update()
    o = bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(o); h.put(o, mat, True)
    uv = mesh.uv_layers.new(name='Cloth coordinates')
    for p in mesh.polygons:
        for li in p.loop_indices:
            n = mesh.loops[li].vertex_index; uv.data[li].uv = (n%(nx+1)/nx,n//(nx+1)/ny)
    bpy.context.view_layer.objects.active = o
    sol = o.modifiers.new('Soft cloth thickness','SOLIDIFY'); sol.thickness = thickness
    bpy.ops.object.modifier_apply(modifier=sol.name)
    return o


def shell(name, rows, mat):
    count = 32; verts = []; faces = []
    for k,(cx,cy,z,width,depth) in enumerate(rows):
        for i in range(count):
            a = i/count*math.tau
            verts.append((cx+width*math.cos(a), cy+depth*math.sin(a),
                z+.012*math.sin(3*a+k*.6)-.025*max(0,math.sin(a))))
    for k in range(len(rows)-1):
        for i in range(count):
            a=k*count+i; b=k*count+(i+1)%count; faces.append((a,b,b+count,a+count))
    faces += [tuple(reversed(range(count))),tuple((len(rows)-1)*count+i for i in range(count))]
    mesh=bpy.data.meshes.new(name); mesh.from_pydata(verts,[],faces); mesh.update()
    o=bpy.data.objects.new(name,mesh); bpy.context.scene.collection.objects.link(o); h.put(o,mat,True)
    return o


def finish(path):
    groups = {}
    for o in list(bpy.context.scene.objects):
        if o.type == 'CURVE':
            bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
            bpy.context.view_layer.objects.active=o; bpy.ops.object.convert(target='MESH')
        if o.type != 'MESH': continue
        if not o.data.uv_layers:
            uv=o.data.uv_layers.new(name='Source planar UV')
            for p in o.data.polygons:
                axes=[i for i in range(3) if i!=max(range(3),key=lambda a:abs(p.normal[a]))]
                for li in p.loop_indices:
                    v=o.data.vertices[o.data.loops[li].vertex_index].co; uv.data[li].uv=(v[axes[0]],v[axes[1]])
        groups.setdefault(o.data.materials[0].name,[]).append(o)
    for name,objects in groups.items():
        parts=[o.name for o in objects]
        bpy.ops.object.select_all(action='DESELECT')
        for o in objects:o.select_set(True)
        bpy.context.view_layer.objects.active=objects[0]
        if len(objects)>1:bpy.ops.object.join()
        bpy.context.object.name=name; bpy.context.object['lived_in_parts']=parts
    bpy.ops.file.pack_all()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    records[-1]['after']=hashlib.sha256(path.read_bytes()).hexdigest()


path=open_source('loft-bed')
edit_components(lambda lo,hi,m: m=='loft_quilt' or (m=='loft_linen' and lo.z>.96 and hi.y-lo.y<.6))
def pillow(p,lo,hi):
    centre=(lo+hi)*.5; left=centre.x<0
    angle=-.19 if left else .11
    x,y=p.x-centre.x,p.y-centre.y
    p.x=centre.x+x*math.cos(angle)-y*math.sin(angle)+(-.035 if left else .045)
    p.y=centre.y+x*math.sin(angle)+y*math.cos(angle)+(-.12 if left else .04)
    if p.z>centre.z:
        p.z-=.035*math.exp(-((x/.25)**2+(y/.19)**2))
    return p
edit_components(lambda lo,hi,m: m in ('loft_white','loft_linen_shade') and lo.z>.95,pillow)
# Exposed linen is creased, with one uneven edge beneath the pulled-back quilt.
nx,ny=32,24; pts=[]
for j in range(ny+1):
    t=j/ny
    for i in range(nx+1):
        u=i/nx*2-1
        x=u*.88; y=-1.27+t*2.1+.025*math.sin(u*5)*t
        z=.961+.012*(1+math.sin(u*8+y*7))+.012*math.exp(-((u+.2+t*.4)/.25)**2)
        pts.append((x,y,z))
fabric('Creased linen left after sleeping',pts,nx,ny,'linen',.009)
# Bunched diagonally towards the foot, with a lifted turned-back upper edge.
pts=[]
for j in range(ny+1):
    t=j/ny
    for i in range(nx+1):
        u=i/nx*2-1
        x=u*.885+.025*math.sin(t*8)*(1-u*u)
        y=-1.26+t*(1.66-.24*u)+.045*math.sin(u*4)*t*t
        edge=max(0,(abs(u)-.92)/.08)
        z=.991-.105*edge+.025*(1+math.sin(u*10+t*14))*(1-edge)
        z+=.115*math.exp(-((u+.4-t*.7)/.20)**2)*math.sin(t*math.pi)**2
        z+=.14*math.exp(-((t-.88)/.085)**2)*(1-edge*.5)
        pts.append((x,y,z))
fabric('Quilt pushed back after a night in bed',pts,nx,ny,'quilt')
finish(path)

path=open_source('loft-wall-life')
# Retain rail, pegs, upper shelf, books and plant. Replace only hanging clothes.
edit_components(lambda lo,hi,m: hi.z<1.82 and m not in ('loft_wood_dark','loft_oak','loft_wood_edge'))
shell('Weighted canvas bag',[(.50,-.23,.43,.14,.07),(.49,-.24,.47,.23,.12),
    (.48,-.25,.64,.255,.145),(.47,-.22,.83,.23,.12),(.47,-.19,.94,.19,.065)],'linen')
# A curved flap follows the softened bag body; the back corner hangs lower.
pts=[]
for j in range(9):
    t=j/8
    for i in range(17):
        u=i/16*2-1
        pts.append((.47+u*(.21+.015*math.sin(t*math.pi)),
            -.245-.15*math.sin(t*math.pi/2)+.025*u*u,
            .94-.235*t+.025*u+.012*math.cos(u*5)*(t*t)))
fabric('Soft folded satchel flap',pts,16,8,'cream',.015)
h.box('Satchel leather tab',(.47,-.403,.72),(.055,.02,.12),'leather',.012)
h.box('Satchel fastening',(.47,-.419,.72),(.038,.012,.04),'brass',.008)
# Both strap legs are straight under load, with only a short bend over the peg.
for side in (-1,1):
    a=Vector((.55,-.183,1.74)); b=Vector((.47+side*.205,-.23,.88))
    width=Vector((.016,0,0)); pts=[]
    for j in range(9):
        p=a.lerp(b,j/8); pts.extend([tuple(p-width),tuple(p+width)])
    fabric('Taut leather strap under weight',pts,1,8,'leather',.008)
h.curve('Strap folded over wooden peg',[(.535,-.17,1.73),(.55,-.199,1.777),(.565,-.17,1.73)],.016,'leather')
finish(path)

path=open_source('loft-chair')
# One continuous coat draped over the back, with fabric pooled onto the seat.
profile=[(.46,.35,.35),(.45,.62,.34),(.43,.92,.325),(.38,1.20,.32),
    (.31,1.29,.32),(.22,1.23,.32),(.16,1.05,.32),(.09,.78,.33),
    (-.07,.72,.35),(-.29,.62,.36),(-.36,.40,.34)]
nx=32; ny=(len(profile)-1)*8; pts=[]
for j in range(ny+1):
    k=min(len(profile)-2,j//8); t=(j-k*8)/8
    # Smooth interpolation makes the shoulders settle over the curved rail.
    f=t*t*(3-2*t)
    cy,z,w=[profile[k][i]*(1-f)+profile[k+1][i]*f for i in range(3)]
    for i in range(nx+1):
        u=i/nx*2-1
        x=u*w+.018*math.sin(j*.17)*(1-u*u)
        y=cy+.024*math.sin(u*12+j*.15)
        zz=z+.018*math.sin(u*10+j*.25)
        if j<4 or j>ny-4:zz+=.035*math.sin(u*5+.4)
        pts.append((x,y,zz))
fabric('Coat casually slung across chair',pts,nx,ny,'blue',.018)
for side in (-1,1):
    shell('Loose hanging coat sleeve',[(side*.40,.22,.38+(side+1)*.06,.07,.042),
        (side*.43,.26,.55,.08,.048),(side*.40,.32,.79,.085,.055),
        (side*.35,.37,1.03,.085,.06),(side*.30,.34,1.23,.09,.06)],'blue')
h.curve('Coat back seam',[(-.04,.485,.37),(-.02,.48,.66),(0,.46,.9),(.02,.405,1.16)],.005,'blue_light')
h.curve('Soft collar folded on chair', [(-.10,.25,1.255),(-.085,.34,1.31),(.07,.35,1.315),(.11,.25,1.26)],.027,'blue_light')
finish(path)
(HERE/'lived-in-revision.json').write_text(json.dumps({'date':'2026-10-27',
    'record':str(Path(__file__).relative_to(ROOT)),'sources':records},indent=2)+'\n')
