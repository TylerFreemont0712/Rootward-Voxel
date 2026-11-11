"""One deliberate revision of adopted masters after the annotated loft review.

Opens the saved sources, replaces only marked components, preserves a before
copy and records hashes. Export with the normal world-art build afterwards.
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
h = importlib.util.module_from_spec(spec)
spec.loader.exec_module(h)
records = []


def open_source(asset):
    source = ROOT / 'art/source/world' / asset / 'v1/model.blend'
    backup = source.with_name('model.pre-marked-review.blend')
    if backup.exists():
        if source.read_bytes() != backup.read_bytes():
            raise RuntimeError('Revision already applied; edit the master: ' + asset)
    else:
        shutil.copy2(source, backup)
    records.append({'asset': asset, 'before': hashlib.sha256(source.read_bytes()).hexdigest(),
                    'backup': str(backup.relative_to(ROOT))})
    bpy.ops.wm.open_mainfile(filepath=str(source))
    bpy.context.preferences.filepaths.save_version = 0
    h.PARENT = next(o for o in bpy.context.scene.objects if o.type == 'EMPTY')
    h.M.clear()
    for m in bpy.data.materials:
        if m.name.startswith('loft_'):
            h.M[m.name[5:].split('.')[0]] = m
    for key, color in {'ink':'543b2b', 'teal_dark':'315c5a'}.items():
        if key not in h.M: h.material(key, color)
    return source


def components_edit(predicate, action=None):
    """Select joined parts by connected geometry in world space, not batch names."""
    for o in list(bpy.context.scene.objects):
        if o.type != 'MESH':
            continue
        bm = bmesh.new(); bm.from_mesh(o.data)
        unseen = set(bm.verts)
        remove = []
        while unseen:
            seed = unseen.pop(); group = {seed}; todo = [seed]
            while todo:
                for e in todo.pop().link_edges:
                    for v in e.verts:
                        if v in unseen:
                            unseen.remove(v); group.add(v); todo.append(v)
            pts = [o.matrix_world @ v.co for v in group]
            lo = Vector(tuple(min(v[i] for v in pts) for i in range(3)))
            hi = Vector(tuple(max(v[i] for v in pts) for i in range(3)))
            mat = o.data.materials[0].name if o.data.materials else ''
            if predicate(lo, hi, mat):
                if action:
                    for v in group:
                        world = o.matrix_world @ v.co
                        v.co = o.matrix_world.inverted() @ action(world, lo, hi, mat)
                else:
                    remove.extend(group)
        if remove:
            bmesh.ops.delete(bm, geom=remove, context='VERTS')
        bm.to_mesh(o.data); bm.free(); o.data.update()
        if not o.data.vertices:
            bpy.data.objects.remove(o, do_unlink=True)


def finish(source):
    # Curves are editable in the source; the exporter converts them to meshes.
    for o in list(bpy.context.scene.objects):
        if o.type == 'CURVE':
            bpy.ops.object.select_all(action='DESELECT'); o.select_set(True)
            bpy.context.view_layer.objects.active = o
            bpy.ops.object.convert(target='MESH')
        if o.type == 'MESH' and not o.data.uv_layers:
            uv = o.data.uv_layers.new(name='Source planar UV')
            for p in o.data.polygons:
                axes = [i for i in range(3) if i != max(range(3), key=lambda a: abs(p.normal[a]))]
                for li in p.loop_indices:
                    co = o.data.vertices[o.data.loops[li].vertex_index].co
                    uv.data[li].uv = co[axes[0]], co[axes[1]]
    bpy.ops.file.pack_all()
    bpy.context.scene['marked_review'] = '2026-10-27: fitted bedding, coherent crates, hanging cloth and shared window projection'
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    records[-1]['after'] = hashlib.sha256(source.read_bytes()).hexdigest()


source = open_source('loft-travel-stacks')
components_edit(lambda lo, hi, m: hi.z < .65 and hi.x < .16 and lo.x < -.5)
# All four walls use the same horizontal boards, with proper corner uprights.
for z in (.11, .31, .51):
    for y in (-.335, .335):
        h.box('Crate long wall slat', (-.30, y, z), (.82, .065, .18), 'oak', .012)
    for x in (-.685, .085):
        h.box('Crate end wall slat', (x, 0, z), (.065, .61, .18), 'oak', .012)
for x in (-.67, .07):
    for y in (-.34, .34):
        h.box('Joined crate corner upright', (x, y, .31), (.075, .075, .62), 'wood', .012)
        for z in (.10, .52):
            # Tiny dark nail heads on both exposed faces of each corner.
            h.sphere('Crate nail', (x, y + math.copysign(.041, y), z), (.009, .004, .009), 'ink', 8, 4)
for n in range(4):
    h.box('Crate lid board', (-.30, -.252 + n * .168, .638), (.83, .158, .055), 'oak', .009)
finish(source)

source = open_source('loft-bed')
components_edit(lambda lo, hi, m: m == 'loft_quilt')
# Lift the mattress, pillows, sheet and their seams above the end rail.
components_edit(lambda lo, hi, m: m in ('loft_linen', 'loft_white', 'loft_linen_shade'),
                lambda p, lo, hi, m: p + Vector((0, 0, .15)))
# A tucked quilt: its edge stays inside the posts and above the wooden rails.
# The fabric falls around the mattress instead of passing through the footboard.
nx, ny = 32, 32
verts, faces = [], []
for j in range(ny + 1):
    t = j / ny
    y = -1.29 + t * 2.05
    foot = max(0, 1 - t / .075)
    for i in range(nx + 1):
        u = i / nx; x = (u - .5) * 1.82
        edge = max(0, (abs(x) - .81) / .10)
        z = .985 - .115 * max(edge, foot) + .009 * math.sin(x * 16 + y * 5)
        verts.append((x, y, z))
for j in range(ny):
    for i in range(nx):
        a = j * (nx + 1) + i
        faces.append((a, a + 1, a + nx + 2, a + nx + 1))
mesh = bpy.data.meshes.new('Quilt fitted to mattress'); mesh.from_pydata(verts, [], faces); mesh.update()
o = bpy.data.objects.new('Tucked patchwork quilt', mesh); bpy.context.scene.collection.objects.link(o); h.put(o, 'quilt', True)
uv = mesh.uv_layers.new(name='Whole fabric')
for p in mesh.polygons:
    for li in p.loop_indices:
        n = mesh.loops[li].vertex_index; uv.data[li].uv = (n % (nx + 1) / nx, n // (nx + 1) / ny)
sol = o.modifiers.new('Quilt cotton thickness', 'SOLIDIFY'); sol.thickness = .012
bpy.context.view_layer.objects.active = o; bpy.ops.object.modifier_apply(modifier=sol.name)
finish(source)


def surface(name, rows, mat, folds=.0):
    """Closed soft shell with asymmetric silhouette and broad gravity folds."""
    verts, faces = [], []
    count = 24
    for k, (cx, y, z, width, depth) in enumerate(rows):
        for i in range(count):
            a = i / count * math.tau
            x = cx + width * math.cos(a)
            yy = y + depth * math.sin(a)
            yy += folds * math.sin(a * 5 + k * .45) * abs(math.sin(a))
            verts.append((x, yy, z + .012 * math.cos(a * 3 + k)))
    for j in range(len(rows) - 1):
        for i in range(count):
            a = j * count + i; b = j * count + (i + 1) % count
            faces.append((a, b, b + count, a + count))
    faces += [tuple(reversed(range(count))), tuple((len(rows) - 1) * count + i for i in range(count))]
    mesh = bpy.data.meshes.new(name); mesh.from_pydata(verts, [], faces); mesh.update()
    o = bpy.data.objects.new(name, mesh); bpy.context.scene.collection.objects.link(o); h.put(o, mat, True)
    return o


source = open_source('loft-wall-life')
components_edit(lambda lo, hi, m: hi.z < 1.81 and (m not in ('loft_wood_dark', 'loft_oak', 'loft_wood_edge')))
# Garment hung from its collar: sloped shoulders, heavy uneven hem, loose sleeves.
surface('Coat with weighted folds', [(-.53,-.15,.75,.205,.07),(-.55,-.14,.81,.25,.09),
    (-.58,-.14,1.03,.235,.105),(-.59,-.14,1.29,.235,.10),
    (-.60,-.13,1.48,.255,.085),(-.60,-.12,1.57,.19,.065),(-.60,-.13,1.71,.055,.035)], 'blue', .019)
surface('Coat left loose sleeve', [(-.91,-.16,.91,.075,.065),(-.94,-.13,1.05,.08,.075),
    (-.93,-.10,1.27,.09,.085),(-.82,-.10,1.49,.105,.09)], 'blue', .01)
surface('Coat right bent sleeve', [(-.29,-.24,.99,.075,.06),(-.23,-.19,1.13,.085,.07),
    (-.24,-.11,1.31,.09,.085),(-.38,-.10,1.50,.105,.09)], 'blue', .01)
for side in (-1,1):
    cx = -.60 + side * .09
    h.face('Folded coat lapel', [(cx,-.218,1.65),(cx+side*.09,-.245,1.53),
        (cx+side*.045,-.262,1.35),(-.60,-.256,1.48)], 'blue_light')
for z in (.91,1.10,1.29,1.46):
    h.sphere('Coat small brass button',(-.565,-.259,z),(.014,.01,.014),'brass',10,6)
for x in (-.73,-.44):
    h.curve('Coat pocket welt',[(x-.055,-.252,1.02),(x+.055,-.256,1.01)],.009,'blue_light')
h.curve('Coat opening seam',[(-.59,-.245,.77),(-.61,-.26,1.1),(-.60,-.255,1.44)],.005,'teal_dark')
h.curve('Coat collar loop',[(-.65,-.13,1.67),(-.61,-.18,1.76),(-.55,-.13,1.68)],.012,'linen')
# Soft canvas pouch, rounded gusset and a broad strap carrying its weight.
surface('Satchel rounded gusset',[(.49,-.17,.76,.16,.075),(.48,-.18,.79,.225,.115),
    (.47,-.19,.91,.24,.13),(.46,-.17,1.08,.215,.105),(.45,-.15,1.14,.18,.065)],'linen',.009)
h.face('Satchel folded flap',[(.25,-.246,1.13),(.66,-.246,1.13),(.69,-.31,1.01),
    (.62,-.324,.95),(.40,-.331,.94),(.23,-.305,.99)],'cream')
h.curve('Satchel stitched flap edge',[(.25,-.309,.997),(.4,-.339,.952),(.61,-.333,.962),(.67,-.319,1.015)],.005,'leather')
h.box('Satchel leather fastening',(.47,-.341,.98),(.055,.018,.13),'leather',.012)
h.box('Satchel clasp',(.47,-.357,.98),(.039,.015,.04),'brass',.008)
for side in (-1,1):
    pts=[(.55,-.16,1.74),(.55+side*.085,-.17,1.60),(.46+side*.20,-.18,1.36),(.46+side*.20,-.18,1.09)]
    for a,b in zip(pts,pts[1:]):
        h.face('Flat leather shoulder strap',[(a[0]-.018,a[1]-.012,a[2]),(a[0]+.018,a[1]-.012,a[2]),
            (b[0]+.018,b[1]-.012,b[2]),(b[0]-.018,b[1]-.012,b[2])],'leather')
finish(source)

source = open_source('loft-shell')
for o in bpy.context.scene.objects:
    if o.type != 'MESH' or o.name not in ('Porthole harbour view', 'Dormer glass'):
        continue
    uv = o.data.uv_layers.active
    for p in o.data.polygons:
        for li in p.loop_indices:
            v = o.matrix_world @ o.data.vertices[o.data.loops[li].vertex_index].co
            # One north-facing panorama, correct 3:2 aspect and shared horizon.
            # The higher porthole sees sky; the lower window sees the harbour.
            uv.data[li].uv = (.20 + (v.x - 5.6) / 9.0, .68 + (v.z - 2.30) / 6.0)
finish(source)

source = open_source('loft-cable')
for o in list(bpy.context.scene.objects):
    if o.type == 'MESH': bpy.data.objects.remove(o, do_unlink=True)
h.curve('Cable resting against west wall', [(0,0,2.27),(-.40,.18,2.18),(-.40,.85,1.60),
    (-.28,1.60,1.23),(-.15,2.20,1.18),(-.10,2.55,1.22)], .017, 'cable')
finish(source)
(HERE / 'marked-review.json').write_text(json.dumps({'date':'2026-10-27',
    'record':str(Path(__file__).relative_to(ROOT)), 'sources':records}, indent=2)+'\n')
